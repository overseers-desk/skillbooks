# spar-dispatch.tcl — Async dispatcher class + phase runners (P, A).
# Callable from both tclsh (CLI) and wish (GUI).
# Does NOT call vwait — the caller's event loop handles that.

package require TclOO

# Idempotent load — top-level scripts (spar-transition.tcl, spar-ui.tcl,
# test/test-*.tcl) may source this via multiple paths.
# oo::class create is not idempotent, so guard it.
if {[info exists ::spar::_dispatch_loaded]} {
    package provide spar-dispatch 1.0
    return
}

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    variable _dispatch_loaded 1
    # Captured at source time — info script inside a proc resolves to the
    # calling script at invocation, not this file, which breaks path
    # resolution when run from a test one dir deeper.
    variable dispatch_script_dir [file dirname [file normalize [info script]]]
}
namespace eval spar::p {}
namespace eval spar::a {}

# ── Prompt templates ──────────────────────────────────────────────────
# Prompts live as standalone files under prompts/ with __PLACEHOLDER__
# markers. Loader trims the trailing newline a text editor adds, so the
# substituted result is byte-identical to the previous heredocs.
proc spar::load_prompt_template {name} {
    variable dispatch_script_dir
    set path [file join $dispatch_script_dir prompts $name]
    set fd [open $path r]
    set s [read $fd]
    close $fd
    return [string trimright $s "\n"]
}

# spar::detect_browser_cmd — Probe the host once for a usable browser and
# return the leading shell command that the agent's bash splices in front of
# a `"URL"` argument. Memoised after first call so every per-segment prompt
# build across a dispatcher run reuses the same answer instead of asking the
# worker to re-detect (issue #96).
#
# Resolution prefers the serialised-browsing arbiter (#141). browser-
# serialiser is the project's single-browser arbiter: it holds its own lock
# and, when an overseer is present on localhost:11402, delegates to the one
# process that owns the logged-in Chromium profile. The linkedin/facebook
# site skills already drive the browser through it. Routing the worker's
# ad-hoc page fetch through `browser-serialiser --dump` (the curl/WebFetch
# fallback the skill documents, which renders the DOM to stdout) makes
# workers and site skills serialise on one arbiter, instead of two
# uncoordinated locks (the old `/tmp/chromium.lock` vs the serialiser's own
# lock) colliding on the shared user-data-dir. Sibling of #125 (worker path
# bypasses the managed browser); option 1 of #141 subsumes both.
#
# Fallback is a raw headless chromium under /tmp/chromium.lock, used only
# when no serialiser is installed — in which case no site skill runs through
# one either, so there is no cross-regime collision to coordinate, and the
# /tmp/chromium.lock still serialises workers among themselves (#116). The
# command name stays bare (resolved on the worker's PATH at run time) and
# $HOME stays unexpanded, which keeps the written prompt portable across
# users.
proc spar::detect_browser_cmd {} {
    variable _browser_cmd_cache
    if {[info exists _browser_cmd_cache]} { return $_browser_cmd_cache }

    # browser-serialiser ships with the serialised-browsing skill, usually on
    # PATH (its bin/ dir). Resolve it robustly rather than hard-coding a path.
    if {[auto_execok browser-serialiser] ne ""} {
        set _browser_cmd_cache "browser-serialiser --dump -t 20"
        return $_browser_cmd_cache
    }

    set ua "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
    set lock_wrap "flock /tmp/chromium.lock timeout 10"
    set flags "--headless=new --dump-dom --user-agent=\"$ua\""

    set chromium [auto_execok chromium]
    if {$chromium ne ""} {
        if {[catch {exec readlink -f $chromium} resolved]} {
            set resolved $chromium
        }
        if {$resolved eq "/usr/bin/snap"} {
            set userdir "\$HOME/snap/chromium/common/chromium"
        } else {
            set userdir "\$HOME/.config/chromium"
        }
        set _browser_cmd_cache "$lock_wrap chromium $flags --user-data-dir=\"$userdir\""
        return $_browser_cmd_cache
    }

    error "spar::detect_browser_cmd: neither browser-serialiser nor chromium on PATH"
}

source [file join $::spar::dispatch_script_dir spar-dispatcher.tcl]

# _pool_pre_launch - bridge the Dispatcher's (row kind) pre-launch hook
# to the CLI's (tid slug idx total) step_callback. Used by
# spar-transition.tcl's dispatch_ready when --jobs=0 steps the shared
# pool one row at a time. The ordinal is counted here (each row passes
# the gate once) and the total is curried in at install, where the
# batch count is already known.
proc spar::_pool_pre_launch {step_callback total row kind} {
    variable _step_ordinal
    incr _step_ordinal
    return [{*}$step_callback $kind $row $_step_ordinal $total]
}

# spar::delete_roster_locks — best-effort removal of per-segment
# .roster.lock files (#95) after a dispatch batch completes. The lock is
# pre-deleted at the start of each segment's prep (_prepare_segment, the
# canonical home of the path); this is the matching end-of-run sweep so
# the zero-byte flock target does not linger as debris between runs.
#
# Scoped to the segments a batch actually touched, never a campaign-wide
# glob, so a concurrent dispatcher's lock on a different segment is left
# intact. Safe only once every worker holding the flock has finished:
# flock guards the inode, so deleting the path mid-run and letting a
# later worker recreate it would hand out a second, non-excluding lock.
# Best-effort: absence is fine (flock has no requirement the file persist
# between runs), so deletion errors are swallowed.
proc spar::delete_roster_locks {segment_dirs} {
    foreach segdir $segment_dirs {
        if {$segdir eq ""} continue
        catch {file delete -force -- [file join $segdir .roster.lock]}
    }
}

# spar::p::prepare_for_pool — P-phase dispatch entry. Runs per-segment
# prep (roster read, YAML validation, prompt assembly, DbC-Pre
# snapshot) and returns a list of {stem prompt_dir} tuples plus the
# resolved logs_dir, so the caller (CLI's dispatch_ready or the GUI's
# DispatchController) enqueues each row into spar::Dispatcher with
# worker=harness_run and harness_class=spar::ProfileHarness. CLI and
# GUI share this single entry point.
#
# opts dict keys:
#   campaign_file  (required) path to campaign YAML
#   logs_dir       (string, optional) override log directory base
#   segments       (list, optional) only process named segments
#   stems          (list, optional) only process rows with matching stems;
#                                    also bypasses the "profile exists" skip
#
# on_progress is used only for prep-time skipped/failed events
# emitted during _prepare_segment; row-level progress is delivered by
# the Pool's events once the worker runs.
#
# Returns: dict {logs_dir <abs path> rows {{stem pdir} ...}}
proc spar::p::prepare_for_pool {opts on_progress} {
    set campaign_file [dict getdef $opts campaign_file ""]
    if {$campaign_file eq ""} {
        error "spar::p::prepare_for_pool: opts.campaign_file is required"
    }
    set user_logs    [dict getdef $opts logs_dir ""]
    set sel_segments [dict getdef $opts segments {}]

    set cdata    [spar::load_campaign $campaign_file]
    # Version pre-flight (refuse-to-start): do not run P on a campaign whose
    # declared spec version this tool does not support. Unstamped is allowed.
    spar::assert_supported_version "campaign.yaml" [spar::campaign_version $cdata]
    set base     [dict get $cdata _base]
    set segments [spar::filter_segments [spar::campaign_segment_names $cdata] $sel_segments]

    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set logs_dir  [spar::resolve_logs_dir $campaign_file p $datestamp $user_logs]

    set rows {}
    foreach segment $segments {
        set segdir [file join $base $segment]
        if {![file exists [file join $segdir roster.tsv]]} continue
        if {[catch {
            set seg [spar::p::_prepare_segment \
                $segdir $cdata $opts $datestamp $on_progress $campaign_file $segment]
        } err]} {
            {*}$on_progress "_segment_${segment}" failed "setup error: $err"
            continue
        }
        # P's prompt_dir basename is exactly the stem (see _prepare_segment).
        foreach pdir [dict get $seg prompt_dirs] {
            lappend rows [list [file tail $pdir] $pdir]
        }
    }
    return [dict create logs_dir $logs_dir rows $rows]
}

# _prepare_segment — per-segment setup. Reads the roster, writes prompt
# dirs, captures a DbC-Pre snapshot. Returns
#   {result <per-segment result dict>
#    prompt_dirs <list of prompt dirs this invocation created>
#    pre_snapshot <dict of pre-existing roster issues>}
# "skipped profile exists" events are emitted synchronously via
# on_progress during the row loop.
proc spar::p::_prepare_segment {segment_dir cdata opts datestamp on_progress campaign_file segment_name} {
    set segment_dir [file normalize $segment_dir]

    set sel_stems [dict getdef $opts stems {}]

    set roster_path [file join $segment_dir roster.tsv]
    set profile_dir [spar::profile_dir_for_segment $segment_dir]
    set goal_path [file join $segment_dir segment.yaml]
    if {![file exists $goal_path]} {
        set goal_path [file join $segment_dir goal.md]
    }

    # Canonical per-segment roster lock path (#95). Dot-prefix so it
    # hides in `ls`; no `.tsv` infix because the lock is conceptually
    # roster-shaped, not TSV-shaped. Pre-delete any stale lock from a
    # prior run so the new run starts clean — flock semantics don't
    # require deletion, but accumulated cosmetic debris is what bit
    # the .gitignore three times in this repo's history.
    set roster_lock [file join $segment_dir .roster.lock]
    catch {file delete -force -- $roster_lock}

    variable ::spar::dispatch_script_dir
    set script_dir $::spar::dispatch_script_dir
    set spar_p [file normalize [file join $script_dir .. spar-P-profile.md]]
    set sqlite3_skill [file normalize [file join $script_dir .. SQLITE3_SKILL.md]]
    set sqlite3_skill_text ""
    if {[file exists $sqlite3_skill]} {
        set _fd [open $sqlite3_skill r]
        set sqlite3_skill_text [read $_fd]
        close $_fd
    }

    set overview [dict getdef $cdata usp_document ""]
    set antifacts [dict getdef $cdata antifacts ""]
    set appendices [dict getdef $cdata prompt_appendices [dict create]]
    set appendix_p_author [dict getdef $appendices p_author ""]

    # Limited-knowledge profiling (INVARIANTS.md I1): P reads only the roster
    # and the segment definition. The campaign usp_document/overview is NOT a
    # profiler input — it is campaign-bound (our pitch and our current facts),
    # and feeding it is what let our facts seep into reusable profiles.
    foreach {path label} [list \
        $roster_path Roster $goal_path Goal $spar_p SPAR-P] {
        if {![file exists $path]} {
            error "$label not found: $path"
        }
    }
    if {$antifacts ne "" && ![file exists $antifacts]} {
        error "Antifacts not found: $antifacts"
    }
    file mkdir $profile_dir

    # Seconds + pid so re-entry (e.g. --auto after its first iteration)
    # never shares a workdir with a previous call. Workdir stays
    # per-segment — only logs_dir collapses to campaign-wide.
    set workdir "/tmp/spar-p-[file tail $segment_dir]-$datestamp-[pid]"
    set prompts_dir [file join $workdir prompts]
    file mkdir $prompts_dir

    # Read profile_reject_if from segment.yaml. Empty list when the field
    # is absent — no audit. The harness §4.3/§4.4 audit fires only when
    # this list is non-empty.
    set segment_yaml [file join $segment_dir segment.yaml]
    set segment_data [spar::read_segment_yaml $segment_yaml]
    if {$segment_data eq ""} {
        set required_skills {}
    } else {
        # Version pre-flight (refuse-to-start): refuse a segment whose declared
        # spec version this tool does not support. Unstamped is allowed.
        spar::assert_supported_version "segment '[file tail $segment_dir]'" \
            [spar::segment_version $segment_data]
        set required_skills [spar::extract_required_skills $segment_data $segment_yaml]
    }

    set rows [spar::load_roster $roster_path]

    set count 0
    set skipped 0

    foreach row $rows {
        set name [string trim [dict getdef $row contact_name ""]]
        set org [string trim [dict getdef $row organisation ""]]
        set role [string trim [dict getdef $row role ""]]
        set phone [string trim [dict getdef $row phone ""]]
        set email [string trim [dict getdef $row email ""]]
        set linkedin [string trim [dict getdef $row linkedin_url ""]]
        set facebook [string trim [dict getdef $row facebook_url ""]]
        set date_invalid [string trim [dict getdef $row date_excluded ""]]
        set s_note [string trim [dict getdef $row s_note ""]]
        set p_note [string trim [dict getdef $row p_note ""]]
        set stem [string trim [dict getdef $row stem ""]]

        # Header fragments and invalidated rows never dispatched.
        # One of contact_name / organisation may be blank: P §4.1 resolves
        # a missing name from a known organisation, and consumer segments
        # carry named individuals with no organisation. A row with neither
        # is an undispatchable fragment.
        if {$name eq "contact_name" || $name eq "organisation"} continue
        if {$org eq "" && $name eq ""} continue
        if {$date_invalid ne ""} continue
        if {$stem eq ""} continue

        if {[llength $sel_stems] > 0 && $stem ni $sel_stems} continue

        set outfile [spar::profile_path_for_stem $segment_dir $stem]
        # Legacy path: profiles authored before #45. Still
        # counts as "profile exists" until migration completes.
        set legacy_outfile [spar::legacy_profile_path_for_stem $segment_dir $stem]

        # Skip existing profile unless caller supplied an explicit stems
        # list — then they have accepted responsibility for pre-deleting
        # the old profile and want a rebuild.
        if {[llength $sel_stems] == 0 \
            && ([file exists $outfile] || [file exists $legacy_outfile])} {
            incr skipped
            {*}$on_progress $stem skipped "profile exists"
            continue
        }

        incr count
        set pdir [file join $prompts_dir $stem]
        file mkdir $pdir

        set antifacts_line ""
        if {$antifacts ne ""} {
            set antifacts_line "Antifact checklist: read $antifacts — flag any claims not supported by these sources."
        }

        set venue_line ""
        if {[dict exists $cdata venue]} {
            set _venue [dict get $cdata venue]
            set _vaddr [dict get $_venue address]
            set _vcoord [dict get $_venue coordinate]
            set _vlat [dict get $_vcoord latitude]
            set _vlng [dict get $_vcoord longitude]
            set venue_line "Campaign venue: $_vaddr (coordinate $_vlat,$_vlng). Use OSRM for any distance assessment per SPAR-P §4.6.1; do not estimate."
        }

        set prompt [string map [list \
            __SPAR_P_PATH__   $spar_p \
            __NAME__          $name \
            __ORG__           $org \
            __ROLE__          $role \
            __PHONE__         $phone \
            __EMAIL__         $email \
            __LINKEDIN__      $linkedin \
            __FACEBOOK__      $facebook \
            __S_NOTE__        $s_note \
            __P_NOTE__        $p_note \
            __GOAL_PATH__     $goal_path \
            __CAMPAIGN_PATH__ $campaign_file \
            __SEGMENT_KEY__   $segment_name \
            __OVERVIEW__      $overview \
            __ANTIFACTS_LINE__ $antifacts_line \
            __VENUE_LINE__    $venue_line \
            __OUTFILE__       $outfile \
            __ROSTER_PATH__   $roster_path \
            __STEM__          $stem \
            __SQLITE3_SKILL__ $sqlite3_skill_text \
            __BROWSER_CMD__   [spar::detect_browser_cmd] \
            __ROSTER_LOCK__   $roster_lock \
        ] [spar::load_prompt_template spar-p.txt]]

        # p_author (campaign prompt_appendices) is NOT appended to the profiler:
        # it is campaign-bound guidance, and the profiler operates on the segment
        # definition alone (INVARIANTS.md I1). Relevance guidance that P needs
        # lives in segment.yaml rating_rubric, a campaign-independent home.

        set fd [open [file join $pdir prompt.txt] w]
        puts $fd $prompt
        close $fd

        set fd [open [file join $pdir meta.env] w]
        puts $fd "STEM=\"$stem\""
        puts $fd "OUTFILE=\"$outfile\""
        puts $fd "ROSTER_PATH=\"$roster_path\""
        # Canonical per-segment lock path, so a cost-cap finalise resume
        # (ProfileHarness::do_finalise_after_cost_kill) serialises its roster
        # write on the same lock the worker prompt uses.
        puts $fd "ROSTER_LOCK=\"$roster_lock\""
        puts $fd "REQUIRED_SKILLS=\"[join $required_skills { }]\""
        puts $fd "CONTACT_NAME=\"$name\""
        puts $fd "CONTACT_ORG=\"$org\""
        puts $fd "CONTACT_EMAIL=\"$email\""
        # Per-campaign cost-cap override (spar-harness.tcl reads
        # WORKER_COST_CAP_USD from meta.env). The profile path previously
        # never wrote it, so campaign.yaml could not tune the cap the
        # harness comment promised; this supplies it when the campaign
        # sets worker_cost_cap_usd. Empty -> harness default applies.
        set _cost_cap [dict getdef $cdata worker_cost_cap_usd ""]
        if {$_cost_cap ne ""} {
            puts $fd "WORKER_COST_CAP_USD=$_cost_cap"
        }
        close $fd
    }

    set result [dict create \
        segment [file tail $segment_dir] \
        count $count \
        skipped $skipped \
        prompts_dir $prompts_dir]

    # DbC-Pre: snapshot roster issues so DbC-Post can attribute new ones
    # to the agent that just ran. Skip when count==0: nothing will run.
    set pre_snapshot [dict create]
    if {$count > 0} {
        if {[catch {
            # DbC-Pre bypass: fresh State so any Phase B cache cannot
            # carry stale entries into the snapshot the post-pass diffs against.
            set _pre_state [spar::State new]
            set _pre_contacts [$_pre_state classify_segment $segment_dir]
            $_pre_state destroy
            foreach _issue [spar::validate_roster $_pre_contacts] {
                set _cn [dict get $_issue contact_name]
                set _cd [dict get $_issue code]
                dict set pre_snapshot "${_cn}|${_cd}" 1
            }
        } _snap_err]} {
            {*}$on_progress "_dbc_pre" warning "snapshot failed: $_snap_err"
        }
    }

    set prompt_dirs [lsort [glob -nocomplain -type d [file join $prompts_dir *]]]

    return [dict create \
        result $result \
        prompt_dirs $prompt_dirs \
        pre_snapshot $pre_snapshot \
        roster_lock $roster_lock]
}

# ════════════════════════════════════════════════════════════════════════
# spar::a::prepare_for_pool — SPAR-A dispatch entry (approach dispatch).
# ════════════════════════════════════════════════════════════════════════
#
# Returns {logs_dir <path> rows {{stem pdir} ...} result <r>} so the
# caller (CLI's dispatch_ready or the GUI's DispatchController) enqueues
# each row into spar::Dispatcher with worker=harness_run and
# harness_class=spar::ApproachHarness. CLI and GUI share this single
# entry point.
#
# opts dict keys:
#   campaign_file  (required) path to campaign YAML
#   logs_dir       (string, optional) override log directory
#   segments       (list, optional) only process named segments
#   stems          (list, optional) only process rows with matching stems
proc spar::a::prepare_for_pool {opts on_progress} {
    set prep [spar::a::_build_prompts $opts $on_progress]
    set result      [dict get $prep result]
    set fresh_pdirs [dict get $prep prompt_dirs]
    set logs_dir    [dict get $prep logs_dir]
    set stem_map    [dict get $prep stem_map]
    set rows {}
    foreach pdir $fresh_pdirs {
        set bn [file tail $pdir]
        if {[dict exists $stem_map $bn]} {
            lappend rows [list [dict get $stem_map $bn] $pdir]
        }
    }
    return [dict create logs_dir $logs_dir rows $rows result $result]
}

# _build_prompts — A-phase per-segment prep. Returns {result
# <result-dict> prompt_dirs <list> logs_dir <path> stem_map <slug →
# stem>}; prepare_for_pool repackages prompt_dirs into pool rows.
proc spar::a::_build_prompts {opts on_progress} {
    set campaign_file [dict getdef $opts campaign_file ""]
    if {$campaign_file eq ""} {
        error "spar::a::_build_prompts: opts.campaign_file is required"
    }
    set user_logs [dict getdef $opts logs_dir ""]
    set sel_segments [dict getdef $opts segments {}]
    set sel_stems [dict getdef $opts stems {}]

    set cdata [spar::load_campaign $campaign_file]
    # Version pre-flight (refuse-to-start): do not run A on a campaign whose
    # declared spec version this tool does not support. Unstamped is allowed.
    spar::assert_supported_version "campaign.yaml" [spar::campaign_version $cdata]
    set base [dict get $cdata _base]

    set sender_name [dict get $cdata sender name]
    set sender_role [dict get $cdata sender role]
    set sender_email [dict get $cdata sender email]
    set sender_org [dict getdef [dict get $cdata sender] organisation ""]
    set language [dict get $cdata language]
    # approach_filename in campaign YAML is retained for backwards compat
    # but no longer consulted: the authoritative slug is the roster stem,
    # and approach files are always written to {stem}.yaml so
    # classify_segment can find them by the same key it looks up profiles by.
    variable ::spar::dispatch_script_dir
    set script_dir $::spar::dispatch_script_dir
    set method [file normalize [file join $script_dir .. spar-A-approach.md]]
    set appendices [dict getdef $cdata prompt_appendices [dict create]]
    set appendix_a_author [dict getdef $appendices a_author ""]
    set appendix_a_challenger [dict getdef $appendices a_challenger ""]
    set appendix_a_assembly [dict getdef $appendices a_assembly ""]
    set overview [dict get $cdata usp_document]
    set antifacts [dict getdef $cdata antifacts ""]
    set campaign_principles [dict getdef $cdata campaign_principles ""]
    set a_max_passes_ceiling [dict getdef $cdata a_max_passes 3]
    set segments [spar::filter_segments [spar::campaign_segment_names $cdata] $sel_segments]

    # Campaign filters (issue #41 in-scope-channel gate replaces
    # filter.require_email). A roster row is dispatchable for A when it
    # has at least one populated field for a channel the campaign declares.
    set filter [dict getdef $cdata filter [dict create]]
    set filter_skip_excluded [string is true -strict [dict getdef $filter skip_excluded true]]
    set filter_min_star [dict getdef $filter min_star 0]
    set filter_require_profile [string is true -strict [dict getdef $filter require_profile false]]
    set in_scope_channels [spar::campaign_in_scope_channels $cdata]

    set lang_inst [spar::lang_instruction $language]

    if {![file exists $method]} {
        error "Method file not found: $method"
    }
    if {![file exists $overview]} {
        error "Overview file not found: $overview"
    }
    if {$antifacts ne "" && ![file exists $antifacts]} {
        error "Antifacts file not found: $antifacts"
    }
    if {$campaign_principles ne "" && ![file exists $campaign_principles]} {
        error "Campaign principles not found: $campaign_principles"
    }

    # Seconds resolution + pid so repeat calls within the same invocation
    # (--auto's state-machine loop) never share a workdir with a previous
    # run whose prompt dirs would be re-dispatched.
    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set workdir "/tmp/spar-a-$datestamp-[pid]"
    set prompts_dir [file join $workdir prompts]
    file mkdir $prompts_dir

    set logs_dir [spar::resolve_logs_dir $campaign_file a $datestamp $user_logs]

    set campaign_name [dict getdef $cdata campaign ""]
    set filter_desc "in_scope_channels=\{[join $in_scope_channels { }]\} skip_excluded=$filter_skip_excluded min_star=$filter_min_star require_profile=$filter_require_profile"

    set sender_line "$sender_name, $sender_role"
    if {$sender_org ne ""} {
        append sender_line ", $sender_org"
    }
    append sender_line ", using $sender_email"

    set count 0
    set skipped 0
    set fresh_prompt_dirs {}
    set stem_map [dict create]

    foreach segment $segments {
        set roster_path [file join $base $segment roster.tsv]
        set goal_path [file join $base $segment segment.yaml]
        if {![file exists $goal_path]} {
            set goal_path [file join $base $segment goal.md]
        }
        set seg_dir [file join $base $segment]
        set profile_dir [spar::profile_dir_for_segment $seg_dir]

        if {![file exists $roster_path]} continue
        if {![file exists $goal_path]} continue

        # Version pre-flight (refuse-to-start): refuse a segment whose declared
        # spec version this tool does not support. Unstamped is allowed.
        set _seg_data [spar::read_segment_yaml [file join $seg_dir segment.yaml]]
        if {$_seg_data ne ""} {
            spar::assert_supported_version "segment '$segment'" \
                [spar::segment_version $_seg_data]
        }

        file mkdir [spar::approach_dir_for_segment $seg_dir]

        set rows [spar::load_roster $roster_path]

        foreach row $rows {
            set org [string trim [dict getdef $row organisation ""]]
            set name [string trim [dict getdef $row contact_name ""]]
            set role [string trim [dict getdef $row role ""]]
            set phone [string trim [dict getdef $row phone ""]]
            set email [string trim [dict getdef $row email ""]]
            set linkedin [string trim [dict getdef $row linkedin_url ""]]
            set facebook [string trim [dict getdef $row facebook_url ""]]
            set p_note [string trim [dict getdef $row p_note ""]]
            set star [string trim [dict getdef $row star_rating ""]]
            set s_note [string trim [dict getdef $row s_note ""]]
            set date_invalid [string trim [dict getdef $row date_excluded ""]]
            set stem [string trim [dict getdef $row stem ""]]

            if {$org eq "organisation" || $name eq ""} continue
            if {$org eq ""} continue

            if {[llength $sel_stems] > 0 && $stem ni $sel_stems} continue

            # SSOT for approach-dispatch gates (#56): shared with
            # spar::State's transition_eligible T2 so the UI tree and this
            # loop can never disagree about who is dispatchable.
            set gate_reason [spar::_approach_dispatch_gate $row $cdata]
            if {$gate_reason ne ""} {
                incr skipped
                set label [expr {$stem ne "" \
                    ? $stem \
                    : "[spar::slugify $name]-[spar::slugify $org]"}]
                {*}$on_progress $label skipped $gate_reason
                continue
            }

            set slug_name [spar::slugify $name]
            set slug_org [spar::slugify $org]

            # Approach file always {stem}.yaml (stem is authoritative —
            # classify_segment reads it from the same path). Rows without
            # a stem are sweep artefacts and cannot be approached.
            if {$stem eq ""} {
                incr skipped
                {*}$on_progress "${slug_name}-${slug_org}" skipped "no stem"
                continue
            }
            set outfile [spar::approach_path_for_stem $seg_dir $stem]

            if {[file exists $outfile]} {
                incr skipped
                {*}$on_progress $stem skipped "approach exists"
                continue
            }

            # Profile lookup — {stem}.md (post #45).
            # Legacy profile-{stem}.md files are ignored by the dispatcher;
            # rename them by hand to {stem}.md if encountered.
            set profile_path ""
            if {$stem ne ""} {
                set candidate [spar::profile_path_for_stem $seg_dir $stem]
                if {[file exists $candidate]} {
                    set profile_path $candidate
                }
            }
            set max_passes 1
            if {$profile_path ne ""} {
                set profile_a1_instruction "3. Profile: $profile_path"
                set fd [open $profile_path r]
                set profile_content [read $fd]
                close $fd
                set max_passes [spar::get_max_passes $profile_path]
            } else {
                if {$filter_require_profile} {
                    incr skipped
                    {*}$on_progress $stem skipped "no profile"
                    continue
                }
                set profile_a1_instruction "3. No profile document exists for this contact. Treat as yield 0 (no data points). Use the roster p_note and s_note below as the primary source for angle selection and drafting."
                set profile_content "No profile document. Roster notes only:
p_note: $p_note
s_note: $s_note"
                set max_passes 1
            }
            # Apply campaign-level hard ceiling (a_max_passes, default 3).
            if {$max_passes > $a_max_passes_ceiling} {
                set max_passes $a_max_passes_ceiling
            }

            set channel_d [spar::channel_desc $linkedin $phone]

            set contact_summary "Name: $name
Organisation: $org
Role: $role
Phone: $phone
Email: $email
LinkedIn: $linkedin
Facebook: $facebook
Star rating: $star
p_note: $p_note
s_note: $s_note"

            incr count
            set prompt_slug [format "%03d-%s-%s" $count $slug_name $slug_org]
            set prompt_dir [file join $prompts_dir $prompt_slug]
            file mkdir $prompt_dir
            lappend fresh_prompt_dirs $prompt_dir
            dict set stem_map $prompt_slug $stem

            set fd [open [file join $prompt_dir meta.env] w]
            puts $fd "MAX_PASSES=$max_passes"
            puts $fd "OUTFILE=$outfile"
            puts $fd "METHOD=$method"
            puts $fd "OVERVIEW=$overview"
            puts $fd "ANTIFACTS=$antifacts"
            puts $fd "GOAL=$goal_path"
            puts $fd "CONTACT_SUMMARY=$name | $org | $segment"
            puts $fd "CONTACT_NAME=$name"
            puts $fd "ROSTER_EMAIL=$email"
            puts $fd "ROSTER_ORGANISATION=$org"
            puts $fd "CHALLENGER_MODEL=sonnet"
            close $fd

            if {$appendix_a_assembly ne ""} {
                set fd [open [file join $prompt_dir appendix-assembly.txt] w]
                puts -nonewline $fd $appendix_a_assembly
                close $fd
            }

            set file_items "1. Method: $method — read §4.1 through §4.5 (warmth, channel, language, angle, draft). Skip §4.6 (spar) — that is handled separately.
2. Organisation overview: $overview — read in full. This is the ground truth about the organisation. The campaign plan block (the segments.$segment block in $campaign_file) lists which USPs apply to this segment and whether each is functional or emotional. Use those USPs, do not invent your own from the overview.
$profile_a1_instruction
4. Campaign plan block: read the \"segments.$segment\" block in $campaign_file (campaign.yaml) — \"message_goal\" for the specific objective this message must achieve (e.g. secure a FAM visit, collect a roster expression of interest); \"objective\" for the long-term commercial goal, not what this message asks for; \"first_ask\" for approach style guidance; and the USP framings. If the block has subsegments, determine which applies to this contact and use its overrides where present. The segment file $goal_path holds only the population definition (discovery_criteria, rating_rubric)."
            set item_num 5
            if {$antifacts ne ""} {
                append file_items "
${item_num}. Antifact checklist: $antifacts — check your draft against every false claim listed here before outputting."
                incr item_num
            }
            if {$campaign_principles ne ""} {
                append file_items "
${item_num}. Campaign principles: $campaign_principles — read the \"Profile-informed approaches\" section. Do not ask the recipient for information already captured in their profile."
            }

            set author_prompt [string map [list \
                __FILE_ITEMS__       $file_items \
                __CONTACT_SUMMARY__  $contact_summary \
                __CHANNEL_DESC__     $channel_d \
                __SENDER_LINE__      $sender_line \
                __LANG_INSTRUCTION__ $lang_inst \
            ] [spar::load_prompt_template spar-a-author.txt]]

            set fd [open [file join $prompt_dir author-draft.txt] w]
            puts $fd $author_prompt
            if {$appendix_a_author ne ""} {
                puts $fd ""
                puts $fd $appendix_a_author
            }
            close $fd

            set factcheck_files "Files to read:
1. $overview
2. $campaign_file (the segments.$segment plan block)"
            if {$antifacts ne ""} {
                append factcheck_files "
3. $antifacts"
            }

            if {$antifacts ne "" || [file exists $overview]} {
                set factcheck_section [string map [list \
                    __FACTCHECK_FILES__ $factcheck_files \
                ] [spar::load_prompt_template spar-a-factcheck.txt]]
            } else {
                set factcheck_section "## Step 2: Verdict

Emit exactly one of these lines as the very last line of your output:"
            }

            # __DRAFT_PLACEHOLDER__ is intentionally left in place — the
            # harness substitutes it after Stage 1 produces a draft.
            set challenger_prompt [string map [list \
                __PROFILE_CONTENT__   $profile_content \
                __FACTCHECK_SECTION__ $factcheck_section \
            ] [spar::load_prompt_template spar-a-challenger.txt]]

            set fd [open [file join $prompt_dir challenger-template.txt] w]
            puts $fd $challenger_prompt
            if {$appendix_a_challenger ne ""} {
                puts $fd ""
                puts $fd $appendix_a_challenger
            }
            close $fd

            set fd [open [file join $prompt_dir profile-content.txt] w]
            puts $fd $profile_content
            close $fd
        }
    }

    set result [dict create \
        campaign $campaign_name \
        sender_name $sender_name \
        sender_email $sender_email \
        language $language \
        segments $segments \
        filter_desc $filter_desc \
        count $count \
        skipped $skipped \
        prompts_dir $prompts_dir \
        logs_dir $logs_dir]

    return [dict create \
        result       $result \
        prompt_dirs  $fresh_prompt_dirs \
        logs_dir     $logs_dir \
        stem_map     $stem_map]
}

package provide spar-dispatch 1.0

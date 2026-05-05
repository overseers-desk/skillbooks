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

# spar::detect_browser_cmd — Probe the host once for a usable headless
# browser and return the leading shell command that the agent's bash
# splices in front of `"URL" 2>/dev/null`. Memoised after first call so
# every per-segment prompt build across a dispatcher run reuses the same
# answer instead of asking the worker to re-detect (issue #96).
#
# Resolution: chromium (snap → $HOME/snap/.../chromium profile;
# non-snap → $HOME/.config/chromium); else error. $HOME stays unexpanded
# in the returned string — the agent's bash expands it at run time,
# which keeps the prompt file portable across users.
proc spar::detect_browser_cmd {} {
    variable _browser_cmd_cache
    if {[info exists _browser_cmd_cache]} { return $_browser_cmd_cache }

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

    error "spar::detect_browser_cmd: chromium not on PATH"
}

source [file join $::spar::dispatch_script_dir spar-dispatcher.tcl]

# spar::run_through_pool — generic CLI adapter. Construct a fresh
# spar::Dispatcher, enqueue every (row, worker_proc, row_opts) tuple,
# wire row events back through the legacy on_progress / on_complete
# callbacks, and tear down when the pool drains. Runners (P, A, T6,
# T7) call this so all dispatch goes through one architecture.
#
# Args:
#   jobs            global concurrency cap for this batch
#   tid             T-id (used by step_callback signature only)
#   worker_proc     name of the initcmd-defined worker (e.g.
#                   "harness_run", "ses_send", "imap_poll")
#   rows            list of {stem opts} pairs; opts is the per-row
#                   dict the worker proc consumes
#   result          opaque result dict passed back through on_complete
#   on_progress     {slug status message} callback
#   on_complete     {done failed result} callback (fires once)
#   step_callback   optional {tid slug idx total} → continue|abort
#                   callback fired before each row is posted
#
# The completion callback is called exactly once, after every row has
# reached a terminal state (done / failed / cancelled). cancelled rows
# count as skipped, not failed — they were aborted by the user.
namespace eval ::spar { variable pool_runs [dict create] }

proc spar::run_through_pool {jobs tid worker_proc rows result \
                              on_progress on_complete \
                              {step_callback ""}} {
    variable pool_runs
    if {[llength $rows] == 0} {
        {*}$on_complete 0 0 $result
        return
    }
    set total [llength $rows]
    set run_id "run_[clock microseconds]_[expr {int(rand() * 100000)}]"
    set st [dict create \
        done     0 \
        failed   0 \
        skipped  0 \
        seen     0 \
        total    $total \
        result   $result \
        progress $on_progress \
        complete $on_complete]

    set disp [spar::Dispatcher new $jobs]
    dict set st dispatcher $disp
    dict set pool_runs $run_id $st

    # Step gate (CLI --jobs=0). Translate the legacy step_callback
    # signature (tid slug idx total) onto the Dispatcher's
    # pre_post hook (row tid idx total). slug == row in the CLI
    # path; the runner uses the stem as the row id.
    if {$step_callback ne ""} {
        $disp set_pre_post_callback \
            [list ::spar::_pool_pre_post $step_callback]
    }

    $disp subscribe row-done   [list ::spar::_pool_on_done   $run_id]
    $disp subscribe row-failed [list ::spar::_pool_on_failed $run_id]
    $disp subscribe row-state  [list ::spar::_pool_on_state  $run_id]

    # Pause until every row is enqueued so step_callback receives the
    # final total, not a growing one mid-batch.
    $disp pause_queue
    foreach pair $rows {
        lassign $pair stem row_opts
        $disp enqueue $stem $tid $worker_proc $row_opts
        # Mirror the legacy `[START] slug` line at enqueue time. The
        # GUI fires this on row-running; the CLI fires it here so the
        # output ordering matches the legacy queue (one [START] per
        # row, in enqueue order).
        {*}$on_progress $stem started ""
    }
    $disp resume_queue
}

# _pool_pre_post — bridge the Dispatcher's (row tid idx total)
# pre-post hook to the CLI's (tid slug idx total) step_callback.
proc spar::_pool_pre_post {step_callback row tid idx total} {
    return [{*}$step_callback $tid $row $idx $total]
}

proc spar::_pool_on_state {run_id row to_state} {
    variable pool_runs
    if {![dict exists $pool_runs $run_id]} return
    if {$to_state ni {done failed cancelled}} return
    set st [dict get $pool_runs $run_id]
    if {$to_state eq "cancelled"} {
        dict incr st skipped
        {*}[dict get $st progress] $row skipped "cancelled"
    }
    dict incr st seen
    dict set pool_runs $run_id $st
    if {[dict get $st seen] >= [dict get $st total]} {
        # Defer finish so the row-state subscriber list isn't mutated
        # while we're iterating it.
        after idle [list ::spar::_pool_finish $run_id]
    }
}

proc spar::_pool_on_done {run_id row result} {
    variable pool_runs
    if {![dict exists $pool_runs $run_id]} return
    set st [dict get $pool_runs $run_id]
    dict incr st done
    dict set pool_runs $run_id $st
    set msg ""
    catch {set msg [dict get $result message_id]}
    {*}[dict get $st progress] $row done $msg
}

proc spar::_pool_on_failed {run_id row reason} {
    variable pool_runs
    if {![dict exists $pool_runs $run_id]} return
    set st [dict get $pool_runs $run_id]
    dict incr st failed
    dict set pool_runs $run_id $st
    {*}[dict get $st progress] $row failed $reason
}

# spar::_cleanup_locks_then_call — wrapped on_complete used by p::run.
# Deletes any roster lock files from the segments that participated in
# the batch, then forwards to the caller's on_complete. Best-effort:
# absence is fine, deletion errors are ignored, because flock does not
# require the file to exist between runs (#95).
proc spar::_cleanup_locks_then_call {lock_paths user_cb done failed result} {
    foreach p $lock_paths {
        if {$p eq ""} continue
        catch {file delete -force -- $p}
    }
    {*}$user_cb $done $failed $result
}

proc spar::_pool_finish {run_id} {
    variable pool_runs
    if {![dict exists $pool_runs $run_id]} return
    set st [dict get $pool_runs $run_id]
    dict unset pool_runs $run_id
    set d  [dict get $st done]
    set f  [dict get $st failed]
    set r  [dict get $st result]
    set cb [dict get $st complete]
    set disp [dict get $st dispatcher]
    catch {$disp destroy}
    {*}$cb $d $f $r
}

# ════════════════════════════════════════════════════════════════════════
# spar::p::run — SPAR-P phase runner (profile dispatch).
# ════════════════════════════════════════════════════════════════════════
#
# opts dict keys:
#   campaign_file  (required) path to campaign YAML
#   dry_run        (bool, default 0) write prompts but don't spawn harnesses
#   jobs           (int, default 4)  max concurrent harnesses across the
#                                    whole campaign (global cap — see
#                                    _prepare_segment for setup split)
#   logs_dir       (string, optional) override log directory base
#   segments       (list, optional) only process named segments
#   stems          (list, optional) only process rows with matching stems;
#                                    also bypasses the "profile exists" skip
#
# on_progress — callback prefix: {slug status message}
#               status ∈ {started, done, failed, skipped, warning}
# on_complete — callback prefix: {total_done total_failed result}
#
# Setup (roster read, YAML validation, prompt assembly, DbC-Pre snapshot)
# runs per-segment in _prepare_segment and returns a prompt_dirs list.
# p::run aggregates those lists and hands one flat list to a single
# Dispatcher, so `jobs=N` bounds total live harnesses across the campaign.
# Same shape as spar::a::run.

proc spar::p::run {opts on_progress on_complete} {
    set campaign_file [spar::dict_get_default $opts campaign_file ""]
    if {$campaign_file eq ""} {
        error "spar::p::run: opts.campaign_file is required"
    }
    set dry_run [spar::dict_get_default $opts dry_run 0]
    set jobs [spar::dict_get_default $opts jobs 4]
    set user_logs [spar::dict_get_default $opts logs_dir ""]
    set tid [spar::dict_get_default $opts tid ""]
    set step_callback [spar::dict_get_default $opts step_callback ""]

    set cdata [spar::load_campaign $campaign_file]
    set base [dict get $cdata _base]
    set segments [dict get $cdata segments]

    set sel_segments [spar::dict_get_default $opts segments {}]
    set segments [spar::filter_segments $segments $sel_segments]

    # Per-slug log files inside logs_dir are named by stem, so they
    # don't collide unless two segments share a stem (documented
    # limitation).
    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set logs_dir [spar::resolve_logs_dir $campaign_file p $datestamp $user_logs]

    # Gather prompt_dirs across segments and build a slug → per-segment
    # context map for DbC-Post attribution. _prepare_segment emits
    # "skipped profile exists" events synchronously through on_progress.
    set all_prompt_dirs {}
    set slug_ctx [dict create]
    set per_seg_results {}
    set lock_paths {}
    set total_count 0
    set total_skipped 0

    foreach segment $segments {
        set segdir [file join $base $segment]
        if {![file exists [file join $segdir roster.tsv]]} continue
        if {[catch {
            set seg [spar::p::_prepare_segment \
                $segdir $cdata $opts $datestamp $on_progress]
        } err]} {
            {*}$on_progress "_segment_${segment}" failed "setup error: $err"
            continue
        }
        lappend per_seg_results [dict get $seg result]
        lappend lock_paths      [dict get $seg roster_lock]
        incr total_count   [dict get $seg result count]
        incr total_skipped [dict get $seg result skipped]
        foreach pdir [dict get $seg prompt_dirs] {
            lappend all_prompt_dirs $pdir
            dict set slug_ctx [file tail $pdir] \
                [list $segdir [dict get $seg pre_snapshot]]
        }
    }

    set agg_result [dict create \
        campaign [spar::dict_get_default $cdata campaign ""] \
        count $total_count \
        skipped $total_skipped \
        logs_dir $logs_dir \
        segments [llength $per_seg_results] \
        results $per_seg_results]

    if {$dry_run || [llength $all_prompt_dirs] == 0} {
        {*}$on_complete 0 0 $agg_result
        return
    }

    set wrapped_progress [list spar::p::_dbc_post_progress \
        $on_progress $slug_ctx]

    # Build {stem opts} pairs. Stem == basename of the prompt_dir.
    # The Pool's harness_run worker drives spar::ProfileHarness end-to-
    # end for each row.
    set rows {}
    foreach pdir $all_prompt_dirs {
        set stem [file tail $pdir]
        lappend rows [list $stem [dict create \
            prompt_dir    $pdir \
            log_dir       $logs_dir \
            harness_class spar::ProfileHarness]]
    }

    # Wrap on_complete so the batch's roster locks are cleaned at
    # end-of-run (#95). The user's on_complete fires after deletion;
    # delete is best-effort (catch) since flock has no semantic
    # requirement for the file to be present.
    set wrapped_complete [list spar::_cleanup_locks_then_call \
        $lock_paths $on_complete]

    spar::run_through_pool $jobs $tid harness_run $rows $agg_result \
        $wrapped_progress $wrapped_complete $step_callback
    return
}

# spar::p::prepare_for_pool — GUI entry point. Runs the same
# per-segment prep as spar::p::run, but returns a list of
# {stem prompt_dir} tuples (plus the resolved logs_dir) so the GUI's
# DispatchController can enqueue each row into spar::Dispatcher with
# worker=harness_run and harness_class=spar::ProfileHarness directly,
# bypassing the spar::run_through_pool wrapper that the CLI uses for
# its callback-shape contract.
#
# opts has the same shape as spar::p::run (campaign_file, segments,
# stems). on_progress is used only for prep-time skipped/failed events
# emitted during _prepare_segment; row-level progress is delivered by
# the Pool's events once the worker runs.
#
# Returns: dict {logs_dir <abs path> rows {{stem pdir} ...}}
proc spar::p::prepare_for_pool {opts on_progress} {
    set campaign_file [spar::dict_get_default $opts campaign_file ""]
    if {$campaign_file eq ""} {
        error "spar::p::prepare_for_pool: opts.campaign_file is required"
    }
    set user_logs    [spar::dict_get_default $opts logs_dir ""]
    set sel_segments [spar::dict_get_default $opts segments {}]

    set cdata    [spar::load_campaign $campaign_file]
    set base     [dict get $cdata _base]
    set segments [spar::filter_segments [dict get $cdata segments] $sel_segments]

    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set logs_dir  [spar::resolve_logs_dir $campaign_file p $datestamp $user_logs]

    set rows {}
    foreach segment $segments {
        set segdir [file join $base $segment]
        if {![file exists [file join $segdir roster.tsv]]} continue
        if {[catch {
            set seg [spar::p::_prepare_segment \
                $segdir $cdata $opts $datestamp $on_progress]
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
proc spar::p::_prepare_segment {segment_dir cdata opts datestamp on_progress} {
    set segment_dir [file normalize $segment_dir]

    set sel_stems [spar::dict_get_default $opts stems {}]

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

    set overview [spar::dict_get_default $cdata usp_document]
    set antifacts [spar::dict_get_default $cdata antifacts]
    set appendices [spar::dict_get_default $cdata prompt_appendices [dict create]]
    set appendix_p_author [spar::dict_get_default $appendices p_author ""]

    foreach {path label} [list \
        $roster_path Roster $goal_path Goal $spar_p SPAR-P $overview Overview] {
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
        set required_skills [spar::extract_required_skills $segment_data $segment_yaml]
    }

    set rows [spar::load_roster $roster_path]

    set count 0
    set skipped 0

    foreach row $rows {
        set name [string trim [spar::dict_get_default $row contact_name]]
        set org [string trim [spar::dict_get_default $row organisation]]
        set role [string trim [spar::dict_get_default $row role]]
        set phone [string trim [spar::dict_get_default $row phone]]
        set email [string trim [spar::dict_get_default $row email]]
        set linkedin [string trim [spar::dict_get_default $row linkedin_url]]
        set facebook [string trim [spar::dict_get_default $row facebook_url]]
        set date_invalid [string trim [spar::dict_get_default $row date_excluded]]
        set s_note [string trim [spar::dict_get_default $row s_note]]
        set p_note [string trim [spar::dict_get_default $row p_note]]
        set stem [string trim [spar::dict_get_default $row stem ""]]

        # Header fragments and invalidated rows never dispatched.
        # Blank contact_name is allowed through: P §4.1 resolves the name
        # when organisation is identified but no individual is yet known.
        if {$name eq "contact_name" || $name eq "organisation"} continue
        if {$org eq ""} continue
        if {$date_invalid ne ""} continue
        if {$stem eq ""} continue

        if {[llength $sel_stems] > 0 && $stem ni $sel_stems} continue

        set outfile [spar::profile_path_for_stem $segment_dir $stem]
        # Legacy path: profiles authored before SmartLayer/aesop#45. Still
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

        if {$appendix_p_author ne ""} {
            append prompt "\n\n$appendix_p_author"
        }

        set fd [open [file join $pdir prompt.txt] w]
        puts $fd $prompt
        close $fd

        set fd [open [file join $pdir meta.env] w]
        puts $fd "STEM=\"$stem\""
        puts $fd "OUTFILE=\"$outfile\""
        puts $fd "ROSTER_PATH=\"$roster_path\""
        puts $fd "REQUIRED_SKILLS=\"[join $required_skills { }]\""
        puts $fd "CONTACT_NAME=\"$name\""
        puts $fd "CONTACT_ORG=\"$org\""
        puts $fd "CONTACT_EMAIL=\"$email\""
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

# on-progress wrapper that runs DbC-Post validation when a slug completes.
# slug_ctx: dict slug → {segment_dir pre_snapshot}. Emits new roster
# issues (not in the slug's pre_snapshot) as severity "warning" with
# code prefix "regression:".
proc spar::p::_dbc_post_progress {orig_progress slug_ctx slug status message} {
    {*}$orig_progress $slug $status $message
    if {$status ne "done"} return
    if {![dict exists $slug_ctx $slug]} return
    lassign [dict get $slug_ctx $slug] segment_dir pre_snapshot
    if {[catch {
        # DbC-Post bypass: fresh State, same rationale as the pre snapshot.
        set _post_state [spar::State new]
        set _post_contacts [$_post_state classify_segment $segment_dir]
        $_post_state destroy
        set _post_issues [spar::validate_roster $_post_contacts]
    } _post_err]} {
        {*}$orig_progress $slug warning "DbC-Post validate_roster failed: $_post_err"
        return
    }
    foreach _issue $_post_issues {
        set _cn [dict get $_issue contact_name]
        set _cd [dict get $_issue code]
        set _key "${_cn}|${_cd}"
        if {[dict exists $pre_snapshot $_key]} continue
        set _msg [dict get $_issue message]
        {*}$orig_progress $slug warning "regression: $_cd ($_cn): $_msg"
    }
}

# ════════════════════════════════════════════════════════════════════════
# spar::a::run — SPAR-A phase runner (approach dispatch).
# ════════════════════════════════════════════════════════════════════════
#
# opts dict keys:
#   campaign_file  (required) path to campaign YAML
#   dry_run        (bool, default 0)
#   jobs           (int, default 8)
#   logs_dir       (string, optional) override log directory
#   segments       (list, optional) only process named segments
#   stems          (list, optional) only process rows with matching stems
#
# on_progress — callback prefix: {slug status message}
#               status ∈ {started, done, failed, skipped}
# on_complete — callback prefix: {total_done total_failed result}

proc spar::a::run {opts on_progress on_complete} {
    set prep [spar::a::_build_prompts $opts $on_progress]
    set result        [dict get $prep result]
    set fresh_pdirs   [dict get $prep prompt_dirs]
    set logs_dir      [dict get $prep logs_dir]
    set count         [dict get $result count]

    set dry_run       [spar::dict_get_default $opts dry_run 0]
    set jobs          [spar::dict_get_default $opts jobs 8]
    set tid           [spar::dict_get_default $opts tid ""]
    set step_callback [spar::dict_get_default $opts step_callback ""]

    if {$dry_run || $count == 0} {
        {*}$on_complete $count 0 $result
        return $result
    }

    # Dispatch only the prompt dirs we created this invocation — never glob
    # the workdir, since a previous call within the same process may have
    # left prompt dirs there and the harness would re-run them.
    set prompt_dirs $fresh_pdirs
    # Shuffle for load balancing (Fisher-Yates).
    set n [llength $prompt_dirs]
    for {set i [expr {$n - 1}]} {$i > 0} {incr i -1} {
        set j [expr {int(rand() * ($i + 1))}]
        set tmp [lindex $prompt_dirs $i]
        lset prompt_dirs $i [lindex $prompt_dirs $j]
        lset prompt_dirs $j $tmp
    }

    # A-phase prompt-dir basenames are NNN-name-org slugs, not stems.
    # The Pool worker doesn't care what the row id is — it's the
    # progress-reporting key. Use the basename so on_progress messages
    # carry the same slug the operator sees on disk.
    set rows {}
    foreach pdir $prompt_dirs {
        set slug [file tail $pdir]
        lappend rows [list $slug [dict create \
            prompt_dir    $pdir \
            log_dir       $logs_dir \
            harness_class spar::ApproachHarness]]
    }

    spar::run_through_pool $jobs $tid harness_run $rows $result \
        $on_progress $on_complete $step_callback
    return $result
}

# spar::a::prepare_for_pool — Phase-3 GUI entry point. Same prep as
# spar::a::run, returns {logs_dir <path> rows {{stem pdir} ...}} so the
# DispatchController can enqueue each row into spar::Dispatcher with
# worker=harness_run and harness_class=spar::ApproachHarness.
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

# _build_prompts — A-phase per-segment prep. Lifted verbatim from the
# previous body of spar::a::run so the runner and prepare_for_pool share
# one path. Returns {result <result-dict> prompt_dirs <list> logs_dir <path>
# stem_map <slug → stem>}.
proc spar::a::_build_prompts {opts on_progress} {
    set campaign_file [spar::dict_get_default $opts campaign_file ""]
    if {$campaign_file eq ""} {
        error "spar::a::_build_prompts: opts.campaign_file is required"
    }
    set user_logs [spar::dict_get_default $opts logs_dir ""]
    set sel_segments [spar::dict_get_default $opts segments {}]
    set sel_stems [spar::dict_get_default $opts stems {}]

    set cdata [spar::load_campaign $campaign_file]
    set base [dict get $cdata _base]

    set sender_name [dict get $cdata sender name]
    set sender_role [dict get $cdata sender role]
    set sender_email [dict get $cdata sender email]
    set sender_org [spar::dict_get_default [dict get $cdata sender] organisation]
    set language [dict get $cdata language]
    # approach_filename in campaign YAML is retained for backwards compat
    # but no longer consulted: the authoritative slug is the roster stem,
    # and approach files are always written to {stem}.yaml so
    # classify_segment can find them by the same key it looks up profiles by.
    variable ::spar::dispatch_script_dir
    set script_dir $::spar::dispatch_script_dir
    set method [file normalize [file join $script_dir .. spar-A-approach.md]]
    set appendices [spar::dict_get_default $cdata prompt_appendices [dict create]]
    set appendix_a_author [spar::dict_get_default $appendices a_author ""]
    set appendix_a_challenger [spar::dict_get_default $appendices a_challenger ""]
    set appendix_a_assembly [spar::dict_get_default $appendices a_assembly ""]
    set overview [dict get $cdata usp_document]
    set antifacts [spar::dict_get_default $cdata antifacts]
    set campaign_principles [spar::dict_get_default $cdata campaign_principles]
    set a_max_passes_ceiling [spar::dict_get_default $cdata a_max_passes 3]
    set segments [spar::filter_segments [dict get $cdata segments] $sel_segments]

    # Campaign filters (issue #41 in-scope-channel gate replaces
    # filter.require_email). A roster row is dispatchable for A when it
    # has at least one populated field for a channel the campaign declares.
    set filter [spar::dict_get_default $cdata filter [dict create]]
    set filter_skip_excluded [string is true -strict [spar::dict_get_default $filter skip_excluded true]]
    set filter_min_star [spar::dict_get_default $filter min_star 0]
    set filter_require_profile [string is true -strict [spar::dict_get_default $filter require_profile false]]
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

    set campaign_name [spar::dict_get_default $cdata campaign]
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

        file mkdir [spar::approach_dir_for_segment $seg_dir]

        set rows [spar::load_roster $roster_path]

        foreach row $rows {
            set org [string trim [spar::dict_get_default $row organisation]]
            set name [string trim [spar::dict_get_default $row contact_name]]
            set role [string trim [spar::dict_get_default $row role]]
            set phone [string trim [spar::dict_get_default $row phone]]
            set email [string trim [spar::dict_get_default $row email]]
            set linkedin [string trim [spar::dict_get_default $row linkedin_url]]
            set facebook [string trim [spar::dict_get_default $row facebook_url]]
            set p_note [string trim [spar::dict_get_default $row p_note]]
            set star [string trim [spar::dict_get_default $row star_rating]]
            set response_likelihood [string trim [spar::dict_get_default $row response_likelihood]]
            set s_note [string trim [spar::dict_get_default $row s_note]]
            set date_invalid [string trim [spar::dict_get_default $row date_excluded]]
            set stem [string trim [spar::dict_get_default $row stem ""]]

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

            # Profile lookup — {stem}.md (post SmartLayer/aesop#45).
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
Response likelihood: $response_likelihood
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
2. Organisation overview: $overview — read in full. This is the ground truth about the organisation. The segment file lists which USPs apply to this segment and whether each is functional or emotional. Use those USPs, do not invent your own from the overview.
$profile_a1_instruction
4. Segment file: $goal_path — read the \"message_goal\" field for the specific objective this message must achieve (e.g. secure a FAM visit, collect a roster expression of interest). The \"objective\" field is the long-term commercial goal, not what this message asks for. Read \"first_ask\" for approach style guidance. If the segment has subsegments, determine which subsegment applies to this contact and use its overrides where present."
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
2. $goal_path"
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

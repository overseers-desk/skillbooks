# spar-dispatch.tcl — Async dispatch library for SPAR batch operations
# Callable from both tclsh (CLI) and wish (GUI).
# Does NOT call vwait — the caller's event loop handles that.

package require TclOO

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export dispatch_profiles dispatch_approaches
    # Captured at source time — `info script` inside a proc reflects the
    # *calling* script at invocation, not this file, which broke path
    # resolution when dispatch_profiles was called from a test one dir deeper.
    variable dispatch_script_dir [file dirname [file normalize [info script]]]
}

# spar::Dispatcher — async queue of child harness processes.
#
# Takes a list of prompt_dirs and runs up to Jobs concurrent
# `tclsh HarnessPath <prompt_dir> LogsDir` children. Each line of a
# child's stdout is forwarded as an OnProgress "started" message; pipe
# close determines done/failed. When the queue drains and no children
# are active, OnComplete is called with {done failed result}, after
# which the object destroys itself.
#
# Used by dispatch_profiles, dispatch_approaches, and (per aesop#35)
# dispatch_sweeps. The per-phase facades build the prompt_dirs; the
# Dispatcher owns everything from spawn to completion.

oo::class create spar::Dispatcher {
    variable Queue QueueIdx Active Completed Failed
    variable Jobs LogsDir HarnessPath OnProgress OnComplete Result

    constructor {jobs logs_dir harness_path on_progress on_complete result} {
        set Jobs $jobs
        set LogsDir $logs_dir
        set HarnessPath $harness_path
        set OnProgress $on_progress
        set OnComplete $on_complete
        set Result $result
        set Queue {}
        set QueueIdx 0
        set Active 0
        set Completed 0
        set Failed 0
    }

    method run {prompt_dirs} {
        set Queue $prompt_dirs
        my start_next
    }

    # start_next and on_harness_output are dispatched externally (from
    # fileevent, and via the [self] command from the start_next tail) so
    # they cannot use a leading-underscore private naming convention —
    # TclOO would not export them.
    method start_next {} {
        while {$QueueIdx < [llength $Queue] && $Active < $Jobs} {
            set pdir [lindex $Queue $QueueIdx]
            incr QueueIdx
            set slug [file tail $pdir]

            {*}$OnProgress $slug started ""

            set cmd [list tclsh9.0 $HarnessPath $pdir $LogsDir]
            if {[catch {open "| $cmd 2>@1" r} pipe]} {
                {*}$OnProgress $slug failed "could not start harness: $pipe"
                incr Failed
                continue
            }
            fconfigure $pipe -blocking 0 -buffering line
            fileevent $pipe readable [list [self] on_harness_output $pipe $slug]
            incr Active
        }

        if {$Active == 0 && $QueueIdx >= [llength $Queue]} {
            set cb $OnComplete
            set done $Completed
            set fail $Failed
            set result $Result
            [self] destroy
            {*}$cb $done $fail $result
        }
    }

    method on_harness_output {pipe slug} {
        if {[gets $pipe line] >= 0} {
            # Children emit ROSTER_UPDATE marker lines (tab-separated) to
            # request TSV mutations. The dispatcher applies them serially
            # from its single event loop — that is the synchronisation that
            # replaces the per-harness flock. Non-marker lines are forwarded
            # as ordinary progress.
            if {[string match "ROSTER_UPDATE\t*" $line]} {
                my handle_roster_update $slug $line
            } else {
                {*}$OnProgress $slug started $line
            }
            return
        }
        if {[eof $pipe]} {
            if {[catch {close $pipe} err]} {
                {*}$OnProgress $slug failed $err
                incr Failed
            } else {
                {*}$OnProgress $slug done ""
                incr Completed
            }
            incr Active -1
            my start_next
        }
    }

    # Parse ROSTER_UPDATE<TAB>roster_path<TAB>key_col<TAB>key_val<TAB>field<TAB>new_val
    # and apply via spar::update_roster_field. Failure is non-fatal: emit a
    # warning progress event and carry on.
    method handle_roster_update {slug line} {
        set parts [split $line \t]
        if {[llength $parts] != 6} {
            {*}$OnProgress $slug warning "malformed ROSTER_UPDATE (expected 6 fields, got [llength $parts])"
            return
        }
        lassign $parts _ roster_path key_col key_val field new_val
        if {[catch {
            spar::update_roster_field $roster_path $key_col $key_val $field $new_val
        } err]} {
            {*}$OnProgress $slug warning "roster update failed ($key_col=$key_val $field=$new_val): $err"
            return
        }
        {*}$OnProgress $slug started "roster: $key_col=$key_val $field=$new_val"
    }
}

# dispatch_profiles — build SPAR-P profiles for roster entries without existing profiles.
#
# segment_dir   absolute path to the segment directory
# opts          dict with keys:
#                 campaign_file  (string, optional — mutually exclusive with overview)
#                 overview       (string, optional — path to overview doc)
#                 antifacts      (string, optional — path to antifacts doc)
#                 dry_run        (bool, default 0)
#                 jobs           (int, default 4)
#                 logs_dir       (string, optional — override log directory)
#                 stems          (list, optional — when set, only rows whose stem
#                                 is in the list are processed, and the
#                                 "profile already exists" skip is bypassed so
#                                 a caller that has pre-deleted the old profile
#                                 can force a rebuild. When empty/absent,
#                                 default behaviour applies: build for every
#                                 roster row without an existing profile file.)
# on_progress   callback prefix: {slug status message}
#                 status is one of: started, done, failed, skipped
# on_complete   callback prefix: {total_done total_failed}
#
# Returns immediately after launching the first batch of harnesses (or
# after dry-run scan). Calls on_complete when all harnesses finish.
#
proc spar::dispatch_profiles {segment_dir opts on_progress on_complete} {
    set segment_dir [file normalize $segment_dir]

    # --- Extract options ---
    set dry_run [spar::dict_get_default $opts dry_run 0]
    set jobs [spar::dict_get_default $opts jobs 4]
    set user_logs [spar::dict_get_default $opts logs_dir ""]
    set campaign_file [spar::dict_get_default $opts campaign_file ""]
    set user_overview [spar::dict_get_default $opts overview ""]
    set user_antifacts [spar::dict_get_default $opts antifacts ""]
    set sel_stems [spar::dict_get_default $opts stems {}]

    # --- Resolve required paths ---
    set roster_path [file join $segment_dir roster.tsv]
    set profile_dir [file join $segment_dir profiles]
    set goal_path [file join $segment_dir segment.yaml]
    if {![file exists $goal_path]} {
        set goal_path [file join $segment_dir goal.md]
    }

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

    # --- Resolve overview/antifacts ---
    set overview ""
    set antifacts ""

    set appendix_p_author ""
    if {$campaign_file ne ""} {
        set cdata [spar::load_campaign $campaign_file]
        set overview [spar::dict_get_default $cdata usp_document]
        set antifacts [spar::dict_get_default $cdata antifacts]
        set appendices [spar::dict_get_default $cdata prompt_appendices [dict create]]
        set appendix_p_author [spar::dict_get_default $appendices p_author ""]
    } elseif {$user_overview ne ""} {
        set overview [file normalize $user_overview]
        if {$user_antifacts ne ""} {
            set antifacts [file normalize $user_antifacts]
        }
    } else {
        error "provide campaign_file or overview in opts"
    }

    # --- Validate required files ---
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

    # --- Working directories ---
    # Seconds + pid so re-entry (e.g. --auto re-entering after its first
    # iteration) never shares a workdir with a previous call.
    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set workdir "/tmp/spar-p-[file tail $segment_dir]-$datestamp-[pid]"
    set prompts_dir [file join $workdir prompts]
    file mkdir $prompts_dir

    if {$user_logs ne ""} {
        if {![file isdirectory $user_logs]} {
            error "Log directory not found: $user_logs"
        }
        set logs_dir $user_logs
    } elseif {[file isdirectory /var/local/logs/spar]} {
        set logs_dir "/var/local/logs/spar/spar-p-[file tail $segment_dir]-$datestamp"
    } else {
        set logs_dir "$::env(HOME)/logs/spar/spar-p-[file tail $segment_dir]-$datestamp"
    }
    if {$user_logs eq ""} {
        file mkdir $logs_dir
    }

    # --- Load roster ---
    set rows [spar::load_roster $roster_path]

    # --- Generate prompts ---
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

        # Skip header fragments and invalidated entries.
        # Blank contact_name is allowed through: P §4.0b resolves the name
        # when organisation is identified but no individual is yet known.
        if {$name eq "contact_name" || $name eq "organisation"} continue
        if {$org eq ""} continue
        if {$date_invalid ne ""} continue
        if {$stem eq ""} continue

        if {[llength $sel_stems] > 0 && $stem ni $sel_stems} continue

        set outfile [file join $profile_dir "${stem}.md"]
        # Legacy path: profiles authored before SmartLayer/aesop#45. Still
        # counts as "profile exists" until migration is complete.
        set legacy_outfile [file join $profile_dir "profile-${stem}.md"]

        # Skip if profile already exists — unless caller supplied an explicit
        # stems list, in which case they have accepted responsibility for
        # pre-deleting the old profile and want a rebuild.
        if {[llength $sel_stems] == 0 \
            && ([file exists $outfile] || [file exists $legacy_outfile])} {
            incr skipped
            {*}$on_progress $stem skipped "profile exists"
            continue
        }

        incr count
        # Prompt-dir == stem. Matches the A-phase convention and makes the
        # harness's roster-row lookup (by stem) direct.
        set pdir [file join $prompts_dir $stem]
        file mkdir $pdir

        set antifacts_line ""
        if {$antifacts ne ""} {
            set antifacts_line "Antifact checklist: read $antifacts — flag any claims not supported by these sources."
        }

        set prompt "Follow the SPAR-P procedure at $spar_p.

Target: $name at $org, role: $role. Phone: $phone. Email: $email. LinkedIn: $linkedin. Facebook: $facebook.
Roster notes — s_note: $s_note, p_note: $p_note.

Campaign context: read $goal_path for the segment's objective, USPs, and angle table.
Organisation overview: read $overview for ground truth about the organisation.
$antifacts_line

Output file: $outfile
Roster file: $roster_path
Roster stem (file must be named exactly {stem}.md): $stem

Follow SPAR-P §5 profile structure exactly. The profile MUST begin with a YAML front-matter block (see §5.1) carrying profile_date, star_rating, richness, richness_count, warmth_finding, applicable_angles, and a dependent_data snapshot of contact_name, organisation, role, and date_excluded from the roster. After writing the profile, follow SPAR-P §4.9 to write star_rating to the roster TSV as well (both the profile front matter and the TSV carry it — the profile is the authorial home, the TSV is the query-optimised copy). Then follow §4.11 to backfill any missing contact details (email, linkedin_url, facebook_url) and replace stale contacts discovered during research with the person currently in the role. Never write a masked or redacted email address (e.g. 'b***@example.com') to the roster — if the only email found is masked, leave the field empty.
Web search is the primary research method. Use Chromium only when the target has a LinkedIn or Facebook URL and WebFetch returns insufficient data. Wrap Chromium with flock: flock /tmp/chromium.lock /snap/bin/chromium --headless --dump-dom --virtual-time-budget=30000 --window-size=1920,10000 --user-data-dir=\"\$HOME/snap/chromium/common/chromium\" \"URL\" 2>/dev/null

$sqlite3_skill_text"

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
        close $fd
    }

    # --- Return scan results via a dict ---
    set result [dict create \
        segment [file tail $segment_dir] \
        count $count \
        skipped $skipped \
        prompts_dir $prompts_dir \
        logs_dir $logs_dir]

    if {$dry_run || $count == 0} {
        {*}$on_complete $count 0 $result
        return $result
    }

    # --- Concurrent dispatch via event loop ---
    #
    # DbC-Pre: roster integrity for this segment was validated above
    # (load_roster enforces field-count assertion; required input files
    # existence-checked). Snapshot validate_roster output keyed by
    # "stem|code" so the DbC-Post wrapper can surface any new issues
    # as a per-slug regression attributed to the agent.
    set pre_snapshot [dict create]
    if {[catch {
        set _pre_contacts [spar::classify_segment $segment_dir]
        foreach _issue [spar::validate_roster $_pre_contacts] {
            set _cn [dict get $_issue contact_name]
            set _cd [dict get $_issue code]
            # Key by contact_name|code — stem isn't on the issue dict, and
            # (contact_name, code) is stable enough to filter pre-existing
            # issues from agent regressions.
            dict set pre_snapshot "${_cn}|${_cd}" 1
        }
    } _snap_err]} {
        # Snapshot is best-effort; a failure here shouldn't block dispatch.
        {*}$on_progress "_dbc_pre" warning "snapshot failed: $_snap_err"
    }
    set prompt_dirs [lsort [glob -nocomplain -type d [file join $prompts_dir *]]]

    variable ::spar::dispatch_script_dir
    set script_dir $::spar::dispatch_script_dir
    set harness [file join $script_dir spar-p-harness.tcl]

    # DbC-Post wrapper: on each harness completion, re-validate the roster
    # and emit any new (contact_name, code) pairs as a regression warning
    # for the completed slug. Pre-existing issues from pre_snapshot are
    # filtered out so only agent-caused regressions surface.
    set wrapped_progress [list spar::_p_dbc_post_progress \
        $on_progress $segment_dir $pre_snapshot]

    set disp [spar::Dispatcher new $jobs $logs_dir $harness \
        $wrapped_progress $on_complete $result]
    $disp run $prompt_dirs
    return $result
}

# Internal: on-progress wrapper that runs DbC-Post validation when a slug
# completes. Emits new roster issues (not in pre_snapshot) to the caller's
# on_progress as severity "warning" with code prefix "regression:".
proc spar::_p_dbc_post_progress {orig_progress segment_dir pre_snapshot slug status message} {
    {*}$orig_progress $slug $status $message
    if {$status ne "done"} return
    if {[catch {
        set _post_contacts [spar::classify_segment $segment_dir]
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


# dispatch_approaches — generate SPAR-A approach files from a campaign YAML.
#
# campaign_file  absolute path to campaign YAML
# opts           dict with keys:
#                  dry_run   (bool, default 0)
#                  jobs      (int, default 8)
#                  logs_dir  (string, optional — override log directory)
#                  segments  (list, optional — when set, only segments
#                             whose name is in the list are processed)
#                  stems     (list, optional — when set, only roster rows
#                             whose stem is in the list are processed)
# on_progress    callback prefix: {slug status message}
#                  status is one of: started, done, failed, skipped
# on_complete    callback prefix: {total_done total_failed}
#
# Returns immediately after launching the first batch of harnesses (or
# after dry-run scan). Calls on_complete when all harnesses finish.
#
proc spar::dispatch_approaches {campaign_file opts on_progress on_complete} {
    set dry_run [spar::dict_get_default $opts dry_run 0]
    set jobs [spar::dict_get_default $opts jobs 8]
    set user_logs [spar::dict_get_default $opts logs_dir ""]
    set sel_segments [spar::dict_get_default $opts segments {}]
    set sel_stems [spar::dict_get_default $opts stems {}]

    # --- Read campaign YAML ---
    set cdata [spar::load_campaign $campaign_file]
    set base [dict get $cdata _base]

    set sender_name [dict get $cdata sender name]
    set sender_role [dict get $cdata sender role]
    set sender_email [dict get $cdata sender email]
    set sender_org [spar::dict_get_default [dict get $cdata sender] organisation]
    set language [dict get $cdata language]
    # approach_filename in campaign YAML is retained for backwards compat but
    # no longer consulted: the authoritative slug is the roster `stem`, and
    # approach files are always written to {stem}.yaml so classify_segment
    # can find them by the same key it looks up profiles by.
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
    set segments [dict get $cdata segments]
    if {[llength $sel_segments] > 0} {
        set _filtered {}
        foreach _s $segments {
            if {$_s in $sel_segments} { lappend _filtered $_s }
        }
        set segments $_filtered
    }

    # Filters
    set filter [spar::dict_get_default $cdata filter [dict create]]
    set filter_require_email [string is true -strict [spar::dict_get_default $filter require_email false]]
    set filter_skip_excluded [string is true -strict [spar::dict_get_default $filter skip_excluded true]]
    set filter_min_star [spar::dict_get_default $filter min_star 0]
    set filter_require_profile [string is true -strict [spar::dict_get_default $filter require_profile false]]

    set lang_inst [spar::lang_instruction $language]

    # --- Validate required files ---
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

    # --- Working directories ---
    # Seconds resolution and a pid suffix so repeat calls within the same
    # invocation (e.g. --auto's state-machine loop) never share a workdir
    # with a previous run whose prompt dirs would then be re-dispatched.
    set datestamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set workdir "/tmp/spar-a-$datestamp-[pid]"
    set prompts_dir [file join $workdir prompts]
    file mkdir $prompts_dir

    if {$user_logs ne ""} {
        if {![file isdirectory $user_logs]} {
            error "Log directory not found: $user_logs"
        }
        set logs_dir $user_logs
    } elseif {[file isdirectory /var/local/logs/spar]} {
        set logs_dir "/var/local/logs/spar/spar-a-$datestamp"
    } else {
        set logs_dir "$::env(HOME)/logs/spar/spar-a-$datestamp"
    }
    if {$user_logs eq ""} {
        file mkdir $logs_dir
    }

    # --- Campaign summary data ---
    set campaign_name [spar::dict_get_default $cdata campaign]
    set filter_desc "email=$filter_require_email skip_excluded=$filter_skip_excluded min_star=$filter_min_star require_profile=$filter_require_profile"

    # --- Build sender line ---
    set sender_line "$sender_name, $sender_role"
    if {$sender_org ne ""} {
        append sender_line ", $sender_org"
    }
    append sender_line ", using $sender_email"

    # --- Process segments ---
    set count 0
    set skipped 0
    set fresh_prompt_dirs {}

    foreach segment $segments {
        set roster_path [file join $base $segment roster.tsv]
        set goal_path [file join $base $segment segment.yaml]
        if {![file exists $goal_path]} {
            set goal_path [file join $base $segment goal.md]
        }
        set profile_dir [file join $base $segment profiles]

        if {![file exists $roster_path]} continue
        if {![file exists $goal_path]} continue

        file mkdir [file join $base $segment approach]

        set rows [spar::load_roster $roster_path]

        foreach row $rows {
            set org [string trim [spar::dict_get_default $row organisation]]
            set name [string trim [spar::dict_get_default $row contact_name]]
            set role [string trim [spar::dict_get_default $row role]]
            set phone [string trim [spar::dict_get_default $row phone]]
            set email [string trim [spar::dict_get_default $row email]]
            set linkedin [string trim [spar::dict_get_default $row linkedin_url]]
            set facebook [string trim [spar::dict_get_default $row facebook_url]]
            set verified [string trim [spar::dict_get_default $row verified]]
            set p_note [string trim [spar::dict_get_default $row p_note]]
            set star [string trim [spar::dict_get_default $row star_rating]]
            set response_likelihood [string trim [spar::dict_get_default $row response_likelihood]]
            set s_note [string trim [spar::dict_get_default $row s_note]]
            set date_invalid [string trim [spar::dict_get_default $row date_excluded]]
            set stem [string trim [spar::dict_get_default $row stem ""]]

            # Skip header and malformed rows
            if {$org eq "organisation" || $name eq ""} continue
            if {$org eq ""} continue

            # Caller-supplied stem filter (independent of campaign-level filters).
            if {[llength $sel_stems] > 0 && $stem ni $sel_stems} continue

            # Campaign filters
            if {$filter_require_email && ![string match *@* $email]} continue
            if {$filter_skip_excluded && $date_invalid ne ""} continue
            if {$filter_min_star > 0} {
                if {![string is integer -strict $star] || $star < $filter_min_star} continue
            }

            set slug_name [spar::slugify $name]
            set slug_org [spar::slugify $org]

            # Approach file is always {stem}.yaml (stem is authoritative —
            # classify_segment reads it from the same path). Rows without
            # a stem are sweep artefacts and cannot be approached.
            if {$stem eq ""} {
                incr skipped
                {*}$on_progress "${slug_name}-${slug_org}" skipped "no stem"
                continue
            }
            set outfile [file join $base $segment approach "${stem}.yaml"]

            if {[file exists $outfile]} {
                incr skipped
                {*}$on_progress $stem skipped "approach exists"
                continue
            }

            # Profile lookup — {stem}.md (post SmartLayer/aesop#45). Legacy
            # profile-{stem}.md files are ignored by the dispatcher; migrate them
            # via spar-manager/migrate-profile-naming.tcl.
            set profile_path ""
            if {$stem ne ""} {
                set candidate [file join $profile_dir "${stem}.md"]
                if {[file exists $candidate]} {
                    set profile_path $candidate
                }
            }
            set max_rounds 1
            if {$profile_path ne ""} {
                set profile_a1_instruction "3. Profile: $profile_path"
                set fd [open $profile_path r]
                set profile_content [read $fd]
                close $fd
                set max_rounds [spar::get_max_rounds $profile_path]
            } else {
                if {$filter_require_profile} {
                    incr skipped
                    {*}$on_progress $stem skipped "no profile"
                    continue
                }
                set profile_a1_instruction "3. No profile document exists for this contact. Treat as Thin profile. Use the roster p_note and s_note below as the primary source for angle selection and drafting."
                set profile_content "No profile document. Roster notes only:
p_note: $p_note
s_note: $s_note"
                set max_rounds 1
            }

            # Channel selection
            set channel_d [spar::channel_desc $linkedin $phone]

            # Contact summary
            set contact_summary "Name: $name
Organisation: $org
Role: $role
Phone: $phone
Email: $email
LinkedIn: $linkedin
Facebook: $facebook
Star rating: $star
Response likelihood: $response_likelihood
Verified: $verified
p_note: $p_note
s_note: $s_note"

            incr count
            set prompt_slug [format "%03d-%s-%s" $count $slug_name $slug_org]
            set prompt_dir [file join $prompts_dir $prompt_slug]
            file mkdir $prompt_dir
            lappend fresh_prompt_dirs $prompt_dir

            # --- meta.env ---
            set fd [open [file join $prompt_dir meta.env] w]
            puts $fd "MAX_ROUNDS=$max_rounds"
            puts $fd "OUTFILE=$outfile"
            puts $fd "METHOD=$method"
            puts $fd "OVERVIEW=$overview"
            puts $fd "ANTIFACTS=$antifacts"
            puts $fd "GOAL=$goal_path"
            puts $fd "CONTACT_SUMMARY=$name | $org | $segment"
            puts $fd "ROSTER_EMAIL=$email"
            puts $fd "ROSTER_ORGANISATION=$org"
            puts $fd "CHALLENGER_MODEL=sonnet"
            close $fd

            if {$appendix_a_assembly ne ""} {
                set fd [open [file join $prompt_dir appendix-assembly.txt] w]
                puts -nonewline $fd $appendix_a_assembly
                close $fd
            }

            # --- Build file-reading instructions ---
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

            # --- author-draft.txt ---
            set fd [open [file join $prompt_dir author-draft.txt] w]
            puts $fd "You are executing SPAR-A Stage 1 (drafting) for one contact. Your task is to draft the approach message(s) and angle rationale. You do NOT perform the A2 spar — that runs in a separate, context-isolated process.

## Files to read before drafting

Read ALL of these files carefully before writing anything.

$file_items

## Contact details from roster

$contact_summary

## Channel selection

$channel_d

## Key constraints

- The sender is $sender_line.
- The email must stand alone for a recipient who has never heard of the sender's organisation. Introduce who you are, what the organisation is, and why you are writing.
- Read the segment file to determine the correct approach type. Do not default to a generic email.
- $lang_inst
- No emoji.

## Output format

Output your angle selection rationale between these markers:

RATIONALE_START
\[your rationale here\]
RATIONALE_END

Output your draft message(s) between these markers:

DRAFT_START
\[your draft messages here — email, LinkedIn note, phone script as applicable per channel\]
DRAFT_END

Do NOT write any files. Only output text to stdout with the markers above."
            if {$appendix_a_author ne ""} {
                puts $fd ""
                puts $fd $appendix_a_author
            }
            close $fd

            # --- Build challenger fact-check section ---
            set factcheck_files "Files to read:
1. $overview
2. $goal_path"
            if {$antifacts ne ""} {
                append factcheck_files "
3. $antifacts"
            }

            if {$antifacts ne "" || [file exists $overview]} {
                set factcheck_section "## Step 2: Fact-check (break character)

Break character. Now read the following files and check every factual claim in the draft message against them. Flag any errors or claims that cannot be verified.

$factcheck_files
Do not flag drive-time or distance claims (e.g. \"X minutes from Y\"). These are approximate figures and do not need fact-check verification.

For each issue found, write: \"FACTCHECK: \[claim in draft\] — \[what the source says or that no source exists\]\"

## Step 3: Verdict

After completing Steps 1 and 2, emit exactly one of these lines as the very last line of your output:"
            } else {
                set factcheck_section "## Step 2: Verdict

Emit exactly one of these lines as the very last line of your output:"
            }

            # --- challenger-template.txt ---
            set fd [open [file join $prompt_dir challenger-template.txt] w]
            puts $fd "You have sequential tasks. Complete Step 1 fully before proceeding.

## Step 1: Role-play as the recipient

You are the following person. React to the email draft below as if you received it cold — you have never heard of the sender or their organisation. Give a natural, in-character reaction. Do NOT use a rubric or structured format. Just react as a person would.

### Your profile

$profile_content

### The message you received

__DRAFT_PLACEHOLDER__

---

Give your in-character reaction now. When done, proceed.

$factcheck_section

VERDICT: DONE
VERDICT: REVISE

Emit VERDICT: DONE if the draft is credible (the persona reacted naturally without major objections) and factually correct. Emit VERDICT: REVISE if the persona had significant concerns or if fact-check found errors that must be fixed."
            if {$appendix_a_challenger ne ""} {
                puts $fd ""
                puts $fd $appendix_a_challenger
            }
            close $fd

            # --- profile-content.txt ---
            set fd [open [file join $prompt_dir profile-content.txt] w]
            puts $fd $profile_content
            close $fd
        }
    }

    # --- Return scan results ---
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

    if {$dry_run || $count == 0} {
        {*}$on_complete $count 0 $result
        return $result
    }

    # --- Dispatch harnesses ---
    variable ::spar::dispatch_script_dir
    set script_dir $::spar::dispatch_script_dir
    set harness [file join $script_dir spar-a-harness.tcl]

    # Dispatch only the prompt dirs we created this invocation — never glob
    # the workdir, since a previous call within the same process may have
    # left prompt dirs there and the harness would re-run them.
    set prompt_dirs $fresh_prompt_dirs
    # Shuffle for load balancing (Fisher-Yates)
    set n [llength $prompt_dirs]
    for {set i [expr {$n - 1}]} {$i > 0} {incr i -1} {
        set j [expr {int(rand() * ($i + 1))}]
        set tmp [lindex $prompt_dirs $i]
        lset prompt_dirs $i [lindex $prompt_dirs $j]
        lset prompt_dirs $j $tmp
    }

    set disp [spar::Dispatcher new $jobs $logs_dir $harness \
        $on_progress $on_complete $result]
    $disp run $prompt_dirs
    return $result
}

package provide spar-dispatch 1.0

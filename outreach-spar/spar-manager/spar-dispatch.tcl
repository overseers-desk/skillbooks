# spar-dispatch.tcl — Async dispatch library for SPAR batch operations
# Callable from both tclsh (CLI) and wish (GUI).
# Does NOT call vwait — the caller's event loop handles that.

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export dispatch_profiles dispatch_approaches
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
# on_progress   callback prefix: {slug status message}
#                 status is one of: started, done, failed, skipped
# on_complete   callback prefix: {total_done total_failed}
#
# Returns immediately after launching the first batch of workers (or after
# dry-run scan). Calls on_complete when all workers finish.
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

    # --- Resolve required paths ---
    set roster_path [file join $segment_dir roster.tsv]
    set profile_dir [file join $segment_dir profiles]
    set goal_path [file join $segment_dir segment.yaml]
    if {![file exists $goal_path]} {
        set goal_path [file join $segment_dir goal.md]
    }

    set script_dir [file dirname [file normalize [info script]]]
    set spar_p [file normalize [file join $script_dir .. spar-P-profile.md]]

    # --- Resolve overview/antifacts ---
    set overview ""
    set antifacts ""

    if {$campaign_file ne ""} {
        set cdata [spar::load_campaign $campaign_file]
        set overview [spar::dict_get_default $cdata usp_document]
        set antifacts [spar::dict_get_default $cdata antifacts]
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
    set datestamp [clock format [clock seconds] -format %Y%m%d%H%M]
    set workdir "/tmp/spar-p-[file tail $segment_dir]-$datestamp"
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
        set date_invalid [string trim [spar::dict_get_default $row date_found_invalid]]
        set s_note [string trim [spar::dict_get_default $row s_note]]
        set p_note [string trim [spar::dict_get_default $row p_note]]

        # Skip header fragments, blank rows, invalidated entries
        if {$name eq "" || $name eq "contact_name" || $name eq "organisation"} continue
        if {$org eq ""} continue
        if {$date_invalid ne ""} continue

        set slug_name [spar::slugify $name]
        set slug_org [spar::slugify $org]
        set outfile [file join $profile_dir "profile-${slug_name}-${slug_org}.md"]

        # Skip if profile already exists
        if {[file exists $outfile] || [spar::profile_exists $profile_dir $slug_name $slug_org]} {
            incr skipped
            {*}$on_progress "${slug_name}-${slug_org}" skipped "profile exists"
            continue
        }

        incr count
        set prompt_slug [format "%03d-%s-%s" $count $slug_name $slug_org]
        set prompt_file [file join $prompts_dir "${prompt_slug}.txt"]

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

Follow SPAR-P §5 profile structure exactly. After writing the profile, follow SPAR-P §4.9 to write star_rating and response_likelihood to the roster TSV (not to the profile document). Then follow §4.11 to backfill any missing contact details (email, linkedin_url, facebook_url) and replace stale contacts discovered during research with the person currently in the role. Never write a masked or redacted email address (e.g. 'b***@example.com') to the roster — if the only email found is masked, leave the field empty.
Web search is the primary research method. Use Chromium only when the target has a LinkedIn or Facebook URL and WebFetch returns insufficient data. Wrap Chromium with flock: flock /tmp/chromium.lock /snap/bin/chromium --headless --dump-dom --virtual-time-budget=30000 --window-size=1920,10000 --user-data-dir=\"\$HOME/snap/chromium/common/chromium\" \"URL\" 2>/dev/null"

        set fd [open $prompt_file w]
        puts $fd $prompt
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
    set prompt_files [lsort [glob -nocomplain [file join $prompts_dir *.txt]]]

    # Use a namespace variable dict to hold dispatch state
    variable _p_state
    set sid [incr _p_state(next_id)]
    set _p_state($sid,queue) $prompt_files
    set _p_state($sid,queue_idx) 0
    set _p_state($sid,active) 0
    set _p_state($sid,completed) 0
    set _p_state($sid,failed) 0
    set _p_state($sid,jobs) $jobs
    set _p_state($sid,logs_dir) $logs_dir
    set _p_state($sid,on_progress) $on_progress
    set _p_state($sid,on_complete) $on_complete
    set _p_state($sid,result) $result
    set _p_state($sid,segment_dir) $segment_dir

    _p_start_next $sid
    return $result
}

proc spar::_p_start_next {sid} {
    variable _p_state

    while {$_p_state($sid,queue_idx) < [llength $_p_state($sid,queue)] \
           && $_p_state($sid,active) < $_p_state($sid,jobs)} {
        set pfile [lindex $_p_state($sid,queue) $_p_state($sid,queue_idx)]
        incr _p_state($sid,queue_idx)
        set slug [file rootname [file tail $pfile]]
        set logfile [file join $_p_state($sid,logs_dir) "${slug}.log"]

        {*}$_p_state($sid,on_progress) $slug started ""

        set pipe [open "| /bin/sh -c {cat \"$pfile\" | claude -p --dangerously-skip-permissions --model sonnet --max-budget-usd 3.00 > \"$logfile\" 2>&1; echo \"EXIT:\$?\"}" r]
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list spar::_p_on_worker_done $sid $pipe $slug]
        incr _p_state($sid,active)
    }

    if {$_p_state($sid,active) == 0 \
        && $_p_state($sid,queue_idx) >= [llength $_p_state($sid,queue)]} {
        set done $_p_state($sid,completed)
        set fail $_p_state($sid,failed)
        set result $_p_state($sid,result)
        set cb $_p_state($sid,on_complete)
        _p_cleanup $sid
        {*}$cb $done $fail $result
    }
}

proc spar::_p_on_worker_done {sid pipe slug} {
    variable _p_state

    if {[gets $pipe line] >= 0} {
        if {[string match "EXIT:*" $line]} {
            set rc [string range $line 5 end]
            if {$rc ne "0"} {
                {*}$_p_state($sid,on_progress) $slug failed "rc=$rc"
                incr _p_state($sid,failed)
            } else {
                # Post-profile guardrail: blank masked emails in roster.
                # Uses spar::is_masked_email — same check that
                # validate_campaign/spar-progress.tcl reports on.
                _p_sanitise_roster_email $sid $slug
                {*}$_p_state($sid,on_progress) $slug done ""
                incr _p_state($sid,completed)
            }
        }
        return
    }
    if {[eof $pipe]} {
        catch {close $pipe}
        incr _p_state($sid,active) -1
        _p_start_next $sid
    }
}

# _p_sanitise_roster_email — after a P-stage worker succeeds, check whether
# the email it wrote to the roster is masked (e.g. "b***@foo.com").  If so,
# blank it — a masked address is worse than empty because it inflates the
# "has email" count and can propagate into approach files.
#
# Detection delegates to spar::is_masked_email (spar-state.tcl) — the same
# function that validate_campaign / spar-progress.tcl uses for reporting.
proc spar::_p_sanitise_roster_email {sid slug} {
    variable _p_state
    set seg_dir $_p_state($sid,segment_dir)
    set roster [file join $seg_dir roster.tsv]
    if {![file exists $roster]} return

    set rows [spar::load_roster $roster]
    set dirty 0
    set updated {}
    foreach row $rows {
        set stem [spar::dict_get_default $row stem ""]
        if {$stem eq $slug} {
            set email [string trim [spar::dict_get_default $row email ""]]
            if {[spar::is_masked_email $email]} {
                puts "\[$slug\] Guardrail: blanked masked email '$email' in roster"
                dict set row email ""
                set dirty 1
            }
        }
        lappend updated $row
    }

    if {$dirty} {
        spar::write_roster $roster $updated
    }
}

proc spar::_p_cleanup {sid} {
    variable _p_state
    foreach key [array names _p_state ${sid},*] {
        unset _p_state($key)
    }
}

# Initialise the ID counter
namespace eval spar {
    variable _p_state
    set _p_state(next_id) 0
}


# dispatch_approaches — generate SPAR-A approach files from a campaign YAML.
#
# campaign_file  absolute path to campaign YAML
# opts           dict with keys:
#                  dry_run   (bool, default 0)
#                  jobs      (int, default 8)
#                  logs_dir  (string, optional — override log directory)
# on_progress    callback prefix: {slug status message}
#                  status is one of: started, done, failed, skipped
# on_complete    callback prefix: {total_done total_failed}
#
# Returns immediately after launching the first batch of workers (or after
# dry-run scan). Calls on_complete when all workers finish.
#
proc spar::dispatch_approaches {campaign_file opts on_progress on_complete} {
    set dry_run [spar::dict_get_default $opts dry_run 0]
    set jobs [spar::dict_get_default $opts jobs 8]
    set user_logs [spar::dict_get_default $opts logs_dir ""]

    # --- Read campaign YAML ---
    set cdata [spar::load_campaign $campaign_file]
    set base [dict get $cdata _base]

    set sender_name [dict get $cdata sender name]
    set sender_role [dict get $cdata sender role]
    set sender_email [dict get $cdata sender email]
    set sender_org [spar::dict_get_default [dict get $cdata sender] organisation]
    set language [dict get $cdata language]
    set approach_pattern [dict get $cdata approach_filename]
    set method [dict get $cdata method]
    set overview [dict get $cdata usp_document]
    set antifacts [spar::dict_get_default $cdata antifacts]
    set campaign_principles [spar::dict_get_default $cdata campaign_principles]
    set segments [dict get $cdata segments]

    # Filters
    set filter [spar::dict_get_default $cdata filter [dict create]]
    set filter_require_email [string is true -strict [spar::dict_get_default $filter require_email false]]
    set filter_require_no_linkedin [string is true -strict [spar::dict_get_default $filter require_no_linkedin false]]
    set filter_exclude_invalid [string is true -strict [spar::dict_get_default $filter exclude_invalid true]]
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
    set datestamp [clock format [clock seconds] -format %Y%m%d]
    set workdir "/tmp/spar-a-$datestamp"
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
    set filter_desc "email=$filter_require_email no_linkedin=$filter_require_no_linkedin valid_only=$filter_exclude_invalid min_star=$filter_min_star require_profile=$filter_require_profile"

    # --- Build sender line ---
    set sender_line "$sender_name, $sender_role"
    if {$sender_org ne ""} {
        append sender_line ", $sender_org"
    }
    append sender_line ", using $sender_email"

    # --- Process segments ---
    set count 0
    set skipped 0

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
            set date_invalid [string trim [spar::dict_get_default $row date_found_invalid]]

            # Skip header and malformed rows
            if {$org eq "organisation" || $name eq ""} continue
            if {$org eq ""} continue

            # Campaign filters
            if {$filter_require_email && ![string match *@* $email]} continue
            if {$filter_require_no_linkedin && $linkedin ne ""} continue
            if {$filter_exclude_invalid && $date_invalid ne ""} continue
            if {$filter_min_star > 0} {
                if {![string is integer -strict $star] || $star < $filter_min_star} continue
            }

            set slug_name [spar::slugify $name]
            set slug_org [spar::slugify $org]

            # Build output filename from YAML pattern
            set outfile_name [string map \
                [list \{star\} $star \{slug_name\} $slug_name \{slug_org\} $slug_org] \
                $approach_pattern]
            set outfile [file join $base $segment approach $outfile_name]

            # Skip if approach file already exists
            if {[file exists $outfile]} {
                incr skipped
                {*}$on_progress "${slug_name}-${slug_org}" skipped "approach exists"
                continue
            }
            if {[llength [glob -nocomplain [file join $base $segment approach "${slug_name}-*.yaml"]]] > 0} {
                incr skipped
                {*}$on_progress "${slug_name}-${slug_org}" skipped "approach exists"
                continue
            }

            # Profile lookup
            set profile_path [spar::find_profile $profile_dir $slug_name $slug_org]
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
                    {*}$on_progress "${slug_name}-${slug_org}" skipped "no profile"
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
            puts $fd "CHALLENGER_MODEL=sonnet"
            close $fd

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
        method $method \
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

    # --- Dispatch workers ---
    set script_dir [file dirname [file normalize [info script]]]
    set worker [file join $script_dir spar-a-worker.tcl]

    set prompt_dirs [lsort [glob -nocomplain -type d [file join $prompts_dir *]]]
    # Shuffle for load balancing (Fisher-Yates)
    set n [llength $prompt_dirs]
    for {set i [expr {$n - 1}]} {$i > 0} {incr i -1} {
        set j [expr {int(rand() * ($i + 1))}]
        set tmp [lindex $prompt_dirs $i]
        lset prompt_dirs $i [lindex $prompt_dirs $j]
        lset prompt_dirs $j $tmp
    }

    # Use a namespace variable dict to hold dispatch state
    variable _a_state
    set sid [incr _a_state(next_id)]
    set _a_state($sid,queue) $prompt_dirs
    set _a_state($sid,queue_idx) 0
    set _a_state($sid,active) 0
    set _a_state($sid,completed) 0
    set _a_state($sid,failed) 0
    set _a_state($sid,jobs) $jobs
    set _a_state($sid,logs_dir) $logs_dir
    set _a_state($sid,worker) $worker
    set _a_state($sid,on_progress) $on_progress
    set _a_state($sid,on_complete) $on_complete
    set _a_state($sid,result) $result

    _a_start_next $sid
    return $result
}

proc spar::_a_start_next {sid} {
    variable _a_state

    while {$_a_state($sid,queue_idx) < [llength $_a_state($sid,queue)] \
           && $_a_state($sid,active) < $_a_state($sid,jobs)} {
        set pdir [lindex $_a_state($sid,queue) $_a_state($sid,queue_idx)]
        incr _a_state($sid,queue_idx)
        set slug [file tail $pdir]

        {*}$_a_state($sid,on_progress) $slug started ""

        set cmd [list tclsh $_a_state($sid,worker) $pdir $_a_state($sid,logs_dir)]
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            {*}$_a_state($sid,on_progress) $slug failed "could not start worker: $pipe"
            incr _a_state($sid,failed)
            continue
        }
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list spar::_a_on_worker_output $sid $pipe $slug]
        incr _a_state($sid,active)
    }

    if {$_a_state($sid,active) == 0 \
        && $_a_state($sid,queue_idx) >= [llength $_a_state($sid,queue)]} {
        set done $_a_state($sid,completed)
        set fail $_a_state($sid,failed)
        set result $_a_state($sid,result)
        set cb $_a_state($sid,on_complete)
        _a_cleanup $sid
        {*}$cb $done $fail $result
    }
}

proc spar::_a_on_worker_output {sid pipe slug} {
    variable _a_state

    if {[gets $pipe line] >= 0} {
        # Forward worker output as progress messages
        {*}$_a_state($sid,on_progress) $slug started $line
        return
    }
    if {[eof $pipe]} {
        if {[catch {close $pipe} err]} {
            {*}$_a_state($sid,on_progress) $slug failed ""
            incr _a_state($sid,failed)
        } else {
            {*}$_a_state($sid,on_progress) $slug done ""
            incr _a_state($sid,completed)
        }
        incr _a_state($sid,active) -1
        _a_start_next $sid
    }
}

proc spar::_a_cleanup {sid} {
    variable _a_state
    foreach key [array names _a_state ${sid},*] {
        unset _a_state($key)
    }
}

# Initialise the ID counter
namespace eval spar {
    variable _a_state
    set _a_state(next_id) 0
}

package provide spar-dispatch 1.0

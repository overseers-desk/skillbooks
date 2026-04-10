#!/usr/bin/env tclsh
# spar-a-batch.tcl — Generate SPAR-A approach files from a campaign YAML
# Tcl port of ../bin/spar-a-batch.sh
# Usage: tclsh spar-a-batch.tcl <campaign.yaml> [--dry-run] [--jobs=N] [--logs=DIR]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-lib.tcl]

# --- Argument parsing ---
set campaign_file ""
set dry_run 0
set jobs 8
set user_logs ""

foreach arg $argv {
    switch -glob -- $arg {
        --dry-run   { set dry_run 1 }
        --jobs=*    { set jobs [string range $arg 7 end] }
        --logs=*    { set user_logs [string range $arg 7 end] }
        --*         { puts stderr "Unknown flag: $arg"; exit 1 }
        default     { set campaign_file $arg }
    }
}

if {$campaign_file eq ""} {
    puts stderr "Usage: tclsh spar-a-batch.tcl <campaign.yaml> \[--dry-run\] \[--jobs=N\] \[--logs=DIR\]"
    exit 1
}
if {![file exists $campaign_file]} {
    puts stderr "Campaign file not found: $campaign_file"
    exit 1
}

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
    puts stderr "Method file not found: $method"
    exit 1
}
if {![file exists $overview]} {
    puts stderr "Overview file not found: $overview"
    exit 1
}
if {$antifacts ne "" && ![file exists $antifacts]} {
    puts stderr "Antifacts file not found: $antifacts"
    exit 1
}
if {$campaign_principles ne "" && ![file exists $campaign_principles]} {
    puts stderr "Campaign principles not found: $campaign_principles"
    exit 1
}

# --- Working directories ---
set datestamp [clock format [clock seconds] -format %Y%m%d]
set workdir "/tmp/spar-a-$datestamp"
set prompts_dir [file join $workdir prompts]
file mkdir $prompts_dir

if {$user_logs ne ""} {
    if {![file isdirectory $user_logs]} {
        puts stderr "Log directory not found: $user_logs"
        exit 1
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

# --- Print campaign summary ---
puts "Campaign:    [spar::dict_get_default $cdata campaign]"
puts "Sender:      $sender_name <$sender_email>"
puts "Method:      $method"
puts "Language:    $language"
puts "Segments:    $segments"
puts "Filters:     email=$filter_require_email no_linkedin=$filter_require_no_linkedin valid_only=$filter_exclude_invalid min_star=$filter_min_star require_profile=$filter_require_profile"
puts ""

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
            continue
        }
        if {[llength [glob -nocomplain [file join $base $segment approach "${slug_name}-*.yaml"]]] > 0} {
            incr skipped
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

puts "Generated $count prompt files in $prompts_dir/"
puts "Skipped $skipped (approach file already exists)"
puts ""

if {$dry_run} {
    puts "Dry run complete. Review prompts in $prompts_dir/"
    exit 0
}

if {$count == 0} {
    puts "Nothing to do."
    exit 0
}

# --- Dispatch workers ---
set worker [file join $script_dir spar-a-worker.tcl]
puts "Running $count jobs, $jobs concurrent..."
puts ""

set prompt_dirs [lsort [glob -nocomplain -type d [file join $prompts_dir *]]]
# Shuffle for load balancing (simple Fisher-Yates)
set n [llength $prompt_dirs]
for {set i [expr {$n - 1}]} {$i > 0} {incr i -1} {
    set j [expr {int(rand() * ($i + 1))}]
    set tmp [lindex $prompt_dirs $i]
    lset prompt_dirs $i [lindex $prompt_dirs $j]
    lset prompt_dirs $j $tmp
}

set active 0
set completed 0
set failed 0
set queue_idx 0

proc start_next {} {
    global prompt_dirs queue_idx jobs active completed failed logs_dir worker

    while {$queue_idx < [llength $prompt_dirs] && $active < $jobs} {
        set pdir [lindex $prompt_dirs $queue_idx]
        incr queue_idx
        set slug [file tail $pdir]

        set cmd [list tclsh $worker $pdir $logs_dir]
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            puts "  \[FAIL\] $slug: could not start worker: $pipe"
            incr failed
            continue
        }
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list on_worker_output $pipe $slug]
        incr active
    }

    if {$active == 0 && $queue_idx >= [llength $prompt_dirs]} {
        set ::alldone 1
    }
}

proc on_worker_output {pipe slug} {
    global active completed failed

    if {[gets $pipe line] >= 0} {
        puts "  $line"
        return
    }
    if {[eof $pipe]} {
        if {[catch {close $pipe} err]} {
            puts "  \[FAIL\] $slug"
            incr failed
        } else {
            incr completed
        }
        incr active -1
        start_next
    }
}

start_next
if {[llength $prompt_dirs] > 0} {
    vwait ::alldone
}

puts ""
puts "=== Summary ==="
puts "Logs:       $logs_dir/"
puts "Successful: $completed"
puts "Failed:     $failed"

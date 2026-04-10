#!/usr/bin/env tclsh
# spar-a-worker.tcl — Process one SPAR-A approach: author drafts, challenger spars
# Tcl port of ../bin/spar-a-worker.sh
#
# The author runs as a single resumed session (draft → revise → assemble).
# The challenger runs as fresh context-isolated sessions (one per spar round).
#
# Usage: tclsh spar-a-worker.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: author-draft.txt, challenger-template.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh spar-a-worker.tcl <prompt-dir> <log-dir>"
    exit 1
}

set prompt_dir [lindex $argv 0]
set log_dir [lindex $argv 1]
set slug [file tail $prompt_dir]

# --- Read meta.env ---
set meta [dict create]
set fd [open [file join $prompt_dir meta.env] r]
while {[gets $fd line] >= 0} {
    if {[regexp {^([A-Z_]+)=(.*)$} $line -> key val]} {
        # Strip surrounding quotes if present
        set val [string trim $val "\""]
        dict set meta $key $val
    }
}
close $fd

set max_rounds [dict get $meta MAX_ROUNDS]
set outfile [dict get $meta OUTFILE]
set method_path [dict get $meta METHOD]
set overview_path [dict get $meta OVERVIEW]
set antifacts [spar::dict_get_default $meta ANTIFACTS]
set goal_path [dict get $meta GOAL]
set contact_summary [dict get $meta CONTACT_SUMMARY]
set challenger_model [spar::dict_get_default $meta CHALLENGER_MODEL sonnet]
set roster_email [spar::dict_get_default $meta ROSTER_EMAIL ""]

set log_prefix [file join $log_dir $slug]
set cost_log [file join $log_dir "$slug-cost.jsonl"]

file mkdir $log_dir
set fd [open $cost_log w]; close $fd

# ── Helpers ────────────────────────────────────────────────────────────

# Parse "resets 3am (Australia/Brisbane)" → seconds to sleep
proc credit_wait_secs {msg} {
    if {![regexp {resets (\d{1,2}(?::\d{2})?\s*[ap]m)} $msg -> reset_time]} {
        return 3600
    }
    set tz "Australia/Brisbane"
    if {[regexp {\(([^)]+)\)} $msg -> found_tz]} {
        set tz $found_tz
    }
    set now_epoch [clock seconds]
    if {[catch {
        set reset_epoch [clock scan "today $reset_time" -timezone :$tz]
    }]} {
        return 3600
    }
    if {$reset_epoch <= $now_epoch} {
        if {[catch {
            set reset_epoch [clock scan "tomorrow $reset_time" -timezone :$tz]
        }]} {
            return 3600
        }
    }
    set wait [expr {$reset_epoch - $now_epoch + 120}]
    if {$wait < 60} { set wait 60 }
    return $wait
}

# Invoke claude CLI, parse JSON output, handle credit-limit retries
# Returns: 0 on success, 1 on failure
# Side effects: writes log_file (text result) and log_file.json (raw JSON)
proc invoke_claude {stage log_file args} {
    upvar 1 slug slug cost_log cost_log

    set json_file "${log_file}.json"
    set max_retries 5
    set attempt 0

    while {1} {
        incr attempt

        # Build the command
        set cmd [list claude -p --output-format json --dangerously-skip-permissions]
        set cmd [concat $cmd $args]

        # Run claude, capture stdout to json_file, stderr to stderr file
        if {[catch {
            set result [exec {*}$cmd > $json_file 2> "${log_file}.stderr"]
        } err]} {
            # Non-zero exit — check if JSON was still written
            if {![file exists $json_file] || [file size $json_file] == 0} {
                puts "FAIL ($stage rc=error): $slug"
                return 1
            }
        }

        # Read and parse JSON output
        set fd [open $json_file r]
        set raw_json [read $fd]
        close $fd

        if {[catch {set parsed [::json::json2dict $raw_json]} parse_err]} {
            puts "FAIL ($stage: invalid JSON): $slug"
            return 1
        }

        # Detect credit-limit error
        if {[dict exists $parsed is_error] && [dict get $parsed is_error] eq "true"} {
            set result_text [spar::dict_get_default $parsed result ""]
            if {[string match -nocase *hit*your*limit*resets* $result_text]} {
                if {$attempt >= $max_retries} {
                    puts "FAIL ($stage: credit limit after $max_retries retries): $slug"
                    return 1
                }
                set wait_secs [credit_wait_secs $result_text]
                puts "\[$slug\] Credit limit hit (attempt $attempt/$max_retries). Sleeping [expr {$wait_secs/60}]m until reset..."
                after [expr {$wait_secs * 1000}] set ::_wake 1
                vwait ::_wake
                continue
            }
        }

        # Check for valid result
        if {![dict exists $parsed result]} {
            puts "FAIL ($stage: no result in output): $slug"
            return 1
        }

        # Write text result to log file
        set fd [open $log_file w]
        puts -nonewline $fd [dict get $parsed result]
        close $fd

        # Append cost entry to JSONL log (compact, one line per entry)
        set _prev_indent [::json::write indented]
        ::json::write indented false
        set cost_entry [::json::write object \
            stage [::json::write string $stage] \
            cost [spar::dict_get_default $parsed total_cost_usd 0]]
        ::json::write indented $_prev_indent
        set fd [open $cost_log a]
        puts $fd $cost_entry
        close $fd

        return 0
    }
}

proc get_session_id {json_file} {
    set fd [open $json_file r]
    set raw [read $fd]
    close $fd
    set parsed [::json::json2dict $raw]
    return [dict get $parsed session_id]
}

proc read_file {path} {
    set fd [open $path r]
    set content [read $fd]
    close $fd
    return $content
}

proc write_file {path content} {
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
}

# validate_and_correct -- validate approach file post-assembly, retry on error.
# Attempts 1-2: current model. Attempt 3: opus. Returns 0 if valid, 1 if failed.
proc validate_and_correct {outfile roster_email contact_name session_id log_prefix slug} {
    set max_fix 3

    for {set attempt 1} {$attempt <= $max_fix} {incr attempt} {
        set errors [spar::validate_approach $outfile $roster_email $contact_name]
        set hard {}
        foreach e $errors {
            if {[dict get $e severity] eq "error"} {
                lappend hard $e
            }
        }

        if {[llength $hard] == 0} {
            if {$attempt > 1} {
                puts "\[$slug\] Validation passed after $attempt attempt(s)."
            }
            return 0
        }

        set lines {}
        foreach e $hard {
            lappend lines "- \[[dict get $e code]\] [dict get $e message]"
        }
        set error_text [join $lines \n]
        puts "\[$slug\] Validation failed (attempt $attempt/$max_fix):\n$error_text"

        set fix_log "${log_prefix}-fix${attempt}.log"
        set fix_prompt "The approach file you just wrote failed validation:\n\n$error_text\n\nRewrite the file at $outfile to fix these errors. The to: field in each email message must be a real email address (not a placeholder). It must match the roster email: $roster_email"

        set model_args {}
        if {$attempt == 3} {
            set model_args [list --model opus]
        }

        if {[invoke_claude "fix${attempt}" $fix_log \
                --resume $session_id {*}$model_args $fix_prompt]} {
            return 1
        }
    }

    # Final check after last correction
    set errors [spar::validate_approach $outfile $roster_email $contact_name]
    foreach e $errors {
        if {[dict get $e severity] eq "error"} {
            puts "FAIL (validation failed after $max_fix retries): $slug"
            return 1
        }
    }
    return 0
}

# ── Author: draft ──────────────────────────────────────────────────────

puts "\[$slug\] Author: drafting..."
set author_draft_log "${log_prefix}-author-draft.log"
set author_prompt [read_file [file join $prompt_dir author-draft.txt]]

if {[invoke_claude "author-draft" $author_draft_log $author_prompt]} {
    exit 1
}

set author_session [get_session_id "${author_draft_log}.json"]

set draft_text [read_file $author_draft_log]
set draft [spar::extract_between $draft_text "DRAFT_START" "DRAFT_END"]
if {$draft eq ""} {
    puts "FAIL (no draft markers): $slug"
    exit 1
}

set rationale [spar::extract_between $draft_text "RATIONALE_START" "RATIONALE_END"]
write_file [file join $prompt_dir draft-current.txt] $draft
write_file [file join $prompt_dir rationale.txt] $rationale

# ── Spar loop ──────────────────────────────────────────────────────────

set round 0
set verdict "REVISE"

while {$round < $max_rounds && $verdict eq "REVISE"} {
    incr round
    puts "\[$slug\] Challenger round $round/$max_rounds..."

    # Challenger: fresh session, context-isolated
    set challenger_template [read_file [file join $prompt_dir challenger-template.txt]]
    set current_draft [read_file [file join $prompt_dir draft-current.txt]]
    set challenger_prompt [string map [list __DRAFT_PLACEHOLDER__ $current_draft] $challenger_template]

    set challenger_log "${log_prefix}-challenger-round${round}.log"
    if {[invoke_claude "challenger-round${round}" $challenger_log \
            --model $challenger_model $challenger_prompt]} {
        exit 1
    }

    file copy -force $challenger_log [file join $prompt_dir "challenger-round${round}.txt"]

    # Extract verdict
    set challenger_text [read_file $challenger_log]
    set verdict ""
    foreach line [split $challenger_text \n] {
        if {[string match "VERDICT:*" $line]} {
            set verdict [string trim [string range $line 8 end]]
        }
    }
    if {$verdict eq ""} { set verdict "REVISE" }

    if {$verdict eq "DONE"} {
        puts "\[$slug\] Challenger round $round: DONE"
        break
    }

    puts "\[$slug\] Challenger round $round: REVISE — author revising..."

    # Author revision: resume session
    set author_rev_log "${log_prefix}-author-rev${round}.log"
    set challenger_feedback [read_file [file join $prompt_dir "challenger-round${round}.txt"]]

    set rev_prompt "This is revision round $round. A challenger (context-isolated, playing the recipient) reacted to your draft and fact-checked it.

## Challenger feedback (round $round)

$challenger_feedback

## Instructions

Revise the draft to address valid concerns. Do not over-correct. If the reaction was positive on a point, keep it. If a factual error was flagged, fix it. If the tone was off, adjust.

Output the revised draft between DRAFT_START and DRAFT_END markers. Output any updated rationale between RATIONALE_START and RATIONALE_END."

    write_file [file join $prompt_dir "author-rev${round}.txt"] $rev_prompt

    if {[invoke_claude "author-rev${round}" $author_rev_log \
            --resume $author_session $rev_prompt]} {
        exit 1
    }

    set rev_text [read_file $author_rev_log]
    set revised_draft [spar::extract_between $rev_text "DRAFT_START" "DRAFT_END"]
    if {$revised_draft ne ""} {
        write_file [file join $prompt_dir draft-current.txt] $revised_draft
    }
    set revised_rationale [spar::extract_between $rev_text "RATIONALE_START" "RATIONALE_END"]
    if {$revised_rationale ne ""} {
        write_file [file join $prompt_dir rationale.txt] $revised_rationale
    }
}

# ── Author: assemble ───────────────────────────────────────────────────

puts "\[$slug\] Author: assembling..."

# Collect challenger logs
set all_challenger ""
for {set r 1} {$r <= $round} {incr r} {
    set cfile [file join $prompt_dir "challenger-round${r}.txt"]
    if {[file exists $cfile]} {
        append all_challenger "\n### A2 Response $r\n\n[read_file $cfile]\n"
    }
}

# Collect revision drafts
set all_revisions ""
for {set r 1} {$r <= $round} {incr r} {
    set rev_log "${log_prefix}-author-rev${r}.log"
    if {[file exists $rev_log]} {
        set rev_draft [spar::extract_between [read_file $rev_log] "DRAFT_START" "DRAFT_END"]
        if {$rev_draft ne ""} {
            append all_revisions "\n### A1 Draft [expr {$r + 1}]\n\n$rev_draft\n"
        }
    }
}

set initial_draft [spar::extract_between [read_file "${log_prefix}-author-draft.log"] "DRAFT_START" "DRAFT_END"]
set final_draft [read_file [file join $prompt_dir draft-current.txt]]

set assembly_prompt "Write the final comms file. You have the method, overview, antifacts, goal, and profile from your drafting context. Refer to §6 (comms file structure) and §7 (quality checklist) in the method file.

## Contact details

$contact_summary

## A1 Draft 1

$initial_draft

## Challenger spar log ($challenger_model, context-isolated)
$all_challenger

## Revisions
$all_revisions

## Final draft

$final_draft

## Instructions

Write the complete comms file to: $outfile

Follow §6 structure exactly. Include contact header, angle rationale, A1 Draft 1, all A2 responses, revision drafts, final draft, fact provenance table, and roster a_note line. The contact header fields are: Contact, Response likelihood ({n}%, from the response_likelihood value in the contact details above), Warmth level, Channel, Language, Angle, Profile richness.

Run §7 quality checklist before writing. Fix any failures in the final draft.

After writing, estimate the response likelihood for this contact as a whole-number percentage, based on warmth level, angle quality, challenger verdict, and channel availability. Print exactly:
RESPONSE_LIKELIHOOD: {n}%

Then print: DONE: $contact_summary | $outfile"

set assembly_log "${log_prefix}-author-assembly.log"
write_file [file join $prompt_dir assembly.txt] $assembly_prompt

if {[invoke_claude "assembly" $assembly_log \
        --resume $author_session $assembly_prompt]} {
    exit 1
}

# ── Post-assembly validation ──────────────────────────────────────────

set contact_name [string trim [lindex [split $contact_summary |] 0]]
if {[file exists $outfile]} {
    if {[validate_and_correct $outfile $roster_email $contact_name \
            $author_session $log_prefix $slug]} {
        exit 1
    }
}

# ── Summary ────────────────────────────────────────────────────────────

# Sum costs from JSONL log
set total_cost 0.0
if {[file exists $cost_log]} {
    set fd [open $cost_log r]
    while {[gets $fd line] >= 0} {
        set line [string trim $line]
        if {$line eq ""} continue
        if {[catch {set d [::json::json2dict $line]}]} continue
        set c [spar::dict_get_default $d cost 0]
        set total_cost [expr {$total_cost + $c}]
    }
    close $fd
}

if {[file exists $outfile]} {
    puts "DONE: $slug ($round round(s), verdict=$verdict, cost=\$$total_cost)"

    # Update roster response_likelihood via trdsql
    set assembly_text [read_file $assembly_log]
    set band_likelihood ""
    foreach line [split $assembly_text \n] {
        if {[string match "RESPONSE_LIKELIHOOD:*" $line]} {
            regexp {\d+} $line band_likelihood
        }
    }
    if {$band_likelihood ne ""} {
        set roster_path [file join [file dirname [file dirname $outfile]] roster.tsv]
        set contact_name [lindex [split $contact_summary |] 0]
        set contact_name [string trim $contact_name]

        if {[file exists $roster_path]} {
            # Read header columns to build SELECT
            set fd [open $roster_path r]
            set header_line [gets $fd]
            close $fd
            set header_line [string trimright $header_line \r]
            set cols [split $header_line \t]

            set safe_name [string map {' ''} $contact_name]
            set select_parts {}
            foreach col $cols {
                if {$col eq "response_likelihood"} {
                    lappend select_parts "CASE WHEN contact_name='${safe_name}' THEN '${band_likelihood}' ELSE \"response_likelihood\" END AS \"response_likelihood\""
                } else {
                    lappend select_parts "\"${col}\""
                }
            }
            set select_list [join $select_parts ,]

            set tmp [exec mktemp]
            set lock_hash [lindex [split [exec echo $roster_path | md5sum] " "] 0]
            set lock_file "/tmp/spar-roster-[string range $lock_hash 0 7].lock"

            if {[catch {
                exec flock -x $lock_file \
                    trdsql -ih -oh -id \t -od \t \
                    "SELECT ${select_list} FROM \"${roster_path}\"" > $tmp
                file rename -force $tmp $roster_path
                puts "  roster update: ${contact_name} → response_likelihood=${band_likelihood}%"
            } err]} {
                puts "  roster update failed: $err"
                catch {file delete $tmp}
            }
        }
    }
} else {
    puts "WARN: $slug completed but $outfile not found (cost=\$$total_cost)"
}

exit 0

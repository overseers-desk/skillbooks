#!/usr/bin/env tclsh9.0
# spar-a-harness.tcl — Approach-phase harness. One process per contact.
#
# Wraps the author's single resumed session (draft → revise → assemble) plus
# context-isolated challenger rounds, with DbC-Post validate_and_correct.
#
# Usage: tclsh9.0 spar-a-harness.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: author-draft.txt, challenger-template.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-claude.tcl]

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh9.0 spar-a-harness.tcl <prompt-dir> <log-dir>"
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
        set val [string trim $val "\""]
        dict set meta $key $val
    }
}
close $fd

set max_rounds [dict get $meta MAX_ROUNDS]
set outfile [dict get $meta OUTFILE]
set contact_summary [dict get $meta CONTACT_SUMMARY]
set challenger_model [spar::dict_get_default $meta CHALLENGER_MODEL sonnet]
set roster_email [spar::dict_get_default $meta ROSTER_EMAIL ""]
set roster_organisation [spar::dict_get_default $meta ROSTER_ORGANISATION ""]

set log_prefix [file join $log_dir $slug]
file mkdir $log_dir

# ── ApproachHarness class ─────────────────────────────────────────────

oo::class create spar::ApproachHarness {
    superclass spar::Harness

    # validate_and_correct -- DbC-Post loop for approach files. Attempts
    # 1-2 use the current model; attempt 3 escalates to opus. Returns 0 on
    # clean validation, 1 if still broken after max_fix fix rounds.
    method validate_and_correct {outfile roster_email contact_name {roster_organisation ""}} {
        set max_fix 3
        set slug [my slug]
        set lp   [my log_prefix]

        for {set attempt 1} {$attempt <= $max_fix} {incr attempt} {
            set errors [spar::validate_approach $outfile $roster_email $contact_name $roster_organisation]
            set hard {}
            foreach e $errors {
                if {[dict get $e severity] eq "error"} { lappend hard $e }
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

            set fix_log "${lp}-fix${attempt}.log"
            set fix_prompt "The approach file you just wrote failed validation:\n\n$error_text\n\nRewrite the file at $outfile to fix these errors. The to: field in each email message must be a real email address (not a placeholder). It must match the roster email: $roster_email"

            set model_args {}
            if {$attempt == 3} { set model_args [list --model opus] }

            if {[my resume "fix${attempt}" $fix_log $fix_prompt {*}$model_args]} {
                return 1
            }
        }

        set errors [spar::validate_approach $outfile $roster_email $contact_name $roster_organisation]
        foreach e $errors {
            if {[dict get $e severity] eq "error"} {
                puts "FAIL (validation failed after $max_fix retries): $slug"
                return 1
            }
        }
        return 0
    }
}

set harness [spar::ApproachHarness new $slug $log_prefix]

# ── Author: draft ──────────────────────────────────────────────────────

puts "\[$slug\] \[phase: drafting\]"
puts "\[$slug\] Author: drafting..."
set author_draft_log "${log_prefix}-author-draft.log"
set author_prompt [spar::read_file [file join $prompt_dir author-draft.txt]]

if {[$harness call "author-draft" $author_draft_log $author_prompt]} {
    exit 1
}

set draft_text [spar::read_file $author_draft_log]
set draft [spar::extract_between $draft_text "DRAFT_START" "DRAFT_END"]
if {$draft eq ""} {
    puts "FAIL (no draft markers): $slug"
    exit 1
}

set rationale [spar::extract_between $draft_text "RATIONALE_START" "RATIONALE_END"]
spar::write_file [file join $prompt_dir draft-current.txt] $draft
spar::write_file [file join $prompt_dir rationale.txt] $rationale

# ── Spar loop ──────────────────────────────────────────────────────────
#
# The challenger runs fresh each round (context-isolated), so it uses its
# own short-lived harness. The author is the persistent $harness — its
# session_id is what gets resumed.

set round 0
set verdict "REVISE"

while {$round < $max_rounds && $verdict eq "REVISE"} {
    incr round
    puts "\[$slug\] \[phase: challenger $round/$max_rounds\]"
    puts "\[$slug\] Challenger round $round/$max_rounds..."

    set challenger_template [spar::read_file [file join $prompt_dir challenger-template.txt]]
    set current_draft [spar::read_file [file join $prompt_dir draft-current.txt]]
    set challenger_prompt [string map [list __DRAFT_PLACEHOLDER__ $current_draft] $challenger_template]

    # Challenger runs fresh (no --resume). Harness::call only captures a
    # session_id on the first successful call, so subsequent `call`
    # invocations are context-isolated but still accumulate cost to the
    # shared ledger.
    set challenger_log "${log_prefix}-challenger-round${round}.log"
    if {[$harness call "challenger-round${round}" $challenger_log $challenger_prompt --model $challenger_model]} {
        exit 1
    }

    file copy -force $challenger_log [file join $prompt_dir "challenger-round${round}.txt"]

    set challenger_text [spar::read_file $challenger_log]
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

    puts "\[$slug\] \[phase: revising $round\]"
    puts "\[$slug\] Challenger round $round: REVISE — author revising..."

    set author_rev_log "${log_prefix}-author-rev${round}.log"
    set challenger_feedback [spar::read_file [file join $prompt_dir "challenger-round${round}.txt"]]

    set rev_prompt "This is revision round $round. A challenger (context-isolated, playing the recipient) reacted to your draft and fact-checked it.

## Challenger feedback (round $round)

$challenger_feedback

## Instructions

Revise the draft to address valid concerns. Do not over-correct. If the reaction was positive on a point, keep it. If a factual error was flagged, fix it. If the tone was off, adjust.

Output the revised draft between DRAFT_START and DRAFT_END markers. Output any updated rationale between RATIONALE_START and RATIONALE_END."

    spar::write_file [file join $prompt_dir "author-rev${round}.txt"] $rev_prompt

    if {[$harness resume "author-rev${round}" $author_rev_log $rev_prompt]} {
        exit 1
    }

    set rev_text [spar::read_file $author_rev_log]
    set revised_draft [spar::extract_between $rev_text "DRAFT_START" "DRAFT_END"]
    if {$revised_draft ne ""} {
        spar::write_file [file join $prompt_dir draft-current.txt] $revised_draft
    }
    set revised_rationale [spar::extract_between $rev_text "RATIONALE_START" "RATIONALE_END"]
    if {$revised_rationale ne ""} {
        spar::write_file [file join $prompt_dir rationale.txt] $revised_rationale
    }
}

# ── Author: assemble ───────────────────────────────────────────────────

puts "\[$slug\] \[phase: assembling\]"
puts "\[$slug\] Author: assembling..."

set all_challenger ""
for {set r 1} {$r <= $round} {incr r} {
    set cfile [file join $prompt_dir "challenger-round${r}.txt"]
    if {[file exists $cfile]} {
        append all_challenger "\n### A2 Response $r\n\n[spar::read_file $cfile]\n"
    }
}

set all_revisions ""
for {set r 1} {$r <= $round} {incr r} {
    set rev_log "${log_prefix}-author-rev${r}.log"
    if {[file exists $rev_log]} {
        set rev_draft [spar::extract_between [spar::read_file $rev_log] "DRAFT_START" "DRAFT_END"]
        if {$rev_draft ne ""} {
            append all_revisions "\n### A1 Draft [expr {$r + 1}]\n\n$rev_draft\n"
        }
    }
}

set initial_draft [spar::extract_between [spar::read_file "${log_prefix}-author-draft.log"] "DRAFT_START" "DRAFT_END"]
set final_draft [spar::read_file [file join $prompt_dir draft-current.txt]]

set assembly_prompt "Write the final approach file. You have the method, overview, antifacts, goal, and profile from your drafting context. Refer to §6 (approach file structure) and §7 (quality checklist) in the method file.

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

Write the complete approach file to: $outfile

Follow §6 structure exactly. Include contact header, angle rationale, A1 Draft 1, all A2 responses, revision drafts, final draft, fact provenance table, and roster a_note line. The contact header fields are: Contact, Response likelihood ({n}%, from the response_likelihood value in the contact details above), Warmth level, Channel, Language, Angle, Profile yield.

The YAML MUST include a top-level generated_for block recording the roster contact_name and organisation as of generation time:

generated_for:
  contact_name: <contact name from Contact details>
  organisation: <organisation from Contact details>

This block is used to detect roster edits that post-date the approach file. Write the values exactly as given in the Contact details section.

Run §7 quality checklist before writing. Fix any failures in the final draft.

After writing, estimate the response likelihood for this contact as a whole-number percentage, based on warmth level, angle quality, challenger verdict, and channel availability. Print exactly:
RESPONSE_LIKELIHOOD: {n}%

Then print: DONE: $contact_summary | $outfile"

set appendix_path [file join $prompt_dir appendix-assembly.txt]
if {[file exists $appendix_path]} {
    set appendix_text [spar::read_file $appendix_path]
    if {[string trim $appendix_text] ne ""} {
        append assembly_prompt "\n\n$appendix_text"
    }
}

set assembly_log "${log_prefix}-author-assembly.log"
spar::write_file [file join $prompt_dir assembly.txt] $assembly_prompt

# DbC-Pre: pre-conditions for assembly are that the upstream draft / spar /
# revision logs all exist and are non-empty (those AI calls only mutate
# workdir log files, not project state, so they do not need their own DbC
# pairs). The approach file does not yet exist; the assembly call is what
# creates it. Assert rather than trust — a silently empty prior log would
# otherwise feed assembly malformed input and be misattributed.
set required_logs [list "${log_prefix}-author-draft.log"]
for {set r 1} {$r <= $round} {incr r} {
    lappend required_logs "${log_prefix}-challenger-round${r}.log"
}
# Revision logs exist for each round whose verdict was REVISE. The final
# round breaks out on DONE without writing a rev log.
set rev_rounds [expr {$verdict eq "DONE" ? $round - 1 : $round}]
for {set r 1} {$r <= $rev_rounds} {incr r} {
    lappend required_logs "${log_prefix}-author-rev${r}.log"
}
foreach _log $required_logs {
    if {![file exists $_log]} {
        puts "FAIL (DbC-Pre: assembly precondition log missing: $_log): $slug"
        exit 1
    }
    if {[file size $_log] == 0} {
        puts "FAIL (DbC-Pre: assembly precondition log empty: $_log): $slug"
        exit 1
    }
}
if {[$harness resume "assembly" $assembly_log $assembly_prompt]} {
    exit 1
}

# ── Post-assembly validation ──────────────────────────────────────────

# DbC-Post: pair for the assembly call above. ApproachHarness's
# validate_and_correct runs spar::validate_approach on the file the agent
# just wrote; on error it resumes the agent with the specific failure
# (this is the "blame the renter" half of the contract).
set contact_name [string trim [lindex [split $contact_summary |] 0]]
if {[file exists $outfile]} {
    if {[$harness validate_and_correct $outfile $roster_email $contact_name $roster_organisation]} {
        exit 1
    }
}

# ── Summary ────────────────────────────────────────────────────────────

set total_cost [$harness cost_total]

if {[file exists $outfile]} {
    puts "DONE: $slug ($round round(s), verdict=$verdict, cost=\$$total_cost)"

    # Update roster response_likelihood via sqlite3
    set assembly_text [spar::read_file $assembly_log]
    set band_likelihood ""
    foreach line [split $assembly_text \n] {
        if {[string match "RESPONSE_LIKELIHOOD:*" $line]} {
            regexp {\d+} $line band_likelihood
        }
    }
    if {$band_likelihood ne ""} {
        set roster_path [file join [file dirname [file dirname $outfile]] roster.tsv]
        set contact_name [string trim [lindex [split $contact_summary |] 0]]
        if {[file exists $roster_path]} {
            # Emit a ROSTER_UPDATE marker; the dispatcher applies it from
            # its single-threaded event loop (no flock from here).
            puts "ROSTER_UPDATE\t$roster_path\tcontact_name\t$contact_name\tresponse_likelihood\t$band_likelihood"
            flush stdout
        }
    }
} else {
    puts "WARN: $slug completed but $outfile not found (cost=\$$total_cost)"
}

exit 0

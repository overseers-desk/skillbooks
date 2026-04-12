#!/usr/bin/env tclsh
# spar-p-harness.tcl — Profile-phase harness. One process per contact.
#
# Wraps a single claude session that authors profiles/{stem}.md, plus the
# DbC-Post validate_and_correct loop (validate_profile + masked-email
# roster sanitisation). Structural twin of spar-a-harness.tcl, minus the
# challenger spar.
#
# Usage: tclsh spar-p-harness.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: prompt.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-claude.tcl]

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh spar-p-harness.tcl <prompt-dir> <log-dir>"
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

set outfile [dict get $meta OUTFILE]
set roster_path [dict get $meta ROSTER_PATH]
set stem [dict get $meta STEM]

set log_prefix [file join $log_dir $slug]
file mkdir $log_dir

# ── ProfileHarness class ──────────────────────────────────────────────

oo::class create spar::ProfileHarness {
    superclass spar::Harness

    # Load the current roster row for this slug. Used by both validation
    # and the masked-email sanitiser.
    method _roster_row {roster_path slug} {
        if {![file exists $roster_path]} { return [dict create] }
        foreach r [spar::load_roster $roster_path] {
            if {[spar::dict_get_default $r stem ""] eq $slug} { return $r }
        }
        return [dict create]
    }

    # DbC-Post: if the agent wrote a masked email (e.g. "b***@foo.com") to
    # the roster, blank the field. A masked address is worse than empty —
    # it inflates "has email" counts and propagates into approach files.
    method sanitise_roster_email {roster_path slug} {
        if {![file exists $roster_path]} { return }
        set rows [spar::load_roster $roster_path]
        set dirty 0
        set updated {}
        foreach row $rows {
            if {[spar::dict_get_default $row stem ""] eq $slug} {
                set email [string trim [spar::dict_get_default $row email ""]]
                if {[spar::is_masked_email $email]} {
                    puts "\[[my slug]\] Guardrail: blanked masked email '$email' in roster"
                    dict set row email ""
                    set dirty 1
                }
            }
            lappend updated $row
        }
        if {$dirty} { spar::write_roster $roster_path $updated }
    }

    # DbC-Post loop for profile files. Attempts 1-2 use the current model;
    # attempt 3 escalates to opus. Returns 0 on clean validation, 1 if
    # still broken after max_fix rounds.
    method validate_and_correct {outfile roster_path} {
        set max_fix 3
        set slug [my slug]
        set lp   [my log_prefix]

        for {set attempt 1} {$attempt <= $max_fix} {incr attempt} {
            if {![file exists $outfile]} {
                puts "\[$slug\] Profile missing at $outfile (attempt $attempt/$max_fix)"
                set row [my _roster_row $roster_path $slug]
                set error_text "- \[missing_profile\] The profile file was not written to $outfile"

                set fix_log "${lp}-fix${attempt}.log"
                set fix_prompt "You did not produce a profile file. Write it now to: $outfile\n\nFollow SPAR-P §5 structure. The file MUST begin with a YAML front-matter block per §5.1."

                set model_args {}
                if {$attempt == 3} { set model_args [list --model opus] }
                if {[my resume "fix${attempt}" $fix_log $fix_prompt {*}$model_args]} {
                    return 1
                }
                continue
            }

            set row [my _roster_row $roster_path $slug]
            set errors [spar::validate_profile $outfile $row $slug]
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
            set fix_prompt "The profile file you just wrote ($outfile) failed validation:\n\n$error_text\n\nRewrite the file to fix these errors. The YAML front matter (SPAR-P §5.1) is required and must carry profile_date, star_rating, richness, richness_count, warmth_finding, applicable_angles, and a dependent_data snapshot of contact_name/organisation/role/date_excluded from the roster. Do not remove or rename any front-matter key."

            set model_args {}
            if {$attempt == 3} { set model_args [list --model opus] }

            if {[my resume "fix${attempt}" $fix_log $fix_prompt {*}$model_args]} {
                return 1
            }
        }

        set row [my _roster_row $roster_path $slug]
        set errors [spar::validate_profile $outfile $row $slug]
        foreach e $errors {
            if {[dict get $e severity] eq "error"} {
                puts "FAIL (validation failed after $max_fix retries): $slug — [dict get $e message]"
                return 1
            }
        }
        return 0
    }
}

# ── Run ────────────────────────────────────────────────────────────────

set harness [spar::ProfileHarness new $slug $log_prefix]

puts "\[$slug\] Profile: researching..."
set draft_log "${log_prefix}-profile.log"
set prompt [spar::read_file [file join $prompt_dir prompt.txt]]

# DbC-Pre: roster integrity for this segment was validated at
# dispatch_profiles entry (load_roster enforces field-count assertion;
# required input files existence-checked there). The agent inherits a
# roster known to be well-formed.
if {[$harness call "profile" $draft_log $prompt]} {
    exit 1
}

# DbC-Post: sanitise masked emails written to the roster, then run
# validate_profile on the front matter — agent-introduced damage fails
# the harness with a specific reason after max_fix retries.
$harness sanitise_roster_email $roster_path $slug

if {[$harness validate_and_correct $outfile $roster_path]} {
    exit 1
}

set total_cost [$harness cost_total]
puts "DONE: $slug (cost=\$$total_cost)"
exit 0

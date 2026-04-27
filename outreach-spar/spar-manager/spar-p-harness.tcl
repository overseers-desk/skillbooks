#!/usr/bin/env tclsh9.0
# spar-p-harness.tcl — Profile-phase harness. One process per contact.
#
# Wraps a single claude session that authors profiles/{stem}.md, plus the
# DbC-Post validate_and_correct loop (validate_profile + masked-email
# roster sanitisation). Structural twin of spar-a-harness.tcl, minus the
# challenger spar.
#
# Usage: tclsh9.0 spar-p-harness.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: prompt.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-claude.tcl]

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh9.0 spar-p-harness.tcl <prompt-dir> <log-dir>"
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
set p_strict [spar::dict_get_default $meta P_STRICT 0]
set contact_name [spar::dict_get_default $meta CONTACT_NAME ""]
set contact_org [spar::dict_get_default $meta CONTACT_ORG ""]
set contact_email [spar::dict_get_default $meta CONTACT_EMAIL ""]

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
    # Emits a ROSTER_UPDATE marker per match; the dispatcher applies it.
    method sanitise_roster_email {roster_path slug} {
        if {![file exists $roster_path]} { return }
        foreach row [spar::load_roster $roster_path] {
            if {[spar::dict_get_default $row stem ""] ne $slug} continue
            set email [string trim [spar::dict_get_default $row email ""]]
            if {[spar::is_masked_email $email]} {
                puts "\[[my slug]\] Guardrail: blanked masked email '$email' in roster"
                puts "ROSTER_UPDATE\t$roster_path\tstem\t$slug\temail\t"
                flush stdout
            }
        }
    }

    # DbC-Post loop for profile files. Attempts 1-2 use the current model;
    # attempt 3 escalates to opus. Returns 0 on clean validation, 1 if
    # still broken after max_fix rounds. p_strict opts into the §4.3/§4.4
    # mandatory-skill audit (issue #76).
    method validate_and_correct {outfile roster_path p_strict} {
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
            # Also run segment-scoped roster checks and surface any
            # error-severity issue whose contact_name matches this slug.
            # This is how within-segment duplicate categories
            # (roster_duplicate_name_org = case_1,
            #  roster_shared_inbox_collision = case_2) reach the
            # per-harness resume loop.
            set my_cname [string trim [spar::dict_get_default $row contact_name ""]]
            set segment_dir [file dirname $roster_path]
            if {$my_cname ne ""} {
                if {[catch {spar::classify_segment $segment_dir} seg_contacts]} {
                    set seg_contacts {}
                }
                foreach ri [spar::validate_roster $seg_contacts] {
                    if {[dict get $ri severity] ne "error"} continue
                    if {[dict get $ri contact_name] ne $my_cname} continue
                    lappend errors $ri
                }
            }

            # Issue #76: transcript-based audit that the agent invoked the
            # mandatory linkedin and facebook skills (SPAR-P §4.3, §4.4).
            # Skipped when p_strict is off, the row is legitimately
            # excluded (date_excluded set per §4.1/§4.2/§4.8), or
            # session_id was never captured. transcript_not_found is
            # returned at warning severity and falls through the existing
            # error-only filter below.
            if {$p_strict eq "1" \
                    && [string trim [spar::dict_get_default $row date_excluded ""]] eq "" \
                    && [my session_id] ne ""} {
                foreach ai [spar::audit_skills_in_transcript \
                                [my session_id] {linkedin facebook} $my_cname] {
                    lappend errors $ai
                }
            }

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

            # When the §4.3/§4.4 audit fires, prepend a single high-priority
            # instruction so the agent does not bury the skill invocation
            # under the rest of the error bag.
            set audit_preamble ""
            set audit_present {}
            foreach e $hard {
                set _c [dict get $e code]
                if {$_c eq "linkedin_lookup_missing" || $_c eq "facebook_lookup_missing"} {
                    lappend audit_present $_c
                }
            }
            if {[llength $audit_present] > 0} {
                set _parts {}
                foreach _c $audit_present {
                    if {$_c eq "linkedin_lookup_missing"} {
                        lappend _parts "invoke the linkedin skill (Skill tool with skill=linkedin) to fetch and parse the LinkedIn profile per SPAR-P §4.3"
                    } else {
                        lappend _parts "invoke the facebook skill (Skill tool with skill=facebook) to fetch and parse the Facebook profile per SPAR-P §4.4"
                    }
                }
                set audit_preamble "FIRST: [join $_parts { AND }]. Then re-derive any front-matter fields whose values depend on that data (warmth_finding, applicable_angles).\n\n"
            }

            set fix_prompt "${audit_preamble}The profile for $slug failed post-validation:\n\n$error_text\n\nFor errors in the profile file (malformed/missing front matter, missing required keys, invalid enum values, stale dependent_data) rewrite $outfile per SPAR-P §5 — the YAML front matter §5.1 is required and must carry profile_date, star_rating, yield, warmth_finding, applicable_angles, and a dependent_data snapshot of contact_name/organisation/role/date_excluded; do not remove or rename any front-matter key.\n\nFor errors about the roster row (profile_unreachable_without_exclusion) edit the roster TSV for stem '$slug' per SPAR-P §4.8/§4.15 using sqlite3 — either set date_excluded='no reachable channel (YYYY-MM-DD)' if the contact has no email, LinkedIn, Facebook, or phone and cannot be researched, or backfill a channel by further research.\n\nFor roster_shared_inbox_collision: the email you wrote is already used by another contact at the same organisation in this segment. Per SPAR-P §4.8 shared-inbox rule, either (1) research a non-shared personal or direct email address for this contact and write that instead, or (2) leave this contact's email field empty (sqlite3 UPDATE … SET email='') and allow the approach to proceed via LinkedIn or phone. Do not overwrite the other contact's email.\n\nFor roster_duplicate_name_org: the roster already contains another row with the same contact_name and organisation in this segment. The two rows are a true duplicate. Set date_excluded on the row for stem '$slug' with reason 'duplicate of existing row ([date])' and do not produce a profile; the existing row's profile stands."

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

$harness inject_mailroom \
    [file join $prompt_dir prompt.txt] \
    $contact_name $contact_org $contact_email

puts "\[$slug\] \[phase: researching\]"
puts "\[$slug\] Profile: researching..."
set draft_log "${log_prefix}-profile.log"
set prompt [spar::read_file [file join $prompt_dir prompt.txt]]

# DbC-Pre: roster integrity for this segment was validated at
# spar::p::_run_segment entry (load_roster enforces field-count assertion;
# required input files existence-checked there). The agent inherits a
# roster known to be well-formed.
if {[$harness call "profile" $draft_log $prompt]} {
    exit 1
}

# DbC-Post: sanitise masked emails written to the roster, then run
# validate_profile on both the front matter and roster-row invariants
# (#39 R1: profile_unreachable_without_exclusion — profile exists iff the
# row has a reachable channel or date_excluded is set). Agent-introduced
# damage fails the harness with a specific reason after max_fix retries.
$harness sanitise_roster_email $roster_path $slug

if {[$harness validate_and_correct $outfile $roster_path $p_strict]} {
    exit 1
}

set total_cost [$harness cost_total]
puts "DONE: $slug (cost=\$$total_cost)"
exit 0

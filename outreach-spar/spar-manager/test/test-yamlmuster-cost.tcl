#!/usr/bin/env tclsh9.0
# test-yamlmuster-cost.tcl — the partial-validation claim as an asserted
# number, on the approach transition gate. The gate (spar::_approach_gate_error,
# reached via spar::State approach_validation_error) validates with
# -severities error -limit 1, so it must (1) never select a warning-declared
# rule and (2) unwind at the first error. This file pins both against the
# compiled approach ruleset's cost account (`stats`).
#
# run.tcl runs each test file in its own tclsh subprocess, so the lazy
# per-kind yamlmuster instance is fresh here and its `stats` reflect only the
# calls this file makes.

package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

# Error-tagged approach-rule count, pinned from rules/approach.rules. The
# ruleset compiles to 20 rules; 4 are warning-declared, leaving 16 error rules:
#
#   error   vocab root, decisions, round, message, parent,            (8)
#           fact_check_item, fact_provenance_item, script_item
#   error   require decisions (missing_decisions)                     (1)
#   error   predicate rounds_structural (missing_rounds/no_final)     (1)
#   error   predicate placeholder_to                                  (1)
#   error   predicate first_line_is_profile_hash (-needs approach_path) (1)
#   error   predicate profile_hash_actual        (-needs approach_path) (1)
#   error   predicate linkedin_guard                                  (1)
#   error   atmost too_many_final_emails                              (1)
#   error   require reply_missing_parent_message_id                   (1)
#   ------------------------------------------------------------------ 16
#   warning require draft_missing_number, review_missing_number,      (4)
#           require email_missing_content (reply + non-reply variants)
#
# The gate passes approach_path, so both -needs-gated hash predicates select;
# rules_selected below asserts the 16 back from the engine, failing loudly if
# the ruleset's error count ever drifts from this pin.
set ERROR_RULES 16

# ════════════════════════════════════════════════════════════════════════
# 1. Clean fixture: the gate returns no error and evaluates no warning rule.
# ════════════════════════════════════════════════════════════════════════
section "1. gate cost on a clean approach"

set seg [make_temp_segment]
write_profile $seg "cost-clean"
set ap [write_approach_yaml $seg "cost-clean" [approach_yaml_final_unsent]]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Cost Clean" stem "cost-clean"}] \
]

set State [spar::State new]
set contacts [$State classify_segment $seg]
set contact [lindex $contacts 0]

set gate_err [$State approach_validation_error $contact]
assert_eq $gate_err "" "clean approach → gate returns no error"

set gate_stats [[spar::_yamlmuster_approach] stats]
set gate_selected  [dict get $gate_stats rules_selected]
set gate_evaluated [dict get $gate_stats rules_evaluated]

assert_eq $gate_selected $ERROR_RULES \
    "gate selects exactly the $ERROR_RULES error-declared rules (no warning rules)"
assert_eq [expr {$gate_evaluated <= $ERROR_RULES}] 1 \
    "gate evaluates at most the error-rule count ($gate_evaluated <= $ERROR_RULES)"

# ════════════════════════════════════════════════════════════════════════
# 2. The gate evaluates no more than a full validate over the same file.
# ════════════════════════════════════════════════════════════════════════
section "2. gate cost <= full-validate cost"

set full_issues [spar::validate_approach $ap "" "Cost Clean"]
set full_stats [[spar::_yamlmuster_approach] stats]
set full_evaluated [dict get $full_stats rules_evaluated]

# Sanity: the clean fixture is genuinely clean under a full run too.
assert_eq [llength $full_issues] 0 "clean approach → full validate has no issues"
assert_eq [expr {$gate_evaluated <= $full_evaluated}] 1 \
    "gate evaluated ($gate_evaluated) <= full evaluated ($full_evaluated)"

# ════════════════════════════════════════════════════════════════════════
# 3. Broken fixture: -limit 1 unwinds at the first error.
# ════════════════════════════════════════════════════════════════════════
section "3. -limit 1 early exit on a broken approach"

# A valid approach with `decisions` removed: vocab root finds no unknown key,
# then require decisions emits missing_decisions and the gate stops there.
set broken {rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
}
set bp [write_approach_yaml $seg "cost-broken" $broken]
set badata [spar::read_approach_yaml $bp]
set berr [spar::_approach_gate_error $badata $bp "" "Cost Broken"]
assert_eq [expr {$berr ne ""}] 1 "broken approach → gate returns an error"

set broken_stats [[spar::_yamlmuster_approach] stats]
set broken_evaluated [dict get $broken_stats rules_evaluated]
set broken_errors [dict get $broken_stats errors_emitted]

assert_eq $broken_errors 1 "-limit 1 → exactly one error emitted before unwinding"
assert_eq [expr {$broken_evaluated < $ERROR_RULES}] 1 \
    "early exit evaluates fewer than the full error-rule count ($broken_evaluated < $ERROR_RULES)"

$State destroy
finish_tests

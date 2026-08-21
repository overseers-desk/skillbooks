#!/usr/bin/env tclsh9.0
# Campaign stems allowlist (segments.<seg>.stems): scope helper,
# load-time shape validation, eligibility confinement, roster
# cross-check warning, and P-dispatch agreement.
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 1. spar::campaign_stem_in_scope — scope truths
# ════════════════════════════════════════════════════════════════════════
section "1. campaign_stem_in_scope"

assert_eq [spar::campaign_stem_in_scope {} segA alpha] 1 \
    "empty cdata → in scope"
assert_eq [spar::campaign_stem_in_scope {segments {segA segB}} segA alpha] 1 \
    "legacy list-form segments → in scope"
assert_eq [spar::campaign_stem_in_scope {segments {segA {objective o}}} segA alpha] 1 \
    "plan block without stems → in scope"
assert_eq [spar::campaign_stem_in_scope {segments {segA {stems {alpha beta}}}} segA alpha] 1 \
    "listed stem → in scope"
assert_eq [spar::campaign_stem_in_scope {segments {segA {stems {alpha beta}}}} segA gamma] 0 \
    "unlisted stem → out of scope"
assert_eq [spar::campaign_stem_in_scope {segments {segA {stems {alpha}}}} segB alpha] 1 \
    "other segment unconstrained → in scope"

# ════════════════════════════════════════════════════════════════════════
# 2. load_campaign — stems shape validation
# ════════════════════════════════════════════════════════════════════════
section "2. load_campaign stems validation"

proc _cs_write_campaign {stems_yaml} {
    set base [make_temp_campaign]
    set yaml [file join $base campaigns camp.yaml]
    file mkdir [file join $base campaigns]
    set fd [open $yaml w]
    puts $fd "campaign: Test"
    puts $fd "segments:"
    puts $fd "  sega:"
    puts $fd "    objective: test"
    if {$stems_yaml ne ""} { puts $fd $stems_yaml }
    close $fd
    return $yaml
}

set cs_ok [_cs_write_campaign "    stems:\n      - alpha\n      - beta"]
set cs_data [spar::load_campaign $cs_ok]
assert_eq [dict get $cs_data segments sega stems] {alpha beta} \
    "valid stems list parses through"

assert_error {spar::load_campaign [_cs_write_campaign "    stems: \[\]"]} \
    "*stems is empty*" "empty stems list errors"
assert_error {spar::load_campaign [_cs_write_campaign "    stems:\n      - alpha\n      - alpha"]} \
    "*lists 'alpha' twice*" "duplicate stem errors"
assert_error {spar::load_campaign [_cs_write_campaign "    stems:\n      - \"two words\""]} \
    "*non-empty stem slugs*" "multi-word entry errors"

set cs_none [_cs_write_campaign ""]
set cs_data2 [spar::load_campaign $cs_none]
assert_eq [dict exists $cs_data2 segments sega stems] 0 \
    "no stems key → none stored (regression guard)"

# ════════════════════════════════════════════════════════════════════════
# 3. transition_eligible — confinement across the report path
# ════════════════════════════════════════════════════════════════════════
section "3. transition_eligible confinement"

set te_seg [make_temp_segment]
set te_segname [file tail $te_seg]
write_roster_tsv $te_seg $::std_headers [list \
    [make_base_row {contact_name "A One" organisation "Org A" email "a@example.com" stem alpha}] \
    [make_base_row {contact_name "B Two" organisation "Org B" email "b@example.com" stem beta}] \
]
set te_contacts [$State classify_segment $te_seg [approach_dir_of $te_seg]]

set te_cdata [dict create segments [dict create $te_segname [dict create stems {alpha}]]]
set te_tasks [$State transition_eligible $te_contacts "T1" email $te_cdata ""]
assert_eq [llength $te_tasks] 1 "stems {alpha} → one T1 task"
assert_eq [dict get [lindex $te_tasks 0] stem] alpha "the task is alpha's"

set te_tasks_all [$State transition_eligible $te_contacts "T1" email {} ""]
assert_eq [llength $te_tasks_all] 2 "no cdata → both rows eligible (regression guard)"

set te_cdata_nostems [dict create segments [dict create $te_segname [dict create objective o]]]
set te_tasks_ns [$State transition_eligible $te_contacts "T1" email $te_cdata_nostems ""]
assert_eq [llength $te_tasks_ns] 2 "plan block without stems → both rows eligible"

# ════════════════════════════════════════════════════════════════════════
# 4. build_warnings — stems_unknown roster cross-check
# ════════════════════════════════════════════════════════════════════════
section "4. stems_unknown warning"

package require spar::validate

set wu_cdata [dict create segments [dict create $te_segname [dict create stems {alpha ghost}]]]
set wu_issues [spar::validate_campaign_stems $te_contacts $wu_cdata]
assert_eq [llength [issues_with_code $wu_issues stems_unknown]] 1 \
    "one unknown stem → one stems_unknown warning"
assert_match [dict get [lindex $wu_issues 0] message] "*ghost*" \
    "warning names the unknown stem"

set wu_clean [spar::validate_campaign_stems $te_contacts \
    [dict create segments [dict create $te_segname [dict create stems {alpha beta}]]]]
assert_eq [llength $wu_clean] 0 "all stems known → no warning"

# Integration: through build_warnings the issue must arrive in the
# {severity segment contact message} shape spar-progress.tcl reads, in
# the trailing validation_issues run its head-trim arithmetic assumes.
set wu_warn [spar::build_warnings $te_contacts $wu_cdata]
set wu_vi [dict get $wu_warn validation_issues]
set wu_ghost {}
foreach _i $wu_vi {
    if {[string match "*ghost*" [dict get $_i message]]} { lappend wu_ghost $_i }
}
assert_eq [llength $wu_ghost] 1 "build_warnings carries the stems_unknown issue"
assert_eq [dict exists [lindex $wu_ghost 0] contact] 1 \
    "issue reshaped to the declared contact key"
# Trailing-run invariant: the last llength(validation_issues) entries of
# messages are exactly the validation issues, so the head-trim
# arithmetic in spar-progress.tcl stays valid with stems included.
set wu_msgs [dict get $wu_warn messages]
set wu_tail [lrange $wu_msgs end-[expr {[llength $wu_vi]-1}] end]
set wu_tail_ghost 0
foreach _m $wu_tail { if {[string match "*ghost*" $_m]} { incr wu_tail_ghost } }
assert_eq $wu_tail_ghost 1 "stems message sits in the trailing validation run"
# The spar-progress.tcl grouping loop must not throw on any issue shape.
set wu_grouped {}
foreach _i $wu_vi { lappend wu_grouped [dict get $_i contact] }
assert_eq [llength $wu_grouped] [llength $wu_vi] \
    "progress-style grouping reads every issue"

# ════════════════════════════════════════════════════════════════════════
# 5. P dispatch loop — agreement with eligibility
# ════════════════════════════════════════════════════════════════════════
section "5. P prepare_for_pool honours campaign stems"

package require spar::prompts

proc _cs_make_dispatch_campaign {seg_name stems_yaml} {
    set base [make_temp_campaign]
    set seg [file join $base segments $seg_name]
    file mkdir $seg
    file mkdir [file join $base campaigns camp]
    write_roster_tsv $seg {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration date_excluded} [list \
        [dict create stem alpha contact_name "A One" organisation "Org A" sweep_iteration 1] \
        [dict create stem beta  contact_name "B Two" organisation "Org B" sweep_iteration 1] \
        [dict create stem gamma contact_name "C Three" organisation "Org C" sweep_iteration 1] \
    ]
    set fd [open [spar::segment_yaml_for_segment $seg] w]
    puts $fd "objective: test"
    close $fd
    set fd [open [file join $base overview.md] w]
    puts $fd "# Test overview"
    close $fd
    set yaml [file join $base campaigns camp.yaml]
    set fd [open $yaml w]
    puts $fd "campaign: Test"
    puts $fd "usp_document: ../overview.md"
    puts $fd "segments:"
    puts $fd "  $seg_name:"
    puts $fd "    objective: test"
    if {$stems_yaml ne ""} { puts $fd $stems_yaml }
    close $fd
    return $yaml
}

set dp_yaml [_cs_make_dispatch_campaign csdisp1 "    stems:\n      - alpha\n      - gamma"]
set dp_prep [spar::p::prepare_for_pool \
    [dict create campaign_file $dp_yaml] {apply {args {}}}]
assert_eq [llength [dict get $dp_prep rows]] 2 \
    "stems {alpha gamma} → P queues two of three rows"

set dp_yaml_all [_cs_make_dispatch_campaign csdisp2 ""]
set dp_prep_all [spar::p::prepare_for_pool \
    [dict create campaign_file $dp_yaml_all] {apply {args {}}}]
assert_eq [llength [dict get $dp_prep_all rows]] 3 \
    "no stems → P queues all three rows (regression guard)"

# ── Summary ─────────────────────────────────────────────────────────────
finish_tests

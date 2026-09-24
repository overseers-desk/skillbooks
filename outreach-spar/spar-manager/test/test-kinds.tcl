#!/usr/bin/env tclsh9.0
# Segment kinds (segment.yaml `kinds:`): the token list every profile of the
# segment states kind by kind, its authoring-time check, and the checklist
# passage the dispatcher renders from prompts/kinds-guidance.txt.
package require yaml
package require TclOO
package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts
package require spar::validate

section "extract_kinds"

assert_eq [spar::extract_kinds [dict create kinds {wedding naming funeral}] seg.yaml] \
    {wedding naming funeral} "tokens read back in order"
assert_eq [spar::extract_kinds [dict create title X] seg.yaml] {} \
    "absent list is empty"
assert_eq [catch {spar::extract_kinds [dict create kinds [list wedding ""]] seg.yaml}] 1 \
    "blank entry refused"

section "kinds_guidance: passage follows the list"

set g [spar::kinds_guidance {wedding naming funeral}]
assert_match $g "*wedding, naming, funeral*" "tokens listed verbatim"
assert_match $g "*none published*" "status vocabulary present"
assert_eq [spar::kinds_guidance {}] "" "no kinds, no passage"

section "segment.rules: kinds_list"

set tmpdir [exec mktemp -d /tmp/spar-test-kinds.XXXXXX]
file mkdir [file join $tmpdir segments]
set segbase [file join $tmpdir segments seg]
proc write_seed {segbase kinds_yaml} {
    set fd [open "$segbase.yaml" w]
    puts $fd "version: \"2.0\""
    puts $fd "title: Test segment"
    puts $fd "date: 2026-09-24"
    puts $fd "target_type: qualification-only"
    puts $fd "provenance: test"
    puts $fd "discovery_criteria: test"
    puts $fd "rating_rubric: test"
    puts $fd $kinds_yaml
    close $fd
    set fd [open "$segbase.sweep.yaml" w]
    puts $fd "version: \"2.0\""
    puts $fd "segment: seg"
    puts $fd "sources: \[\]"
    puts $fd "rounds: \[\]"
    close $fd
}
proc seed_codes {segbase} {
    lmap i [spar::validate_seed $segbase] {dict get $i code}
}
write_seed $segbase "kinds:\n  - wedding\n  - vow-renewal\n  - funeral"
assert_eq [expr {"invalid_kinds" in [seed_codes $segbase]}] 0 "token list passes"
assert_eq [expr {"unknown_key_root" in [seed_codes $segbase]}] 0 "kinds is a known key"
write_seed $segbase "kinds:\n  - wedding\n  - Wedding Ceremony\n  - wedding"
set codes [seed_codes $segbase]
assert_eq [llength [lsearch -all -exact $codes invalid_kinds]] 2 \
    "a non-token and a duplicate each error"
write_seed $segbase "scope_note: none"
assert_eq [expr {"invalid_kinds" in [seed_codes $segbase]}] 0 "absent list passes"
file delete -force $tmpdir
cleanup_temps

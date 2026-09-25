#!/usr/bin/env tclsh9.0
# Segment presence gate (segment.yaml `presence_gate:`): the checks whose
# joint emptiness excludes the row, their closed vocabulary, and
# the passage the dispatcher renders from prompts/presence-gate.txt.
package require yaml
package require TclOO
package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts
package require spar::validate

section "extract_presence_gate"

assert_eq [spar::extract_presence_gate [dict create presence_gate {web facebook}] seg.yaml] \
    {web facebook} "tokens read back in order"
assert_eq [spar::extract_presence_gate [dict create title X] seg.yaml] {} \
    "absent list is empty"
assert_eq [catch {spar::extract_presence_gate [dict create presence_gate {web myspace}] seg.yaml}] 1 \
    "unknown check refused"

section "presence_guidance"

set g [spar::presence_guidance {web facebook}]
assert_match $g "*web, facebook*" "checks listed verbatim"
assert_match $g "*stop*" "the exit is stated"
assert_eq [spar::presence_guidance {}] "" "no gate, no passage"

section "segment.rules: presence_gate_vocab and version 2.2"

set tmpdir [exec mktemp -d /tmp/spar-test-presence.XXXXXX]
file mkdir [file join $tmpdir segments]
set segbase [file join $tmpdir segments seg]
proc write_seed {segbase version extra} {
    set fd [open "$segbase.yaml" w]
    puts $fd "version: \"$version\""
    puts $fd "title: Test segment"
    puts $fd "date: 2026-09-25"
    puts $fd "target_type: qualification-only"
    puts $fd "provenance: test"
    puts $fd "discovery_criteria: test"
    puts $fd "rating_rubric: test"
    puts $fd $extra
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
write_seed $segbase 2.2 "presence_gate:\n  - web\n  - facebook"
set codes [seed_codes $segbase]
assert_eq [expr {"invalid_presence_gate" in $codes}] 0 "web and a module pass"
assert_eq [expr {"segment_version_unsupported" in $codes}] 0 "2.2 is a supported segment version"
assert_eq [expr {"unknown_key_root" in $codes}] 0 "presence_gate is a known key"
write_seed $segbase 2.0 "presence_gate:\n  - web\n  - myspace\n  - web"
set codes [seed_codes $segbase]
assert_eq [llength [lsearch -all -exact $codes invalid_presence_gate]] 2 \
    "an unknown check and a duplicate each error"
write_seed $segbase 2.1 "scope_note: none"
assert_eq [expr {"segment_version_unsupported" in [seed_codes $segbase]}] 1 \
    "2.1 never applied to segment definitions"
file delete -force $tmpdir
cleanup_temps
finish_tests

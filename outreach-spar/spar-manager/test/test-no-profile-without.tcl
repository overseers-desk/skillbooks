#!/usr/bin/env tclsh9.0
# Segment no_profile_without (segment.yaml): the checks a profile's existence
# depends on, their shape and closed vocabulary, and the passage the
# dispatcher renders from prompts/no-profile-without.txt.
package require yaml
package require TclOO
package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts
package require spar::validate

section "extract_no_profile_without"

set f [spar::extract_no_profile_without [dict create no_profile_without {any_of {web facebook}}] seg.yaml]
assert_eq [dict get $f mode] any_of "mode read back"
assert_eq [dict get $f checks] {web facebook} "tokens read back in order"
assert_eq [spar::extract_no_profile_without [dict create title X] seg.yaml] {} \
    "absent list is empty"
assert_eq [catch {spar::extract_no_profile_without [dict create no_profile_without {any_of {web myspace}}] seg.yaml}] 1 \
    "unknown check refused"

section "no_profile_without_guidance"

set g [spar::no_profile_without_guidance [dict create mode any_of checks {web facebook}]]
assert_match $g "*web, facebook*" "checks listed verbatim"
assert_match $g "*stop*" "the exit is stated"
assert_match [spar::no_profile_without_guidance [dict create mode all_of checks {linkedin}]] "*any check finds nothing*" "all_of fails on any empty check"
assert_eq [spar::no_profile_without_guidance {}] "" "no field, no passage"

section "segment.rules: no_profile_without_shape and version 2.2"

set tmpdir [exec mktemp -d /tmp/spar-test-no-profile.XXXXXX]
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
write_seed $segbase 2.2 "no_profile_without:\n  any_of:\n    - web\n    - facebook"
set codes [seed_codes $segbase]
assert_eq [expr {"invalid_no_profile_without" in $codes}] 0 "web and a module pass"
assert_eq [expr {"segment_version_unsupported" in $codes}] 0 "2.2 is a supported segment version"
assert_eq [expr {"unknown_key_root" in $codes}] 0 "no_profile_without is a known key"
write_seed $segbase 2.0 "no_profile_without:\n  any_of:\n    - web\n    - myspace\n    - web"
set codes [seed_codes $segbase]
assert_eq [llength [lsearch -all -exact $codes invalid_no_profile_without]] 2 \
    "an unknown check and a duplicate each error"
write_seed $segbase 2.2 "no_profile_without:\n  both:\n    - web"
assert_eq [expr {"invalid_no_profile_without" in [seed_codes $segbase]}] 1 "a key other than any_of or all_of errors"
write_seed $segbase 2.1 "scope_note: none"
assert_eq [expr {"segment_version_unsupported" in [seed_codes $segbase]}] 1 \
    "2.1 never applied to segment definitions"
file delete -force $tmpdir

section "profile_body: a gated file has none"

set tmpdir [exec mktemp -d /tmp/spar-test-no-profile.XXXXXX]
set gated [file join $tmpdir gated.md]
set fd [open $gated w]
puts $fd "---\nprofile_date: 2026-09-25\nstar_rating: 0\nyield: 0\ndependent_data:\n  date_excluded: 2026-09-25\nroster_patch:\n  date_excluded: 2026-09-25\n  p_note: 'no_profile_without: web, facebook empty, 2026-09-25'\n---\n"
close $fd
assert_eq [spar::profile_body $gated] "" "front matter only reads as an empty body"
set full [file join $tmpdir full.md]
set fd [open $full w]
puts $fd "---\nstar_rating: 3\n---\n\n# Profile: X\n\nText."
close $fd
assert_match [spar::profile_body $full] "# Profile: X*" "a body reads back"
file delete -force $tmpdir
cleanup_temps
finish_tests

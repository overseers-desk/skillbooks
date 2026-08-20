#!/usr/bin/env tclsh9.0
# Segment platform declarations (segment.yaml `platforms:`): the map's
# closed vocabularies, the required-skills derivation the §4.3/§4.4 audit
# consumes, and the per-strength prompt guidance the dispatcher assembles
# from prompts/platform-*.txt.
package require yaml
package require TclOO
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir .. lib spar-dispatch.tcl]
source [file join $script_dir test-helpers.tcl]

section "extract_platforms: vocabularies and derivation"

set seg [dict create platforms [dict create linkedin required facebook expected]]
set map [spar::extract_platforms $seg seg.yaml]
assert_eq [dict get $map linkedin] required "linkedin strength read back"
assert_eq [dict get $map facebook] expected "facebook strength read back"
assert_eq [spar::extract_required_skills $seg seg.yaml] {linkedin} \
    "only required entries feed the audit list"

assert_eq [spar::extract_platforms [dict create title X] seg.yaml] {} \
    "absent map is empty (no instruction, no audit)"
assert_eq [spar::extract_required_skills [dict create title X] seg.yaml] {} \
    "absent map requires nothing"

assert_eq [catch {spar::extract_platforms \
    [dict create platforms {myspace required}] seg.yaml}] 1 \
    "unknown platform refused (no platforms/myspace.md module)"
assert_eq [catch {spar::extract_platforms \
    [dict create platforms {linkedin mandatory}] seg.yaml}] 1 \
    "unknown strength refused"

section "platform_guidance: passages follow the map"

set g [spar::platform_guidance [dict create linkedin required]]
assert_match $g "*audit expects the skill invoked*" "required passage present"
assert_match $g "*linkedin_url*" "required passage names the roster field"
assert_match $g "*serialised-browsing arbiter*" "mechanics sentence ships"
assert_eq [string match "*Facebook presence*" $g] 0 \
    "undeclared platform contributes no passage"

set g [spar::platform_guidance [dict create facebook expected]]
assert_match $g "*Facebook presence*" "expected passage present"
assert_match $g "*facebook.com action per gate interval*" \
    "expected passage names the platform's gate"
assert_eq [string match "*audit expects*" $g] 0 \
    "expected carries no enforcement language"

set g [spar::platform_guidance [dict create]]
assert_match $g "*serialised-browsing arbiter*" \
    "empty map still ships the mechanics sentence"
assert_eq [string match "*This population*" $g] 0 \
    "empty map states no population fact"

finish_tests

#!/usr/bin/env tclsh9.0
# test-sweep-transition.tcl — T0 (Seed → Sweep). Covers the sweep-file
# reader/writers (round-trip through spar::yaml_parse, quote safety),
# task selection from the census, the mediated batch applier, and the
# stamp that makes a replay inert.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set tmpdir [exec mktemp -d /tmp/spar-test-sweep.XXXXXX]
lappend ::cleanup_dirs $tmpdir

# ── Fixture: a seed pair (segments/<seg>.yaml + <seg>.sweep.yaml) ───────

proc write_seed_pair {root seg} {
    file mkdir [file join $root segments $seg]
    file mkdir [file join $root campaigns camp]
    set seg_dir [file join $root segments $seg]
    set fd [open [spar::segment_yaml_for_segment $seg_dir] w]
    puts $fd {version: "2.0"}
    puts $fd "title: Test Segment"
    puts $fd {date: "2026-08-06"}
    puts $fd "provenance: seeded by the test fixture"
    puts $fd "discovery_criteria: |"
    puts $fd "  Everyone in the fixture population."
    puts $fd "rating_rubric: |"
    puts $fd "  5: perfect. 0: excluded."
    close $fd

    set fd [open [spar::sweep_yaml_for_segment $seg_dir] w]
    puts $fd {version: "1.0"}
    puts $fd "segment: $seg"
    puts $fd "market_estimate:"
    puts $fd "  value: 120"
    puts $fd "  derivation: |"
    puts $fd "    Top-down: 120 in the state register."
    puts $fd {  estimated: "2026-08-06"}
    puts $fd "sources:"
    puts $fd "  - name: State register"
    puts $fd "    type: registry"
    puts $fd "    url: https://example.invalid/register"
    puts $fd "    status: unharvested"
    puts $fd "  - name: Trade directory"
    puts $fd "    type: directory"
    puts $fd "    status: partial — 40 of 120 pages read"
    puts $fd "  - name: Local paper"
    puts $fd "    type: outlet"
    puts $fd "    status: exhausted — archive read to 2019"
    puts $fd "  - name: Closed forum"
    puts $fd "    type: informal"
    puts $fd "    status: unreachable (login wall)"
    puts $fd "exclusions: out-of-state operators"
    puts $fd "escapes: \[\]"
    puts $fd "rounds: \[\]"
    close $fd
    return $seg_dir
}

set root [file join $tmpdir inst]
set seg_dir [write_seed_pair $root vic]
set sweep [spar::sweep_yaml_for_segment $seg_dir]
set roster [spar::roster_path_for_segment $seg_dir]

# ── 1. Reader ──────────────────────────────────────────────────────────

section "1. read_sweep_yaml"

set data [spar::read_sweep_yaml $sweep]
assert_eq [dict get $data segment] vic "segment key read"
assert_eq [llength [dict get $data sources]] 4 "four census sources"
assert_eq [dict get $data market_estimate estimated] "2026-08-06" \
    "quoted date stays an ISO string"
assert_error {spar::read_sweep_yaml [file join $tmpdir nope.sweep.yaml]} \
    "*not found*" "missing file errors"

section "2. status tokens"

assert_eq [spar::sweep_status_token "partial — 40 of 120 pages read"] partial \
    "base token split off the free-text reason"
assert_eq [spar::sweep_status_token "unreachable (login wall)"] unreachable \
    "bracketed reason does not join the token"
assert_eq [spar::sweep_source_open "exhausted — archive read to 2019"] 0 \
    "exhausted source is closed"
assert_eq [spar::sweep_source_open "unharvested"] 1 "unharvested source is open"

# ── 3. Quote-safe scalars ──────────────────────────────────────────────

section "3. yaml_scalar"

assert_eq [spar::yaml_scalar "partial: 40 of 120"] {"partial: 40 of 120"} \
    "a mid-text ': ' is quoted"
assert_eq [spar::yaml_scalar "2026-08-06"] {"2026-08-06"} "a date is quoted"
assert_eq [spar::yaml_scalar "unharvested"] "unharvested" "a plain token stays bare"
assert_eq [spar::yaml_scalar 3] 3 "an integer stays bare"
assert_eq [spar::yaml_scalar ""] {""} "an empty value is quoted"
assert_eq [spar::yaml_scalar "no"] {"no"} "a YAML bool token is quoted"
assert_eq [spar::yaml_scalar "- leading dash"] {"- leading dash"} \
    "a leading indicator character is quoted"
assert_error {spar::yaml_scalar "two\nlines"} "*block scalar*" \
    "a multi-line value is refused, not flattened"

# ── 4. update_source_status ────────────────────────────────────────────

section "4. update_source_status"

spar::update_source_status $sweep "State register" "partial: 12 of 120 resolved"
set data [spar::read_sweep_yaml $sweep]
set st ""
foreach s [dict get $data sources] {
    if {[dict get $s name] eq "State register"} { set st [dict get $s status] }
}
assert_eq $st "partial: 12 of 120 resolved" \
    "status carrying ': ' re-parses as one scalar"
assert_eq [dict get $data market_estimate value] 120 \
    "the rest of the file survives the edit"
assert_match [spar::_sweep_read $sweep] "*Top-down: 120 in the state register.*" \
    "the derivation block scalar is untouched"
assert_error {spar::update_source_status $sweep "No such source" partial} \
    "*no source named*" "an unknown source errors rather than appending one"

# ── 5. append_sweep_round ──────────────────────────────────────────────

section "5. append_sweep_round"

spar::append_sweep_round $sweep [dict create \
    n 1 date 2026-08-06 method "T0: one worker per source" \
    inputs {"State register"} \
    reconciliation "State register: 12 kept of 120 listed" \
    coverage_after "12/120" yield 12]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 1 "rounds: \[\] became one entry"
set r [lindex [dict get $data rounds] 0]
assert_eq [dict get $r date] "2026-08-06" "round date re-parses as ISO, not epoch"
assert_eq [dict get $r method] "T0: one worker per source" \
    "a method carrying ': ' re-parses whole"
assert_eq [dict get $r yield] 12 "yield recorded"

# A second source in the same round merges rather than opening a new one.
spar::append_sweep_round $sweep [dict create \
    n 1 date 2026-08-06 method "T0: one worker per source" \
    inputs {"Trade directory"} \
    reconciliation "Trade directory: 5 kept of 60 listed" \
    coverage_after "17/120" yield 5]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 1 "same round number merges"
set r [lindex [dict get $data rounds] 0]
assert_eq [llength [dict get $r inputs]] 2 "both sources listed as inputs"
assert_eq [dict get $r yield] 17 "yields summed"
assert_eq [dict get $r coverage_after] "17/120" "coverage is the fresher count"
assert_match [dict get $r reconciliation] "*State register*Trade directory*" \
    "both reconciliation lines kept"

# A later round appends after the last entry.
spar::append_sweep_round $sweep [dict create \
    n 2 date 2026-08-07 method "T0 round 2" inputs {"Local paper"} \
    reconciliation "Local paper: 0 kept" coverage_after "17/120" yield 0]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 2 "round 2 appended"
assert_eq [dict get [lindex [dict get $data rounds] 1] n] 2 "in order"
assert_eq [dict get $data exclusions] "out-of-state operators" \
    "keys after rounds: survive the splice"

finish_tests

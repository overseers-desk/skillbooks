#!/usr/bin/env tclsh9.0
# Tests for spar-transition.tcl's positional `Tn[:seg[/stem]]` token grammar.
#
# Strategy: source spar-transition-cli.tcl which exposes parse_cli as a
# library. The proc returns a dict {ok 1 spec {...}} on success, or
# {ok 0 error <msg>} on failure. The script's main body calls parse_cli
# at startup and exits on error; the test bypasses that by sourcing the
# library file directly.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

# Source enough to populate the transition registry — parse_cli validates
# unknown TIDs against ::spar::transitions::all.
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-transition-cli.tcl]

# helper — assert parse_cli succeeds and the resulting tid_scopes matches.
proc assert_parse {argv expected_scopes label} {
    set result [spar::parse_cli $argv]
    if {[dict get $result ok] != 1} {
        puts "FAIL: $label"
        puts "  argv: $argv"
        puts "  expected ok parse with scopes $expected_scopes"
        puts "  actual error: [dict get $result error]"
        incr ::failures
        return
    }
    set actual [dict get $result spec tid_scopes]
    if {$actual ne $expected_scopes} {
        puts "FAIL: $label"
        puts "  argv: $argv"
        puts "  expected scopes: $expected_scopes"
        puts "  actual scopes:   $actual"
        incr ::failures
    } else {
        puts "  ok: $label"
        incr ::passes
    }
}

proc assert_parse_error {argv pattern label} {
    set result [spar::parse_cli $argv]
    if {[dict get $result ok] == 1} {
        puts "FAIL: $label"
        puts "  argv: $argv"
        puts "  expected error matching: $pattern"
        puts "  parse succeeded with: [dict get $result spec]"
        incr ::failures
        return
    }
    set msg [dict get $result error]
    if {![string match $pattern $msg]} {
        puts "FAIL: $label"
        puts "  argv: $argv"
        puts "  expected error matching: $pattern"
        puts "  actual error: $msg"
        incr ::failures
    } else {
        puts "  ok: $label"
        incr ::passes
    }
}

# ════════════════════════════════════════════════════════════════════════
# 1. Positional Tn token forms
# ════════════════════════════════════════════════════════════════════════
section "1. Positional Tn token forms"

# Bare T1 → tid only, segment and stem empty
assert_parse {/tmp/x.yaml T1} {{T1 {} {}}} \
    "bare T1 → {T1 {} {}}"

# T2:segment → tid + segment, stem empty
assert_parse {/tmp/x.yaml T2:commercial-labour-hire} \
    {{T2 commercial-labour-hire {}}} \
    "T2:segment → {T2 segment {}}"

# T6:segment/stem → all three
assert_parse {/tmp/x.yaml T6:commercial-labour-hire/andrew-kerby} \
    {{T6 commercial-labour-hire andrew-kerby}} \
    "T6:segment/stem → {T6 segment stem}"

# Multiple repeats including duplicate-TID scopes
assert_parse {/tmp/x.yaml T1 T1:foo T2:bar} \
    {{T1 {} {}} {T1 foo {}} {T2 bar {}}} \
    "T1 T1:foo T2:bar → all three preserved in insertion order"

# Mixed kinds in one invocation (the architectural motivation)
assert_parse {/tmp/x.yaml T1 T6:commercial-labour-hire/andrew-kerby} \
    {{T1 {} {}} {T6 commercial-labour-hire andrew-kerby}} \
    "T1 + T6:seg/stem mixed → both scopes captured"

# ════════════════════════════════════════════════════════════════════════
# 2. Validation errors
# ════════════════════════════════════════════════════════════════════════
section "2. Validation errors"

# Unknown TID
assert_parse_error {/tmp/x.yaml T99} \
    "*unknown transition*T99*" \
    "unknown TID errors with hint"

# Stem without segment is malformed
assert_parse_error {/tmp/x.yaml T6:/andrew-kerby} \
    "*stem requires segment*" \
    "stem without segment is rejected"

# --auto with positional Tn token is rejected
assert_parse_error {/tmp/x.yaml --auto T1} \
    "*--auto*positional*" \
    "--auto + positional T1 errors out"

# Removed --tid= flag points at new syntax
assert_parse_error {/tmp/x.yaml --tid=T1} \
    "*--tid=*replaced*Tn*" \
    "--tid=T1 errors with hint at new positional syntax"

# Removed --segment= flag points at new syntax
assert_parse_error {/tmp/x.yaml --segment=foo} \
    "*--segment=*replaced*Tn:seg*" \
    "--segment=foo errors with hint at new positional syntax"

# Removed --stem= flag points at new syntax
assert_parse_error {/tmp/x.yaml --stem=alice} \
    "*--stem=*replaced*Tn:seg/stem*" \
    "--stem=alice errors with hint at new positional syntax"

# ════════════════════════════════════════════════════════════════════════
# 3. Other flags survive
# ════════════════════════════════════════════════════════════════════════
section "3. Other flags survive"

# --jobs / --dry-run / --delay / --yes / --verbose / --dispatchable
# / --awaiting / --blocked / --auto all parse.

set result [spar::parse_cli {/tmp/x.yaml T1 --dry-run --jobs=8 --delay=5 --yes --verbose}]
assert_eq [dict get $result ok] 1 "compound flags parse ok"
set spec [dict get $result spec]
assert_eq [dict get $spec dry_run] 1 "--dry-run sets dry_run"
assert_eq [dict get $spec jobs] 8 "--jobs=8 captured"
assert_eq [dict get $spec delay] 5 "--delay=5 captured"
assert_eq [dict get $spec assume_yes] 1 "--yes sets assume_yes"
assert_eq [dict get $spec verbose] 1 "--verbose sets verbose"

# --auto without positional Tn is fine
set result [spar::parse_cli {/tmp/x.yaml --auto --dry-run}]
assert_eq [dict get $result ok] 1 "--auto without Tn parses ok"
assert_eq [dict get [dict get $result spec] auto_mode] 1 "--auto sets auto_mode"

# Campaign path captured verbatim — parse_cli is filesystem-pure (the
# script layer rejects non-yaml paths and missing files at runtime).
set result [spar::parse_cli {some-campaign-dir T1}]
assert_eq [dict get $result ok] 1 "any positional path parses ok"
assert_eq [dict get [dict get $result spec] campaign_path] "some-campaign-dir" \
    "campaign_path captured verbatim"

finish_tests

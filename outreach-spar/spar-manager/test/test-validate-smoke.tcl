#!/usr/bin/env tclsh9.0
# Opt-in smoke: run spar-validate-cli.tcl against real campaign data and check
# it completes and emits structured output. Real instances live outside this
# repo and carry client-specific names, so paths come from the environment, not
# the source. Set a colon-separated list of campaign.yaml paths:
#
#   SPAR_SMOKE_CAMPAIGNS=/path/one/campaign.yaml:/path/two/campaign.yaml \
#       tclsh9.0 test/test-validate-smoke.tcl
#
# Unset or pointing at absent files → the test skips (so CI without the data
# still passes). This is a smoke of the run, not a pass/fail of the data: real
# instances may legitimately carry data-integrity errors pre-uplift.
package require yaml
package require json
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set cli_path [file join $script_dir .. spar-validate-cli.tcl]

section "60. validate CLI smoke (real data, opt-in)"

set raw [expr {[info exists ::env(SPAR_SMOKE_CAMPAIGNS)] ? $::env(SPAR_SMOKE_CAMPAIGNS) : ""}]
if {$raw eq ""} {
    puts "  SKIP: SPAR_SMOKE_CAMPAIGNS not set"
} else {
    foreach path [split $raw ":"] {
        if {$path eq ""} continue
        if {![file exists $path]} {
            puts "  SKIP: not found — $path"
            continue
        }
        set tmp [file join /tmp "spar-smoke-[pid]-[clock microseconds]"]
        catch {exec tclsh9.0 $cli_path $path --json > $tmp 2>/dev/null}
        set fd [open $tmp r]; set out [read $fd]; close $fd
        file delete $tmp
        set ok [expr {![catch {::json::json2dict $out} parsed]}]
        set tag [file tail [file dirname $path]]
        assert_eq $ok 1 "smoke $tag: CLI emitted parseable JSON"
        if {$ok} {
            assert_eq [dict exists $parsed error_count] 1 "smoke $tag: has error_count"
            assert_eq [dict exists $parsed warning_count] 1 "smoke $tag: has warning_count"
        }
    }
}

finish_tests

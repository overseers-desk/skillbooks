#!/usr/bin/env tclsh9.0
# spar-a-harness.tcl — Approach-phase harness entry point.
# Usage: tclsh9.0 spar-a-harness.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: author-draft.txt, challenger-template.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-harness.tcl]
package require sha256

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh9.0 spar-a-harness.tcl <prompt-dir> <log-dir>"
    exit 1
}
exit [[spar::ApproachHarness new {*}$argv] run]

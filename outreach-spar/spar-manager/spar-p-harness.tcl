#!/usr/bin/env tclsh9.0
# spar-p-harness.tcl — Profile-phase harness entry point.
# Usage: tclsh9.0 spar-p-harness.tcl <prompt-dir> <log-dir>
#   <prompt-dir> contains: prompt.txt, meta.env

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-harness.tcl]

spar::install_log_timestamp

if {[llength $argv] < 2} {
    puts stderr "Usage: tclsh9.0 spar-p-harness.tcl <prompt-dir> <log-dir>"
    exit 1
}
exit [[spar::ProfileHarness new {*}$argv] run]

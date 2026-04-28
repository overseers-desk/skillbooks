#!/usr/bin/env tclsh9.0
package require Thread

set script_dir [file dirname [file normalize [info script]]]
set test_files [lsort [glob -directory $script_dir test-*.tcl]]
set test_files [lsearch -all -inline -not -exact $test_files [file join $script_dir test-helpers.tcl]]

set workers [expr {[info exists ::env(SPAR_TEST_JOBS)]
                   ? $::env(SPAR_TEST_JOBS)
                   : [exec getconf _NPROCESSORS_ONLN]}]

set pool [tpool::create \
    -minworkers 0 \
    -maxworkers $workers \
    -idletime   30 \
    -initcmd {
        proc run_test_file {path} {
            set t0 [clock milliseconds]
            set rc [catch {exec tclsh9.0 $path 2>@1} output]
            return [dict create \
                path       $path \
                rc         $rc \
                elapsed_ms [expr {[clock milliseconds] - $t0}] \
                output     $output]
        }
    }]

set t0 [clock milliseconds]
set pending {}
foreach f $test_files {
    lappend pending [tpool::post -nowait $pool [list run_test_file $f]]
}

set results {}
while {[llength $pending]} {
    set done [tpool::wait $pool $pending pending]
    foreach j $done { lappend results [tpool::get $pool $j] }
}
tpool::release $pool
set wall [expr {[clock milliseconds] - $t0}]

set by_path [lsort -command {apply {{a b} {string compare [dict get $a path] [dict get $b path]}}} $results]

set failed 0
puts ""
foreach r $by_path {
    set tag [expr {[dict get $r rc] == 0 ? "PASS" : "FAIL"}]
    if {[dict get $r rc] != 0} { incr failed }
    set passes [regexp -inline {Results: ([0-9]+) passed, ([0-9]+) failed} [dict get $r output]]
    if {[llength $passes] >= 3} {
        set summary [format "%3d/%-3d" [lindex $passes 1] [expr {[lindex $passes 1] + [lindex $passes 2]}]]
    } else {
        set summary "       "
    }
    puts [format "%-32s  %s  %s  %5d ms" [file tail [dict get $r path]] $tag $summary [dict get $r elapsed_ms]]
}

foreach r $by_path {
    if {[dict get $r rc] != 0} {
        puts "\n────── [file tail [dict get $r path]] ──────"
        puts [dict get $r output]
    }
}

set total_passes 0
set total_failures 0
foreach r $results {
    set m [regexp -inline {Results: ([0-9]+) passed, ([0-9]+) failed} [dict get $r output]]
    if {[llength $m] >= 3} {
        incr total_passes   [lindex $m 1]
        incr total_failures [lindex $m 2]
    }
}

puts ""
puts "════════════════════════════════════════════════════════════════"
puts [format "Files: %d ok, %d failed   Tests: %d passed, %d failed   Wall: %d ms (workers=%d)" \
    [expr {[llength $results] - $failed}] $failed $total_passes $total_failures $wall $workers]
puts "════════════════════════════════════════════════════════════════"

exit [expr {$failed > 0}]

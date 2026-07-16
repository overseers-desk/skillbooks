#!/usr/bin/env tclsh9.0
package require Thread

set script_dir [file dirname [file normalize [info script]]]
set test_files [lsort [glob -directory $script_dir test-*.tcl]]
set test_files [lsearch -all -inline -not -exact $test_files [file join $script_dir test-helpers.tcl]]

set workers [expr {[info exists ::env(SPAR_TEST_JOBS)]
                   ? $::env(SPAR_TEST_JOBS)
                   : [exec getconf _NPROCESSORS_ONLN]}]

# A test that requires Tk needs a real display; wish9.0 falls off the
# script end into the event loop instead of exiting, so only a Tk test
# runs under it (word-bounded match, so `package require tkdown` does not
# read as Tk - mirrors tests/run.sh in teatotal, the jobloop/jobpool
# vendor home). Start one private Xvfb for the whole run - never an
# existing display, where its windows would land over someone's work -
# and tear it down when the suite finishes, so plain `tclsh9.0
# test/run.tcl` comes back green on a headless box with no caller-side
# xvfb-run needed.
proc needs_tk {path} {
    set fd [open $path r]; set src [read $fd]; close $fd
    return [regexp -line {^[[:space:]]*package require (Tk|Ttk|tk|ttk)\y} $src]
}

set display ""
set xvfb_pid ""
if {[llength [lmap f $test_files {expr {[needs_tk $f] ? 1 : [continue]}}]]} {
    set disp 99
    while {[file exists "/tmp/.X${disp}-lock"] || [file exists "/tmp/.X11-unix/X${disp}"]} {
        incr disp
    }
    set display ":$disp"
    set xvfb_pid [exec Xvfb $display -screen 0 1500x1150x24 \
        > /tmp/spar-tests-xvfb.log 2>@1 &]
    exec sleep 2
}

set pool [tpool::create \
    -minworkers 0 \
    -maxworkers $workers \
    -idletime   30 \
    -initcmd {
        proc file_needs_tk {path} {
            set fd [open $path r]; set src [read $fd]; close $fd
            return [regexp -line {^[[:space:]]*package require (Tk|Ttk|tk|ttk)\y} $src]
        }
        proc run_test_file {path display} {
            set t0 [clock milliseconds]
            if {[file_needs_tk $path]} {
                set ::env(DISPLAY) $display
                set rc [catch {exec wish9.0 $path 2>@1} output]
            } else {
                set rc [catch {exec tclsh9.0 $path 2>@1} output]
            }
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
    lappend pending [tpool::post -nowait $pool [list run_test_file $f $display]]
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

if {$xvfb_pid ne ""} { catch {exec kill $xvfb_pid} }

exit [expr {$failed > 0}]

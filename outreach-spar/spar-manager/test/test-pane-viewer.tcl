#!/usr/bin/env tclsh9.0
# PaneViewer: viewers constructed on one pane displace each other on
# show, with no wiring between them; a viewer on another pane is left
# alone. Skipped when no Tk display is available.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

if {![info exists ::env(DISPLAY)] || $::env(DISPLAY) eq ""} {
    puts "  SKIP: no DISPLAY"
    finish_tests
}

package require Tk
source [file join $script_dir .. ui utils.tcl]
source [file join $script_dir .. ui pane-viewer.tcl]

oo::class create CountingViewer {
    superclass spar::ui::PaneViewer
    variable Renders
    constructor {pane name} { next $pane $name; set Renders 0 }
    method render {} { incr Renders }
    method renders {} { return $Renders }
}

foreach pw {.pw .pw2} {
    ttk::panedwindow $pw -orient horizontal
    $pw add [ttk::frame ${pw}.main -width 200 -height 100]
    $pw add [ttk::frame ${pw}.right]
    pack $pw -fill both -expand 1
}
update

set a [CountingViewer new .pw a]
set b [CountingViewer new .pw b]
set c [CountingViewer new .pw b2]
set other [CountingViewer new .pw2 x]

section "1. show displaces the peers on the same pane"

$other show
$a show
assert_eq [list [$a is_visible] [$b is_visible] [$c is_visible]] {1 0 0} "a shown alone"
assert_eq [pack slaves .pw.right] .pw.right.a "only a's frame packed"
assert_eq [$a renders] 1 "show renders"

$b show
assert_eq [list [$a is_visible] [$b is_visible] [$c is_visible]] {0 1 0} "b displaces a"
assert_eq [pack slaves .pw.right] .pw.right.b "only b's frame packed"
assert_eq [$other is_visible] 1 "viewer on another pane untouched"

section "2. toggle and hide"

$b toggle
assert_eq [$b is_visible] 0 "toggle hides a shown viewer"
assert_eq [pack slaves .pw.right] {} "nothing packed after hide"
$c toggle
assert_eq [$c is_visible] 1 "toggle shows a hidden viewer"

section "3. a destroyed viewer leaves the peer list"

$c destroy
set rc [catch {$a show} err]
assert_eq $rc 0 "show after a peer is destroyed"
assert_eq [pack slaves .pw.right] .pw.right.a "a packed"

finish_tests

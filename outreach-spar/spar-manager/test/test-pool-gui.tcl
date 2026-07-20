#!/usr/bin/env tclsh9.0
# Phase-3 headless GUI smoke for the Dispatcher + DispatchController +
# TransitionTree wiring.
#
# Skipped when no Tk display is available: wish9.0 not on PATH, no
# DISPLAY, and no Xvfb to start one. The integration tests file uses
# the same conditional-skip idiom for its golden-campaign dependency.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

# ── Lazy-source paths ───────────────────────────────────────────────
# DispatchController sources the dispatch libraries on the first Play
# rather than at load time, so a wrong path there surfaces as a logged
# "not available" and a silent return, not a load error. Nothing else
# here drives that method. Check the names it lists resolve against the
# directory spar-ui.tcl hands it as ScriptDir. Runs before the display
# gate below: it needs no Tk.
section "0. DispatchController's lazy sources resolve"

set dc_path [file join $script_dir .. ui dispatch-controller.tcl]
set fd [open $dc_path r]; set dc_src [read $fd]; close $fd

# Take the loop's file list and the path expression built from it, then
# run that expression against the real directory. Whatever the source
# line says is what gets checked.
set found [regexp {foreach\s+(\w+)\s+\{([^\}]*)\}[^\n]*\n\s*(set path \[file join \$ScriptDir[^\n]*\])} \
    $dc_src -> loop_var lazy_libs path_expr]
assert_eq $found 1 "DispatchController still lazy-sources a list of libraries"
if {$found} {
    set ScriptDir [file join $script_dir ..]
    foreach $loop_var $lazy_libs {
        eval $path_expr
        assert_eq [file exists $path] 1 \
            "lazy source resolves: [set $loop_var]"
    }
}

# ── Display detection ───────────────────────────────────────────────
proc have_display? {} {
    if {[info exists ::env(DISPLAY)] && $::env(DISPLAY) ne ""} {
        # Probe with xdpyinfo if available; otherwise assume the env
        # var is honest. Avoids loading Tk just to find out.
        if {[auto_execok xdpyinfo] ne ""} {
            return [expr {[catch {exec xdpyinfo}] == 0}]
        }
        return 1
    }
    return 0
}

if {[auto_execok wish9.0] eq ""} {
    puts "  SKIP: wish9.0 not on PATH"
    finish_tests
}
if {![have_display?] && [auto_execok Xvfb] eq ""} {
    puts "  SKIP: no DISPLAY and no Xvfb"
    finish_tests
}

# ── Load Tk into this interpreter ───────────────────────────────────
package require Tk
wm withdraw .

package require Thread

# Same load pattern the bootstrap uses, sufficient for what the smoke
# test exercises.
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir .. lib spar-dispatcher.tcl]
source [file join $script_dir .. ui campaign-model.tcl]
source [file join $script_dir .. ui log-window.tcl]
source [file join $script_dir .. ui transition-tree.tcl]
source [file join $script_dir .. ui dispatch-controller.tcl]

# wait_for / wait_for_state helpers — copy of the patterns from
# test-pool.tcl. Kept inline to avoid coupling.
proc wait_for {script {timeout_ms 5000}} {
    set deadline [expr {[clock milliseconds] + $timeout_ms}]
    while {[clock milliseconds] < $deadline} {
        if {[uplevel 1 $script]} { return 1 }
        set ::tick 0
        after 20 set ::tick 1
        vwait ::tick
    }
    return 0
}

proc wait_for_state {dispatcher row state {timeout_ms 5000}} {
    return [wait_for [list expr {[$dispatcher state $row] eq $state}] \
        $timeout_ms]
}

proc wait_for_terminal {dispatcher row {timeout_ms 5000}} {
    return [wait_for \
        [list expr {[$dispatcher state $row] in {done failed cancelled}}] \
        $timeout_ms]
}

# ── Build the tree directly (no CampaignModel needed for these
#    behaviours; we drive update_row through the controller events) ──

ttk::frame .tpanel
pack .tpanel

# A tiny stub CampaignModel-shape that the TransitionTree and
# DispatchController constructors can subscribe to. Just enough surface
# to satisfy [my subscribe] and the few accessors the smoke test
# touches; the real model is heavy (loads YAML, classifies a campaign,
# starts a coroutine) and untouched by what this test wants to verify.
oo::class create FakeCampaign {
    variable Subs Cdata Transitions State
    constructor {} {
        set Subs [dict create]
        set Cdata [dict create]
        set Transitions {}
        set State [spar::State new]
    }
    method subscribe {event cb} { dict lappend Subs $event $cb }
    method get_cdata           {} { return $Cdata }
    method get_state           {} { return $State }
    method get_all_contacts    {} { return {} }
    method get_transitions     {} { return $Transitions }
    method refresh             {} { return }
}

set campaign [FakeCampaign new]

set tree_obj [spar::ui::TransitionTree new $campaign .tpanel]

# Manually insert a couple of rows so update_row has something to paint.
set tree [$tree_obj get_tree_widget]
$tree insert {} end -id t0 -text "T1: Sweep → Profile (3)" -open false
foreach {stem name} {r1 "Row One" r2 "Row Two" r3 "Row Three"} {
    set row_id [$tree insert t0 end -text "  $name" \
        -values [list $stem "" "" "pending" ""]]
}
# Note: we skip populating SlugToRow on TransitionTree. update_row()
# silently no-ops when a stem isn't in the map, which is fine: the
# assertions below read Pool state, not painted text.

# Build a log window and the controller. Controller's constructor
# requires Tk widgets; we use real ttk frames.
set log [spar::ui::LogWindow new 0]

ttk::frame .dispatch
pack .dispatch
ttk::button .dispatch.play   -text "▶ Send to pool" -state disabled
ttk::button .dispatch.pause  -text "⏸ Pause"        -state disabled
ttk::button .dispatch.cancel -text "✕ Cancel"       -state disabled
pack .dispatch.play .dispatch.pause .dispatch.cancel -side left
ttk::frame .dispatch.progress
ttk::progressbar .dispatch.progress.bar -mode determinate -value 0
ttk::label       .dispatch.progress.status -text ""
pack .dispatch.progress.bar .dispatch.progress.status -fill x

spar::ui::install_logger_appender $log
set pool [spar::Dispatcher new 4]
set dc [spar::ui::DispatchController new \
    $campaign $tree_obj $log $pool \
    .dispatch.play .dispatch.pause .dispatch.cancel \
    .dispatch.progress \
    [file join $script_dir ..] "" "" {} 0 0]

$tree_obj set_dispatch $dc

# ════════════════════════════════════════════════════════════════════
# 1. Enqueue 2 fake_worker rows directly on the Pool; verify both reach
#    done. Drives the controller's job-state subscription as a side
#    effect — observable via the Tree's `state` column once update_row
#    paints (we don't assert that text here; we assert pool state).
# ════════════════════════════════════════════════════════════════════
section "1. Enqueue + reach done"
$pool enqueue r1 fake_worker {plan {{sleep 200}}}
$pool enqueue r2 fake_worker {plan {{sleep 200}}}
foreach r {r1 r2} { wait_for_state $pool $r running 1000 }
foreach r {r1 r2} { assert_eq [$pool state $r] running "$r is running" }
foreach r {r1 r2} { wait_for_terminal $pool $r 3000 }
foreach r {r1 r2} { assert_eq [$pool state $r] done "$r reached done" }

# ════════════════════════════════════════════════════════════════════
# 2. While 1 is in flight, enqueue 1 more, pause queue, verify it sits
#    queued; resume, verify it dispatches.
# ════════════════════════════════════════════════════════════════════
section "2. Pause queue holds new rows"
$pool enqueue r3 fake_worker {plan {{sleep 400}}}
wait_for_state $pool r3 running 1000
$pool pause_queue
$pool enqueue r4 fake_worker {plan {{sleep 100}}}
# r4 should sit queued for at least one event loop tick (queue paused).
set ::tick 0; after 50 set ::tick 1; vwait ::tick
assert_eq [$pool state r4] queued "r4 sits queued while queue paused"

$pool resume_queue
wait_for_state $pool r4 running 1500
wait_for_terminal $pool r4 2000
assert_eq [$pool state r4] done "r4 dispatched after resume_queue"

wait_for_terminal $pool r3 2000

# ════════════════════════════════════════════════════════════════════
# 3. Cancel a queued row → cancelled.
# ════════════════════════════════════════════════════════════════════
section "3. Cancel a queued row"
# Block worker slots so the next enqueue stays queued. Pool jobs=4, so
# we need to fill all 4 slots first.
foreach r {b1 b2 b3 b4} {
    $pool enqueue $r fake_worker {plan {{sleep 600}}}
}
foreach r {b1 b2 b3 b4} { wait_for_state $pool $r running 1000 }
$pool enqueue qcancel fake_worker {plan {{sleep 50}}}
assert_eq [$pool state qcancel] queued "qcancel queued behind blockers"

$pool cancel qcancel
assert_eq [$pool state qcancel] cancelled \
    "queued row transitions to cancelled when controller cancels it"

foreach r {b1 b2 b3 b4} { wait_for_terminal $pool $r 2000 }

# ════════════════════════════════════════════════════════════════════
# 4. Toggle Ongoing-only on the tree; rows whose stems are not in the
#    Pool's active+queued set must be detached.
# ════════════════════════════════════════════════════════════════════
section "4. Ongoing-only filter detaches inactive rows"
# All previous rows are terminal → Pool active+queued is empty. With
# OngoingOnly on and all leaves having stems not in the live set, every
# leaf row should be detached.
set tree [$tree_obj get_tree_widget]
set leaves_before [$tree children t0]
assert_eq [llength $leaves_before] 3 "tree starts with 3 leaves"

# Drive the toggle the same way the user does — flip the variable
# the checkbutton is bound to, then call the handler. The variable
# lives in the TclOO instance namespace; locate it by enumerating.
set varname ""
foreach v [info vars [info object namespace $tree_obj]::*] {
    if {[string match *::OngoingOnly $v]} { set varname $v; break }
}
if {$varname eq ""} {
    puts "  SKIP 4: could not locate OngoingOnly var"
} else {
    set $varname 1
    $tree_obj on_ongoing_toggled
    set leaves_after [$tree children t0]
    assert_eq [llength $leaves_after] 0 \
        "after Ongoing-only toggle, 0 leaves visible (Pool empty)"
    set $varname 0
    $tree_obj on_ongoing_toggled
    set leaves_restored [$tree children t0]
    assert_eq [llength $leaves_restored] 3 \
        "after toggle off, 3 leaves restored"
}

# ════════════════════════════════════════════════════════════════════
# 5. Channel groups: a mixed-band transition gets one group node per
#    channel; selection, SlugToRow, and the ongoing filter work across
#    the extra level. A single-channel transition stays flat.
# ════════════════════════════════════════════════════════════════════
section "5. Channel groups under a mixed-band transition"

# populate against the FakeCampaign's empty transition list clears the
# hand-built tree from the earlier sections and resets the t$idx
# counter, so on_transition_loaded builds from t0.
$tree_obj populate

set t6_tasks {
    {"Alice A" a1 "Org A" seg-x dispatchable "" email}
    {"Bob B"   b1 "Org B" seg-x dispatchable "" linkedin}
    {"Cara C"  c1 "Org C" seg-x dispatchable "" email}
    {"Dan D"   d1 "Org D" seg-x blocked "invalid_approach_yaml: x" ""}
}
$tree_obj on_transition_loaded T6 "Approach → Send" $t6_tasks

set groups [$tree children t0]
assert_eq [llength $groups] 3 "mixed band: 3 group nodes under the header"
set glabels [lmap g $groups {string trim [$tree item $g -text]}]
assert_eq [expr {"✉ email (2)" in $glabels}] 1 "email group labelled with count 2"
assert_eq [expr {"🔗 linkedin (1)" in $glabels}] 1 "linkedin group labelled with count 1"
assert_eq [expr {"other (1)" in $glabels}] 1 "channel-less blocked row grouped as other"

set leaves [$tree_obj leaf_descendants t0]
assert_eq [llength $leaves] 4 "leaf_descendants finds all 4 contacts through groups"
assert_eq [$tree_obj header_of [lindex $leaves 0]] t0 "header_of resolves a grouped leaf to t0"
set s2r [$tree_obj get_slug_to_row]
foreach stem {a1 b1 c1 d1} {
    assert_eq [dict exists $s2r $stem] 1 "SlugToRow covers grouped leaf $stem"
}

# Selecting the linkedin group resolves to a 1-leaf cohort of t0.
set li_group ""
foreach g $groups {
    if {[string match "*linkedin*" [$tree item $g -text]]} { set li_group $g }
}
set ::target {}
$tree_obj subscribe dispatch-target-changed \
    [list apply {{parent nchild label verb} {
        set ::target [list $parent $nchild]
    }}]
$tree selection set [list $li_group]
$tree_obj on_select
assert_eq $::target {t0 1} "group selection → cohort of its 1 leaf under t0"

# Ongoing filter detaches and restores across the group level.
set varname ""
foreach v [info vars [info object namespace $tree_obj]::*] {
    if {[string match *::OngoingOnly $v]} { set varname $v; break }
}
if {$varname eq ""} {
    puts "  SKIP 5-filter: could not locate OngoingOnly var"
} else {
    set $varname 1
    $tree_obj on_ongoing_toggled
    assert_eq [llength [$tree_obj leaf_descendants t0]] 0 \
        "Ongoing-only detaches grouped leaves (Pool empty)"
    set $varname 0
    $tree_obj on_ongoing_toggled
    set email_group ""
    foreach g [$tree children t0] {
        if {[string match "*email*" [$tree item $g -text]]} { set email_group $g }
    }
    assert_eq [llength [$tree children $email_group]] 2 \
        "toggle off restores leaves under their group"
}

# A single-channel band stays flat: leaves directly under the header.
$tree_obj on_transition_loaded T7 "Send → Reply" {
    {"Eve E" e1 "Org E" seg-x dispatchable "" ""}
    {"Fay F" f1 "Org F" seg-x dispatchable "" ""}
}
set t7_children [$tree children t1]
assert_eq [llength $t7_children] 2 "single-channel band: leaves directly under header"
assert_eq [$tree set [lindex $t7_children 0] stem] e1 "flat leaf carries its stem"

$pool destroy
finish_tests

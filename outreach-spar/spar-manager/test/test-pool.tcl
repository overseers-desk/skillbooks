#!/usr/bin/env tclsh9.0
# Tests for spar::Dispatcher (the GUI's job pool) and the message-protocol
# enforcement defined in spar-dispatcher-initcmd.tcl.
#
# Strategy: drive the Dispatcher with fake_worker tpool jobs that emit
# scripted message sequences. No real claude / SES / IMAP calls. The
# fake_worker proc is defined in spar-dispatcher-initcmd.tcl alongside
# the production worker procs, so it loads via the same initcmd path.

package require Thread
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

# spar-dispatcher.tcl needs spar-state.tcl in scope for spar::update_roster_field
# (called by on_roster_update). Source it so the file loads cleanly.
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-dispatcher.tcl]

set ::log_messages {}
proc test_log {msg} { lappend ::log_messages $msg }

# wait_for — poll a script returning a boolean until true or timeout.
# Pumps the event loop so async on_* messages land.
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
    return [wait_for [list expr {[$dispatcher state $row] in {done failed cancelled}}] \
        $timeout_ms]
}

# ════════════════════════════════════════════════════════════════════════
# 1. Introspection mirror — every msg_* in initcmd has a matching on_*
# ════════════════════════════════════════════════════════════════════════
section "1. Introspection mirror"

# Read the initcmd file and pull out msg_* proc names.
set initcmd_path [file join $script_dir .. spar-dispatcher-initcmd.tcl]
set fd [open $initcmd_path r]; set initcmd_src [read $fd]; close $fd
set msg_names {}
foreach line [split $initcmd_src \n] {
    if {[regexp {^proc\s+(msg_[a-z_]+)\s} $line -> name]} {
        lappend msg_names $name
    }
}
set msg_names [lsort -unique $msg_names]

set on_names {}
foreach m [info class methods spar::Dispatcher -all] {
    if {[regexp {^on_[a-z_]+$} $m]} { lappend on_names $m }
}
set on_names [lsort -unique $on_names]

# Build the expected on_* set by stripping msg_ → on_.
set expected_on {}
foreach m $msg_names { lappend expected_on [regsub {^msg_} $m on_] }
set expected_on [lsort -unique $expected_on]

assert_eq $on_names $expected_on \
    "every msg_* has a matching on_* method (and vice versa)"

# ════════════════════════════════════════════════════════════════════════
# 2. Basic dispatch — enqueue a row, fake_worker runs it, reaches done
# ════════════════════════════════════════════════════════════════════════
section "2. Basic dispatch"

set d [spar::Dispatcher new 4 test_log]
$d pause_queue
$d enqueue r1 T1 fake_worker {plan {{sleep 50}}}
assert_eq [$d state r1] queued "r1 starts queued (queue paused)"

# Resume; the post happens immediately and the state flips to running
$d resume_queue
assert_eq [$d state r1] running "r1 transitions to running at post time"

wait_for_terminal $d r1 3000
assert_eq [$d state r1] done "r1 reaches done"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 3. Concurrency cap — Jobs=2, enqueue 4, only 2 run concurrently
# ════════════════════════════════════════════════════════════════════════
section "3. Concurrency cap"

set d [spar::Dispatcher new 2 test_log]
foreach r {r1 r2 r3 r4} {
    $d enqueue $r T1 fake_worker {plan {{sleep 200}}}
}

# State flips to running at tpool::post time, so the snapshot is
# deterministic the moment all enqueues have returned.
assert_eq [$d posted_count] 2 "Jobs=2 caps posted at 2"
assert_eq [llength [$d queued_rows]] 2 "remaining 2 stay queued"

foreach r {r1 r2 r3 r4} { wait_for_terminal $d $r 5000 }
foreach r {r1 r2 r3 r4} {
    assert_eq [$d state $r] done "$r eventually reaches done"
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 4. Queue pause/resume — paused queue does not post new
# ════════════════════════════════════════════════════════════════════════
section "4. Queue pause/resume"

set d [spar::Dispatcher new 2 test_log]
$d pause_queue
foreach r {r1 r2 r3} {
    $d enqueue $r T1 fake_worker {plan {{sleep 30}}}
}
set ::tick 0; after 50 set ::tick 1; vwait ::tick
foreach r {r1 r2 r3} {
    assert_eq [$d state $r] queued "$r stays queued while pause_queue is set"
}

$d resume_queue
foreach r {r1 r2 r3} { wait_for_terminal $d $r 3000 }
foreach r {r1 r2 r3} {
    assert_eq [$d state $r] done "$r drains after resume_queue"
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 5. Cancel a queued row — drops before posting
# ════════════════════════════════════════════════════════════════════════
section "5. Cancel queued"

set d [spar::Dispatcher new 1 test_log]
# Block worker slot with a long-running row
$d enqueue r1 T1 fake_worker {plan {{sleep 300}}}
$d enqueue r2 T1 fake_worker {plan {{sleep 30}}}
wait_for_state $d r1 running 1000
assert_eq [$d state r2] queued "r2 queued behind r1"

$d cancel r2
assert_eq [$d state r2] cancelled "queued r2 cancels immediately"

wait_for_terminal $d r1 1000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 6. Cancel a running row — sentinel, worker observes, emits cancelled
# ════════════════════════════════════════════════════════════════════════
section "6. Cancel running"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 T1 fake_worker \
    {plan {{sleep 50} {check_cancel} {sleep 50} {check_cancel}}}
wait_for_state $d r1 running 1000
$d cancel r1
wait_for_terminal $d r1 2000
assert_eq [$d state r1] cancelled "running r1 cancels via sentinel"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 7. Pause/resume a running row — sentinel pause, then resume → done
# ════════════════════════════════════════════════════════════════════════
section "7. Pause and resume row"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 T1 fake_worker \
    {plan {{sleep 50} {check_pause 30} {sleep 30}}}
wait_for_state $d r1 running 1000
$d pause_row r1
wait_for_state $d r1 paused 2000
assert_eq [$d state r1] paused "r1 reaches paused via sentinel"
$d resume_row r1
wait_for_terminal $d r1 2000
assert_eq [$d state r1] done "r1 resumes and reaches done"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 8. State-machine validation — out-of-order messages logged and dropped
# ════════════════════════════════════════════════════════════════════════
section "8. State-machine validation"

set d [spar::Dispatcher new 1 test_log]
set ::log_messages {}
$d on_phase nonexistent_row foo
assert_match [join $::log_messages " "] "*phase for unknown row nonexistent_row*" \
    "on_phase for unknown row is logged"

# Register a queued row (queue paused so it does not auto-post), then
# send on_done — should be logged + dropped because the row never
# transitioned to running.
$d pause_queue
$d enqueue r1 T1 fake_worker {plan {{sleep 200}}}
set ::log_messages {}
$d on_done r1 {}
assert_match [join $::log_messages " "] "*done for row r1 in state queued*" \
    "on_done for queued row is logged and dropped"
assert_eq [$d state r1] queued "r1 still queued after illegal on_done"

$d resume_queue
wait_for_terminal $d r1 1000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 9. count_by_transition — across heterogeneous rows
# ════════════════════════════════════════════════════════════════════════
section "9. count_by_transition"

set d [spar::Dispatcher new 4 test_log]
$d enqueue a1 T1 fake_worker {plan {{sleep 30}}}
$d enqueue a2 T1 fake_worker {plan {{sleep 30}}}
$d enqueue b1 T2 fake_worker {plan {{sleep 30}}}
$d enqueue b2 T2 fake_worker {plan {{sleep 30}}}
$d enqueue b3 T2 fake_worker {plan {{sleep 30}}}
foreach r {a1 a2 b1 b2 b3} { wait_for_terminal $d $r 3000 }
assert_eq [$d count_by_transition T1 done] 2 "T1 done count = 2"
assert_eq [$d count_by_transition T2 done] 3 "T2 done count = 3"
assert_eq [$d count_by_transition T1 failed] 0 "T1 failed count = 0"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 10. Rate-limited cycle — running → rate_limited → running → done
# ════════════════════════════════════════════════════════════════════════
section "10. Rate-limited cycle"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 T1 fake_worker [list plan [list \
    [list sleep 30] \
    [list msg_rate_limited [clock seconds]] \
    [list sleep 30] \
    [list msg_rate_limit_cleared] \
    [list sleep 30]]]
wait_for_state $d r1 rate_limited 2000
assert_eq [$d state r1] rate_limited "r1 enters rate_limited"
wait_for_state $d r1 running 2000
assert_eq [$d state r1] running "r1 returns to running after cleared"
wait_for_terminal $d r1 2000
assert_eq [$d state r1] done "r1 reaches done after rate-limit cycle"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 11. Requeue — terminal row goes back to queued and re-runs
# ════════════════════════════════════════════════════════════════════════
section "11. Requeue"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 T1 fake_worker {plan {{msg_failed boom}}}
wait_for_terminal $d r1 2000
assert_eq [$d state r1] failed "r1 fails first time"

$d pause_queue
$d requeue r1
assert_eq [$d state r1] queued "requeued r1 is queued (queue paused)"
$d resume_queue
wait_for_terminal $d r1 2000
assert_eq [$d state r1] failed "r1 fails again on rerun (same plan)"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 12. active_rows — excludes terminal
# ════════════════════════════════════════════════════════════════════════
section "12. active_rows"

set d [spar::Dispatcher new 4 test_log]
$d enqueue r1 T1 fake_worker {plan {{sleep 30}}}
$d enqueue r2 T1 fake_worker {plan {{msg_failed nope}}}
$d enqueue r3 T1 fake_worker {plan {{sleep 200}}}
wait_for_terminal $d r2 2000
wait_for_terminal $d r1 2000
# r3 still running (200ms vs 30ms others)
set active [$d active_rows]
assert_eq [llength $active] 1 "only r3 still active"
assert_eq [lindex $active 0] r3 "active row is r3"
wait_for_terminal $d r3 2000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 13. harness_run — wires through to a harness_class instance
# ════════════════════════════════════════════════════════════════════════
# The real spar::ProfileHarness / spar::ApproachHarness needs claude on
# PATH plus a fully-built prompt_dir (prompt.txt, meta.env, roster, etc.)
# to exercise end-to-end. That is heavier than this test wants. Instead
# we instantiate FakeHarness — a stand-in defined alongside fake_worker
# in spar-dispatcher-initcmd.tcl that mimics the (prompt_dir log_dir)
# constructor and the run-returns-0/1 contract — to verify only the
# routing path: enqueue → tpool::post → harness_run → msg_done/failed.
# Coverage of the real harness body lives in test-state.tcl /
# test-validate-*; this section catches breakage in the worker wrapper.
section "13. harness_run routing"

set tmp_root [file join /tmp "spar-pool-harness-[pid]-[clock microseconds]"]
file mkdir $tmp_root
lappend ::cleanup_dirs $tmp_root

proc make_harness_dirs {tag {rc 0}} {
    set p [file join $::tmp_root "$tag-prompt"]
    set l [file join $::tmp_root "$tag-log"]
    file mkdir $p $l
    if {$rc ne ""} {
        set fd [open [file join $p run-rc] w]; puts -nonewline $fd $rc; close $fd
    }
    return [list $p $l]
}

set d [spar::Dispatcher new 2 test_log]

# 13a. Successful harness run reaches done with rc=0 in the result dict.
lassign [make_harness_dirs ok 0] p_ok l_ok
$d enqueue h_ok T1 harness_run [dict create \
    prompt_dir $p_ok log_dir $l_ok harness_class FakeHarness]
wait_for_terminal $d h_ok 3000
assert_eq [$d state h_ok] done "harness_run rc=0 reaches done"

# 13b. Harness rc=1 lands as failed with the rc message.
lassign [make_harness_dirs fail 1] p_f l_f
$d enqueue h_fail T1 harness_run [dict create \
    prompt_dir $p_f log_dir $l_f harness_class FakeHarness]
wait_for_terminal $d h_fail 3000
assert_eq [$d state h_fail] failed "harness_run rc=1 reaches failed"

# 13c. Harness raising an error is caught and surfaced as failed.
lassign [make_harness_dirs throw throw] p_t l_t
$d enqueue h_throw T1 harness_run [dict create \
    prompt_dir $p_t log_dir $l_t harness_class FakeHarness]
wait_for_terminal $d h_throw 3000
assert_eq [$d state h_throw] failed "harness_run catches errors as failed"

# 13d. Cancel before the worker enters the harness body — the cancel
# sentinel is set before resume_queue posts to the tpool, so the
# pre-flight check fires.
lassign [make_harness_dirs precancel 0] p_pc l_pc
$d pause_queue
$d enqueue h_pc T1 harness_run [dict create \
    prompt_dir $p_pc log_dir $l_pc harness_class FakeHarness]
$d cancel h_pc
assert_eq [$d state h_pc] cancelled \
    "cancel before post drops the row without invoking the harness"
$d resume_queue

$d destroy

# ════════════════════════════════════════════════════════════════════════
# 14. ses_send / imap_poll — Phase-2 stubs route to msg_failed
# ════════════════════════════════════════════════════════════════════════
# These two workers are deliberate stubs in Phase 2; the real bodies
# (lifting the Driver classes from transitions/send_email.tcl and
# transitions/check_replies.tcl) land in a follow-up. The stubs prove
# the routing path is in place so Phase 3 can wire the GUI without
# blocking on the send/poll work.
section "14. ses_send / imap_poll stubs"

set d [spar::Dispatcher new 2 test_log]

$d enqueue s1 T6 ses_send [dict create tasks {}]
wait_for_terminal $d s1 2000
assert_eq [$d state s1] failed "ses_send stub fails fast"

$d enqueue i1 T7 imap_poll [dict create tasks {}]
wait_for_terminal $d i1 2000
assert_eq [$d state i1] failed "imap_poll stub fails fast"

$d destroy

finish_tests

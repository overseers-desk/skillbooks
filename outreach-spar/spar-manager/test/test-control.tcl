#!/usr/bin/env tclsh9.0
# Tests for spar-control.tcl: the drain socket a running dispatch
# listens on. Strategy mirrors test-pool.tcl: a Dispatcher driven by
# fake_worker jobs, no real backends. The listener takes port 0 here so
# the OS assigns a free port and parallel test runs never collide.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-dispatcher.tcl]
source [file join $script_dir .. spar-control.tcl]

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

# send_command — one client exchange against the listener: connect,
# send the line, read the one-line reply. Client and server share this
# interpreter's event loop, so the read must pump events rather than
# block: a blocking gets here would starve the server's fileevent and
# deadlock the exchange.
proc send_command {port line} {
    set chan [socket 127.0.0.1 $port]
    fconfigure $chan -blocking 0 -buffering line
    puts $chan $line
    set reply ""
    wait_for {expr {[set reply [gets $chan]] ne "" || [eof $chan]}}
    close $chan
    return $reply
}

# ════════════════════════════════════════════════════════════════════════
# 1. drain cancels the queue, spares the running job
# ════════════════════════════════════════════════════════════════════════
section "1. drain cancels the queue, spares the running job"

set srv [spar::control_listen 0]
set port [lindex [chan configure $srv -sockname] 2]

set disp [spar::Dispatcher new 1]
set ::spar::control_dispatcher $disp
$disp register fake fake_worker
$disp enqueue slow-row fake {plan {{sleep 400}}}
$disp enqueue queued-a fake {plan {}}
$disp enqueue queued-b fake {plan {}}

assert_eq [wait_for [list expr {[$disp state slow-row] eq "running"}]] 1 \
    "slow-row launches (jobs cap 1 keeps the rest queued)"

set reply [send_command $port drain]
assert_eq $reply "ok: draining (2 queued row(s) cancelled)" "drain reply names the cancelled count"
assert_eq $::spar::control_draining 1 "drain flips control_draining"
assert_eq [$disp state queued-a] cancelled "queued-a cancelled"
assert_eq [$disp state queued-b] cancelled "queued-b cancelled"
assert_eq [$disp state slow-row] running "in-flight row keeps running"

assert_eq [wait_for [list expr {[$disp state slow-row] eq "done"}]] 1 \
    "in-flight row completes after drain"

# ════════════════════════════════════════════════════════════════════════
# 2. drain is idempotent; unknown commands are refused
# ════════════════════════════════════════════════════════════════════════
section "2. drain is idempotent; unknown commands are refused"

set reply [send_command $port drain]
assert_eq $reply "ok: draining (0 queued row(s) cancelled)" "second drain finds nothing to cancel"

set reply [send_command $port status]
assert_eq $reply "error: unknown command (try: drain)" "unknown verb refused"

$disp destroy
set ::spar::control_dispatcher ""

# ════════════════════════════════════════════════════════════════════════
# 3. drain with no live pool still sets the flag
# ════════════════════════════════════════════════════════════════════════
section "3. drain with no live pool still sets the flag"

set ::spar::control_draining 0
set reply [send_command $port drain]
assert_eq $reply "ok: draining (0 queued row(s) cancelled)" "drain between passes answers ok"
assert_eq $::spar::control_draining 1 "flag set with no pool live"

close $srv

finish_tests

#!/usr/bin/env tclsh9.0
# Tests for spar::control: the drain socket a running dispatch
# listens on. Strategy mirrors test-pool.tcl: a Dispatcher driven by
# fake_worker jobs, no real backends. The listener takes port 0 here so
# the OS assigns a free port and parallel test runs never collide.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::dispatcher
package require spar::control

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

# listen_ephemeral — a listener on an OS-assigned port, returned as
# {chan port}. Port 0 keeps parallel test runs from colliding, and the
# assignment is read back from the channel.
proc listen_ephemeral {} {
    set srv [spar::control_listen 0]
    return [list $srv [lindex [chan configure $srv -sockname] 2]]
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
assert_eq $reply "error: unknown command (try: drain | jobs N | setenv NAME=VALUE)" "unknown verb refused"

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

# ════════════════════════════════════════════════════════════════════════
# 4. a taken port raises rather than sliding to another
# ════════════════════════════════════════════════════════════════════════
section "4. a taken port raises rather than sliding to another"

# The CLI turns this error into a startup failure, so the port an
# operator was given stays the port that answers.
lassign [listen_ephemeral] held_srv held_port
assert_eq [catch {spar::control_listen $held_port}] 1 \
    "binding a port already held raises"

close $held_srv

# ── setenv: the second protocol verb ─────────────────────────────────
section "setenv sets ::env for later worker launches"

lassign [listen_ephemeral] env_srv env_port
catch {unset ::env(SPAR_TEST_SETENV)}
set reply [send_command $env_port "setenv SPAR_TEST_SETENV=/tmp/claude-b"]
assert_match $reply "ok: SPAR_TEST_SETENV*" "setenv replies ok naming the variable"
assert_eq $::env(SPAR_TEST_SETENV) "/tmp/claude-b" "setenv lands in ::env"

set reply [send_command $env_port "setenv 1BAD=x"]
assert_match $reply "error: unknown command*" "malformed name rejected"

set reply [send_command $env_port "bogus"]
assert_match $reply "*jobs N*setenv NAME=VALUE*" "unknown-command reply names every verb"
unset ::env(SPAR_TEST_SETENV)
close $env_srv

# ── jobs: resize the pool cap mid-run ────────────────────────────────
section "jobs resizes the live pool and outlives it"

lassign [listen_ephemeral] jobs_srv jobs_port
set ::spar::control_jobs_cap ""
set disp [spar::Dispatcher new 1]
set ::spar::control_dispatcher $disp
$disp register fake fake_worker
$disp enqueue slow-a fake {plan {{sleep 400}}}
$disp enqueue slow-b fake {plan {{sleep 400}}}
$disp enqueue slow-c fake {plan {{sleep 400}}}
assert_eq [wait_for [list expr {[$disp state slow-a] eq "running"}]] 1 \
    "first row launches (cap 1 queues the rest)"
assert_eq [llength [$disp queued_jobs]] 2 "two rows wait behind cap 1"

set reply [send_command $jobs_port "jobs 3"]
assert_eq $reply "ok: jobs cap 3 (was 1)" "jobs reply names new and old cap"
assert_eq [llength [$disp queued_jobs]] 0 "raised cap launches the queue at once"
assert_eq $::spar::control_jobs_cap 3 "the value is recorded for later pools"

set reply [send_command $jobs_port "jobs 0"]
assert_match $reply "error: unknown command*" "jobs 0 refused"
set reply [send_command $jobs_port "jobs many"]
assert_match $reply "error: unknown command*" "non-numeric jobs refused"

foreach r {slow-a slow-b slow-c} {
    assert_eq [wait_for [list expr {[$disp state $r] eq "done"}]] 1 "$r completes"
}
$disp destroy
set ::spar::control_dispatcher ""

set reply [send_command $jobs_port "jobs 7"]
assert_eq $reply "ok: jobs cap 7 (no live pool — applies from the next pass)" \
    "no-pool jobs answers ok and records"
assert_eq $::spar::control_jobs_cap 7 "no-pool jobs still records the value"
set ::spar::control_jobs_cap ""
close $jobs_srv

finish_tests

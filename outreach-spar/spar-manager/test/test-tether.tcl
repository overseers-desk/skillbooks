#!/usr/bin/env tclsh9.0
# Tests for the claude-session tether (#202): a session harness_run
# launches dies with the dispatcher process however that process ends,
# and the session's .stderr log records that it was in flight.
#
# The hard-kill case needs a dispatcher that can be SIGKILLed, so it runs
# in a child tclsh that loads spar::dispatcher, tethers a stub harness and
# starts a fake claude under deadman exactly as coachman's _invoke does.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::dispatcher
package require deadman

proc pid_alive {p} {
    if {$p eq ""} { return 0 }
    return [expr {![catch {exec kill -0 $p 2>/dev/null}]}]
}
proc read_file {path} {
    if {![file exists $path]} { return "" }
    set fd [open $path r]; set s [read $fd]; close $fd
    return $s
}
proc wait_until {script {timeout_ms 20000}} {
    set deadline [expr {[clock milliseconds] + $timeout_ms}]
    while {[clock milliseconds] < $deadline} {
        if {[uplevel 1 $script]} { return 1 }
        after 100
    }
    return 0
}

set dir [make_temp_dir]

# A fake claude: records its pid, starts a grandchild the group kill must
# also reach, and waits; "quick" makes it print and exit at once.
set fake [file join $dir fake-claude]
set fd [open $fake w]
puts $fd "#!/bin/sh
if \[ \"\$1\" = quick \]; then echo \$\$ > \"$dir/quick.pid\"; echo done; exit 0; fi
echo \$\$ > \"$dir/claude.pid\"
sleep 300 &
echo \$! > \"$dir/grandchild.pid\"
echo started
wait"
close $fd
file attributes $fake -permissions 0755

oo::class create StubHarness {
    method claude_bin {} { return $::fake_claude }
}
oo::class create NoClaudeHarness {
    method claude_bin {} { return "" }
}

section "1. tether_harness rewires claude_bin"

set ::fake_claude $fake
set h [StubHarness new]
spar::tether_harness $h
assert_eq [$h claude_bin] $::spar::tether_bin \
    "a tethered harness launches tools/claude-tether"
assert_eq [file executable $::spar::tether_bin] 1 "tools/claude-tether is executable"
assert_eq $::env(SPAR_TETHER_CLAUDE) $fake "the real claude rides SPAR_TETHER_CLAUDE"
assert_eq $::env(SPAR_TETHER_PID) [pid] "this process's pid rides SPAR_TETHER_PID"

set n [NoClaudeHarness new]
spar::tether_harness $n
assert_eq [$n claude_bin] "" "a claude_bin that finds no claude still returns empty"

set plain [oo::object new]
spar::tether_harness $plain
assert_eq [info object methods $plain] {} "an instance with no claude_bin is left alone"

section "2. a session that ends on its own is reaped at once"

set t0 [clock milliseconds]
set res [deadman::run [list [$h claude_bin] quick] -err [file join $dir quick.stderr]]
set elapsed [expr {[clock milliseconds] - $t0}]
assert_eq [dict get $res exit] 0 "the session's exit code comes through the tether"
assert_eq [string trim [dict get $res stdout]] done "the session's stdout comes through the tether"
assert_eq [expr {$elapsed < 1500}] 1 \
    "the watcher does not hold the stdout pipe open (took ${elapsed}ms)"
set qlead [string trim [read_file [file join $dir quick.pid]]]
proc group_members {pg} {
    catch {exec ps -o pid= -g $pg} out
    return [regexp -all -inline {\d+} $out]
}
assert_eq [wait_until {expr {[group_members $qlead] eq ""}} 5000] 1 \
    "the watcher leaves the session's group once claude is reaped"
assert_eq [string match *tether:* [read_file [file join $dir quick.stderr]]] 0 \
    "a session that ended on its own records no tether line"

section "3. a launch whose parent is not the dispatcher runs untethered"

set out [exec env SPAR_TETHER_PID=1 SPAR_TETHER_CLAUDE=$fake \
    $::spar::tether_bin quick 2>@1]
assert_match $out "*running untethered*" "the mismatch is reported on stderr"
assert_match $out "*done*" "and claude still runs"

section "4. a SIGKILLed dispatcher takes its claude session with it"

set child [file join $dir dispatcher.tcl]
set fd [open $child w]
puts $fd [string map [list @HELPERS@ [file join $script_dir test-helpers.tcl] \
        @FAKE@ $fake @DIR@ $dir] {
    source {@HELPERS@}
    package require spar::state
    package require spar::dispatcher
    package require deadman
    set ::fake_claude {@FAKE@}
    oo::class create StubHarness {
        method claude_bin {} { return $::fake_claude }
    }
    set h [StubHarness new]
    spar::tether_harness $h
    proc finished {res} { set ::forever 1 }
    deadman::run [list [$h claude_bin] long] \
        -out {@DIR@/claude.out} -err {@DIR@/claude.stderr} -done finished
    vwait ::forever
}]
close $fd

set dpid [exec tclsh9.0 $child >/dev/null 2>[file join $dir dispatcher.err] &]
set cpid_file [file join $dir claude.pid]
set gpid_file [file join $dir grandchild.pid]
if {![wait_until {expr {[file exists $gpid_file] && [file size $gpid_file] > 0}}]} {
    puts "FAIL: fake claude never started; dispatcher stderr:"
    puts [read_file [file join $dir dispatcher.err]]
    incr ::failures
} else {
    set cpid [string trim [read_file $cpid_file]]
    set gpid [string trim [read_file $gpid_file]]
    assert_eq [string trim [exec ps -o ppid= -p $cpid]] $dpid \
        "claude runs as the dispatcher's child"
    assert_eq [pid_alive $cpid] 1 "claude is running before the kill"
    exec kill -KILL $dpid
    assert_eq [wait_until {expr {![pid_alive $cpid]}}] 1 \
        "claude ends after the dispatcher is SIGKILLed"
    assert_eq [wait_until {expr {![pid_alive $gpid]}}] 1 \
        "claude's own child ends with it"
    assert_match [read_file [file join $dir claude.stderr]] \
        "*spar tether: * dispatcher pid $dpid ended with this session in flight; terminating claude pid $cpid*" \
        "the session's .stderr log records how it ended"
    catch {exec kill -KILL $cpid $gpid 2>/dev/null}
}

finish_tests

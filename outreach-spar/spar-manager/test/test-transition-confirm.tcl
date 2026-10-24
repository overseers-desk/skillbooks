#!/usr/bin/env tclsh9.0
# The up-front send confirmation needs a terminal to ask (#203).
#
# spar-transition asks [y/N] on stdin before a transition that requires
# send confirmation. A run with no terminal on stdin (cron, nohup, a
# closed pipe) cannot be asked: it names --yes and exits 2, its own
# status, distinct from the exit 1 of a run whose work failed, before
# any row is prepared.
#
# Strategy: a launched campaign with one T6-ready row, run through the
# CLI under a wall-clock bound with stdin from /dev/null or a pipe, so
# a gate that waits on stdin shows as a timeout, not a hang.
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state

# run_status — run $cmd (an exec-style list, redirections included)
# bounded by $ms, returning {<exit status> <output>}; a run that does
# not exit in time is killed and reports status "timeout".
proc run_status {cmd ms} {
    set fd [open "|$cmd 2>@1" r]
    set kids [pid $fd]
    fconfigure $fd -blocking 0
    set ::_rs_out ""
    fileevent $fd readable [list apply {{fd} {
        append ::_rs_out [read $fd]
        if {[eof $fd]} { set ::_rs_state exited }
    }} $fd]
    set timer [after $ms {set ::_rs_state timeout}]
    vwait ::_rs_state
    after cancel $timer
    if {$::_rs_state eq "timeout"} {
        foreach p $kids { catch {exec kill -9 $p} }
        catch {close $fd}
        return [list timeout $::_rs_out]
    }
    fconfigure $fd -blocking 1
    set status 0
    if {[catch {close $fd} - opts]} {
        set ec [dict get $opts -errorcode]
        if {[lindex $ec 0] eq "CHILDSTATUS"} { set status [lindex $ec 2] }
    }
    return [list $status $::_rs_out]
}

section "fixture: a launched campaign with one T6-ready row"

set cdir [make_temp_campaign]
set seg [file join $cdir segments seg-a]
file mkdir $seg
write_segment_yaml $seg "title: seg-a\nversion: \"2.0\"\n"
write_campaign_yaml $cdir "campaign: Confirm\nversion: \"$spar::CURRENT_SPEC_VERSION\"\nstart_date: 2026-01-01\nprimary_channel: email\nsegments:\n  - seg-a\n"
write_profile $seg "t6a"
write_approach_yaml $seg "t6a" [approach_yaml_final_unsent]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "T6A" stem "t6a" email "test@acme-venues.au" star_rating 4}]]

set cli  [file join $script_dir .. spar-transition]
set yaml [file join $cdir campaigns camp.yaml]

lassign [run_status [list tclsh9.0 $cli $yaml --dispatchable --control-port=0 </dev/null] 60000] st out
assert_eq $st 0 "the overview runs"
assert_match $out "*T6: Approach → Send*1 dispatchable*" "the T6 row is ready, so a live T6 run reaches the gate"

section "no terminal on stdin: the run names --yes and exits 2"

lassign [run_status [list tclsh9.0 $cli $yaml T6 --control-port=0 </dev/null] 60000] st out
assert_eq $st 2 "stdin from /dev/null exits with the unconfirmed status, not the failure status"
assert_match $out "*pass --yes*" "the message names the flag"
assert_match $out "*T6 (Approach → Send): 1 live action(s)*" "and the transition and count it could not confirm"
assert_eq [string match {*\[START\]*} $out] 0 "no row was started"
assert_eq [string match "*Aborted.*" $out] 0 "the run does not abort as if answered N"

section "a pipe is not a terminal either"

# A piped answer is not an operator at a prompt; the one unattended
# route is --yes, as the help says.
lassign [run_status [list tclsh9.0 $cli $yaml T6 --control-port=0 << "y\n"] 60000] st out
assert_eq $st 2 "a piped y does not stand in for --yes"
assert_match $out "*pass --yes*" "the message names the flag"

section "--yes passes the gate unattended"

# Dry run so the gate, not SES, is what the run exercises; the row is
# then prepared and reported, which the unattended abort never reached.
lassign [run_status [list tclsh9.0 $cli $yaml T6 --yes --dry-run --control-port=0 </dev/null] 60000] st out
assert_eq [expr {$st eq "timeout"}] 0 "the run exits"
assert_eq [expr {$st == 2}] 0 "with --yes the gate is not the reason it exits"
assert_match $out {*\[START\] t6a*} "the row is prepared"

finish_tests

#!/usr/bin/env tclsh9.0
# One contact, two segments: the pass must still finish.
#
# A contact listed in two segments' rosters is one ready task (the ready
# set is deduped by stem) but two prepared rows, one prompt dir per
# segment. The pool keys a job by its stem, so only the first becomes a
# job; a front-end that expects a report from every prepared row waits
# for one that can never arrive, and the run hangs after its last worker
# finishes.
#
# Strategy: build the two-segment campaign, then run spar-transition.tcl
# against it under a wall-clock bound. --dry-run keeps the rows off
# claude, so a bounded run that has not exited is the hang itself.
package require yaml
package require TclOO
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts

# run_bounded — run $cmd, returning {ok <output>} or {timeout <output>}.
# Pure Tcl rather than coreutils `timeout`, which is not on a stock mac.
proc run_bounded {cmd ms} {
    set fd [open "|$cmd 2>@1" r]
    set kids [pid $fd]
    fconfigure $fd -blocking 0
    set ::_rb_out ""
    fileevent $fd readable [list apply {{fd} {
        append ::_rb_out [read $fd]
        if {[eof $fd]} { set ::_rb_state ok }
    }} $fd]
    set timer [after $ms {set ::_rb_state timeout}]
    vwait ::_rb_state
    after cancel $timer
    if {$::_rb_state eq "timeout"} {
        foreach p $kids { catch {exec kill -9 $p} }
    }
    catch {close $fd}
    return [list $::_rb_state $::_rb_out]
}

# ════════════════════════════════════════════════════════════════════════
# 60. a stem in two segments still converges
# ════════════════════════════════════════════════════════════════════════
section "60. duplicate stem across segments"

# alice is in both rosters; bob and carol keep each segment in the pass,
# which is what puts alice's second row in front of the dispatcher.
set cdir [make_temp_campaign]
foreach seg {seg-a seg-b} {
    file mkdir [file join $cdir segments $seg]
    write_segment_yaml [file join $cdir segments $seg] \
        "title: $seg\nversion: \"2.0\"\n"
}
write_roster_tsv [file join $cdir segments seg-a] $::std_headers [list \
    [make_base_row {stem alice contact_name Alice}] \
    [make_base_row {stem bob contact_name Bob}]]
write_roster_tsv [file join $cdir segments seg-b] $::std_headers [list \
    [make_base_row {stem alice contact_name Alice}] \
    [make_base_row {stem carol contact_name Carol}]]
write_campaign_yaml $cdir \
    "campaign: Duplicate Stem\nversion: \"$spar::CURRENT_SPEC_VERSION\"\nsegments:\n  - seg-a\n  - seg-b\n"

set prep [spar::p::prepare_for_pool \
    [dict create campaign_file [file join $cdir campaigns camp.yaml]] \
    {apply {args {}}}]
set stems [lmap pair [dict get $prep rows] {lindex $pair 0}]
assert_eq [llength $stems] 4 "prep builds one row per segment listing"
assert_eq [llength [lsort -unique $stems]] 3 "one stem carries two of them"

set cli [file join $script_dir .. spar-transition.tcl]
lassign [run_bounded [list tclsh9.0 $cli \
    [file join $cdir campaigns camp.yaml] T1 --dry-run --control-port=0] \
    60000] state out
assert_eq $state ok "the pass exits instead of waiting on the row the pool refused"
assert_match $out "*alice: listed in more than one segment*" \
    "the skipped row is named"
assert_match $out "*3 of 3 validated*" "the three distinct stems all run"

finish_tests

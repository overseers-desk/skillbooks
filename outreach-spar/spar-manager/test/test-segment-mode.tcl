#!/usr/bin/env tclsh9.0
# test-segment-mode.tcl — population-tier work from a segment alone:
# resolve_segment, the classify guard for a missing approach context,
# campaign-free P/S prep, and the three CLIs taking a segments/<name>
# input. Campaign-tier T-ids are refused in segment mode.
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts

# Bounded CLI run, as in test-dispatch-duplicate-stem.tcl: a hang fails
# the test instead of wedging the suite.
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

set State [spar::State new]

# ── Fixture: a segment-only instance root (no campaigns/ folder) ──
proc make_segment_only {name} {
    set base [make_temp_dir]
    file mkdir [file join $base segments $name]
    return [file join $base segments $name]
}

section "resolve_segment"

set seg [make_segment_only lender]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {stem "alice-acme" contact_name "Alice" star_rating 4 email a@acme.test}] \
    [make_base_row {stem "bob-none" contact_name "Bob" star_rating 4 email ""}]]
write_segment_yaml $seg "version: \"2.0\"\ntitle: Lenders\ndate: 2026-08-01\ndiscovery_criteria: |\n  test\n"
write_profile $seg "alice-acme"

set rs [spar::resolve_segment $seg]
assert_eq [dict get $rs campaign_name] lender "segment name stands as the run label"
assert_eq [dict get $rs cdata] {} "no campaign dict in segment mode"
assert_eq [llength [dict get $rs segment_paths]] 1 "one rostered segment"
assert_eq [dict get $rs segment_paths] [dict get $rs all_segment_paths] \
    "rostered and named sets coincide when the roster exists"
assert_eq [dict get $rs campaign_dir] [file dirname [file dirname $seg]] \
    "instance root is two levels up"

set rs2 [spar::resolve_segment "$seg.yaml"]
assert_eq [dict get $rs2 campaign_name] lender "the definition YAML names the same segment"

# Seeded but rosterless: valid input, nothing to classify.
set seeded [make_segment_only fresh]
write_segment_yaml $seeded "version: \"2.0\"\ntitle: Fresh\ndate: 2026-08-01\ndiscovery_criteria: |\n  test\n"
set rs3 [spar::resolve_segment $seeded]
assert_eq [dict get $rs3 segment_paths] {} "no roster, nothing for classification"
assert_eq [llength [dict get $rs3 all_segment_paths]] 1 "the named set still carries it"

assert_error {spar::resolve_segment [make_temp_dir]} \
    "*not under a segments/ folder*" "a stray path is refused"

section "classification without approach context"

set contacts [$State classify_segment $seg ""]
set by_stem [dict create]
foreach c $contacts { dict set by_stem [dict get $c stem] $c }
assert_eq [dict get [dict get $by_stem alice-acme] state] PROFILED \
    "profiled contact classifies PROFILED with no approach folder"
assert_eq [dict get [dict get $by_stem alice-acme] approach_path] "" \
    "no approach path is fabricated"
assert_eq [dict get [dict get $by_stem bob-none] state] DISCOVERED \
    "unprofiled contact classifies DISCOVERED"

section "campaign-free S prep (T0 from a seeded segment)"

set swseg [make_segment_only swept]
write_segment_yaml $swseg "version: \"2.0\"\ntitle: Swept\ndate: 2026-08-01\ndiscovery_criteria: |\n  test\n"
set fd [open [spar::sweep_yaml_for_segment $swseg] w]
puts $fd {version: "2.0"}
puts $fd "segment: swept"
puts $fd "market_estimate:"
puts $fd "  denominator: 10"
puts $fd "  basis: test"
puts $fd "sources:"
puts $fd "- name: State register"
puts $fd "  type: registry"
puts $fd "  status: open"
puts $fd "exclusions: \[\]"
puts $fd "escapes: \[\]"
puts $fd "rounds: \[\]"
close $fd
set t0_tasks [spar::transition_campaign_tasks T0 {} "" \
    [list [list swept $swseg]]]
assert_eq [llength $t0_tasks] 1 "T0 derives its census task with no campaign"
assert_eq [dict get [lindex $t0_tasks 0] task_state] dispatchable \
    "the open source is dispatchable"
set sprep [spar::s::prepare_for_pool \
    [dict create segment_dirs [list $swseg]] {apply {args {}}}]
assert_eq [llength [dict get $sprep rows]] 1 "S prep builds the source row campaign-free"

# An unreachable source whose probe predates the latest round is due a
# re-probe; one probed in the latest round is not. Prep builds a row for
# exactly the sources the task list reports as dispatchable (#216).
set fd [open [spar::sweep_yaml_for_segment $swseg] w]
puts $fd {version: "2.0"}
puts $fd "segment: swept"
puts $fd "sources:"
puts $fd "- name: State register"
puts $fd "  type: registry"
puts $fd "  status: open"
puts $fd "- name: Gated forum"
puts $fd "  type: informal"
puts $fd "  status: unreachable (login wall)"
puts $fd "  probe: login wall (round 1)"
puts $fd "- name: Gated group"
puts $fd "  type: informal"
puts $fd "  status: unreachable (login wall)"
puts $fd "  probe: login wall (round 2)"
puts $fd "rounds:"
puts $fd "- n: 1"
puts $fd "- n: 2"
close $fd
set t0_tasks [spar::transition_campaign_tasks T0 {} "" \
    [list [list swept $swseg]]]
set task_stems [lsort [lmap t $t0_tasks {dict get $t stem}]]
assert_eq $task_stems [lsort [list [spar::sweep_task_stem swept "State register"] \
    [spar::sweep_task_stem swept "Gated forum"]]] \
    "the stale-probe unreachable source is a task; the freshly probed one is not"
set sprep [spar::s::prepare_for_pool \
    [dict create segment_dirs [list $swseg]] {apply {args {}}}]
assert_eq [lsort [lmap pair [dict get $sprep rows] {lindex $pair 0}]] $task_stems \
    "S prep builds a row for every source the task list reports, and no other"

# A source whose control or probe is a block scalar fails at prep, before
# a worker is paid for: the harness could not write its verdict back
# (#218). The validator names the same source.
set fd [open [spar::sweep_yaml_for_segment $swseg] w]
puts $fd {version: "2.0"}
puts $fd "segment: swept"
puts $fd "sources:"
puts $fd "- name: State register"
puts $fd "  type: registry"
puts $fd "  status: open"
puts $fd "- name: Trade directory"
puts $fd "  type: directory"
puts $fd "  status: partial"
puts $fd "  control: >-"
puts $fd "    Known member found"
puts $fd "    through the same query."
puts $fd "rounds: \[\]"
close $fd
set ::prep_events {}
set sprep [spar::s::prepare_for_pool \
    [dict create segment_dirs [list $swseg]] \
    {apply {args { lappend ::prep_events $args }}}]
assert_eq [lmap pair [dict get $sprep rows] {lindex $pair 0}] \
    [list [spar::sweep_task_stem swept "State register"]] \
    "a source with a block-scalar control gets no prompt dir"
assert_eq [llength $::prep_events] 1 "and is reported once"
lassign [lindex $::prep_events 0] ev_stem ev_status ev_msg
assert_eq [list $ev_stem $ev_status] \
    [list [spar::sweep_task_stem swept "Trade directory"] failed] \
    "as a failed row under its own stem"
assert_match $ev_msg "control is a block scalar*" "naming the field"
set codes [lmap i [spar::validate_seed $swseg] {
    if {[dict get $i code] ne "block_scalar_source_field"} continue
    dict get $i message
}]
assert_eq [llength $codes] 1 "the sweep validator flags the block-scalar field"
assert_match [lindex $codes 0] "*'Trade directory': control*" \
    "naming the source and the field"

section "campaign-free P prep"

set prep [spar::p::prepare_for_pool \
    [dict create segment_dirs [list $seg] stems {bob-none}] {apply {args {}}}]
set stems [lmap pair [dict get $prep rows] {lindex $pair 0}]
assert_eq $stems bob-none "the named contact is prepared with no campaign"
set pdir [lindex [lindex [dict get $prep rows] 0] 1]
set fd [open [file join $pdir meta.env] r]; set env_text [read $fd]; close $fd
assert_match $env_text "*CAMPAIGN_FILE=\"\"*" "meta.env carries an empty campaign file"

# A row named by stem is prepared over its existing profile. meta.env
# flags it PROFILE_STALE only when the snapshot disagrees with the row
# (#193), so the harness's pre-call re-check never cuts short a
# rebuild of a current profile.
proc alice_meta_env {seg} {
    set prep [spar::p::prepare_for_pool \
        [dict create segment_dirs [list $seg] stems {alice-acme}] {apply {args {}}}]
    set pdir [lindex [lindex [dict get $prep rows] 0] 1]
    set fd [open [file join $pdir meta.env] r]; set t [read $fd]; close $fd
    return $t
}
write_profile $seg "alice-acme" -contact_name "Alice"
assert_eq [string match "*PROFILE_STALE*" [alice_meta_env $seg]] 0 \
    "a current profile prepared by stem carries no stale flag"
write_profile $seg "alice-acme" -contact_name "Alicia"
assert_match [alice_meta_env $seg] "*PROFILE_STALE=1*" \
    "a stale profile prepared by stem is flagged for the re-check"
write_profile $seg "alice-acme"

section "a host with no browser fails prep once (#204)"

# Stand in for a host with neither browser-serialiser nor chromium: the
# probe throws, and counts how often it is asked.
rename spar::detect_browser_cmd _real_detect_browser_cmd
proc spar::detect_browser_cmd {} {
    incr ::browser_probes
    error "spar::detect_browser_cmd: neither browser-serialiser nor chromium on PATH"
}
foreach {kind segdir stems} [list p $seg {alice-acme} s $swseg {}] {
    set ::browser_probes 0
    set ::prep_events {}
    assert_error {spar::${kind}::prepare_for_pool \
            [dict create segment_dirs [list $segdir $segdir] stems $stems] \
            {apply {args { lappend ::prep_events $args }}}} \
        "*neither browser-serialiser nor chromium*" \
        "$kind prep raises the missing browser as its own error"
    assert_eq $::browser_probes 1 "$kind prep asks for the browser once"
    assert_eq $::prep_events {} "$kind prep reports no per-segment failure"
}
rename spar::detect_browser_cmd {}
rename _real_detect_browser_cmd spar::detect_browser_cmd

section "tier filtering at the CLI"

set cli [file join $script_dir .. spar-transition]
lassign [run_bounded [list tclsh9.0 $cli $seg --dispatchable --control-port=0] 60000] st out
assert_eq $st ok "segment-path report run completes"
assert_match $out "*T1*" "population transition reported"
assert_eq [string match "*T6*" $out] 0 "campaign-tier send transition absent from the report"

lassign [run_bounded [list tclsh9.0 $cli $seg T6 --dry-run --control-port=0] 60000] st out
assert_eq $st ok "campaign-tier request in segment mode exits"
assert_match $out "*need a campaign YAML*" "and says why"

section "validate and progress CLIs on a segment"

set vcli [file join $script_dir .. spar-validate-cli.tcl]
lassign [run_bounded [list tclsh9.0 $vcli $seg] 60000] st out
assert_eq $st ok "validate-cli accepts the segment path"
assert_eq [string match "*version_unsupported*" $out] 0 "no campaign version is demanded"

set pcli [file join $script_dir .. spar-progress]
lassign [run_bounded [list tclsh9.0 $pcli $seg] 60000] st out
assert_eq $st ok "progress accepts the segment path"
assert_match $out "*lender*" "the segment row renders"

section "several segments, one virtual campaign"

set root2 [file dirname [file dirname [make_segment_only alpha]]]
set segA [file join $root2 segments alpha]
file mkdir [file join $root2 segments beta]
set segB [file join $root2 segments beta]
write_roster_tsv $segA $::std_headers [list \
    [make_base_row {stem "a1" contact_name "Ann" star_rating 4 email a@x.test}]]
write_roster_tsv $segB $::std_headers [list \
    [make_base_row {stem "b1" contact_name "Ben" star_rating 3 email b@x.test}]]
write_segment_yaml $segA "version: \"2.0\"\ntitle: A\ndate: 2026-08-01\ndiscovery_criteria: |\n  test\n"
write_segment_yaml $segB "version: \"2.0\"\ntitle: B\ndate: 2026-08-01\ndiscovery_criteria: |\n  test\n"

set multi [spar::resolve_segments [list $segA $segB]]
assert_eq [llength [dict get $multi segment_paths]] 2 "both segments in one resolution"
assert_eq [dict get $multi campaign_name] "alpha, beta" "the set names the run"

lassign [run_bounded [list tclsh9.0 $pcli $segA $segB] 60000] st out
assert_eq $st ok "progress over two segments completes"
assert_eq [regexp -all -line {^TOTAL } $out] 1 "one table, one TOTAL row"
assert_match $out "*Segments:*" "header names the set"
assert_eq [string match "*Reach*" $out] 0 "campaign columns absent without a campaign"
assert_eq [string match "*Sent*" $out] 0 "engagement columns absent without a campaign"

lassign [run_bounded [list tclsh9.0 $cli $segA $segB --dispatchable --control-port=0] 60000] st out
assert_eq $st ok "transition report over two segments completes"
assert_match $out "*Segments: alpha, beta*" "run label names the set"

finish_tests

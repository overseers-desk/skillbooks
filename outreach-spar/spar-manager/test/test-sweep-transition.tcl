#!/usr/bin/env tclsh9.0
# test-sweep-transition.tcl — T0 (Seed → Sweep). Covers the sweep-file
# reader/writers (round-trip through spar::yaml_parse, quote safety),
# task selection from the census, the mediated batch applier, and the
# stamp that makes a replay inert.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::harness

set tmpdir [exec mktemp -d /tmp/spar-test-sweep.XXXXXX]
lappend ::cleanup_dirs $tmpdir

# ── Fixture: a seed pair (segments/<seg>.yaml + <seg>.sweep.yaml) ───────

proc write_seed_pair {root seg} {
    file mkdir [file join $root segments $seg]
    file mkdir [file join $root campaigns camp]
    set seg_dir [file join $root segments $seg]
    set fd [open [spar::segment_yaml_for_segment $seg_dir] w]
    puts $fd {version: "2.0"}
    puts $fd "title: Test Segment"
    puts $fd {date: "2026-08-06"}
    puts $fd "provenance: seeded by the test fixture"
    puts $fd "discovery_criteria: |"
    puts $fd "  Everyone in the fixture population."
    puts $fd "rating_rubric: |"
    puts $fd "  5: perfect. 0: excluded."
    close $fd

    set fd [open [spar::sweep_yaml_for_segment $seg_dir] w]
    puts $fd {version: "1.0"}
    puts $fd "segment: $seg"
    puts $fd "market_estimate:"
    puts $fd "  value: 120"
    puts $fd "  derivation: |"
    puts $fd "    Top-down: 120 in the state register."
    puts $fd {  estimated: "2026-08-06"}
    puts $fd "sources:"
    puts $fd "  - name: State register"
    puts $fd "    type: registry"
    puts $fd "    url: https://example.invalid/register"
    puts $fd "    status: unharvested"
    puts $fd "  - name: Trade directory"
    puts $fd "    type: directory"
    puts $fd "    status: partial — 40 of 120 pages read"
    puts $fd "  - name: Local paper"
    puts $fd "    type: outlet"
    puts $fd "    status: exhausted — archive read to 2019"
    puts $fd "  - name: Closed forum"
    puts $fd "    type: informal"
    puts $fd "    status: unreachable (login wall)"
    puts $fd "exclusions: out-of-state operators"
    puts $fd "escapes: \[\]"
    puts $fd "rounds: \[\]"
    close $fd
    return $seg_dir
}

set root [file join $tmpdir inst]
set seg_dir [write_seed_pair $root vic]
set sweep [spar::sweep_yaml_for_segment $seg_dir]
set roster [spar::roster_path_for_segment $seg_dir]

# ── 1. Reader ──────────────────────────────────────────────────────────

section "1. read_sweep_yaml"

set data [spar::read_sweep_yaml $sweep]
assert_eq [dict get $data segment] vic "segment key read"
assert_eq [llength [dict get $data sources]] 4 "four census sources"
assert_eq [dict get $data market_estimate estimated] "2026-08-06" \
    "quoted date stays an ISO string"
assert_error {spar::read_sweep_yaml [file join $tmpdir nope.sweep.yaml]} \
    "*not found*" "missing file errors"

section "2. status tokens"

assert_eq [spar::sweep_status_token "partial — 40 of 120 pages read"] partial \
    "base token split off the free-text reason"
assert_eq [spar::sweep_status_token "unreachable (login wall)"] unreachable \
    "bracketed reason does not join the token"
assert_eq [spar::sweep_source_open "exhausted — archive read to 2019"] 0 \
    "exhausted source is closed"
assert_eq [spar::sweep_source_open "unharvested"] 1 "unharvested source is open"
assert_eq [spar::transition_auto_safe T0] 1 \
    "T0 is auto-safe: --auto sweeps every open source"

# ── 3. Quote-safe scalars ──────────────────────────────────────────────

section "3. yaml_scalar"

assert_eq [spar::yaml_scalar "partial: 40 of 120"] {"partial: 40 of 120"} \
    "a mid-text ': ' is quoted"
assert_eq [spar::yaml_scalar "2026-08-06"] "2026-08-06" "an exact date stays bare"
assert_eq [spar::yaml_scalar "unharvested"] "unharvested" "a plain token stays bare"
assert_eq [spar::yaml_scalar 3] 3 "an integer stays bare"
assert_eq [spar::yaml_scalar ""] {""} "an empty value is quoted"
assert_eq [spar::yaml_scalar "no"] {"no"} "a YAML bool token is quoted"
assert_eq [spar::yaml_scalar "- leading dash"] {"- leading dash"} \
    "a leading indicator character is quoted"
assert_error {spar::yaml_scalar "two\nlines"} "*block scalar*" \
    "a multi-line value is refused, not flattened"

# ── 3b. _yaml_block_entries ─────────────────────────────────────────────

section "3b. _yaml_block_entries"

# Column-0 style: items dash at the same indentation as the key itself.
set c0_lines [list \
    {sources:} \
    {- name: Alpha} \
    {  type: registry} \
    {- name: Beta} \
    {  type: directory} \
    {exclusions: out-of-state}]
set c0_blk [spar::_yaml_block_entries $c0_lines sources]
assert_eq [llength [dict get $c0_blk entries]] 2 \
    "column-0 items: both entries seen"
assert_eq [dict get $c0_blk entries] {{1 2 2} {3 4 2}} \
    "column-0 items: line ranges cover the item and its own fields"
assert_eq [dict get $c0_blk block_end] 5 \
    "column-0 items: block ends at the following top-level key, not before"

# Indented style: unchanged from today's behaviour.
set ind_lines [list \
    {sources:} \
    {  - name: Alpha} \
    {    type: registry} \
    {  - name: Beta} \
    {    type: directory} \
    {exclusions: out-of-state}]
set ind_blk [spar::_yaml_block_entries $ind_lines sources]
assert_eq [llength [dict get $ind_blk entries]] 2 \
    "indented items: both entries seen"
assert_eq [dict get $ind_blk entries] {{1 2 4} {3 4 4}} \
    "indented items: line ranges unchanged"
assert_eq [dict get $ind_blk block_end] 5 \
    "indented items: block ends at the following top-level key"

# A second top-level sequence follows: the two blocks do not merge.
set two_seq_lines [list \
    {sources:} \
    {- name: Alpha} \
    {rounds:} \
    {- n: 1}]
set two_seq_blk [spar::_yaml_block_entries $two_seq_lines sources]
assert_eq [llength [dict get $two_seq_blk entries]] 1 \
    "a following top-level sequence: sources keeps only its own item"
assert_eq [dict get $two_seq_blk block_end] 2 \
    "a following top-level sequence: sources ends at 'rounds:', not merged into it"

# End-of-file with no key following: the last item still closes.
set eof_lines [list {sources:} {- name: Alpha} {  type: registry}]
set eof_blk [spar::_yaml_block_entries $eof_lines sources]
assert_eq [dict get $eof_blk entries] {{1 2 2}} \
    "column-0 items: end-of-file closes the last entry"
assert_eq [dict get $eof_blk block_end] 3 "end-of-file: block_end is the line count"

# ── 4. update_source_status ────────────────────────────────────────────

section "4. update_source_status"

spar::update_source_status $sweep "State register" "partial: 12 of 120 resolved"
set data [spar::read_sweep_yaml $sweep]
set st ""
foreach s [dict get $data sources] {
    if {[dict get $s name] eq "State register"} { set st [dict get $s status] }
}
assert_eq $st "partial: 12 of 120 resolved" \
    "status carrying ': ' re-parses as one scalar"
assert_eq [dict get $data market_estimate value] 120 \
    "the rest of the file survives the edit"
assert_match [spar::_sweep_read $sweep] "*Top-down: 120 in the state register.*" \
    "the derivation block scalar is untouched"
assert_error {spar::update_source_status $sweep "No such source" partial} \
    "*no source named*" "an unknown source errors rather than appending one"

# ── 4b. update_source_field round-trip (column-0 sources) ───────────────

section "4b. update_source_field round-trip (column-0 sources)"

set c0_sweep [file join $tmpdir col0.sweep.yaml]
set fd [open $c0_sweep w]
puts $fd {version: "1.0"}
puts $fd "segment: col0test"
puts $fd "sources:"
puts $fd "- name: State register"
puts $fd "  type: registry"
puts $fd "  status: unharvested"
puts $fd "- name: Trade directory"
puts $fd "  type: directory"
puts $fd "  status: partial — 40 of 120 pages read"
puts $fd "exclusions: out-of-state operators"
puts $fd "rounds: \[\]"
close $fd

set c0_before [spar::read_sweep_yaml $c0_sweep]

# Set a field that already exists on one entry.
spar::update_source_field $c0_sweep "State register" status \
    "exhausted — all 120 entries read"

# Set a field that does not yet exist on the other entry.
spar::update_source_field $c0_sweep "Trade directory" note \
    "flagged for follow-up"

assert_eq [expr {![catch {spar::read_sweep_yaml $c0_sweep}]}] 1 \
    "column-0 sources: the file still parses after both edits"
set c0_after [spar::read_sweep_yaml $c0_sweep]

proc c0_source {data name} {
    foreach s [dict get $data sources] {
        if {[dict get $s name] eq $name} { return $s }
    }
    error "no source named '$name'"
}

set sr_before [c0_source $c0_before "State register"]
set sr_after  [c0_source $c0_after  "State register"]
assert_eq [dict get $sr_after status] "exhausted — all 120 entries read" \
    "column-0: existing field set on the named source"
assert_eq [dict get $sr_after type] [dict get $sr_before type] \
    "column-0: an untouched field on the edited source survives"

set td_before [c0_source $c0_before "Trade directory"]
set td_after  [c0_source $c0_after  "Trade directory"]
assert_eq [dict get $td_after note] "flagged for follow-up" \
    "column-0: a field absent from the entry is inserted"
assert_eq [dict get $td_after status] [dict get $td_before status] \
    "column-0: the other source's pre-existing field is untouched"
assert_eq [dict get $td_after type] [dict get $td_before type] \
    "column-0: the other source's other field is untouched"

assert_eq [dict get $c0_after exclusions] [dict get $c0_before exclusions] \
    "column-0: a key after the sequence survives both edits"
assert_eq [dict get $c0_after rounds] [dict get $c0_before rounds] \
    "column-0: rounds is untouched"

assert_error {spar::update_source_field $c0_sweep "No such source" status x} \
    "*no source named*" "column-0: an unknown source still errors, not appends"

# ── 5. append_sweep_round ──────────────────────────────────────────────

section "5. append_sweep_round"

spar::append_sweep_round $sweep [dict create \
    n 1 date 2026-08-06 method "T0: one worker per source" \
    inputs {"State register"} \
    reconciliation "State register: 12 kept of 120 listed" \
    coverage_after "12/120" yield 12]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 1 "rounds: \[\] became one entry"
set r [lindex [dict get $data rounds] 0]
assert_eq [dict get $r date] "2026-08-06" "round date re-parses as ISO, not epoch"
assert_eq [dict get $r method] "T0: one worker per source" \
    "a method carrying ': ' re-parses whole"
assert_eq [dict get $r yield] 12 "yield recorded"

# A second source in the same round merges rather than opening a new one.
spar::append_sweep_round $sweep [dict create \
    n 1 date 2026-08-06 method "T0: one worker per source" \
    inputs {"Trade directory"} \
    reconciliation "Trade directory: 5 kept of 60 listed" \
    coverage_after "17/120" yield 5]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 1 "same round number merges"
set r [lindex [dict get $data rounds] 0]
assert_eq [llength [dict get $r inputs]] 2 "both sources listed as inputs"
assert_eq [dict get $r yield] 17 "yields summed"
assert_eq [dict get $r coverage_after] "17/120" "coverage is the fresher count"
assert_match [dict get $r reconciliation] "*State register*Trade directory*" \
    "both reconciliation lines kept"

# A later round appends after the last entry.
spar::append_sweep_round $sweep [dict create \
    n 2 date 2026-08-07 method "T0 round 2" inputs {"Local paper"} \
    reconciliation "Local paper: 0 kept" coverage_after "17/120" yield 0]
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data rounds]] 2 "round 2 appended"
assert_eq [dict get [lindex [dict get $data rounds] 1] n] 2 "in order"
assert_eq [dict get $data exclusions] "out-of-state operators" \
    "keys after rounds: survive the splice"

# ── 6. Task selection ──────────────────────────────────────────────────

section "6. task selection from the census"

set camp [file join $root campaigns camp.yaml]
set fd [open $camp w]
puts $fd "campaign: test"
puts $fd {version: "2.0"}
puts $fd "primary_channel: email"
puts $fd "segments:"
puts $fd "  vic:"
puts $fd "    plan: sweep it"
close $fd

proc task_named {tasks name} {
    foreach t $tasks {
        if {[dict get $t contact_name] eq $name} { return $t }
    }
    error "no task named '$name'"
}

set cdata [spar::load_campaign $camp]
set seg_paths [list [list vic [file join $root segments vic]]]
set tasks [spar::transition_campaign_tasks T0 $cdata $camp $seg_paths]
set names {}
foreach t $tasks { lappend names [dict get $t contact_name] }

# By this point in the fixture (section 5) rounds: holds n 1 and n 2, so the
# latest round is 2. Closed forum is unreachable with no probe field,
# which dispatches it for the probe rather than skipping it.
assert_eq [lsort $names] {{Closed forum} {State register} {Trade directory}} \
    "exhausted is skipped; open sources and a probe-less unreachable source dispatch"
assert_match [dict get [task_named $tasks "Closed forum"] reason] \
    "*no probe recorded*probe it*" \
    "no probe on record: the reason names the missing probe"

assert_eq [dict get [lindex $tasks 0] task_state] dispatchable \
    "open sources are dispatchable"
assert_eq [dict get [lindex $tasks 0] segment] vic "task carries its segment"
assert_eq [dict get [lindex $tasks 0] stem] \
    [spar::sweep_task_stem vic "State register"] "stem is the pool key"

# Every contact-driven transition ignores the campaign-task seam.
assert_eq [spar::transition_campaign_tasks T1 $cdata $camp $seg_paths] {} \
    "T1 has no campaign-level tasks"

# A probe stamped with an earlier round than the latest still dispatches,
# for a varied re-probe.
spar::update_source_field $sweep "Closed forum" probe \
    "login wall persists (round 1)"
set tasks [spar::transition_campaign_tasks T0 $cdata $camp $seg_paths]
assert_match [dict get [task_named $tasks "Closed forum"] reason] \
    "*predates round 2*re-probe*" \
    "a probe older than the latest round dispatches for a varied re-probe"

# A probe stamped with the latest round closes the source for this round.
spar::update_source_field $sweep "Closed forum" probe \
    "login wall confirmed (round 2)"
set tasks [spar::transition_campaign_tasks T0 $cdata $camp $seg_paths]
set names {}
foreach t $tasks { lappend names [dict get $t contact_name] }
assert_eq [lsort $names] {{State register} {Trade directory}} \
    "a probe stamped at the latest round is skipped"

# A source worked to exhaustion drops out of the next pass.
spar::update_source_status $sweep "State register" "exhausted — all 120 entries read"
set tasks [spar::transition_campaign_tasks T0 $cdata $camp $seg_paths]
assert_eq [llength $tasks] 1 "an exhausted source is no longer ready"
assert_eq [dict get [lindex $tasks 0] contact_name] "Trade directory" \
    "the remaining open source is the one left"

# A sweep file that does not parse blocks rather than disappears.
set bad_seg [write_seed_pair $root nsw]
set fd [open [spar::sweep_yaml_for_segment $bad_seg] w]
puts $fd "segment: nsw"
puts $fd "sources: \[oops"
close $fd
set fd [open $camp w]
puts $fd "campaign: test"
puts $fd {version: "2.0"}
puts $fd "primary_channel: email"
puts $fd "segments:"
puts $fd "  nsw:"
puts $fd "    plan: sweep it"
close $fd
set tasks [spar::transition_campaign_tasks T0 [spar::load_campaign $camp] $camp \
    [list [list nsw [file join $root segments nsw]]]]
assert_eq [llength $tasks] 1 "an unparseable sweep file yields one row"
assert_eq [dict get [lindex $tasks 0] task_state] blocked "and it is blocked"
assert_match [dict get [lindex $tasks 0] reason] "*does not parse*" \
    "with the parse failure as its reason"

# ── 7. Batch applier ───────────────────────────────────────────────────

section "7. apply_sweep_batch"

# write_return -- a worker deliverable: front-matter lines, then a body.
proc write_return {path fm_lines} {
    set fd [open $path w]
    puts $fd "---"
    foreach l $fm_lines { puts $fd $l }
    puts $fd "---"
    puts $fd ""
    puts $fd "Worked the register A-F; 120 entries listed."
    close $fd
    return $path
}

set batch_seg [write_seed_pair $root qld]
set batch_roster [spar::roster_path_for_segment $batch_seg]
set ret [file join $tmpdir return-1.md]

write_return $ret {
    "source_status: partial — 60 of 120 entries read"
    "reconciliation: |"
    "  120 listed; 60 read; 2 in scope; 2 rows returned."
    "rows_new:"
    "  - stem: jane-doe-acme"
    "    contact_name: Jane Doe"
    "    organisation: Acme Pty Ltd"
    "    role: General Manager"
    "    email: jane@acme.example"
    "    sweep_iteration: 1"
    "    discovered_via: State register entry 412"
    "    s_note: named as the responsible person"
    "    star_rating: 4"
    "  - stem: sam-lee-borden"
    "    contact_name: Sam Lee"
    "    organisation: Borden Ltd"
    "    sweep_iteration: 1"
    "    discovered_via: State register entry 480"
    "    star_rating: 2"
}
set issues [spar::apply_sweep_batch $ret $batch_roster qld]
assert_eq [llength $issues] 0 "clean batch returns no issues"
assert_eq [file exists $batch_roster] 1 "the first sweep creates the roster"
set rows [spar::load_roster $batch_roster]
assert_eq [llength $rows] 2 "both rows appended"
assert_eq [dict get [lindex $rows 0] contact_name] "Jane Doe" "first row landed"
assert_eq [dict get [lindex $rows 0] star_rating] 4 "star recorded"
set fd [open $batch_roster r]; gets $fd hdr; close $fd
assert_eq [split $hdr \t] [spar::roster_core_columns] \
    "created with the core column header"

# The stamp makes a replay inert, so a reconcile cannot double-append.
set issues [spar::apply_sweep_batch $ret $batch_roster qld]
assert_eq [llength $issues] 0 "replay returns no issues"
assert_eq [llength [spar::load_roster $batch_roster]] 2 "replay appends nothing"
set fd [open $ret r]; set rtext [read $fd]; close $fd
assert_match $rtext "*sweep_batch_applied:*" "stamp written into the front matter"

# A stem already on the roster is a re-find, not a find.
set ret2 [file join $tmpdir return-2.md]
write_return $ret2 {
    "source_status: exhausted — all 120 entries read"
    "reconciliation: 120 listed; 120 read; 1 row returned."
    "rows_new:"
    "  - stem: jane-doe-acme"
    "    contact_name: Jane Doe"
    "    organisation: Acme Pty Ltd"
}
set issues [spar::apply_sweep_batch $ret2 $batch_roster qld]
assert_eq [has_issue $issues duplicate_stem] 1 "a stem already on the roster is rejected"
assert_eq [llength [spar::load_roster $batch_roster]] 2 "and nothing is appended"

# Twice within one batch is the same defect.
set ret3 [file join $tmpdir return-3.md]
write_return $ret3 {
    "source_status: partial — halfway"
    "reconciliation: 2 rows returned."
    "rows_new:"
    "  - stem: kim-ng-orbit"
    "    contact_name: Kim Ng"
    "    organisation: Orbit"
    "  - stem: kim-ng-orbit"
    "    contact_name: Kim Ng"
    "    organisation: Orbit Pty Ltd"
}
set issues [spar::apply_sweep_batch $ret3 $batch_roster qld]
assert_eq [has_issue $issues duplicate_stem] 1 "a stem repeated inside the batch is rejected"
assert_eq [llength [spar::load_roster $batch_roster]] 2 "the whole batch is held back"

# A column this roster does not carry.
set ret4 [file join $tmpdir return-4.md]
write_return $ret4 {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: pat-ray-vale"
    "    contact_name: Pat Ray"
    "    organisation: Vale"
    "    lender_type: broker"
}
set issues [spar::apply_sweep_batch $ret4 $batch_roster qld]
assert_eq [has_issue $issues unknown_column] 1 "an undeclared column is rejected"

# ── 8. Row shape ───────────────────────────────────────────────────────

section "8. sweep-return row validation"

proc row_issues {fm_lines} {
    global tmpdir
    set p [file join $tmpdir return-shape.md]
    write_return $p $fm_lines
    return [spar::validate_sweep_return $p]
}

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: no-org-row"
    "    contact_name: \"\""
    "    organisation: \"\""
}]
assert_eq [has_issue $issues invalid_row] 1 "a row naming nobody is rejected"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: bare-date-row"
    "    contact_name: Dana Fox"
    "    organisation: Fox Ltd"
    "    date_excluded: 2026-08-06"
}]
assert_eq [has_issue $issues invalid_row] 0 \
    "a bare date_excluded passes; write_roster renders it ISO"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: quoted-date-row"
    "    contact_name: Dana Fox"
    "    organisation: Fox Ltd"
    "    date_excluded: \"2026-08-06\""
}]
assert_match [dict get [lindex [issues_with_code $issues invalid_row] 0] message] \
    "*was quoted*" "a quoted date_excluded is rejected"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: tabbed-row"
    "    contact_name: Dana Fox"
    "    organisation: \"Fox\tLtd\""
}]
assert_match [dict get [lindex [issues_with_code $issues invalid_row] 0] message] \
    "*holds a tab*" "a tab inside a value is caught"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: Bad Stem"
    "    contact_name: Dana Fox"
    "    organisation: Fox Ltd"
}]
assert_match [dict get [lindex [issues_with_code $issues invalid_row] 0] message] \
    "*slug-shaped*" "a stem that is not a slug is caught"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: over-starred"
    "    contact_name: Dana Fox"
    "    organisation: Fox Ltd"
    "    star_rating: 9"
}]
assert_match [dict get [lindex [issues_with_code $issues invalid_row] 0] message] \
    "*integer 0-5*" "a star outside 0-5 is caught"

set issues [row_issues {
    "source_status: harvested-ish"
    "reconciliation: 1 row returned."
}]
assert_eq [has_issue $issues invalid_source_status] 1 \
    "a status whose lead word is outside the vocabulary is caught"

set issues [row_issues {
    "reconciliation: 1 row returned."
}]
assert_eq [has_issue $issues missing_source_status] 1 "a missing status is caught"

set issues [row_issues {
    "source_status: exhausted"
    "rows_new: \[\]"
}]
assert_eq [has_issue $issues missing_reconciliation] 1 \
    "a batch that reconciles against nothing is caught"

set issues [row_issues {
    "source_status: exhausted — all read"
    "reconciliation: 0 rows returned."
    "rows_new: \[\]"
}]
assert_eq [llength $issues] 0 "a source that yielded nothing still validates"

# ── 9. SweepHarness ────────────────────────────────────────────────────
#
# The claude call is the one part not exercised here: the harness's own
# work is what happens either side of it, and each of those methods runs
# standalone against a deliverable already on disk.

section "9. SweepHarness applies, records and stamps"

set h_seg [write_seed_pair $root tas]
set h_sweep [spar::sweep_yaml_for_segment $h_seg]
set h_roster [spar::roster_path_for_segment $h_seg]
set h_prompt [file join $tmpdir prompts sweep-tas-state-register]
file mkdir $h_prompt
set h_logs [file join $tmpdir logs-tas]
file mkdir $h_logs
set h_out [file join $h_logs "sweep-tas-state-register-return.md"]

set fd [open [file join $h_prompt meta.env] w]
puts $fd "STEM=\"sweep-tas-state-register\""
puts $fd "OUTFILE=\"$h_out\""
puts $fd "ROSTER_PATH=\"$h_roster\""
puts $fd "SWEEP_PATH=\"$h_sweep\""
puts $fd "SEGMENT_DIR=\"$h_seg\""
puts $fd "SEGMENT_KEY=\"tas\""
puts $fd "SOURCE_NAME=\"State register\""
puts $fd "SWEEP_ROUND=\"1\""
puts $fd "MODEL=\"opus\""
close $fd

write_return $h_out {
    "source_status: partial — 60 of 120 entries read, A-F"
    "reconciliation: |"
    "  120 listed; 60 read; 1 in scope; 1 row returned."
    "sweep_feedback:"
    "  - kind: new-source"
    "    note: the register links a state association directory"
    "rows_new:"
    "  - stem: rae-quinn-tasco"
    "    contact_name: Rae Quinn"
    "    organisation: Tasco"
    "    sweep_iteration: 1"
    "    discovered_via: State register entry 12"
    "    star_rating: 3"
}

set harness [spar::SweepHarness new $h_prompt $h_logs]
$harness load_my_meta
assert_eq [$harness declared_status] "partial — 60 of 120 entries read, A-F" \
    "the declared status is read back off the deliverable"

set errs [$harness validate_sweep_errors 1]
set hard {}
foreach e $errs { if {[dict get $e severity] eq "error"} { lappend hard $e } }
assert_eq [llength $hard] 0 "the batch applies with no hard errors"
assert_eq [llength [spar::load_roster $h_roster]] 1 "the row reached the roster"
assert_eq [$harness coverage] "1/120" \
    "coverage is the live roster count over the denominator"

spar::update_source_status $h_sweep "State register" [$harness declared_status]
$harness record_round
$harness destroy

set data [spar::read_sweep_yaml $h_sweep]
set st ""
foreach s [dict get $data sources] {
    if {[dict get $s name] eq "State register"} { set st [dict get $s status] }
}
assert_eq $st "partial — 60 of 120 entries read, A-F" "the source status is updated"
assert_eq [llength [dict get $data rounds]] 1 "the round is recorded"
set r [lindex [dict get $data rounds] 0]
assert_eq [dict get $r n] 1 "round 1"
assert_eq [dict get $r yield] 1 "yield is the rows applied"
assert_eq [dict get $r coverage_after] "1/120" "coverage recorded"
assert_match [dict get $r reconciliation] "State register:*120 listed*" \
    "the worker's reconciliation is attributed to its source"
assert_match [dict get $r surprises] "*new-source*association directory*" \
    "sweep_feedback becomes the round's surprises"

# An escape the worker declares reaches the sweep file's standing list;
# one with no verdict is dropped, since the verdict is what the list is for.
set esc_issues [spar::validate_sweep_return $h_out]
assert_eq [llength $esc_issues] 0 "the deliverable validates clean"
assert_eq [spar::append_sweep_escapes $h_sweep [list \
    [dict create member "Vale Holdings" verdict missing-keyword \
        note "trades as a co-op"] \
    [dict create member "No Verdict Ltd" note "just a note"]]] 1 \
    "one escape of two recorded; the verdictless one dropped"
set data [spar::read_sweep_yaml $h_sweep]
assert_eq [llength [dict get $data escapes]] 1 "escapes: \[\] became one entry"
assert_eq [dict get [lindex [dict get $data escapes] 0] verdict] missing-keyword \
    "the verdict survives the round trip"
assert_eq [spar::append_sweep_escapes $h_sweep [list \
    [dict create member "Vale Holdings" verdict missing-keyword]]] 0 \
    "a member already listed is not doubled"

set issues [row_issues {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "escapes:"
    "  - member: Vale Holdings"
    "    verdict: forgot-to-look"
}]
assert_eq [has_issue $issues invalid_escape] 1 \
    "an escape verdict outside the vocabulary warns"
assert_eq [dict get [lindex [issues_with_code $issues invalid_escape] 0] severity] \
    warning "and it warns rather than bouncing the batch"

# A second run of the same deliverable (a replay, or a fix-loop retry
# after the batch already landed) applies nothing further.
set harness2 [spar::SweepHarness new $h_prompt $h_logs]
$harness2 load_my_meta
set errs [$harness2 validate_sweep_errors 2]
assert_eq [llength $errs] 0 "a stamped deliverable re-validates clean"
assert_eq [llength [spar::load_roster $h_roster]] 1 "and appends nothing"
$harness2 destroy

finish_tests

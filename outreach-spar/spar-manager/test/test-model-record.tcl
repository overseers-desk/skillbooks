#!/usr/bin/env tclsh9.0
# test-model-record.tcl — the harness records which model wrote a
# deliverable (#154): authored_model in a profile's front matter,
# authored_model and challenger_model at an approach's root, each the full
# id from the init event of the session's stream-json transcript.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::harness

set tmpdir [exec mktemp -d /tmp/spar-test-model-record.XXXXXX]
lappend ::cleanup_dirs $tmpdir
set logs [file join $tmpdir logs]
file mkdir $logs

# A transcript as claude -p --output-format stream-json writes it: the
# init event first, then events that are not init.
proc write_transcript {path model} {
    set fd [open $path w]
    puts $fd "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"s1\",\"model\":\"$model\",\"tools\":\[\]}"
    puts $fd {{"type":"assistant","message":{"content":[{"type":"text","text":"the init step is done"}]}}}
    puts $fd {{"type":"result","subtype":"success","total_cost_usd":0.1,"session_id":"s1"}}
    close $fd
}

# ════════════════════════════════════════════════════════════════════════
section "1. session_model reads the init event"
# ════════════════════════════════════════════════════════════════════════

set tr [file join $tmpdir t.log.json]
write_transcript $tr claude-opus-4-8
assert_eq [spar::session_model $tr] claude-opus-4-8 "the init event's model is returned"
assert_eq [spar::session_model [file join $tmpdir absent.json]] "" \
    "an absent transcript yields no model"
set fd [open $tr w]
puts $fd {{"type":"result","subtype":"success","session_id":"s1"}}
close $fd
assert_eq [spar::session_model $tr] "" "a transcript with no init event yields no model"

# ════════════════════════════════════════════════════════════════════════
section "2. ProfileHarness stamps authored_model"
# ════════════════════════════════════════════════════════════════════════

set seg_dir [file join $tmpdir segments seg]
file mkdir $seg_dir
set stem jane-doe-acme
set profile [spar::profile_path_for_stem $seg_dir $stem]
set pdir [file join $tmpdir prompts $stem]
file mkdir $pdir
set fd [open [file join $pdir meta.env] w]
puts $fd "STEM=\"$stem\""
puts $fd "OUTFILE=\"$profile\""
puts $fd "ROSTER_PATH=\"[spar::roster_path_for_segment $seg_dir]\""
close $fd
set fd [open $profile w]
puts $fd "---"
puts $fd "profile_date: 2026-09-15"
puts $fd "star_rating: 4"
puts $fd "yield: 3"
puts $fd "dependent_data:"
puts $fd "  contact_name: Jane Doe"
puts $fd "authored_model: copied-from-a-sibling"
puts $fd "---"
puts $fd ""
puts $fd "# Profile: Jane Doe"
close $fd

set ph [spar::ProfileHarness new $pdir $logs]
$ph load_my_meta
write_transcript "[$ph log_prefix]-profile.log.json" claude-sonnet-4-6
$ph stamp_authored_model
$ph destroy
set fm [spar::read_profile_front_matter $profile]
assert_eq [dict getdef $fm authored_model ""] claude-sonnet-4-6 \
    "the profile carries the profile call's model, replacing the worker's line"
set fd [open $profile r]; set ptext [read $fd]; close $fd
assert_eq [llength [regexp -all -inline -line {^authored_model:} $ptext]] 1 \
    "one authored_model line"
set codes [lmap i [spar::validate_profile $profile {} "Jane Doe"] {dict get $i code}]
assert_eq [lsearch -glob $codes unknown_key*] -1 "authored_model is in the profile vocabulary"

# ════════════════════════════════════════════════════════════════════════
section "3. ApproachHarness stamps authored_model and challenger_model"
# ════════════════════════════════════════════════════════════════════════

set approach [file join $tmpdir $stem.yaml]
set fd [open $approach w]
puts $fd "decisions:"
puts $fd "  channel: email"
puts $fd "rounds:"
puts $fd "- type: final"
puts $fd "  number: 1"
puts $fd "  messages:"
puts $fd "  - channel: email"
puts $fd "    to: jane@acme-venues.au"
puts $fd "    subject: Hello"
puts $fd "    body: Hello there"
puts $fd "    actioned_date: null"
puts $fd "    replied_date: null"
close $fd
set apdir [file join $tmpdir prompts approach-$stem]
file mkdir $apdir
set fd [open [file join $apdir meta.env] w]
puts $fd "MAX_PASSES=1"
puts $fd "OUTFILE=\"$approach\""
puts $fd "CONTACT_SUMMARY=\"Jane Doe | Acme\""
puts $fd "SEGMENT_DIR=\"$seg_dir\""
close $fd
set ah [spar::ApproachHarness new $apdir $logs]
$ah load_my_meta
write_transcript "[$ah log_prefix]-author-draft.log.json" claude-opus-4-8
write_transcript "[$ah log_prefix]-challenger-pass1.log.json" claude-sonnet-4-6
$ah stamp_models
$ah destroy
set adata [spar::read_approach_yaml $approach]
assert_eq [dict getdef $adata authored_model ""] claude-opus-4-8 "the author's model is recorded"
assert_eq [dict getdef $adata challenger_model ""] claude-sonnet-4-6 "the challenger's model is recorded"
set codes [lmap i [spar::validate_approach $approach "jane@acme-venues.au" "Jane Doe"] {dict get $i code}]
assert_eq [lsearch -glob $codes unknown_key*] -1 "both keys are in the approach vocabulary"

finish_tests

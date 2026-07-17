#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 9. detect_duplicates
# ════════════════════════════════════════════════════════════════════════
section "9. detect_duplicates"

# 9a. duplicate_email: same email in two contacts from different segments → flagged
set seg1 [make_temp_segment]
set seg2 [make_temp_segment]

write_roster_tsv $seg1 $::std_headers [list \
    [make_base_row {contact_name "Alice One" email "shared@acme-venues.au" stem ""}] \
]
write_roster_tsv $seg2 $::std_headers [list \
    [make_base_row {contact_name "Alice Two" email "shared@acme-venues.au" stem ""}] \
]

set c1 [$State refine_segment [$State classify_segment $seg1]]
set c2 [$State refine_segment [$State classify_segment $seg2]]
set all_contacts [concat $c1 $c2]
set dups [spar::detect_duplicates $all_contacts]
assert_eq [expr {[llength [dict get $dups duplicate_email]] > 0}] 1 \
    "duplicate_email: same email in different segments → flagged"

# 9b. duplicate_email: same email in two contacts from the SAME segment → not flagged
set seg3 [make_temp_segment]
write_roster_tsv $seg3 $::std_headers [list \
    [make_base_row {contact_name "Bob One" email "bob@acme-venues.au" stem ""}] \
    [make_base_row {contact_name "Bob Two" email "bob@acme-venues.au" stem ""}] \
]
set c3 [$State refine_segment [$State classify_segment $seg3]]
set dups3 [spar::detect_duplicates $c3]
assert_eq [llength [dict get $dups3 duplicate_email]] 0 \
    "duplicate_email: same email within one segment → not flagged"

# 9c. duplicate_email: one contact per email → not flagged
set seg4 [make_temp_segment]
set seg5 [make_temp_segment]
write_roster_tsv $seg4 $::std_headers [list \
    [make_base_row {contact_name "Carol" email "carol@acme-venues.au" stem ""}] \
]
write_roster_tsv $seg5 $::std_headers [list \
    [make_base_row {contact_name "Diana" email "diana@acme-venues.au" stem ""}] \
]
set c4 [$State refine_segment [$State classify_segment $seg4]]
set c5 [$State refine_segment [$State classify_segment $seg5]]
set dups45 [spar::detect_duplicates [concat $c4 $c5]]
assert_eq [llength [dict get $dups45 duplicate_email]] 0 \
    "duplicate_email: unique emails → not flagged"

# 9d. duplicate_name: same normalised name across two different segments → flagged
set seg6 [make_temp_segment]
set seg7 [make_temp_segment]
write_roster_tsv $seg6 $::std_headers [list \
    [make_base_row {contact_name "John Smith" email "john1@acme-venues.au" stem ""}] \
]
write_roster_tsv $seg7 $::std_headers [list \
    [make_base_row {contact_name "John Smith" email "john2@acme-venues.au" stem ""}] \
]
set c6 [$State refine_segment [$State classify_segment $seg6]]
set c7 [$State refine_segment [$State classify_segment $seg7]]
set dups67 [spar::detect_duplicates [concat $c6 $c7]]
assert_eq [expr {[llength [dict get $dups67 duplicate_name]] > 0}] 1 \
    "duplicate_name: same name in different segments → flagged"

# 9e. duplicate_name: same name within one segment → not flagged
set seg8 [make_temp_segment]
write_roster_tsv $seg8 $::std_headers [list \
    [make_base_row {contact_name "Jane Doe" email "jane1@acme-venues.au" stem ""}] \
    [make_base_row {contact_name "Jane Doe" email "jane2@acme-venues.au" stem ""}] \
]
set c8 [$State refine_segment [$State classify_segment $seg8]]
set dups8 [spar::detect_duplicates $c8]
assert_eq [llength [dict get $dups8 duplicate_name]] 0 \
    "duplicate_name: same name within one segment → not flagged"

# 9f. duplicate_to: same To: address in final-round messages of two approach files → flagged
set seg9 [make_temp_segment]
set seg10 [make_temp_segment]

write_profile $seg9 "dup-to-a"
write_approach_yaml $seg9 "dup-to-a" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: recipient@acme-venues.au
    subject: Hello A
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg9 $::std_headers [list \
    [make_base_row {contact_name "To Dup A" email "a@acme-venues.au" stem "dup-to-a"}] \
]

write_profile $seg10 "dup-to-b"
write_approach_yaml $seg10 "dup-to-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: recipient@acme-venues.au
    subject: Hello B
    body: Body B
    actioned_date: 2026-04-02
    replied_date: null
}
write_roster_tsv $seg10 $::std_headers [list \
    [make_base_row {contact_name "To Dup B" email "b@acme-venues.au" stem "dup-to-b"}] \
]

set c9 [$State refine_segment [$State classify_segment $seg9]]
set c10 [$State refine_segment [$State classify_segment $seg10]]
set dups910 [spar::detect_duplicates [concat $c9 $c10]]
assert_eq [expr {[llength [dict get $dups910 duplicate_to]] > 0}] 1 \
    "duplicate_to: same To: address in two approach files → flagged"

# 9g. duplicate_to: unique To: addresses → not flagged
set seg11 [make_temp_segment]
set seg12 [make_temp_segment]

write_profile $seg11 "uniq-to-a"
write_approach_yaml $seg11 "uniq-to-a" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: unique-a@acme-venues.au
    subject: Hello A
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg11 $::std_headers [list \
    [make_base_row {contact_name "Uniq A" email "a@acme-venues.au" stem "uniq-to-a"}] \
]

write_profile $seg12 "uniq-to-b"
write_approach_yaml $seg12 "uniq-to-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: unique-b@acme-venues.au
    subject: Hello B
    body: Body B
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg12 $::std_headers [list \
    [make_base_row {contact_name "Uniq B" email "b@acme-venues.au" stem "uniq-to-b"}] \
]

set c11 [$State refine_segment [$State classify_segment $seg11]]
set c12 [$State refine_segment [$State classify_segment $seg12]]
set dups1112 [spar::detect_duplicates [concat $c11 $c12]]
assert_eq [llength [dict get $dups1112 duplicate_to]] 0 \
    "duplicate_to: unique addresses → not flagged"

# 9h. identical_subject: same subject in two unsent approach files → flagged
set seg13 [make_temp_segment]
set seg14 [make_temp_segment]

write_profile $seg13 "subj-dup-a"
write_approach_yaml $seg13 "subj-dup-a" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: x@acme-venues.au
    subject: Shared Subject Line
    body: Body A
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg13 $::std_headers [list \
    [make_base_row {contact_name "Subj A" email "sa@acme-venues.au" stem "subj-dup-a"}] \
]

write_profile $seg14 "subj-dup-b"
write_approach_yaml $seg14 "subj-dup-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: y@acme-venues.au
    subject: Shared Subject Line
    body: Body B
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg14 $::std_headers [list \
    [make_base_row {contact_name "Subj B" email "sb@acme-venues.au" stem "subj-dup-b"}] \
]

set c13 [$State refine_segment [$State classify_segment $seg13]]
set c14 [$State refine_segment [$State classify_segment $seg14]]
set dups1314 [spar::detect_duplicates [concat $c13 $c14]]
assert_eq [expr {[llength [dict get $dups1314 identical_subject]] > 0}] 1 \
    "identical_subject: same subject in two unsent approaches → flagged"

# 9i. identical_subject: sent messages with same subject → not flagged (unsent_subjects only collects unsent)
set seg15 [make_temp_segment]
set seg16 [make_temp_segment]

write_profile $seg15 "subj-sent-a"
write_approach_yaml $seg15 "subj-sent-a" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: x@acme-venues.au
    subject: Already Sent Subject
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg15 $::std_headers [list \
    [make_base_row {contact_name "Sent Subj A" email "ssa@acme-venues.au" stem "subj-sent-a"}] \
]

write_profile $seg16 "subj-sent-b"
write_approach_yaml $seg16 "subj-sent-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: y@acme-venues.au
    subject: Already Sent Subject
    body: Body B
    actioned_date: 2026-04-02
    replied_date: null
}
write_roster_tsv $seg16 $::std_headers [list \
    [make_base_row {contact_name "Sent Subj B" email "ssb@acme-venues.au" stem "subj-sent-b"}] \
]

set c15 [$State refine_segment [$State classify_segment $seg15]]
set c16 [$State refine_segment [$State classify_segment $seg16]]
set dups1516 [spar::detect_duplicates [concat $c15 $c16]]
assert_eq [llength [dict get $dups1516 identical_subject]] 0 \
    "identical_subject: sent messages with same subject → not flagged"

# 9j. EXCLUDED contact does not contribute to duplicate_name
set seg_inv1 [make_temp_segment]
set seg_inv2 [make_temp_segment]
write_roster_tsv $seg_inv1 $::std_headers [list \
    [make_base_row {contact_name "Ghost Person" email "ghost1@acme-venues.au" \
        stem "" date_excluded "2026-04-01"}] \
]
write_roster_tsv $seg_inv2 $::std_headers [list \
    [make_base_row {contact_name "Ghost Person" email "ghost2@acme-venues.au" stem ""}] \
]
set cinv1 [$State refine_segment [$State classify_segment $seg_inv1]]
set cinv2 [$State refine_segment [$State classify_segment $seg_inv2]]
set dups_inv [spar::detect_duplicates [concat $cinv1 $cinv2]]
assert_eq [llength [dict get $dups_inv duplicate_name]] 0 \
    "duplicate_name: EXCLUDED contact does not contribute → not flagged"

# 9k. EXCLUDED contact does not contribute to duplicate_email
set seg_inv3 [make_temp_segment]
set seg_inv4 [make_temp_segment]
write_roster_tsv $seg_inv3 $::std_headers [list \
    [make_base_row {contact_name "Invalid One" email "shared-inv@acme-venues.au" \
        stem "" date_excluded "2026-04-02"}] \
]
write_roster_tsv $seg_inv4 $::std_headers [list \
    [make_base_row {contact_name "Active Two" email "shared-inv@acme-venues.au" stem ""}] \
]
set cinv3 [$State refine_segment [$State classify_segment $seg_inv3]]
set cinv4 [$State refine_segment [$State classify_segment $seg_inv4]]
set dups_inv2 [spar::detect_duplicates [concat $cinv3 $cinv4]]
assert_eq [llength [dict get $dups_inv2 duplicate_email]] 0 \
    "duplicate_email: EXCLUDED contact does not contribute → not flagged"

# 9l. EXCLUDED contact's approach file does not contribute to duplicate_to
set seg_inv5 [make_temp_segment]
set seg_inv6 [make_temp_segment]
write_profile $seg_inv5 "inv-approach-a"
write_approach_yaml $seg_inv5 "inv-approach-a" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: collide@acme-venues.au
    subject: Invalid Contact Approach
    body: Body A
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_inv5 $::std_headers [list \
    [make_base_row {contact_name "Was Invalid" email "wasinv@acme-venues.au" \
        stem "inv-approach-a" date_excluded "2026-04-03"}] \
]
write_profile $seg_inv6 "active-approach-b"
write_approach_yaml $seg_inv6 "active-approach-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: collide@acme-venues.au
    subject: Active Contact Approach
    body: Body B
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_inv6 $::std_headers [list \
    [make_base_row {contact_name "Still Active" email "active@acme-venues.au" \
        stem "active-approach-b"}] \
]
set cinv5 [$State refine_segment [$State classify_segment $seg_inv5]]
set cinv6 [$State refine_segment [$State classify_segment $seg_inv6]]
set dups_inv3 [spar::detect_duplicates [concat $cinv5 $cinv6]]
assert_eq [llength [dict get $dups_inv3 duplicate_to]] 0 \
    "duplicate_to: EXCLUDED contact's approach file does not contribute → not flagged"

# ════════════════════════════════════════════════════════════════════════
# 17. normalise_name
# ════════════════════════════════════════════════════════════════════════
section "17. normalise_name"

assert_eq [spar::normalise_name "John Smith"] "john smith" \
    "normalise: John Smith → john smith"
assert_eq [spar::normalise_name "JOHN SMITH"] "john smith" \
    "normalise: JOHN SMITH → john smith"
assert_eq [spar::normalise_name "John (Johnny) Smith"] "john smith" \
    "normalise: parenthetical stripped"
assert_eq [spar::normalise_name "Smith/Jones"] "smith jones" \
    "normalise: slash → space"
assert_eq [spar::normalise_name "Smith & Jones"] "smith jones" \
    "normalise: ampersand → space"
assert_eq [spar::normalise_name "  John   Smith  "] "john smith" \
    "normalise: whitespace collapsed and trimmed"

# ════════════════════════════════════════════════════════════════════════
# 18. parse_star
# ════════════════════════════════════════════════════════════════════════
section "18. parse_star"

assert_eq [spar::parse_star "5"] 5 "parse_star: 5 → 5"
assert_eq [spar::parse_star "3"] 3 "parse_star: 3 → 3"
assert_eq [spar::parse_star ""] 0 "parse_star: empty → 0"
assert_eq [spar::parse_star "abc"] 0 "parse_star: abc → 0"
assert_eq [spar::parse_star "3+"] 3 "parse_star: 3+ → 3"
assert_eq [spar::parse_star "0"] 0 "parse_star: 0 → 0"

# ════════════════════════════════════════════════════════════════════════
# 19. roster_counts
# ════════════════════════════════════════════════════════════════════════
section "19. roster_counts"

# 19a. Basic roster_counts with mixed contacts
set seg [make_temp_segment]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {stem "alice" star_rating "5" email "a@test.com" linkedin_url "" facebook_url "" phone ""}] \
    [make_base_row {stem "bob" star_rating "3" email "" linkedin_url "https://li.com/bob" facebook_url "" phone ""}] \
    [make_base_row {stem "carol" star_rating "2" email "c@test.com" linkedin_url "" facebook_url "" phone ""}] \
    [make_base_row {stem "dave" star_rating "4" email "" linkedin_url "" facebook_url "" phone "0400000000"}] \
    [make_base_row {stem "eve" star_rating "3" email "" linkedin_url "" facebook_url "https://fb.com/eve" phone ""}] \
]
set rc [spar::roster_counts $seg]
assert_eq [dict get $rc valid] 5 "roster_counts: 5 valid contacts"
assert_eq [dict get $rc star3] 4 "roster_counts: 4 contacts with star >= 3"
assert_eq [dict get $rc has_email] 1 "roster_counts: 1 star3+ with email"
assert_eq [dict get $rc has_linkedin] 1 "roster_counts: 1 star3+ with linkedin"
assert_eq [dict get $rc has_facebook] 1 "roster_counts: 1 star3+ with facebook"
assert_eq [dict get $rc has_phone_only] 1 "roster_counts: 1 star3+ phone only"

# 19b. roster_counts with invalid contact excluded
set seg [make_temp_segment]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {stem "alice" star_rating "5" email "a@test.com"}] \
    [make_base_row {stem "bob" star_rating "3" date_excluded "2026-01-01"}] \
]
set rc [spar::roster_counts $seg]
assert_eq [dict get $rc valid] 1 "roster_counts: invalid contact excluded"
assert_eq [dict get $rc star3] 1 "roster_counts: only valid star3 counted"

# 19c. roster_counts with empty roster
set seg [make_temp_segment]
write_roster_tsv $seg $::std_headers {}
set rc [spar::roster_counts $seg]
assert_eq [dict get $rc valid] 0 "roster_counts: empty roster → 0 valid"
assert_eq [dict get $rc star3] 0 "roster_counts: empty roster → 0 star3"

# ════════════════════════════════════════════════════════════════════════
# 27. spar::read_segment_yaml
# ════════════════════════════════════════════════════════════════════════
section "27. spar::read_segment_yaml"

# Missing file → empty string
set sy_missing [spar::read_segment_yaml /tmp/spar-segyaml-no-such-file-[pid]]
assert_eq $sy_missing "" "read_segment_yaml: missing file → empty string"

# Well-formed segment.yaml with scalars, multi-line block, and a list of dicts
set sy_path [file join /tmp "spar-segyaml-[pid]-[clock microseconds].yaml"]
set fd [open $sy_path w]
puts $fd "title: Test segment"
puts $fd "priority: Tier 1"
puts $fd "objective: |"
puts $fd "  Multi-line objective."
puts $fd "  Second line."
puts $fd "rating_rubric: |"
puts $fd "  Brief prose rubric."
puts $fd "usps:"
puts $fd "  - id: U1"
puts $fd "    type: emotional"
puts $fd "    framing: Why this matters."
puts $fd "  - id: U2"
puts $fd "    type: functional"
puts $fd "    framing: Functional value."
close $fd

set sy_data [spar::read_segment_yaml $sy_path]
assert_match $sy_data "*title*" "read_segment_yaml: parses non-empty dict"
assert_eq [dict get $sy_data title]    "Test segment" "read_segment_yaml: scalar field"
assert_eq [dict get $sy_data priority] "Tier 1"       "read_segment_yaml: scalar field"
assert_match [dict get $sy_data objective] \
    "*Multi-line objective.*Second line.*" \
    "read_segment_yaml: multi-line block scalar"
assert_eq [llength [dict get $sy_data usps]] 2 \
    "read_segment_yaml: list of dicts has two entries"
set sy_first_usp [lindex [dict get $sy_data usps] 0]
assert_eq [dict get $sy_first_usp id]   "U1"        "read_segment_yaml: list-of-dicts entry id"
assert_eq [dict get $sy_first_usp type] "emotional" "read_segment_yaml: list-of-dicts entry type"

file delete $sy_path

# Malformed YAML — must not throw. read_segment_yaml wraps the parse in
# catch and returns "" on failure; getting past the assignment without a
# Tcl error is itself the assertion.
set sy_bad [file join /tmp "spar-segyaml-bad-[pid]-[clock microseconds].yaml"]
set fd [open $sy_bad w]
puts $fd "key: value"
puts $fd "  bogus_indent_under_scalar"
puts $fd "another:: weird"
close $fd
set sy_bad_threw [catch {spar::read_segment_yaml $sy_bad} sy_bad_data]
assert_eq $sy_bad_threw 0 "read_segment_yaml: malformed input does not throw"
file delete $sy_bad


# ── campaign_segment_names: map vs legacy-list detection ──

# Legacy list form (bare names) → returned unchanged.
assert_eq [spar::campaign_segment_names [dict create segments {wedding-planner tour-operator}]] \
    {wedding-planner tour-operator} "campaign_segment_names: legacy list form"
assert_eq [spar::campaign_segment_names [dict create segments {only-one}]] \
    {only-one} "campaign_segment_names: single-name list"

# Map form (name -> plan block) → returns the keys, order preserved.
set seg_map [dict create \
    wedding-planner [dict create objective "win weddings"] \
    tour-operator   [dict create objective "win tours" first_ask "hello"]]
assert_eq [spar::campaign_segment_names [dict create segments $seg_map]] \
    {wedding-planner tour-operator} "campaign_segment_names: map form returns keys"

# Map with a sparse (empty) plan block → still detected as map.
set seg_map_sparse [dict create seg-a [dict create objective "x"] seg-b ""]
assert_eq [spar::campaign_segment_names [dict create segments $seg_map_sparse]] \
    {seg-a seg-b} "campaign_segment_names: sparse map block detected as map"

# Single-segment dot map (segments: {.: {...}}).
assert_eq [spar::campaign_segment_names \
        [dict create segments [dict create . [dict create objective "x"]]]] \
    {.} "campaign_segment_names: single dot-segment map"

# Absent segments → empty.
assert_eq [spar::campaign_segment_names [dict create campaign "x"]] {} \
    "campaign_segment_names: absent segments → empty"

# ════════════════════════════════════════════════════════════════════════
# get_max_passes — profile-derived A-phase pass budget (#144)
# ════════════════════════════════════════════════════════════════════════
section "get_max_passes"

# yield ≥ 6 licenses 3 passes. Regression guard for #144: get_max_passes runs
# in the ::spar namespace, where a relative `info procs` guard silently missed
# the front-matter reader and the proc fell through to 1 for every profile.
set seg_mp [make_temp_segment]
write_profile $seg_mp mp-high -yield 10
assert_eq [spar::get_max_passes [file join $seg_mp profiles mp-high.md]] 3 \
    "get_max_passes: yield 10 → 3 passes"

write_profile $seg_mp mp-six -yield 6
assert_eq [spar::get_max_passes [file join $seg_mp profiles mp-six.md]] 3 \
    "get_max_passes: yield 6 (boundary) → 3 passes"

# yield < 6 stays at a single pass.
write_profile $seg_mp mp-low -yield 5
assert_eq [spar::get_max_passes [file join $seg_mp profiles mp-low.md]] 1 \
    "get_max_passes: yield 5 → 1 pass"

# Missing profile → 1 pass.
assert_eq [spar::get_max_passes [file join $seg_mp profiles nope.md]] 1 \
    "get_max_passes: missing profile → 1 pass"


# ────────────────────────────────────────────────────────────────────────
section "render_rollcall (run-end per-contact summary, #148)"

# _parse_fail_reason splits the dispatcher's flat reason into {rc cause}.
assert_eq [spar::_parse_fail_reason "harness exited rc=2 | FAIL (T2: stalled): bob"] \
    {2 {FAIL (T2: stalled): bob}} \
    "_parse_fail_reason: extracts rc and the cause after ' | '"
assert_eq [spar::_parse_fail_reason "ses_send: connection refused"] \
    {{} {ses_send: connection refused}} \
    "_parse_fail_reason: no rc/separator → empty rc, whole string as cause"

# render_rollcall names every non-DONE contact with phase, exit class, cause.
set rc_recs [list \
    [dict create slug alice-acme tid T2 outcome failed \
        reason "harness exited rc=1 | FAIL (no draft markers): alice-acme"] \
    [dict create slug carol-inc tid T1 outcome cancelled reason cancelled]]
set rc_out [spar::render_rollcall $rc_recs]
assert_match $rc_out "*alice-acme*"  "render_rollcall: lists the failed slug"
assert_match $rc_out "*\[T2\]*"      "render_rollcall: shows the phase TID"
assert_match $rc_out "*rc=1*"        "render_rollcall: shows the exit class"
assert_match $rc_out "*no draft markers*" "render_rollcall: shows the cause"
assert_match $rc_out "*carol-inc*cancelled*" "render_rollcall: lists cancelled rows too"

# An empty roll-call renders nothing (caller prints no extra block).
assert_eq [spar::render_rollcall {}] "" "render_rollcall: empty list → blank"

section "yaml_parse — tcllib yaml hang guard"

# A document whose last line is an empty-valued key with no trailing newline
# loops forever in tcllib yaml 0.4.2; yaml_parse supplies the newline so the
# parse returns instead of hanging, with the same result as the newline form.
assert_eq [spar::yaml_parse "a: 1\nkey:"] [spar::yaml_parse "a: 1\nkey:\n"] \
    "yaml_parse: trailing bare key without newline parses, matches newline form"
assert_eq [spar::yaml_parse "a: 1\nkey:"] {a 1 key {}} \
    "yaml_parse: the guarded parse yields the expected dict"
assert_eq [spar::yaml_parse "x: 1\ny: 2\n"] {x 1 y 2} \
    "yaml_parse: an already-terminated document is unchanged"


finish_tests

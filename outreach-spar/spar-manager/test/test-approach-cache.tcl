#!/usr/bin/env tclsh9.0
# Phase D — cache contract tests for spar::State approach_summary.
#
# These tests lock down the per-instance approach-projection cache:
# hit, miss, hash-driven invalidation, mtime-driven invalidation,
# explicit forget_approach, bypass-site freshness, and cross-render
# persistence. They use the ::spar::parse_count instrumentation
# (incremented inside spar::read_approach_yaml) as the ground-truth
# signal that a parse did or did not happen.
#
# Reused fixture builders from test/test-helpers.tcl: make_temp_segment,
# write_profile, write_approach_yaml, write_roster_tsv.

package require yaml
package require sha256
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

# Approach YAML helper — line 1 is `profile_hash: sha256:<hex>` matching
# the profile bytes, so classify_contact returns APPROACHED (not
# APPROACH_STALE). subject is parameterised so test 4 can rewrite the
# body while keeping the line-1 hash identical.
proc cache_approach_yaml {profile_path {subject "Test subject"}} {
    set hex [string tolower [::sha2::sha256 -hex -file $profile_path]]
    return "profile_hash: sha256:$hex
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: $subject
    body: Hello there
    actioned_date: null
    replied_date: null
"
}

# Approach YAML with an explicit, deliberately-wrong line-1 hash, used
# by test 3 to drive hash-mismatch invalidation while leaving the rest
# of the file untouched.
proc cache_approach_yaml_with_hash {hex {subject "Test subject"}} {
    return "profile_hash: sha256:$hex
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: $subject
    body: Hello there
    actioned_date: null
    replied_date: null
"
}

# ════════════════════════════════════════════════════════════════════════
# 1. Cache hit — second call on same path does not re-parse.
# ════════════════════════════════════════════════════════════════════════
section "1. Cache hit (no re-parse on second call)"

set seg [make_temp_segment]
set pp [write_profile $seg "hit-one"]
write_approach_yaml $seg "hit-one" [cache_approach_yaml $pp]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Hit One" stem "hit-one"}] \
]

set State [spar::State new]
set contacts [$State classify_segment $seg]
set contact [lindex $contacts 0]
assert_eq [dict get $contact state] "APPROACHED" "1: contact classifies APPROACHED"

set ::spar::parse_count 0
set first [$State approach_summary $contact]
set after_first $::spar::parse_count
set second [$State approach_summary $contact]
set after_second $::spar::parse_count

assert_eq $after_first 1 "1: first call parses once"
assert_eq $after_second $after_first "1: second call does not re-parse"
assert_eq $second $first "1: second call returns same dict as first"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 2. Cache miss across distinct paths — each path parses once.
# ════════════════════════════════════════════════════════════════════════
section "2. Cache miss across distinct paths"

set seg [make_temp_segment]
set pp1 [write_profile $seg "miss-a"]
set pp2 [write_profile $seg "miss-b"]
write_approach_yaml $seg "miss-a" [cache_approach_yaml $pp1]
write_approach_yaml $seg "miss-b" [cache_approach_yaml $pp2]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Miss A" stem "miss-a"}] \
    [make_base_row {contact_name "Miss B" stem "miss-b"}] \
]

set State [spar::State new]
set contacts [$State classify_segment $seg]
set ca [lindex $contacts 0]
set cb [lindex $contacts 1]
assert_eq [dict get $ca state] "APPROACHED" "2: contact A is APPROACHED"
assert_eq [dict get $cb state] "APPROACHED" "2: contact B is APPROACHED"

set ::spar::parse_count 0
$State approach_summary $ca
$State approach_summary $cb
assert_eq $::spar::parse_count 2 "2: two distinct paths → two parses"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 3. Hash-driven invalidation — line-1 profile_hash change forces re-parse.
# ════════════════════════════════════════════════════════════════════════
section "3. Hash-driven invalidation"

set seg [make_temp_segment]
set pp [write_profile $seg "hash-flip"]
set ap [write_approach_yaml $seg "hash-flip" [cache_approach_yaml $pp]]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Hash Flip" stem "hash-flip"}] \
]

set State [spar::State new]
set contact [lindex [$State classify_segment $seg] 0]

set ::spar::parse_count 0
$State approach_summary $contact
set baseline $::spar::parse_count
assert_eq $baseline 1 "3: baseline parse count is 1"

# Rewrite line 1 with a different profile_hash hex, leaving body alone.
# mtime advances naturally on the rewrite.
after 1100
write_approach_yaml $seg "hash-flip" [cache_approach_yaml_with_hash \
    "1111111111111111111111111111111111111111111111111111111111111111"]

$State approach_summary $contact
assert_eq $::spar::parse_count [expr {$baseline + 1}] \
    "3: hash flip → exactly one re-parse"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 4. Mtime-driven invalidation — same line-1 hash, different body.
# ════════════════════════════════════════════════════════════════════════
section "4. Mtime-driven invalidation"

set seg [make_temp_segment]
set pp [write_profile $seg "mtime-flip"]
write_approach_yaml $seg "mtime-flip" [cache_approach_yaml $pp "Original subject"]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Mtime Flip" stem "mtime-flip"}] \
]

set State [spar::State new]
set contact [lindex [$State classify_segment $seg] 0]

set ::spar::parse_count 0
set summary_before [$State approach_summary $contact]
set baseline $::spar::parse_count
assert_eq $baseline 1 "4: baseline parse count is 1"

# Rewrite with the same line-1 profile_hash but a different subject.
# Wait > 1s so mtime advances on filesystems with 1s mtime granularity.
after 1100
write_approach_yaml $seg "mtime-flip" [cache_approach_yaml $pp "New subject"]

set summary_after [$State approach_summary $contact]
assert_eq $::spar::parse_count [expr {$baseline + 1}] \
    "4: mtime advance → re-parse"

# Pull the new subject out of the projection to confirm the cache
# actually picked up the new content (not just bumped its counter).
set new_subject ""
foreach round [dict get $summary_after rounds] {
    if {[dict get $round type] eq "final"} {
        foreach msg [dict get $round messages] {
            if {[dict get $msg channel] eq "email"} {
                set new_subject [dict get $msg subject]
            }
        }
    }
}
assert_eq $new_subject "New subject" "4: returned summary reflects new content"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 5. Explicit forget_approach — drops cache entry.
# ════════════════════════════════════════════════════════════════════════
section "5. Explicit forget_approach invalidation"

set seg [make_temp_segment]
set pp [write_profile $seg "forget-one"]
write_approach_yaml $seg "forget-one" [cache_approach_yaml $pp]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Forget One" stem "forget-one"}] \
]

set State [spar::State new]
set contact [lindex [$State classify_segment $seg] 0]
set ap [dict get $contact approach_path]

set ::spar::parse_count 0
$State approach_summary $contact
set baseline $::spar::parse_count
assert_eq $baseline 1 "5: baseline parse count is 1"

# Sanity: a second call without forget hits the cache.
$State approach_summary $contact
assert_eq $::spar::parse_count $baseline "5: pre-forget second call hits cache"

$State forget_approach $ap
$State approach_summary $contact
assert_eq $::spar::parse_count [expr {$baseline + 1}] \
    "5: forget_approach forces re-parse on next call"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 6. Bypass-site freshness — spar::read_approach_yaml never caches.
# ════════════════════════════════════════════════════════════════════════
section "6. Bypass-site freshness"

set seg [make_temp_segment]
set pp [write_profile $seg "bypass-one"]
set ap [write_approach_yaml $seg "bypass-one" [cache_approach_yaml $pp "Cached subject"]]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Bypass One" stem "bypass-one"}] \
]

set State [spar::State new]
set contact [lindex [$State classify_segment $seg] 0]

# Populate the cache with the original content.
set cached [$State approach_summary $contact]

# Rewrite the file (same hash, different subject).
after 1100
write_approach_yaml $seg "bypass-one" [cache_approach_yaml $pp "Fresh subject"]

# spar::read_approach_yaml is the function the three bypass sites call.
# It must always parse — never consult the cache.
set ::spar::parse_count 0
set fresh1 [spar::read_approach_yaml $ap]
set fresh2 [spar::read_approach_yaml $ap]
assert_eq $::spar::parse_count 2 "6: read_approach_yaml parses every call (no cache)"

# The freshly-read data must contain the new subject AND the body
# (which the projection blanks). Both prove this is a full parse, not
# a projection lookup.
set fresh_subject ""
set fresh_body ""
foreach round [dict get $fresh1 rounds] {
    if {[dict get $round type] eq "final"} {
        foreach msg [dict get $round messages] {
            if {[dict get $msg channel] eq "email"} {
                set fresh_subject [dict get $msg subject]
                set fresh_body [dict get $msg body]
            }
        }
    }
}
assert_eq $fresh_subject "Fresh subject" "6: bypass read sees on-disk content"
assert_eq $fresh_body "Hello there" "6: bypass read sees full body (cache projection blanks it)"

$State destroy

# Meta-assertion: the three direct approach_summary callers documented
# in the issue body's bypass list (transitions/send_email.tcl,
# ui/inspector.tcl) do NOT call approach_summary — they read fresh via
# spar::read_approach_yaml. spar-dispatch.tcl's DbC sites construct a
# fresh State per call so the cache is always empty there; they are
# allowed to call either. This grep guards against accidental migration
# of the two file-level bypass sites.
set repo_root [file normalize [file join $script_dir ..]]
set send_email_path [file join $repo_root transitions send_email.tcl]
set inspector_path [file join $repo_root ui inspector.tcl]

# Count occurrences of approach_summary by reading the file in Tcl
# (grep -c exits non-zero on zero matches, which complicates exec).
proc count_substr {path needle} {
    if {![file exists $path]} { return -1 }
    set fd [open $path r]
    set content [read $fd]
    close $fd
    return [regexp -all $needle $content]
}
set send_hits [count_substr $send_email_path approach_summary]
set inspector_hits [count_substr $inspector_path approach_summary]

assert_eq $send_hits 0 \
    "6: transitions/send_email.tcl has zero approach_summary callers"
assert_eq $inspector_hits 0 \
    "6: ui/inspector.tcl has zero approach_summary callers"

# ════════════════════════════════════════════════════════════════════════
# 7. Cross-render persistence — one State across two renders.
# ════════════════════════════════════════════════════════════════════════
section "7. Cross-render persistence"

set seg [make_temp_segment]
set pp1 [write_profile $seg "render-a"]
set pp2 [write_profile $seg "render-b"]
set pp3 [write_profile $seg "render-c"]
set ap1 [write_approach_yaml $seg "render-a" [cache_approach_yaml $pp1]]
set ap2 [write_approach_yaml $seg "render-b" [cache_approach_yaml $pp2]]
set ap3 [write_approach_yaml $seg "render-c" [cache_approach_yaml $pp3]]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Render A" stem "render-a"}] \
    [make_base_row {contact_name "Render B" stem "render-b"}] \
    [make_base_row {contact_name "Render C" stem "render-c"}] \
]

# One State retained across all three renders.
set State [spar::State new]

# Helper: classify, refine, run T6 eligibility — what one UI render
# does on the fill pass.
set cdata [dict create \
    primary_channel email \
    in_scope_channels {email} \
    filter [dict create min_star 0 skip_excluded false]]

# Render 1 — cold cache. Three APPROACHED contacts → three parses.
set ::spar::parse_count 0
set classified [$State classify_segment $seg]
set refined [$State refine_segment $classified]
$State transition_eligible $classified "T6" email $cdata 2026-04-27
set parses_render1 $::spar::parse_count
assert_eq $parses_render1 3 "7: render 1 parses all 3 approaches once each"

# Render 2 — warm cache, no file changes. Zero re-parses.
set ::spar::parse_count 0
set classified [$State classify_segment $seg]
set refined [$State refine_segment $classified]
$State transition_eligible $classified "T6" email $cdata 2026-04-27
assert_eq $::spar::parse_count 0 \
    "7: render 2 with unchanged files → zero re-parses"

# Render 3 — modify one approach (line-1 hash flip → invalidates that
# entry only). Exactly one re-parse.
after 1100
write_approach_yaml $seg "render-b" [cache_approach_yaml_with_hash \
    "2222222222222222222222222222222222222222222222222222222222222222"]

set ::spar::parse_count 0
set classified [$State classify_segment $seg]
set refined [$State refine_segment $classified]
$State transition_eligible $classified "T6" email $cdata 2026-04-27
assert_eq $::spar::parse_count 1 \
    "7: render 3 with one file changed → exactly one re-parse"

$State destroy

finish_tests

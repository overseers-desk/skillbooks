#!/usr/bin/env tclsh9.0
# Cache-prefetch contract tests for spar::State::prefetch_approach_cache.
#
# These tests cover what's new vs test-approach-cache.tcl:
#   - prefetch posts batches of tpool jobs without waiting
#   - approach_summary joins each path's pending job on first need
#   - parses count once per cache-write (drained via approach_summary /
#     refine_segment), regardless of whether the parse happened on the
#     main thread or in a worker
#   - prefetch skips paths already cache-valid and already in-flight
#   - prefetch skips empty / missing paths
#   - per-State pool isolation
#
# parse_count is the canonical signal — it is incremented when the
# cache absorbs a result, not at post time. Tests drain via refine_segment
# (which routes through approach_summary) before asserting.
#
# The pool itself runs jobs in parallel; correctness of the cache
# invariants under threading is what's asserted here. Wall-time is
# measured separately by manual benchmark on a real campaign.

package require yaml
package require sha256
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

# Approach YAML helper — line 1 is `profile_hash: sha256:<hex>` matching
# the profile bytes, so classify_contact returns APPROACHED.
proc tpool_approach_yaml {profile_path {subject "Test subject"}} {
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

proc tpool_approach_yaml_with_hash {hex {subject "Test subject"}} {
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

# build_segment N -- create a temp segment with N APPROACHED contacts.
# Returns {seg_dir [list of approach_paths]}.
proc build_segment {n} {
    set seg [make_temp_segment]
    set rows {}
    set paths {}
    for {set i 0} {$i < $n} {incr i} {
        set stem [format "tp-%03d" $i]
        set pp [write_profile $seg $stem]
        set ap [write_approach_yaml $seg $stem [tpool_approach_yaml $pp]]
        lappend rows [make_base_row [list contact_name "TPool $i" stem $stem]]
        lappend paths $ap
    }
    write_roster_tsv $seg $::std_headers $rows
    return [list $seg $paths]
}

# ════════════════════════════════════════════════════════════════════════
# 1. Batch prefetch + drain — N parses observed after refine_segment.
# ════════════════════════════════════════════════════════════════════════
section "1. Batch prefetch posts jobs; drain via refine drives N parses"

lassign [build_segment 30] seg paths

set State [spar::State new]
set ::spar::parse_count 0
$State prefetch_approach_cache $paths

# parse_count does not jump at post time — workers haven't been joined yet.
# Drain by classifying + refining; refine_contact routes through
# approach_summary which joins each pending job and writes the cache.
set contacts [$State classify_segment $seg]
set refined [$State refine_segment $contacts]
assert_eq $::spar::parse_count 30 \
    "1: 30 paths drained via refine → 30 parse_count increments"

# Re-render: pure cache-hit, parse_count unchanged.
set ::spar::parse_count 0
$State refine_segment $contacts
assert_eq $::spar::parse_count 0 \
    "1: re-render is pure cache-hit"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 2. Idempotence — second prefetch with same paths posts no new jobs.
# ════════════════════════════════════════════════════════════════════════
section "2. Idempotent prefetch (no extra jobs on warm cache)"

lassign [build_segment 10] seg paths

set State [spar::State new]
$State prefetch_approach_cache $paths
# Drain so cache is fully warm.
set contacts [$State classify_segment $seg]
$State refine_segment $contacts

# Second prefetch on a warm cache must not post new jobs. Reset parse_count
# and refine again — should be zero new parses.
set ::spar::parse_count 0
$State prefetch_approach_cache $paths
$State refine_segment $contacts
assert_eq $::spar::parse_count 0 \
    "2: second prefetch on warm cache + re-drain → zero new parses"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 3. Targeted invalidation — flipping one file's line-1 hash re-parses
#    only that file when prefetch is called again with all paths.
# ════════════════════════════════════════════════════════════════════════
section "3. Targeted re-parse after one file changes"

lassign [build_segment 10] seg paths

set State [spar::State new]
$State prefetch_approach_cache $paths
set contacts [$State classify_segment $seg]
$State refine_segment $contacts   ;# drain initial 10 parses

# Wait > 1s so mtime advances on filesystems with 1s granularity, then
# rewrite one approach with a different line-1 hash. The other 9 stay
# byte-identical and their cache entries remain valid.
after 1100
set victim [lindex $paths 4]
set fd [open $victim w]
puts -nonewline $fd [tpool_approach_yaml_with_hash \
    "1111111111111111111111111111111111111111111111111111111111111111"]
close $fd

set ::spar::parse_count 0
$State prefetch_approach_cache $paths
# Re-classify to pick up the new line-1 hash on the affected contact, then
# drain. Only the rewritten file should parse.
set contacts [$State classify_segment $seg]
$State refine_segment $contacts
assert_eq $::spar::parse_count 1 \
    "3: only the changed file re-parses; 9 still cache-hit"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 4. Empty and missing paths are skipped without error.
# ════════════════════════════════════════════════════════════════════════
section "4. Empty / missing paths are tolerated"

lassign [build_segment 3] seg paths

set State [spar::State new]
set mixed [list "" "/nonexistent/approach.yaml" {*}$paths ""]
set ::spar::parse_count 0
$State prefetch_approach_cache $mixed
set contacts [$State classify_segment $seg]
$State refine_segment $contacts
assert_eq $::spar::parse_count 3 \
    "4: 3 real paths parse; 1 empty + 1 missing skipped silently"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 5. Pool lifecycle is per-State — two instances don't share cache.
# ════════════════════════════════════════════════════════════════════════
section "5. Per-State pool isolation"

lassign [build_segment 5] seg paths

set S1 [spar::State new]
$S1 prefetch_approach_cache $paths
set c1 [$S1 classify_segment $seg]
$S1 refine_segment $c1   ;# drains S1's pending jobs

# Second State has its own (empty) cache; its prefetch parses fresh.
set S2 [spar::State new]
set ::spar::parse_count 0
$S2 prefetch_approach_cache $paths
set c2 [$S2 classify_segment $seg]
$S2 refine_segment $c2
assert_eq $::spar::parse_count 5 \
    "5: second State's cache is independent — prefetch+drain parses all 5"

$S1 destroy
$S2 destroy

# ════════════════════════════════════════════════════════════════════════
# 6. Refine after prefetch returns SENT/REPLIED projections, not stubs.
#    Locks down the end-to-end invariant: workers produce the same
#    projection shape that the serial path produces.
# ════════════════════════════════════════════════════════════════════════
section "6. Worker-built projections drive refine correctly"

set seg [make_temp_segment]
set pp [write_profile $seg "sent-one"]

# An approach with one sent email message → refine should mark SENT.
set hex [string tolower [::sha2::sha256 -hex -file $pp]]
set sent_yaml "profile_hash: sha256:$hex
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Sent test
    body: Body
    actioned_date: 2026-04-20
    replied_date: null
"
write_approach_yaml $seg "sent-one" $sent_yaml
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {contact_name "Sent One" stem "sent-one"}]]

set State [spar::State new]
set contact [lindex [$State classify_segment $seg] 0]
$State prefetch_approach_cache [list [dict get $contact approach_path]]
set refined [$State refine_contact $contact]
assert_eq [dict get $refined state] "SENT" \
    "6: refine after prefetch → SENT (worker projection drives state correctly)"
assert_eq [dict get $refined email_sent] 1 \
    "6: email_sent flag populated from worker projection"

$State destroy

# ════════════════════════════════════════════════════════════════════════
# 7. forget_approach drops pending jobs along with cache entries —
#    a writer that rewrote a file mid-render must invalidate any
#    in-flight prefetch whose result was captured against the
#    pre-rewrite bytes.
# ════════════════════════════════════════════════════════════════════════
section "7. forget_approach cancels pending prefetch"

lassign [build_segment 5] seg paths

set State [spar::State new]
$State prefetch_approach_cache $paths

# Forget one path before refine drains it. The next refine should re-parse
# that path (forget cleared both cache and pending entry), the others
# resolve from their pending jobs.
set victim [lindex $paths 2]
$State forget_approach $victim

set ::spar::parse_count 0
set contacts [$State classify_segment $seg]
$State refine_segment $contacts
assert_eq $::spar::parse_count 5 \
    "7: forget + drain still produces 5 cache-writes (4 pending + 1 sync re-parse)"

$State destroy

finish_tests

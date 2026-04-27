#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 24. spar::p::run — stems selector narrows the work queue
# ════════════════════════════════════════════════════════════════════════
section "24. spar::p::run — stems selector"

source [file join $script_dir .. spar-dispatch.tcl]

# Build a minimal campaign: one segment with three roster rows, an
# overview.md promoted to usp_document, a segment.yaml goal, and a
# top-level campaign.yaml.
set dp_base [make_temp_campaign]
set dp_seg_name "seg-a"
set dp_seg [file join $dp_base $dp_seg_name]
file mkdir $dp_seg
file mkdir [file join $dp_seg profiles]

set dp_headers {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration date_excluded}
write_roster_tsv $dp_seg $dp_headers [list \
    [dict create stem alpha contact_name "A One"   organisation "Org A" sweep_iteration 1] \
    [dict create stem beta  contact_name "B Two"   organisation "Org B" sweep_iteration 1] \
    [dict create stem gamma contact_name "C Three" organisation "Org C" sweep_iteration 1] \
]

set fd [open [file join $dp_seg segment.yaml] w]
puts $fd "objective: test"
puts $fd "message_goal: test"
close $fd

set dp_overview [file join $dp_base overview.md]
set fd [open $dp_overview w]
puts $fd "# Test overview"
close $fd

set dp_yaml [file join $dp_base campaign.yaml]
set fd [open $dp_yaml w]
puts $fd "campaign: Test"
puts $fd "usp_document: overview.md"
puts $fd "segments:"
puts $fd "  - $dp_seg_name"
close $fd

# Drive spar::p::run and capture the segment's count via on_complete.
proc _dp_run_count {opts} {
    set ::dp_last -1
    spar::p::run $opts \
        {apply {args {}}} \
        {apply {{d f res} {
            set results [dict get $res results]
            if {[llength $results] > 0} {
                set ::dp_last [dict get [lindex $results 0] count]
            } else {
                set ::dp_last 0
            }
        }}}
    return $::dp_last
}

# Baseline: no stems → all three rows queued
set dp_count_all [_dp_run_count [dict create \
    campaign_file $dp_yaml dry_run 1]]
assert_eq $dp_count_all 3 "spar::p::run: no stems → 3 queued"

# Narrowed: stems={beta} → only beta queued
file delete -force [file join $dp_seg profiles]
file mkdir [file join $dp_seg profiles]
set dp_count_one [_dp_run_count [dict create \
    campaign_file $dp_yaml dry_run 1 stems {beta}]]
assert_eq $dp_count_one 1 "spar::p::run: stems={beta} → 1 queued"

# stems selector bypasses profile-exists skip (caller pre-deleted old profile).
# Re-run with an existing profiles/beta.md on disk → still 1, not 0.
write_profile $dp_seg beta
set dp_count_rebuild [_dp_run_count [dict create \
    campaign_file $dp_yaml dry_run 1 stems {beta}]]
assert_eq $dp_count_rebuild 1 "spar::p::run: stems+existing profile → rebuild queued"

# Without stems, existing profile is skipped.
set dp_count_skip [_dp_run_count [dict create \
    campaign_file $dp_yaml dry_run 1]]
assert_eq $dp_count_skip 2 "spar::p::run: no stems + 1 profile exists → 2 queued"

# ════════════════════════════════════════════════════════════════════════
# 24b. T-id → runner routing table
# ════════════════════════════════════════════════════════════════════════
section "24b. transition runner routing"

assert_eq [spar::has_transition_runner T1] 1 "routing: T1 is wired"
assert_eq [spar::has_transition_runner T2] 1 "routing: T2 is wired"
assert_eq [spar::has_transition_runner T6] 1 "routing: T6 is wired"
assert_eq [spar::has_transition_runner T7] 1 "routing: T7 is wired"
assert_eq [spar::has_transition_runner T3] 1 "routing: T3 is wired"
assert_eq [spar::has_transition_runner T4] 1 "routing: T4 is wired"
assert_eq [spar::has_transition_runner T8] 0 "routing: T8 is not wired"
assert_eq [spar::has_transition_runner T9] 0 "routing: T9 is not wired"

# transition_runner returns a command prefix [list $obj run]. The object
# is a TclOO instance of the class registered against the T-id, so shape
# checks are "second element is `run`" and "class name matches".
proc _runner_class {tid} {
    set runner [spar::transition_runner $tid]
    return [info object class [lindex $runner 0]]
}
assert_eq [_runner_class T1] ::spar::transitions::ProfileTransition "routing: T1 → ProfileTransition"
assert_eq [_runner_class T3] ::spar::transitions::ProfileTransition "routing: T3 → ProfileTransition"
assert_eq [_runner_class T2] ::spar::transitions::ApproachTransition "routing: T2 → ApproachTransition"
assert_eq [_runner_class T4] ::spar::transitions::ApproachTransition "routing: T4 → ApproachTransition"
assert_eq [_runner_class T6] ::spar::transitions::SendEmailTransition "routing: T6 → SendEmailTransition"
assert_eq [_runner_class T7] ::spar::transitions::CheckRepliesTransition "routing: T7 → CheckRepliesTransition"
foreach _tid {T1 T2 T6 T7 T3 T4} {
    assert_eq [lindex [spar::transition_runner $_tid] 1] run \
        "routing: $_tid runner verb is `run`"
}

set _routing_err ""
catch {spar::transition_runner T8} _routing_err
assert_match $_routing_err "no runner*" "routing: T8 lookup errors"

# ════════════════════════════════════════════════════════════════════════
# 24c. spar::filter_approaches_by_stems — T7 cohort narrowing (issue #73)
# ════════════════════════════════════════════════════════════════════════
section "24c. spar::filter_approaches_by_stems — T7 cohort narrowing"

source [file join $script_dir .. spar-email.tcl]

set fas_inputs [list \
    [dict create approach_path /x/approach/alpha.yaml      to_email a@x fingerprints {}] \
    [dict create approach_path /x/approach/beta.yaml       to_email b@x fingerprints {}] \
    [dict create approach_path /x/approach/gamma.yaml      to_email c@x fingerprints {}]]

# Empty stems → no filter
set fas_all [spar::filter_approaches_by_stems $fas_inputs {}]
assert_eq [llength $fas_all] 3 "filter: empty stems → all 3 kept"

# Narrow to one stem
set fas_one [spar::filter_approaches_by_stems $fas_inputs {beta}]
assert_eq [llength $fas_one] 1 "filter: stems={beta} → 1 kept"
assert_eq [dict get [lindex $fas_one 0] to_email] b@x \
    "filter: stems={beta} → kept entry is beta"

# Multiple stems, mixed presence
set fas_two [spar::filter_approaches_by_stems $fas_inputs {alpha gamma unknown}]
assert_eq [llength $fas_two] 2 "filter: stems={alpha,gamma,unknown} → 2 kept (unknown ignored)"

# Shared inbox: two approaches with the same to_email, one in cohort.
set fas_shared [list \
    [dict create approach_path /x/approach/jane-duo.yaml   to_email shared@x fingerprints {}] \
    [dict create approach_path /x/approach/john-duo.yaml   to_email shared@x fingerprints {}]]
set fas_s1 [spar::filter_approaches_by_stems $fas_shared {jane-duo}]
assert_eq [llength $fas_s1] 1 "filter: shared inbox, one in cohort → that one kept"
assert_eq [dict get [lindex $fas_s1 0] approach_path] /x/approach/jane-duo.yaml \
    "filter: shared inbox → kept entry is jane-duo"

# No-match stems
set fas_none [spar::filter_approaches_by_stems $fas_inputs {nobody}]
assert_eq [llength $fas_none] 0 "filter: stems={nobody} → 0 kept"

# ════════════════════════════════════════════════════════════════════════
section "25. Campaign channel slots (issue #41)"
# ════════════════════════════════════════════════════════════════════════

# ── campaign_in_scope_channels: empty, single, multi, map form ──
assert_eq [spar::campaign_in_scope_channels [dict create]] {} \
    "in_scope_channels: empty dict → {}"
assert_eq [spar::campaign_in_scope_channels \
    [dict create primary_channel email]] {email} \
    "in_scope_channels: primary only (bare string)"
assert_eq [spar::campaign_in_scope_channels \
    [dict create primary_channel email \
                 secondary_channel [dict create channel phone wait_days 7 wait_condition no_reply]]] \
    {email phone} \
    "in_scope_channels: primary bare + secondary map"
assert_eq [spar::campaign_in_scope_channels \
    [dict create primary_channel email \
                 secondary_channel phone \
                 tertiary_channel linkedin]] \
    {email phone linkedin} \
    "in_scope_channels: all three slots"
# De-duplication — a slot repeating the same channel appears once
assert_eq [spar::campaign_in_scope_channels \
    [dict create primary_channel email \
                 secondary_channel email]] {email} \
    "in_scope_channels: duplicates collapsed"

# ── roster_row_has_in_scope_channel ──
set c41_row_email    [dict create email alice@example.com linkedin_url "" facebook_url "" phone ""]
set c41_row_phone    [dict create email "" linkedin_url "" facebook_url "" phone "0412 000 000"]
set c41_row_linkedin [dict create email "" linkedin_url "https://linkedin.com/in/x" facebook_url "" phone ""]
set c41_row_none     [dict create email "" linkedin_url "" facebook_url "" phone ""]

assert_eq [spar::roster_row_has_in_scope_channel $c41_row_email {email}] 1 \
    "row_has_in_scope: email row passes {email}"
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_phone {email}] 0 \
    "row_has_in_scope: phone-only row fails {email}"
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_phone {email phone}] 1 \
    "row_has_in_scope: phone-only row passes {email phone} (secondary wins)"
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_linkedin {email phone}] 0 \
    "row_has_in_scope: linkedin-only row fails {email phone}"
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_linkedin {linkedin}] 1 \
    "row_has_in_scope: linkedin-only row passes {linkedin}"
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_none {email phone linkedin facebook}] 0 \
    "row_has_in_scope: all-blank row fails every channel"

# Empty channel list (campaign declares no slots) — everything passes
# (legacy fallback: absent an explicit constraint, do not block).
assert_eq [spar::roster_row_has_in_scope_channel $c41_row_none {}] 1 \
    "row_has_in_scope: empty channel list → row passes (legacy fallback)"

# ════════════════════════════════════════════════════════════════════════
section "26. T9 / T10 secondary / tertiary channel eligibility (issue #41)"
# ════════════════════════════════════════════════════════════════════════

# Approach-YAML helper for a final round with primary email (sent on $primary_date,
# optionally replied on $replied_date, or null) + a pending secondary phone
# message. Produces the shape state-machine.md §States expects for T9.
proc t9_yaml_primary_email_sent_secondary_phone_pending {primary_date {replied_date null}} {
    return "decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Hello
    body: body
    actioned_date: $primary_date
    replied_date: $replied_date
  - channel: phone
    to: \"0412 000 000\"
    phone_note: |
        text: \"Hi…\"
    actioned_date: null
    replied_date: null
"
}

proc t9_yaml_primary_unsent {} {
    return {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Hello
    body: body
    actioned_date: null
    replied_date: null
  - channel: phone
    to: "0412 000 000"
    phone_note: |
        text: "Hi…"
    actioned_date: null
    replied_date: null
}
}

# Campaign dict with primary=email, secondary=phone@7d no_reply
set t9_cdata [dict create \
    primary_channel email \
    secondary_channel [dict create channel phone wait_days 7 wait_condition no_reply]]

# Today for deterministic wait-day math.
set t9_today 2026-04-15

# ── T9 ready: primary email sent 10d ago, no reply, secondary phone pending ──
set t9_seg [make_temp_segment]
write_profile $t9_seg "contact-1"
write_approach_yaml $t9_seg "contact-1" [t9_yaml_primary_email_sent_secondary_phone_pending 2026-04-05]
set t9_headers $::std_headers
set t9_rows [list \
    [make_base_row {contact_name "C1" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" stem "contact-1"}] \
]
write_roster_tsv $t9_seg $t9_headers $t9_rows
set t9_contacts [$State classify_segment $t9_seg]
set t9_contacts [$State refine_segment $t9_contacts]
set t9_ready [$State transition_eligible $t9_contacts "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_ready] 1 \
    "T9 ready: primary sent 10d ago, no reply, phone pending → 1 task"
assert_eq [dict get [lindex $t9_ready 0] task_state] "ready" \
    "T9 ready: task_state=ready"

# ── T9 pending: primary sent 3d ago (< 7d wait) ──
set t9_seg2 [make_temp_segment]
write_profile $t9_seg2 "contact-2"
write_approach_yaml $t9_seg2 "contact-2" [t9_yaml_primary_email_sent_secondary_phone_pending 2026-04-12]
write_roster_tsv $t9_seg2 $t9_headers [list \
    [make_base_row {contact_name "C2" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" stem "contact-2"}]]
set t9_contacts2 [$State classify_segment $t9_seg2]
set t9_contacts2 [$State refine_segment $t9_contacts2]
set t9_pend [$State transition_eligible $t9_contacts2 "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_pend] 1 "T9 pending: primary sent 3d ago → 1 pending task"
assert_eq [dict get [lindex $t9_pend 0] task_state] "pending" \
    "T9 pending: task_state=pending"
assert_match [dict get [lindex $t9_pend 0] reason] "*waiting until day 7*" \
    "T9 pending reason names the wait threshold"

# ── T9 not visible: primary got a reply → state=REPLIED → T9 skips ──
# (REPLIED state already expresses that outreach succeeded; the wait_condition
# check is redundant with state gating for the primary-reply case.)
set t9_seg3 [make_temp_segment]
write_profile $t9_seg3 "contact-3"
write_approach_yaml $t9_seg3 "contact-3" [t9_yaml_primary_email_sent_secondary_phone_pending 2026-04-05 2026-04-06]
write_roster_tsv $t9_seg3 $t9_headers [list \
    [make_base_row {contact_name "C3" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" stem "contact-3"}]]
set t9_contacts3 [$State classify_segment $t9_seg3]
set t9_contacts3 [$State refine_segment $t9_contacts3]
set t9_blocked [$State transition_eligible $t9_contacts3 "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_blocked] 0 \
    "T9 state-gated: contact in REPLIED (primary replied) → no T9 row"

# ── T9 not visible: primary not sent yet (no preceding signal to wait on) ──
set t9_seg4 [make_temp_segment]
write_profile $t9_seg4 "contact-4"
write_approach_yaml $t9_seg4 "contact-4" [t9_yaml_primary_unsent]
write_roster_tsv $t9_seg4 $t9_headers [list \
    [make_base_row {contact_name "C4" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" stem "contact-4"}]]
set t9_contacts4 [$State classify_segment $t9_seg4]
set t9_contacts4 [$State refine_segment $t9_contacts4]
set t9_noop [$State transition_eligible $t9_contacts4 "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_noop] 0 \
    "T9 none: primary unsent → no T9 row (don't show 'preceding not yet sent' noise)"

# ── T9 zero without cdata ──
set t9_no_cdata [$State transition_eligible $t9_contacts "T9" email]
assert_eq [llength $t9_no_cdata] 0 \
    "T9 zero when cdata omitted (back-compat with pre-#41 callers)"

# ── T9 zero when campaign lacks secondary_channel ──
set t9_primary_only_cdata [dict create primary_channel email]
set t9_zero [$State transition_eligible $t9_contacts "T9" email $t9_primary_only_cdata $t9_today]
assert_eq [llength $t9_zero] 0 \
    "T9 zero when campaign has no secondary_channel slot"

# ── T10: tertiary, gated on secondary-channel message ──
# Campaign primary=email, secondary=phone@3d, tertiary=linkedin@5d.
# Final round: email actioned_date=2026-04-01, phone actioned_date=2026-04-05,
# linkedin pending. Today=2026-04-15. Phone was sent 10d ago, wait_days=5,
# no reply on phone → tertiary_ready=1.
set t10_cdata [dict create \
    primary_channel email \
    secondary_channel [dict create channel phone wait_days 3 wait_condition no_reply] \
    tertiary_channel  [dict create channel linkedin wait_days 5 wait_condition no_reply]]

proc t10_yaml_primary_sent_secondary_sent_tertiary_pending {primary_date secondary_date} {
    return "decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Hello
    body: body
    actioned_date: $primary_date
    replied_date: null
  - channel: phone
    to: \"0412 000 000\"
    phone_note: |
        text: \"Hi…\"
    actioned_date: $secondary_date
    replied_date: null
  - channel: linkedin
    body: Linkedin follow-up
    actioned_date: null
    replied_date: null
"
}

set t10_seg [make_temp_segment]
write_profile $t10_seg "contact-10"
write_approach_yaml $t10_seg "contact-10" [t10_yaml_primary_sent_secondary_sent_tertiary_pending 2026-04-01 2026-04-05]
write_roster_tsv $t10_seg $t9_headers [list \
    [make_base_row {contact_name "C10" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" linkedin_url "https://linkedin.com/in/c10" stem "contact-10"}]]
set t10_contacts [$State classify_segment $t10_seg]
set t10_contacts [$State refine_segment $t10_contacts]
set t10_ready [$State transition_eligible $t10_contacts "T10" email $t10_cdata $t9_today]
assert_eq [llength $t10_ready] 1 \
    "T10 ready: secondary sent 10d ago, wait=5d, linkedin pending → 1 task"
assert_eq [dict get [lindex $t10_ready 0] task_state] "ready" \
    "T10 ready: task_state=ready"

# ── T10 pending: secondary sent 2d ago (< 5d wait) ──
set t10_seg2 [make_temp_segment]
write_profile $t10_seg2 "contact-11"
write_approach_yaml $t10_seg2 "contact-11" [t10_yaml_primary_sent_secondary_sent_tertiary_pending 2026-04-01 2026-04-13]
write_roster_tsv $t10_seg2 $t9_headers [list \
    [make_base_row {contact_name "C11" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" linkedin_url "https://linkedin.com/in/c11" stem "contact-11"}]]
set t10_contacts2 [$State classify_segment $t10_seg2]
set t10_contacts2 [$State refine_segment $t10_contacts2]
set t10_pend [$State transition_eligible $t10_contacts2 "T10" email $t10_cdata $t9_today]
assert_eq [llength $t10_pend] 1 "T10 pending: secondary sent 2d ago → 1 pending"
assert_match [dict get [lindex $t10_pend 0] reason] "*waiting until day 5*" \
    "T10 pending names the wait threshold"

# ── T10 zero if tertiary slot absent ──
set t10_no_tert [$State transition_eligible $t10_contacts "T10" email $t9_cdata $t9_today]
assert_eq [llength $t10_no_tert] 0 \
    "T10 zero when campaign has no tertiary_channel slot"

# ════════════════════════════════════════════════════════════════════════
section "T6 / T7 behavioural eligibility (issue #84 audit gap)"
# ════════════════════════════════════════════════════════════════════════
#
# Routing tests cover that T6 → SendEmailTransition and T7 →
# CheckRepliesTransition resolve. These tests cover the per-T-id
# `eligible` method bodies — the ready / pending-with-no-email /
# already-sent / wrong-channel / invalid-yaml branches that the routing
# tests do not exercise.

# ── T6 ──────────────────────────────────────────────────────────────────

# T6-a: APPROACHED, has_email, primary_channel=email, email_sent=0 → ready.
set t6a_seg [make_temp_segment]
write_profile $t6a_seg "t6a"
write_approach_yaml $t6a_seg "t6a" [approach_yaml_final_unsent]
write_roster_tsv $t6a_seg $::std_headers [list \
    [make_base_row {contact_name "T6A" stem "t6a" email "test@acme-venues.au" star_rating 4}] \
]
set t6a_c [$State classify_segment $t6a_seg]
set t6a_c [$State refine_segment $t6a_c]
set t6a_tasks [$State transition_eligible $t6a_c "T6" "email"]
assert_eq [llength $t6a_tasks] 1 "T6: APPROACHED+email+unsent → 1 task"
assert_eq [dict get [lindex $t6a_tasks 0] task_state] "ready" \
    "T6: APPROACHED+email+unsent → task_state=ready"

# T6-b: APPROACHED, has_email=0 → pending with "No email address".
set t6b_seg [make_temp_segment]
write_profile $t6b_seg "t6b"
write_approach_yaml $t6b_seg "t6b" [approach_yaml_final_unsent]
write_roster_tsv $t6b_seg $::std_headers [list \
    [make_base_row {contact_name "T6B" stem "t6b" email "" \
        linkedin_url "https://linkedin.com/in/t6b" star_rating 4}] \
]
set t6b_c [$State classify_segment $t6b_seg]
set t6b_c [$State refine_segment $t6b_c]
set t6b_tasks [$State transition_eligible $t6b_c "T6" "email"]
assert_eq [llength $t6b_tasks] 1 "T6: APPROACHED+no-email → 1 task"
assert_eq [dict get [lindex $t6b_tasks 0] task_state] "pending" \
    "T6: APPROACHED+no-email → task_state=pending"
assert_eq [dict get [lindex $t6b_tasks 0] reason] "No email address" \
    "T6: APPROACHED+no-email → reason='No email address'"

# T6-c: APPROACHED but already-sent (email_sent=1) → no task (suppressed).
set t6c_seg [make_temp_segment]
write_profile $t6c_seg "t6c"
write_approach_yaml $t6c_seg "t6c" [approach_yaml_final_sent_email]
write_roster_tsv $t6c_seg $::std_headers [list \
    [make_base_row {contact_name "T6C" stem "t6c" email "test@acme-venues.au" star_rating 4}] \
]
set t6c_c [$State classify_segment $t6c_seg]
set t6c_c [$State refine_segment $t6c_c]
set t6c_tasks [$State transition_eligible $t6c_c "T6" "email"]
assert_eq [llength $t6c_tasks] 0 \
    "T6: APPROACHED+email+already-sent → 0 tasks (refine sees email_sent=1)"

# T6-d: APPROACHED, primary_channel=linkedin → no task (T6 is email-only
# until per-message routing per #49).
set t6d_seg [make_temp_segment]
write_profile $t6d_seg "t6d"
write_approach_yaml $t6d_seg "t6d" [approach_yaml_final_unsent]
write_roster_tsv $t6d_seg $::std_headers [list \
    [make_base_row {contact_name "T6D" stem "t6d" email "test@acme-venues.au" star_rating 4}] \
]
set t6d_c [$State classify_segment $t6d_seg]
set t6d_c [$State refine_segment $t6d_c]
set t6d_tasks [$State transition_eligible $t6d_c "T6" "linkedin"]
assert_eq [llength $t6d_tasks] 0 \
    "T6: primary_channel=linkedin → 0 tasks"

# T6-e: APPROACHED + invalid approach YAML (unknown root key) → pending
# with reason starting "invalid_approach_yaml:".
set t6e_seg [make_temp_segment]
write_profile $t6e_seg "t6e"
write_approach_yaml $t6e_seg "t6e" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Hi
    body: Hello
    actioned_date: null
    replied_date: null
bogus_root_key: value
}
write_roster_tsv $t6e_seg $::std_headers [list \
    [make_base_row {contact_name "T6E" stem "t6e" email "test@acme-venues.au" star_rating 4}] \
]
set t6e_c [$State classify_segment $t6e_seg]
set t6e_c [$State refine_segment $t6e_c]
set t6e_tasks [$State transition_eligible $t6e_c "T6" "email"]
assert_eq [llength $t6e_tasks] 1 "T6: invalid YAML → 1 task"
assert_eq [dict get [lindex $t6e_tasks 0] task_state] "pending" \
    "T6: invalid YAML → task_state=pending"
assert_match [dict get [lindex $t6e_tasks 0] reason] "invalid_approach_yaml:*" \
    "T6: invalid YAML → reason starts 'invalid_approach_yaml:'"

# ── T7 ──────────────────────────────────────────────────────────────────

# T7-a: SENT, email_replied=0 → ready.
set t7a_seg [make_temp_segment]
write_profile $t7a_seg "t7a"
write_approach_yaml $t7a_seg "t7a" [approach_yaml_final_sent_email]
write_roster_tsv $t7a_seg $::std_headers [list \
    [make_base_row {contact_name "T7A" stem "t7a" email "test@acme-venues.au" star_rating 4}] \
]
set t7a_c [$State classify_segment $t7a_seg]
set t7a_c [$State refine_segment $t7a_c]
set t7a_tasks [$State transition_eligible $t7a_c "T7"]
assert_eq [llength $t7a_tasks] 1 "T7: SENT+no-reply → 1 task"
assert_eq [dict get [lindex $t7a_tasks 0] task_state] "ready" \
    "T7: SENT+no-reply → task_state=ready"

# T7-b: REPLIED (email_replied=1) → no task.
set t7b_seg [make_temp_segment]
write_profile $t7b_seg "t7b"
write_approach_yaml $t7b_seg "t7b" [approach_yaml_final_replied]
write_roster_tsv $t7b_seg $::std_headers [list \
    [make_base_row {contact_name "T7B" stem "t7b" email "test@acme-venues.au" star_rating 4}] \
]
set t7b_c [$State classify_segment $t7b_seg]
set t7b_c [$State refine_segment $t7b_c]
set t7b_tasks [$State transition_eligible $t7b_c "T7"]
assert_eq [llength $t7b_tasks] 0 \
    "T7: REPLIED → 0 tasks (already replied, no monitoring needed)"

# T7-c: APPROACHED but never sent → no task (T7 monitors only sent
# emails).
set t7c_seg [make_temp_segment]
write_profile $t7c_seg "t7c"
write_approach_yaml $t7c_seg "t7c" [approach_yaml_final_unsent]
write_roster_tsv $t7c_seg $::std_headers [list \
    [make_base_row {contact_name "T7C" stem "t7c" email "test@acme-venues.au" star_rating 4}] \
]
set t7c_c [$State classify_segment $t7c_seg]
set t7c_c [$State refine_segment $t7c_c]
set t7c_tasks [$State transition_eligible $t7c_c "T7"]
assert_eq [llength $t7c_tasks] 0 \
    "T7: APPROACHED+unsent → 0 tasks (no email_sent yet)"

# T7-d: EXCLUDED contact (was sent before exclusion) → no task. T7
# explicitly skips EXCLUDED to avoid reply-watching a contact the
# operator has retired.
set t7d_seg [make_temp_segment]
write_profile $t7d_seg "t7d"
write_approach_yaml $t7d_seg "t7d" [approach_yaml_final_sent_email]
write_roster_tsv $t7d_seg $::std_headers [list \
    [make_base_row {contact_name "T7D" stem "t7d" email "test@acme-venues.au" \
        star_rating 4 date_excluded "2026-04-05"}] \
]
set t7d_c [$State classify_segment $t7d_seg]
set t7d_c [$State refine_segment $t7d_c]
set t7d_tasks [$State transition_eligible $t7d_c "T7"]
assert_eq [llength $t7d_tasks] 0 \
    "T7: EXCLUDED → 0 tasks (regardless of prior email_sent)"

# T7-e: SENT contact + invalid approach YAML → pending with
# reason starting "invalid_approach_yaml:". Validates the
# eligibility-time approach gate symmetric with T6.
set t7e_seg [make_temp_segment]
write_profile $t7e_seg "t7e"
write_approach_yaml $t7e_seg "t7e" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Sent
    body: Hello
    actioned_date: 2026-04-01
    replied_date: null
bogus_root_key: value
}
write_roster_tsv $t7e_seg $::std_headers [list \
    [make_base_row {contact_name "T7E" stem "t7e" email "test@acme-venues.au" star_rating 4}] \
]
set t7e_c [$State classify_segment $t7e_seg]
set t7e_c [$State refine_segment $t7e_c]
set t7e_tasks [$State transition_eligible $t7e_c "T7"]
assert_eq [llength $t7e_tasks] 1 "T7: SENT+invalid YAML → 1 task"
assert_eq [dict get [lindex $t7e_tasks 0] task_state] "pending" \
    "T7: SENT+invalid YAML → task_state=pending"
assert_match [dict get [lindex $t7e_tasks 0] reason] "invalid_approach_yaml:*" \
    "T7: SENT+invalid YAML → reason starts 'invalid_approach_yaml:'"

# ════════════════════════════════════════════════════════════════════════
# audit_skills_in_transcript (issue #76)
# ════════════════════════════════════════════════════════════════════════
puts "\n── audit_skills_in_transcript ─────────────────────────────────────"

set audit_root [file join $script_dir fixtures transcripts]

# Both skills present → no issues.
set au_both [spar::audit_skills_in_transcript "sess-both" {linkedin facebook} "Test Contact" $audit_root]
assert_eq [llength $au_both] 0 "audit: both skills present → 0 issues"

# Neither skill present → 2 issues with the right codes.
set au_none [spar::audit_skills_in_transcript "sess-none" {linkedin facebook} "Test Contact" $audit_root]
assert_eq [llength $au_none] 2 "audit: neither skill present → 2 issues"
set au_codes {}
foreach _i $au_none { lappend au_codes [dict get $_i code] }
set au_codes [lsort $au_codes]
assert_eq $au_codes {facebook_lookup_missing linkedin_lookup_missing} \
    "audit: codes are linkedin_lookup_missing and facebook_lookup_missing"
assert_eq [dict get [lindex $au_none 0] severity] "error" \
    "audit: missing-skill issues are severity=error"
assert_eq [dict get [lindex $au_none 0] contact_name] "Test Contact" \
    "audit: contact_name carried through"

# Asymmetric: only linkedin required, sess-both has both — must yield 0.
set au_one [spar::audit_skills_in_transcript "sess-both" {linkedin} "Test Contact" $audit_root]
assert_eq [llength $au_one] 0 "audit: required={linkedin}, present={linkedin,facebook} → 0 issues"

# Missing transcript → single warning, not an error (so the harness's
# severity=error filter drops it; plumbing failure must not loop the agent).
set au_miss [spar::audit_skills_in_transcript "no-such-session" {linkedin facebook} "Test Contact" $audit_root]
assert_eq [llength $au_miss] 1 "audit: missing transcript → 1 issue"
assert_eq [dict get [lindex $au_miss 0] code] "transcript_not_found" \
    "audit: missing transcript → code=transcript_not_found"
assert_eq [dict get [lindex $au_miss 0] severity] "warning" \
    "audit: missing transcript → severity=warning"


finish_tests

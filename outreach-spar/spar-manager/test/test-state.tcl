#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 1. Primary state classification
# ════════════════════════════════════════════════════════════════════════
section "1. Primary state classification"

# 1a. date_excluded set → EXCLUDED
set seg [make_temp_segment]
set row [make_base_row {date_excluded "2026-01-15"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "EXCLUDED" "date_excluded → EXCLUDED"

# 1b. Valid contact, stem="" → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {stem ""}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "no profile file → DISCOVERED"

# 1c. Valid contact, stem set, profile file exists → PROFILED
set seg [make_temp_segment]
write_profile $seg "alice-smith-acme"
set row [make_base_row {stem "alice-smith-acme"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "stem + file exists → PROFILED"

# 1d. Valid contact, stem set, profile file MISSING → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {stem "nonexistent-profile"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "stem + file missing → DISCOVERED"

# 1e. Valid, stem set, profile+approach files exist, no final round → APPROACHED
set seg [make_temp_segment]
write_profile $seg "bob-jones-widgets"
write_approach_yaml $seg "bob-jones-widgets" [approach_yaml_no_final]
set row [make_base_row {stem "bob-jones-widgets"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "approach exists, no final round → APPROACHED"

# 1f. Valid, approach with final round but unsent → APPROACHED
set seg [make_temp_segment]
write_profile $seg "carol-lee-bigco"
write_approach_yaml $seg "carol-lee-bigco" [approach_yaml_final_unsent]
set row [make_base_row {stem "carol-lee-bigco"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "final round, no actioned_date → APPROACHED"

# 1g. Valid, approach with final round, actioned_date set → SENT (after refine)
set seg [make_temp_segment]
write_profile $seg "dave-kim-techcorp"
write_approach_yaml $seg "dave-kim-techcorp" [approach_yaml_final_sent_email]
set row [make_base_row {stem "dave-kim-techcorp"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result state] "SENT" "final round, actioned_date set → SENT"

# 1h. Valid, approach with final round, actioned_date+replied_date set → REPLIED
set seg [make_temp_segment]
write_profile $seg "eve-tanaka-globalinc"
write_approach_yaml $seg "eve-tanaka-globalinc" [approach_yaml_final_replied]
set row [make_base_row {stem "eve-tanaka-globalinc"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result state] "REPLIED" "final round, replied_date set → REPLIED"

# 1i. Valid, approach with final round, reply with direction=received → REPLIED
set seg [make_temp_segment]
write_profile $seg "frank-wu-pacific"
write_approach_yaml $seg "frank-wu-pacific" [approach_yaml_final_reply_received]
set row [make_base_row {stem "frank-wu-pacific"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result state] "REPLIED" "final round, direction=received reply → REPLIED"

# 1j. Approach exists, profile MISSING → PROFILE_STALE (issue #63).
# Re-profile required before re-approach. Legacy DISCOVERED behaviour
# (skipping the approach entirely) would silently lose the work.
set seg [make_temp_segment]
write_approach_yaml $seg "ghost-profile-stem" [approach_yaml_final_unsent]
set row [make_base_row {stem "ghost-profile-stem"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILE_STALE" \
    "approach references missing profile → PROFILE_STALE (#63)"

# 1k. Approach with profile_hash matching profile bytes → APPROACHED (#63)
set seg [make_temp_segment]
write_profile $seg "hash-ok"
set _ph_match [string tolower [::sha2::sha256 -hex -file [file join $seg profiles "hash-ok.md"]]]
write_approach_yaml $seg "hash-ok" "profile_hash: sha256:$_ph_match
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
"
set row [make_base_row {stem "hash-ok"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" \
    "approach + profile_hash match → APPROACHED"

# 1l. Approach with profile_hash MISMATCHING profile bytes → APPROACH_STALE (#63)
set seg [make_temp_segment]
write_profile $seg "hash-bad"
write_approach_yaml $seg "hash-bad" {profile_hash: sha256:0000000000000000000000000000000000000000000000000000000000000000
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}
set row [make_base_row {stem "hash-bad"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACH_STALE" \
    "approach + profile_hash mismatch → APPROACH_STALE (#63)"

# 1m. Approach without profile_hash (legacy / pre-#63) → APPROACHED.
# Without a stored hash the state machine cannot prove staleness; the
# contact stays APPROACHED until rebuilt through A.
set seg [make_temp_segment]
write_profile $seg "hash-absent"
write_approach_yaml $seg "hash-absent" [approach_yaml_final_unsent]
set row [make_base_row {stem "hash-absent"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" \
    "legacy approach (no profile_hash) → APPROACHED"

# 1m2. classify_contact (cheap by design, post-#84): SENT/REPLIED collapse
# to APPROACHED until refine_contact is called. Auto-safe transitions
# (T1/T2/T3/T4) never read any_sent/email_sent/linkedin_sent/any_replied, so the lossy mapping
# is safe for that scope and the parse stays skipped.
set seg [make_temp_segment]
write_profile $seg "cheap-sent"
write_approach_yaml $seg "cheap-sent" [approach_yaml_final_sent_email]
set row [make_base_row {stem "cheap-sent"}]
set cheap [$State classify_contact $row $seg]
set refined [$State refine_contact $cheap]
assert_eq [dict get $cheap state] "APPROACHED" \
    "classify_contact: SENT contact reports as APPROACHED (no parse)"
assert_eq [dict get $refined state] "SENT" \
    "refine_contact: SENT contact reports as SENT (parse path)"

# 1m3. classify_contact still detects APPROACH_STALE via line-1 hash
# without parsing the YAML body.
set seg [make_temp_segment]
write_profile $seg "cheap-stale"
write_approach_yaml $seg "cheap-stale" {profile_hash: sha256:0000000000000000000000000000000000000000000000000000000000000000
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}
set row [make_base_row {stem "cheap-stale"}]
assert_eq [dict get [$State classify_contact $row $seg] state] "APPROACH_STALE" \
    "classify_contact: line-1 hash mismatch → APPROACH_STALE (no parse)"

# 1m4. classify_contact: legacy approach without profile_hash → APPROACHED.
set seg [make_temp_segment]
write_profile $seg "cheap-legacy"
write_approach_yaml $seg "cheap-legacy" [approach_yaml_final_unsent]
set row [make_base_row {stem "cheap-legacy"}]
assert_eq [dict get [$State classify_contact $row $seg] state] "APPROACHED" \
    "classify_contact: legacy approach (no hash) → APPROACHED"

# 1n. SENT supersedes APPROACH_STALE: an engaged contact is not re-approached
# on hash mismatch alone — would clobber the send history.
set seg [make_temp_segment]
write_profile $seg "hash-bad-sent"
write_approach_yaml $seg "hash-bad-sent" {profile_hash: sha256:0000000000000000000000000000000000000000000000000000000000000000
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: 2026-04-01
    replied_date: null
}
set row [make_base_row {stem "hash-bad-sent"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result state] "SENT" \
    "SENT supersedes APPROACH_STALE (engaged contact not re-approached)"

# ════════════════════════════════════════════════════════════════════════
# 2. Secondary properties
# ════════════════════════════════════════════════════════════════════════
section "2. Secondary properties"

set seg [make_temp_segment]

# 2a. has_email: email with @ → 1
set row [make_base_row {email "foo@bar.com"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_email] 1 "email foo@bar.com → has_email=1"

# 2b. has_email: empty email → 0
set row [make_base_row {email ""}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_email] 0 "email empty → has_email=0"

# 2c. has_linkedin
set row [make_base_row {linkedin_url "https://linkedin.com/in/x"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_linkedin] 1 "linkedin_url set → has_linkedin=1"

# 2d. has_linkedin empty
set row [make_base_row {linkedin_url ""}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_linkedin] 0 "linkedin_url empty → has_linkedin=0"

# 2e. has_phone_only: phone set, no email/linkedin/facebook
set row [make_base_row {phone "0412000000" email "" linkedin_url "" facebook_url ""}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_phone_only] 1 "phone only → has_phone_only=1"

# 2f. has_phone_only: phone set but email present → 0
set row [make_base_row {phone "0412000000" email "foo@bar.com"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_phone_only] 0 "phone+email → has_phone_only=0"

# 2g. star_rating "5" → star=5
set row [make_base_row {star_rating "5"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result star] 5 "star_rating 5 → star=5"

# 2h. star_rating "" → star=0
set row [make_base_row {star_rating ""}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result star] 0 "star_rating empty → star=0"

# 2i. star_rating "3" → star=3
set row [make_base_row {star_rating "3"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result star] 3 "star_rating 3 → star=3"

# 2j. has_facebook
set row [make_base_row {facebook_url "https://facebook.com/someone"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_facebook] 1 "facebook_url set → has_facebook=1"

# ════════════════════════════════════════════════════════════════════════
# 3. Channel properties
# ════════════════════════════════════════════════════════════════════════
section "3. Channel properties"

# 3a. Approach with final round email message, actioned_date set → email_sent=1
set seg [make_temp_segment]
write_profile $seg "ch-email-sent"
write_approach_yaml $seg "ch-email-sent" [approach_yaml_final_sent_email]
set row [make_base_row {stem "ch-email-sent"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result email_sent] 1 "final email actioned → email_sent=1"

# 3b. Approach with final round linkedin message, actioned_date set → linkedin_sent=1
set seg [make_temp_segment]
write_profile $seg "ch-linkedin-sent"
write_approach_yaml $seg "ch-linkedin-sent" [approach_yaml_final_sent_linkedin]
set row [make_base_row {stem "ch-linkedin-sent"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result linkedin_sent] 1 "final linkedin actioned → linkedin_sent=1"

# 3c. email_sent=0 when approach unsent
set seg [make_temp_segment]
write_profile $seg "ch-unsent"
write_approach_yaml $seg "ch-unsent" [approach_yaml_final_unsent]
set row [make_base_row {stem "ch-unsent"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result email_sent] 0 "final email not actioned → email_sent=0"

# 3d. Approach with final round, replied_date set → any_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-replied"
write_approach_yaml $seg "ch-replied" [approach_yaml_final_replied]
set row [make_base_row {stem "ch-replied"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result any_replied] 1 "final replied_date → any_replied=1"

# 3e. direction=received → any_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-recv"
write_approach_yaml $seg "ch-recv" [approach_yaml_final_reply_received]
set row [make_base_row {stem "ch-recv"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result any_replied] 1 "direction=received → any_replied=1"

# 3f. Multi-channel: linkedin sent, email not sent
set seg [make_temp_segment]
write_profile $seg "ch-multi"
write_approach_yaml $seg "ch-multi" [approach_yaml_final_multi_channel]
set row [make_base_row {stem "ch-multi"}]
set result [$State refine_contact [$State classify_contact $row $seg]]
assert_eq [dict get $result linkedin_sent] 1 "multi-channel: linkedin_sent=1"
assert_eq [dict get $result email_sent] 0 "multi-channel: email_sent=0 (not actioned)"

# ════════════════════════════════════════════════════════════════════════
# 4. classify_segment tests
# ════════════════════════════════════════════════════════════════════════
section "4. classify_segment"

# 4a. Correct number of contacts and correct states
set seg [make_temp_segment]

write_profile $seg "profiled-one"
write_profile $seg "approached-one"
write_approach_yaml $seg "approached-one" [approach_yaml_final_unsent]
write_profile $seg "sent-one"
write_approach_yaml $seg "sent-one" [approach_yaml_final_sent_email]

set headers $::std_headers
set rows [list \
    [make_base_row {contact_name "Invalid Irene" date_excluded "2026-01-01" stem ""}] \
    [make_base_row {contact_name "Discovered Dan" stem ""}] \
    [make_base_row {contact_name "Profiled Pat" stem "profiled-one"}] \
    [make_base_row {contact_name "Approached Ann" stem "approached-one"}] \
    [make_base_row {contact_name "Sent Steve" stem "sent-one"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [$State refine_segment [$State classify_segment $seg]]
assert_eq [llength $contacts] 5 "classify_segment returns 5 contacts"

# Verify each contact's state by name
foreach c $contacts {
    set name [dict get $c contact_name]
    set state [dict get $c state]
    switch -- $name {
        "Invalid Irene"   { assert_eq $state "EXCLUDED"     "segment: $name → EXCLUDED" }
        "Discovered Dan"  { assert_eq $state "DISCOVERED"  "segment: $name → DISCOVERED" }
        "Profiled Pat"    { assert_eq $state "PROFILED"    "segment: $name → PROFILED" }
        "Approached Ann"  { assert_eq $state "APPROACHED"  "segment: $name → APPROACHED" }
        "Sent Steve"      { assert_eq $state "SENT"        "segment: $name → SENT" }
    }
}

# 4b. Schema validation: roster missing stem column → error
set seg [make_temp_segment]
set bad_headers {contact_name organisation_name email star_rating}
set bad_rows [list [dict create contact_name "Test" organisation_name "Org" email "a@b.com" star_rating "3"]]
write_roster_tsv $seg $bad_headers $bad_rows

assert_error {$State classify_segment $seg} \
    "*missing required column*stem*" \
    "missing stem column → error"

# ════════════════════════════════════════════════════════════════════════
# 5. progress_counts tests
# ════════════════════════════════════════════════════════════════════════
section "5. progress_counts"

# Create 5 contacts in known states with known properties.
set seg [make_temp_segment]

write_profile $seg "p-alice"
write_profile $seg "p-bob"
write_approach_yaml $seg "p-bob" [approach_yaml_final_unsent]
write_profile $seg "p-carol"
write_approach_yaml $seg "p-carol" [approach_yaml_final_sent_email]
write_profile $seg "p-dave"
write_approach_yaml $seg "p-dave" [approach_yaml_final_replied]

set headers $::std_headers
set rows [list \
    [make_base_row {contact_name "Alice" star_rating "4" email "alice@acme-venues.au" stem "p-alice"}] \
    [make_base_row {contact_name "Bob" star_rating "5" email "bob@acme-venues.au" stem "p-bob"}] \
    [make_base_row {contact_name "Carol" star_rating "3" email "carol@acme-venues.au" stem "p-carol"}] \
    [make_base_row {contact_name "Dave" star_rating "3" email "dave@acme-venues.au" stem "p-dave"}] \
    [make_base_row {contact_name "Ed" star_rating "2" email "" stem "" date_excluded "2026-01-01"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [$State refine_segment [$State classify_segment $seg]]
set counts [spar::progress_counts $contacts]

# Ed is EXCLUDED → Valid = 4
assert_eq [dict get $counts valid] 4 "progress: valid=4"
# Alice(PROFILED) + Bob(APPROACHED) + Carol(SENT) + Dave(REPLIED) = 4 profiled-or-above
assert_eq [dict get $counts profiled] 4 "progress: profiled=4"
# star≥3: Alice(4), Bob(5), Carol(3), Dave(3) = 4; Ed is invalid so excluded
assert_eq [dict get $counts star3] 4 "progress: star3=4"
# approached-or-above with star≥3: Bob(APPROACHED,5), Carol(SENT,3), Dave(REPLIED,3) = 3
assert_eq [dict get $counts approached_star3] 3 "progress: approached_star3=3"
# email with star≥3: Alice, Bob, Carol, Dave all have email = 4
assert_eq [dict get $counts has_email] 4 "progress: has_email=4"
# sent: Carol(SENT) + Dave(REPLIED) = 2
assert_eq [dict get $counts sent] 2 "progress: sent=2"
# replied: Dave(REPLIED) = 1
assert_eq [dict get $counts replied] 1 "progress: replied=1"

# 5b. Channel-agnostic sent/replied: a LinkedIn-only contact (no email)
# counts in sent and replied — connectors do not gate state.
set seg [make_temp_segment]
write_profile $seg "p-frank"
write_approach_yaml $seg "p-frank" [approach_yaml_final_replied_linkedin]
set rows [list \
    [make_base_row {contact_name "Frank" star_rating "4" email "" linkedin_url "https://www.linkedin.com/in/frank" stem "p-frank"}] \
]
write_roster_tsv $seg $::std_headers $rows
set contacts [$State refine_segment [$State classify_segment $seg]]
assert_eq [dict get [lindex $contacts 0] state] "REPLIED" "progress: linkedin-only reply resolves REPLIED"
set counts [spar::progress_counts $contacts]
assert_eq [dict get $counts has_email] 0 "progress: linkedin-only has_email=0"
assert_eq [dict get $counts sent] 1 "progress: linkedin-only sent=1"
assert_eq [dict get $counts replied] 1 "progress: linkedin-only replied=1"

# ════════════════════════════════════════════════════════════════════════
# 6. Transition eligibility tests
# ════════════════════════════════════════════════════════════════════════
section "6. Transition eligibility"

# Build a set of contacts in various states for transition testing.
set seg [make_temp_segment]

write_profile $seg "t-profiled-hi"
write_profile $seg "t-profiled-lo"
write_profile $seg "t-approached-email"
write_approach_yaml $seg "t-approached-email" [approach_yaml_final_unsent]
write_profile $seg "t-approached-noemail"
write_approach_yaml $seg "t-approached-noemail" [approach_yaml_final_unsent]
write_profile $seg "t-sent"
write_approach_yaml $seg "t-sent" [approach_yaml_final_sent_email]

set headers $::std_headers
set rows [list \
    [make_base_row {contact_name "Disco Dan" stem "" star_rating "4" email "dan@acme-venues.au"}] \
    [make_base_row {contact_name "Prof Hi" stem "t-profiled-hi" star_rating "4" email "hi@acme-venues.au"}] \
    [make_base_row {contact_name "Prof Lo" stem "t-profiled-lo" star_rating "2" email "lo@acme-venues.au"}] \
    [make_base_row {contact_name "App Email" stem "t-approached-email" star_rating "3" email "app@acme-venues.au"}] \
    [make_base_row {contact_name "App NoEmail" stem "t-approached-noemail" star_rating "3" email ""}] \
    [make_base_row {contact_name "Sent Sam" stem "t-sent" star_rating "3" email "sent@acme-venues.au"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [$State refine_segment [$State classify_segment $seg]]

# T1: Sweep → Profile: contact in DISCOVERED → ready
set t1 [$State transition_eligible $contacts "T1"]
set t1_names [lmap c $t1 {dict get $c contact_name}]
assert_eq [expr {"Disco Dan" in $t1_names}] 1 "T1: DISCOVERED contact is eligible"
assert_eq [expr {"Prof Hi" in $t1_names}] 0 "T1: PROFILED contact not eligible"

# T2: Profile → Approach: PROFILED + star≥3 → ready; star<3 → not in list
set t2 [$State transition_eligible $contacts "T2"]
set t2_names [lmap c $t2 {dict get $c contact_name}]
assert_eq [expr {"Prof Hi" in $t2_names}] 1 "T2: PROFILED star≥3 is eligible"
assert_eq [expr {"Prof Lo" in $t2_names}] 0 "T2: PROFILED star<3 not eligible"

# T6: Approach → Send routes by each contact's own final-round channel
# (all three fixtures lead with email), not the campaign channel.
proc t6_split {tasks} {
    set disp {}; set blocked {}
    foreach c $tasks {
        if {[dict get $c task_state] eq "dispatchable"} {
            lappend disp [dict get $c contact_name]
        } else {
            lappend blocked [dict get $c contact_name]
        }
    }
    return [list $disp $blocked]
}
lassign [t6_split [$State transition_eligible $contacts "T6" "email"]] \
    t6_dispatchable_names t6_blocked
assert_eq [expr {"App Email" in $t6_dispatchable_names}] 1 "T6: APPROACHED+email → dispatchable"
assert_eq [expr {"App NoEmail" in $t6_blocked}] 1 "T6: APPROACHED no email → blocked"
assert_eq [expr {"Sent Sam" in $t6_dispatchable_names || "Sent Sam" in $t6_blocked}] 0 \
    "T6: SENT+email_sent already → not in T6 list"

# The campaign primary channel does not change routing: with the campaign
# set to linkedin, these email-final contacts still route by email. App
# Email dispatches (not blocked "No linkedin_url"), App NoEmail blocks on
# the email address, not the missing linkedin_url. This is the regression
# guard for email-only contacts in a linkedin-primary campaign.
lassign [t6_split [$State transition_eligible $contacts "T6" "linkedin"]] \
    t6lk_dispatchable t6lk_blocked
assert_eq [expr {"App Email" in $t6lk_dispatchable}] 1 \
    "T6: email contact under linkedin campaign → dispatchable"
set app_noemail_reason ""
foreach c [$State transition_eligible $contacts "T6" "linkedin"] {
    if {[dict get $c contact_name] eq "App NoEmail"} {
        set app_noemail_reason [dict get $c reason]
    }
}
assert_eq $app_noemail_reason "No email address" \
    "T6: email contact under linkedin campaign blocks on email, not linkedin_url"

# T6 tasks carry the send channel that routed them, dispatchable and
# blocked alike, so the UI can group send cohorts per channel.
foreach c [$State transition_eligible $contacts "T6" "email"] {
    switch -- [dict get $c contact_name] {
        "App Email"   { assert_eq [dict get $c channel] "email" \
                            "T6: dispatchable task carries channel=email" }
        "App NoEmail" { assert_eq [dict get $c channel] "email" \
                            "T6: blocked task carries channel=email" }
    }
}

# T7: Send → Reply: email_sent, not any_replied → dispatchable (monitoring)
set t7 [$State transition_eligible $contacts "T7"]
set t7_names [lmap c $t7 {dict get $c contact_name}]
assert_eq [expr {"Sent Sam" in $t7_names}] 1 "T7: SENT+email_sent → in monitoring list"
# T7 is not a send: its tasks carry no channel, keeping its tree flat.
assert_eq [dict get [lindex $t7 0] channel] "" "T7: task channel is empty"

# transition_eligible result dicts must carry stem and _segment_dir so
# downstream callers (spar-transition.tcl dispatch) can route without
# re-classifying.
set t1_first [lindex $t1 0]
assert_eq [dict exists $t1_first stem] 1 "transition_eligible: result has stem key"
assert_eq [dict exists $t1_first _segment_dir] 1 "transition_eligible: result has _segment_dir key"
assert_eq [dict get $t1_first _segment_dir] $seg "transition_eligible: _segment_dir matches input"

# ════════════════════════════════════════════════════════════════════════
# 7. Profile path and approach path in result
# ════════════════════════════════════════════════════════════════════════
section "7. Path properties in classify_contact result"

set seg [make_temp_segment]
set pp [write_profile $seg "path-test"]
set ap [write_approach_yaml $seg "path-test" [approach_yaml_final_unsent]]
set row [make_base_row {stem "path-test"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result profile_path] $pp "profile_path points to correct file"
assert_eq [dict get $result approach_path] $ap "approach_path points to correct file"

# Empty paths when stem is empty
set row2 [make_base_row {stem ""}]
set result2 [$State classify_contact $row2 $seg]
assert_eq [dict get $result2 profile_path] "" "no profile file → profile_path empty"
assert_eq [dict get $result2 approach_path] "" "no profile file → approach_path empty"

# ════════════════════════════════════════════════════════════════════════
# 8. Edge cases
# ════════════════════════════════════════════════════════════════════════
section "8. Edge cases"

# 8a. EXCLUDED takes priority even if stem is set and files exist
set seg [make_temp_segment]
write_profile $seg "invalid-priority"
write_approach_yaml $seg "invalid-priority" [approach_yaml_final_sent_email]
set row [make_base_row {date_excluded "2026-03-01" stem "invalid-priority"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "EXCLUDED" "EXCLUDED wins over SENT when date_excluded set"

# 8b. profile file exists but no approach file → stays PROFILED
set seg [make_temp_segment]
write_profile $seg "no-approach-file"
set row [make_base_row {stem "no-approach-file"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "profile exists but no approach file → PROFILED"

# 8c. star_rating with non-numeric value → star=0
set seg [make_temp_segment]
set row [make_base_row {star_rating "abc"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result star] 0 "non-numeric star_rating → star=0"

# 8d. email without @ → has_email=0
set seg [make_temp_segment]
set row [make_base_row {email "not-an-email"}]
set result [$State classify_contact $row $seg]
assert_eq [dict get $result has_email] 0 "email without @ → has_email=0"

# ════════════════════════════════════════════════════════════════════════
# 10. T8 transition eligibility
# ════════════════════════════════════════════════════════════════════════
section "10. T8 transition eligibility"

# 10a. T8: linkedin_sent=1, email_sent=0 → appears in T8 list
set seg_t8 [make_temp_segment]
write_profile $seg_t8 "t8-linkedin-only"
write_approach_yaml $seg_t8 "t8-linkedin-only" [approach_yaml_final_multi_channel]
write_roster_tsv $seg_t8 $::std_headers [list \
    [make_base_row {contact_name "LI Sent" email "li@acme-venues.au" \
        linkedin_url "https://linkedin.com/in/li" \
        stem "t8-linkedin-only" star_rating "4"}] \
]

set ct8 [$State refine_segment [$State classify_segment $seg_t8]]
set t8_results [$State transition_eligible $ct8 "T8"]
set t8_names [lmap c $t8_results {dict get $c contact_name}]
assert_eq [expr {"LI Sent" in $t8_names}] 1 \
    "T8: linkedin_sent=1, email_sent=0 → eligible"
# Verify task_state is awaiting
set t8_entry [lindex $t8_results 0]
assert_eq [dict get $t8_entry task_state] "awaiting" \
    "T8: task_state is awaiting"

# 10b. T8: email_sent=1 → does NOT appear in T8 list
set seg_t8b [make_temp_segment]
write_profile $seg_t8b "t8-both-sent"
write_approach_yaml $seg_t8b "t8-both-sent" {decisions:
  channel: linkedin_then_email
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    body: Hi, I would like to connect
    actioned_date: 2026-04-01
    replied_date: null
  - channel: email
    to: test@acme-venues.au
    subject: Following up
    body: Hello there
    actioned_date: 2026-04-03
    replied_date: null
}
write_roster_tsv $seg_t8b $::std_headers [list \
    [make_base_row {contact_name "Both Sent" email "both@acme-venues.au" \
        linkedin_url "https://linkedin.com/in/both" \
        stem "t8-both-sent" star_rating "4"}] \
]

set ct8b [$State refine_segment [$State classify_segment $seg_t8b]]
set t8b_results [$State transition_eligible $ct8b "T8"]
set t8b_names [lmap c $t8b_results {dict get $c contact_name}]
assert_eq [expr {"Both Sent" in $t8b_names}] 0 \
    "T8: email_sent=1 → not eligible for T8"

# 10c. T7: EXCLUDED contact with email_sent=1 → not eligible for T7 monitoring
set seg_t7_inv [make_temp_segment]
write_profile $seg_t7_inv "t7-invalidated"
write_approach_yaml $seg_t7_inv "t7-invalidated" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: sent-then-invalid@acme-venues.au
    subject: Sent before invalidation
    body: Hello
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg_t7_inv $::std_headers [list \
    [make_base_row {contact_name "Sent Then Invalid" email "sti@acme-venues.au" \
        stem "t7-invalidated" star_rating "4" date_excluded "2026-04-05"}] \
]
set ct7_inv [$State refine_segment [$State classify_segment $seg_t7_inv]]
set t7_inv_results [$State transition_eligible $ct7_inv "T7"]
assert_eq [llength $t7_inv_results] 0 \
    "T7: EXCLUDED contact with email_sent=1 → not eligible"

# 10d. T8: EXCLUDED contact with linkedin_sent=1 → not eligible for T8
set seg_t8_inv [make_temp_segment]
write_profile $seg_t8_inv "t8-invalidated"
write_approach_yaml $seg_t8_inv "t8-invalidated" [approach_yaml_final_multi_channel]
write_roster_tsv $seg_t8_inv $::std_headers [list \
    [make_base_row {contact_name "LI Sent Then Invalid" email "lsti@acme-venues.au" \
        linkedin_url "https://linkedin.com/in/lsti" \
        stem "t8-invalidated" star_rating "4" date_excluded "2026-04-05"}] \
]
set ct8_inv [$State refine_segment [$State classify_segment $seg_t8_inv]]
set t8_inv_results [$State transition_eligible $ct8_inv "T8"]
assert_eq [llength $t8_inv_results] 0 \
    "T8: EXCLUDED contact with linkedin_sent=1 → not eligible"

# ════════════════════════════════════════════════════════════════════════
# 15. T3/T4 zero tasks (PROFILE_STALE undefined)
# ════════════════════════════════════════════════════════════════════════
section "15. T3/T4 routing (#63)"

# Baseline: a healthy mix (DISCOVERED, PROFILED, APPROACHED, SENT) yields
# zero T3 and zero T4 tasks — re-profile/re-approach only fire on staleness.
set seg_t34 [make_temp_segment]
write_profile $seg_t34 "t34-profiled"
write_profile $seg_t34 "t34-approached"
write_approach_yaml $seg_t34 "t34-approached" [approach_yaml_final_unsent]
write_profile $seg_t34 "t34-sent"
write_approach_yaml $seg_t34 "t34-sent" [approach_yaml_final_sent_email]
write_roster_tsv $seg_t34 $::std_headers [list \
    [make_base_row {contact_name "Disco" stem ""}] \
    [make_base_row {contact_name "Prof" stem "t34-profiled"}] \
    [make_base_row {contact_name "App" stem "t34-approached"}] \
    [make_base_row {contact_name "Sent" stem "t34-sent"}] \
]
set ct34 [$State classify_segment $seg_t34]

set t3_results [$State transition_eligible $ct34 "T3"]
assert_eq [llength $t3_results] 0 "T3: zero tasks when no contact is PROFILE_STALE"

set t4_results [$State transition_eligible $ct34 "T4"]
assert_eq [llength $t4_results] 0 "T4: zero tasks when no contact is APPROACH_STALE"

# T3: missing-profile-with-approach lands in PROFILE_STALE → 1 T3 task.
set seg_t3 [make_temp_segment]
write_approach_yaml $seg_t3 "needs-reprofile" [approach_yaml_final_unsent]
write_roster_tsv $seg_t3 $::std_headers [list \
    [make_base_row {contact_name "Needs Reprofile" star_rating 4 stem "needs-reprofile"}] \
]
set ct3 [$State classify_segment $seg_t3]
set t3_ready [$State transition_eligible $ct3 "T3"]
assert_eq [llength $t3_ready] 1 \
    "T3: approach references missing profile → 1 ready task"

# T4: APPROACH_STALE (hash mismatch) → 1 T4 task; T2 still sees zero.
set seg_t4 [make_temp_segment]
write_profile $seg_t4 "hash-stale"
write_approach_yaml $seg_t4 "hash-stale" {profile_hash: sha256:0000000000000000000000000000000000000000000000000000000000000000
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_t4 $::std_headers [list \
    [make_base_row {contact_name "Hash Stale" star_rating 4 email "test@acme-venues.au" stem "hash-stale"}] \
]
set ct4 [$State classify_segment $seg_t4]
# Use the campaign-aware form so the dispatch gate (in_scope_channel) accepts it.
set t4_cdata [dict create primary_channel email]
set t4_ready [$State transition_eligible $ct4 "T4" email $t4_cdata 2026-04-15]
assert_eq [llength $t4_ready] 1 \
    "T4: APPROACH_STALE → 1 ready task (#63)"
set t2_zero [$State transition_eligible $ct4 "T2" email $t4_cdata 2026-04-15]
assert_eq [llength $t2_zero] 0 \
    "T2: APPROACH_STALE not eligible for T2 (T4's territory)"

# ════════════════════════════════════════════════════════════════════════
# 16. progress_counts edge cases
# ════════════════════════════════════════════════════════════════════════
section "16. progress_counts edge cases"

# 16a. Empty segment (headers only, no data rows) → all counts = 0
set seg_empty [make_temp_segment]
write_roster_tsv $seg_empty $::std_headers [list]
set c_empty [$State classify_segment $seg_empty]
set counts_empty [spar::progress_counts $c_empty]
assert_eq [dict get $counts_empty valid] 0 "empty segment: valid=0"
assert_eq [dict get $counts_empty profiled] 0 "empty segment: profiled=0"
assert_eq [dict get $counts_empty star3] 0 "empty segment: star3=0"
assert_eq [dict get $counts_empty approached_star3] 0 "empty segment: approached_star3=0"
assert_eq [dict get $counts_empty sent] 0 "empty segment: sent=0"
assert_eq [dict get $counts_empty replied] 0 "empty segment: replied=0"

# 16b. All EXCLUDED contacts → valid=0, all other counts=0
set seg_inv [make_temp_segment]
write_roster_tsv $seg_inv $::std_headers [list \
    [make_base_row {contact_name "Inv A" date_excluded "2026-01-01" stem ""}] \
    [make_base_row {contact_name "Inv B" date_excluded "2026-02-01" stem ""}] \
]
set c_inv [$State classify_segment $seg_inv]
set counts_inv [spar::progress_counts $c_inv]
assert_eq [dict get $counts_inv valid] 0 "all invalid: valid=0"
assert_eq [dict get $counts_inv profiled] 0 "all invalid: profiled=0"
assert_eq [dict get $counts_inv star3] 0 "all invalid: star3=0"

# 16c. Contact with star_rating=2 → counted in valid and profiled but NOT star3
set seg_lo [make_temp_segment]
write_profile $seg_lo "lo-star"
write_roster_tsv $seg_lo $::std_headers [list \
    [make_base_row {contact_name "Lo Star" stem "lo-star" star_rating "2" email "lo@acme-venues.au"}] \
]
set c_lo [$State classify_segment $seg_lo]
set counts_lo [spar::progress_counts $c_lo]
assert_eq [dict get $counts_lo valid] 1 "star=2: valid=1"
assert_eq [dict get $counts_lo profiled] 1 "star=2: profiled=1"
assert_eq [dict get $counts_lo star3] 0 "star=2: star3=0"
assert_eq [dict get $counts_lo approached_star3] 0 "star=2: approached_star3=0"

# ════════════════════════════════════════════════════════════════════════
# ════════════════════════════════════════════════════════════════════════
# 13. Blank contact_name — P-phase lead
# ════════════════════════════════════════════════════════════════════════
section "Blank contact_name"

# 13a. contact_name empty, date_excluded empty → DISCOVERED (no profile yet)
set seg_n1 [make_temp_segment]
write_roster_tsv $seg_n1 $::std_headers [list \
    [make_base_row {contact_name "" stem "acme-tours" \
        organisation_name "Acme Tours" phone "07 5555 1234" \
        email "info@acmetours.com" date_excluded ""}] \
]
set cn1 [$State classify_segment $seg_n1]
assert_eq [llength $cn1] 1 "blank-name: segment includes row"
assert_eq [dict get [lindex $cn1 0] state] "DISCOVERED" "blank-name: contact_name empty + no profile → DISCOVERED"

# 13b. contact_name empty, date_excluded set → EXCLUDED
set seg_n2 [make_temp_segment]
write_roster_tsv $seg_n2 $::std_headers [list \
    [make_base_row {contact_name "" stem "defunct-co" \
        date_excluded "2026-04-07"}] \
]
set cn2 [$State classify_segment $seg_n2]
assert_eq [llength $cn2] 1 "blank-name excluded: segment includes row"
assert_eq [dict get [lindex $cn2 0] state] "EXCLUDED" "blank-name + date_excluded → EXCLUDED"

# 13c. progress_counts includes blank-name DISCOVERED row in Valid
set seg_n3 [make_temp_segment]
write_roster_tsv $seg_n3 $::std_headers [list \
    [make_base_row {contact_name "Named Contact" stem "named-contact"}] \
    [make_base_row {contact_name "" stem "nameless-org" \
        organisation_name "Nameless Org" date_excluded ""}] \
]
set cn3 [$State classify_segment $seg_n3]
assert_eq [llength $cn3] 2 "blank-name progress: segment has 2 rows"
set pc3 [spar::progress_counts $cn3]
assert_eq [dict get $pc3 valid] 2 "blank-name progress: Valid counts blank-name rows"

# ════════════════════════════════════════════════════════════════════════
section "21. validate_roster — roster quality-checklist assertions"
# ════════════════════════════════════════════════════════════════════════

# Full headers matching the real roster format for validate_roster tests
set ::vr_headers {
    stem contact_name organisation role phone email linkedin_url facebook_url
    sweep_iteration discovered_via date_excluded
    s_note p_note star_rating
}

proc make_vr_row {{overrides {}}} {
    set row [dict create \
        stem              "test-contact-test-org" \
        contact_name      "Test Contact" \
        organisation      "Test Org" \
        role              "Manager" \
        phone             "" \
        email             "test@acme-venues.au" \
        linkedin_url      "" \
        facebook_url      "" \
        sweep_iteration   "1" \
        discovered_via    "" \
        date_excluded "" \
        s_note            "" \
        p_note            "" \
        star_rating       "3" \
    ]
    dict for {k v} $overrides {
        dict set row $k $v
    }
    return $row
}

# Helper: classify a segment and run validate_roster, return issues
proc vr_issues {segment_dir} {
    global State
    set contacts [$State classify_segment $segment_dir]
    return [spar::validate_roster $contacts]
}


# ── Assertion 1: placeholder contact_name ──
set seg_vr1 [make_temp_segment]
write_roster_tsv $seg_vr1 $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Unknown" email a@b.com}] \
    [make_vr_row {stem s2 contact_name "Test Real" email c@d.com}] \
]
set issues_vr1 [vr_issues $seg_vr1]
assert_eq [has_issue $issues_vr1 roster_placeholder_name] 1 \
    "A1: placeholder contact_name 'Unknown' flagged"

# ── Assertion 3: duplicate (contact_name, organisation) pair ──
set seg_vr3 [make_temp_segment]
write_roster_tsv $seg_vr3 $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Jane Doe" organisation "Acme" email a@b.com}] \
    [make_vr_row {stem s2 contact_name "Jane Doe" organisation "Acme" email c@d.com}] \
]
set issues_vr3 [vr_issues $seg_vr3]
assert_eq [has_issue $issues_vr3 roster_duplicate_name_org] 1 \
    "A3: duplicate (name, org) pair flagged"

# ── Assertion 4: no channel ──
set seg_vr4 [make_temp_segment]
write_roster_tsv $seg_vr4 $::vr_headers [list \
    [make_vr_row {stem s1 email "" linkedin_url "" facebook_url ""}] \
]
set issues_vr4 [vr_issues $seg_vr4]
assert_eq [has_issue $issues_vr4 roster_no_channel] 1 \
    "A4: contact with no email/linkedin/facebook flagged"

# ── Assertion 5: missing sweep_iteration ──
set seg_vr5 [make_temp_segment]
write_roster_tsv $seg_vr5 $::vr_headers [list \
    [make_vr_row {stem s1 sweep_iteration ""}] \
]
set issues_vr5 [vr_issues $seg_vr5]
assert_eq [has_issue $issues_vr5 roster_no_sweep_iteration] 1 \
    "A5: missing sweep_iteration flagged"

# ── Assertion 1 (cont.): blank contact_name with organisation is allowed ──
set seg_vr1b [make_temp_segment]
write_roster_tsv $seg_vr1b $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "" organisation "Known Org" email a@b.com}] \
]
set issues_vr1b [vr_issues $seg_vr1b]
assert_eq [has_issue $issues_vr1b roster_placeholder_name] 0 \
    "A1b: blank contact_name + non-empty organisation exempt (P §4.1 case)"

# ── Assertion 8: star_rating=0 without date_excluded ──
set seg_vr8 [make_temp_segment]
write_roster_tsv $seg_vr8 $::vr_headers [list \
    [make_vr_row {stem s1 star_rating 0 date_excluded ""}] \
]
set issues_vr8 [vr_issues $seg_vr8]
assert_eq [has_issue $issues_vr8 roster_zero_star_no_invalid] 1 \
    "A8: star_rating=0 without date_excluded flagged"

# ── Assertion 9: empty stem ──
set seg_vr9 [make_temp_segment]
write_roster_tsv $seg_vr9 $::vr_headers [list \
    [make_vr_row {stem ""}] \
]
set issues_vr9 [vr_issues $seg_vr9]
assert_eq [has_issue $issues_vr9 roster_empty_stem] 1 \
    "A9: empty stem flagged as error"

# ── Assertion 10: duplicate stems ──
set seg_vr10 [make_temp_segment]
write_roster_tsv $seg_vr10 $::vr_headers [list \
    [make_vr_row {stem same-stem contact_name "Alice" email a@b.com}] \
    [make_vr_row {stem same-stem contact_name "Bob" email c@d.com}] \
]
set issues_vr10 [vr_issues $seg_vr10]
assert_eq [has_issue $issues_vr10 roster_duplicate_stem] 1 \
    "A10: duplicate stems flagged as error"

# ── Assertion 2: truncated row (hard error in load_roster) ──
set seg_vr2 [make_temp_segment]
set vr2_path [file join $seg_vr2 roster.tsv]
set fd [open $vr2_path w]
puts $fd [join $::vr_headers \t]
# Write a truncated row (only 3 fields instead of 20)
puts $fd "short-stem\tShort Name\tShort Org"
close $fd
assert_error {spar::load_roster $vr2_path} "*truncated row*" \
    "A2: truncated row causes hard error in load_roster"

# ── Negative test: clean roster has no validate_roster issues ──
set seg_vr_clean [make_temp_segment]
write_roster_tsv $seg_vr_clean $::vr_headers [list \
    [make_vr_row {stem a1 contact_name "Alice" email a@b.com sweep_iteration 1}] \
    [make_vr_row {stem b2 contact_name "Bob" email c@d.com sweep_iteration 1}] \
]
set issues_vr_clean [vr_issues $seg_vr_clean]
assert_eq [llength $issues_vr_clean] 0 \
    "Clean roster: no validate_roster issues"

# ── Helper: find first issue with given code, return its severity/category ──
proc issue_severity {issues code} {
    foreach i $issues {
        if {[dict get $i code] eq $code} { return [dict get $i severity] }
    }
    return ""
}
proc issue_category {issues code} {
    foreach i $issues {
        if {[dict get $i code] eq $code} {
            if {[dict exists $i category]} { return [dict get $i category] }
            return ""
        }
    }
    return ""
}
proc count_issues {issues code} {
    set n 0
    foreach i $issues {
        if {[dict get $i code] eq $code} { incr n }
    }
    return $n
}

# ── case_1 (issue #5): roster_duplicate_name_org is now error severity ──
set seg_c1 [make_temp_segment]
write_roster_tsv $seg_c1 $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Jane Doe" organisation "Acme" email a@b.com}] \
    [make_vr_row {stem s2 contact_name "Jane Doe" organisation "Acme" email c@d.com}] \
]
set issues_c1 [vr_issues $seg_c1]
assert_eq [issue_severity $issues_c1 roster_duplicate_name_org] "error" \
    "case_1: roster_duplicate_name_org promoted to error severity"
assert_eq [issue_category $issues_c1 roster_duplicate_name_org] "case_1" \
    "case_1: roster_duplicate_name_org carries category=case_1"

# ── case_2 (issue #5): shared org inbox, different contacts ──
set seg_c2 [make_temp_segment]
write_roster_tsv $seg_c2 $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Mike Carlson" organisation "Pony Club Queensland" email "admin@ponyclubqld.com.au"}] \
    [make_vr_row {stem s2 contact_name "Sarah Standen" organisation "Pony Club Queensland" email "admin@ponyclubqld.com.au"}] \
]
set issues_c2 [vr_issues $seg_c2]
assert_eq [has_issue $issues_c2 roster_shared_inbox_collision] 1 \
    "case_2: shared-inbox collision flagged"
assert_eq [issue_severity $issues_c2 roster_shared_inbox_collision] "error" \
    "case_2: roster_shared_inbox_collision is error severity"
assert_eq [issue_category $issues_c2 roster_shared_inbox_collision] "case_2" \
    "case_2: carries category=case_2"
assert_eq [count_issues $issues_c2 roster_shared_inbox_collision] 2 \
    "case_2: fires for both colliding rows"

# ── case_3 (issue #5): same person, different organisations, shared personal email ──
set seg_c3 [make_temp_segment]
write_roster_tsv $seg_c3 $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Colin Batt" organisation "Rotary Club of Nerang" email "revcolinbatt@gmail.com"}] \
    [make_vr_row {stem s2 contact_name "Colin Batt" organisation "Nerang Uniting Church" email "revcolinbatt@gmail.com"}] \
]
set issues_c3 [vr_issues $seg_c3]
assert_eq [has_issue $issues_c3 roster_personal_email_reused] 1 \
    "case_3: personal email reuse flagged"
assert_eq [issue_severity $issues_c3 roster_personal_email_reused] "warning" \
    "case_3: roster_personal_email_reused is warning severity"
assert_eq [issue_category $issues_c3 roster_personal_email_reused] "case_3" \
    "case_3: carries category=case_3"
# case_3 must not masquerade as case_2
assert_eq [has_issue $issues_c3 roster_shared_inbox_collision] 0 \
    "case_3: does not trigger case_2 when orgs differ"

# ── Negative: single email, single row → no email-collision codes ──
set seg_cn [make_temp_segment]
write_roster_tsv $seg_cn $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Alice" organisation "Acme" email "a@b.com"}] \
    [make_vr_row {stem s2 contact_name "Bob" organisation "Beeco" email "c@d.com"}] \
]
set issues_cn [vr_issues $seg_cn]
assert_eq [has_issue $issues_cn roster_shared_inbox_collision] 0 \
    "negative: distinct emails do not trigger case_2"
assert_eq [has_issue $issues_cn roster_personal_email_reused] 0 \
    "negative: distinct emails do not trigger case_3"

# ── Negative: EXCLUDED rows are skipped ──
set seg_cx [make_temp_segment]
write_roster_tsv $seg_cx $::vr_headers [list \
    [make_vr_row {stem s1 contact_name "Mike" organisation "Acme" email "admin@acme.com" date_excluded "2026-04-01"}] \
    [make_vr_row {stem s2 contact_name "Sarah" organisation "Acme" email "admin@acme.com"}] \
]
set issues_cx [vr_issues $seg_cx]
assert_eq [has_issue $issues_cx roster_shared_inbox_collision] 0 \
    "EXCLUDED rows do not participate in case_2"

# ════════════════════════════════════════════════════════════════════════
section "22. validate_approach — structural validation (rules/approach.rules)"
# ════════════════════════════════════════════════════════════════════════

# Helper: write YAML content to a temp file and call validate_approach
proc va_issues {yaml_content {roster_email "test@acme-venues.au"} {contact_name "Test"}} {
    set path [file tempfile tmpf ".yaml"]
    set fd [open $path w]
    puts $fd $yaml_content
    close $fd
    set result [spar::validate_approach $path $roster_email $contact_name]
    file delete $path
    return $result
}

# ── invalid_yaml: unparseable file ──
set issues_inv [va_issues "- \[unclosed"]
assert_eq [has_issue $issues_inv invalid_yaml] 1 \
    "invalid_yaml: unparseable YAML flagged"

# ── missing_decisions: no decisions key ──
set issues_md [va_issues {
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
}]
assert_eq [has_issue $issues_md missing_decisions] 1 \
    "missing_decisions: absent decisions key flagged"

# ── missing_rounds: no rounds key ──
set issues_mr [va_issues {
decisions:
  channel: email
}]
assert_eq [has_issue $issues_mr missing_rounds] 1 \
    "missing_rounds: absent rounds key flagged"

# ── no_final_round: rounds exist but none is type: final ──
set issues_nf [va_issues {
decisions: {}
rounds:
  - type: draft
    number: 1
    messages:
      - channel: email
        subject: Draft
        body: Draft body
}]
assert_eq [has_issue $issues_nf no_final_round] 1 \
    "no_final_round: no round with type=final flagged"

# ── draft_missing_number: draft round without number field ──
set issues_dn [va_issues {
decisions: {}
rounds:
  - type: draft
    messages:
      - channel: email
        subject: Draft
        body: Draft body
  - type: final
    messages:
      - channel: email
        subject: Final
        body: Final body
        to: test@acme-venues.au
}]
assert_eq [has_issue $issues_dn draft_missing_number] 1 \
    "draft_missing_number: draft round without number flagged"

# ── review_missing_number: review round without number field ──
set issues_rn [va_issues {
decisions: {}
rounds:
  - type: review
    messages:
      - channel: email
        subject: Review
        body: Review body
  - type: final
    messages:
      - channel: email
        subject: Final
        body: Final body
        to: test@acme-venues.au
}]
assert_eq [has_issue $issues_rn review_missing_number] 1 \
    "review_missing_number: review round without number flagged"

# ── email_missing_content: email message with neither subject nor body ──
set issues_ec [va_issues {
decisions: {}
rounds:
  - type: final
    messages:
      - channel: email
        to: test@acme-venues.au
}]
assert_eq [has_issue $issues_ec email_missing_content] 1 \
    "email_missing_content: email without subject or body flagged"

# ── too_many_final_emails: final round with 2 email messages rejected ──
set issues_tme [va_issues {
decisions: {}
rounds:
  - type: final
    messages:
      - channel: email
        to: a@acme-venues.au
        subject: First
        body: One
      - channel: email
        to: b@acme-venues.au
        subject: Second
        body: Two
}]
assert_eq [has_issue $issues_tme too_many_final_emails] 1 \
    "too_many_final_emails: two emails in final flagged"

# ── Negative: zero emails in final (e.g. phone-only) passes cap check ──
set issues_zf [va_issues {
decisions:
  channel: phone
rounds:
  - type: final
    messages:
      - channel: phone
        to: "+61-400-000-000"
        text: Call script.
}]
assert_eq [has_issue $issues_zf too_many_final_emails] 0 \
    "too_many_final_emails: zero-email final not flagged"

# ── Negative: one email + one phone in final (mixed-channel) passes cap check ──
set issues_mf [va_issues {
decisions:
  channel: email
rounds:
  - type: final
    messages:
      - channel: email
        to: test@acme-venues.au
        subject: Final
        body: Body
      - channel: phone
        to: "+61-400-000-000"
        text: Call script.
}]
assert_eq [has_issue $issues_mf too_many_final_emails] 0 \
    "too_many_final_emails: one email + one phone not flagged"

# ── Negative test: valid approach has no structural issues ──
set issues_valid [va_issues {
decisions:
  channel: email
rounds:
  - type: draft
    number: 1
    messages:
      - channel: email
        subject: Draft subject
        body: Draft body
  - type: final
    messages:
      - channel: email
        subject: Final subject
        body: Final body
        to: test@acme-venues.au
}]
assert_eq [llength $issues_valid] 0 \
    "Valid approach: no structural issues"

# ════════════════════════════════════════════════════════════════════════
section "23. validate_approach — closed vocabulary (issue #43)"
# ════════════════════════════════════════════════════════════════════════

# ── unknown_key_root: invented top-level key rejected ──
set issues_ur [va_issues {
decisions: {}
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
        to: test@acme-venues.au
discovery:
  catchment: Sydney
}]
assert_eq [has_issue $issues_ur unknown_key_root] 1 \
    "unknown_key_root: invented key 'discovery' at root flagged"

# ── unknown_key_decisions: minority spelling 'channel_note' rejected ──
set issues_ud [va_issues {
decisions:
  channel: email
  channel_note: secondary
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
        to: test@acme-venues.au
}]
assert_eq [has_issue $issues_ud unknown_key_decisions] 1 \
    "unknown_key_decisions: 'channel_note' in decisions flagged"

# ── wrong_level: chosen_usps at root should be per-round ──
set issues_wl [va_issues {
decisions: {}
chosen_usps:
  - First USP
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
        to: test@acme-venues.au
}]
assert_eq [has_issue $issues_wl wrong_level] 1 \
    "wrong_level: chosen_usps at root points to round level"

# ── wrong_level at message: 'note' is canonical at fact_check_item, not message ──
set issues_wm [va_issues {
decisions: {}
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
        to: test@acme-venues.au
        note: Remember to follow up
}]
assert_eq [has_issue $issues_wm wrong_level] 1 \
    "wrong_level: 'note' in message points to fact_check_item"

# ── unknown_key_message: a key not canonical anywhere is rejected as unknown ──
set issues_um [va_issues {
decisions: {}
rounds:
  - type: final
    messages:
      - channel: email
        subject: Hi
        body: Hello
        to: test@acme-venues.au
        invented_field: nonsense
}]
assert_eq [has_issue $issues_um unknown_key_message] 1 \
    "unknown_key_message: 'invented_field' in message flagged"

# ── Negative test: valid closed-vocabulary file produces no vocab issues ──
set issues_ok [va_issues {
decisions:
  channel: email
rounds:
  - type: draft
    number: 1
    chosen_usps:
      - point one
    messages:
      - channel: email
        subject: Draft subject
        body: Draft body
        director_note: internal
  - type: final
    messages:
      - channel: email
        subject: Final subject
        body: Final body
        to: test@acme-venues.au
fact_provenance:
  - claim: Example
    source: URL
}]
assert_eq [has_issue $issues_ok unknown_key_root] 0 \
    "closed vocab: clean file has no unknown_key_root"
assert_eq [has_issue $issues_ok wrong_level] 0 \
    "closed vocab: clean file has no wrong_level"


finish_tests

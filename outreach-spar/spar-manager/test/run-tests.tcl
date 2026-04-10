#!/usr/bin/env tclsh
# run-tests.tcl — Test suite for spar-state.tcl (SPAR campaign state machine)
#
# Run:  tclsh test/run-tests.tcl
# Exit: 0 on all pass, 1 on any failure.

package require yaml

# ── Source the library under test ────────────────────────────────────────
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]

# ── Minimal test framework ──────────────────────────────────────────────
set ::passes   0
set ::failures 0
set ::errors   0
set ::cleanup_dirs {}

proc assert_eq {actual expected label} {
    if {$actual ne $expected} {
        puts "FAIL: $label"
        puts "  expected: $expected"
        puts "  actual:   $actual"
        incr ::failures
    } else {
        puts "  ok: $label"
        incr ::passes
    }
}

proc assert_match {actual pattern label} {
    if {![string match $pattern $actual]} {
        puts "FAIL: $label"
        puts "  pattern:  $pattern"
        puts "  actual:   $actual"
        incr ::failures
    } else {
        puts "  ok: $label"
        incr ::passes
    }
}

proc assert_error {script pattern label} {
    set code [catch {uplevel 1 $script} msg]
    if {$code == 0} {
        puts "FAIL: $label"
        puts "  expected error matching: $pattern"
        puts "  got no error"
        incr ::failures
    } elseif {![string match $pattern $msg]} {
        puts "FAIL: $label"
        puts "  expected error matching: $pattern"
        puts "  actual error:  $msg"
        incr ::failures
    } else {
        puts "  ok: $label"
        incr ::passes
    }
}

proc section {title} {
    puts ""
    puts "── $title ──"
}

# ── Helpers: temporary segment directories ──────────────────────────────

# make_temp_segment -- create a temp directory mimicking a segment.
# Returns the path.  Caller is responsible for cleanup (or use register_cleanup).
proc make_temp_segment {} {
    set base [file join /tmp "spar-test-[pid]-[clock microseconds]"]
    file mkdir $base
    file mkdir [file join $base profiles]
    file mkdir [file join $base approach]
    lappend ::cleanup_dirs $base
    return $base
}

# write_roster_tsv -- write a roster.tsv from a list of dicts.
# headers is a list of column names.  rows is a list of dicts (missing keys → "").
proc write_roster_tsv {segment_dir headers rows} {
    set path [file join $segment_dir roster.tsv]
    set fd [open $path w]
    puts $fd [join $headers \t]
    foreach row $rows {
        set fields {}
        foreach h $headers {
            if {[dict exists $row $h]} {
                lappend fields [dict get $row $h]
            } else {
                lappend fields ""
            }
        }
        puts $fd [join $fields \t]
    }
    close $fd
    return $path
}

# write_profile -- create a minimal profile .md file.
proc write_profile {segment_dir stem} {
    set path [file join $segment_dir profiles "profile-${stem}.md"]
    set fd [open $path w]
    puts $fd "# Profile: $stem"
    puts $fd "Richness: Thin"
    close $fd
    return $path
}

# write_approach_yaml -- create an approach YAML file from plain text.
# content is the raw YAML string.
proc write_approach_yaml {segment_dir stem content} {
    set path [file join $segment_dir approach "${stem}.yaml"]
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
    return $path
}

# Standard roster headers for most tests.
set ::std_headers {
    contact_name organisation_name email linkedin_url facebook_url phone
    star_rating date_found_invalid stem
}

# make_base_row -- return a dict with default valid values.
proc make_base_row {{overrides {}}} {
    set row [dict create \
        contact_name    "Test Contact" \
        organisation_name "Test Org" \
        email           "test@example.com" \
        linkedin_url    "" \
        facebook_url    "" \
        phone           "" \
        star_rating     "3" \
        date_found_invalid "" \
        stem            "" \
    ]
    dict for {k v} $overrides {
        dict set row $k $v
    }
    return $row
}

# Approach YAML templates
proc approach_yaml_no_final {} {
    return {decisions:
  channel: email
rounds:
- type: draft
  number: 1
  messages:
  - channel: email
    subject: Draft subject
    body: Draft body
}
}

proc approach_yaml_final_unsent {} {
    return {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@example.com
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
}

proc approach_yaml_final_sent_email {} {
    return {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@example.com
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: null
}
}

proc approach_yaml_final_replied {} {
    return {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@example.com
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: 2026-04-05
}
}

proc approach_yaml_final_reply_received {} {
    return {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@example.com
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: null
  replies:
  - direction: received
    date: 2026-04-05
    from: test@example.com
}
}

proc approach_yaml_final_sent_linkedin {} {
    return {decisions:
  channel: linkedin
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    body: Hi, I would like to connect
    actioned_date: 2026-04-01
    replied_date: null
}
}

proc approach_yaml_final_multi_channel {} {
    return {decisions:
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
    to: test@example.com
    subject: Following up
    body: Hello there
    actioned_date: null
    replied_date: null
}
}

# cleanup_temps -- remove all registered temporary directories.
proc cleanup_temps {} {
    foreach dir $::cleanup_dirs {
        if {[file isdirectory $dir]} {
            file delete -force $dir
        }
    }
    set ::cleanup_dirs {}
}

# ════════════════════════════════════════════════════════════════════════
# 1. Primary state classification
# ════════════════════════════════════════════════════════════════════════
section "1. Primary state classification"

# 1a. date_found_invalid set → INVALID
set seg [make_temp_segment]
set row [make_base_row {date_found_invalid "2026-01-15"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "INVALID" "date_found_invalid → INVALID"

# 1b. Valid contact, stem="" → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {stem ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "no profile file → DISCOVERED"

# 1c. Valid contact, stem set, profile file exists → PROFILED
set seg [make_temp_segment]
write_profile $seg "alice-smith-acme"
set row [make_base_row {stem "alice-smith-acme"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "stem + file exists → PROFILED"

# 1d. Valid contact, stem set, profile file MISSING → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {stem "nonexistent-profile"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "stem + file missing → DISCOVERED"

# 1e. Valid, stem set, profile+approach files exist, no final round → APPROACHED
set seg [make_temp_segment]
write_profile $seg "bob-jones-widgets"
write_approach_yaml $seg "bob-jones-widgets" [approach_yaml_no_final]
set row [make_base_row {stem "bob-jones-widgets"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "approach exists, no final round → APPROACHED"

# 1f. Valid, approach with final round but unsent → APPROACHED
set seg [make_temp_segment]
write_profile $seg "carol-lee-bigco"
write_approach_yaml $seg "carol-lee-bigco" [approach_yaml_final_unsent]
set row [make_base_row {stem "carol-lee-bigco"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "final round, no actioned_date → APPROACHED"

# 1g. Valid, approach with final round, actioned_date set → SENT
set seg [make_temp_segment]
write_profile $seg "dave-kim-techcorp"
write_approach_yaml $seg "dave-kim-techcorp" [approach_yaml_final_sent_email]
set row [make_base_row {stem "dave-kim-techcorp"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "SENT" "final round, actioned_date set → SENT"

# 1h. Valid, approach with final round, actioned_date+replied_date set → REPLIED
set seg [make_temp_segment]
write_profile $seg "eve-tanaka-globalinc"
write_approach_yaml $seg "eve-tanaka-globalinc" [approach_yaml_final_replied]
set row [make_base_row {stem "eve-tanaka-globalinc"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "REPLIED" "final round, replied_date set → REPLIED"

# 1i. Valid, approach with final round, reply with direction=received → REPLIED
set seg [make_temp_segment]
write_profile $seg "frank-wu-pacific"
write_approach_yaml $seg "frank-wu-pacific" [approach_yaml_final_reply_received]
set row [make_base_row {stem "frank-wu-pacific"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "REPLIED" "final round, direction=received reply → REPLIED"

# ════════════════════════════════════════════════════════════════════════
# 2. Secondary properties
# ════════════════════════════════════════════════════════════════════════
section "2. Secondary properties"

set seg [make_temp_segment]

# 2a. has_email: email with @ → 1
set row [make_base_row {email "foo@bar.com"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_email] 1 "email foo@bar.com → has_email=1"

# 2b. has_email: empty email → 0
set row [make_base_row {email ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_email] 0 "email empty → has_email=0"

# 2c. has_linkedin
set row [make_base_row {linkedin_url "https://linkedin.com/in/x"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_linkedin] 1 "linkedin_url set → has_linkedin=1"

# 2d. has_linkedin empty
set row [make_base_row {linkedin_url ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_linkedin] 0 "linkedin_url empty → has_linkedin=0"

# 2e. has_phone_only: phone set, no email/linkedin/facebook
set row [make_base_row {phone "0412000000" email "" linkedin_url "" facebook_url ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_phone_only] 1 "phone only → has_phone_only=1"

# 2f. has_phone_only: phone set but email present → 0
set row [make_base_row {phone "0412000000" email "foo@bar.com"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_phone_only] 0 "phone+email → has_phone_only=0"

# 2g. star_rating "5" → star=5
set row [make_base_row {star_rating "5"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result star] 5 "star_rating 5 → star=5"

# 2h. star_rating "" → star=0
set row [make_base_row {star_rating ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result star] 0 "star_rating empty → star=0"

# 2i. star_rating "3" → star=3
set row [make_base_row {star_rating "3"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result star] 3 "star_rating 3 → star=3"

# 2j. has_facebook
set row [make_base_row {facebook_url "https://facebook.com/someone"}]
set result [spar::classify_contact $row $seg]
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
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_sent] 1 "final email actioned → email_sent=1"

# 3b. Approach with final round linkedin message, actioned_date set → linkedin_sent=1
set seg [make_temp_segment]
write_profile $seg "ch-linkedin-sent"
write_approach_yaml $seg "ch-linkedin-sent" [approach_yaml_final_sent_linkedin]
set row [make_base_row {stem "ch-linkedin-sent"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result linkedin_sent] 1 "final linkedin actioned → linkedin_sent=1"

# 3c. email_sent=0 when approach unsent
set seg [make_temp_segment]
write_profile $seg "ch-unsent"
write_approach_yaml $seg "ch-unsent" [approach_yaml_final_unsent]
set row [make_base_row {stem "ch-unsent"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_sent] 0 "final email not actioned → email_sent=0"

# 3d. Approach with final round, replied_date set → email_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-replied"
write_approach_yaml $seg "ch-replied" [approach_yaml_final_replied]
set row [make_base_row {stem "ch-replied"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_replied] 1 "final replied_date → email_replied=1"

# 3e. direction=received → email_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-recv"
write_approach_yaml $seg "ch-recv" [approach_yaml_final_reply_received]
set row [make_base_row {stem "ch-recv"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_replied] 1 "direction=received → email_replied=1"

# 3f. Multi-channel: linkedin sent, email not sent
set seg [make_temp_segment]
write_profile $seg "ch-multi"
write_approach_yaml $seg "ch-multi" [approach_yaml_final_multi_channel]
set row [make_base_row {stem "ch-multi"}]
set result [spar::classify_contact $row $seg]
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
    [make_base_row {contact_name "Invalid Irene" date_found_invalid "2026-01-01" stem ""}] \
    [make_base_row {contact_name "Discovered Dan" stem ""}] \
    [make_base_row {contact_name "Profiled Pat" stem "profiled-one"}] \
    [make_base_row {contact_name "Approached Ann" stem "approached-one"}] \
    [make_base_row {contact_name "Sent Steve" stem "sent-one"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [spar::classify_segment $seg]
assert_eq [llength $contacts] 5 "classify_segment returns 5 contacts"

# Verify each contact's state by name
foreach c $contacts {
    set name [dict get $c contact_name]
    set state [dict get $c state]
    switch -- $name {
        "Invalid Irene"   { assert_eq $state "INVALID"     "segment: $name → INVALID" }
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

assert_error {spar::classify_segment $seg} \
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
    [make_base_row {contact_name "Alice" star_rating "4" email "alice@example.com" stem "p-alice"}] \
    [make_base_row {contact_name "Bob" star_rating "5" email "bob@example.com" stem "p-bob"}] \
    [make_base_row {contact_name "Carol" star_rating "3" email "carol@example.com" stem "p-carol"}] \
    [make_base_row {contact_name "Dave" star_rating "3" email "dave@example.com" stem "p-dave"}] \
    [make_base_row {contact_name "Ed" star_rating "2" email "" stem "" date_found_invalid "2026-01-01"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [spar::classify_segment $seg]
set counts [spar::progress_counts $contacts]

# Ed is INVALID → Valid = 4
assert_eq [dict get $counts valid] 4 "progress: valid=4"
# Alice(PROFILED) + Bob(APPROACHED) + Carol(SENT) + Dave(REPLIED) = 4 profiled-or-above
assert_eq [dict get $counts profiled] 4 "progress: profiled=4"
# star≥3: Alice(4), Bob(5), Carol(3), Dave(3) = 4; Ed is invalid so excluded
assert_eq [dict get $counts star3] 4 "progress: star3=4"
# approached-or-above with star≥3: Bob(APPROACHED,5), Carol(SENT,3), Dave(REPLIED,3) = 3
assert_eq [dict get $counts approached_star3] 3 "progress: approached_star3=3"
# email with star≥3: Alice, Bob, Carol, Dave all have email = 4
assert_eq [dict get $counts has_email] 4 "progress: has_email=4"
# approached+ star≥3 has_email: Bob, Carol, Dave = 3
assert_eq [dict get $counts approached_email] 3 "progress: approached_email=3"
# email_sent: Carol(SENT, email actioned) + Dave(REPLIED, email actioned) = 2
assert_eq [dict get $counts email_sent] 2 "progress: email_sent=2"
# email_replied: Dave = 1
assert_eq [dict get $counts email_replied] 1 "progress: email_replied=1"

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
    [make_base_row {contact_name "Disco Dan" stem "" star_rating "4" email "dan@example.com"}] \
    [make_base_row {contact_name "Prof Hi" stem "t-profiled-hi" star_rating "4" email "hi@example.com"}] \
    [make_base_row {contact_name "Prof Lo" stem "t-profiled-lo" star_rating "2" email "lo@example.com"}] \
    [make_base_row {contact_name "App Email" stem "t-approached-email" star_rating "3" email "app@example.com"}] \
    [make_base_row {contact_name "App NoEmail" stem "t-approached-noemail" star_rating "3" email ""}] \
    [make_base_row {contact_name "Sent Sam" stem "t-sent" star_rating "3" email "sent@example.com"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [spar::classify_segment $seg]

# T1: Sweep → Profile: contact in DISCOVERED → ready
set t1 [spar::transition_eligible $contacts "T1"]
set t1_names [lmap c $t1 {dict get $c contact_name}]
assert_eq [expr {"Disco Dan" in $t1_names}] 1 "T1: DISCOVERED contact is eligible"
assert_eq [expr {"Prof Hi" in $t1_names}] 0 "T1: PROFILED contact not eligible"

# T2: Profile → Approach: PROFILED + star≥3 → ready; star<3 → not in list
set t2 [spar::transition_eligible $contacts "T2"]
set t2_names [lmap c $t2 {dict get $c contact_name}]
assert_eq [expr {"Prof Hi" in $t2_names}] 1 "T2: PROFILED star≥3 is eligible"
assert_eq [expr {"Prof Lo" in $t2_names}] 0 "T2: PROFILED star<3 not eligible"

# T3: Approach → Send: APPROACHED, has_email, not email_sent → ready
# also: SENT + has_email + not email_sent (multi-channel case)
set t3 [spar::transition_eligible $contacts "T3"]
set t3_names [lmap c $t3 {dict get $c contact_name}]
set t3_ready_names {}
set t3_pending {}
foreach c $t3 {
    if {[dict get $c task_state] eq "ready"} {
        lappend t3_ready_names [dict get $c contact_name]
    } else {
        lappend t3_pending [dict get $c contact_name]
    }
}
assert_eq [expr {"App Email" in $t3_ready_names}] 1 "T3: APPROACHED+email → ready"
assert_eq [expr {"App NoEmail" in $t3_pending}] 1 "T3: APPROACHED no email → pending"
assert_eq [expr {"Sent Sam" in $t3_ready_names || "Sent Sam" in $t3_pending}] 0 \
    "T3: SENT+email_sent already → not in T3 list"

# T4: Send → Reply: email_sent, not email_replied → pending (monitoring)
set t4 [spar::transition_eligible $contacts "T4"]
set t4_names [lmap c $t4 {dict get $c contact_name}]
assert_eq [expr {"Sent Sam" in $t4_names}] 1 "T4: SENT+email_sent → in monitoring list"

# ════════════════════════════════════════════════════════════════════════
# 7. Profile path and approach path in result
# ════════════════════════════════════════════════════════════════════════
section "7. Path properties in classify_contact result"

set seg [make_temp_segment]
set pp [write_profile $seg "path-test"]
set ap [write_approach_yaml $seg "path-test" [approach_yaml_final_unsent]]
set row [make_base_row {stem "path-test"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result profile_path] $pp "profile_path points to correct file"
assert_eq [dict get $result approach_path] $ap "approach_path points to correct file"

# Empty paths when stem is empty
set row2 [make_base_row {stem ""}]
set result2 [spar::classify_contact $row2 $seg]
assert_eq [dict get $result2 profile_path] "" "no profile file → profile_path empty"
assert_eq [dict get $result2 approach_path] "" "no profile file → approach_path empty"

# ════════════════════════════════════════════════════════════════════════
# 8. Edge cases
# ════════════════════════════════════════════════════════════════════════
section "8. Edge cases"

# 8a. INVALID takes priority even if stem is set and files exist
set seg [make_temp_segment]
write_profile $seg "invalid-priority"
write_approach_yaml $seg "invalid-priority" [approach_yaml_final_sent_email]
set row [make_base_row {date_found_invalid "2026-03-01" stem "invalid-priority"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "INVALID" "INVALID wins over SENT when date_found_invalid set"

# 8b. profile file exists but no approach file → stays PROFILED
set seg [make_temp_segment]
write_profile $seg "no-approach-file"
set row [make_base_row {stem "no-approach-file"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "profile exists but no approach file → PROFILED"

# 8c. star_rating with non-numeric value → star=0
set seg [make_temp_segment]
set row [make_base_row {star_rating "abc"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result star] 0 "non-numeric star_rating → star=0"

# 8d. email without @ → has_email=0
set seg [make_temp_segment]
set row [make_base_row {email "not-an-email"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result has_email] 0 "email without @ → has_email=0"

# ════════════════════════════════════════════════════════════════════════
# 9. detect_duplicates
# ════════════════════════════════════════════════════════════════════════
section "9. detect_duplicates"

# 9a. duplicate_email: same email in two contacts from different segments → flagged
set seg1 [make_temp_segment]
set seg2 [make_temp_segment]

write_roster_tsv $seg1 $::std_headers [list \
    [make_base_row {contact_name "Alice One" email "shared@example.com" stem ""}] \
]
write_roster_tsv $seg2 $::std_headers [list \
    [make_base_row {contact_name "Alice Two" email "shared@example.com" stem ""}] \
]

set c1 [spar::classify_segment $seg1]
set c2 [spar::classify_segment $seg2]
set all_contacts [concat $c1 $c2]
set dups [spar::detect_duplicates $all_contacts]
assert_eq [expr {[llength [dict get $dups duplicate_email]] > 0}] 1 \
    "duplicate_email: same email in different segments → flagged"

# 9b. duplicate_email: same email in two contacts from the SAME segment → not flagged
set seg3 [make_temp_segment]
write_roster_tsv $seg3 $::std_headers [list \
    [make_base_row {contact_name "Bob One" email "bob@example.com" stem ""}] \
    [make_base_row {contact_name "Bob Two" email "bob@example.com" stem ""}] \
]
set c3 [spar::classify_segment $seg3]
set dups3 [spar::detect_duplicates $c3]
assert_eq [llength [dict get $dups3 duplicate_email]] 0 \
    "duplicate_email: same email within one segment → not flagged"

# 9c. duplicate_email: one contact per email → not flagged
set seg4 [make_temp_segment]
set seg5 [make_temp_segment]
write_roster_tsv $seg4 $::std_headers [list \
    [make_base_row {contact_name "Carol" email "carol@example.com" stem ""}] \
]
write_roster_tsv $seg5 $::std_headers [list \
    [make_base_row {contact_name "Diana" email "diana@example.com" stem ""}] \
]
set c4 [spar::classify_segment $seg4]
set c5 [spar::classify_segment $seg5]
set dups45 [spar::detect_duplicates [concat $c4 $c5]]
assert_eq [llength [dict get $dups45 duplicate_email]] 0 \
    "duplicate_email: unique emails → not flagged"

# 9d. duplicate_name: same normalised name across two different segments → flagged
set seg6 [make_temp_segment]
set seg7 [make_temp_segment]
write_roster_tsv $seg6 $::std_headers [list \
    [make_base_row {contact_name "John Smith" email "john1@example.com" stem ""}] \
]
write_roster_tsv $seg7 $::std_headers [list \
    [make_base_row {contact_name "John Smith" email "john2@example.com" stem ""}] \
]
set c6 [spar::classify_segment $seg6]
set c7 [spar::classify_segment $seg7]
set dups67 [spar::detect_duplicates [concat $c6 $c7]]
assert_eq [expr {[llength [dict get $dups67 duplicate_name]] > 0}] 1 \
    "duplicate_name: same name in different segments → flagged"

# 9e. duplicate_name: same name within one segment → not flagged
set seg8 [make_temp_segment]
write_roster_tsv $seg8 $::std_headers [list \
    [make_base_row {contact_name "Jane Doe" email "jane1@example.com" stem ""}] \
    [make_base_row {contact_name "Jane Doe" email "jane2@example.com" stem ""}] \
]
set c8 [spar::classify_segment $seg8]
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
    to: recipient@example.com
    subject: Hello A
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg9 $::std_headers [list \
    [make_base_row {contact_name "To Dup A" email "a@example.com" stem "dup-to-a"}] \
]

write_profile $seg10 "dup-to-b"
write_approach_yaml $seg10 "dup-to-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: recipient@example.com
    subject: Hello B
    body: Body B
    actioned_date: 2026-04-02
    replied_date: null
}
write_roster_tsv $seg10 $::std_headers [list \
    [make_base_row {contact_name "To Dup B" email "b@example.com" stem "dup-to-b"}] \
]

set c9 [spar::classify_segment $seg9]
set c10 [spar::classify_segment $seg10]
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
    to: unique-a@example.com
    subject: Hello A
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg11 $::std_headers [list \
    [make_base_row {contact_name "Uniq A" email "a@example.com" stem "uniq-to-a"}] \
]

write_profile $seg12 "uniq-to-b"
write_approach_yaml $seg12 "uniq-to-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: unique-b@example.com
    subject: Hello B
    body: Body B
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg12 $::std_headers [list \
    [make_base_row {contact_name "Uniq B" email "b@example.com" stem "uniq-to-b"}] \
]

set c11 [spar::classify_segment $seg11]
set c12 [spar::classify_segment $seg12]
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
    to: x@example.com
    subject: Shared Subject Line
    body: Body A
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg13 $::std_headers [list \
    [make_base_row {contact_name "Subj A" email "sa@example.com" stem "subj-dup-a"}] \
]

write_profile $seg14 "subj-dup-b"
write_approach_yaml $seg14 "subj-dup-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: y@example.com
    subject: Shared Subject Line
    body: Body B
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg14 $::std_headers [list \
    [make_base_row {contact_name "Subj B" email "sb@example.com" stem "subj-dup-b"}] \
]

set c13 [spar::classify_segment $seg13]
set c14 [spar::classify_segment $seg14]
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
    to: x@example.com
    subject: Already Sent Subject
    body: Body A
    actioned_date: 2026-04-01
    replied_date: null
}
write_roster_tsv $seg15 $::std_headers [list \
    [make_base_row {contact_name "Sent Subj A" email "ssa@example.com" stem "subj-sent-a"}] \
]

write_profile $seg16 "subj-sent-b"
write_approach_yaml $seg16 "subj-sent-b" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: y@example.com
    subject: Already Sent Subject
    body: Body B
    actioned_date: 2026-04-02
    replied_date: null
}
write_roster_tsv $seg16 $::std_headers [list \
    [make_base_row {contact_name "Sent Subj B" email "ssb@example.com" stem "subj-sent-b"}] \
]

set c15 [spar::classify_segment $seg15]
set c16 [spar::classify_segment $seg16]
set dups1516 [spar::detect_duplicates [concat $c15 $c16]]
assert_eq [llength [dict get $dups1516 identical_subject]] 0 \
    "identical_subject: sent messages with same subject → not flagged"

# ════════════════════════════════════════════════════════════════════════
# 10. T8 transition eligibility
# ════════════════════════════════════════════════════════════════════════
section "10. T8 transition eligibility"

# 10a. T8: linkedin_sent=1, email_sent=0 → appears in T8 list
set seg_t8 [make_temp_segment]
write_profile $seg_t8 "t8-linkedin-only"
write_approach_yaml $seg_t8 "t8-linkedin-only" [approach_yaml_final_multi_channel]
write_roster_tsv $seg_t8 $::std_headers [list \
    [make_base_row {contact_name "LI Sent" email "li@example.com" \
        linkedin_url "https://linkedin.com/in/li" \
        stem "t8-linkedin-only" star_rating "4"}] \
]

set ct8 [spar::classify_segment $seg_t8]
set t8_results [spar::transition_eligible $ct8 "T8"]
set t8_names [lmap c $t8_results {dict get $c contact_name}]
assert_eq [expr {"LI Sent" in $t8_names}] 1 \
    "T8: linkedin_sent=1, email_sent=0 → eligible"
# Verify task_state is pending
set t8_entry [lindex $t8_results 0]
assert_eq [dict get $t8_entry task_state] "pending" \
    "T8: task_state is pending"

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
    to: test@example.com
    subject: Following up
    body: Hello there
    actioned_date: 2026-04-03
    replied_date: null
}
write_roster_tsv $seg_t8b $::std_headers [list \
    [make_base_row {contact_name "Both Sent" email "both@example.com" \
        linkedin_url "https://linkedin.com/in/both" \
        stem "t8-both-sent" star_rating "4"}] \
]

set ct8b [spar::classify_segment $seg_t8b]
set t8b_results [spar::transition_eligible $ct8b "T8"]
set t8b_names [lmap c $t8b_results {dict get $c contact_name}]
assert_eq [expr {"Both Sent" in $t8b_names}] 0 \
    "T8: email_sent=1 → not eligible for T8"

# ════════════════════════════════════════════════════════════════════════
# 11. validate_campaign
# ════════════════════════════════════════════════════════════════════════
section "11. validate_campaign"

proc issues_with_code {issues code} {
    set result {}
    foreach issue $issues { if {[dict get $issue code] eq $code} { lappend result $issue } }
    return $result
}

# 11a. placeholder_to triggered: approach file with to: PLACEHOLDER → one issue
set seg_v1 [make_temp_segment]
write_profile $seg_v1 "v-placeholder"
write_approach_yaml $seg_v1 "v-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v1 $::std_headers [list \
    [make_base_row {contact_name "Placeholder Pete" email "pete@example.com" \
        stem "v-placeholder"}] \
]
set cv1 [spar::classify_segment $seg_v1]
set issues_v1 [spar::validate_campaign $cv1]
set pt_issues [issues_with_code $issues_v1 placeholder_to]
assert_eq [llength $pt_issues] 1 "placeholder_to: PLACEHOLDER in to: → one issue"

# 11b. placeholder_to not triggered: valid email in to:
set seg_v2 [make_temp_segment]
write_profile $seg_v2 "v-valid-to"
write_approach_yaml $seg_v2 "v-valid-to" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: foo@bar.com
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v2 $::std_headers [list \
    [make_base_row {contact_name "Valid Vic" email "foo@bar.com" \
        stem "v-valid-to"}] \
]
set cv2 [spar::classify_segment $seg_v2]
set issues_v2 [spar::validate_campaign $cv2]
set pt_issues2 [issues_with_code $issues_v2 placeholder_to]
assert_eq [llength $pt_issues2] 0 "placeholder_to: valid email in to: → zero issues"

# 11c. email_desync triggered: roster email differs from approach to:
set seg_v3 [make_temp_segment]
write_profile $seg_v3 "v-desync"
write_approach_yaml $seg_v3 "v-desync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: alice@old.com
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v3 $::std_headers [list \
    [make_base_row {contact_name "Desync Alice" email "alice@new.com" \
        stem "v-desync"}] \
]
set cv3 [spar::classify_segment $seg_v3]
set issues_v3 [spar::validate_campaign $cv3]
set ed_issues [issues_with_code $issues_v3 email_desync]
assert_eq [llength $ed_issues] 1 "email_desync: roster email differs from approach to: → one issue"

# 11d. email_desync not triggered: roster email matches approach to: (case-insensitive)
set seg_v4 [make_temp_segment]
write_profile $seg_v4 "v-sync"
write_approach_yaml $seg_v4 "v-sync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: Bob@Example.COM
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v4 $::std_headers [list \
    [make_base_row {contact_name "Sync Bob" email "bob@example.com" \
        stem "v-sync"}] \
]
set cv4 [spar::classify_segment $seg_v4]
set issues_v4 [spar::validate_campaign $cv4]
set ed_issues2 [issues_with_code $issues_v4 email_desync]
assert_eq [llength $ed_issues2] 0 "email_desync: matching emails (case-insensitive) → zero issues"

# 11e. merged_contact_name triggered: contact_name contains ' & '
set seg_v5 [make_temp_segment]
write_roster_tsv $seg_v5 $::std_headers [list \
    [make_base_row {contact_name "Anthony O'Flynn & Nina Hansen" \
        stem ""}] \
]
set cv5 [spar::classify_segment $seg_v5]
set issues_v5 [spar::validate_campaign $cv5]
set mc_issues [issues_with_code $issues_v5 merged_contact_name]
assert_eq [llength $mc_issues] 1 "merged_contact_name: name with ' & ' → one issue"

# 11f. merged_contact_name not triggered: normal contact_name
set seg_v6 [make_temp_segment]
write_roster_tsv $seg_v6 $::std_headers [list \
    [make_base_row {contact_name "Normal Name" \
        stem ""}] \
]
set cv6 [spar::classify_segment $seg_v6]
set issues_v6 [spar::validate_campaign $cv6]
set mc_issues2 [issues_with_code $issues_v6 merged_contact_name]
assert_eq [llength $mc_issues2] 0 "merged_contact_name: normal name → zero issues"

# 11g. orphan_profile triggered: .md file in profiles/ not referenced by roster
set seg_v7 [make_temp_segment]
write_profile $seg_v7 "referenced-profile"
write_profile $seg_v7 "orphan-profile"
write_roster_tsv $seg_v7 $::std_headers [list \
    [make_base_row {contact_name "Ref Contact" \
        stem "referenced-profile"}] \
]
set cv7 [spar::classify_segment $seg_v7]
set issues_v7 [spar::validate_campaign $cv7]
set op_issues [issues_with_code $issues_v7 orphan_profile]
assert_eq [llength $op_issues] 1 "orphan_profile: unreferenced .md file → one issue"

# 11h. orphan_profile not triggered: all .md files referenced
set seg_v8 [make_temp_segment]
write_profile $seg_v8 "used-profile"
write_roster_tsv $seg_v8 $::std_headers [list \
    [make_base_row {contact_name "Used Contact" \
        stem "used-profile"}] \
]
set cv8 [spar::classify_segment $seg_v8]
set issues_v8 [spar::validate_campaign $cv8]
set op_issues2 [issues_with_code $issues_v8 orphan_profile]
assert_eq [llength $op_issues2] 0 "orphan_profile: all .md files referenced → zero issues"

# 11i. orphan_approach triggered: .yaml file in approach/ not referenced by roster
set seg_v9 [make_temp_segment]
write_profile $seg_v9 "ref-approach-contact"
write_approach_yaml $seg_v9 "ref-approach-contact" [approach_yaml_final_unsent]
write_approach_yaml $seg_v9 "orphan-approach" [approach_yaml_final_unsent]
write_roster_tsv $seg_v9 $::std_headers [list \
    [make_base_row {contact_name "Ref Approach" \
        stem "ref-approach-contact"}] \
]
set cv9 [spar::classify_segment $seg_v9]
set issues_v9 [spar::validate_campaign $cv9]
set oa_issues [issues_with_code $issues_v9 orphan_approach]
assert_eq [llength $oa_issues] 1 "orphan_approach: unreferenced .yaml file → one issue"

# 11j. orphan_approach not triggered: all .yaml files referenced
set seg_v10 [make_temp_segment]
write_profile $seg_v10 "used-approach-contact"
write_approach_yaml $seg_v10 "used-approach-contact" [approach_yaml_final_unsent]
write_roster_tsv $seg_v10 $::std_headers [list \
    [make_base_row {contact_name "Used Approach" \
        stem "used-approach-contact"}] \
]
set cv10 [spar::classify_segment $seg_v10]
set issues_v10 [spar::validate_campaign $cv10]
set oa_issues2 [issues_with_code $issues_v10 orphan_approach]
assert_eq [llength $oa_issues2] 0 "orphan_approach: all .yaml files referenced → zero issues"

# ════════════════════════════════════════════════════════════════════════
# 12. validate_approach (per-file guard rail)
# ════════════════════════════════════════════════════════════════════════
section "validate_approach"

# 12a. Valid email in to: field → no errors
set seg_va1 [make_temp_segment]
set va1_path [write_approach_yaml $seg_va1 "va-valid" [approach_yaml_final_unsent]]
set va1_issues [spar::validate_approach $va1_path "test@example.com" "VA Contact"]
assert_eq [llength $va1_issues] 0 "validate_approach: valid email → no issues"

# 12b. Placeholder to: field → placeholder_to error
set seg_va2 [make_temp_segment]
set va2_path [write_approach_yaml $seg_va2 "va-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2_issues [spar::validate_approach $va2_path "real@example.com" "VA Placeholder"]
set va2_errors [issues_with_code $va2_issues placeholder_to]
assert_eq [llength $va2_errors] 1 "validate_approach: placeholder to: → placeholder_to error"
assert_eq [dict get [lindex $va2_errors 0] severity] "error" "validate_approach: placeholder_to severity is error"

# 12c. to: differs from roster email → email_desync warning
set seg_va3 [make_temp_segment]
set va3_path [write_approach_yaml $seg_va3 "va-desync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: wrong@example.com
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va3_issues [spar::validate_approach $va3_path "correct@example.com" "VA Desync"]
set va3_warnings [issues_with_code $va3_issues email_desync]
assert_eq [llength $va3_warnings] 1 "validate_approach: to: differs from roster email → email_desync warning"
assert_eq [dict get [lindex $va3_warnings 0] severity] "warning" "validate_approach: email_desync severity is warning"

# 12d. No final round → no errors
set seg_va4 [make_temp_segment]
set va4_path [write_approach_yaml $seg_va4 "va-nofinal" [approach_yaml_no_final]]
set va4_issues [spar::validate_approach $va4_path "test@example.com" "VA NoFinal"]
assert_eq [llength $va4_issues] 0 "validate_approach: no final round → no issues"

# 12e. Nonexistent file → no errors (graceful)
set va5_issues [spar::validate_approach "/tmp/nonexistent-approach.yaml" "test@example.com" "VA Missing"]
assert_eq [llength $va5_issues] 0 "validate_approach: nonexistent file → no issues"

# 12f. validate_campaign still produces same results via delegation
# Reuse seg_va2 (placeholder) through classify_segment path
set seg_va6 [make_temp_segment]
write_profile $seg_va6 "va-campaign-check"
write_approach_yaml $seg_va6 "va-campaign-check" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER_EMAIL
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_va6 $::std_headers [list \
    [make_base_row {contact_name "Campaign Check" email "real@example.com" \
        stem "va-campaign-check"}] \
]
set cv_va6 [spar::classify_segment $seg_va6]
set issues_va6 [spar::validate_campaign $cv_va6]
set pt_va6 [issues_with_code $issues_va6 placeholder_to]
assert_eq [llength $pt_va6] 1 "validate_campaign: still detects placeholder_to via validate_approach delegation"

# ════════════════════════════════════════════════════════════════════════
# Cleanup and summary
# ════════════════════════════════════════════════════════════════════════
cleanup_temps

puts ""
puts "════════════════════════════════════════════════════════════════"
puts "Results: $::passes passed, $::failures failed"
puts "════════════════════════════════════════════════════════════════"

if {$::failures > 0} {
    exit 1
} else {
    exit 0
}

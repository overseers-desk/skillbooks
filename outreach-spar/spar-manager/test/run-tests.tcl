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
    set path [file join $segment_dir profiles "${stem}.md"]
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
    star_rating date_found_invalid profile_stem approach_stem
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
        profile_stem    "" \
        approach_stem   "" \
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

# 1b. Valid contact, profile_stem="" → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {profile_stem ""}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "no profile_stem → DISCOVERED"

# 1c. Valid contact, profile_stem set, profile file exists → PROFILED
set seg [make_temp_segment]
write_profile $seg "alice-smith-acme"
set row [make_base_row {profile_stem "alice-smith-acme"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "profile_stem + file exists → PROFILED"

# 1d. Valid contact, profile_stem set, profile file MISSING → DISCOVERED
set seg [make_temp_segment]
set row [make_base_row {profile_stem "nonexistent-profile"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "DISCOVERED" "profile_stem + file missing → DISCOVERED"

# 1e. Valid, profile+approach stems set, approach file exists, no final round → APPROACHED
set seg [make_temp_segment]
write_profile $seg "bob-jones-widgets"
write_approach_yaml $seg "bob-jones-widgets" [approach_yaml_no_final]
set row [make_base_row {profile_stem "bob-jones-widgets" approach_stem "bob-jones-widgets"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "approach exists, no final round → APPROACHED"

# 1f. Valid, approach with final round but unsent → APPROACHED
set seg [make_temp_segment]
write_profile $seg "carol-lee-bigco"
write_approach_yaml $seg "carol-lee-bigco" [approach_yaml_final_unsent]
set row [make_base_row {profile_stem "carol-lee-bigco" approach_stem "carol-lee-bigco"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "APPROACHED" "final round, no actioned_date → APPROACHED"

# 1g. Valid, approach with final round, actioned_date set → SENT
set seg [make_temp_segment]
write_profile $seg "dave-kim-techcorp"
write_approach_yaml $seg "dave-kim-techcorp" [approach_yaml_final_sent_email]
set row [make_base_row {profile_stem "dave-kim-techcorp" approach_stem "dave-kim-techcorp"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "SENT" "final round, actioned_date set → SENT"

# 1h. Valid, approach with final round, actioned_date+replied_date set → REPLIED
set seg [make_temp_segment]
write_profile $seg "eve-tanaka-globalinc"
write_approach_yaml $seg "eve-tanaka-globalinc" [approach_yaml_final_replied]
set row [make_base_row {profile_stem "eve-tanaka-globalinc" approach_stem "eve-tanaka-globalinc"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "REPLIED" "final round, replied_date set → REPLIED"

# 1i. Valid, approach with final round, reply with direction=received → REPLIED
set seg [make_temp_segment]
write_profile $seg "frank-wu-pacific"
write_approach_yaml $seg "frank-wu-pacific" [approach_yaml_final_reply_received]
set row [make_base_row {profile_stem "frank-wu-pacific" approach_stem "frank-wu-pacific"}]
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
set row [make_base_row {profile_stem "ch-email-sent" approach_stem "ch-email-sent"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_sent] 1 "final email actioned → email_sent=1"

# 3b. Approach with final round linkedin message, actioned_date set → linkedin_sent=1
set seg [make_temp_segment]
write_profile $seg "ch-linkedin-sent"
write_approach_yaml $seg "ch-linkedin-sent" [approach_yaml_final_sent_linkedin]
set row [make_base_row {profile_stem "ch-linkedin-sent" approach_stem "ch-linkedin-sent"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result linkedin_sent] 1 "final linkedin actioned → linkedin_sent=1"

# 3c. email_sent=0 when approach unsent
set seg [make_temp_segment]
write_profile $seg "ch-unsent"
write_approach_yaml $seg "ch-unsent" [approach_yaml_final_unsent]
set row [make_base_row {profile_stem "ch-unsent" approach_stem "ch-unsent"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_sent] 0 "final email not actioned → email_sent=0"

# 3d. Approach with final round, replied_date set → email_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-replied"
write_approach_yaml $seg "ch-replied" [approach_yaml_final_replied]
set row [make_base_row {profile_stem "ch-replied" approach_stem "ch-replied"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_replied] 1 "final replied_date → email_replied=1"

# 3e. direction=received → email_replied=1
set seg [make_temp_segment]
write_profile $seg "ch-recv"
write_approach_yaml $seg "ch-recv" [approach_yaml_final_reply_received]
set row [make_base_row {profile_stem "ch-recv" approach_stem "ch-recv"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result email_replied] 1 "direction=received → email_replied=1"

# 3f. Multi-channel: linkedin sent, email not sent
set seg [make_temp_segment]
write_profile $seg "ch-multi"
write_approach_yaml $seg "ch-multi" [approach_yaml_final_multi_channel]
set row [make_base_row {profile_stem "ch-multi" approach_stem "ch-multi"}]
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
    [make_base_row {contact_name "Invalid Irene" date_found_invalid "2026-01-01" profile_stem "" approach_stem ""}] \
    [make_base_row {contact_name "Discovered Dan" profile_stem "" approach_stem ""}] \
    [make_base_row {contact_name "Profiled Pat" profile_stem "profiled-one" approach_stem ""}] \
    [make_base_row {contact_name "Approached Ann" profile_stem "approached-one" approach_stem "approached-one"}] \
    [make_base_row {contact_name "Sent Steve" profile_stem "sent-one" approach_stem "sent-one"}] \
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

# 4b. Schema validation: roster missing profile_stem column → error
set seg [make_temp_segment]
set bad_headers {contact_name organisation_name email star_rating}
set bad_rows [list [dict create contact_name "Test" organisation_name "Org" email "a@b.com" star_rating "3"]]
write_roster_tsv $seg $bad_headers $bad_rows

assert_error {spar::classify_segment $seg} \
    "*missing required column*profile_stem*" \
    "missing profile_stem column → error"

# 4c. Schema validation: roster missing approach_stem column → error
set seg [make_temp_segment]
set bad_headers2 {contact_name organisation_name email star_rating profile_stem}
set bad_rows2 [list [dict create contact_name "Test" organisation_name "Org" email "a@b.com" star_rating "3" profile_stem ""]]
write_roster_tsv $seg $bad_headers2 $bad_rows2

assert_error {spar::classify_segment $seg} \
    "*missing required column*approach_stem*" \
    "missing approach_stem column → error"

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
    [make_base_row {contact_name "Alice" star_rating "4" email "alice@example.com" profile_stem "p-alice" approach_stem ""}] \
    [make_base_row {contact_name "Bob" star_rating "5" email "bob@example.com" profile_stem "p-bob" approach_stem "p-bob"}] \
    [make_base_row {contact_name "Carol" star_rating "3" email "carol@example.com" profile_stem "p-carol" approach_stem "p-carol"}] \
    [make_base_row {contact_name "Dave" star_rating "3" email "dave@example.com" profile_stem "p-dave" approach_stem "p-dave"}] \
    [make_base_row {contact_name "Ed" star_rating "2" email "" profile_stem "" approach_stem "" date_found_invalid "2026-01-01"}] \
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
    [make_base_row {contact_name "Disco Dan" profile_stem "" approach_stem "" star_rating "4" email "dan@example.com"}] \
    [make_base_row {contact_name "Prof Hi" profile_stem "t-profiled-hi" approach_stem "" star_rating "4" email "hi@example.com"}] \
    [make_base_row {contact_name "Prof Lo" profile_stem "t-profiled-lo" approach_stem "" star_rating "2" email "lo@example.com"}] \
    [make_base_row {contact_name "App Email" profile_stem "t-approached-email" approach_stem "t-approached-email" star_rating "3" email "app@example.com"}] \
    [make_base_row {contact_name "App NoEmail" profile_stem "t-approached-noemail" approach_stem "t-approached-noemail" star_rating "3" email ""}] \
    [make_base_row {contact_name "Sent Sam" profile_stem "t-sent" approach_stem "t-sent" star_rating "3" email "sent@example.com"}] \
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
set row [make_base_row {profile_stem "path-test" approach_stem "path-test"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result profile_path] $pp "profile_path points to correct file"
assert_eq [dict get $result approach_path] $ap "approach_path points to correct file"

# Empty paths when stems are empty
set row2 [make_base_row {profile_stem "" approach_stem ""}]
set result2 [spar::classify_contact $row2 $seg]
assert_eq [dict get $result2 profile_path] "" "no profile_stem → profile_path empty"
assert_eq [dict get $result2 approach_path] "" "no approach_stem → approach_path empty"

# ════════════════════════════════════════════════════════════════════════
# 8. Edge cases
# ════════════════════════════════════════════════════════════════════════
section "8. Edge cases"

# 8a. INVALID takes priority even if profile_stem and approach_stem are set
set seg [make_temp_segment]
write_profile $seg "invalid-priority"
write_approach_yaml $seg "invalid-priority" [approach_yaml_final_sent_email]
set row [make_base_row {date_found_invalid "2026-03-01" profile_stem "invalid-priority" approach_stem "invalid-priority"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "INVALID" "INVALID wins over SENT when date_found_invalid set"

# 8b. approach_stem set but no approach file → stays PROFILED
set seg [make_temp_segment]
write_profile $seg "no-approach-file"
set row [make_base_row {profile_stem "no-approach-file" approach_stem "missing-approach"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "PROFILED" "approach_stem set but file missing → PROFILED"

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

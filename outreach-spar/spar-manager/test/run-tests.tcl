#!/usr/bin/env tclsh9.0
# run-tests.tcl — Test suite for spar-state.tcl (SPAR campaign state machine)
#
# Run:  tclsh9.0 test/run-tests.tcl
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

# write_profile -- create a profile .md file with valid YAML front matter.
# The dependent_data block is emitted as an empty mapping by default; the
# staleness check in classify_contact / validate_profile skips fields absent
# from the snapshot, so an empty dependent_data never flags stale. Tests that
# exercise staleness populate the snapshot explicitly via args, e.g.:
#   write_profile $seg alice -contact_name "Alice Smith" -organisation "Acme"
# Keys accepted in args:
#   -profile_date -star_rating -yield -warmth_finding
#   -applicable_angle   (single slug; default "default-angle")
#   -contact_name -organisation -role -date_excluded  (snapshot fields)
proc write_profile {segment_dir stem args} {
    set path [file join $segment_dir profiles "${stem}.md"]
    array set opts {
        -profile_date    2026-04-12
        -star_rating     4
        -yield           2
        -warmth_finding  cold
        -applicable_angle default-angle
    }
    array set snap {}
    foreach {k v} $args {
        if {$k in {-contact_name -organisation -role -date_excluded}} {
            set snap([string range $k 1 end]) $v
        } else {
            set opts($k) $v
        }
    }

    set fd [open $path w]
    puts $fd "---"
    puts $fd "profile_date: $opts(-profile_date)"
    puts $fd "star_rating: $opts(-star_rating)"
    puts $fd "yield: $opts(-yield)"
    puts $fd "warmth_finding: $opts(-warmth_finding)"
    puts $fd "applicable_angles:"
    puts $fd "  - $opts(-applicable_angle)"
    if {[array size snap] == 0} {
        puts $fd "dependent_data: {}"
    } else {
        puts $fd "dependent_data:"
        foreach k {contact_name organisation role date_excluded} {
            if {[info exists snap($k)]} {
                puts $fd "  ${k}: $snap($k)"
            }
        }
    }
    puts $fd "---"
    puts $fd ""
    puts $fd "# Profile: $stem"
    puts $fd ""
    puts $fd "Minimal body for test fixture."
    close $fd
    return $path
}

# write_profile_raw -- write exact raw content to profiles/{stem}.md. For tests
# that need a deliberately malformed profile (missing fences, bad YAML, etc.).
proc write_profile_raw {segment_dir stem content} {
    set path [file join $segment_dir profiles "${stem}.md"]
    set fd [open $path w]
    puts -nonewline $fd $content
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

# has_issue -- check that a specific issue code appears in an issues list.
proc has_issue {issues code} {
    foreach i $issues {
        if {[dict get $i code] eq $code} { return 1 }
    }
    return 0
}

# Standard roster headers for most tests.
set ::std_headers {
    contact_name organisation_name email linkedin_url facebook_url phone
    star_rating date_excluded stem
}

# make_base_row -- return a dict with default valid values.
proc make_base_row {{overrides {}}} {
    set row [dict create \
        contact_name    "Test Contact" \
        organisation_name "Test Org" \
        email           "test@acme-venues.au" \
        linkedin_url    "" \
        facebook_url    "" \
        phone           "" \
        star_rating     "3" \
        date_excluded "" \
        stem            "" \
    ]
    dict for {k v} $overrides {
        dict set row $k $v
    }
    return $row
}

# Approach YAML templates
proc approach_yaml_no_final {} {
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
decisions:
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
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
}

proc approach_yaml_final_sent_email {} {
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: null
}
}

proc approach_yaml_final_replied {} {
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: 2026-04-05
}
}

proc approach_yaml_final_reply_received {} {
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: null
  replies:
  - direction: received
    date: 2026-04-05
    from: test@acme-venues.au
}
}

proc approach_yaml_final_sent_linkedin {} {
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
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
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
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

# 1a. date_excluded set → EXCLUDED
set seg [make_temp_segment]
set row [make_base_row {date_excluded "2026-01-15"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "EXCLUDED" "date_excluded → EXCLUDED"

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
    [make_base_row {contact_name "Invalid Irene" date_excluded "2026-01-01" stem ""}] \
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
    [make_base_row {contact_name "Alice" star_rating "4" email "alice@acme-venues.au" stem "p-alice"}] \
    [make_base_row {contact_name "Bob" star_rating "5" email "bob@acme-venues.au" stem "p-bob"}] \
    [make_base_row {contact_name "Carol" star_rating "3" email "carol@acme-venues.au" stem "p-carol"}] \
    [make_base_row {contact_name "Dave" star_rating "3" email "dave@acme-venues.au" stem "p-dave"}] \
    [make_base_row {contact_name "Ed" star_rating "2" email "" stem "" date_excluded "2026-01-01"}] \
]
write_roster_tsv $seg $headers $rows

set contacts [spar::classify_segment $seg]
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
    [make_base_row {contact_name "Disco Dan" stem "" star_rating "4" email "dan@acme-venues.au"}] \
    [make_base_row {contact_name "Prof Hi" stem "t-profiled-hi" star_rating "4" email "hi@acme-venues.au"}] \
    [make_base_row {contact_name "Prof Lo" stem "t-profiled-lo" star_rating "2" email "lo@acme-venues.au"}] \
    [make_base_row {contact_name "App Email" stem "t-approached-email" star_rating "3" email "app@acme-venues.au"}] \
    [make_base_row {contact_name "App NoEmail" stem "t-approached-noemail" star_rating "3" email ""}] \
    [make_base_row {contact_name "Sent Sam" stem "t-sent" star_rating "3" email "sent@acme-venues.au"}] \
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
# primary_channel="email" required — see issue #49 interim gate.
set t3 [spar::transition_eligible $contacts "T3" "email"]
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

# T3 primary_channel gate (issue #49): non-email or unspecified → zero tasks.
set t3_lk [spar::transition_eligible $contacts "T3" "linkedin"]
assert_eq [llength $t3_lk] 0 "T3: primary_channel=linkedin → zero tasks"
set t3_u [spar::transition_eligible $contacts "T3"]
assert_eq [llength $t3_u] 0 "T3: primary_channel unknown → zero tasks"

# T4: Send → Reply: email_sent, not email_replied → pending (monitoring)
set t4 [spar::transition_eligible $contacts "T4"]
set t4_names [lmap c $t4 {dict get $c contact_name}]
assert_eq [expr {"Sent Sam" in $t4_names}] 1 "T4: SENT+email_sent → in monitoring list"

# transition_eligible result dicts must carry stem and _segment_dir so
# downstream callers (spar-transitions.tcl --execute) can route without
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

# 8a. EXCLUDED takes priority even if stem is set and files exist
set seg [make_temp_segment]
write_profile $seg "invalid-priority"
write_approach_yaml $seg "invalid-priority" [approach_yaml_final_sent_email]
set row [make_base_row {date_excluded "2026-03-01" stem "invalid-priority"}]
set result [spar::classify_contact $row $seg]
assert_eq [dict get $result state] "EXCLUDED" "EXCLUDED wins over SENT when date_excluded set"

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
    [make_base_row {contact_name "Alice One" email "shared@acme-venues.au" stem ""}] \
]
write_roster_tsv $seg2 $::std_headers [list \
    [make_base_row {contact_name "Alice Two" email "shared@acme-venues.au" stem ""}] \
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
    [make_base_row {contact_name "Bob One" email "bob@acme-venues.au" stem ""}] \
    [make_base_row {contact_name "Bob Two" email "bob@acme-venues.au" stem ""}] \
]
set c3 [spar::classify_segment $seg3]
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
set c4 [spar::classify_segment $seg4]
set c5 [spar::classify_segment $seg5]
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
set c6 [spar::classify_segment $seg6]
set c7 [spar::classify_segment $seg7]
set dups67 [spar::detect_duplicates [concat $c6 $c7]]
assert_eq [expr {[llength [dict get $dups67 duplicate_name]] > 0}] 1 \
    "duplicate_name: same name in different segments → flagged"

# 9e. duplicate_name: same name within one segment → not flagged
set seg8 [make_temp_segment]
write_roster_tsv $seg8 $::std_headers [list \
    [make_base_row {contact_name "Jane Doe" email "jane1@acme-venues.au" stem ""}] \
    [make_base_row {contact_name "Jane Doe" email "jane2@acme-venues.au" stem ""}] \
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

set c15 [spar::classify_segment $seg15]
set c16 [spar::classify_segment $seg16]
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
set cinv1 [spar::classify_segment $seg_inv1]
set cinv2 [spar::classify_segment $seg_inv2]
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
set cinv3 [spar::classify_segment $seg_inv3]
set cinv4 [spar::classify_segment $seg_inv4]
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
set cinv5 [spar::classify_segment $seg_inv5]
set cinv6 [spar::classify_segment $seg_inv6]
set dups_inv3 [spar::detect_duplicates [concat $cinv5 $cinv6]]
assert_eq [llength [dict get $dups_inv3 duplicate_to]] 0 \
    "duplicate_to: EXCLUDED contact's approach file does not contribute → not flagged"

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

set ct8b [spar::classify_segment $seg_t8b]
set t8b_results [spar::transition_eligible $ct8b "T8"]
set t8b_names [lmap c $t8b_results {dict get $c contact_name}]
assert_eq [expr {"Both Sent" in $t8b_names}] 0 \
    "T8: email_sent=1 → not eligible for T8"

# 10c. T4: EXCLUDED contact with email_sent=1 → not eligible for T4 monitoring
set seg_t4_inv [make_temp_segment]
write_profile $seg_t4_inv "t4-invalidated"
write_approach_yaml $seg_t4_inv "t4-invalidated" {decisions:
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
write_roster_tsv $seg_t4_inv $::std_headers [list \
    [make_base_row {contact_name "Sent Then Invalid" email "sti@acme-venues.au" \
        stem "t4-invalidated" star_rating "4" date_excluded "2026-04-05"}] \
]
set ct4_inv [spar::classify_segment $seg_t4_inv]
set t4_inv_results [spar::transition_eligible $ct4_inv "T4"]
assert_eq [llength $t4_inv_results] 0 \
    "T4: EXCLUDED contact with email_sent=1 → not eligible"

# 10d. T8: EXCLUDED contact with linkedin_sent=1 → not eligible for T8
set seg_t8_inv [make_temp_segment]
write_profile $seg_t8_inv "t8-invalidated"
write_approach_yaml $seg_t8_inv "t8-invalidated" [approach_yaml_final_multi_channel]
write_roster_tsv $seg_t8_inv $::std_headers [list \
    [make_base_row {contact_name "LI Sent Then Invalid" email "lsti@acme-venues.au" \
        linkedin_url "https://linkedin.com/in/lsti" \
        stem "t8-invalidated" star_rating "4" date_excluded "2026-04-05"}] \
]
set ct8_inv [spar::classify_segment $seg_t8_inv]
set t8_inv_results [spar::transition_eligible $ct8_inv "T8"]
assert_eq [llength $t8_inv_results] 0 \
    "T8: EXCLUDED contact with linkedin_sent=1 → not eligible"

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
    [make_base_row {contact_name "Placeholder Pete" email "pete@acme-venues.au" \
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
    to: Bob@Acme-Venues.AU
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v4 $::std_headers [list \
    [make_base_row {contact_name "Sync Bob" email "bob@acme-venues.au" \
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
set va1_issues [spar::validate_approach $va1_path "test@acme-venues.au" "Test Contact"]
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
set va2_issues [spar::validate_approach $va2_path "real@acme-venues.au" "VA Placeholder"]
set va2_errors [issues_with_code $va2_issues placeholder_to]
assert_eq [llength $va2_errors] 1 "validate_approach: placeholder to: → placeholder_to error"
assert_eq [dict get [lindex $va2_errors 0] severity] "error" "validate_approach: placeholder_to severity is error"

# 12b2. Syntactically-valid placeholder domain (RFC 2606) → placeholder_to error
set seg_va2b [make_temp_segment]
set va2b_path [write_approach_yaml $seg_va2b "va-rfc-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: recipient@example.com
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2b_issues [spar::validate_approach $va2b_path "recipient@example.com" "VA RFC Placeholder"]
set va2b_errors [issues_with_code $va2b_issues placeholder_to]
assert_eq [llength $va2b_errors] 1 "validate_approach: @example.com to: → placeholder_to error"

# 12b3. Stub local-part (e.g. todo@real.com) → placeholder_to error
set seg_va2c [make_temp_segment]
set va2c_path [write_approach_yaml $seg_va2c "va-stub-local" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: todo@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2c_issues [spar::validate_approach $va2c_path "todo@acme-venues.au" "VA Stub Local"]
set va2c_errors [issues_with_code $va2c_issues placeholder_to]
assert_eq [llength $va2c_errors] 1 "validate_approach: stub local-part → placeholder_to error"

# 12c. to: differs from roster email → email_desync warning
set seg_va3 [make_temp_segment]
set va3_path [write_approach_yaml $seg_va3 "va-desync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: wrong@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va3_issues [spar::validate_approach $va3_path "correct@acme-venues.au" "VA Desync"]
set va3_warnings [issues_with_code $va3_issues email_desync]
assert_eq [llength $va3_warnings] 1 "validate_approach: to: differs from roster email → email_desync warning"
assert_eq [dict get [lindex $va3_warnings 0] severity] "warning" "validate_approach: email_desync severity is warning"

# 12d. No final round → structural error (no_final_round)
set seg_va4 [make_temp_segment]
set va4_path [write_approach_yaml $seg_va4 "va-nofinal" [approach_yaml_no_final]]
set va4_issues [spar::validate_approach $va4_path "test@acme-venues.au" "Test Contact"]
assert_eq [has_issue $va4_issues no_final_round] 1 "validate_approach: no final round → no_final_round error"

# 12d1. Missing generated_for → error (issue #30)
set seg_va_mgf [make_temp_segment]
set va_mgf_path [write_approach_yaml $seg_va_mgf "va-mgf" {decisions:
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
}]
set va_mgf_issues [spar::validate_approach $va_mgf_path "test@acme-venues.au" "VA MGF" "Some Org"]
set va_mgf_errors [issues_with_code $va_mgf_issues missing_generated_for]
assert_eq [llength $va_mgf_errors] 1 "validate_approach: missing generated_for → missing_generated_for error"
assert_eq [dict get [lindex $va_mgf_errors 0] severity] "error" "validate_approach: missing_generated_for severity is error"

# 12d1b. Missing response_likelihood → error (issue #69)
set seg_va_mrl [make_temp_segment]
set va_mrl_path [write_approach_yaml $seg_va_mrl "va-mrl" {generated_for:
  contact_name: VA MRL
  organisation: Some Org
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
}]
set va_mrl_issues [spar::validate_approach $va_mrl_path "test@acme-venues.au" "VA MRL" "Some Org"]
set va_mrl_errors [issues_with_code $va_mrl_issues missing_response_likelihood]
assert_eq [llength $va_mrl_errors] 1 "validate_approach: missing response_likelihood → missing_response_likelihood error"
assert_eq [dict get [lindex $va_mrl_errors 0] severity] "error" "validate_approach: missing_response_likelihood severity is error"

# 12d1c. Send-path carve-out: _approach_validation_error must not block dispatch
# on missing_response_likelihood alone (#69 — pre-existing approach files
# authored before the check must remain sendable).
set va_mrl_contact [dict create approach_path $va_mrl_path \
    email "test@acme-venues.au" contact_name "VA MRL" organisation "Some Org"]
assert_eq [spar::_approach_validation_error $va_mrl_contact] "" \
    "_approach_validation_error: missing_response_likelihood alone → not a dispatch blocker"

# 12d2. generated_for.contact_name differs from roster → name_desync warning
set seg_va_nd [make_temp_segment]
set va_nd_path [write_approach_yaml $seg_va_nd "va-nd" {generated_for:
  contact_name: Jane Old
  organisation: Acme Co
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
}]
set va_nd_issues [spar::validate_approach $va_nd_path "test@acme-venues.au" "Jane New" "Acme Co"]
set va_nd_warnings [issues_with_code $va_nd_issues name_desync]
assert_eq [llength $va_nd_warnings] 1 "validate_approach: generated_for.contact_name differs → name_desync warning"
assert_eq [dict get [lindex $va_nd_warnings 0] severity] "warning" "validate_approach: name_desync severity is warning"

# 12d3. generated_for.organisation differs from roster → org_desync warning
set seg_va_od [make_temp_segment]
set va_od_path [write_approach_yaml $seg_va_od "va-od" {generated_for:
  contact_name: Jane Doe
  organisation: Old Co
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
}]
set va_od_issues [spar::validate_approach $va_od_path "test@acme-venues.au" "Jane Doe" "New Co"]
set va_od_warnings [issues_with_code $va_od_issues org_desync]
assert_eq [llength $va_od_warnings] 1 "validate_approach: generated_for.organisation differs → org_desync warning"
assert_eq [dict get [lindex $va_od_warnings 0] severity] "warning" "validate_approach: org_desync severity is warning"

# 12d4. generated_for matching roster → no desync
set seg_va_ok [make_temp_segment]
set va_ok_path [write_approach_yaml $seg_va_ok "va-ok" {generated_for:
  contact_name: Jane Doe
  organisation: Acme Co
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
}]
set va_ok_issues [spar::validate_approach $va_ok_path "test@acme-venues.au" "Jane Doe" "Acme Co"]
assert_eq [has_issue $va_ok_issues name_desync] 0 "validate_approach: matching name → no name_desync"
assert_eq [has_issue $va_ok_issues org_desync] 0 "validate_approach: matching org → no org_desync"

# 12e. Nonexistent file → no errors (graceful)
set va5_issues [spar::validate_approach "/tmp/nonexistent-approach.yaml" "test@acme-venues.au" "VA Missing"]
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
    [make_base_row {contact_name "Campaign Check" email "real@acme-venues.au" \
        stem "va-campaign-check"}] \
]
set cv_va6 [spar::classify_segment $seg_va6]
set issues_va6 [spar::validate_campaign $cv_va6]
set pt_va6 [issues_with_code $issues_va6 placeholder_to]
assert_eq [llength $pt_va6] 1 "validate_campaign: still detects placeholder_to via validate_approach delegation"

# ════════════════════════════════════════════════════════════════════════
# 12p. validate_profile (per-file front-matter check, SmartLayer/aesop#45)
# ════════════════════════════════════════════════════════════════════════
section "validate_profile"

# 12p-a. Valid front matter → no errors
set seg_vp1 [make_temp_segment]
set vp1_path [write_profile $seg_vp1 "vp-valid"]
set vp1_row [make_base_row {stem "vp-valid"}]
set vp1_issues [spar::validate_profile $vp1_path $vp1_row "VP Valid"]
assert_eq [llength $vp1_issues] 0 "validate_profile: valid front matter → no issues"

# 12p-b. Missing fences → invalid_front_matter error
set seg_vp2 [make_temp_segment]
set vp2_path [write_profile_raw $seg_vp2 "vp-nofm" "# Profile\n\nNo front matter here.\n"]
set vp2_issues [spar::validate_profile $vp2_path [make_base_row] "VP NoFM"]
assert_eq [has_issue $vp2_issues invalid_front_matter] 1 "validate_profile: missing fences → invalid_front_matter"

# 12p-c. Unparseable YAML in front matter → invalid_front_matter error
# Use a structure YAML cannot parse: mismatched indentation with a block seq inside a mapping.
set seg_vp3 [make_temp_segment]
set vp3_path [write_profile_raw $seg_vp3 "vp-badyaml" "---\nkey: value\n  - broken\n \tmixed indent with tab\n---\nbody"]
set vp3_issues [spar::validate_profile $vp3_path [make_base_row] "VP BadYAML"]
assert_eq [has_issue $vp3_issues invalid_front_matter] 1 "validate_profile: unparseable YAML → invalid_front_matter"

# 12p-d. Unknown top-level key → unknown_key_root error
set seg_vp4 [make_temp_segment]
set vp4_path [write_profile_raw $seg_vp4 "vp-unknown" "---\nprofile_date: 2026-04-12\nstar_rating: 3\nyield: 2\nwarmth_finding: cold\napplicable_angles:\n  - foo\ndependent_data: {}\nrogue_key: oops\n---\nbody"]
set vp4_issues [spar::validate_profile $vp4_path [make_base_row] "VP Unknown"]
assert_eq [has_issue $vp4_issues unknown_key_root] 1 "validate_profile: unknown root key → unknown_key_root"

# 12p-e. invalid_yield — non-integer value
set seg_vp5 [make_temp_segment]
set vp5_path [write_profile $seg_vp5 "vp-yield" -yield "sparkly"]
set vp5_issues [spar::validate_profile $vp5_path [make_base_row] "VP Yield"]
assert_eq [has_issue $vp5_issues invalid_yield] 1 "validate_profile: yield 'sparkly' → invalid_yield"

# 12p-f. invalid_warmth_finding
set seg_vp6 [make_temp_segment]
set vp6_path [write_profile $seg_vp6 "vp-warm" -warmth_finding "lukewarm"]
set vp6_issues [spar::validate_profile $vp6_path [make_base_row] "VP Warmth"]
assert_eq [has_issue $vp6_issues invalid_warmth_finding] 1 "validate_profile: warmth_finding 'lukewarm' → invalid_warmth_finding"

# 12p-g. invalid_star_rating (0 must not appear)
set seg_vp7 [make_temp_segment]
set vp7_path [write_profile $seg_vp7 "vp-star0" -star_rating 0]
set vp7_issues [spar::validate_profile $vp7_path [make_base_row] "VP Star0"]
assert_eq [has_issue $vp7_issues invalid_star_rating] 1 "validate_profile: star_rating 0 → invalid_star_rating"

# 12p-h. Missing required key (yield omitted)
set seg_vp8 [make_temp_segment]
set vp8_path [write_profile_raw $seg_vp8 "vp-miss" "---\nprofile_date: 2026-04-12\nstar_rating: 3\nwarmth_finding: cold\napplicable_angles:\n  - foo\ndependent_data: {}\n---\nbody"]
set vp8_issues [spar::validate_profile $vp8_path [make_base_row] "VP Missing"]
assert_eq [has_issue $vp8_issues missing_yield] 1 "validate_profile: missing yield → missing_yield"

# 12p-i. Staleness — snapshot contact_name differs from roster
set seg_vp9 [make_temp_segment]
set vp9_path [write_profile $seg_vp9 "vp-stale-name" \
    -contact_name "Old Name" -organisation "SomeOrg" -role "SomeRole" -date_excluded null]
set vp9_row [dict create stem "vp-stale-name" contact_name "New Name" \
    organisation "SomeOrg" role "SomeRole" date_excluded ""]
set vp9_issues [spar::validate_profile $vp9_path $vp9_row "VP StaleName"]
assert_eq [has_issue $vp9_issues stale_contact_name] 1 "validate_profile: contact_name drift → stale_contact_name"

# 12p-j. Staleness — date_excluded asymmetric: date → empty = stale
set seg_vp10 [make_temp_segment]
set vp10_path [write_profile $seg_vp10 "vp-stale-date" \
    -contact_name "Same" -organisation "Same" -role "Same" -date_excluded 2026-01-01]
set vp10_row [dict create stem "vp-stale-date" contact_name "Same" \
    organisation "Same" role "Same" date_excluded ""]
set vp10_issues [spar::validate_profile $vp10_path $vp10_row "VP StaleDate"]
assert_eq [has_issue $vp10_issues stale_date_excluded] 1 \
    "validate_profile: snapshot date_excluded set, current empty → stale_date_excluded"

# 12p-k. Staleness — date_excluded asymmetric: empty → date = NOT stale (EXCLUDED supersedes)
set seg_vp11 [make_temp_segment]
set vp11_path [write_profile $seg_vp11 "vp-not-stale" \
    -contact_name "Same" -organisation "Same" -role "Same" -date_excluded null]
set vp11_row [dict create stem "vp-not-stale" contact_name "Same" \
    organisation "Same" role "Same" date_excluded "2026-04-10"]
set vp11_issues [spar::validate_profile $vp11_path $vp11_row "VP NotStale"]
assert_eq [has_issue $vp11_issues stale_date_excluded] 0 \
    "validate_profile: snapshot empty, current has date → NOT stale (reverse direction)"

# 12p-l. Nonexistent file → no issues (graceful, mirrors validate_approach)
set vp12_issues [spar::validate_profile "/tmp/nonexistent-profile.md" [make_base_row] "VP Missing"]
assert_eq [llength $vp12_issues] 0 "validate_profile: nonexistent file → no issues"

# 12p-m. PROFILE_STALE classification via classify_contact
set seg_vp13 [make_temp_segment]
write_profile $seg_vp13 "vp-classify-stale" \
    -contact_name "Was Called This" -organisation "Same Org" -role "Same Role"
set vp13_roster [list stem contact_name organisation role date_excluded email]
set vp13_tsv [file join $seg_vp13 roster.tsv]
set fd [open $vp13_tsv w]
puts $fd [join $vp13_roster \t]
puts $fd [join [list "vp-classify-stale" "Is Called This Now" "Same Org" "Same Role" "" "x@y.com"] \t]
close $fd
set vp13_contacts [spar::classify_segment $seg_vp13]
set vp13_state [dict get [lindex $vp13_contacts 0] state]
assert_eq $vp13_state "PROFILE_STALE" "classify_contact: snapshot ≠ roster → PROFILE_STALE"

# 12p-n. PROFILE_STALE appears as T6 transition target
set vp13_t6 [spar::transition_eligible $vp13_contacts "T6"]
set vp13_t6_names [lmap c $vp13_t6 {dict get $c contact_name}]
assert_eq [expr {"Is Called This Now" in $vp13_t6_names}] 1 \
    "T6: PROFILE_STALE contact is eligible for re-profile"

# 12p-o. validate_campaign integration: staleness warning flows through
set vp14_issues [spar::validate_campaign $vp13_contacts]
assert_eq [has_issue $vp14_issues stale_contact_name] 1 \
    "validate_campaign: profile staleness surfaces through include_profile path"

# 12p-p. validate_campaign_semantics skips include_profile (progress-only path)
set vp14_sem [spar::validate_campaign_semantics $vp13_contacts]
assert_eq [has_issue $vp14_sem stale_contact_name] 0 \
    "validate_campaign_semantics: skips profile checks (include_profile=0)"

# 12p-q. #39 R1: profile exists but no channels and no date_excluded → error
set seg_vp15 [make_temp_segment]
set vp15_path [write_profile $seg_vp15 "vp-unreachable"]
set vp15_row [dict create stem "vp-unreachable" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "" date_excluded ""]
set vp15_issues [spar::validate_profile $vp15_path $vp15_row "VP Unreachable"]
assert_eq [has_issue $vp15_issues profile_unreachable_without_exclusion] 1 \
    "validate_profile: profile + all channels empty + no date_excluded → profile_unreachable_without_exclusion"

# 12p-r. #39 R1: date_excluded set → no error (P honoured §4.15)
set seg_vp16 [make_temp_segment]
set vp16_path [write_profile $seg_vp16 "vp-excluded" -date_excluded "2026-04-12"]
set vp16_row [dict create stem "vp-excluded" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "" date_excluded "2026-04-12"]
set vp16_issues [spar::validate_profile $vp16_path $vp16_row "VP Excluded"]
assert_eq [has_issue $vp16_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: all channels empty but date_excluded set → no R1 error"

# 12p-s. #39 R1: phone-only contact is reachable (phone path per §4.15)
set seg_vp17 [make_temp_segment]
set vp17_path [write_profile $seg_vp17 "vp-phoneonly"]
set vp17_row [dict create stem "vp-phoneonly" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "0400000000" date_excluded ""]
set vp17_issues [spar::validate_profile $vp17_path $vp17_row "VP PhoneOnly"]
assert_eq [has_issue $vp17_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: phone-only contact → no R1 error"

# 12p-t. #39 R1: one channel present → no error
set seg_vp18 [make_temp_segment]
set vp18_path [write_profile $seg_vp18 "vp-haslinkedin"]
set vp18_row [dict create stem "vp-haslinkedin" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "https://linkedin.com/in/x" facebook_url "" \
    phone "" date_excluded ""]
set vp18_issues [spar::validate_profile $vp18_path $vp18_row "VP HasLinkedIn"]
assert_eq [has_issue $vp18_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: LinkedIn present → no R1 error"

# 12p-u. #39 R1: empty roster_row (orphan) → no R1 error (orphan is separate check)
set seg_vp19 [make_temp_segment]
set vp19_path [write_profile $seg_vp19 "vp-orphan"]
set vp19_issues [spar::validate_profile $vp19_path [dict create] "VP Orphan"]
assert_eq [has_issue $vp19_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: empty roster_row → no R1 error (orphan check is separate)"

# ════════════════════════════════════════════════════════════════════════
# 13. Golden snapshot (real campaign data)
# ════════════════════════════════════════════════════════════════════════
section "13. Golden snapshot (real campaign data)"

set campaign_dir [file normalize [file join $script_dir .. .. .. .. rivermill segments-outreach.spar]]
if {![file isdirectory $campaign_dir]} {
    puts "  SKIP: campaign directory not found ($campaign_dir)"
} else {
    # 13a. line-dance segment
    set ld_seg [file join $campaign_dir line-dance]
    set ld_contacts [spar::classify_segment $ld_seg]
    set ld_counts [spar::progress_counts $ld_contacts]
    assert_eq [dict get $ld_counts valid] 12 "golden line-dance: valid=12"
    assert_eq [dict get $ld_counts profiled] 12 "golden line-dance: profiled=12"
    assert_eq [dict get $ld_counts star3] 10 "golden line-dance: star3=10"

    # 13b. community-organisation segment
    set co_seg [file join $campaign_dir community-organisation]
    set co_contacts [spar::classify_segment $co_seg]
    set co_counts [spar::progress_counts $co_contacts]
    assert_eq [dict get $co_counts valid] 73 "golden community-organisation: valid=73"
    assert_eq [dict get $co_counts profiled] 73 "golden community-organisation: profiled=73"
}

# ════════════════════════════════════════════════════════════════════════
# 15. T6/T7 zero tasks (PROFILE_STALE undefined)
# ════════════════════════════════════════════════════════════════════════
section "15. T6/T7 zero tasks (PROFILE_STALE undefined)"

set seg_t67 [make_temp_segment]
write_profile $seg_t67 "t67-profiled"
write_profile $seg_t67 "t67-approached"
write_approach_yaml $seg_t67 "t67-approached" [approach_yaml_final_unsent]
write_profile $seg_t67 "t67-sent"
write_approach_yaml $seg_t67 "t67-sent" [approach_yaml_final_sent_email]
write_roster_tsv $seg_t67 $::std_headers [list \
    [make_base_row {contact_name "Disco" stem ""}] \
    [make_base_row {contact_name "Prof" stem "t67-profiled"}] \
    [make_base_row {contact_name "App" stem "t67-approached"}] \
    [make_base_row {contact_name "Sent" stem "t67-sent"}] \
]
set ct67 [spar::classify_segment $seg_t67]

set t6_results [spar::transition_eligible $ct67 "T6"]
assert_eq [llength $t6_results] 0 "T6: zero tasks (PROFILE_STALE undefined)"

set t7_results [spar::transition_eligible $ct67 "T7"]
assert_eq [llength $t7_results] 0 "T7: zero tasks (PROFILE_STALE undefined)"

# ════════════════════════════════════════════════════════════════════════
# 16. progress_counts edge cases
# ════════════════════════════════════════════════════════════════════════
section "16. progress_counts edge cases"

# 16a. Empty segment (headers only, no data rows) → all counts = 0
set seg_empty [make_temp_segment]
write_roster_tsv $seg_empty $::std_headers [list]
set c_empty [spar::classify_segment $seg_empty]
set counts_empty [spar::progress_counts $c_empty]
assert_eq [dict get $counts_empty valid] 0 "empty segment: valid=0"
assert_eq [dict get $counts_empty profiled] 0 "empty segment: profiled=0"
assert_eq [dict get $counts_empty star3] 0 "empty segment: star3=0"
assert_eq [dict get $counts_empty approached_star3] 0 "empty segment: approached_star3=0"
assert_eq [dict get $counts_empty email_sent] 0 "empty segment: email_sent=0"
assert_eq [dict get $counts_empty email_replied] 0 "empty segment: email_replied=0"

# 16b. All EXCLUDED contacts → valid=0, all other counts=0
set seg_inv [make_temp_segment]
write_roster_tsv $seg_inv $::std_headers [list \
    [make_base_row {contact_name "Inv A" date_excluded "2026-01-01" stem ""}] \
    [make_base_row {contact_name "Inv B" date_excluded "2026-02-01" stem ""}] \
]
set c_inv [spar::classify_segment $seg_inv]
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
set c_lo [spar::classify_segment $seg_lo]
set counts_lo [spar::progress_counts $c_lo]
assert_eq [dict get $counts_lo valid] 1 "star=2: valid=1"
assert_eq [dict get $counts_lo profiled] 1 "star=2: profiled=1"
assert_eq [dict get $counts_lo star3] 0 "star=2: star3=0"
assert_eq [dict get $counts_lo approached_star3] 0 "star=2: approached_star3=0"

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
# 20. --json integration test (spar-progress.tcl)
# ════════════════════════════════════════════════════════════════════════
section "20. --json integration test"

package require json

proc make_temp_campaign {} {
    set base [file join /tmp "spar-campaign-test-[pid]-[clock microseconds]"]
    file mkdir $base
    lappend ::cleanup_dirs $base
    return $base
}

proc write_campaign_yaml {campaign_dir content} {
    set path [file join $campaign_dir campaign.yaml]
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
    return $path
}

set cdir [make_temp_campaign]
set seg_a [file join $cdir seg-a]
file mkdir $seg_a
file mkdir [file join $seg_a profiles]
file mkdir [file join $seg_a approach]
write_roster_tsv $seg_a $::std_headers [list \
    [make_base_row {stem "alice" contact_name "Alice" star_rating "5" email "a@test.com"}] \
    [make_base_row {stem "bob" contact_name "Bob" star_rating "3" email "b@test.com"}] \
]
write_profile $seg_a "alice"
write_campaign_yaml $cdir "campaign: Test Campaign\nsegments:\n  - seg-a\nfilter:\n  min_star: 3\n"

set progress_script [file join $script_dir .. spar-progress.tcl]
set json_str [exec tclsh9.0 $progress_script $cdir --json 2>/dev/null]
set parsed [::json::json2dict $json_str]

assert_eq [dict get $parsed campaign] "Test Campaign" "json: campaign value"
assert_eq [dict exists $parsed totals] 1 "json: has totals"
set jtotals [dict get $parsed totals]
assert_eq [dict exists $jtotals qualified] 1 "json: totals has qualified"
set jq [dict get $jtotals qualified]
assert_eq [dict exists $jq email] 1 "json: qualified has email"
set je [dict get $jq email]
assert_eq [dict exists $je approached] 1 "json: email has approached"
set ja [dict get $je approached]
assert_eq [dict exists $ja sent] 1 "json: approached has sent"
set js [dict get $ja sent]
assert_eq [dict exists $js replied] 1 "json: sent has replied"
assert_eq [dict exists $parsed segments] 1 "json: has segments"
assert_eq [llength [dict get $parsed segments]] 1 "json: one segment"
assert_eq [dict exists $parsed transitions] 1 "json: has transitions"
assert_eq [llength [dict get $parsed transitions]] 7 "json: 7 transitions"
assert_eq [dict exists $parsed warnings] 1 "json: has warnings"
assert_eq [dict exists $parsed validation] 1 "json: has validation"

# Test YAML-as-positional-arg
set json_str2 [exec tclsh9.0 $progress_script [file join $cdir campaign.yaml] --json 2>/dev/null]
set parsed2 [::json::json2dict $json_str2]
assert_eq [dict get $parsed2 campaign] "Test Campaign" "json: YAML as positional arg"

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
set cn1 [spar::classify_segment $seg_n1]
assert_eq [llength $cn1] 1 "blank-name: segment includes row"
assert_eq [dict get [lindex $cn1 0] state] "DISCOVERED" "blank-name: contact_name empty + no profile → DISCOVERED"

# 13b. contact_name empty, date_excluded set → EXCLUDED
set seg_n2 [make_temp_segment]
write_roster_tsv $seg_n2 $::std_headers [list \
    [make_base_row {contact_name "" stem "defunct-co" \
        date_excluded "2026-04-07"}] \
]
set cn2 [spar::classify_segment $seg_n2]
assert_eq [llength $cn2] 1 "blank-name excluded: segment includes row"
assert_eq [dict get [lindex $cn2 0] state] "EXCLUDED" "blank-name + date_excluded → EXCLUDED"

# 13c. progress_counts includes blank-name DISCOVERED row in Valid
set seg_n3 [make_temp_segment]
write_roster_tsv $seg_n3 $::std_headers [list \
    [make_base_row {contact_name "Named Contact" stem "named-contact"}] \
    [make_base_row {contact_name "" stem "nameless-org" \
        organisation_name "Nameless Org" date_excluded ""}] \
]
set cn3 [spar::classify_segment $seg_n3]
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
    s_note p_note star_rating response_likelihood a_note r_note
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
        response_likelihood "" \
        a_note            "" \
        r_note            "" \
    ]
    dict for {k v} $overrides {
        dict set row $k $v
    }
    return $row
}

# Helper: classify a segment and run validate_roster, return issues
proc vr_issues {segment_dir} {
    set contacts [spar::classify_segment $segment_dir]
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

# ── Assertion 7: response_likelihood without star_rating ──
set seg_vr7 [make_temp_segment]
write_roster_tsv $seg_vr7 $::vr_headers [list \
    [make_vr_row {stem s1 star_rating "" response_likelihood "80"}] \
]
set issues_vr7 [vr_issues $seg_vr7]
assert_eq [has_issue $issues_vr7 roster_likelihood_without_star] 1 \
    "A7: response_likelihood without star_rating flagged"

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
section "22. validate_approach — structural validation (approach-schema.yaml)"
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
generated_for:
  contact_name: Test
  organisation: Test Org
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
generated_for:
  contact_name: Test
  organisation: Test Org
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
generated_for:
  contact_name: Test
  organisation: Test Org
response_likelihood: 50
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
  warmth: warm
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
assert_eq [spar::has_transition_runner T3] 1 "routing: T3 is wired"
assert_eq [spar::has_transition_runner T4] 1 "routing: T4 is wired"
assert_eq [spar::has_transition_runner T6] 1 "routing: T6 is wired"
assert_eq [spar::has_transition_runner T7] 1 "routing: T7 is wired"
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
assert_eq [_runner_class T6] ::spar::transitions::ProfileTransition "routing: T6 → ProfileTransition"
assert_eq [_runner_class T2] ::spar::transitions::ApproachTransition "routing: T2 → ApproachTransition"
assert_eq [_runner_class T7] ::spar::transitions::ApproachTransition "routing: T7 → ApproachTransition"
assert_eq [_runner_class T3] ::spar::transitions::SendEmailTransition "routing: T3 → SendEmailTransition"
assert_eq [_runner_class T4] ::spar::transitions::CheckRepliesTransition "routing: T4 → CheckRepliesTransition"
foreach _tid {T1 T2 T3 T4 T6 T7} {
    assert_eq [lindex [spar::transition_runner $_tid] 1] run \
        "routing: $_tid runner verb is `run`"
}

set _routing_err ""
catch {spar::transition_runner T8} _routing_err
assert_match $_routing_err "no runner*" "routing: T8 lookup errors"

# ════════════════════════════════════════════════════════════════════════
# 24c. spar::filter_approaches_by_stems — T4 cohort narrowing (issue #73)
# ════════════════════════════════════════════════════════════════════════
section "24c. spar::filter_approaches_by_stems — T4 cohort narrowing"

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
    return "generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
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
    return {generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
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
set t9_contacts [spar::classify_segment $t9_seg]
set t9_ready [spar::transition_eligible $t9_contacts "T9" email $t9_cdata $t9_today]
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
set t9_contacts2 [spar::classify_segment $t9_seg2]
set t9_pend [spar::transition_eligible $t9_contacts2 "T9" email $t9_cdata $t9_today]
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
set t9_contacts3 [spar::classify_segment $t9_seg3]
set t9_blocked [spar::transition_eligible $t9_contacts3 "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_blocked] 0 \
    "T9 state-gated: contact in REPLIED (primary replied) → no T9 row"

# ── T9 not visible: primary not sent yet (no preceding signal to wait on) ──
set t9_seg4 [make_temp_segment]
write_profile $t9_seg4 "contact-4"
write_approach_yaml $t9_seg4 "contact-4" [t9_yaml_primary_unsent]
write_roster_tsv $t9_seg4 $t9_headers [list \
    [make_base_row {contact_name "C4" star_rating 4 email "test@acme-venues.au" phone "0412 000 000" stem "contact-4"}]]
set t9_contacts4 [spar::classify_segment $t9_seg4]
set t9_noop [spar::transition_eligible $t9_contacts4 "T9" email $t9_cdata $t9_today]
assert_eq [llength $t9_noop] 0 \
    "T9 none: primary unsent → no T9 row (don't show 'preceding not yet sent' noise)"

# ── T9 zero without cdata ──
set t9_no_cdata [spar::transition_eligible $t9_contacts "T9" email]
assert_eq [llength $t9_no_cdata] 0 \
    "T9 zero when cdata omitted (back-compat with pre-#41 callers)"

# ── T9 zero when campaign lacks secondary_channel ──
set t9_primary_only_cdata [dict create primary_channel email]
set t9_zero [spar::transition_eligible $t9_contacts "T9" email $t9_primary_only_cdata $t9_today]
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
    return "generated_for:
  contact_name: Test Contact
  organisation: Test Org
response_likelihood: 50
decisions:
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
set t10_contacts [spar::classify_segment $t10_seg]
set t10_ready [spar::transition_eligible $t10_contacts "T10" email $t10_cdata $t9_today]
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
set t10_contacts2 [spar::classify_segment $t10_seg2]
set t10_pend [spar::transition_eligible $t10_contacts2 "T10" email $t10_cdata $t9_today]
assert_eq [llength $t10_pend] 1 "T10 pending: secondary sent 2d ago → 1 pending"
assert_match [dict get [lindex $t10_pend 0] reason] "*waiting until day 5*" \
    "T10 pending names the wait threshold"

# ── T10 zero if tertiary slot absent ──
set t10_no_tert [spar::transition_eligible $t10_contacts "T10" email $t9_cdata $t9_today]
assert_eq [llength $t10_no_tert] 0 \
    "T10 zero when campaign has no tertiary_channel slot"

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

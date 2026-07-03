#!/usr/bin/env tclsh9.0
# test-email.tcl — Test suite for spar-email.tcl
#
# Run:  tclsh9.0 test/test-email.tcl
# Exit: 0 on all pass, 1 on any failure.

package require yaml

# ── Source the library under test ────────────────────────────────────────
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-email.tcl]

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

proc assert_contains {haystack needle label} {
    if {[string first $needle $haystack] == -1} {
        puts "FAIL: $label"
        puts "  expected to contain: $needle"
        puts "  actual:   $haystack"
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

# ── Helpers: temporary directories ─────────────────────────────────────

proc make_temp_dir {} {
    set base [file join /tmp "spar-email-test-[pid]-[clock microseconds]"]
    file mkdir $base
    lappend ::cleanup_dirs $base
    return $base
}

proc make_temp_segment {} {
    set base [make_temp_dir]
    file mkdir [file join $base profiles]
    file mkdir [file join $base approach]
    return $base
}

proc write_approach_yaml {segment_dir stem content} {
    set path [file join $segment_dir approach "${stem}.yaml"]
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
    return $path
}

proc cleanup_temps {} {
    foreach dir $::cleanup_dirs {
        if {[file isdirectory $dir]} {
            file delete -force $dir
        }
    }
    set ::cleanup_dirs {}
}

# ════════════════════════════════════════════════════════════════════════
# 1. extract_email_address
# ════════════════════════════════════════════════════════════════════════
section "1. extract_email_address"

assert_eq [spar::extract_email_address "John Smith <john@example.com>"] \
    "john@example.com" \
    "extract from Name <email> format"

assert_eq [spar::extract_email_address "john@example.com"] \
    "john@example.com" \
    "extract bare email"

assert_eq [spar::extract_email_address "  JOHN@EXAMPLE.COM  "] \
    "john@example.com" \
    "bare email with whitespace and uppercase"

assert_eq [spar::extract_email_address "\"Smith, John\" <John.Smith@Example.COM>"] \
    "john.smith@example.com" \
    "quoted display name with uppercase email"

assert_eq [spar::extract_email_address ""] \
    "" \
    "empty string"

# ════════════════════════════════════════════════════════════════════════
# 2. html_to_text
# ════════════════════════════════════════════════════════════════════════
section "2. html_to_text"

assert_eq [spar::html_to_text "Hello <b>world</b>!"] \
    "Hello world!" \
    "strip inline tags"

assert_eq [spar::html_to_text "Line1<br>Line2<br/>Line3"] \
    "Line1\nLine2\nLine3" \
    "br tags become newlines"

assert_eq [spar::html_to_text "<div>Para 1</div><div>Para 2</div>"] \
    "Para 1\nPara 2" \
    "div tags become newlines"

assert_eq [spar::html_to_text "Before<blockquote>Quoted text</blockquote>After"] \
    "Before\nAfter" \
    "blockquote content stripped"

assert_eq [spar::html_to_text "Hello &amp; goodbye &lt;world&gt;"] \
    "Hello & goodbye <world>" \
    "HTML entities decoded"

# Test forwarded-message truncation
set html_fwd "New content\nFrom: Someone"
assert_eq [spar::html_to_text $html_fwd] \
    "New content" \
    "truncate at From: marker"

set html_orig "New content\n-----Original Message-----\nOld stuff"
assert_eq [spar::html_to_text $html_orig] \
    "New content" \
    "truncate at Original Message marker"

set html_quote "New content\n> quoted line\nmore"
assert_eq [spar::html_to_text $html_quote] \
    "New content" \
    "truncate at > quoted line"

# ════════════════════════════════════════════════════════════════════════
# 3. fingerprint_match
# ════════════════════════════════════════════════════════════════════════
section "3. fingerprint_match"

set fps {"alice@example.com|2026-04-05T10:30:00" "bob@test.com|2026-04-06"}

assert_eq [spar::fingerprint_match $fps "alice@example.com" "2026-04-05T10:30:00"] 1 \
    "exact match"

assert_eq [spar::fingerprint_match $fps "alice@example.com" "2026-04-05T11:00:00"] 0 \
    "same sender, different time → no match"

assert_eq [spar::fingerprint_match $fps "bob@test.com" "2026-04-06T09:00:00"] 1 \
    "date-only legacy match"

assert_eq [spar::fingerprint_match $fps "unknown@test.com" "2026-04-05T10:30:00"] 0 \
    "different sender → no match"

# Test empty-from legacy match
set fps_empty {"|2026-04-07T12:00:00"}
assert_eq [spar::fingerprint_match $fps_empty "someone@test.com" "2026-04-07T12:00:00"] 1 \
    "empty-from legacy entry matches any sender"

# Test empty-from date-only match
set fps_empty2 {"|2026-04-07"}
assert_eq [spar::fingerprint_match $fps_empty2 "someone@test.com" "2026-04-07T15:00:00"] 1 \
    "empty-from date-only legacy entry matches any sender"

# Empty existing set
assert_eq [spar::fingerprint_match {} "alice@example.com" "2026-04-05"] 0 \
    "empty fingerprint set → no match"

# ════════════════════════════════════════════════════════════════════════
# 4. send_email (removed)
# ════════════════════════════════════════════════════════════════════════
# The SES send flow lives on spar::ses::send_one (per-row helper) and
# the ses_send Pool worker; its dry-run path is covered by
# test/test-pool.tcl section 14 rather than a unit test here.

# ════════════════════════════════════════════════════════════════════════
# 5. stamp_actioned_date
# ════════════════════════════════════════════════════════════════════════
section "5. stamp_actioned_date"

# 5a. Stamp unsent email in final round
set seg [make_temp_segment]
set yaml_content {decisions:
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
set ap [write_approach_yaml $seg "stamp-test" $yaml_content]
set changed [spar::stamp_actioned_date $ap "2026-04-10"]
assert_eq $changed 1 "stamp_actioned_date returns 1 when file changed"

# Read back and verify
set fd [open $ap r]
set stamped [read $fd]
close $fd
assert_contains $stamped "actioned_date: 2026-04-10" "actioned_date stamped with today's date"
# replied_date should remain null
assert_contains $stamped "replied_date: null" "replied_date unchanged"

# 5b. Already stamped → no change
set changed2 [spar::stamp_actioned_date $ap "2026-04-11"]
assert_eq $changed2 0 "stamp_actioned_date returns 0 when already stamped"

# 5b2. channel=linkedin stamps the linkedin message and leaves the
# email message's actioned_date untouched.
set seg_li [make_temp_segment]
set yaml_li {decisions:
  channel: linkedin
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    mode: invite
    text: Hi, I would like to connect
    actioned_date: null
    replied_date: null
  - channel: email
    to: test@acme-venues.au
    subject: Follow-up subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
set ap_li [write_approach_yaml $seg_li "stamp-li" $yaml_li]
set changed_li [spar::stamp_actioned_date $ap_li "2026-07-03" linkedin]
assert_eq $changed_li 1 "stamp(linkedin) returns 1 when linkedin msg stamped"
set fd [open $ap_li r]; set stamped_li [read $fd]; close $fd
assert_contains $stamped_li "actioned_date: 2026-07-03" \
    "stamp(linkedin) stamps the linkedin message"
assert_contains $stamped_li "actioned_date: null" \
    "stamp(linkedin) leaves the email message unstamped"
set data_li [spar::read_approach_yaml $ap_li]
set li_msg [spar::final_channel_message $data_li linkedin]
set em_msg [spar::final_channel_message $data_li email]
assert_eq [dict get $li_msg mode] "invite" \
    "final_channel_message(linkedin) selects the linkedin message"
assert_eq [dict get $em_msg subject] "Follow-up subject" \
    "final_channel_message(email) selects the email message"

# 5c. No final round → no change
set seg2 [make_temp_segment]
set yaml_draft {decisions:
  channel: email
rounds:
- type: draft
  number: 1
  messages:
  - channel: email
    subject: Draft subject
    body: Draft body
    actioned_date: null
}
set ap2 [write_approach_yaml $seg2 "no-final" $yaml_draft]
set changed3 [spar::stamp_actioned_date $ap2 "2026-04-10"]
assert_eq $changed3 0 "stamp_actioned_date returns 0 when no final round"

# 5d. Non-email channel in final round → not stamped
set seg3 [make_temp_segment]
set yaml_linkedin {decisions:
  channel: linkedin
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    body: Hi, I would like to connect
    actioned_date: null
    replied_date: null
}
set ap3 [write_approach_yaml $seg3 "linkedin-only" $yaml_linkedin]
set changed4 [spar::stamp_actioned_date $ap3 "2026-04-10"]
assert_eq $changed4 0 "stamp_actioned_date skips non-email channels"

# 5e. Final linkedin message WITHOUT an actioned_date key (legal per the
# schema — lifecycle fields may be omitted, issue #160): the line is
# inserted at field indentation, the file still parses, the validator
# stays green, and a second stamp is a 0-no-change because the date is set.
set seg_ins [make_temp_segment]
set yaml_li_nokey {decisions:
  channel: linkedin
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    mode: invite
    text: Hi, I would like to connect
  - channel: email
    to: test@acme-venues.au
    subject: Follow-up subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
set ap_ins [write_approach_yaml $seg_ins "stamp-li-nokey" $yaml_li_nokey]
set changed_ins [spar::stamp_actioned_date $ap_ins "2026-07-04" linkedin]
assert_eq $changed_ins 1 "stamp(linkedin) returns 1 when actioned_date key inserted"
set fd [open $ap_ins r]; set stamped_ins [read $fd]; close $fd
assert_contains $stamped_ins "    actioned_date: 2026-07-04" \
    "inserted actioned_date line at field indentation"
assert_contains $stamped_ins "actioned_date: null" \
    "email message's actioned_date left null"
set data_ins [::yaml::yaml2dict $stamped_ins]
set li_msg_ins [spar::final_channel_message $data_ins linkedin]
# (the yaml package parses unquoted dates to epoch seconds, so assert
# parsed-non-null here; the exact text is asserted above)
assert_eq [spar::is_null [dict get $li_msg_ins actioned_date]] 0 \
    "file parses and linkedin message carries the inserted date"
assert_eq [llength [spar::_dbc_errors $ap_ins]] 0 \
    "DbC post-validation green after insertion"
set changed_ins2 [spar::stamp_actioned_date $ap_ins "2026-07-05" linkedin]
assert_eq $changed_ins2 0 "re-stamp returns 0 — date already set by insertion"

# 5f. Email-channel equivalent: final email message without the key, and
# with a multi-line body so the insertion lands after the literal block.
set seg_ins2 [make_temp_segment]
set yaml_em_nokey {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: |
      Hello there,

      Second paragraph.
a_note: trailing top-level key
}
set ap_ins2 [write_approach_yaml $seg_ins2 "stamp-em-nokey" $yaml_em_nokey]
set changed_em [spar::stamp_actioned_date $ap_ins2 "2026-07-04"]
assert_eq $changed_em 1 "stamp(email) returns 1 when actioned_date key inserted"
set fd [open $ap_ins2 r]; set stamped_em [read $fd]; close $fd
assert_contains $stamped_em "    actioned_date: 2026-07-04" \
    "inserted actioned_date line at field indentation (email)"
set data_em [::yaml::yaml2dict $stamped_em]
set em_msg_ins [spar::final_channel_message $data_em email]
assert_eq [spar::is_null [dict get $em_msg_ins actioned_date]] 0 \
    "file parses and email message carries the inserted date"
assert_contains [dict get $em_msg_ins body] "Second paragraph." \
    "multi-line body intact after insertion"
assert_eq [spar::dict_get_default $data_em a_note ""] "trailing top-level key" \
    "top-level key after rounds intact"
assert_eq [llength [spar::_dbc_errors $ap_ins2]] 0 \
    "DbC post-validation green after insertion (email)"
set changed_em2 [spar::stamp_actioned_date $ap_ins2 "2026-07-05"]
assert_eq $changed_em2 0 "re-stamp(email) returns 0 — date already set by insertion"

# ════════════════════════════════════════════════════════════════════════
# 6. append_reply_to_yaml
# ════════════════════════════════════════════════════════════════════════
section "6. append_reply_to_yaml"

# 6a. Append reply to approach with no existing replies
set seg4 [make_temp_segment]
set yaml_sent {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: contact@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: 2026-04-01
    replied_date: null
}
set ap4 [write_approach_yaml $seg4 "reply-test" $yaml_sent]
spar::append_reply_to_yaml $ap4 "2026-04-05T10:30:00" "John Smith <john@example.com>" "Thank you for reaching out."

set fd [open $ap4 r]
set replied [read $fd]
close $fd

assert_contains $replied "replies:" "replies section added"
assert_contains $replied "direction: received" "reply has direction: received"
assert_contains $replied "2026-04-05T10:30:00" "reply has timestamp"
assert_contains $replied "John Smith <john@example.com>" "reply has from display"
assert_contains $replied "Thank you for reaching out." "reply has body text"
assert_contains $replied "replied_date: 2026-04-05" "replied_date set on email message"

# 6b. Append second reply to approach with existing reply
spar::append_reply_to_yaml $ap4 "2026-04-06T14:00:00" "John Smith <john@example.com>" "Following up on my previous email."

set fd [open $ap4 r]
set replied2 [read $fd]
close $fd

assert_contains $replied2 "Following up on my previous email." "second reply appended"
assert_contains $replied2 "Thank you for reaching out." "first reply still present"

# 6c. Approach with no final round → no change
set seg5 [make_temp_segment]
set yaml_nofinal {decisions:
  channel: email
rounds:
- type: draft
  number: 1
  messages:
  - channel: email
    subject: Draft
    body: Draft body
}
set ap5 [write_approach_yaml $seg5 "no-final-reply" $yaml_nofinal]
set fd_before [open $ap5 r]
set before [read $fd_before]
close $fd_before

spar::append_reply_to_yaml $ap5 "2026-04-05" "someone@test.com" "Reply text"

set fd_after [open $ap5 r]
set after [read $fd_after]
close $fd_after

assert_eq $before $after "no final round → file unchanged"

# ════════════════════════════════════════════════════════════════════════
# 7. collect_sent_approaches
# ════════════════════════════════════════════════════════════════════════
section "7. collect_sent_approaches"

# 7a. Sent approach is collected
set seg6 [make_temp_segment]
write_approach_yaml $seg6 "sent-approach" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: contact@example.com
    subject: Hello
    body: Hi there
    actioned_date: 2026-04-01
    replied_date: null
}
set collected [spar::collect_sent_approaches [list $seg6]]
assert_eq [llength $collected] 1 "one sent approach collected"
set entry [lindex $collected 0]
assert_eq [dict get $entry to_email] "contact@example.com" "to_email extracted"
assert_eq [llength [dict get $entry fingerprints]] 0 "no fingerprints (no replies)"

# 7b. Unsent approach is not collected
set seg7 [make_temp_segment]
write_approach_yaml $seg7 "unsent-approach" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: unsent@example.com
    subject: Hello
    body: Hi there
    actioned_date: null
    replied_date: null
}
set collected2 [spar::collect_sent_approaches [list $seg7]]
assert_eq [llength $collected2] 0 "unsent approach not collected"

# 7c. Approach with existing replies has fingerprints
set seg8 [make_temp_segment]
write_approach_yaml $seg8 "replied-approach" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: replied@example.com
    subject: Hello
    body: Hi
    actioned_date: 2026-04-01
    replied_date: 2026-04-05
  replies:
  - direction: received
    date: "2026-04-05T10:30:00"
    from: "replied@example.com"
    body: "Thanks"
}
set collected3 [spar::collect_sent_approaches [list $seg8]]
assert_eq [llength $collected3] 1 "replied approach collected"
set fps [dict get [lindex $collected3 0] fingerprints]
assert_eq [llength $fps] 1 "one fingerprint from existing reply"
assert_eq [lindex $fps 0] "replied@example.com|2026-04-05T10:30:00" "fingerprint format correct"

# 7d. Multiple segments
set collected_multi [spar::collect_sent_approaches [list $seg6 $seg8]]
assert_eq [llength $collected_multi] 2 "approaches from multiple segments collected"

# 7e. No approach directory → no results
set seg_empty [make_temp_dir]
set collected_empty [spar::collect_sent_approaches [list $seg_empty]]
assert_eq [llength $collected_empty] 0 "segment without approach dir → empty"

# ════════════════════════════════════════════════════════════════════════
# 8. stamp_actioned_date preserves formatting
# ════════════════════════════════════════════════════════════════════════
section "8. stamp_actioned_date formatting preservation"

set seg9 [make_temp_segment]
set yaml_multiline {decisions:
  channel: email
rounds:
- type: final
  number: 1
  notes: |
    This approach has multi-line notes.
    Keep them intact.
  messages:
  - channel: email
    to: format@acme-venues.au
    subject: Formatting test
    body: |
      Dear Sir,

      This is a multi-line body.
      Please preserve it.
    actioned_date: null
    replied_date: null
}
set ap9 [write_approach_yaml $seg9 "format-test" $yaml_multiline]
spar::stamp_actioned_date $ap9 "2026-04-10"

set fd [open $ap9 r]
set formatted [read $fd]
close $fd

assert_contains $formatted "actioned_date: 2026-04-10" "actioned_date stamped"
assert_contains $formatted "This approach has multi-line notes." "notes preserved"
assert_contains $formatted "Dear Sir," "body preserved"
assert_contains $formatted "replied_date: null" "replied_date still null"

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

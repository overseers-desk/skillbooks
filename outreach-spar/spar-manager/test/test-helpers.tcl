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
proc make_temp_dir {} {
    set base [file join /tmp "spar-test-[pid]-[clock microseconds]"]
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
#   -profile_date -star_rating -yield
#   -contact_name -organisation -role -date_excluded  (snapshot fields)
proc write_profile {segment_dir stem args} {
    set path [file join $segment_dir profiles "${stem}.md"]
    array set opts {
        -profile_date    2026-04-12
        -star_rating     4
        -yield           2
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
    to: test@acme-venues.au
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
    to: test@acme-venues.au
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
    to: test@acme-venues.au
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

proc approach_yaml_final_unsent_linkedin {} {
    return {decisions:
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

proc approach_yaml_final_replied_linkedin {} {
    return {decisions:
  channel: linkedin
rounds:
- type: final
  number: 1
  messages:
  - channel: linkedin
    body: Hi, I would like to connect
    actioned_date: 2026-04-01
    replied_date: 2026-04-05
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
    to: test@acme-venues.au
    subject: Following up
    body: Hello there
    actioned_date: null
    replied_date: null
}
}

proc approach_yaml_final_phone_only {} {
    return {decisions:
  channel: phone
rounds:
- type: final
  number: 1
  messages:
  - channel: phone
    to: "+61 400 000 000"
    text: Call intro
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

proc finish_tests {} {
    cleanup_temps
    puts ""
    puts "════════════════════════════════════════════════════════════════"
    puts "Results: $::passes passed, $::failures failed"
    puts "════════════════════════════════════════════════════════════════"
    exit [expr {$::failures > 0 ? 1 : 0}]
}

proc issues_with_code {issues code} {
    set result {}
    foreach issue $issues { if {[dict get $issue code] eq $code} { lappend result $issue } }
    return $result
}
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

proc write_segment_yaml {segment_dir content} {
    set path [file join $segment_dir segment.yaml]
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
    return $path
}

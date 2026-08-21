#!/usr/bin/env tclsh9.0
# test-roster-patch.tcl — spar::apply_roster_patch / apply_approach_patch:
# declaration-and-apply roster mediation. Covers: patch applies, re-apply
# is inert (stamp), a stamped patch leaves a later human roster edit
# standing, masked email rejected pre-apply, star sync fires on drift and
# leaves excluded rows alone.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set tmpdir [exec mktemp -d /tmp/spar-test-roster-patch.XXXXXX]
set roster [file join $tmpdir roster.tsv]
set profile [file join $tmpdir jane-doe-acme.md]

proc write_test_roster {path {email ""} {star 3}} {
    set fd [open $path w]
    puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating postcode} \t]
    puts $fd [join [list jane-doe-acme "Jane Doe" Acme "" "" $email "" "" 1 test "" "" "" $star 4211] \t]
    close $fd
}

proc write_test_profile {path fm_lines} {
    set fd [open $path w]
    puts $fd "---"
    foreach l $fm_lines { puts $fd $l }
    puts $fd "---"
    puts $fd ""
    puts $fd "# Profile: Jane Doe"
    close $fd
}

proc roster_field {path field} {
    set rows [spar::load_roster $path]
    foreach r $rows {
        if {[dict get $r stem] eq "jane-doe-acme"} {
            return [dict getdef $r $field ""]
        }
    }
    return "(row missing)"
}

# 1. Patch applies: email lands on the row, stamp lands in the profile.
write_test_roster $roster
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 4"
    "yield: 5"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"\""
    "roster_patch:"
    "  email: jane@acme.example"
    "  phone: 07 5555 0000"
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme]
assert_eq [llength $issues] 0 "clean patch returns no issues"
assert_eq [roster_field $roster email] "jane@acme.example" "patched email applied"
assert_eq [roster_field $roster phone] "07 5555 0000" "patched phone applied"
assert_eq [roster_field $roster star_rating] 4 "star synced from front matter"
set fd [open $profile r]; set ptext [read $fd]; close $fd
assert_match $ptext "*roster_patch_applied:*" "stamp written into front matter"

# 2. Stamped patch is inert: a later human roster edit stands.
spar::update_roster_field $roster stem jane-doe-acme email human@corrected.example
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme]
assert_eq [llength $issues] 0 "re-apply returns no issues"
assert_eq [roster_field $roster email] "human@corrected.example" "human edit survives stamped re-apply"

# 3. Star sync still fires on drift even when the patch is stamped.
spar::update_roster_field $roster stem jane-doe-acme star_rating 1
spar::apply_roster_patch $profile $roster jane-doe-acme
assert_eq [roster_field $roster star_rating] 4 "star drift re-synced from profile home"

# 4. Excluded row: star stays as the excluder set it.
spar::update_roster_field $roster stem jane-doe-acme date_excluded 2026-07-18
spar::update_roster_field $roster stem jane-doe-acme star_rating 0
spar::apply_roster_patch $profile $roster jane-doe-acme
assert_eq [roster_field $roster star_rating] 0 "excluded row's star left alone"

# 5. Masked email rejected pre-apply; roster untouched.
write_test_roster $roster
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 3"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"\""
    "roster_patch:"
    "  email: \"j***@acme.example\""
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme]
assert_eq [llength $issues] 1 "masked email yields one issue"
assert_match [dict get [lindex $issues 0] code] patch_masked_email "issue code is patch_masked_email"
assert_eq [roster_field $roster email] "" "roster untouched on rejection"
set fd [open $profile r]; set ptext [read $fd]; close $fd
assert_eq [string match "*roster_patch_applied*" $ptext] 0 "no stamp on rejection"

# 6. rows_new: a found row lands with sweep_iteration copied from the
# profiled contact; a second apply is inert.
proc write_test_sweep {path} {
    set fd [open $path w]
    puts $fd {version: "1.0"}
    puts $fd "segment: roster"
    puts $fd "market_estimate:"
    puts $fd "  value: 120"
    puts $fd "  derivation: top-down"
    puts $fd {  estimated: "2026-08-06"}
    puts $fd "sources:"
    puts $fd "  - name: State register"
    puts $fd "    type: registry"
    puts $fd "    status: unharvested"
    puts $fd "  - name: Local paper"
    puts $fd "    type: outlet"
    puts $fd "    status: exhausted — archive read to 2019"
    puts $fd "exclusions: none"
    puts $fd "escapes: \[\]"
    puts $fd "rounds: \[\]"
    close $fd
}
set sweep [file join $tmpdir roster.sweep.yaml]
write_test_roster $roster
write_test_sweep $sweep
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 3"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"\""
    "rows_new:"
    "  - stem: bob-roe-beta"
    "    contact_name: Bob Roe"
    "    organisation: Beta"
    "    email: bob@beta.example"
    "    discovered_via: \"profile:jane-doe-acme · named as co-organiser on Jane's page\""
    "sources_new:"
    "  - name: \"web search: \\\"marriage officiant\\\"\""
    "    type: platform"
    "    status: unharvested"
    "    note: probe found 6 unrostered hits"
    "    discovered_via: profile:jane-doe-acme"
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme $sweep]
assert_eq [llength $issues] 0 "rows_new + sources_new apply clean"
set rows [spar::load_roster $roster]
assert_eq [llength $rows] 2 "found row appended"
set bob [lindex $rows 1]
assert_eq [dict get $bob stem] bob-roe-beta "appended row is the declared stem"
assert_eq [dict get $bob sweep_iteration] 1 "sweep_iteration copied from the profiled row"
assert_match [dict get $bob discovered_via] "profile:jane-doe-acme*" "discovered_via kept as declared"
set data [spar::read_sweep_yaml $sweep]
assert_eq [llength [dict get $data sources]] 3 "census gained the declared source"
set newsrc [lindex [dict get $data sources] end]
assert_eq [dict get $newsrc name] {web search: "marriage officiant"} "source name as declared"
assert_eq [dict get $newsrc discovered_via] profile:jane-doe-acme "source carries discovered_via"
assert_eq [spar::sweep_source_open [dict get $newsrc status]] 1 "new source is open work for T0"
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme $sweep]
assert_eq [llength $issues] 0 "stamped re-apply returns no issues"
assert_eq [llength [spar::load_roster $roster]] 2 "stamped re-apply appends no row"
assert_eq [llength [dict get [spar::read_sweep_yaml $sweep] sources]] 3 "stamped re-apply appends no source"

# 7. Rejections leave roster and census untouched: a stem already held,
# a source already in the census (even exhausted), a source with no
# sweep file.
write_test_roster $roster
write_test_sweep $sweep
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 3"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"\""
    "roster_patch:"
    "  email: jane@acme.example"
    "rows_new:"
    "  - stem: jane-doe-acme"
    "    contact_name: Jane Doe"
    "    discovered_via: profile:jane-doe-acme"
    "sources_new:"
    "  - name: Local paper"
    "    type: outlet"
    "    status: unharvested"
    "    discovered_via: profile:jane-doe-acme"
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme $sweep]
set codes [lsort [lmap i $issues {dict get $i code}]]
assert_eq $codes {duplicate_source duplicate_stem} "held stem and known source both rejected"
assert_eq [roster_field $roster email] "" "patch not applied when a sibling declaration is rejected"
assert_eq [llength [spar::load_roster $roster]] 1 "no row appended on rejection"
assert_eq [llength [dict get [spar::read_sweep_yaml $sweep] sources]] 2 "no source appended on rejection"
set fd [open $profile r]; set ptext [read $fd]; close $fd
assert_eq [string match "*roster_patch_applied*" $ptext] 0 "no stamp on rejection"

write_test_roster $roster
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 3"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"\""
    "sources_new:"
    "  - name: New register"
    "    type: registry"
    "    status: unharvested"
    "    discovered_via: profile:jane-doe-acme"
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme]
assert_eq [lmap i $issues {dict get $i code}] sources_new_no_sweep "sources_new without a sweep file is rejected"

# 8. Approach-side patch: applies and appends the stamp as a root line.
write_test_roster $roster
set approach [file join $tmpdir jane-doe-acme.yaml]
set fd [open $approach w]
puts $fd "decisions:"
puts $fd "  channel: email"
puts $fd "rounds:"
puts $fd "  - type: final"
puts $fd "    messages: \[\]"
puts $fd "roster_patch:"
puts $fd "  email: found@send.example"
close $fd
set issues [spar::apply_approach_patch $approach $roster jane-doe-acme]
assert_eq [llength $issues] 0 "approach patch clean"
assert_eq [roster_field $roster email] "found@send.example" "approach patch applied"
spar::update_roster_field $roster stem jane-doe-acme email human2@corrected.example
spar::apply_approach_patch $approach $roster jane-doe-acme
assert_eq [roster_field $roster email] "human2@corrected.example" "stamped approach patch inert"

file delete -force $tmpdir
puts "test-roster-patch: all assertions passed"

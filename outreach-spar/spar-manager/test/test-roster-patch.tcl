#!/usr/bin/env tclsh9.0
# test-roster-patch.tcl — spar::apply_roster_patch / apply_approach_patch:
# declaration-and-apply roster mediation. Covers: patch applies, re-apply
# is inert (stamp), a stamped patch leaves a later human roster edit
# standing, masked email rejected pre-apply, star sync fires on drift and
# leaves excluded rows alone, a resolved name that would duplicate a live
# person excludes the nameless row instead of naming it (#201).

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state

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

# 8. validate_profile on the declarations: a discovered_via not leading
# with profile:<stem> and a source outside the type vocabulary are errors;
# the well-formed set from case 6 passes clean.
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
    "rows_new:"
    "  - stem: bob-roe-beta"
    "    contact_name: Bob Roe"
    "    organisation: Beta"
    "    discovered_via: co-organiser on Jane's page"
    "sources_new:"
    "  - name: Beta newsletter"
    "    type: magazine"
    "    status: unharvested"
    "    discovered_via: profile:someone-else"
}
set row [lindex [spar::load_roster $roster] 0]
set codes [lsort -unique [lmap i [spar::validate_profile $profile $row "Jane Doe"] {dict get $i code}]]
assert_eq [expr {"discovered_via_not_profile" in $codes}] 1 "discovered_via without the profile:<stem> lead is flagged"
assert_eq [expr {"invalid_source_type" in $codes}] 1 "source type outside the vocabulary is flagged"
assert_eq [llength [lsearch -all -inline -glob [lmap i [spar::validate_profile $profile $row "Jane Doe"] {dict get $i message}] "*profile:jane-doe-acme*"]] 2 "both entries name the expected lead"
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
    "    discovered_via: \"profile:jane-doe-acme · co-organiser on Jane's page\""
    "sources_new:"
    "  - name: Beta newsletter"
    "    type: outlet"
    "    status: unharvested"
    "    discovered_via: profile:jane-doe-acme"
}
set errs [lmap i [spar::validate_profile $profile $row "Jane Doe"] {expr {[dict get $i severity] eq "error" ? [dict get $i code] : [continue]}}]
assert_eq $errs {} "well-formed rows_new and sources_new validate clean"

# 9. Approach-side patch: applies and appends the stamp as a root line.
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

# 10. A resolved name that would make a nameless row a same-person
# duplicate (#201): the name is not written, the nameless row is excluded
# as the duplicate with the canonical stem in p_note, and the error tells
# the worker to rewrite its deliverable as the exclusion profile.
proc write_dup_roster {path {canon_excluded ""} {nameless_p_note ""}} {
    set fd [open $path w]
    puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating postcode} \t]
    puts $fd [join [list jo-mackenzie-amare-ceramics "Jo Mackenzie" "Amare Ceramics" Owner "" jo@amare.example "" "" 1 test $canon_excluded "" "" 4 4211] \t]
    puts $fd [join [list amare-ceramics "" "Amare Ceramics" "" "" "" "" "" 2 test "" "" $nameless_p_note 3 4211] \t]
    close $fd
}
proc row_of {path stem} {
    foreach r [spar::load_roster $path] {
        if {[dict get $r stem] eq $stem} { return $r }
    }
    return {}
}
set dup_profile [file join $tmpdir amare-ceramics.md]
set named_fm {
    "profile_date: 2026-08-10"
    "star_rating: 4"
    "yield: 3"
    "dependent_data:"
    "  contact_name: Jo Mackenzie"
    "  organisation: Amare Ceramics"
    "  role: Owner"
    "  date_excluded: \"\""
    "roster_patch:"
    "  contact_name: Jo Mackenzie"
    "  role: Owner"
    "  email: jo@amare.example"
    "rows_new:"
    "  - stem: sam-lee-kiln-works"
    "    contact_name: Sam Lee"
    "    organisation: Kiln Works"
    "    discovered_via: \"profile:amare-ceramics · named as Jo's kiln partner\""
    "sources_new:"
    "  - name: Ceramics guild list"
    "    type: registry"
    "    status: unharvested"
    "    discovered_via: profile:amare-ceramics"
}
set today [clock format [clock seconds] -format %Y-%m-%d]
write_dup_roster $roster
write_test_sweep $sweep
write_test_profile $dup_profile $named_fm
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics $sweep {roster_patch {} appended 0}]
assert_eq [lmap i $issues {dict get $i code}] patch_duplicate_person "the collision is one patch_duplicate_person issue"
assert_eq [dict get [lindex $issues 0] severity] error "and it is an error, so the fix turn rewrites the deliverable"
assert_match [dict get [lindex $issues 0] message] "*jo-mackenzie-amare-ceramics*exclusion profile*" "the message names the canonical row and the rewrite asked for"
set nr [row_of $roster amare-ceramics]
assert_eq [dict get $nr contact_name] "" "the resolved name is not written"
assert_eq [dict get $nr role] "" "nor the role"
assert_eq [dict get $nr email] "" "nor the channel"
assert_eq [dict get $nr date_excluded] $today "the nameless row is excluded"
assert_eq [dict get $nr star_rating] 0 "at star 0"
assert_eq [dict get $nr p_note] "duplicate of jo-mackenzie-amare-ceramics: resolved to Jo Mackenzie at Amare Ceramics" "p_note names the canonical row"
set cr [row_of $roster jo-mackenzie-amare-ceramics]
assert_eq [list [dict get $cr contact_name] [dict get $cr star_rating] [dict get $cr date_excluded]] {{Jo Mackenzie} 4 {}} "the canonical row is untouched"
assert_eq [llength [spar::load_roster $roster]] 2 "rows_new waits for a clean turn"
assert_eq [llength [dict get [spar::read_sweep_yaml $sweep] sources]] 2 "sources_new waits for a clean turn"
set fd [open $dup_profile r]; set ptext [read $fd]; close $fd
assert_eq [string match "*roster_patch_applied*" $ptext] 0 "no stamp while the deliverable still names the person"
set live_pairs [lmap r [spar::load_roster $roster] {
    expr {[dict get $r date_excluded] eq "" && [dict get $r contact_name] ne ""
          ? "[string tolower [dict get $r contact_name]]|[string tolower [dict get $r organisation]]" : [continue]}}]
assert_eq [llength $live_pairs] [llength [lsort -unique $live_pairs]] "no live (contact_name, organisation) pair repeats"

# A fix turn that still declares the name: the same error, the
# exclusion's date and note as they were, the note not doubled.
spar::update_roster_field $roster stem amare-ceramics date_excluded 2026-08-10
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics $sweep {roster_patch {} appended 0}]
assert_eq [lmap i $issues {dict get $i code}] patch_duplicate_person "a turn still naming the person is refused again"
set nr [row_of $roster amare-ceramics]
assert_eq [dict get $nr date_excluded] 2026-08-10 "the exclusion keeps its date"
assert_eq [dict get $nr p_note] "duplicate of jo-mackenzie-amare-ceramics: resolved to Jo Mackenzie at Amare Ceramics" "the note is not appended twice"
assert_eq [dict get $nr contact_name] "" "the name is still not written"

# The fix turn that does as asked: an exclusion profile with no name in
# its patch applies clean, and the deferred rows_new and sources_new land.
write_test_profile $dup_profile {
    "profile_date: 2026-08-10"
    "star_rating: 0"
    "yield: 0"
    "dependent_data:"
    "  contact_name: null"
    "  organisation: Amare Ceramics"
    "  role: null"
    "  date_excluded: 2026-08-10"
    "rows_new:"
    "  - stem: sam-lee-kiln-works"
    "    contact_name: Sam Lee"
    "    organisation: Kiln Works"
    "    discovered_via: \"profile:amare-ceramics · named as Jo's kiln partner\""
    "sources_new:"
    "  - name: Ceramics guild list"
    "    type: registry"
    "    status: unharvested"
    "    discovered_via: profile:amare-ceramics"
}
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics $sweep {roster_patch {} appended 0}]
assert_eq $issues {} "the rewritten exclusion profile applies clean"
assert_eq [llength [spar::load_roster $roster]] 3 "its rows_new lands"
assert_eq [llength [dict get [spar::read_sweep_yaml $sweep] sources]] 3 "its sources_new lands"
set nr [row_of $roster amare-ceramics]
assert_eq [list [dict get $nr contact_name] [dict get $nr date_excluded] [dict get $nr star_rating]] {{} 2026-08-10 0} "the row stays nameless and excluded"

# The pair is compared as validate_roster compares it: trimmed and case
# folded, so a differently cased resolution collides too, with no record
# given (the reconcile path) as with one.
write_dup_roster $roster
write_test_profile $dup_profile {
    "profile_date: 2026-08-10"
    "star_rating: 4"
    "roster_patch:"
    "  contact_name: \" jo mackenzie \""
    "  organisation: AMARE CERAMICS"
}
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics]
assert_eq [lmap i $issues {dict get $i code}] patch_duplicate_person "case and spacing do not hide the collision"
assert_eq [dict get [row_of $roster amare-ceramics] contact_name] "" "and the name is not written"

# An excluded canonical row is no live person: validate_roster leaves it
# out, so the name is written and nothing is excluded.
write_dup_roster $roster 2026-01-01
write_test_profile $dup_profile {
    "profile_date: 2026-08-10"
    "star_rating: 4"
    "roster_patch:"
    "  contact_name: Jo Mackenzie"
}
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics "" {roster_patch {} appended 0}]
assert_eq $issues {} "against an excluded row the resolution applies clean"
set nr [row_of $roster amare-ceramics]
assert_eq [list [dict get $nr contact_name] [dict get $nr date_excluded] [dict get $nr star_rating]] {{Jo Mackenzie} {} 4} "the name lands and the row stays live"

# A different person at the same organisation is no duplicate.
write_dup_roster $roster
write_test_profile $dup_profile {
    "profile_date: 2026-08-10"
    "star_rating: 3"
    "roster_patch:"
    "  contact_name: Ana Ruiz"
}
set issues [spar::apply_roster_patch $dup_profile $roster amare-ceramics "" {roster_patch {} appended 0}]
assert_eq $issues {} "a second person at the organisation applies clean"
assert_eq [dict get [row_of $roster amare-ceramics] contact_name] "Ana Ruiz" "and is named"

file delete -force $tmpdir
puts "test-roster-patch: all assertions passed"

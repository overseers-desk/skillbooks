#!/usr/bin/env tclsh9.0
# test-date-convention.tcl — the bare-date convention across its
# boundaries: dates are written bare in YAML, tcllib types them to epoch
# seconds, write_roster renders date_excluded ISO at the funnel, and a
# quoted date (arriving as an ISO string) fails validation. Covers:
# write_roster normalisation, apply_roster_patch end-to-end with a bare
# date, yaml_scalar bare-date emission, profile / seed / sweep-return
# quoted-date errors.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::validate

set tmpdir [exec mktemp -d /tmp/spar-test-date-convention.XXXXXX]
set roster [file join $tmpdir roster.tsv]
set profile [file join $tmpdir jane-doe-acme.md]

proc write_test_roster {path} {
    set fd [open $path w]
    puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating} \t]
    puts $fd [join [list jane-doe-acme "Jane Doe" Acme "" "" "" "" "" 1 test "" "" "" 3] \t]
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
    return ""
}

# 1. write_roster renders an epoch date_excluded as YYYY-MM-DD.
write_test_roster $roster
set rows [spar::load_roster $roster]
set epoch [clock scan 2026-07-18 -format %Y-%m-%d]
set rows [lmap r $rows {dict replace $r date_excluded $epoch}]
spar::write_roster $roster $rows
assert_eq [roster_field $roster date_excluded] "2026-07-18" \
    "write_roster renders epoch date_excluded ISO"

# 2. write_roster leaves an ISO date_excluded and other integer columns alone.
set rows [spar::load_roster $roster]
set rows [lmap r $rows {dict replace $r sweep_iteration 3}]
spar::write_roster $roster $rows
assert_eq [roster_field $roster date_excluded] "2026-07-18" \
    "ISO date_excluded passes through unchanged"
assert_eq [roster_field $roster sweep_iteration] "3" \
    "integer non-date column untouched"

# 3. apply_roster_patch end-to-end: a bare front-matter date lands ISO.
write_test_roster $roster
write_test_profile $profile {
    "profile_date: 2026-07-18"
    "star_rating: 0"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: 2026-07-18"
    "roster_patch:"
    "  date_excluded: 2026-07-18"
    "  p_note: out of scope for the segment"
}
set issues [spar::apply_roster_patch $profile $roster jane-doe-acme]
assert_eq [llength $issues] 0 "bare-date patch applies clean"
assert_eq [roster_field $roster date_excluded] "2026-07-18" \
    "bare front-matter date reaches the TSV as ISO"

# 4. yaml_scalar: an exact ISO date emits bare; a date-led longer string
# still quotes (YAML 1.1 would read date-plus-time as a timestamp).
assert_eq [spar::yaml_scalar 2026-07-18] "2026-07-18" \
    "exact date emits bare"
assert_eq [spar::yaml_scalar "2026-07-18 10:00:00"] "\"2026-07-18 10:00:00\"" \
    "date-led longer string stays quoted"

# 5. validate_profile: a quoted date (ISO string post-parse) errors; the
# bare form passes. The profile from section 3 is all-bare: no quoted_date.
set row [lindex [spar::load_roster $roster] 0]
set issues [spar::validate_profile $profile $row "Jane Doe"]
set quoted [lmap i $issues {expr {[dict get $i code] eq "quoted_date" ? $i : [continue]}}]
assert_eq [llength $quoted] 0 "bare dates pass profile validation"
write_test_profile $profile {
    "profile_date: \"2026-07-18\""
    "star_rating: 0"
    "yield: 2"
    "dependent_data:"
    "  contact_name: Jane Doe"
    "  organisation: Acme"
    "  role: \"\""
    "  date_excluded: \"2026-07-18\""
    "roster_patch:"
    "  date_excluded: \"2026-07-18\""
    "  p_note: out of scope for the segment"
}
set issues [spar::validate_profile $profile $row "Jane Doe"]
set quoted [lmap i $issues {expr {[dict get $i code] eq "quoted_date" ? $i : [continue]}}]
assert_eq [llength $quoted] 3 \
    "quoted profile_date and both date_excluded each error"

# 6. sweep-return rows: an epoch date_excluded passes (the funnel renders
# it), a quoted one errors, garbage still errors.
proc sweep_return_issues {dx} {
    set fm [dict create source_status exhausted reconciliation matched \
        rows_new [list \
            [dict create stem jane-doe-acme contact_name "Jane Doe" \
                organisation Acme date_excluded $dx]]]
    return [spar::validate_sweep_return_data $fm]
}
assert_eq [llength [sweep_return_issues $epoch]] 0 "epoch date_excluded accepted"
set issues [sweep_return_issues "2026-07-18"]
assert_match [dict get [lindex $issues 0] message] "*was quoted*" \
    "quoted date_excluded rejected"
set issues [sweep_return_issues "late july"]
assert_match [dict get [lindex $issues 0] message] "*not a date*" \
    "non-date date_excluded rejected"

# 7. approach validation: a quoted actioned_date or roster_patch date
# errors; the bare form (epoch post-parse) passes.
proc approach_data {dx} {
    return [dict create \
        decisions [dict create channel email] \
        rounds [list [dict create type final messages [list \
            [dict create channel email subject S body B to a@b.example \
                actioned_date $dx]]]] \
        roster_patch [dict create date_excluded $dx]]
}
set codes [lmap i [spar::validate_approach_data \
        [approach_data "2026-07-18"] "" a@b.example "Jane Doe"] \
    {dict get $i code}]
assert_eq [llength [lsearch -all -exact $codes quoted_date]] 2 \
    "quoted actioned_date and roster_patch.date_excluded each error"
set codes [lmap i [spar::validate_approach_data \
        [approach_data $epoch] "" a@b.example "Jane Doe"] \
    {dict get $i code}]
assert_eq [expr {"quoted_date" in $codes}] 0 "bare approach dates pass"

# 8. validate_seed: a quoted segment date errors, a bare one passes.
set segbase [file join $tmpdir seg]
proc write_seed {segbase datestr} {
    set fd [open "$segbase.yaml" w]
    puts $fd "version: \"2.0\""
    puts $fd "title: Test segment"
    puts $fd "date: $datestr"
    puts $fd "target_type: qualification-only"
    puts $fd "provenance: test"
    puts $fd "discovery_criteria: |-"
    puts $fd "  anyone"
    puts $fd "rating_rubric: |-"
    puts $fd "  stars"
    close $fd
    set fd [open "$segbase.sweep.yaml" w]
    puts $fd "version: \"2.0\""
    puts $fd "segment: seg"
    puts $fd "market_estimate:"
    puts $fd "  value: 10"
    puts $fd "  derivation: test"
    puts $fd "  estimated: $datestr"
    puts $fd "sources:"
    puts $fd "  - name: reg"
    puts $fd "    type: registry"
    puts $fd "    status: open"
    puts $fd "exclusions: none"
    puts $fd "escapes: \[\]"
    puts $fd "rounds: \[\]"
    close $fd
}
write_seed $segbase 2026-07-18
set codes [lmap i [spar::validate_seed $segbase] {dict get $i code}]
assert_eq [expr {"quoted_date" in $codes}] 0 "bare seed dates pass"
write_seed $segbase "\"2026-07-18\""
set codes [lmap i [spar::validate_seed $segbase] {dict get $i code}]
assert_eq [llength [lsearch -all -exact $codes quoted_date]] 2 \
    "quoted segment date and sweep estimated each error"

file delete -force $tmpdir
finish_tests

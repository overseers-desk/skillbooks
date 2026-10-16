#!/usr/bin/env tclsh9.0
# test-patch-provenance.tcl — whose roster_patch_applied stamp counts
# (#209). A worker holds Write on its deliverable and copies the stamp
# line from a finished sibling it reads as an example; the harness keeps
# its own record of what landed, so a stamp it did not write skips
# nothing, and its own stamp replaces the copy rather than doubling it.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::harness
package require spar::prompts

set tmpdir [exec mktemp -d /tmp/spar-test-patch-provenance.XXXXXX]
lappend ::cleanup_dirs $tmpdir

set seg_dir [file join $tmpdir segments seg]
file mkdir $seg_dir
set roster [spar::roster_path_for_segment $seg_dir]
set stem jane-doe-acme
set profile [spar::profile_path_for_stem $seg_dir $stem]

proc write_roster {path} {
    set fd [open $path w]
    puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating} \t]
    puts $fd [join [list jane-doe-acme "" Acme "" "" "" "" "" 1 test "" "" "" 3] \t]
    close $fd
}

# A profile as the worker leaves it: a roster_patch naming the contact,
# and optionally the stamp line copied from a sibling.
proc write_profile {path {extra {}}} {
    set fd [open $path w]
    puts $fd "---"
    foreach l [list \
        "profile_date: 2026-09-15" \
        "star_rating: 4" \
        "yield: 3" \
        "dependent_data:" \
        "  contact_name: Jane Doe" \
        "  organisation: Acme" \
        "  role: Director" \
        "  date_excluded: \"\"" \
        "roster_patch:" \
        "  contact_name: Jane Doe" \
        "  role: Director" \
        "  p_note: found on the company page" \
        {*}$extra] {
        puts $fd $l
    }
    puts $fd "---"
    puts $fd ""
    puts $fd "# Profile: Jane Doe"
    close $fd
}

proc roster_field {path field} {
    foreach r [spar::load_roster $path] {
        if {[dict get $r stem] eq "jane-doe-acme"} { return [dict getdef $r $field ""] }
    }
    return "(row missing)"
}

proc stamp_lines {path} {
    set fd [open $path r]; set t [read $fd]; close $fd
    return [llength [regexp -all -inline -line {^roster_patch_applied:.*$} $t]]
}

proc make_harness {seg_dir roster stem profile} {
    set pdir [file join $::tmpdir prompts $stem]
    file mkdir $pdir
    set fd [open [file join $pdir meta.env] w]
    puts $fd "STEM=\"$stem\""
    puts $fd "OUTFILE=\"$profile\""
    puts $fd "ROSTER_PATH=\"$roster\""
    close $fd
    set h [spar::ProfileHarness new $pdir [file join $::tmpdir logs]]
    $h load_my_meta
    return $h
}

# ════════════════════════════════════════════════════════════════════════
section "1. The applier's applied record overrides the file's stamp"
# ════════════════════════════════════════════════════════════════════════

# No record: the stamp says the file's own patch landed, so only cells
# that have gone blank since are written, and a human's edit stands.
write_roster $roster
spar::update_roster_field $roster stem $stem role "Chair"
write_profile $profile {"roster_patch_applied: 2026-09-15"}
assert_eq [llength [spar::apply_roster_patch $profile $roster $stem]] 0 \
    "no record: the file's stamp decides, as the startup reconcile reads it"
assert_eq [roster_field $roster contact_name] "Jane Doe" \
    "a stamped file with no record refills a blank cell"
assert_eq [roster_field $roster role] "Chair" \
    "a stamped file with no record leaves a human's edit"

write_roster $roster
set issues [spar::apply_roster_patch $profile $roster $stem "" \
    [dict create roster_patch {} appended 0]]
assert_eq [llength $issues] 0 "a record of nothing applied: the patch applies clean"
assert_eq [roster_field $roster contact_name] "Jane Doe" "contact_name reached the row"
assert_eq [roster_field $roster p_note] "found on the company page" "p_note reached the row"
assert_eq [stamp_lines $profile] 1 "the harness's stamp replaced the copied line"

# A key already applied at the same value is not rewritten, so a human's
# later edit of it stands; a key the record lacks lands.
spar::update_roster_field $roster stem $stem role "Managing Director"
write_profile $profile {"  email: jane@acme.example" "roster_patch_applied: 2026-09-15"}
spar::apply_roster_patch $profile $roster $stem "" [dict create \
    roster_patch {contact_name {Jane Doe} role Director p_note {found on the company page}} \
    appended 1]
assert_eq [roster_field $roster role] "Managing Director" \
    "an applied key is not replayed over the human's edit"
assert_eq [roster_field $roster email] "jane@acme.example" \
    "a key added since the record lands"

# ════════════════════════════════════════════════════════════════════════
section "2. ProfileHarness: a stamp copied during the turn is ignored"
# ════════════════════════════════════════════════════════════════════════

write_roster $roster
file delete $profile
set h [make_harness $seg_dir $roster $stem $profile]
# The worker's turn: it reads a stamped sibling and writes the stamp too.
write_profile $profile {"roster_patch_applied: 2026-09-15"}
set errs [$h validate_profile_errors 1]
set hard [lmap e $errs {expr {[dict get $e severity] eq "error" ? $e : [continue]}}]
assert_eq $hard {} "the profile validates with no errors"
assert_eq [roster_field $roster contact_name] "Jane Doe" \
    "the patch landed despite the copied stamp"
assert_eq [roster_field $roster role] "Director" "role landed"
assert_eq [stamp_lines $profile] 1 "one stamp line in the front matter"

# A fix turn that adds a key after the first apply gets it applied, and
# keys already applied are not rewritten.
spar::update_roster_field $roster stem $stem p_note "operator's note"
write_profile $profile {"  phone: 07 5555 0000" "roster_patch_applied: 2026-09-15"}
$h validate_profile_errors 2
assert_eq [roster_field $roster phone] "07 5555 0000" "a key a fix turn adds lands"
assert_eq [roster_field $roster p_note] "operator's note" \
    "a key applied earlier in the run is not rewritten"
$h destroy

# ════════════════════════════════════════════════════════════════════════
section "3. ProfileHarness: a stamp present before the turn stands"
# ════════════════════════════════════════════════════════════════════════

# An earlier run applied and stamped this profile; a human then corrected
# the row. A re-profile that keeps the declaration must not replay it.
spar::update_roster_field $roster stem $stem role "Chair"
set h [make_harness $seg_dir $roster $stem $profile]
write_profile $profile {"  phone: 07 5555 0000" "roster_patch_applied: 2026-09-15"}
$h validate_profile_errors 1
assert_eq [roster_field $roster role] "Chair" \
    "the earlier run's declaration is not replayed over the human's edit"
$h destroy

# ════════════════════════════════════════════════════════════════════════
section "4. Approach: a copied stamp is ignored, a prior one stands"
# ════════════════════════════════════════════════════════════════════════

write_roster $roster
set approach [file join $tmpdir $stem.yaml]
proc write_approach {path email} {
    set fd [open $path w]
    puts $fd "decisions:"
    puts $fd "  channel: email"
    puts $fd "roster_patch:"
    puts $fd "  email: $email"
    puts $fd "roster_patch_applied: 2026-09-15"
    close $fd
}
write_approach $approach found@send.example
set issues [spar::apply_approach_patch $approach $roster $stem \
    [dict create roster_patch {}]]
assert_eq [llength $issues] 0 "approach patch clean"
assert_eq [roster_field $roster email] "found@send.example" \
    "the approach patch landed despite the copied stamp"
assert_eq [stamp_lines $approach] 1 "one stamp line in the approach"
assert_eq [dict exists [spar::read_approach_yaml $approach] roster_patch_applied] 1 \
    "the approach still parses with its stamp"

# ApproachHarness reads its record before the author writes.
set apdir [file join $tmpdir prompts approach-$stem]
file mkdir $apdir
set fd [open [file join $apdir meta.env] w]
puts $fd "MAX_PASSES=1"
puts $fd "OUTFILE=\"$approach\""
puts $fd "CONTACT_SUMMARY=\"Jane Doe | Acme\""
puts $fd "SEGMENT_DIR=\"$seg_dir\""
close $fd
spar::update_roster_field $roster stem $stem email human@corrected.example
set ah [spar::ApproachHarness new $apdir [file join $tmpdir logs]]
$ah load_my_meta
$ah apply_declarations
assert_eq [roster_field $roster email] "human@corrected.example" \
    "a stamp present before the run stands"
$ah destroy

file delete $approach
set ah [spar::ApproachHarness new $apdir [file join $tmpdir logs]]
$ah load_my_meta
write_approach $approach second@send.example
$ah apply_declarations
assert_eq [roster_field $roster email] "second@send.example" \
    "a stamp the author wrote during the run is ignored"
$ah destroy

# ════════════════════════════════════════════════════════════════════════
section "5. A re-profile refills a cell gone blank since the earlier apply"
# ════════════════════════════════════════════════════════════════════════

# An earlier run applied contact_name and role and stamped the profile;
# some writer has since blanked both cells. The re-profile declares the
# same values, and the snapshot names them, so they must land again or
# the snapshot check fails every retry.
write_roster $roster
write_profile $profile {"roster_patch_applied: 2026-08-01"}
set h [make_harness $seg_dir $roster $stem $profile]
write_profile $profile {"roster_patch_applied: 2026-09-15"}
set errs [$h validate_profile_errors 1]
set hard [lmap e $errs {expr {[dict get $e severity] eq "error" ? $e : [continue]}}]
assert_eq $hard {} "the re-profile validates with no errors"
assert_eq [roster_field $roster contact_name] "Jane Doe" \
    "contact_name refilled into the blank cell"
assert_eq [roster_field $roster role] "Director" \
    "role refilled: the rule covers every column, not only contact_name"
$h destroy

# A blank cell whose recorded value was blank stays blank: there is
# nothing to refill with.
set r [dict create stem $stem p_note ""]
assert_eq [spar::_patch_unapplied {p_note {}} {p_note {}} $r] {} \
    "a blank recorded value refills nothing"
assert_eq [spar::_patch_unapplied {p_note x} {p_note x} \
    [dict create stem $stem p_note "  "]] {p_note x} \
    "a whitespace-only cell counts as blank"

# ════════════════════════════════════════════════════════════════════════
section "6. Startup reconcile refills blank cells from stamped profiles"
# ════════════════════════════════════════════════════════════════════════

set cdir [make_temp_campaign]
set rseg [file join $cdir segments seg]
file mkdir $rseg
write_segment_yaml $rseg "title: seg\nversion: \"2.0\"\n"
set rroster [spar::roster_path_for_segment $rseg]
set fd [open $rroster w]
puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating} \t]
puts $fd [join [list jane-doe-acme "" Acme "" "" "" "" "" 1 test "" "" "" 4] \t]
puts $fd [join [list john-roe-acme "John Q Roe" Acme "" "" "" "" "" 1 test "" "" "" 4] \t]
close $fd
write_profile [spar::profile_path_for_stem $rseg jane-doe-acme] \
    {"roster_patch_applied: 2026-08-01"}
set jp [spar::profile_path_for_stem $rseg john-roe-acme]
write_profile $jp {"roster_patch_applied: 2026-08-01"}
set fd [open $jp r]; set t [read $fd]; close $fd
set fd [open $jp w]; puts -nonewline $fd [string map {"Jane Doe" "John Roe"} $t]; close $fd
write_campaign_yaml $cdir \
    "campaign: Refill\nversion: \"$spar::CURRENT_SPEC_VERSION\"\nsegments:\n  - seg\n"
catch {spar::p::prepare_for_pool \
    [dict create campaign_file [file join $cdir campaigns camp.yaml] \
        stems {jane-doe-acme}] \
    {apply {args {}}}}
set rows [spar::load_roster $rroster]
assert_eq [dict get [lindex $rows 0] contact_name] "Jane Doe" \
    "the reconcile refilled the blank contact_name from the stamped profile"
assert_eq [dict get [lindex $rows 0] role] "Director" \
    "and the blank role"
assert_eq [dict get [lindex $rows 1] contact_name] "John Q Roe" \
    "a non-blank cell that differs from the profile is left as the human set it"
assert_eq [stamp_lines $jp] 1 "the reconcile adds no stamp line"

# ════════════════════════════════════════════════════════════════════════
section "7. rows_new: a prior stamp covers only what the prior file declared"
# ════════════════════════════════════════════════════════════════════════

proc row_count {path} { return [llength [spar::load_roster $path]] }
set bob_rows [list \
    "rows_new:" \
    "  - stem: bob-roe-beta" \
    "    contact_name: Bob Roe" \
    "    organisation: Beta" \
    "    discovered_via: \"profile:jane-doe-acme · named on Jane's page\""]

write_roster $roster
write_profile $profile {"roster_patch_applied: 2026-08-01"}
set h [make_harness $seg_dir $roster $stem $profile]
write_profile $profile [list {*}$bob_rows "roster_patch_applied: 2026-09-15"]
$h validate_profile_errors 1
assert_eq [row_count $roster] 2 \
    "a re-profile's rows_new lands when the prior file declared none"
$h destroy

# The prior file declared rows_new, so its stamp says they landed.
write_roster $roster
write_profile $profile [list {*}$bob_rows "roster_patch_applied: 2026-08-01"]
set h [make_harness $seg_dir $roster $stem $profile]
$h validate_profile_errors 1
assert_eq [row_count $roster] 1 \
    "a prior file's own rows_new is not appended again"
$h destroy

# ════════════════════════════════════════════════════════════════════════
section "8. A blank contact_name is rejected, not written"
# ════════════════════════════════════════════════════════════════════════

write_roster $roster
spar::update_roster_field $roster stem $stem contact_name "Jane Doe"
foreach blank {{""} {"  "}} {
    set fd [open $profile w]
    puts $fd "---\nprofile_date: 2026-09-15\nstar_rating: 4\nyield: 3"
    puts $fd "roster_patch:\n  contact_name: $blank\n  role: Director\n---\n"
    close $fd
    set issues [spar::apply_roster_patch $profile $roster $stem "" \
        [dict create roster_patch {} appended 0]]
    assert_eq [lmap i $issues {dict get $i code}] patch_blank_contact_name \
        "profile: contact_name $blank is rejected"
    assert_eq [roster_field $roster contact_name] "Jane Doe" \
        "profile: the roster keeps the name"
    assert_eq [roster_field $roster role] "" \
        "profile: the rejection holds back the whole patch"
}
set fd [open $approach w]
puts $fd "decisions:\n  channel: email\nroster_patch:\n  contact_name: \"\""
close $fd
set issues [spar::apply_approach_patch $approach $roster $stem \
    [dict create roster_patch {}]]
assert_eq [lmap i $issues {dict get $i code}] patch_blank_contact_name \
    "approach: a blank contact_name is rejected"
assert_eq [roster_field $roster contact_name] "Jane Doe" \
    "approach: the roster keeps the name"
set issues [spar::apply_approach_patch $approach $roster $stem]
assert_eq [lmap i $issues {dict get $i code}] patch_blank_contact_name \
    "approach without a record: an unstamped blank contact_name is rejected too"

# ════════════════════════════════════════════════════════════════════════
section "9. Approach: a blank cell is refilled, with or without a record"
# ════════════════════════════════════════════════════════════════════════

write_roster $roster
write_approach $approach found@send.example
assert_eq [spar::apply_approach_patch $approach $roster $stem] {} \
    "stamped approach, no record: clean"
assert_eq [roster_field $roster email] "found@send.example" \
    "stamped approach, no record: the blank email is refilled"
spar::update_roster_field $roster stem $stem email ""
spar::apply_approach_patch $approach $roster $stem \
    [dict create roster_patch {email found@send.example}]
assert_eq [roster_field $roster email] "found@send.example" \
    "harness record holding the value: the blank email is refilled"

finish_tests

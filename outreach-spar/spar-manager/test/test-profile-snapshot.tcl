#!/usr/bin/env tclsh9.0
# test-profile-snapshot.tcl — a profile's dependent_data snapshot against
# the roster row. P: once the declarations are applied, a snapshot that
# still disagrees with the row is a fix-loop error (#192). T3: a row whose
# snapshot agrees with the roster by the time it runs, before the worker's
# call or after a turn that wrote nothing, finishes DONE (#193).

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::harness

set tmpdir [exec mktemp -d /tmp/spar-test-profile-snapshot.XXXXXX]
lappend ::cleanup_dirs $tmpdir

set seg_dir [file join $tmpdir segments seg]
file mkdir $seg_dir
set roster [spar::roster_path_for_segment $seg_dir]
set stem jane-doe-acme
set profile [spar::profile_path_for_stem $seg_dir $stem]

proc write_roster {path name} {
    set fd [open $path w]
    puts $fd [join {stem contact_name organisation role phone email linkedin_url facebook_url sweep_iteration discovered_via date_excluded s_note p_note star_rating} \t]
    puts $fd [join [list jane-doe-acme $name Acme "" "" "" "" "" 1 test "" "" "" 4] \t]
    close $fd
}

proc write_profile {path {patch {}}} {
    set fd [open $path w]
    puts $fd "---"
    foreach l [list \
        "profile_date: 2026-09-15" \
        "star_rating: 4" \
        "yield: 3" \
        "dependent_data:" \
        "  contact_name: Jane Doe" \
        "  organisation: Acme" \
        "  role: \"\"" \
        "  date_excluded: \"\""] {
        puts $fd $l
    }
    if {[llength $patch]} {
        puts $fd "roster_patch:"
        foreach l $patch { puts $fd "  $l" }
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

proc make_prompt_dir {tag stem profile roster {stale 0}} {
    set pdir [file join $::tmpdir prompts-$tag $stem]
    file mkdir $pdir
    set fd [open [file join $pdir meta.env] w]
    puts $fd "STEM=\"$stem\""
    puts $fd "OUTFILE=\"$profile\""
    puts $fd "ROSTER_PATH=\"$roster\""
    if {$stale} { puts $fd "PROFILE_STALE=1" }
    close $fd
    return $pdir
}

proc issue_of {issues code} {
    foreach i $issues { if {[dict get $i code] eq $code} { return $i } }
    return {}
}

# ════════════════════════════════════════════════════════════════════════
section "1. P: a snapshot the patched row disagrees with is an error (#192)"
# ════════════════════════════════════════════════════════════════════════

# The worker resolved the name into dependent_data but declared no
# roster_patch for it, so the row keeps its blank name.
write_roster $roster ""
file delete $profile
set h [spar::ProfileHarness new [make_prompt_dir p1 $stem $profile $roster] \
    [file join $tmpdir logs]]
$h load_my_meta
write_profile $profile
set stale [issue_of [$h validate_profile_errors 1] stale_contact_name]
assert_eq [dict getdef $stale severity ""] error \
    "stale_contact_name is an error once the patch has applied"
assert_match [dict getdef $stale message ""] "*declare it in roster_patch*" \
    "the message names both ways to fix it"

# The fix turn declares the name; the harness applies it on re-validation.
write_profile $profile {"contact_name: Jane Doe"}
set errs [$h validate_profile_errors 2]
assert_eq [issue_of $errs stale_contact_name] {} "the snapshot now agrees with the row"
assert_eq [roster_field $roster contact_name] "Jane Doe" "the name reached the roster"
$h destroy

# A rejected patch leaves the row as it was, so the comparison proves
# nothing about the snapshot: it stays a warning.
write_roster $roster ""
file delete $profile
set h [spar::ProfileHarness new [make_prompt_dir p2 $stem $profile $roster] \
    [file join $tmpdir logs]]
$h load_my_meta
write_profile $profile {"email: \"j***@acme.example\""}
set errs [$h validate_profile_errors 1]
assert_eq [dict getdef [issue_of $errs patch_masked_email] severity ""] error \
    "the masked email is rejected"
assert_eq [dict getdef [issue_of $errs stale_contact_name] severity ""] warning \
    "against an unpatched row the snapshot comparison stays a warning"
$h destroy

# ════════════════════════════════════════════════════════════════════════
section "2. T3: a profile current by the time it runs finishes DONE (#193)"
# ════════════════════════════════════════════════════════════════════════

# Dispatched stale; the operator filled the roster's name while it queued.
write_profile $profile
write_roster $roster "Jane Doe"
set ph [spar::ProfileHarness new [make_prompt_dir t3a $stem $profile $roster 1] \
    [file join $tmpdir logs]]
oo::objdefine $ph {
    method inject_prefetch {} { error "must not prefetch for a current profile" }
    method do_profile_call {} { error "must not call the worker for a current profile" }
}
assert_eq [$ph run] 0 "a flagged row that is current before the call is DONE"
$ph destroy

# Still stale: the worker is called, and an untouched file still requeues.
write_roster $roster ""
set ::called 0
set ph [spar::ProfileHarness new [make_prompt_dir t3b $stem $profile $roster 1] \
    [file join $tmpdir logs]]
oo::objdefine $ph {
    method inject_prefetch {} { return 0 }
    method do_profile_call {} { incr ::called; return 0 }
    method validate_and_correct {o r s} { error "must not validate an untouched outfile" }
}
assert_eq [$ph run] 4 "a still-stale row whose worker wrote nothing requeues"
assert_eq $::called 1 "the worker was called"
$ph destroy

# The roster is corrected during the turn and the worker, finding the
# profile current, writes nothing: that is the right outcome.
set ph [spar::ProfileHarness new [make_prompt_dir t3c $stem $profile $roster 1] \
    [file join $tmpdir logs]]
oo::objdefine $ph {
    method inject_prefetch {} { return 0 }
    method do_profile_call {} {
        spar::update_roster_field $::roster stem jane-doe-acme contact_name "Jane Doe"
        return 0
    }
    method validate_and_correct {o r s} { error "must not validate an untouched outfile" }
}
assert_eq [$ph run] 0 "an untouched profile that now agrees with its row is DONE"
$ph destroy

# A re-author of a current profile carries no flag: the worker runs, and
# a turn that writes nothing still requeues (#181).
set ::called 0
set ph [spar::ProfileHarness new [make_prompt_dir t3d $stem $profile $roster] \
    [file join $tmpdir logs]]
oo::objdefine $ph {
    method inject_prefetch {} { return 0 }
    method do_profile_call {} { incr ::called; return 0 }
    method validate_and_correct {o r s} { error "must not validate an untouched outfile" }
}
assert_eq [$ph run] 4 "an unflagged untouched re-author requeues"
assert_eq $::called 1 "and its worker was called"
$ph destroy

finish_tests

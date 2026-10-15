#!/usr/bin/env tclsh9.0
# ProgressTable against a stub CampaignModel: contact rows under a
# segment row, and a roster that carries one stem twice (#109).
#
# Skipped when no Tk display is available.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

if {![info exists ::env(DISPLAY)] || $::env(DISPLAY) eq ""} {
    puts "  SKIP: no DISPLAY"
    finish_tests
}

package require Tk
wm withdraw .
set ::colours(totals_bg) "#e2e2e2"
source [file join $script_dir .. ui progress-table.tcl]

# Stub model: the four calls ProgressTable makes, over a fixed contact list.
oo::class create StubCampaign {
    variable Contacts
    constructor {contacts} { set Contacts $contacts }
    method subscribe {args} {}
    method get_segments {} {
        return [list [list seg-a [lrepeat 22 0]] [list seg-b [lrepeat 22 0]]]
    }
    method get_full_load_done {} { return 1 }
    method get_all_contacts {} { return $Contacts }
}

proc contact {seg stem name} {
    dict create _segment_dir /x/segments/$seg stem $stem contact_name $name \
        state PROFILED star 3 has_email 1 has_linkedin 0 has_facebook 0 \
        has_phone_only 0
}

# Counts the segment-loaded event carries, all zero.
set cdict [dict create]
foreach k {valid profiled star3 approachable approached_star3 has_email
           has_linkedin has_facebook has_phone_only sent replied} {
    dict set cdict $k 0
}

# Capture the table's warnings rather than print them.
set ::warned {}
proc capture_warn {msg} { lappend ::warned $msg }
${::spar::ui::progress_log}::logproc warn capture_warn

section "1. duplicate stem in one roster is skipped and logged (#109)"

set camp [StubCampaign new [list \
    [contact seg-a jane-acme      "Jane Prior"] \
    [contact seg-a bob-acme       "Bob Other"] \
    [contact seg-a jane-acme      "Paul Successor"] \
    [contact seg-b jane-acme      "Jane Elsewhere"]]]
ttk::frame .f
set pt [spar::ui::ProgressTable new $camp .f]
$pt populate

set rc [catch {$pt on_segment_loaded seg-a $cdict} err]
assert_eq $rc 0 "segment load survives a duplicate stem"
assert_eq [.f.tree children seg-a] {c:jane-acme c:bob-acme} "first row kept, duplicate not inserted"
assert_eq [.f.tree item c:jane-acme -text] "  Jane Prior" "kept row is the first one read"
assert_eq [llength $::warned] 1 "one warning for the one duplicate"
assert_match [lindex $::warned 0] "*jane-acme*seg-a*Paul Successor*" "warning names stem, segment and skipped row"

section "2. the same stem in a second segment is skipped too"

set ::warned {}
set rc [catch {$pt on_segment_loaded seg-b $cdict} err]
assert_eq $rc 0 "second segment's load survives the cross-segment duplicate"
assert_eq [.f.tree children seg-b] {} "cross-segment duplicate not inserted"
assert_eq [llength $::warned] 1 "cross-segment duplicate warned"

section "3. reloading a segment rebuilds its children"

set ::warned {}
$pt on_segment_loaded seg-a $cdict
assert_eq [.f.tree children seg-a] {c:jane-acme c:bob-acme} "children rebuilt"
assert_eq [llength $::warned] 1 "only the in-roster duplicate warns again"

finish_tests

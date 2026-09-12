#!/usr/bin/env tclsh9.0
# test-line-break-convention.tcl — the in-field line break across its
# boundaries. The roster TSV has no quoting, so a field value can hold
# neither a tab nor a newline; a line break inside a note travels as CR,
# which the row split does not see. Covers: write_roster's conversion at
# the funnel, the reader leaving CR intact, a multi-line note surviving a
# round trip on one physical line, a tab reported rather than spent, and
# note_to_lines rendering CR as lines for a prompt.

package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::validate

set tmpdir [exec mktemp -d /tmp/spar-test-line-break.XXXXXX]
set roster [file join $tmpdir roster.tsv]

set headers {stem contact_name organisation role phone email linkedin_url
             facebook_url sweep_iteration discovered_via date_excluded
             s_note p_note star_rating}

proc write_test_roster {path} {
    global headers
    set fd [open $path w]
    fconfigure $fd -translation lf
    puts $fd [join $headers \t]
    puts $fd [join [list jane-doe-acme "Jane Doe" Acme "" "" "" "" "" 1 test "" "" "" 3] \t]
    close $fd
}

proc roster_field {path field} {
    foreach r [spar::load_roster $path] {
        if {[dict get $r stem] eq "jane-doe-acme"} {
            return [dict getdef $r $field ""]
        }
    }
    return ""
}

proc physical_lines {path} {
    set fd [open $path r]
    fconfigure $fd -translation binary
    set raw [read $fd]
    close $fd
    return [llength [split [string trimright $raw \n] \n]]
}

section "1. write_roster converts a note's newlines to CR"
write_test_roster $roster
set note "First paragraph.\nSecond paragraph.\nThird."
set rows [lmap r [spar::load_roster $roster] {dict replace $r p_note $note}]
spar::write_roster $roster $rows
assert_eq [physical_lines $roster] 2 "header and one row; the note did not split it"
assert_eq [roster_field $roster p_note] "First paragraph.\rSecond paragraph.\rThird." \
    "each newline reached the file as CR"

section "2. a CRLF pair collapses to one CR"
set rows [lmap r [spar::load_roster $roster] {dict replace $r p_note "one\r\ntwo"}]
spar::write_roster $roster $rows
assert_eq [roster_field $roster p_note] "one\rtwo" "CRLF became a single CR"
assert_eq [physical_lines $roster] 2 "still one row"

section "3. a tab becomes a space, the format offering it no in-field form"
set rows [lmap r [spar::load_roster $roster] {dict replace $r p_note "left\tright"}]
spar::write_roster $roster $rows
assert_eq [roster_field $roster p_note] "left right" "the tab is a space"
assert_eq [llength [spar::load_roster $roster]] 1 "the column count held"

section "4. the reader leaves an already-CR value intact"
set fd [open $roster w]
fconfigure $fd -translation lf
puts $fd [join $headers \t]
puts $fd [join [list jane-doe-acme "Jane Doe" Acme "" "" "" "" "" 1 test "" "" "a\rb\rc" 3] \t]
close $fd
assert_eq [roster_field $roster p_note] "a\rb\rc" "CR read back as field content"

section "5. a CRLF row ending still reads as a row ending"
set fd [open $roster w]
fconfigure $fd -translation binary
puts -nonewline $fd "[join $headers \t]\r\n"
puts -nonewline $fd "[join [list jane-doe-acme "Jane Doe" Acme "" "" "" "" "" 1 test "" "" "p\rq" 3] \t]\r\n"
close $fd
assert_eq [llength [spar::load_roster $roster]] 1 "one row off a CRLF file"
assert_eq [roster_field $roster p_note] "p\rq" "and its in-field CR survived"

section "6. note_to_lines renders CR as lines for a reader outside the TSV"
assert_eq [spar::note_to_lines "a\rb"] "a\n  b" "indented so it stays inside a key: value shape"
assert_eq [spar::note_to_lines "a\rb" ""] "a\nb" "and bare when the caller wants no indent"

section "7. a worker's tab is reported; a worker's newline is not"
set seg [make_temp_segment]
write_roster_tsv $seg $headers [list [make_base_row]]
proc row_issues {seg lines} {
    set d [file join $seg deliverable.md]
    set fd [open $d w]
    puts $fd "---"
    foreach l $lines { puts $fd $l }
    puts $fd "---"
    close $fd
    return [spar::validate_sweep_return $d]
}
set issues [row_issues $seg {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: tabbed-row"
    "    contact_name: Dana Fox"
    "    organisation: \"Fox\tLtd\""
}]
assert_match [dict get [lindex [issues_with_code $issues invalid_row] 0] message] \
    "*holds a tab*" "a tab in a declared row is reported"
set issues [row_issues $seg {
    "source_status: partial — halfway"
    "reconciliation: 1 row returned."
    "rows_new:"
    "  - stem: noted-row"
    "    contact_name: Dana Fox"
    "    organisation: Fox Ltd"
    "    s_note: |"
    "      First paragraph."
    "      Second paragraph."
}]
assert_eq [llength [issues_with_code $issues invalid_row]] 0 \
    "a multi-line note in a declared row passes; the writer converts it"

file delete -force $tmpdir
file delete -force $seg
finish_tests

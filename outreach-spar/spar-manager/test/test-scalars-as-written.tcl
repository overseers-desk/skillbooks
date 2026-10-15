#!/usr/bin/env tclsh9.0
# Values tcllib yaml 0.4.2 parses without complaint yet returns other than
# written (spar::_pred_scalars_as_written): text after a closing quote,
# ': ' in an unquoted value, and a line that is none of key, list item,
# continuation or comment. Each is reported at its line, YAML that parses
# as written is not, and the approach, profile, seed and sweep-return
# validators hand the scan their file's text.
package require yaml
package require logger
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::validate
package require spar::email

# The line numbers reported: every issue the predicate returns, or the
# misparsed_scalar issues among a validator's.
proc lines_of {issues} {
    lmap i $issues {
        if {[dict getdef $i code misparsed_scalar] ne "misparsed_scalar"} continue
        regexp {^line (\d+),} [dict get $i message] -> n
        set n
    }
}
proc flagged {text} {
    lines_of [spar::_pred_scalars_as_written {} [dict create context [dict create raw $text]]]
}

section "each shape, at its line"

foreach {text want label} {
    "a: 1\nclaim: \"Saturdays\" imply weekly."  2 "text after a double-quoted value"
    "claim: 'Saturdays' imply weekly."           1 "text after a single-quoted value"
    "items:\n  - \"x y\" tail"                   2 "list item without a key"
    "items:\n  - claim: \"x y\" tail"            2 "list item with a key"
    "claim: \"opens\n  closes\" tail\nnext: 1"  2 "text after a quote closing on a later line"
    "source: page (Contact: +61493563028)"      1 "': ' in an unquoted value"
    "items:\n  - note: see Contact: here"       2 "': ' in a list item's value"
    "subject: Re:"                              1 "a value ending in ':'"
    "note: a long value\n  that goes: on"       2 "': ' in a continuation line"
    "a: 1\r\nnote: a: b\r\nc: 2\r\n"            2 "CRLF line ends"
    "---\nrole: Owner: sole\n---\nBody: not: YAML" 2 "front matter, counted from the fence"
    "a: 1\nb: 2\n</content>"                     3 "a leaked tag at the end of the file"
    "rounds:\n  - n: 1\n    final: true\n  </content>" 4 "a leaked tag inside a list"
    "a:\n  b: 1\n  stray words"                  3 "a bare line under a key that already has a value"
    "a: 1\n\"quoted stray\""                     2 "a bare quoted line where a key belongs"
    "a:\n  note: >-\n  under-indented text\nb: 1" 3 "block scalar text no deeper than its key"
    "c: \"x\" / the\n  rest of it\nd: 1"        1 "a dropped tail running on: one report"
} {
    assert_eq [flagged $text] $want $label
}

section "YAML that parses as written"

foreach {text label} {
    "# note: a: b\n\nkey: value"                      "comment and blank lines"
    "body: |\n  Re: your note: thanks\n\n  \"Hi\" Jane\nnext: 1" "block scalar lines, blank included"
    "- body: >-\n    folded: text: here\n  next: 1"    "folded block scalar in a list item"
    "tags: \[a, \"b\" c\]\nmap: {a: b}"               "flow collections"
    "claim: \"x: y\"  \nsource: 'it''s' # a: b"       "full quotes, then spaces or a comment"
    "note: \"opens: here\n  closes: there\"\nnext: 1" "a quote closing on a later line"
    "- see Contact: here\n- \"x: y\"\n- k: \"v\""     "list items with and without a key"
    "url: https://example.com/a:b\ntime: 10:30"       "a colon with no space after it"
    "said: He said\n  \"hello\" to them"               "a continuation opening with a quote"
    "\"quoted: key\": value"                          "a quoted key"
    "- map:\r\n    a: 1\r\n"                          "a key ending a CRLF line"
    "note:\n  a plain value\n    on two lines\nnext: 1" "a plain value on the lines below its key"
    "note:  # why\n  'quoted below'\nnext: 1"         "a quoted value below its key"
    "items:\n  -\n    bare item\n  - x"               "a list item's value on the next line"
    "a: 1\n---\nb: 2\n..."                            "document markers"
    "d: 'the tier''s\n  count: 3'\nnext: 1"           "a doubled quote before the line ends inside the value"
} {
    assert_eq [flagged $text] {} $label
}

section "the validators hand the scan their file's text"

set seg [make_temp_segment]
set ap [write_approach_yaml $seg jane [approach_yaml_final_unsent]]
assert_eq [spar::validate_approach $ap "" "Jane"] {} "a clean approach file yields no issue"
write_approach_yaml $seg jane [string map {"source: profile" "source: site (Contact: +61)"} \
    [approach_yaml_final_unsent]]
assert_eq [lines_of [spar::validate_approach $ap "" "Jane"]] 6 \
    "validate_approach reports the line"
assert_eq [lines_of [spar::validate_approach_data [spar::read_approach_yaml $ap] $ap "" "Jane"]] {} \
    "validate_approach_data has no text to scan"
write_approach_yaml $seg jane "[approach_yaml_final_unsent]</content>\n"
set leaked [llength [split [approach_yaml_final_unsent] \n]]
assert_eq [lines_of [spar::validate_approach $ap "" "Jane"]] $leaked \
    "validate_approach reports a leaked closing tag on its line"
write_approach_yaml $seg jane [string map {"source: profile" "source: site (Contact: +61)"} \
    [approach_yaml_final_unsent]]
assert_eq [spar::stamp_actioned_date $ap 2026-09-24] 1 \
    "a send is still stamped in a file carrying one"

set pp [write_profile_raw $seg jane "---\nprofile_date: 2026-09-24\nstar_rating: 3\nyield: 1\ndependent_data:\n  role: Owner: sole trader\n---\n\nNotes: the body: not YAML.\n"]
assert_eq [lines_of [spar::validate_profile $pp {} "Jane"]] 6 \
    "validate_profile reports a front-matter line"

set base [file join [make_temp_dir] segments seg]
file mkdir [file dirname $base]
proc put {path text} { set fd [open $path w]; puts -nonewline $fd $text; close $fd }
put $base.yaml "version: \"2.0\"\ntitle: Test\ndate: 2026-09-24\ndiscovery_criteria: anyone: who asks\n"
put $base.sweep.yaml "version: \"2.0\"\nsegment: seg\nexclusions: \"none\" so far\n"
assert_eq [lines_of [spar::validate_seed $base]] {4 3} \
    "validate_seed reports a line in each file of the pair"

set sr [file join [file dirname $base] return.md]
put $sr "---\nrows_new:\n  - stem: a-b\n    s_note: Contact: Bob, weekdays\n---\nBody.\n"
assert_eq [lines_of [spar::validate_sweep_return $sr]] 4 \
    "validate_sweep_return reports a front-matter line"

finish_tests

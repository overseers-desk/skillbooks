#!/usr/bin/env tclsh9.0
# The Inspector formats a profile body as markdown and shows message and
# reply bodies as written (#74). A message goes out text/plain, so its
# literal ** and # are what the recipient reads; the Inspector shows the
# same. Skipped when no Tk display is available.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

if {![info exists ::env(DISPLAY)] || $::env(DISPLAY) eq ""} {
    puts "  SKIP: no DISPLAY"
    finish_tests
}

package require Tk
package require spar::state
source [file join $script_dir .. ui subscribable.tcl]
source [file join $script_dir .. ui utils.tcl]
source [file join $script_dir .. ui markdown-view.tcl]
source [file join $script_dir .. ui collapsible.tcl]
source [file join $script_dir .. ui pane-viewer.tcl]
source [file join $script_dir .. ui inspector.tcl]

# text_widgets w — every Tk text widget under $w, in creation order.
proc text_widgets {w} {
    set out {}
    foreach c [winfo children $w] {
        if {[winfo class $c] eq "Text"} { lappend out $c }
        lappend out {*}[text_widgets $c]
    }
    return $out
}

# font_at tw pattern — the font of the first character of the first
# match of $pattern in $tw ("" when the text is absent or untagged).
proc font_at {tw pattern} {
    set idx [$tw search -exact -- $pattern 1.0 end]
    if {$idx eq ""} { return "" }
    foreach t [$tw tag names $idx] {
        set f [$tw tag cget $t -font]
        if {$f ne ""} { return $f }
    }
    return ""
}

section "1. markdown_view renders a profile-shaped document"

assert_eq $::spar::ui::markdown_view::have_markdown 1 "tcllib Markdown is available"

set md {# Jane Doe

## Career history

| Year | Role |
|------|------|
| 2020 | CEO |

She runs **Acme Events** and writes _the newsletter_ with `code` in it.
See [her site](https://acme-venues.au/jane) or <https://acme-venues.au>.
AT&T, 5 < 6.

- first point
- second point

1. one
2. two

> quoted line}

text .t1 -wrap word
pack .t1
::spar::ui::markdown_view::render .t1 $md
set out [.t1 get 1.0 end-1c]

assert_eq [string first "#" $out] -1 "no heading hash is left"
assert_eq [string first "**" $out] -1 "no bold marker is left"
assert_eq [string first "|" $out] -1 "no table pipe is left"
assert_match $out "Jane Doe\n\nCareer history\n\n*" "headings open the text, a blank line apart"
assert_match $out "*Year\tRole\n2020\tCEO*" "a table is tab-separated rows"
assert_match $out "*her site (https://acme-venues.au/jane)*" \
    "a link keeps its text, with its URL in brackets"
assert_match $out "*or https://acme-venues.au.*" \
    "a bare link is not repeated in brackets"
assert_match $out "*AT&T, 5 < 6.*" "entities are decoded"
assert_match $out "*• first point\n• second point*" "a bullet list"
assert_match $out "*1. one\n2. two*" "a numbered list"
assert_match $out "*quoted line" "a blockquote, with no trailing newline"
assert_eq [expr {[lsearch -glob [.t1 tag names] md_quote] >= 0}] 1 "the blockquote carries md_quote"

set h1 [font_at .t1 "Jane Doe"]
set p  [font_at .t1 "She runs"]
assert_eq [font actual $h1 -weight] bold "an h1 is bold"
assert_eq [expr {abs([font actual $h1 -size]) > abs([font actual $p -size])}] 1 \
    "an h1 is larger than body text"
assert_eq [font actual [font_at .t1 "Acme Events"] -weight] bold "strong is bold"
assert_eq [font actual [font_at .t1 "the newsletter"] -slant] italic "em is italic"
assert_eq [font actual [font_at .t1 "code"] -family] [font actual TkFixedFont -family] \
    "inline code is in the fixed font"
assert_eq [font actual [font_at .t1 "Year"] -weight] bold "a table header cell is bold"
assert_eq [font actual [font_at .t1 "2020"] -weight] normal "a table body cell is not"
assert_eq [.t1 tag bind [lindex [.t1 tag names [.t1 search -exact "her site" 1.0]] 0]] {} \
    "a link has no binding: it is not clickable"

section "1a. an underscore inside a word is text, not emphasis"

# tcllib's Markdown pairs intra-word underscores into emphasis, which
# would drop both from "linkedin_url and p_note".
text .t3 -wrap word
::spar::ui::markdown_view::render .t3 [join {
    {Fields linkedin_url and p_note, page https://acme-venues.au/a_b_c here.}
    {Code `star_rating` and a [link](https://acme-venues.au/x_y_z), and _real emphasis_.}
    {}
    {```}
    {stem_one stem_two}
    {```}
} \n]
set out3 [.t3 get 1.0 end-1c]
assert_match $out3 "Fields linkedin_url and p_note, page https://acme-venues.au/a_b_c here.*" \
    "intra-word underscores survive in prose and a bare URL"
assert_match $out3 "*Code star_rating and a link (https://acme-venues.au/x_y_z), and real emphasis.*" \
    "a code span and a link target keep theirs unescaped"
assert_match $out3 "*\nstem_one stem_two" "a code block keeps its own"
assert_eq [font actual [font_at .t3 "real emphasis"] -slant] italic \
    "an underscore pair around words is still emphasis"
assert_eq [font actual [font_at .t3 "linkedin_url"] -slant] roman \
    "the field name is not italicised"

section "2. without Markdown the source is inserted as written"

set saved $::spar::ui::markdown_view::have_markdown
set ::spar::ui::markdown_view::have_markdown 0
text .t2
::spar::ui::markdown_view::render .t2 "# H\n\n**b**"
assert_eq [.t2 get 1.0 end-1c] "# H\n\n**b**" "the fallback is the raw source"
set ::spar::ui::markdown_view::have_markdown $saved

section "3. the Inspector formats the profile and leaves messages as written"

# The campaign and tree the Inspector subscribes to: it asks the
# campaign for the contact and nothing else of either.
proc fake_campaign {method args} {
    if {$method eq "get_contact"} { return $::contact }
}
proc fake_tree {method args} {}

set seg [make_temp_segment]
set ppath [write_profile_raw $seg jane "---\nprofile_date: 2026-04-12\nstar_rating: 4\n---\n\n# Jane Doe\n\nShe runs **Acme Events**.\n"]
set apath [write_approach_yaml $seg jane {rounds:
- type: final
  messages:
  - channel: email
    subject: Hello
    body: |-
      Hi Jane,

      **Not bold** and # not a heading.
      Kind regards,
      Sam
  replies:
  - direction: received
    from: jane@acme-venues.au
    subject: Re: Hello
    date: 2026-05-01
    body: |-
      > quoted original
      **Thanks**
}]

ttk::panedwindow .pw -orient horizontal
.pw add [ttk::frame .pw.main -width 200 -height 100]
.pw add [ttk::frame .pw.right]
pack .pw -fill both -expand 1
update

set contact [dict create stem jane contact_name "Jane Doe" organisation Acme \
    profile_path $ppath approach_path $apath star 4]
set insp [spar::ui::Inspector new fake_campaign fake_tree .pw]
$insp on_double_clicked jane
update

set nb .pw.right.insp.nb
set p_texts [text_widgets ${nb}.p]
assert_eq [llength $p_texts] 1 "the P tab has one text block, the profile body"
set p_out [[lindex $p_texts 0] get 1.0 end-1c]
assert_eq $p_out "Jane Doe\n\nShe runs Acme Events." "the profile body is formatted"
assert_eq [font actual [font_at [lindex $p_texts 0] "Acme Events"] -weight] bold \
    "its bold text is bold"

set a_texts [text_widgets ${nb}.a]
assert_eq [llength $a_texts] 1 "the A tab has one message body"
assert_eq [[lindex $a_texts 0] get 1.0 end-1c] \
    "Hi Jane,\n\n**Not bold** and # not a heading.\nKind regards,\nSam" \
    "the message body is shown exactly as sent"

set r_texts [text_widgets ${nb}.r]
assert_eq [llength $r_texts] 1 "the R tab has one reply body"
assert_eq [[lindex $r_texts 0] get 1.0 end-1c] "> quoted original\n**Thanks**" \
    "the reply body is shown exactly as received"

finish_tests

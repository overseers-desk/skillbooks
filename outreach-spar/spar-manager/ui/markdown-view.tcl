# spar-manager/ui/markdown-view.tcl
#
# Markdown shown in a read-only Tk text widget (#74). tcllib's Markdown
# turns the source into HTML; render walks that HTML and inserts its text
# with tags for headings, bold, italic, code, lists, blockquotes and
# tables. Tables come out as tab-separated rows without column alignment.
# Links are plain text, the URL in brackets after the link text when the
# two differ: the Inspector opens no URLs anywhere else, so a link here
# does not either.
#
# Only a profile body is markdown. A message or reply body is sent and
# received as text/plain (transitions/smtp_send.tcl), so the Inspector
# shows it as written, and nothing here touches it.
#
# Without tcllib's Markdown, or on source it cannot convert, render
# inserts the source as written.

package require Tk

namespace eval ::spar::ui::markdown_view {
    variable have_markdown [expr {![catch {package require Markdown}]}]

    # Indent steps in pixels: a list level, a blockquote level, a code
    # block.
    variable list_step  20
    variable quote_step 16
    variable pre_step   12

    # render tw md — insert $md into text widget $tw, which must be in
    # state normal. Signature fits wrapped_text_block's fill argument.
    proc render {tw md} {
        variable have_markdown
        if {!$have_markdown
                || [catch {Markdown::convert [_escape_intraword $md]} html]} {
            $tw insert end $md
            return
        }
        _render_html $tw $html
    }

    # _escape_intraword md — escape each underscore between two word
    # characters, outside code and link targets. tcllib's Markdown reads
    # a pair of them as emphasis, so "linkedin_url and p_note" would lose
    # both underscores and italicise the words between; a profile is full
    # of field names, URLs and addresses that carry them. A code span or
    # block shows a backslash literally, and a link target keeps one, so
    # those are left alone.
    proc _escape_intraword {md} {
        set out {}
        set in_fence 0
        foreach line [split $md \n] {
            if {[regexp {^\s*```} $line]} {
                set in_fence [expr {!$in_fence}]
                lappend out $line
                continue
            }
            if {$in_fence || [regexp {^(    |\t)} $line]} {
                lappend out $line
                continue
            }
            set esc ""
            foreach tok [regexp -all -inline {`[^`]*`|\]\([^)]*\)|<[^>\s]+>|[^`\]<]+|[`\]<]} $line] {
                if {[string index $tok 0] in {` ] <}} {
                    append esc $tok
                } else {
                    append esc [regsub -all {([[:alnum:]])_(?=[[:alnum:]])} $tok {\1\\_}]
                }
            }
            lappend out $esc
        }
        return [join $out \n]
    }

    proc _render_html {tw html} {
        set heading 0     ;# 1..6 inside <hN>, else 0
        set bold    0     ;# nesting counts, so <strong> inside <th> holds
        set italic  0
        set code    0
        set in_pre  0
        set quote   0     ;# blockquote depth
        set lists   {}    ;# stack of {ul|ol counter}
        set link_start ""
        set link_href  ""
        set first_cell 0
        set th 0

        foreach tok [regexp -all -inline {<[^>]*>|[^<]+} $html] {
            if {[regexp {^<(/?)([A-Za-z][A-Za-z0-9]*)([^>]*)>$} $tok -> close name attrs]} {
                set name [string tolower $name]
                if {$close eq ""} {
                    switch -- $name {
                        h1 - h2 - h3 - h4 - h5 - h6 {
                            _break $tw 1
                            set heading [string index $name 1]
                        }
                        p - table { _break $tw 1 }
                        div       { _break $tw 0 }
                        blockquote { _break $tw 1; incr quote }
                        pre       { _break $tw 1; set in_pre 1 }
                        ul        { _break $tw [expr {[llength $lists] == 0}]; lappend lists {ul 0} }
                        ol        { _break $tw [expr {[llength $lists] == 0}]; lappend lists {ol 0} }
                        li {
                            _break $tw 0
                            set top [lindex $lists end]
                            if {[lindex $top 0] eq "ol"} {
                                set n [expr {[lindex $top 1] + 1}]
                                lset lists end 1 $n
                                set marker "$n. "
                            } else {
                                set marker "• "
                            }
                            $tw insert end $marker [_tags $tw $heading $bold $italic $code $in_pre $quote $lists]
                        }
                        tr        { _break $tw 0; set first_cell 1 }
                        th - td {
                            if {!$first_cell} {
                                _trim_spaces $tw
                                $tw insert end "\t" [_tags $tw $heading $bold $italic $code $in_pre $quote $lists]
                            }
                            set first_cell 0
                            if {$name eq "th"} { set th 1; incr bold }
                        }
                        strong - b { incr bold }
                        em - i     { incr italic }
                        code       { incr code }
                        br         { $tw insert end "\n" }
                        hr {
                            _break $tw 1
                            $tw insert end [string repeat ─ 24] \
                                [_tags $tw 0 0 0 0 0 $quote $lists]
                            _break $tw 0
                        }
                        a {
                            set link_start [$tw index end-1c]
                            set link_href ""
                            regexp {href\s*=\s*["']([^"']*)["']} $attrs -> link_href
                            set link_href [_entities $link_href]
                        }
                        img {
                            set alt ""
                            regexp {alt\s*=\s*["']([^"']*)["']} $attrs -> alt
                            if {$alt ne ""} {
                                $tw insert end "\[[_entities $alt]\]" \
                                    [_tags $tw $heading $bold $italic $code $in_pre $quote $lists]
                            }
                        }
                    }
                } else {
                    switch -- $name {
                        h1 - h2 - h3 - h4 - h5 - h6 { set heading 0; _break $tw 0 }
                        blockquote { if {$quote > 0} { incr quote -1 } }
                        pre        { set in_pre 0 }
                        ul - ol    { set lists [lrange $lists 0 end-1] }
                        th - td    { if {$th} { set th 0; incr bold -1 } }
                        strong - b { if {$bold > 0} { incr bold -1 } }
                        em - i     { if {$italic > 0} { incr italic -1 } }
                        code       { if {$code > 0} { incr code -1 } }
                        a {
                            if {$link_start ne ""} {
                                set label [$tw get $link_start end-1c]
                                if {$link_href ne "" && $link_href ne $label
                                        && $link_href ne "mailto:$label"} {
                                    $tw insert end " ($link_href)" \
                                        [_tags $tw $heading $bold $italic $code $in_pre $quote $lists]
                                }
                            }
                            set link_start ""
                        }
                    }
                }
                continue
            }

            # Text between tags. In a code block it stands as written, less
            # the newline before </code>; elsewhere a run of whitespace is
            # one space, and none opens a line.
            if {$in_pre} {
                set text [_entities [string trimright $tok "\n"]]
            } else {
                set text [regsub -all {\s+} $tok " "]
                if {[_at_line_start $tw]} { set text [string trimleft $text] }
                if {$text eq ""} continue
                set text [_entities $text]
            }
            $tw insert end $text \
                [_tags $tw $heading $bold $italic [expr {$code || $in_pre}] $in_pre $quote $lists]
        }

        # Drop the trailing spaces and line breaks closing blocks leave.
        while {[$tw index end-1c] ne "1.0" && [$tw get end-2c end-1c] in {" " "\n"}} {
            $tw delete end-2c end-1c
        }
    }

    # _break tw gap — end the current line if anything is on it; with
    # gap set, also leave one blank line before the next block.
    proc _break {tw gap} {
        _trim_spaces $tw
        if {[$tw index end-1c] eq "1.0"} return
        if {[$tw get end-2c end-1c] ne "\n"} { $tw insert end "\n" }
        if {$gap && [$tw get end-3c end-2c] ne "\n"} { $tw insert end "\n" }
    }

    # _trim_spaces tw — drop the spaces the HTML's own line breaks left
    # at the end of the text, before a line ends or a cell begins.
    proc _trim_spaces {tw} {
        while {[$tw index end-1c] ne "1.0" && [$tw get end-2c end-1c] eq " "} {
            $tw delete end-2c end-1c
        }
    }

    proc _at_line_start {tw} {
        return [expr {[$tw index end-1c] eq "1.0"
                      || [$tw get end-2c end-1c] eq "\n"}]
    }

    proc _entities {s} {
        set s [regsub -all -command {&#(x?)([0-9A-Fa-f]+);} $s [list apply {{- x n} {
            if {$x ne ""} { return [format %c [scan $n %x]] }
            return [format %c [scan $n %d]]
        }}]]
        return [string map {&lt; < &gt; > &quot; \" &#39; ' &apos; ' &nbsp; " " &amp; &} $s]
    }

    # _tags — the tag list for text inserted in the current state: one
    # font tag and one margin tag, each configured on first use.
    proc _tags {tw heading bold italic code in_pre quote lists} {
        variable list_step
        variable quote_step
        variable pre_step

        set font [_font $heading [expr {$bold > 0}] [expr {$italic > 0}] [expr {$code > 0}]]
        if {$font ni [$tw tag names]} {
            $tw tag configure $font -font $font
        }
        set tags [list $font]

        set depth [llength $lists]
        set left [expr {$quote * $quote_step}]
        set hang $left
        if {$depth > 0} {
            set left [expr {$left + ($depth - 1) * $list_step}]
            set hang [expr {$left + $list_step}]
        }
        if {$in_pre} {
            set left [expr {$left + $pre_step}]
            set hang $left
        }
        if {$left > 0 || $hang > 0} {
            set margin md_margin_${left}_${hang}
            if {$margin ni [$tw tag names]} {
                $tw tag configure $margin -lmargin1 $left -lmargin2 $hang
            }
            lappend tags $margin
        }
        if {$quote > 0} {
            if {"md_quote" ni [$tw tag names]} {
                $tw tag configure md_quote -foreground "#555555"
            }
            lappend tags md_quote
        }
        return $tags
    }

    # _font heading bold italic code — a named font derived from the
    # system's own (TkDefaultFont, or TkFixedFont for code), so the view
    # keeps the family and size the rest of the app uses. A heading is
    # bold and scaled up from it.
    proc _font {heading bold italic code} {
        set name spar_md_h${heading}_b${bold}_i${italic}_c${code}
        if {$name in [font names]} { return $name }
        set opts [font actual [expr {$code ? "TkFixedFont" : "TkDefaultFont"}]]
        set scale [lindex {1.0 1.6 1.4 1.2 1.1 1.0 1.0} $heading]
        # A negative -size is in pixels; scaling keeps the sign.
        dict set opts -size [expr {round([dict get $opts -size] * $scale)}]
        if {$bold || $heading > 0} { dict set opts -weight bold }
        if {$italic} { dict set opts -slant italic }
        font create $name {*}$opts
        return $name
    }
}

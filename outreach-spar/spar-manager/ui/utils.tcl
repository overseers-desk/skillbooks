# spar-manager/ui/ns.tcl
#
# Stateless namespace helpers that don't warrant their own classes.
# Each sub-namespace groups a small set of procs; all state flows
# through explicit arguments. If a helper grows state, it should
# graduate to its own class file under the design criterion in #67.

package require Tk

namespace eval ::spar::ui::warnings {

    # build campaign parent_frame — construct the warnings zone widget
    # tree inside $parent_frame and subscribe to the Campaign's refresh
    # events. Returns the frame path so the caller can keep it if it
    # needs to call toggle/rebuild directly (most callers don't: the
    # event subscription handles rebuild, and the -command on the
    # toggle button handles toggle).
    proc build {campaign parent_frame} {
        set f ${parent_frame}.warnings
        ttk::frame $f
        pack $f -fill x -padx 8 -pady {2 4}

        set warnings [$campaign get_warnings]
        set summary [compute_summary $campaign]
        ttk::button ${f}.toggle \
            -text "▸ ⚠ [llength $warnings] warnings ($summary)" \
            -command [list ::spar::ui::warnings::toggle $f] \
            -style Toolbutton
        pack ${f}.toggle -fill x -anchor w

        text ${f}.txt -height 5 -wrap word -font "TkDefaultFont 8" \
            -state disabled -background "#fff8e1" -relief flat
        populate_text $campaign $f

        $campaign subscribe refreshed    [list ::spar::ui::warnings::rebuild $campaign $f]
        $campaign subscribe fully-loaded [list ::spar::ui::warnings::rebuild $campaign $f]

        return $f
    }

    # compute_summary campaign — bucket the warnings into
    # duplicate-email / duplicate-name / identical-subject / other
    # and return a short "N duplicate email, M duplicate name, …" string.
    proc compute_summary {campaign} {
        set warnings [$campaign get_warnings]
        set warn_dup_email 0
        set warn_dup_name 0
        set warn_dup_subject 0
        set warn_other 0
        foreach w $warnings {
            if {[string match "*Duplicate To:*" $w] || [string match "*Duplicate email:*" $w]} {
                incr warn_dup_email
            } elseif {[string match "*Duplicate name:*" $w]} {
                incr warn_dup_name
            } elseif {[string match "*Identical subject:*" $w]} {
                incr warn_dup_subject
            } else {
                incr warn_other
            }
        }
        set parts {}
        if {$warn_dup_email   > 0} { lappend parts "${warn_dup_email} duplicate email" }
        if {$warn_dup_name    > 0} { lappend parts "${warn_dup_name} duplicate name" }
        if {$warn_dup_subject > 0} { lappend parts "${warn_dup_subject} identical subject" }
        if {$warn_other       > 0} { lappend parts "${warn_other} other" }
        return [join $parts ", "]
    }

    # populate_text campaign frame — rewrite the bullet-list text widget.
    proc populate_text {campaign frame} {
        set warnings [$campaign get_warnings]
        ${frame}.txt tag configure bold -font "TkDefaultFont 8 bold"
        ${frame}.txt configure -state normal
        ${frame}.txt delete 1.0 end
        foreach w $warnings {
            set colon [string first ":" $w]
            if {$colon >= 0} {
                ${frame}.txt insert end "• " {} \
                    [string range $w 0 $colon] bold \
                    [string range $w [expr {$colon+1}] end] {}
            } else {
                ${frame}.txt insert end "• $w"
            }
            ${frame}.txt insert end "\n"
        }
        ${frame}.txt configure -state disabled
    }

    # toggle frame — flip visibility of the text widget. Reads Tk's own
    # mapped state (no cached Expanded flag). Flips the arrow glyph in
    # the button label without recomputing the count/summary.
    proc toggle {frame} {
        if {[winfo ismapped ${frame}.txt]} {
            pack forget ${frame}.txt
            set cur [${frame}.toggle cget -text]
            ${frame}.toggle configure -text [string map {▾ ▸} $cur]
        } else {
            pack ${frame}.txt -fill x -padx 4 -pady 2
            set cur [${frame}.toggle cget -text]
            ${frame}.toggle configure -text [string map {▸ ▾} $cur]
        }
    }

    # rebuild campaign frame — recompute summary, repopulate text,
    # update the button count/summary. Preserves the current
    # expanded/collapsed state (the arrow glyph comes from winfo ismapped).
    proc rebuild {campaign frame} {
        set warnings [$campaign get_warnings]
        set summary [compute_summary $campaign]
        populate_text $campaign $frame
        set arrow [expr {[winfo ismapped ${frame}.txt] ? "▾" : "▸"}]
        ${frame}.toggle configure \
            -text "$arrow ⚠ [llength $warnings] warnings ($summary)"
    }
}

namespace eval ::spar::ui::legend {

    # show — create .legendwin or raise it if it already exists.
    proc show {} {
        if {[winfo exists .legendwin]} {
            wm deiconify .legendwin
            raise .legendwin
            return
        }
        toplevel .legendwin
        wm title .legendwin "Column Denominator Tree"
        canvas .legendwin.c -width 750 -height 220 -highlightthickness 0
        pack .legendwin.c -fill both -expand 1
        bind .legendwin.c <Configure> {::spar::ui::legend::draw .legendwin.c}
        wm protocol .legendwin WM_DELETE_WINDOW {wm withdraw .legendwin}
    }

    # draw canvas — paint the denominator-tree graph onto $canvas. Bound
    # to the canvas's <Configure> so the layout reflows when the window
    # resizes.
    proc draw {c} {
        $c delete all
        set bfont "TkDefaultFont 9 bold"
        set afont "TkDefaultFont 8"
        set line_colour "#888888"
        set acolour "#666666"

        set w [winfo width $c]
        if {$w < 10} { set w 700 }

        set dy 34
        set y0 14
        set y1 [expr {$y0 + $dy}]
        set y2 [expr {$y0 + 2*$dy}]
        set y3 [expr {$y0 + 3*$dy}]
        set y4 [expr {$y0 + 4*$dy}]
        set y5 [expr {$y0 + 5*$dy}]

        set margin 50
        set span [expr {$w - 2*$margin}]
        set x_valid    [expr {$w / 2}]
        set x_profile  [expr {$margin + $span * 0.0}]
        set x_star     [expr {$margin + $span * 0.50}]
        set x_astar    [expr {$margin + $span * 0.10}]
        set x_email    [expr {$margin + $span * 0.30}]
        set x_linkedin [expr {$margin + $span * 0.55}]
        set x_facebook [expr {$margin + $span * 0.75}]
        set x_phone    [expr {$margin + $span * 0.95}]
        set x_aeml     [expr {$margin + $span * 0.40}]
        set x_sent     [expr {$margin + $span * 0.50}]
        set x_repl     [expr {$margin + $span * 0.60}]

        set nodes [list \
            "Valid"       ""         $x_valid    $y0 \
            "Profile"     "/ Valid"  $x_profile  $y1 \
            "3+★"    "/ Valid"  $x_star     $y1 \
            "A/3+★"  "/ 3+★" $x_astar $y2 \
            "Email"       "/ 3+★" $x_email $y2 \
            "LinkedIn"    "/ 3+★" $x_linkedin $y2 \
            "Facebook"    "/ 3+★" $x_facebook $y2 \
            "Only ☎" "/ 3+★" $x_phone $y2 \
            "A/Eml"       "/ Email" $x_aeml     $y3 \
            "✉ Sent" "/ A/Eml" $x_sent     $y4 \
            "✉ Repl" "/ Sent"  $x_repl     $y5 \
        ]

        foreach {lbl denom x y} $nodes {
            $c create text $x $y -text $lbl -font $bfont -anchor center
            if {$denom ne ""} {
                $c create text $x [expr {$y + 11}] -text $denom -font $afont \
                    -fill $acolour -anchor center
            }
        }

        set g 14
        set gt 9
        $c create line $x_valid [expr {$y0+$gt}]  $x_profile [expr {$y1-$gt}] -fill $line_colour
        $c create line $x_valid [expr {$y0+$gt}]  $x_star    [expr {$y1-$gt}] -fill $line_colour
        foreach xc [list $x_astar $x_email $x_linkedin $x_facebook $x_phone] {
            $c create line $x_star [expr {$y1+$g}] $xc [expr {$y2-$gt}] -fill $line_colour
        }
        $c create line $x_email [expr {$y2+$g}] $x_aeml [expr {$y3-$gt}] -fill $line_colour
        $c create line $x_aeml  [expr {$y3+$g}] $x_sent [expr {$y4-$gt}] -fill $line_colour
        $c create line $x_sent  [expr {$y4+$g}] $x_repl [expr {$y5-$gt}] -fill $line_colour
    }
}

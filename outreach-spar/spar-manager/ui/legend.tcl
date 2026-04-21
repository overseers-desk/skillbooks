# spar-manager/ui/legend.tcl
#
# ::spar::ui::legend — the column-denominator-tree popup.
#
# Namespace module, not a class. The legend is stateless: the `.legendwin`
# toplevel is created on demand, nothing persists between invocations
# beyond the toplevel itself. Two procs:
#
#   show  — create .legendwin (or raise it if it already exists).
#   draw  — paint the denominator-tree graph onto a canvas widget.
#
# Bound from the toolbar via `-command ::spar::ui::legend::show`.

package require Tk

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

    # draw — paint the denominator-tree graph onto $c. Bound to the
    # canvas's <Configure> so the layout reflows when the window resizes.
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

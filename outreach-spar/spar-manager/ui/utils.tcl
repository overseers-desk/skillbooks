# spar-manager/ui/ns.tcl
#
# Stateless namespace helpers that don't warrant their own classes.
# Each sub-namespace groups a small set of procs; all state flows
# through explicit arguments. If a helper grows state, it should
# graduate to its own class file under the design criterion in #67.
#
# Widgets: use ttk::*. Classic tk widgets ignore the theme. For a
# readonly selectable field (Ctrl-C copy), use ttk::entry with the
# Flat.TEntry style — see copy_text below. Don't specify -font; users
# expect ours to match other apps on their system.

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

        # rebuild on reloading clears the panel (Warnings is empty
        # post-reset); rebuild on fully-loaded refills it.
        $campaign subscribe reloading    [list ::spar::ui::warnings::rebuild $campaign $f]
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
            "Sent"   "/ A/3+★" $x_sent     $y4 \
            "Repl"   "/ Sent"  $x_repl     $y5 \
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

namespace eval ::spar::ui::inspector_widgets {

    # scrollable parent — attach a canvas + vertical scrollbar inside
    # $parent and return an inner ttk::frame the caller populates. The
    # inner frame's width tracks the canvas width so children reflow;
    # scrollregion updates on both canvas and inner-frame size changes.
    proc scrollable {parent} {
        set sc ${parent}.sc
        ttk::frame $sc
        pack $sc -fill both -expand 1

        set cv ${sc}.cv
        canvas $cv -highlightthickness 0 \
            -yscrollcommand [list ${sc}.vsb set]
        ttk::scrollbar ${sc}.vsb -orient vertical -command [list $cv yview]
        pack ${sc}.vsb -side right -fill y
        pack $cv -side left -fill both -expand 1

        set body ${cv}.inner
        ttk::frame $body
        $cv create window 0 0 -window $body -anchor nw -tags inner

        # Coalesce -scrollregion updates through `after idle` instead of
        # recomputing synchronously inside the <Configure> callbacks.
        # During a scrollbar drag, motion events keep the event queue
        # busy and idle handlers do not fire, so the scrollregion stays
        # frozen until the user releases. Without this, a late geometry
        # settle inside the inner frame (text-widget displayline reflow
        # on first expose, theme post-map repaint, etc.) fires <Configure>
        # on $body mid-drag, recomputes scrollregion, and the canvas's
        # -yscrollcommand pushes new thumb fractions to the scrollbar
        # that no longer match the user's mouse position, producing the
        # "thumb jumps out from under the finger" symptom.
        bind $cv <Configure> [list apply {{cv w} {
            $cv itemconfigure inner -width $w
            ::spar::ui::inspector_widgets::_queue_sr $cv
        }} $cv %w]
        bind $body <Configure> [list ::spar::ui::inspector_widgets::_queue_sr $cv]
        return $body
    }

    # kv_row parent key value indent — pack one key/value row. indent=0
    # is a top-level row; indent=1 is padded for list items and dict
    # sub-rows. The value side is a readonly classic entry styled flat so
    # it reads as a label but supports mouse selection and Ctrl-C. No
    # wrapping (entries are single-line); long values scroll horizontally.
    proc kv_row {parent key value {indent 0}} {
        set row ${parent}.[_uniq row]
        ttk::frame $row
        pack $row -fill x -anchor w
        set lpad [expr {$indent * 16}]
        ttk::label ${row}.k -text $key -width 22 -anchor w
        pack ${row}.k -side left -padx [list $lpad 4]
        copy_text ${row}.v $value
        pack ${row}.v -side left -fill x -expand 1
        return $row
    }

    # wrapped_text_block parent text pack_args max_lines: pack a flat
    # read-only Text widget under $parent, sized to its wrapped display-line
    # count. Resizes on width change (sash drag, window resize, expanding
    # collapsible) by re-measuring inside a <Configure> handler, with a
    # guard against the loop that setting -height itself would create.
    # max_lines clamps the height; use 0 to disable the cap, as the
    # Inspector does for full-message bodies. Returns the widget path.
    proc wrapped_text_block {parent text {pack_args {-fill x -padx 6 -pady {2 2}}} {max_lines 20}} {
        set tw ${parent}.[_uniq wtb]
        text $tw -wrap word -relief flat -borderwidth 0 -takefocus 0 \
            -height 1 -background [. cget -background]
        $tw insert end $text
        $tw configure -state disabled
        pack $tw {*}$pack_args
        update idletasks
        set n [$tw count -displaylines 1.0 end]
        if {$n < 1} { set n 1 }
        if {$max_lines > 0 && $n > $max_lines} { set n $max_lines }
        $tw configure -height $n
        bind $tw <Configure> [list apply {{tw max_lines} {
            if {![winfo exists $tw]} return
            set m [$tw count -displaylines 1.0 end]
            if {$m < 1} { set m 1 }
            if {$max_lines > 0 && $m > $max_lines} { set m $max_lines }
            if {$m != [$tw cget -height]} {
                $tw configure -height $m
            }
        }} $tw $max_lines]
        return $tw
    }

    # kv_row_wrap parent key value indent. Width-aware variant of kv_row.
    # Short scalars (≤60 chars and no embedded newline) delegate to kv_row
    # and render inline. Longer or multiline values stack: a "key:" header
    # row, then a wrapped_text_block holding the value. Decision is on
    # string length and \n presence, not \n alone, because a YAML folded
    # scalar (`>` style) arrives as one long line with no newline, and
    # inline rendering would scroll horizontally inside kv_row's flat entry
    # rather than wrap. The 60-char threshold keeps slugs, emails, short
    # titles inline while paragraphs and long campaign titles stack.
    proc kv_row_wrap {parent key value {indent 0}} {
        if {[string length $value] <= 60 && [string first "\n" $value] < 0} {
            return [kv_row $parent $key $value $indent]
        }
        set lpad [expr {$indent * 16}]
        set hdr ${parent}.[_uniq kvw]
        ttk::label $hdr -text "${key}:" -anchor w
        pack $hdr -fill x -padx [list $lpad 4] -pady {4 0}
        return [wrapped_text_block $parent $value \
            [list -fill x -padx [list [expr {$lpad + 16}] 4] -pady {0 2}]]
    }

    # copy_text path value — construct a flat readonly ttk::entry that
    # looks like a label but supports text selection. Reusable for header
    # strings and any other place a label could have gone. Uses the
    # Flat.TEntry style (configured once, below).
    proc copy_text {path value} {
        ttk::entry $path -style Flat.TEntry -takefocus 0
        $path insert 0 $value
        $path configure -state readonly
        return $path
    }

    # copy_text_set path value — update a copy_text entry's content.
    proc copy_text_set {path value} {
        $path configure -state normal
        $path delete 0 end
        $path insert 0 $value
        $path configure -state readonly
    }

    # Flat.TEntry — a borderless, padding-less ttk::entry style whose
    # field background matches the root window, so a readonly entry
    # renders as a flat selectable label. Configured at source-time (Tk
    # is up by the time utils.tcl is loaded from spar-ui.tcl).
    ttk::style configure Flat.TEntry -borderwidth 0 -relief flat -padding 0
    ttk::style map Flat.TEntry \
        -fieldbackground [list readonly [. cget -background]]

    # Pending `after idle` ids for deferred -scrollregion updates,
    # keyed by canvas widget path. See the comment in `scrollable`.
    variable _sr_pending
    array set _sr_pending {}

    proc _queue_sr {cv} {
        variable _sr_pending
        if {[info exists _sr_pending($cv)]} {
            after cancel $_sr_pending($cv)
        }
        set _sr_pending($cv) [after idle \
            [list ::spar::ui::inspector_widgets::_apply_sr $cv]]
    }

    proc _apply_sr {cv} {
        variable _sr_pending
        unset -nocomplain _sr_pending($cv)
        if {![winfo exists $cv]} return
        $cv configure -scrollregion [$cv bbox all]
    }

    variable _uniq_ctr 0
    proc _uniq {prefix} {
        variable _uniq_ctr
        incr _uniq_ctr
        return "${prefix}${_uniq_ctr}"
    }

    # bind_mousewheel_recursive canvas widget — bind wheel events on
    # $widget and all its descendants to scroll $canvas. Called after
    # each render pass so newly-added widgets participate.
    proc bind_mousewheel_recursive {canvas widget} {
        # The wheel scripts return -code break so Tk's Text class binding
        # does not also scroll the widget's internal view. Without break,
        # a wheel event over a body text widget scrolls both the outer
        # canvas and the widget's own yview, leaving the widget showing
        # a different slice of its content from where the surrounding
        # layout suggests.
        bind $widget <Button-4> [list apply {{c} {
            $c yview scroll -3 units
            return -code break
        }} $canvas]
        bind $widget <Button-5> [list apply {{c} {
            $c yview scroll  3 units
            return -code break
        }} $canvas]
        bind $widget <MouseWheel> [list apply {{c D} {
            $c yview scroll [expr {-$D/30}] units
            return -code break
        }} $canvas %D]
        foreach child [winfo children $widget] {
            bind_mousewheel_recursive $canvas $child
        }
    }
}

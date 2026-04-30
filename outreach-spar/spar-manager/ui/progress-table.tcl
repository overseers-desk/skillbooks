# spar-manager/ui/progress-table.tcl
#
# spar::ui::ProgressTable — owns the per-segment progress ttk::treeview.
#
# Encapsulates column config, per-segment count snapshots, per-segment
# inclusion (checkbox) state, the "…" placeholder policy for
# filesystem-dependent columns, and the totals row. Subscribes to the
# CampaignModel's segment-loaded / fully-loaded / reloading events so
# rows update as async loads complete.
#
# Consumers call `populate`, `set_all`, `get_checked_segments` as
# public methods. Future TransitionTree will subscribe to
# `segments-changed` to know which rows count as in-scope.
#
# Events fired:
#   segments-changed {checked_list}
#       emitted whenever the set of checked segments changes — either
#       because the user toggled a row, or because `set_all` was called
#       from the All/None toolbar buttons, or because `populate` seeded
#       new defaults from a reloaded model.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::ProgressTable {
    variable Campaign PTree PtreeCols PtreeColIds DenomParent
    variable SegCounts SegChecked FsDependentCols ColCountKeys
    variable Subs ChildRows

    constructor {campaign parent_frame} {
        set Campaign    $campaign
        set SegCounts   [dict create]
        set SegChecked  [dict create]
        set Subs        [dict create]

        # Column definitions: id, heading, anchor. Each data column
        # combines count + pct into one cell ("123 45%"). Widths are
        # computed from content after population, not hardcoded.
        set PtreeCols {
            valid    "Valid"       e
            profiled "Profile"     e
            star3    "3+★"    e
            astar    "A/3+★"  e
            email    "Email"       e
            aeml     "A/✉"       e
            linkedin "LinkedIn"    e
            facebook "Facebook"    e
            phone    "Only ☎" e
            sent     "✉ Sent" e
            repl     "✉ Repl" e
        }

        set PtreeColIds {}
        foreach {id heading anchor} $PtreeCols { lappend PtreeColIds $id }

        # Denominator parent col-id for percentage (empty = no pct).
        set DenomParent {
            valid    {}
            profiled valid
            star3    valid
            astar    star3
            email    star3
            aeml     email
            linkedin star3
            facebook star3
            phone    star3
            sent     aeml
            repl     sent
        }

        # Filesystem-dependent column IDs — shown as "…" until full load.
        set FsDependentCols {profiled astar aeml sent repl}

        # Column ID -> progress_counts dict key.
        set ColCountKeys [dict create \
            valid valid  profiled profiled  star3 star3 \
            astar approached_star3  email has_email  aeml approached_email \
            linkedin has_linkedin  facebook has_facebook  phone has_phone_only \
            sent email_sent  repl email_replied]

        # Build the widget inside the parent labelframe.
        set PTree ${parent_frame}.tree
        set vsb   ${parent_frame}.vsb
        set hsb   ${parent_frame}.hsb
        ttk::treeview $PTree \
            -columns $PtreeColIds \
            -show {tree headings} \
            -selectmode none \
            -yscrollcommand [list $vsb set] \
            -xscrollcommand [list $hsb set]

        ttk::scrollbar $vsb -orient vertical   -command [list $PTree yview]
        ttk::scrollbar $hsb -orient horizontal -command [list $PTree xview]

        grid $PTree -in $parent_frame -row 0 -column 0 -sticky nsew -padx {2 0} -pady {2 0}
        grid $vsb   -in $parent_frame -row 0 -column 1 -sticky ns   -pady {2 0}
        grid $hsb   -in $parent_frame -row 1 -column 0 -sticky ew   -padx {2 0}
        grid rowconfigure    $parent_frame 0 -weight 1
        grid columnconfigure $parent_frame 0 -weight 1

        # Tree column (#0): segment name — stretches to fill extra space.
        $PTree column #0 -stretch 1 -anchor w -minwidth 120

        # Data columns: fixed width (computed), never stretch.
        foreach {id heading anchor} $PtreeCols {
            $PTree heading $id -text $heading -anchor $anchor
            $PTree column  $id -stretch 0 -anchor $anchor -minwidth 10
        }

        # Tags: muted for skip segments, totals row styling.
        $PTree tag configure muted -foreground $::colours(muted_fg)
        $PTree tag configure totals -font "TkDefaultFont 9 bold" \
            -background $::colours(totals_bg)

        # Click on column #0 toggles the checkbox for that segment.
        bind $PTree <Button-1> [list [self] on_click %x %y]

        # Double-click any column of a real segment row opens the segment
        # viewer via the segment-double-clicked event. Tk delivers the
        # Button-1 binding on each click of a double-click, so the
        # checkbox toggle happens on click 1 and the viewer opens on
        # click 2 — both behaviours are wanted.
        bind $PTree <Double-1> [list [self] on_double_click %x %y]

        # Mouse wheel scrolling.
        bind $PTree <Button-4>   { %W yview scroll -3 units }
        bind $PTree <Button-5>   { %W yview scroll  3 units }
        bind $PTree <MouseWheel> { %W yview scroll [expr {-%D/120}] units }

        # TIMING: measure expand render latency (remove after measurement).
        bind $PTree <<TreeviewOpen>> [list [self] on_tree_open]

        # Subscribe to the Campaign's lifecycle events.
        $Campaign subscribe segment-loaded [list [self] on_segment_loaded]
        $Campaign subscribe fully-loaded   [list [self] on_fully_loaded]
        $Campaign subscribe reloading      [list [self] on_reloading]
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method get_checked_segments {} {
        set out {}
        dict for {seg v} $SegChecked {
            if {$v} { lappend out $seg }
        }
        return $out
    }

    # ─── Public entry points ──────────────────────────────────────────────

    # populate — rebuild the treeview from the Campaign's current
    # segments. Called once at startup and again on each `reloading`.
    # Resets SegCounts / SegChecked from the fresh segment list and
    # fires segments-changed with the resulting default.
    method populate {} {
        set segments       [$Campaign get_segments]
        set full_load_done [$Campaign get_full_load_done]

        $PTree delete [$PTree children {}]
        set SegCounts  [dict create]
        set SegChecked [dict create]
        set ChildRows  [dict create]

        foreach seg_entry $segments {
            lassign $seg_entry seg_name is_campaign raw_data
            set tags {}
            if {!$is_campaign} { lappend tags muted }

            # raw_data is flat list: count {} count pct count pct ...
            # ci 0 = valid (no pct), ci 1..10 = count pct pairs
            set counts {}
            for {set ci 0} {$ci < 11} {incr ci} {
                lappend counts [lindex $raw_data [expr {$ci * 2}]]
            }

            # Build values list for treeview columns (formatted cells).
            set values {}
            set ci 0
            foreach {id heading anchor} $PtreeCols {
                set count [lindex $counts $ci]
                set pid [dict get $DenomParent $id]
                if {$pid eq ""} {
                    lappend values $count
                } else {
                    set pidx [lsearch $PtreeColIds $pid]
                    set denom [lindex $counts $pidx]
                    lappend values [my _fmt_cell $count $denom]
                }
                incr ci
            }

            # During async load, show "…" for filesystem-dependent columns.
            if {!$full_load_done} {
                set vi 0
                foreach {id heading anchor} $PtreeCols {
                    if {$id in $FsDependentCols} {
                        lset values $vi "…"
                    }
                    incr vi
                }
            }

            set cb [expr {$is_campaign ? "☑" : "  "}]
            $PTree insert {} end -id $seg_name -text "$cb  $seg_name" \
                -values $values -tags $tags

            if {$is_campaign} {
                dict set SegChecked $seg_name 1
                set ci 0
                foreach id $PtreeColIds {
                    dict set SegCounts $seg_name $id [lindex $counts $ci]
                    incr ci
                }
            }
        }

        # Insert totals row (updated by _recalc_totals).
        $PTree insert {} end -id __totals__ -text "  TOTAL" \
            -values [lrepeat [llength $PtreeColIds] ""] -tags totals

        my _recalc_totals
        after idle [list [self] autosize]
        my _fire segments-changed [my get_checked_segments]
    }

    # rebuild — alias for populate. Callers that say "rebuild" in their
    # wiring stay readable without forcing them to know the internal verb.
    method rebuild {} { my populate }

    # autosize — measure content, set column widths. Called via after
    # idle so row geometry is finalised. Public because it's invoked
    # externally via `after idle [list [self] autosize]`.
    method autosize {} {
        set font TkDefaultFont
        set pad 12   ;# horizontal cell padding (pixels)

        # Column #0: measure heading + segment rows + contact child rows
        set max0 [font measure $font "Segment"]
        foreach item [$PTree children {}] {
            set txt [$PTree item $item -text]
            set w [font measure $font $txt]
            if {$w > $max0} { set max0 $w }
            foreach child [$PTree children $item] {
                set txt [$PTree item $child -text]
                set w [font measure $font $txt]
                if {$w > $max0} { set max0 $w }
            }
        }
        $PTree column #0 -minwidth [expr {$max0 + $pad}]

        # Data columns: measure heading + all cell values
        set ci 0
        foreach {id heading anchor} $PtreeCols {
            set maxw [font measure $font $heading]
            foreach item [$PTree children {}] {
                set val [lindex [$PTree item $item -values] $ci]
                set w [font measure $font $val]
                if {$w > $maxw} { set maxw $w }
            }
            set colw [expr {$maxw + $pad}]
            $PTree column $id -width $colw -minwidth $colw
            incr ci
        }
    }

    # set_all flag — mass check / uncheck (toolbar All / None).
    method set_all {flag} {
        set flag [expr {$flag ? 1 : 0}]
        foreach seg [dict keys $SegChecked] {
            dict set SegChecked $seg $flag
            set cb [expr {$flag ? "☑" : "☐"}]
            $PTree item $seg -text "$cb  $seg"
        }
        my _recalc_totals
        my _fire segments-changed [my get_checked_segments]
    }

    # on_segment_toggle — flip one segment's checkbox state and refresh
    # the glyph + totals. Public because it's invoked by the Button-1
    # binding via on_click.
    method on_segment_toggle {segment} {
        if {![dict exists $SegChecked $segment]} return
        set new [expr {![dict get $SegChecked $segment]}]
        dict set SegChecked $segment $new
        set cb [expr {$new ? "☑" : "☐"}]
        $PTree item $segment -text "$cb  $segment"
        my _recalc_totals
        my _fire segments-changed [my get_checked_segments]
    }

    # on_click — Button-1 handler. Toggle the checkbox only when the
    # click lands on the checkbox glyph at the start of column #0;
    # clicks anywhere else (segment name, count columns, between rows)
    # fall through to the treeview's class binding which selects the
    # row. This narrow toggle zone gives a single click outside the
    # checkbox a visible selection effect, so a subsequent double-click
    # is visually confirmable. Public because it's invoked from a bind.
    method on_click {x y} {
        set col [$PTree identify column $x $y]
        set row [$PTree identify row    $x $y]
        if {$col ne "#0" || $row eq "" || $row eq "__totals__"} return
        if {[$PTree parent $row] ne ""} return
        set bbox [$PTree bbox $row #0]
        if {[llength $bbox] != 4} return
        lassign $bbox bx by bw bh
        # Hit zone = pixel width of the checkbox glyph plus its trailing
        # spaces. font measure scales with the user's Tk DPI, so this
        # works on hi-DPI displays without hard-coded pixel offsets.
        set hit_w [font measure TkDefaultFont "☑  "]
        if {$x < $bx + $hit_w} {
            my on_segment_toggle $row
        }
    }

    # on_double_click — Double-1 handler. Fires segment-double-clicked
    # for any real segment row (skip-segment rows included — viewing a
    # non-checked segment is legitimate). Totals row and clicks outside
    # any row are ignored.
    method on_double_click {x y} {
        set row [$PTree identify row $x $y]
        if {$row eq "" || $row eq "__totals__"} return
        if {[$PTree parent $row] ne ""} return
        my _fire segment-double-clicked $row
    }

    # TIMING: measure how long Tk takes to render newly visible child rows.
    # Remove after measurement confirms < 500 ms.
    method on_tree_open {} {
        set item [$PTree focus]
        set n [llength [$PTree children $item]]
        set t0 [clock microseconds]
        update idletasks
        set t1 [clock microseconds]
        puts stderr "<<TreeviewOpen>> $item ($n children): [expr {$t1 - $t0}] us"
    }

    # ─── Event handlers (Campaign subscriptions) ──────────────────────────

    # on_segment_loaded — one segment of the async pass finished. Update
    # its row in place and refresh totals. Public because it's invoked
    # via [list [self] on_segment_loaded] from the subscription dispatch.
    method on_segment_loaded {seg cdict is_active} {
        if {![$PTree exists $seg]} return

        # Sentinel "" in cdict = "preserve the existing cell". The two-phase
        # loader (#82) uses this to keep the "…" placeholder on parse-derived
        # columns (sent/repl) during the cheap-pass fire, then writes real
        # values during the parse-pass fire.
        set counts {}
        foreach id $PtreeColIds {
            set key [dict get $ColCountKeys $id]
            lappend counts [dict get $cdict $key]
        }

        if {$is_active} {
            set ci 0
            foreach id $PtreeColIds {
                set v [lindex $counts $ci]
                if {$v ne ""} {
                    dict set SegCounts $seg $id $v
                }
                incr ci
            }
        }

        set existing [$PTree item $seg -values]
        set values {}
        set ci 0
        foreach {id heading anchor} $PtreeCols {
            set count [lindex $counts $ci]
            if {$count eq ""} {
                lappend values [lindex $existing $ci]
            } else {
                set pid [dict get $DenomParent $id]
                if {$pid eq ""} {
                    lappend values $count
                } else {
                    set pidx [lsearch $PtreeColIds $pid]
                    set denom [lindex $counts $pidx]
                    if {$denom eq "" && [dict exists $SegCounts $seg $pid]} {
                        set denom [dict get $SegCounts $seg $pid]
                    }
                    lappend values [my _fmt_cell $count $denom]
                }
            }
            incr ci
        }
        $PTree item $seg -values $values
        my _refresh_seg_children $seg
    }

    # on_fully_loaded — async load finished. The per-row values were
    # already updated piecemeal by on_segment_loaded; here we refresh
    # the totals row (now that full_load_done is true, "…" gives way to
    # real numbers) and re-autosize.
    method on_fully_loaded {} {
        my _recalc_totals
        after idle [list [self] autosize]
    }

    # on_reloading — refresh has reset Segments to TSV-only counts;
    # populate re-renders against the placeholders. segment-loaded
    # events will then fill in the filesystem-dependent columns.
    method on_reloading {} {
        my populate
    }

    # ─── Internal helpers ─────────────────────────────────────────────────

    # _fmt_cell — "123 45%" or just "123" when no denominator.
    method _fmt_cell {count denom} {
        if {$denom eq "" || $denom == 0} { return $count }
        return [format "%d %d%%" $count [expr {$count * 100 / $denom}]]
    }

    # _recalc_totals — sum counts across checked segments, format into
    # the totals row. "…" overrides for filesystem-dependent columns
    # while the async load is still in flight.
    method _recalc_totals {} {
        set full_load_done [$Campaign get_full_load_done]

        set sums [dict create]
        foreach id $PtreeColIds { dict set sums $id 0 }

        dict for {seg_name counts} $SegCounts {
            if {![dict exists $SegChecked $seg_name]} continue
            if {![dict get $SegChecked $seg_name]} continue
            foreach id $PtreeColIds {
                dict set sums $id [expr {[dict get $sums $id] + [dict get $counts $id]}]
            }
        }

        set values {}
        foreach {id heading anchor} $PtreeCols {
            set count [dict get $sums $id]
            set pid [dict get $DenomParent $id]
            if {$pid eq ""} {
                lappend values $count
            } else {
                set denom [dict get $sums $pid]
                lappend values [my _fmt_cell $count $denom]
            }
        }

        if {!$full_load_done} {
            set vi 0
            foreach {id heading anchor} $PtreeCols {
                if {$id in $FsDependentCols} {
                    lset values $vi "…"
                }
                incr vi
            }
        }

        $PTree item __totals__ -values $values
    }

    # _contact_values: returns an 11-element list (one per column) with "✓"
    # where this contact is counted in that column's aggregate, "" otherwise.
    # Mirrors the conditions in spar::progress_counts so the sum of ✓s equals
    # the segment row's count for each column.
    method _contact_values {c} {
        set state [dict get $c state]
        set star  [dict get $c star]
        set em    [dict get $c has_email]
        set li    [dict get $c has_linkedin]
        set fb    [dict get $c has_facebook]
        set ph    [dict get $c has_phone_only]
        set sent  [dict get $c email_sent]
        set repl  [dict get $c email_replied]

        set profiled_plus  {PROFILED PROFILE_STALE APPROACHED APPROACH_STALE SENT REPLIED}
        set approached_plus {APPROACHED APPROACH_STALE SENT REPLIED}

        set is_valid [expr {$state ne "EXCLUDED"}]
        set is_prof  [expr {$state in $profiled_plus}]
        set is_s3    [expr {$star >= 3}]
        set is_appr  [expr {$state in $approached_plus}]

        set v "✓"
        return [list \
            [expr {$is_valid                              ? $v : ""}] \
            [expr {$is_prof                               ? $v : ""}] \
            [expr {$is_s3                                 ? $v : ""}] \
            [expr {($is_s3 && $is_appr)                   ? $v : ""}] \
            [expr {($is_s3 && $em)                        ? $v : ""}] \
            [expr {($is_s3 && $em && $is_appr)            ? $v : ""}] \
            [expr {($is_s3 && $li)                        ? $v : ""}] \
            [expr {($is_s3 && $fb)                        ? $v : ""}] \
            [expr {($is_s3 && $ph)                        ? $v : ""}] \
            [expr {($is_s3 && $em && $is_appr && $sent)   ? $v : ""}] \
            [expr {($is_s3 && $em && $is_appr && $repl)   ? $v : ""}]]
    }

    # _refresh_seg_children: delete existing child rows for seg_name, then
    # insert one child per contact in AllContacts that belongs to this segment
    # (matched by file tail of _segment_dir). Called from on_segment_loaded
    # after each phase updates the segment row's values.
    method _refresh_seg_children {seg_name} {
        set t0 [clock microseconds]
        foreach child [$PTree children $seg_name] { $PTree delete $child }
        foreach c [$Campaign get_all_contacts] {
            if {[file tail [dict get $c _segment_dir]] ne $seg_name} continue
            set name [dict get $c contact_name]
            $PTree insert $seg_name end -text "  $name" -values [my _contact_values $c]
        }
        set t1 [clock microseconds]
        set n [llength [$PTree children $seg_name]]
        puts stderr "_refresh_seg_children $seg_name ($n rows): [expr {$t1 - $t0}] us"
    }
}

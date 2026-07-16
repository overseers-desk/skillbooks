# spar-manager/ui/segment-viewer.tcl
#
# spar::ui::SegmentViewer — read-only pane that renders the parsed
# segment.yaml of one segment. Opens on Double-1 against a row in the
# ProgressTable. Shares `.pw.right` with the per-contact Inspector via
# a `shown` event: each viewer hides on the other's `shown`, so the
# pane shows one or the other but not both. Closes via the ✕ button.
#
# The viewer is deliberately read-only. The segment schema is still
# settling; an editor is premature.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::SegmentViewer {
    variable Campaign Progress Pane
    variable Right HeaderStem Body Canvas
    variable CurrentSegment Visible SashPos Subs

    constructor {campaign progress parent_panedwindow} {
        set Campaign       $campaign
        set Progress       $progress
        set Pane           $parent_panedwindow
        set CurrentSegment ""
        set Visible        0
        set SashPos        0
        set Subs           [dict create]

        # Sub-frame inside .pw.right so Inspector and SegmentViewer can
        # coexist as peer subtrees and pack-forget independently.
        set Right ${Pane}.right.seg
        ttk::frame $Right

        ttk::frame ${Right}.hdr
        pack ${Right}.hdr -fill x -side top
        ttk::button ${Right}.hdr.close -text "✕" -style Toolbutton \
            -command [list [self] hide]
        pack ${Right}.hdr.close -side right -padx {0 6}
        set HeaderStem ${Right}.hdr.stem
        ::spar::ui::inspector_widgets::copy_text $HeaderStem ""
        pack $HeaderStem -side left -fill x -expand 1 -padx 6 -pady 4

        set Body [::spar::ui::inspector_widgets::scrollable $Right]
        set Canvas [winfo parent $Body]

        $Progress subscribe segment-double-clicked \
            [list [self] on_segment_double_clicked]
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    method is_visible          {} { return $Visible }

    # ─── Event handlers ───────────────────────────────────────────────────

    method on_segment_double_clicked {seg_name} {
        if {$seg_name eq ""} return
        set CurrentSegment $seg_name
        my show
    }

    # ─── Visibility control ───────────────────────────────────────────────

    method show {} {
        my fire shown
        pack $Right -fill both -expand 1
        set Visible 1
        set w [winfo width $Pane]
        if {$SashPos <= 0 || $SashPos >= $w} {
            set SashPos [expr {int($w * 0.5)}]
        }
        catch { $Pane sashpos 0 $SashPos }
        my render
    }

    method hide {} {
        catch { set SashPos [$Pane sashpos 0] }
        pack forget $Right
        catch { $Pane sashpos 0 [winfo width $Pane] }
        set Visible 0
    }

    # displace — peer viewer is taking the pane. Pack-forget only;
    # leave the sash to the peer's show().
    method displace {} {
        pack forget $Right
        set Visible 0
    }

    # ─── Rendering ────────────────────────────────────────────────────────

    method render {} {
        foreach w [winfo children $Body] { destroy $w }

        if {$CurrentSegment eq ""} {
            ::spar::ui::inspector_widgets::copy_text_set $HeaderStem "(no segment)"
            return
        }

        ::spar::ui::inspector_widgets::copy_text_set $HeaderStem $CurrentSegment

        set seg_dir [file join [$Campaign get_campaign_dir] $CurrentSegment]
        set yaml_path [file join $seg_dir segment.yaml]

        if {![file exists $yaml_path]} {
            ttk::label ${Body}.warn \
                -text "no segment.yaml in [file tail $seg_dir]/" \
                -anchor w
            pack ${Body}.warn -fill x -padx 6 -pady 8
            update idletasks
            ::spar::ui::inspector_widgets::bind_mousewheel_recursive $Canvas $Body
            $Canvas configure -scrollregion [$Canvas bbox all]
            return
        }

        set data [spar::read_segment_yaml $yaml_path]
        if {$data eq ""} {
            ttk::label ${Body}.warn \
                -text "segment.yaml unreadable or empty" \
                -foreground "#aa0000" -anchor w
            pack ${Body}.warn -fill x -padx 6 -pady 8
            update idletasks
            ::spar::ui::inspector_widgets::bind_mousewheel_recursive $Canvas $Body
            $Canvas configure -scrollregion [$Canvas bbox all]
            return
        }

        dict for {k v} $data {
            my render_field $Body $k $v
        }

        update idletasks
        ::spar::ui::inspector_widgets::bind_mousewheel_recursive $Canvas $Body
        $Canvas configure -scrollregion [$Canvas bbox all]
    }

    # render_field — dispatch on field name and shape. yaml2dict returns
    # nested lists for both dicts and arrays; the segment schema is
    # small and stable enough to dispatch by key. Unknown keys fall
    # through to the scalar/text path so future schema additions render
    # without code changes.
    method render_field {parent key value} {
        switch -- $key {
            usps               -
            conversion_funnel  -
            approach_sequencing -
            subsegments        -
            proof_points {
                my render_list_of_dicts $parent $key $value
            }
            default {
                my render_scalar $parent $key $value
            }
        }
    }

    method render_scalar {parent key value} {
        if {$value eq "" || [spar::is_null $value]} {
            ::spar::ui::inspector_widgets::kv_row $parent $key ""
            return
        }
        # Multi-line block scalars (objective, first_ask, rating_rubric,
        # discovery_criteria, etc.) get a soft-wrapped read-only text
        # block under a label header; single-line values become a kv_row.
        if {[string first "\n" $value] >= 0} {
            my render_label_header $parent $key
            ::spar::ui::inspector_widgets::wrapped_text_block \
                $parent [string trim $value]
        } else {
            ::spar::ui::inspector_widgets::kv_row $parent $key $value
        }
    }

    method render_label_header {parent key} {
        set lbl ${parent}.[::spar::ui::inspector_widgets::_uniq lh]
        ttk::label $lbl -text "$key:" -anchor w
        pack $lbl -fill x -padx 6 -pady {6 0}
    }

    method render_list_of_dicts {parent key value} {
        ::spar::ui::inspector_widgets::kv_row $parent $key ""
        if {[llength $value] == 0} return
        set i 0
        foreach item $value {
            set header [my list_item_header $key $item $i]
            set cl [spar::ui::Collapsible new $parent $header 0]
            pack [$cl widget] -fill x -pady {2 2}
            set ibody [$cl body]
            if {[llength $item] % 2 == 0} {
                foreach {ik iv} $item {
                    if {[string first "\n" $iv] >= 0} {
                        my render_label_header $ibody $ik
                        ::spar::ui::inspector_widgets::wrapped_text_block \
                            $ibody [string trim $iv]
                    } else {
                        set disp [expr {[spar::is_null $iv] ? "" : $iv}]
                        ::spar::ui::inspector_widgets::kv_row $ibody $ik $disp 1
                    }
                }
            } else {
                ::spar::ui::inspector_widgets::kv_row $ibody "(item)" $item 1
            }
            incr i
        }
    }

    # list_item_header — a short label per list entry so the user can
    # tell items apart while collapsed. Picks the most distinguishing
    # field for the known list-of-dict keys; falls back to the index.
    method list_item_header {key item idx} {
        if {[llength $item] % 2 != 0} { return "#$idx" }
        set d $item
        switch -- $key {
            usps {
                set id    [dict getdef $d id ""]
                set label [dict getdef $d label ""]
                set type  [dict getdef $d type ""]
                set who   [expr {$id ne "" ? $id : $label}]
                if {$who eq ""} { set who "#$idx" }
                if {$type ne ""} { return "$who ($type)" }
                return $who
            }
            conversion_funnel -
            approach_sequencing {
                set step [dict getdef $d step ""]
                set name [dict getdef $d name ""]
                set parts {}
                if {$step ne ""} { lappend parts $step }
                if {$name ne ""} { lappend parts $name }
                if {[llength $parts] == 0} { return "#$idx" }
                return [join $parts ". "]
            }
            subsegments {
                set name [dict getdef $d name ""]
                if {$name ne ""} { return $name }
                return "#$idx"
            }
            proof_points {
                set id [dict getdef $d id ""]
                if {$id ne ""} { return $id }
                return "#$idx"
            }
        }
        return "#$idx"
    }

}

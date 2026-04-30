# spar-manager/ui/campaign-viewer.tcl
#
# spar::ui::CampaignViewer is a read-only pane that renders the parsed
# campaign.yaml. Opens via the "View full" button in the Campaign
# Configuration labelframe and shares `.pw.right` with the per-contact
# Inspector and the SegmentViewer through cross `shown` subscriptions:
# each viewer hides on the others' `shown`, so the pane carries one of
# the three at a time. Closes via the X button (toggle reuses show/hide).
#
# The viewer is read-only because campaign YAML is hand-curated (often
# with comments) and round-tripping through a Tcl YAML writer would lose
# comments and reflow whitespace.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::CampaignViewer {
    variable Campaign Pane
    variable Right HeaderStem Body Canvas
    variable Visible SashPos Subs

    constructor {campaign parent_panedwindow} {
        set Campaign $campaign
        set Pane     $parent_panedwindow
        set Visible  0
        set SashPos  0
        set Subs     [dict create]

        set Right ${Pane}.right.cmp
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
    }

    # Subscription
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    method is_visible {} { return $Visible }

    # Visibility control

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

    # displace: a peer viewer is taking the pane. Pack-forget the
    # sub-frame; leave the sash to the peer's show().
    method displace {} {
        pack forget $Right
        set Visible 0
    }

    method toggle {} { if {$Visible} { my hide } else { my show } }

    # Rendering

    method render {} {
        foreach w [winfo children $Body] { destroy $w }

        set cdata [$Campaign get_cdata]
        set title [spar::dict_get_default $cdata campaign \
            [file tail [$Campaign get_campaign_file]]]
        ::spar::ui::inspector_widgets::copy_text_set $HeaderStem $title

        if {[dict size $cdata] == 0} {
            ttk::label ${Body}.warn -text "campaign.yaml unreadable or empty" \
                -foreground "#aa0000" -anchor w
            pack ${Body}.warn -fill x -padx 6 -pady 8
            update idletasks
            ::spar::ui::inspector_widgets::bind_mousewheel_recursive \
                $Canvas $Body
            $Canvas configure -scrollregion [$Canvas bbox all]
            return
        }

        dict for {k v} $cdata { my render_field $Body $k $v }

        update idletasks
        ::spar::ui::inspector_widgets::bind_mousewheel_recursive $Canvas $Body
        $Canvas configure -scrollregion [$Canvas bbox all]
    }

    method render_field {parent key value} {
        switch -- $key {
            sender             { my render_sender $parent $value }
            usps               { my render_dict_collapsible $parent $key $value 1 }
            filter             { my render_dict_collapsible $parent $key $value 0 }
            prompt_appendices  { my render_prompt_appendices $parent $value }
            segments           -
            skip_segments      { my render_list $parent $key $value }
            default            {
                ::spar::ui::inspector_widgets::kv_row_wrap $parent $key $value
            }
        }
    }

    method render_sender {parent value} {
        set cl [spar::ui::Collapsible new $parent "sender" 1]
        pack [$cl widget] -fill x -pady {2 2}
        set body [$cl body]
        if {[llength $value] % 2 != 0} {
            ::spar::ui::inspector_widgets::kv_row_wrap $body "(value)" $value 1
            return
        }
        foreach {k v} $value {
            if {$k eq "smtp_pass"} {
                set disp [expr {$v ne "" ? "●●●●●● (set)" : "(unset)"}]
                ::spar::ui::inspector_widgets::kv_row $body $k $disp 1
                continue
            }
            ::spar::ui::inspector_widgets::kv_row_wrap $body $k $v 1
        }
    }

    method render_dict_collapsible {parent key value expanded} {
        set cl [spar::ui::Collapsible new $parent $key $expanded]
        pack [$cl widget] -fill x -pady {2 2}
        set body [$cl body]
        if {[llength $value] == 0} {
            ttk::label ${body}.empty -text "(empty)" -foreground "#777777" \
                -anchor w
            pack ${body}.empty -fill x -padx 22 -pady 2
            return
        }
        if {[llength $value] % 2 != 0} {
            ::spar::ui::inspector_widgets::kv_row_wrap $body "(value)" $value 1
            return
        }
        foreach {k v} $value {
            ::spar::ui::inspector_widgets::kv_row_wrap $body $k $v 1
        }
    }

    method render_prompt_appendices {parent value} {
        set cl [spar::ui::Collapsible new $parent "prompt_appendices" 0]
        pack [$cl widget] -fill x -pady {2 2}
        set body [$cl body]
        if {[llength $value] == 0 || [llength $value] % 2 != 0} {
            ttk::label ${body}.empty -text "(empty)" -foreground "#777777" \
                -anchor w
            pack ${body}.empty -fill x -padx 22 -pady 2
            return
        }
        foreach {k v} $value {
            my render_label_header $body $k 1
            my render_text_block $body [string trim $v]
        }
    }

    method render_list {parent key value} {
        my render_label_header $parent $key 0
        if {[llength $value] == 0} {
            ttk::label ${parent}.[::spar::ui::inspector_widgets::_uniq lstem] \
                -text "(empty)" -foreground "#777777" -anchor w
            pack [lindex [winfo children $parent] end] \
                -fill x -padx 22 -pady 2
            return
        }
        foreach item $value {
            set lbl ${parent}.[::spar::ui::inspector_widgets::_uniq lstit]
            ttk::label $lbl -text "• $item" -anchor w
            pack $lbl -fill x -padx {22 4} -pady 1
        }
    }

    method render_label_header {parent key indent} {
        set lpad [expr {$indent * 16 + 6}]
        set lbl ${parent}.[::spar::ui::inspector_widgets::_uniq lh]
        ttk::label $lbl -text "${key}:" -anchor w
        pack $lbl -fill x -padx [list $lpad 4] -pady {6 0}
    }

    method render_text_block {parent text} {
        set tw ${parent}.[::spar::ui::inspector_widgets::_uniq tb]
        text $tw -wrap word -relief flat -borderwidth 0 -takefocus 0 \
            -height 1 -background [. cget -background]
        $tw insert end $text
        $tw configure -state disabled
        pack $tw -fill x -padx {22 4} -pady {2 4}
        update idletasks
        set n [$tw count -displaylines 1.0 end]
        if {$n < 1}  { set n 1 }
        if {$n > 20} { set n 20 }
        $tw configure -height $n
    }
}

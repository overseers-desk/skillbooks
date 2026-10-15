# spar-manager/ui/campaign-viewer.tcl
#
# spar::ui::CampaignViewer is a read-only pane that renders the parsed
# campaign.yaml. Opens via the "View full" button in the Campaign
# Configuration labelframe, which toggles it. A PaneViewer: shares
# `.pw.right` with its peers, one at a time. Closes via the ✕ button.
#
# The viewer is read-only because campaign YAML is hand-curated (often
# with comments) and round-tripping through a Tcl YAML writer would lose
# comments and reflow whitespace.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::CampaignViewer {
    superclass spar::ui::PaneViewer
    variable Campaign
    variable Right HeaderStem Body Canvas

    constructor {campaign parent_panedwindow} {
        next $parent_panedwindow cmp
        set Campaign $campaign

        set Body [::spar::ui::inspector_widgets::scrollable $Right]
        set Canvas [winfo parent $Body]
    }

    # Rendering

    method render {} {
        foreach w [winfo children $Body] { destroy $w }

        set cdata [$Campaign get_cdata]
        set title [dict getdef $cdata campaign \
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
            ::spar::ui::inspector_widgets::label_header $body $k 1
            ::spar::ui::inspector_widgets::wrapped_text_block \
                $body [string trim $v] {-fill x -padx {22 4} -pady {2 4}}
        }
    }
}

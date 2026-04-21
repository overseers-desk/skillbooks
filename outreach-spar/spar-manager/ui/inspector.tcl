# spar-manager/ui/inspector.tcl
#
# spar::ui::Inspector — contact-inspector pane.
#
# Fills .pw.right (already created by spar-ui.tcl) with a header strip
# and a scrollable body, and renders the selected contact's roster,
# profile, and approach sections. Read-only. Opens on leaf double-click;
# closes via the ✕ button in the header. Selection changes update the
# body when open. Multi-select and non-leaf selections fire an empty
# stem from TransitionTree and are ignored so the last single-selection
# contents persist.
#
# TclOO leading-underscore reminder: methods invoked externally (via
# after, bind, fileevent, -command, or subscription callbacks) MUST NOT
# start with an underscore — TclOO will not export them. That applies
# to on_selection_changed, on_double_clicked, on_refreshed, show, hide,
# toggle.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::Inspector {
    variable Campaign Tree
    variable Pane CurrentStem Visible SashPos CollapseMemory
    variable Right HeaderStem Canvas Body
    variable Subs

    constructor {campaign tree parent_panedwindow} {
        set Campaign        $campaign
        set Tree            $tree
        set Pane            $parent_panedwindow
        set CurrentStem     ""
        set Visible         0
        set SashPos         0
        set CollapseMemory  [dict create]
        set Subs            [dict create]

        set Right ${Pane}.right

        # Header strip: stem label (left) + ✕ close button (right).
        ttk::frame ${Right}.hdr
        pack ${Right}.hdr -fill x -side top
        set HeaderStem ${Right}.hdr.stem
        ttk::label $HeaderStem -text "" -font "TkDefaultFont 9 bold" -anchor w
        pack $HeaderStem -side left -fill x -expand 1 -padx 6 -pady 4
        ttk::button ${Right}.hdr.close -text "✕" -style Toolbutton \
            -command [list [self] hide]
        pack ${Right}.hdr.close -side right -padx {0 6}

        # Scroll area: canvas + vertical scrollbar; inner frame attached
        # via create window. <Configure> on the canvas drives both the
        # scrollregion and the inner-frame width so children reflow.
        ttk::frame ${Right}.sc
        pack ${Right}.sc -fill both -expand 1
        set Canvas ${Right}.sc.cv
        canvas $Canvas -highlightthickness 0 \
            -yscrollcommand [list ${Right}.sc.vsb set]
        ttk::scrollbar ${Right}.sc.vsb -orient vertical \
            -command [list $Canvas yview]
        pack ${Right}.sc.vsb -side right -fill y
        pack $Canvas -side left -fill both -expand 1

        set Body ${Canvas}.inner
        ttk::frame $Body
        $Canvas create window 0 0 -window $Body -anchor nw -tags inner

        bind $Canvas <Configure> [list apply {{cv w} {
            $cv itemconfigure inner -width $w
            $cv configure -scrollregion [$cv bbox all]
        }} $Canvas %w]
        bind $Body <Configure> [list apply {{cv} {
            $cv configure -scrollregion [$cv bbox all]
        }} $Canvas]

        $Tree subscribe selection-changed [list [self] on_selection_changed]
        $Tree subscribe double-clicked    [list [self] on_double_clicked]
        $Campaign subscribe refreshed     [list [self] on_refreshed]
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method get_current_stem {} { return $CurrentStem }
    method is_visible       {} { return $Visible }

    # ─── Event handlers ───────────────────────────────────────────────────

    # Ignore empty stems so multi-select and non-leaf selections keep the
    # pane on the prior single-selection contents rather than blanking.
    method on_selection_changed {stem} {
        if {$stem eq ""} return
        set CurrentStem $stem
        if {$Visible} { my render }
    }

    method on_double_clicked {stem} {
        if {$stem eq ""} return
        set CurrentStem $stem
        my show
    }

    method on_refreshed {} {
        if {$Visible} { my render }
    }

    # ─── Visibility control ───────────────────────────────────────────────

    method show {} {
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
        catch { $Pane sashpos 0 [winfo width $Pane] }
        set Visible 0
    }

    method toggle {} { if {$Visible} { my hide } else { my show } }

    # ─── Rendering ────────────────────────────────────────────────────────

    method render {} {
        foreach w [winfo children $Body] { destroy $w }

        if {$CurrentStem eq ""} {
            $HeaderStem configure -text "(no selection)"
            ttk::label ${Body}.placeholder \
                -text "Select a contact to inspect." -anchor w
            pack ${Body}.placeholder -fill x -padx 6 -pady 8
            return
        }

        $HeaderStem configure -text $CurrentStem

        set contact [$Campaign get_contact $CurrentStem]
        if {$contact eq ""} {
            ttk::label ${Body}.placeholder \
                -text "Contact not loaded yet." -anchor w
            pack ${Body}.placeholder -fill x -padx 6 -pady 8
            return
        }

        my _render_roster   $contact
        if {[spar::dict_get_default $contact profile_path ""] ne ""} {
            my _render_profile $contact
        }
        if {[spar::dict_get_default $contact approach_path ""] ne ""} {
            my _render_approach $contact
        }

        ::spar::ui::inspector_widgets::bind_mousewheel_recursive $Canvas $Body
        update idletasks
        $Canvas configure -scrollregion [$Canvas bbox all]
    }

    # ─── Section renderers ────────────────────────────────────────────────

    method _render_roster {contact} {
        set sec [::spar::ui::inspector_widgets::collapsible $Body roster "Roster" 1]
        pack $sec -fill x -pady {4 2}
        set body ${sec}.body

        set name   [spar::dict_get_default $contact contact_name ""]
        set org    [spar::dict_get_default $contact organisation ""]
        set role   [spar::dict_get_default $contact role ""]
        set seg    [spar::dict_get_default $contact _segment_dir ""]
        if {$seg ne ""} { set seg [file tail $seg] }
        set star   [spar::dict_get_default $contact star ""]
        set state  [spar::dict_get_default $contact state ""]

        set channels {}
        if {[spar::dict_get_default $contact has_email      0]} { lappend channels "email" }
        if {[spar::dict_get_default $contact has_linkedin   0]} { lappend channels "linkedin" }
        if {[spar::dict_get_default $contact has_facebook   0]} { lappend channels "facebook" }
        if {[spar::dict_get_default $contact has_phone_only 0]} { lappend channels "phone-only" }

        ::spar::ui::inspector_widgets::kv_row $body "Name"         $name
        ::spar::ui::inspector_widgets::kv_row $body "Organisation" $org
        ::spar::ui::inspector_widgets::kv_row $body "Role"         $role
        ::spar::ui::inspector_widgets::kv_row $body "Segment"      $seg
        ::spar::ui::inspector_widgets::kv_row $body "Channels"     [join $channels ", "]
        ::spar::ui::inspector_widgets::kv_row $body "Star"         $star
        ::spar::ui::inspector_widgets::kv_row $body "State"        $state

        set dx [spar::dict_get_default $contact date_excluded ""]
        if {$dx ne "" && ![spar::is_null $dx]} {
            ::spar::ui::inspector_widgets::kv_row $body "Excluded" $dx
        }
    }

    method _render_profile {contact} {
        set sec [::spar::ui::inspector_widgets::collapsible $Body profile "Profile" 1]
        pack $sec -fill x -pady {2 2}
        set body ${sec}.body

        set path [dict get $contact profile_path]
        set fm [spar::read_profile_front_matter $path]
        if {$fm eq ""} {
            ttk::label ${body}.warn \
                -text "profile front-matter unreadable" -foreground "#aa0000"
            pack ${body}.warn -fill x -padx 6 -pady 2
        } else {
            dict for {k v} $fm {
                my _render_profile_value $body $k $v
            }
        }

        set text [spar::read_profile_body $path]
        set text [string trim $text]
        if {$text ne ""} {
            set nlines [llength [split $text \n]]
            if {$nlines > 20} { set nlines 20 }
            if {$nlines < 3}  { set nlines 3 }
            set tw ${body}.bodytxt
            text $tw -wrap word -relief flat -borderwidth 0 \
                -height $nlines -font "TkDefaultFont" \
                -background [. cget -background]
            $tw insert end $text
            $tw configure -state disabled
            pack $tw -fill x -padx 6 -pady {4 2}
        }
    }

    # Dispatch by key name for the known structured frontmatter fields.
    # yaml2dict returns dicts and lists as indistinguishable flat lists,
    # so heuristic type detection is unreliable; the schema (spar-P-profile.md
    # §5.1) is small and stable enough to dispatch by name.
    method _render_profile_value {body key val} {
        switch -- $key {
            dependent_data {
                ::spar::ui::inspector_widgets::kv_row $body $key ""
                if {[llength $val] % 2 == 0} {
                    foreach {sk sv} $val {
                        set disp $sv
                        if {[spar::is_null $sv]} { set disp "" }
                        ::spar::ui::inspector_widgets::kv_row $body $sk $disp 1
                    }
                }
            }
            applicable_angles {
                ::spar::ui::inspector_widgets::kv_row $body $key ""
                foreach item $val {
                    ::spar::ui::inspector_widgets::kv_row $body "" $item 1
                }
            }
            default {
                set disp $val
                if {[spar::is_null $val]} { set disp "" }
                ::spar::ui::inspector_widgets::kv_row $body $key $disp
            }
        }
    }

    method _render_approach {contact} {
        set sec [::spar::ui::inspector_widgets::collapsible $Body approach "Approach" 1]
        pack $sec -fill x -pady {2 4}
        set body ${sec}.body

        set path [dict get $contact approach_path]
        set data [spar::read_approach_yaml $path]
        if {$data eq "" || ![dict exists $data rounds]} {
            ttk::label ${body}.warn -text "approach YAML unreadable or empty"
            pack ${body}.warn -fill x -padx 6 -pady 2
            return
        }

        set stem $CurrentStem
        set idx 0
        foreach round [dict get $data rounds] {
            set rtype [spar::dict_get_default $round type ""]
            set messages [spar::dict_get_default $round messages {}]

            set latest_sec 0
            foreach msg $messages {
                set ad [spar::dict_get_default $msg actioned_date ""]
                if {$ad eq "" || [spar::is_null $ad]} continue
                set s [my _date_to_sec $ad]
                if {$s ne "" && $s > $latest_sec} { set latest_sec $s }
            }

            set header "Round $idx — $rtype"
            if {$latest_sec > 0} {
                append header "  (sent: [clock format $latest_sec -format %Y-%m-%d -timezone :UTC])"
            }

            set round_key [list $stem $idx]
            set default_expanded [expr {$rtype eq "final" ? 1 : 0}]
            if {[dict exists $CollapseMemory $round_key]} {
                set expanded [dict get $CollapseMemory $round_key]
            } else {
                set expanded $default_expanded
            }

            set rsec [::spar::ui::inspector_widgets::collapsible_cb \
                $body "r$idx" $header $expanded \
                [list [self] remember_collapse $round_key]]
            pack $rsec -fill x -pady {2 2}
            set rbody ${rsec}.body

            set mi 0
            foreach msg $messages {
                my _render_message $rbody $mi $msg
                incr mi
            }

            incr idx
        }
    }

    method remember_collapse {round_key expanded} {
        dict set CollapseMemory $round_key $expanded
    }

    method _render_message {parent idx msg} {
        set frame ${parent}.m${idx}
        ttk::frame $frame -borderwidth 1 -relief solid
        pack $frame -fill x -padx 4 -pady 2

        set channel [spar::dict_get_default $msg channel ""]
        ::spar::ui::inspector_widgets::kv_row $frame "Channel" $channel

        if {$channel eq "email"} {
            set to   [spar::dict_get_default $msg to ""]
            set cc   [spar::dict_get_default $msg cc ""]
            set bcc  [spar::dict_get_default $msg bcc ""]
            set subj [spar::dict_get_default $msg subject ""]

            if {[llength $to] > 0} {
                ::spar::ui::inspector_widgets::kv_row $frame "To" [join $to ", "]
            }
            if {$cc ne "" && ![spar::is_null $cc] && [llength $cc] > 0} {
                ::spar::ui::inspector_widgets::kv_row $frame "Cc" [join $cc ", "]
            }
            if {$bcc ne "" && ![spar::is_null $bcc] && [llength $bcc] > 0} {
                ::spar::ui::inspector_widgets::kv_row $frame "Bcc" [join $bcc ", "]
            }
            if {$subj ne ""} {
                ::spar::ui::inspector_widgets::kv_row $frame "Subject" $subj
            }
        }

        set body [spar::dict_get_default $msg body ""]
        if {$body ne "" && ![spar::is_null $body]} {
            set body [string trim $body]
            set nlines [llength [split $body \n]]
            if {$nlines > 20} { set nlines 20 }
            if {$nlines < 3}  { set nlines 3 }
            set tw ${frame}.body
            text $tw -wrap word -relief flat -borderwidth 0 \
                -height $nlines -font "TkDefaultFont" \
                -background [. cget -background]
            $tw insert end $body
            $tw configure -state disabled
            pack $tw -fill x -padx 6 -pady {2 2}
        }

        set ad [spar::dict_get_default $msg actioned_date ""]
        if {$ad ne "" && ![spar::is_null $ad]} {
            ::spar::ui::inspector_widgets::kv_row $frame "Sent" \
                [my _fmt_date_with_since $ad]
        }
        set rd [spar::dict_get_default $msg replied_date ""]
        if {$rd ne "" && ![spar::is_null $rd]} {
            ::spar::ui::inspector_widgets::kv_row $frame "Replied" \
                [my _fmt_date_with_since $rd]
        }
    }

    # Date values may arrive as ISO strings or as YAML-parsed Unix
    # epoch integers; normalise to seconds and fail closed on anything
    # else.
    method _date_to_sec {v} {
        if {[string is integer -strict $v]} { return $v }
        if {[catch {clock scan $v -format %Y-%m-%d -timezone :UTC} s]} {
            return ""
        }
        return $s
    }

    method _fmt_date_with_since {v} {
        set s [my _date_to_sec $v]
        if {$s eq ""} { return $v }
        set iso [clock format $s -format %Y-%m-%d -timezone :UTC]
        set days [spar::_days_since $s]
        if {$days eq "" || $days < 0} { return $iso }
        if {$days == 0} { return "$iso (today)" }
        if {$days == 1} { return "$iso (1 day ago)" }
        return "$iso ($days days ago)"
    }
}

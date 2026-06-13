# spar-manager/ui/inspector.tcl
#
# spar::ui::Inspector — per-contact detail pane with four tabs labelled
# S, P, A, R (the pipeline's own vocabulary: Roster, Profile, Approach,
# Reply). Fills .pw.right (already created by spar-ui.tcl) with a header
# strip and a ttk::notebook. Each tab's enabled/disabled state reflects
# which data exists for the contact; render selects the latest-reached
# tab so arrow-keying down the tree lands on whichever surface carries
# the newest information for each contact. Read-only. Opens on leaf
# double-click; closes via the ✕ button. Selection changes update the
# bodies when open. Multi-select and non-leaf selections fire an empty
# stem from TransitionTree and are ignored so the last single-selection
# contents persist.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::Inspector {
    variable Campaign Tree
    variable Pane CurrentStem Visible SashPos
    variable Right HeaderStem Notebook
    variable Tabs TabFrames TabCanvases CollapseMemory
    variable Subs

    constructor {campaign tree parent_panedwindow} {
        set Campaign        $campaign
        set Tree            $tree
        set Pane            $parent_panedwindow
        set CurrentStem     ""
        set Visible         0
        set SashPos         0
        set Tabs            [dict create]
        set TabFrames       [dict create]
        set TabCanvases     [dict create]
        set CollapseMemory  [dict create]
        set Subs            [dict create]

        # Own a sub-frame inside .pw.right so SegmentViewer can pack a
        # peer sub-frame in the same pane and the two can swap visibility
        # without their widget trees colliding. Pack the sub-frame at
        # construction so .pw.right contributes its natural width to the
        # toplevel's initial layout — otherwise the window opens narrower
        # and the half-of-current-width sash math shrinks .pw.main more
        # than it did before this refactor.
        set Right ${Pane}.right.insp
        ttk::frame $Right
        pack $Right -fill both -expand 1

        ttk::frame ${Right}.hdr
        pack ${Right}.hdr -fill x -side top
        ttk::button ${Right}.hdr.close -text "✕" -style Toolbutton \
            -command [list [self] hide]
        pack ${Right}.hdr.close -side right -padx {0 6}
        set HeaderStem ${Right}.hdr.stem
        ::spar::ui::inspector_widgets::copy_text $HeaderStem ""
        pack $HeaderStem -side left -fill x -expand 1 -padx 6 -pady 4

        # Notebook sits directly under the header so its tab strip stays
        # fixed. Each tab owns its own scrollable canvas, so scrolling
        # within an active tab moves only that tab's content (the tab
        # strip never scrolls off). Per-tab scrollbars also mean tall P
        # or R bodies show a working scrollbar against their own tab.
        set Notebook ${Right}.nb
        ttk::notebook $Notebook
        pack $Notebook -fill both -expand 1

        foreach letter {S P A R} {
            set frame ${Notebook}.[string tolower $letter]
            ttk::frame $frame
            $Notebook add $frame -text $letter
            set body   [::spar::ui::inspector_widgets::scrollable $frame]
            set canvas [winfo parent $body]
            dict set TabFrames   $letter $frame
            dict set Tabs        $letter $body
            dict set TabCanvases $letter $canvas
        }

        $Tree subscribe selection-changed [list [self] on_selection_changed]
        $Tree subscribe double-clicked    [list [self] on_double_clicked]
        $Campaign subscribe fully-loaded  [list [self] on_fully_loaded]
    }

    # ─── Subscription / accessors ─────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

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

    method on_fully_loaded {} { if {$Visible} { my render } }

    # ─── Visibility control ───────────────────────────────────────────────

    method show {} {
        # Fire `shown` first so any peer viewer pack-forgets its
        # sub-frame before we pack ours and slide the sash open.
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

    # displace — peer viewer is taking the pane. Pack-forget our
    # sub-frame but leave the sash position alone; the peer's show()
    # will set it. Distinct from `hide` (which retracts the sash) so
    # the show→displace→pack→sashpos flow doesn't fight itself.
    method displace {} {
        pack forget $Right
        set Visible 0
    }

    method toggle {} { if {$Visible} { my hide } else { my show } }

    # ─── Rendering ────────────────────────────────────────────────────────

    method render {} {
        dict for {letter tab} $Tabs {
            foreach w [winfo children $tab] { destroy $w }
        }

        if {$CurrentStem eq "" || [set contact [$Campaign get_contact $CurrentStem]] eq ""} {
            ::spar::ui::inspector_widgets::copy_text_set $HeaderStem \
                [expr {$CurrentStem eq "" ? "(no selection)" : $CurrentStem}]
            set msg [expr {$CurrentStem eq "" ? "Select a contact to inspect." : "Contact not loaded yet."}]
            ttk::label [dict get $Tabs S].ph -text $msg -anchor w
            pack [dict get $Tabs S].ph -fill x -padx 6 -pady 8
            foreach letter {S P A R} {
                $Notebook tab [dict get $TabFrames $letter] -text $letter \
                    -state [expr {$letter eq "S" ? "normal" : "disabled"}]
            }
            $Notebook select [dict get $TabFrames S]
            return
        }

        set seg [spar::dict_get_default $contact _segment_dir ""]
        if {$seg ne ""} { set seg [file tail $seg] }
        set heading [expr {$seg ne "" ? "$seg/$CurrentStem" : $CurrentStem}]
        ::spar::ui::inspector_widgets::copy_text_set $HeaderStem $heading

        set has_profile  [expr {[spar::dict_get_default $contact profile_path ""]  ne ""}]
        set has_approach [expr {[spar::dict_get_default $contact approach_path ""] ne ""}]
        set replies      [my collect_replies $contact]
        set has_reply    [expr {[llength $replies] > 0}]

        $Notebook tab [dict get $TabFrames S] -state normal -text [my tab_title_s $contact]
        $Notebook tab [dict get $TabFrames P] -state [expr {$has_profile  ? "normal" : "disabled"}] \
            -text [expr {$has_profile  ? [my tab_title_p $contact] : "P"}]
        $Notebook tab [dict get $TabFrames A] -state [expr {$has_approach ? "normal" : "disabled"}] \
            -text [expr {$has_approach ? [my tab_title_a $contact] : "A"}]
        $Notebook tab [dict get $TabFrames R] -state [expr {$has_reply    ? "normal" : "disabled"}] \
            -text [expr {$has_reply    ? "R [llength $replies]" : "R"}]

        my fill_s $contact
        if {$has_profile}  { my fill_p $contact }
        if {$has_approach} { my fill_a $contact }
        if {$has_reply}    { my fill_r $replies }

        set latest S
        if {$has_profile}  { set latest P }
        if {$has_approach} { set latest A }
        if {$has_reply}    { set latest R }
        $Notebook select [dict get $TabFrames $latest]

        update idletasks
        dict for {letter body} $Tabs {
            set canvas [dict get $TabCanvases $letter]
            ::spar::ui::inspector_widgets::bind_mousewheel_recursive $canvas $body
            $canvas configure -scrollregion [$canvas bbox all]
        }
    }

    # Tab titles carry each authoring tab's self-assessment of the contact:
    # S names the contact (roster identity), P shows the P-authored star
    # rating, A shows the A-authored response_likelihood (a root key in the
    # approach YAML, read from the file), R the reply count.
    # Disabled tabs stay as bare letters (see render).

    method tab_title_s {contact} {
        set name [spar::dict_get_default $contact contact_name ""]
        set org  [spar::dict_get_default $contact organisation ""]
        set parts {}
        if {$name ne ""} { lappend parts $name }
        if {$org  ne ""} { lappend parts $org }
        if {[llength $parts] == 0} { return "S" }
        return "S: [join $parts ", "]"
    }

    method tab_title_p {contact} {
        set star [spar::dict_get_default $contact star 0]
        if {![string is integer -strict $star] || $star <= 0} { return "P" }
        if {$star > 5} { set star 5 }
        return "P [string repeat "★" $star][string repeat "☆" [expr {5 - $star}]]"
    }

    method tab_title_a {contact} {
        set path [spar::dict_get_default $contact approach_path ""]
        if {$path eq ""} { return "A" }
        set data [spar::read_approach_yaml $path]
        set pct [spar::dict_get_default $data response_likelihood ""]
        if {$pct eq "" || [spar::is_null $pct]} { return "A" }
        return "A ${pct}%"
    }

    # Walk every round's replies[] keeping direction=received. Attach the
    # round index so the R tab can label each reply with its origin.
    method collect_replies {contact} {
        set out {}
        set path [spar::dict_get_default $contact approach_path ""]
        if {$path eq ""} { return $out }
        set data [spar::read_approach_yaml $path]
        if {$data eq "" || ![dict exists $data rounds]} { return $out }
        set idx 0
        foreach round [dict get $data rounds] {
            foreach reply [spar::dict_get_default $round replies {}] {
                if {[spar::dict_get_default $reply direction ""] ne "received"} continue
                lappend out [dict merge $reply [dict create _round $idx]]
            }
            incr idx
        }
        return $out
    }

    # ─── Tab fillers ──────────────────────────────────────────────────────

    method fill_s {contact} {
        set body [dict get $Tabs S]
        set seg [spar::dict_get_default $contact _segment_dir ""]
        if {$seg ne ""} { set seg [file tail $seg] }

        set channels {}
        foreach {flag label} {has_email email has_linkedin linkedin has_facebook facebook has_phone_only phone-only} {
            if {[spar::dict_get_default $contact $flag 0]} { lappend channels $label }
        }

        foreach {label key} {
            Name         contact_name
            Organisation organisation
            Role         role
            Star         star
            State        state
        } {
            ::spar::ui::inspector_widgets::kv_row $body $label \
                [spar::dict_get_default $contact $key ""]
        }
        ::spar::ui::inspector_widgets::kv_row $body "Segment"  $seg
        ::spar::ui::inspector_widgets::kv_row $body "Channels" [join $channels ", "]

        set dx [spar::dict_get_default $contact date_excluded ""]
        if {$dx ne "" && ![spar::is_null $dx]} {
            ::spar::ui::inspector_widgets::kv_row $body "Excluded" $dx
        }
    }

    method fill_p {contact} {
        set body [dict get $Tabs P]
        set path [dict get $contact profile_path]
        set fm [spar::read_profile_front_matter $path]
        if {$fm eq ""} {
            ttk::label ${body}.warn -text "profile front-matter unreadable" \
                -foreground "#aa0000"
            pack ${body}.warn -fill x -padx 6 -pady 2
        } else {
            dict for {k v} $fm { my render_profile_value $body $k $v }
        }
        set text [string trim [spar::read_profile_body $path]]
        if {$text ne ""} {
            ::spar::ui::inspector_widgets::wrapped_text_block \
                $body $text {-fill x -padx 6 -pady {2 2}} 0
        }
    }

    # Dispatch by key name for the known structured frontmatter fields.
    # yaml2dict returns dicts and lists as indistinguishable flat lists,
    # so heuristic type detection is unreliable; the schema (spar-P-profile.md
    # §5.1) is small and stable enough to dispatch by name.
    method render_profile_value {body key val} {
        switch -- $key {
            dependent_data {
                ::spar::ui::inspector_widgets::kv_row $body $key ""
                if {[llength $val] % 2 == 0} {
                    foreach {sk sv} $val {
                        set disp [expr {[spar::is_null $sv] ? "" : $sv}]
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
                set disp [expr {[spar::is_null $val] ? "" : $val}]
                ::spar::ui::inspector_widgets::kv_row $body $key $disp
            }
        }
    }

    method fill_a {contact} {
        set body [dict get $Tabs A]
        set data [spar::read_approach_yaml [dict get $contact approach_path]]
        if {$data eq "" || ![dict exists $data rounds]} {
            ttk::label ${body}.warn -text "approach YAML unreadable or empty"
            pack ${body}.warn -fill x -padx 6 -pady 2
            return
        }

        set idx 0
        foreach round [dict get $data rounds] {
            set rtype   [spar::dict_get_default $round type ""]
            set rnumber [spar::dict_get_default $round number ""]

            set header "Round $idx — $rtype"
            if {$rnumber ne "" && ![spar::is_null $rnumber]} {
                append header " #$rnumber"
            }

            set key [list $CurrentStem $idx]
            if {[dict exists $CollapseMemory $key]} {
                set expanded [dict get $CollapseMemory $key]
            } else {
                set expanded [expr {$rtype eq "final"}]
            }

            set cl [spar::ui::Collapsible new $body $header $expanded]
            pack [$cl widget] -fill x -pady {2 2}
            $cl subscribe toggled [list [self] remember_collapse $key]

            set rbody [$cl body]
            set mi 0
            foreach msg [spar::dict_get_default $round messages {}] {
                my render_message $rbody $mi $msg
                incr mi
            }
            incr idx
        }
    }

    method remember_collapse {key expanded} {
        dict set CollapseMemory $key $expanded
    }

    # Replies reuse render_message by projecting reply fields onto the
    # message schema. The round tag rides on the channel label so each
    # reply still shows which round drew it out.
    method fill_r {replies} {
        set body [dict get $Tabs R]
        set sorted [lsort -command [list [self] reply_cmp] $replies]
        set idx 0
        foreach reply $sorted {
            my render_message $body $idx [dict create \
                channel       "reply (round [dict get $reply _round])" \
                from          [spar::dict_get_default $reply from ""] \
                subject       [spar::dict_get_default $reply subject ""] \
                body          [spar::dict_get_default $reply body ""] \
                received_date [spar::dict_get_default $reply date ""]]
            incr idx
        }
    }

    method reply_cmp {a b} {
        set sa [my date_to_sec [spar::dict_get_default $a date ""]]
        set sb [my date_to_sec [spar::dict_get_default $b date ""]]
        if {$sa eq ""} { set sa 0 }
        if {$sb eq ""} { set sb 0 }
        return [expr {$sb - $sa}]
    }

    method render_message {parent idx msg} {
        set frame ${parent}.m${idx}
        ttk::frame $frame -borderwidth 1 -relief solid
        pack $frame -fill x -padx 4 -pady 2

        ::spar::ui::inspector_widgets::kv_row $frame "Channel" \
            [spar::dict_get_default $msg channel ""]

        set from [spar::dict_get_default $msg from ""]
        if {$from ne "" && ![spar::is_null $from]} {
            ::spar::ui::inspector_widgets::kv_row $frame "From" $from
        }

        if {[spar::dict_get_default $msg channel ""] eq "email"} {
            foreach {label key} {To to Cc cc Bcc bcc} {
                set v [spar::dict_get_default $msg $key ""]
                if {$v ne "" && ![spar::is_null $v] && [llength $v] > 0} {
                    ::spar::ui::inspector_widgets::kv_row $frame $label [join $v ", "]
                }
            }
        }

        set subj [spar::dict_get_default $msg subject ""]
        if {$subj ne "" && ![spar::is_null $subj]} {
            ::spar::ui::inspector_widgets::kv_row $frame "Subject" $subj
        }

        set body [spar::dict_get_default $msg body ""]
        if {$body ne "" && ![spar::is_null $body]} {
            ::spar::ui::inspector_widgets::wrapped_text_block \
                $frame [string trim $body] {-fill x -padx 6 -pady {2 2}} 0
        }

        foreach {label key} {Sent actioned_date Received received_date} {
            set v [spar::dict_get_default $msg $key ""]
            if {$v ne "" && ![spar::is_null $v]} {
                ::spar::ui::inspector_widgets::kv_row $frame $label \
                    [my fmt_date_with_since $v]
            }
        }
    }

    # Date values may arrive as ISO strings or as YAML-parsed Unix
    # epoch integers; normalise to seconds and fail closed on anything
    # else.
    method date_to_sec {v} {
        if {[string is integer -strict $v]} { return $v }
        if {[catch {clock scan $v -format %Y-%m-%d -timezone :UTC} s]} {
            if {[catch {clock scan $v -timezone :UTC} s]} { return "" }
        }
        return $s
    }

    method fmt_date_with_since {v} {
        set s [my date_to_sec $v]
        if {$s eq ""} { return $v }
        set iso [clock format $s -format %Y-%m-%d -timezone :UTC]
        set days [spar::_days_since $s]
        if {$days eq "" || $days < 0} { return $iso }
        if {$days == 0} { return "$iso (today)" }
        if {$days == 1} { return "$iso (1 day ago)" }
        return "$iso ($days days ago)"
    }
}

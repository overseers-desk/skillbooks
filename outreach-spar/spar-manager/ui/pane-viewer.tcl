# spar-manager/ui/pane-viewer.tcl
#
# spar::ui::PaneViewer — the shell the right-pane viewers (Inspector,
# SegmentViewer, CampaignViewer) share. Each viewer owns a sub-frame of
# ${pane}.right with a header strip (title and ✕ close button), and the
# pane carries one viewer at a time: showing one displaces every other
# viewer constructed on the same pane. The peers are found through a
# per-pane registry, so a new viewer is one `new` line with no wiring.
#
# Subclasses call `next $pane $name` from their constructor, fill the
# sub-frame below the header, and define `render`, which `show` calls.
# The sash position is kept across hide/show.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::PaneViewer {
    variable Pane Right HeaderStem Visible SashPos

    constructor {pane name} {
        set Pane    $pane
        set Visible 0
        set SashPos 0

        set Right ${Pane}.right.$name
        ttk::frame $Right

        ttk::frame ${Right}.hdr
        pack ${Right}.hdr -fill x -side top
        ttk::button ${Right}.hdr.close -text "✕" -style Toolbutton \
            -command [list [self] hide]
        pack ${Right}.hdr.close -side right -padx {0 6}
        set HeaderStem ${Right}.hdr.stem
        ::spar::ui::inspector_widgets::copy_text $HeaderStem ""
        pack $HeaderStem -side left -fill x -expand 1 -padx 6 -pady 4

        # Peers: pane -> the viewers constructed on it.
        classvariable Peers
        dict lappend Peers $Pane [self]
    }

    destructor {
        classvariable Peers
        if {[info exists Peers] && [dict exists $Peers $Pane]} {
            dict set Peers $Pane [lsearch -all -inline -not -exact \
                [dict get $Peers $Pane] [self]]
        }
        if {[info exists Right] && [winfo exists $Right]} { destroy $Right }
    }

    method is_visible {} { return $Visible }

    method show {} {
        # Displace the peers first so their sub-frames are gone before
        # we pack ours and slide the sash open.
        classvariable Peers
        foreach p [dict get $Peers $Pane] {
            if {$p ne [self]} { $p displace }
        }
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

    # displace — a peer is taking the pane. Pack-forget our sub-frame but
    # leave the sash alone; the peer's show sets it. Distinct from hide
    # (which retracts the sash) so show→displace→pack→sashpos does not
    # fight itself.
    method displace {} {
        pack forget $Right
        set Visible 0
    }

    method toggle {} { if {$Visible} { my hide } else { my show } }
}

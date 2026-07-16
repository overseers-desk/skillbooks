# spar-manager/ui/collapsible.tcl
#
# spar::ui::Collapsible — a folding section with a header button that
# toggles a body frame. The caller packs [widget] somewhere, fills [body]
# with children, and optionally subscribes to the `toggled` event for
# cross-render persistence (the Inspector keys CollapseMemory by
# [list stem round_idx] and writes back here).

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::Collapsible {
    variable Frame Header Body Expanded HeaderText Subs

    constructor {parent header_text {expanded_default 1}} {
        set HeaderText $header_text
        set Expanded   [expr {!!$expanded_default}]
        set Subs       [dict create]

        set Frame  ${parent}.cl[incr ::spar::ui::_collapsible_seq]
        ttk::frame $Frame
        set Header ${Frame}.hdr
        ttk::button $Header -style Toolbutton -command [list [self] toggle]
        ttk::frame ${Frame}.body
        set Body ${Frame}.body
        pack $Header -fill x -anchor w
        my sync
    }

    method widget      {} { return $Frame }
    method body        {} { return $Body }

    method expand   {} { if {!$Expanded} { my toggle } }
    method collapse {} { if { $Expanded} { my toggle } }

    method toggle {} {
        set Expanded [expr {!$Expanded}]
        my sync
        my fire toggled $Expanded
    }

    method subscribe {event cb} { dict lappend Subs $event $cb }

    method sync {} {
        set glyph [expr {$Expanded ? "▾" : "▸"}]
        $Header configure -text "$glyph  $HeaderText"
        if {$Expanded} {
            pack $Body -fill x -padx {12 0} -pady {2 4}
        } else {
            pack forget $Body
        }
    }

    method fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }
}

set ::spar::ui::_collapsible_seq 0

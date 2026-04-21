# spar-manager/ui/inspector.tcl
#
# spar::ui::Inspector — contact-inspector pane.
#
# SCAFFOLD ONLY. This class exists so that its state (pane widget path,
# current stem, visible flag, sash position, per-round collapse memory)
# has a home from day one of the refactor, and so TransitionTree's
# selection events have a subscriber. The actual rendering (roster /
# profile / approach sections) is issue #66 and is out of scope for
# this commit. Render methods are intentionally empty stubs.
#
# TclOO leading-underscore reminder: methods invoked externally (via
# after, bind, fileevent, -command, or subscription callbacks) MUST NOT
# start with an underscore — TclOO will not export them. That applies
# to on_selection_changed, on_double_clicked, show, hide, toggle.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::Inspector {
    variable Campaign Tree
    variable Pane CurrentStem Visible SashPos CollapseMemory
    variable Subs

    constructor {campaign tree parent_panedwindow} {
        set Campaign        $campaign
        set Tree            $tree
        set Pane            ""
        set CurrentStem     ""
        set Visible         0
        set SashPos         0
        set CollapseMemory  [dict create]
        set Subs            [dict create]

        # Pane widget construction is #66. For the scaffold, stay
        # invisible — don't add a third pane to $parent_panedwindow.
        # The argument is captured so #66's constructor change is local.

        $Tree subscribe selection-changed [list [self] on_selection_changed]
        $Tree subscribe double-clicked    [list [self] on_double_clicked]
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

    # on_selection_changed — TransitionTree fired `selection-changed`.
    # Track the stem; re-render if the pane is visible.
    method on_selection_changed {stem} {
        set CurrentStem $stem
        if {$Visible} { my render }
    }

    # on_double_clicked — TransitionTree fired `double-clicked`. Track
    # the stem and reveal the pane.
    method on_double_clicked {stem} {
        set CurrentStem $stem
        my show
    }

    # ─── Visibility control ───────────────────────────────────────────────

    # show / hide / toggle — flip the visibility flag. Actual pane reveal
    # is #66. Public so future toolbar buttons and keybindings can drive
    # them.
    method show   {} { set Visible 1 }
    method hide   {} { set Visible 0 }
    method toggle {} { if {$Visible} { my hide } else { my show } }

    # ─── Rendering ────────────────────────────────────────────────────────

    # render — #66: draw the roster / profile / approach sections for
    # CurrentStem into Pane. Intentionally empty in the scaffold.
    method render {} {
        # Issue #66.
    }
}

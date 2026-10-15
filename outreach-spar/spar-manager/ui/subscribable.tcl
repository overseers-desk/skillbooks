# spar-manager/ui/subscribable.tcl
#
# spar::ui::Subscribable — the event subscription the UI classes share,
# mixed into each one that fires events. `subscribe event cb` registers
# a callback; `my _fire event ?arg …?` calls every callback registered
# for event, in registration order, with the args appended.

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::Subscribable {
    variable Subs

    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![info exists Subs] || ![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }
}

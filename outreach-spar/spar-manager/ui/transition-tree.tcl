# spar-manager/ui/transition-tree.tcl
#
# spar::ui::TransitionTree — owns the transition ttk::treeview.
#
# Encapsulates the tree widget, the row_id → contact_name map, the
# stem → row_id map, and the Show-completed toggle. Subscribes to the
# CampaignModel's `reloading` event (clears the tree at the start of
# a refresh) and `transition-loaded` events (fills incrementally as
# the loader coroutine produces tids).
#
# DispatchController (Commit 5) consults this class via get_tree_widget,
# get_row_names, get_slug_to_row, and update_row. _resolve_target
# consults DispatchController's is_dispatching via a back-reference
# wired post-construction by set_dispatch — we can't take it at
# construction time because DispatchController needs this tree too.
#
# Events fired:
#   selection-changed {stem}
#       emitted on tree-select when a single leaf row is highlighted.
#       Inspector will subscribe in #66.
#   double-clicked {stem}
#       emitted on Double-1 against a leaf row. Inspector will
#       subscribe in #66.
#   dispatch-target-changed {parent nchild label verb}
#       emitted whenever the selection changes in a way that affects
#       the Dispatch button's state/label. DispatchController subscribes
#       in its constructor to drive the Play button.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::TransitionTree {
    variable Campaign Tree RowNames SlugToRow ShowCompleted
    variable Dispatch NextTransitionIdx
    variable Subs

    constructor {campaign parent_frame} {
        set Campaign           $campaign
        set RowNames           [dict create]
        set SlugToRow          [dict create]
        set ShowCompleted      1
        set Dispatch           ""
        set NextTransitionIdx  0
        set Subs               [dict create]

        # Toolbar with Show-completed checkbox.
        ttk::frame ${parent_frame}.toolbar
        pack ${parent_frame}.toolbar -fill x -padx 4 -pady {4 0}

        # The checkbutton -variable needs a fully-qualified namespace var,
        # not an instance variable. Use [my varname ShowCompleted] so the
        # checkbox toggles the instance variable directly.
        ttk::checkbutton ${parent_frame}.toolbar.showcomplete -text "Show completed" \
            -variable [my varname ShowCompleted]
        pack ${parent_frame}.toolbar.showcomplete -side left

        # Tree + scrollbar.
        ttk::frame ${parent_frame}.treeframe
        pack ${parent_frame}.treeframe -fill both -expand 1 -padx 4 -pady 2

        set Tree ${parent_frame}.treeframe.tree
        set vsb  ${parent_frame}.treeframe.vsb

        ttk::treeview $Tree \
            -columns {stem org segment state reason} \
            -displaycolumns {org segment state reason} \
            -show {tree headings} -selectmode extended
        ttk::scrollbar $vsb -orient vertical -command [list $Tree yview]
        $Tree configure -yscrollcommand [list $vsb set]

        pack $vsb -side right -fill y
        pack $Tree -fill both -expand 1

        $Tree heading #0      -text "Transition / Contact"
        $Tree heading org     -text "Organisation"
        $Tree heading segment -text "Segment"
        $Tree heading state   -text "State"
        $Tree heading reason  -text "Pending Reason"

        $Tree column #0      -width 250 -minwidth 150
        $Tree column org     -width 200 -minwidth 100
        $Tree column segment -width 150 -minwidth 80
        $Tree column state   -width 70  -minwidth 50
        $Tree column reason  -width 300 -minwidth 100

        $Tree tag configure done      -foreground #999999
        $Tree tag configure pending   -foreground #cc6600
        $Tree tag configure in_cohort -background #e8f0fa

        bind $Tree <<TreeviewSelect>> [list [self] on_select]
        bind $Tree <Double-1>         [list [self] on_double_click]

        # Subscribe to reloading — refresh has reset the model; clear
        # the tree so transition-loaded events refill it cleanly.
        $Campaign subscribe reloading [list [self] on_reloading]

        # Subscribe to transition-loaded — loader coroutine fires this
        # once per tid so the tree fills in steps.
        $Campaign subscribe transition-loaded [list [self] on_transition_loaded]
    }

    # set_dispatch — called after DispatchController is constructed to
    # close the circular wire. Needed because _resolve_target must
    # consult the controller's is_dispatching flag, and the controller
    # itself needs this tree at construction time.
    method set_dispatch {dispatch} { set Dispatch $dispatch }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method get_tree_widget  {} { return $Tree }
    method get_row_names    {} { return $RowNames }
    method get_slug_to_row  {} { return $SlugToRow }
    method get_show_completed {} { return $ShowCompleted }

    # ─── Public entry points ──────────────────────────────────────────────

    # populate — rebuild the treeview from the Campaign's current
    # transitions. Resets RowNames / SlugToRow / NextTransitionIdx.
    # Used by the initial empty render in spar-ui.tcl and by
    # on_reloading (where Transitions is empty, so the call effectively
    # clears). The loader coroutine fills the tree incrementally via
    # on_transition_loaded.
    method populate {} {
        set transitions [$Campaign get_transitions]

        foreach item [$Tree children {}] {
            $Tree delete $item
        }
        set RowNames          [dict create]
        set SlugToRow         [dict create]
        set NextTransitionIdx 0

        # Transitions list is built in ui_transition_tids order, so the
        # i-th tentry corresponds to the i-th tid in that list.
        set tids [spar::ui_transition_tids]
        set i 0
        foreach tentry $transitions {
            lassign $tentry tlabel tcount ttasks
            my _insert_transition [lindex $tids $i] $tlabel $ttasks
            incr i
        }
    }

    # _insert_transition — append one transition branch (parent + child
    # rows) to the tree. Shared by populate and on_transition_loaded;
    # parent_id is derived from NextTransitionIdx so async-appended ids
    # match the `t$idx` shape the dispatch path's auto_dispatch expects.
    method _insert_transition {tid tlabel ttasks} {
        set parent_id "t$NextTransitionIdx"
        set tcount [llength $ttasks]
        $Tree insert {} end -id $parent_id -text "$tid: $tlabel ($tcount)" -open false

        foreach task $ttasks {
            lassign $task tname tstem torg tseg tstate treason
            set tags {}
            if {$tstate eq "done"} {
                set tags {done}
            } elseif {$tstate eq "pending"} {
                set tags {pending}
            }
            set row_id [$Tree insert $parent_id end -text "  $tname" \
                -values [list $tstem $torg $tseg $tstate $treason] -tags $tags]
            dict set RowNames $row_id $tname
            if {$tstem ne ""} {
                dict set SlugToRow $tstem $row_id
            }
        }

        incr NextTransitionIdx
    }

    # rebuild — alias for populate.
    method rebuild {} { my populate }

    # update_row — called from ui_on_progress (and, in Commit 5, from
    # DispatchController) to rewrite one cohort row's state/reason
    # columns. For Commit 4 the caller still passes a pre-rendered
    # state_text/reason_text pair (because the cohort render logic lives
    # in render_row in spar-ui.tcl). Commit 5 may choose to move the
    # state-to-glyph translation here.
    method update_row {stem state_text reason_text} {
        if {![dict exists $SlugToRow $stem]} return
        set row_id [dict get $SlugToRow $stem]
        if {![$Tree exists $row_id]} return
        $Tree set $row_id state  $state_text
        $Tree set $row_id reason $reason_text
    }

    # get_selected_stem — returns the stem of the single selected leaf
    # row, or empty string if the selection is not a single leaf.
    method get_selected_stem {} {
        set sel [$Tree selection]
        if {[llength $sel] != 1} { return "" }
        set item [lindex $sel 0]
        if {[$Tree parent $item] eq ""} { return "" }
        return [$Tree set $item stem]
    }

    # ─── Event handlers ───────────────────────────────────────────────────

    # on_select — bound to <<TreeviewSelect>>. Fires `selection-changed`
    # (for Inspector) and `dispatch-target-changed` (for the dispatch
    # button). The target tuple is resolved by _resolve_target.
    method on_select {} {
        set stem [my get_selected_stem]
        my _fire selection-changed $stem

        lassign [my _resolve_target] parent nchild label verb
        my _fire dispatch-target-changed $parent $nchild $label $verb
    }

    # on_double_click — fires `double-clicked` with the selected stem.
    # Inspector subscribes in #66.
    method on_double_click {} {
        set stem [my get_selected_stem]
        if {$stem ne ""} {
            my _fire double-clicked $stem
        }
    }

    # on_reloading — CampaignModel reset its state at the start of a
    # refresh. populate against the now-empty Transitions clears the
    # tree; transition-loaded events will refill it.
    method on_reloading {} {
        my populate
    }

    # on_transition_loaded — CampaignModel fired `transition-loaded` for
    # one tid during the async pass. Append its branch in place. tid
    # arrives in the payload for debugging; the visual position comes
    # from NextTransitionIdx, which is in lockstep with tid order.
    method on_transition_loaded {tid tlabel ttasks} {
        my _insert_transition $tid $tlabel $ttasks
    }

    # ─── Internal helpers ─────────────────────────────────────────────────

    # _resolve_target — inspect the current selection and compute the
    # {parent nchild label verb} quadruple the dispatch button needs.
    # Returns {"" 0 "" ""} when the selection is not dispatchable (mixed
    # parents, empty transition, or dispatching in progress).
    method _resolve_target {} {
        if {$Dispatch ne "" && [$Dispatch is_dispatching]} {
            return [list "" 0 "" ""]
        }
        set sel [$Tree selection]
        set parents {}
        set children {}
        foreach item $sel {
            set p [$Tree parent $item]
            if {$p eq ""} {
                lappend parents $item
            } else {
                lappend parents $p
                lappend children $item
            }
        }
        set parents [lsort -unique $parents]

        # Mixed parents, or nothing selected ⇒ not dispatchable.
        if {[llength $parents] != 1} {
            return [list "" 0 "" ""]
        }
        set parent [lindex $parents 0]

        # Empty transition (no children at all) ⇒ nothing to dispatch.
        if {[$Tree children $parent] eq ""} {
            return [list "" 0 "" ""]
        }

        set label [$Tree item $parent -text]
        regsub {\s*\(\d+\)\s*$} $label "" label

        set nchild [llength $children]

        # When children are selected and the runner supports re-author
        # (currently T1/T3 — profile runners), passing stems bypasses the
        # "profile exists" skip. Reflect that in the verb so the user
        # sees the action before firing.
        set verb "Dispatch"
        if {$nchild > 0} {
            set tnum [string range $parent 1 end]
            set tids [spar::ui_transition_tids]
            set tid [lindex $tids $tnum]
            if {[spar::transition_supports_reauthor $tid]} {
                foreach c $children {
                    if {[$Tree set $c state] eq "done"} {
                        set verb "Re-author"
                        break
                    }
                }
            }
        }

        return [list $parent $nchild $label $verb]
    }
}

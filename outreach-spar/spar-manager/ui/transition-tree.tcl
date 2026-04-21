# spar-manager/ui/transition-tree.tcl
#
# spar::ui::TransitionTree — owns the transition ttk::treeview.
#
# Encapsulates the tree widget, the row_id → contact_name map, the
# stem → row_id map, and the Show-completed toggle. Subscribes to the
# CampaignModel's `refreshed` event so the tree rebuilds after each
# refresh without extra wiring here.
#
# The current dispatch code (clear_cohort, reapply_cohort_after_refresh,
# ui_on_progress, do_dispatch, ui_on_complete, auto_dispatch) still
# reads `$tree` and `slug_to_row` directly — those procs move into
# DispatchController in Commit 5. To keep Commit 4 minimal, the class
# mirrors its Tree widget path into the top-level `tree` global and its
# SlugToRow dict into the top-level `slug_to_row` global (same shim
# pattern Commit 1 used for `segments`/`all_contacts`). Commit 5
# replaces every shim read with a method call and drops both globals.
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
#       the Dispatch button's state/label. DispatchController (or, for
#       Commit 4, the inline wiring that owns the $play button)
#       subscribes to drive $play configure.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::TransitionTree {
    variable Campaign Tree RowNames SlugToRow ShowCompleted
    variable Subs

    constructor {campaign parent_frame} {
        set Campaign      $campaign
        set RowNames      [dict create]
        set SlugToRow     [dict create]
        set ShowCompleted 1
        set Subs          [dict create]

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

        # Subscribe to refreshed — refreshed rebuilds the tree in place.
        $Campaign subscribe refreshed [list [self] on_refreshed]

        # Commit-5 cleanup target: shim global mirrors. Still read by
        # clear_cohort / reapply_cohort_after_refresh / ui_on_progress /
        # do_dispatch / auto_dispatch / ui_on_complete in spar-ui.tcl.
        set ::tree        $Tree
        set ::slug_to_row $SlugToRow
    }

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
    # transitions. Resets RowNames / SlugToRow and mirrors both to the
    # Commit-5 shim globals. Public because auto_dispatch and the
    # CampaignModel `fully-loaded` / `refreshed` wiring in spar-ui.tcl
    # call it directly via [$tree_obj populate].
    method populate {} {
        set transitions [$Campaign get_transitions]

        foreach item [$Tree children {}] {
            $Tree delete $item
        }
        set RowNames  [dict create]
        set SlugToRow [dict create]

        set ti 0
        foreach tentry $transitions {
            lassign $tentry tlabel tcount ttasks

            set parent_id "t$ti"
            $Tree insert {} end -id $parent_id -text "$tlabel ($tcount)" -open false

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

            incr ti
        }

        # Commit-5 cleanup target: keep shim globals in sync so the
        # still-procedural dispatch code sees fresh row ids.
        set ::row_names   $RowNames
        set ::slug_to_row $SlugToRow
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

    # on_refreshed — CampaignModel fired `refreshed`. Rebuild the tree.
    method on_refreshed {} {
        my populate
    }

    # ─── Internal helpers ─────────────────────────────────────────────────

    # _resolve_target — inspect the current selection and compute the
    # {parent nchild label verb} quadruple the dispatch button needs.
    # Returns {"" 0 "" ""} when the selection is not dispatchable (mixed
    # parents, empty transition, or dispatching in progress).
    #
    # The ::dispatching global read is a Commit-5 target: once
    # DispatchController exists, the subscriber will query
    # `[$dispatch is_dispatching]`. For Commit 4 it still lives here.
    method _resolve_target {} {
        if {[info exists ::dispatching] && $::dispatching == 1} {
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

        # When children are selected and the runner is ::spar::p::run
        # (T1/T6), passing stems bypasses the "profile exists" skip —
        # i.e. re-authors. Reflect that in the verb so the user sees the
        # action before firing.
        set verb "Dispatch"
        if {$nchild > 0} {
            set tnum [string range $parent 1 end]
            set tids {T1 T2 T3 T4 T6 T7 T8}
            set tid [lindex $tids $tnum]
            if {[spar::has_transition_runner $tid]} {
                set runner [spar::transition_runner $tid]
                if {$runner eq "::spar::p::run"} {
                    foreach c $children {
                        if {[$Tree set $c state] eq "done"} {
                            set verb "Re-author"
                            break
                        }
                    }
                }
            }
        }

        return [list $parent $nchild $label $verb]
    }
}

# spar-manager/transitions/base.tcl
#
# spar::transitions::Transition — abstract base class for SPAR state
# transitions. Each T-id in state-machine.md is represented by exactly
# one Transition subclass instance held in ::spar::transitions::registry.
#
# Subclass contract:
#   run          execute the transition; must call on_complete exactly once
#   build_opts   adapt (ready_tasks, filter_segments, filter_stems) to the
#                per-runner opts dict merged onto {campaign_file, dry_run, jobs}
#
# The remaining methods (tid, label, auto_safe, dispatch_status,
# supports_reauthor, ui_tree_row) read from params set at construction.
#
# Registrations live at the bottom of each subclass file so that sourcing
# the file is the single act that makes a T-id visible to the rest of the
# system — no parallel list is maintained.

package require TclOO

namespace eval ::spar::transitions {
    variable registry [dict create]
}

oo::class create ::spar::transitions::Transition {
    variable Tid Params

    constructor {tid params} {
        set Tid $tid
        set Params $params
    }

    method tid {} { return $Tid }

    method param {key {default ""}} {
        if {[dict exists $Params $key]} {
            return [dict get $Params $key]
        }
        return $default
    }

    method label                      {} { my param -label "" }
    method auto_safe                  {} { my param -auto-safe 0 }
    method dispatch_status            {} { my param -dispatch-status available }
    method supports_reauthor          {} { my param -supports-reauthor 0 }
    method ui_tree_row                {} { my param -ui-tree-row 1 }
    method requires_send_confirmation {} { my param -requires-send-confirmation 0 }

    # Default build_opts — no extra opts. Subclasses that need per-runner
    # setup override.
    method build_opts {tasks filter_segments filter_stems} {
        return [dict create]
    }

    # run must be overridden by subclasses that declare dispatch_status
    # `available`. Manual / not-implemented transitions inherit this stub.
    method run {opts on_progress on_complete} {
        {*}$on_complete 0 0 [dict create \
            message "[my tid] ([my label]): dispatch_status=[my dispatch_status]"]
    }

    # Default eligible — zero tasks. Subclasses that have eligibility
    # criteria (T1, T2, T3, T4, T6, T8, T9, T10) override. Method name has
    # no leading underscore: TclOO would unexport it and the dispatcher in
    # spar::transition_eligible reaches it via the registered object
    # command, which is an external call.
    method eligible {contact primary_channel cdata today_iso} {
        return {}
    }
}

# register — construct a subclass instance and record it under its T-id.
# -class and -tid are required; all other params flow through to Params
# so subclasses can read them via `my param`.
proc ::spar::transitions::register {args} {
    variable registry
    if {![dict exists $args -class]} { error "register: missing -class" }
    if {![dict exists $args -tid]}   { error "register: missing -tid" }
    set klass [dict get $args -class]
    set tid   [dict get $args -tid]
    if {[dict exists $registry $tid]} {
        error "register: $tid already registered"
    }
    set obj [$klass new $tid $args]
    dict set registry $tid $obj
}

proc ::spar::transitions::get {tid} {
    variable registry
    if {![dict exists $registry $tid]} {
        error "no transition registered for $tid"
    }
    return [dict get $registry $tid]
}

proc ::spar::transitions::all {} {
    variable registry
    # Sorted by T-id numeric part so row positions stay T1..T10 regardless
    # of class-file load order (profile.tcl registers T1 and T6 together).
    return [lsort -command ::spar::transitions::_tid_cmp [dict keys $registry]]
}

proc ::spar::transitions::_tid_cmp {a b} {
    set an [string range $a 1 end]
    set bn [string range $b 1 end]
    return [expr {$an - $bn}]
}

# assert_matches_doc — compare registered T-ids against state-machine.md.
# Errors on asymmetric difference so a drifting registry or a documented-
# but-unimplemented transition is caught at load time. The doc lives one
# directory up from spar-manager/; pass the explicit path if that layout
# changes.
proc ::spar::transitions::assert_matches_doc {doc_path} {
    if {![file exists $doc_path]} {
        # Silent no-op: doc may not exist in some test or CLI-only contexts.
        return
    }
    set fd [open $doc_path r]
    set text [read $fd]
    close $fd
    set doc_tids [dict create]
    foreach line [split $text \n] {
        if {[regexp {^\|\s*(T[0-9]+)\s*\|} $line -> m]} {
            dict set doc_tids $m 1
        }
    }
    set reg_tids [dict create]
    foreach t [::spar::transitions::all] { dict set reg_tids $t 1 }
    set missing_in_reg {}
    set missing_in_doc {}
    foreach t [dict keys $doc_tids] {
        if {![dict exists $reg_tids $t]} { lappend missing_in_reg $t }
    }
    foreach t [dict keys $reg_tids] {
        if {![dict exists $doc_tids $t]} { lappend missing_in_doc $t }
    }
    if {[llength $missing_in_reg] > 0 || [llength $missing_in_doc] > 0} {
        error "transition registry drift: missing_in_registry=[lsort $missing_in_reg] missing_in_doc=[lsort $missing_in_doc]"
    }
}

# ── spar::* accessors ─────────────────────────────────────────────────
# Thin delegators around the registry. Live here, alongside the registry
# itself, rather than in spar-state.tcl — every consumer that wants the
# accessors already sources transitions/base.tcl (transitively, via
# spar-state.tcl), and keeping them next to the registry makes the
# dependency obvious.

# has_transition_runner -- 1 if the T-id's class has dispatch_status
# "available" (i.e. the Dispatch button should fire a runner). Manual
# and not-implemented transitions return 0 here so callers gate cleanly.
proc spar::has_transition_runner {tid} {
    if {$tid ni [::spar::transitions::all]} { return 0 }
    return [expr {[[::spar::transitions::get $tid] dispatch_status] eq "available"}]
}

# transition_runner -- command prefix that invokes the T-id's run method.
# Callers expand with {*}$runner $opts $on_progress $on_complete. Errors
# if the T-id is unregistered or non-dispatchable — gate via
# has_transition_runner.
proc spar::transition_runner {tid} {
    if {$tid ni [::spar::transitions::all]} {
        error "unknown transition: $tid"
    }
    if {![spar::has_transition_runner $tid]} {
        error "no runner for $tid"
    }
    return [list [::spar::transitions::get $tid] run]
}

# transition_label -- human-readable edge name.
proc spar::transition_label {tid} {
    return [[::spar::transitions::get $tid] label]
}

# transition_auto_safe -- 1 if --auto may drive this transition.
proc spar::transition_auto_safe {tid} {
    if {$tid ni [::spar::transitions::all]} { return 0 }
    return [[::spar::transitions::get $tid] auto_safe]
}

# transition_dispatch_status -- "available", "manual", "not-implemented",
# or "unknown" for an unregistered T-id.
proc spar::transition_dispatch_status {tid} {
    if {$tid ni [::spar::transitions::all]} { return "unknown" }
    return [[::spar::transitions::get $tid] dispatch_status]
}

# transition_supports_reauthor -- 1 if passing stems to the runner
# re-authors existing artefacts (profile runners bypass the "profile
# exists" skip).
proc spar::transition_supports_reauthor {tid} {
    if {$tid ni [::spar::transitions::all]} { return 0 }
    return [[::spar::transitions::get $tid] supports_reauthor]
}

# transition_tids -- all registered T-ids in registration order.
proc spar::transition_tids {} {
    return [::spar::transitions::all]
}

# ui_transition_tids -- T-ids shown as rows in the transition tree.
# Excludes manual transitions (T9/T10) whose UI presence is the per-
# contact inspector, not the tree. Used by dispatch-controller,
# transition-tree, and campaign-model so all three agree on ordering.
proc spar::ui_transition_tids {} {
    set out {}
    foreach t [::spar::transitions::all] {
        if {[[::spar::transitions::get $t] ui_tree_row]} { lappend out $t }
    }
    return $out
}

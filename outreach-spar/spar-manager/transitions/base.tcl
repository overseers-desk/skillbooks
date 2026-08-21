# spar-manager/transitions/base.tcl
#
# spar::transitions::Transition — abstract base class for SPAR state
# transitions. Each T-id in state-machine.md is represented by exactly
# one Transition subclass instance held in ::spar::transitions::registry.
#
# Subclass contract:
#   prepare_for_pool  build the per-row Pool batch; return
#                     {worker_proc <name> rows {{stem opts} ...}}
#   build_opts        adapt (ready_tasks, filter_segments, filter_stems) to
#                     the per-runner opts dict merged onto
#                     {campaign_file, dry_run, jobs}
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
    # outgoing=1 marks transitions whose dispatch contacts the outside
    # world (T6/T8/T9/T10). transition_eligible holds their dispatchable
    # tasks back until the campaign's start_date says it has launched.
    method outgoing                   {} { my param -outgoing 0 }
    # tier names which of the methodology's record tiers the transition
    # works on (spar-methodology.md, "Campaigns and segments"): population
    # transitions (the T0 sweep, T1/T3 profiling) read nothing campaign-
    # bound and run from a segment alone; campaign is the default for the
    # rest.
    method tier                       {} { my param -tier campaign }

    # Default build_opts — no extra opts. Subclasses that need per-runner
    # setup override.
    method build_opts {tasks filter_segments filter_stems} {
        return [dict create]
    }

    # prepare_for_pool — return {worker_proc <name> rows {{stem opts} ...}}
    # for the unified dispatch_ready in spar-transition.tcl. Each row's
    # `opts` is the per-row dict the worker_proc consumes (e.g.
    # {prompt_dir log_dir harness_class} for harness_run).
    #
    # Subclasses with dispatch_status=available override. The base
    # default errors so a missing override is loud.
    #
    # opts has the same shape as run's opts. on_progress is invoked
    # synchronously during prep for skipped/failed setup events; row-
    # level progress is delivered by the Pool's row events once the
    # worker runs.
    method prepare_for_pool {opts on_progress} {
        error "[my tid]: prepare_for_pool not implemented"
    }

    # Default eligible — zero tasks. Subclasses that have eligibility
    # criteria (T1, T2, T3, T4, T6, T7, T8, T9, T10) override. Method name has
    # no leading underscore: TclOO would unexport it and the dispatcher in
    # spar::State's transition_eligible reaches it via the registered object
    # command, which is an external call.
    #
    # state — the spar::State driving this pass. Phase A threads it through;
    # Phase B uses it to pull cached approach summaries instead of re-parsing
    # the YAML at each gate.
    method eligible {state contact primary_channel cdata today_iso} {
        return {}
    }

    # campaign_tasks — ready tasks a transition derives from the campaign
    # itself rather than from a contact. `eligible` walks classified
    # contacts, and T0's work is not among them: its tasks are the census
    # sources in each segment's sweep.yaml, and a segment being swept for
    # the first time has no roster, so it contributes no contacts at all.
    # Every ready-task assembly (both front ends, report and dispatch)
    # folds this in beside the eligible walk, so a campaign-level
    # transition needs no special case in either dispatch path.
    #
    # Returns task dicts of the same shape spar::_task builds. Default
    # empty, so every contact-driven T-id inherits it unchanged.
    # segment_paths is the resolved {label seg_dir} list the caller
    # already walked (resolve_campaign or resolve_segment); a segment-
    # mode caller has no campaign, so tasks derive from that list, not
    # from cdata.
    method campaign_tasks {cdata campaign_file segment_paths} {
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
    # of class-file load order (profile.tcl registers T1 and T3 together).
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
# itself, rather than in spar::state — every consumer that wants the
# accessors already sources transitions/base.tcl (transitively, via
# spar::state), and keeping them next to the registry makes the
# dependency obvious.

# has_transition_runner -- 1 if the T-id's class has dispatch_status
# "available" (i.e. the Dispatch button should fire a runner). Manual
# and not-implemented transitions return 0 here so callers gate cleanly.
proc spar::has_transition_runner {tid} {
    if {$tid ni [::spar::transitions::all]} { return 0 }
    return [expr {[[::spar::transitions::get $tid] dispatch_status] eq "available"}]
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

# transition_campaign_tasks -- the T-id's campaign-level ready tasks (see
# the class method). Empty for an unregistered T-id and for a caller with
# no campaign file in hand, so a consumer folds the call in unconditionally.
proc spar::transition_campaign_tasks {tid cdata campaign_file segment_paths} {
    if {$tid ni [::spar::transitions::all]} { return {} }
    return [[::spar::transitions::get $tid] campaign_tasks $cdata $campaign_file $segment_paths]
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

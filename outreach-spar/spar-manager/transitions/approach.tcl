# spar-manager/transitions/approach.tcl
#
# ApproachTransition — T2 (Profile → Approach) and T7 (Re-profile →
# Re-approach). Both dispatch through ::spar::a::run in a campaign-wide
# pass; filters are propagated as opts to the runner.

oo::class create ::spar::transitions::ApproachTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set result [dict create \
            log_message "[my tid]: [llength $tasks] task(s) ready (campaign-wide pass)"]
        if {[llength $filter_segments] > 0} {
            dict set result segments $filter_segments
        }
        if {[llength $filter_stems] > 0} {
            dict set result stems $filter_stems
        }
        return $result
    }

    method run {opts on_progress on_complete} {
        ::spar::a::run $opts $on_progress $on_complete
    }

    # T2: PROFILED contacts that pass the campaign-wide approach-dispatch
    # gate (min_star, in_scope_channel, skip_excluded — SSOT with
    # spar::a::run per #56).  T7 is deferred (zero tasks) until
    # PROFILE_STALE re-profiling detection lands.
    method eligible {contact primary_channel cdata today_iso} {
        if {[my tid] ne "T2"} { return {} }
        set state [dict get $contact state]
        if {$state ne "PROFILED"} { return {} }
        if {[spar::_approach_dispatch_gate $contact $cdata] ne ""} { return {} }
        return [list [spar::_task $contact ready ""]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::ApproachTransition \
    -tid T2 \
    -label "Profile → Approach" \
    -auto-safe 1 \
    -dispatch-status available \
    -ui-tree-row 1

::spar::transitions::register \
    -class ::spar::transitions::ApproachTransition \
    -tid T7 \
    -label "Re-profile → Re-approach" \
    -auto-safe 1 \
    -dispatch-status available \
    -ui-tree-row 1

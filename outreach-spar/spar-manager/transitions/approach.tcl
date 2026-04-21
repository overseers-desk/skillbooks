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

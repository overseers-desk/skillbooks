# spar-manager/transitions/profile.tcl
#
# ProfileTransition — T1 (Sweep → Profile) and T6 (Stale → Re-profile).
# Both dispatch through ::spar::p::run; the only difference is entry state
# (DISCOVERED for T1, PROFILE_STALE for T6), which is handled by
# spar::transition_eligible.

oo::class create ::spar::transitions::ProfileTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set stems {}
        foreach c $tasks { lappend stems [dict get $c stem] }
        if {[llength $filter_stems] > 0} { set stems $filter_stems }
        set segs [dict create]
        foreach c $tasks {
            dict set segs [file tail [dict get $c _segment_dir]] 1
        }
        set segments_list [dict keys $segs]
        return [dict create \
            stems $stems \
            segments $segments_list \
            log_message "[my tid]: [llength $tasks] task(s) across [llength $segments_list] segment(s)"]
    }

    method run {opts on_progress on_complete} {
        ::spar::p::run $opts $on_progress $on_complete
    }
}

::spar::transitions::register \
    -class ::spar::transitions::ProfileTransition \
    -tid T1 \
    -label "Sweep → Profile" \
    -auto-safe 1 \
    -dispatch-status available \
    -supports-reauthor 1 \
    -ui-tree-row 1

::spar::transitions::register \
    -class ::spar::transitions::ProfileTransition \
    -tid T6 \
    -label "Stale → Re-profile" \
    -auto-safe 1 \
    -dispatch-status available \
    -supports-reauthor 1 \
    -ui-tree-row 1

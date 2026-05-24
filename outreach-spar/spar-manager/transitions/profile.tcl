# spar-manager/transitions/profile.tcl
#
# ProfileTransition — T1 (Sweep → Profile) and T3 (Stale → Re-profile).
# Both dispatch through ::spar::p::prepare_for_pool; the only difference
# is entry state (DISCOVERED for T1, PROFILE_STALE for T3), which is
# handled by spar::State's transition_eligible.

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

    # prepare_for_pool — pool-shape entry. Wraps spar::p::prepare_for_pool
    # (which returns {logs_dir <abs path> rows {{stem pdir} ...}}) and
    # repackages each {stem pdir} pair into the per-row opts dict the
    # harness_run worker consumes.
    method prepare_for_pool {opts on_progress} {
        set prep [::spar::p::prepare_for_pool $opts $on_progress]
        set logs_dir [dict get $prep logs_dir]
        set rows {}
        foreach pair [dict get $prep rows] {
            lassign $pair stem pdir
            lappend rows [list $stem [dict create \
                prompt_dir    $pdir \
                log_dir       $logs_dir \
                harness_class spar::ProfileHarness]]
        }
        return [dict create worker_proc harness_run rows $rows]
    }

    # T1 fires from DISCOVERED, T3 fires from PROFILE_STALE — same class,
    # entry state distinguished via [my tid].
    method eligible {state contact primary_channel cdata today_iso} {
        set state [dict get $contact state]
        set tid [my tid]
        if {$tid eq "T1" && $state eq "DISCOVERED"} {
            return [list [spar::_task $contact ready ""]]
        }
        if {$tid eq "T3" && $state eq "PROFILE_STALE"} {
            return [list [spar::_task $contact ready ""]]
        }
        return {}
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
    -tid T3 \
    -label "Stale → Re-profile" \
    -auto-safe 1 \
    -dispatch-status available \
    -supports-reauthor 1 \
    -ui-tree-row 1

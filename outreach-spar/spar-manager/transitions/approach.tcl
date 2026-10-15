# spar-manager/transitions/approach.tcl
#
# ApproachTransition — T2 (Profile → Approach) and T4 (Re-profile →
# Re-approach). Both dispatch through ::spar::a::prepare_for_pool in a
# campaign-wide pass, restricted to the ready tasks' stems.

oo::class create ::spar::transitions::ApproachTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set result [dict create \
            log_message "[my tid]: [llength $tasks] task(s) dispatchable (campaign-wide pass)"]
        if {[llength $filter_segments] > 0} {
            dict set result segments $filter_segments
        }
        set stems {}
        foreach c $tasks { lappend stems [dict get $c stem] }
        dict set result stems $stems
        return $result
    }

    # prepare_for_pool — pool-shape entry. Wraps spar::a::prepare_for_pool
    # (which returns {logs_dir <abs path> rows {{stem pdir} ...} result <r>})
    # and repackages each pair into the per-row opts dict the harness_run
    # worker consumes. dry_run is threaded into each row so the worker can
    # skip the claude exec under --dry-run (the prompt dir is still
    # assembled, mirroring the send path's dry-run behaviour).
    method prepare_for_pool {opts on_progress} {
        set prep [::spar::a::prepare_for_pool $opts $on_progress]
        set logs_dir [dict get $prep logs_dir]
        set dry_run [dict getdef $opts dry_run 0]
        set rows {}
        foreach pair [dict get $prep rows] {
            lassign $pair stem pdir
            lappend rows [list $stem [dict create \
                prompt_dir    $pdir \
                log_dir       $logs_dir \
                dry_run       $dry_run \
                harness_class spar::ApproachHarness]]
        }
        return [dict create worker_proc harness_run rows $rows]
    }

    # T2: PROFILED contacts that pass the campaign-wide approach-dispatch
    # gate (min_star, in_scope_channel, skip_excluded — SSOT with
    # spar::a::_build_prompts per #56); a passing contact whose profile
    # fails validation is blocked with reason "invalid_profile: …".
    # T4: APPROACH_STALE contacts. classify_contact assigns this state when
    # the approach's profile_hash diverges from the current profile bytes
    # (#63); T4 re-runs A on those, dispatching through the same gate so
    # filter rules stay symmetric with T2.
    method eligible {state contact primary_channel cdata today_iso} {
        set tid [my tid]
        set cstate [dict get $contact state]
        if {$tid eq "T2"} {
            if {$cstate ne "PROFILED"} { return {} }
        } elseif {$tid eq "T4"} {
            if {$cstate ne "APPROACH_STALE"} { return {} }
        } else {
            return {}
        }
        if {[spar::_approach_dispatch_gate $contact $cdata] ne ""} { return {} }
        # A drafts from the profile, so one that fails validate_profile is
        # a defect to surface, not a row to dispatch.
        set perr [$state profile_validation_error $contact]
        if {$perr ne ""} {
            return [list [spar::_task $contact blocked "invalid_profile: $perr"]]
        }
        return [list [spar::_task $contact dispatchable ""]]
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
    -tid T4 \
    -label "Re-profile → Re-approach" \
    -auto-safe 1 \
    -dispatch-status available \
    -ui-tree-row 1

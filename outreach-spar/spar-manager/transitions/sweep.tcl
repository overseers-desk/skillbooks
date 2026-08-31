# spar-manager/transitions/sweep.tcl
#
# SweepTransition — T0 (Seed → Sweep). The entry into DISCOVERED: it
# turns a seeded segment (segments/<seg>.yaml plus <seg>.sweep.yaml) into
# roster rows, one discovery worker per unexhausted census source.
#
# T0 is the one transition whose tasks are not contacts. A segment swept
# for the first time has no roster, so the per-contact classifier has
# nothing to classify; the work is the source census in the sweep file.
# That is what the base class's campaign_tasks exists for (see
# transitions/base.tcl).

oo::class create ::spar::transitions::SweepTransition {
    superclass ::spar::transitions::Transition

    # One task per source whose status base token is neither exhausted
    # nor unreachable (spar::sweep_source_open). Unreachable closes a
    # source for the round that probed it, not forever: with no probe
    # record it dispatches for the probe (nothing distinguishes a closed
    # gate from a wrong query until one is recorded), and with a probe
    # from an earlier round it dispatches for a varied re-probe. The
    # harness stamps the probe with its round; the stamp is what decides.
    # A segment with no sweep file is not seeded yet and contributes
    # nothing; a sweep file that does not parse contributes one blocked
    # row naming the defect, rather than vanishing. Both front ends drop
    # blocked rows from dispatch and show them to the operator.
    method campaign_tasks {cdata campaign_file segment_paths} {
        set out {}
        foreach item $segment_paths {
            lassign $item seg seg_dir
            set sweep_path [spar::sweep_yaml_for_segment $seg_dir]
            if {![file exists $sweep_path]} continue
            if {[catch {spar::read_sweep_yaml $sweep_path} data]} {
                lappend out [my _task $seg $seg_dir "sweep.yaml" "" \
                    blocked "sweep.yaml does not parse: $data"]
                continue
            }
            set latest_n 0
            foreach r [dict getdef $data rounds {}] {
                if {![catch {dict size $r}]} {
                    set n [string trim [dict getdef $r n 0]]
                    if {[string is integer -strict $n] && $n > $latest_n} {
                        set latest_n $n
                    }
                }
            }
            foreach src [dict getdef $data sources {}] {
                set name [string trim [dict getdef $src name ""]]
                if {$name eq ""} continue
                set status [string trim [dict getdef $src status ""]]
                if {![spar::sweep_source_open $status]} {
                    if {[spar::sweep_status_token $status] ne "unreachable"} continue
                    set probe [string trim [dict getdef $src probe ""]]
                    if {$probe eq ""} {
                        set status "unreachable, no probe recorded: probe it (vary the parameters, record what was tried)"
                    } elseif {![regexp {\(round (\d+)\)} $probe -> pn] \
                              || $pn < $latest_n} {
                        set status "unreachable, probe predates round $latest_n: re-probe with varied parameters"
                    } else continue
                }
                lappend out [my _task $seg $seg_dir $name \
                    [dict getdef $src type ""] dispatchable $status]
            }
        }
        return $out
    }

    # The task dict both front ends consume, in spar::_task's shape: the
    # source stands where a contact would, so the report line, the GUI
    # tree row and the scope filters all read it without a special case.
    method _task {segment seg_dir source_name source_type task_state reason} {
        return [dict create \
            contact_name $source_name \
            organisation $source_type \
            segment      $segment \
            stem         [spar::sweep_task_stem $segment $source_name] \
            _segment_dir $seg_dir \
            task_state   $task_state \
            reason       $reason \
            channel      ""]
    }

    method build_opts {tasks filter_segments filter_stems} {
        set stems {}
        foreach t $tasks { lappend stems [dict get $t stem] }
        if {[llength $filter_stems] > 0} { set stems $filter_stems }
        set segs {}
        foreach t $tasks {
            set s [dict get $t segment]
            if {$s ni $segs} { lappend segs $s }
        }
        return [dict create \
            stems $stems \
            segments $segs \
            log_message "[my tid]: [llength $tasks] source(s) across [llength $segs] segment(s)"]
    }

    # prepare_for_pool — pool-shape entry, the same contract T1 returns:
    # {worker_proc harness_run rows {{stem opts}}}. ::spar::s::prepare_for_pool
    # builds one prompt dir per source; the harness applies what the
    # worker declares.
    method prepare_for_pool {opts on_progress} {
        set prep [::spar::s::prepare_for_pool $opts $on_progress]
        set logs_dir [dict get $prep logs_dir]
        set dry_run [dict getdef $opts dry_run 0]
        set rows {}
        foreach pair [dict get $prep rows] {
            lassign $pair stem pdir
            lappend rows [list $stem [dict create \
                prompt_dir    $pdir \
                log_dir       $logs_dir \
                dry_run       $dry_run \
                harness_class spar::SweepHarness]]
        }
        return [dict create worker_proc harness_run rows $rows]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::SweepTransition \
    -tid T0 \
    -tier population \
    -label "Seed → Sweep" \
    -auto-safe 0 \
    -dispatch-status available \
    -supports-reauthor 0 \
    -ui-tree-row 1

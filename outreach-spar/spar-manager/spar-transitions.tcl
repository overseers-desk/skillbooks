#!/usr/bin/env tclsh9.0
# spar-transitions.tcl — transition eligibility report and executor (CLI)
#
# Report mode (default):
#   tclsh9.0 spar-transitions.tcl [campaign_dir_or_yaml] [Tn[:seg[/stem]] ...]
#       [--pending|--ready] [-v|--verbose]
#
# Execute mode:
#   tclsh9.0 spar-transitions.tcl <campaign_dir_or_yaml> Tn[:seg[/stem]] ...
#       --execute [--jobs=N] [--delay=N] [--yes] [--dry-run]
#
# Positional Tn tokens after the campaign path name the transitions to
# act on:
#   Tn                   all rows of TID Tn, campaign-wide
#   Tn:<segment>         Tn restricted to one segment
#   Tn:<segment>/<stem>  Tn for one specific contact
# Tokens are repeatable and mixable across TIDs. The grammar is parsed
# in spar-transitions-cli.tcl (test/test-cli-parser.tcl drives it).
#
# --auto drives auto_safe=1 transitions as a state machine and refuses
# any positional Tn token. Transitions with external-action side-effects
# (e.g. SES send) declare auto_safe=0 and are filtered out.
#
# --jobs=0 activates stepping: worker parallelism drops to 1 and a
# stdin [y/N] gate fires before each item.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-dispatch.tcl]
source [file join $script_dir spar-email.tcl]
source [file join $script_dir spar-transitions-cli.tcl]

# print_help — usage text. The compact grammar block at the top is the
# operator-facing summary; the TRANSITIONS list is generated from the
# registry so adding a transition surfaces it here automatically.
proc print_help {} {
    puts {spar-transitions.tcl — report and execute SPAR state transitions.

USAGE
    tclsh9.0 spar-transitions.tcl [campaign_dir_or_yaml] [Tn[:seg[/stem]] ...] [options]

POSITIONAL TRANSITION TOKENS
    Tn                  all rows of TID Tn, campaign-wide
    Tn:<segment>        rows of Tn restricted to one segment
    Tn:<segment>/<stem> rows of Tn for one specific contact
    (repeatable; mixable across TIDs)

OPTIONS
    --pending         show/act on pending tasks only
    --ready           show/act on ready tasks only
    --execute         run the transition; default is report-only
    --auto            with --execute: drive the offline state machine
                      (all auto_safe=1 transitions) until convergence.
                      Refuses if any positional Tn token is supplied.
    --dry-run         run the transition with writes disabled (implies
                      execute-mode; pass alone, not with --execute).
    --jobs=N          parallel jobs for --execute (default 4); pass
                      --jobs=0 to step one item at a time with a
                      stdin [y/N] gate before each item.
    --delay=N         seconds between sends for send-type transitions
                      (default 2); ignored when --jobs=0.
    --yes             skip any up-front confirmation prompt
    -v, --verbose     in report mode, list each contact (default: counts only)
    -h, --help        show this help

TRANSITIONS}
    foreach tid [spar::transition_tids] {
        set t [::spar::transitions::get $tid]
        set status [$t dispatch_status]
        set mark $status
        switch -- $status {
            available       { set mark "execute: wired" }
            not-implemented { set mark "execute: not wired" }
            manual          { set mark "manual" }
            blocked         { set mark "blocked" }
            n/a             { set mark "n/a" }
        }
        puts [format "    %-3s %-28s (%s)" $tid [$t label] $mark]
    }
    puts {
COMMON WORKFLOWS
    # Report: what's ready across all transitions?
    tclsh9.0 spar-transitions.tcl path/to/campaign --ready

    # Execute one transition's ready work
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T1 --execute

    # Step through one transition's ready work, confirming each item
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T1 --execute --jobs=0

    # Dry-run first, then live
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T1 --dry-run
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T1 --execute

    # Limit to one segment or one contact
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T1:vic --execute
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml T6:vic/jane-doe --execute

    # Mix transitions and scopes in one shared pool
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml \
        T1 T2:vic T6:vic/jane-doe --execute --jobs=8

    # Drive the offline state machine (auto_safe transitions) until
    # convergence, re-classifying between iterations.
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --execute --auto}
}

# Parse argv. The parser returns {ok 0 error <msg>} on grammar errors;
# surface those as one-line stderr messages and exit 1. --help triggers
# print_help and exit 0.
set parse_result [spar::parse_cli $argv]
if {[dict get $parse_result ok] != 1} {
    puts stderr "Error: [dict get $parse_result error]"
    exit 1
}
set spec [dict get $parse_result spec]

if {[dict get $spec help]} { print_help; exit 0 }

set campaign_path [dict get $spec campaign_path]
set tid_scopes    [dict get $spec tid_scopes]
set filter_state  [dict get $spec filter_state]
set execute_mode  [dict get $spec execute_mode]
set auto_mode     [dict get $spec auto_mode]
set dry_run       [dict get $spec dry_run]
set jobs          [dict get $spec jobs]
set delay         [dict get $spec delay]
set assume_yes    [dict get $spec assume_yes]
set verbose       [dict get $spec verbose]
set stepping      0

# Normalise path → campaign_dir + (optional) campaign_file. A directory
# triggers the YAML auto-discover (campaign.yaml or campaign*.yaml);
# a *.yaml argument is taken as the YAML directly. Unspecified path
# defaults to ".".
set campaign_dir ""
set campaign_file ""
if {$campaign_path ne ""} {
    set norm [file normalize $campaign_path]
    if {[file isfile $norm] && [string match *.yaml $norm]} {
        set campaign_file $norm
        set campaign_dir [file dirname $norm]
    } else {
        set campaign_dir $campaign_path
    }
}
if {$campaign_dir eq ""} { set campaign_dir "." }
set campaign_dir [file normalize $campaign_dir]

# tid_scope_filter — return {segments stems} pair for one TID by
# unioning every scope that names this TID. An unscoped scope ({tid {}
# {}}) widens both lists to "no filter" (empty list = all segments /
# all stems).
proc tid_scope_filter {tid_scopes tid} {
    set segs {}
    set stems {}
    set seg_unbounded 0
    set stem_unbounded 0
    foreach scope $tid_scopes {
        lassign $scope st sg sm
        if {$st ne $tid} continue
        if {$sg eq ""} {
            set seg_unbounded 1
            set stem_unbounded 1
        } else {
            if {!$seg_unbounded} { lappend segs $sg }
            if {$sm eq ""} {
                set stem_unbounded 1
            } else {
                if {!$stem_unbounded} { lappend stems $sm }
            }
        }
    }
    if {$seg_unbounded}  { set segs  {} }
    if {$stem_unbounded} { set stems {} }
    return [list [lsort -unique $segs] [lsort -unique $stems]]
}

if {$execute_mode && $filter_state eq "pending"} {
    puts stderr "Error: --execute requires --ready (default); --pending has no executable work."
    exit 1
}

if {$auto_mode && !$execute_mode} {
    puts stderr "Error: --auto only applies with --execute (or --dry-run)."
    exit 1
}

# --jobs=0 is the stepping signal: one item at a time, gated by a
# stdin [y/N] callback installed below. Parallelism and pacing both
# become meaningless once the user's keystroke is the pace.
if {$jobs == 0} {
    set stepping 1
    set jobs 1
    set delay 0
}

# step_prompt -- stdin [y/N] gate, installed as the step_callback
# when --jobs=0. Generic: the caller passes the current transition's
# tid and the item label; this proc carries no T-id-specific logic.
proc step_prompt {tid slug idx total} {
    set label ""
    catch {set label [::spar::transition_label $tid]}
    set desc [expr {$label ne "" ? "$tid ($label)" : $tid}]
    puts -nonewline stderr "\[y/N\] $desc: $slug ($idx/$total)? "
    flush stderr
    set reply [string trim [gets stdin]]
    if {[string tolower $reply] in {y yes}} { return continue }
    return abort
}

# --- Discover campaign YAML ---
if {$campaign_file ne ""} {
    set yaml_path $campaign_file
} else {
    set yaml_path [file join $campaign_dir campaign.yaml]
    if {![file exists $yaml_path]} {
        set candidates [lsort [glob -nocomplain [file join $campaign_dir campaign*.yaml]]]
        set yaml_path [expr {[llength $candidates] > 0 ? [lindex $candidates end] : ""}]
    }
}

# --- Load campaign YAML ---
set segments_list {}
set skip_set {}
set campaign_name [file tail $campaign_dir]
set primary_channel ""
set cdata [dict create]

if {$yaml_path ne "" && [file exists $yaml_path]} {
    set cdata [spar::load_campaign $yaml_path]
    set campaign_name [spar::dict_get_default $cdata campaign [file tail $yaml_path]]
    set primary_channel [spar::campaign_primary_channel $cdata]
    if {[dict exists $cdata segments]} {
        set segments_list [dict get $cdata segments]
    }
    if {[dict exists $cdata skip_segments]} {
        set skip_set [dict get $cdata skip_segments]
    }
} else {
    puts stderr "Warning: no campaign YAML found; falling back to directory roster scan."
    foreach child [lsort [glob -nocomplain [file join $campaign_dir *]]] {
        if {[file isdirectory $child] && [file exists [file join $child roster.tsv]]} {
            lappend segments_list [file tail $child]
        }
    }
}

if {$execute_mode && $yaml_path eq ""} {
    puts stderr "Error: --execute requires a campaign YAML (P harness needs usp_document/antifacts)."
    exit 1
}

# --- Build segment paths ---
# Per-TID scopes do their own segment filtering inside
# compute_ready_by_tid; segment_paths here is the campaign-wide set
# (minus skip_segments) so any scope can pick from any segment.
set segment_paths {}
foreach seg $segments_list {
    if {$seg in $skip_set} continue
    set seg_dir [file join $campaign_dir $seg]
    if {[file isdirectory $seg_dir] && [file exists [file join $seg_dir roster.tsv]]} {
        lappend segment_paths [list $seg $seg_dir]
    }
}

if {[llength $segment_paths] == 0} {
    puts stderr "No segments found."
    exit 1
}

# --- Classify all contacts ---
# In --auto mode, T1/T2/T3/T4 are the only active transitions and none
# of them read parsed-approach fields (#63). Skip the refine pass —
# cheap classify_segment is enough. Non-auto needs refined fields for
# T6+ progress reporting; refine via the State's cache so any later
# transition_eligible call hits the same projection.
# One State for the whole CLI run — its lifetime matches this script's.
set State [spar::State new]
set all_contacts {}
foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {
        set c [$State classify_segment $seg_dir]
        if {!$auto_mode} {
            set c [$State refine_segment $c]
        }
    } err]} {
        puts stderr "Error in $label: $err"
        continue
    }
    lappend all_contacts {*}$c
}

# --- Active transitions ---
# All T-ids, labels, and auto-safety come from the transition registry
# populated at load time by spar-manager/transitions/*.tcl. No parallel
# list is maintained here.
if {[llength $tid_scopes] == 0} {
    set active_tids [spar::transition_tids]
} else {
    # Unique TIDs in insertion order from tid_scopes.
    set active_tids {}
    foreach scope $tid_scopes {
        lassign $scope tid _ _
        if {$tid ni $active_tids} { lappend active_tids $tid }
    }
}

# --auto drives the offline state machine. Included T-ids are those
# whose metadata declares auto_safe=1 (T1/T2/T3/T4). T6 (email send) is
# excluded because auto_safe=0; T7 has a runner but is kept out for the
# same reason so the loop stays offline.
if {$auto_mode} {
    set filtered_active {}
    foreach t $active_tids {
        if {[spar::transition_auto_safe $t]} { lappend filtered_active $t }
    }
    set active_tids $filtered_active
}

# ────────────────────────────────────────────────────────────────────────
# Execute mode — dispatch ready tasks through the routing table.
# ────────────────────────────────────────────────────────────────────────
if {$execute_mode} {
    set ::_total_done 0
    set ::_total_failed 0

    proc exec_on_progress {slug status message} {
        switch -- $status {
            started { if {$message eq ""} { puts "  \[START\] $slug" } }
            done    { puts "  \[DONE \] $slug [expr {$message ne "" ? "($message)" : ""}]" }
            failed  { puts "  \[FAIL \] $slug ($message)" }
            skipped { puts "  \[SKIP \] $slug ($message)" }
            warning { puts stderr "  \[WARN \] $slug: $message" }
        }
    }

    # Classify segments → contacts. Used at startup and again before each
    # --auto iteration so disk changes from the previous pass feed the
    # next round of transition eligibility.
    #
    # In --auto mode the only active T-ids are T1/T2/T3/T4 (auto_safe=1),
    # none of which read the refined approach fields; classify_segment
    # alone is the natural fit and transition_eligible refines lazily.
    proc reclassify_contacts {state segment_paths {refine 0}} {
        set out {}
        foreach item $segment_paths {
            lassign $item label seg_dir
            if {[catch {
                set c [$state classify_segment $seg_dir]
                if {$refine} {
                    set c [$state refine_segment $c]
                }
            } err]} {
                puts stderr "Error in $label: $err"
                continue
            }
            lappend out {*}$c
        }
        return $out
    }

    # Compute ready tasks per TID, applying each TID's scope filter
    # (segment + stem). Multiple scopes for the same TID concatenate;
    # rows are deduped by stem so `T1 T1:foo` does not run T1's foo
    # rows twice. cdata is the full campaign dict — T9/T10 need it to
    # read secondary/tertiary channel slots.
    proc compute_ready_by_tid {state all_contacts active_tids tid_scopes \
                               primary_channel {cdata {}}} {
        set ready_by_tid [dict create]
        foreach tid $active_tids {
            lassign [tid_scope_filter $tid_scopes $tid] segs stems
            set eligible [$state transition_eligible \
                $all_contacts $tid $primary_channel $cdata]
            set seen_stems [dict create]
            set ready_list {}
            foreach c $eligible {
                if {[dict get $c task_state] ne "ready"} continue
                if {[llength $segs] > 0} {
                    set seg_name [file tail [dict get $c _segment_dir]]
                    if {$seg_name ni $segs} continue
                }
                if {[llength $stems] > 0} {
                    if {[dict get $c stem] ni $stems} continue
                }
                set key [dict get $c stem]
                if {[dict exists $seen_stems $key]} continue
                dict set seen_stems $key 1
                lappend ready_list $c
            }
            if {[llength $ready_list] > 0} {
                dict set ready_by_tid $tid $ready_list
            }
        }
        return $ready_by_tid
    }

    # Dispatch every ready T-id through one shared spar::Dispatcher.
    # Per-TID scope filters flow into build_opts as filter_segments /
    # filter_stems so each runner sees only the scope its TID asked
    # for; per-TID prepare_for_pool returns {worker_proc rows} which
    # we fold into a single batch enqueued onto the same pool.
    #
    # The shared pool means --jobs=N is the campaign-wide cap (not
    # per-TID). set_worker_cap ses_send 1 keeps T6 rows serial inside
    # the pool while harness_run rows (T1/T2/T3/T4) parallelise. See
    # docs/concurrency.md "Per-worker cap".
    proc dispatch_ready {ready_by_tid active_tids tid_scopes \
                         yaml_path cdata dry_run jobs delay \
                         assume_yes step_callback} {
        # Collect {tid worker_proc rows} triples from every active TID.
        # Prep failures decrement nothing — they were never enqueued —
        # but we surface them as warnings so the operator sees them.
        set batches {}
        foreach tid $active_tids {
            if {![spar::has_transition_runner $tid]} continue
            if {![dict exists $ready_by_tid $tid]} continue
            set tasks [dict get $ready_by_tid $tid]
            lassign [tid_scope_filter $tid_scopes $tid] f_segs f_stems
            set base_opts [dict create \
                campaign_file $yaml_path \
                dry_run $dry_run \
                jobs $jobs \
                delay $delay \
                tid $tid]
            if {$step_callback ne ""} {
                dict set base_opts step_callback $step_callback
            }
            set cls [::spar::transitions::get $tid]
            set extra [$cls build_opts $tasks $f_segs $f_stems]
            if {[dict exists $extra log_message]} {
                puts [dict get $extra log_message]
                set extra [dict remove $extra log_message]
            }
            set opts [dict merge $base_opts $extra]
            if {[catch {set prep [$cls prepare_for_pool $opts \
                    exec_on_progress]} err]} {
                puts stderr "  $tid prep error: $err"
                incr ::_total_failed [llength $tasks]
                continue
            }
            set worker_proc [dict get $prep worker_proc]
            set rows        [dict get $prep rows]
            if {[llength $rows] == 0} continue
            lappend batches [list $tid $worker_proc $rows]
        }

        if {[llength $batches] == 0} return

        # Build the shared Dispatcher and pre-install per-worker caps.
        # ses_send is unconditionally capped at 1 (harmless when no T6
        # rows are in the batch); other workers inherit the global cap.
        set ::_alldone 0
        set ::_total_seen 0
        set ::_total_expected 0
        foreach batch $batches {
            incr ::_total_expected [llength [lindex $batch 2]]
        }

        set disp [spar::Dispatcher new $jobs ::spar::_pool_log_drop]
        $disp set_worker_cap ses_send 1

        if {$step_callback ne ""} {
            $disp set_pre_post_callback \
                [list ::spar::_pool_pre_post $step_callback]
        }

        $disp subscribe row-done   [list ::_dispatch_on_done]
        $disp subscribe row-failed [list ::_dispatch_on_failed]
        $disp subscribe row-state  [list ::_dispatch_on_state]

        # Pause the queue while every batch is enqueued so step_callback
        # (when present) sees the final total, not a growing one.
        $disp pause_queue
        foreach batch $batches {
            lassign $batch tid worker_proc rows
            foreach pair $rows {
                lassign $pair stem row_opts
                $disp enqueue $stem $tid $worker_proc $row_opts
                # Mirror the legacy `[START] slug` line at enqueue time
                # so output ordering matches the historical queue.
                exec_on_progress $stem started ""
            }
        }
        $disp resume_queue

        if {$::_total_expected > 0} { vwait ::_alldone }

        catch {$disp destroy}
    }

    # Row-event subscribers used by dispatch_ready. Defined at script
    # scope so the Dispatcher's subscribe call (which runs inside the
    # proc) finds them. They mutate the same exec_on_progress /
    # ::_total_done / ::_total_failed state the script's outer summary
    # block reads.
    proc ::_dispatch_on_done {row result} {
        incr ::_total_done
        set msg ""
        catch {set msg [dict get $result message_id]}
        exec_on_progress $row done $msg
    }
    proc ::_dispatch_on_failed {row reason} {
        incr ::_total_failed
        exec_on_progress $row failed $reason
    }
    proc ::_dispatch_on_state {row to_state} {
        if {$to_state ni {done failed cancelled}} return
        if {$to_state eq "cancelled"} {
            exec_on_progress $row skipped "cancelled"
        }
        incr ::_total_seen
        if {$::_total_seen >= $::_total_expected} {
            after idle [list set ::_alldone 1]
        }
    }

    # ────────────────────────────────────────────────────────────────────
    # --auto: state-machine loop. Re-classify between iterations so T1→T2
    # and T3→T4 happen in a single invocation.
    # ────────────────────────────────────────────────────────────────────
    if {$auto_mode} {
        puts "Campaign: $campaign_name"
        if {$dry_run} { puts "(dry run — writes disabled)" }

        set MAX_ITER 8
        set last_signature ""
        set iter 1
        while {$iter <= $MAX_ITER} {
            set all_contacts [reclassify_contacts $State $segment_paths 0]
            set ready_by_tid [compute_ready_by_tid \
                $State $all_contacts $active_tids $tid_scopes \
                $primary_channel $cdata]

            if {[dict size $ready_by_tid] == 0} {
                if {$iter == 1} {
                    puts "No ready tasks for the requested transitions."
                } else {
                    puts ""
                    puts "Iteration $iter: nothing left — converged."
                }
                break
            }

            # Convergence guard: if the same set of tasks is ready as last
            # iteration, we made no progress (something is wedged).
            set signature ""
            foreach tid [lsort [dict keys $ready_by_tid]] {
                set keys [list]
                foreach c [dict get $ready_by_tid $tid] {
                    lappend keys "[dict get $c _segment_dir]:[dict get $c stem]"
                }
                append signature "${tid}=[lsort $keys];"
            }
            if {$signature eq $last_signature} {
                puts ""
                puts "Iteration $iter: ready set unchanged — stopping (wedged)."
                break
            }
            set last_signature $signature

            puts ""
            puts "── Iteration $iter ──"

            dispatch_ready $ready_by_tid $active_tids $tid_scopes \
                $yaml_path $cdata $dry_run $jobs $delay \
                $assume_yes \
                [expr {$stepping ? "step_prompt" : ""}]

            incr iter
        }
        if {$iter > $MAX_ITER} {
            puts ""
            puts "Hit MAX_ITERATIONS ($MAX_ITER) — stopping. Investigate."
        }

        puts ""
        puts "=== Summary ==="
        puts "Done:   $::_total_done"
        puts "Failed: $::_total_failed"
        if {$::_total_failed > 0} { exit 1 }
        exit 0
    }

    # ────────────────────────────────────────────────────────────────────
    # Non-auto execute (single pass, explicit or default tid_scopes).
    # ────────────────────────────────────────────────────────────────────
    set ready_by_tid [compute_ready_by_tid \
        $State $all_contacts $active_tids $tid_scopes \
        $primary_channel $cdata]

    if {[dict size $ready_by_tid] == 0} {
        puts "Campaign: $campaign_name"
        puts "No ready tasks for the requested transitions."
        exit 0
    }

    # Warn (don't fail) for ready work on unwired TIDs. T8 is the only
    # remaining monitoring-only TID.
    foreach tid [dict keys $ready_by_tid] {
        if {![spar::has_transition_runner $tid]} {
            set n [llength [dict get $ready_by_tid $tid]]
            puts stderr "Note: $tid has $n ready task(s) but no runner is wired — skipping."
        }
    }

    puts "Campaign: $campaign_name"
    if {$dry_run} { puts "(dry run — writes disabled)" }

    # Up-front confirmation lives at the CLI layer (not inside the
    # transition class) so the GUI path — which has already confirmed
    # via its own buttons — doesn't prompt on stdin. Any transition
    # whose class declares requires_send_confirmation=1 gates here.
    # Skipped under --dry-run, --yes, or --jobs=0 (stepping supplies
    # its own per-item gate).
    if {!$dry_run && !$assume_yes && !$stepping} {
        foreach tid $active_tids {
            if {![dict exists $ready_by_tid $tid]} continue
            set t [::spar::transitions::get $tid]
            if {![$t requires_send_confirmation]} continue
            set n [llength [dict get $ready_by_tid $tid]]
            puts -nonewline "$tid ([$t label]): proceed with $n live action(s)? \[y/N\] "
            flush stdout
            set reply [string trim [gets stdin]]
            if {[string tolower $reply] ni {y yes}} {
                puts "Aborted."
                exit 1
            }
        }
    }

    dispatch_ready $ready_by_tid $active_tids $tid_scopes \
        $yaml_path $cdata $dry_run $jobs $delay \
        $assume_yes \
        [expr {$stepping ? "step_prompt" : ""}]

    puts ""
    puts "=== Summary ==="
    puts "Done:   $::_total_done"
    puts "Failed: $::_total_failed"
    if {$::_total_failed > 0} { exit 1 }
    exit 0
}

# ────────────────────────────────────────────────────────────────────────
# Report mode — honours per-TID scopes so `T1:vic` shows only T1's vic
# rows when the user asked for that scope.
# ────────────────────────────────────────────────────────────────────────
puts "Campaign: $campaign_name\n"

set any_output 0
foreach tid [spar::transition_tids] {
    if {$tid ni $active_tids} continue
    set label [spar::transition_label $tid]

    lassign [tid_scope_filter $tid_scopes $tid] segs stems
    set eligible [$State transition_eligible $all_contacts $tid $primary_channel $cdata]

    set ready_list  {}
    set pending_list {}
    foreach c $eligible {
        if {[llength $segs] > 0} {
            set seg_name [file tail [dict get $c _segment_dir]]
            if {$seg_name ni $segs} continue
        }
        if {[llength $stems] > 0} {
            if {[dict get $c stem] ni $stems} continue
        }
        if {[dict get $c task_state] eq "pending"} {
            lappend pending_list $c
        } else {
            lappend ready_list $c
        }
    }

    # Apply state filter — only omits rows when a state filter is set and
    # the relevant bucket is empty. With no state filter, zero-count rows
    # still print so the reader can see the full transition ladder.
    if {$filter_state eq "ready"   && [llength $ready_list]  == 0} continue
    if {$filter_state eq "pending" && [llength $pending_list] == 0} continue

    set nr [llength $ready_list]
    set np [llength $pending_list]
    set total [expr {$nr + $np}]

    if {$filter_state eq ""} {
        puts [format "%-3s %-26s — %3d total (%3d ready, %3d pending)" "${tid}:" $label $total $nr $np]
    } elseif {$filter_state eq "ready"} {
        puts [format "%-3s %-26s — %3d ready" "${tid}:" $label $nr]
    } else {
        puts [format "%-3s %-26s — %3d pending" "${tid}:" $label $np]
    }

    proc print_contacts {clist} {
        foreach c $clist {
            set seg  [dict get $c segment]
            set name [dict get $c contact_name]
            set org  [dict get $c organisation]
            set reason [dict get $c reason]
            if {$reason ne ""} {
                puts "  \[$seg\] $name / $org  ($reason)"
            } else {
                puts "  \[$seg\] $name / $org"
            }
        }
    }

    if {$verbose} {
        if {$filter_state eq "pending"} {
            print_contacts $pending_list
        } elseif {$filter_state eq "ready"} {
            print_contacts $ready_list
        } else {
            if {[llength $ready_list] > 0} {
                puts "  ready:"
                foreach c $ready_list { print_contacts [list $c] }
            }
            if {[llength $pending_list] > 0} {
                puts "  pending:"
                foreach c $pending_list { print_contacts [list $c] }
            }
        }
        puts ""
    }
    set any_output 1
}

if {!$any_output} {
    puts "No matching transitions found."
} elseif {!$verbose} {
    puts "(pass --verbose / -v to list individual contacts)"
}

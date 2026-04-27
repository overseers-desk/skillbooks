#!/usr/bin/env tclsh9.0
# spar-transitions.tcl — transition eligibility report and executor (CLI)
#
# Report mode (default):
#   tclsh9.0 spar-transitions.tcl [campaign_dir_or_yaml] [--tid=T3 ...]
#       [--segment=<name> ...] [--stem=<roster-stem> ...] [--pending|--ready]
#
# Execute mode:
#   tclsh9.0 spar-transitions.tcl <campaign_dir_or_yaml> --tid=Tn --execute
#       [--segment=<name> ...] [--stem=<stem> ...] [--jobs=N] [--delay=N]
#       [--yes] [--dry-run]
#
# Each T-id is represented by a Transition class in
# spar-manager/transitions/; registration happens at source time and
# this file reads the registry via spar::transition_tids / _runner /
# _label / etc. Per-runner opts come from each class's `build_opts`
# method, not from proc-name lookups.
#
# Transitions that declare requires_send_confirmation surface an
# up-front [y/N] here (CLI layer) so the GUI path — which confirms
# via its own buttons — doesn't prompt on stdin.
#
# --auto drives auto_safe=1 transitions as a state machine: classify,
# dispatch ready work, re-classify, repeat until no new work is ready.
# Transitions with external-action side-effects (e.g. SES send)
# declare auto_safe=0 and are filtered out; passing one via --tid=
# alongside --auto is a hard error.
#
# --jobs=0 activates stepping: worker parallelism drops to 1 and a
# stdin [y/N] gate fires before each item. The gate is generic — the
# dispatcher / driver invokes a callback between items and the
# transition class does not know what the callback does.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-dispatch.tcl]
source [file join $script_dir spar-email.tcl]

# --- Argument parsing ---
# Hand-rolled rather than tcllib cmdline because --tid, --segment, --stem
# are repeatable; cmdline::getoptions and tcl::OptProc both overwrite on
# repeat. Third-party parse_args/argparse support accumulation but aren't
# installed. Tradeoff: we only accept --flag=value, not --flag value.
set campaign_dir ""
set campaign_file ""
set filter_tid {}
set filter_state {}   ;# "ready", "pending", or empty (all)
set filter_segments {}
set filter_stems {}
set execute_mode 0
set auto_mode 0
set dry_run 0
set jobs 4
set delay 2
set assume_yes 0
set verbose 0
set stepping 0

proc print_help {} {
    puts {spar-transitions.tcl — report and execute SPAR state transitions.

USAGE
    tclsh9.0 spar-transitions.tcl [campaign_dir_or_yaml] [options]

OPTIONS
    --tid=Tn          filter by transition id (repeatable); default: all
    --segment=NAME    restrict to segment (repeatable)
    --stem=STEM       restrict to contact stem (repeatable)
    --pending         show/act on pending tasks only
    --ready           show/act on ready tasks only
    --execute         run the transition; default is report-only
    --auto            with --execute: drive the offline state machine
                      (all auto_safe=1 transitions) until convergence.
                      Re-classifies between iterations so upstream
                      output feeds downstream transitions in one run.
                      Refuses if any --tid= names an auto_safe=0
                      transition.
    --dry-run         run the transition with writes disabled (implies
                      execute-mode; pass alone, not with --execute).
                      Harness-backed transitions write prompts, skip
                      children; send-type transitions skip the external
                      action and any stamp that follows it.
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
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --tid=Tn --execute

    # Step through one transition's ready work, confirming each item
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --tid=Tn \
        --execute --jobs=0

    # Dry-run first, then live
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --tid=Tn --dry-run
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --tid=Tn --execute

    # Limit to one segment or one stem
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --tid=Tn --execute \
        --segment=vic --stem=jane-doe

    # Drive the offline state machine (auto_safe transitions) until
    # convergence, re-classifying between iterations.
    tclsh9.0 spar-transitions.tcl path/to/campaign.yaml --execute --auto}
}

foreach arg $argv {
    switch -glob -- $arg {
        -h        -
        --help      { print_help; exit 0 }
        --tid=*     { lappend filter_tid [string range $arg 6 end] }
        --segment=* { lappend filter_segments [string range $arg 10 end] }
        --stem=*    { lappend filter_stems [string range $arg 7 end] }
        --jobs=*    { set jobs [string range $arg 7 end] }
        --delay=*   { set delay [string range $arg 8 end] }
        --yes       { set assume_yes 1 }
        --pending   { set filter_state pending }
        --ready     { set filter_state ready }
        --execute   { set execute_mode 1 }
        --auto      { set auto_mode 1 }
        --dry-run   { set dry_run 1 }
        -v          -
        --verbose   { set verbose 1 }
        --*         { puts stderr "Unknown flag: $arg (try --help)"; exit 1 }
        default     {
            set norm [file normalize $arg]
            if {[file isfile $norm] && [string match *.yaml $norm]} {
                set campaign_file $norm
                set campaign_dir [file dirname $norm]
            } else {
                set campaign_dir $arg
            }
        }
    }
}

if {$dry_run && $execute_mode} {
    puts stderr "Error: --dry-run and --execute are mutually exclusive."
    puts stderr "  --dry-run   runs the transition with writes disabled"
    puts stderr "  --execute   runs the transition live (with writes)"
    puts stderr "Pick one."
    exit 1
}
# --dry-run is its own execute mode — no need to pass --execute alongside.
if {$dry_run} { set execute_mode 1 }

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

# Safety: --auto refuses any transition whose class declares
# auto_safe=0 (e.g. live SES send). The check is against class
# metadata, not T-id literals, so new auto-unsafe transitions are
# refused without touching this file.
if {$auto_mode && [llength $filter_tid] > 0} {
    set unsafe {}
    foreach tid $filter_tid {
        if {[catch {set t [::spar::transitions::get $tid]}]} continue
        if {![$t auto_safe]} { lappend unsafe "$tid ([$t label])" }
    }
    if {[llength $unsafe] > 0} {
        puts stderr "Error: --auto excludes [join $unsafe {, }]. Drop those --tid= values or drop --auto."
        exit 1
    }
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

if {$campaign_file ne "" && $campaign_dir eq ""} {
    set campaign_dir [file dirname [file normalize $campaign_file]]
}
if {$campaign_dir eq ""} { set campaign_dir "." }
set campaign_dir [file normalize $campaign_dir]

# --- Discover campaign YAML ---
if {$campaign_file ne ""} {
    set yaml_path [file normalize $campaign_file]
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

# --- Build segment paths (honour --segment filter) ---
set segment_paths {}
foreach seg $segments_list {
    if {$seg in $skip_set} continue
    if {[llength $filter_segments] > 0 && $seg ni $filter_segments} continue
    set seg_dir [file join $campaign_dir $seg]
    if {[file isdirectory $seg_dir] && [file exists [file join $seg_dir roster.tsv]]} {
        lappend segment_paths [list $seg $seg_dir]
    }
}

if {[llength $segment_paths] == 0} {
    puts stderr "No segments found."
    exit 1
}

# --- Classify all contacts, then apply --stem filter ---
# In --auto mode, T1/T2/T6/T7 are the only active transitions and none of
# them read parsed-approach fields (#63). Skip the YAML parse on the
# initial pass too — the auto loop reclassifies cheaply each iteration.
set _classify_full [expr {$auto_mode ? 0 : 1}]
set all_contacts {}
foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {set c [spar::classify_segment $seg_dir $_classify_full]} err]} {
        puts stderr "Error in $label: $err"
        continue
    }
    lappend all_contacts {*}$c
}

if {[llength $filter_stems] > 0} {
    set filtered {}
    foreach c $all_contacts {
        set s [spar::dict_get_default $c stem ""]
        if {$s in $filter_stems} {
            lappend filtered $c
        }
    }
    set all_contacts $filtered
}

# --- Transition definitions ---
# All T-ids, labels, and auto-safety come from the transition registry
# populated at load time by spar-manager/transitions/*.tcl. No parallel
# list is maintained here.
if {[llength $filter_tid] == 0} {
    set active_tids [spar::transition_tids]
} else {
    set active_tids $filter_tid
}

# --auto drives the offline state machine. Included T-ids are those
# whose metadata declares auto_safe=1 (T1/T2/T6/T7). T3 (email send) is
# excluded because auto_safe=0; T4 has a runner but is kept out for the
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
    set ::_pending_dispatchers 0
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

    proc exec_on_complete {done failed result} {
        incr ::_total_done $done
        incr ::_total_failed $failed
        incr ::_pending_dispatchers -1
        if {$::_pending_dispatchers <= 0} {
            set ::_alldone 1
        }
    }

    # Classify segments → contacts (honours --stem filter). Used at startup
    # and again before each --auto iteration so disk changes from the
    # previous pass feed the next round of transition eligibility.
    #
    # In --auto mode the only active T-ids are T1/T2/T6/T7 (auto_safe=1),
    # none of which read the parsed-approach fields (email_sent /
    # linkedin_sent / email_replied / to_addresses / unsent_subjects). We
    # opt into classify_segment's cheap mode (full=0) so each iteration
    # skips read_approach_yaml + analyse_final_round per contact —
    # that's the latency that previously made --auto silent for several
    # seconds before the first dispatch (#63).
    proc reclassify_contacts {segment_paths filter_stems {full 1}} {
        set out {}
        foreach item $segment_paths {
            lassign $item label seg_dir
            if {[catch {set c [spar::classify_segment $seg_dir $full]} err]} {
                puts stderr "Error in $label: $err"
                continue
            }
            lappend out {*}$c
        }
        if {[llength $filter_stems] > 0} {
            set filtered {}
            foreach c $out {
                if {[dict get $c stem] in $filter_stems} { lappend filtered $c }
            }
            set out $filtered
        }
        return $out
    }

    # Compute ready tasks per TID. cdata is full campaign dict — T9/T10
    # need it to read secondary/tertiary channel slots.
    proc compute_ready_by_tid {all_contacts active_tids primary_channel {cdata {}}} {
        set ready_by_tid [dict create]
        foreach tid $active_tids {
            set eligible [spar::transition_eligible $all_contacts $tid $primary_channel $cdata]
            set ready_list {}
            foreach c $eligible {
                if {[dict get $c task_state] eq "ready"} { lappend ready_list $c }
            }
            if {[llength $ready_list] > 0} { dict set ready_by_tid $tid $ready_list }
        }
        return $ready_by_tid
    }

    # Dispatch every ready T-id through its runner. Runners run concurrently;
    # exec_on_complete decrements ::_pending_dispatchers and the outer vwait
    # blocks until all have drained.
    proc dispatch_ready {ready_by_tid active_tids yaml_path cdata \
                         dry_run jobs delay \
                         filter_segments filter_stems assume_yes \
                         step_callback} {
        set ::_pending_dispatchers 0
        set ::_alldone 0
        foreach tid $active_tids {
            if {![spar::has_transition_runner $tid]} continue
            if {![dict exists $ready_by_tid $tid]} continue
            set runner [spar::transition_runner $tid]
            set tasks [dict get $ready_by_tid $tid]
            set opts [dict create \
                campaign_file $yaml_path \
                dry_run $dry_run \
                jobs $jobs \
                delay $delay \
                tid $tid]
            if {$step_callback ne ""} {
                dict set opts step_callback $step_callback
            }
            # Per-runner opts come from the transition class's build_opts
            # method. It returns a dict to merge onto opts; the
            # log_message key is the one-line summary printed before
            # dispatch.
            set cls [::spar::transitions::get $tid]
            set extra [$cls build_opts $tasks $filter_segments $filter_stems]
            if {[dict exists $extra log_message]} {
                puts [dict get $extra log_message]
                set extra [dict remove $extra log_message]
            }
            set opts [dict merge $opts $extra]
            incr ::_pending_dispatchers
            if {[catch {{*}$runner $opts exec_on_progress exec_on_complete} err]} {
                puts stderr "  $tid dispatch error: $err"
                incr ::_pending_dispatchers -1
                incr ::_total_failed [llength $tasks]
            }
        }
        if {$::_pending_dispatchers > 0} { vwait ::_alldone }
    }

    # ────────────────────────────────────────────────────────────────────
    # --auto: state-machine loop. Re-classify between iterations so T1→T2
    # and T6→T7 happen in a single invocation.
    # ────────────────────────────────────────────────────────────────────
    if {$auto_mode} {
        puts "Campaign: $campaign_name"
        if {$dry_run} { puts "(dry run — writes disabled)" }

        set MAX_ITER 8
        set last_signature ""
        set iter 1
        while {$iter <= $MAX_ITER} {
            set all_contacts [reclassify_contacts $segment_paths $filter_stems 0]
            set ready_by_tid [compute_ready_by_tid \
                $all_contacts $active_tids $primary_channel $cdata]

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

            dispatch_ready $ready_by_tid $active_tids \
                $yaml_path $cdata $dry_run $jobs $delay \
                $filter_segments $filter_stems $assume_yes \
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
    # Non-auto execute (single pass, explicit or default --tid).
    # ────────────────────────────────────────────────────────────────────
    set ready_by_tid [compute_ready_by_tid \
        $all_contacts $active_tids $primary_channel $cdata]

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

    dispatch_ready $ready_by_tid $active_tids \
        $yaml_path $cdata $dry_run $jobs $delay \
        $filter_segments $filter_stems $assume_yes \
        [expr {$stepping ? "step_prompt" : ""}]

    puts ""
    puts "=== Summary ==="
    puts "Done:   $::_total_done"
    puts "Failed: $::_total_failed"
    if {$::_total_failed > 0} { exit 1 }
    exit 0
}

# ────────────────────────────────────────────────────────────────────────
# Report mode (original behaviour, now honouring --segment / --stem)
# ────────────────────────────────────────────────────────────────────────
puts "Campaign: $campaign_name\n"

set any_output 0
foreach tid [spar::transition_tids] {
    if {$tid ni $active_tids} continue
    set label [spar::transition_label $tid]

    set eligible [spar::transition_eligible $all_contacts $tid $primary_channel $cdata]

    set ready_list  {}
    set pending_list {}
    foreach c $eligible {
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

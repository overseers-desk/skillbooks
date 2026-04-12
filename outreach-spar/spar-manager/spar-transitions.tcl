#!/usr/bin/env tclsh
# spar-transitions.tcl — transition eligibility report and executor (CLI)
#
# Report mode (default):
#   tclsh spar-transitions.tcl [campaign_dir_or_yaml] [--tid=T3 ...]
#       [--segment=<name> ...] [--stem=<roster-stem> ...] [--pending|--ready]
#
# Execute mode:
#   tclsh spar-transitions.tcl <campaign_dir_or_yaml> --tid=Tn --execute
#       [--segment=<name> ...] [--stem=<stem> ...] [--jobs=N] [--dry-run]
#
# T1 and T6 route to spar::dispatch_profiles (P harness). T2, T3, T4, T7, T8
# execution is not yet wired; --execute on those TIDs fails loudly rather than
# silently skipping.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-dispatch.tcl]

# --- Argument parsing ---
set campaign_dir ""
set campaign_file ""
set filter_tid {}
set filter_state {}   ;# "ready", "pending", or empty (all)
set filter_segments {}
set filter_stems {}
set execute_mode 0
set dry_run 0
set jobs 4

foreach arg $argv {
    switch -glob -- $arg {
        --tid=*     { lappend filter_tid [string range $arg 6 end] }
        --segment=* { lappend filter_segments [string range $arg 10 end] }
        --stem=*    { lappend filter_stems [string range $arg 7 end] }
        --jobs=*    { set jobs [string range $arg 7 end] }
        --pending   { set filter_state pending }
        --ready     { set filter_state ready }
        --execute   { set execute_mode 1 }
        --dry-run   { set dry_run 1 }
        --*         { puts stderr "Unknown flag: $arg"; exit 1 }
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

if {$execute_mode && $filter_state eq "pending"} {
    puts stderr "Error: --execute requires --ready (default); --pending has no executable work."
    exit 1
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

if {$yaml_path ne "" && [file exists $yaml_path]} {
    set cdata [spar::load_campaign $yaml_path]
    set campaign_name [spar::dict_get_default $cdata campaign [file tail $yaml_path]]
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
set all_contacts {}
foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {set c [spar::classify_segment $seg_dir]} err]} {
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
set tids    {T1 T2 T3 T4 T6 T7 T8}
set tlabels {
    "Sweep \u2192 Profile"
    "Profile \u2192 Approach"
    "Approach \u2192 Send"
    "Send \u2192 Reply"
    "Stale \u2192 Re-profile"
    "Re-profile \u2192 Re-approach"
    "LinkedIn \u2192 Email follow-up"
}

if {[llength $filter_tid] == 0} {
    set active_tids $tids
} else {
    set active_tids $filter_tid
}

# ────────────────────────────────────────────────────────────────────────
# Execute mode — route ready tasks to dispatchers
# ────────────────────────────────────────────────────────────────────────
if {$execute_mode} {
    set profile_tids {T1 T6}
    set unimplemented_tids {T2 T3 T4 T7 T8}

    # Collect ready tasks per TID
    set ready_by_tid [dict create]
    foreach tid $active_tids {
        set eligible [spar::transition_eligible $all_contacts $tid]
        set ready_list {}
        foreach c $eligible {
            if {[dict get $c task_state] eq "ready"} {
                lappend ready_list $c
            }
        }
        if {[llength $ready_list] > 0} {
            dict set ready_by_tid $tid $ready_list
        }
    }

    if {[dict size $ready_by_tid] == 0} {
        puts "Campaign: $campaign_name"
        puts "No ready tasks for the requested transitions."
        exit 0
    }

    # Fail loudly for unimplemented TIDs with ready work
    foreach tid $unimplemented_tids {
        if {[dict exists $ready_by_tid $tid]} {
            set n [llength [dict get $ready_by_tid $tid]]
            puts stderr "Error: --execute for $tid is not yet wired ($n ready task(s))."
            puts stderr "  T2/T7 → use spar-a-batch.tcl for now."
            puts stderr "  T3/T4/T8 → no harness exists yet."
            exit 1
        }
    }

    # Dispatch T1/T6 per segment
    puts "Campaign: $campaign_name"
    if {$dry_run} { puts "(dry run — prompts written, no harnesses spawned)" }

    set ::_pending_dispatchers 0
    set ::_total_done 0
    set ::_total_failed 0

    proc exec_on_progress {slug status message} {
        switch -- $status {
            started { puts "  \[START\] $slug" }
            done    { puts "  \[DONE \] $slug" }
            failed  { puts "  \[FAIL \] $slug ($message)" }
            skipped { puts "  \[SKIP \] $slug ($message)" }
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

    foreach tid $profile_tids {
        if {![dict exists $ready_by_tid $tid]} continue
        set tasks [dict get $ready_by_tid $tid]

        # Group by _segment_dir
        set by_segdir [dict create]
        foreach c $tasks {
            set sd [dict get $c _segment_dir]
            dict lappend by_segdir $sd [dict get $c stem]
        }

        dict for {segdir stems} $by_segdir {
            puts "$tid @ [file tail $segdir]: [llength $stems] task(s) — [join $stems {, }]"
            set opts [dict create \
                campaign_file $yaml_path \
                dry_run $dry_run \
                jobs $jobs \
                stems $stems]
            incr ::_pending_dispatchers
            if {[catch {
                spar::dispatch_profiles $segdir $opts exec_on_progress exec_on_complete
            } err]} {
                puts stderr "  dispatch error: $err"
                incr ::_pending_dispatchers -1
                incr ::_total_failed [llength $stems]
            }
        }
    }

    if {$::_pending_dispatchers > 0} {
        vwait ::_alldone
    }

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
for {set i 0} {$i < [llength $tids]} {incr i} {
    set tid [lindex $tids $i]
    if {$tid ni $active_tids} continue
    set label [lindex $tlabels $i]

    set eligible [spar::transition_eligible $all_contacts $tid]
    if {[llength $eligible] == 0} continue

    set ready_list  {}
    set pending_list {}
    foreach c $eligible {
        if {[dict get $c task_state] eq "pending"} {
            lappend pending_list $c
        } else {
            lappend ready_list $c
        }
    }

    # Apply state filter
    if {$filter_state eq "ready"   && [llength $ready_list]  == 0} continue
    if {$filter_state eq "pending" && [llength $pending_list] == 0} continue

    set nr [llength $ready_list]
    set np [llength $pending_list]
    set total [expr {$nr + $np}]

    if {$filter_state eq ""} {
        puts "${tid}: ${label} — $total total ($nr ready, $np pending)"
    } elseif {$filter_state eq "ready"} {
        puts "${tid}: ${label} — $nr ready"
    } else {
        puts "${tid}: ${label} — $np pending"
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
    set any_output 1
}

if {!$any_output} {
    puts "No matching transitions found."
}

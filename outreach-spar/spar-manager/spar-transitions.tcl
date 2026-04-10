#!/usr/bin/env tclsh
# spar-transitions.tcl — transition eligibility table (CLI, no GUI)
# Usage: tclsh spar-transitions.tcl [campaign_dir_or_yaml] [--tid=T3] [--pending] [--ready]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# --- Argument parsing ---
set campaign_dir ""
set campaign_file ""
set filter_tid {}
set filter_state {}   ;# "ready", "pending", or empty (all)

foreach arg $argv {
    switch -glob -- $arg {
        --tid=*   { lappend filter_tid [string range $arg 6 end] }
        --pending { set filter_state pending }
        --ready   { set filter_state ready }
        --*       { puts stderr "Unknown flag: $arg"; exit 1 }
        default   {
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

# --- Build segment paths ---
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
set all_contacts {}
foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {set c [spar::classify_segment $seg_dir]} err]} {
        puts stderr "Error in $label: $err"
        continue
    }
    lappend all_contacts {*}$c
}

# --- Transition definitions ---
set tids    {T1 T2 T3 T4 T5 T6 T7 T8}
set tlabels {
    "Sweep \u2192 Profile"
    "Profile \u2192 Approach"
    "Approach \u2192 Send"
    "Send \u2192 Reply"
    "Flag invalid"
    "Stale \u2192 Re-profile"
    "Re-profile \u2192 Re-approach"
    "LinkedIn \u2192 Email follow-up"
}

if {[llength $filter_tid] == 0} {
    set active_tids $tids
} else {
    set active_tids $filter_tid
}

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

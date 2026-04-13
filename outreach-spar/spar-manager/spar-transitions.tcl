#!/usr/bin/env tclsh
# spar-transitions.tcl — transition eligibility report and executor (CLI)
#
# Report mode (default):
#   tclsh spar-transitions.tcl [campaign_dir_or_yaml] [--tid=T3 ...]
#       [--segment=<name> ...] [--stem=<roster-stem> ...] [--pending|--ready]
#
# Execute mode:
#   tclsh spar-transitions.tcl <campaign_dir_or_yaml> --tid=Tn --execute
#       [--segment=<name> ...] [--stem=<stem> ...] [--jobs=N] [--delay=N]
#       [--yes] [--dry-run]
#
# T1/T6 route to spar::dispatch_profiles (P harness). T3 sends via AWS SES
# (spar::send_email) serially with --delay pacing. T2/T4/T7/T8 execution is
# not wired here; --execute on those TIDs fails loudly rather than silently
# skipping.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-dispatch.tcl]
source [file join $script_dir spar-email.tcl]

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
set delay 2
set assume_yes 0
set verbose 0

proc print_help {} {
    puts {spar-transitions.tcl — report and execute SPAR state transitions.

USAGE
    tclsh spar-transitions.tcl [campaign_dir_or_yaml] [options]

OPTIONS
    --tid=Tn          filter by transition id (repeatable); default: all
    --segment=NAME    restrict to segment (repeatable)
    --stem=STEM       restrict to contact stem (repeatable)
    --pending         show/act on pending tasks only
    --ready           show/act on ready tasks only
    --execute         run the transition (T1/T3/T6); default is report-only
    --dry-run         with --execute: write prompts / skip SES, no harnesses
    --jobs=N          parallel jobs for T1/T6 --execute (default 4)
    --delay=N         seconds between T3 sends (default 2, serial)
    --yes             skip the "send N emails? [y/N]" confirmation
    -v, --verbose     in report mode, list each contact (default: counts only)
    -h, --help        show this help

TRANSITIONS
    T1  Sweep → Profile           (execute: wired here)
    T2  Profile → Approach        (execute: use spar-a-batch.tcl)
    T3  Approach → Send           (execute: wired here, via AWS SES)
    T4  Send → Reply              (execute: not wired — monitoring-only TID)
    T6  Stale → Re-profile        (execute: wired here)
    T7  Re-profile → Re-approach  (execute: use spar-a-batch.tcl)
    T8  LinkedIn → Email          (execute: not wired)

COMMON WORKFLOWS
    # Report: what's ready across all transitions?
    tclsh spar-transitions.tcl path/to/campaign --ready

    # Create all missing profiles (T1) in a campaign
    tclsh spar-transitions.tcl path/to/campaign.yaml --tid=T1 --execute

    # Make all missing approaches (T2) — separate tool:
    tclsh spar-a-batch.tcl path/to/campaign.yaml

    # Send all approach-ready emails (T3) — dry-run first, then live
    tclsh spar-transitions.tcl path/to/campaign.yaml --tid=T3 --execute --dry-run
    tclsh spar-transitions.tcl path/to/campaign.yaml --tid=T3 --execute

    # Limit to one segment or one stem
    tclsh spar-transitions.tcl path/to/campaign.yaml --tid=T1 --execute \
        --segment=vic --stem=jane-doe}
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
set primary_channel ""

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
    set email_tids {T3}
    set unimplemented_tids {T2 T4 T7 T8}

    # Collect ready tasks per TID
    set ready_by_tid [dict create]
    foreach tid $active_tids {
        set eligible [spar::transition_eligible $all_contacts $tid $primary_channel]
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
            puts stderr "  T4/T8 → no harness exists yet."
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

    # ── T3: send approach-ready emails via AWS SES ─────────────────────
    if {[dict exists $ready_by_tid T3]} {
        set t3_tasks [dict get $ready_by_tid T3]

        # Resolve campaign-level defaults.
        set camp_sender [spar::dict_get_default $cdata sender [dict create]]
        set camp_from_name  [spar::dict_get_default $camp_sender name ""]
        set camp_from_email [spar::dict_get_default $camp_sender email ""]
        set camp_bcc        [spar::dict_get_default $camp_sender bcc ""]
        set ses_region      [spar::dict_get_default $cdata ses_region "ap-southeast-2"]

        set n_t3 [llength $t3_tasks]
        puts ""
        puts "T3: Approach → Send — $n_t3 email(s) ready"

        # Confirmation unless --dry-run or --yes.
        if {!$dry_run && !$assume_yes} {
            puts -nonewline "Send $n_t3 email(s) live via SES (region $ses_region)? \[y/N\] "
            flush stdout
            set reply [string trim [gets stdin]]
            if {[string tolower $reply] ne "y" && [string tolower $reply] ne "yes"} {
                puts "Aborted — no emails sent."
                exit 1
            }
        }

        set first 1
        foreach c $t3_tasks {
            if {!$first && !$dry_run} { after [expr {$delay * 1000}] }
            set first 0

            set stem      [dict get $c stem]
            set seg_dir   [dict get $c _segment_dir]
            set slug      "[file tail $seg_dir]/$stem"
            set approach_path [file join $seg_dir approach "${stem}.yaml"]

            puts "  \[START\] $slug"

            if {![file exists $approach_path]} {
                puts "  \[FAIL \] $slug (approach file missing: $approach_path)"
                incr ::_total_failed
                continue
            }

            set approach_data [spar::read_approach_yaml $approach_path]
            set msg [spar::final_email_message $approach_data]
            if {$msg eq ""} {
                puts "  \[FAIL \] $slug (no email message in final round)"
                incr ::_total_failed
                continue
            }

            set to      [string trim [spar::dict_get_default $msg to ""]]
            set cc      [string trim [spar::dict_get_default $msg cc ""]]
            set bcc     [string trim [spar::dict_get_default $msg bcc ""]]
            set subject [spar::dict_get_default $msg subject ""]
            set body    [spar::dict_get_default $msg body ""]

            if {$to eq "" || $subject eq "" || $body eq ""} {
                puts "  \[FAIL \] $slug (message missing to/subject/body)"
                incr ::_total_failed
                continue
            }

            # Sender: approach decisions.sender first, campaign fallback.
            set from_name  $camp_from_name
            set from_email $camp_from_email
            if {[dict exists $approach_data decisions]} {
                set ad_sender [spar::dict_get_default [dict get $approach_data decisions] sender [dict create]]
                set ad_name  [spar::dict_get_default $ad_sender name ""]
                set ad_email [spar::dict_get_default $ad_sender email ""]
                if {$ad_email ne ""} {
                    set from_email $ad_email
                    if {$ad_name ne ""} { set from_name $ad_name }
                }
            }
            if {$from_email eq ""} {
                puts "  \[FAIL \] $slug (no sender: neither approach decisions.sender.email nor campaign sender.email set)"
                incr ::_total_failed
                continue
            }
            set from_hdr [expr {$from_name ne "" ? "$from_name <$from_email>" : $from_email}]

            # BCC: message-level first, then campaign sender.bcc, else
            # self-BCC the effective From address so every send leaves an
            # archive copy in the sender's own mailbox.
            if {$bcc eq ""} { set bcc $camp_bcc }
            if {$bcc eq ""} { set bcc $from_email }

            set send_opts [dict create \
                region  $ses_region \
                from    $from_hdr \
                to      $to \
                subject $subject \
                body    $body \
                dry_run $dry_run]
            if {$cc ne ""}  { dict set send_opts cc  $cc  }
            if {$bcc ne ""} { dict set send_opts bcc $bcc }

            if {[catch {set result [spar::send_email $send_opts]} err]} {
                puts "  \[FAIL \] $slug (send_email threw: $err)"
                incr ::_total_failed
                continue
            }

            if {![dict get $result ok]} {
                puts "  \[FAIL \] $slug ([dict get $result message_id])"
                incr ::_total_failed
                continue
            }

            # Stamp actioned_date on success. Under the ≤1-email invariant
            # (too_many_final_emails in validate_approach), stamping all
            # unsent emails stamps exactly the one we just sent.
            if {!$dry_run} {
                set today [clock format [clock seconds] -format "%Y-%m-%d"]
                if {[catch {spar::stamp_actioned_date $approach_path $today} err]} {
                    puts "  \[FAIL \] $slug (sent ok but stamp failed: $err)"
                    incr ::_total_failed
                    continue
                }
            }

            puts "  \[DONE \] $slug ([dict get $result message_id])"
            incr ::_total_done
        }
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

    set eligible [spar::transition_eligible $all_contacts $tid $primary_channel]
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

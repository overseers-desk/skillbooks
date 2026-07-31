#!/usr/bin/env tclsh9.0
# spar-progress.tcl — Campaign progress table and duplicate detection (CLI)
# Usage: tclsh9.0 spar-progress.tcl [campaign_dir_or_yaml ...] [--campaign=YAML ...] [--no-reply-check] [--json] [--legend] [-v|--verbose]
# Positional arg may be a directory or a campaign YAML file (directory derived from YAML path).
# Several campaigns may be named in one run: each gets its own name line,
# table and warnings, in the order given.
#
# --no-reply-check omits the T7 (reply-check) row from the transition list.
# --json           one campaign per run; the object shape is the contract.
# -v, --verbose    under Warnings, list the member names behind each grouped
#                  per-contact warning (default: segment counts only).

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lib spar-state.tcl]

# --- Argument parsing ---
# Hand-rolled (not tcllib cmdline) for style consistency with
# spar-transition.tcl — see that file for the rationale.
set campaign_specs {}   ;# list of {campaign_file campaign_dir}, in argument order
set json_mode 0
set skip_reply_check 0
set verbose 0
set show_legend 0
foreach arg $argv {
    switch -glob -- $arg {
        --campaign=*     { lappend campaign_specs [list [string range $arg 11 end] ""] }
        --json           { set json_mode 1 }
        --no-reply-check { set skip_reply_check 1 }
        -v               -
        --verbose        { set verbose 1 }
        --legend         { set show_legend 1 }
        --*              { puts stderr "Unknown flag: $arg"; exit 1 }
        default          {
            if {[string match *.yaml $arg]} {
                set f [file normalize $arg]
                lappend campaign_specs [list $f [file dirname $f]]
            } else {
                lappend campaign_specs [list "" $arg]
            }
        }
    }
}
# No campaign named: resolve_campaign discovers one under the working directory.
if {[llength $campaign_specs] == 0} { set campaign_specs [list [list "" ""]] }

# --- Resolve one campaign, classify its segments, collect its counts ---
# Returns the resolve_campaign dict plus all_contacts and segment_counts,
# or "" when the campaign will not resolve, its reason on stderr.
# The State is passed in so its cache spans every campaign in the run.
proc analyse_campaign {State campaign_file campaign_dir} {
    if {[catch {set rc [spar::resolve_campaign $campaign_file $campaign_dir]} err]} {
        puts stderr $err
        return ""
    }
    set cdata        [dict get $rc cdata]
    set approach_dir [spar::approach_dir_for_campaign [dict get $rc yaml_path]]
    set all_contacts {}
    set segment_counts {}   ;# list of {label counts_dict}

    foreach item [dict get $rc segment_paths] {
        lassign $item label seg_dir
        if {[catch {
            # Cheap classify, then refine: progress_counts projects the
            # SENT / REPLIED states, which only refinement resolves. The
            # cache means refine_segment shares parses with any later
            # transition_eligible calls in this script.
            set classified [$State refine_segment \
                [$State classify_segment $seg_dir $approach_dir]]
        } err]} {
            puts stderr "Error in $label: $err"
            continue
        }
        lappend all_contacts {*}$classified
        lappend segment_counts [list $label [spar::progress_counts $classified $cdata]]
    }
    return [dict merge $rc [dict create \
        all_contacts $all_contacts segment_counts $segment_counts]]
}

# One State for the whole CLI run — its lifetime matches this script's.
set State [spar::State new]

# --- JSON mode ---
if {$json_mode} {
    # The object shape is the contract, so one campaign per run.
    if {[llength $campaign_specs] > 1} {
        puts stderr "--json reports a single campaign; name one."
        exit 1
    }
    lassign [lindex $campaign_specs 0] campaign_file campaign_dir
    set analysis [analyse_campaign $State $campaign_file $campaign_dir]
    if {$analysis eq ""} { exit 1 }
    dict with analysis {}

    package require json::write

    proc _counts_tree {c} {
        dict with c {}
        ::json::write object \
            valid     $valid \
            profiled  $profiled \
            qualified [::json::write object \
                count      $star3 \
                approachable $approachable \
                approached $approached_star3 \
                sent       $sent \
                replied    $replied \
                channels   [::json::write object \
                    email      $has_email \
                    linkedin   $has_linkedin \
                    facebook   $has_facebook \
                    phone_only $has_phone_only]]
    }
    proc progress_to_json {progress_dict} {
        set seg_list {}
        foreach s [dict get $progress_dict segments] {
            lappend seg_list [::json::write object \
                name [::json::write string [dict get $s name]] \
                active [expr {[dict get $s active] ? "true" : "false"}] \
                counts [_counts_tree [dict get $s counts]]]
        }
        set tr_list {}
        foreach t [dict get $progress_dict transitions] {
            lappend tr_list [::json::write object \
                label [::json::write string [dict get $t label]] count [dict get $t count]]
        }
        set w [dict get $progress_dict warnings]

        ::json::write object \
            campaign [::json::write string [dict get $progress_dict campaign]] \
            min_star [dict get $progress_dict min_star] \
            segments [::json::write array {*}$seg_list] \
            totals [_counts_tree [dict get $progress_dict totals]] \
            warnings [::json::write object \
                duplicate_to [dict get $w duplicate_to] \
                duplicate_name [dict get $w duplicate_name] \
                duplicate_email [dict get $w duplicate_email] \
                identical_subject [dict get $w identical_subject]] \
            validation [::json::write object \
                errors [dict get $w validation_errors] \
                warnings [dict get $w validation_warnings]] \
            transitions [::json::write array {*}$tr_list]
    }

    # Build the progress dict
    set seg_results {}
    foreach item $segment_counts {
        lassign $item label counts
        lappend seg_results [dict create name $label active 1 counts $counts]
    }
    set totals [dict create valid 0 profiled 0 star3 0 approachable 0 \
        approached_star3 0 has_email 0 has_linkedin 0 has_facebook 0 \
        has_phone_only 0 sent 0 replied 0]
    foreach seg_info $seg_results {
        set sc [dict get $seg_info counts]
        dict for {k v} $sc { dict set totals $k [expr {[dict get $totals $k] + $v}] }
    }
    # Transition labels come from the transition registry via
    # spar::transition_label; progress JSON includes the same T-ids as
    # the UI tree. --no-reply-check omits T7 from the output.
    set transitions {}
    foreach tid [spar::ui_transition_tids] {
        if {$skip_reply_check && $tid eq "T7"} continue
        set tlabel [spar::transition_label $tid]
        set tasks [$State transition_eligible $all_contacts $tid $primary_channel $cdata]
        lappend transitions [dict create label "$tid: $tlabel" count [llength $tasks] tasks $tasks]
    }
    puts [progress_to_json [dict create campaign $campaign_name min_star $min_star \
        segments $seg_results totals $totals \
        warnings [spar::build_warnings $all_contacts $cdata] \
        transitions $transitions]]
    exit 0
}

# --- Human-readable output ---
proc fmt_cell {count denom} {
    if {$denom > 0} {
        set pct [expr {$count * 100.0 / $denom}]
        return [format "%3d %3.0f%%" $count $pct]
    } else {
        return [format "%3d    -" $count]
    }
}
proc pad_right {s w} { format "%-${w}s" $s }
proc pad_left  {s w} { format "%${w}s" $s }

# print_report -- one campaign's name line, progress table and warnings.
# The name, table and legend go to stdout, so a multi-campaign run reads
# and redirects as one document; the warnings go to stderr, so 2>/dev/null
# drops them and leaves the tables.
proc print_report {analysis} {
    global verbose show_legend
    dict with analysis {}

    puts "Campaign:    $campaign_name"

    set headers {Segment Valid Profile "3+★ " Reach "A/Reach " Email LinkedIn Facebook "Only ☎ " Sent Repl}

    # Compute column widths
    set ncols [llength $headers]
    set widths {}
    for {set i 0} {$i < $ncols} {incr i} {
        lappend widths [string length [lindex $headers $i]]
    }

    # Build data rows
    set data_rows {}

    # Grand totals
    set gt_v 0; set gt_p 0; set gt_s 0; set gt_re 0; set gt_a 0; set gt_e 0
    set gt_l 0; set gt_f 0; set gt_po 0; set gt_es 0; set gt_r 0

    foreach item $segment_counts {
        lassign $item label counts
        set v [dict get $counts valid]
        set p [dict get $counts profiled]
        set s [dict get $counts star3]
        set re [dict get $counts approachable]
        set a [dict get $counts approached_star3]
        set e [dict get $counts has_email]
        set l [dict get $counts has_linkedin]
        set f [dict get $counts has_facebook]
        set po [dict get $counts has_phone_only]
        set es [dict get $counts sent]
        set r [dict get $counts replied]

        set row [list $label $v \
            [fmt_cell $p $v] [fmt_cell $s $v] [fmt_cell $re $s] [fmt_cell $a $re] \
            [fmt_cell $e $s] [fmt_cell $l $s] [fmt_cell $f $s] \
            [fmt_cell $po $s] [fmt_cell $es $a] [fmt_cell $r $es]]
        lappend data_rows $row

        incr gt_v $v; incr gt_p $p; incr gt_s $s; incr gt_re $re; incr gt_a $a
        incr gt_e $e; incr gt_l $l; incr gt_f $f
        incr gt_po $po; incr gt_es $es; incr gt_r $r
    }

    # TOTAL row
    set total_row [list TOTAL $gt_v \
        [fmt_cell $gt_p $gt_v] [fmt_cell $gt_s $gt_v] [fmt_cell $gt_re $gt_s] \
        [fmt_cell $gt_a $gt_re] \
        [fmt_cell $gt_e $gt_s] [fmt_cell $gt_l $gt_s] [fmt_cell $gt_f $gt_s] \
        [fmt_cell $gt_po $gt_s] [fmt_cell $gt_es $gt_a] [fmt_cell $gt_r $gt_es]]
    lappend data_rows $total_row

    # Update column widths
    foreach row $data_rows {
        for {set i 0} {$i < $ncols} {incr i} {
            set cw [string length [lindex $row $i]]
            if {$cw > [lindex $widths $i]} {
                lset widths $i $cw
            }
        }
    }

    # Header row
    set parts {}
    for {set i 0} {$i < $ncols} {incr i} {
        set h [lindex $headers $i]
        set w [lindex $widths $i]
        if {$i == 0} {
            lappend parts [pad_right $h $w]
        } else {
            lappend parts [pad_left $h $w]
        }
    }
    puts "|[join $parts |]|"

    # Separator row
    set sparts {}
    for {set i 0} {$i < $ncols} {incr i} {
        set w [lindex $widths $i]
        if {$i == 0} {
            lappend sparts ":[string repeat - [expr {$w - 1}]]"
        } else {
            lappend sparts "[string repeat - [expr {$w - 1}]]:"
        }
    }
    puts "|[join $sparts |]|"

    # Data rows
    foreach row $data_rows {
        set parts {}
        for {set i 0} {$i < $ncols} {incr i} {
            set cell [lindex $row $i]
            set w [lindex $widths $i]
            if {$i == 0} {
                lappend parts [pad_right $cell $w]
            } else {
                lappend parts [pad_left $cell $w]
            }
        }
        puts "|[join $parts |]|"
    }

    if {$show_legend} {
        puts "\nColumn legend  (each cell is a count; the % is the share of the denominator named)"
        puts "  Valid     Contacts not excluded. Denominator for Profile and 3+★."
        puts "  Profile   Profiled or beyond, as % of Valid."
        puts "  3+★       Rated 3 stars or higher — the qualified pool. Denominator for Reach,"
        puts "            Email, LinkedIn, Facebook and Only ☎."
        puts "  Reach     Approachable: 3+★ holding at least one channel the campaign declares,"
        puts "            as % of 3+★. The gap to 3+★ is the no-channel backlog — recorded"
        puts "            reality, not an error; those contacts sit outside every denominator"
        puts "            below until a channel is found."
        puts "  A/Reach   Approached, as % of Reach — 100% means everyone approachable was."
        puts "  Email     Has an email address, as % of 3+★."
        puts "  LinkedIn  Has a LinkedIn profile, as % of 3+★."
        puts "  Facebook  Has a Facebook profile, as % of 3+★."
        puts "  Only ☎    Reachable by phone only (no email or social), as % of 3+★."
        puts "  Sent      Sent on any channel (state SENT or beyond), as % of A/Reach."
        puts "  Repl      Replied on any channel; the % is the REPLY RATE = replies ÷ sent."
        puts "            This is the campaign's key conversion metric."
    } else {
        puts "\nRun with --legend to see column definitions."
    }

    # --- Warnings and validation ---
    set warn_result [spar::build_warnings $all_contacts $cdata]
    set warn_messages [dict get $warn_result messages]
    set val_issues   [dict get $warn_result validation_issues]

    # Per-contact validation warnings are the trailing block of `messages`
    # (build_warnings appends them last, after the sender-block and duplicate
    # warnings). Split them off: the head warnings carry locations that don't
    # collapse, so they print verbatim; the per-contact ones group by problem.
    set nval [llength $val_issues]
    set head_messages [lrange $warn_messages 0 end-$nval]

    if {[llength $head_messages] > 0 || $nval > 0} {
        puts stderr "\n## Warnings\n"
        foreach msg $head_messages {
            puts stderr "- $msg"
        }

        # Group the per-contact issues by problem text (carrying its severity),
        # then by segment, so every segment sharing a problem lands on one line:
        #   [WARNING] <problem>: segA (3), segB (9)
        # --verbose expands each segment to its member names.
        set order {}          ;# problem texts, first-seen order
        set severity_of {}    ;# problem -> severity
        set by_segment {}     ;# problem -> (segment -> list of member names)
        foreach issue $val_issues {
            set m [dict get $issue message]
            if {![dict exists $severity_of $m]} {
                lappend order $m
                dict set severity_of $m [dict get $issue severity]
                dict set by_segment $m {}
            }
            dict update by_segment $m segs {
                dict lappend segs [dict get $issue segment] [dict get $issue contact]
            }
        }
        foreach m $order {
            set sev [string toupper [dict get $severity_of $m]]
            set segs [dict get $by_segment $m]
            set seg_parts {}
            foreach {seg names} $segs {
                lappend seg_parts "$seg ([llength $names])"
            }
            puts stderr "- \[$sev\] $m: [join $seg_parts {, }]"
            if {$verbose} {
                foreach {seg names} $segs {
                    puts stderr "    - $seg ([llength $names]): [join $names {, }]"
                }
            }
        }

        if {$nval > 0 && !$verbose} {
            puts stderr "\n(pass --verbose / -v to list the members behind each warning)"
        }
    }
}

# One report per campaign named, in argument order, blank line between.
# A campaign that will not resolve costs its own report and the exit
# status, not the reports of the campaigns named beside it.
set status 0
set first 1
foreach spec $campaign_specs {
    lassign $spec campaign_file campaign_dir
    set analysis [analyse_campaign $State $campaign_file $campaign_dir]
    if {$analysis eq ""} { set status 1; continue }
    if {!$first} { puts "" }
    set first 0
    print_report $analysis
}
exit $status

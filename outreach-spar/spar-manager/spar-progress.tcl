#!/usr/bin/env tclsh9.0
# spar-progress.tcl — Campaign progress table and duplicate detection (CLI)
# Usage: tclsh9.0 spar-progress.tcl [campaign_dir_or_yaml] [--campaign=YAML] [--no-reply-check] [--json]
# Positional arg may be a directory or a campaign YAML file (directory derived from YAML path).
#
# --no-reply-check omits the T7 (reply-check) row from the transition list.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# --- Argument parsing ---
# Hand-rolled (not tcllib cmdline) for style consistency with
# spar-transition.tcl — see that file for the rationale.
set campaign_dir ""
set campaign_file ""
set json_mode 0
set skip_reply_check 0
foreach arg $argv {
    switch -glob -- $arg {
        --campaign=*     { set campaign_file [string range $arg 11 end] }
        --json           { set json_mode 1 }
        --no-reply-check { set skip_reply_check 1 }
        --legend         {}
        --*              { puts stderr "Unknown flag: $arg"; exit 1 }
        default          {
            if {[string match *.yaml $arg]} {
                set campaign_file [file normalize $arg]
                set campaign_dir [file dirname $campaign_file]
            } else {
                set campaign_dir $arg
            }
        }
    }
}

# --- Resolve campaign (discover YAML, load, build segment paths) ---
if {[catch {set rc [spar::resolve_campaign $campaign_file $campaign_dir]} err]} {
    puts stderr $err
    exit 1
}
set campaign_dir    [dict get $rc campaign_dir]
set yaml_path       [dict get $rc yaml_path]
set cdata           [dict get $rc cdata]
set campaign_name   [dict get $rc campaign_name]
set primary_channel [dict get $rc primary_channel]
set min_star        [dict get $rc min_star]
set segment_paths   [dict get $rc segment_paths]

# --- Classify all segments and collect counts ---
# One State for the whole CLI run — its lifetime matches this script's.
set State [spar::State new]
set all_contacts {}
set segment_counts {}   ;# list of {label counts_dict}

foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {
        # Cheap classify, then refine — progress_counts reads email_sent /
        # email_replied which are placeholder-zero on cheap output. The
        # cache means refine_segment shares parses with any later
        # transition_eligible calls in this script.
        set classified [$State refine_segment [$State classify_segment $seg_dir]]
    } err]} {
        puts stderr "Error in $label: $err"
        continue
    }
    lappend all_contacts {*}$classified
    lappend segment_counts [list $label [spar::progress_counts $classified]]
}

# --- JSON mode ---
if {$json_mode} {
    package require json::write

    proc _counts_tree {c} {
        dict with c {}
        ::json::write object \
            valid     $valid \
            profiled  $profiled \
            qualified [::json::write object \
                count     $star3 \
                approached $approached_star3 \
                email     [::json::write object \
                    count     $has_email \
                    approached [::json::write object \
                        count $approached_email \
                        sent  [::json::write object \
                            count   $email_sent \
                            replied $email_replied]]] \
                linkedin  $has_linkedin \
                facebook  $has_facebook \
                phone_only $has_phone_only]
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
    set totals [dict create valid 0 profiled 0 star3 0 approached_star3 0 \
        has_email 0 approached_email 0 has_linkedin 0 has_facebook 0 \
        has_phone_only 0 email_sent 0 email_replied 0]
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
puts stderr "Campaign:    $campaign_name"

# --- Format progress table ---
proc fmt_cell {count denom} {
    if {$denom > 0} {
        set pct [expr {$count * 100.0 / $denom}]
        return [format "%3d %3.0f%%" $count $pct]
    } else {
        return [format "%3d    -" $count]
    }
}

set headers {Segment Valid Profile "3+★ " "A/3+★ " Email A/Eml LinkedIn Facebook "Only ☎ " "✉ Sent" "✉ Repl"}

# Compute column widths
set ncols [llength $headers]
set widths {}
for {set i 0} {$i < $ncols} {incr i} {
    lappend widths [string length [lindex $headers $i]]
}

# Build data rows
set data_rows {}

# Grand totals
set gt_v 0; set gt_p 0; set gt_s 0; set gt_a 0; set gt_e 0; set gt_ae 0
set gt_l 0; set gt_f 0; set gt_po 0; set gt_es 0; set gt_r 0

foreach item $segment_counts {
    lassign $item label counts
    set v [dict get $counts valid]
    set p [dict get $counts profiled]
    set s [dict get $counts star3]
    set a [dict get $counts approached_star3]
    set e [dict get $counts has_email]
    set ae [dict get $counts approached_email]
    set l [dict get $counts has_linkedin]
    set f [dict get $counts has_facebook]
    set po [dict get $counts has_phone_only]
    set es [dict get $counts email_sent]
    set r [dict get $counts email_replied]

    set row [list $label $v \
        [fmt_cell $p $v] [fmt_cell $s $v] [fmt_cell $a $s] \
        [fmt_cell $e $s] [fmt_cell $ae $e] [fmt_cell $l $s] \
        [fmt_cell $f $s] [fmt_cell $po $s] [fmt_cell $es $ae] \
        [fmt_cell $r $es]]
    lappend data_rows $row

    incr gt_v $v; incr gt_p $p; incr gt_s $s; incr gt_a $a
    incr gt_e $e; incr gt_ae $ae; incr gt_l $l; incr gt_f $f
    incr gt_po $po; incr gt_es $es; incr gt_r $r
}

# TOTAL row
set total_row [list TOTAL $gt_v \
    [fmt_cell $gt_p $gt_v] [fmt_cell $gt_s $gt_v] [fmt_cell $gt_a $gt_s] \
    [fmt_cell $gt_e $gt_s] [fmt_cell $gt_ae $gt_e] [fmt_cell $gt_l $gt_s] \
    [fmt_cell $gt_f $gt_s] [fmt_cell $gt_po $gt_s] [fmt_cell $gt_es $gt_ae] \
    [fmt_cell $gt_r $gt_es]]
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

# Print table
proc pad_right {s w} { format "%-${w}s" $s }
proc pad_left  {s w} { format "%${w}s" $s }

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

puts "\nRun with --legend to see column definitions."

# --- Warnings and validation ---
set warn_result [spar::build_warnings $all_contacts $cdata]
set warn_messages [dict get $warn_result messages]
if {[llength $warn_messages] > 0} {
    puts "\n## Warnings\n"
    foreach msg $warn_messages {
        puts "- $msg"
    }
}

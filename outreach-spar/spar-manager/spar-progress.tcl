#!/usr/bin/env tclsh
# spar-progress.tcl — Campaign progress table and duplicate detection (CLI)
# Tcl replacement for: python3 ../bin/update-campaign.py --no-mailroom
# Usage: tclsh spar-progress.tcl [campaign_dir_or_yaml] [--campaign=YAML] [--no-mailroom] [--json]
# Positional arg may be a directory or a campaign YAML file (directory derived from YAML path).

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# --- Argument parsing ---
set campaign_dir ""
set campaign_file ""
set json_mode 0
foreach arg $argv {
    switch -glob -- $arg {
        --campaign=*  { set campaign_file [string range $arg 11 end] }
        --json        { set json_mode 1 }
        --no-mailroom {}
        --legend      {}
        --*           { puts stderr "Unknown flag: $arg"; exit 1 }
        default       {
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
if {$campaign_dir eq ""} {
    set campaign_dir "."
}
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
set min_star 0

if {$yaml_path ne "" && [file exists $yaml_path]} {
    set cdata [spar::load_campaign $yaml_path]
    set campaign_name [spar::dict_get_default $cdata campaign [file tail $yaml_path]]
    if {[dict exists $cdata filter]} {
        set min_star [spar::dict_get_default [dict get $cdata filter] min_star 0]
    }
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

# --- Classify all segments and collect counts ---
set all_contacts {}
set segment_counts {}   ;# list of {label counts_dict}

foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {
        set classified [spar::classify_segment $seg_dir]
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

    proc _cn {n d} {
        ::json::write object count $n pct [expr {$d > 0 ? [format "%.1f" [expr {$n*100.0/$d}]] : "null"}]
    }
    proc _counts_tree {c} {
        dict with c {}
        ::json::write object \
            valid [::json::write string $valid] \
            profiled [_cn $profiled $valid] \
            qualified [::json::write object \
                count [::json::write string $star3] \
                pct [expr {$valid>0 ? [format "%.1f" [expr {$star3*100.0/$valid}]] : "null"}] \
                approached [_cn $approached_star3 $star3] \
                email [::json::write object \
                    count [::json::write string $has_email] \
                    pct [expr {$star3>0 ? [format "%.1f" [expr {$has_email*100.0/$star3}]] : "null"}] \
                    approached [::json::write object \
                        count [::json::write string $approached_email] \
                        pct [expr {$has_email>0 ? [format "%.1f" [expr {$approached_email*100.0/$has_email}]] : "null"}] \
                        sent [::json::write object \
                            count [::json::write string $email_sent] \
                            pct [expr {$approached_email>0 ? [format "%.1f" [expr {$email_sent*100.0/$approached_email}]] : "null"}] \
                            replied [_cn $email_replied $email_sent]]]] \
                linkedin [_cn $has_linkedin $star3] \
                facebook [_cn $has_facebook $star3] \
                phone_only [_cn $has_phone_only $star3]]
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
        set v [dict get $progress_dict validation]
        set nerr 0; set nwarn 0
        foreach i $v { if {[dict get $i severity] eq "error"} {incr nerr} else {incr nwarn} }

        ::json::write object \
            campaign [::json::write string [dict get $progress_dict campaign]] \
            min_star [dict get $progress_dict min_star] \
            segments [::json::write array {*}$seg_list] \
            totals [_counts_tree [dict get $progress_dict totals]] \
            warnings [::json::write object \
                duplicate_to [llength [dict get $w duplicate_to]] \
                duplicate_name [llength [dict get $w duplicate_name]] \
                duplicate_email [llength [dict get $w duplicate_email]] \
                identical_subject [llength [dict get $w identical_subject]]] \
            validation [::json::write object errors $nerr warnings $nwarn] \
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
    set transition_defs {
        T1 "Sweep \u2192 Profile"   T2 "Profile \u2192 Approach"
        T3 "Approach \u2192 Send"   T4 "Send \u2192 Reply"
        T5 "Flag invalid"           T6 "Stale \u2192 Re-profile"
        T7 "Re-profile \u2192 Re-approach" T8 "LinkedIn \u2192 Email follow-up"
    }
    set transitions {}
    dict for {tid tlabel} $transition_defs {
        set tasks [spar::transition_eligible $all_contacts $tid]
        lappend transitions [dict create label "$tid: $tlabel" count [llength $tasks] tasks $tasks]
    }
    puts [progress_to_json [dict create campaign $campaign_name min_star $min_star \
        segments $seg_results totals $totals \
        warnings [spar::detect_duplicates $all_contacts] \
        validation [spar::validate_campaign $all_contacts] \
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

# --- Duplicate detection ---
set dups [spar::detect_duplicates $all_contacts]

# Duplicate To: addresses
set dup_to [dict get $dups duplicate_to]
if {[llength $dup_to] > 0} {
    puts "\n## Duplicate recipients\n"
    puts "Same To: address in multiple approach files.\n"
    foreach item $dup_to {
        set addr [dict get $item address]
        set files [dict get $item files]
        puts "- **$addr**"
        foreach f $files {
            lassign $f seg filename
            puts "  - $seg/$filename"
        }
    }
}

# Duplicate names
set dup_name [dict get $dups duplicate_name]
if {[llength $dup_name] > 0} {
    puts "\n## Duplicate contacts by name\n"
    puts "Same person in multiple segments.\n"
    foreach item $dup_name {
        set entries [dict get $item entries]
        # Display using the first entry's original name
        set display_name [lindex [lindex $entries 0] 1]
        puts "- **$display_name**"
        foreach entry $entries {
            lassign $entry seg cname org email
            set email_str ""
            if {$email ne ""} { set email_str "  <$email>" }
            puts "  - \[$seg\] $org$email_str"
        }
    }
}

# Duplicate emails
set dup_email [dict get $dups duplicate_email]
if {[llength $dup_email] > 0} {
    puts "\n## Duplicate contacts by email\n"
    puts "Same email in multiple segments.\n"
    foreach item $dup_email {
        set addr [dict get $item email]
        set entries [dict get $item entries]
        puts "- **$addr**"
        foreach entry $entries {
            lassign $entry seg cname org
            puts "  - \[$seg\] $cname — $org"
        }
    }
}

# Identical subjects
set dup_subject [dict get $dups identical_subject]
if {[llength $dup_subject] > 0} {
    puts "\n## Identical subject lines in unsent approaches\n"
    foreach item $dup_subject {
        set subj [dict get $item subject]
        set files [dict get $item files]
        puts "- **Subject:** $subj"
        foreach f $files {
            lassign $f seg filename
            puts "  - $seg/$filename"
        }
    }
}

#!/usr/bin/env tclsh
# spar-progress.tcl — Campaign progress table and duplicate detection (CLI)
# Tcl replacement for: python3 ../bin/update-campaign.py --no-mailroom
# Usage: tclsh spar-progress.tcl [campaign_dir] [--campaign=YAML] [--no-mailroom]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# --- Argument parsing ---
set campaign_dir "."
set campaign_file ""

foreach arg $argv {
    switch -glob -- $arg {
        --campaign=*  { set campaign_file [string range $arg 11 end] }
        --no-mailroom {}
        --legend      {}
        --*           { puts stderr "Unknown flag: $arg"; exit 1 }
        default       { set campaign_dir $arg }
    }
}

set campaign_dir [file normalize $campaign_dir]

# --- Discover campaign YAML ---
if {$campaign_file ne ""} {
    set yaml_path [file normalize $campaign_file]
} else {
    # Auto-discover: campaign.yaml or last campaign*.yaml by sort order
    set yaml_path [file join $campaign_dir campaign.yaml]
    if {![file exists $yaml_path]} {
        set candidates [lsort [glob -nocomplain [file join $campaign_dir campaign*.yaml]]]
        if {[llength $candidates] > 0} {
            set yaml_path [lindex $candidates end]
        } else {
            set yaml_path ""
        }
    }
}

# --- Load campaign YAML ---
set segments_list {}
set skip_set {}

if {$yaml_path ne "" && [file exists $yaml_path]} {
    set cdata [spar::load_campaign $yaml_path]
    puts stderr "Campaign:    [spar::dict_get_default $cdata campaign [file tail $yaml_path]]"

    # Extract segments list
    if {[dict exists $cdata segments]} {
        set segments_list [dict get $cdata segments]
    }

    # Extract skip_segments
    if {[dict exists $cdata skip_segments]} {
        foreach s [dict get $cdata skip_segments] {
            lappend skip_set $s
        }
    }
} else {
    puts stderr "Warning: no campaign YAML found; falling back to directory roster scan."
    # Discover all directories with roster.tsv
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
    foreach c $classified {
        lappend all_contacts $c
    }
    set counts [spar::progress_counts $classified]
    lappend segment_counts [list $label $counts]
}

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

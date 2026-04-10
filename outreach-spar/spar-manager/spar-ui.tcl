#!/usr/bin/env wish9.0
# SPAR Campaign Manager — Live UI

package require Tk

# Accept campaign directory as argument, default to current directory
set campaign_dir [expr {[llength $argv] > 0 ? [lindex $argv 0] : "."}]
set campaign_dir [file normalize $campaign_dir]

# Source backend libraries
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# Pre-widget startup check: if no campaign YAML exists, print a helpful
# message and exit before spawning any Tk windows.
proc _find_campaign_yaml {dir} {
    set p [file join $dir campaign.yaml]
    if {[file exists $p]} { return $p }
    set cs [lsort [glob -nocomplain [file join $dir campaign*.yaml]]]
    if {[llength $cs]} { return [lindex $cs end] }
    return ""
}
if {[_find_campaign_yaml $campaign_dir] eq ""} {
    puts stderr "spar-ui: no campaign YAML found in $campaign_dir"
    puts stderr "Usage: wish9.0 spar-ui.tcl <campaign-dir>"
    puts stderr "  campaign-dir must contain campaign.yaml or campaign*.yaml"
    exit 1
}

# ============================================================
# Load campaign data
# ============================================================

proc discover_campaign_yaml {campaign_dir} {
    set yaml_path [file join $campaign_dir campaign.yaml]
    if {[file exists $yaml_path]} {
        return $yaml_path
    }
    set candidates [lsort [glob -nocomplain [file join $campaign_dir campaign*.yaml]]]
    if {[llength $candidates] > 0} {
        return [lindex $candidates end]
    }
    return ""
}

proc load_campaign_data {} {
    global campaign_dir campaign_name sender_text method_ref filter_desc
    global segments segments_data warnings transitions
    global cdata yaml_path all_contacts segment_order skip_set

    set yaml_path [discover_campaign_yaml $campaign_dir]
    if {$yaml_path eq ""} {
        tk_messageBox -icon error -title "No Campaign" \
            -message "No campaign YAML found in:\n$campaign_dir"
        set campaign_name "(no campaign)"
        set sender_text ""
        set method_ref ""
        set filter_desc ""
        set segments {}
        set warnings {}
        set transitions {}
        set all_contacts {}
        set segment_order {}
        return
    }

    if {[catch {set cdata [spar::load_campaign $yaml_path]} err]} {
        tk_messageBox -icon error -title "Campaign Load Error" \
            -message "Error loading campaign:\n$err"
        set campaign_name "(error)"
        set sender_text ""
        set method_ref ""
        set filter_desc ""
        set segments {}
        set warnings {}
        set transitions {}
        set all_contacts {}
        set segment_order {}
        return
    }

    # --- Campaign config values ---
    set campaign_name [spar::dict_get_default $cdata campaign [file tail $yaml_path]]

    # Sender
    set sender_parts {}
    if {[dict exists $cdata sender]} {
        set sender_d [dict get $cdata sender]
        set s_name [spar::dict_get_default $sender_d name ""]
        set s_role [spar::dict_get_default $sender_d role ""]
        set s_email [spar::dict_get_default $sender_d email ""]
        if {$s_name ne ""} { lappend sender_parts $s_name }
        if {$s_role ne ""} { lappend sender_parts $s_role }
        if {$s_email ne ""} { lappend sender_parts "($s_email)" }
    }
    set sender_text [join $sender_parts ", "]

    # Method
    set method_ref [spar::dict_get_default $cdata method ""]

    # Filter
    set filter_desc ""
    if {[dict exists $cdata filter]} {
        set filt [dict get $cdata filter]
        set filter_parts {}
        if {[catch {
            dict for {k v} $filt {
                lappend filter_parts "${k}=${v}"
            }
        }]} {
            set filter_desc "$filt"
        } else {
            set filter_desc [join $filter_parts "  "]
        }
    }

    # --- Discover segments ---
    set segments_list {}
    if {[dict exists $cdata segments]} {
        set segments_list [dict get $cdata segments]
    }
    set skip_set {}
    if {[dict exists $cdata skip_segments]} {
        foreach s [dict get $cdata skip_segments] {
            lappend skip_set $s
        }
    }

    # If no segments in YAML, fall back to directory scan
    if {[llength $segments_list] == 0} {
        foreach child [lsort [glob -nocomplain [file join $campaign_dir *]]] {
            if {[file isdirectory $child] && [file exists [file join $child roster.tsv]]} {
                lappend segments_list [file tail $child]
            }
        }
    }

    # Build segment paths (include skipped segments so they appear muted)
    set segment_order {}
    set segment_paths {}
    foreach seg $segments_list {
        set seg_dir [file join $campaign_dir $seg]
        if {[file isdirectory $seg_dir] && [file exists [file join $seg_dir roster.tsv]]} {
            lappend segment_order $seg
            lappend segment_paths [list $seg $seg_dir]
        }
    }

    # --- Classify all segments ---
    set all_contacts {}
    set segments {}

    foreach item $segment_paths {
        lassign $item label seg_dir
        set is_active [expr {$label ni $skip_set}]

        if {[catch {
            set classified [spar::classify_segment $seg_dir]
        } err]} {
            # On error, add a zero-count row
            set zero_data [list 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {}]
            lappend segments [list $label $is_active $zero_data]
            continue
        }

        if {$is_active} {
            foreach c $classified {
                lappend all_contacts $c
            }
        }

        set counts [spar::progress_counts $classified]

        # Build the raw_data list: {count pct count pct ...} matching mock-ui format
        # Column order: Valid, Profile, 3+star, A/3+star, Email, A/Eml, LinkedIn, Facebook, Only-phone, Sent, Repl
        set v [dict get $counts valid]
        set p [dict get $counts profiled]
        set s3 [dict get $counts star3]
        set a3 [dict get $counts approached_star3]
        set e [dict get $counts has_email]
        set ae [dict get $counts approached_email]
        set l [dict get $counts has_linkedin]
        set f [dict get $counts has_facebook]
        set po [dict get $counts has_phone_only]
        set es [dict get $counts email_sent]
        set er [dict get $counts email_replied]

        set raw_data [list \
            $v {} \
            $p [format_pct $p $v] \
            $s3 [format_pct $s3 $v] \
            $a3 [format_pct $a3 $s3] \
            $e [format_pct $e $s3] \
            $ae [format_pct $ae $e] \
            $l [format_pct $l $s3] \
            $f [format_pct $f $s3] \
            $po [format_pct $po $s3] \
            $es [format_pct $es $ae] \
            $er [format_pct $er $es]]

        lappend segments [list $label $is_active $raw_data]
    }

    # --- Warnings ---
    set warnings [build_warnings $all_contacts]

    # --- Transitions ---
    set transitions [build_transitions $all_contacts]
}

proc format_pct {num denom} {
    if {$denom == 0} {
        return "-"
    }
    set pct [expr {$num * 100 / $denom}]
    return "${pct}%"
}

proc build_warnings {all_contacts} {
    set result {}

    # Duplicate detection
    if {[llength $all_contacts] > 0} {
        set dups [spar::detect_duplicates $all_contacts]

        # Duplicate To
        foreach item [dict get $dups duplicate_to] {
            set addr [dict get $item address]
            set files [dict get $item files]
            set locs {}
            foreach f $files {
                lassign $f seg filename
                lappend locs "$seg/$filename"
            }
            lappend result "Duplicate To: $addr in [join $locs {, }]"
        }

        # Duplicate name
        foreach item [dict get $dups duplicate_name] {
            set entries [dict get $item entries]
            set display_name [lindex [lindex $entries 0] 1]
            set parts {}
            foreach entry $entries {
                lassign $entry seg cname org email
                lappend parts "$seg ($org)"
            }
            lappend result "Duplicate name: $display_name in [join $parts { and }]"
        }

        # Duplicate email
        foreach item [dict get $dups duplicate_email] {
            set addr [dict get $item email]
            set entries [dict get $item entries]
            set parts {}
            foreach entry $entries {
                lassign $entry seg cname org
                lappend parts "$seg ($cname)"
            }
            lappend result "Duplicate email: $addr in [join $parts { and }]"
        }

        # Identical subject
        foreach item [dict get $dups identical_subject] {
            set subj [dict get $item subject]
            set files [dict get $item files]
            set locs {}
            foreach f $files {
                lassign $f seg filename
                lappend locs "$seg/$filename"
            }
            lappend result "Identical subject: \"$subj\" in [join $locs {, }]"
        }
    }

    # Validation
    if {[llength $all_contacts] > 0} {
        set issues [spar::validate_campaign $all_contacts]
        foreach issue $issues {
            set sev [dict get $issue severity]
            set seg [spar::dict_get_default $issue segment ""]
            set cname [spar::dict_get_default $issue contact_name ""]
            set msg [dict get $issue message]
            set prefix "\[[string toupper $sev]\]"
            if {$seg ne ""} { append prefix " $seg" }
            if {$cname ne ""} { append prefix " ($cname)" }
            lappend result "$prefix: $msg"
        }
    }

    return $result
}

proc build_transitions {all_contacts} {
    set labels {
        "Sweep \u2192 Profile"
        "Profile \u2192 Approach"
        "Approach \u2192 Send"
        "Send \u2192 Reply"
        "Flag invalid"
        "Stale \u2192 Re-profile"
        "Re-profile \u2192 Re-approach"
        "LinkedIn \u2192 Email follow-up"
    }
    set tids {T1 T2 T3 T4 T5 T6 T7 T8}

    set result {}
    for {set i 0} {$i < [llength $labels]} {incr i} {
        set label [lindex $labels $i]
        set tid [lindex $tids $i]

        set eligible [spar::transition_eligible $all_contacts $tid]
        set count [llength $eligible]

        set tasks {}
        foreach contact $eligible {
            set cname [dict get $contact contact_name]
            set org [dict get $contact organisation]
            set seg [dict get $contact segment]
            set tstate [dict get $contact task_state]
            set reason [dict get $contact reason]
            lappend tasks [list $cname $org $seg $tstate $reason]
        }

        lappend result [list $label $count $tasks]
    }

    return $result
}

# --- Load data ---
load_campaign_data

# ============================================================
# Colour palette
# ============================================================

set colours(hdr_bottom)  "#f8f9fa"
set colours(totals_bg)   "#e2e2e2"
set colours(muted_fg)    "#999999"

# ============================================================
# Window title
# ============================================================

wm title . "SPAR Campaign Manager \u2014 $campaign_name"

# ============================================================
# Main layout
# ============================================================

ttk::notebook .tabs
pack .tabs -fill both -expand 1

# Placeholder tab
ttk::frame .tabs.tab_old
.tabs add .tabs.tab_old -text "2026-03"
ttk::label .tabs.tab_old.lbl -text "(No data loaded)" -foreground #999
pack .tabs.tab_old.lbl -expand 1

# Active tab
ttk::frame .tabs.tab_current
.tabs add .tabs.tab_current -text [expr {[info exists campaign_name] && $campaign_name ne "" ? [string range $campaign_name 0 6] : "Current"}]
.tabs select .tabs.tab_current

# Paned window inside active tab
ttk::panedwindow .tabs.tab_current.pw -orient vertical
pack .tabs.tab_current.pw -fill both -expand 1

ttk::frame .tabs.tab_current.pw.campaign
.tabs.tab_current.pw add .tabs.tab_current.pw.campaign -weight 3

ttk::frame .tabs.tab_current.pw.transitions
.tabs.tab_current.pw add .tabs.tab_current.pw.transitions -weight 2

set cpanel .tabs.tab_current.pw.campaign
set tpanel .tabs.tab_current.pw.transitions

# ============================================================
# Zone 2: Campaign panel
# ============================================================

# --- 2.1 Config summary ---
ttk::labelframe ${cpanel}.config -text "Campaign Configuration"
pack ${cpanel}.config -fill x -padx 8 -pady {6 2}

set cf ${cpanel}.config
ttk::label ${cf}.l1 -text "Campaign:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v1 -text $campaign_name
ttk::label ${cf}.l2 -text "Sender:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v2 -text $sender_text
ttk::label ${cf}.l3 -text "Method:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v3 -text $method_ref
ttk::label ${cf}.l4 -text "Filter:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v4 -text $filter_desc

grid ${cf}.l1 ${cf}.v1 -sticky w -padx {6 4} -pady 1
grid ${cf}.l2 ${cf}.v2 -sticky w -padx {6 4} -pady 1
grid ${cf}.l3 ${cf}.v3 -sticky w -padx {6 4} -pady 1
grid ${cf}.l4 ${cf}.v4 -sticky w -padx {6 4} -pady 1

# Toolbar: Check Email, Refresh, Legend, Select All/None
ttk::frame ${cpanel}.toolbar
pack ${cpanel}.toolbar -fill x -padx 8 -pady {2 2}

ttk::button ${cpanel}.toolbar.checkemail -text "Check Email" -command do_check_email
pack ${cpanel}.toolbar.checkemail -side right

ttk::button ${cpanel}.toolbar.refresh -text "Refresh" -command do_refresh
pack ${cpanel}.toolbar.refresh -side right -padx {0 4}

ttk::button ${cpanel}.toolbar.legend -text "Legend" -command show_legend_window
pack ${cpanel}.toolbar.legend -side right -padx {0 4}

ttk::button ${cpanel}.toolbar.selall -text "All" -width 4 -command {
    global seg_checked ptree
    foreach seg [array names ::seg_checked] {
        set ::seg_checked($seg) 1
        $ptree item $seg -text "\u2611  $seg"
    }
    recalc_totals
}
pack ${cpanel}.toolbar.selall -side left

ttk::button ${cpanel}.toolbar.selnone -text "None" -width 4 -command {
    global seg_checked ptree
    foreach seg [array names ::seg_checked] {
        set ::seg_checked($seg) 0
        $ptree item $seg -text "\u2610  $seg"
    }
    recalc_totals
}
pack ${cpanel}.toolbar.selnone -side left -padx {2 0}

proc do_check_email {} {
    global script_dir
    set email_lib [file join $script_dir spar-email.tcl]
    if {[file exists $email_lib]} {
        if {[catch {source $email_lib} err]} {
            log_message "Error loading spar-email.tcl: $err"
            return
        }
        if {[catch {spar::check_replies_mailroom} err]} {
            log_message "Email check error: $err"
        } else {
            log_message "Email check completed."
        }
        do_refresh
    } else {
        log_message "Email checking not available (spar-email.tcl not found)."
    }
}

proc do_refresh {} {
    global campaign_name sender_text method_ref filter_desc
    global segments warnings transitions
    global cf cpanel wframe tpanel

    # Reload all data
    load_campaign_data

    # Update config labels
    ${cf}.v1 configure -text $campaign_name
    ${cf}.v2 configure -text $sender_text
    ${cf}.v3 configure -text $method_ref
    ${cf}.v4 configure -text $filter_desc

    # Update window title
    wm title . "SPAR Campaign Manager \u2014 $campaign_name"

    # Rebuild progress table
    rebuild_progress_table

    # Rebuild warnings
    rebuild_warnings

    # Rebuild transitions
    rebuild_transitions

    log_message "Refreshed campaign data."
}

# Legend window — identical to mock-ui.tcl
proc show_legend_window {} {
    if {[winfo exists .legendwin]} {
        wm deiconify .legendwin
        raise .legendwin
        return
    }
    toplevel .legendwin
    wm title .legendwin "Column Denominator Tree"
    canvas .legendwin.c -width 750 -height 220 -highlightthickness 0
    pack .legendwin.c -fill both -expand 1
    bind .legendwin.c <Configure> {draw_legend .legendwin.c}
    wm protocol .legendwin WM_DELETE_WINDOW {wm withdraw .legendwin}
}

proc draw_legend {c} {
    $c delete all
    set bfont "TkDefaultFont 9 bold"
    set afont "TkDefaultFont 8"
    set line_colour "#888888"
    set acolour "#666666"

    set w [winfo width $c]
    if {$w < 10} {set w 700}

    set dy 34
    set y0 14
    set y1 [expr {$y0 + $dy}]
    set y2 [expr {$y0 + 2*$dy}]
    set y3 [expr {$y0 + 3*$dy}]
    set y4 [expr {$y0 + 4*$dy}]
    set y5 [expr {$y0 + 5*$dy}]

    set margin 50
    set span [expr {$w - 2*$margin}]
    set x_valid    [expr {$w / 2}]
    set x_profile  [expr {$margin + $span * 0.0}]
    set x_star     [expr {$margin + $span * 0.50}]
    set x_astar    [expr {$margin + $span * 0.10}]
    set x_email    [expr {$margin + $span * 0.30}]
    set x_linkedin [expr {$margin + $span * 0.55}]
    set x_facebook [expr {$margin + $span * 0.75}]
    set x_phone    [expr {$margin + $span * 0.95}]
    set x_aeml     [expr {$margin + $span * 0.40}]
    set x_sent     [expr {$margin + $span * 0.50}]
    set x_repl     [expr {$margin + $span * 0.60}]

    set nodes [list \
        "Valid"       ""         $x_valid    $y0 \
        "Profile"     "/ Valid"  $x_profile  $y1 \
        "3+\u2605"    "/ Valid"  $x_star     $y1 \
        "A/3+\u2605"  "/ 3+\u2605" $x_astar $y2 \
        "Email"       "/ 3+\u2605" $x_email $y2 \
        "LinkedIn"    "/ 3+\u2605" $x_linkedin $y2 \
        "Facebook"    "/ 3+\u2605" $x_facebook $y2 \
        "Only \u260e" "/ 3+\u2605" $x_phone $y2 \
        "A/Eml"       "/ Email" $x_aeml     $y3 \
        "\u2709 Sent" "/ A/Eml" $x_sent     $y4 \
        "\u2709 Repl" "/ Sent"  $x_repl     $y5 \
    ]

    foreach {lbl denom x y} $nodes {
        $c create text $x $y -text $lbl -font $bfont -anchor center
        if {$denom ne ""} {
            $c create text $x [expr {$y + 11}] -text $denom -font $afont -fill $acolour -anchor center
        }
    }

    set g 14
    set gt 9
    $c create line $x_valid [expr {$y0+$gt}]  $x_profile [expr {$y1-$gt}] -fill $line_colour
    $c create line $x_valid [expr {$y0+$gt}]  $x_star    [expr {$y1-$gt}] -fill $line_colour
    foreach xc [list $x_astar $x_email $x_linkedin $x_facebook $x_phone] {
        $c create line $x_star [expr {$y1+$g}] $xc [expr {$y2-$gt}] -fill $line_colour
    }
    $c create line $x_email [expr {$y2+$g}] $x_aeml [expr {$y3-$gt}] -fill $line_colour
    $c create line $x_aeml  [expr {$y3+$g}] $x_sent [expr {$y4-$gt}] -fill $line_colour
    $c create line $x_sent  [expr {$y4+$g}] $x_repl [expr {$y5-$gt}] -fill $line_colour
}

# --- 2.2 Progress table ---
ttk::labelframe ${cpanel}.progress -text "Progress"
pack ${cpanel}.progress -fill both -expand 1 -padx 8 -pady {2 2}

# Treeview column definitions: id, heading, anchor
# Each data column combines count + pct into one cell ("123 45%")
# Widths are computed from content after population, not hardcoded.
set ptree_cols {
    valid    "Valid"       e
    profiled "Profile"    e
    star3    "3+\u2605"   e
    astar    "A/3+\u2605" e
    email    "Email"      e
    aeml     "A/Eml"      e
    linkedin "LinkedIn"   e
    facebook "Facebook"   e
    phone    "Only \u260e" e
    sent     "\u2709 Sent" e
    repl     "\u2709 Repl" e
}

# Extract just column IDs for -columns
set ptree_col_ids {}
foreach {id heading anchor} $ptree_cols { lappend ptree_col_ids $id }

set ptree ${cpanel}.progress.tree
ttk::treeview $ptree \
    -columns $ptree_col_ids \
    -show {tree headings} \
    -selectmode none \
    -yscrollcommand [list ${cpanel}.progress.vsb set]

ttk::scrollbar ${cpanel}.progress.vsb -orient vertical -command [list $ptree yview]

grid $ptree                 -in ${cpanel}.progress -row 0 -column 0 -sticky nsew -padx {2 0} -pady {2 2}
grid ${cpanel}.progress.vsb -in ${cpanel}.progress -row 0 -column 1 -sticky ns   -pady {2 2}
grid rowconfigure    ${cpanel}.progress 0 -weight 1
grid columnconfigure ${cpanel}.progress 0 -weight 1

# Tree column (#0): segment name — stretches to fill extra window space
$ptree column #0 -stretch 1 -anchor w -minwidth 120

# Data columns: fixed width (computed from content), never stretch
foreach {id heading anchor} $ptree_cols {
    $ptree heading $id -text $heading -anchor $anchor
    $ptree column  $id -stretch 0 -anchor $anchor -minwidth 10
}

# Tags: muted for skip segments, totals row styling
$ptree tag configure muted   -foreground $::colours(muted_fg)
$ptree tag configure totals  -font "TkDefaultFont 9 bold" \
    -background $::colours(totals_bg)

# Denominator parent col-id for percentage (empty = no pct)
set denom_parent {
    valid    {}
    profiled valid
    star3    valid
    astar    star3
    email    star3
    aeml     email
    linkedin star3
    facebook star3
    phone    star3
    sent     aeml
    repl     sent
}

# Per-segment raw counts, keyed by segment name
set seg_counts [dict create]
array set seg_checked {}

# Format a single cell: "123 45%" or just "123" when no denominator
proc fmt_cell {count denom} {
    if {$denom eq "" || $denom == 0} { return $count }
    return [format "%d %d%%" $count [expr {$count * 100 / $denom}]]
}

proc populate_progress_tree {} {
    global ptree ptree_col_ids ptree_cols segments seg_counts seg_checked denom_parent

    $ptree delete [$ptree children {}]
    set seg_counts [dict create]
    array unset seg_checked

    foreach seg_entry $segments {
        lassign $seg_entry seg_name is_campaign raw_data
        set tags {}
        if {!$is_campaign} { lappend tags muted }

        # raw_data is flat list: count {} count pct count pct ...
        # ci 0 = valid (no pct), ci 1..10 = count pct pairs
        set counts {}
        for {set ci 0} {$ci < 11} {incr ci} {
            lappend counts [lindex $raw_data [expr {$ci * 2}]]
        }

        # Build values list for treeview columns (formatted cells)
        set values {}
        set ci 0
        foreach {id heading anchor} $ptree_cols {
            set count [lindex $counts $ci]
            set pid [dict get $denom_parent $id]
            if {$pid eq ""} {
                lappend values $count
            } else {
                set pidx [lsearch $ptree_col_ids $pid]
                set denom [lindex $counts $pidx]
                lappend values [fmt_cell $count $denom]
            }
            incr ci
        }

        set cb [expr {$is_campaign ? "\u2611" : "  "}]
        $ptree insert {} end -id $seg_name -text "$cb  $seg_name" \
            -values $values -tags $tags

        if {$is_campaign} {
            set seg_checked($seg_name) 1
            set ci 0
            foreach id $ptree_col_ids {
                dict set seg_counts $seg_name $id [lindex $counts $ci]
                incr ci
            }
        }
    }

    # Insert totals row (updated by recalc_totals)
    $ptree insert {} end -id __totals__ -text "  TOTAL" \
        -values [lrepeat [llength $ptree_col_ids] ""] -tags totals

    recalc_totals
    after idle autosize_progress_tree
}

# autosize_progress_tree -- measure content and set column widths.
# Called after idle so row geometry is finalised.
proc autosize_progress_tree {} {
    global ptree ptree_col_ids ptree_cols

    set font TkDefaultFont
    set pad 12   ;# horizontal cell padding (pixels)

    # Column #0: measure heading + all row texts
    set max0 [font measure $font "Segment"]
    foreach item [$ptree children {}] {
        set txt [$ptree item $item -text]
        set w [font measure $font $txt]
        if {$w > $max0} { set max0 $w }
    }
    $ptree column #0 -minwidth [expr {$max0 + $pad}]

    # Data columns: measure heading + all cell values
    set ci 0
    foreach {id heading anchor} $ptree_cols {
        set maxw [font measure $font $heading]
        foreach item [$ptree children {}] {
            set val [lindex [$ptree item $item -values] $ci]
            set w [font measure $font $val]
            if {$w > $maxw} { set maxw $w }
        }
        set colw [expr {$maxw + $pad}]
        $ptree column $id -width $colw -minwidth $colw
        incr ci
    }
}

proc recalc_totals {} {
    global ptree ptree_col_ids ptree_cols seg_counts seg_checked denom_parent

    # Sum counts for checked segments
    set sums [dict create]
    foreach id $ptree_col_ids { dict set sums $id 0 }

    dict for {seg_name counts} $seg_counts {
        if {![info exists ::seg_checked($seg_name)] || !$::seg_checked($seg_name)} continue
        foreach id $ptree_col_ids {
            dict set sums $id [expr {[dict get $sums $id] + [dict get $counts $id]}]
        }
    }

    # Format totals values
    set values {}
    foreach {id heading anchor} $ptree_cols {
        set count [dict get $sums $id]
        set pid [dict get $denom_parent $id]
        if {$pid eq ""} {
            lappend values $count
        } else {
            set denom [dict get $sums $pid]
            lappend values [fmt_cell $count $denom]
        }
    }

    $ptree item __totals__ -values $values
}

# Toggle segment inclusion on click of column #0
bind $ptree <Button-1> {
    set _clicked_col [%W identify column %x %y]
    set _clicked_row [%W identify row %x %y]
    if {$_clicked_col eq "#0" && $_clicked_row ne "" && $_clicked_row ne "__totals__"} {
        set _seg $_clicked_row
        if {[info exists ::seg_checked($_seg)]} {
            set ::seg_checked($_seg) [expr {!$::seg_checked($_seg)}]
            set _cb [expr {$::seg_checked($_seg) ? "\u2611" : "\u2610"}]
            %W item $_seg -text "$_cb  $_seg"
            recalc_totals
        }
    }
}

# Mouse wheel scrolling
bind $ptree <Button-4>   { %W yview scroll -3 units }
bind $ptree <Button-5>   { %W yview scroll  3 units }
bind $ptree <MouseWheel> { %W yview scroll [expr {-%D/120}] units }

populate_progress_tree

# --- 2.3 Warnings (collapsed by default) ---

set warnings_expanded 0

ttk::frame ${cpanel}.warnings
pack ${cpanel}.warnings -fill x -padx 8 -pady {2 4}

set wframe ${cpanel}.warnings

proc compute_warning_summary {} {
    global warnings
    set warn_dup_email 0
    set warn_dup_name 0
    set warn_dup_subject 0
    set warn_other 0
    foreach w $warnings {
        if {[string match "*Duplicate To:*" $w] || [string match "*Duplicate email:*" $w]} {
            incr warn_dup_email
        } elseif {[string match "*Duplicate name:*" $w]} {
            incr warn_dup_name
        } elseif {[string match "*Identical subject:*" $w]} {
            incr warn_dup_subject
        } else {
            incr warn_other
        }
    }
    set parts {}
    if {$warn_dup_email > 0} { lappend parts "${warn_dup_email} duplicate email" }
    if {$warn_dup_name > 0}  { lappend parts "${warn_dup_name} duplicate name" }
    if {$warn_dup_subject > 0} { lappend parts "${warn_dup_subject} identical subject" }
    if {$warn_other > 0}     { lappend parts "${warn_other} other" }
    return [join $parts ", "]
}

set warn_summary [compute_warning_summary]

ttk::button ${wframe}.toggle -text "\u25b6 \u26a0 [llength $warnings] warnings ($warn_summary)" \
    -command toggle_warnings -style Toolbutton
pack ${wframe}.toggle -fill x -anchor w

text ${wframe}.txt -height 5 -wrap word -font "TkDefaultFont 8" -state disabled \
    -background "#fff8e1" -relief flat

proc populate_warnings_text {} {
    global wframe warnings
    ${wframe}.txt tag configure bold -font "TkDefaultFont 8 bold"
    ${wframe}.txt configure -state normal
    ${wframe}.txt delete 1.0 end
    foreach w $warnings {
        set colon [string first ":" $w]
        if {$colon >= 0} {
            ${wframe}.txt insert end "\u2022 " {} [string range $w 0 $colon] bold [string range $w [expr {$colon+1}] end] {}
        } else {
            ${wframe}.txt insert end "\u2022 $w"
        }
        ${wframe}.txt insert end "\n"
    }
    ${wframe}.txt configure -state disabled
}

populate_warnings_text

proc toggle_warnings {} {
    global warnings_expanded wframe warnings warn_summary
    if {$warnings_expanded} {
        pack forget ${wframe}.txt
        ${wframe}.toggle configure -text "\u25b6 \u26a0 [llength $warnings] warnings ($warn_summary)"
        set warnings_expanded 0
    } else {
        pack ${wframe}.txt -fill x -padx 4 -pady 2
        ${wframe}.toggle configure -text "\u25bc \u26a0 [llength $warnings] warnings ($warn_summary)"
        set warnings_expanded 1
    }
}

# ============================================================
# Zone 3: Transition manager
# ============================================================

ttk::frame ${tpanel}.toolbar
pack ${tpanel}.toolbar -fill x -padx 4 -pady {4 0}

set show_completed 1
ttk::checkbutton ${tpanel}.toolbar.showcomplete -text "Show completed" \
    -variable show_completed
pack ${tpanel}.toolbar.showcomplete -side left

ttk::frame ${tpanel}.treeframe
pack ${tpanel}.treeframe -fill both -expand 1 -padx 4 -pady 2

ttk::treeview ${tpanel}.treeframe.tree -columns {org segment state reason} \
    -show {tree headings} -selectmode extended
ttk::scrollbar ${tpanel}.treeframe.vsb -orient vertical \
    -command [list ${tpanel}.treeframe.tree yview]
${tpanel}.treeframe.tree configure -yscrollcommand [list ${tpanel}.treeframe.vsb set]

pack ${tpanel}.treeframe.vsb -side right -fill y
pack ${tpanel}.treeframe.tree -fill both -expand 1

set tree ${tpanel}.treeframe.tree

$tree heading #0    -text "Transition / Contact"
$tree heading org   -text "Organisation"
$tree heading segment -text "Segment"
$tree heading state -text "State"
$tree heading reason -text "Pending Reason"

$tree column #0     -width 250 -minwidth 150
$tree column org    -width 200 -minwidth 100
$tree column segment -width 150 -minwidth 80
$tree column state  -width 70  -minwidth 50
$tree column reason -width 300 -minwidth 100

proc populate_transitions {} {
    global tree transitions

    # Clear existing items
    foreach item [$tree children {}] {
        $tree delete $item
    }

    set ti 0
    foreach tentry $transitions {
        lassign $tentry tlabel tcount ttasks

        set parent_id "t$ti"
        $tree insert {} end -id $parent_id -text "$tlabel ($tcount)" -open false

        foreach task $ttasks {
            lassign $task tname torg tseg tstate treason
            set tags {}
            if {$tstate eq "done"} {
                set tags {done}
            } elseif {$tstate eq "pending"} {
                set tags {pending}
            }
            $tree insert $parent_id end -text $tname \
                -values [list $torg $tseg $tstate $treason] -tags $tags
        }

        incr ti
    }
}

populate_transitions

$tree tag configure done    -foreground #999999
$tree tag configure pending -foreground #cc6600

# Dispatch controls
ttk::frame ${tpanel}.dispatch
pack ${tpanel}.dispatch -fill x -padx 4 -pady {0 4}

ttk::button ${tpanel}.dispatch.play -text "\u25b6 Dispatch" -state disabled -command do_dispatch
ttk::button ${tpanel}.dispatch.stop -text "\u23f9 Stop"     -state disabled

pack ${tpanel}.dispatch.play -side left -padx {0 4}
pack ${tpanel}.dispatch.stop -side left -padx {0 8}

ttk::progressbar ${tpanel}.dispatch.pbar -mode determinate -value 0
ttk::button ${tpanel}.dispatch.logbtn -text "Log\u2026" -command show_log_window

proc show_dispatch_bar {} {
    global tpanel
    pack ${tpanel}.dispatch.pbar -side left -fill x -expand 1 -padx {8 4}
    pack ${tpanel}.dispatch.logbtn -side left
}

# Log window
proc show_log_window {} {
    if {[winfo exists .logwin]} {
        wm deiconify .logwin
        raise .logwin
        return
    }
    toplevel .logwin
    wm title .logwin "Dispatch Log"

    ttk::frame .logwin.bar
    pack .logwin.bar -fill x -padx 4 -pady {4 0}
    ttk::button .logwin.bar.clear -text "Clear" -command {
        .logwin.txt configure -state normal
        .logwin.txt delete 1.0 end
        .logwin.txt configure -state disabled
    }
    pack .logwin.bar.clear -side right

    text .logwin.txt -wrap word -font "TkFixedFont 8" -state disabled
    ttk::scrollbar .logwin.sb -orient vertical -command {.logwin.txt yview}
    .logwin.txt configure -yscrollcommand {.logwin.sb set}

    pack .logwin.sb -side right -fill y -padx {0 4} -pady {0 4}
    pack .logwin.txt -fill both -expand 1 -padx {4 0} -pady {0 4}

    wm protocol .logwin WM_DELETE_WINDOW {wm withdraw .logwin}
}

proc log_message {msg} {
    set ts [clock format [clock seconds] -format "%H:%M:%S"]
    # Ensure log window exists
    if {![winfo exists .logwin]} {
        show_log_window
    }
    .logwin.txt configure -state normal
    .logwin.txt insert end "$ts $msg\n"
    .logwin.txt see end
    .logwin.txt configure -state disabled
}

proc do_dispatch {} {
    global tree tpanel script_dir

    set sel [$tree selection]
    if {[llength $sel] == 0} return

    # Determine which transition is selected
    set parent ""
    foreach item $sel {
        if {[$tree parent $item] eq ""} {
            set parent $item
            break
        }
    }
    if {$parent eq ""} return

    set label [$tree item $parent -text]

    show_dispatch_bar
    log_message "Dispatch requested: $label"

    # Determine transition type from parent id
    set tid $parent  ;# e.g. "t0", "t1", ...
    set tnum [string range $tid 1 end]

    set dispatch_lib [file join $script_dir spar-dispatch.tcl]
    if {![file exists $dispatch_lib]} {
        log_message "Dispatch library not available (spar-dispatch.tcl not found)."
        return
    }

    if {[catch {source $dispatch_lib} err]} {
        log_message "Error loading spar-dispatch.tcl: $err"
        return
    }

    switch -- $tnum {
        0 {
            # T1: Sweep -> Profile
            if {[catch {spar::dispatch_profiles} err]} {
                log_message "T1 dispatch error: $err"
            } else {
                log_message "T1 dispatch completed."
            }
        }
        1 {
            # T2: Profile -> Approach
            if {[catch {spar::dispatch_approaches} err]} {
                log_message "T2 dispatch error: $err"
            } else {
                log_message "T2 dispatch completed."
            }
        }
        default {
            log_message "Dispatch for transition T[expr {$tnum + 1}] not implemented."
        }
    }

    do_refresh
}

bind $tree <<TreeviewSelect>> [list apply {{tree play} {
    set sel [$tree selection]
    set enable 0
    foreach item $sel {
        if {[$tree parent $item] eq "" && [$tree children $item] ne ""} {
            set enable 1
            break
        }
    }
    $play configure -state [expr {$enable ? "normal" : "disabled"}]
}} $tree ${tpanel}.dispatch.play]

# Show the dispatch bar
show_dispatch_bar

# ============================================================
# Rebuild procedures for Refresh
# ============================================================

proc rebuild_progress_table {} {
    populate_progress_tree
}

proc rebuild_warnings {} {
    global wframe warnings warn_summary warnings_expanded
    set warn_summary [compute_warning_summary]
    populate_warnings_text
    # Update toggle button text
    if {$warnings_expanded} {
        ${wframe}.toggle configure -text "\u25bc \u26a0 [llength $warnings] warnings ($warn_summary)"
    } else {
        ${wframe}.toggle configure -text "\u25b6 \u26a0 [llength $warnings] warnings ($warn_summary)"
    }
}

proc rebuild_transitions {} {
    populate_transitions
}

# ============================================================
# Initial sash position
# ============================================================

bind .tabs.tab_current.pw <Map> {
    after 50 {
        set h [winfo height .tabs.tab_current.pw]
        if {$h > 100} {
            .tabs.tab_current.pw sashpos 0 [expr {int($h * 0.65)}]
        }
    }
    bind .tabs.tab_current.pw <Map> {}
}

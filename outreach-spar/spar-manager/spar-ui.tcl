#!/usr/bin/env wish9.0
# SPAR Campaign Manager — Live UI

package require Tk

# Accept campaign directory or YAML file as argument, default to current directory.
# Arg ending in .yaml is treated as an explicit YAML path (must exist).
# Otherwise it is treated as a directory; campaign*.yaml is sought inside.
#
# Resolution happens exactly ONCE here — $campaign_file is authoritative for
# the life of the process. Reloading is allowed (the YAML on disk may
# change), but re-resolving is not: a second campaign*.yaml appearing in
# the directory at runtime must not swap the target under running ops.
set _arg [expr {[llength $argv] > 0 ? [lindex $argv 0] : "."}]
set _norm [file normalize $_arg]
if {[string match *.yaml $_arg]} {
    if {![file isfile $_norm]} {
        puts stderr "spar-ui: campaign YAML not found: $_arg"
        exit 1
    }
    set campaign_file $_norm
    set campaign_dir [file dirname $_norm]
} else {
    set campaign_dir $_norm
    set _p [file join $campaign_dir campaign.yaml]
    if {[file exists $_p]} {
        set campaign_file $_p
    } else {
        set _cs [lsort [glob -nocomplain [file join $campaign_dir campaign*.yaml]]]
        if {[llength $_cs]} {
            set campaign_file [lindex $_cs end]
        } else {
            set campaign_file ""
        }
    }
    if {$campaign_file eq ""} {
        puts stderr "spar-ui: no campaign YAML found in $campaign_dir"
        puts stderr "Usage: wish9.0 spar-ui.tcl <campaign-dir-or-yaml> \[flags\]"
        puts stderr "  Argument may be a directory containing campaign*.yaml, or a YAML file directly"
        puts stderr "Flags (non-interactive / debug):"
        puts stderr "  --tid=T2              dispatch this transition after async load completes"
        puts stderr "  --stems=a,b,c         narrow --tid dispatch to these roster stems"
        puts stderr "  --autoquit            exit after dispatch completes (exit status = failed count, clamped to 0/1)"
        puts stderr "  --log-stderr          mirror UI log lines to stderr regardless of --autoquit"
        exit 1
    }
}

# Non-interactive / debug flags: parse remaining argv (everything after the
# positional campaign argument).
set auto_tid ""
set auto_stems {}
set auto_quit 0
set log_to_stderr 0
foreach _a [lrange $argv 1 end] {
    if {[regexp {^--tid=(.+)$} $_a -> v]} { set auto_tid $v; continue }
    if {[regexp {^--stems=(.+)$} $_a -> v]} { set auto_stems [split $v ,]; continue }
    if {$_a eq "--autoquit"}    { set auto_quit 1; set log_to_stderr 1; continue }
    if {$_a eq "--log-stderr"}  { set log_to_stderr 1; continue }
    puts stderr "spar-ui: unrecognised argument: $_a"
    exit 1
}
if {[llength $auto_stems] > 0 && $auto_tid eq ""} {
    puts stderr "spar-ui: --stems requires --tid"
    exit 1
}

# Source backend libraries
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# ============================================================
# Load campaign data
# ============================================================

# Load campaign YAML config and discover segments.
# Sets config globals; returns 1 on success, 0 on error.
# Re-reads $campaign_file from disk; does not re-resolve which file to use.
proc load_campaign_config {} {
    global campaign_dir campaign_name sender_text filter_desc
    global cdata yaml_path segment_order skip_set segment_paths campaign_file

    set yaml_path $campaign_file
    if {![file exists $yaml_path]} {
        tk_messageBox -icon error -title "Campaign Missing" \
            -message "Campaign YAML no longer exists:\n$yaml_path"
        set campaign_name "(missing)"
        set sender_text ""
        set filter_desc ""
        set segment_order {}
        set segment_paths {}
        return 0
    }

    if {[catch {set cdata [spar::load_campaign $yaml_path]} err]} {
        tk_messageBox -icon error -title "Campaign Load Error" \
            -message "Error loading campaign:\n$err"
        set campaign_name "(error)"
        set sender_text ""
        set filter_desc ""
        set segment_order {}
        set segment_paths {}
        return 0
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

    return 1
}

# Fast startup load: campaign config + roster TSV counts only.
# Filesystem-dependent columns (Profile, A/3+★, A/Eml, Sent, Repl) are
# deferred to schedule_async_load.
proc load_campaign_data_fast {} {
    global segments warnings transitions
    global all_contacts skip_set segment_paths
    global segment_paths_for_async full_load_done

    set full_load_done 0
    set segment_paths_for_async {}

    if {![load_campaign_config]} {
        set segments {}
        set warnings {}
        set transitions {}
        set all_contacts {}
        set full_load_done 1
        return
    }

    set all_contacts {}
    set segments {}

    foreach item $segment_paths {
        lassign $item label seg_dir
        set is_active [expr {$label ni $skip_set}]

        lappend segment_paths_for_async [list $label $seg_dir $is_active]

        if {[catch {set rcounts [spar::roster_counts $seg_dir]} err]} {
            set zero_data [list 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {}]
            lappend segments [list $label $is_active $zero_data]
            continue
        }

        set v  [dict get $rcounts valid]
        set s3 [dict get $rcounts star3]
        set e  [dict get $rcounts has_email]
        set l  [dict get $rcounts has_linkedin]
        set f  [dict get $rcounts has_facebook]
        set po [dict get $rcounts has_phone_only]

        # TSV-derivable columns filled; filesystem columns placeholder (0)
        set raw_data [list \
            $v {} \
            0 {} \
            $s3 [format_pct $s3 $v] \
            0 {} \
            $e [format_pct $e $s3] \
            0 {} \
            $l [format_pct $l $s3] \
            $f [format_pct $f $s3] \
            $po [format_pct $po $s3] \
            0 {} \
            0 {}]

        lappend segments [list $label $is_active $raw_data]
    }

    set warnings {}
    set transitions {}
}

# Full synchronous load (used by Refresh).
proc load_campaign_data_full {} {
    global segments warnings transitions
    global all_contacts skip_set segment_paths
    global full_load_done

    set full_load_done 1

    if {![load_campaign_config]} {
        set segments {}
        set warnings {}
        set transitions {}
        set all_contacts {}
        return
    }

    set all_contacts {}
    set segments {}

    foreach item $segment_paths {
        lassign $item label seg_dir
        set is_active [expr {$label ni $skip_set}]

        if {[catch {
            set classified [spar::classify_segment $seg_dir]
        } err]} {
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

    set warnings [build_warnings $all_contacts]
    set transitions [build_transitions $all_contacts]
}

proc format_pct {num denom} {
    if {$denom == 0} {
        return "-"
    }
    set pct [expr {$num * 100 / $denom}]
    return "${pct}%"
}

# --- Async loading state ---
set full_load_done 1
set async_after_ids {}
set segment_paths_for_async {}
set async_segments_remaining 0

# Filesystem-dependent column IDs (shown as "\u2026" until full load)
set fs_dependent_cols {profiled astar aeml sent repl}

# Column ID -> progress_counts dict key
set col_count_keys [dict create \
    valid valid  profiled profiled  star3 star3 \
    astar approached_star3  email has_email  aeml approached_email \
    linkedin has_linkedin  facebook has_facebook  phone has_phone_only \
    sent email_sent  repl email_replied]

proc cancel_async_load {} {
    global async_after_ids
    foreach id $async_after_ids {
        after cancel $id
    }
    set async_after_ids {}
}

proc schedule_async_load {} {
    global segment_paths_for_async async_after_ids async_segments_remaining
    global full_load_done
    cancel_async_load
    set async_segments_remaining [llength $segment_paths_for_async]
    if {$async_segments_remaining == 0} {
        set full_load_done 1
        recalc_totals
        return
    }
    # Use timer (not after idle) so Tk renders the window between segments
    lappend async_after_ids [after 1 _async_load_next]
}

proc _async_load_next {} {
    global segment_paths_for_async async_after_ids async_segments_remaining
    global full_load_done ptree ptree_col_ids ptree_cols
    global seg_counts all_contacts col_count_keys denom_parent
    global warnings transitions

    if {[llength $segment_paths_for_async] == 0} return

    set item [lindex $segment_paths_for_async 0]
    set segment_paths_for_async [lrange $segment_paths_for_async 1 end]
    lassign $item seg_name seg_dir is_active

    if {![catch {set classified [spar::classify_segment $seg_dir]} err]} {
        if {$is_active} {
            foreach c $classified { lappend all_contacts $c }
        }

        set cdict [spar::progress_counts $classified]

        if {[$ptree exists $seg_name]} {
            set counts {}
            foreach id $ptree_col_ids {
                set key [dict get $col_count_keys $id]
                lappend counts [dict get $cdict $key]
            }

            if {$is_active} {
                set ci 0
                foreach id $ptree_col_ids {
                    dict set seg_counts $seg_name $id [lindex $counts $ci]
                    incr ci
                }
            }

            # Build formatted values for this row
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
            $ptree item $seg_name -values $values
        }
    }

    incr async_segments_remaining -1

    if {[llength $segment_paths_for_async] > 0} {
        lappend async_after_ids [after 1 _async_load_next]
    } else {
        set full_load_done 1
        recalc_totals
        after idle autosize_progress_tree

        set warnings [build_warnings $all_contacts]
        set transitions [build_transitions $all_contacts]
        rebuild_warnings
        rebuild_transitions

        # Headless / self-debug hook: if --tid was given on the command
        # line, drive the dispatch programmatically once the tree is
        # populated. after idle so the UI finishes laying out.
        global auto_tid
        if {$auto_tid ne ""} {
            after idle auto_dispatch
        }
    }
}

proc build_warnings {all_contacts} {
    return [dict get [spar::build_warnings $all_contacts] messages]
}

proc build_transitions {all_contacts} {
    global cdata
    set labels {
        "Sweep \u2192 Profile"
        "Profile \u2192 Approach"
        "Approach \u2192 Send"
        "Send \u2192 Reply"
        "Stale \u2192 Re-profile"
        "Re-profile \u2192 Re-approach"
        "LinkedIn \u2192 Email follow-up"
    }
    set tids {T1 T2 T3 T4 T6 T7 T8}

    set primary_channel ""
    if {[info exists cdata]} {
        set primary_channel [spar::campaign_primary_channel $cdata]
    }

    set result {}
    for {set i 0} {$i < [llength $labels]} {incr i} {
        set label [lindex $labels $i]
        set tid [lindex $tids $i]

        set eligible [spar::transition_eligible $all_contacts $tid $primary_channel]
        set count [llength $eligible]

        set tasks {}
        foreach contact $eligible {
            set cname [dict get $contact contact_name]
            set cstem [spar::dict_get_default $contact stem ""]
            set org [dict get $contact organisation]
            set seg [dict get $contact segment]
            set tstate [dict get $contact task_state]
            set reason [dict get $contact reason]
            lappend tasks [list $cname $cstem $org $seg $tstate $reason]
        }

        lappend result [list $label $count $tasks]
    }

    return $result
}

# --- Load data (fast: TSV only, filesystem deferred) ---
load_campaign_data_fast

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
ttk::label ${cf}.l4 -text "Filter:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v4 -text $filter_desc

grid ${cf}.l1 ${cf}.v1 -sticky w -padx {6 4} -pady 1
grid ${cf}.l2 ${cf}.v2 -sticky w -padx {6 4} -pady 1
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
    global campaign_name sender_text filter_desc
    global segments warnings transitions
    global cf cpanel wframe tpanel

    # Reload all data
    cancel_async_load
    load_campaign_data_full

    # Update config labels
    ${cf}.v1 configure -text $campaign_name
    ${cf}.v2 configure -text $sender_text
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
    global ptree ptree_col_ids ptree_cols segments seg_counts seg_checked
    global denom_parent full_load_done fs_dependent_cols

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

        # During async load, show "…" for filesystem-dependent columns
        if {!$full_load_done} {
            set vi 0
            foreach {id heading anchor} $ptree_cols {
                if {$id in $fs_dependent_cols} {
                    lset values $vi "\u2026"
                }
                incr vi
            }
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
    global ptree ptree_col_ids ptree_cols seg_counts seg_checked
    global denom_parent full_load_done fs_dependent_cols

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

    # During async load, show "…" for filesystem-dependent totals
    if {!$full_load_done} {
        set vi 0
        foreach {id heading anchor} $ptree_cols {
            if {$id in $fs_dependent_cols} {
                lset values $vi "\u2026"
            }
            incr vi
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

ttk::button ${wframe}.toggle -text "\u25b8 \u26a0 [llength $warnings] warnings ($warn_summary)" \
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
        ${wframe}.toggle configure -text "\u25b8 \u26a0 [llength $warnings] warnings ($warn_summary)"
        set warnings_expanded 0
    } else {
        pack ${wframe}.txt -fill x -padx 4 -pady 2
        ${wframe}.toggle configure -text "\u25be \u26a0 [llength $warnings] warnings ($warn_summary)"
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

ttk::treeview ${tpanel}.treeframe.tree \
    -columns {stem org segment state reason} \
    -displaycolumns {org segment state reason} \
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
            lassign $task tname tstem torg tseg tstate treason
            set tags {}
            if {$tstate eq "done"} {
                set tags {done}
            } elseif {$tstate eq "pending"} {
                set tags {pending}
            }
            $tree insert $parent_id end -text $tname \
                -values [list $tstem $torg $tseg $tstate $treason] -tags $tags
        }

        incr ti
    }
}

populate_transitions

$tree tag configure done    -foreground #999999
$tree tag configure pending -foreground #cc6600

# Dispatch controls
ttk::frame ${tpanel}.dispatch
pack ${tpanel}.dispatch -side bottom -fill x -padx 4 -pady {0 4} -before ${tpanel}.treeframe

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
    global log_to_stderr
    set ts [clock format [clock seconds] -format "%H:%M:%S"]
    if {$log_to_stderr} {
        puts stderr "$ts $msg"
        flush stderr
    }
    # Ensure log window exists
    if {![winfo exists .logwin]} {
        show_log_window
    }
    .logwin.txt configure -state normal
    .logwin.txt insert end "$ts $msg\n"
    .logwin.txt see end
    .logwin.txt configure -state disabled
}

set dispatching 0
set saved_tree_bindtags {}

proc ui_on_progress {slug status message} {
    log_message "  \[$status\] $slug $message"
}

proc ui_on_complete {done failed result} {
    global dispatching tpanel tree saved_tree_bindtags
    set dispatching 0
    ${tpanel}.dispatch.play configure -state normal
    $tree state !disabled
    if {$saved_tree_bindtags ne {}} {
        bindtags $tree $saved_tree_bindtags
        set saved_tree_bindtags {}
    }
    set skipped [spar::dict_get_default $result skipped 0]
    set count   [spar::dict_get_default $result count 0]
    set tail ""
    if {$skipped ne "" && $skipped > 0} { append tail ", $skipped skipped" }
    if {$count ne "" && $count == 0 && $done == 0 && $failed == 0} {
        append tail " (no rows matched the runner's filters — check in-scope channel, min_star, or that the approach file already exists)"
    }
    log_message "Dispatch completed: $done done, $failed failed$tail."
    do_refresh
    event generate $tree <<TreeviewSelect>>

    global auto_quit
    if {$auto_quit} {
        # Exit with 1 if anything failed, else 0. Flush any pending Tk
        # work first so the log line actually reaches stderr.
        update
        exit [expr {$failed > 0 ? 1 : 0}]
    }
}

# Headless / self-debug entry point: called from _async_load_next after
# the tree is populated when --tid was given on the command line. Maps
# --tid to the parent tree node, optionally narrows to --stems, and
# fires do_dispatch via the normal selection path so the new code
# exercises the same code path the user exercises manually.
proc auto_dispatch {} {
    global tree auto_tid auto_stems auto_quit
    set tids {T1 T2 T3 T4 T6 T7 T8}
    set idx [lsearch -exact $tids $auto_tid]
    if {$idx < 0} {
        puts stderr "spar-ui: --tid=$auto_tid is not one of: [join $tids {, }]"
        if {$auto_quit} { exit 1 }
        return
    }
    set parent "t$idx"
    if {![$tree exists $parent]} {
        puts stderr "spar-ui: transition $auto_tid has no tree row (not populated?)"
        if {$auto_quit} { exit 1 }
        return
    }
    set children [$tree children $parent]
    if {[llength $children] == 0} {
        puts stderr "spar-ui: transition $auto_tid has zero eligible contacts"
        if {$auto_quit} { exit 0 }
        return
    }

    if {[llength $auto_stems] > 0} {
        # Narrow to children whose stashed stem matches.
        set matches {}
        set all_stems {}
        foreach c $children {
            set s [$tree set $c stem]
            lappend all_stems $s
            if {$s in $auto_stems} { lappend matches $c }
        }
        if {[llength $matches] == 0} {
            puts stderr "spar-ui: none of --stems=[join $auto_stems ,] matched the $auto_tid tree."
            puts stderr "spar-ui: available stems under $auto_tid: [join $all_stems {, }]"
            if {$auto_quit} { exit 1 }
            return
        }
        # Report missing stems so the caller notices typos.
        set missing {}
        foreach s $auto_stems {
            set found 0
            foreach c $matches {
                if {[$tree set $c stem] eq $s} { set found 1; break }
            }
            if {!$found} { lappend missing $s }
        }
        if {[llength $missing] > 0} {
            puts stderr "spar-ui: --stems not found under $auto_tid: [join $missing {, }]"
        }
        $tree selection set $matches
    } else {
        $tree selection set [list $parent]
    }
    event generate $tree <<TreeviewSelect>>
    update
    do_dispatch
}

proc do_dispatch {} {
    global tree tpanel script_dir dispatching saved_tree_bindtags campaign_file

    if {$dispatching} return

    set sel [$tree selection]
    if {[llength $sel] == 0} return

    # Gather the parent node(s) spanned by the selection. A child-only
    # selection implies its parent. More than one distinct parent means
    # the user crossed transitions — refuse. The binding should have
    # disabled the button in that case, but guard against stale state.
    set parents {}
    set child_items {}
    foreach item $sel {
        set p [$tree parent $item]
        if {$p eq ""} {
            lappend parents $item
        } else {
            lappend parents $p
            lappend child_items $item
        }
    }
    set parents [lsort -unique $parents]
    if {[llength $parents] != 1} return
    set parent [lindex $parents 0]

    set label [$tree item $parent -text]

    # Tree item id (t0..t6) to T-id. The ordering must match
    # build_transitions above.
    set tnum [string range $parent 1 end]
    set tids {T1 T2 T3 T4 T6 T7 T8}
    set tid [lindex $tids $tnum]

    # Ensure backend libraries are loaded.
    foreach lib {spar-dispatch.tcl spar-email.tcl} {
        set path [file join $script_dir $lib]
        if {![file exists $path]} {
            log_message "Dispatch library not available ($lib not found)."
            return
        }
        if {[catch {source $path} err]} {
            log_message "Error loading $lib: $err"
            return
        }
    }

    if {![spar::has_transition_runner $tid]} {
        log_message "Dispatch for $tid not implemented."
        return
    }
    set runner [spar::transition_runner $tid]

    set opts [dict create \
        campaign_file $campaign_file \
        dry_run 0 \
        jobs 4]
    if {$runner eq "::spar::email::run"} {
        # UI has its own flow — no tty prompt.
        dict set opts delay_seconds 0
        dict set opts confirmed 1
    }

    # Narrow dispatch to the selected children, if any. Empty list ⇒
    # current (parent-only) behaviour: runner processes all ready rows.
    if {[llength $child_items] > 0} {
        set sel_stems {}
        foreach c $child_items {
            set s [$tree set $c stem]
            if {$s ne ""} { lappend sel_stems $s }
        }
        if {[llength $sel_stems] > 0} {
            dict set opts stems $sel_stems
            log_message "Dispatch narrowed to [llength $sel_stems] selected stem(s): [join $sel_stems {, }]"
        }
    }

    set dispatching 1
    ${tpanel}.dispatch.play configure -state disabled
    $tree state disabled
    set saved_tree_bindtags [bindtags $tree]
    bindtags $tree [list $tree .]
    update idletasks

    show_dispatch_bar
    log_message "Dispatch requested: $label ($tid)"

    if {[catch {$runner $opts ui_on_progress ui_on_complete} err]} {
        log_message "$tid dispatch error: $err"
        set dispatching 0
        ${tpanel}.dispatch.play configure -state normal
        $tree state !disabled
        if {$saved_tree_bindtags ne {}} {
            bindtags $tree $saved_tree_bindtags
            set saved_tree_bindtags {}
        }
    }
}

bind $tree <<TreeviewSelect>> [list apply {{tree play} {
    set sel [$tree selection]
    set parents {}
    set children {}
    foreach item $sel {
        set p [$tree parent $item]
        if {$p eq ""} {
            lappend parents $item
        } else {
            lappend parents $p
            lappend children $item
        }
    }
    set parents [lsort -unique $parents]

    # Mixed parents, or nothing selected ⇒ disable.
    if {[llength $parents] != 1} {
        $play configure -state disabled -text "\u25b6 Dispatch"
        return
    }
    set parent [lindex $parents 0]
    # Empty transition (no children at all) ⇒ nothing to dispatch.
    if {[$tree children $parent] eq ""} {
        $play configure -state disabled -text "\u25b6 Dispatch"
        return
    }

    set label [$tree item $parent -text]
    regsub {\s*\(\d+\)\s*$} $label "" label

    set nchild [llength $children]

    # When children are selected and the runner is ::spar::p::run
    # (T1/T6), passing stems bypasses the "profile exists" skip — i.e.
    # re-authors. Reflect that in the verb so the user sees the action
    # before firing.
    set verb "Dispatch"
    if {$nchild > 0} {
        set tnum [string range $parent 1 end]
        set tids {T1 T2 T3 T4 T6 T7 T8}
        set tid [lindex $tids $tnum]
        if {[spar::has_transition_runner $tid]} {
            set runner [spar::transition_runner $tid]
            if {$runner eq "::spar::p::run"} {
                foreach c $children {
                    if {[$tree set $c state] eq "done"} {
                        set verb "Re-author"
                        break
                    }
                }
            }
        }
    }

    if {$nchild > 0} {
        $play configure -state normal \
            -text "\u25b6 ${verb}: $label ($nchild)"
    } else {
        $play configure -state normal -text "\u25b6 Dispatch: $label"
    }
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
        ${wframe}.toggle configure -text "\u25be \u26a0 [llength $warnings] warnings ($warn_summary)"
    } else {
        ${wframe}.toggle configure -text "\u25b8 \u26a0 [llength $warnings] warnings ($warn_summary)"
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

# Schedule async loading of filesystem-dependent columns.
# Use a timer (not after idle) so the window renders first.
after 1 schedule_async_load

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
source [file join $script_dir ui campaign-model.tcl]
source [file join $script_dir ui log-window.tcl]
source [file join $script_dir ui progress-table.tcl]
source [file join $script_dir ui transition-tree.tcl]

# ============================================================
# Load campaign data
# ============================================================

# The CampaignModel owns campaign config, segment data, async-load state,
# and per-contact classification. This bootstrap instantiates it and
# populates shim top-level vars (segments, all_contacts, warnings, …)
# that the still-procedural UI zones read. Each subsequent refactor
# commit removes one zone's shim reads as that zone becomes a class.
set campaign [spar::ui::CampaignModel new $campaign_file $script_dir]
$campaign load

# LogWindow owns the dispatch log buffer, the optional toplevel, and the
# unread counter. Construction takes log_to_stderr as config (never
# mutated internally). The toolbar badge subscribes to unread-changed.
set log [spar::ui::LogWindow new $log_to_stderr]

set cdata          [$campaign get_cdata]
set campaign_name  [$campaign get_campaign_name]
set sender_text    [$campaign get_sender_text]
set filter_desc    [$campaign get_filter_desc]
set segments       [$campaign get_segments]
set all_contacts   [$campaign get_all_contacts]
set warnings       [$campaign get_warnings]
set transitions    [$campaign get_transitions]
set full_load_done [$campaign get_full_load_done]

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

ttk::button ${cpanel}.toolbar.checkemail -text "Check Email" -command [list $campaign check_email]
pack ${cpanel}.toolbar.checkemail -side right

ttk::button ${cpanel}.toolbar.refresh -text "Refresh" -command [list $campaign refresh]
pack ${cpanel}.toolbar.refresh -side right -padx {0 4}

ttk::button ${cpanel}.toolbar.legend -text "Legend" -command show_legend_window
pack ${cpanel}.toolbar.legend -side right -padx {0 4}

ttk::button ${cpanel}.toolbar.selall -text "All" -width 4 \
    -command [list apply {{} { $::progress set_all 1 }}]
pack ${cpanel}.toolbar.selall -side left

ttk::button ${cpanel}.toolbar.selnone -text "None" -width 4 \
    -command [list apply {{} { $::progress set_all 0 }}]
pack ${cpanel}.toolbar.selnone -side left -padx {2 0}


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

# ProgressTable encapsulates the progress treeview, its column config,
# per-segment count snapshots, checkbox state, totals row, and the
# "..." placeholders that display while async classification is in
# flight. It subscribes to the CampaignModel's segment-loaded /
# fully-loaded / refreshed events in its constructor, so refreshes
# propagate without extra wiring here.
set progress [spar::ui::ProgressTable new $campaign ${cpanel}.progress]
$progress populate

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

# TransitionTree encapsulates the transition treeview, the row_id →
# contact_name map, the stem → row_id map, the Show-completed
# checkbox, and <<TreeviewSelect>> / <Double-1> bindings. It
# subscribes to the CampaignModel's `refreshed` event in its
# constructor so refreshes rebuild the tree without extra wiring.
#
# Commit-5 cleanup target: the class mirrors its Tree widget path into
# the top-level `tree` global and its SlugToRow dict into
# `slug_to_row` because the still-procedural dispatch procs in this
# file (clear_cohort, reapply_cohort_after_refresh, ui_on_progress,
# do_dispatch, auto_dispatch, ui_on_complete) still read them
# directly. Commit 5 (DispatchController) replaces every shim read
# with a method call and drops both globals.
set tree_obj [spar::ui::TransitionTree new $campaign $tpanel]
$tree_obj populate

# Dispatch controls
ttk::frame ${tpanel}.dispatch
pack ${tpanel}.dispatch -side bottom -fill x -padx 4 -pady {0 4} -before ${tpanel}.treeframe

ttk::button ${tpanel}.dispatch.play   -text "\u25b6 Dispatch" -state disabled -command do_dispatch
ttk::button ${tpanel}.dispatch.pause  -text "\u23f8 Pause"    -state disabled -command do_pause
ttk::button ${tpanel}.dispatch.cancel -text "\u2715 Cancel"   -state disabled -command do_cancel

pack ${tpanel}.dispatch.play   -side left -padx {0 4}
pack ${tpanel}.dispatch.pause  -side left -padx {0 4}
pack ${tpanel}.dispatch.cancel -side left -padx {0 8}

ttk::frame       ${tpanel}.dispatch.progress
ttk::progressbar ${tpanel}.dispatch.progress.bar -mode determinate -value 0
ttk::label       ${tpanel}.dispatch.progress.status -text "" -anchor w
pack ${tpanel}.dispatch.progress.bar    -fill x -expand 1
pack ${tpanel}.dispatch.progress.status -fill x
ttk::button ${tpanel}.dispatch.logbtn -text "Log\u2026" -command [list $log show]

# Badge: LogWindow fires unread-changed whenever the count shifts.
# Toolbar button text flips between plain and bullet-dotted.
$log subscribe unread-changed [list apply {{count} {
    global tpanel
    set text [expr {$count ? "Log\u2026 \u2022" : "Log\u2026"}]
    ${tpanel}.dispatch.logbtn configure -text $text
}}]

proc show_dispatch_bar {} {
    global tpanel
    pack ${tpanel}.dispatch.progress -side left -fill x -expand 1 -padx {8 4}
    pack ${tpanel}.dispatch.logbtn -side left
}

set dispatching 0
set paused 0

# Cohort state, keyed on stem. Persists across do_refresh so terminal
# per-row glyphs stay visible from end-of-dispatch until the next
# dispatch clears them. slug_to_row and row_names are owned by the
# TransitionTree class (Commit 4); it writes them as shim globals on
# every populate so the still-procedural dispatch procs below can
# continue to read them until Commit 5.
set cohort_stems {}
set cohort_state  [dict create]
set cohort_reason [dict create]
set cohort_phase  [dict create]
# Snapshot of a cohort row's classify state/reason columns, taken when
# the row enters the cohort. clear_cohort restores from this so the
# classify view re-appears for rows dropped from the next cohort.
set classify_snapshot [dict create]

# Braille-dot spinner frames for the aggregate progress status line.
set aggregate_frames [list \u280b \u2819 \u2839 \u2838 \u283c \u2834 \u2826 \u2827 \u2807 \u280f]
set aggregate_tick 0
set aggregate_after ""

proc do_pause {} {
    global paused tpanel
    if {!$paused} {
        spar::pause_all
        set paused 1
        ${tpanel}.dispatch.pause configure -text "\u25b6 Resume"
        $::log log "Dispatch paused: queued items held; in-flight items finish normally."
    } else {
        spar::resume_all
        set paused 0
        ${tpanel}.dispatch.pause configure -text "\u23f8 Pause"
        $::log log "Dispatch resumed."
    }
}

proc do_cancel {} {
    spar::cancel_all
    $::log log "Dispatch cancelled: queued items skipped; in-flight items finish normally."
}

# Render one cohort row: #0 text = plain name, state column = dispatch
# glyph+label, reason column = phase/time/reason detail.
proc render_row {row_id} {
    global tree cohort_state cohort_reason cohort_phase cohort_stems tree_obj
    if {![$tree exists $row_id]} return
    set stem [$tree set $row_id stem]
    if {$stem eq "" || ![dict exists $cohort_state $stem]} return
    set state  [dict get $cohort_state $stem]
    set reason [expr {[dict exists $cohort_reason $stem] ? [dict get $cohort_reason $stem] : ""}]
    set phase  [expr {[dict exists $cohort_phase  $stem] ? [dict get $cohort_phase  $stem] : ""}]
    set row_names [$tree_obj get_row_names]
    set name   [expr {[dict exists $row_names    $row_id] ? [dict get $row_names    $row_id] : ""}]
    switch -- $state {
        queued {
            set pos   [expr {[lsearch -exact $cohort_stems $stem] + 1}]
            set total [llength $cohort_stems]
            set state_text "\u25cb queued #$pos/$total"
            set reason_text ""
        }
        running {
            set state_text  "\u25d0 running"
            set reason_text $phase
        }
        done {
            set state_text  "\u2713 done"
            set reason_text $reason
        }
        failed {
            set state_text  "\u2717 failed"
            set reason_text $reason
        }
        skipped {
            set state_text  "\u2298 skipped"
            set reason_text $reason
        }
        cancelled {
            set state_text  "\u2298 cancelled"
            set reason_text ""
        }
        default {
            set state_text  ""
            set reason_text ""
        }
    }
    $tree item $row_id -text "  $name"
    $tree set $row_id state  $state_text
    $tree set $row_id reason $reason_text
}

proc update_progress_display {} {
    global tpanel cohort_stems cohort_state aggregate_frames aggregate_tick dispatching
    set total [llength $cohort_stems]
    if {$total == 0} {
        ${tpanel}.dispatch.progress.bar configure -value 0
        ${tpanel}.dispatch.progress.status configure -text ""
        return
    }
    set done 0; set failed 0; set running 0; set skipped 0; set cancelled 0
    foreach s $cohort_stems {
        switch -- [dict get $cohort_state $s] {
            done      { incr done }
            failed    { incr failed }
            running   { incr running }
            skipped   { incr skipped }
            cancelled { incr cancelled }
        }
    }
    set finished [expr {$done + $failed + $skipped + $cancelled}]
    ${tpanel}.dispatch.progress.bar configure -value [expr {100.0 * $finished / $total}]
    set prefix ""
    if {$dispatching} {
        set frame [lindex $aggregate_frames [expr {$aggregate_tick % [llength $aggregate_frames]}]]
        set prefix "$frame "
    }
    set text "${prefix}$done of $total done"
    if {$failed    > 0} { append text " \u00b7 $failed failed" }
    if {$running   > 0} { append text " \u00b7 $running running" }
    if {$skipped   > 0} { append text " \u00b7 $skipped skipped" }
    if {$cancelled > 0} { append text " \u00b7 $cancelled cancelled" }
    ${tpanel}.dispatch.progress.status configure -text $text
}

proc aggregate_animate {} {
    global dispatching aggregate_tick aggregate_after
    if {!$dispatching} { set aggregate_after ""; return }
    incr aggregate_tick
    update_progress_display
    set aggregate_after [after 150 aggregate_animate]
}

proc clear_cohort {} {
    global tree cohort_stems cohort_state cohort_reason cohort_phase slug_to_row tree_obj
    global classify_snapshot aggregate_after aggregate_tick
    if {$aggregate_after ne ""} {
        after cancel $aggregate_after
        set aggregate_after ""
    }
    set aggregate_tick 0
    set row_names [$tree_obj get_row_names]
    # Restore previous-cohort rows: drop in_cohort tag, reset #0 text,
    # and restore the state/reason columns from the classify snapshot.
    foreach s $cohort_stems {
        if {![dict exists $slug_to_row $s]} continue
        set row_id [dict get $slug_to_row $s]
        if {![$tree exists $row_id]} continue
        set tags [$tree item $row_id -tags]
        set idx [lsearch -exact $tags in_cohort]
        if {$idx >= 0} {
            $tree item $row_id -tags [lreplace $tags $idx $idx]
        }
        set name [expr {[dict exists $row_names $row_id] ? [dict get $row_names $row_id] : ""}]
        $tree item $row_id -text "  $name"
        if {[dict exists $classify_snapshot $s]} {
            lassign [dict get $classify_snapshot $s] cs cr
            $tree set $row_id state  $cs
            $tree set $row_id reason $cr
        }
    }
    set cohort_stems       {}
    set cohort_state       [dict create]
    set cohort_reason      [dict create]
    set cohort_phase       [dict create]
    set slug_to_row        [dict create]
    set classify_snapshot  [dict create]
    update_progress_display
}

# After do_refresh rebuilds the tree (new row ids), reconnect slug_to_row
# and re-render cohort members so terminal glyphs survive the refresh.
proc reapply_cohort_after_refresh {} {
    global tree cohort_stems slug_to_row classify_snapshot
    set slug_to_row       [dict create]
    set classify_snapshot [dict create]
    if {[llength $cohort_stems] == 0} return
    foreach parent [$tree children {}] {
        foreach row [$tree children $parent] {
            set s [$tree set $row stem]
            if {$s eq ""} continue
            if {[lsearch -exact $cohort_stems $s] < 0} continue
            dict set slug_to_row $s $row
            # Re-snapshot classify state/reason from the freshly-rebuilt
            # tree so clear_cohort can restore to current classify values.
            dict set classify_snapshot $s [list \
                [$tree set $row state] \
                [$tree set $row reason]]
            set tags [$tree item $row -tags]
            if {[lsearch -exact $tags in_cohort] < 0} {
                $tree item $row -tags [concat $tags in_cohort]
            }
            render_row $row
        }
    }
}


proc ui_on_progress {slug status message} {
    global cohort_state cohort_reason cohort_phase slug_to_row
    global aggregate_after
    # Phase markers are row state, not log events.
    if {[regexp {\[phase:\s*([^\]]+)\]} $message -> phase]} {
        if {[dict exists $cohort_state $slug]} {
            dict set cohort_phase $slug [string trim $phase]
            if {[dict exists $slug_to_row $slug]} {
                render_row [dict get $slug_to_row $slug]
            }
        }
        return
    }
    # Runner iterates the whole segment and emits "skipped" for rows it
    # pre-filters (approach exists, excluded, wrong channel). When the
    # user narrowed to a cohort, these non-cohort skips are noise —
    # suppress them from the log entirely.
    if {$status eq "skipped" && ![dict exists $cohort_state $slug]} {
        return
    }
    # slug == stem during a run; non-cohort events (e.g. the
    # {slug_name}-{slug_org} "no stem" skip) skip row rendering.
    if {[dict exists $cohort_state $slug]} {
        set prev [dict get $cohort_state $slug]
        set changed 0
        switch -- $status {
            started {
                if {$prev ne "running"} {
                    dict set cohort_state $slug running
                    set changed 1
                    if {$aggregate_after eq ""} { aggregate_animate }
                }
                set m [string trim $message]
                if {$m ne ""} { dict set cohort_reason $slug $m }
            }
            done {
                dict set cohort_state $slug done
                dict set cohort_reason $slug [clock format [clock seconds] -format "%H:%M"]
                set changed 1
            }
            failed {
                dict set cohort_state $slug failed
                set r [string trim $message]
                if {$r eq ""} {
                    set r [expr {[dict exists $cohort_reason $slug] ? [dict get $cohort_reason $slug] : "unknown"}]
                }
                if {[string length $r] > 80} { set r "[string range $r 0 77]\u2026" }
                dict set cohort_reason $slug $r
                set changed 1
            }
            skipped {
                if {[string trim $message] eq "cancelled"} {
                    dict set cohort_state $slug cancelled
                } else {
                    dict set cohort_state $slug skipped
                    dict set cohort_reason $slug [string trim $message]
                }
                set changed 1
            }
            warning {
                # LogWindow.log will bump unread on its own.
            }
        }
        if {$changed && [dict exists $slug_to_row $slug]} {
            render_row [dict get $slug_to_row $slug]
        }
    }
    update_progress_display
    # Suppress the dispatcher's empty "started" kickoff from the log —
    # already reflected in the row's running state. Log everything else.
    if {!($status eq "started" && $message eq "")} {
        $::log log "  \[$status\] $slug $message"
    }
}

proc ui_on_complete {done failed result} {
    global dispatching paused tpanel tree aggregate_after
    set dispatching 0
    set paused 0
    ${tpanel}.dispatch.play configure -state normal
    ${tpanel}.dispatch.pause configure -state disabled -text "\u23f8 Pause"
    ${tpanel}.dispatch.cancel configure -state disabled
    # Stop the aggregate spinner but keep cohort_* dicts so the terminal
    # per-row glyphs persist. The next do_dispatch calls clear_cohort.
    if {$aggregate_after ne ""} {
        after cancel $aggregate_after
        set aggregate_after ""
    }
    set skipped [spar::dict_get_default $result skipped 0]
    set count   [spar::dict_get_default $result count 0]
    set tail ""
    if {$skipped ne "" && $skipped > 0} { append tail ", $skipped skipped" }
    if {$count ne "" && $count == 0 && $done == 0 && $failed == 0} {
        append tail " (no rows matched the runner's filters — check in-scope channel, min_star, or that the approach file already exists)"
    }
    $::log log "Dispatch completed: $done done, $failed failed$tail."
    $::campaign refresh
    reapply_cohort_after_refresh
    update_progress_display
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
    global tree tpanel script_dir dispatching cohort_stems cohort_state slug_to_row classify_snapshot campaign_file

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
            $::log log "Dispatch library not available ($lib not found)."
            return
        }
        if {[catch {source $path} err]} {
            $::log log "Error loading $lib: $err"
            return
        }
    }

    if {![spar::has_transition_runner $tid]} {
        $::log log "Dispatch for $tid not implemented."
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

    # Clear the previous cohort so its terminal glyphs are wiped before
    # the new run begins. Stem-less rows can't be dispatched (the runner
    # skips them server-side), so they're excluded from the cohort.
    clear_cohort
    # Parent-only selection: the implicit cohort is every child under it.
    # With no cohort, update_progress_display and render_row silently
    # no-op — the aggregate caption stays blank and no row gets ◐/✓.
    if {[llength $child_items] == 0} {
        set child_items [$tree children $parent]
    }
    if {[llength $child_items] > 0} {
        set sel_stems {}
        foreach c $child_items {
            set s [$tree set $c stem]
            if {$s eq ""} continue
            lappend sel_stems $s
            lappend cohort_stems $s
            dict set cohort_state $s queued
            dict set slug_to_row  $s $c
            dict set classify_snapshot $s [list \
                [$tree set $c state] \
                [$tree set $c reason]]
            set tags [$tree item $c -tags]
            if {[lsearch -exact $tags in_cohort] < 0} {
                $tree item $c -tags [concat $tags in_cohort]
            }
            render_row $c
        }
        if {[llength $sel_stems] > 0} {
            dict set opts stems $sel_stems
            $::log log "Dispatch cohort: [llength $sel_stems] stem(s)"
        }
    }

    set dispatching 1
    set ::paused 0
    ${tpanel}.dispatch.play configure -state disabled
    ${tpanel}.dispatch.pause configure -state normal -text "\u23f8 Pause"
    ${tpanel}.dispatch.cancel configure -state normal
    set ::aggregate_tick 0
    update_progress_display
    aggregate_animate
    update idletasks

    show_dispatch_bar
    $::log log "Dispatch requested: $label ($tid)"

    if {[catch {$runner $opts ui_on_progress ui_on_complete} err]} {
        $::log log "$tid dispatch error: $err"
        set dispatching 0
        set ::paused 0
        ${tpanel}.dispatch.play configure -state normal
        ${tpanel}.dispatch.pause configure -state disabled -text "\u23f8 Pause"
        ${tpanel}.dispatch.cancel configure -state disabled
        clear_cohort
    }
}

# TransitionTree fires dispatch-target-changed whenever the selection
# shifts in a way that affects the Dispatch button. The inline logic
# that used to walk parents/children and poke $play now lives in
# TransitionTree::_resolve_target; the subscriber below just applies
# the resolved {parent nchild label verb} tuple to the button.
$tree_obj subscribe dispatch-target-changed [list apply {{play parent nchild label verb} {
    if {$parent eq ""} {
        $play configure -state disabled -text "▶ Dispatch"
        return
    }
    if {$nchild > 0} {
        $play configure -state normal \
            -text "▶ ${verb}: $label ($nchild)"
    } else {
        $play configure -state normal -text "▶ Dispatch: $label"
    }
}} ${tpanel}.dispatch.play]

# Show the dispatch bar
show_dispatch_bar


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

# ============================================================
# Model subscriptions
# ============================================================
#
# Each subscriber pulls fresh data from the CampaignModel's accessors,
# mirrors the data into shim globals the still-procedural populate /
# recalc procs read, then invokes those procs. As each zone becomes a
# class in later commits, its subscriber inlines into the class's own
# event handler and the shim globals disappear.

$campaign subscribe fully-loaded [list apply {{} {
    set ::all_contacts   [$::campaign get_all_contacts]
    set ::warnings       [$::campaign get_warnings]
    set ::transitions    [$::campaign get_transitions]
    set ::full_load_done [$::campaign get_full_load_done]

    global wframe warn_summary warnings_expanded
    set warn_summary [compute_warning_summary]
    populate_warnings_text
    if {$warnings_expanded} {
        ${wframe}.toggle configure -text "▾ ⚠ [llength $::warnings] warnings ($warn_summary)"
    } else {
        ${wframe}.toggle configure -text "▸ ⚠ [llength $::warnings] warnings ($warn_summary)"
    }

    $::tree_obj populate

    # Headless / self-debug hook: if --tid was given on the command
    # line, drive the dispatch programmatically once the tree is
    # populated.
    global auto_tid
    if {$auto_tid ne ""} {
        after idle auto_dispatch
    }
}}]

$campaign subscribe refreshed [list apply {{} {
    set ::cdata          [$::campaign get_cdata]
    set ::campaign_name  [$::campaign get_campaign_name]
    set ::sender_text    [$::campaign get_sender_text]
    set ::filter_desc    [$::campaign get_filter_desc]
    set ::segments       [$::campaign get_segments]
    set ::all_contacts   [$::campaign get_all_contacts]
    set ::warnings       [$::campaign get_warnings]
    set ::transitions    [$::campaign get_transitions]
    set ::full_load_done [$::campaign get_full_load_done]

    global cf
    ${cf}.v1 configure -text $::campaign_name
    ${cf}.v2 configure -text $::sender_text
    ${cf}.v4 configure -text $::filter_desc
    wm title . "SPAR Campaign Manager — $::campaign_name"

    global wframe warn_summary warnings_expanded
    set warn_summary [compute_warning_summary]
    populate_warnings_text
    if {$warnings_expanded} {
        ${wframe}.toggle configure -text "▾ ⚠ [llength $::warnings] warnings ($warn_summary)"
    } else {
        ${wframe}.toggle configure -text "▸ ⚠ [llength $::warnings] warnings ($warn_summary)"
    }

    # TransitionTree self-subscribes to `refreshed` and rebuilds its tree;
    # no populate call needed here.
}}]

$campaign subscribe log-message [list $log log]

# Start async loading of filesystem-dependent columns. Use a timer
# (not after idle) so the window renders first.
after 1 [list $campaign start_async]

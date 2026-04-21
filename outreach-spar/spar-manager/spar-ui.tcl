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
        puts stderr "  --dry-run             dispatch with writes disabled (applies to --tid or right-click menu)"
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
set auto_dry_run 0
set log_to_stderr 0
foreach _a [lrange $argv 1 end] {
    if {[regexp {^--tid=(.+)$} $_a -> v]} { set auto_tid $v; continue }
    if {[regexp {^--stems=(.+)$} $_a -> v]} { set auto_stems [split $v ,]; continue }
    if {$_a eq "--dry-run"}     { set auto_dry_run 1; continue }
    if {$_a eq "--autoquit"}    { set auto_quit 1; set log_to_stderr 1; continue }
    if {$_a eq "--log-stderr"}  { set log_to_stderr 1; continue }
    puts stderr "spar-ui: unrecognised argument: $_a"
    exit 1
}
if {[llength $auto_stems] > 0 && $auto_tid eq ""} {
    puts stderr "spar-ui: --stems requires --tid"
    exit 1
}
if {$auto_dry_run && $auto_tid eq ""} {
    puts stderr "spar-ui: --dry-run only affects the --tid auto-dispatch path; right-click the Play button for the interactive dry-run menu"
    exit 1
}

# Source backend libraries
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]
source [file join $script_dir ui campaign-model.tcl]
source [file join $script_dir ui log-window.tcl]
source [file join $script_dir ui progress-table.tcl]
source [file join $script_dir ui transition-tree.tcl]
source [file join $script_dir ui dispatch-controller.tcl]
source [file join $script_dir ui utils.tcl]
source [file join $script_dir ui inspector.tcl]

# ============================================================
# Load campaign data
# ============================================================

# The CampaignModel owns campaign config, segment data, async-load state,
# and per-contact classification. Zones (ProgressTable, TransitionTree,
# DispatchController, warnings module, Inspector) subscribe to its events
# and call its accessors directly; no shim globals remain.
set campaign [spar::ui::CampaignModel new $campaign_file $script_dir]
$campaign load

# LogWindow owns the dispatch log buffer, the optional toplevel, and the
# unread counter. Construction takes log_to_stderr as config (never
# mutated internally). The toolbar badge subscribes to unread-changed.
set log [spar::ui::LogWindow new $log_to_stderr]

set campaign_name  [$campaign get_campaign_name]
set sender_text    [$campaign get_sender_text]
set filter_desc    [$campaign get_filter_desc]

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

ttk::panedwindow .pw -orient horizontal
pack .pw -fill both -expand 1

ttk::panedwindow .pw.main -orient vertical
.pw add .pw.main -weight 1

ttk::frame .pw.main.campaign
.pw.main add .pw.main.campaign -weight 3

ttk::frame .pw.main.transitions
.pw.main add .pw.main.transitions -weight 2

ttk::frame .pw.right
.pw add .pw.right -weight 0

set cpanel .pw.main.campaign
set tpanel .pw.main.transitions

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

ttk::button ${cpanel}.toolbar.legend -text "Legend" \
    -command ::spar::ui::legend::show
pack ${cpanel}.toolbar.legend -side right -padx {0 4}

ttk::button ${cpanel}.toolbar.selall -text "All" -width 4 \
    -command [list apply {{} { $::progress set_all 1 }}]
pack ${cpanel}.toolbar.selall -side left

ttk::button ${cpanel}.toolbar.selnone -text "None" -width 4 \
    -command [list apply {{} { $::progress set_all 0 }}]
pack ${cpanel}.toolbar.selnone -side left -padx {2 0}


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
#
# Stateless namespace helper (ui/ns.tcl). `build` constructs the widget
# tree and self-subscribes to the Campaign's refreshed + fully-loaded
# events so the warning count / summary auto-update. No state lives in
# the namespace; frame + campaign flow through closures.
::spar::ui::warnings::build $campaign $cpanel


# ============================================================
# Zone 3: Transition manager
# ============================================================

# TransitionTree encapsulates the transition treeview, the row_id →
# contact_name map, the stem → row_id map, the Show-completed
# checkbox, and <<TreeviewSelect>> / <Double-1> bindings. It
# subscribes to the CampaignModel's `refreshed` event in its
# constructor so refreshes rebuild the tree without extra wiring.
set tree_obj [spar::ui::TransitionTree new $campaign $tpanel]
$tree_obj populate

# Dispatch controls
ttk::frame ${tpanel}.dispatch
pack ${tpanel}.dispatch -side bottom -fill x -padx 4 -pady {0 4} -before ${tpanel}.treeframe

# Buttons created disabled; DispatchController's constructor wires the
# -command callbacks to its dispatch / pause / cancel methods.
ttk::button ${tpanel}.dispatch.play   -text "\u25b6 Dispatch" -state disabled
ttk::button ${tpanel}.dispatch.pause  -text "\u23f8 Pause"    -state disabled
ttk::button ${tpanel}.dispatch.cancel -text "\u2715 Cancel"   -state disabled

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

# DispatchController owns the cohort dicts, dispatch lifecycle,
# progress-bar animation, pause/cancel, and the headless auto_dispatch
# entry point. It wires the Play / Pause / Cancel buttons in its
# constructor and subscribes to Campaign (refreshed, fully-loaded) and
# TransitionTree (dispatch-target-changed) for its own lifecycle.
#
# Circular wire: TransitionTree's _resolve_target needs to read
# is_dispatching, and DispatchController's subscribers and update_row
# calls need the tree. Construct the tree first, then the controller,
# then back-fill the tree with set_dispatch.
set dispatch [spar::ui::DispatchController new \
    $campaign $tree_obj $log \
    ${tpanel}.dispatch.play \
    ${tpanel}.dispatch.pause \
    ${tpanel}.dispatch.cancel \
    ${tpanel}.dispatch.progress \
    $script_dir $campaign_file \
    $auto_tid $auto_stems $auto_quit $auto_dry_run]

$tree_obj set_dispatch $dispatch

$dispatch show_dispatch_bar

# Inspector scaffold (#66). Subscribes to TransitionTree's
# selection-changed and double-clicked events so the wiring exists
# from day one; the actual pane construction + render methods are
# issue #66 and are empty stubs in the scaffold.
set inspector [spar::ui::Inspector new $campaign $tree_obj .pw]


# ============================================================
# Initial sash position
# ============================================================

bind .pw <Map> {
    after 50 {
        set w [winfo width .pw]
        if {$w > 100} {
            .pw sashpos 0 $w
        }
    }
    bind .pw <Map> {}
}

bind .pw.main <Map> {
    after 50 {
        set h [winfo height .pw.main]
        if {$h > 100} {
            .pw.main sashpos 0 [expr {int($h * 0.65)}]
        }
    }
    bind .pw.main <Map> {}
}

# ============================================================
# Model subscriptions
# ============================================================
#
# Every refactored zone self-subscribes to the Campaign events it cares
# about. The two things left here are:
#   - the config-summary labels (cf.v1/v2/v4) + window title, which
#     belong to this bootstrap and have no owning class;
#   - a kick to TransitionTree on `fully-loaded` (it self-subscribes to
#     `refreshed` but not `fully-loaded`, and the first populate against
#     the post-async transitions list lives here).
# log-message is piped straight into the LogWindow.

$campaign subscribe fully-loaded [list $tree_obj populate]

$campaign subscribe refreshed [list apply {{} {
    global cf
    ${cf}.v1 configure -text [$::campaign get_campaign_name]
    ${cf}.v2 configure -text [$::campaign get_sender_text]
    ${cf}.v4 configure -text [$::campaign get_filter_desc]
    wm title . "SPAR Campaign Manager — [$::campaign get_campaign_name]"
}}]

$campaign subscribe log-message [list $log log]

# Start async loading of filesystem-dependent columns. Use a timer
# (not after idle) so the window renders first.
after 1 [list $campaign start_async]

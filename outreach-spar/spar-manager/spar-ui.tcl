#!/usr/bin/env wish9.0
# SPAR Campaign Manager — Live UI

package require Tk

# Load timer baseline. Reset on each `reloading` so refreshes are also
# measured. fully-loaded subscriber prints elapsed to stderr — used to
# compare loader strategies branch-to-branch.
set ::load_kickoff_time [clock microseconds]

# Cache the launch directory before anything that might cd. The
# campaign-open dialog uses this when no campaign has been loaded yet,
# so it opens in the directory the user invoked the app from rather
# than wherever Tk's default would land.
set startup_pwd [pwd]

# ============================================================
# Argv parsing
# ============================================================
#
# Positional argument:
#   *.yaml file → mount that campaign directly
#   directory   → open the file picker rooted there at startup
#   absent      → launch into the welcome state
#
# Subsequent flags (--tid, --autoquit, etc.) drive non-interactive
# auto-dispatch and require a campaign-file positional argument; they
# are not meaningful from the welcome-state path.

set initial_arg ""
if {[llength $argv] > 0} { set initial_arg [lindex $argv 0] }

set initial_mode ""
set initial_path ""
set initial_dir  ""

if {$initial_arg ne ""} {
    set _norm [file normalize $initial_arg]
    if {[string match *.yaml $initial_arg]} {
        if {![file isfile $_norm]} {
            puts stderr "spar-ui: campaign YAML not found: $initial_arg"
            exit 1
        }
        set initial_mode "file"
        set initial_path $_norm
    } else {
        if {![file isdirectory $_norm]} {
            puts stderr "spar-ui: not a YAML file or directory: $initial_arg"
            exit 1
        }
        set initial_mode "folder"
        set initial_dir $_norm
    }
} else {
    set initial_mode "none"
}

# Non-interactive / debug flags: parse remaining argv.
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
if {$auto_tid ne "" && $initial_mode ne "file"} {
    puts stderr "spar-ui: --tid requires a campaign YAML file as the positional argument"
    exit 1
}

# Cache the absolute script path for the loaded-state relaunch path.
set script_path [file normalize [info script]]
set script_dir  [file dirname $script_path]

# ============================================================
# Source backend libraries
# ============================================================

source [file join $script_dir spar-state.tcl]
source [file join $script_dir spar-dispatcher.tcl]
source [file join $script_dir ui campaign-model.tcl]
source [file join $script_dir ui log-window.tcl]
source [file join $script_dir ui progress-table.tcl]
source [file join $script_dir ui transition-tree.tcl]
source [file join $script_dir ui dispatch-controller.tcl]
source [file join $script_dir ui utils.tcl]
source [file join $script_dir ui collapsible.tcl]
source [file join $script_dir ui inspector.tcl]
source [file join $script_dir ui segment-viewer.tcl]
source [file join $script_dir ui settings.tcl]

# ============================================================
# Colour palette
# ============================================================

set colours(hdr_bottom)  "#f8f9fa"
set colours(totals_bg)   "#e2e2e2"
set colours(muted_fg)    "#999999"

# ============================================================
# Window title and icon
# ============================================================

set _icon_path [file join $script_dir icon.svg]
if {[file exists $_icon_path]} {
    image create photo ::spar_icon -format {svg -scaletoheight 128} -file $_icon_path
    wm iconphoto . -default ::spar_icon
}
wm title . "SPAR Campaign Manager"

# ============================================================
# Persistent header strip
# ============================================================
#
# Mounted once and present in both welcome and loaded states. The
# left button opens the campaign picker — same control, same
# position, same handler in both states. The window title carries
# the campaign name in the loaded state.

namespace eval ::spar::ui {}

ttk::frame .header
pack .header -side top -fill x

ttk::button .header.open -text "Open campaign…" \
    -command ::spar::ui::request_open
pack .header.open -side left -padx {6 4} -pady 4

ttk::separator .headersep -orient horizontal
pack .headersep -side top -fill x

bind . <Control-o> {::spar::ui::request_open; break}

# ============================================================
# Open / mount / welcome
# ============================================================

# Pop the file-open dialog with the campaign-file filters. Returns
# the picked absolute path, or "" if the user cancelled. The
# init_dir argument decides the starting directory; pass "" to let
# Tk choose (typically the last-used location).
proc ::spar::ui::pick_campaign_file {{init_dir ""}} {
    set filetypes {
        {{Campaign files} {campaign*.yaml}}
        {{All YAML}       {*.yaml}}
    }
    set opts [list -filetypes $filetypes -title "Open campaign"]
    if {$init_dir ne ""} { lappend opts -initialdir $init_dir }
    return [tk_getOpenFile {*}$opts]
}

# Where the open dialog should root depends on state:
#   loaded  → the directory of the campaign loaded at startup
#   welcome → the directory the user launched the app from
proc ::spar::ui::dialog_initial_dir {} {
    global startup_pwd initial_path
    if {$initial_path ne ""} {
        return [file dirname $initial_path]
    }
    return $startup_pwd
}

# User asked to open a campaign (header button or Ctrl+O). Open the
# dialog; on a pick, relaunch the process with the picked file as
# argv. Cancel is a no-op.
proc ::spar::ui::request_open {} {
    set picked [pick_campaign_file [dialog_initial_dir]]
    if {$picked eq ""} { return }
    relaunch $picked
}

# Re-exec the script with $path as argv. Used for every transition
# into the loaded state from a running process — welcome → loaded,
# folder-argv → loaded, and loaded → loaded. The new process takes
# the file-argv startup path and so builds the loaded UI before the
# event loop runs, which is the only sequence that gives the WM a
# correct first-map size. Re-execing also guarantees a clean slate
# (no half-torn-down OO objects, no stale subscriptions, no in-flight
# async loads or dispatches).
proc ::spar::ui::relaunch {path} {
    global script_path
    exec [info nameofexecutable] $script_path $path &
    exit 0
}

# Render the welcome state — icon, title, tagline, and a short
# introduction grounded in the project's own description of what
# SPAR is. The only campaign-open control is the header button
# above. The welcome screen is one-shot per process: when the user
# picks a campaign, the process re-execs into the loaded state.
proc ::spar::ui::mount_welcome {} {
    foreach w [winfo children .] {
        if {$w eq ".header" || $w eq ".headersep"} { continue }
        destroy $w
    }

    ttk::frame .welcome
    pack .welcome -fill both -expand 1

    if {[lsearch -exact [image names] "::spar_icon"] >= 0} {
        ttk::label .welcome.icon -image ::spar_icon
        pack .welcome.icon -pady {32 16}
    }

    ttk::label .welcome.title \
        -text "SPAR Campaign Manager" \
        -font "TkHeadingFont"
    pack .welcome.title -pady {0 4}

    ttk::label .welcome.tagline \
        -text "Search · Profile · Approach · Revise" \
        -foreground "#666666"
    pack .welcome.tagline -pady {0 26}

    ttk::label .welcome.intro -justify left -text \
"SPAR is an AI-executed methodology for outreach discovery and
engagement, organised in four phases: Search, Profile, Approach,
Revise. The methodology is domain-agnostic — campaign-specific
content lives in each campaign's YAML and roster.

This application loads a SPAR campaign, classifies its roster
contacts by their progress through the pipeline, surfaces
duplicates and other warnings, and dispatches the outreach
messages."
    pack .welcome.intro -padx 48 -pady {0 36}
}

# build_loaded_body — construct the loaded-state widget tree and wire
# model subscriptions for $path. Single-shot per process: the welcome
# → loaded transition calls this once; subsequent campaign switches
# go through mount_campaign's exec-relaunch path.
proc ::spar::ui::build_loaded_body {path} {
    global script_dir colours
    global campaign log progress tree_obj dispatch inspector segviewer
    global cf cpanel tpanel
    global auto_tid auto_stems auto_quit auto_dry_run log_to_stderr

    # The CampaignModel owns campaign config, segment data, async-load
    # state, and per-contact classification. Zones (ProgressTable,
    # TransitionTree, DispatchController, warnings module, Inspector)
    # subscribe to its events and call its accessors directly.
    set campaign [spar::ui::CampaignModel new $path $script_dir]
    $campaign load

    # Load timer wiring. reloading resets the kickoff stamp so each
    # refresh measures its own latency; fully-loaded prints elapsed.
    # When `--autoquit` was given without `--tid`, exit after the first
    # fully-loaded — used to compare loader strategies across branches.
    $campaign subscribe reloading [list apply {{} {
        set ::load_kickoff_time [clock microseconds]
    }}]
    $campaign subscribe fully-loaded [list apply {{} {
        global auto_tid auto_quit
        set us [expr {[clock microseconds] - $::load_kickoff_time}]
        puts stderr [format "\[load-timer\] fully-loaded in %.2fs" \
            [expr {$us / 1000000.0}]]
        if {$auto_quit && $auto_tid eq ""} { exit 0 }
    }}]

    # LogWindow owns the dispatch log buffer, the optional toplevel,
    # and the unread counter. The toolbar badge subscribes to
    # unread-changed.
    set log [spar::ui::LogWindow new $log_to_stderr]

    set campaign_name [$campaign get_campaign_name]
    set sender_text   [$campaign get_sender_text]
    set filter_desc   [$campaign get_filter_desc]

    wm title . "SPAR Campaign Manager — $campaign_name"

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

    # Toolbar: Refresh, Legend, Select All/None, gear + status (via settings module)
    ttk::frame ${cpanel}.toolbar
    pack ${cpanel}.toolbar -fill x -padx 8 -pady {2 2}

    ::spar::ui::settings::build_status $campaign ${cpanel}.toolbar

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

    # ProgressTable encapsulates the progress treeview, its column
    # config, per-segment count snapshots, checkbox state, totals row,
    # and the "..." placeholders shown while async classification is
    # in flight. It subscribes to the CampaignModel's segment-loaded /
    # fully-loaded / reloading events in its constructor, so refreshes
    # propagate without extra wiring here.
    set progress [spar::ui::ProgressTable new $campaign ${cpanel}.progress]
    $progress populate

    # --- 2.3 Warnings (collapsed by default) ---
    ::spar::ui::warnings::build $campaign $cpanel

    # ============================================================
    # Zone 3: Transition manager
    # ============================================================

    # TransitionTree encapsulates the transition treeview, the row_id
    # → contact_name map, the stem → row_id map, the Show-completed
    # checkbox, and <<TreeviewSelect>> / <Double-1> bindings. It
    # subscribes to the CampaignModel's `reloading` and
    # `transition-loaded` events so the tree clears and refills as the
    # loader coroutine produces tids.
    set tree_obj [spar::ui::TransitionTree new $campaign $tpanel]
    $tree_obj populate

    # Dispatch controls
    ttk::frame ${tpanel}.dispatch
    pack ${tpanel}.dispatch -side bottom -fill x -padx 4 -pady {0 4} -before ${tpanel}.treeframe

    ttk::button ${tpanel}.dispatch.play   -text "▶ Dispatch" -state disabled
    ttk::button ${tpanel}.dispatch.pause  -text "⏸ Pause"    -state disabled
    ttk::button ${tpanel}.dispatch.cancel -text "✕ Cancel"   -state disabled

    pack ${tpanel}.dispatch.play   -side left -padx {0 4}
    pack ${tpanel}.dispatch.pause  -side left -padx {0 4}
    pack ${tpanel}.dispatch.cancel -side left -padx {0 8}

    ttk::frame       ${tpanel}.dispatch.progress
    ttk::progressbar ${tpanel}.dispatch.progress.bar -mode determinate -value 0
    ttk::label       ${tpanel}.dispatch.progress.status -text "" -anchor w
    pack ${tpanel}.dispatch.progress.bar    -fill x -expand 1
    pack ${tpanel}.dispatch.progress.status -fill x
    ttk::button ${tpanel}.dispatch.logbtn -text "Log…" -command [list $log show]

    # Badge: LogWindow fires unread-changed whenever the count shifts.
    $log subscribe unread-changed [list apply {{count} {
        global tpanel
        set text [expr {$count ? "Log… •" : "Log…"}]
        ${tpanel}.dispatch.logbtn configure -text $text
    }}]

    # spar::Dispatcher (the GUI's mixed-type job pool) is constructed
    # once per process; it outlives campaign refreshes. The Controller's
    # on_fully_loaded handler calls prune_missing + reapply_pool_state
    # so refreshed views inherit the surviving Pool state. jobs=4
    # matches the prior CLI default in spar::p::run.
    set ::pool [spar::Dispatcher new 4 [list $log log]]

    # DispatchController translates Play/Pause/Cancel and the right-
    # click menu into Pool methods, and renders Pool row-state events
    # back onto the TransitionTree.
    #
    # Circular wire: TransitionTree's _resolve_target needs to read
    # is_dispatching, and DispatchController's subscribers and
    # update_row calls need the tree. Construct the tree first, then
    # the controller, then back-fill the tree with set_dispatch.
    set dispatch [spar::ui::DispatchController new \
        $campaign $tree_obj $log $::pool \
        ${tpanel}.dispatch.play \
        ${tpanel}.dispatch.pause \
        ${tpanel}.dispatch.cancel \
        ${tpanel}.dispatch.progress \
        $script_dir $path \
        $auto_tid $auto_stems $auto_quit $auto_dry_run]

    $tree_obj set_dispatch $dispatch

    $dispatch show_dispatch_bar

    # Inspector scaffold (#66). Subscribes to TransitionTree's
    # selection-changed and double-clicked events so the wiring exists
    # from day one.
    set inspector [spar::ui::Inspector new $campaign $tree_obj .pw]

    # SegmentViewer — opens on Double-1 in the progress table. Shares
    # `.pw.right` with Inspector via cross `shown` subscriptions: each
    # hides itself when the other shows, so the pane carries one or the
    # other but not both.
    set segviewer [spar::ui::SegmentViewer new $campaign $progress .pw]
    $inspector subscribe shown [list $segviewer displace]
    $segviewer subscribe shown [list $inspector displace]

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
    # Every refactored zone self-subscribes to the Campaign events it
    # cares about. The only thing left here is the config-summary
    # labels (cf.v1/v2/v4) + window title, which belong to this
    # bootstrap and have no owning class. log-message is piped straight
    # into the LogWindow.

    $campaign subscribe reloading [list apply {{} {
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
}

# ============================================================
# Decide initial state
# ============================================================

switch -- $initial_mode {
    file {
        ::spar::ui::build_loaded_body $initial_path
    }
    folder {
        set _picked [::spar::ui::pick_campaign_file $initial_dir]
        if {$_picked ne ""} {
            ::spar::ui::relaunch $_picked
        } else {
            ::spar::ui::mount_welcome
        }
    }
    none {
        ::spar::ui::mount_welcome
    }
}

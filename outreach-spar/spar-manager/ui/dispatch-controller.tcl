# spar-manager/ui/dispatch-controller.tcl
#
# spar::ui::DispatchController — owns the dispatch lifecycle and its
# entire state cluster: cohort dicts, pause/cancel flags, the aggregate
# progress-bar animation, the Play / Pause / Cancel buttons, and the
# auto_dispatch headless entry point.
#
# It consumes the TransitionTree's selection + row-update API and the
# CampaignModel's refresh-lifecycle events, and wires a spar::Dispatcher
# (indirectly, via the transition runner) to its own on_progress /
# on_complete methods. No other code reads or writes cohort state.
#
# Circular wire: DispatchController needs TransitionTree at construction
# (subscribe + update_row), and TransitionTree's _resolve_target needs to
# ask the controller `is_dispatching`. We resolve by constructing
# TransitionTree first and back-filling via $transitions set_dispatch.
#
# TclOO leading-underscore reminder: methods invoked externally (via
# after, -command, [list [self] …] as an event callback) MUST NOT start
# with an underscore — TclOO will not export them. Helpers called only
# via `my` are fine with _.
#
# Events fired:
#   row-changed {stem state reason}
#       after a cohort row's state/reason updates. Internal wiring calls
#       $transitions update_row directly; this event exists for future
#       subscribers.
#   progress-changed {done total}
#       after each cohort progress recompute.
#   dispatch-started {tid}
#       dispatch has been handed to the transition runner.
#   dispatch-ended {tid done failed}
#       on_complete has fired.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::DispatchController {
    variable Campaign Transitions Log
    variable PlayBtn PauseBtn CancelBtn ProgressFrame
    variable AutoTid AutoStems AutoQuit AutoDryRun ScriptDir CampaignFile
    variable PlayMenu LastWasDryRun

    variable CohortStems CohortState CohortReason CohortPhase
    variable ClassifySnapshot
    variable Dispatching Paused
    variable AggregateTick AggregateAfter AggregateFrames
    variable Subs

    constructor {campaign transitions log \
                 play_btn pause_btn cancel_btn progress_frame \
                 script_dir campaign_file \
                 auto_tid auto_stems auto_quit {auto_dry_run 0}} {
        set Campaign       $campaign
        set Transitions    $transitions
        set Log            $log
        set PlayBtn        $play_btn
        set PauseBtn       $pause_btn
        set CancelBtn      $cancel_btn
        set ProgressFrame  $progress_frame
        set ScriptDir      $script_dir
        set CampaignFile   $campaign_file
        set AutoTid        $auto_tid
        set AutoStems      $auto_stems
        set AutoQuit       $auto_quit
        set AutoDryRun     $auto_dry_run
        set LastWasDryRun  0

        set CohortStems      {}
        set CohortState      [dict create]
        set CohortReason     [dict create]
        set CohortPhase      [dict create]
        set ClassifySnapshot [dict create]

        set Dispatching 0
        set Paused      0

        set AggregateTick  0
        set AggregateAfter ""
        set AggregateFrames [list ⠋ ⠙ ⠹ ⠸ ⠼ \
                                  ⠴ ⠦ ⠧ ⠇ ⠏]

        set Subs [dict create]

        # Wire buttons to controller methods.
        $PlayBtn   configure -command [list [self] dispatch]
        $PauseBtn  configure -command [list [self] pause]
        $CancelBtn configure -command [list [self] cancel]

        # Right-click on the Play button opens a menu with live/dry-run
        # variants. Dry-run is not a common need, so we keep it off the
        # primary button surface. `<Button-3>` on a ttk::button still
        # fires bindings regardless of the button's enabled state; the
        # handler checks is_dispatching / the Play state before popping.
        set PlayMenu ${play_btn}.menu
        menu $PlayMenu -tearoff 0
        $PlayMenu add command -label "Dispatch (live)" \
            -command [list [self] dispatch 0]
        $PlayMenu add command -label "Dispatch (dry run — writes disabled)" \
            -command [list [self] dispatch 1]
        bind $PlayBtn <Button-3> [list [self] on_play_menu %X %Y]

        # Subscribe to Campaign lifecycle. reapply_cohort runs from
        # on_fully_loaded since it needs the tree to be fully populated.
        $Campaign subscribe fully-loaded [list [self] on_fully_loaded]

        # Subscribe to TransitionTree selection shifts — drives the Play
        # button's enable/disable + label.
        $Transitions subscribe dispatch-target-changed \
            [list [self] on_target_changed]
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method is_dispatching {} { return $Dispatching }

    # ─── Public entry points ──────────────────────────────────────────────

    # show_dispatch_bar — pack the progress frame and the Log button into
    # the dispatch row. Called once at startup, public because the
    # bootstrap invokes it.
    method show_dispatch_bar {} {
        pack $ProgressFrame -side left -fill x -expand 1 -padx {8 4}
        # The Log button is a sibling of the progress frame in the
        # dispatch row; its path is derived from ProgressFrame's parent.
        set parent [winfo parent $ProgressFrame]
        if {[winfo exists ${parent}.logbtn]} {
            pack ${parent}.logbtn -side left
        }
    }

    # dispatch — replaces do_dispatch. Reads tree selection, builds
    # cohort, invokes the runner for the selected transition.
    #
    # dry_run (default 0): when 1, runners receive dry_run=1 and skip
    # their write side (email send, YAML append, profile write, etc.)
    # while still producing per-row progress so the cohort view shows
    # what WOULD transition.
    method dispatch {{dry_run 0}} {
        if {$Dispatching} return
        set LastWasDryRun $dry_run

        set tree [$Transitions get_tree_widget]
        set sel [$tree selection]
        if {[llength $sel] == 0} return

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
        regsub {\s*\(\d+\)\s*$} $label "" label

        # Tree item id (t0..t6) to T-id. Ordering is driven by the
        # transition registry in spar-state.tcl (populated from the
        # per-class files) — CampaignModel's _build_transitions reads
        # the same list.
        set tnum [string range $parent 1 end]
        set tids [spar::ui_transition_tids]
        set tid [lindex $tids $tnum]

        foreach lib {spar-dispatch.tcl spar-email.tcl} {
            set path [file join $ScriptDir $lib]
            if {![file exists $path]} {
                $Log log "Dispatch library not available ($lib not found)."
                return
            }
            if {[catch {uplevel #0 [list source $path]} err]} {
                $Log log "Error loading $lib: $err"
                return
            }
        }

        if {![spar::has_transition_runner $tid]} {
            $Log log "Dispatch for $tid not implemented."
            return
        }
        set runner [spar::transition_runner $tid]

        set opts [dict create \
            campaign_file $CampaignFile \
            dry_run $dry_run \
            jobs 4]

        # Clear the previous cohort so its terminal glyphs are wiped.
        my clear

        # Parent-only selection: the implicit cohort is every child.
        if {[llength $child_items] == 0} {
            set child_items [$tree children $parent]
        }

        if {[llength $child_items] > 0} {
            set sel_stems {}
            foreach c $child_items {
                set s [$tree set $c stem]
                if {$s eq ""} continue
                lappend sel_stems $s
                lappend CohortStems $s
                dict set CohortState $s queued
                dict set ClassifySnapshot $s [list \
                    [$tree set $c state] \
                    [$tree set $c reason]]
                set tags [$tree item $c -tags]
                if {[lsearch -exact $tags in_cohort] < 0} {
                    $tree item $c -tags [concat $tags in_cohort]
                }
                my _render_row $s
            }
            if {[llength $sel_stems] > 0} {
                dict set opts stems $sel_stems
                $Log log "Dispatch cohort: [llength $sel_stems] stem(s)"
            }
        }

        # Call build_opts so transition-specific keys (e.g. T6's `tasks`)
        # are populated — mirrors the CLI's dispatch_ready path. Filter
        # eligible contacts down to the selected stems so only the
        # user's selection is dispatched, not the entire campaign.
        set cdata [$Campaign get_cdata]
        set primary_channel ""
        if {[dict size $cdata] > 0} {
            set primary_channel [spar::campaign_primary_channel $cdata]
        }
        set eligible [[$Campaign get_state] transition_eligible \
            [$Campaign get_all_contacts] $tid $primary_channel $cdata]
        if {[llength $sel_stems] > 0} {
            set stem_set [dict create]
            foreach s $sel_stems { dict set stem_set $s 1 }
            set filtered {}
            foreach c $eligible {
                if {[dict exists $stem_set [spar::dict_get_default $c stem ""]]} {
                    lappend filtered $c
                }
            }
            set eligible $filtered
        }
        set cls [::spar::transitions::get $tid]
        set extra [$cls build_opts $eligible {} {}]
        if {[dict exists $extra log_message]} {
            $Log log [dict get $extra log_message]
            set extra [dict remove $extra log_message]
        }
        set opts [dict merge $opts $extra]

        # Batch confirmation for transitions that send externally (e.g. T6
        # email). One dialog for the whole cohort instead of per-item popups.
        if {!$dry_run} {
            set cls [::spar::transitions::get $tid]
            if {[$cls requires_send_confirmation]} {
                set n [llength $CohortStems]
                set answer [tk_messageBox -title "Confirm Send" \
                    -icon question -type yesno \
                    -message "Send $n email(s) via $label ($tid)?" \
                    -detail "Press Yes to proceed, No to cancel."]
                if {$answer ne "yes"} {
                    $Log log "Dispatch cancelled by user."
                    my clear
                    return
                }
            }
        }

        set Dispatching 1
        set Paused      0
        $PlayBtn   configure -state disabled
        $PauseBtn  configure -state normal   -text "⏸ Pause"
        $CancelBtn configure -state normal
        set AggregateTick 0
        my _update_progress_display
        my aggregate_animate

        my show_dispatch_bar
        set mode_tag [expr {$dry_run ? " (DRY RUN — writes disabled)" : ""}]
        $Log log "Dispatch requested: $label ($tid)$mode_tag"

        my _fire dispatch-started $tid

        if {[catch {{*}$runner $opts \
                [list [self] on_progress] \
                [list [self] on_complete]} err]} {
            $Log log "$tid dispatch error: $err"
            set Dispatching 0
            set Paused      0
            $PlayBtn   configure -state normal
            $PauseBtn  configure -state disabled -text "⏸ Pause"
            $CancelBtn configure -state disabled
            my clear
        }
    }

    # pause / resume toggle. `pause` is the button handler and flips
    # based on the current Paused flag — matches the old do_pause which
    # both pauses and resumes.
    method pause {} {
        if {!$Paused} {
            spar::pause_all
            set Paused 1
            $PauseBtn configure -text "▶ Resume"
            $Log log "Dispatch paused: queued items held; in-flight items finish normally."
        } else {
            spar::resume_all
            set Paused 0
            $PauseBtn configure -text "⏸ Pause"
            $Log log "Dispatch resumed."
        }
    }

    # resume — explicit method so callers that know they want to resume
    # don't have to rely on the pause-as-toggle contract.
    method resume {} {
        if {$Paused} { my pause }
    }

    method cancel {} {
        spar::cancel_all
        $Log log "Dispatch cancelled: queued items skipped; in-flight items finish normally."
    }

    # auto_dispatch — headless / self-debug entry point. Called from the
    # fully-loaded event handler when --tid was given on the command line.
    # Consumes AutoTid so subsequent fully-loaded events (post-dispatch
    # refresh) do not retrigger.
    method auto_dispatch {} {
        set target $AutoTid
        set AutoTid ""
        set tree [$Transitions get_tree_widget]
        set tids [spar::ui_transition_tids]
        set idx [lsearch -exact $tids $target]
        if {$idx < 0} {
            puts stderr "spar-ui: --tid=$target is not one of: [join $tids {, }]"
            if {$AutoQuit} { exit 1 }
            return
        }
        set parent "t$idx"
        if {![$tree exists $parent]} {
            puts stderr "spar-ui: transition $target has no tree row (not populated?)"
            if {$AutoQuit} { exit 1 }
            return
        }
        set children [$tree children $parent]
        if {[llength $children] == 0} {
            puts stderr "spar-ui: transition $target has zero eligible contacts"
            if {$AutoQuit} { exit 0 }
            return
        }

        if {[llength $AutoStems] > 0} {
            set matches {}
            set all_stems {}
            foreach c $children {
                set s [$tree set $c stem]
                lappend all_stems $s
                if {$s in $AutoStems} { lappend matches $c }
            }
            if {[llength $matches] == 0} {
                puts stderr "spar-ui: none of --stems=[join $AutoStems ,] matched the $target tree."
                puts stderr "spar-ui: available stems under $target: [join $all_stems {, }]"
                if {$AutoQuit} { exit 1 }
                return
            }
            set missing {}
            foreach s $AutoStems {
                set found 0
                foreach c $matches {
                    if {[$tree set $c stem] eq $s} { set found 1; break }
                }
                if {!$found} { lappend missing $s }
            }
            if {[llength $missing] > 0} {
                puts stderr "spar-ui: --stems not found under $target: [join $missing {, }]"
            }
            $tree selection set $matches
        } else {
            $tree selection set [list $parent]
        }
        event generate $tree <<TreeviewSelect>>
        update
        my dispatch $AutoDryRun
    }

    # on_play_menu — right-click handler on the Play button. Pops the
    # live/dry-run menu, but only when there is something dispatchable
    # (mirrors the Play button's own enabled state).
    method on_play_menu {x_screen y_screen} {
        if {$Dispatching} return
        if {[$PlayBtn cget -state] ne "normal"} return
        tk_popup $PlayMenu $x_screen $y_screen
    }

    # on_progress — Dispatcher callback. Status ∈ {started, done, failed,
    # skipped, warning}. Public because it's invoked via [list [self]
    # on_progress] from the runner.
    method on_progress {slug status message} {
        # Phase markers are row state, not log events.
        if {[regexp {\[phase:\s*([^\]]+)\]} $message -> phase]} {
            if {[dict exists $CohortState $slug]} {
                dict set CohortPhase $slug [string trim $phase]
                my _render_row $slug
            }
            return
        }
        # Runner emits "skipped" for rows it pre-filters (approach
        # exists, excluded, wrong channel). Non-cohort skips are noise
        # when the user narrowed the cohort — suppress from the log.
        if {$status eq "skipped" && ![dict exists $CohortState $slug]} {
            return
        }
        if {[dict exists $CohortState $slug]} {
            set prev [dict get $CohortState $slug]
            set changed 0
            switch -- $status {
                started {
                    if {$prev ne "running"} {
                        dict set CohortState $slug running
                        set changed 1
                        if {$AggregateAfter eq ""} { my aggregate_animate }
                    }
                    set m [string trim $message]
                    if {$m ne ""} { dict set CohortReason $slug $m }
                }
                done {
                    dict set CohortState $slug done
                    dict set CohortReason $slug [clock format [clock seconds] -format "%H:%M"]
                    set changed 1
                }
                failed {
                    dict set CohortState $slug failed
                    set r [string trim $message]
                    if {$r eq ""} {
                        set r [expr {[dict exists $CohortReason $slug] ? [dict get $CohortReason $slug] : "unknown"}]
                    }
                    if {[string length $r] > 80} { set r "[string range $r 0 77]…" }
                    dict set CohortReason $slug $r
                    set changed 1
                }
                skipped {
                    if {[string trim $message] eq "cancelled"} {
                        dict set CohortState $slug cancelled
                    } else {
                        dict set CohortState $slug skipped
                        dict set CohortReason $slug [string trim $message]
                    }
                    set changed 1
                }
                warning {
                    # LogWindow.log will bump unread on its own.
                }
            }
            if {$changed} {
                my _render_row $slug
                set st     [dict get $CohortState $slug]
                set reason [expr {[dict exists $CohortReason $slug] \
                                    ? [dict get $CohortReason $slug] : ""}]
                my _fire row-changed $slug $st $reason
            }
        }
        my _update_progress_display
        # Suppress the dispatcher's empty "started" kickoff from the log
        # — already reflected in the row's running state.
        if {!($status eq "started" && $message eq "")} {
            $Log log "  \[$status\] $slug $message"
        }
    }

    # on_complete — final callback from the Dispatcher / transition runner.
    method on_complete {done failed result} {
        set Dispatching 0
        set Paused      0
        $PlayBtn   configure -state normal
        $PauseBtn  configure -state disabled -text "⏸ Pause"
        $CancelBtn configure -state disabled

        # Stop the aggregate spinner but keep cohort dicts — terminal
        # per-row glyphs persist until the next dispatch clears them.
        if {$AggregateAfter ne ""} {
            after cancel $AggregateAfter
            set AggregateAfter ""
        }

        set skipped [spar::dict_get_default $result skipped 0]
        set count   [spar::dict_get_default $result count 0]
        set tail ""
        if {$skipped ne "" && $skipped > 0} { append tail ", $skipped skipped" }
        if {$count ne "" && $count == 0 && $done == 0 && $failed == 0} {
            append tail " (no rows matched the runner's filters — check in-scope channel, min_star, or that the approach file already exists)"
        }
        set mode_tag [expr {$LastWasDryRun ? " (dry run — no writes)" : ""}]
        set summary "Dispatch completed: $done done, $failed failed$tail$mode_tag."
        $Log log $summary

        # Pop up a summary before resetting the progress bar.
        tk_messageBox -title "Dispatch Complete" \
            -icon info -type ok -message $summary

        $Campaign refresh
        my clear

        # Kick the tree so the dispatch-target-changed subscriber
        # re-evaluates the Play button now that Dispatching is 0.
        set tree [$Transitions get_tree_widget]
        event generate $tree <<TreeviewSelect>>

        my _fire dispatch-ended "" $done $failed

        if {$AutoQuit} {
            update
            exit [expr {$failed > 0 ? 1 : 0}]
        }
    }

    # clear — empty the cohort dicts, cancel animation, restore prior
    # classify state/reason on rows leaving the cohort. Replaces
    # clear_cohort.
    method clear {} {
        if {$AggregateAfter ne ""} {
            after cancel $AggregateAfter
            set AggregateAfter ""
        }
        set AggregateTick 0

        set tree       [$Transitions get_tree_widget]
        set row_names  [$Transitions get_row_names]
        set slug_to_row [$Transitions get_slug_to_row]

        foreach s $CohortStems {
            if {![dict exists $slug_to_row $s]} continue
            set row_id [dict get $slug_to_row $s]
            if {![$tree exists $row_id]} continue
            set tags [$tree item $row_id -tags]
            set idx [lsearch -exact $tags in_cohort]
            if {$idx >= 0} {
                $tree item $row_id -tags [lreplace $tags $idx $idx]
            }
            set name [expr {[dict exists $row_names $row_id] \
                              ? [dict get $row_names $row_id] : ""}]
            $tree item $row_id -text "  $name"
            if {[dict exists $ClassifySnapshot $s]} {
                lassign [dict get $ClassifySnapshot $s] cs cr
                $tree set $row_id state  $cs
                $tree set $row_id reason $cr
            }
        }
        set CohortStems      {}
        set CohortState      [dict create]
        set CohortReason     [dict create]
        set CohortPhase      [dict create]
        set ClassifySnapshot [dict create]
        my _update_progress_display
    }

    # reapply_cohort — after a refresh rebuilds the tree (new row ids),
    # re-snapshot classify state and re-render cohort rows so terminal
    # glyphs survive the refresh. Replaces reapply_cohort_after_refresh.
    method reapply_cohort {} {
        set ClassifySnapshot [dict create]
        if {[llength $CohortStems] == 0} return

        set tree [$Transitions get_tree_widget]
        set stem_set [dict create]
        foreach s $CohortStems { dict set stem_set $s 1 }

        foreach parent [$tree children {}] {
            foreach row [$tree children $parent] {
                set s [$tree set $row stem]
                if {$s eq ""} continue
                if {![dict exists $stem_set $s]} continue
                dict set ClassifySnapshot $s [list \
                    [$tree set $row state] \
                    [$tree set $row reason]]
                set tags [$tree item $row -tags]
                if {[lsearch -exact $tags in_cohort] < 0} {
                    $tree item $row -tags [concat $tags in_cohort]
                }
                my _render_row $s
            }
        }
    }

    # aggregate_animate — spinner tick for the progress status line.
    # Public because it's invoked via `after 150 [list [self] …]`.
    method aggregate_animate {} {
        if {!$Dispatching} { set AggregateAfter ""; return }
        incr AggregateTick
        my _update_progress_display
        set AggregateAfter [after 150 [list [self] aggregate_animate]]
    }

    # ─── Event handlers (subscriptions) ───────────────────────────────────

    # on_fully_loaded — Campaign fired `fully-loaded`. The tree is now
    # populated, so re-thread any in-flight cohort onto the new row
    # ids. If --tid was given on the command line, drive the dispatch
    # programmatically (auto_dispatch consumes AutoTid one-shot so the
    # post-dispatch refresh's fully-loaded does not retrigger it).
    method on_fully_loaded {} {
        my reapply_cohort
        if {$AutoTid ne ""} {
            after idle [list [self] auto_dispatch]
        }
    }

    # on_target_changed — TransitionTree fired `dispatch-target-changed`.
    # Apply the resolved {parent nchild label verb} tuple to the Play
    # button. Public because it's invoked from the subscription dispatch.
    method on_target_changed {parent nchild label verb} {
        if {$parent eq ""} {
            $PlayBtn configure -state disabled -text "▶ Dispatch"
            return
        }
        if {$nchild > 0} {
            $PlayBtn configure -state normal \
                -text "▶ ${verb}: $label ($nchild)"
        } else {
            $PlayBtn configure -state normal -text "▶ Dispatch: $label"
        }
    }

    # ─── Internal helpers ─────────────────────────────────────────────────

    # _render_row — format cohort row text/state/reason from the cohort
    # dicts, hand the state_text/reason_text pair to TransitionTree's
    # update_row. Takes a stem (not a row id) because the only map from
    # stem to row id now lives on TransitionTree.
    method _render_row {stem} {
        if {![dict exists $CohortState $stem]} return
        set state  [dict get $CohortState $stem]
        set reason [expr {[dict exists $CohortReason $stem] \
                            ? [dict get $CohortReason $stem] : ""}]
        set phase  [expr {[dict exists $CohortPhase  $stem] \
                            ? [dict get $CohortPhase  $stem] : ""}]
        switch -- $state {
            queued {
                set pos   [expr {[lsearch -exact $CohortStems $stem] + 1}]
                set total [llength $CohortStems]
                set state_text "○ queued #$pos/$total"
                set reason_text ""
            }
            running {
                set state_text  "◐ running"
                set reason_text $phase
            }
            done {
                set state_text  "✓ done"
                set reason_text $reason
            }
            failed {
                set state_text  "✗ failed"
                set reason_text $reason
            }
            skipped {
                set state_text  "⊘ skipped"
                set reason_text $reason
            }
            cancelled {
                set state_text  "⊘ cancelled"
                set reason_text ""
            }
            default {
                set state_text  ""
                set reason_text ""
            }
        }
        # TransitionTree holds the row id map and the widget; hand off.
        # Tree #0 text also needs the plain name (no glyph prefix); the
        # existing update_row doesn't touch #0, so we poke the widget
        # directly for the name reset — same pattern as the old proc.
        set tree       [$Transitions get_tree_widget]
        set slug_to_row [$Transitions get_slug_to_row]
        if {[dict exists $slug_to_row $stem]} {
            set row_id [dict get $slug_to_row $stem]
            if {[$tree exists $row_id]} {
                set row_names [$Transitions get_row_names]
                set name [expr {[dict exists $row_names $row_id] \
                                  ? [dict get $row_names $row_id] : ""}]
                $tree item $row_id -text "  $name"
            }
        }
        $Transitions update_row $stem $state_text $reason_text
    }

    # _update_progress_display — recompute cohort aggregate counts and
    # update the progress bar + status label.
    method _update_progress_display {} {
        set total [llength $CohortStems]
        set bar    ${ProgressFrame}.bar
        set status ${ProgressFrame}.status
        if {$total == 0} {
            $bar configure -value 0
            $status configure -text ""
            my _fire progress-changed 0 0
            return
        }
        set done 0; set failed 0; set running 0; set skipped 0; set cancelled 0
        foreach s $CohortStems {
            switch -- [dict get $CohortState $s] {
                done      { incr done }
                failed    { incr failed }
                running   { incr running }
                skipped   { incr skipped }
                cancelled { incr cancelled }
            }
        }
        set finished [expr {$done + $failed + $skipped + $cancelled}]
        $bar configure -value [expr {100.0 * $finished / $total}]
        set prefix ""
        if {$Dispatching} {
            set frame [lindex $AggregateFrames \
                [expr {$AggregateTick % [llength $AggregateFrames]}]]
            set prefix "$frame "
        }
        set text "${prefix}$done of $total done"
        if {$failed    > 0} { append text " · $failed failed" }
        if {$running   > 0} { append text " · $running running" }
        if {$skipped   > 0} { append text " · $skipped skipped" }
        if {$cancelled > 0} { append text " · $cancelled cancelled" }
        $status configure -text $text
        my _fire progress-changed $done $total
    }
}

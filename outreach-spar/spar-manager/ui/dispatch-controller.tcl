# spar-manager/ui/dispatch-controller.tcl
#
# spar::ui::DispatchController — translates user actions on the
# Play / Pause / Cancel buttons (plus the right-click menu on tree
# rows) into spar::Dispatcher method calls, and renders the Pool's
# row state back onto the TransitionTree.
#
# Phase 3 rewire: per-cohort lifecycle state and per-row classify
# snapshots are gone. The Pool is the single source of truth for
# row state across all in-flight rows of every transition kind. The
# Controller subscribes to its `job-state` event to drive
# update_row, and reads `active_jobs` / `queued_jobs` for the
# progress bar.
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
#       after a Pool row's state/reason rendering updates.
#   progress-changed {posted total}
#       after each progress recompute (posted = active+queued, total
#       = posted + finished-since-last-clear).
#   dispatch-started {tid}
#       Play succeeded in enqueueing at least one row.
#   dispatch-ended {tid done failed}
#       all rows from a Play burst have reached a terminal state.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::DispatchController {
    variable Campaign Transitions Log Dispatcher
    variable PlayBtn PauseBtn CancelBtn ProgressFrame
    variable AutoTid AutoStems AutoQuit AutoDryRun ScriptDir CampaignFile
    variable PlayMenu LastWasDryRun
    variable AggregateTick AggregateAfter AggregateFrames
    variable Subs
    variable RowTid RowReason RowPhase RowMeta RowDryRun
    variable BurstStems BurstFinished BurstFailed BurstActive
    variable RowMenu RowMenuRow

    constructor {campaign transitions log dispatcher \
                 play_btn pause_btn cancel_btn progress_frame \
                 script_dir campaign_file \
                 auto_tid auto_stems auto_quit {auto_dry_run 0}} {
        set Campaign       $campaign
        set Transitions    $transitions
        set Log            $log
        set Dispatcher     $dispatcher
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

        set RowTid         [dict create]
        set RowReason      [dict create]
        set RowPhase       [dict create]
        set RowMeta        [dict create]
        set RowDryRun      [dict create]
        set BurstStems     {}
        set BurstFinished  0
        set BurstFailed    0
        set BurstActive    0

        set AggregateTick  0
        set AggregateAfter ""
        set AggregateFrames [list ⠋ ⠙ ⠹ ⠸ ⠼ \
                                  ⠴ ⠦ ⠧ ⠇ ⠏]

        set Subs [dict create]
        set RowMenu ""
        set RowMenuRow ""

        # Wire buttons to controller methods.
        $PlayBtn   configure -command [list [self] dispatch]
        $PauseBtn  configure -command [list [self] pause]
        $CancelBtn configure -command [list [self] cancel]

        # Right-click on the Play button opens a menu with live/dry-run
        # variants. Dry-run is not a common need, so we keep it off the
        # primary button surface. `<Button-3>` on a ttk::button still
        # fires bindings regardless of the button's enabled state; the
        # handler checks the play state before popping.
        set PlayMenu ${play_btn}.menu
        menu $PlayMenu -tearoff 0
        $PlayMenu add command -label "Send to pool (live)" \
            -command [list [self] dispatch 0]
        $PlayMenu add command -label "Send to pool (dry run — writes disabled)" \
            -command [list [self] dispatch 1]
        bind $PlayBtn <Button-3> [list [self] on_play_menu %X %Y]

        # Subscribe to Pool events. job-state drives the per-row glyph;
        # job-phase keeps the running subtitle current; job-failed gives
        # a reason; job-done likewise.
        $Dispatcher subscribe job-state \
            [list [self] on_row_state]
        $Dispatcher subscribe job-phase \
            [list [self] on_row_phase]
        $Dispatcher subscribe job-failed \
            [list [self] on_row_failed]
        $Dispatcher subscribe job-done \
            [list [self] on_row_done]

        # Subscribe to Campaign lifecycle. on_fully_loaded both kicks
        # the --tid auto-dispatch path and rebinds the Pool's per-row
        # state onto the rebuilt tree (refresh persistence).
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
    #
    # is_dispatching — Phase-3 contract: always false. Play is non-
    # blocking now (each click adds rows to the Pool), so there is no
    # mode in which the tree should suppress its Play-button updates.
    # TransitionTree's _resolve_target keeps the historical guard in
    # place; we just stop tripping it.
    method is_dispatching {} { return 0 }

    method dispatcher {} { return $Dispatcher }

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

    # dispatch — Play handler. Reads the tree selection, prepares prompt
    # dirs for harness transitions (T1..T4), and enqueues each row into
    # the Pool. Pause is queue-pause, so this method returns once the
    # rows are queued; the worker threads pick them up asynchronously.
    method dispatch {{dry_run 0}} {
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

        # Tree item id (t0..tN) to T-id, via the same ordering the
        # CampaignModel and TransitionTree use.
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

        # Parent-only selection: the implicit cohort is every child.
        if {[llength $child_items] == 0} {
            set child_items [$tree children $parent]
        }

        # Build the cohort from the selected leaf rows.
        set sel_stems {}
        foreach c $child_items {
            set s [$tree set $c stem]
            if {$s eq ""} continue
            lappend sel_stems $s
        }
        if {[llength $sel_stems] == 0} {
            $Log log "Dispatch: nothing selected."
            return
        }

        # Filter eligible contacts down to the selected stems.
        set cdata [$Campaign get_cdata]
        set primary_channel ""
        if {[dict size $cdata] > 0} {
            set primary_channel [spar::campaign_primary_channel $cdata]
        }
        set eligible [[$Campaign get_state] transition_eligible \
            [$Campaign get_all_contacts] $tid $primary_channel $cdata]
        set stem_set [dict create]
        foreach s $sel_stems { dict set stem_set $s 1 }
        set filtered {}
        foreach c $eligible {
            if {[dict exists $stem_set [dict getdef $c stem ""]]} {
                lappend filtered $c
            }
        }
        set eligible $filtered

        # Pull transition-specific opts (tasks, segments, etc.) the way
        # the legacy CLI path does.
        set cls [::spar::transitions::get $tid]
        set extra [$cls build_opts $eligible {} $sel_stems]
        if {[dict exists $extra log_message]} {
            $Log log [dict get $extra log_message]
            set extra [dict remove $extra log_message]
        }
        set base_opts [dict create \
            campaign_file $CampaignFile \
            dry_run $dry_run \
            jobs 4 \
            tid $tid]
        set opts [dict merge $base_opts $extra]

        # T6 needs an explicit Send confirmation — one dialog for the
        # whole batch instead of per-row prompts.
        if {!$dry_run} {
            if {[$cls requires_send_confirmation]} {
                set n [llength $sel_stems]
                set answer [tk_messageBox -title "Confirm Send" \
                    -icon question -type yesno \
                    -message "Send $n email(s) via $label ($tid)?" \
                    -detail "Press Yes to proceed, No to cancel."]
                if {$answer ne "yes"} {
                    $Log log "Dispatch cancelled by user."
                    return
                }
            }
        }

        set mode_tag [expr {$dry_run ? " (DRY RUN — writes disabled)" : ""}]
        $Log log "Dispatch requested: $label ($tid)$mode_tag"

        set enqueued [my _enqueue_prepared $opts $sel_stems $tid $dry_run]
        if {[llength $enqueued] == 0} {
            $Log log "Dispatch: no rows enqueued (none eligible after gating)."
            return
        }
        # Set BurstStems from _enqueue_prepared's result only now, after
        # every row in it has been enqueued. jobloop's enqueue fires each
        # row's "queued" (and, if a slot is free, "running") job-state
        # report synchronously, inline; only a job's terminal report
        # (done/failed/cancelled) is deferred, via a 0ms timer, so none can
        # land before this line runs. Resetting BurstStems earlier (before
        # or during the enqueue loop) wiped rows this same burst had just
        # added, so on_row_state's `$row in $BurstStems` test failed for
        # every terminal report and the burst-complete block below never
        # ran — the GUI's spinner never stopped and --autoquit never saw
        # its burst finish.
        set BurstStems $enqueued
        set BurstFinished 0
        set BurstFailed 0
        incr BurstActive [llength $enqueued]

        my _update_progress_display
        if {$AggregateAfter eq ""} { my aggregate_animate }

        # Kick the tree so the Play button's enable state re-evaluates.
        event generate $tree <<TreeviewSelect>>

        my _fire dispatch-started $tid
    }

    # _enqueue_prepared — ask the transition class for its pool shape
    # via prepare_for_pool, then enqueue each {stem opts} pair onto the
    # shared Dispatcher with the worker_proc the class declares. The
    # transition layer is the SSOT for per-row opts; this method only
    # filters by selection and drives the in-pool gating + requeue.
    # Returns the list of stems actually enqueued (possibly empty). The
    # caller derives its count from [llength] and owns writing that list
    # onto BurstStems — see the comment in `dispatch` for why this method
    # must not touch BurstStems itself.
    method _enqueue_prepared {opts sel_stems tid dry_run} {
        set cls [::spar::transitions::get $tid]
        if {[catch {set prep [$cls prepare_for_pool $opts \
                [list [self] on_prep_progress]]} err]} {
            $Log log "Dispatch prep failed: $err"
            return {}
        }
        set worker_proc [dict get $prep worker_proc]
        set rows        [dict get $prep rows]

        set selset [dict create]
        foreach s $sel_stems { dict set selset $s 1 }

        set enqueued {}
        foreach pair $rows {
            lassign $pair stem row_opts
            if {[llength $sel_stems] > 0 && ![dict exists $selset $stem]} continue
            set st [$Dispatcher state $stem]
            if {$st ni {"" done failed cancelled}} {
                $Log log "Skip $stem: already in pool ($st)"
                continue
            }
            if {$st in {done failed cancelled}} {
                $Dispatcher requeue $stem
            }
            dict set RowTid    $stem $tid
            dict set RowDryRun $stem $dry_run
            dict set RowMeta   $stem $row_opts
            lappend enqueued $stem
            # A row may name its own worker (T6 linkedin rows carry
            # linkedin_send); the batch worker_proc is the default.
            set wp [dict getdef $row_opts worker_proc $worker_proc]
            $Dispatcher enqueue $stem $wp $row_opts
        }
        return $enqueued
    }

    # on_prep_progress — prep-time callback invoked by prepare_for_pool
    # for skipped/failed rows. We mirror the legacy log behaviour and
    # also paint the row's state so the user sees the skip. Public
    # because it's invoked via [list [self] on_prep_progress] passed
    # as a callback prefix — TclOO unexports leading-underscore methods.
    method on_prep_progress {slug status message} {
        if {$status eq "skipped"} {
            dict set RowReason $slug $message
            my _render_row $slug skipped
        } elseif {$status eq "failed"} {
            dict set RowReason $slug $message
            my _render_row $slug failed
        }
        $Log log "  \[$status\] $slug $message"
    }

    # pause / resume toggle — pause-of-queue, not pause of in-flight.
    method pause {} {
        if {![$Dispatcher is_queue_paused]} {
            $Dispatcher pause_queue
            $PauseBtn configure -text "▶ Resume"
            $Log log "Queue paused: queued items held; in-flight items finish normally."
        } else {
            $Dispatcher resume_queue
            $PauseBtn configure -text "⏸ Pause"
            $Log log "Queue resumed."
        }
    }

    method resume {} {
        if {[$Dispatcher is_queue_paused]} { my pause }
    }

    # cancel — drain queued rows. In-flight rows continue to finish (per-
    # row Kill is deferred — see docs/concurrency.md "Deferred work").
    method cancel {} {
        set queued [$Dispatcher queued_jobs]
        foreach r $queued { $Dispatcher cancel $r }
        $Log log "Cancelled [llength $queued] queued row(s); in-flight items finish normally."
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
    # live/dry-run menu, but only when there is something dispatchable.
    method on_play_menu {x_screen y_screen} {
        if {[$PlayBtn cget -state] ne "normal"} return
        tk_popup $PlayMenu $x_screen $y_screen
    }

    # ─── Pool event handlers ──────────────────────────────────────────────

    method on_row_state {row state} {
        my _render_row $row $state
        if {$state in {done failed cancelled} && $row in $BurstStems} {
            if {$state eq "done"} { incr BurstFinished }
            if {$state eq "failed"} { incr BurstFailed }
            if {$BurstActive > 0} { incr BurstActive -1 }
            if {$BurstActive == 0} {
                # Burst complete. Stop the spinner and bounce the tree
                # so the Play button re-enables.
                if {$AggregateAfter ne ""} {
                    after cancel $AggregateAfter
                    set AggregateAfter ""
                }
                $Campaign refresh
                set tree [$Transitions get_tree_widget]
                event generate $tree <<TreeviewSelect>>
                set tag [expr {$LastWasDryRun ? " (dry run — no writes)" : ""}]
                $Log log \
                    "Dispatch burst completed: $BurstFinished done, $BurstFailed failed$tag."
                my _fire dispatch-ended "" $BurstFinished $BurstFailed
                # A burst only exists because work was dispatched, whether
                # that dispatch was scoped by --tid (auto_dispatch) or by
                # an interactive Play click; --autoquit means quit once
                # that work finishes, however it was scoped. AutoTid is
                # unconditionally cleared by auto_dispatch before it ever
                # calls `dispatch`, so gating this exit on `$AutoTid eq ""`
                # excluded exactly the --tid path it exists to serve.
                if {$AutoQuit} {
                    update
                    exit [expr {$BurstFailed > 0 ? 1 : 0}]
                }
            }
        }
        my _update_progress_display
    }

    method on_row_phase {row phase} {
        dict set RowPhase $row $phase
        my _render_row $row [$Dispatcher state $row]
    }

    method on_row_failed {row reason} {
        dict set RowReason $row $reason
        # job-state will follow with state=failed; render then.
    }

    method on_row_done {row result} {
        dict set RowReason $row [clock format [clock seconds] -format "%H:%M"]
    }

    # ─── Campaign / tree event handlers ───────────────────────────────────

    method on_fully_loaded {} {
        # Phase-4 refresh persistence. The TransitionTree has been
        # rebuilt; row ids may differ for the same stems, contacts may
        # have been added or removed. Prune the Pool's state map so it
        # forgets stems no longer in the tree (terminal/queued only —
        # in-flight rows keep their slot), then walk what's left and
        # re-render so the new tree picks up the surviving Pool state.
        set tree_stems [dict keys [$Transitions get_slug_to_row]]
        $Dispatcher prune_missing $tree_stems
        my reapply_pool_state

        if {$AutoTid ne ""} {
            after idle [list [self] auto_dispatch]
        }
    }

    # reapply_pool_state — for every row the Pool still tracks, rerun
    # the job-state render so the rebuilt tree's columns reflect the
    # current Pool state. Cheap: each call is one update_row, and the
    # set is bounded by what is currently or recently in flight.
    method reapply_pool_state {} {
        foreach row [$Dispatcher all_jobs] {
            set st [$Dispatcher state $row]
            if {$st eq ""} continue
            my _render_row $row $st
        }
    }

    method on_target_changed {parent nchild label verb} {
        if {$parent eq ""} {
            $PlayBtn configure -state disabled -text "▶ Send to pool"
            return
        }
        if {$nchild > 0} {
            $PlayBtn configure -state normal \
                -text "▶ Send to pool: $label ($nchild)"
        } else {
            $PlayBtn configure -state normal -text "▶ Send to pool: $label"
        }
        # Pause is meaningful whenever there are queued rows (or we
        # want to pre-empt new sends). Cancel is meaningful when there
        # are queued rows. Both are toggled on best-effort here.
        if {[llength [$Dispatcher queued_jobs]] > 0 \
                || [llength [$Dispatcher active_jobs]] > 0} {
            $PauseBtn  configure -state normal
            $CancelBtn configure -state normal
        } else {
            $PauseBtn  configure -state disabled
            $CancelBtn configure -state disabled
        }
    }

    # ─── Right-click menu on tree rows ────────────────────────────────────

    # row_menu_for — TransitionTree calls this on <Button-3>. Builds a
    # state-aware menu and pops it at the screen coords. Items shown
    # depend on the row's Pool state.
    method row_menu_for {row x_screen y_screen} {
        if {$row eq ""} return
        if {$RowMenu eq ""} {
            set RowMenu .row_action_menu
            if {[winfo exists $RowMenu]} { destroy $RowMenu }
            menu $RowMenu -tearoff 0
        }
        $RowMenu delete 0 end
        set RowMenuRow $row
        set st [$Dispatcher state $row]
        switch -- $st {
            "" {
                $RowMenu add command -label "Send to pool" \
                    -command [list [self] menu_send_one]
            }
            queued {
                $RowMenu add command -label "Cancel" \
                    -command [list [self] menu_cancel]
            }
            running -
            rate_limited {
                $RowMenu add command -label "Pause" \
                    -command [list [self] menu_pause_job]
                $RowMenu add command -label "Cancel" \
                    -command [list [self] menu_cancel]
            }
            paused {
                $RowMenu add command -label "Resume" \
                    -command [list [self] menu_resume_job]
                $RowMenu add command -label "Cancel" \
                    -command [list [self] menu_cancel]
            }
            done -
            failed -
            cancelled {
                $RowMenu add command -label "Requeue" \
                    -command [list [self] menu_requeue]
            }
        }
        $RowMenu add separator
        $RowMenu add command -label "Open log" \
            -command [list [self] menu_open_log]
        tk_popup $RowMenu $x_screen $y_screen
    }

    # menu_send_one — Send-to-pool from the row right-click. Uses the
    # current selection-or-row-under-cursor as a one-row burst.
    method menu_send_one {} {
        set tree [$Transitions get_tree_widget]
        # Restrict the selection to the right-clicked row, then drive
        # the normal dispatch path so prep + opts wiring runs.
        set slug_to_row [$Transitions get_slug_to_row]
        if {[dict exists $slug_to_row $RowMenuRow]} {
            set rid [dict get $slug_to_row $RowMenuRow]
            if {[$tree exists $rid]} {
                $tree selection set [list $rid]
                event generate $tree <<TreeviewSelect>>
                update
                my dispatch 0
            }
        }
    }

    method menu_cancel    {} { $Dispatcher cancel     $RowMenuRow }
    method menu_pause_job {} { $Dispatcher pause_job  $RowMenuRow }
    method menu_resume_job {} { $Dispatcher resume_job $RowMenuRow }
    method menu_requeue   {} { $Dispatcher requeue    $RowMenuRow }

    method menu_open_log {} {
        set meta [expr {[dict exists $RowMeta $RowMenuRow] \
                          ? [dict get $RowMeta $RowMenuRow] : [dict create]}]
        set ld [expr {[dict exists $meta log_dir] \
                        ? [dict get $meta log_dir] : ""}]
        if {$ld eq ""} {
            tk_messageBox -title "No log" -icon info -type ok \
                -message "No log directory recorded for $RowMenuRow yet." \
                -detail "Logs are recorded once the row is enqueued via the harness."
            return
        }
        set path [file join $ld "${RowMenuRow}-cost.jsonl"]
        tk_messageBox -title "Log path" -icon info -type ok \
            -message "Log directory for $RowMenuRow:" \
            -detail "$ld\n\nMost recent cost ledger: $path"
    }

    # aggregate_animate — spinner tick for the progress status line.
    # Public because it's invoked via `after 150 [list [self] …]`.
    method aggregate_animate {} {
        if {$BurstActive == 0} { set AggregateAfter ""; return }
        incr AggregateTick
        my _update_progress_display
        set AggregateAfter [after 150 [list [self] aggregate_animate]]
    }

    # ─── Internal helpers ─────────────────────────────────────────────────

    # _render_row — paint a row's state column from the Pool's state
    # plus our local phase/reason side-tables.
    method _render_row {stem state} {
        set reason [expr {[dict exists $RowReason $stem] \
                            ? [dict get $RowReason $stem] : ""}]
        set phase  [expr {[dict exists $RowPhase $stem] \
                            ? [dict get $RowPhase $stem] : ""}]
        switch -- $state {
            queued {
                set state_text "○ queued"
                set reason_text ""
            }
            running {
                set state_text  "◐ running"
                set reason_text $phase
            }
            paused {
                set state_text  "⏸ paused"
                set reason_text $phase
            }
            rate_limited {
                set state_text  "⌛ rate-limited"
                set reason_text $reason
            }
            done {
                set state_text  "✓ done"
                set reason_text $reason
            }
            failed {
                set r $reason
                if {[string length $r] > 80} { set r "[string range $r 0 77]…" }
                set state_text  "✗ failed"
                set reason_text $r
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
        set tree [$Transitions get_tree_widget]
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
        my _fire row-changed $stem $state $reason
    }

    # _update_progress_display — recompute progress from Pool state.
    # Total = active + queued; finished = burst counters.
    method _update_progress_display {} {
        set posted [llength [$Dispatcher active_jobs]]
        set queued [llength [$Dispatcher queued_jobs]]
        set bar    ${ProgressFrame}.bar
        set status ${ProgressFrame}.status
        set total [llength $BurstStems]
        if {$total == 0 && $posted == 0 && $queued == 0} {
            $bar configure -value 0
            $status configure -text ""
            my _fire progress-changed 0 0
            return
        }
        if {$total > 0} {
            set finished [expr {$BurstFinished + $BurstFailed}]
            $bar configure -value [expr {100.0 * $finished / $total}]
        } else {
            $bar configure -value 0
        }
        set prefix ""
        if {$BurstActive > 0} {
            set frame [lindex $AggregateFrames \
                [expr {$AggregateTick % [llength $AggregateFrames]}]]
            set prefix "$frame "
        }
        set parts {}
        if {$total > 0} {
            lappend parts "$BurstFinished/$total done"
        }
        if {$BurstFailed > 0} { lappend parts "$BurstFailed failed" }
        if {$posted > 0}      { lappend parts "$posted running" }
        if {$queued > 0}      { lappend parts "$queued queued" }
        $status configure -text "${prefix}[join $parts { · }]"
        my _fire progress-changed [expr {$posted + $queued}] $total
    }
}

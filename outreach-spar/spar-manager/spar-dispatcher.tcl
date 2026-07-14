# spar::Dispatcher — coordinator for the GUI's mixed-type job pool.
#
# Owns the row queue, the per-row state map, and the global concurrency
# cap. Posts jobs to a tpool whose worker procs are defined in
# spar-dispatcher-initcmd.tcl. Receives messages from worker threads
# through thread::send -async calls into its on_* methods.
#
# The protocol — twelve message types, the row state machine, and the
# downward sentinel channel — is documented in docs/concurrency.md.
#
# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources.

package require TclOO
package require Thread
package require logger

if {[info exists ::spar::_pool_loaded]} {
    package provide spar-dispatcher 1.0
    return
}

namespace eval spar {
    variable _pool_loaded 1
    variable pool_script_dir [file dirname [file normalize [info script]]]
    # Logger service for state-machine warnings the Dispatcher emits
    # via _log (out-of-order/dropped messages, roster_update failures).
    variable dispatch_log [logger::init spar::dispatch]
}

oo::class create spar::Dispatcher {
    variable Pool Jobs WorkerCap
    variable Queue RowState RowMeta RowJobId
    variable QueuePaused
    variable LogCallback PrePostCallback Subs

    # Terminal states. Anything else is non-terminal.
    variable Terminal

    constructor {jobs {log_cb ""} {initcmd ""}} {
        set Jobs            $jobs
        set WorkerCap       [dict create]
        set Queue           {}
        set RowState        [dict create]
        set RowMeta         [dict create]
        set RowJobId        [dict create]
        set QueuePaused     0
        set LogCallback     $log_cb
        set PrePostCallback ""
        set Subs            [dict create]
        set Terminal        {done failed cancelled}

        set me  [self]
        set tid [thread::id]
        # The worker bootstrap: a generic preamble (whom to message) ahead
        # of the deployment's own script, which declares the worker procs
        # and their file manifest. The default is this application's
        # (spar::pool_initcmd, defined below the class).
        if {$initcmd eq ""} { set initcmd [spar::pool_initcmd] }
        set initcmd "
            set ::main_tid [list $tid]
            set ::dispatcher [list $me]
            $initcmd
        "
        # minworkers = maxworkers — pre-spawn all worker threads at
        # tpool::create time. With -minworkers 0 the Thread package's
        # lazy-spawn path produces only one worker for the pool's
        # lifetime, regardless of post volume; subsequent posts queue
        # behind the first worker and the pool never grows. Verified
        # by test/test-pool.tcl §17 ("True parallelism with blocking
        # workers"); see docs/concurrency.md "Pool sizing" for the
        # diagnosis trail.
        set Pool [tpool::create \
            -minworkers $jobs \
            -maxworkers $jobs \
            -idletime   60 \
            -initcmd    $initcmd]
    }

    destructor {
        if {[info exists Pool]} {
            catch {tpool::release $Pool}
        }
    }

    # ─── Subscription ────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    # set_pre_post_callback — install a synchronous gate fired just
    # before tpool::post for each row. Invoked as
    #   {*}$cb $row $tid $idx $total
    # where idx is the 1-based position among rows posted so far in
    # the current Dispatcher's lifetime, and total is the count of
    # rows enqueued so far. Return "abort" to cancel the row before
    # it is posted (state moves to cancelled, no worker runs); any
    # other return (or empty) lets the post proceed. Used by the CLI
    # --jobs=0 stepping path to gate one row at a time on stdin.
    method set_pre_post_callback {cb} { set PrePostCallback $cb }
    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Public accessors ────────────────────────────────────────────
    method state {row} {
        if {[dict exists $RowState $row]} { return [dict get $RowState $row] }
        return ""
    }
    method tid_of {row} {
        if {[dict exists $RowMeta $row]} {
            return [dict get $RowMeta $row tid]
        }
        return ""
    }
    method count_by_transition {tid state} {
        set n 0
        dict for {row meta} $RowMeta {
            if {[dict get $meta tid] ne $tid} continue
            if {[dict get $RowState $row] ne $state} continue
            incr n
        }
        return $n
    }
    # active_rows — rows that hold a tpool worker slot. Posted to the
    # tpool, not yet terminal: running, paused, rate_limited. Used for
    # the concurrency cap and for the GUI's "ongoing" filter set.
    # Queued rows are not active by this definition; they have not yet
    # been posted.
    method active_rows {} {
        set out {}
        dict for {row state} $RowState {
            if {$state in {running paused rate_limited}} { lappend out $row }
        }
        return $out
    }
    method queued_rows {} {
        set out {}
        dict for {row state} $RowState {
            if {$state eq "queued"} { lappend out $row }
        }
        return $out
    }
    method all_rows {} { return [dict keys $RowState] }
    method is_queue_paused {} { return $QueuePaused }
    method jobs_cap {} { return $Jobs }
    method posted_count {} { return [llength [my active_rows]] }

    # set_worker_cap — install a per-worker-proc concurrency cap that
    # further constrains the global Jobs cap. A row is posted to the
    # tpool only if (global active < Jobs) AND (active rows whose meta
    # carries this worker_proc < cap). Default cap is Jobs (i.e. no
    # extra constraint).
    #
    # Used by the unified dispatch_ready in spar-transition.tcl to let
    # SES rows (worker_proc=ses_send) run serially while harness rows
    # parallelise inside the same shared pool. The decision lives in
    # docs/concurrency.md "Per-worker cap".
    method set_worker_cap {worker_proc cap} {
        dict set WorkerCap $worker_proc $cap
    }

    # _active_count_for_worker — count active rows whose meta worker
    # equals $worker_proc. O(active_rows). Called from _try_post_next.
    method _active_count_for_worker {worker_proc} {
        set n 0
        foreach row [my active_rows] {
            if {[dict get $RowMeta $row worker] eq $worker_proc} { incr n }
        }
        return $n
    }

    # ─── Public mutators ─────────────────────────────────────────────

    # enqueue — register a row in the queue with its transition kind
    # and the opts dict the worker will receive.  worker_proc names the
    # initcmd-defined proc that does the work (e.g. "harness_run",
    # "ses_send", "imap_poll", "fake_worker" in tests).
    method enqueue {row tid worker_proc opts} {
        if {[dict exists $RowState $row]} {
            my _log "enqueue: row $row already in pool (state [dict get $RowState $row]); ignoring"
            return
        }
        dict set RowState $row queued
        dict set RowMeta  $row [dict create \
            tid          $tid \
            worker       $worker_proc \
            opts         $opts \
            posted_at    [clock milliseconds] \
            started_at   ""]
        lappend Queue $row
        my _fire row-state $row queued
        my _try_post_next
    }

    # cancel — for a queued row, drop it before the worker is posted.
    # For an in-flight row, set the cancel sentinel; the worker observes
    # it at its next safe point and emits msg_cancelled.
    method cancel {row} {
        if {![dict exists $RowState $row]} return
        set s [dict get $RowState $row]
        if {$s eq "queued"} {
            set idx [lsearch -exact $Queue $row]
            if {$idx >= 0} { set Queue [lreplace $Queue $idx $idx] }
            my _set_state $row cancelled
            return
        }
        if {$s in $Terminal} return
        # Running, paused, or rate_limited: signal the worker and wait.
        tsv::set ::spar::pool $row.cancel 1
    }

    method pause_row {row} {
        if {![dict exists $RowState $row]} return
        if {[dict get $RowState $row] in $Terminal} return
        tsv::set ::spar::pool $row.pause 1
    }

    method resume_row {row} {
        if {![dict exists $RowState $row]} return
        catch {tsv::unset ::spar::pool $row.pause}
    }

    method pause_queue {} {
        set QueuePaused 1
        my _fire queue-paused
    }

    method resume_queue {} {
        set QueuePaused 0
        my _fire queue-resumed
        my _try_post_next
    }

    # prune_missing — drop every row in RowState whose key is not in
    # $valid_rows. Called after a workspace refresh so the Pool's
    # state map sheds entries for contacts that no longer appear in
    # the rebuilt TransitionTree (e.g. removed-from-roster). In-flight
    # rows for stems that disappeared mid-refresh are intentionally
    # NOT dropped — only rows in a terminal state, or queued rows
    # that were not yet posted, can be safely garbage-collected.
    # Active workers (running / paused / rate_limited) keep their
    # state; they own a tpool slot and will arrive at a terminal
    # message of their own accord.
    method prune_missing {valid_rows} {
        set valid [dict create]
        foreach r $valid_rows { dict set valid $r 1 }
        set dropped {}
        dict for {row state} $RowState {
            if {[dict exists $valid $row]} continue
            if {$state in {running paused rate_limited}} continue
            lappend dropped $row
        }
        foreach row $dropped {
            dict unset RowState $row
            catch {dict unset RowMeta  $row}
            catch {dict unset RowJobId $row}
            set idx [lsearch -exact $Queue $row]
            if {$idx >= 0} { set Queue [lreplace $Queue $idx $idx] }
            catch {tsv::unset ::spar::pool $row.cancel}
            catch {tsv::unset ::spar::pool $row.pause}
        }
        return [llength $dropped]
    }

    # requeue — move a terminal row back to queued so the user can
    # retry it. Clears any prior sentinel state.
    method requeue {row} {
        if {![dict exists $RowState $row]} return
        if {[dict get $RowState $row] ni $Terminal} return
        catch {tsv::unset ::spar::pool $row.cancel}
        catch {tsv::unset ::spar::pool $row.pause}
        dict set RowMeta $row started_at ""
        my _set_state $row queued
        lappend Queue $row
        my _try_post_next
    }

    # ─── Worker → Dispatcher message handlers ────────────────────────
    # Each on_* method is called by thread::send -async from a worker
    # thread; runs in the main thread's event loop. Handlers consult
    # state before mutating; out-of-order messages are logged and
    # dropped.

    method on_phase {row phase} {
        if {![my _expect_active $row phase]} return
        my _fire row-phase $row $phase
    }

    method on_progress {row text} {
        if {![my _expect_active $row progress]} return
        my _fire row-progress $row $text
    }

    method on_done {row {result {}}} {
        if {![my _expect $row done {running paused rate_limited}]} return
        my _set_state $row done
        my _fire row-done $row $result
        my _try_post_next
    }

    method on_failed {row reason} {
        if {![my _expect $row failed {running paused rate_limited}]} return
        my _set_state $row failed
        my _fire row-failed $row $reason
        my _try_post_next
    }

    method on_cancelled {row} {
        if {![my _expect $row cancelled {running paused}]} return
        my _set_state $row cancelled
        catch {tsv::unset ::spar::pool $row.cancel}
        my _try_post_next
    }

    # A domain message the pool relays whole: the semantics belong to the
    # deployment's subscriber (spar::subscribe_pool_domain, below the
    # class), not to the pool. A relay with no subscriber is logged and
    # dropped rather than silently lost.
    method on_roster_update {args} {
        if {![dict exists $Subs domain-roster_update]} {
            my _log "roster_update with no subscriber; dropping: $args"
            return
        }
        my _fire domain-roster_update {*}$args
    }

    method on_cost {row stage usd} {
        if {![my _expect_active $row cost]} return
        my _fire row-cost $row $stage $usd
    }

    method on_retry {row stage attempt max} {
        if {![my _expect_active $row retry]} return
        my _fire row-retry $row $stage $attempt $max
    }

    method on_rate_limited {row reset_at} {
        if {![my _expect $row rate_limited running]} return
        my _set_state $row rate_limited
        my _fire row-rate-limited $row $reset_at
    }

    method on_rate_limit_cleared {row} {
        if {![my _expect $row rate_limit_cleared rate_limited]} return
        my _set_state $row running
        my _fire row-rate-limit-cleared $row
    }

    method on_paused {row} {
        if {![my _expect $row paused running]} return
        my _set_state $row paused
        my _fire row-paused $row
    }

    method on_resumed {row} {
        if {![my _expect $row resumed paused]} return
        my _set_state $row running
        my _fire row-resumed $row
    }

    method on_credit_warning {row usd_window window_secs} {
        if {![my _expect_active $row credit_warning]} return
        my _fire row-credit-warning $row $usd_window $window_secs
    }

    # ─── Internals ───────────────────────────────────────────────────

    # _try_post_next — walk the queue in order and post any row that
    # fits both the global Jobs cap and its per-worker cap. The state
    # transitions to running at post time, not at msg_started arrival;
    # this avoids the race where the dict showed `queued` between post
    # and the asynchronous message arrival, and lets the cap math read
    # directly from the state map.
    #
    # A row blocked only by its per-worker cap stays in queue; we keep
    # scanning so other workers' rows can still post. This preserves
    # per-worker FIFO under contention while letting unrelated workers
    # run in parallel inside the same shared pool.
    method _try_post_next {} {
        if {$QueuePaused} return
        set new_queue {}
        set i 0
        while {$i < [llength $Queue]} {
            set row [lindex $Queue $i]
            incr i
            if {![dict exists $RowState $row]} continue
            if {[dict get $RowState $row] ne "queued"} continue
            # Global cap blocks the entire pass; nothing more can post
            # until a slot frees and _try_post_next runs again.
            if {[llength [my active_rows]] >= $Jobs} {
                lappend new_queue $row
                # Tail is unprocessed; preserve it.
                while {$i < [llength $Queue]} {
                    lappend new_queue [lindex $Queue $i]
                    incr i
                }
                break
            }
            set meta [dict get $RowMeta $row]
            set worker [dict get $meta worker]
            # Per-worker cap. Default = Jobs (no extra constraint).
            set wcap [expr {[dict exists $WorkerCap $worker]
                            ? [dict get $WorkerCap $worker]
                            : $Jobs}]
            if {[my _active_count_for_worker $worker] >= $wcap} {
                lappend new_queue $row
                continue
            }
            set opts   [dict get $meta opts]
            set tid    [dict get $meta tid]
            # Pre-post gate. Total/idx are computed against current
            # state-map size for a stable, monotonically increasing
            # position usable by the stdin gate. The callback runs
            # synchronously in the main thread; an "abort" return
            # cancels this row before any tpool::post happens.
            if {$PrePostCallback ne ""} {
                set total [dict size $RowState]
                set idx 0
                dict for {r _} $RowState {
                    incr idx
                    if {$r eq $row} break
                }
                set verdict ""
                catch {set verdict [{*}$PrePostCallback $row $tid $idx $total]}
                if {$verdict eq "abort"} {
                    my _set_state $row cancelled
                    continue
                }
            }
            dict set RowMeta $row started_at [clock milliseconds]
            my _set_state $row running
            set jobid [tpool::post -nowait $Pool \
                [list $worker $row $opts]]
            dict set RowJobId $row $jobid
        }
        set Queue $new_queue
    }

    # _expect — assert that the row's current state is one of the
    # allowed_from states, given that this is the named transition.
    # Logs and returns 0 on violation.
    method _expect {row transition allowed_from} {
        if {![dict exists $RowState $row]} {
            my _log "$transition for unknown row $row; dropping"
            return 0
        }
        set cur [dict get $RowState $row]
        if {$cur ni $allowed_from} {
            my _log "$transition for row $row in state $cur (allowed: [join $allowed_from {, }]); dropping"
            return 0
        }
        return 1
    }

    # _expect_active — informational messages allowed during any non-
    # terminal state.
    method _expect_active {row mtype} {
        if {![dict exists $RowState $row]} {
            my _log "$mtype for unknown row $row; dropping"
            return 0
        }
        set cur [dict get $RowState $row]
        if {$cur in $Terminal} {
            my _log "$mtype for row $row in terminal state $cur; dropping"
            return 0
        }
        return 1
    }

    method _set_state {row to} {
        dict set RowState $row $to
        my _fire row-state $row $to
    }

    method _log {msg} {
        ${::spar::dispatch_log}::warn $msg
        # LogCallback is retained for the GUI's LogWindow wiring (until
        # commit 5 swaps it for a logger appender) and for tests that
        # capture per-instance dispatcher messages for assertion.
        if {$LogCallback ne ""} {
            {*}$LogCallback "spar::Dispatcher: $msg"
        }
    }
}

# ─── spar residue: this deployment's own wiring ──────────────────────────
# The pool class above is generic; what follows is what this application
# feeds it: the worker bootstrap manifest, and the domain subscriber each
# construction site installs beside the pool.

# The worker bootstrap script: the six file globals the worker procs read,
# then the worker definitions themselves.
proc spar::pool_initcmd {} {
    variable pool_script_dir
    set d $pool_script_dir
    return "
        set ::pool_state_file   [list [file join $d spar-state.tcl]]
        set ::pool_harness_file [list [file join $d spar-harness.tcl]]
        set ::pool_email_file   [list [file join $d spar-email.tcl]]
        set ::pool_ses_send_file   [list [file join $d transitions ses_send_one.tcl]]
        set ::pool_li_send_file    [list [file join $d transitions linkedin_send_one.tcl]]
        set ::pool_imap_check_file [list [file join $d transitions imap_check_one.tcl]]
        source [list [file join $d spar-dispatcher-initcmd.tcl]]
    "
}

# Wire the domain messages to their spar semantics. Both front-ends call
# this right after constructing their Dispatcher.
proc spar::subscribe_pool_domain {disp} {
    $disp subscribe domain-roster_update ::spar::_pool_roster_update
}

# roster_update: a worker requests a serialised mutation of a roster TSV;
# the main thread is the serialisation point.
proc spar::_pool_roster_update {row roster_path key_col key_val field new_val} {
    if {[catch {
        spar::update_roster_field $roster_path $key_col $key_val \
            $field $new_val
    } err]} {
        ${::spar::dispatch_log}::warn \
            "roster_update failed for row=$row $key_col=$key_val: $err"
    }
}

package provide spar-dispatcher 1.0

# spar::Dispatcher — coordinator for the GUI's mixed-type job pool.
#
# Owns the row queue, the per-row state map, and the global concurrency
# cap. Posts jobs to a tpool whose worker procs are defined in
# spar-dispatcher-initcmd.tcl. Receives messages from worker threads
# through thread::send -async calls into its on_* methods.
#
# The protocol — twelve message types, the row state machine, and the
# downward sentinel channel — is documented in docs/job-pool.md.
#
# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources.

package require TclOO
package require Thread

if {[info exists ::spar::_pool_loaded]} {
    package provide spar-dispatcher 1.0
    return
}

namespace eval spar {
    variable _pool_loaded 1
    variable pool_script_dir [file dirname [file normalize [info script]]]
}

oo::class create spar::Dispatcher {
    variable Pool Jobs
    variable Queue RowState RowMeta RowJobId
    variable QueuePaused
    variable LogCallback Subs

    # Terminal states. Anything else is non-terminal.
    variable Terminal

    constructor {jobs {log_cb ""}} {
        set Jobs        $jobs
        set Queue       {}
        set RowState    [dict create]
        set RowMeta     [dict create]
        set RowJobId    [dict create]
        set QueuePaused 0
        set LogCallback $log_cb
        set Subs        [dict create]
        set Terminal    {done failed cancelled}

        set me  [self]
        set tid [thread::id]
        set initcmd_path [file join $::spar::pool_script_dir \
            spar-dispatcher-initcmd.tcl]
        set state_path   [file join $::spar::pool_script_dir spar-state.tcl]
        set harness_path [file join $::spar::pool_script_dir spar-harness.tcl]
        set email_path   [file join $::spar::pool_script_dir spar-email.tcl]
        set ses_send_path [file join $::spar::pool_script_dir \
            transitions ses_send_one.tcl]
        set imap_check_path [file join $::spar::pool_script_dir \
            transitions imap_check_one.tcl]

        set initcmd "
            set ::main_tid [list $tid]
            set ::dispatcher [list $me]
            set ::pool_state_file   [list $state_path]
            set ::pool_harness_file [list $harness_path]
            set ::pool_email_file   [list $email_path]
            set ::pool_ses_send_file   [list $ses_send_path]
            set ::pool_imap_check_file [list $imap_check_path]
            source [list $initcmd_path]
        "
        set Pool [tpool::create \
            -minworkers 0 \
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

    method on_roster_update {row roster_path key_col key_val field new_val} {
        if {[catch {
            spar::update_roster_field $roster_path $key_col $key_val \
                $field $new_val
        } err]} {
            my _log "roster_update failed for row=$row $key_col=$key_val: $err"
        }
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

    # _try_post_next — pop queued rows and post them to the tpool while
    # we are below the global cap. The state transitions to running at
    # post time, not at msg_started arrival; this avoids the race where
    # the dict still showed `queued` between post and the asynchronous
    # message arrival, and also lets the cap math read directly from
    # the state map.
    method _try_post_next {} {
        if {$QueuePaused} return
        while {[llength $Queue] > 0 && [llength [my active_rows]] < $Jobs} {
            set row [lindex $Queue 0]
            set Queue [lrange $Queue 1 end]
            if {![dict exists $RowState $row]} continue
            if {[dict get $RowState $row] ne "queued"} continue
            set meta [dict get $RowMeta $row]
            set worker [dict get $meta worker]
            set opts   [dict get $meta opts]
            dict set RowMeta $row started_at [clock milliseconds]
            my _set_state $row running
            set jobid [tpool::post -nowait $Pool \
                [list $worker $row $opts]]
            dict set RowJobId $row $jobid
        }
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
        if {$LogCallback ne ""} {
            {*}$LogCallback "spar::Dispatcher: $msg"
        }
    }
}

package provide spar-dispatcher 1.0

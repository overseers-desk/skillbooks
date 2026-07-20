# spar::Dispatcher - the campaign job pool.
#
# The generic coordinator (queue, per-row state machine, concurrency caps,
# cooperative cancel/pause, the worker-report surface, the event stream)
# is the vendored `jobloop` module. spar::Dispatcher subclasses it to
# supply what is spar's own: the logger service and the domain reports a
# spar worker sends that a generic pool does not know - cost, retry,
# credit warnings, and roster updates.
#
# Each job runs as a coroutine on the front-end's own event loop; there is
# no worker thread and no message marshalling. The worker bodies
# (harness_run / ses_send / linkedin_send / imap_poll) live in the main
# interpreter, sourced at the bottom of this file alongside the
# harness/email/transition code they call.
#
# The generic protocol is documented in the jobloop man page; the spar
# additions and the per-kind cap policy live in docs/concurrency.md.
#
# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources.

package require logger

if {[info exists ::spar::_pool_loaded]} {
    package provide spar-dispatcher 1.0
    return
}

namespace eval spar {
    variable _pool_loaded 1
    # Live coachman harnesses, keyed by row, published by harness_run for
    # the span of its run() so a front-end's cancel can abort them.
    variable live_harnesses [dict create]
    variable pool_script_dir [file dirname [file normalize [info script]]]
    # vendor/ carries the jobloop module; a checkout runs as-is.
    ::tcl::tm::path add [file join $pool_script_dir .. vendor]
    # Logger service for the pool's dropped/out-of-order warnings.
    variable dispatch_log [logger::init spar::dispatch]
}
package require jobloop

oo::class create spar::Dispatcher {
    superclass jobloop

    # Keep spar's construction signature (jobs, optional log callback);
    # feed jobloop spar's logger service. jobloop has no worker bootstrap:
    # the worker bodies are commands in this interpreter, sourced below.
    variable RequeuedOnce

    constructor {jobs {log_cb ""}} {
        next $jobs -log $log_cb -logger spar::dispatch
        set RequeuedOnce [dict create]
    }

    # ─── spar's domain reports ───────────────────────────────────────
    # A generic pool carries lifecycle; these four are spar's own worker
    # signals. cost/retry/credit_warning are informational (they fire an
    # event and change no state); roster_update is relayed whole to the
    # serialising handler wired below.

    method on_cost {row stage usd} {
        if {![my _expect_active $row cost]} return
        my _fire job-cost $row $stage $usd
    }
    method on_retry {row stage attempt max} {
        if {![my _expect_active $row retry]} return
        my _fire job-retry $row $stage $attempt $max
    }
    method on_credit_warning {row usd_window window_secs} {
        if {![my _expect_active $row credit_warning]} return
        my _fire job-credit-warning $row $usd_window $window_secs
    }
    method on_roster_update {args} {
        if {![my subscribed domain-roster_update]} {
            my _log "roster_update with no subscriber; dropping: $args"
            return
        }
        my _fire domain-roster_update {*}$args
    }

    # Requeue-on-token (#181): a ProfileHarness run that closed cleanly
    # without writing its outfile reports failed with this token (via
    # harness_run rc=4). The job goes terminal as usual, then back to
    # the queue tail, so the retry runs after the congestion that
    # starved the first attempt has drained. Two caps, two owners: the
    # harness's prompt-dir marker turns a second untouched close into a
    # plain FAIL (with slug and cost context), and RequeuedOnce keeps
    # this pool from looping even if a worker keeps reporting the token.
    #
    # job-requeued fires BEFORE the failed events so a front-end's
    # counters can treat them as an intermediate pair, not a final
    # outcome (the CLI skips them; the GUI is state-driven and needs
    # nothing). The requeue itself is deferred off this coroutine's
    # stack: done synchronously, the state re-flips to queued/running
    # before RunJob's no-verb fallback reads it, and the fallback would
    # stamp the requeued incarnation done.
    method on_failed {job reason} {
        set will_requeue 0
        if {[string match {*PROFILE_UNTOUCHED_RETRY*} $reason]
                && ![dict exists $RequeuedOnce $job]
                && ![catch {my state $job} _s]
                && $_s in {running paused rate_limited}} {
            set will_requeue 1
            dict set RequeuedOnce $job 1
            my _fire job-requeued $job
        }
        next $job $reason
        if {$will_requeue && [my state $job] eq "failed"} {
            after 0 [list [self] requeue_failed $job]
        }
    }

    # The deferred half of the token requeue. Public because the timer
    # dispatches it through the object command. The state guard covers
    # the gap: a job cancelled, pruned, or re-reported between the
    # failed event and this timer stays where it is.
    method requeue_failed {job} {
        if {[catch {my state $job} s]} return
        if {$s eq "failed"} { my requeue $job }
    }
}

# ─── spar's wiring ───────────────────────────────────────────────────────

# Both front-ends call this right after constructing their Dispatcher, to
# wire the one domain report that carries semantics: roster_update, a
# request for a serialised mutation of a roster TSV. Coroutines run on the
# one event loop, so the mutation is already serialised; the worker may
# also call spar::update_roster_field itself. This subscriber keeps the
# domain event usable for a caller that reports through the pool instead.
proc spar::subscribe_pool_domain {disp} {
    $disp subscribe domain-roster_update ::spar::_pool_roster_update
}
# is_usage_limit_halt — true when a worker's failure reason carries
# coachman's stable USAGE_LIMIT_UNRECOGNIZED token: a claude usage limit
# whose wording coachman no longer parses (a reworded window, or a
# monthly/spend/fast limit). Both front-ends test it to halt dispatch
# loudly instead of grinding every remaining row into the same limit.
# The token is coachman's contract (documented at its _invoke); this is
# the single place spar names it.
proc spar::is_usage_limit_halt {reason} {
    return [string match {*USAGE_LIMIT_UNRECOGNIZED*} $reason]
}

# halt_dispatch_queue — cancel every still-queued row on the dispatcher so
# no new job launches; in-flight rows finish on their own. Returns the
# count cancelled. The shared half of each front-end's usage-limit halt;
# the front-end adds its own loud report (stderr line, or a dialog).
proc spar::halt_dispatch_queue {disp} {
    set queued [$disp queued_jobs]
    foreach r $queued { $disp cancel $r }
    return [llength $queued]
}

# live_harness_count — how many coachman harnesses are running right now,
# the abortable in-flight runs (a short send worker holds none). A
# front-end reads it to size its "also stop the in-flight run(s)?" prompt.
proc spar::live_harness_count {} {
    variable live_harnesses
    return [dict size $live_harnesses]
}

# abort_live_harnesses — abort every running coachman harness. Each abort
# is sticky, so the harness ends its whole run (not just the current
# stage) and reports failed through harness_run, which unpublishes it.
# Returns the count told to stop. In-flight short sends are not harnesses
# and are left to finish.
proc spar::abort_live_harnesses {} {
    variable live_harnesses
    set n 0
    dict for {row inst} $live_harnesses {
        if {[catch {$inst abort}]} continue
        incr n
    }
    return $n
}

proc spar::_pool_roster_update {row roster_path key_col key_val field new_val} {
    if {[catch {
        spar::update_roster_field $roster_path $key_col $key_val \
            $field $new_val
    } err]} {
        ${::spar::dispatch_log}::warn \
            "roster_update failed for row=$row $key_col=$key_val: $err"
    }
}

# ─── Worker code, loaded once into the main interpreter ──────────────────
#
# jobloop's workers are commands in this interpreter, not procs seeded into
# a thread pool. Source the harness, email, and per-row transition helpers
# the worker bodies call, then the worker bodies themselves. The guard at
# the top of this file runs the block once; spar-harness carries its own
# re-source guard, and the email/transition files only redefine procs.
apply {{} {
    variable ::spar::pool_script_dir
    set d $::spar::pool_script_dir
    source [file join $d spar-email.tcl]
    source [file join $d spar-harness.tcl]
    source [file join $d .. transitions ses_send_one.tcl]
    source [file join $d .. transitions linkedin_send_one.tcl]
    source [file join $d .. transitions imap_check_one.tcl]
    source [file join $d spar-dispatcher-initcmd.tcl]
}}

package provide spar-dispatcher 1.0

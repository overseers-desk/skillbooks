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
    variable pool_script_dir [file dirname [file normalize [info script]]]
    # vendor/ carries the jobloop module; a checkout runs as-is.
    ::tcl::tm::path add [file join $pool_script_dir vendor]
    # Logger service for the pool's dropped/out-of-order warnings.
    variable dispatch_log [logger::init spar::dispatch]
}
package require jobloop

oo::class create spar::Dispatcher {
    superclass jobloop

    # Keep spar's construction signature (jobs, optional log callback);
    # feed jobloop spar's logger service. jobloop has no worker bootstrap:
    # the worker bodies are commands in this interpreter, sourced below.
    constructor {jobs {log_cb ""}} {
        next $jobs -log $log_cb -logger spar::dispatch
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
    source [file join $d transitions ses_send_one.tcl]
    source [file join $d transitions linkedin_send_one.tcl]
    source [file join $d transitions imap_check_one.tcl]
    source [file join $d spar-dispatcher-initcmd.tcl]
}}

package provide spar-dispatcher 1.0

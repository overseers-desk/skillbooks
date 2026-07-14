# spar::Dispatcher — the campaign job pool.
#
# The generic coordinator (queue, per-row state machine, concurrency caps,
# cooperative cancel/pause, the worker-message surface, the event stream)
# is the vendored `jobpool` module. spar::Dispatcher subclasses it to
# supply what is spar's own: the worker bootstrap manifest, the logger
# service, and the domain messages a spar worker sends that a generic pool
# does not know — cost, retry, credit warnings, and roster updates.
#
# The generic protocol is documented in the jobpool man page; the spar
# additions and the per-worker cap policy live in docs/concurrency.md.
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
    # vendor/ carries the jobpool module; a checkout runs as-is.
    ::tcl::tm::path add [file join $pool_script_dir vendor]
    # Logger service for the pool's dropped/out-of-order warnings.
    variable dispatch_log [logger::init spar::dispatch]
}
package require jobpool

oo::class create spar::Dispatcher {
    superclass jobpool

    # Keep spar's construction signature (jobs, optional log callback);
    # feed jobpool the worker bootstrap and spar's logger service.
    constructor {jobs {log_cb ""}} {
        next $jobs -log $log_cb -init [spar::pool_initcmd] \
            -logger spar::dispatch
    }

    # ─── spar's domain messages ──────────────────────────────────────
    # A generic pool carries lifecycle; these four are spar's own worker
    # signals. cost/retry/credit_warning are informational (they fire an
    # event and change no state); roster_update is relayed whole to the
    # serialising handler wired below.

    method on_cost {row stage usd} {
        if {![my _expect_active $row cost]} return
        my _fire row-cost $row $stage $usd
    }
    method on_retry {row stage attempt max} {
        if {![my _expect_active $row retry]} return
        my _fire row-retry $row $stage $attempt $max
    }
    method on_credit_warning {row usd_window window_secs} {
        if {![my _expect_active $row credit_warning]} return
        my _fire row-credit-warning $row $usd_window $window_secs
    }
    method on_roster_update {args} {
        if {![my subscribed domain-roster_update]} {
            my _log "roster_update with no subscriber; dropping: $args"
            return
        }
        my _fire domain-roster_update {*}$args
    }
}

# ─── spar's wiring, fed to the pool ──────────────────────────────────────

# The worker bootstrap: the file globals the worker procs read, then the
# worker definitions.
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

# Both front-ends call this right after constructing their Dispatcher, to
# wire the one domain message that carries semantics: roster_update, a
# worker's request for a serialised mutation of a roster TSV, run on the
# main thread.
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

package provide spar-dispatcher 1.0

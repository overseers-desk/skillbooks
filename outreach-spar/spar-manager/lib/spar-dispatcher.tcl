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

    # ─── requeue-on-token ────────────────────────────────────────────
    # Unlike the passive report relays above, this pair changes
    # dispatch behaviour.
    #
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
    # outcome; both front-ends skip them (the CLI's _retry_pending, the
    # GUI controller's RetryPending). The requeue itself is deferred off
    # this coroutine's stack: done synchronously, the state re-flips to
    # queued/running before RunJob's no-verb fallback reads it, and the
    # fallback would stamp the requeued incarnation done.
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
            after 1 [list [self] requeue_failed $job]
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
# halt_kind — which batch-fatal wall a worker's failure reason names, or
# "" for an ordinary per-row failure. Two walls, both coachman's stable
# tokens (its _invoke documents the contract; this proc is the single
# place spar names them):
#
#   usage_limit        a claude usage limit whose wording coachman no
#                      longer parses (a reworded window, or a monthly,
#                      spend or fast limit)
#   api_access_denied  the API refusing the account the run
#                      authenticates as, HTTP 401 or 403
#
# Both front-ends test this to halt dispatch loudly instead of grinding
# every remaining row into the same wall. It returns the kind rather
# than a yes/no because the operator's next move differs: one is a clock
# to wait out, the other is the wrong account to correct.
proc spar::halt_kind {reason} {
    if {[string match {*USAGE_LIMIT_UNRECOGNIZED*} $reason]} { return usage_limit }
    if {[string match {*API_ACCESS_DENIED*} $reason]}        { return api_access_denied }
    return ""
}

# halt_dispatch_queue — cancel every still-queued row on the dispatcher so
# no new job launches; in-flight rows finish on their own. Returns the
# count cancelled. The shared half of each front-end's wall halt; the
# front-end adds its own loud report (stderr line, or a dialog).
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
# a thread pool. The harness, email, and per-row transition helpers the
# worker bodies call are sourced here; the bodies (harness_run / ses_send /
# linkedin_send / imap_poll) follow.
#
# Under jobloop each job runs as a coroutine on the front-end's event
# loop, in this interpreter. A worker reports through the jobloop verbs
# (checkpoint / phase / progress / done / failed / rate_limited /
# rate_limit_cleared), picked up by the `namespace path` below; there is
# no thread to marshal to and no cancel/pause sentinel to poll - the
# checkpoint verb observes both. Roster mutations run on this thread by
# construction, so a worker calls spar::update_roster_field directly.
#
# A worker waits the loop's way: it never blocks on a synchronous read or
# a bare vwait, which would stall every other job in the process. The
# coroutine-aware waits (spar::pool_sleep / pool_exec / pool_http) live in
# spar-lib.tcl, the shared base, so the harness path reaches them too; each
# falls back to the blocking form when called outside a coroutine.
apply {{} {
    variable ::spar::pool_script_dir
    set d $::spar::pool_script_dir
    source [file join $d spar-email.tcl]
    source [file join $d spar-harness.tcl]
    source [file join $d .. transitions ses_send_one.tcl]
    source [file join $d .. transitions linkedin_send_one.tcl]
    source [file join $d .. transitions imap_check_one.tcl]
}}


# The worker bodies are global procs; this line lets an unqualified
# `checkpoint` / `done` / `failed` inside them resolve to the jobloop
# verbs. Each verb finds its owning pool from [info coroutine].
namespace path ::jobloop::worker

# ─── Worker proc bodies (production) ─────────────────────────────────────
#
# A worker owns its row's slot from the moment jobloop launches its
# coroutine (state -> running) until it reports a terminal verb - done,
# failed, or cancelled (the last raised by checkpoint). jobloop reclaims
# the slot on that verb, and also frees it if the body returns with no
# terminal verb (reported done empty) or raises (reported failed). So a
# body cannot strand its slot: an uncaught throw anywhere - a missing opts
# key, an error from the harness constructor - is caught by jobloop's
# RunJob and reported failed. Each body still names its own terminal verb
# on every normal path.

# harness_run - drive a Profile or Approach harness end-to-end for one
# row. opts must carry:
#   prompt_dir    - directory the harness reads (prompt.txt, meta.env,
#                   author-draft.txt, etc.)
#   log_dir       - directory the harness writes (-cost.jsonl, -*.log,
#                   -*.json transcripts)
#   harness_class - TclOO class command, normally spar::ProfileHarness or
#                   spar::ApproachHarness. Tests may pass a stub class of
#                   the same constructor + run shape.
#
# The claude session inside the harness is driven through deadman with an
# async completion (see spar-harness.tcl _invoke), so a long run yields the
# loop rather than freezing it. Cancel-checked once before the harness
# starts; a mid-run cancel reaches the harness through
# spar::abort_live_harnesses, which the harness is published for below.
proc harness_run {row opts} {
    checkpoint $row

    # Dry-run short-circuit. prepare_for_pool has already assembled the
    # prompt dir exactly as a live run would. The only side-effecting step
    # left is the claude exec inside the harness, which authors and writes
    # the output file, so skip it and report done. This mirrors
    # ses_send_one's dry-run return. Read with plain dict ops so the check
    # needs no spar:: helpers.
    if {[dict exists $opts dry_run] && [dict get $opts dry_run]} {
        done $row [list dry_run 1]
        return
    }

    set prompt_dir    [dict get $opts prompt_dir]
    set log_dir       [dict get $opts log_dir]
    set harness_class [dict get $opts harness_class]

    set rc 1
    set cause ""
    if {[catch {
        set inst [$harness_class new $prompt_dir $log_dir]
        # Publish the live harness so a front-end's cancel can abort it
        # mid-run (spar::abort_live_harnesses). Registered only for the
        # span of run(); a short send worker (ses/linkedin/imap) has no
        # harness and never appears here.
        dict set ::spar::live_harnesses $row $inst
        try {
            set rc [$inst run]
        } finally {
            dict unset ::spar::live_harnesses $row
        }
        if {$rc != 0} { catch {set cause [$inst fail_cause]} }
        catch {$inst destroy}
    } err]} {
        catch {dict unset ::spar::live_harnesses $row}
        failed $row "harness_run: $err"
        return
    }
    if {$rc == 0} {
        done $row [list rc 0]
    } elseif {$rc == 4} {
        # ProfileHarness truth-check (#181): clean close, outfile untouched,
        # first occurrence. The token routes spar::Dispatcher::on_failed to
        # requeue the row at the queue tail; the harness's prompt-dir marker
        # caps it at one retry.
        failed $row "PROFILE_UNTOUCHED_RETRY: profile not written by this run"
    } else {
        failed $row "harness exited rc=$rc[expr {$cause ne "" ? " | $cause" : ""}]"
    }
}

# ses_send - drive one row through SES SMTP. opts is the per-row payload
# built by the controller / CLI runner: campaign_file, dry_run,
# approach_path, sender (the campaign sender dict), and an optional
# delay_ms used to pace consecutive sends. Cancel checked once before the
# send; per-stage cancel inside the SMTP exchange is not implemented (the
# exchange is short). delay_ms is honoured after a successful send so a
# run of many rows does not breach SES's per-second cap; a failed row does
# not pace - the failure did not reach SES.
proc ses_send {row opts} {
    checkpoint $row
    set rc [catch {::spar::ses::send_one $opts} result]
    if {$rc != 0} {
        failed $row "ses_send: $result"
        return
    }
    set status [lindex $result 0]
    set detail [lindex $result 1]
    if {$status eq "ok"} {
        set delay_ms [dict getdef $opts delay_ms 0]
        if {$delay_ms > 0} { spar::pool_sleep $delay_ms }
        done $row [list message_id $detail]
    } else {
        failed $row $detail
    }
}

# linkedin_send - drive one row through the overseer's POST /run
# (spar::li::send_one in transitions/linkedin_send_one.tcl). No delay_ms
# pacing here: the overseer's linkedin.com rate gate owns the cadence.
# Serialised by set_kind_cap linkedin_send 1, installed beside ses_send's
# cap.
proc linkedin_send {row opts} {
    checkpoint $row
    # A send parks server-side behind the rate gate, an open breaker or a
    # held account, and the row would otherwise show nothing for the whole
    # wait. send_one's probe already reads why, so hand it the pool's phase
    # verb to say so; the GUI shows a running row's phase as its reason.
    dict set opts note_cmd [list ::jobloop::worker::phase $row]
    set rc [catch {::spar::li::send_one $opts} result]
    if {$rc != 0} {
        failed $row "linkedin_send: $result"
        return
    }
    set status [lindex $result 0]
    set detail [lindex $result 1]
    if {$status eq "ok"} {
        done $row [list result $detail]
    } else {
        failed $row $detail
    }
}

# imap_poll - drive one row through one inbox-search + zero-or-more
# inbox-read cycle. opts is the per-row payload: campaign_file, dry_run,
# approach_path, to_email, fingerprints, account, folder, sender. Cancel
# checked once at entry; the courier calls are driven through the exec
# helper, so a slow inbox yields the loop rather than freezing it.
proc imap_poll {row opts} {
    checkpoint $row
    set rc [catch {::spar::imap::check_one $opts} result]
    if {$rc != 0} {
        failed $row "imap_poll: $result"
        return
    }
    set status [lindex $result 0]
    set detail [lindex $result 1]
    if {$status eq "ok"} {
        done $row [list new_replies $detail]
    } else {
        failed $row $detail
    }
}

package provide spar-dispatcher 1.0

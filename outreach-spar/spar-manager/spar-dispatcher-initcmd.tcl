# Sourced into each tpool worker thread by spar::Dispatcher's constructor.
# Defines the message-sending procs (msg_*), the cancel/pause sentinel
# helpers, the worker proc bodies (harness_run / ses_send / imap_poll),
# and test fixtures (fake_worker, fake_harness_class).
#
# Globals available when this file is sourced:
#   ::main_tid           — main thread id, target of all msg_* sends
#   ::dispatcher         — spar::Dispatcher object command in the main thread
#   ::pool_state_file    — abs path to spar-state.tcl  (lazy-sourced by harness_run)
#   ::pool_harness_file  — abs path to spar-harness.tcl (lazy-sourced by harness_run)
#   ::pool_email_file    — abs path to spar-email.tcl  (lazy-sourced by ses_send / imap_poll)
#   ::pool_ses_send_file — abs path to ses_send_one.tcl (lazy-sourced by ses_send)
#   ::pool_imap_check_file — abs path to imap_check_one.tcl (lazy-sourced by imap_poll)
#
# Worker bodies (harness_run / ses_send / imap_poll / fake_worker) are
# the only callers of msg_*; nothing else in worker-thread code may
# call thread::send directly. The grep
#     grep -n 'thread::send' transitions/*.tcl spar-harness.tcl
# must return only matches inside msg_* proc bodies.

package require Thread
package require Tcl 9

# ─── Message procs (worker → Dispatcher) ─────────────────────────────────
#
# Note: there is no msg_started. The Dispatcher transitions a row from
# queued to running at tpool::post time, before the worker thread is
# necessarily even running. The worker's first action is whatever real
# work the row needs; it does not need to announce that it has started.

proc msg_phase {row phase} {
    thread::send -async $::main_tid [list $::dispatcher on_phase $row $phase]
}
proc msg_progress {row text} {
    thread::send -async $::main_tid [list $::dispatcher on_progress $row $text]
}
proc msg_done {row {result {}}} {
    thread::send -async $::main_tid [list $::dispatcher on_done $row $result]
}
proc msg_failed {row reason} {
    thread::send -async $::main_tid [list $::dispatcher on_failed $row $reason]
}
proc msg_cancelled {row} {
    thread::send -async $::main_tid [list $::dispatcher on_cancelled $row]
}
proc msg_roster_update {row roster_path key_col key_val field new_val} {
    thread::send -async $::main_tid [list $::dispatcher on_roster_update \
        $row $roster_path $key_col $key_val $field $new_val]
}
proc msg_cost {row stage usd} {
    thread::send -async $::main_tid [list $::dispatcher on_cost \
        $row $stage $usd]
}
proc msg_retry {row stage attempt max} {
    thread::send -async $::main_tid [list $::dispatcher on_retry \
        $row $stage $attempt $max]
}
proc msg_rate_limited {row reset_at} {
    thread::send -async $::main_tid [list $::dispatcher on_rate_limited \
        $row $reset_at]
}
proc msg_rate_limit_cleared {row} {
    thread::send -async $::main_tid [list $::dispatcher on_rate_limit_cleared $row]
}
proc msg_paused {row} {
    thread::send -async $::main_tid [list $::dispatcher on_paused $row]
}
proc msg_resumed {row} {
    thread::send -async $::main_tid [list $::dispatcher on_resumed $row]
}
proc msg_credit_warning {row usd_window window_secs} {
    thread::send -async $::main_tid [list $::dispatcher on_credit_warning \
        $row $usd_window $window_secs]
}

# ─── Sentinel helpers (Dispatcher → worker via tsv) ──────────────────────

# Workers must use these instead of reading the tsv directly. The tsv
# array name is stable across threads.
proc worker_cancel_requested? {row} {
    return [tsv::exists ::spar::pool $row.cancel]
}
proc worker_pause_requested? {row} {
    return [tsv::exists ::spar::pool $row.pause]
}

# ─── Worker proc bodies (production) ─────────────────────────────────────

# _ensure_harness_loaded — lazy-source spar-harness (and its deps) into
# this worker interp. Called by harness_run on first use; subsequent
# rows on the same worker reuse the loaded packages. The package
# guards in spar-state.tcl / spar-harness.tcl make repeat sources cheap.
proc _ensure_harness_loaded {} {
    if {[info exists ::spar::_harness_loaded]} { return }
    uplevel #0 [list source $::pool_state_file]
    uplevel #0 [list source $::pool_harness_file]
    set ::spar::_harness_loaded 1
}

# _ensure_email_loaded — lazy-source spar-state.tcl + spar-email.tcl +
# the per-row send/check helpers into this worker interp. Called by
# ses_send and imap_poll on first use. The package guards on each file
# make repeat sources cheap; the worker reuses the loaded code on
# subsequent rows.
proc _ensure_email_loaded {} {
    if {[info exists ::spar::_email_loaded]} { return }
    uplevel #0 [list source $::pool_state_file]
    uplevel #0 [list source $::pool_email_file]
    uplevel #0 [list source $::pool_ses_send_file]
    uplevel #0 [list source $::pool_imap_check_file]
    set ::spar::_email_loaded 1
}

# harness_run — drive a Profile or Approach harness end-to-end for one
# row. opts must carry:
#   prompt_dir    — directory the harness reads (prompt.txt, meta.env,
#                   author-draft.txt, etc.)
#   log_dir       — directory the harness writes (-cost.jsonl, -*.log,
#                   -*.json transcripts)
#   harness_class — TclOO class command, normally
#                   spar::ProfileHarness or spar::ApproachHarness.
#                   Tests may pass a stub class providing the same
#                   constructor + run shape.
#
# Cancel-checked once before the harness starts. Per-stage cancel
# inside the harness is deferred — see docs/concurrency.md "Deferred
# work" — so a cancel that arrives while exec claude is in flight
# only takes effect after the current call returns.
#
# Phase-2 scope: harness_run only emits msg_done / msg_failed /
# msg_cancelled. The msg_phase / msg_cost / msg_rate_limited call
# sites inside spar-harness.tcl can land in a later commit; the
# Dispatcher's on_* handlers for those messages already exist.
proc harness_run {row opts} {
    if {[worker_cancel_requested? $row]} {
        msg_cancelled $row
        return
    }

    # Dry-run short-circuit. prepare_for_pool has already assembled the
    # prompt dir exactly as a live run would. The only side-effecting step
    # left is the claude exec inside the harness, which authors and writes
    # the output file, so skip it and report done. This mirrors
    # ses_send_one's `if {$dry_run} {return [list ok dry-run]}`. Read with
    # plain dict ops so the check needs no spar:: helpers loaded yet.
    if {[dict exists $opts dry_run] && [dict get $opts dry_run]} {
        msg_done $row [list dry_run 1]
        return
    }

    _ensure_harness_loaded

    set prompt_dir    [dict get $opts prompt_dir]
    set log_dir       [dict get $opts log_dir]
    set harness_class [dict get $opts harness_class]

    set rc 1
    if {[catch {
        set inst [$harness_class new $prompt_dir $log_dir]
        set rc [$inst run]
        catch {$inst destroy}
    } err]} {
        msg_failed $row "harness_run: $err"
        return
    }
    if {$rc == 0} {
        msg_done $row [list rc 0]
    } else {
        msg_failed $row "harness exited rc=$rc"
    }
}

# ses_send — drive one row through SES SMTP. The opts dict is the
# per-row payload built by the controller / CLI runner: it carries
# campaign_file, dry_run, approach_path, sender (the campaign sender
# dict), and an optional delay_ms used to pace consecutive sends from
# the same worker thread. Cancel sentinel checked once before the
# send; per-stage cancel inside the SMTP exchange is not implemented
# (the SMTP exec is synchronous and short — typically a few seconds).
#
# delay_ms is honoured after a successful send so a worker that
# processes many rows in succession does not breach SES's per-second
# cap. Failed rows do not pace — the failure didn't reach SES.
proc ses_send {row opts} {
    if {[worker_cancel_requested? $row]} {
        msg_cancelled $row
        return
    }
    _ensure_email_loaded
    set rc [catch {::spar::ses::send_one $opts} result]
    if {$rc != 0} {
        msg_failed $row "ses_send: $result"
        return
    }
    set status [lindex $result 0]
    set detail [lindex $result 1]
    if {$status eq "ok"} {
        set delay_ms [spar::dict_get_default $opts delay_ms 0]
        if {$delay_ms > 0} {
            set ::ses_delay_done 0
            after $delay_ms set ::ses_delay_done 1
            vwait ::ses_delay_done
        }
        msg_done $row [list message_id $detail]
    } else {
        msg_failed $row $detail
    }
}

# imap_poll — drive one row through one inbox-search + zero-or-more
# inbox-read cycle. opts is the per-row payload built by the
# controller / CLI runner: campaign_file, dry_run, approach_path,
# to_email, fingerprints, account, folder, sender. Cancel checked
# once at entry; mailroom calls are synchronous and brief.
proc imap_poll {row opts} {
    if {[worker_cancel_requested? $row]} {
        msg_cancelled $row
        return
    }
    _ensure_email_loaded
    set rc [catch {::spar::imap::check_one $opts} result]
    if {$rc != 0} {
        msg_failed $row "imap_poll: $result"
        return
    }
    set status [lindex $result 0]
    set detail [lindex $result 1]
    if {$status eq "ok"} {
        msg_done $row [list new_replies $detail]
    } else {
        msg_failed $row $detail
    }
}

# ─── Worker test fixtures ────────────────────────────────────────────────

# fake_worker — runs a scripted plan of message and sentinel-check
# steps. Used only by test/test-pool.tcl to drive the Dispatcher
# without real claude/SES/IMAP backends.
#
# opts is a dict with at least one key, "plan", which is a list of
# tuples. If the plan does not end with a terminal message, auto-emits
# msg_done.
#
# Plan tuples:
#   {sleep ms}                           — yield to event loop for ms
#                                          (vwait+after; worker remains
#                                          responsive to thread::send)
#   {exec_sleep secs}                    — block the worker thread in a
#                                          real exec for secs (mimics the
#                                          harness's exec claude). Used by
#                                          test/test-pool.tcl §17 to assert
#                                          the pool actually parallelises;
#                                          a worker holding this step is
#                                          OS-blocked, not event-loop
#                                          responsive — which is what the
#                                          production harness looks like.
#   {msg_<name> arg ...}                 — emit the named message
#   {check_cancel}                       — exit as cancelled if sentinel set
#   {check_pause poll_ms}                — pause while sentinel set
proc fake_worker {row opts} {
    set plan [dict get $opts plan]
    set terminal_emitted 0
    foreach step $plan {
        set action [lindex $step 0]
        set rest   [lrange $step 1 end]
        switch -- $action {
            sleep {
                set ms [lindex $rest 0]
                set ::sleep_done 0
                after $ms set ::sleep_done 1
                vwait ::sleep_done
            }
            exec_sleep {
                set secs [lindex $rest 0]
                exec sleep $secs
            }
            check_cancel {
                if {[worker_cancel_requested? $row]} {
                    msg_cancelled $row
                    set terminal_emitted 1
                    break
                }
            }
            check_pause {
                set poll_ms [expr {[llength $rest] ? [lindex $rest 0] : 50}]
                if {[worker_pause_requested? $row]} {
                    msg_paused $row
                    while {[worker_pause_requested? $row]} {
                        set ::pause_tick 0
                        after $poll_ms set ::pause_tick 1
                        vwait ::pause_tick
                    }
                    msg_resumed $row
                }
            }
            default {
                # Treat as a msg_* invocation; track if it's terminal.
                if {$action in {msg_done msg_failed msg_cancelled}} {
                    set terminal_emitted 1
                }
                {*}[concat [list $action $row] $rest]
            }
        }
    }
    if {!$terminal_emitted} { msg_done $row {} }
}

# fake_worker_a / fake_worker_b — aliases for fake_worker that test-pool.tcl
# §18 ("Per-worker cap") uses to drive distinct worker_proc names through
# one shared pool. Production code never references them; they exist only
# so set_worker_cap can apply different caps to two otherwise-identical
# workers.
proc fake_worker_a {row opts} { fake_worker $row $opts }
proc fake_worker_b {row opts} { fake_worker $row $opts }

# FakeHarness — minimal harness shape used by test/test-pool.tcl to
# exercise harness_run without sourcing spar-harness.tcl or invoking
# claude. Mirrors the constructor signature of spar::ProfileHarness /
# spar::ApproachHarness ([new $prompt_dir $log_dir]) and the run
# contract (returns 0 = success, 1 = failure). Reads a single token
# from $prompt_dir/run-rc to choose its return: "0" passes, "1" fails,
# "throw" raises an error to exercise the catch path.
#
# Defined here so it lives in the same worker interp as harness_run.
# Production code never instantiates it; if no test posts a job that
# touches it, the class simply sits in the worker interp as dead code.
package require TclOO
oo::class create FakeHarness {
    variable PromptDir LogDir
    constructor {prompt_dir log_dir} {
        set PromptDir $prompt_dir
        set LogDir    $log_dir
        file mkdir $log_dir
    }
    method run {} {
        set rc_file [file join $PromptDir run-rc]
        if {![file exists $rc_file]} { return 0 }
        set fd [open $rc_file r]; set rc [string trim [read $fd]]; close $fd
        switch -- $rc {
            0       { return 0 }
            1       { return 1 }
            throw   { error "fake harness deliberate error" }
            default { return 0 }
        }
    }
}

# Sourced into each tpool worker thread by spar::Dispatcher's constructor.
# Defines the message-sending procs (msg_*), the cancel/pause sentinel
# helpers, the worker proc bodies (added in Phase 2), and a fake_worker
# proc used by tests.
#
# Globals available when this file is sourced:
#   ::main_tid    — the main thread id, target of all msg_* sends
#   ::dispatcher  — the spar::Dispatcher object command in the main thread
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

# ─── Worker test fixture ─────────────────────────────────────────────────

# fake_worker — runs a scripted plan of message and sentinel-check
# steps. Used only by test/test-pool.tcl to drive the Dispatcher
# without real claude/SES/IMAP backends.
#
# opts is a dict with at least one key, "plan", which is a list of
# tuples. If the plan does not end with a terminal message, auto-emits
# msg_done.
#
# Plan tuples:
#   {sleep ms}                           — block this thread for ms
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

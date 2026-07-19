# Sourced into the main interpreter by spar-dispatcher.tcl. Defines the
# worker proc bodies (harness_run / ses_send / linkedin_send / imap_poll)
# and the test fixtures (fake_worker, FakeHarness).
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

package require Tcl 9

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
# starts; per-stage cancel inside the harness is deferred (see
# docs/concurrency.md "Deferred and adjacent work").
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
        set rc [$inst run]
        if {$rc != 0} { catch {set cause [$inst fail_cause]} }
        catch {$inst destroy}
    } err]} {
        failed $row "harness_run: $err"
        return
    }
    if {$rc == 0} {
        done $row [list rc 0]
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

# ─── Worker test fixtures ────────────────────────────────────────────────

# fake_worker - runs a scripted plan of report and checkpoint steps. Used
# only by test/test-pool.tcl to drive the Dispatcher without real
# claude/SES/IMAP backends.
#
# opts is a dict with at least one key, "plan", a list of tuples. If the
# plan does not end with a terminal verb, auto-emits done.
#
# Plan tuples:
#   {sleep ms}                - yield to the loop for ms (timer + yield)
#   {msg_<verb> arg ...}      - call the named jobloop verb (the msg_
#                               prefix is the historical spelling)
#   {check_cancel}            - checkpoint: unwind as cancelled if flagged
proc fake_worker {row opts} {
    set plan [dict get $opts plan]
    set terminal_emitted 0
    foreach step $plan {
        set action [lindex $step 0]
        set rest   [lrange $step 1 end]
        switch -- $action {
            sleep {
                spar::pool_sleep [lindex $rest 0]
            }
            check_cancel {
                checkpoint $row
            }
            default {
                # A step names a jobloop verb, historically msg_<verb>.
                set verb [regsub {^msg_} $action {}]
                if {$verb in {done failed}} { set terminal_emitted 1 }
                {*}[concat [list $verb $row] $rest]
            }
        }
    }
    if {!$terminal_emitted} { done $row {} }
}

# FakeHarness - minimal harness shape used by test/test-pool.tcl to
# exercise harness_run without sourcing the real harness or invoking
# claude. Mirrors the constructor signature of spar::ProfileHarness /
# spar::ApproachHarness ([new $prompt_dir $log_dir]) and the run contract
# (returns 0 = success, 1 = failure). Reads a single token from
# $prompt_dir/run-rc to choose its return: "0" passes, "1" fails, "throw"
# raises an error to exercise the catch path. Production code never
# instantiates it.
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
    # Mirror spar::Harness::fail_cause so harness_run can fold a cause into
    # the failure reason for the run-end roll-call. Reads an optional
    # run-cause file.
    method fail_cause {} {
        set f [file join $PromptDir run-cause]
        if {![file exists $f]} { return "" }
        set fd [open $f r]; set c [string trim [read $fd]]; close $fd
        return $c
    }
}

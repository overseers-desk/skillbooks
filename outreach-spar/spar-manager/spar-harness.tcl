# spar-harness.tcl — TclOO base class plus Approach and Profile subclasses
# for harnessed Claude CLI sessions.
#
# A "harness" wraps a single claude session with the machinery the DbC
# contract requires: JSON invocation, credit-limit retry, session-resume
# for fix loops, per-stage cost ledger. The spar::ApproachHarness and
# spar::ProfileHarness subclasses supply the phase-specific
# validate_and_correct loop and orchestration.
#
# Requires spar-state.tcl sourced first (for spar::State,
# spar::dict_get_default, and the validators).

package require json
package require json::write
package require TclOO
package require logger
# vendor/ carries the modules this app depends on: a checkout runs as-is,
# and an upstream bump lands as a reviewable diff. deadman's home, man
# page, and full test suite live in the teatotal repository.
::tcl::tm::path add \
    [file join [file dirname [file normalize [info script]]] vendor]
package require deadman

# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources.
if {[info exists ::spar::_harness_loaded]} {
    package provide spar-harness 1.0
    return
}

namespace eval spar {
    variable _harness_loaded 1
    # Capture the harness install directory at source time. Used by
    # load_prompt to resolve prompts/<name>.txt relative to this file.
    variable harness_dir [file dirname [file normalize [info script]]]
    # Logger service for harness runtime output. Per-row context
    # (slug, phase) goes in the message body; logger adds the
    # timestamp, service tag, and level.
    variable harness_log [logger::init spar::harness]
}

source [file join $::spar::harness_dir spar-courier.tcl]

oo::class create spar::Harness {
    variable Slug LogPrefix CostLog SessionId PromptDir LogDir \
             WorkerCostCapUsd CostKilled \
             StallKilled StallTimeoutMs UsageResetSecs \
             FailCause

    constructor {prompt_dir log_dir} {
        set PromptDir $prompt_dir
        set LogDir    $log_dir
        set Slug      [file tail $prompt_dir]
        set LogPrefix [file join $log_dir $Slug]
        set CostLog   "${LogPrefix}-cost.jsonl"
        set SessionId ""
        set CostKilled 0
        set StallKilled 0
        set UsageResetSecs 0
        set FailCause ""
        # Per-worker cost cap (#114) is the sole budget circuit-breaker:
        # it bounds a runaway think/retry loop that spends fast. The
        # wall-clock cap was removed — dollars, not time, is the bound. The
        # default sits above the $7.83 heaviest-worker ceiling on record;
        # campaign.yaml tunes it per campaign through meta.env (key
        # WORKER_COST_CAP_USD). Zero disables the watchdog.
        set WorkerCostCapUsd 10.0
        # Per-worker stall watchdog (#115): SIGTERM a worker that has emitted no
        # stdout for STALL_TIMEOUT_SECS, catching a hung Skill that the cost cap
        # would only reach much later (or never, with the cap disabled). The
        # default ships enabled but conservative — long enough that a slow
        # subagent turn or web fetch does not trip it. Zero disables. Stored in
        # ms for direct comparison with clock milliseconds.
        set StallTimeoutMs 600000
        if {[file exists [file join $prompt_dir meta.env]]} {
            set meta [my load_meta]
            set WorkerCostCapUsd [spar::dict_get_default \
                $meta WORKER_COST_CAP_USD $WorkerCostCapUsd]
            set StallTimeoutMs [expr {int([spar::dict_get_default \
                $meta STALL_TIMEOUT_SECS 600] * 1000)}]
        }
        file mkdir $log_dir
        set fd [open $CostLog w]; close $fd
    }

    # Public accessors — subclasses and harness scripts use these.
    method slug        {} { return $Slug }
    method log_prefix  {} { return $LogPrefix }
    method session_id  {} { return $SessionId }
    method prompt_dir  {} { return $PromptDir }
    method log_dir     {} { return $LogDir }
    method cost_cap    {} { return $WorkerCostCapUsd }
    method stall_timeout {} { return [expr {$StallTimeoutMs / 1000}] }
    method fail_cause  {} { return $FailCause }

    # _fail — record a terminal FAIL cause and log it. The recorded cause is
    # read back by the dispatcher worker (only when run returns non-zero) and
    # surfaced in the run-end roll-call. Last write before a non-zero run wins;
    # an intermediate cause on a path that later recovers is never read.
    method _fail {msg} { set FailCause $msg; ${::spar::harness_log}::error $msg }

    # Per-worker cost cap in USD for a single dispatch (parent session
    # plus its research subagents). Zero disables the watchdog.
    method set_worker_cost_cap {usd} {
        set WorkerCostCapUsd $usd
    }

    # Per-worker stall timeout in seconds (#115). Zero disables. Fractional
    # values are accepted so tests can drive a sub-second timeout; the
    # stored ms count is a whole number, as the watchdog requires.
    method set_stall_timeout {secs} {
        set StallTimeoutMs [expr {int($secs * 1000)}]
    }

    # permission_args — the claude permission flags this harness runs under.
    # Approach/author/challenger work unrestricted under skip-permissions.
    # ProfileHarness overrides this to fence research fan-out (#132).
    method permission_args {} {
        return [list --dangerously-skip-permissions]
    }

    # Load prompts/<name>.txt and apply __KEY__ → value substitutions
    # from the subs dict. Keys in subs are passed without the __..__
    # wrapping; this method adds them.
    method load_prompt {name subs} {
        set path [file join $::spar::harness_dir prompts "${name}.txt"]
        set tmpl [spar::read_file $path]
        set map {}
        dict for {k v} $subs {
            lappend map "__${k}__" $v
        }
        return [string map $map $tmpl]
    }

    # Read prompt_dir/meta.env into a dict. Replaces the duplicated
    # scaffolding the two harness scripts used to carry.
    method load_meta {} {
        set meta [dict create]
        set fd [open [file join $PromptDir meta.env] r]
        while {[gets $fd line] >= 0} {
            if {[regexp {^([A-Z_]+)=(.*)$} $line -> key val]} {
                set val [string trim $val "\""]
                dict set meta $key $val
            }
        }
        close $fd
        return $meta
    }

    # call — first or standalone claude call. Returns a terminal code:
    # 0 success, 1 hard failure, 2 external kill / stall / incomplete, 3
    # deliberate budget kill (cost cap). The usage-window block (code 4) is
    # consumed inside _with_recovery and never reaches here. Captures session_id
    # from the stream; subsequent calls on the same harness reuse it via
    # `resume`.
    method call {stage log_file prompt args} {
        set rc [my _with_recovery call $stage $log_file $prompt {*}$args]
        # Capture session_id whenever the stream produced one — including an
        # incomplete or budget-killed run — so an interrupted call can still
        # be resumed and the cost meter can find the transcript.
        if {$SessionId eq ""} {
            set SessionId [my _extract_session_id "${log_file}.json"]
        }
        return $rc
    }

    # resume — resume the captured session with a fix/revision prompt.
    # Fails if call has not yet been made successfully.
    method resume {stage log_file prompt args} {
        if {$SessionId eq ""} {
            error "spar::Harness::resume: no session_id — call must succeed first"
        }
        return [my _with_recovery resume $stage $log_file $prompt --resume $SessionId {*}$args]
    }

    # inject_courier — substitute __COURIER_SECTION__ in the prompt
    # file with the prefetched courier block (accounts header + per-
    # contact correspondence cascade). Runs in the harness so the slow
    # `courier -A search` exec parallelises across contacts instead of
    # serialising in the dispatcher's prepare loop. Empty section when
    # courier isn't installed.
    method inject_courier {prompt_path name org email} {
        set hdr  [spar::courier::accounts_block]
        set body [spar::courier::contact_block $name $org $email]
        set section [expr {$hdr eq "" ? "" : "\n\n${hdr}${body}"}]
        set prompt [spar::read_file $prompt_path]
        set prompt [string map [list __COURIER_SECTION__ $section] $prompt]
        spar::write_file $prompt_path $prompt
        ${::spar::harness_log}::info "\[$Slug\] \[phase: courier\]"
    }

    # cost_total — sum `cost` fields across the JSONL ledger.
    method cost_total {} {
        set total 0.0
        if {![file exists $CostLog]} { return $total }
        set fd [open $CostLog r]
        while {[gets $fd line] >= 0} {
            set line [string trim $line]
            if {$line eq ""} continue
            if {[catch {set d [::json::json2dict $line]}]} continue
            set total [expr {$total + [spar::dict_get_default $d cost 0]}]
        }
        close $fd
        return $total
    }

    # _with_recovery — the recovery layer call/resume route through. _invoke
    # classifies and returns; this method owns the one interruption class
    # _invoke cannot resolve on its own — a usage-window block (code 4), where
    # the subscription limit is reached and resets at a stated time. It waits
    # until the reset and re-invokes, bounded by max_retries; on exhaustion it
    # surfaces the terminal 1 the old in-loop path returned. Because rc==4 is
    # consumed here, no caller ever sees it.
    #
    # After the reset, how to re-issue depends on the entrypoint and the
    # per-stage posture:
    #   - resume-initiated (entry=resume): $args already carries --resume and
    #     the resume's own prompt; replay verbatim to continue the session.
    #   - call-initiated (entry=call), posture resume (the default everywhere):
    #     the interrupted research is worth preserving, so switch to --resume
    #     <captured sid> plus a continuation prompt for the remaining attempts.
    #     session_id is captured from json_file here, before the next _invoke
    #     truncates it.
    #   - call-initiated, posture restart (per-stage override): re-issue fresh
    #     with the original prompt+args, clearing SessionId so the new session
    #     is metered by its own init event, not the dead one.
    method _with_recovery {entry stage log_file prompt args} {
        set max_retries 5
        # A stall kill (#146) is a recoverable interruption, not a verdict on the
        # work: a worker that emitted only thinking tokens then fell silent past
        # the stall timeout produced nothing on disk to validate, and the silence
        # is often a usage-limit window the CLI never surfaced as a resets-string
        # for the rc==4 path to catch. Retry it on a fresh session rather than
        # dropping the contact with no product. Bounded separately from the
        # usage-window retries — the two failure classes are independent — and
        # each retry already spaces itself by one stall_timeout of wall clock.
        set max_stall_retries 2
        set stall_attempt 0
        set json_file "${log_file}.json"
        for {set attempt 1} {1} {incr attempt} {
            set rc [my _invoke $stage $log_file $prompt {*}$args]
            if {$rc == 2 && $StallKilled} {
                if {$stall_attempt >= $max_stall_retries} {
                    my _fail \
                        "FAIL ($stage: stalled after $max_stall_retries fresh-session retries): $Slug"
                    return 2
                }
                incr stall_attempt
                ${::spar::harness_log}::warn \
                    "\[$Slug\] Stalled (retry $stall_attempt/$max_stall_retries) — restarting on a fresh session"
                # A resume-initiated stall replays verbatim on its own session
                # (restarting fresh would discard the work that session holds); a
                # call-initiated one clears the captured session so the retry is
                # metered by a fresh init event, not the hung one.
                if {$entry ne "resume" && [lsearch -exact $args --resume] < 0} {
                    set SessionId ""
                }
                continue
            }
            if {$rc != 4} { return $rc }
            if {$attempt >= $max_retries} {
                my _fail "FAIL ($stage: credit limit after $max_retries retries): $Slug"
                return 1
            }
            ${::spar::harness_log}::warn "\[$Slug\] Credit limit hit (attempt $attempt/$max_retries). Sleeping [expr {$UsageResetSecs / 60}]m until reset..."
            # A usage-window reset can be an hour out; in a jobloop coroutine
            # that wait must not freeze the loop, so resume the coroutine
            # when the timer fires (guarded, so a torn-down coroutine leaves
            # nothing to fire into) rather than parking the whole process on
            # a vwait. Outside a coroutine the vwait fallback keeps a
            # standalone run working.
            if {[info coroutine] ne ""} {
                after [expr {$UsageResetSecs * 1000}] \
                    [list apply {co {
                        if {[llength [info commands $co]]} { $co }
                    }} [info coroutine]]
                yield
            } else {
                after [expr {$UsageResetSecs * 1000}] set ::_wake 1
                vwait ::_wake
            }

            # Already in resume mode — either a resume-initiated call, or a
            # call already converted on an earlier block — so replay verbatim.
            # The lsearch guard is what stops a second --resume being added.
            if {$entry eq "resume" || [lsearch -exact $args --resume] >= 0} {
                continue
            }
            if {[my recovery_posture $stage] eq "resume" \
                    && [set sid [my _extract_session_id $json_file]] ne ""} {
                set SessionId $sid
                set prompt [my continuation_prompt $stage]
                set args [linsert $args 0 --resume $sid]
            } else {
                set SessionId ""
            }
        }
    }

    # recovery_posture — for a usage-window block on an initial `call`, whether
    # to resume-continue the interrupted session (the default everywhere) or
    # restart it fresh. A stage whose interrupted work is not worth preserving
    # may override to "restart". Resume-initiated calls ignore this — they
    # always continue their own session.
    method recovery_posture {stage} { return resume }

    # continuation_prompt — the prompt sent when resuming a `call` after the
    # usage window resets. It must tell the agent to continue from the work
    # already in the session, the opposite of the cost-cap finalise prompt's
    # "stop all research". Generic by default; ProfileHarness points it at the
    # research-specific spar-p-continue prompt.
    method continuation_prompt {stage} {
        return "The previous turn of this task was paused by a subscription usage-limit window, which has now reset. The budget is fine. Do not restart from scratch or repeat work already done. Continue the task from where you left off, using everything already gathered in this session, and finish it."
    }

    # _invoke — run the claude CLI once and classify the outcome; it does not
    # wait or retry. Codes: 0 success, 1 hard failure, 2 external kill / stall /
    # incomplete, 3 cost-cap budget kill, 4 usage-window blocked (the reset
    # seconds ride UsageResetSecs; _with_recovery consumes it). Writes the
    # product on success and appends the cost-log entry.
    method _invoke {stage log_file prompt args} {
        set json_file "${log_file}.json"

        set claude_bin [spar::find_tool claude]
        if {$claude_bin eq ""} {
            my _fail "FAIL ($stage: claude not found — check Settings): $Slug"
            return 1
        }
        # --model rides immediately after -p so the model is the first thing
        # visible in `ps ax` output rather than scrolled off past the flags.
        # Default to sonnet unless the caller supplied --model (fix-loop
        # attempt 3 escalates to opus; challenger passes its own model); pull
        # the caller's pair out of args so it is not repeated. Per-phase model
        # selection from campaign YAML is tracked in #91.
        set model sonnet
        set idx [lsearch -exact $args --model]
        if {$idx >= 0} {
            set model [lindex $args [expr {$idx + 1}]]
            set args [lreplace $args $idx [expr {$idx + 1}]]
        }
        # permission_args goes before the boolean flags, never last: claude's
        # --allowedTools/--disallowedTools are variadic (<tools...>), so a tool
        # list immediately ahead of the prompt eats it and -p is left with no
        # input. Keep a non-variadic flag between them.
        set cmd [concat \
            [list $claude_bin -p --model $model] [my permission_args] \
            [list --output-format stream-json --verbose] $args [list $prompt]]

        # Verdict rule this harness commits to: the deliverable on disk
        # is the source of truth, not the claude envelope. stream-json
        # writes one JSONL event per line as work happens, so
        # _stream_result recovers the final result object when the turn
        # closes, and _extract_session_id recovers session_id from the
        # first (init) event even when it does not. Record real elapsed
        # and the true exit code so a kill is reported honestly.
        set t0 [clock seconds]
        set CostKilled 0
        set StallKilled 0
        # deadman owns the pipe, the stall clock, and the group kill; the
        # budget check rides its poll tick (budget_poll below), and a cost
        # kill beats a stall on a shared tick because the poll callback
        # runs before the stall check.
        set dm [list -out $json_file -err "${log_file}.stderr" \
            -stall $StallTimeoutMs]
        if {$WorkerCostCapUsd > 0} {
            lappend dm -poll \
                [list [my _cost_poll_ms] [list [self] budget_poll $json_file]]
        }
        # In a jobloop coroutine (the pool path) deadman completes into the
        # coroutine: hand it [info coroutine] as -done and yield, so the
        # minutes-long claude run drives the loop instead of freezing it,
        # and the result dict arrives as the yield's value. Called outside a
        # coroutine (a standalone or a test harness run) deadman's own vwait
        # blocks until the child is reaped.
        if {[info coroutine] ne ""} {
            deadman::run $cmd {*}$dm -done [info coroutine]
            set r [yield]
        } else {
            set r [deadman::run $cmd {*}$dm]
        }
        set exit_code [dict get $r exit]
        switch -- [dict get $r cause] {
            cost  { set CostKilled 1 }
            stall { set StallKilled 1 }
        }
        set elapsed [expr {[clock seconds] - $t0}]

        set parsed [my _stream_result $json_file]

        # A deliberate budget kill is a circuit-breaker on RESEARCH:
        # resuming the research re-spends the very budget the cap exists
        # to bound (#139). The cost watchdog SIGTERM (CostKilled) is that
        # kill — it fails the row with return 3 to mark the cap tripped.
        # ProfileHarness::run reads return 3 as a signal to resume once
        # for a research-free FINALISE under a small extra cap (recovering
        # the spend without re-opening research); the approach path treats
        # it as a terminal fail. An external kill or a truncated-but-
        # incomplete stream is a different animal — the turn may have done
        # real work the disk product still holds — so that path keeps
        # return 2, the validate-the-product / resume route (FM-HARNESS-2).
        if {[llength $parsed] == 0} {
            if {$CostKilled} {
                my _fail \
                    "FAIL ($stage: cost cap \$$WorkerCostCapUsd reached — budget kill): $Slug"
                return 3
            }
            # A stall kill (#115) is the same animal as an external kill for
            # recovery — the disk product may hold real work — so it shares
            # return 2 (validate-the-product). Check it AFTER CostKilled so a
            # cost kill is never downgraded to a resumable stall; the cause
            # string distinguishes the two in the log (#133).
            if {$StallKilled} {
                my _fail \
                    "FAIL ($stage: stalled — no output for >= [my stall_timeout]s; [my _failure_cause $log_file $json_file $exit_code]): $Slug"
                return 2
            }
            my _fail \
                "FAIL ($stage: ended without result after ${elapsed}s; [my _failure_cause $log_file $json_file $exit_code]): $Slug"
            return 2
        }
        # A complete envelope landed despite a budget kill (the work
        # finished just before SIGTERM): the product verdict stands, so
        # fall through to the success path below — a genuinely complete
        # profile validates to DONE without resuming.

        if {[dict exists $parsed is_error] && [dict get $parsed is_error] eq "true"} {
            set result_text [spar::dict_get_default $parsed result ""]
            if {[string match -nocase *hit*your*limit*resets* $result_text]} {
                # Usage-window block. Classify and return 4; _with_recovery
                # owns the wait and the retry. The reset seconds ride
                # UsageResetSecs. (The string match and reset-time scrape are
                # the only prose-dependent code in the harness — kept here in
                # one place so there is a single home to harden if a future
                # CLI exposes a structured usage-limit signal.)
                set UsageResetSecs [my _credit_wait_secs $result_text]
                return 4
            }
        }

        if {![dict exists $parsed result]} {
            my _fail "FAIL ($stage: no result in output; [my _failure_cause $log_file $json_file $exit_code]): $Slug"
            return 1
        }

        set fd [open $log_file w]
        try {
            puts -nonewline $fd [dict get $parsed result]
        } finally {
            close $fd
        }

        set _prev_indent [::json::write indented]
        ::json::write indented false
        set cost_entry [::json::write object \
            stage [::json::write string $stage] \
            cost [spar::dict_get_default $parsed total_cost_usd 0]]
        ::json::write indented $_prev_indent
        set fd [open $CostLog a]
        try {
            puts $fd $cost_entry
        } finally {
            close $fd
        }

        return 0
    }

    # budget_poll — the cost breach detector, dispatched from deadman's
    # poll tick. Prices this worker (parent session plus its research
    # subagents) and, once the spend crosses WorkerCostCapUsd, kills the
    # run with cause `cost` so _invoke fails the row fast (#114).
    # session_id comes from the growing json_file (the init event lands
    # within the first second), so the poll meters the right session even
    # though `call` captures SessionId only after _invoke returns. Carries
    # no leading underscore: TclOO leaves underscored methods unexported,
    # and this one is dispatched from outside the object.
    method budget_poll {json_file h} {
        if {$WorkerCostCapUsd <= 0} { return }
        set sid $SessionId
        if {$sid eq ""} { set sid [my _extract_session_id $json_file] }
        if {$sid eq ""} { return }
        set cost [spar::worker_cost_usd $sid]
        if {$cost >= $WorkerCostCapUsd} {
            ${::spar::harness_log}::warn \
                "\[$Slug\] Cost cap: \$[format %.2f $cost] >= \$$WorkerCostCapUsd — SIGTERM worker group"
            deadman::kill $h cost
        }
    }

    # The watchdog poll interval in ms. A method so tests can shorten it
    # without touching the production cadence (30s: long enough that the
    # cost read stays a negligible fraction of wall time, short enough to
    # catch a runaway within one $-cap's worth of overspend).
    method _cost_poll_ms {} { return 30000 }

    # _stream_result — the final result object from a stream-json
    # transcript, or {} when no complete result line was written (the turn
    # was killed or truncated). Tolerates a half-written trailing line.
    method _stream_result {json_file} {
        if {![file exists $json_file]} { return {} }
        set result {}
        set fd [open $json_file r]
        try {
            while {[gets $fd line] >= 0} {
                set line [string trim $line]
                if {$line eq ""} continue
                if {[catch {set obj [::json::json2dict $line]}]} continue
                if {[dict exists $obj type] && [dict get $obj type] eq "result"} {
                    set result $obj
                }
            }
        } finally {
            close $fd
        }
        return $result
    }

    # _extract_session_id — session_id from the first stream-json event that
    # carries it (the init event), so it survives a kill that prevented the
    # final result object from being written.
    method _extract_session_id {json_file} {
        if {![file exists $json_file]} { return "" }
        set sid ""
        set fd [open $json_file r]
        try {
            while {[gets $fd line] >= 0} {
                set line [string trim $line]
                if {$line eq ""} continue
                if {[catch {set obj [::json::json2dict $line]}]} continue
                if {[dict exists $obj session_id]} {
                    set sid [dict get $obj session_id]
                    break
                }
            }
        } finally {
            close $fd
        }
        return $sid
    }

    # _failure_cause — assemble a one-line cause string for a FAIL log when the
    # turn produced no usable result (#133). A claude exit with empty stdout
    # used to leave the operator with "rc=error" and nothing else; surface the
    # child exit code (already in hand), the tail of the stderr file, and the
    # last stream event that did land, so an empty-artefact failure becomes
    # diagnosable instead of undetermined.
    method _failure_cause {log_file json_file exit_code} {
        set parts [list "exit $exit_code"]
        set stderr_file "${log_file}.stderr"
        if {[file exists $stderr_file] && [file size $stderr_file] > 0} {
            set fd [open $stderr_file r]
            try {
                set lines [split [read $fd] \n]
            } finally {
                close $fd
            }
            set kept {}
            foreach line $lines {
                set line [string trim $line]
                if {$line ne ""} { lappend kept $line }
            }
            if {[llength $kept] > 0} {
                set n [llength $kept]
                set start [expr {$n > 5 ? $n - 5 : 0}]
                lappend parts "stderr: [join [lrange $kept $start end] { | }]"
            }
        }
        if {[file exists $json_file]} {
            set fd [open $json_file r]
            set last ""
            try {
                while {[gets $fd line] >= 0} {
                    set line [string trim $line]
                    if {$line eq ""} continue
                    if {[catch {set obj [::json::json2dict $line]}]} continue
                    set last $obj
                }
            } finally {
                close $fd
            }
            if {$last ne ""} {
                set ev [spar::dict_get_default $last type "?"]
                set sub [spar::dict_get_default $last subtype ""]
                if {$sub ne ""} { append ev "/$sub" }
                lappend parts "last event: $ev"
            }
        }
        return [join $parts {, }]
    }

    # Parse "resets 3am (Australia/Brisbane)" → seconds to sleep.
    method _credit_wait_secs {msg} {
        if {![regexp {resets (\d{1,2}(?::\d{2})?\s*[ap]m)} $msg -> reset_time]} {
            return 3600
        }
        set tz "Australia/Brisbane"
        if {[regexp {\(([^)]+)\)} $msg -> found_tz]} {
            set tz $found_tz
        }
        set now_epoch [clock seconds]
        if {[catch {
            set reset_epoch [clock scan "today $reset_time" -timezone :$tz]
        }]} {
            return 3600
        }
        if {$reset_epoch <= $now_epoch} {
            if {[catch {
                set reset_epoch [clock scan "tomorrow $reset_time" -timezone :$tz]
            }]} {
                return 3600
            }
        }
        set wait [expr {$reset_epoch - $now_epoch + 120}]
        if {$wait < 60} { set wait 60 }
        return $wait
    }

    # ── DbC-Post fix loop ─────────────────────────────────────────────
    #
    # Both ApproachHarness and ProfileHarness wrap a max_fix=3 retry
    # around a phase-specific validator. Validate, accept on no-error,
    # otherwise log + resume with a fix prompt + retry. Attempt 3
    # escalates to opus. After max_fix rounds, run a final validation
    # and report failure if errors remain.
    #
    # Subclass contract:
    #   $validator_method      — `my <name> $attempt` returns a list of
    #                            error dicts (severity, code, message).
    #   $prompt_builder_method — `my <name> $attempt $hard $error_text`
    #                            returns the fix prompt string.
    # Optional overrides: after_resume, report_fix_failure.
    method run_fix_loop {validator_method prompt_builder_method} {
        set max_fix 3
        for {set attempt 1} {$attempt <= $max_fix} {incr attempt} {
            set errors [my $validator_method $attempt]
            set hard [my hard_errors_from $errors]
            if {[llength $hard] == 0} {
                if {$attempt > 1} {
                    ${::spar::harness_log}::info "\[$Slug\] Validation passed after $attempt attempt(s)."
                }
                return 0
            }
            set error_text [my format_errors $hard]
            ${::spar::harness_log}::warn "\[$Slug\] Validation failed (attempt $attempt/$max_fix):\n$error_text"
            set fix_log "${LogPrefix}-fix${attempt}.log"
            set fix_prompt [my $prompt_builder_method $attempt $hard $error_text]
            set model_args {}
            if {$attempt == 3} { set model_args [list --model opus] }
            if {[my resume "fix${attempt}" $fix_log $fix_prompt {*}$model_args]} {
                return 1
            }
            my after_resume
        }
        # Final pass after exhausting retries.
        set errors [my $validator_method final]
        set hard [my hard_errors_from $errors]
        if {[llength $hard] > 0} {
            my report_fix_failure $hard $max_fix
            return 1
        }
        return 0
    }

    # Filter to error-severity entries only.
    method hard_errors_from {errors} {
        set hard {}
        foreach e $errors {
            if {[dict get $e severity] eq "error"} { lappend hard $e }
        }
        return $hard
    }

    # Format a hard-error list as bullet lines for fix prompts.
    method format_errors {hard} {
        set lines {}
        foreach e $hard {
            lappend lines "- \[[dict get $e code]\] [dict get $e message]"
        }
        return [join $lines \n]
    }

    # Hook fired after a successful resume (agent rewrote the output
    # file). Default no-op; ApproachHarness overrides to drop a State
    # cache so the next iteration sees fresh bytes.
    method after_resume {} {}

    # Default failure message when the loop exits with errors remaining.
    # ProfileHarness overrides to include the first error message.
    method report_fix_failure {hard max_fix} {
        my _fail "FAIL (validation failed after $max_fix retries): $Slug"
    }
}

# Lightweight file helpers — used across harness scripts.
proc spar::read_file {path} {
    set fd [open $path r]
    set content [read $fd]
    close $fd
    return $content
}

proc spar::write_file {path content} {
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
}

# ── ApproachHarness class ─────────────────────────────────────────────

oo::class create spar::ApproachHarness {
    superclass spar::Harness
    variable State Outfile RosterEmail ContactName RosterOrg \
             MaxPasses ContactSummary ChallengerModel ContactNameMeta \
             Pass Verdict ProfilePath

    constructor {prompt_dir log_dir} {
        next $prompt_dir $log_dir
        # The harness rewrites the approach file across fix attempts —
        # back-to-back rewrites can land within mtime granularity (1s)
        # and may keep the line-1 profile_hash unchanged, so neither
        # invalidator on approach_summary's cache fires reliably. Hold
        # a State for shared validation paths and use forget_approach
        # explicitly after each agent write that touched the outfile.
        set State [spar::State new]
    }
    destructor {
        if {[info exists State] && $State ne ""} {
            $State destroy
            set State ""
        }
    }
    method state {} { return $State }

    # DbC-Post loop for approach files. Per-call args are stashed as
    # instance vars so the validator and prompt-builder methods see
    # them; the retry skeleton lives in spar::Harness::run_fix_loop.
    method validate_and_correct {outfile roster_email contact_name {roster_organisation ""}} {
        set Outfile     $outfile
        set RosterEmail $roster_email
        set ContactName $contact_name
        set RosterOrg   $roster_organisation
        return [my run_fix_loop validate_approach_errors build_approach_fix_prompt]
    }

    # Path-form validate_approach parses fresh — appropriate because every
    # attempt follows an agent write to $Outfile.
    method validate_approach_errors {attempt} {
        return [spar::validate_approach $Outfile $RosterEmail $ContactName $RosterOrg]
    }

    method build_approach_fix_prompt {attempt hard error_text} {
        return [my load_prompt spar-a-fix [dict create \
            ERROR_TEXT   $error_text \
            OUTFILE      $Outfile \
            ROSTER_EMAIL $RosterEmail]]
    }

    # Drop the State's approach cache after each agent rewrite so the
    # next validate_approach + the post-loop prepend_profile_hash call
    # both see fresh bytes.
    method after_resume {} {
        $State forget_approach $Outfile
    }

    # Run the full A-phase pipeline. Returns 0 on success, 1 on failure.
    # The try/on-error wrapper turns an uncaught exception into a logged
    # FAIL line — without it, an exception in load_my_meta or any phase
    # method would propagate up to harness_run as "harness exited rc=…"
    # with no per-row context in the operator's log.
    method run {} {
        try {
            my load_my_meta
            my do_inject_courier
            if {[my do_author_draft]}             { return 1 }
            if {[my run_spar_loop]}               { return 1 }
            if {[my do_assembly]}                 { return 1 }
            if {[my do_post_assembly_validation]} { return 1 }
            my do_summary
            return 0
        } on error {err opts} {
            my _fail \
                "FAIL ([my slug]): uncaught error in ApproachHarness::run — $err"
            return 1
        }
    }

    # Unpack meta.env into instance vars used by phase methods.
    # ProfilePath mirrors approach_path_for_stem / profile_path_for_stem:
    # outfile is <segment_dir>/approach/<stem>.yaml; profile is at
    # <segment_dir>/profiles/<stem>.md.
    method load_my_meta {} {
        set meta [my load_meta]
        set MaxPasses        [dict get $meta MAX_PASSES]
        set Outfile          [dict get $meta OUTFILE]
        set ContactSummary   [dict get $meta CONTACT_SUMMARY]
        set ChallengerModel  [spar::dict_get_default $meta CHALLENGER_MODEL sonnet]
        set RosterEmail      [spar::dict_get_default $meta ROSTER_EMAIL ""]
        set RosterOrg        [spar::dict_get_default $meta ROSTER_ORGANISATION ""]
        set ContactNameMeta  [spar::dict_get_default $meta CONTACT_NAME ""]
        set ContactName      [string trim [lindex [split $ContactSummary |] 0]]
        set seg_dir [file dirname [file dirname $Outfile]]
        set stem    [file rootname [file tail $Outfile]]
        set ProfilePath [file join $seg_dir profiles "${stem}.md"]
    }

    method do_inject_courier {} {
        my inject_courier \
            [file join [my prompt_dir] author-draft.txt] \
            $ContactNameMeta $RosterOrg $RosterEmail
    }

    method do_author_draft {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: drafting\]"
        ${::spar::harness_log}::info "\[$slug\] Author: drafting..."
        set author_draft_log "${log_prefix}-author-draft.log"
        set author_prompt [spar::read_file [file join $prompt_dir author-draft.txt]]

        if {[my call "author-draft" $author_draft_log $author_prompt]} {
            return 1
        }

        set draft_text [spar::transcript_assistant_text "${author_draft_log}.json"]
        set draft [spar::extract_between $draft_text "DRAFT_START" "DRAFT_END"]
        if {$draft eq ""} {
            my _fail "FAIL (no draft markers): $slug"
            return 1
        }
        set rationale [spar::extract_between $draft_text "RATIONALE_START" "RATIONALE_END"]
        spar::write_file [file join $prompt_dir draft-current.txt] $draft
        spar::write_file [file join $prompt_dir rationale.txt] $rationale
        return 0
    }

    # The challenger runs fresh each pass (context-isolated) — call,
    # not resume. The author is the persistent harness; its session_id
    # is what the rev step resumes.
    method run_spar_loop {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        set Pass 0
        set Verdict "REVISE"

        while {$Pass < $MaxPasses && $Verdict eq "REVISE"} {
            incr Pass
            ${::spar::harness_log}::info "\[$slug\] \[phase: challenger $Pass/$MaxPasses\]"
            ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass/$MaxPasses..."

            set challenger_template [spar::read_file [file join $prompt_dir challenger-template.txt]]
            set current_draft [spar::read_file [file join $prompt_dir draft-current.txt]]
            set challenger_prompt [string map [list __DRAFT_PLACEHOLDER__ $current_draft] $challenger_template]

            set challenger_log "${log_prefix}-challenger-pass${Pass}.log"
            if {[my call "challenger-pass${Pass}" $challenger_log $challenger_prompt --model $ChallengerModel]} {
                return 1
            }

            file copy -force $challenger_log [file join $prompt_dir "challenger-pass${Pass}.txt"]

            set challenger_text [spar::read_file $challenger_log]
            set Verdict ""
            foreach line [split $challenger_text \n] {
                if {[string match "VERDICT:*" $line]} {
                    set Verdict [string trim [string range $line 8 end]]
                }
            }
            if {$Verdict eq ""} { set Verdict "REVISE" }

            if {$Verdict eq "DONE"} {
                ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass: DONE"
                break
            }

            ${::spar::harness_log}::info "\[$slug\] \[phase: revising $Pass\]"
            ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass: REVISE — author revising..."

            set author_rev_log "${log_prefix}-author-rev${Pass}.log"
            set challenger_feedback [spar::read_file [file join $prompt_dir "challenger-pass${Pass}.txt"]]

            set rev_prompt [my load_prompt spar-a-revise [dict create \
                PASS                $Pass \
                CHALLENGER_FEEDBACK $challenger_feedback]]

            spar::write_file [file join $prompt_dir "author-rev${Pass}.txt"] $rev_prompt

            if {[my resume "author-rev${Pass}" $author_rev_log $rev_prompt]} {
                return 1
            }

            set rev_text [spar::transcript_assistant_text "${author_rev_log}.json"]
            set revised_draft [spar::extract_between $rev_text "DRAFT_START" "DRAFT_END"]
            if {$revised_draft ne ""} {
                spar::write_file [file join $prompt_dir draft-current.txt] $revised_draft
            }
            set revised_rationale [spar::extract_between $rev_text "RATIONALE_START" "RATIONALE_END"]
            if {$revised_rationale ne ""} {
                spar::write_file [file join $prompt_dir rationale.txt] $revised_rationale
            }
        }
        return 0
    }

    method do_assembly {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: assembling\]"
        ${::spar::harness_log}::info "\[$slug\] Author: assembling..."

        set all_challenger ""
        for {set r 1} {$r <= $Pass} {incr r} {
            set cfile [file join $prompt_dir "challenger-pass${r}.txt"]
            if {[file exists $cfile]} {
                append all_challenger "\n### A2 Response $r\n\n[spar::read_file $cfile]\n"
            }
        }
        set all_revisions ""
        for {set r 1} {$r <= $Pass} {incr r} {
            set rev_log "${log_prefix}-author-rev${r}.log"
            if {[file exists $rev_log]} {
                set rev_draft [spar::extract_between [spar::transcript_assistant_text "${rev_log}.json"] "DRAFT_START" "DRAFT_END"]
                if {$rev_draft ne ""} {
                    append all_revisions "\n### A1 Draft [expr {$r + 1}]\n\n$rev_draft\n"
                }
            }
        }

        set initial_draft [spar::extract_between [spar::transcript_assistant_text "${log_prefix}-author-draft.log.json"] "DRAFT_START" "DRAFT_END"]
        set final_draft [spar::read_file [file join $prompt_dir draft-current.txt]]

        set assembly_prompt [my load_prompt spar-a-assembly [dict create \
            CONTACT_SUMMARY  $ContactSummary \
            INITIAL_DRAFT    $initial_draft \
            CHALLENGER_MODEL $ChallengerModel \
            ALL_CHALLENGER   $all_challenger \
            ALL_REVISIONS    $all_revisions \
            FINAL_DRAFT      $final_draft \
            OUTFILE          $Outfile]]

        set appendix_path [file join $prompt_dir appendix-assembly.txt]
        if {[file exists $appendix_path]} {
            set appendix_text [spar::read_file $appendix_path]
            if {[string trim $appendix_text] ne ""} {
                append assembly_prompt "\n\n$appendix_text"
            }
        }

        set assembly_log "${log_prefix}-author-assembly.log"
        spar::write_file [file join $prompt_dir assembly.txt] $assembly_prompt

        # DbC-Pre: pre-conditions for assembly are that the upstream
        # draft / spar / revision logs all exist and are non-empty.
        # Assert rather than trust.
        set required_logs [list "${log_prefix}-author-draft.log"]
        for {set r 1} {$r <= $Pass} {incr r} {
            lappend required_logs "${log_prefix}-challenger-pass${r}.log"
        }
        set rev_passes [expr {$Verdict eq "DONE" ? $Pass - 1 : $Pass}]
        for {set r 1} {$r <= $rev_passes} {incr r} {
            lappend required_logs "${log_prefix}-author-rev${r}.log"
        }
        foreach lg $required_logs {
            if {![file exists $lg]} {
                my _fail "FAIL (DbC-Pre: assembly precondition log missing: $lg): $slug"
                return 1
            }
            if {[file size $lg] == 0} {
                my _fail "FAIL (DbC-Pre: assembly precondition log empty: $lg): $slug"
                return 1
            }
        }
        if {[my resume "assembly" $assembly_log $assembly_prompt]} {
            return 1
        }
        return 0
    }

    # DbC-Post pair for the assembly call. validate_and_correct runs
    # spar::validate_approach on the file the agent just wrote; on
    # error it resumes the agent with the specific failure (the "blame
    # the renter" half of the contract). When Outfile is missing
    # (assembly silently produced nothing), fall through — do_summary
    # will warn.
    method do_post_assembly_validation {} {
        if {![file exists $Outfile]} { return 0 }
        if {[my validate_and_correct $Outfile $RosterEmail $ContactName $RosterOrg]} {
            return 1
        }
        # profile_hash linkage (#63): prepend AFTER validation passes.
        # Doing it here (not via the prompt) keeps the agent's attention
        # budget on the message and guarantees the position discipline
        # (line 1) without trusting the agent to follow it.
        if {[file exists $ProfilePath]} {
            spar::prepend_profile_hash $Outfile $ProfilePath
        }
        return 0
    }

    method do_summary {} {
        set slug       [my slug]
        set total_cost [my cost_total]

        if {![file exists $Outfile]} {
            ${::spar::harness_log}::warn "WARN: $slug completed but $Outfile not found (cost=\$$total_cost)"
            return
        }
        ${::spar::harness_log}::info "DONE: $slug ($Pass pass(es), verdict=$Verdict, cost=\$$total_cost)"

        # response_likelihood is written into the approach YAML by the
        # assembly agent (a root key, per spar-A-approach.md §6); it is
        # campaign-bound and does not go to the segment's shared roster.
        # No roster write-back here.
    }
}

# ── ProfileHarness class ──────────────────────────────────────────────

oo::class create spar::ProfileHarness {
    superclass spar::Harness

    variable State Outfile RosterPath RosterLock RequiredSkills \
             Stem ContactName ContactOrg ContactEmail

    # Profile workers run under an explicit allow-list instead of
    # skip-permissions, so a research delegation can only reach the
    # read-only Explore subagent (which cannot cascade); a full-tool/null
    # Agent spawn fails to match Agent(Explore) and the deep-research swarm
    # is denied. This closes the 270-subagent runaway (#132). dontAsk makes
    # the allow-list non-interactive: a tool outside it is denied, not
    # prompted, so an unattended run never stalls.
    method permission_args {} {
        return [list \
            --permission-mode dontAsk \
            --allowedTools "WebSearch,WebFetch,Read,Write,Edit,Glob,Grep,ToolSearch,TodoWrite,Skill,Bash,Agent(Explore),SendMessage" \
            --disallowedTools "Agent(general-purpose),Agent(claude),Agent(general),Workflow,Skill(deep-research),Skill(ot:build-dossier)"]
    }

    # Override the generic continuation prompt with the research-specific one:
    # a profile interrupted mid-research should resume its research, not stop
    # (the inverse of do_finalise_after_cost_kill, which stops it). load_my_meta
    # runs before do_profile_call, so Stem/Outfile are set by the time a
    # usage-window block can fire.
    method continuation_prompt {stage} {
        return [my load_prompt spar-p-continue [dict create \
            STEM $Stem OUTFILE $Outfile]]
    }

    method state {} {
        if {![info exists State] || $State eq ""} {
            set State [spar::State new]
        }
        return $State
    }

    destructor {
        if {[info exists State] && $State ne "" && [info commands $State] ne ""} {
            $State destroy
        }
    }

    # Load the current roster row for this slug. Used by both validation
    # and the masked-email sanitiser.
    method _roster_row {roster_path slug} {
        if {![file exists $roster_path]} { return [dict create] }
        foreach r [spar::load_roster $roster_path] {
            if {[spar::dict_get_default $r stem ""] eq $slug} { return $r }
        }
        return [dict create]
    }

    # DbC-Post: if the agent wrote a masked email (e.g. "b***@foo.com") to
    # the roster, blank the field. A masked address is worse than empty —
    # it inflates "has email" counts and propagates into approach files.
    # The harness runs as a coroutine on the one thread the pool and the
    # front-end share, so the roster write is already serialised against
    # every other job; blank the field by calling spar::update_roster_field
    # directly rather than marshalling a report across threads.
    method sanitise_roster_email {roster_path slug} {
        if {![file exists $roster_path]} { return }
        foreach row [spar::load_roster $roster_path] {
            if {[spar::dict_get_default $row stem ""] ne $slug} continue
            set email [string trim [spar::dict_get_default $row email ""]]
            if {[spar::is_masked_email $email]} {
                ${::spar::harness_log}::warn "\[[my slug]\] Guardrail: blanked masked email '$email' in roster"
                if {[catch {
                    spar::update_roster_field $roster_path \
                        stem $slug email ""
                } err]} {
                    ${::spar::harness_log}::warn \
                        "\[[my slug]\] roster blank failed for stem=$slug: $err"
                }
            }
        }
    }

    # DbC-Post loop for profile files. Per-call args stashed as instance
    # vars; retry skeleton lives in spar::Harness::run_fix_loop. The
    # required_skills list (derived from segment.yaml's profile_reject_if)
    # opts into the §4.3/§4.4 mandatory-skill audit per skill named.
    method validate_and_correct {outfile roster_path required_skills} {
        set Outfile        $outfile
        set RosterPath     $roster_path
        set RequiredSkills $required_skills
        return [my run_fix_loop validate_profile_errors build_profile_fix_prompt]
    }

    method validate_profile_errors {attempt} {
        set slug [my slug]
        set row  [my _roster_row $RosterPath $slug]
        # A missing file is normally the missing-profile fault (feeds the
        # missing-profile branch in build_profile_fix_prompt; the next
        # iteration re-validates the rewritten file). The exception is an
        # excluded row: §5.4 requires an excluded contact to have NO
        # profile document, so an absent file next to a date_excluded row
        # is the correct terminal state, not a fault. Mirrors the
        # profile_unreachable_without_exclusion check, which likewise
        # tolerates an absent channel once date_excluded is set.
        if {![file exists $Outfile]} {
            if {[spar::_roster_field_current $row date_excluded] ne ""} {
                return {}
            }
            return [list [dict create severity error code missing_profile \
                          message "The profile file was not written to $Outfile"]]
        }
        set errors [spar::validate_profile $Outfile $row $slug]
        # Segment-scoped roster checks reach this harness via
        # contact_name match — within-segment duplicates and
        # shared-inbox collisions surface here for resume.
        set my_cname [string trim [spar::dict_get_default $row contact_name ""]]
        set segment_dir [file dirname $RosterPath]
        if {$my_cname ne ""} {
            if {[catch {[my state] classify_segment $segment_dir} seg_contacts]} {
                set seg_contacts {}
            }
            foreach ri [spar::validate_roster $seg_contacts] {
                if {[dict get $ri severity] ne "error"} continue
                if {[dict get $ri contact_name] ne $my_cname} continue
                lappend errors $ri
            }
        }
        # Issue #76: transcript-based audit. Skipped when the segment lists
        # no required skills (profile_reject_if absent or empty), the row
        # is excluded, or session_id was never captured.
        if {[llength $RequiredSkills] > 0 \
                && [string trim [spar::dict_get_default $row date_excluded ""]] eq "" \
                && [my session_id] ne ""} {
            foreach ai [spar::audit_skills_in_transcript \
                            [my session_id] $RequiredSkills $my_cname] {
                lappend errors $ai
            }
        }
        return $errors
    }

    method build_profile_fix_prompt {attempt hard error_text} {
        if {[llength $hard] == 1 && [dict get [lindex $hard 0] code] eq "missing_profile"} {
            return [my load_prompt spar-p-fix-missing [dict create OUTFILE $Outfile]]
        }
        return [my load_prompt spar-p-fix-validation [dict create \
            AUDIT_PREAMBLE [my build_audit_preamble $hard] \
            SLUG           [my slug] \
            ERROR_TEXT     $error_text \
            OUTFILE        $Outfile]]
    }

    # When the §4.3/§4.4 audit fires, prepend a high-priority instruction
    # so the agent does not bury the skill invocation under the rest of
    # the error bag.
    method build_audit_preamble {hard} {
        set audit_present {}
        foreach e $hard {
            set c [dict get $e code]
            if {$c eq "linkedin_lookup_missing" || $c eq "facebook_lookup_missing"} {
                lappend audit_present $c
            }
        }
        if {[llength $audit_present] == 0} { return "" }
        set parts {}
        foreach c $audit_present {
            if {$c eq "linkedin_lookup_missing"} {
                lappend parts "invoke the linkedin skill (Skill tool with skill=linkedin) to fetch and parse the LinkedIn profile per SPAR-P §4.3"
            } else {
                lappend parts "invoke the facebook skill (Skill tool with skill=facebook) to fetch and parse the Facebook profile per SPAR-P §4.4"
            }
        }
        return "FIRST: [join $parts { AND }]. Then re-derive any front-matter fields whose values depend on that data (star_rating, yield).\n\n"
    }

    # Override: include the first error message in the failure line.
    method report_fix_failure {hard max_fix} {
        set msg [dict get [lindex $hard 0] message]
        my _fail "FAIL (validation failed after $max_fix retries): [my slug] — $msg"
    }

    # Run the full P-phase pipeline. Returns 0 on success, 1 on failure.
    # The try/on-error wrapper logs uncaught exceptions as a FAIL line
    # so the operator sees a per-row outcome instead of a generic
    # "harness exited rc=…" from harness_run.
    method run {} {
        try {
            my load_my_meta
            my do_inject_courier
            # do_profile_call returns one of four codes:
            #   0 — turn closed cleanly
            #   1 — hard failure (no usable product)
            #   2 — turn cut short by an EXTERNAL kill / truncation; the
            #       disk product may still hold real work, so fall through
            #       to validate it (FM-HARNESS-2): a complete profile lands
            #       DONE, a partial one surfaces missing_profile and the fix
            #       loop resumes the captured session.
            #   3 — DELIBERATE budget kill (cost cap). The watchdog SIGTERM
            #       lands after the costly research and the profile body are
            #       written but typically before the cheap finalisation the
            #       prompt orders last (the roster star_rating write and the
            #       YAML front matter). Resuming the *research* would re-spend
            #       the budget the cap bounds (#139); resuming only to
            #       FINALISE does no research, so it is cheap and recovers the
            #       near-total spend instead of discarding it. do_finalise_-
            #       after_cost_kill does that single bounded resume, then the
            #       product is validated below like any other run.
            set pc [my do_profile_call]
            if {$pc == 1} { return 1 }
            if {$pc == 3} { my do_finalise_after_cost_kill }
            # DbC-Post: sanitise masked emails written to the roster, then
            # run validate_profile on both the front matter and roster-row
            # invariants (#39 R1: profile_unreachable_without_exclusion —
            # profile exists iff the row has a reachable channel or
            # date_excluded is set).
            my sanitise_roster_email $RosterPath [my slug]
            if {[my validate_and_correct $Outfile $RosterPath $RequiredSkills]} { return 1 }
            my do_summary
            return 0
        } on error {err opts} {
            my _fail \
                "FAIL ([my slug]): uncaught error in ProfileHarness::run — $err"
            return 1
        }
    }

    method load_my_meta {} {
        set meta [my load_meta]
        set Outfile      [dict get $meta OUTFILE]
        set RosterPath   [dict get $meta ROSTER_PATH]
        set Stem         [dict get $meta STEM]
        # The dispatcher is the canonical home of the per-segment lock path
        # (.roster.lock beside the roster); it writes ROSTER_LOCK into
        # meta.env. Fall back to the same derivation only for a prompt dir
        # written before that key existed, so a standalone resume still
        # serialises on the right lock.
        set RosterLock   [spar::dict_get_default $meta ROSTER_LOCK \
                              [file join [file dirname $RosterPath] .roster.lock]]
        set RequiredSkills [spar::dict_get_default $meta REQUIRED_SKILLS ""]
        set ContactName  [spar::dict_get_default $meta CONTACT_NAME ""]
        set ContactOrg   [spar::dict_get_default $meta CONTACT_ORG ""]
        set ContactEmail [spar::dict_get_default $meta CONTACT_EMAIL ""]
    }

    method do_inject_courier {} {
        my inject_courier \
            [file join [my prompt_dir] prompt.txt] \
            $ContactName $ContactOrg $ContactEmail
    }

    # DbC-Pre: roster integrity for this segment was validated at
    # spar::p::_run_segment entry (load_roster enforces field-count
    # assertion; required input files existence-checked there). The
    # agent inherits a roster known to be well-formed.
    method do_profile_call {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: researching\]"
        ${::spar::harness_log}::info "\[$slug\] Profile: researching..."
        set draft_log "${log_prefix}-profile.log"
        set prompt [spar::read_file [file join $prompt_dir prompt.txt]]
        return [my call "profile" $draft_log $prompt]
    }

    # do_finalise_after_cost_kill — recover a cost-cap-killed profile worker.
    # The watchdog SIGTERM lands after the costly research and the profile
    # body are written but before the cheap finalisation (the roster
    # star_rating sqlite write and the YAML front matter, which the prompt
    # orders last), so discarding the worker loses near-all the spend and
    # leaves a body-only profile with no front matter that the validator
    # rejects. Resume the captured session once with a self-contained
    # finalise prompt that does no research, so it cannot re-spend the
    # research budget. The post-profile validate_and_correct in run() is the
    # verdict: a now-complete profile lands DONE, a still-partial one resumes
    # to be fixed.
    method do_finalise_after_cost_kill {} {
        set slug [my slug]
        if {[my session_id] eq ""} {
            # The init event never landed, so there is no session to resume.
            # Fall through to validation, which surfaces the partial profile.
            ${::spar::harness_log}::warn \
                "\[$slug\] Cost cap fired before a session_id was captured — cannot resume to finalise"
            return
        }
        ${::spar::harness_log}::info "\[$slug\] \[phase: finalising (post cost-cap)\]"
        # Bound the finalise resume. worker_cost_usd meters the resumed
        # session cumulatively (--resume appends to the same transcript), so
        # the cap must sit ABOVE the spend already booked: cap + $2 gives the
        # finalise ~$2 of headroom. A flat $2 cap would re-trip on the first
        # poll because the worker already crossed cap. Zero cap is impossible
        # here (rc==3 only fires when the watchdog is armed, i.e. cap > 0).
        my set_worker_cost_cap [expr {[my cost_cap] + 2.0}]
        set finalise_log "[my log_prefix]-finalise.log"
        set finalise_prompt [my load_prompt spar-p-finalise [dict create \
            STEM        $Stem \
            OUTFILE     $Outfile \
            ROSTER_PATH $RosterPath \
            ROSTER_LOCK $RosterLock]]
        if {[my resume "finalise" $finalise_log $finalise_prompt]} {
            ${::spar::harness_log}::warn \
                "\[$slug\] Finalise resume did not close cleanly; validating the on-disk product anyway"
        }
    }

    method do_summary {} {
        set total_cost [my cost_total]
        ${::spar::harness_log}::info "DONE: [my slug] (cost=\$$total_cost)"
    }
}

package provide spar-harness 1.0

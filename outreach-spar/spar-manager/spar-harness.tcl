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

source [file join $::spar::harness_dir spar-mailroom.tcl]

oo::class create spar::Harness {
    variable Slug LogPrefix CostLog SessionId PromptDir LogDir \
             WorkerCostCapUsd CostKilled \
             StallKilled LastProgressMs StallTimeoutMs

    constructor {prompt_dir log_dir} {
        set PromptDir $prompt_dir
        set LogDir    $log_dir
        set Slug      [file tail $prompt_dir]
        set LogPrefix [file join $log_dir $Slug]
        set CostLog   "${LogPrefix}-cost.jsonl"
        set SessionId ""
        set CostKilled 0
        set StallKilled 0
        set LastProgressMs 0
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
            set StallTimeoutMs [expr {[spar::dict_get_default \
                $meta STALL_TIMEOUT_SECS 600] * 1000}]
        }
        file mkdir $log_dir
        set fd [open $CostLog w]; close $fd
    }

    # Public accessors — subclasses and harness scripts use these.
    method slug        {} { return $Slug }
    method log_prefix  {} { return $LogPrefix }
    method cost_log    {} { return $CostLog }
    method session_id  {} { return $SessionId }
    method prompt_dir  {} { return $PromptDir }
    method log_dir     {} { return $LogDir }
    method cost_cap    {} { return $WorkerCostCapUsd }
    method stall_timeout {} { return [expr {$StallTimeoutMs / 1000}] }

    # Per-worker cost cap in USD for a single dispatch (parent session
    # plus its research subagents). Zero disables the watchdog.
    method set_worker_cost_cap {usd} {
        set WorkerCostCapUsd $usd
    }

    # Per-worker stall timeout in seconds (#115). Zero disables. Fractional
    # values are accepted so tests can drive a sub-second timeout.
    method set_stall_timeout {secs} {
        set StallTimeoutMs [expr {$secs * 1000}]
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

    # call — first or standalone claude call. Returns the _invoke code:
    # 0 success, 1 hard failure, 2 external kill / incomplete, 3 deliberate
    # budget kill (cost cap). Captures session_id from the
    # stream; subsequent calls on the same harness reuse it via `resume`.
    method call {stage log_file prompt args} {
        set rc [my _invoke $stage $log_file $prompt {*}$args]
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
        return [my _invoke $stage $log_file $prompt --resume $SessionId {*}$args]
    }

    # inject_mailroom — substitute __MAILROOM_SECTION__ in the prompt
    # file with the prefetched mailroom block (accounts header + per-
    # contact correspondence cascade). Runs in the harness so the slow
    # `mailroom -A search` exec parallelises across contacts instead of
    # serialising in the dispatcher's prepare loop. Empty section when
    # mailroom isn't installed.
    method inject_mailroom {prompt_path name org email} {
        set hdr  [spar::mailroom::accounts_block]
        set body [spar::mailroom::contact_block $name $org $email]
        set section [expr {$hdr eq "" ? "" : "\n\n${hdr}${body}"}]
        set prompt [spar::read_file $prompt_path]
        set prompt [string map [list __MAILROOM_SECTION__ $section] $prompt]
        spar::write_file $prompt_path $prompt
        ${::spar::harness_log}::info "\[$Slug\] \[phase: mailroom\]"
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

    # _invoke — the single claude-CLI call loop. Handles credit-limit
    # waits, JSON parse, result extraction, cost-log append.
    method _invoke {stage log_file prompt args} {
        set json_file "${log_file}.json"
        set max_retries 5
        set attempt 0

        while {1} {
            incr attempt

            set claude_bin [spar::find_tool claude]
            if {$claude_bin eq ""} {
                ${::spar::harness_log}::error "FAIL ($stage: claude not found — check Settings): $Slug"
                return 1
            }
            set cmd [concat [list $claude_bin -p --output-format stream-json --verbose] [my permission_args]]
            # Default to sonnet unless caller already supplied --model
            # (fix-loop attempt 3 escalates to opus; challenger passes its
            # own model). Per-phase model selection from campaign YAML is
            # tracked in #91.
            if {[lsearch -exact $args --model] < 0} {
                lappend cmd --model sonnet
            }
            set cmd [concat $cmd $args [list $prompt]]

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
            set exit_code [my _run_watched $cmd $json_file "${log_file}.stderr"]
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
                    ${::spar::harness_log}::error \
                        "FAIL ($stage: cost cap \$$WorkerCostCapUsd reached — budget kill): $Slug"
                    return 3
                }
                # A stall kill (#115) is the same animal as an external kill for
                # recovery — the disk product may hold real work — so it shares
                # return 2 (validate-the-product). Check it AFTER CostKilled so a
                # cost kill is never downgraded to a resumable stall; the cause
                # string distinguishes the two in the log (#133).
                if {$StallKilled} {
                    ${::spar::harness_log}::error \
                        "FAIL ($stage: stalled — no output for >= [my stall_timeout]s; [my _failure_cause $log_file $json_file $exit_code]): $Slug"
                    return 2
                }
                ${::spar::harness_log}::error \
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
                    if {$attempt >= $max_retries} {
                        ${::spar::harness_log}::error "FAIL ($stage: credit limit after $max_retries retries): $Slug"
                        return 1
                    }
                    set wait_secs [my _credit_wait_secs $result_text]
                    ${::spar::harness_log}::warn "\[$Slug\] Credit limit hit (attempt $attempt/$max_retries). Sleeping [expr {$wait_secs/60}]m until reset..."
                    after [expr {$wait_secs * 1000}] set ::_wake 1
                    vwait ::_wake
                    continue
                }
            }

            if {![dict exists $parsed result]} {
                ${::spar::harness_log}::error "FAIL ($stage: no result in output; [my _failure_cause $log_file $json_file $exit_code]): $Slug"
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
    }

    # _run_watched — run the claude command, capturing stdout to json_file
    # and stderr to stderr_file, returning the child exit code (0 on clean
    # exit). While it runs, a cost watchdog polls this worker's accumulated
    # spend (parent session plus its research subagents) and SIGTERMs the
    # whole process group once it crosses WorkerCostCapUsd, setting
    # CostKilled so _invoke fails the row fast (#114).
    #
    # The command runs through a pipe rather than a blocking exec so the
    # poll timer and the stream reader share one event loop. setsid puts
    # the child in its own process group, so kill -TERM -<pid> reaches
    # claude and the subagents it spawned without touching this harness
    # process. With no cost cap configured the watchdog never fires, but
    # the same pipe path runs so there is one exec path to reason about.
    #
    # rw_drain / rw_poll are dispatched from fileevent / after at global
    # scope through [self], so they carry no leading underscore — TclOO
    # leaves underscored methods unexported and an external dispatch of one
    # fails with "unknown method".
    method _run_watched {cmd json_file stderr_file} {
        set setsid_bin [spar::resolve_coreutil setsid]
        # No setsid (e.g. macOS without util-linux): fall back to a plain
        # blocking exec. The cost watchdog needs a killable process group,
        # so it is inert here; the disk-product verdict is unaffected.
        if {$setsid_bin eq ""} {
            set ec 0
            if {[catch {
                exec {*}$cmd > $json_file 2> $stderr_file
            } _err opts]} {
                set e [dict get $opts -errorcode]
                if {[lindex $e 0] eq "CHILDSTATUS"} { set ec [lindex $e 2] }
            }
            return $ec
        }

        # Build the pipe: setsid wraps the command; stderr is redirected to
        # its file inside the child so only stdout flows up the pipe, which
        # rw_drain tees into json_file as lines arrive.
        set chan [open [list | {*}$setsid_bin {*}$cmd 2> $stderr_file] r]
        fconfigure $chan -blocking 0 -buffering line
        set lead [lindex [pid $chan] 0]
        set out [open $json_file w]

        set ::_rw_done($lead) 0
        set ::_rw_ec($lead) 0
        # Seed the stall clock before arming the poll so the first tick measures
        # idleness from now, not from epoch 0 (which would read as an instant
        # stall). rw_drain advances it on every stdout line.
        set LastProgressMs [clock milliseconds]
        fileevent $chan readable [list [self] rw_drain $chan $out $lead]
        if {$WorkerCostCapUsd > 0 || $StallTimeoutMs > 0} {
            after [my _cost_poll_ms] \
                [list [self] rw_poll $json_file $lead]
        }
        vwait ::_rw_done($lead)
        set ec $::_rw_ec($lead)
        unset -nocomplain ::_rw_done($lead) ::_rw_ec($lead)
        catch {close $out}
        return $ec
    }

    # rw_drain — tee available stdout lines from the pipe into json_file
    # and, on EOF, reap the child's exit code into ::_rw_ec and signal
    # completion. An external kill or the cost watchdog closes the child's
    # stdout, so EOF fires for every termination cause.
    method rw_drain {chan out lead} {
        while {1} {
            if {[catch {gets $chan line} n]} { set n -1 }
            if {$n < 0} {
                if {[eof $chan]} {
                    if {[catch {close $chan} _e opts]} {
                        set e [dict get $opts -errorcode]
                        if {[lindex $e 0] eq "CHILDSTATUS"} {
                            set ::_rw_ec($lead) [lindex $e 2]
                        }
                    }
                    set ::_rw_done($lead) 1
                }
                return
            }
            puts $out $line
            flush $out
            set LastProgressMs [clock milliseconds]
        }
    }

    # rw_poll — watchdog tick: price this worker and, once it crosses the
    # cap, SIGTERM the process group (negative pid). session_id comes from
    # the growing json_file (the init event lands within the first second),
    # so the poll meters the right session even though `call` captures
    # SessionId only after _invoke returns. Re-arms itself until the run
    # completes.
    method rw_poll {json_file lead} {
        # The run can finish between two ticks, after which _run_watched has
        # unset ::_rw_done($lead). A bare $::_rw_done($lead) would then read
        # a missing element and error into bgerror, and on pid reuse could
        # even act against an unrelated later run — so gate on existence too.
        if {![info exists ::_rw_done($lead)] || $::_rw_done($lead)} { return }
        # Two breach detectors share this tick, each gated on its own being
        # armed: with the cost cap disabled (cap == 0) the cost block must not
        # run, or `$cost >= 0` would fire an instant false budget kill. Cost is
        # checked first so a worker over both bounds is recorded as the terminal
        # budget kill (rc==3), not the resumable stall (rc==2).
        if {$WorkerCostCapUsd > 0} {
            set sid $SessionId
            if {$sid eq ""} { set sid [my _extract_session_id $json_file] }
            if {$sid ne ""} {
                set cost [spar::worker_cost_usd $sid]
                if {$cost >= $WorkerCostCapUsd} {
                    set CostKilled 1
                    ${::spar::harness_log}::warn \
                        "\[$Slug\] Cost cap: \$[format %.2f $cost] >= \$$WorkerCostCapUsd — SIGTERM worker group"
                    my _sigterm_group $lead
                    return
                }
            }
        }
        if {$StallTimeoutMs > 0} {
            set idle [expr {[clock milliseconds] - $LastProgressMs}]
            if {$idle >= $StallTimeoutMs} {
                set StallKilled 1
                ${::spar::harness_log}::warn \
                    "\[$Slug\] Stall: no output for [expr {$idle / 1000}]s >= [my stall_timeout]s — SIGTERM worker group"
                my _sigterm_group $lead
                return
            }
        }
        after [my _cost_poll_ms] [list [self] rw_poll $json_file $lead]
    }

    # _sigterm_group — SIGTERM the worker's process group (negative pid). setsid
    # put the child in its own group with the group id equal to the lead pid
    # when it execs in place (the case for this pipe shape: the Tcl pipe child
    # is not already a group leader, so setsid does not fork). The positive-pid
    # SIGTERM is a belt-and-suspenders for any host where setsid forks, so the
    # lead itself is signalled even if the group target misses.
    method _sigterm_group {lead} {
        catch {exec kill -TERM -$lead}
        catch {exec kill -TERM $lead}
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
        ${::spar::harness_log}::error "FAIL (validation failed after $max_fix retries): $Slug"
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
            my do_inject_mailroom
            if {[my do_author_draft]}             { return 1 }
            if {[my run_spar_loop]}               { return 1 }
            if {[my do_assembly]}                 { return 1 }
            if {[my do_post_assembly_validation]} { return 1 }
            my do_summary
            return 0
        } on error {err opts} {
            ${::spar::harness_log}::error \
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

    method do_inject_mailroom {} {
        my inject_mailroom \
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

        set draft_text [spar::read_file $author_draft_log]
        set draft [spar::extract_between $draft_text "DRAFT_START" "DRAFT_END"]
        if {$draft eq ""} {
            ${::spar::harness_log}::error "FAIL (no draft markers): $slug"
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

            set rev_text [spar::read_file $author_rev_log]
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
                set rev_draft [spar::extract_between [spar::read_file $rev_log] "DRAFT_START" "DRAFT_END"]
                if {$rev_draft ne ""} {
                    append all_revisions "\n### A1 Draft [expr {$r + 1}]\n\n$rev_draft\n"
                }
            }
        }

        set initial_draft [spar::extract_between [spar::read_file "${log_prefix}-author-draft.log"] "DRAFT_START" "DRAFT_END"]
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
                ${::spar::harness_log}::error "FAIL (DbC-Pre: assembly precondition log missing: $lg): $slug"
                return 1
            }
            if {[file size $lg] == 0} {
                ${::spar::harness_log}::error "FAIL (DbC-Pre: assembly precondition log empty: $lg): $slug"
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
    # Emits msg_roster_update per match; the dispatcher applies it.
    method sanitise_roster_email {roster_path slug} {
        if {![file exists $roster_path]} { return }
        foreach row [spar::load_roster $roster_path] {
            if {[spar::dict_get_default $row stem ""] ne $slug} continue
            set email [string trim [spar::dict_get_default $row email ""]]
            if {[spar::is_masked_email $email]} {
                ${::spar::harness_log}::warn "\[[my slug]\] Guardrail: blanked masked email '$email' in roster"
                if {[llength [info commands msg_roster_update]] > 0} {
                    msg_roster_update [my slug] $roster_path \
                        stem $slug email ""
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
        return "FIRST: [join $parts { AND }]. Then re-derive any front-matter fields whose values depend on that data (warmth_finding, applicable_angles).\n\n"
    }

    # Override: include the first error message in the failure line.
    method report_fix_failure {hard max_fix} {
        set msg [dict get [lindex $hard 0] message]
        ${::spar::harness_log}::error "FAIL (validation failed after $max_fix retries): [my slug] — $msg"
    }

    # Run the full P-phase pipeline. Returns 0 on success, 1 on failure.
    # The try/on-error wrapper logs uncaught exceptions as a FAIL line
    # so the operator sees a per-row outcome instead of a generic
    # "harness exited rc=…" from harness_run.
    method run {} {
        try {
            my load_my_meta
            my do_inject_mailroom
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
            ${::spar::harness_log}::error \
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

    method do_inject_mailroom {} {
        my inject_mailroom \
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

#!/usr/bin/env tclsh9.0
# Exercises the per-worker cost cap circuit-breaker in spar::Harness
# (#114, #139) and the return-code contract that distinguishes a DELIBERATE
# budget kill (fail fast, no resume) from an external kill / truncation
# (validate the disk product, resume) from a complete envelope (success).
#
# _invoke return codes:
#   0 — turn closed cleanly (or a complete envelope landed before a kill)
#   1 — hard failure (no usable product)
#   2 — external kill / truncation: turn cut short, product may hold work
#   3 — deliberate budget kill (cost cap): the circuit-breaker firing
#
# The claude binary is stubbed by overriding spar::find_tool — the real
# claude on $PATH is never invoked. Cost-cap stubs emit an init event
# (carrying session_id) then sleep past the deadline, so the cost watchdog
# fires well before their natural exit and a prompt return proves the kill
# landed; worker_cost_usd is overridden so the meter does not depend on a
# real ~/.claude/projects transcript.

package require TclOO
package require json
package require json::write
package require logger

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-harness.tcl]
source [file join $script_dir test-helpers.tcl]

# ── Shared setup ────────────────────────────────────────────────────────
# A scratch root for every stub and log dir below, plus a default
# spar::find_tool override so _invoke never resolves the real claude on
# PATH. Each section that needs a different stub re-overrides find_tool to
# point at its own stub.
set tmp_root [file join /tmp "spar-test-timeout-[pid]-[clock microseconds]"]
file mkdir $tmp_root
lappend ::cleanup_dirs $tmp_root

set stub_path [file join $tmp_root claude]
set fd [open $stub_path w]
puts $fd "#!/bin/sh"
puts $fd "sleep 30"
close $fd
file attributes $stub_path -permissions 0755

# Override spar::find_tool so _invoke picks up a stub instead of the real
# claude on PATH. auto_execok would otherwise resolve `claude` to whatever
# is installed system-wide.
proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::stub_path] }
    return [auto_execok $name]
}

set prompt_dir [file join $tmp_root prompt]
set log_dir    [file join $tmp_root logs]
file mkdir $prompt_dir
file mkdir $log_dir

# ════════════════════════════════════════════════════════════════════════
section "2c. External kill is incomplete, not a budget kill (rc=2)"
# ════════════════════════════════════════════════════════════════════════

# A worker dies with no result object and no budget cap firing — an
# external SIGKILL, a crash, a truncated stream. That is NOT a deliberate
# budget kill, so _invoke returns rc=2 (incomplete): ProfileHarness::run
# keeps the validate-the-product / resume path for it, since the disk
# product may still hold real work (FM-HARNESS-2). The stub exits non-zero
# without writing a result line; with a cost cap that never trips (no real
# session on disk), the circuit-breaker does not fire.
set crash_stub [file join $tmp_root claude-crash]
set fd [open $crash_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"crash-sess"}'}
puts $fd "exit 137"
close $fd
file attributes $crash_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::crash_stub] }
    return [auto_execok $name]
}

set log_file_crash [file join $tmp_root logs-crash test-crash.log]
set inst_crash [spar::Harness new $prompt_dir [file join $tmp_root logs-crash]]

set rc_crash [$inst_crash call "test-stage" $log_file_crash "dummy prompt"]
$inst_crash destroy

assert_eq $rc_crash 2 "_invoke returns rc=2 (external kill / incomplete) when no budget cap fired"

# ════════════════════════════════════════════════════════════════════════
section "5. meta.env carrier: constructor reads WORKER_COST_CAP_USD"
# ════════════════════════════════════════════════════════════════════════

# The cost cap travels through meta.env (key WORKER_COST_CAP_USD), so a
# campaign can tune it per run. An absent key leaves the default (above the
# $7.83 ceiling on record).
set cap_meta_dir [file join $tmp_root prompt-costmeta]
file mkdir $cap_meta_dir
set fd [open [file join $cap_meta_dir meta.env] w]
puts $fd "STEM=\"cost-row\""
puts $fd "WORKER_COST_CAP_USD=\"3.50\""
close $fd
set inst_cap [spar::Harness new $cap_meta_dir [file join $tmp_root logs-cap]]
assert_eq [$inst_cap cost_cap] 3.50 \
    "meta.env: WORKER_COST_CAP_USD read into the harness"
$inst_cap destroy

set inst_def [spar::Harness new $prompt_dir [file join $tmp_root logs-capdef]]
assert_eq [$inst_def cost_cap] 10.0 \
    "default cost cap (10.0, above the \$7.83 ceiling) when meta key absent"
$inst_def destroy

# ════════════════════════════════════════════════════════════════════════
section "6. Cost cap is a deliberate budget kill (rc=3, no resume)"
# ════════════════════════════════════════════════════════════════════════

# A worker whose accumulated spend crosses the cap is SIGTERM'd by the
# watchdog. That is a budget circuit-breaker, so _invoke returns rc=3 —
# fail fast, no resume (#114, #139). The stub emits an init event (carrying
# session_id) then sleeps; the watchdog meters the worker by that
# session_id and kills the group.
#
# worker_cost_usd is overridden so the test does not depend on a real
# ~/.claude/projects transcript: it reports a figure over the cap for the
# test session_id once a couple of polls have passed. _cost_poll_ms is
# shortened to keep the test quick.
set cap_stub [file join $tmp_root claude-cap]
set fd [open $cap_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"cap-sess"}'}
puts $fd "sleep 30"
close $fd
file attributes $cap_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::cap_stub] }
    return [auto_execok $name]
}

# Stand-in cost meter: anything at or over the cap for the test session.
set ::orig_worker_cost_usd [info body spar::worker_cost_usd]
set ::orig_worker_cost_args [info args spar::worker_cost_usd]
proc spar::worker_cost_usd {session_id {transcripts_root ""}} {
    if {$session_id eq "cap-sess"} { return 99.0 }
    return 0.0
}

set cap_prompt [file join $tmp_root prompt-cap]
file mkdir $cap_prompt
set inst_cc [spar::Harness new $cap_prompt [file join $tmp_root logs-cc]]
# Shorten the watchdog cadence on this one instance — no test-only
# subclass; oo::objdefine overrides the single method on the single
# object, leaving the production poll interval untouched.
oo::objdefine $inst_cc method _cost_poll_ms {} { return 200 }
$inst_cc set_worker_cost_cap 5.0

set log_file_cc [file join $tmp_root logs-cc cc.log]
set t0 [clock milliseconds]
set rc_cc [$inst_cc call "cost-stage" $log_file_cc "dummy prompt"]
set elapsed_cc [expr {[clock milliseconds] - $t0}]
$inst_cc destroy

# Restore the real meter for any later legs.
proc spar::worker_cost_usd {session_id {transcripts_root ""}} $::orig_worker_cost_usd

assert_eq $rc_cc 3 "_invoke returns rc=3 (deliberate budget kill) when the cost cap trips"
# The stub would sleep 30s; the watchdog kills within a few 200ms polls,
# so a return well under that proves the cost cap fired, not the stub
# exiting on its own.
if {$elapsed_cc >= 8000} {
    puts "FAIL: cost cap did not fire within budget"
    puts "  elapsed: ${elapsed_cc}ms (expected < 8000ms)"
    incr ::failures
} else {
    puts "  ok: cost cap fired at ${elapsed_cc}ms (< 8000ms)"
    incr ::passes
}

# ════════════════════════════════════════════════════════════════════════
section "6b. Under-cap run completes cleanly across several polls (no stale-timer error)"
# ════════════════════════════════════════════════════════════════════════

# A worker that stays under the cap and finishes after the watchdog has
# re-armed a few times: the run must return rc=0 with the result intact,
# and the poll timer pending at completion must not error when it fires
# into the next event loop (the run unsets ::_rw_done($lead) on return, so
# the poll guard has to tolerate the missing element). A bgerror here would
# surface as a non-zero exit / stderr noise; the assertions below confirm a
# clean success.
set under_stub [file join $tmp_root claude-under]
set fd [open $under_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"under-sess"}'}
puts $fd "sleep 0.6"
puts $fd {printf '%s\n' '{"type":"result","subtype":"success","result":"UNDER OK","is_error":false,"total_cost_usd":0.04,"session_id":"under-sess"}'}
puts $fd "exit 0"
close $fd
file attributes $under_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::under_stub] }
    return [auto_execok $name]
}
# Meter always under the cap so the watchdog re-arms but never kills.
proc spar::worker_cost_usd {session_id {transcripts_root ""}} { return 0.10 }

set under_prompt [file join $tmp_root prompt-under]
file mkdir $under_prompt
set inst_un [spar::Harness new $under_prompt [file join $tmp_root logs-un]]
oo::objdefine $inst_un method _cost_poll_ms {} { return 150 }
$inst_un set_worker_cost_cap 5.0

set log_un [file join $tmp_root logs-un un.log]
set rc_un [$inst_un call "under-stage" $log_un "dummy prompt"]
# Pump the event loop briefly so any stale re-armed poll timer (150ms)
# fires here; with the guard it returns quietly, without it bgerror trips.
after 400 set ::_un_wait 1
vwait ::_un_wait
set un_result [string trim [exec cat $log_un]]
$inst_un destroy
proc spar::worker_cost_usd {session_id {transcripts_root ""}} $::orig_worker_cost_usd

assert_eq $rc_un 0 "under-cap run returns rc=0 after several polls"
assert_eq $un_result "UNDER OK" "under-cap run wrote its result intact"

# ════════════════════════════════════════════════════════════════════════
section "7. worker_cost_usd prices parent + subagents at sonnet rates"
# ════════════════════════════════════════════════════════════════════════

# A synthetic ~/.claude/projects layout: one parent session plus two
# research subagents under <sid>/subagents/. worker_cost_usd globs by
# session_id, sums assistant `usage` deduped per requestId, and prices at
# sonnet published rates (input 3, output 15, cache_write 3.75, cache_read
# 0.30 per Mtok). The subagents are the bulk of a heavy worker's bill, so
# the meter must include them.
set proj_root [file join $tmp_root projects]
set proj_dir  [file join $proj_root some-campaign]
set sid "synth-sess-1234"
file mkdir [file join $proj_dir $sid subagents]

proc write_usage_line {fd req in out cw cr} {
    set u "{\"input_tokens\":$in,\"output_tokens\":$out,\"cache_creation_input_tokens\":$cw,\"cache_read_input_tokens\":$cr}"
    puts $fd "{\"type\":\"assistant\",\"requestId\":\"$req\",\"message\":{\"model\":\"claude-sonnet-4-6\",\"usage\":$u}}"
}

# Parent: one request, 1M output tokens = $15 at sonnet output rate.
set fd [open [file join $proj_dir $sid.jsonl] w]
puts $fd "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"$sid\"}"
write_usage_line $fd req-A 0 1000000 0 0
# Same request appears again with lower numbers — must NOT double count.
write_usage_line $fd req-A 0 500000 0 0
close $fd

# Subagent 1: 1M cache_read tokens = $0.30.
set fd [open [file join $proj_dir $sid subagents agent-1.jsonl] w]
write_usage_line $fd req-B 0 0 0 1000000
close $fd

# Subagent 2: 1M cache_write tokens = $3.75 and 1M input = $3.00.
set fd [open [file join $proj_dir $sid subagents agent-2.jsonl] w]
write_usage_line $fd req-C 1000000 0 1000000 0
close $fd

# Expected: 15.00 (parent) + 0.30 (sub1) + 3.75 + 3.00 (sub2) = 22.05.
set cost [spar::worker_cost_usd $sid $proj_root]
assert_eq [format %.2f $cost] 22.05 \
    "worker_cost_usd sums parent + subagents, dedups per requestId, sonnet rates"

set files [spar::worker_session_files $sid $proj_root]
assert_eq [llength $files] 3 "worker_session_files finds parent + 2 subagents"

# Missing session: zero, not an error (the transcript has not appeared yet).
assert_eq [spar::worker_cost_usd "no-such-sess" $proj_root] 0.0 \
    "worker_cost_usd returns 0.0 before the transcript appears"

finish_tests

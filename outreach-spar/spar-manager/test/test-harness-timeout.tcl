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
# landed; session_cost_usd is overridden so the meter does not depend on a
# real ~/.claude/projects transcript.

package require TclOO
package require json
package require json::write
package require logger

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir .. lib spar-harness.tcl]
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
# session_cost_usd is overridden so the test does not depend on a real
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

set cap_prompt [file join $tmp_root prompt-cap]
file mkdir $cap_prompt
set inst_cc [spar::Harness new $cap_prompt [file join $tmp_root logs-cc]]
# Shorten the watchdog cadence on this one instance — no test-only
# subclass; oo::objdefine overrides the single method on the single
# object, leaving the production poll interval untouched.
oo::objdefine $inst_cc method _cost_poll_ms {} { return 200 }
# Stand-in cost meter: anything at or over the cap for the test session.
oo::objdefine $inst_cc method session_cost_usd {sid} {
    if {$sid eq "cap-sess"} { return 99.0 }
    return 0.0
}
$inst_cc set_worker_cost_cap 5.0

set log_file_cc [file join $tmp_root logs-cc cc.log]
set t0 [clock milliseconds]
set rc_cc [$inst_cc call "cost-stage" $log_file_cc "dummy prompt"]
set elapsed_cc [expr {[clock milliseconds] - $t0}]
$inst_cc destroy

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
set under_prompt [file join $tmp_root prompt-under]
file mkdir $under_prompt
set inst_un [spar::Harness new $under_prompt [file join $tmp_root logs-un]]
oo::objdefine $inst_un method _cost_poll_ms {} { return 150 }
# Meter always under the cap so the watchdog re-arms but never kills.
oo::objdefine $inst_un method session_cost_usd {sid} { return 0.10 }
$inst_un set_worker_cost_cap 5.0

set log_un [file join $tmp_root logs-un un.log]
set rc_un [$inst_un call "under-stage" $log_un "dummy prompt"]
# Pump the event loop briefly so any stale re-armed poll timer (150ms)
# fires here; with the guard it returns quietly, without it bgerror trips.
after 400 set ::_un_wait 1
vwait ::_un_wait
set un_result [string trim [exec cat $log_un]]
$inst_un destroy

assert_eq $rc_un 0 "under-cap run returns rc=0 after several polls"
assert_eq $un_result "UNDER OK" "under-cap run wrote its result intact"

# ════════════════════════════════════════════════════════════════════════
section "8. Profile cost-cap kill resumes once to finalise, not fail"
# ════════════════════════════════════════════════════════════════════════

# A cost-cap kill (rc==3) of a profile worker must not be discarded: the
# kill lands after the costly research and body are written but before the
# cheap finalisation, so ProfileHarness::run resumes the captured session
# once with the self-contained finalise prompt (no research) under cap + $2
# of headroom, then validates the on-disk product. do_profile_call is
# stubbed to report the kill and resume records its stage and the cap in
# force, proving run() finalises rather than returning 1.
set fin_prompt_dir [file join $tmp_root prompt-fin]
file mkdir $fin_prompt_dir
set fd [open [file join $fin_prompt_dir meta.env] w]
puts $fd "WORKER_COST_CAP_USD=4.0"
close $fd

set ph [spar::ProfileHarness new $fin_prompt_dir [file join $tmp_root logs-fin]]
set ::fin_resume_calls {}
oo::objdefine $ph {
    method load_my_meta {} {
        my variable Outfile RosterPath Stem RosterLock RequiredSkills
        set Outfile        /tmp/none/profile.md
        set RosterPath     /tmp/none/roster.tsv
        set Stem           teststem
        set RosterLock     /tmp/none/.roster.lock
        set RequiredSkills {}
    }
    method do_profile_call {} { return 3 }
    method session_id {} { return "fin-sess" }
    method resume {stage log_file prompt args} {
        lappend ::fin_resume_calls [list $stage [my cost_cap]]
        return 0
    }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { return 0 }
    method do_summary {} {}
    method testset_sid {v} { my variable SessionId; set SessionId $v }
}
$ph testset_sid fin-sess
set rc_fin [$ph run]
$ph destroy

assert_eq $rc_fin 0 "profile run returns 0 (finalised) after a cost-cap kill"
assert_eq [llength $::fin_resume_calls] 1 "exactly one finalise resume issued"
assert_eq [lindex [lindex $::fin_resume_calls 0] 0] "finalise" \
    "the resume ran the finalise stage"
assert_eq [lindex [lindex $::fin_resume_calls 0] 1] 6.0 \
    "finalise cap is the worker cap + \$2 headroom (4.0 -> 6.0)"

# A cost-cap kill with no captured session_id cannot resume; run() must not
# crash, and must fall through to validation (which here passes).
set ph2 [spar::ProfileHarness new $fin_prompt_dir [file join $tmp_root logs-fin2]]
set ::fin2_resume_calls {}
oo::objdefine $ph2 {
    method load_my_meta {} {
        my variable Outfile RosterPath Stem RosterLock RequiredSkills
        set Outfile        /tmp/none/profile.md
        set RosterPath     /tmp/none/roster.tsv
        set Stem           teststem
        set RosterLock     /tmp/none/.roster.lock
        set RequiredSkills {}
    }
    method do_profile_call {} { return 3 }
    method session_id {} { return "" }
    method resume {stage log_file prompt args} {
        lappend ::fin2_resume_calls $stage
        return 0
    }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { return 0 }
    method do_summary {} {}
}
set rc_fin2 [$ph2 run]
$ph2 destroy
assert_eq $rc_fin2 0 "cost-cap kill with no session_id falls through without crashing"
assert_eq [llength $::fin2_resume_calls] 0 "no resume attempted without a session_id"

# ════════════════════════════════════════════════════════════════════════
section "9. Credit-limit hit waits then resumes the same session (rc=0)"
# ════════════════════════════════════════════════════════════════════════

# Characterisation of the usage-window (credit-limit) retry before it is
# refactored out of _invoke. The stub emits a complete is_error envelope whose
# result text matches the harness's *hit*your*limit*resets* guard on its FIRST
# invocation, then a success envelope on the SECOND. The harness must wait
# (_credit_wait_secs, overridden to 0 here so the test does not sleep until the
# named reset time) and retry, ultimately returning rc=0 with the success
# product on disk — proving the credit limit is not a terminal failure.
set cl_counter [file join $tmp_root cl-counter]
set cl_stub [file join $tmp_root claude-creditlimit]
set fd [open $cl_stub w]
puts $fd "#!/bin/sh"
puts $fd "CNT=\"$cl_counter\""
puts $fd {n=$(cat "$CNT" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$CNT"}
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"limit-sess"}'}
puts $fd {if [ "$n" -eq 1 ]; then}
puts $fd {  printf '%s\n' '{"type":"result","subtype":"error_during_execution","is_error":true,"result":"You have hit your usage limit, resets 3am (Australia/Brisbane)","total_cost_usd":0,"session_id":"limit-sess"}'}
puts $fd {else}
puts $fd {  printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"PROFILE OK","total_cost_usd":0.05,"session_id":"limit-sess"}'}
puts $fd {fi}
puts $fd "exit 0"
close $fd
file attributes $cl_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::cl_stub] }
    return [auto_execok $name]
}

set cl_prompt [file join $tmp_root prompt-cl]
file mkdir $cl_prompt
set inst_cl [spar::Harness new $cl_prompt [file join $tmp_root logs-cl]]
# Disable the cost watchdog (this leg is about the credit-limit retry, not the
# cap) and collapse the credit-limit sleep to ~0 so the test runs instantly.
$inst_cl set_worker_cost_cap 0
oo::objdefine $inst_cl method _credit_wait_secs {msg} { return 0 }

set log_cl [file join $tmp_root logs-cl cl.log]
set t0 [clock milliseconds]
set rc_cl [$inst_cl call "credit-stage" $log_cl "dummy prompt"]
set elapsed_cl [expr {[clock milliseconds] - $t0}]
set cl_result [string trim [exec cat $log_cl]]
set cl_attempts [string trim [exec cat $cl_counter]]
$inst_cl destroy

assert_eq $rc_cl 0 "credit-limit hit then success returns rc=0"
assert_eq $cl_result "PROFILE OK" "the second (post-reset) attempt's product is on disk"
assert_eq $cl_attempts 2 "exactly two claude invocations: limit then success"

# ════════════════════════════════════════════════════════════════════════
section "10. Failure cause is captured for an empty-result FAIL (#133)"
# ════════════════════════════════════════════════════════════════════════

# When claude exits with no usable result, the FAIL log must carry the child
# exit code, the stderr tail, and the last stream event that did land — so the
# five empty-artefact failures of #133 stop being undiagnosable. Exercise the
# cause assembler directly (exported for the test); section 2c already proves
# the rc==2 path invokes it without crashing.
set fc_dir [file join $tmp_root prompt-fc]
file mkdir $fc_dir
set inst_fc [spar::Harness new $fc_dir [file join $tmp_root logs-fc]]
oo::objdefine $inst_fc export _failure_cause

set fc_log [file join $tmp_root logs-fc fc.log]
set f [open "${fc_log}.stderr" w]
puts $f "warning: something benign"
puts $f "fatal: the real cause"
close $f
set f [open "${fc_log}.json" w]
puts $f {{"type":"system","subtype":"init","session_id":"fc-sess"}}
close $f

set cause [$inst_fc _failure_cause $fc_log "${fc_log}.json" 137]
$inst_fc destroy

assert_match $cause "*exit 137*" "cause carries the child exit code"
assert_match $cause "*fatal: the real cause*" "cause carries the stderr tail"
assert_match $cause "*last event: system/init*" "cause carries the last stream event"

# ════════════════════════════════════════════════════════════════════════
section "11. Stall watchdog: meta.env carrier + idle SIGTERM (#115)"
# ════════════════════════════════════════════════════════════════════════

# The stall timeout travels through meta.env (STALL_TIMEOUT_SECS), mirroring
# WORKER_COST_CAP_USD; absent key leaves the conservative default.
set stall_meta_dir [file join $tmp_root prompt-stallmeta]
file mkdir $stall_meta_dir
set fd [open [file join $stall_meta_dir meta.env] w]
puts $fd "STALL_TIMEOUT_SECS=\"45\""
close $fd
set inst_sm [spar::Harness new $stall_meta_dir [file join $tmp_root logs-sm]]
assert_eq [$inst_sm stall_timeout] 45 "meta.env: STALL_TIMEOUT_SECS read into the harness"
$inst_sm destroy

set stall_nokey_dir [file join $tmp_root prompt-stallnokey]
file mkdir $stall_nokey_dir
set inst_snk [spar::Harness new $stall_nokey_dir [file join $tmp_root logs-snk]]
assert_eq [$inst_snk stall_timeout] 600 "default stall timeout (600s) when meta key absent"
$inst_snk destroy

# A worker that emits an init event then falls silent is SIGTERM'd by the stall
# watchdog. The cost cap is disabled (this leg is the stall path, not the cap),
# so the poll must arm on the stall bound alone. This stub always stalls, so the
# bounded fresh-session retries (#146) are exhausted and the call returns rc==2:
# the disk product may hold work, same recovery as an external kill.
set stall_stub [file join $tmp_root claude-stall]
set fd [open $stall_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"stall-sess"}'}
puts $fd "sleep 30"
close $fd
file attributes $stall_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::stall_stub] }
    return [auto_execok $name]
}

set stall_prompt [file join $tmp_root prompt-stall]
file mkdir $stall_prompt
set inst_st [spar::Harness new $stall_prompt [file join $tmp_root logs-st]]
oo::objdefine $inst_st method _cost_poll_ms {} { return 150 }
$inst_st set_worker_cost_cap 0
$inst_st set_stall_timeout 0.4

set log_st [file join $tmp_root logs-st st.log]
set t0 [clock milliseconds]
set rc_st [$inst_st call "stall-stage" $log_st "dummy prompt"]
set elapsed_st [expr {[clock milliseconds] - $t0}]
$inst_st destroy

assert_eq $rc_st 2 "stall kill returns rc=2 (validate-the-product) with cost cap disabled"
if {$elapsed_st >= 8000} {
    puts "FAIL: stall watchdog did not fire within budget"
    puts "  elapsed: ${elapsed_st}ms (expected < 8000ms)"
    incr ::failures
} else {
    puts "  ok: stall watchdog fired at ${elapsed_st}ms (< 8000ms)"
    incr ::passes
}

# ════════════════════════════════════════════════════════════════════════
section "11b. Stall retries on a fresh session, then recovers (#146)"
# ════════════════════════════════════════════════════════════════════════

# A stall is a recoverable interruption: the worker emitted nothing on disk to
# validate, and the silence is often a usage-limit window the CLI never surfaced
# as a resets-string. So a call-initiated stall must not drop the contact — the
# recovery layer retries on a FRESH session (no --resume, the hung session
# cleared) up to the bound. The stub stalls on its first invocation and succeeds
# on the second; the harness must return rc=0 with the recovered product on disk,
# after exactly two invocations, the retry carrying no --resume.
set sr_counter [file join $tmp_root sr-counter]
set sr_argv    [file join $tmp_root sr-argv]
set sr_stub [file join $tmp_root claude-stallretry]
set fd [open $sr_stub w]
puts $fd "#!/bin/sh"
puts $fd "CNT=\"$sr_counter\""
puts $fd "ARGV=\"$sr_argv\""
puts $fd {printf '%s\n' "$*" >> "$ARGV"}
puts $fd {n=$(cat "$CNT" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$CNT"}
puts $fd {printf '%s\n' "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"stallretry-sess-$n\"}"}
puts $fd {if [ "$n" -eq 1 ]; then}
puts $fd {  sleep 30}
puts $fd {else}
puts $fd {  printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"RECOVERED","total_cost_usd":0.03,"session_id":"stallretry-sess-2"}'}
puts $fd {fi}
puts $fd "exit 0"
close $fd
file attributes $sr_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::sr_stub] }
    return [auto_execok $name]
}

set sr_prompt [file join $tmp_root prompt-sr]
file mkdir $sr_prompt
set inst_sr [spar::Harness new $sr_prompt [file join $tmp_root logs-sr]]
oo::objdefine $inst_sr method _cost_poll_ms {} { return 150 }
$inst_sr set_worker_cost_cap 0
$inst_sr set_stall_timeout 0.4

set log_sr [file join $tmp_root logs-sr sr.log]
set rc_sr [$inst_sr call "stallretry-stage" $log_sr "dummy prompt"]
set sr_result [string trim [exec cat $log_sr]]
set sr_attempts [string trim [exec cat $sr_counter]]
set argv_sr [split [string trim [exec cat $sr_argv]] \n]
$inst_sr destroy

assert_eq $rc_sr 0 "stall then success returns rc=0 (contact recovered, not dropped)"
assert_eq $sr_result "RECOVERED" "the fresh-session retry's product is on disk"
assert_eq $sr_attempts 2 "exactly two invocations: stall then fresh retry"
if {[string match *--resume* [lindex $argv_sr 1]]} {
    puts "FAIL: stall retry should run fresh, not resume the hung session"; incr ::failures
} else { puts "  ok: stall retry runs fresh (no --resume)"; incr ::passes }

# ════════════════════════════════════════════════════════════════════════
section "12. Usage-window recovery posture: resume default, restart override (#142)"
# ════════════════════════════════════════════════════════════════════════

# After the reset, an initial `call` resumes the interrupted session by default
# (the user-chosen posture): the retry carries --resume <captured sid> instead
# of restarting fresh. A per-stage override flips it back to restart. The stub
# records its argv per invocation so the retry's command line is observable;
# rc never surfaces as 4 (the wrapper consumes it).
set rec_counter [file join $tmp_root rec-counter]
set rec_argv [file join $tmp_root rec-argv]
set rec_stub [file join $tmp_root claude-rec]
set fd [open $rec_stub w]
puts $fd "#!/bin/sh"
puts $fd "CNT=\"$rec_counter\""
puts $fd "ARGV=\"$rec_argv\""
puts $fd {printf '%s\n' "$*" >> "$ARGV"}
puts $fd {n=$(cat "$CNT" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$CNT"}
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"limit-sess"}'}
puts $fd {if [ "$n" -eq 1 ]; then}
puts $fd {  printf '%s\n' '{"type":"result","subtype":"error_during_execution","is_error":true,"result":"You have hit your usage limit, resets 3am (Australia/Brisbane)","total_cost_usd":0,"session_id":"limit-sess"}'}
puts $fd {else}
puts $fd {  printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"PROFILE OK","total_cost_usd":0.05,"session_id":"limit-sess"}'}
puts $fd {fi}
puts $fd "exit 0"
close $fd
file attributes $rec_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::rec_stub] }
    return [auto_execok $name]
}

# Default posture: resume-continue.
file delete -force $rec_counter $rec_argv
set rv_prompt [file join $tmp_root prompt-rv]
file mkdir $rv_prompt
set inst_rv [spar::Harness new $rv_prompt [file join $tmp_root logs-rv]]
$inst_rv set_worker_cost_cap 0
oo::objdefine $inst_rv method _credit_wait_secs {msg} { return 0 }
set rc_rv [$inst_rv call "rec-stage" [file join $tmp_root logs-rv rv.log] "dummy prompt"]
$inst_rv destroy
set argv_rv [split [string trim [exec cat $rec_argv]] \n]
assert_eq $rc_rv 0 "resume-posture call recovers to rc=0 (code 4 never leaks)"
assert_eq [llength $argv_rv] 2 "exactly two invocations: block then resumed retry"
if {[string match *--resume* [lindex $argv_rv 0]]} {
    puts "FAIL: first invocation should not carry --resume"; incr ::failures
} else { puts "  ok: first invocation runs fresh (no --resume)"; incr ::passes }
assert_match [lindex $argv_rv 1] "*--resume limit-sess*" \
    "second invocation resumes the captured session"

# Per-stage override: restart fresh, no --resume on the retry.
file delete -force $rec_counter $rec_argv
set rs_prompt [file join $tmp_root prompt-rs]
file mkdir $rs_prompt
set inst_rs [spar::Harness new $rs_prompt [file join $tmp_root logs-rs]]
$inst_rs set_worker_cost_cap 0
oo::objdefine $inst_rs method _credit_wait_secs {msg} { return 0 }
oo::objdefine $inst_rs method recovery_posture {stage} { return restart }
set rc_rs [$inst_rs call "rec-stage" [file join $tmp_root logs-rs rs.log] "dummy prompt"]
$inst_rs destroy
set argv_rs [split [string trim [exec cat $rec_argv]] \n]
assert_eq $rc_rs 0 "restart-posture call recovers to rc=0"
if {[string match *--resume* [lindex $argv_rs 1]]} {
    puts "FAIL: restart posture should not add --resume on the retry"; incr ::failures
} else { puts "  ok: restart posture re-issues fresh (no --resume)"; incr ::passes }

# ════════════════════════════════════════════════════════════════════════
section "13. No draft markers is a captured FAIL cause (#145)"
# ════════════════════════════════════════════════════════════════════════

# do_author_draft greps the author transcript for DRAFT_START/DRAFT_END. When
# the author returns a complete envelope but its text carries no markers, the
# draft is empty and the contact must fail with a cause the run-end roll-call
# can name — not a silent drop. The stub emits a clean success envelope whose
# assistant text holds no markers, so `call` returns 0 and the no-markers
# branch (not the call-failed branch) is what fails the contact.
set nd_stub [file join $tmp_root claude-nodraft]
set fd [open $nd_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s\n' '{"type":"system","subtype":"init","session_id":"nodraft-sess"}'}
puts $fd {printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"I looked into the contact but have nothing to pitch right now."}]}}'}
puts $fd {printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"I looked into the contact but have nothing to pitch right now.","total_cost_usd":0.05,"session_id":"nodraft-sess"}'}
puts $fd "exit 0"
close $fd
file attributes $nd_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::nd_stub] }
    return [auto_execok $name]
}

set nd_prompt [file join $tmp_root prompt-nodraft]
file mkdir $nd_prompt
set afd [open [file join $nd_prompt author-draft.txt] w]; puts $afd "draft a message"; close $afd
set inst_nd [spar::ApproachHarness new $nd_prompt [file join $tmp_root logs-nodraft]]
$inst_nd set_worker_cost_cap 0
set rc_nd [$inst_nd do_author_draft]
set cause_nd [$inst_nd fail_cause]
$inst_nd destroy

assert_eq $rc_nd 1 "do_author_draft returns 1 when the transcript has no DRAFT markers"
assert_match $cause_nd "*no draft markers*" \
    "fail_cause records the no-draft-markers cause for the roll-call"

# ════════════════════════════════════════════════════════════════════════
section "14. claude-not-found is a hard failure with a captured cause (rc=1)"
# ════════════════════════════════════════════════════════════════════════

# The rc=1 hard-failure path: when the claude binary cannot be resolved,
# _invoke fails fast (no resume) and records a cause the roll-call can show.
proc spar::find_tool {name} {
    if {$name eq "claude"} { return "" }
    return [auto_execok $name]
}

set nf_prompt [file join $tmp_root prompt-nf]
file mkdir $nf_prompt
set inst_nf [spar::Harness new $nf_prompt [file join $tmp_root logs-nf]]
set rc_nf [$inst_nf call "nf-stage" [file join $tmp_root logs-nf nf.log] "dummy prompt"]
set cause_nf [$inst_nf fail_cause]
$inst_nf destroy

assert_eq $rc_nf 1 "claude-not-found returns rc=1 (hard failure, no resume)"
assert_match $cause_nf "*claude not found*" \
    "fail_cause records the not-found cause for the roll-call"

# ════════════════════════════════════════════════════════════════════════
section "11. Untouched pre-existing outfile requeues once, then fails (#181)"
# ════════════════════════════════════════════════════════════════════════

# A worker that ends its turn parked on a backgrounded fetch closes
# cleanly (rc=0 from do_profile_call) without reaching its write step. A
# re-profile row's pre-existing outfile then passes validation (staleness
# issues are warning-severity), so run() must intercept the untouched
# file before validation: first occurrence returns 4 (harness_run maps
# it to the PROFILE_UNTOUCHED_RETRY requeue), the requeued attempt with a
# still-untouched outfile is a hard FAIL. The stubs raise on the paths a
# correct run must not reach, so a miss surfaces as rc=1, not rc=4.
set rq_prompt_dir [file join $tmp_root prompt-rq]
file mkdir $rq_prompt_dir
set rq_outfile [file join $tmp_root profiles-rq rq-stem.md]
file mkdir [file dirname $rq_outfile]
set fd [open $rq_outfile w]
puts -nonewline $fd "---\nprofile_date: 2026-01-01\n---\nstale body\n"
close $fd
set fd [open [file join $rq_prompt_dir meta.env] w]
puts $fd "STEM=\"rq-stem\""
puts $fd "OUTFILE=\"$rq_outfile\""
puts $fd "ROSTER_PATH=\"/tmp/none/roster.tsv\""
close $fd

set ph3 [spar::ProfileHarness new $rq_prompt_dir [file join $tmp_root logs-rq]]
oo::objdefine $ph3 {
    method do_profile_call {} { return 0 }
    method session_id {} { return "rq-sess" }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { error "must not validate an untouched outfile" }
    method do_summary {} { error "must not reach DONE" }
}
set rc_rq [$ph3 run]
$ph3 destroy
assert_eq $rc_rq 4 "clean close with untouched pre-existing outfile returns rc=4"
assert_eq [file exists [file join $rq_prompt_dir retry.marker]] 1 \
    "retry marker written to the prompt dir"

set ph4 [spar::ProfileHarness new $rq_prompt_dir [file join $tmp_root logs-rq2]]
oo::objdefine $ph4 {
    method do_profile_call {} { return 0 }
    method session_id {} { return "rq-sess-2" }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { error "must not validate an untouched outfile" }
    method do_summary {} { error "must not reach DONE" }
}
set rc_rq2 [$ph4 run]
$ph4 destroy
assert_eq $rc_rq2 1 "second untouched close (marker present) is a hard FAIL"

# A run that rewrites the outfile proceeds to validation and DONE.
set ph5 [spar::ProfileHarness new $rq_prompt_dir [file join $tmp_root logs-rq3]]
set ::rq_validated 0
oo::objdefine $ph5 {
    method do_profile_call {} {
        my variable Outfile
        spar::write_file $Outfile "---\nprofile_date: 2026-07-21\n---\nfresh body\n"
        return 0
    }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { incr ::rq_validated; return 0 }
    method do_summary {} {}
}
set rc_rq3 [$ph5 run]
$ph5 destroy
assert_eq $rc_rq3 0 "a rewritten outfile passes through to validation and DONE"
assert_eq $::rq_validated 1 "validation ran for the rewritten outfile"

# No pre-existing outfile (the T1 shape): a clean close that wrote
# nothing keeps the missing_profile fix-loop path, not the requeue.
set t1_prompt_dir [file join $tmp_root prompt-t1]
file mkdir $t1_prompt_dir
set fd [open [file join $t1_prompt_dir meta.env] w]
puts $fd "STEM=\"t1-stem\""
puts $fd "OUTFILE=\"[file join $tmp_root profiles-rq t1-stem.md]\""
puts $fd "ROSTER_PATH=\"/tmp/none/roster.tsv\""
close $fd
set ph6 [spar::ProfileHarness new $t1_prompt_dir [file join $tmp_root logs-t1]]
set ::t1_validated 0
oo::objdefine $ph6 {
    method do_profile_call {} { return 0 }
    method sanitise_roster_email {rp slug} {}
    method validate_and_correct {o r s} { incr ::t1_validated; return 0 }
    method do_summary {} {}
}
set rc_t1 [$ph6 run]
$ph6 destroy
assert_eq $rc_t1 0 "no pre-existing outfile: run falls through to validation"
assert_eq $::t1_validated 1 "validation (missing_profile owner) ran for the T1 shape"

finish_tests

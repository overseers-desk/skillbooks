#!/usr/bin/env tclsh9.0
# Exercises the per-attempt wall-clock cap in spar::Harness::_invoke
# (#114). Two paths:
#   1. resolve_coreutil — finds `timeout` on Linux, `gtimeout` on macOS
#      (with coreutils installed). Returns "" when neither present.
#   2. _invoke wrap — when WorkerTimeoutSecs > 0, the wrapped exec exits
#      within the deadline with rc=1 and the harness log records
#      "timeout after Ns".
#
# The second test stubs `claude` by overriding spar::find_tool — the
# real claude binary on $PATH is not invoked. The stub sleeps past the
# deadline; if the wrap is working, timeout(1) sends SIGTERM at the
# deadline and the test passes well before the stub's natural exit.

package require TclOO
package require json
package require json::write
package require logger

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-harness.tcl]
source [file join $script_dir test-helpers.tcl]

# ════════════════════════════════════════════════════════════════════════
section "1. resolve_coreutil resolves timeout on this host"
# ════════════════════════════════════════════════════════════════════════

set timeout_bin [spar::resolve_coreutil timeout]
if {$timeout_bin eq ""} {
    puts "  skip: no `timeout` (or `gtimeout`) on PATH — coreutils not installed"
    puts "        install with: brew install coreutils  (macOS)"
    finish_tests
}
assert_match $timeout_bin "*timeout*" \
    "resolve_coreutil timeout returns a path containing 'timeout'"

# ════════════════════════════════════════════════════════════════════════
section "2. Wrapped _invoke exits within deadline on stuck claude"
# ════════════════════════════════════════════════════════════════════════

# Stub claude binary that sleeps past any reasonable deadline. The
# wrapped timeout(1) should SIGTERM it at the configured deadline.
set tmp_root [file join /tmp "spar-test-timeout-[pid]-[clock microseconds]"]
file mkdir $tmp_root
lappend ::cleanup_dirs $tmp_root

set stub_path [file join $tmp_root claude]
set fd [open $stub_path w]
puts $fd "#!/bin/sh"
puts $fd "sleep 30"
close $fd
file attributes $stub_path -permissions 0755

# Override spar::find_tool so _invoke picks up the stub instead of the
# real claude on PATH. auto_execok would otherwise resolve `claude` to
# whatever is installed system-wide.
proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::stub_path] }
    return [auto_execok $name]
}

set prompt_dir [file join $tmp_root prompt]
set log_dir    [file join $tmp_root logs]
file mkdir $prompt_dir
file mkdir $log_dir

set inst [spar::Harness new $prompt_dir $log_dir]
$inst set_worker_timeout 2

set log_file [file join $log_dir test.log]

set t0 [clock milliseconds]
set rc [$inst call "test-stage" $log_file "dummy prompt"]
set elapsed_ms [expr {[clock milliseconds] - $t0}]

$inst destroy

assert_eq $rc 1 "_invoke returns rc=1 when stub claude is killed by timeout"

# Stub sleeps 30s; deadline is 2s + 60s kill-after grace. SIGTERM should
# fire at ~2s and `sleep` exits promptly. Allow 8s to absorb CI jitter.
if {$elapsed_ms >= 8000} {
    puts "FAIL: timeout did not fire within budget"
    puts "  elapsed: ${elapsed_ms}ms (expected < 8000ms)"
    incr ::failures
} else {
    puts "  ok: timeout fired at ${elapsed_ms}ms (< 8000ms)"
    incr ::passes
}

# The harness log emits the FAIL line via logger; capture it from
# stderr would require fd redirection. Simpler: check the per-stage
# JSON file is empty/missing and the stderr file exists — together
# they prove the stub was killed mid-flight, not that it completed
# normally.
set json_file "${log_file}.json"
set stderr_file "${log_file}.stderr"
assert_eq [file exists $stderr_file] 1 "stderr file exists from killed exec"
set json_size 0
if {[file exists $json_file]} { set json_size [file size $json_file] }
assert_eq $json_size 0 "json file empty (claude was killed before output)"

# ════════════════════════════════════════════════════════════════════════
section "2b. Timeout after a complete envelope is a success (product over status)"
# ════════════════════════════════════════════════════════════════════════

# A stub that writes a complete JSON envelope, then sleeps past the
# deadline — modelling a session that finished its work just before the
# wall-clock kill landed (e.g. SIGTSTP past the deadline, SIGTERM on
# resume). timeout(1) exits 124, but the envelope is whole on disk, so
# _invoke must judge by the product and return success, not fail on the
# exit status.
set done_stub [file join $tmp_root claude-done]
set fd [open $done_stub w]
puts $fd "#!/bin/sh"
puts $fd {printf '%s' '{"result":"profile written","is_error":false,"total_cost_usd":0.01,"session_id":"done-sess"}'}
puts $fd "sleep 30"
close $fd
file attributes $done_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::done_stub] }
    return [auto_execok $name]
}

set log_file_done [file join $log_dir test-done.log]
set inst_done [spar::Harness new $prompt_dir [file join $tmp_root logs-done]]
$inst_done set_worker_timeout 2

set t0 [clock milliseconds]
set rc_done [$inst_done call "test-stage" $log_file_done "dummy prompt"]
set elapsed_done [expr {[clock milliseconds] - $t0}]
set sid_done [$inst_done session_id]
$inst_done destroy

assert_eq $rc_done 0 "_invoke returns rc=0 when the envelope was written before the timeout kill"

# The kill still fires at ~2s (the stub would otherwise sleep 30s), so a
# prompt return proves the envelope was recovered rather than the call
# blocking on the stub's natural exit.
if {$elapsed_done >= 8000} {
    puts "FAIL: timeout did not fire within budget"
    puts "  elapsed: ${elapsed_done}ms (expected < 8000ms)"
    incr ::failures
} else {
    puts "  ok: success recovered, kill fired at ${elapsed_done}ms (< 8000ms)"
    incr ::passes
}

# The harness extracted result into the log file and the session id from
# the envelope — the markers of a processed success.
assert_eq [file exists $log_file_done] 1 "result file written from recovered envelope"
assert_eq $sid_done "done-sess" "session id captured from recovered envelope"

# ════════════════════════════════════════════════════════════════════════
section "3. Escape hatch: WorkerTimeoutSecs=0 does not wrap"
# ════════════════════════════════════════════════════════════════════════

# With timeout=0, the wrap is not prepended. The stub claude still
# fails the call (no JSON output), but elapsed time should reflect a
# different code path (no SIGTERM at 2s). We can't easily wait 30s, so
# use a fast-exit stub for this leg.

set fast_stub [file join $tmp_root claude-fast]
set fd [open $fast_stub w]
puts $fd "#!/bin/sh"
puts $fd "exit 0"
close $fd
file attributes $fast_stub -permissions 0755

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::fast_stub] }
    return [auto_execok $name]
}

set log_file2 [file join $log_dir test2.log]
set inst2 [spar::Harness new $prompt_dir [file join $tmp_root logs2]]
# Do not call set_worker_timeout — default 0.

set t0 [clock milliseconds]
set rc2 [$inst2 call "test-stage" $log_file2 "dummy"]
set elapsed2 [expr {[clock milliseconds] - $t0}]
$inst2 destroy

# rc=1 because the stub produces no JSON; the point is that the call
# returned promptly (no timeout binary was invoked).
assert_eq $rc2 1 "escape hatch: rc=1 from missing JSON, not from timeout"
if {$elapsed2 >= 5000} {
    puts "FAIL: escape hatch call took too long"
    puts "  elapsed: ${elapsed2}ms"
    incr ::failures
} else {
    puts "  ok: escape hatch elapsed=${elapsed2}ms (< 5000ms)"
    incr ::passes
}

# ════════════════════════════════════════════════════════════════════════
section "4. meta.env carrier: constructor reads WORKER_TIMEOUT_SECS"
# ════════════════════════════════════════════════════════════════════════

# Production path: _prepare_segment / _build_prompts write
# WORKER_TIMEOUT_SECS into the prompt dir's meta.env. The harness
# constructor reads it — no set_worker_timeout call. This is what every
# dispatch path (run, prepare_for_pool, GUI) relies on, since they all
# build prompt dirs through the same prep functions.

proc spar::find_tool {name} {
    if {$name eq "claude"} { return [list $::stub_path] }
    return [auto_execok $name]
}

set meta_prompt_dir [file join $tmp_root prompt-meta]
file mkdir $meta_prompt_dir
set fd [open [file join $meta_prompt_dir meta.env] w]
puts $fd "STEM=\"meta-row\""
puts $fd "WORKER_TIMEOUT_SECS=\"2\""
close $fd

set inst3 [spar::Harness new $meta_prompt_dir [file join $tmp_root logs3]]
# Deliberately NO set_worker_timeout — the value must come from meta.env.

set log_file3 [file join $tmp_root logs3 test3.log]
set t0 [clock milliseconds]
set rc3 [$inst3 call "test-stage" $log_file3 "dummy prompt"]
set elapsed3 [expr {[clock milliseconds] - $t0}]
$inst3 destroy

assert_eq $rc3 1 "meta.env: rc=1 when stub killed by timeout read from meta.env"
if {$elapsed3 >= 8000} {
    puts "FAIL: meta.env-driven timeout did not fire within budget"
    puts "  elapsed: ${elapsed3}ms (expected < 8000ms)"
    incr ::failures
} else {
    puts "  ok: meta.env-driven timeout fired at ${elapsed3}ms (< 8000ms)"
    incr ::passes
}

finish_tests

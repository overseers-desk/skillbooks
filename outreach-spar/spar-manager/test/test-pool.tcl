#!/usr/bin/env tclsh9.0
# Tests for spar::Dispatcher (the shared job pool) and the state-machine
# enforcement it inherits from jobloop.
#
# Strategy: drive the Dispatcher with fake_worker coroutine jobs that run
# scripted report sequences. No real claude / SES / IMAP calls. The
# fake_worker proc is defined in spar-dispatcher-initcmd.tcl alongside the
# production worker procs, sourced into this interpreter by
# spar-dispatcher.tcl.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

# spar-dispatcher.tcl needs spar-state.tcl in scope for spar::update_roster_field
# (called by on_roster_update). Source it so the file loads cleanly.
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-dispatcher.tcl]

set ::log_messages {}
proc test_log {msg} { lappend ::log_messages $msg }

# wait_for — poll a script returning a boolean until true or timeout.
# Pumps the event loop so async on_* messages land.
proc wait_for {script {timeout_ms 5000}} {
    set deadline [expr {[clock milliseconds] + $timeout_ms}]
    while {[clock milliseconds] < $deadline} {
        if {[uplevel 1 $script]} { return 1 }
        set ::tick 0
        after 20 set ::tick 1
        vwait ::tick
    }
    return 0
}

proc wait_for_state {dispatcher row state {timeout_ms 5000}} {
    return [wait_for [list expr {[$dispatcher state $row] eq $state}] \
        $timeout_ms]
}

proc wait_for_terminal {dispatcher row {timeout_ms 5000}} {
    return [wait_for [list expr {[$dispatcher state $row] in {done failed cancelled}}] \
        $timeout_ms]
}

# ════════════════════════════════════════════════════════════════════════
# 1. No marshalling layer - the worker file crosses no thread
# ════════════════════════════════════════════════════════════════════════
# jobloop runs each job as a coroutine on the main thread, so the worker
# file carries no thread::send, no tsv sentinel, and no msg_* bridge procs:
# a worker reports through the jobloop verbs (checkpoint/done/failed/...).
# Guard against the marshalling layer creeping back, and confirm the
# spar-domain reports still land on matching on_* methods.
section "1. No marshalling layer"

set initcmd_path [file join $script_dir .. spar-dispatcher-initcmd.tcl]
set fd [open $initcmd_path r]; set initcmd_src [read $fd]; close $fd
assert_eq [regexp {thread::send} $initcmd_src] 0 \
    "worker file has no thread::send"
assert_eq [regexp {tsv::} $initcmd_src] 0 \
    "worker file has no tsv sentinel"
set msg_names {}
foreach line [split $initcmd_src \n] {
    if {[regexp {^proc\s+(msg_[a-z_]+)\s} $line -> name]} {
        lappend msg_names $name
    }
}
assert_eq $msg_names {} "no msg_* marshalling procs remain"

set methods [info class methods spar::Dispatcher -all]
foreach on {on_cost on_retry on_credit_warning on_roster_update} {
    assert_eq [expr {$on in $methods}] 1 "Dispatcher carries $on"
}

# ════════════════════════════════════════════════════════════════════════
# 2. Basic dispatch — enqueue a row, fake_worker runs it, reaches done
# ════════════════════════════════════════════════════════════════════════
section "2. Basic dispatch"

set d [spar::Dispatcher new 4 test_log]
$d pause_queue
$d enqueue r1 fake_worker {plan {{sleep 50}}}
assert_eq [$d state r1] queued "r1 starts queued (queue paused)"

# Resume; the post happens immediately and the state flips to running
$d resume_queue
assert_eq [$d state r1] running "r1 transitions to running at post time"

wait_for_terminal $d r1 3000
assert_eq [$d state r1] done "r1 reaches done"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 3. Concurrency cap — Jobs=2, enqueue 4, only 2 run concurrently
# ════════════════════════════════════════════════════════════════════════
section "3. Concurrency cap"

set d [spar::Dispatcher new 2 test_log]
foreach r {r1 r2 r3 r4} {
    $d enqueue $r fake_worker {plan {{sleep 200}}}
}

# State flips to running at launch time (before the coroutine starts), so
# the snapshot is deterministic the moment all enqueues have returned.
assert_eq [llength [$d active_jobs]] 2 "Jobs=2 caps active at 2"
assert_eq [llength [$d queued_jobs]] 2 "remaining 2 stay queued"

foreach r {r1 r2 r3 r4} { wait_for_terminal $d $r 5000 }
foreach r {r1 r2 r3 r4} {
    assert_eq [$d state $r] done "$r eventually reaches done"
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 4. Queue pause/resume — paused queue does not post new
# ════════════════════════════════════════════════════════════════════════
section "4. Queue pause/resume"

set d [spar::Dispatcher new 2 test_log]
$d pause_queue
foreach r {r1 r2 r3} {
    $d enqueue $r fake_worker {plan {{sleep 30}}}
}
set ::tick 0; after 50 set ::tick 1; vwait ::tick
foreach r {r1 r2 r3} {
    assert_eq [$d state $r] queued "$r stays queued while pause_queue is set"
}

$d resume_queue
foreach r {r1 r2 r3} { wait_for_terminal $d $r 3000 }
foreach r {r1 r2 r3} {
    assert_eq [$d state $r] done "$r drains after resume_queue"
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 5. Cancel a queued row — drops before posting
# ════════════════════════════════════════════════════════════════════════
section "5. Cancel queued"

set d [spar::Dispatcher new 1 test_log]
# Block worker slot with a long-running row
$d enqueue r1 fake_worker {plan {{sleep 300}}}
$d enqueue r2 fake_worker {plan {{sleep 30}}}
wait_for_state $d r1 running 1000
assert_eq [$d state r2] queued "r2 queued behind r1"

$d cancel r2
assert_eq [$d state r2] cancelled "queued r2 cancels immediately"

wait_for_terminal $d r1 1000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 6. Cancel a running row — sentinel, worker observes, emits cancelled
# ════════════════════════════════════════════════════════════════════════
section "6. Cancel running"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 fake_worker \
    {plan {{sleep 50} {check_cancel} {sleep 50} {check_cancel}}}
wait_for_state $d r1 running 1000
$d cancel r1
wait_for_terminal $d r1 2000
assert_eq [$d state r1] cancelled "running r1 cancels via sentinel"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 7. Pause/resume a running row — sentinel pause, then resume → done
# ════════════════════════════════════════════════════════════════════════
section "7. Pause and resume row"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 fake_worker \
    {plan {{sleep 50} {check_pause 30} {sleep 30}}}
wait_for_state $d r1 running 1000
$d pause_job r1
wait_for_state $d r1 paused 2000
assert_eq [$d state r1] paused "r1 reaches paused via sentinel"
$d resume_job r1
wait_for_terminal $d r1 2000
assert_eq [$d state r1] done "r1 resumes and reaches done"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 8. State-machine validation — out-of-order messages logged and dropped
# ════════════════════════════════════════════════════════════════════════
section "8. State-machine validation"

set d [spar::Dispatcher new 1 test_log]
set ::log_messages {}
$d on_phase nonexistent_row foo
assert_match [join $::log_messages " "] "*phase for unknown job nonexistent_row*" \
    "on_phase for unknown row is logged"

# Register a queued row (queue paused so it does not auto-post), then
# send on_done — should be logged + dropped because the row never
# transitioned to running.
$d pause_queue
$d enqueue r1 fake_worker {plan {{sleep 200}}}
set ::log_messages {}
$d on_done r1 {}
assert_match [join $::log_messages " "] "*done for job r1 in state queued*" \
    "on_done for queued row is logged and dropped"
assert_eq [$d state r1] queued "r1 still queued after illegal on_done"

$d resume_queue
wait_for_terminal $d r1 1000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 9. count_by_kind — across heterogeneous rows
# ════════════════════════════════════════════════════════════════════════
section "9. count_by_kind"

set d [spar::Dispatcher new 4 test_log]
$d enqueue a1 fake_worker_a {plan {{sleep 30}}}
$d enqueue a2 fake_worker_a {plan {{sleep 30}}}
$d enqueue b1 fake_worker_b {plan {{sleep 30}}}
$d enqueue b2 fake_worker_b {plan {{sleep 30}}}
$d enqueue b3 fake_worker_b {plan {{sleep 30}}}
foreach r {a1 a2 b1 b2 b3} { wait_for_terminal $d $r 3000 }
assert_eq [$d count_by_kind fake_worker_a done] 2 "fake_worker_a done count = 2"
assert_eq [$d count_by_kind fake_worker_b done] 3 "fake_worker_b done count = 3"
assert_eq [$d count_by_kind fake_worker_a failed] 0 "fake_worker_a failed count = 0"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 10. Rate-limited cycle — running → rate_limited → running → done
# ════════════════════════════════════════════════════════════════════════
section "10. Rate-limited cycle"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 fake_worker [list plan [list \
    [list sleep 30] \
    [list msg_rate_limited [clock seconds]] \
    [list sleep 30] \
    [list msg_rate_limit_cleared] \
    [list sleep 30]]]
wait_for_state $d r1 rate_limited 2000
assert_eq [$d state r1] rate_limited "r1 enters rate_limited"
wait_for_state $d r1 running 2000
assert_eq [$d state r1] running "r1 returns to running after cleared"
wait_for_terminal $d r1 2000
assert_eq [$d state r1] done "r1 reaches done after rate-limit cycle"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 11. Requeue — terminal row goes back to queued and re-runs
# ════════════════════════════════════════════════════════════════════════
section "11. Requeue"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 fake_worker {plan {{msg_failed boom}}}
wait_for_terminal $d r1 2000
assert_eq [$d state r1] failed "r1 fails first time"

$d pause_queue
$d requeue r1
assert_eq [$d state r1] queued "requeued r1 is queued (queue paused)"
$d resume_queue
wait_for_terminal $d r1 2000
assert_eq [$d state r1] failed "r1 fails again on rerun (same plan)"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 12. active_jobs — excludes terminal
# ════════════════════════════════════════════════════════════════════════
section "12. active_jobs"

set d [spar::Dispatcher new 4 test_log]
$d enqueue r1 fake_worker {plan {{sleep 30}}}
$d enqueue r2 fake_worker {plan {{msg_failed nope}}}
$d enqueue r3 fake_worker {plan {{sleep 200}}}
wait_for_terminal $d r2 2000
wait_for_terminal $d r1 2000
# r3 still running (200ms vs 30ms others)
set active [$d active_jobs]
assert_eq [llength $active] 1 "only r3 still active"
assert_eq [lindex $active 0] r3 "active row is r3"
wait_for_terminal $d r3 2000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 13. harness_run — wires through to a harness_class instance
# ════════════════════════════════════════════════════════════════════════
# The real spar::ProfileHarness / spar::ApproachHarness needs claude on
# PATH plus a fully-built prompt_dir (prompt.txt, meta.env, roster, etc.)
# to exercise end-to-end. That is heavier than this test wants. Instead
# we instantiate FakeHarness — a stand-in defined alongside fake_worker
# in spar-dispatcher-initcmd.tcl that mimics the (prompt_dir log_dir)
# constructor and the run-returns-0/1 contract — to verify only the
# routing path: enqueue → coroutine → harness_run → done/failed.
# Coverage of the real harness body lives in test-state.tcl /
# test-validate-*; this section catches breakage in the worker wrapper.
section "13. harness_run routing"

set tmp_root [file join /tmp "spar-pool-harness-[pid]-[clock microseconds]"]
file mkdir $tmp_root
lappend ::cleanup_dirs $tmp_root

proc make_harness_dirs {tag {rc 0} {cause ""}} {
    set p [file join $::tmp_root "$tag-prompt"]
    set l [file join $::tmp_root "$tag-log"]
    file mkdir $p $l
    if {$rc ne ""} {
        set fd [open [file join $p run-rc] w]; puts -nonewline $fd $rc; close $fd
    }
    if {$cause ne ""} {
        set fd [open [file join $p run-cause] w]; puts -nonewline $fd $cause; close $fd
    }
    return [list $p $l]
}

set d [spar::Dispatcher new 2 test_log]

# 13a. Successful harness run reaches done with rc=0 in the result dict.
lassign [make_harness_dirs ok 0] p_ok l_ok
$d enqueue h_ok harness_run [dict create \
    prompt_dir $p_ok log_dir $l_ok harness_class FakeHarness]
wait_for_terminal $d h_ok 3000
assert_eq [$d state h_ok] done "harness_run rc=0 reaches done"

# 13b. Harness rc=1 lands as failed with the rc message.
lassign [make_harness_dirs fail 1] p_f l_f
$d enqueue h_fail harness_run [dict create \
    prompt_dir $p_f log_dir $l_f harness_class FakeHarness]
wait_for_terminal $d h_fail 3000
assert_eq [$d state h_fail] failed "harness_run rc=1 reaches failed"

# 13c. Harness raising an error is caught and surfaced as failed.
lassign [make_harness_dirs throw throw] p_t l_t
$d enqueue h_throw harness_run [dict create \
    prompt_dir $p_t log_dir $l_t harness_class FakeHarness]
wait_for_terminal $d h_throw 3000
assert_eq [$d state h_throw] failed "harness_run catches errors as failed"

# 13e. The harness FAIL cause reaches the failure reason for the roll-call
# (#148): harness_run reads fail_cause when rc!=0 and folds it into the reason,
# so a real enqueue→harness_run→job-failed round trip carries the cause an
# operator needs, not just "rc=1". Render it through spar::render_rollcall to
# prove the run-end worklist is built from the live event, end to end.
set ::_rc_reason ""
$d subscribe job-failed [list apply {{row reason} { set ::_rc_reason $reason }}]
lassign [make_harness_dirs cause 1 "FAIL (T2: stalled — no output): cause-prompt"] p_c l_c
$d enqueue h_cause harness_run [dict create \
    prompt_dir $p_c log_dir $l_c harness_class FakeHarness]
wait_for_terminal $d h_cause 3000
assert_match $::_rc_reason "*rc=1*FAIL (T2: stalled*" \
    "harness_run folds fail_cause into the failure reason"
set rc_line [spar::render_rollcall \
    [list [dict create slug h_cause tid T2 outcome failed reason $::_rc_reason]]]
assert_match $rc_line "*h_cause*\[T2\]*rc=1*stalled*" \
    "render_rollcall builds the worklist line from the live failure reason"

# 13d. Cancel before the worker enters the harness body: the row is
# cancelled while still queued (before resume_queue launches it), so it
# never reaches a coroutine.
lassign [make_harness_dirs precancel 0] p_pc l_pc
$d pause_queue
$d enqueue h_pc harness_run [dict create \
    prompt_dir $p_pc log_dir $l_pc harness_class FakeHarness]
$d cancel h_pc
assert_eq [$d state h_pc] cancelled \
    "cancel before post drops the row without invoking the harness"
$d resume_queue

# 13e. Dry-run skips the harness body entirely. The row's run-rc is
# "throw", so the FakeHarness would fail if it ran; under dry_run=1
# harness_run short-circuits to msg_done before instantiating the
# harness, so the row still reaches done. Proves --dry-run authors
# nothing and writes no output file.
lassign [make_harness_dirs dryrun throw] p_dr l_dr
$d enqueue h_dr harness_run [dict create \
    prompt_dir $p_dr log_dir $l_dr dry_run 1 harness_class FakeHarness]
wait_for_terminal $d h_dr 3000
assert_eq [$d state h_dr] done \
    "dry_run short-circuits harness_run to done without running the harness"

$d destroy

# ════════════════════════════════════════════════════════════════════════
# 14. ses_send — happy path through a fake smtp_send helper
# ════════════════════════════════════════════════════════════════════════
# The worker shells out to smtp_send.tcl. We override the helper path
# in opts so tests don't open a real TLS socket. The fake helper just
# echoes a fixed message-id on stdout — enough to verify the wiring:
# enqueue → ses_send → ses::send_one → exec helper → msg_done with the
# id in the result dict, and that the approach YAML's actioned_date is
# stamped on success.
section "14. ses_send happy path"

# Fake smtp_send: takes a params file and prints a deterministic id.
set fake_smtp [file join $tmp_root fake-smtp_send.tcl]
set fd [open $fake_smtp w]
puts $fd "#!/usr/bin/env tclsh9.0"
puts $fd "puts FAKE-MID-12345"
puts $fd "exit 0"
close $fd
file attributes $fake_smtp -permissions 0o755

# Approach YAML with one final-round email message, unsent.
set seg_dir [file join $tmp_root "seg-ses"]
file mkdir [file join $seg_dir approach]
set approach_yaml {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: dest@acme-venues.au
    subject: Hi
    body: Hello there
    actioned_date: null
    replied_date: null
}
set approach_path [file join $seg_dir approach "alice.yaml"]
set fd [open $approach_path w]; puts -nonewline $fd $approach_yaml; close $fd

set ses_opts [dict create \
    campaign_file "" \
    approach_path $approach_path \
    sender [dict create \
        name      "Sender Name" \
        email     "me@acme-venues.au" \
        smtp_host "smtp.example.com" \
        smtp_port 587 \
        smtp_user "me@acme-venues.au" \
        bcc       ""] \
    dry_run 0 \
    smtp_helper $fake_smtp \
    today "2026-04-28"]

# Pre-cache an SMTP password in the keychain stand-in via cdata
# fallback. ses::send_one's keychain lookup will fail (test host has
# no entry for smtp.example.com); the cdata fallback in
# spar::smtp_credentials lifts sender.smtp_pass when present.
dict set ses_opts sender smtp_pass "fake-pass"

set d [spar::Dispatcher new 2 test_log]
$d enqueue alice ses_send $ses_opts
wait_for_terminal $d alice 5000
assert_eq [$d state alice] done "ses_send happy path reaches done"

# actioned_date should now be stamped in the YAML.
set fd [open $approach_path r]; set after [read $fd]; close $fd
assert_match $after "*actioned_date: 2026-04-28*" \
    "ses_send stamps actioned_date on success"

$d destroy

# 14b. ses_send dry-run does not invoke the helper and does not stamp.
set seg_dir2 [file join $tmp_root "seg-ses-dry"]
file mkdir [file join $seg_dir2 approach]
set approach_path2 [file join $seg_dir2 approach "bob.yaml"]
set fd [open $approach_path2 w]; puts -nonewline $fd $approach_yaml; close $fd

set dry_opts [dict replace $ses_opts \
    approach_path $approach_path2 dry_run 1]

set d [spar::Dispatcher new 2 test_log]
$d enqueue bob ses_send $dry_opts
wait_for_terminal $d bob 5000
assert_eq [$d state bob] done "ses_send dry-run reaches done"
set fd [open $approach_path2 r]; set after2 [read $fd]; close $fd
assert_match $after2 "*actioned_date: null*" \
    "ses_send dry-run leaves actioned_date null"
$d destroy

# 14c. ses_send failure when the approach file is missing.
set d [spar::Dispatcher new 2 test_log]
set bad_opts [dict replace $ses_opts approach_path /nonexistent/path.yaml]
$d enqueue ghost ses_send $bad_opts
wait_for_terminal $d ghost 5000
assert_eq [$d state ghost] failed "ses_send fails when approach missing"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 14d. imap_poll — happy path through a fake courier helper
# ════════════════════════════════════════════════════════════════════════
# The worker shells out to courier. We override courier_bin in opts
# to point at a fake script that returns canned JSON for both `search`
# and `read`. The fake script branches on its first positional arg
# after "--imap <account>" to mimic the real courier CLI.
section "14d. imap_poll happy path"

set fake_courier [file join $tmp_root fake-courier.tcl]
set fd [open $fake_courier w]
puts $fd {#!/usr/bin/env tclsh9.0
# Args: --imap <account> (search|read) -f <folder> ...
# Emit canned JSON for the two subcommands. Drop --imap/-f flags.
set positional {}
for {set i 0} {$i < [llength $argv]} {incr i} {
    set a [lindex $argv $i]
    if {$a in {--imap -f -u --limit}} { incr i; continue }
    lappend positional $a
}
set op [lindex $positional 0]
if {$op eq "search"} {
    puts {{"search": {"acct": {"results": [{"uid": "U1", "from": "Dest <dest@acme-venues.au>", "to": ["Me <me@acme-venues.au>"], "cc": [], "date": "2026-04-25T10:00:00"}], "provenance": {}}}}}
} elseif {$op eq "read"} {
    puts {{"read": {"acct": {"body": "Hello back from Dest", "from": "dest@acme-venues.au", "to": ["me@acme-venues.au"], "date": "2026-04-25T10:00:00"}}}}
}
exit 0
}
close $fd
file attributes $fake_courier -permissions 0o755

set seg_dir3 [file join $tmp_root "seg-imap"]
file mkdir [file join $seg_dir3 approach]
set approach_yaml_sent {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: dest@acme-venues.au
    subject: Hi
    body: Hello there
    actioned_date: 2026-04-20
    replied_date: null
}
set approach_path3 [file join $seg_dir3 approach "carol.yaml"]
set fd [open $approach_path3 w]; puts -nonewline $fd $approach_yaml_sent; close $fd

set imap_opts [dict create \
    approach_path $approach_path3 \
    to_email      "dest@acme-venues.au" \
    fingerprints  {} \
    account       "acct" \
    folder        "INBOX" \
    sender        "me@acme-venues.au" \
    dry_run       0 \
    courier_bin   $fake_courier]

set d [spar::Dispatcher new 2 test_log]
$d enqueue carol imap_poll $imap_opts
wait_for_terminal $d carol 5000
assert_eq [$d state carol] done "imap_poll happy path reaches done"

# The reply should have been appended to the YAML.
set fd [open $approach_path3 r]; set after3 [read $fd]; close $fd
assert_match $after3 "*Hello back from Dest*" \
    "imap_poll appends reply body to approach YAML"
$d destroy

# 14f. imap_poll with a since floor after the message date: inbox
# history predating the send is not a reply; no append.
set seg_dir3f [file join $tmp_root "seg-imap-floor"]
file mkdir [file join $seg_dir3f approach]
set approach_path3f [file join $seg_dir3f approach "cass.yaml"]
set fd [open $approach_path3f w]; puts -nonewline $fd $approach_yaml_sent; close $fd

set floor_opts [dict replace $imap_opts \
    approach_path $approach_path3f \
    since         "2026-04-26"]

set d [spar::Dispatcher new 2 test_log]
$d enqueue cass imap_poll $floor_opts
wait_for_terminal $d cass 5000
assert_eq [$d state cass] done "imap_poll with future floor reaches done"
set fd [open $approach_path3f r]; set after3f [read $fd]; close $fd
assert_eq [string match "*Hello back from Dest*" $after3f] 0 \
    "message before the since floor is not appended"
$d destroy

# 14e. imap_poll with already-recorded fingerprint: no append.
set seg_dir4 [file join $tmp_root "seg-imap-known"]
file mkdir [file join $seg_dir4 approach]
set approach_path4 [file join $seg_dir4 approach "dan.yaml"]
set fd [open $approach_path4 w]; puts -nonewline $fd $approach_yaml_sent; close $fd

set known_opts [dict replace $imap_opts \
    approach_path $approach_path4 \
    fingerprints  [list "dest@acme-venues.au|2026-04-25T10:00:00"]]

set d [spar::Dispatcher new 2 test_log]
$d enqueue dan imap_poll $known_opts
wait_for_terminal $d dan 5000
assert_eq [$d state dan] done "imap_poll done when nothing new"
set fd [open $approach_path4 r]; set after4 [read $fd]; close $fd
# The reply body should NOT have been appended.
if {[string first "Hello back from Dest" $after4] >= 0} {
    puts "FAIL: imap_poll appended reply despite fingerprint match"
    incr ::failures
} else {
    puts "  ok: imap_poll skips already-fingerprinted reply"
    incr ::passes
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 15. prune_missing — drops state for stems no longer in the tree
# ════════════════════════════════════════════════════════════════════════
# Workspace refresh case: the Pool outlives the tree. After refresh,
# stems that disappeared (removed contacts, segment churn) should be
# garbage-collected from the Pool's state map. Active workers must
# survive the prune even if the new tree happens not to list them
# (race: refresh while a row is in flight).
section "15. prune_missing"

# Pool with cap 1: a single running blocker keeps the next enqueue
# stuck in queued, deterministically.
set d [spar::Dispatcher new 1 test_log]

# Two terminal rows that finish before the blocker arrives.
$d enqueue done1 fake_worker {plan {{sleep 30}}}
wait_for_terminal $d done1 2000
$d enqueue fail1 fake_worker {plan {{msg_failed boom}}}
wait_for_terminal $d fail1 2000

# Long-running blocker, then a queued row that cannot post.
$d enqueue running1 fake_worker {plan {{sleep 600}}}
wait_for_state $d running1 running 1000
$d enqueue queued1 fake_worker {plan {{sleep 30}}}
assert_eq [$d state queued1] queued "queued1 stays queued behind running1"

# Refresh: tree now contains only running1 + a fresh stem the Pool
# never heard of. done1, fail1, queued1 should be dropped; running1
# survives even though its stem is absent from the prune list (the
# active-state guard protects it).
set kept [$d prune_missing [list fresh_stem]]
assert_eq $kept 3 "prune drops 3 non-active rows"
assert_eq [$d state done1]   "" "done1 dropped from state map"
assert_eq [$d state fail1]   "" "fail1 dropped from state map"
assert_eq [$d state queued1] "" "queued1 dropped from state map"
assert_eq [$d state running1] running "running1 survives prune"

# Verify the Queue list itself was scrubbed: enqueue a fresh row and
# confirm it is the only queued entry (not stuck behind a ghost).
$d pause_queue
$d enqueue post_prune fake_worker {plan {{sleep 30}}}
assert_eq [$d queued_jobs] [list post_prune] \
    "Queue list scrubbed of pruned stems"
$d resume_queue
wait_for_terminal $d post_prune 2000
wait_for_terminal $d running1   2000

$d destroy

# ════════════════════════════════════════════════════════════════════════
# 17. Concurrent I/O waits overlap
# ════════════════════════════════════════════════════════════════════════
#
# jobloop's concurrency is overlapping I/O waits, not parallel CPU: N
# coroutines each parked on a subprocess or a timer all make progress
# together on the one event loop. This test enqueues four rows, each
# running a real `sleep` child through spar::pool_exec (the same async
# subprocess path the production harness's claude runs through) and
# asserts wall time is roughly one sleep duration (overlapped) rather than
# four (serial). A body that blocked the loop on its child would serialise
# the four and fail the bound.
section "17. Concurrent I/O waits overlap"

set d [spar::Dispatcher new 4 test_log]
set t0 [clock milliseconds]
foreach r {p1 p2 p3 p4} {
    $d enqueue $r fake_worker {plan {{exec_sleep 2}}}
}
foreach r {p1 p2 p3 p4} { wait_for_terminal $d $r 12000 }
set elapsed [expr {[clock milliseconds] - $t0}]
foreach r {p1 p2 p3 p4} {
    assert_eq [$d state $r] done "$r reaches done"
}
# Four 2-second sleeps overlapped ≈ 2s; in series ≈ 8s. Allow
# generous slack for coroutine and subprocess startup and OS scheduling.
if {$elapsed < 4500} {
    puts "  ok: 4×exec_sleep 2s ran in parallel (elapsed=${elapsed}ms)"
    incr ::passes
} else {
    puts "FAIL: 4×exec_sleep 2s ran serially (elapsed=${elapsed}ms; expected <4500ms)"
    incr ::failures
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 18. Per-worker cap — distinct worker_proc names get distinct caps
# ════════════════════════════════════════════════════════════════════════
#
# A unified Dispatcher must let one transition kind run serially (SES,
# rate-limit pacing) while others run in parallel inside the same pool.
# set_kind_cap installs a per-worker-proc cap that further constrains
# the global Jobs cap; rows for that worker_proc cannot exceed it even
# when the global cap has slack.
#
# This test enqueues 4 fake_worker_a rows and 4 fake_worker_b rows into
# a pool of 8. set_kind_cap fake_worker_a 1 forces the four a-rows to
# serialise; fake_worker_b is uncapped (4 in parallel under jobs=8).
#
# Wall time signature: a-rows take 4×2s=~8s sequentially; b-rows take
# ~2s in parallel. Overall ~8s wall, dominated by the serialised side.
# Without set_kind_cap, both groups parallelise and the total drops
# to ~2s.
section "18. Per-worker cap"

set d [spar::Dispatcher new 8 test_log]
$d set_kind_cap fake_worker_a 1
set t0 [clock milliseconds]
foreach r {a1 a2 a3 a4} {
    $d enqueue $r fake_worker_a {plan {{exec_sleep 2}}}
}
foreach r {b1 b2 b3 b4} {
    $d enqueue $r fake_worker_b {plan {{exec_sleep 2}}}
}
foreach r {a1 a2 a3 a4 b1 b2 b3 b4} { wait_for_terminal $d $r 20000 }
set elapsed [expr {[clock milliseconds] - $t0}]
foreach r {a1 a2 a3 a4 b1 b2 b3 b4} {
    assert_eq [$d state $r] done "$r reaches done"
}
# fake_worker_a's 4×2s serialised ≈ 8s; fake_worker_b's 4×2s parallel ≈ 2s.
# Overall wall time should be near max(8s, 2s) = 8s. Without per-kind
# caps the test would finish in ~2s (everything overlapped under cap=8).
# Allow generous slack for coroutine and subprocess startup and OS scheduling.
if {$elapsed > 6500 && $elapsed < 12000} {
    puts "  ok: per-worker cap enforces serial fake_worker_a (elapsed=${elapsed}ms)"
    incr ::passes
} else {
    puts "FAIL: per-worker cap not enforced (elapsed=${elapsed}ms; expected 6500–12000ms)"
    incr ::failures
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 19. Fill to N at the start and refill the instant a slot frees
# ════════════════════════════════════════════════════════════════════════
#
# Regression guard for #138: a --jobs=N run must keep all N slots busy
# while the queue has work — fill to N at the start, and the moment one
# row finishes, post the next, not wait for a wave to drain. §17 proved
# four rows run in parallel; this proves the fill holds when the queue is
# several times the cap and rows free their slots one at a time.
#
# Setup: jobs=4, sixteen rows, each a real blocking exec_sleep 1s. With
# the pool kept full the sixteen rows clear in four waves ≈ 4s. If the
# dispatcher posted a short first wave or refilled only per-wave (the
# bug), wall time stretches toward serial. The bound rejects anything
# slower than ~one extra wave of slack.
section "19. Fill to N and refill on free"

set JOBS 4
set NROWS 16
set d [spar::Dispatcher new $JOBS test_log]

# Post-time fill: with the queue paused, enqueue all rows, then resume.
# The single _try_post_next on resume must post exactly JOBS rows (fill
# the pool in one pass), not a partial wave.
$d pause_queue
for {set i 1} {$i <= $NROWS} {incr i} {
    $d enqueue f$i fake_worker {plan {{exec_sleep 1}}}
}
$d resume_queue
assert_eq [llength [$d active_jobs]] $JOBS \
    "resume launches exactly JOBS=$JOBS rows in the first fill pass"
assert_eq [llength [$d queued_jobs]] [expr {$NROWS - $JOBS}] \
    "the rest stay queued behind the first fill"

# Refill-to-cap holds: sample the active count repeatedly while the queue
# drains; it must stay pinned at JOBS until fewer than JOBS rows remain.
set t0 [clock milliseconds]
set saw_below_cap_with_queue 0
while {1} {
    set posted [llength [$d active_jobs]]
    set queued [llength [$d queued_jobs]]
    set terminal 0
    foreach r [$d all_jobs] {
        if {[$d state $r] in {done failed cancelled}} { incr terminal }
    }
    if {$terminal >= $NROWS} break
    # While work remains to fill every slot, the pool must read full.
    if {$queued > 0 && $posted < $JOBS} { set saw_below_cap_with_queue 1 }
    if {[clock milliseconds] - $t0 > 30000} break
    set ::tick 0; after 40 set ::tick 1; vwait ::tick
}
set elapsed [expr {[clock milliseconds] - $t0}]
foreach r [$d all_jobs] {
    assert_eq [$d state $r] done "[set r] reaches done"
}
assert_eq $saw_below_cap_with_queue 0 \
    "pool never drops below JOBS while rows wait in the queue"
# 16 rows / 4 slots × 1s = 4 waves ≈ 4s. Generous slack for coroutine
# and subprocess startup and OS scheduling; a partial-fill /
# per-wave-refill bug runs far slower.
if {$elapsed < 8000} {
    puts "  ok: 16 rows over 4 slots stayed full (elapsed=${elapsed}ms)"
    incr ::passes
} else {
    puts "FAIL: pool under-filled — 16/4 took ${elapsed}ms (expected <8000ms)"
    incr ::failures
}
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 20. A worker that dies without a terminal message frees its slot (#138)
# ════════════════════════════════════════════════════════════════════════
#
# Root cause of #138: a worker owns its slot until it reports a terminal
# verb (done / failed / cancelled). A body that returns by raising, before
# any terminal verb, would strand the row in `running` forever; active_jobs
# keeps counting it against the cap, so the slot reads occupied while no job
# runs, and a few of these collapse a --jobs=N pool to a trickle.
#
# jobloop's RunJob closes that gap: an uncaught throw from a body is
# reported failed and the slot freed. This drives it directly: harness_run
# rows whose opts omit the keys the body reads (prompt_dir, harness_class)
# throw before any terminal verb. They must land in `failed`, and good
# rows queued behind them must then run.
section "20. Worker error frees the slot (#138 regression)"

set d [spar::Dispatcher new 4 test_log]

# Four harness_run rows with opts that make _harness_run_body throw
# (missing prompt_dir / harness_class). Pre-guard these stranded all
# four slots in `running` forever.
foreach r {dead1 dead2 dead3 dead4} {
    $d enqueue $r harness_run {bogus 1}
}
foreach r {dead1 dead2 dead3 dead4} { wait_for_terminal $d $r 5000 }
foreach r {dead1 dead2 dead3 dead4} {
    assert_eq [$d state $r] failed "$r fails instead of stranding its slot"
}
assert_eq [llength [$d active_jobs]] 0 "all four leaked-candidate slots reclaimed"

# Good rows queued behind the dead ones must now run to completion —
# proof the slots are genuinely free, not just relabelled.
foreach r {live1 live2 live3 live4} {
    $d enqueue $r fake_worker {plan {{sleep 30} {msg_done}}}
}
foreach r {live1 live2 live3 live4} { wait_for_terminal $d $r 5000 }
foreach r {live1 live2 live3 live4} {
    assert_eq [$d state $r] done "$r runs in a reclaimed slot"
}
$d destroy

# ── 21. roster_update relays to the domain subscriber ────────────────────
section "21. roster_update relays to the domain subscriber"

# Without a subscriber the relay logs and drops; with one, the payload
# arrives whole. The subscriber here is the test's own; the spar wiring
# (spar::subscribe_pool_domain) is one [subscribe] away from it.
set d [spar::Dispatcher new 1 test_log]
$d on_roster_update r1 /tmp/nowhere.tsv slug s1 email e@x
assert_match [join $::log_messages \n] "*roster_update with no subscriber*" \
    "an unsubscribed roster_update is logged, not lost silently"
set ::domain_got {}
$d subscribe domain-roster_update {lappend ::domain_got}
$d on_roster_update r1 /tmp/nowhere.tsv slug s1 email e@x
assert_eq [lindex $::domain_got 0] r1 "payload row arrives at the subscriber"
assert_eq [llength $::domain_got] 6 "payload arrives whole"
$d destroy

finish_tests

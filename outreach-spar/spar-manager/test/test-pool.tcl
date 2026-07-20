#!/usr/bin/env tclsh9.0
# Tests for what spar::Dispatcher adds on top of jobloop: no marshalling
# layer, the harness_run / ses_send / imap_poll workers, and the
# roster_update relay to the domain subscriber. Pool mechanics (dispatch,
# caps, pause/resume, cancel, the state-machine guards, rate-limiting,
# requeue, active_jobs, prune_missing, per-kind caps, concurrency, and
# worker-error recovery) are jobloop's, proven once in teatotal's
# tests/test-jobloop.tcl and tests/test-jobpool.tcl; this file does not
# re-prove them through the Dispatcher.
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
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir .. lib spar-dispatcher.tcl]

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

set initcmd_path [file join $script_dir .. lib spar-dispatcher-initcmd.tcl]
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
# 2. harness_run wires through to a harness_class instance
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
section "2. harness_run routing"

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

# 2a. Successful harness run reaches done with rc=0 in the result dict.
lassign [make_harness_dirs ok 0] p_ok l_ok
$d enqueue h_ok harness_run [dict create \
    prompt_dir $p_ok log_dir $l_ok harness_class FakeHarness]
wait_for_terminal $d h_ok 3000
assert_eq [$d state h_ok] done "harness_run rc=0 reaches done"

# 2b. Harness rc=1 lands as failed with the rc message.
lassign [make_harness_dirs fail 1] p_f l_f
$d enqueue h_fail harness_run [dict create \
    prompt_dir $p_f log_dir $l_f harness_class FakeHarness]
wait_for_terminal $d h_fail 3000
assert_eq [$d state h_fail] failed "harness_run rc=1 reaches failed"

# 2c. Harness raising an error is caught and surfaced as failed.
lassign [make_harness_dirs throw throw] p_t l_t
$d enqueue h_throw harness_run [dict create \
    prompt_dir $p_t log_dir $l_t harness_class FakeHarness]
wait_for_terminal $d h_throw 3000
assert_eq [$d state h_throw] failed "harness_run catches errors as failed"

# 2e. The harness FAIL cause reaches the failure reason for the roll-call
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

# 2f. PROFILE_UNTOUCHED_RETRY (#181): rc=4 reports failed with the token
# and the Dispatcher requeues the row at the queue tail once. Here the
# first failure rewrites run-rc to 0 (standing in for the retry finding
# the congestion drained), so the requeued run completes: the job's
# state trail shows one failed round trip ending done.
lassign [make_harness_dirs rq 4] p_rq l_rq
set ::p_rq $p_rq
set ::_rq_trail {}
$d subscribe job-state [list apply {{row state} {
    if {$row eq "h_rq"} { lappend ::_rq_trail $state }
}}]
$d subscribe job-failed [list apply {{row reason} {
    if {$row eq "h_rq"} {
        set fd [open [file join $::p_rq run-rc] w]
        puts -nonewline $fd 0
        close $fd
    }
}}]
$d enqueue h_rq harness_run [dict create \
    prompt_dir $p_rq log_dir $l_rq harness_class FakeHarness]
wait_for_terminal $d h_rq 3000
assert_eq [$d state h_rq] done \
    "untouched-retry rc=4 requeues and the retry lands done"
assert_eq $::_rq_trail {queued running failed queued running done} \
    "requeue round trip: failed once, requeued, done"

# 2g. The pool requeues a token failure once. A worker that keeps
# returning 4 (its prompt-dir marker logic broken) stays failed on the
# second occurrence instead of looping the queue.
lassign [make_harness_dirs rq2 4] p_rq2 l_rq2
set ::_rq2_trail {}
$d subscribe job-state [list apply {{row state} {
    if {$row eq "h_rq2"} { lappend ::_rq2_trail $state }
}}]
$d enqueue h_rq2 harness_run [dict create \
    prompt_dir $p_rq2 log_dir $l_rq2 harness_class FakeHarness]
wait_for_terminal $d h_rq2 3000
assert_eq [$d state h_rq2] failed \
    "second token failure stays failed (requeued once)"
assert_eq $::_rq2_trail {queued running failed queued running failed} \
    "requeue cap: one round trip then terminal failed"

# 2d. Cancel before the worker enters the harness body: the row is
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

# 2f. Dry-run skips the harness body entirely. The row's run-rc is
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
# 3. ses_send happy path through a fake smtp_send helper
# ════════════════════════════════════════════════════════════════════════
# The worker shells out to smtp_send.tcl. We override the helper path
# in opts so tests don't open a real TLS socket. The fake helper just
# echoes a fixed message-id on stdout — enough to verify the wiring:
# enqueue → ses_send → ses::send_one → exec helper → msg_done with the
# id in the result dict, and that the approach YAML's actioned_date is
# stamped on success.
section "3. ses_send happy path"

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

# 3b. ses_send dry-run does not invoke the helper and does not stamp.
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

# 3c. ses_send failure when the approach file is missing.
set d [spar::Dispatcher new 2 test_log]
set bad_opts [dict replace $ses_opts approach_path /nonexistent/path.yaml]
$d enqueue ghost ses_send $bad_opts
wait_for_terminal $d ghost 5000
assert_eq [$d state ghost] failed "ses_send fails when approach missing"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 4. imap_poll happy path through a fake courier helper
# ════════════════════════════════════════════════════════════════════════
# The worker shells out to courier. We override courier_bin in opts
# to point at a fake script that returns canned JSON for both `search`
# and `read`. The fake script branches on its first positional arg
# after "--imap <account>" to mimic the real courier CLI.
section "4. imap_poll happy path"

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

# 4b. imap_poll with a since floor after the message date: inbox
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

# 4c. imap_poll with already-recorded fingerprint: no append.
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

# ── 5. roster_update relays to the domain subscriber ──────────────────────
section "5. roster_update relays to the domain subscriber"

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

section "6. usage-limit halt helpers"

# is_usage_limit_halt keys on coachman's stable token wherever it sits in
# the failure reason harness_run passes through.
assert_eq [spar::is_usage_limit_halt \
    {harness exited rc=1 | FAIL (author-draft: USAGE_LIMIT_UNRECOGNIZED, suspected usage limit): slug}] 1 \
    "the halt token in a wrapped reason is recognised"
assert_eq [spar::is_usage_limit_halt {harness exited rc=1 | FAIL (no draft markers): slug}] 0 \
    "an ordinary failure reason does not halt"

# halt_dispatch_queue cancels every still-queued row and returns the
# count; in-flight rows are the front-end's concern, not this helper's.
# Pause the queue so all three rows stay queued, then drain.
set d [spar::Dispatcher new 2 test_log]
$d pause_queue
foreach r {a b c} { $d enqueue $r fake_worker [dict create plan {{msg_done {}}}] }
assert_eq [llength [$d queued_jobs]] 3 "three rows queued while paused"
assert_eq [spar::halt_dispatch_queue $d] 3 "halt cancels all three queued rows"
assert_eq [llength [$d queued_jobs]] 0 "nothing queued after the halt"
$d destroy

section "7. in-flight harness abort registry"

# harness_run publishes each live harness in spar::live_harnesses; the
# helpers count and abort them. Fake harness instances (an object with an
# abort method) stand in for the registered coachman harnesses.
set ::spar::live_harnesses [dict create]
assert_eq [spar::live_harness_count] 0 "no live harnesses to start"

set ::aborted {}
foreach row {p1 p2} {
    set fake [oo::object new]
    oo::objdefine $fake method abort {} {
        lappend ::aborted [self]; return 1
    }
    dict set ::spar::live_harnesses $row $fake
}
assert_eq [spar::live_harness_count] 2 "two live harnesses counted"
assert_eq [spar::abort_live_harnesses] 2 "both live harnesses told to abort"
assert_eq [llength $::aborted] 2 "each harness's abort was called"
set ::spar::live_harnesses [dict create]

finish_tests

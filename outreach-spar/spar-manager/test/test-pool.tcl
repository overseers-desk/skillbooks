#!/usr/bin/env tclsh9.0
# Tests for spar::Dispatcher (the GUI's job pool) and the message-protocol
# enforcement defined in spar-dispatcher-initcmd.tcl.
#
# Strategy: drive the Dispatcher with fake_worker tpool jobs that emit
# scripted message sequences. No real claude / SES / IMAP calls. The
# fake_worker proc is defined in spar-dispatcher-initcmd.tcl alongside
# the production worker procs, so it loads via the same initcmd path.

package require Thread
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
# 1. Introspection mirror — every msg_* in initcmd has a matching on_*
# ════════════════════════════════════════════════════════════════════════
section "1. Introspection mirror"

# Read the initcmd file and pull out msg_* proc names.
set initcmd_path [file join $script_dir .. spar-dispatcher-initcmd.tcl]
set fd [open $initcmd_path r]; set initcmd_src [read $fd]; close $fd
set msg_names {}
foreach line [split $initcmd_src \n] {
    if {[regexp {^proc\s+(msg_[a-z_]+)\s} $line -> name]} {
        lappend msg_names $name
    }
}
set msg_names [lsort -unique $msg_names]

set on_names {}
foreach m [info class methods spar::Dispatcher -all] {
    if {[regexp {^on_[a-z_]+$} $m]} { lappend on_names $m }
}
set on_names [lsort -unique $on_names]

# Build the expected on_* set by stripping msg_ → on_.
set expected_on {}
foreach m $msg_names { lappend expected_on [regsub {^msg_} $m on_] }
set expected_on [lsort -unique $expected_on]

assert_eq $on_names $expected_on \
    "every msg_* has a matching on_* method (and vice versa)"

# ════════════════════════════════════════════════════════════════════════
# 2. Basic dispatch — enqueue a row, fake_worker runs it, reaches done
# ════════════════════════════════════════════════════════════════════════
section "2. Basic dispatch"

set d [spar::Dispatcher new 4 test_log]
$d pause_queue
$d enqueue r1 T1 fake_worker {plan {{sleep 50}}}
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
    $d enqueue $r T1 fake_worker {plan {{sleep 200}}}
}

# State flips to running at tpool::post time, so the snapshot is
# deterministic the moment all enqueues have returned.
assert_eq [$d posted_count] 2 "Jobs=2 caps posted at 2"
assert_eq [llength [$d queued_rows]] 2 "remaining 2 stay queued"

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
    $d enqueue $r T1 fake_worker {plan {{sleep 30}}}
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
$d enqueue r1 T1 fake_worker {plan {{sleep 300}}}
$d enqueue r2 T1 fake_worker {plan {{sleep 30}}}
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
$d enqueue r1 T1 fake_worker \
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
$d enqueue r1 T1 fake_worker \
    {plan {{sleep 50} {check_pause 30} {sleep 30}}}
wait_for_state $d r1 running 1000
$d pause_row r1
wait_for_state $d r1 paused 2000
assert_eq [$d state r1] paused "r1 reaches paused via sentinel"
$d resume_row r1
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
assert_match [join $::log_messages " "] "*phase for unknown row nonexistent_row*" \
    "on_phase for unknown row is logged"

# Register a queued row (queue paused so it does not auto-post), then
# send on_done — should be logged + dropped because the row never
# transitioned to running.
$d pause_queue
$d enqueue r1 T1 fake_worker {plan {{sleep 200}}}
set ::log_messages {}
$d on_done r1 {}
assert_match [join $::log_messages " "] "*done for row r1 in state queued*" \
    "on_done for queued row is logged and dropped"
assert_eq [$d state r1] queued "r1 still queued after illegal on_done"

$d resume_queue
wait_for_terminal $d r1 1000
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 9. count_by_transition — across heterogeneous rows
# ════════════════════════════════════════════════════════════════════════
section "9. count_by_transition"

set d [spar::Dispatcher new 4 test_log]
$d enqueue a1 T1 fake_worker {plan {{sleep 30}}}
$d enqueue a2 T1 fake_worker {plan {{sleep 30}}}
$d enqueue b1 T2 fake_worker {plan {{sleep 30}}}
$d enqueue b2 T2 fake_worker {plan {{sleep 30}}}
$d enqueue b3 T2 fake_worker {plan {{sleep 30}}}
foreach r {a1 a2 b1 b2 b3} { wait_for_terminal $d $r 3000 }
assert_eq [$d count_by_transition T1 done] 2 "T1 done count = 2"
assert_eq [$d count_by_transition T2 done] 3 "T2 done count = 3"
assert_eq [$d count_by_transition T1 failed] 0 "T1 failed count = 0"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 10. Rate-limited cycle — running → rate_limited → running → done
# ════════════════════════════════════════════════════════════════════════
section "10. Rate-limited cycle"

set d [spar::Dispatcher new 1 test_log]
$d enqueue r1 T1 fake_worker [list plan [list \
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
$d enqueue r1 T1 fake_worker {plan {{msg_failed boom}}}
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
# 12. active_rows — excludes terminal
# ════════════════════════════════════════════════════════════════════════
section "12. active_rows"

set d [spar::Dispatcher new 4 test_log]
$d enqueue r1 T1 fake_worker {plan {{sleep 30}}}
$d enqueue r2 T1 fake_worker {plan {{msg_failed nope}}}
$d enqueue r3 T1 fake_worker {plan {{sleep 200}}}
wait_for_terminal $d r2 2000
wait_for_terminal $d r1 2000
# r3 still running (200ms vs 30ms others)
set active [$d active_rows]
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
# routing path: enqueue → tpool::post → harness_run → msg_done/failed.
# Coverage of the real harness body lives in test-state.tcl /
# test-validate-*; this section catches breakage in the worker wrapper.
section "13. harness_run routing"

set tmp_root [file join /tmp "spar-pool-harness-[pid]-[clock microseconds]"]
file mkdir $tmp_root
lappend ::cleanup_dirs $tmp_root

proc make_harness_dirs {tag {rc 0}} {
    set p [file join $::tmp_root "$tag-prompt"]
    set l [file join $::tmp_root "$tag-log"]
    file mkdir $p $l
    if {$rc ne ""} {
        set fd [open [file join $p run-rc] w]; puts -nonewline $fd $rc; close $fd
    }
    return [list $p $l]
}

set d [spar::Dispatcher new 2 test_log]

# 13a. Successful harness run reaches done with rc=0 in the result dict.
lassign [make_harness_dirs ok 0] p_ok l_ok
$d enqueue h_ok T1 harness_run [dict create \
    prompt_dir $p_ok log_dir $l_ok harness_class FakeHarness]
wait_for_terminal $d h_ok 3000
assert_eq [$d state h_ok] done "harness_run rc=0 reaches done"

# 13b. Harness rc=1 lands as failed with the rc message.
lassign [make_harness_dirs fail 1] p_f l_f
$d enqueue h_fail T1 harness_run [dict create \
    prompt_dir $p_f log_dir $l_f harness_class FakeHarness]
wait_for_terminal $d h_fail 3000
assert_eq [$d state h_fail] failed "harness_run rc=1 reaches failed"

# 13c. Harness raising an error is caught and surfaced as failed.
lassign [make_harness_dirs throw throw] p_t l_t
$d enqueue h_throw T1 harness_run [dict create \
    prompt_dir $p_t log_dir $l_t harness_class FakeHarness]
wait_for_terminal $d h_throw 3000
assert_eq [$d state h_throw] failed "harness_run catches errors as failed"

# 13d. Cancel before the worker enters the harness body — the cancel
# sentinel is set before resume_queue posts to the tpool, so the
# pre-flight check fires.
lassign [make_harness_dirs precancel 0] p_pc l_pc
$d pause_queue
$d enqueue h_pc T1 harness_run [dict create \
    prompt_dir $p_pc log_dir $l_pc harness_class FakeHarness]
$d cancel h_pc
assert_eq [$d state h_pc] cancelled \
    "cancel before post drops the row without invoking the harness"
$d resume_queue

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
$d enqueue alice T6 ses_send $ses_opts
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
$d enqueue bob T6 ses_send $dry_opts
wait_for_terminal $d bob 5000
assert_eq [$d state bob] done "ses_send dry-run reaches done"
set fd [open $approach_path2 r]; set after2 [read $fd]; close $fd
assert_match $after2 "*actioned_date: null*" \
    "ses_send dry-run leaves actioned_date null"
$d destroy

# 14c. ses_send failure when the approach file is missing.
set d [spar::Dispatcher new 2 test_log]
set bad_opts [dict replace $ses_opts approach_path /nonexistent/path.yaml]
$d enqueue ghost T6 ses_send $bad_opts
wait_for_terminal $d ghost 5000
assert_eq [$d state ghost] failed "ses_send fails when approach missing"
$d destroy

# ════════════════════════════════════════════════════════════════════════
# 14d. imap_poll — happy path through a fake mailroom helper
# ════════════════════════════════════════════════════════════════════════
# The worker shells out to mailroom. We override mailroom_bin in opts
# to point at a fake script that returns canned JSON for both `search`
# and `read`. The fake script branches on its first positional arg
# after "-a <account>" to mimic the real mailroom CLI.
section "14d. imap_poll happy path"

set fake_mailroom [file join $tmp_root fake-mailroom.tcl]
set fd [open $fake_mailroom w]
puts $fd {#!/usr/bin/env tclsh9.0
# Args: -a <account> (search|read) -f <folder> ...
# Emit canned JSON for the two subcommands. Drop -a/-f flags.
set positional {}
for {set i 0} {$i < [llength $argv]} {incr i} {
    set a [lindex $argv $i]
    if {$a in {-a -f -u --limit}} { incr i; continue }
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
file attributes $fake_mailroom -permissions 0o755

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
    mailroom_bin  $fake_mailroom]

set d [spar::Dispatcher new 2 test_log]
$d enqueue carol T7 imap_poll $imap_opts
wait_for_terminal $d carol 5000
assert_eq [$d state carol] done "imap_poll happy path reaches done"

# The reply should have been appended to the YAML.
set fd [open $approach_path3 r]; set after3 [read $fd]; close $fd
assert_match $after3 "*Hello back from Dest*" \
    "imap_poll appends reply body to approach YAML"
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
$d enqueue dan T7 imap_poll $known_opts
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
$d enqueue done1 T1 fake_worker {plan {{sleep 30}}}
wait_for_terminal $d done1 2000
$d enqueue fail1 T1 fake_worker {plan {{msg_failed boom}}}
wait_for_terminal $d fail1 2000

# Long-running blocker, then a queued row that cannot post.
$d enqueue running1 T1 fake_worker {plan {{sleep 600}}}
wait_for_state $d running1 running 1000
$d enqueue queued1 T1 fake_worker {plan {{sleep 30}}}
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
$d enqueue post_prune T1 fake_worker {plan {{sleep 30}}}
assert_eq [$d queued_rows] [list post_prune] \
    "Queue list scrubbed of pruned stems"
$d resume_queue
wait_for_terminal $d post_prune 2000
wait_for_terminal $d running1   2000

$d destroy

# ════════════════════════════════════════════════════════════════════════
# 16. spar::run_through_pool — CLI adapter end-to-end
# ════════════════════════════════════════════════════════════════════════
# Exercises the CLI's path through the Pool: enqueue a batch of fake
# rows, mirror row events back through the legacy on_progress /
# on_complete callback contract, and tear down once every row reaches
# terminal state. Adapter lives in spar-dispatch.tcl.
section "16. run_through_pool"

# spar-dispatch.tcl needs a few of spar-state's helpers (load_campaign,
# slugify, dict_get_default). Source it lazily — the rest of test-pool
# does not need it.
source [file join $script_dir .. spar-dispatch.tcl]

# 16a. Happy path: three fake rows, all reach done, callbacks called
# in expected order with expected counts.
set ::progress_events {}
set ::complete_events {}
proc rt_progress {slug status message} {
    lappend ::progress_events [list $slug $status $message]
}
proc rt_complete {done failed result} {
    lappend ::complete_events [list $done $failed $result]
    set ::rt_done 1
}
set ::rt_done 0
set rows {}
foreach r {a b c} {
    lappend rows [list $r [dict create plan {{sleep 30}}]]
}
spar::run_through_pool 2 T1 fake_worker $rows [dict create] \
    rt_progress rt_complete
vwait ::rt_done
assert_eq [llength $::complete_events] 1 "on_complete fires exactly once"
lassign [lindex $::complete_events 0] d f res
assert_eq $d 3 "all three rows reach done"
assert_eq $f 0 "no failures"
# Three started + three done events = 6.
assert_eq [llength $::progress_events] 6 \
    "three rows produce three started + three done events"

# 16b. Failure path: one row fails, two succeed.
set ::progress_events {}
set ::complete_events {}
set ::rt_done 0
set rows {}
lappend rows [list ok1 [dict create plan {{sleep 20}}]]
lappend rows [list bad [dict create plan {{msg_failed boom}}]]
lappend rows [list ok2 [dict create plan {{sleep 20}}]]
spar::run_through_pool 2 T1 fake_worker $rows [dict create] \
    rt_progress rt_complete
vwait ::rt_done
lassign [lindex $::complete_events 0] d f _
assert_eq $d 2 "two rows succeed in failure path"
assert_eq $f 1 "one row fails"
# Verify the failed event carries the reason.
set found_fail 0
foreach ev $::progress_events {
    lassign $ev slug status message
    if {$slug eq "bad" && $status eq "failed" && $message eq "boom"} {
        set found_fail 1
    }
}
assert_eq $found_fail 1 "failed event carries the worker's reason"

# 16c. Empty rows list: on_complete fires with zeros immediately.
set ::complete_events {}
set ::rt_done 0
spar::run_through_pool 2 T1 fake_worker {} [dict create marker yes] \
    rt_progress rt_complete
# No vwait — empty path is synchronous.
assert_eq [llength $::complete_events] 1 "empty rows: on_complete called once"
lassign [lindex $::complete_events 0] d f res
assert_eq $d 0 "empty rows: done=0"
assert_eq $f 0 "empty rows: failed=0"
assert_eq [dict get $res marker] yes "empty rows: result dict passed through"

# 16d. step_callback abort: the gate refuses, rows go to cancelled and
# surface as skipped in the on_progress stream.
set ::progress_events {}
set ::complete_events {}
set ::rt_done 0
proc rt_step_abort {tid slug idx total} { return abort }
set rows {}
foreach r {x y z} {
    lappend rows [list $r [dict create plan {{sleep 30}}]]
}
spar::run_through_pool 1 T1 fake_worker $rows [dict create] \
    rt_progress rt_complete rt_step_abort
vwait ::rt_done
lassign [lindex $::complete_events 0] d f _
assert_eq $d 0 "all rows aborted: done=0"
assert_eq $f 0 "all rows aborted: failed=0"
# Each row should produce one started and one skipped event.
set skipped_count 0
foreach ev $::progress_events {
    if {[lindex $ev 1] eq "skipped"} { incr skipped_count }
}
assert_eq $skipped_count 3 "three rows aborted by step_callback"

# 16e. step_callback continue: same as no callback.
set ::progress_events {}
set ::complete_events {}
set ::rt_done 0
proc rt_step_continue {tid slug idx total} { return continue }
set rows {}
foreach r {p q} {
    lappend rows [list $r [dict create plan {{sleep 20}}]]
}
spar::run_through_pool 1 T1 fake_worker $rows [dict create] \
    rt_progress rt_complete rt_step_continue
vwait ::rt_done
lassign [lindex $::complete_events 0] d f _
assert_eq $d 2 "step_callback=continue lets all rows through"
assert_eq $f 0 "step_callback=continue: no failures"

# ════════════════════════════════════════════════════════════════════════
# 17. True parallelism with blocking workers
# ════════════════════════════════════════════════════════════════════════
#
# Reproducer for the bug documented in #86 follow-up and analysed in
# docs/job-pool.md "Pool sizing". A `tpool::create -minworkers 0` only
# spawns one worker for the pool's lifetime, regardless of post volume,
# so production runs at --jobs=8 ran strictly sequentially. Earlier
# tests asserted `posted_count` (which counts state flips at
# tpool::post time) and were therefore satisfied even when no second
# worker thread ever existed.
#
# This test enqueues four rows, each with a real blocking `exec sleep`
# in the worker body, and asserts wall time is roughly one sleep
# duration (parallel) rather than four (serial). exec_sleep is the
# right shape because the production harness's `exec claude` is OS-
# blocked the same way; the original `sleep` plan-step uses event-loop-
# friendly vwait+after and would not have reproduced the bug.
section "17. True parallelism with blocking workers"

set d [spar::Dispatcher new 4 test_log]
set t0 [clock milliseconds]
foreach r {p1 p2 p3 p4} {
    $d enqueue $r T1 fake_worker {plan {{exec_sleep 2}}}
}
foreach r {p1 p2 p3 p4} { wait_for_terminal $d $r 12000 }
set elapsed [expr {[clock milliseconds] - $t0}]
foreach r {p1 p2 p3 p4} {
    assert_eq [$d state $r] done "$r reaches done"
}
# Four 2-second sleeps in parallel ≈ 2s; in series ≈ 8s. Allow
# generous slack for tpool worker startup and OS scheduling.
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
# set_worker_cap installs a per-worker-proc cap that further constrains
# the global Jobs cap; rows for that worker_proc cannot exceed it even
# when the global cap has slack.
#
# This test enqueues 4 fake_worker_a rows and 4 fake_worker_b rows into
# a pool of 8. set_worker_cap fake_worker_a 1 forces the four a-rows to
# serialise; fake_worker_b is uncapped (4 in parallel under jobs=8).
#
# Wall time signature: a-rows take 4×2s=~8s sequentially; b-rows take
# ~2s in parallel. Overall ~8s wall, dominated by the serialised side.
# Without set_worker_cap, both groups parallelise and the total drops
# to ~2s.
section "18. Per-worker cap"

set d [spar::Dispatcher new 8 test_log]
$d set_worker_cap fake_worker_a 1
set t0 [clock milliseconds]
foreach r {a1 a2 a3 a4} {
    $d enqueue $r T1 fake_worker_a {plan {{exec_sleep 2}}}
}
foreach r {b1 b2 b3 b4} {
    $d enqueue $r T2 fake_worker_b {plan {{exec_sleep 2}}}
}
foreach r {a1 a2 a3 a4 b1 b2 b3 b4} { wait_for_terminal $d $r 20000 }
set elapsed [expr {[clock milliseconds] - $t0}]
foreach r {a1 a2 a3 a4 b1 b2 b3 b4} {
    assert_eq [$d state $r] done "$r reaches done"
}
# fake_worker_a's 4×2s serialised ≈ 8s; fake_worker_b's 4×2s parallel ≈ 2s.
# Overall wall time should be near max(8s, 2s) = 8s. Without per-worker
# caps the test would finish in ~2s (everything parallel under cap=8).
# Allow generous slack for tpool worker startup and OS scheduling.
if {$elapsed > 6500 && $elapsed < 12000} {
    puts "  ok: per-worker cap enforces serial fake_worker_a (elapsed=${elapsed}ms)"
    incr ::passes
} else {
    puts "FAIL: per-worker cap not enforced (elapsed=${elapsed}ms; expected 6500–12000ms)"
    incr ::failures
}
$d destroy

finish_tests

# Concurrency in SPAR Manager

## The problem

A SPAR campaign run is heterogeneous. Profile generation (T1, T3) and approach generation (T2, T4) drive `claude` agents. Each agent blocks for minutes per row, is CPU- and cost-bound, and sometimes hits a credit-limit reset the worker must sit through. SES delivery (T6) is network-bound and serialises — one auth handshake per SMTP connection, plus the per-row pacing the campaign sets via `delay`. IMAP polling (T7) is also network-bound but parallelises freely.

A single CLI invocation can take hours. A 30-row T1 batch at the campaign-default `jobs=4` is already a multi-hour run, and `--auto` chains T1 → T2 → T6 → T7 across the same wall clock. The user wants to add and remove work mid-flight in the GUI, see progress without polling, and pause without losing in-flight items. The CLI wants the same row-state machine so its output matches the GUI's and the two surfaces share one budget — when the user says `--jobs=8`, eight worker threads is what they should see, not sixteen.

One job manager satisfies all of this at once: it carries mixed work, runs OS-thread-parallel, drives a per-row state machine, cancels cooperatively, and caps each worker kind. The rest of this document covers what Tcl 9 gives us, the choices made on top of it, the classes that result, the row state machine, the message protocol, the downward sentinel channel, enforcement, and the deferred work.

## What Tcl 9 offers

| Package      | macOS  | Ubuntu | Where it comes from on Ubuntu |
|--------------|--------|--------|-------------------------------|
| Thread       | 3.0.4  | 3.0.1  | `apt install tcl9.0-thread`   |
| coroutine    | 1.4    | 1.4    | `tcllib`                      |
| uevent       | 0.3.2  | 0.3.2  | `tcllib`                      |
| TclOO        | 1.3.1  | 1.3.1  | built into Tcl 9              |
| tcl::process | —      | —      | built into Tcl 9              |

The built-in event loop (`after`, `vwait`, `fileevent`, `chan event`) is always available — no `package require`.

Of these, only one gives real OS-thread parallelism. The rest matter for different reasons.

- **Thread (with the `tpool::` API)** — real OS threads, each carrying its own Tcl interpreter; true parallelism across cores. `test/run.tcl` uses this to fan test files out across `[exec getconf _NPROCESSORS_ONLN]` workers. Note Thread 2.x had `Tpool` as a separately requireable package; Thread 3.x folded it into the `Thread` package under the `tpool::` namespace, so on Tcl 9 do not `package require Tpool` — it fails. The right shape is `package require Thread` and then `tpool::create -minworkers N -maxworkers N -idletime 60 -initcmd { ... }`.
- **The built-in event loop** — single-threaded, cooperative. "Concurrent" in the non-blocking-I/O sense, not parallel. Reach for it when the work is I/O-bound and one core suffices.
- **coroutine** — cooperative, single-thread. Lets one task `yield` to another inside the same interpreter. Worth naming because the word "coroutine" invites the wrong assumption — coroutines on a multi-core machine still occupy one core.
- **uevent** — pub/sub on the event loop. A decoupling tool, not a concurrency primitive; subscribers fire on the same thread that posted.
- **TclOO** — object system. Orthogonal to concurrency; named here only because it sometimes appears alongside the others in capability checks.
- **tcl::process** — a status registry for child processes started by `exec` or `open "|"`. Subcommands: `status`, `list`, `purge`, `autopurge`. Not a concurrency primitive — it does not launch processes, send signals, or contribute parallelism. Named here only to keep the toolbox complete; the deferred-work section below points at the one place it is likely to apply.

## The choices

**tpool for parallelism.** Nothing else gives multi-core. The harness's `exec claude` blocks for minutes per call; the only way to run more than one of them at once is to put each in its own OS thread with its own interpreter.

The alternative considered was a subprocess framing — generalise the original CLI harness queue class into a true coordinator above a `Worker` supertype, with `HarnessWorker`, `SesWorker`, and `ImapWorker` as siblings. It was set aside on clarity grounds. The `tpool`-based design is harder to misread. The failure modes the subprocess form wins on — per-row kill of in-flight `claude`, exit from a credit-limit sleep — are deferred to a later harness migration. That migration moves synchronous `exec claude` to `open "| …"` plus `fileevent`. The deferred-work section names it explicitly so the option is not lost. As of issue #88 Phase 6, both CLI and GUI dispatch through `spar::Dispatcher` — the legacy harness queue and per-Driver classes have been retired.

**Pool sizing: `-minworkers` equal to `-maxworkers` (pre-spawn).** The obvious shape is `-minworkers 0 -maxworkers $jobs`, letting workers spawn lazily as posts arrive. That shape is broken. With `-minworkers 0` the Thread package spawns one worker for the pool's lifetime — that worker handles every post in turn, no matter how many posts arrive, and the pool never grows. A 29-row T1 batch at `--jobs=8` ran sequentially for ~8 hours in production on 2026-04-28 before the bug was caught. The Phase-1b unit tests had been asserting `posted_count` — a counter that ticks the moment `tpool::post` flips a row's state — and were satisfied even when no second worker thread ever existed. The reproducer now is `test/test-pool.tcl` §17 ("True parallelism with blocking workers"), which posts four blocking `exec sleep 2` jobs and asserts wall time under 4500 ms; that bound passes only with real parallelism. The bug holds whether the worker body uses blocking `exec` or event-loop-friendly `open "|"` plus `vwait`, so the deferred `exec → open "|"` migration named below would not, on its own, give parallelism. Pre-spawning is the only fix.

The cost is initcmd overhead for `$jobs` worker threads paid up-front, on small batches as well as large. Each Dispatcher lives for a wish session or a CLI run, so the per-thread cost amortises immediately and is not worth optimising.

**One shared Dispatcher across all transition kinds.** The CLI used to construct one `spar::Dispatcher` per active TID, so `--jobs=4 --tid=T1 --tid=T6` quietly produced up to eight parallel worker threads. The user thinks of the cap as process-wide; per-TID Dispatchers multiply it invisibly. The Dispatcher class itself was always heterogeneous-ready (per-row `worker_proc` and `row_opts`), so unifying is a matter of folding every TID's prep into one batch and one pool, not changing the pool itself.

**Per-worker cap.** SES (T6) must serialise but lives in the same shared pool as the parallel workers. The Dispatcher exposes `set_worker_cap <worker_proc> <cap>` as a sub-cap of the global `Jobs`: a row whose `worker_proc` sits at its per-worker cap stays queued while rows of other workers continue to post. `dispatch_ready` installs `set_worker_cap ses_send 1` so SES sends serialise alongside parallel harness rows; `_try_post_next` walks the queue rather than popping the head, so a blocked SES row at the front does not block harness rows behind it. Reproducer: `test/test-pool.tcl` §18.

**Heterogeneous CLI grammar.** The old `--tid=T1 --tid=T6 --segment=foo --stem=bar` was homogeneous — one segment list and one stem list applied to every TID. That fits a one-runner-at-a-time mental model, but the shared pool wants per-TID scopes. Positional `Tn[:seg[/stem]]` tokens carry their scope on the token, repeat, and mix freely (e.g. `T1 T2:vic T6:vic/jane-doe`). The grammar parses in `spar-transition-cli.tcl` so `test/test-cli-parser.tcl` can drive it without spinning up a campaign YAML.

**Typed message protocol via `thread::send -async`.** Worker threads cannot touch Tk or main-thread state directly; everything passes through a small set of `msg_*` procs in the tpool's `-initcmd` that forward to `on_*` methods on the Dispatcher in the main thread. Downward signals from Dispatcher to workers go through shared variables (`tsv::`), not messages — the main thread cannot `thread::send` into a worker that sits inside a synchronous `exec`.

## The classes that result

**`spar::Dispatcher`** in `spar-dispatcher.tcl` — coordinator. The generic machinery (the heterogeneous queue, the per-row state map, the global `Jobs` cap, the per-worker caps, cooperative cancel/pause, and the `on_*` message surface with its event stream) is the vendored `jobpool` module (`vendor/jobpool-1.0.tm`, protocol in its man page); spar::Dispatcher subclasses it. The subclass supplies spar's worker bootstrap and logger service, and adds the four messages a spar worker sends that a generic pool does not carry: `cost`, `retry`, and `credit_warning` (informational), and `roster_update`, relayed whole to the `domain-roster_update` subscriber `spar::subscribe_pool_domain` installs beside each front-end. Holds no Tk references and creates no widgets.

**Worker proc family** in `spar-dispatcher-initcmd.tcl` — registered in the tpool's `-initcmd` and so present in every worker thread's interpreter. `harness_run` for the AI-driven transitions, `ses_send` for SES delivery, `imap_poll` for reply checking. Each runs to completion or until it observes a cancel sentinel. Worker bodies are the only callers of `msg_*`; nothing else in worker-thread code may call `thread::send` directly.

**Harness library** in `spar-harness.tcl`, loaded inside `harness_run` only. The validate-and-correct fix loop, credit-limit retry, session-resume bookkeeping, cost ledger. Used by the AI-work worker and only by it. The harness is the body of `harness_run`, not a layer above it. The claude pipe itself runs under the vendored deadman watchdog (`vendor/deadman-1.0.tm`): stall detection, the budget poll's kill, and the process-group teardown are the module's, and the harness keeps only the policy (which cause maps to which return code).

**`spar::ui::DispatchController`** in `ui/dispatch-controller.tcl` — Tk controller. Owns the Play/Pause/Cancel buttons, the right-click menu on tree rows, and the progress bar. Translates user actions into Dispatcher method calls and renders Dispatcher row-state events back onto the `TransitionTree`. Does not spawn jobs and does not call `thread::send` directly.

The CLI's equivalent is `dispatch_ready` in `spar-transition.tcl`. Same shape: it consults each transition's `prepare_for_pool`, builds one shared Dispatcher, wires `spar::subscribe_pool_domain`, installs `set_worker_cap ses_send 1`, enqueues every row, and `vwait`s once on a counter the row-state subscriber maintains.

## Row state machine

```
queued ──(tpool::post)──> running
queued ──(cancel before post)──> cancelled
running ──phase / progress / cost / retry / roster_update──> running
running ──rate_limited──> rate_limited ──rate_limit_cleared──> running
running ──paused──> paused ──resumed──> running
running | paused ──cancelled──> cancelled
running | paused | rate_limited ──done──> done
running | paused | rate_limited ──failed──> failed
done | failed | cancelled ──(user requeue)──> queued
```

The `queued → running` transition fires the moment the Dispatcher posts the row to the tpool, not when the worker thread sends back a confirmation. There is no `msg_started` message; the worker's first action is whatever real work the row needs. This avoids a race where the row's state lagged its actual dispatch by the gap between `tpool::post` and the worker's first scheduled instruction.

`rate_limited` and `paused` are waiting states. The worker thread is alive, sitting in a `vwait` on a sentinel or an `after` schedule. Both count against the global `Jobs` cap because the tpool slot is still occupied.

There is no `killed` state. The tpool offers no thread-cancellation primitive, and the harness is not yet structured to permit one. Cooperative cancel — the worker observes a sentinel between safe points and exits as `cancelled` — is the only way out of `running` other than the worker's own terminal message.

## Messages from worker to Dispatcher

Every message is sent by calling a proc named `msg_<name>` defined in the tpool's `-initcmd`. The proc builds the typed payload and forwards it via `thread::send -async $::main_tid [list $::dispatcher on_<name> ...]`. Worker bodies never call `thread::send` directly; the enforcement section below explains why.

### Universal — sent by every worker proc

| message | when | row state effect | payload |
|---|---|---|---|
| `phase` | worker entered a labelled phase | none | row, phase_name |
| `progress` | informational subtitle text for the UI | none | row, text |
| `done` | terminal success | running / paused / rate_limited → done | row, result_dict |
| `failed` | terminal failure | running / paused / rate_limited → failed | row, reason |
| `cancelled` | worker observed cancel sentinel and stopped at a safe point | running / paused → cancelled | row |
| `roster_update` | request a serialised mutation of a roster TSV (the present `ROSTER_UPDATE` protocol); the pool relays it whole to the `domain-roster_update` subscriber that `spar::subscribe_pool_domain` installs, and logs a drop when none is installed | none | row, roster_path, key_col, key_val, field, new_val |

### Harness-only — sent by `harness_run` workers

| message | when | row state effect | payload |
|---|---|---|---|
| `cost` | one claude call returned with parsed `total_cost_usd` | none | row, stage, usd |
| `retry` | the validate-and-correct fix loop is iterating | none | row, stage, attempt, max |
| `rate_limited` | claude returned the limit-reset message; harness about to sleep | running → rate_limited | row, reset_at_unix |
| `rate_limit_cleared` | sleep ended; harness about to retry | rate_limited → running | row |
| `paused` | worker observed the pause sentinel between claude calls | running → paused | row |
| `resumed` | pause sentinel cleared | paused → running | row |
| `credit_warning` | rolling cost over the recent window crossed a configured threshold | none | row, usd_window, window_secs |

## Signals from Dispatcher to worker

The Dispatcher cannot `thread::send` into a worker that sits inside a synchronous `exec`; the message would queue until `exec` returned of its own accord, and only then run. Downward signals are therefore shared variables, not messages. One `tsv::array` per row, keyed by signal name.

The initcmd exports two helpers the worker is required to use rather than reading the tsv directly:

| helper | returns true when |
|---|---|
| `worker_cancel_requested? row` | Dispatcher has set the row's cancel sentinel |
| `worker_pause_requested? row` | Dispatcher has set the row's pause sentinel |

The harness checks both at the top of `_invoke`'s outer loop and between `validate_and_correct` passes. The SES and IMAP worker procs check `worker_cancel_requested?` between rows or between IMAP polls.

A cancel raised before the row was posted to the tpool is handled in the Dispatcher: the row is removed from the queue without `tpool::post` ever being called, and the worker never sees it. A cancel raised after the row started but during a `vwait` — credit-limit sleep, pause sentinel — is delivered when the `vwait` returns, so the harness must check the sentinel at every `vwait` exit point, not only at the top of the loop.

## Enforcement

Three mechanisms, in order of strength.

**Single send surface in the worker.** Workers call `msg_*` procs only; they do not call `thread::send` directly. A pre-commit grep — `grep -n 'thread::send' transitions/*.tcl spar-harness.tcl` — must return only matches inside `msg_*` proc bodies. Anything else is a violation.

**Sender and receiver shape mirror.** For every `msg_<name>` defined in the initcmd, the Dispatcher class defines a public method `on_<name>` with matching arity. A test in `test/test-pool.tcl` enumerates both sets through introspection (`info commands msg_*` and `info class methods spar::Dispatcher`) and asserts they match. The "added a message but forgot to handle it" mistake is caught at test time, not runtime.

**State-machine validation in the Dispatcher.** Each `on_*` method consults the current row state before mutating it. Out-of-order messages — `on_phase` before `on_started`, anything after a terminal state — are logged at warning level and dropped, not raised. A pure-Tcl test fixture posts malformed sequences directly to the Dispatcher, bypassing the tpool, and asserts the violations are detected.

The protocol tables above are the single source of truth for the message set. Adding a new message means editing this document, the initcmd, and the Dispatcher class together. The introspection test fails if any of the three drift.

## Open items

**`progress` versus `phase`.** The harness today emits both `[phase: …]` markers and ordinary stdout chatter. If the UI does not need a per-row subtitle distinct from the phase label, drop `progress` and route any non-phase chatter to a separate `log` message that does not touch row state. To be decided when the Controller's render path is ported.

**Timing of `credit_warning`.** Listed in the protocol now so the Dispatcher can grow its handler in the same pass and the harness can emit it later without the receiver needing to be revisited. The harness change itself — parsing the remaining-credit field in `_invoke`'s parsed JSON — is deferred.

## Deferred work

Named here so the design is not retrofitted in surprise.

**Per-row kill of in-flight claude calls.** Requires migrating `_invoke` from synchronous `exec claude` to `open "| claude …"` plus `fconfigure -blocking 0`, `fileevent`, and `vwait`. With the pipe channel the worker thread is event-loop-driven during the call, the child PID is available via `pid $pipe`, and a kill request arrives in real time and can run `exec kill -TERM [pid $pipe]`. Not in scope for the first cut because the blocking `exec` sites the codebase has today — `spar-harness.tcl:161`, the two `mailroom` calls in `spar-mailroom.tcl`, and the keychain lookups in `transitions/send_email.tcl` — are all acceptable to "let finish" in current usage. After the migration, the killed child's exit status comes from either `close` error parsing or `tcl::process status [pid $pipe]`; either works, and the choice does not affect the kill mechanism.

**Cancel during credit-limit sleep.** The retry loop at `spar-harness.tcl:171-184` already uses `vwait ::_wake` after `after`, so the event loop is running and `thread::send` already gets through. What is missing is a cancel check after the `vwait` returns and a fast path that exits the loop instead of looping back to another claude call. Small change; deferred only because cancel during a multi-hour credit sleep has not yet bitten anyone.

**Keychain access dialog.** On macOS the first call to `security find-generic-password` per Keychain item can pop a modal dialog and block the worker until the user dismisses it. Steady-state cost is zero; rotating the SMTP password unattended would re-trigger it. Worth being aware of, not worth code now.

# Concurrency in SPAR Manager

## The problem

A SPAR campaign run is heterogeneous. Profile generation (T1, T3) and approach generation (T2, T4) drive `claude` agents. Each agent runs for minutes per row and sometimes hits a credit-limit reset the worker must sit through, but from the dispatcher's seat the work is a wait: a subprocess pipe that produces output slowly, not a core kept busy. SES delivery (T6) is network-bound and serialises, one auth handshake per SMTP connection, plus the per-row pacing the campaign sets via `delay`. IMAP polling (T7) is network-bound and parallelises freely. LinkedIn sends (T6 linkedin rows) POST to a local overseer that holds the request through a browser queue and a rate gate. Every one of these is waiting on something outside the process: a child, a socket, a timer.

A single CLI invocation can take hours. A 30-row T1 batch at the campaign-default `jobs=4` is already a multi-hour run, and `--auto` chains T1 to T2 to T6 to T7 across the same wall clock. The user wants to add and remove work mid-flight in the GUI, see progress without polling, and pause without losing in-flight items. The CLI wants the same row-state machine so its output matches the GUI's and the two surfaces share one budget: when the user says `--jobs=8`, eight jobs in flight is what they should see.

One job manager satisfies all of this at once: it carries mixed work, runs many waits at the same time, drives a per-row state machine, cancels cooperatively, and caps each kind of work. Because the work waits rather than burns CPU, the manager needs no threads.

## What Tcl 9 offers

| Package      | Where it comes from on Ubuntu |
|--------------|-------------------------------|
| built-in event loop | none needed (`after`, `vwait`, `fileevent`, `chan event`) |
| coroutine    | built into Tcl 9 |
| Thread (`tpool::`) | `apt install tcl9.0-thread` |
| TclOO        | built into Tcl 9 |
| tcl::process | built into Tcl 9 |

- **The built-in event loop plus coroutine** is the substrate the dispatch pool runs on. A coroutine parks on a `fileevent` or an `after`, yields, and resumes when the world answers; many coroutines multiplex their waits through the one loop, in one interpreter, with nothing to marshal between them. This is concurrency in the non-blocking-I/O sense, not parallel CPU: on a multi-core machine the coroutines still share one core. That is the right trade for work that is mostly waiting.
- **Thread (with the `tpool::` API)** gives real OS-thread parallelism, each thread carrying its own interpreter. Two places in the app still want it, and both are genuinely CPU-bound: `test/run.tcl` fans test files across `[exec getconf _NPROCESSORS_ONLN]` workers, and `spar-state.tcl`'s cold-load parse pool reads and parses every roster in parallel. The dispatch pool is not one of them, so it carries no `Thread` dependency.
- **TclOO** is the object system the pool and its mixins are built from. Orthogonal to concurrency.
- **tcl::process** is a status registry for child processes started by `exec` or `open "|"`. Named here only to keep the toolbox complete; the subprocess watchdog the harness uses (deadman) owns child lifetime instead.

## The choices

**jobloop for the dispatch pool.** The dispatch work waits: the claude pipe, the SMTP and courier children, the overseer socket, the credit-limit and pacing timers. A thread that ran one of these would idle on a read the whole time. jobloop runs each job as a coroutine on the event loop the front-end already has, so one interpreter multiplexes every wait with no message marshalling. The pool is the vendored `jobloop` module (`vendor/jobloop-1.0.tm`, and its mixin `vendor/leash-1.0.tm`, which ties every timer and coroutine to the pool's lifetime); `spar::Dispatcher` subclasses it.

The dispatch pool used to run on `jobpool`, the thread twin of jobloop with the same state machine, pool API, events, and worker verbs. The two are one design over two runtimes, and a worker's reporting and cancellation code moves between them unchanged. The move to jobloop deleted the marshalling that the thread runtime required: the `msg_*` bridge procs, the `thread::send -async` reports, the `tsv::` cancel/pause sentinels, and the per-worker re-sourcing of the harness and email code into each worker interpreter. See "The worker verbs" and "Cancel and pause" below for what stands in their place.

**Concurrency cap: `jobs` concurrent coroutines.** `jobloop new $jobs` runs at most `$jobs` coroutines at once; the rest wait in the queue and launch as slots free. There is no thread pre-spawn, so the `-minworkers 0` starvation bug that made a `--jobs=8` run go sequential under jobpool cannot recur: launching a coroutine is a `coroutine` command, not a thread the pool has to have spawned in advance. `test/test-pool.tcl` §17 posts four rows that each run a real `sleep` child through `spar::pool_exec` and asserts wall time under 4500 ms; that passes only because the four waits overlap on the one loop. §19 posts sixteen rows over four slots and asserts the pool stays filled to four until the queue drains.

**One shared Dispatcher across all transition kinds.** The CLI used to construct one `spar::Dispatcher` per active TID, so `--jobs=4 T1 T6` quietly ran two pools. The user thinks of the cap as run-wide; per-TID pools multiply it invisibly. The Dispatcher is heterogeneous by construction (per-row `worker_proc` and `row_opts`), so unifying is a matter of folding every TID's prep into one batch and one pool.

**Per-kind cap.** SES (T6) must serialise but lives in the same shared pool as the parallel work. The Dispatcher exposes `set_kind_cap <kind> <cap>` as a sub-cap of the global `jobs`: a row whose kind sits at its per-kind cap stays queued while rows of other kinds keep launching. `dispatch_ready` installs `set_kind_cap ses_send 1` and `set_kind_cap linkedin_send 1` so sends serialise alongside parallel harness rows; the queue is walked rather than popped from the head, so a blocked send row at the front does not hold up harness rows behind it. Reproducer: `test/test-pool.tcl` §18.

**Heterogeneous CLI grammar.** Positional `Tn[:seg[/stem]]` tokens carry their scope on the token, repeat, and mix freely (e.g. `T1 T2:vic T6:vic/jane-doe`). The grammar parses in `spar-transition-cli.tcl` so `test/test-cli-parser.tcl` can drive it without spinning up a campaign YAML.

## The classes that result

**`spar::Dispatcher`** in `spar-dispatcher.tcl` is the coordinator. The generic machinery (the heterogeneous queue, the per-row state map, the global `jobs` cap, the per-kind caps, pacing, holds, cooperative cancel/pause, and the `on_*` report surface with its event stream) is `jobloop`; spar::Dispatcher subclasses it. The subclass supplies spar's logger service and adds the four reports a spar worker sends that a generic pool does not carry: `cost`, `retry`, and `credit_warning` (informational), and `roster_update`, relayed whole to the `domain-roster_update` subscriber `spar::subscribe_pool_domain` installs beside each front-end. Holds no Tk references and creates no widgets. Its constructor no longer takes a worker bootstrap: jobloop's workers are commands in this interpreter, so `spar-dispatcher.tcl` sources the harness, email, and per-row transition code once at the bottom of the file, into the main interpreter, where the pool is built.

**Worker proc family** in `spar-dispatcher-initcmd.tcl`, now sourced into the main interpreter rather than seeded into worker threads. `harness_run` for the AI-driven transitions, `ses_send` and `linkedin_send` for delivery, `imap_poll` for reply checking. Each runs as a coroutine and reports through the jobloop verbs, picked up by the file's one `namespace path ::jobloop::worker` line. The file also defines the coroutine-aware I/O helpers the bodies wait on (`spar::pool_sleep`, `spar::pool_exec`, `spar::pool_http`) and the test fixtures (`fake_worker`, `FakeHarness`).

**Harness library** in `spar-harness.tcl`, the body of `harness_run`. The validate-and-correct fix loop, credit-limit retry, session-resume bookkeeping, cost ledger. The claude pipe runs under the vendored deadman watchdog (`vendor/deadman-1.0.tm`): stall detection, the budget poll's kill, and the process-group teardown are the module's, and the harness keeps only the policy. deadman completes into the coroutine (`_invoke` hands it `[info coroutine]` as `-done` and yields), so a minutes-long claude run drives the loop instead of freezing it.

**`spar::ui::DispatchController`** in `ui/dispatch-controller.tcl` is the Tk controller. Owns the Play/Pause/Cancel buttons, the right-click menu on tree rows, and the progress bar. Translates user actions into Dispatcher method calls and renders Dispatcher row-state events back onto the `TransitionTree`. Reads `active_jobs` and `queued_jobs` for the progress bar.

The CLI's equivalent is `dispatch_ready` in `spar-transition.tcl`. Same shape: it consults each transition's `prepare_for_pool`, builds one shared Dispatcher, wires `spar::subscribe_pool_domain`, installs the send caps, enqueues every row, and `vwait`s once on a counter the row-state subscriber maintains. The `vwait` runs the event loop, which is where the coroutines actually make progress.

## Row state machine

```
queued ──(launch)──> running
queued ──(cancel before launch)──> cancelled
running ──phase / progress / cost / retry / roster_update──> running
running ──rate_limited──> rate_limited ──rate_limit_cleared──> running
running ──paused──> paused ──resumed──> running
running | paused ──cancelled──> cancelled
running | paused | rate_limited ──done──> done
running | paused | rate_limited ──failed──> failed
done | failed | cancelled ──(user requeue)──> queued
```

The `queued -> running` transition fires the moment the Dispatcher launches the row, before its coroutine starts, so the cap math reads straight from the state map with no queued/running gap to race. There is no `started` report; the worker's first action is whatever real work the row needs.

`rate_limited` and `paused` are waiting states. The coroutine is alive, parked on a yield. Both count against the global `jobs` cap because the slot is still held.

There is no `killed` state. Cancel is cooperative: the worker observes it at a `checkpoint` between safe points and unwinds as `cancelled`. That is the only way out of `running` other than the worker's own terminal report.

## The worker verbs

A worker reports by calling a verb in `::jobloop::worker`, resolved through the `namespace path` line at the top of `spar-dispatcher-initcmd.tcl`; each verb finds its owning pool from `[info coroutine]` and lands on a matching `on_<name>` method. There is no `thread::send` and no `msg_*` proc: the coroutine already runs on the main thread, so a verb is a direct call. `test/test-pool.tcl` §1 guards that the worker file carries no `thread::send`, no `tsv::`, and no `msg_*` proc.

### Generic (jobloop's own)

| verb | when | row state effect | payload |
|---|---|---|---|
| `checkpoint` | between units of work | cancel: -> cancelled and unwind; pause: park until resumed | row |
| `phase` | entered a labelled phase | none | row, phase_name |
| `progress` | informational subtitle text for the UI | none | row, text |
| `done` | terminal success | running / paused / rate_limited -> done | row, result_dict |
| `failed` | terminal failure | running / paused / rate_limited -> failed | row, reason |
| `rate_limited` | worker waiting on an external limit | running -> rate_limited | row, reset_at_unix |
| `rate_limit_cleared` | that wait ended | rate_limited -> running | row |

A body that returns without a terminal verb is reported `done` with an empty result; an uncaught error is reported `failed` with its message; jobloop's `RunJob` frees the slot however the body ends, so there is no separate slot-reclamation wrapper to maintain.

### spar's domain reports

Sent by the harness (`harness_run`) and relayed by `spar::Dispatcher`'s own `on_*` methods.

| report | when | row state effect | payload |
|---|---|---|---|
| `cost` | one claude call returned with parsed `total_cost_usd` | none | row, stage, usd |
| `retry` | the validate-and-correct fix loop is iterating | none | row, stage, attempt, max |
| `credit_warning` | rolling cost over the recent window crossed a threshold | none | row, usd_window, window_secs |
| `roster_update` | a serialised mutation of a roster TSV, relayed to the `domain-roster_update` subscriber | none | row, roster_path, key_col, key_val, field, new_val |

The masked-email guardrail in `ProfileHarness` no longer routes through `roster_update`: because every worker shares the one thread, it calls `spar::update_roster_field` directly. The `roster_update` report and its subscriber remain for a caller that would rather report through the pool.

## Cancel and pause

Cancel and pause are cooperative and observed at a `checkpoint`, which is the only downward signal. `spar::Dispatcher cancel <row>` on a queued row drops it before it launches; on a running row it sets a flag the coroutine reads at its next `checkpoint`, where it reports `cancelled` and unwinds. `pause_job` parks the coroutine at the next checkpoint (a yield) and `resume_job` resumes it into a re-check of the cancel flag, so cancelling a paused row takes at the park.

Because a checkpoint is a plain call in the coroutine's own stack, there is no shared-variable sentinel and no thread to signal into. A worker that never calls `checkpoint` is never interrupted, which is the price of never tearing a coroutine out of its own stack. Each of the four worker bodies checks once, at entry, before its harness or send begins; per-stage cancel inside the harness is deferred (below).

A cancel that arrives while the coroutine is parked on a wait (a credit-limit sleep, an in-flight claude call) is not seen until the wait returns and the next checkpoint runs. This is the same timing the sentinel model had, for the same reason: the observation point is the worker's, not the pool's.

## The waits

A worker never blocks the loop on a synchronous read or a bare `vwait`; that would stall every other job in the process. Three helpers in `spar-dispatcher-initcmd.tcl` do the waiting the loop's way, and each falls back to the blocking form when called outside a coroutine (a standalone or a test run), so the same body works in both settings.

| helper | replaces | in a coroutine |
|---|---|---|
| `spar::pool_sleep ms` | `after ms ; vwait` | arm a timer that resumes the coroutine, then yield |
| `spar::pool_exec args` | `exec ... 2>@1` | run the child under deadman (pipe, fileevent), yield, return its merged output |
| `spar::pool_http args` | `http::geturl` | issue with `-command` resuming the coroutine, yield, return the token |

`harness_run`'s claude call is the fourth wait: `spar-harness.tcl`'s `_invoke` runs deadman with `-done [info coroutine]` and yields, so the watchdog's stall clock and budget poll ride the event loop while the coroutine sleeps.

## Enforcement

Two mechanisms.

**No marshalling layer.** `test/test-pool.tcl` §1 reads `spar-dispatcher-initcmd.tcl` and asserts it contains no `thread::send`, no `tsv::`, and no `msg_*` proc, and that `spar::Dispatcher` still carries its four domain `on_*` methods. The marshalling the thread runtime needed cannot creep back in unnoticed.

**State-machine validation in the pool.** Each `on_*` method consults the current row state before mutating it. A report that does not fit the state (a `done` for a queued row, anything after a terminal state) is logged at warning level and dropped, not raised. `test/test-pool.tcl` §8 posts malformed reports directly to the Dispatcher and asserts the drops.

## Deferred and adjacent work

**Per-stage cancel inside the harness.** `harness_run` checks cancel once before the harness starts. A cancel that arrives while a claude call is in flight takes effect after the call returns, at the next checkpoint, not mid-call. deadman can already kill the child on the caller's say-so (`deadman::kill`), so wiring a per-stage cancel through to the running pipe is a smaller change than it was under the thread model; it is deferred only because cancel mid-call has not yet been needed.

**Cancel during credit-limit sleep.** The retry loop in `_with_recovery` now yields the loop for the reset window rather than blocking, so a cancel is deliverable during the sleep. What is missing is a checkpoint after the sleep returns and a fast path that exits the loop instead of looping back to another claude call. Small change; deferred only because cancel during a multi-hour credit sleep has not yet bitten anyone.

**Keychain access dialog.** On macOS the first call to `security find-generic-password` per Keychain item can pop a modal dialog and block the worker until the user dismisses it. Steady-state cost is zero; rotating the SMTP password unattended would re-trigger it. Worth being aware of, not worth code now.

# Concurrency in SPAR Manager

## The problem

A SPAR campaign run is heterogeneous. Profile generation (T1, T3) and approach generation (T2, T4) drive `claude` agents that block for minutes per row, are CPU- and cost-bound, and occasionally hit a credit-limit reset that the worker has to sit through. SES delivery (T6) is network-bound and has to serialise — one auth handshake per SMTP connection, plus the SES rate-limit pacing the campaign configures via `delay`. IMAP polling (T7) is also network-bound but parallelises freely.

A single CLI invocation may take hours: a 30-row T1 batch at the campaign-default `jobs=4` is already a multi-hour run, and `--auto` chains T1 → T2 → T6 → T7 across the same wall clock. The user wants to add and remove work mid-flight in the GUI, see progress without polling, and pause without losing in-flight items. The CLI wants the same row-state machine so it can produce identical output and so the two surfaces share a budget — when the user says `--jobs=8`, eight worker threads is what they expect to see, not sixteen.

A job manager carrying mixed work, real OS-thread parallelism, a per-row state machine, cooperative cancel, and per-worker-kind caps is the smallest thing that satisfies these requirements at once. The rest of this document is what Tcl 9 gives us, the choices we made, and where the resulting code lives.

## What Tcl 9 offers

| Package    | macOS  | Ubuntu | Where it comes from on Ubuntu |
|------------|--------|--------|-------------------------------|
| Thread     | 3.0.4  | 3.0.1  | `apt install tcl9.0-thread`   |
| coroutine  | 1.4    | 1.4    | `tcllib`                      |
| uevent     | 0.3.2  | 0.3.2  | `tcllib`                      |
| TclOO      | 1.3.1  | 1.3.1  | built into Tcl 9              |

The built-in event loop (`after`, `vwait`, `fileevent`, `chan event`) is always available — no `package require`.

Of these, only one gives real OS-thread parallelism. The others matter for different reasons.

- **Thread (with the `tpool::` API)** — real OS threads, each with its own Tcl interpreter; true parallelism across cores. This is what `test/run.tcl` uses to fan test files out across `[exec getconf _NPROCESSORS_ONLN]` workers. Note Thread 2.x had `Tpool` as a separately requireable package; Thread 3.x folded it into the `Thread` package under the `tpool::` namespace, so on Tcl 9 do not `package require Tpool` — it fails. The right shape is `package require Thread` followed by `tpool::create -minworkers N -maxworkers N -idletime 60 -initcmd { ... }`.
- **The built-in event loop** — single-threaded, cooperative. "Concurrent" in the non-blocking-I/O sense, not parallel. Reach for this when the work is I/O-bound and a single core suffices.
- **coroutine** — cooperative single-thread. Lets one task `yield` to another inside the same interpreter. Worth mentioning because the name invites the wrong assumption — coroutines on multi-core machines still occupy exactly one core.
- **uevent** — pub/sub on the event loop. A decoupling tool, not a concurrency primitive; subscribers fire on the same thread that posted.
- **TclOO** — object system. Orthogonal to concurrency, listed only because it sometimes appears alongside the others in capability checks.

## The choices

**tpool for parallelism.** Nothing else gives multi-core. The harness's `exec claude` blocks for minutes per call; the only way to run more than one of them at once is to put each in its own OS thread with its own interpreter.

**`-minworkers` equal to `-maxworkers` (pre-spawn).** The obvious choice is `-minworkers 0 -maxworkers $jobs` and let workers spawn lazily as posts arrive. That is broken: with `-minworkers 0` the Thread package spawns exactly one worker for the pool's lifetime, regardless of post volume, and subsequent posts queue behind that one worker. A 29-row T1 batch at `--jobs=8` ran strictly sequentially over ~8 hours in production before this was caught. The reproducer is `test/test-pool.tcl` §17 ("True parallelism with blocking workers"), which posts four blocking `exec sleep 2` jobs and asserts wall time under 4500 ms; the unit tests that came before only asserted `posted_count` (which counts state flips at `tpool::post` time) and were happy even when no second worker thread ever existed. See `docs/job-pool.md` "Pool sizing" for the diagnosis trail.

**One shared Dispatcher across all transition kinds.** The CLI used to construct one `spar::Dispatcher` per active TID, so `--jobs=4 --tid=T1 --tid=T6` quietly produced up to eight parallel worker threads. The user thinks of the cap as process-wide; per-TID Dispatchers multiply it invisibly. The Dispatcher class itself was always heterogeneous-ready (per-row `worker_proc` and `row_opts`), so unification is a matter of folding every TID's prep into one batch and one pool, not changing the pool itself.

**Per-worker cap.** SES (T6) has to serialise, but it lives in the same shared pool as the parallel workers. The Dispatcher exposes `set_worker_cap <worker_proc> <cap>` as a sub-cap of the global `Jobs`: a row whose `worker_proc` is at its per-worker cap stays queued while other workers' rows continue to post. `dispatch_ready` installs `set_worker_cap ses_send 1` so SES sends serialise alongside parallel harness rows; `_try_post_next` walks the queue rather than popping the head, so a blocked SES row at the front does not block harness rows behind it. Reproducer is `test/test-pool.tcl` §18.

**Heterogeneous CLI grammar.** The old `--tid=T1 --tid=T6 --segment=foo --stem=bar` was homogeneous — one segment list and one stem list applied to every TID. That fits a one-runner-at-a-time mental model, but the shared pool wants per-TID scopes. Positional `Tn[:seg[/stem]]` tokens carry their scope on the token, are repeatable, and mix freely (e.g. `T1 T2:vic T6:vic/jane-doe`). The grammar is parsed in `spar-transitions-cli.tcl` so `test/test-cli-parser.tcl` can drive it without spinning up a campaign YAML.

**Typed message protocol via `thread::send -async`.** Worker threads cannot touch Tk or main-thread state directly; everything goes through a small set of `msg_*` procs in the tpool's `-initcmd` that forward to `on_*` methods on the Dispatcher in the main thread. Downward signals from the Dispatcher to workers go through shared variables (`tsv::`), not messages, because the main thread cannot `thread::send` into a worker that is inside a synchronous `exec`. The full protocol — twelve message types, the row state machine, and the downward sentinel channel — is in `docs/job-pool.md`.

## The classes that result

**`spar::Dispatcher`** in `spar-dispatcher.tcl` — coordinator. Owns the heterogeneous queue, the per-row state map, the global `Jobs` cap, and the per-worker caps. Posts jobs to the tpool by looking up the row's `worker_proc`. Receives messages from worker threads through `thread::send -async` calls into its `on_*` methods. Holds no Tk references and creates no widgets.

**Worker proc family** in `spar-dispatcher-initcmd.tcl` — registered in the tpool's `-initcmd` and so present in every worker thread's interpreter. `harness_run` for the AI-driven transitions, `ses_send` for SES delivery, `imap_poll` for reply checking. Each runs to completion or until it observes a cancel sentinel. Worker bodies are the only callers of `msg_*`; nothing else in worker-thread code may call `thread::send` directly.

**Harness library** in `spar-harness.tcl`, loaded inside `harness_run` only. The validate-and-correct fix loop, credit-limit retry, session-resume bookkeeping, cost ledger. Used by the AI-work worker and only by it. The harness is the body of `harness_run`, not a layer above it.

**`spar::ui::DispatchController`** in `ui/dispatch-controller.tcl` — Tk controller. Owns the Play/Pause/Cancel buttons, the right-click menu on tree rows, and the progress bar. Translates user actions into Dispatcher method calls and renders Dispatcher row-state events back onto the `TransitionTree`. Does not spawn jobs and does not call `thread::send` directly.

The CLI's equivalent is the `dispatch_ready` proc in `spar-transitions.tcl`. Same shape: it consults each transition's `prepare_for_pool`, builds one shared Dispatcher, installs `set_worker_cap ses_send 1`, enqueues every row, and `vwait`s once on a counter the row-state subscriber maintains.

For the message protocol, the row state machine, and the downward sentinel channel, see `docs/job-pool.md`.

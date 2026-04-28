# Pool-based job manager

This document describes the design of the job pool that backs the SPAR Manager's transition table when the table is treated as the in-flight queue. The user stories and the surrounding rationale are in issue #88; this document covers only the chosen mechanism.

The alternative considered was a subprocess framing, in which the harness queue class (now `spar::HarnessQueue`, used by the CLI) would be generalised into a true coordinator above a `Worker` supertype, with `HarnessWorker`, `SesWorker`, and `ImapWorker` as siblings. It was set aside on clarity grounds: the `tpool`-based design is harder to misread, and the failure modes the subprocess form wins on — per-row kill of an in-flight claude call, exit from a credit-limit sleep — are deferred to a later harness migration that will move synchronous `exec claude` to `open "| …"` plus `fileevent`. The deferred-work section at the end lists the migration explicitly so the option is not lost.

## Layers

**Dispatcher** (main thread, TclOO class). Owns the heterogeneous queue of pending rows, the global concurrency cap, and the per-row state map. Posts jobs to the tpool by looking up the worker proc associated with the row's transition kind. Receives messages from worker threads through `thread::send -async` calls into its `on_*` methods. Holds no Tk references and creates no widgets.

**Worker proc family** (registered in the tpool's `-initcmd`). One proc per kind of work: `harness_run` for AI-driven transitions, `ses_send` for SES delivery, `imap_poll` for reply checking. Each proc runs in a tpool worker thread with its own Tcl interpreter and shares no state with the main thread other than the message protocol below. No worker proc owns the queue; the Dispatcher posts the proc, the proc runs to completion or until it observes a cancel sentinel.

**Harness library** (loaded inside `harness_run` only). The present `spar-harness.tcl` body — the validate-and-correct fix loop, credit-limit retry, session-resume bookkeeping, cost ledger. Used by the AI-work worker and only by it. The SES and IMAP worker procs do not import it. The harness is not a layer above the worker; it is the body of the worker for AI-work transitions.

**Controller** (Tk, GUI). Owns the Play, Pause, and Cancel buttons, the right-click menu on tree rows, and the progress bar. Translates user actions into Dispatcher method calls. Reads the Dispatcher's per-row state map for rendering. Does not spawn jobs and does not call `thread::send` directly. The `TransitionTree` and `CampaignModel` layers above are unchanged from their present roles.

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

The transition from `queued` to `running` happens at the moment the Dispatcher posts the row to the tpool, not when the worker thread sends back a confirmation. There is no `msg_started` message; the worker's first action is whatever real work the row needs. This avoids a race where the row's state lagged behind its actual dispatch by the duration between `tpool::post` and the worker's first scheduled instruction.

`rate_limited` and `paused` are waiting states. The worker thread is alive; it is sitting in a `vwait` on a sentinel or an `after` schedule. Both count against the global `Jobs` cap because the tpool slot is occupied.

There is no `killed` state. The tpool offers no thread-cancellation primitive, and the harness is not yet structured to permit it. Cooperative cancel — the worker observes a sentinel between safe points and exits as `cancelled` — is the only way out of `running` other than the worker's own terminal message.

## Messages from worker to Dispatcher

Every message is sent by calling a proc named `msg_<name>` defined in the tpool's `-initcmd`. The proc constructs the typed payload and forwards via `thread::send -async $::main_tid [list $::dispatcher on_<name> ...]`. Worker bodies do not call `thread::send` directly; the enforcement section below explains why.

### Universal — sent by every worker proc

| message | when | row state effect | payload |
|---|---|---|---|
| `phase` | worker entered a labelled phase | none | row, phase_name |
| `progress` | informational subtitle text for the UI | none | row, text |
| `done` | terminal success | running / paused / rate_limited → done | row, result_dict |
| `failed` | terminal failure | running / paused / rate_limited → failed | row, reason |
| `cancelled` | worker observed cancel sentinel and stopped at a safe point | running / paused → cancelled | row |
| `roster_update` | request a serialised mutation of a roster TSV (the present `ROSTER_UPDATE` protocol) | none | row, roster_path, key_col, key_val, field, new_val |

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

The Dispatcher cannot `thread::send` into a worker that is inside a synchronous `exec`; the message would queue indefinitely and would not be processed until `exec` returned of its own accord. Downward signals are therefore shared variables, not messages. One `tsv::array` per row, keyed by signal name.

The initcmd exports two helpers the worker is required to use rather than reading the tsv directly:

| helper | returns true when |
|---|---|
| `worker_cancel_requested? row` | Dispatcher has set the row's cancel sentinel |
| `worker_pause_requested? row` | Dispatcher has set the row's pause sentinel |

The harness checks both at the top of `_invoke`'s outer loop and between `validate_and_correct` passes. The SES and IMAP worker procs check `worker_cancel_requested?` between rows or between IMAP polls.

A cancel issued before the row was posted to the tpool is handled in the Dispatcher: the row is removed from the queue without `tpool::post` ever being called, and the worker never sees it. A cancel issued after `started` but during a `vwait` — credit-limit sleep, pause sentinel — is delivered when the `vwait` returns, so the harness must check the sentinel at every `vwait` exit point, not only at the top of the loop.

## Enforcement

Three mechanisms, in order of strength.

**Single send surface in the worker.** Workers call `msg_*` procs only; they do not call `thread::send` directly. A pre-commit grep — `grep -n 'thread::send' transitions/*.tcl spar-harness.tcl` — must return only matches inside `msg_*` proc bodies. Anything else is a violation.

**Sender and receiver shape mirror.** For every `msg_<name>` defined in the initcmd, the Dispatcher class defines a public method `on_<name>` with the same arity. A test in `test/test-pool.tcl` enumerates both sets through introspection (`info commands msg_*` and `info class methods spar::Dispatcher`) and asserts they match. The "added a message but forgot to handle it" mistake is caught at test time rather than runtime.

**State-machine validation in the Dispatcher.** Each `on_*` method consults the current row state before mutating it. Out-of-order messages — `on_phase` before `on_started`, anything after a terminal state — are logged at warning level and dropped, not raised. A pure-Tcl test fixture posts malformed sequences directly to the Dispatcher, bypassing the tpool, and asserts the violations are detected.

The protocol tables above are the single source of truth for the message set. Adding a new message means editing this document, the initcmd, and the Dispatcher class together. The introspection test fails if any of the three drift.

## Open items

**`progress` versus `phase`.** The harness today emits both `[phase: …]` markers and ordinary stdout chatter. If the UI does not need a per-row subtitle distinct from the phase label, drop `progress` and route any non-phase chatter to a separate `log` message that does not touch row state. To be decided when the Controller's render path is ported.

**Timing of `credit_warning`.** Listed in the protocol now so the Dispatcher can grow its handler in the same pass, and the harness can emit it later without the receiver needing to be revisited. The harness change itself — parsing the remaining-credit field in `_invoke`'s parsed JSON — is deferred.

## Deferred work

Named here so the design is not retrofitted in surprise.

**Per-row kill of in-flight claude calls.** Requires migrating `_invoke` from synchronous `exec claude` to `open "| claude …"` plus `fconfigure -blocking 0`, `fileevent`, and `vwait`. With the pipe channel the worker thread is event-loop-driven during the call, the child PID is available via `pid $pipe`, and a kill request arrives in real time and can run `exec kill -TERM [pid $pipe]`. Not in scope for the first cut because the blocking `exec` sites the codebase has today — `spar-harness.tcl:161`, the two `mailroom` calls in `spar-mailroom.tcl`, and the keychain lookups in `transitions/send_email.tcl` — are all acceptable to "let finish" in current usage.

**Cancel during credit-limit sleep.** The retry loop at `spar-harness.tcl:171-184` already uses `vwait ::_wake` after `after`, so the event loop is running and `thread::send` already gets through. What is missing is a cancel check after the `vwait` returns and a fast path that exits the loop instead of looping back to another claude call. Small change; deferred only because cancel during a multi-hour credit sleep has not yet bitten anyone.

**Keychain access dialog.** On macOS the first call to `security find-generic-password` per Keychain item can pop a modal dialog and block the worker until the user dismisses it. Steady-state cost is zero; rotating the SMTP password unattended would re-trigger it. Worth being aware of, not worth code now.

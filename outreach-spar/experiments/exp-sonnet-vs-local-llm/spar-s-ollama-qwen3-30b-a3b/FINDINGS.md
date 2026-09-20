# S-phase on local inference: what the run found

Written 2026-09-20, with the sweep still running. The timing and defect findings below are settled and do not depend on its outcome. The roster comparison does, and is not here yet.

## The short answer

The model is not the constraint. The harness is.

`qwen3:30b-a3b` on dappnode answers a short direct prompt in 3 seconds at 18 tokens per second, and writes a competent technical explanation unprompted. What makes a SPAR sweep infeasible on it is that the dispatcher spawns a full agent session per worker, so every turn re-sends the entire system prompt and tool catalogue before the model reads a word of the task. That cost is invisible on a hosted model and dominant here.

## The numbers

A worker's prompt measures 22,578 tokens. A trivial prompt through the same path measures 15,950, so roughly 16k of every call is fixed overhead and the task itself is the remainder.

Prefill does not run at the rate the hardware benchmark suggests. `local-inference/README.md` reports 94 tokens per second of prefill at 2,048 tokens on dappnode. Measured against real prompts, ollama reports 42 at 2,048, 35 at 4,096, 30 at 6,144 and about 20 by 12,000 to 14,000. The published figure is not wrong and does not overstate anything: the document names its command, `llama-bench -p 512,2048`, and says plainly that its figures are prefill at 2048 tokens. The error was reading the number without the conditions printed beside it, and every estimate here that used 94 was optimistic about threefold as a result.

At 20 tokens per second, one worker turn is roughly 19 minutes of prefill. Workers run two to three turns. T0 dispatches one worker per census source, which across the five seeded segments is 35 workers, confirmed by the dispatcher's own dry run at 35 of 35 validated.

A worker's turns do not get cheaper as it proceeds.

A complete turn measured about 21 minutes prefilling and roughly 39 minutes generating before the sixty-minute cut, so generation is not the small half once the model is writing for real. It emits its reasoning as prose before answering, at around 15 tokens per second, and pays for every word. Observed on a live worker, the prompt grew from 22,578 tokens on its first turn to 32,209 on a later one, while prompt caching reused 10,261, leaving about 22,000 new tokens to prefill either way. The conversation grows about as fast as the cache saves, so each turn costs roughly the same as the first.

So one segment of six workers is four to six hours, and the full set is 22 to 33 hours. Generation is not the cost; decode measured 14.99 tokens per second on a 1,106-token answer, and a worker generates far less than it reads.

Ollama serves one slot on this configuration, so `--jobs` buys nothing. Everything serialises whatever the dispatcher is told.

## Five defects worth more than the timing

Each of the four produces the same symptom, which is that nothing happens. That is why three of them were diagnosed as the last one's recurrence before being seen as separate.

**The router mangles any argument containing punctuation.** `ccr <preset> "$@"` re-spawns the CLI through `child_process.spawn` with `shell: true`, which joins the argument array into a single string for `/bin/sh -c` without escaping. A bare prompt survives. A sweep prompt does not, because it carries apostrophes and parentheses, and the result is `/bin/sh: Syntax error: end of file unexpected` with exit 2 in zero seconds. Node's own DEP0190 deprecation warning, printed on every call, is warning about precisely this. The fix is to set `ANTHROPIC_BASE_URL` to the router's preset endpoint and exec the real binary with the arguments untouched. This affects any caller passing prose through that path, not only this dispatcher.

**The wrapper started the router before exporting the timeout fix.** It called `ccr start` at line 128 and exported `NODE_OPTIONS` with the preload at line 146, so every daemon it started was born without the raised timeout and every call reverted to the 300-second default. This was declared fixed twice on evidence that did not bear on it: once against a daemon that had been started another way, and once by watching a single request survive 25 minutes, which showed the preload could work rather than that it was loaded. The check that settles it is reading `NODE_OPTIONS` from the environ of whatever is listening on the router's port.

**The wrapper's `ccr start` guard blocks when it has to start a daemon.** It is instant when one is already up, which is the case it was written against. When it genuinely starts one, it holds the foreground, the wrapper never reaches its `exec`, and no worker runs at all. The dispatcher logs the job as started, the worker's log stays at zero bytes, and the process tree shows a child that reads as the worker and is the router. Bring the daemon up separately before any dispatcher, and the guard becomes the no-op it was meant to be.

**The router aborts every request at sixty minutes, and the value is unreachable from configuration.** Three consecutive worker turns ran to 59m58s, 59m59s and 59m58s and were cut. The source carries `AbortSignal.timeout(r.TIMEOUT ?? 60*1e3*60)`, so sixty minutes is a fallback, but a grep of the whole bundle finds `.TIMEOUT` written nowhere: not from a provider entry, a preset manifest, the top-level configuration, or any environment variable. The only route that reaches it without patching vendored code is a custom transformer, whose `transformRequestIn` may return `{ body, config }`, and that `config` merges into the request options. Our existing plugin now supplies ninety minutes that way. Note that `API_TIMEOUT_MS` is a different timeout, governing the spawned CLI's patience with the router rather than the router's own outbound call.

**Ollama does not stop generating when its client disconnects.** A killed client leaves its request holding the single slot for the full remaining prefill, starving everything behind it. This happened twice during the run and each time looked like a hang elsewhere. Restarting the service is the reliable way to clear it. Killing a client is not stopping the work.

## Two client timeouts, stacked

Calls were dying at exactly five minutes with a 500. The router's own outbound timeout was already an hour, so it was never the constraint. The limit is Node's global fetch dispatcher, undici, whose headers timeout defaults to 300 seconds and which the router exposes no setting for; it fires while the model is still prefilling and has sent nothing. Behind it sat the CLI-to-router timeout at ten minutes, also under what one call costs. Either alone produces the same symptom, which is why the first diagnosis looked complete and was not.

With both raised, a request held open for 25 minutes and ended only when its client was killed.

## What this says about the comparison

The arm was set up to hold the segments constant and vary the model. It cannot report on the model until a worker completes, and the timing above is why none had when this was written.

It can report something the experiment did not set out to ask. A dispatcher that pays a fixed five-figure token cost per worker turn is an architecture tuned to a fast, cheap, hosted call. Porting it to local inference is not a matter of pointing it elsewhere. The per-call overhead has to come down first, either by reducing what each worker is sent or by not spawning a fresh session per source.

## Levers not pulled

The 128k context was inherited from another machine's setup rather than chosen for these prompts, which fit in a quarter of it. A smaller context would shrink the KV cache and may let ollama serve more than one slot, which is the only route to real parallelism here. Worth measuring before the next arm.

The tool catalogue is 15,353 tokens of the fixed cost across 38 definitions, and ten of those account for about 10,700. A worker that needs six tools is paying for thirty-eight on every turn.

## The lever, measured

The tool definitions can be cut, but not with the flags the dispatcher currently uses. Measured against a capture endpoint, counting with `cl100k_base`:

| invocation | tools declared | tool-definition tokens | whole request |
|---|---|---|---|
| no flags | 38 | 15,754 | 32,257 |
| the dispatcher's current flags | 43 | 17,547 | 33,778 |
| `--tools` with six built-ins | 20 | 3,960 | 16,529 |
| `--tools` plus `--strict-mcp-config` | 6 | 2,598 | 14,835 |

The dispatcher's own flags make the request larger than passing nothing. `--allowedTools` adds permission metadata and never removes a definition, and naming a tool outside the default catalogue makes the server declare it in full. `--disallowedTools` drops a definition only when the name is bare; a scoped exclusion such as `Agent(general-purpose)` leaves the parent tool's entire schema in the request.

`--tools` with an exact list governs what is declared rather than what is permitted, and `--strict-mcp-config` drops tools contributed by MCP servers. Together they cut the captured request by 37%.

**That saving does not survive the router.** Applied to a live worker, the prompt reaching ollama went from 22,578 tokens to 21,678, a cut of 4%. The table above was captured by pointing the CLI straight at a capture endpoint, and the router path is not the same request: a trivial prompt measures 40,337 tokens captured directly and 15,950 as ollama receives it. The router is already dropping most of what the capture counts, so trimming the tool list removes something that was largely not being sent. The measurement was taken on the wrong path, and the same mistake had already appeared once tonight before being repeated here.

What remains true is the shape: `--allowedTools` enlarges a request and `--tools` shrinks it. What is not true is that this makes the sweep feasible. At 21,678 tokens the cost per turn is essentially unchanged.

A larger lever sits beside it and was not adopted. `--safe-mode` collapses the system-prompt portion from 18,370 tokens to 3,853, more than the tools fix saves, by disabling skills, hooks and MCP entirely. Whether a sweep worker can work without those is a question for whoever owns the dispatcher, not one to settle by measurement alone.

These figures come from a session in this repository with its plugins loaded, so the absolute numbers are local. The direction and the proportions are the finding.

## What would make this work

The costs above are not evenly distributed, and that decides where effort is worth spending.

**The fixed preamble is the target, not the machine.** About 16,000 tokens of every 22,578-token turn is the same system prompt and tool catalogue, re-sent because each worker is a fresh agent session. A faster box divides that cost; removing it deletes it. The measured trim of the tool list, which is the only lever reachable without changing the dispatcher, recovered 4% on the real path, so the remaining saving lives in the architecture rather than in configuration.

**One worker per census source is the expensive choice.** T0 spawns 35 sessions for five segments, and each pays the preamble afresh. A worker that took a segment's whole source list in one session would pay it once per segment instead of once per source, cutting the fixed cost by roughly the ratio of sources to segments, which here is seven to one. Nothing about the sweep's logic requires a session boundary at each source; that boundary exists because it is cheap on a hosted model.

**Generation is not free here either.** A turn measured 39 minutes of writing against 21 of reading, and the model spends much of it composing reasoning as prose before the answer. A model that returns reasoning in a separable field, or a prompt that forbids it, recovers a large share of that without touching anything else.

**Concurrency is the only lever that divides rather than subtracts, and it is untested.** The 128k context puts the resident footprint at 32 GB of 62, which is why ollama serves one slot and why `--jobs` changes nothing. Worker prompts are 22k. A 32k-context variant is built and waiting; if it admits two or three slots, the wall-clock divides by that. This is the first thing to measure next, because every other finding here is about the cost of one turn and this one is about how many turns run at once.

**What the hardware is not.** Nothing measured tonight argues the model is unfit. It answered a short prompt in 3 seconds and wrote competently. The question this arm could not reach, whether its roster rows are any good, remains open, and reaching it needs the changes above rather than more patience.

## The timeouts are the story

Seven distinct limits cut a request short tonight, each hidden behind the one above it, each revealed only when its predecessor was lifted.

Node's global fetch dispatcher at 300 seconds, undocumented by the router and not exposed as a setting. The CLI-to-router limit at ten minutes. A wrapper that started the router daemon before exporting the fix for the first of these, so every daemon it started reverted. The router's own abort at sixty minutes, reachable only through a transformer that a preset route never runs. And, once the router was removed entirely, a further cap near six minutes on the direct path, with the CLI carrying a ninety-minute setting and ollama carrying none.

Two more belong to the same family without being timeouts: a guard that blocked instead of starting a daemon, so no worker ran at all, and a server that keeps generating after its client disconnects, so a killed request holds the only slot for its full remaining prefill.

None of these is a bug in the sense of being wrong. Each default is sensible for a hosted model answering in seconds. Together they encode an assumption that a request completes in minutes, and a model taking an hour per turn violates it at every layer independently. Lifting one reveals the next, and the sequence gives no sign of being finished.

That is the practical finding for anyone porting this stack to local inference. The work is not tuning a timeout. It is that the per-turn cost has to come down to where the stack's assumptions hold, which means not re-sending a five-figure token preamble on every turn.

## Why every layer fires: time to first byte, not total time

The seven limits look like a series of unlucky ceilings. They are one problem seen seven times.

Prefill produces no output. A worker's prompt of 18,000 to 22,000 tokens takes fifteen to nineteen minutes to read at the rate this hardware achieves, and during all of it the connection is silent. So time-to-first-byte here is fifteen minutes or more, and any limit shorter than that fires before the model has said anything, whatever the total request budget is set to.

That is why the 300-second dispatcher limit, the six-minute cap on the direct path and the ten-minute client limit all bite identically, and why raising a total-duration setting did not help against them. Streaming does not help either: a streamed response still sends its first chunk only after prefill.

It also explains which fix worked. The sixty-minute router abort was a total-duration limit, and raising the two limits around it let a turn reach 59m59s. The limits that measure silence cannot be satisfied by any budget while prefill stays this long.

So the number to attack is not the timeout and not the total turn cost. It is the prompt that has to be read before anything can be emitted.

## Most of the preamble is the operator's own context, not the tool's

Captured in the real worker directory with the workers' own tool flags: 26,608 tokens without `--safe-mode` and 9,128 with it. The system field accounts for 1,300 and the eleven tool definitions for 5,640, unchanged either way. The difference is entirely in the messages, which fall from 19,668 tokens to 2,656.

What occupies those 19,668 tokens is an operator-side methodology injected at session start, around 53 KB, together with the repository's own instruction files at around 27 KB, and the catalogue of installed skills. None of it is Claude Code's baseline, and none of it is cited by the sweep task.

That revises an earlier conclusion here. Trying a bare working directory changed the prompt by three tokens, which was read as evidence that the cost was inherent to the tool. It was not: the injection is installed globally rather than per-directory, so changing directory could not have moved it.

Projected onto a worker, this puts the prompt near 3,677 tokens and time-to-first-byte near three minutes, inside every limit in the stack. The timeouts stop mattering because the silence they measure is no longer there.

## What the flag costs, and to which sweeps

Not uniform, and the distinction is sharp.

Sweeps of the open web, registers and directories use WebSearch, WebFetch, Read, Write, Edit, Bash, Grep and the subagent tools. The flag touches none of them, and those workers lose nothing.

Sweeps of signed-in platforms lose their only working mechanism. Transcripts show workers invoking platform skills for Instagram and Facebook as a matter of course rather than as a possibility, and those skills carry the authenticated session and the site-specific navigation. The methodology provides a fallback for the generic browser pacing, so losing that alone is an inconvenience. It provides no substitute for an authenticated session, and no built-in tool can sign in.

So the practical shape is a split rather than a switch: the majority of sweeps can run in safe mode at a fifth of the prefill cost, and platform sweeps need either their own path or a pre-authenticated fetch that does not depend on a plugin being loaded.

## The router was never needed, and the fix that was checked most was never running

Ollama 0.34.2 speaks the Anthropic Messages API natively. Pointing the CLI's base URL at ollama's bare origin returns a properly shaped message, so the router's one genuine function, protocol translation, was redundant. Its sixty-minute cap, its shell-based argument reconstruction and its field-stripping transformer were faults, not capabilities. Removing it cost nothing. The base URL takes no `/v1` suffix, because the CLI appends the path itself and doubling it produces a 404.

The installed `claude` binary is compiled with Bun, and Bun ignores `NODE_OPTIONS`. Demonstrated by pointing it at a script that throws unconditionally and watching the binary run clean. So the preload that raises Node's fetch timeouts, described in its own comments as load-bearing, never executed at any point. Every check that read `NODE_OPTIONS` from a process environment confirmed the variable was set and proved nothing about whether it was honoured. `BUN_OPTIONS` is the name this binary reads.

The limit that actually cut requests short on the direct path is `CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS`, named in the CLI's own error text and defaulting to about six minutes. It measures exactly the silence that prefill produces, which is why raising every total-duration budget in the stack had no effect on it.

So of the seven limits, the one that mattered most is the one named for the quantity the arithmetic identified, and the fix applied hardest was inert the whole time.

## Safe mode, measured rather than projected

A worker's prompt under `--safe-mode`, as ollama reports it: 10,178 tokens, against 24,985 without. A 59% cut.

The projection here was 3,677, arrived at by applying the delta from one capture to a baseline taken from another. It was wrong by nearly threefold in the optimistic direction, for the same reason the earlier 54% tool-trim claim was: a capture taken on one path does not describe a request sent on another, and a delta borrowed between them compounds the error.

10,178 tokens is still a real improvement. At the prefill rates the direct path reaches it is a few minutes of silence rather than fifteen, which is what the limits measure.

The general lesson for this experiment's numbers: every figure that came from a capture has been optimistic, and every figure that came from ollama's own log of a real request has held. Prefer the latter, and treat a projection as a hypothesis to check rather than a result to report.

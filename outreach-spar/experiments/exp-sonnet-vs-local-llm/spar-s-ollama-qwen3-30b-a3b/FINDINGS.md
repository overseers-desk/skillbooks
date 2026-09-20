# S-phase on local inference: what the run found

Written 2026-09-20, with the sweep still running. The timing and defect findings below are settled and do not depend on its outcome. The roster comparison does, and is not here yet.

## The short answer

The model is not the constraint. The harness is.

`qwen3:30b-a3b` on dappnode answers a short direct prompt in 3 seconds at 18 tokens per second, and writes a competent technical explanation unprompted. What makes a SPAR sweep infeasible on it is that the dispatcher spawns a full agent session per worker, so every turn re-sends the entire system prompt and tool catalogue before the model reads a word of the task. That cost is invisible on a hosted model and dominant here.

## The numbers

A worker's prompt measures 22,578 tokens. A trivial prompt through the same path measures 15,950, so roughly 16k of every call is fixed overhead and the task itself is the remainder.

Prefill does not run at the rate the hardware benchmark suggests. `local-inference/README.md` reports 94 tokens per second of prefill at 2,048 tokens on dappnode. Measured against real prompts, ollama reports 42 at 2,048, 35 at 4,096, 30 at 6,144 and about 20 by 12,000 to 14,000. The published figure describes a small prompt and overstates a large one about threefold.

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

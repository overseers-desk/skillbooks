# S-phase on local inference: what the run found

## In plain terms: what this model on dappnode can do in SPAR, as of 08:40 on 22 September 2026

The question was what SPAR work a local model can take off hosted Claude, given that hosted Claude costs too much and most SPAR work runs overnight. The condition was that dappnode never idled. Two nights of running the sweep and one night of direct tests give this answer; the numbers behind each line are in the sections below, in the order they were learned, and this section is rewritten as results land.

**The sweep as the harness runs it, one agent session per source: no.** On this hardware a worker's turn at the 13,000 tokens of context a sweep reaches after two file reads generates at one token a second, and this model thinks for thousands of tokens before its first tool call, so a turn is an hour and the client aborted one at its own ninety-minute limit with the model still writing. A source needs ten to twenty turns. Across two nights the whole-task sweep finished one source, a directory, with two honest rows, and declared a register unreachable that a plain fetch reads in full and the hosted arm rostered eleven clubs from. The built-in web search does not exist under the bridge at all, so the source that gave the hosted arm half its rows cannot be worked this way.

**Reading and judging a small piece of text, with the searching and fetching done elsewhere: yes, within limits.** With thinking off, this model moves its deliberation into the answer and runs out of budget before writing anything, twice out of two. With thinking on and a context of two to three thousand tokens it decodes at eight or nine tokens a second, and a rating-only call on a July profile returns a star rating with a rubric-grounded justification in three to ten minutes: on ten of the twelve July contacts the mean absolute difference from Sonnet's rating is 0.60 stars, four exact matches, none further than one star off, a slight lean low, at two to four minutes of box time each once the box was free (two calls that spent their whole cap thinking are re-queued). The same pattern extracts roster rows from a page section: given the zone of the pony club register that holds the catchment, with the segment definition, thinking on and room to finish, the model returned eleven rows in twelve minutes, the same eleven clubs the hosted arm rostered from that page, each with the secretary's name, phone, email and locality as the page gives them, no club wrongly included, and one blemish where a self-correction leaked into a phone cell. The hosted arm's source was scoped to zone 2 by name, so zones beyond it have no hosted key; there the model included every club of the Darling Downs zone, which the catchment does name, and every club of the Ipswich and Lockyer Valley zone, which it names only in part, with confident and wrong regional labels, Rosewood as Logan, Gatton as the Darling Downs, Oakey as the Brisbane horse belt: it reads a page faithfully and judges the catchment by its words alone and generously: across five zones and fifty-one clubs it excluded one, for a missing contact name; "Darling Downs" reached Taroom and Wandoan, four hundred kilometres from the estate, and on the Sunshine Coast zone it rostered all fifteen clubs with a generic reason and no geography checked at all. A locality check against the catchment belongs after it, mechanical and cheap, and on this evidence it is not optional. Given the whole page at once, or three zones at once, or one zone with a small cap, it deliberated club by club and ran out of budget before writing a row: the piece has to be small and the cap has to fit the thinking, which runs to about 150 tokens per entry judged. From a page of search listings, title, URL and snippet only, it does the same: eight equine-vet queries, one per catchment locality, took 65 minutes of box time in all and gave 29 rows, six of the hosted arm's eight equine vets among them; the two it did not find sit in localities the queries never covered. Sixteen rows the hosted arm did not have were fact-checked blind: every one is a real practice, fifteen sit in the catchment, one is on the Sunshine Coast where the reading itself had placed it, two are general practices rostered as equine on a snippet's say-so, and two are one clinic under two names. Its errors are the ones a reader of snippets makes, and each is caught by a step the hosted arm takes and this call was not given: a fetch of the candidate's site, and a locality check against the catchment.

**A whole facts-fed profile in one call: yes, at 38 minutes.** With thinking on and a 16,000-token cap the model wrote the July profile for the first contact: all nine sections in the prescribed shape, from the facts and nothing else, a rating of 3 where Sonnet gave 4, after 6,500 tokens of thinking and 1,500 of profile, 38 minutes with the box to itself. One field is wrong, the co-host's name in the contact field. The July condition, thinking off at a 4,096-token cap, and thinking on at 6,000, both produced nothing. Beside the five July versions under random codenames, a blind judge ranked it third of six on this contact: below Sonnet and the July llama 8B, above the July qwen2.5 14B, the Qwen3.5 35B live run and the qwen3 8B, docked for the wrong contact name and credited for saying plainly that the on-topic signal was not met. One contact and one judge; the other eleven wait on the box.

**A live profile with the tools the bridge gives: honest and mechanically wrong.** On a roster row with a name and a phone number the worker made three web searches, all of which returned unavailable, reported truthfully that it had found nothing, then wrote its profile as a text reply instead of a file, front matter after body, and the validator refused it. The fix attempt's outcome follows below.

**What to share, on this evidence.** The reading and judgement steps at small context, one call each, with search results and page text supplied by something else and the deliverable's mechanics handled outside the model: rating, and, if the running tests confirm it, extraction of rows from a supplied page section. Not the agent loop, not anything that needs the model to search the web, and not anything whose context passes ten thousand tokens.

**What it costs.** Prefill 20 to 27 tokens a second whatever the size; decode 7 to 9 tokens a second at 2,000 to 6,000 tokens of context and about 1 at 13,000 to 15,000. A rating call runs three to ten minutes of box time and the model's thinking varies from 700 to over 3,000 tokens on the same prompt shape, so a cap that fits one call starves another. The model server serves one request at a time, so everything queues. On the hosted side, a sweep worker on this campaign has cost 1.75 to 3.70 USD per source in multi-worker launches.

**What defeats it.** Context size, which sets the decode rate; its own deliberation, which it cannot be told to skip; tools declared to it that have no provider under the bridge; and the mechanics of a deliverable, which it narrates rather than performs.


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

## The six-minute limit is total duration, not first byte

Cutting the prompt from 24,985 tokens to 10,178 did not change the outcome. The request was still cut at 6m0s. At the direct path's prefill rate that prompt is under two minutes of reading, so the first byte had long arrived and roughly four minutes of generation followed before the cut.

That refutes the first-byte account offered above. The arithmetic was right about prefill's silence and wrong about which limit was binding. `CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS` is set to 5400000 in the worker's own environment and the cut is unchanged, so either that name is not honoured by this Bun-compiled binary or it governs something else.

What is established: a limit near 360 seconds ends the whole request, it is not the router's (the router is gone), it is not ollama's (which has no such setting and logs the client as the party that left), and it is not satisfied by reducing the prompt. Its source is not located.

What follows for the workload: a turn needs longer than six minutes on this hardware even with the preamble stripped, because generation alone runs past it. Shrinking the prompt helps the arithmetic and does not clear the constraint.

Recorded as unresolved rather than carried further. Ten limits have been found by lifting the one above, each time revealing another, and the sequence has not converged. The remaining value is in the architectural change already identified, not in locating an eleventh.

## Correcting the correction: it is first byte after all, and the threshold is about 7,000 tokens

The section above concluded the six-minute limit governs total duration. That was wrong, and one observation settles it: a request completed with a 200 after 8m23s, comfortably past six minutes. It was a retry that hit full prompt cache, so it skipped prefill and began generating immediately. Every request cut at 6m0s was one that had to prefill first.

So the limit measures silence, as the arithmetic originally said. What misled the intervening conclusion was the prefill rate: 99 tokens per second came from a progress line on a partially cached request, and the uncached rate is nearer 20. At 20, a 10,178-token prompt is about 8.5 minutes of silence, which is over the cap rather than under it. Safe mode moved the prompt in the right direction and stopped short of the line.

That gives a concrete threshold. Prefill has to finish inside roughly 360 seconds, which at the uncached rate is about 7,000 tokens. The measured safe-mode prompt is 10,178, so it misses by around 3,000 tokens, or by about 30%.

Three observations now agree, where two accounts previously conflicted: uncached requests with large prompts are cut at the cap, a fully cached request ran well past it, and lowering the prompt from 24,985 to 10,178 shortened the silence without clearing the threshold.

The rate figure is the lesson. A single progress line from a cached request described a speed the workload does not get, and using it inverted the diagnosis for several hours.

## It runs: 6,207 tokens, a completed turn, a tool call

Trimming the tool list to six (WebSearch, WebFetch, Read, Write, Bash, Agent) brought a worker's prompt to 6,207 tokens, under the threshold. The request completed with a 200 after 9 minutes 42 seconds, and the worker then invoked its first tool.

That settles the diagnosis for good. The total ran well past six minutes and survived, because prefill finished inside the cap and the first byte arrived in time. The limit measures silence, not duration.

The reduction, in three measured steps from a starting point of 24,985 tokens: removing the router changed the path without changing the size but deleted three faults; `--safe-mode` dropped the operator's own injected context and reached 10,178; trimming eleven tool definitions to six reached 6,207. Each figure is ollama's own count of a real request, not a projection, after two projections proved optimistic by threefold.

The margin is thin. 6,207 tokens is about 5.2 minutes of prefill against a 360-second limit, and a worker's later turns grow: the second turn measured 7,513. The configuration works and is not comfortable, so the architectural fix stands: a worker per segment rather than per source pays this cost five times instead of thirty-five, and buys headroom instead of spending it.

## Turns chain, and caching pays for the growth

The worker completed a second turn as well, a 200 at 10m41s on a 7,513-token prompt, and went on to a third at 8,644. Its tool calls so far are `Read` then `WebFetch`: reading its instructions, then fetching a source. That is the sweep doing what it exists to do.

The growth was expected to be fatal and is not. At the uncached rate a 7,513-token prompt is over six minutes of prefill, which should have breached the cap. Prompt caching carries the shared prefix between turns, so only the new portion is read, and the silence stays under the limit even as the conversation grows.

That revises the threshold from a hard ceiling into a first-turn constraint. What has to fit under the cap is the opening prompt, because every turn after it reuses most of what came before. A worker per segment, carrying more sources through one conversation, is therefore better placed than the per-source design in a second way: it pays the uncached opening once and then rides the cache.

## `--tools` and `--allowedTools` do different jobs, and you need both

Trimming the tool list to get under the prefill threshold meant stripping the dispatcher's `--allowedTools` along with its `--disallowedTools`, and passing `--tools` with six names instead. The prompt came down and the worker was then refused every tool it tried.

The two flags are not alternatives. `--tools` governs which definitions are sent, which is what costs tokens. `--allowedTools` grants permission to call them. With `--permission-mode dontAsk`, which the dispatcher passes, a tool that is declared but not permitted is refused outright rather than prompting.

The model diagnosed this itself, and its output is the best evidence so far about its quality: it named the three tools it had been refused, said what each was needed for, and listed the four things it could not compute without them, including counting entries against the market estimate.

Passing both flags with the same six built-in names costs about eight tokens, because naming a built-in adds permission metadata and no new definition. The prompt went from 6,207 to 6,215 and the worker began fetching sources.

## With the preamble gone, generation becomes the bottleneck

Harvested over the working configuration: generation 81.7 minutes against prefill 76.8. Through the router, with a 22,578-token prompt, prefill dominated generation by roughly five to one. Cutting the opening prompt to 6,215 tokens removed most of the reading cost and left the writing cost where it was, so the two are now level and generation is marginally ahead.

Queueing cost is zero over this window, against 47,109 seconds earlier, which reflects runs that complete rather than a pile of abandoned callers contending for the single slot.

That moves the next lever. Prompt size was the thing worth attacking and is now largely spent; further trimming buys less than it did. What is left is that the model composes its reasoning as prose before answering, at roughly 15 tokens per second, and pays for every word of it. A model that returns reasoning in a separable field, or a prompt that forbids it, attacks the half that now dominates.

The wall-clock figure over this window, 8.79 hours against 2.64 hours of compute, is not a property of the workload. It counts the intervals when the machine sat idle between my own diagnoses and restarts.


## Reasoning is separable on the path that matters

An earlier note here recorded the model returning its reasoning as untagged prose, and judged that worse than tagged reasoning because nothing could strip it by rule. That holds for ollama's `/api/generate` endpoint, where the observation was made, and not for the path the workers use.

On the Anthropic Messages API path, the worker's stream carries `thinking` and `tool_use` as distinct content blocks. The reasoning arrives structurally separated, so it does not contaminate a deliverable and needs no stripping.

It still costs generation time, which now exceeds prefill, so it remains the place to look for speed. What it is not is a quality problem, and the earlier note overstated it by generalising from one endpoint to another.

## The margin is too thin, and the cap turns into a retry tax

The working configuration completes turns, but not on the first attempt. A representative stretch: 500 at 6m0s, 500 at 6m0s, 500 at 6m0s, then 200 at 17m13s. The uncached attempt is cut at the cap; the retry inherits a warm cache, so its prefill is short, the first byte arrives in time, and it runs to completion.

So the turn succeeds and costs about three attempts to do it. Eighteen minutes of wall-clock buys one turn's work.

The cause is margin. A 6,215-token prompt is roughly 5.2 minutes of prefill against a 360-second limit, and ordinary variance in the prefill rate pushes it over. Getting under the cap once is not the same as staying under it.

Two ways to buy headroom, neither of them further prompt-trimming, which is close to exhausted. Raise the limit, which needs finding where it lives, since the name that looked right is set to ninety minutes and changes nothing. Or make the first turn's prompt materially smaller than the threshold rather than marginally under it, which is what a worker per segment does by paying the opening once and amortising it over every source in that segment.

## The limit has a name: `CLAUDE_BYTE_STREAM_IDLE_TIMEOUT_MS`

Setting it to 5400000 in the worker's environment ends the six-minute cuts. Twenty minutes of running produced zero of them, against three consecutive successes at 17m13s, 9m20s and 48.7s. Before, three cuts at 6m0s preceded every completion.

It was found by reading the strings of the CLI binary for environment names containing TIMEOUT, after the router and ollama had both been ruled out and after two better-sounding names had been set to ninety minutes with no effect. `API_TIMEOUT_MS` governs the client's patience with its endpoint. `CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS` sounds exactly right and changes nothing here. The one that matters is an idle timeout on the byte stream, which is what a silent prefill trips.

Three things this settles. The limit measures silence, as the arithmetic said and one intervening account denied. The retry tax is gone, so a turn costs one attempt rather than three. And the prompt no longer has to sit under about 7,000 tokens, which removes the thin margin that made every turn a coin toss.

The general lesson is about where to look. Three timeouts were configured in the layers that seemed responsible, and the binding one lived in the binary at the end of the chain, discoverable in a minute by reading its strings rather than by reasoning about which component ought to own it.

## Decode collapses as context grows, and that is the real ceiling

Measured on a live worker with 22,605 tokens of context: generation at 0.58 tokens per second, steady across 1,578 generated tokens. The early probe on a short prompt measured 14.99. Decode is therefore about 25 times slower once a worker is carrying a fetched page.

This dominates everything else found here. At 0.58 tokens per second a 3,000-token answer takes 86 minutes, and a sweep worker's job is to read pages and write roster rows, so its context grows with every source it touches and its writing slows accordingly.

It also explains the earlier observation that generation had overtaken prefill. That was not the preamble cut revealing a fixed cost underneath; it was decode degrading as the conversation filled.

What follows for the design. Prompt size was worth attacking and has been attacked. The remaining cost is context length at generation time, which a smaller opening prompt does not fix, because the context that matters is the material the worker gathers. A worker per segment makes this worse rather than better, since it accumulates more sources in one conversation. A worker per source, which is what the dispatcher already does, keeps each conversation short.

That reverses the recommendation this document has carried. Paying the preamble thirty-five times is expensive, but it caps how long any single conversation gets. The right design pays the preamble once and keeps the working context small, which means neither the current per-source shape nor a per-segment one, but a worker that fetches, extracts and discards rather than carrying every page forward.

## The collapse is context, not memory, and half the machine is idle

The decode figure above was attributed to context length before that was checked. Checked now: swap is 975 MB total with none used, 26 GB of memory remains available, and `vmstat` reports no paging. No other process competes. Context length stands as the explanation.

The same check turned up something separate. Load average sits at exactly 4.00 on a machine with four cores and eight threads, and `vmstat` reports 49% idle. The model server is using four threads, which is the physical core count and a common default, leaving the hardware threads unused.

Whether that is worth changing is a measurement nobody has taken. Hyperthreading often gives little for this kind of arithmetic and can cost throughput by contending for the same execution units, so the honest position is that a lever may exist and its size is unknown. It is cheap to test by setting the thread count and re-measuring decode at a comparable context length.

Recorded because 49% idle on the machine that is the bottleneck is the kind of thing that reads as obviously wasteful and may not be.

## Decode against context: the curve, measured

Decode rate is a function of how much context the model is carrying, and the relationship is tight enough to plan against. Every request the model server logged last night carries both its prompt size and its achieved generation rate, so the curve came out of the existing log rather than a new experiment. Seventeen requests spanning 55 to 22,609 tokens of prompt:

| Prompt tokens | Decode, tokens per second |
|---|---|
| 55 | 15.01 |
| 6,215 | 3.16 |
| 7,435 | 2.50 |
| 8,431 | 1.84 |
| 9,707 | 1.60 |
| 10,178 | 1.48 |
| 15,953 | 0.88 |
| 18,194 | 0.76 |
| 21,689 | 0.63 |
| 22,605 | 0.58 |

Seconds per generated token runs linearly in context length, at about 79 microseconds per token of context, with an R-squared of 0.99 over the measured range. That is the shape CPU inference gives when attention over the accumulated cache dominates, and it means the cost of writing an answer is roughly the answer's length multiplied by the context it is written against.

What it costs to write a thousand tokens, then, is 5.8 minutes at 6,000 tokens of context, 11.0 at 10,000, and 24.2 at 20,000. The fit is measured between 6,000 and 22,600 tokens and should not be read much past that; its negative intercept is an artifact of a straight line over a bounded range rather than a claim about short prompts, where the observed ceiling is 15 tokens per second.

The 0.58 quoted earlier is not an outlier and not noise. It is what 22,605 tokens of context buys, and the 1.84 measured later is what 8,431 buys. One law covers both.

So the reversal stands on a measurement rather than on a single reading. A worker that accumulates fetched pages in one conversation pays for every later token at the rate its accumulated context sets, and the penalty compounds because the answers that matter come last, when the context is longest. The design that avoids it fetches a source, extracts the rows, discards the page, and carries forward only what it extracted.

## Where a worker's time actually goes: one tool call

The worker running this morning gives the first complete account, because its session log and the model server's log can be lined up against each other.

It started at 07:22:26 and by 08:55 had done three things. It reasoned for 1,979 tokens and called `WebFetch` on the horsezone Queensland listings page. The fetch took 57.2 minutes. It then began reasoning on the result, which is what it is still doing.

So one tool call is 63% of the worker's elapsed time. The fetch returned what was asked of it, listings in the requested shape, priced and placed: a German riding pony at Laravale, an allrounder gelding at Carindale, and so on down the page. The tool works. It is the cost that is the problem.

The model server's side of that same call settles what the cost is made of. The request carried 22,605 tokens, of which 22,457 were already in the prompt cache from an earlier attempt on the same page, so prefill read 148 new tokens in 20 seconds. Generation produced 1,977 tokens in 3,415 seconds, at 0.58 tokens per second. Prefill was 0.6% of the call and generation was 99.4%.

This is the cleanest available demonstration that generation is the constraint, because it is the case where prefill was almost entirely free and the call still took an hour.

The night's whole time accounting, taken from the model server's own phase boundaries, comes to this. Seventy-nine requests were started. Forty reached generation, and across those, prefill took 94 minutes against generation's 301, a generation share of 76%. The other thirty-nine were cut during prefill, before producing a single token, and they held the slot for 225 minutes between them. That last figure is the cost of requests cut before they could generate a token, and it is the second largest item of the night after generation itself. Two different events were being counted as one fault, and separating them settles a question I answered wrongly five times.

Every request that starts and never reaches generation is followed by another request. Where that successor carries the same prompt size, the same work has been resubmitted and it then succeeds, because the failed attempt warmed the cache. Where the successor carries a different prompt size, the work was lost. Over the journal to 09:37:40 on 21 September:

| | Events | Slot time | First | Last | Median hold |
|---|---|---|---|---|---|
| Cut and resubmitted, work recovered | 27 | 161.7 min | 20:46:22 | 09:05:59 | 361s |
| Cut and work lost | 13 | 70.8 min | 20:40:52 | 06:20:26 | 258s |

A median hold of 361 seconds names the thing: a limit at 360 seconds is still firing, and it has fired as recently as 09:05:59, inside the run going now. What changed is that it stopped destroying work. Loss ends at 06:20:26; since then every cut has been absorbed by a resubmission.

That is why the fault read as fixed whenever it was looked at. Each of the five declarations checked whether the run was still moving, which it was, and none distinguished a cut that is absorbed from no cut at all. Both matter and they are not the same measurement. The cost of the absorbed ones is 161.7 minutes of slot time, which is larger than the cost of the ones that lost work.

The cause is still unnamed, and the useful part of that admission is where it is not. All five attempts were on the client side, raising three separate client timeouts to 5,400,000 ms and loading a preload that raises the runtime's own. The cuts continued through all of it. The model server's unit file sets no timeout at all, only a keep-alive of eight hours, so its defaults are in force and have never been examined. That is the side to look at, and it is the side nobody has looked at.

Two cautions on how those numbers were obtained. Task identifiers restart when the model reloads, so keying requests by identifier alone merges separate requests into one and produces figures that look precise and are not; the phases above are paired by walking the log in order instead, which is safe because the server runs a single slot and therefore handles requests strictly in sequence. And a request whose prompt is already cached shows a prefill of zero, correctly, so the 94 minutes is prefill actually performed rather than prompt tokens presented.

`WebFetch` is not a fetch. It retrieves the page and then has the model read it and answer a prompt about it, and on this bridge that model is the local one. The hosted arm makes the same call against hosted Claude and pays nothing comparable for it.

### What this corrects

The 0.58 tokens per second that drove the per-segment reversal is this call. Its 22,605-token context is a fetched web page handed to the model by the tool, not an agent conversation that grew by accumulating sources. The agent's own conversation over the same period ran from 6,819 tokens to 8,431.

Worker shape does not reach this. Whether one worker takes six sources or six workers take one each, `WebFetch` sends a page-sized prompt every time it is called, and the page is the same size either way. The reversal's direction was right, that generation dominates and worsens with context, but the lever it named was the wrong one. What is left of the shape question is smaller than it looked: the opening preamble, paid once per worker, against a conversation that grows.

The lever that reaches the real cost is to keep the page out of the model. A plain retrieval with extraction done by a script sends nothing to be generated, and removes the largest single item in the run. Where a page genuinely needs a model to read it, capping what is sent is the next thing to try, since the cost is the answer's length multiplied by the context it is written against.

One caveat on the separation: the 22,605-token prompt is about three times the agent's conversation at that moment, so the page is plainly the bulk of it, but the log does not show whether the tool's call also carries the conversation. That would change the size of the effect and not its direction.

## Concurrency does not divide the work

Concurrency looked like the one lever that divides the work rather than subtracting from it, and measuring it looked as though it needed a free slot to load a second model into. It can be settled without one, by asking what the machine is doing while a single request runs.

Four logical cores sit at 100% and four at 2% or less. That reads as a half-idle machine and is not one: the topology pairs them 0 with 4, 1 with 5, 2 with 6, 3 with 7, so the busy four are one thread from each of the four physical cores, and the idle four are their hyperthread siblings. Every physical core is saturated by a single request. Load average sits at 4.00 against four cores.

A second slot would run on those sibling threads, sharing the execution units and the memory bandwidth of cores already at full stretch. Hyperthreading returns something on work that stalls waiting for memory and close to nothing on dense arithmetic that keeps the units busy, which is what this is. Memory allows it, with 22 GB free against a 32 GB resident model, so a second slot at reduced context would load. It would not halve the wall clock.

So the thirty-five-worker estimate carries no concurrency discount, and the levers that remain all reduce tokens rather than parallelise them: send less to be read, generate less in reply, or change the model or the machine.

## Almost everything the agent generates is reasoning

The share of a worker's output that is reasoning rather than answer looked as though it needed a worker that had finished, so its output could be read. It does not: the live worker's session log separates the two as it goes.

| Turn | Reasoning tokens | Answer tokens | Reasoning share |
|---|---|---|---|
| 1 | 1,979 | 68 | 97% |
| 2 | 3,667 | 59 | 98% |

The answer in both cases is a tool call, sixty-odd tokens of arguments, arrived at after two to four thousand tokens of deliberation. Counting the tool's own extraction output as answer, which is fair since those 1,977 tokens are the listings themselves, the worker's generation so far divides into roughly 76% reasoning and 24% product.

The reasoning tokens are the harness's own estimate and the answer tokens are measured from the emitted text, so the two columns come from different estimators. The gap is large enough that this does not matter.

This makes suppressing reasoning a larger lever than it first appeared, because it reaches three quarters of what the machine spends its time writing. The caution against reaching for it blind still stands: a model that reasons before answering may answer better, so the thing to measure is roster quality with and without, not speed alone. On this path the reasoning arrives as its own content block and never reaches the deliverable, so suppressing it changes what is paid for rather than what is produced.

## The first quality finding: the model skipped the reading its brief assigned it

The local arm's first segment, `supplier-horse-owner`, turned out to be the one the hosted arm deliberately declined to roster. Hosted row counts run 38 for `horse-introducer`, 26 for `supplier-riding-school`, 23 for `supplier-horse-rehoming`, 9 for `supplier-horse-breeder`, and 1 for `supplier-horse-owner`. That single row came from a staff conversation rather than a sweep.

The hosted arm's own sweep record explains the one. It swept the same horsezone page, found 204 live Queensland listings, and rostered none of them, because the segment holds 36,000 to 46,000 private horse carers and cannot be swept to closure, so a row count against that denominator measures nothing. Closure for the segment is source exhaustion instead.

The local worker spent two hours enumerating those sellers one at a time.

The reason is not that it was briefed differently. Its brief names the sweep record by path and says what to take from it: `market_estimate` is the denominator every count is reported against. The worker's own first turn of reasoning says "First step: Read the source's definition." It then made no `Read` call across three turns, having `Read` among its six tools, and went straight to fetching the listings page. The phrase "cannot be swept to closure" appears nowhere in its log, against control phrases from the same brief that the same search finds.

So the model was told which file to read, said it would read it, and did not. Everything downstream followed from that: it enumerated a population its own segment record says cannot be enumerated, and produced no roster row in two hours of work that was, by the hosted arm's judgement, the wrong work.

This is the first substantive quality finding of the experiment, and it is about judgement rather than output format. A model that skips the framing and goes to the data will look productive and be wrong, and on a segment whose brief happens to suit enumeration the same behaviour would have passed unnoticed.

The arm has moved to `horse-introducer`, whose nine sources are registers and directories, pony club club lists, a farriers' register, hoofcare practitioners, an agent index. Those enumerate cleanly, the hosted arm rostered 38 rows from them, and a like-for-like comparison exists there.

## The timeout fix has been inert since it was written

The limit that cuts requests during prefill has a cause, and it is one layer below where the last five attempts looked.

The bridge loads a preload script that raises the HTTP client's timeouts to ninety minutes. The script runs: pointing `BUN_OPTIONS` at a file that throws unconditionally kills the process, while the same file under `NODE_OPTIONS` leaves it printing its version, which confirms both that the preload mechanism works and that Bun is the runtime. Last night that test was taken as proof the timeout fix was live.

It proves the script runs. It says nothing about whether what the script configures governs anything. The script calls `setGlobalDispatcher` on `undici`. Probed inside the same process, the runtime reports as Bun 1.4.3, `globalThis.fetch` reports as native code, and it compares unequal to `undici.fetch`. Bun implements fetch itself and does not consult undici's dispatcher. So the ninety-minute timeout has never applied to a single request this bridge has made.

That is the same error as the `NODE_OPTIONS` one, made one level deeper. The first version verified that a variable was set. The second verified that the script it named actually ran. Neither verified that the thing the script configures is the thing doing the work, which is the only question that was ever being asked.

What remains is to find what Bun's native fetch does by default, which is a measurement against a socket that accepts and never answers rather than another guess.

### What follows for the bridge

The three `CLAUDE_*` and `API_TIMEOUT_MS` variables are present on the live worker, read from its own `/proc` entry, so whatever the client itself governs with them is governed. The preload is not doing the job it was added for. Anyone rebuilding this should treat `BRIDGE.md`'s preload section as documenting a file that loads and has no effect, which it now says.

## The cut has a name, and it belongs to the runtime

`BUN_CONFIG_HTTP_IDLE_TIMEOUT`. Bun's native fetch applies an idle timeout, and its default measures 360.4 seconds, timed by fetching a socket that accepts a connection and never answers. Prefill emits nothing, so a long prompt holds the stream idle for its entire duration and is cut at six minutes. Setting the variable to 10 produces a cut at 16 seconds, which is how the knob was identified and which shows it scales.

Nothing in the CLI's own vocabulary reaches it. The three `CLAUDE_*` variables and `API_TIMEOUT_MS` are all set to 5,400,000 and all present on the live worker, read from its own process entry. The preload that was supposed to cover the rest configures `undici`, which this runtime does not use. The limit was one layer below every place that was searched, in the runtime rather than in the application, and it was found by listing the binary's timeout-shaped strings and testing the one that was not a `CLAUDE_` name.

The observed cuts in the clean window sit at 430 seconds rather than 360, and the difference is consistent with the mechanism: the timer measures idleness, not total duration, so a request that exchanges something early has its clock start late. Seventy seconds of opening activity followed by 360 idle gives 430.

### On the sample that nearly misled

The overnight cut durations ran from 52 to 1,506 seconds, a spread no fixed timeout produces, and that spread almost argued the timeout hypothesis away. It was contamination. Seventeen dispatcher restarts were made during the night, and each kills a worker mid-request, which the model server records exactly as it records a timeout: a task released before it generated. Restricting to the window since 07:22, which has no restarts, gives three cuts in eleven requests at 430, 430 and 292 seconds. Two identical readings are a limit; the spread was the operator.

The fix is in the wrapper and `BRIDGE.md` carries it.

## Why no worker finishes: the harness kills them at 600 seconds of prefill

Raising Bun's idle timeout moved the limit and revealed the one behind it. A request that would previously have been cut around 430 seconds now ran to 629, and at 629 the worker itself was killed. The dispatcher's own log says why:

    FAIL (sweep: stalled -- no output for >= 600s; exit 143)

The harness carries a stall watchdog that sends SIGTERM to a child that has emitted no stdout for `STALL_TIMEOUT_SECS`, default 600. Prefill emits nothing at all, by its nature. So the watchdog is not detecting a hung worker, it is detecting a working one that has a long prompt to read.

On this hardware prefill runs at 21 to 26 tokens per second, so 600 seconds of silence is a prompt of roughly 13,000 tokens. The worker killed at 10:52 was reading 14,814. A worker's conversation grows with every tool result it receives, so it crosses that line after a handful of turns and is then killed and restarted on a fresh session, losing everything it had gathered.

That is the answer to the question this experiment has been asking sideways all night. The local arm produces no roster rows not because it is slow, but because a ceiling sits below the length of conversation a sweep needs. Each source is attempted, grows, is killed, retried twice on fresh sessions, grows, is killed again. Nothing survives to write a deliverable.

The interaction with the earlier fault is worth stating, because it hid this one. While Bun cut at 430 seconds, no request ever reached 600, so the stall watchdog never fired and its threshold was invisible. Fixing the smaller limit exposed the larger. Both were needed, and the order they were found in was the unhelpful one.

### What would change it

`STALL_TIMEOUT_SECS` is read from `meta.env` in the worker's prompt directory, with zero disabling the watchdog.

The running arm is unblocked without touching the harness. The prompt directories are not created when each source begins; the dispatcher builds one per source at the moment it starts, so every pending source's `meta.env` is already on disk and writable. All nine for the current run now carry 3,600 seconds, which covers a 75,000-token prefill at the observed rate while still catching a genuine hang, where zero would disable the watchdog altogether.

This holds for one run. The directories are regenerated each time, so the durable change is the harness default, and a value in the low thousands would suit a model reading at 21 tokens a second.

An earlier version of this section said no outside process could place a file there, and that was written without looking. The directories were sitting in `/tmp`, listed and writable, and the check took one command.

## Qualifying the skipped-reading finding, and what a longer-lived worker does instead

The claim that the model skips the file its brief tells it to read rests on two workers that made no read call. Both were observed two or three turns in, and both died before they got further. A worker on `horse-introducer` that survived to ten turns has made three read calls. So the honest version is narrower: the two workers that were killed early had not read their framing by the time they died, and one of them had already committed to enumerating a population its sweep record excludes. Whether a worker that lives long enough reads the framing before it matters is not established, and the evidence that it never reads is withdrawn.

What the longer-lived worker does show is worth more than the claim it weakens.

It fetched the pony club register and got 72 characters back, a tagline, because the page renders its content with JavaScript. It diagnosed that correctly and fell back to the office's own browser serialiser through a shell call, which produced a 287 KB dump. That is resourceful and is the behaviour one would want.

It then tried to read the dump and was refused, the file exceeding the 256 KB limit. It retried with a hundred-line limit and was refused again, the content still measuring 73,369 tokens against a 25,000 limit. It retried with a fifty-line limit and was refused identically. A browser dump of a modern page is a handful of enormously long lines, so a line limit cannot shrink it, and the tool's own message says to search the file instead. The model varied the one parameter that could not help, three times, rather than changing approach.

It made a fourth attempt at ten lines, and then changed approach on its own: `grep -i "club" <file> | head -n 50`, which is what the refusal had suggested. So it does reconsider. It takes four tries to get there, and on this hardware four tries is the better part of an hour.

That is the fair statement. The model executes competently, picks good tools, writes good extraction prompts, and recovers from a dead end without help. What it lacks is speed of reconsideration, and the cost of that is measured in minutes per attempt rather than the seconds it would cost on hosted infrastructure. A model that needs four attempts to abandon an approach is workable where attempts are cheap and expensive here.


## A note on how these observations were made

Twice today a claim about the model's judgement was published from an observation that was simply too early. The first said it never reads its framing, taken from two workers seen two or three turns in, and a longer-lived worker refuted it. The second said it repeats itself rather than reconsidering, taken from three failed reads, and its fourth and fifth calls refuted it.

Both errors run the same way, and neither is about the model. A worker on this hardware takes minutes per turn, so any snapshot covers very few turns, and a few turns is not enough to characterise a behaviour. The discipline that follows is to date an observation by the turn count it rests on and to treat a claim drawn from under ten turns as provisional until a worker runs longer.

## The configuration timeline, without which today's timings cannot be read

Three settings changed during the day, so any table spanning them mixes regimes. Times are AEST on 21 September 2026 unless the date is given.

| From | Change | What it does to the numbers |
|---|---|---|
| start of the run, 20 Sep | router removed, `--safe-mode`, tool list cut to six | opening prompt 6,207 tokens against 24,985 |
| 07:19:48 | bridge wrapper last edited before the morning runs | the last configuration the overnight figures describe |
| 11:18 (approx) | `BUN_CONFIG_HTTP_IDLE_TIMEOUT` set to 7200 in the wrapper | requests stop being cut at roughly 430 seconds; the next limit becomes visible |
| 11:18 (approx) | `STALL_TIMEOUT_SECS` set to 3600 in all nine prompt directories of the current run | workers constructed after this survive a prefill longer than 600 seconds; the worker on source one was constructed at 10:52 and is not covered |

Two consequences for reading the tables. Any cut counted before 11:18 belongs to the Bun limit, and the seventeen dispatcher restarts made overnight are recorded by the model server exactly as cuts are, so overnight cut counts are contaminated and the restart-free window since 07:22 is the only clean sample. And any per-source timing that spans 11:18 mixes a regime where long prefills were cut with one where they are not, so the two should not be averaged together.

## Where the blind-judging leak actually is

The scoring method requires that every line identifying the producing arm be stripped before a judge sees a roster, timestamps included. Measured against the hosted arm's `horse-introducer` roster, that requirement bites in exactly one place and bites on every row.

All 38 rows carry a date inside `s_note`, the sweep note, in the form of a bracketed provenance tag. The hosted arm's rows are dated 20 September. Anything the local arm produces will be dated 21 September or later. So the date alone separates the two rosters completely, before a judge reads a word of their content, and it correlates perfectly with the arm.

Nothing else in the file leaks. The other column flagged on a scan was `facebook_url`, whose nineteen matches are ordinary links in the data rather than provenance.

This needs no tooling and no change to the method, which already names timestamps. It needs whoever runs the judging to know that the strip is a single normalisation over one column, applied to every row, and that skipping it makes the blind judging worthless rather than merely imperfect.

This is recorded here rather than in `METHOD.md`, whose value rests on having been fixed before any result existed.

## The first deliverable, and it is honest

At 12:36 on 21 September, three and a half hours into the run, a worker wrote a return file. It is the first the local arm has produced.

It declares no rows. Its front matter is well formed: `rows_new` empty, a `source_status` of unreachable naming the URL, a reconciliation line saying nothing was processed, a `sweep_feedback` entry classifying the problem as source access, and an empty `escapes` list. Its prose says the page requires JavaScript, that both the fetch and the browser serialiser returned markup without club data, and recommends asking the source for an export or finding another register.

The claim is true. The serialiser's 287 KB dump contains exactly one string resembling a club name, and that string is part of the page's own tagline. There are no club names in it. The model did not abandon extractable data; the data was not there.

That matters more than a roster of rows would have. The failure mode this experiment most needed to rule out is a model that invents plausible businesses when a source defeats it, because a roster of businesses that do not exist reads well and is worth nothing. Given a source it could not read, after five attempts and a fallback to a different tool, this model wrote an empty result and said why. On the evidence of one deliverable it reports honestly.

Two qualifications. One deliverable is one deliverable, and the same model on a source that half works is the harder test. And its own account is slightly generous to itself: it says the serialiser returned full HTML with no accessible data, which is true, but it reached that conclusion from a 2 KB preview of a 284 KB result, its `grep` having failed to narrow anything because the document is a single enormous line. It was right, and it was right without having seen most of what it was judging.

An open question for the tooling rather than the model: the serialiser was invoked with a 20-second budget and returned unrendered markup. Whether a longer budget or a different flag would have rendered the club list is not something this arm should answer, since working that out is the sweep's job and the answer would change what is being measured.

## The arm could never have recorded a row, whatever the model did

The harness records a completed source by writing a status field back into the segment's YAML. Its surgical writer ends a block at the first line whose first character is not a space, so a block sequence whose items begin at column 0 reads as containing nothing. The project's real parser reads that style correctly, and the style is valid YAML. The writer does not.

The consequence is that no source in such a file can be found by name, whatever the name is, and the caller fails with "no source named X" after the worker has already written its deliverable. The work is discarded and nothing signals it. That is what happened at 12:50 on 21 September, fourteen minutes after the arm's first deliverable was written.

Four of the five segments seeded for this experiment were written in that style, and so was the fifth. So the finding is larger than one lost result. Across the eleven hours before this was found, no roster row could have been recorded from any segment, whatever the model produced. The timeout at 360 seconds and the stall watchdog at 600 were each sufficient on their own to prevent a deliverable. This third fault would have discarded the deliverable had either of the first two not.

The outcome was overdetermined, which is worth stating plainly because it changes what the night's silence meant. An arm that produces nothing looks like an arm whose model cannot do the work. Three independent faults in the path around the model produced exactly that appearance, and the first evidence about the model itself arrived only once all three were cleared.

Across the wider campaign, eight of seventy-two sweep files use the column-zero style. Each of them silently discards results from any surgical write, and the failure gives no signal to whoever's work is being dropped.

The repair on this arm's side is to indent the sequences by two spaces, which changes no parsed value: the real parser returns an identical structure before and after, verified on each file. The repair on the harness's side, which is the one that matters for everyone else, is a block-end test that does not assume a sequence is indented relative to its key.

## The repair is verified on the write path too

Re-indenting the segment files fixed the read side: the harness's block finder returns nine entries where it returned none. That is half of what the run needs. The other half is whether the harness can then write a status back without damaging the file, and a successful parse is not evidence of that. A key written at the wrong indentation parses cleanly as a key of the wrong parent, reports no error, and silently attaches a source's status to whatever precedes it.

Tested on copies, against two segment files with differently shaped sequences, exercising both branches: rewriting a key that already exists, and inserting one that does not. Both pass on both files. An inserted key lands at column 4, the same column as the entry's other keys, rather than at the dash's column 2. The indent the block finder reports is computed from the dash plus the whitespace after it, so it already points at the mapping keys. The defect suspected here does not exist.

Two facts worth carrying rather than rediscovering. The insert path splices a new key immediately after the entry's `name:` line rather than appending at the end, so every field the harness adds will sit directly under the name in a diff; that is placement, not meaning. And a regression test for this procedure should compare per-key values rather than whole-mapping equality, since key order changes on insert and an order-sensitive comparison reports a corruption that has not happened.

## Reasoning overhead, measured at the session rather than the turn

The second source gives the clearest figure yet, and it is worse than the per-turn numbers suggested.

The worker on `EquiDirectory, by locality` ran for 78 minutes. In that time it took four turns, made one tool call, and received one result. When the session ended it was 6,347 tokens into the reasoning for a turn it had not finished. It wrote no deliverable, and the harness's validator caught that and started a fix attempt.

At the decode rates measured on this hardware, roughly 1.5 to 2.5 tokens per second at ten thousand tokens of context, 6,347 tokens of reasoning is between forty and seventy minutes. So the bulk of the session went into a single block of deliberation that produced nothing and was then discarded when the session ended.

This is the same finding as the per-turn measurements and a good deal starker. Earlier the ratio was 1,979 reasoning tokens against 68 of answer on one turn, and 3,667 against 59 on the next. Here a whole session produced one fetch. The reasoning is not merely the larger share of what the machine writes; on a slow machine it can consume the session before any work lands.

It also explains a failure that would otherwise look like a model that cannot follow instructions. The worker did not decline to write its deliverable, and it did not forget. It never arrived at the writing.

The harness's validator deserves credit here. It noticed the missing deliverable and started a fix attempt rather than recording a silent nothing, which is the behaviour the first source's YAML fault lacked.

## Roster rows, at last, and what they look like

The local arm produced its first roster rows at about 14:30 on 21 September, from `EquiDirectory, by locality`. Two of them, recorded into the segment's roster file, with the source marked `exhausted` in the sweep record. The whole pipeline ran end to end for the first time: the model swept, wrote a deliverable, the harness validated it, recorded the source's status, and the rows landed.

The deliverable is good work. Its reconciliation reads: nine entries in the source, nine read this round, two in scope after the discovery criteria, none already on the roster, two rows returned. Its exclusions are itemised with reasons, naming which entries were dropped as veterinary services, as transport, as a rural supplier, and one dropped as too ambiguous to call. A row with no organisation carries an empty organisation rather than an invented one, and a row with no contact name does the same.

One of those exclusions is the experiment's first direct point of comparison. The local arm dropped a Beaudesert entry as lacking equestrian specificity. The hosted arm's roster for this segment carries that same business as a row. So the two arms, given the same source and the same discovery criteria, disagreed about a member. That is exactly the kind of disagreement the blind judging exists to adjudicate, and it should be left to the judge rather than settled here.

Two rows is two rows. The hosted arm holds 38 for this segment across nine sources, and the local arm has now worked two of them. Nothing about coverage can be said yet.

## The tunnel failed, as the notes said it would

The run died some time after 14:30. Every remaining source failed instantly with a connection refused, the SSH tunnel carrying requests to the model having dropped with no supervisor to restart it. Ollama was untouched throughout, still holding the model. This was written up as the bridge's weak point this morning, before it happened.

Seven sources were burned this way, each failing in seconds rather than hours, so the cost is the idle time rather than the work. The tunnel is back and the run relaunched at 20:48.

One thing to do differently. A relaunch builds fresh prompt directories, and those revert the stall timeout to its 600-second default, so the raised value has to be reapplied after every launch. That is a consequence of holding the fix outside the harness and is worth remembering by whoever next restarts this.

## The pony club register was readable all along, and the honest empty result was wrong

The first deliverable, at 12:36 on 21 September, declared the Pony Club Queensland Zone 2 register unreachable, and this file recorded that the serialiser's dump held no club names, so that the model had reported honestly. The hosted arm's sweep file for the same segment records the same URL, https://ponyclubqld.com.au/clubs/, as exhausted with 11 clubs and 11 contact points, and its roster carries 11 rows from it.

At 00:00 on 22 September a plain curl of that URL returned 191 KB of server-rendered HTML. Stripped of markup it is 31,000 characters of text carrying every club in the state by zone, each with secretary, postal address, phone and email, 199 email addresses in all; Rathdowney, Jimboomba, Mudgeeraba and Tallebudgera are among the entries. The list needs no JavaScript to render.

What the two local workers did with it. The 09:33 worker asked WebFetch to "fetch the club register page to enumerate entries for SPAR-S segment horse-introducer" and received a summary saying the content is a list of Pony Club Queensland clubs organised by zone with no mention of the segment; it died before acting on that. The 10:19 worker asked WebFetch to "fetch club register listing" and received the page's 72-character tagline. It then dumped the page through the browser serialiser, could not read the 287 KB result within the Read tool's limits, grepped it for "club", which returned the whole single-line file, and wrote the unreachable result. It never ran curl, never grepped for a zone or a suburb, and never asked WebFetch for the entries themselves.

So the failure is not access. WebFetch's summarisation step, which under the bridge is answered by the same local model, took each prompt literally: asked to fetch a listing it returned a tagline, asked about the segment it reported no mention of the segment. The data passed through the worker's hands twice.

The earlier claim that the serialiser dump held no club names cannot be re-checked, the temporary file having gone with the run. On the curl evidence it is likelier that the grep-and-preview by which it was checked failed, the file being one line, than that the serialiser rendered the page without its list. That claim is withdrawn.

For the report: same source, same URL, hosted 11 rows, local none, and the source is readable by the cheapest tool the worker holds. The empty result stands as honest and as wrong. Whether a differently phrased fetch or a curl reflex would have produced the rows is a question the decomposed test can put to the model directly, with the page text in hand.

## The second night, 22 September: the box shared between the sweep and direct tests

From 00:00 the sweep worker on the web-search source shared the model server with direct-API tests: a facts-fed P run of the twelve July contacts and decomposed reading tests built from the pony club page and from saved web-search listings. Everything below is read from the server's own journal (`journalctl -u ollama` on dappnode) and the clients' logs; times are AEST.

**The server serves one request at a time, in arrival order.** A five-token probe sent at 23:58 while the worker was mid-turn was still unanswered at its 900-second client timeout. `/api/ps` shows one slot. Every direct test's wall-clock therefore carries a queue wait behind whatever was in flight, and the worker's own turns queue behind the tests; the timing harvest separates the two, and the worker's wall-clock for this night is not comparable with the first night's.

**Decode rate is set by the context the call carries.** The worker's turn on a 12,967-token prompt generated 2,416 tokens in 2,486 seconds, 0.97 a second (task 40516); its re-sent turn ran at 1.1. A facts-fed request at 5,932 tokens of prompt generated 4,096 at 6.8 a second (task 42939). Prefill ran at 20 to 27 tokens a second on both. The 21 September fit holds at 13k and understates the rate at 6k, as its summary warned. For the question of what to share: a call at 6k of context costs a seventh of the time per token that an agent turn at 13k does, before counting the agent turn's prefill.

**A turn can be lost whole.** The worker's third turn returned HTTP 200 after 49 minutes 27 seconds (00:34:55) and the CLI logged no assistant event, then re-sent the identical 12,967-token prompt (task 47314, 01:03:57). Thinking events had stopped five minutes before the response ended, so the tail was content the CLI never surfaced; the body is not logged, so the client-side cause is unresolved. The re-send found no prompt cache, the direct tests having evicted it, and prefilled again. An hour of the box, twice, for one turn.

**The stall watchdog cannot see content generation.** The CLI prints a system event per thinking delta and nothing for visible content until the message completes. A tool call or deliverable at one token a second is minutes of silence, and a queued turn behind a direct test is more; the worker of the 23:31 launch would have been killed at 01:29 with its request live on the server. The bridge now passes `--include-partial-messages`, the keepalive sets `STALL_TIMEOUT_SECS=7200`, and for the running worker a loop wrote a blank line into its stdout pipe every twenty minutes from 01:12, which the harness parses as nothing. The dispatcher was drained after the current source so the next launch carries both fixes.

**Facts-fed P, thinking off, at the July cap: no profile.** The first contact, on the July prompt with thinking off and 4,096 tokens of generation, produced 4,096 tokens of deliberation in plain prose ("We are given the SOURCE FACTS ... We must write the profile strictly ...") and no profile; 44 minutes including its queue wait, 5,932 tokens of prompt. One contact, recorded as `factsfed-nothink.progress` and `raw-nothink/` in the P folder. The run was relaunched with thinking on and a 6,000-token cap so that a profile can exist to judge; its results follow.

**Hosted cost reference.** The hosted arm's horse sweep left no run logs on this laptop, so its cost per source is not measurable here. Hosted T0 runs of other segments of the same campaign on this laptop (August and September 2026) cost 1.75 to 3.70 USD per source worker in multi-worker launches (23 workers 40.21 USD; 9 workers 32.89 USD) and 0.52 to 1.40 USD per single-source relaunch. That is the hosted side of the cost comparison, stated with this provenance.

## The whole-task sweep hits the client's own clock: a turn at this context cannot finish in ninety minutes

The re-sent turn (task 47314, 12,967-token prompt, launched 01:03:57) ran until 02:04:55 and ended with HTTP 500 from the server at exactly 1 hour 29 minutes 59 seconds: the bridge's `API_TIMEOUT_MS` of 5,400,000 milliseconds, set on 21 September against a six-minute default, aborted the request. The server had generated 3,555 tokens at 1.0 a second and reports `truncated = 0`; the model was still writing. The client logged `api_retry` attempt 1 of 10 and re-sent the prompt a third time.

Read together with the first attempt (task 40516, 2,416 tokens, 49 minutes, returned 200 and discarded), the web-search source's third turn has now cost the box 2 hours 20 minutes and produced nothing the worker could act on, and the retry loop would spend ninety minutes per attempt for up to ten attempts. Two figures set the ceiling. Decode at 13,000 tokens of context runs at one token a second on this hardware, and this model's thinking on a sweep turn runs to several thousand tokens, so a turn wants one to two hours of generation before its first tool call. A source needs ten to twenty such turns.

Decision at 02:06: the dispatcher of 23:31 was stopped, the client timeouts in the bridge were raised to three hours (`API_TIMEOUT_MS` and the two `CLAUDE_*` stream timeouts), and a HOLD file pauses the keepalive's sweep relaunch until the direct-API tests and the live profile run have had the box; the sweep resumes after them under the new limits, and whether a turn completes at all inside three hours is then its first question. For the report: the whole-task S sweep on a web-search source is not a matter of a missing timeout. At this context and this decode rate it is an hour or more per turn, and the shareable work is the reading, not the loop.

## Thinking off does not stop the thinking: two deliverables lost to deliberation in the answer

Two direct-API calls with the request's `think` flag off, on this model, spent their whole generation budget reasoning in plain prose and never reached the deliverable. The facts-fed profile (5,932-token prompt, 4,096-token cap) opened "We are given the SOURCE FACTS ... We must write the profile strictly ..." and ran to the cap. The pony club extraction (14,985-token prompt, 2,500-token cap, 2,867 seconds of decode at 0.87 a second after a cached prefill) opened "We are given the segment definition ..." and was still checking Zone 1 clubs' postcodes one by one when the cap fell: zero rows against the hosted arm's eleven, and the Beaudesert club appears only inside the deliberation.

The July facts-fed runs on qwen3:8b and qwen2.5:14b with the same flag wrote profiles; this model at 30B does not switch its deliberation off, it moves it into the answer channel, where it costs the same tokens and leaves no room for the output. The queue of direct tests was switched to thinking on with the cap raised so the answer channel stays clean, and the large prompts were cut into per-query and per-section pieces of two to three thousand tokens, where decode runs at several tokens a second instead of under one. Both are recorded in `decomposed-runs.tsv` with `think` off.

## The built-in web search does not exist under the bridge

Every WebSearch call a local worker has ever made came back "Web search error: unavailable": three calls, all by the live profile worker on 22 September between 02:06 and 04:20. No sweep worker on either night called WebSearch at all; the sweep workers read, fetched and shelled. Web search in the CLI is a server-side tool of the hosted API, and ollama's Anthropic-compatible endpoint has no provider for it, so the tool is declared to the model, costs its share of the prompt, and answers nothing.

Two consequences. The sweep source that gave the hosted arm half its rows, "Web search, per trade and per locality", cannot be worked by a local worker in whole-task mode as the harness stands: the worker would have to know to shell out to a search command, and nothing tells it so. And the live profile procedure, which opens with searches for the person, runs its opening on an empty tool: the first row's worker spent three of its four turns on searches that could not succeed, then reported honestly that it had found nothing. For the bridge, WebSearch is dead weight in the tool list and a search route through Bash, such as the office's own search command line, is the replacement; for the experiment, this is the sharpest reason the division of labour has to be search outside, reading inside, which is what the per-query tests measure.

## Live P, first row: honest, and mechanically wrong

The profile worker on the local roster's first row (a coach with a name and a phone number, no organisation) ran four turns in 2 hours 14 minutes, most of it queued behind direct tests and at 1.9 tokens a second on a context grown by tool output. Three WebSearch calls, all unavailable. It then wrote its profile as a text reply rather than with the Write tool, body first inside `<profile_body>` tags and the YAML front matter after it, with `yield: low` where an integer belongs, and a star rating of 2 for a person it could not research. The harness's validator refused it, `missing_profile`, and opened a fix attempt. What it wrote was truthful about what it had and had not found; what it did not do was follow the deliverable's mechanics, which the hosted arm follows without being watched.

## Live P, first row, the fix loop: one defect per attempt, fifty minutes each

The harness's first fix attempt for the refused profile ran from 04:21 to 05:08 and did write the file, front matter first this time, body after. It carried the same `yield: low` where the procedure asks for an integer count of data points, so the validator refused it again (`invalid_yield`) and opened attempt 2 of 3, at which point the run was stopped so the box could return to the direct tests. The star rating of 2 from the refused profile had by then been written onto the roster row, which is worth a look on the harness side: a rating landing from a deliverable the validator rejects. So on this row the mechanics converge one defect at a time at about fifty minutes an attempt, and the content, honest about finding nothing, did not change between attempts. The second row of the local roster, an organisation with no contact name, was not attempted.

## Rating alone, facts supplied: within a star of Sonnet, a few minutes each

Twelve direct calls, one per July contact, each carrying the Sonnet baseline profile with its `star_rating` line removed and the segment's rubric, asking for the rating and a justification of at most 120 words; thinking on, temperature 0, no context length requested. Ten answered inside their cap. Against Sonnet's ratings: mean absolute difference 0.60 stars, mean signed difference -0.20, four exact, and no rating more than one star from Sonnet's. Sonnet gave 4 to eight of the ten and 5 to two; the local model gave the two 5s back, matched two of the 4s, put three 4s down to 3 and two 4s up to 5. The justifications name the rubric's signals and the profile's own figures. Two calls, on the same prompt shape, spent a 2,500-token cap entirely on thinking and returned nothing; the thinking on a rating ran from 700 to over 3,000 tokens, so the cap for the rest was raised to 4,000 and both are re-run at the end of the queue.

Cost per call once the box was free: prefill 47 to 71 seconds on 2,000 to 2,800 tokens, decode 78 to 124 seconds for 700 to 1,100 tokens, two to four minutes in all. The same calls earlier in the night carried queue waits of ten to thirty minutes behind the profile worker's turns, which is the other half of what sharing a one-slot server costs.

The July study measured this skill on the facts-fed engines and found calibration and prose quality to be different skills, with the 14B tracking Sonnet closest on rating. On rating alone this 30B model on CPU is in that company; whether its prose is, waits on the 16,000-cap profile run.

## A page section, the segment definition, room to think: the hosted arm's eleven, exactly

The pony club register page, cut per zone, with the segment's discovery criteria, rubric and catchment, thinking on, temperature 0, no context length requested. Zone 2 holds the catchment. With an 8,000-token cap the call finished on its own at 4,516 tokens (about 3,000 of thinking, the rest answer) after 12.4 minutes: eleven rows, Beaudesert, Fassifern, Greenbank, Jimboomba, Mudgeeraba, Nerang, Oxenford, Rathdowney, Southport, Tallebudgera and Tamborine, the same eleven the hosted arm rostered from this page on 20 September, each with the secretary's name, phone, email and locality as the page carries them, and "all clubs in this section are in scope" under Excluded, which is right for that zone. Scored against the hosted rows by name: 11 hits, 0 misses, 0 extras. One cell is wrong in form: the model's self-correction about Rathdowney's missing phone ("Wait no - Rathdowney has no phone listed, so phone empty") sits inside the phone cell instead of an empty cell, and its reason for Rathdowney names the Darling Downs where the Scenic Rim would be right.

What it took to get there. The whole page at 15,000 tokens, thinking off: 2,500 tokens of prose deliberation, no rows. Three zones at once, 3,300 to 3,500 tokens, thinking on with a 1,500 cap: all of it thinking, no rows, twice. One zone with a 3,000 cap: zone 1, the largest, all thinking; zone 2, five correct rows and then the cap. The thinking is a walk through every club, about 150 tokens each, checking its locality against the catchment, sound in its reasoning about which Brisbane suburbs are outside the horse belt. So the piece has to be one zone and the cap has to hold the walk, and then the reading is as good as the hosted arm's on this source. The zones that are out of catchment, where the right answer is an empty list, are still running and will say how it handles exclusion; the runs are in `decomposed-runs.tsv`.

## Search listings, one query at a time: the same reading, and the errors a snippet-reader makes

Seventy-two web searches were run once, outside the model, nine trades across eight catchment localities, and each listing saved as title, URL and snippet. One prompt per listing, two to three thousand tokens with the segment definition, thinking on, asks for the sweep's own deliverable from the listing alone. The equine-vet trade ran in full on 22 September between 06:13 and 07:38: eight queries, 65 minutes of box time, 4 to 14 minutes each, a mean of 2,600 tokens out; seven answered inside their cap and one, Jimboomba, spent a 4,000-token cap thinking and is re-queued at 8,000.

Twenty-nine rows across the eight, with practices recurring across localities as they do in the listings. Against the hosted arm's eight equine-vet rows from its own web search: six found (TRH Equine Vets, Scenic Rim Veterinary Service, Gold Coast Equine Clinic, Crown Equine Veterinary Services, Darling Downs Vets, Equine Veterinary Services), two not (Old Mill Vet Equine Service at Dayboro, UQ VETS at Gatton), and neither Dayboro nor Gatton was among the eight localities queried. Sixteen rows the hosted arm does not have: Precision Equine, HoofnPaws & Veresdale, Veresdale Equine, McMahon & Gallagher, Peak Vets, Tamborine Mountain Vet, TambVet, Hinterland Equine at Yandina, The Rivers Equine Vets, North East Equine, Sol Equine Vet, Kyogle Veterinary Clinic, Fairymount Veterinary Clinic, Davidson Veterinary, TFD Equine, and Tamborine Traders, a saddlery the reading rostered from a vet listing because the segment names saddleries too.

Two blind fact-checks, at 06:40 and 07:40, each by one agent told nothing about the rows' origin, under the five-search, five-fetch budget, covered the first fourteen of those and the two hosted rows the reading missed. All sixteen checked exist, evidenced by their own sites or pages. Fifteen are in the catchment; Hinterland Equine, based at Valdora on the Sunshine Coast, is not, and the reading's own locality column had said Yandina. Two are general practices whose own sites name no equine work, McMahon & Gallagher at Beaudesert and Fairymount at Kyogle, rostered on a search snippet's say-so. Two pairs are one clinic under two names: HoofnPaws & Veresdale with Veresdale Equine at one Beaudesert address, Tamborine Mountain Vet with TambVet at one Main Street address. Precision Equine in the Scenic Rim, the three Kyogle equine practices, The Rivers Equine Vets at Murwillumbah and the two Toowoomba practices are genuine members the hosted arm did not have, most of them in the Northern Rivers, where the hosted arm's search did not reach. The exclusions the model wrote were sound throughout: job postings, review aggregators, directory and franchise pages, a specialist surgeons' listing, each named with its reason.

So on listings as on the register page the reading is competent at small context, and its failure modes are the two a snippet-reader has, duplication across queries and a membership or locality claim it cannot check without fetching. The roster's reconciliation step catches the first; a fetch of the candidate's own site and a locality lookup against the catchment catch the second, and those are the steps the hosted arm takes and this call was not given.

## The zones beyond the source's scope: everything in, with the wrong labels

Zone 3 of the register, Ipswich, the Brisbane Valley and the Lockyer Valley, eight clubs, finished in 6.5 minutes at 2,775 tokens with all eight rostered and "Excluded: None". The hosted arm has no rows here because its source is "Pony Club Queensland, Zone 2 club register", scoped to zone 2 by name; the comparison against its eleven is a zone 2 comparison, and what the further zones test is the model's own catchment judgement against the segment definition. The catchment names Ipswich, and Toowoomba and the Darling Downs; it does not name the Lockyer Valley between them or the Somerset region to the north, and a reader of the page has to decide whether Gatton, Laidley, Lowood and Mt Beppo fall inside. The model decided yes for all of them and labelled its reasons with regions the localities are not in: Rosewood and Moore as "Logan catchment", Gatton, Laidley and Hattonvale as "Darling Downs". Its contact details are as the page gives them, with three slips of form: the zone column carries the club name instead of the zone number, one postcode gained a digit, one email has a comma for its dot.

Zone 4, the Darling Downs, twelve clubs in 3.8 minutes, all rostered, which the catchment's own words support, three of them labelled "Brisbane horse belt" where the Darling Downs was the right label. Read with zone 2 this is the shape of the skill. Extraction from a page section is faithful; the judgement of a borderline catchment is generous and its stated geography unreliable, so a downstream check of locality against the catchment, cheap and mechanical, belongs after it. Zone 5, the Western Downs, five clubs from Chinchilla out to Taroom and Wandoan, 10.3 minutes: all five in as "Darling Downs catchment", and Excluded empty. Taroom is four hundred kilometres from the estate. So across zones 2 to 5, thirty-six clubs read and thirty-six rostered, no exclusion anywhere, and the only exclusions seen on this page are in zone 1's thinking before its cap fell, where it was ruling out Brisbane suburbs one by one. The catchment as the segment writes it is a list of regions, and the model applies the words; the buying-radius intent behind them, which the hosted arm carried in its own judgement, does not reach it from the text. Zone 6, the Sunshine Coast, from Buderim and Coolum Beach up to Gympie and Kenilworth, sixteen clubs in 5.8 minutes: fifteen rostered, every one with the same reason, "pony club secretary with contact to horse-owning households", and the one exclusion, Mooloolah, for having no contact person named. No locality was weighed against the catchment at all; the walk through the geography that zone 1's thinking showed and zones 2 to 5 at least attempted has gone. Two rows also lost a column where the page carries no email. So across zones 2 to 6, fifty-one clubs read, fifty rostered, one excluded for a reason that is not geography. The check that a rostered locality is within the catchment is a lookup against a list, and it belongs between this call and the roster. The nineteen zones further north were taken out of the queue at this point: the pattern is settled and the box's time is better spent on the trades that have a hosted key.

## The facts-fed profile, at last: thirty-eight minutes and one wrong field

Thinking on, 16,000-token cap, the July prompt and the July facts for the first contact. The call finished on its own at 8,007 tokens, 29,505 characters of thinking and a 3,999-character profile, in 2,300 seconds, the box to itself; the context peaked at 9,843 tokens and decode fell from nine tokens a second at the start to under two by the end as the thinking filled the window. The profile has the nine sections the prompt prescribes, in order, each written from the facts sheet: a catalogue section that names the one exited-founder guest the facts carry and says plainly that no on-topic episode title was provided, a relevance assessment that walks the three signals and grounds a rating of 3 on the missing first signal, and a verification section. Sonnet rated the same contact 4 and the rating-only call earlier in the night, with the full profile in hand, also gave 4; the facts sheet the driver reconstructs strips the verdict sections, and with them the reach figures that call had cited, so the 3 is the rubric applied to less. The front matter's `contact_name` field carries the co-host's name rather than the subject's, while the title and body are about the subject; `yield` is 3 against Sonnet's 10, a count of the data points it chose to treat as substantive.

This is the same model that spent 4,096 tokens deliberating and wrote nothing under the July condition, and 6,000 thinking and wrote nothing under the first thinking-on cap. Given the budget its deliberation wants, it writes the document. The cost is the finding: thirty-eight minutes of a CPU box per profile, against seconds for the July 8B and 14B models on a GPU and for hosted Sonnet, and the twelve-contact set would take the box seven and a half hours. One contact's profile exists; the other eleven are queued behind the sweep tests and will land as the box allows.

## Blind judging, one contact: third of six

The judging brief fixed at 00:06 was run on the one contact with a profile: the five July versions and this one, renamed to codenames drawn at random, presented in rotated order, to one fresh judge told nothing about engines, machines or this experiment, asked to rank 1 to 6 on factual specificity and density, internal consistency, plausibility, coverage and usefulness for an approach decision, from the documents alone. The key was opened after the verdict.

The ranking: Sonnet first, "richest and most internally consistent, correct contact name, fullest career history, sourced quotes, a verification section that shows due diligence"; the July llama 8B second; this run third, "contact name in the header mismatches the subject, but the body is consistent and unusually honest that signal 1 is not met, making its 3-star call well justified"; the July qwen2.5 14B fourth, for the same header mismatch plus an uncorroborated episode title; the July Qwen3.5 35B live run fifth, for facts that contradict the other five; the July qwen3 8B sixth, for an unfilled template instruction left in the body and fabricated episode numbers. The July study's judge on this same contact had ranked the five in the same relative order, Sonnet, llama, Qwen3.5, qwen2.5, qwen3, so this judge's reading of the July versions agrees with July's, and the new version sits between the second and the old third.

One contact, one judge: a pilot of the method, not a result. It says the machinery works end to end, from the driver through the packet builder to a decoded verdict, and it says that on this contact the 30B model on CPU, given thirty-eight minutes, wrote a profile a judge preferred to three of the four local versions July produced. The other eleven contacts are queued and will be judged the same way as their profiles land.

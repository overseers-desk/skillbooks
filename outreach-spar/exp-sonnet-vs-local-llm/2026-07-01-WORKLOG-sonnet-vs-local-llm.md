# WORKLOG 2026-07-01 — SPAR-P on a local model (Qwen3-30B-A3B, Vulkan) vs hosted Sonnet

Forward-only record for a future agent asked "can SPAR-P run on the local box instead of hosted Claude, to stop bleeding tokens?" It documents the working local stack, the fair like-for-like comparison against a current-spec hosted-Sonnet profile of the same contact, and where the real limit is. Host `xe`/GPU-driver behaviour is tracked separately in `~/code/holotapes-main/issues/host=yoga,*`; this file is about SPAR, not the host.

**Result.** A local Qwen3-30B run, given the same reach as the hosted harness (web search + LinkedIn, both wired through Bash CLIs), produces a structurally valid, non-fabricated SPAR-P profile with the **full real career history** — matching the facts the hosted current-spec Sonnet run gathers. The residual gap is not tools and not speed: it is **rating calibration and active-verification judgement**. On the same facts the local model rated the contact 4; the hosted run rated it 2 after weighing what the facts imply. Detail below.

---

## 1. State reached (the spine)

A local inference stack a Claude-Code agent loop drives end-to-end to write a SPAR-P profile, with web + LinkedIn reach:

- **Model** `/usr/local/ai/spar/models/Qwen3-30B-A3B-Q4_K_M.gguf` — base Qwen3-30B-A3B, Q4_K_M, 18,556,685,824 bytes, sha256 `0d003f6662faee786ed5da3e31b29c978de5ae5d275c8794c606a7f3c01aa8f5`. llama.cpp model size 17.28 GiB. Arch: 30.5B total, 3.3B active (MoE, 128 experts / 8 active), 48 layers, 4 KV heads, head_dim 128. Native ctx 32k, ~131k via YaRN (degrades toward the top; treat ~100k as the practical ceiling). Obtained via **ModelScope** (`Qwen/Qwen3-30B-A3B-GGUF`); HF throttles anonymous downloads and its Xet backend breaks aria2 resume, so ModelScope is the no-token re-fetch path. File persists on `/usr/local/ai` (nvme0n1p3, separate partition, survives reboot).
- **Binaries** built on this host at llama.cpp commit `8c146a8`: Vulkan (Arc 140V) `/usr/local/ai/spar/src/llama.cpp/build-vulkan/bin/{llama-server,llama-bench,llama-cli}`; CPU build alongside.
- **Bridge** claude-code-router (`ccr`, npm `@musistudio/claude-code-router`), config `~/.claude-code-router/config.json`: provider `local-qwen` → `http://127.0.0.1:8080/v1/chat/completions`, model id `qwen3-30b-a3b`, `Router.default = "local-qwen,qwen3-30b-a3b"`. Lets `claude -p` talk to the local server instead of Anthropic.
- **Reach, both via Bash (no tool schema — see §3):** web search `/usr/local/ai/spar/bin/brave-search "<q>" [n]`; LinkedIn `browser-serialiser linkedin.com/parse-profile <slug>` (the `linkedin.com` skill's CLI, on PATH from the overseer-toolbox plugin; needs a logged-in session).
- **Prompt** `spar-p-vulkan-qwen3-30b-a3b/prompt3.txt`: the run brief — parse-profile as identity ground-truth, capped web search, a verification rule, mandatory write.
- **Outputs** (one subfolder per engine, so `spar-p-cuda-*` can slot in as a sibling): the local Qwen/Vulkan run lives under `spar-p-vulkan-qwen3-30b-a3b/` (profile `marco-fredriks.local-qwen3-vulkan-linkedin.md`, star 4; trace `stream.linkedin.jsonl`; run log `run-trace-linkedin.md`; the no-LinkedIn control `marco-fredriks.local-qwen3-vulkan.md` + `prompt2.txt`, §4 dead-end 5). The hosted baseline lives under `spar-p-sonnet/` (profile `marco-fredriks.sonnet-current-spec.md`, star 2).

## 2. Reproduce it (verbatim)

```bash
M=/usr/local/ai/spar/models/Qwen3-30B-A3B-Q4_K_M.gguf
VK=/usr/local/ai/spar/src/llama.cpp/build-vulkan/bin

# 1. inference server on the GPU, thinking OFF (critical — dead-end 4)
"$VK/llama-server" -m "$M" --host 127.0.0.1 --port 8080 -ngl 99 -c 32768 --jinja \
  --chat-template-kwargs '{"enable_thinking":false}'
# wait for "listening on http://127.0.0.1:8080"; curl /health -> {"status":"ok"}

# 2. router
ccr start                     # 127.0.0.1:3456, reads ~/.claude-code-router/config.json

# 3. confirm LinkedIn session is live (once), then run the agent loop
browser-serialiser linkedin.com/login --check           # expect {"status":"already_logged_in"}
mkdir -p /usr/local/ai/spar/runs/lr && cd /usr/local/ai/spar/runs/lr   # copy prompt3.txt here
ccr code -p "$(cat prompt3.txt)" \
  --strict-mcp-config \
  --allowedTools "Bash,WebFetch,Read,Write,Edit,Glob,Agent" \
  --disallowedTools "WebSearch,Grep,ToolSearch,Skill,TodoWrite,SendMessage,NotebookEdit,Workflow,CronCreate,CronDelete,CronList,TaskCreate,TaskGet,TaskList,TaskOutput,TaskStop,TaskUpdate,DesignSync,EnterWorktree,ExitWorktree,ScheduleWakeup,ReportFindings,WaitForMcpServers" \
  --permission-mode bypassPermissions \
  --output-format stream-json --verbose < /dev/null > stream.jsonl 2> err.log
```

Run on the **text console** (Wayland inactive) to free the ~13 GiB the desktop otherwise holds.

## 3. Tools wired through Bash, not the tool layer (the piece that is not obvious)

Two capabilities the hosted harness gets from Claude Code's tool layer must be reached differently on a local model:

- **Native `WebSearch` is dead on local.** It is an Anthropic server-side tool; pointed at a local server it returns an empty envelope (header + "cite your sources" reminder, no results) and the model confabulates sources. `WebFetch` works (client-side) but cannot read LinkedIn's login-walled, client-rendered pages.
- **The `Skill` tool cannot be enabled cheaply.** `llama-server --jinja` builds a GBNF grammar from every tool schema; `Skill` (and the rest of the full catalog) blows the grammar threshold (dead-end 2).

Both are solved the same way: **call the underlying CLI through Bash.** These add no JSON tool schema, so they cost nothing against the grammar limit.
- Web: `/usr/local/ai/spar/bin/brave-search "<q>" [n]` — `curl`s the Brave Search API (`X-Subscription-Token` key inside the wrapper; also in LastPass, do not commit it), prints title/url/snippet. `serpapi` would substitute identically.
- LinkedIn: the `linkedin.com` skill is a set of tcl CLIs driven by `browser-serialiser` (`browser-serialiser linkedin.com/parse-profile <slug>` returns the parsed profile: name, headline, location, experience, skills). Needs a logged-in session in the browser user-data-dir the serialiser targets (`login --check` reports state) and draws on LinkedIn's monthly Commercial-Use quota. Any skill with a CLI wires in this way; the `Skill` tool schema was never the only door.

## 4. Dead-ends mapped (do not re-walk)

1. **Native `WebSearch` unusable on local models** — empty, silent, model fabricates. Use the Bash wrapper (§3).
2. **Tool-count → grammar failure.** The GBNF rule product crosses `MAX_REPETITION_THRESHOLD` (2000, `llama.cpp/src/llama-grammar.cpp:13`) → 400 "failed to parse grammar." Full Claude-Code tool set (~27 + MCP) blows it; a lean ~8-tool set parses. `--allowedTools` does NOT shrink what is sent — only `--disallowedTools` does. Prefer Bash-invoked capabilities (no schema); raising the constant + rebuild is the alternative.
3. **Uncapped research prompt → infinite decode loop.** The 30B model has no self-stop: it re-issues the same query indefinitely and never writes. Cap searches/fetches and make writing mandatory (see `prompt3.txt`). The cap bounds the loop; the model may still exceed the stated number, so bound it, do not rely on it obeying the count.
4. **Base Qwen3 thinks by default,** eating the output budget (short `max_tokens` → empty content, `finish_reason=length`). Disable server-side: `--chat-template-kwargs '{"enable_thinking":false}'`. A leading `/no_think` in the `-p` prompt does not work — Claude Code eats it as a slash command.
5. **Without the LinkedIn CLI wired, the profile is surface-only.** The no-LinkedIn control (`spar-p-vulkan-qwen3-30b-a3b/`: `prompt2.txt` → `marco-fredriks.local-qwen3-vulkan.md`) produced a valid profile with an empty career section — brave snippets confirm the current role but not the history. LinkedIn (§3) is required for the career table.
6. **Aggregator identity is a trap — verify by direct fetch.** For this contact, ZoomInfo/RocketReach/Crunchbase/search-synthesis attribute a ~13-year insurance career ("ING Insurance International", "DiscoveryLife") that belongs to a *different same-named person* (three distinct "Marco Fredriks" LinkedIn profiles exist). A direct `parse-profile` of the canonical URL shows no such history. Build identity/career only from the direct fetch; treat aggregator-only claims as unverified. `prompt3.txt` encodes this rule.

## 5. The run: time, memory, and what "tg128" means

- **Wall-clock:** the LinkedIn run, 6 turns, ~4.7 min (281 s), TTFT ~36 s. Output `star_rating=4`, `yield=5`.
- **Throughput (Vulkan, warm):** token generation ~**11 t/s** (tg128); prompt processing ~230–281 t/s (pp512/pp2048).
- **Memory, peak:** ~22–23 GiB of 30.4 GiB (weights 17.3 GiB + KV for 32k ≈ 3 GiB fp16 + ~2 GiB base). On Vulkan/UMA the weights are `xe` GTT buffers in system RAM, **invisible to process RSS** (`llama-server` RSS ~80 MB) — read `used`/GTT, not RSS. KV per token (2·48·4·128) is 96 KiB fp16; `--cache-type-k/v q8_0` halves it for a bigger window.
- **tg128** = "token generation, 128 tokens": the decode-phase throughput in tokens/second, where the model emits output one token at a time. Distinct from **pp** ("prompt processing"/prefill), the parallel ingest of input tokens. tg is how fast it writes; pp is how fast it reads a large context. SPAR-P needs both: tg to write the profile, pp to re-read the growing conversation each turn.

## 6. Where the bottleneck is (not Vulkan compute)

During sustained generation, **peak package power ~35 W, chassis not hot.** If Vulkan *compute* were the limit the Xe cores would be near their power/thermal ceiling; instead they idle. So compute is not the constraint — the units stall waiting on memory.

Decode (tg) is **memory-bandwidth-bound:** each token streams the active weights out of memory. On Lunar Lake the CPU and Arc 140V share the same on-package LPDDR5X (~130–137 GB/s class); there is no dedicated VRAM. Low power + cool while decode is slow is the textbook bandwidth-bound signature.

Bandwidth is not the whole story. Ceiling: ~3.3B active params × ~0.55 byte (Q4) ≈ ~1.8 GiB/token; at ~135 GB/s that is ~70 tok/s, but observed is ~11. A **second** factor caps it: single-stream (batch=1) MoE decode — the per-token expert gather is scattered, irregular memory access (not the sequential reads that hit peak bandwidth), plus per-token kernel-launch/sync overhead. **Primary = shared-memory bandwidth; secondary = single-stream MoE kernel efficiency; neither is GPU compute.** A discrete GPU with dedicated VRAM raises tg; a faster compute part alone would not. For the agent wall-clock, add re-prefill of the growing conversation each turn (~230 t/s) and tool-call latency (Brave HTTP, LinkedIn fetch).

## 7. Like-for-like: local (LinkedIn) vs current-spec Sonnet

Same contact, Marco Fredriks (CFO, Shade Systems NZ). Both runs current-spec, both with LinkedIn + web reach. Local: `spar-p-vulkan-qwen3-30b-a3b/marco-fredriks.local-qwen3-vulkan-linkedin.md`. Hosted baseline: `spar-p-sonnet/marco-fredriks.sonnet-current-spec.md` (regenerated 2026-07-01 via the `spar-manager` harness, current `spar-P-profile.md`).

| Dimension | Current-spec Sonnet (star 2) | Local Qwen3-30B + LinkedIn (star 4) |
|---|---|---|
| Include/exclude | Include | Include (agrees) |
| Career history | Full real history, direct LinkedIn (Gough → Shamrock → ManageIT → Infinite Energy → Central Otago DC → Shade Systems → ENVISO) | **Full real history, same source, same roles** |
| Fabrication | None; aggregator insurance career actively debunked | None; insurance career absent |
| Verification | **Active** — tried to disconfirm, caught the name-collision career and the Auckland-vs-Dargaville address discrepancy | **Passive** — LinkedIn-as-truth by instruction; did not probe aggregators, so did not encounter or disarm the collision |
| Rating judgement | **2** — reads the three concurrent "present" roles as a diffused/portfolio pattern and the absent value signals as lowering; "present but unremarkable" | **4** — the same three roles sit in its own table, but it rated on *presence of verified data*, not *value to us* |

**Career-depth parity.** With LinkedIn wired, the local model builds the same career table as the hosted run. Retrieval is not the differentiator.

**The differentiator is judgement, two parts.** (a) *Calibration*: given identical facts, the local model rates 4 where the hosted run rates 2 — it over-values on structural fit and does not discount the portfolio/fractional pattern or the missing value signals. (b) *Active verification*: the hosted run's worth was largely in *disconfirming* a wrong fact (the name-collision career) and surfacing a tension (the address); the local model has no such reflex — it confirms and stops, and avoided the trap here only by not stepping near it.

## 8. Analysis / conclusion

For SPAR-P on this contact, a properly-tooled local Qwen3-30B is **fact-complete and non-fabricating but over-generous and passively-verifying**. The split for the campaign:

- **S&P include/rate gate:** usable, with a caveat. It gets inclusion right and the facts right, but it rates optimistically (4 vs a careful 2), so it would over-include / over-rate unless the rating is recalibrated or a conservative bias is applied downstream.
- **A-phase depth:** the value there is judgement — reading what the facts imply and disconfirming what looks too convenient. That is exactly the residual gap, and it is not bought by a faster GPU (§6): tg is bandwidth-bound, and raising it buys latency, not judgement.

Next steps to narrow the residual (untested here):
1. **Force a value-calibrated rating.** Prompt the model to discount portfolio/fractional patterns and absent value signals, and to justify the rating against the rubric's "value to us," not structural fit.
2. **Force an active-verification pass.** Require it to try to disconfirm every aggregator/search claim by a direct source before rating, and to reconcile conflicts — the discipline that catches name-collisions.
3. **Production write-back.** `prompt3.txt` writes only the standalone `.md`; the spec (`spar-P-profile.md` §4.13) also requires `star_rating` written to the roster TSV via `sqlite3` in order (body → roster → front matter). A production prompt must add it, or the state machine's band filters and progress counts break.

The single durable lesson: give a local model the same reach through Bash CLIs and it matches the hosted run on facts; what it still lacks is the reflex to distrust a convenient fact and to price what the facts mean.

## 9. Qwen3.5-35B-A3B (successor engine): tool + verification gaps close; calibration remains

Same setup as §7 (Vulkan, LinkedIn + brave via Bash, same contact, logged-in LinkedIn session), on the successor model — Qwen3.5-35B-A3B, Q4_K_M, 22 GB, in `spar-p-vulkan-qwen3.5-35b-a3b/`. 8 turns, ~8 min, peak ~25 GiB, fit under Wayland at `-c 16384`.

Three engines, one contact (Marco Fredriks):

| engine | star | career | verification |
|---|---|---|---|
| Qwen3-30B-A3B | 4 | full (via LinkedIn) | **passive** — took LinkedIn as truth, flagged nothing |
| **Qwen3.5-35B-A3B** | **4** | **full (via LinkedIn)** | **active + correct** — rejected the ZoomInfo "ING Vysya Life Insurance" claim as a name-collision (different Marco Fredriks); precise on the Infinite Energy nuance ("employment shown, title not — unverifiable") |
| Sonnet (current-spec) | 2 | full | active — debunked the collision |

The successor **closes the verification gap** the 30B had: on the same clean data it independently caught and rejected the aggregator name-collision — the disconfirming reflex the 30B lacked — and reached full career parity with Sonnet. Two of the three axes (tool reach, verification judgement) now match hosted Sonnet.

**Remaining gap: rating calibration.** With full facts and correct verification it still rates **4** where Sonnet rates **2**. It scores presence-of-verified-data, not value-to-us: it does not discount the portfolio/fractional pattern (three concurrent "present" roles) or the absent value signals (no insurance-program authority, no public engagement). Its calibration is data-driven-optimistic — *more* verified data pushed the rating *up* (a run whose LinkedIn fetch hit a login wall saw a thinner career and rated 3; the clean run saw the full history and rated 4). This is the one axis where the A3B local models still trail Sonnet, and the most prompt-tunable — the §8 next-step (a rubric-anchored "rate value, not completeness" instruction) is the lever to test.

Condition note: a LinkedIn login wall on `parse-profile` thins the career table; a warm logged-in session (`browser-serialiser linkedin.com/login --check` → `already_logged_in`) gives the full history. Check it before a run.

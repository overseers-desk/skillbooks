# NEXT-AGENT BRIEF — batch-redo holotapes-career profiles with local Qwen3.5-35B

Handoff written 2026-07-02, context exhausted mid-setup. Task not started. Do the steps in order.

## The task
Redo every SPAR-P profile in the `holotapes-career` campaign using the **local Qwen3.5-35B-A3B** engine (Vulkan), on a **new branch**, **overriding** the existing (hosted-Sonnet) profiles. Goal: how many complete unattended, and quality vs the Sonnet originals. Run **NQA** — the user will wake to check the count.

## Do NOT re-derive these — read them first (don't duplicate in your writeup)
- `exp-sonnet-vs-local-llm/2026-07-01-probe-yoga-vulkan.md` — the whole method: §2 reproduce recipe (llama-server + ccr + `ccr code` loop), §3 tools-via-Bash (brave-search + `browser-serialiser linkedin.com/parse-profile`, no `Skill`, grammar limit), §4 dead-ends, §5–6 tg128/bottleneck, §7–9 the 30b/3.5/Sonnet comparison and the residual (rating calibration).
- `exp-sonnet-vs-local-llm/CLAUDE.md` — memory invariants. Key: **one persistent `llama-server` (load the model once), stream all profiles through it; no reload/reboot per profile.** GTT lazy-frees and is reclaimed by the next load — do not reboot between runs. Keep big files off `/tmp` (tmpfs).
- `spar-p-vulkan-qwen3.5-35b-a3b/prompt3.txt` — the working per-contact prompt (LinkedIn-as-ground-truth + verification rule + SPAR-P §5.2 structure). It is chris-insurance-broking-specific; **adapt the CAMPAIGN/INCLUDE-EXCLUDE block to holotapes-career's segment rules** and make it generic per-contact.

## Prerequisites (in order)
1. **`git pull`** in `~/code/holotapes-career` and `~/code/aesop` before anything (user's instruction; my observations below are pre-pull and may be stale).
2. **Log in to LinkedIn** — `browser-serialiser linkedin.com/login` (checked 2026-07-02: session was **NOT logged in**; `parse-profile` needs it or career tables come back thin — WORKLOG §9 condition note).
3. **Start the engine once**: `llama-server -m /usr/local/ai/spar/models/Qwen3.5-35B-A3B-Q4_K_M.gguf -ngl 99 -c 16384 --jinja --chat-template-kwargs '{"enable_thinking":false}'` (22 GB, ~24 GB peak — fits under Wayland if GUI is light; console gives more headroom). Then `ccr start`. Confirm `curl :8080/health`.

## What I found about the target campaign (the new, undocumented part)
`~/code/holotapes-career/spar-campaigns/` is a **multi-segment** campaign, NOT the flat layout of chris-insurance-broking:
- `campaign-2026-07-reputation.yaml` + `campaign-2026-07-reputation-usp.md` (a reputation/USP campaign — different segment rules; **read the yaml + each segment's `segment.yaml` to get the correct include/exclude + rating rubric**; do not reuse the insurance rules).
- Segment dirs: `media-creator/` and `press-outlet/`. The rosters and existing profiles are **under each segment dir** (`<segment>/roster.tsv`, `<segment>/profiles/*.md`) — there is no top-level `roster.tsv`/`profiles/` (top-level profile count was 0). **Verify the exact paths** before looping.
- `holotapes-career` is on git branch `career`. Branch off from there (e.g. `career-qwen35-local`).

## Run recipe (batch)
Drive the **local** model directly via `ccr code` per contact — do NOT use `spar-transition.tcl` (that runs hosted Sonnet). A background driver script is welcome (survives context compaction); sketch:

```bash
# one persistent server already up (above). For each segment, each roster row:
#   build prompt = generic SPAR-P brief (adapted to that segment.yaml's rules)
#                  + contact fields (name, linkedin slug, org, role, country)
#                  + output path = <segment>/profiles/<stem>.md   (override)
#   cd <a scratch run dir under /usr/local/ai/spar/runs/>   # NOT /tmp
#   ccr code -p "$PROMPT" --strict-mcp-config \
#     --allowedTools "Bash,WebFetch,Read,Write,Edit,Glob,Agent" \
#     --disallowedTools "WebSearch,Grep,ToolSearch,Skill,TodoWrite,SendMessage,NotebookEdit,Workflow,Cron*,Task*,DesignSync,EnterWorktree,ExitWorktree,ScheduleWakeup,ReportFindings,WaitForMcpServers" \
#     --permission-mode bypassPermissions --output-format stream-json --verbose \
#     < /dev/null > "$RUNDIR/<stem>.stream.jsonl" 2> "$RUNDIR/<stem>.err"
#   append one line to progress.log: <stem> star=<n> turns=<n> ts=<...>
# Server loaded ONCE; loop reuses it. ~5–8 min/profile at ~11 t/s tg.
```
Notes: tools reach the model only through Bash (brave-search + browser-serialiser); keep the tool set lean (grammar limit, WORKLOG §4 dead-end 2). Force the verification pass and a value-calibrated rating in the prompt (WORKLOG §8 next-steps — the 3.5 residual is over-rating, star 4 vs Sonnet 2).

## Record-keeping (user's split)
- **Experiment record → here**: create `exp-sonnet-vs-local-llm/batch-media-creator/` for the run log, `progress.log`, `stream*.jsonl`, and a dated WORKLOG (date-leading name). `.log` noise → its `logs/` (git-ignored).
- **Result data → the campaign repo**: the regenerated profiles overwrite `holotapes-career/.../profiles/*.md` on the branch. Commit there separately; the aesop experiment folder holds only the record, not the profiles.

## Progress check for the user
Keep `progress.log` current (one line per finished profile) so "how many done" = `wc -l progress.log` against the roster totals per segment.

## Open items to resolve on start (verify, don't assume)
- Exact roster/profile paths under `media-creator/` and `press-outlet/` (segment layout).
- holotapes-career segment rules (read `segment.yaml` per segment — reputation campaign, not insurance).
- LinkedIn login (was logged out) + monthly Commercial-Use quota (shared; a big batch may hit it — watch for walled `parse-profile` output and pause/flag rather than writing thin profiles as if complete).

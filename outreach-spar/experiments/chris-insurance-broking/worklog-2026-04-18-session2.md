---
name: Session 2 worklog — v2 matrix + tier-2/3 expansion
description: Findings from the 2026-04-18 afternoon session: what worked, what didn't, and why the P-dispatcher throughput degraded
date: 2026-04-18
---

# Session 2 worklog — v2 matrix tier-2/3

## State at session end

- **Roster:** 622 data rows (was 272 at session start)
- **Profiles written:** 272 (unchanged from start; `+3` this session, all between 13:43–13:47)
- **Star distribution:** 4×5★ / 22×4★ / 65×3★ = 91 targetable (was 89)
- **Outstanding queue:** 350 unprofiled rows (sweep_iteration=4 v2-matrix-t23 × 315 + sweep_iteration=5 cross-lead × 31 + tier-1 stragglers × 4)
- **4 `claude -p` harnesses still alive** after dispatcher kill — they are grandchildren of the dispatcher and were not reached by `pkill -f "claude -p ... SPAR-P"`. They will complete their 4 in-flight profiles and exit; chromium subprocesses (40 at kill time) will unwind with them.

## What worked

1. **v2 matrix tier-1** was a strong win: 9 queries → 100 rows → ~50 new 3+★ (39 → 89). ~50% pass rate on a well-targeted keyword set.
2. **`search-log.tsv` as audit trail** — every LinkedIn fetch logged with query + country + page + timestamp. Makes re-runs and gap analysis trivial.
3. **Cross-lead cascade from "Who they know"** is cheap and productive — 109 candidates extracted from 269 scanned profiles, 31 admitted after filtering. Low marginal cost.
4. **Chromium + Chris's snap profile** stayed logged in for the entire 1.5-hour tier-2/3 sweep. No sign-in wall. `flock /tmp/chromium.lock` held.
5. **Dispatcher resumable design** — killing mid-run doesn't corrupt state. Restart is cheap.

## What didn't work

1. **Parse-search output leaked garbled rows into the roster.** ~23 rows have `organisation` = `""`, `"Sports"`, `"Founder"`, starts with `.`, or contains `"RIP"`. Real damage is larger: many rows have *name/org swapped* or *role written into name* — e.g. stem `acollison` with contact_name="Monte Huebsch" org="Mark Gemmell"; stem `aaron-myall` with contact_name="Peter Freeman" org="Sports". These are harness time sinks: the harness WebFetches the LinkedIn URL, discovers the mismatch, tries to reconcile, burns 10–15 min per row before exiting with low-value output.
2. **v2-t23 subagent's filter was too permissive.** It excluded obvious junk (Chris himself, insurance ecosystem, non-person business accounts) but did not enforce *coherence*: name_slug tokens must intersect stem tokens; organisation must not be a single generic word or contain noise tokens. A 15-minute coherence sweep before restart would probably drop 20–30% of the queue with no yield loss.
3. **Throughput degraded from overnight baseline.** Profiles/hour from mtimes:
   - 00:00: 49   03:00: 58  10:00: 44  (overnight + tier-1 baselines)
   - 12:00: 22   13:00: 10  (this session — tier-2/3)
   - Effective rate this session: ~19/hour with `--jobs=4` (baseline 44–58/hour).
4. **One harness stuck = one slot blocked.** Dispatcher does not kill hung harnesses. A 28-minute stall between 13:15 and 13:43 is consistent with 1–2 workers spinning on corrupt rows while the other slots wait for them to exit.
5. **Incomplete kill.** `pkill -f "spar-p-harness"` killed the bash wrappers but left the `claude -p` grandchildren (PIDs 293690, 293691, 293708, 293709) alive. Pattern-matching `claude -p ... Follow the SPAR-P` either didn't match argv exactly or was silently ignored. Next time: `pkill -P <dispatcher-pid>` + `pkill -f "claude -p --dangerously-skip-permissions"` + verify with `pgrep -c claude`.

## Why it was slow — hypothesis ranking

1. **Data quality is the primary cause** (high confidence). Tier-2/3 rows have less role/industry signal in the LinkedIn headline than tier-1; ~23 known-bad rows + unknown tail of swapped-field rows amplify the effect. Each bad row costs a worker ~10–15 min.
2. **Findability probe appendix adds ~2–3 min per profile** (medium confidence). `campaign.yaml` `prompt_appendices.p_author` has the harness run a Google probe and append a `## Findability probe` section after the main profile is written. Visible as the gap between profile-file-mtime and `[DONE]` in the dispatcher log.
3. **Claude API latency / queueing** (low confidence, not measured). Overnight peaks were Sonnet during quiet hours; afternoon rate could reflect higher API contention.

Not the cause: LinkedIn rate limiting (no sign-in walls seen, no 429s); chromium hangs (fetches completing normally); dispatcher logic (resumable state is clean).

## Recommended restart sequence

1. **Confirm 4 lingering `claude -p` processes have exited** (check `pgrep -c claude` ≥ 2 means Claude Code self + possibly leftover; harnesses take ~10 more min).
2. **Coherence sweep on `roster.tsv`** — drop rows where any of:
   - `organisation` is empty, single generic word (`Sports`, `Founder`, `Owner`), starts with `.`, or contains `RIP`
   - name tokens share no prefix with stem tokens
   - role is `""` or equals contact_name
3. **Relaunch dispatcher** with same command (`spar-transitions.tcl campaign.yaml --tid=T1 --execute --jobs=4`).
4. **Consider disabling the findability-experiment appendix** for this run — post-P can extract scores from existing profiles or a follow-up pass. Would likely lift throughput ≥ 20%.
5. **Do not re-arm the status cron** — the problem this session was data quality, not crashes. Cron solved the wrong problem.

## Resumability after the kill (user killed chromium subprocesses)

Verified post-kill state of the 4 `[START]`s the dispatcher had in flight:

| Stem | Profile file | Roster ★ | Resume behaviour |
|---|---|---|---|
| `abhishek-jain-91b93146` | 9811B, 118 lines, YAML `star_rating` present | 2 | Complete — dispatcher will skip |
| `adam-joyce-181a2937` | 8921B, 116 lines, YAML `star_rating` present | 3 | Complete — dispatcher will skip |
| `aaron-myall` | **MISSING** | 0 (roster stale) | Will be re-queued ✓ |
| `acollison` | **MISSING** | 0 (roster stale) | Will be re-queued ✓ |

Both completed profiles have closed YAML front matter (`star_rating:` line present) and full body — they are not partial writes. The two MISSING stems never wrote a file before the kill, so the dispatcher's file-existence skip check will correctly re-queue them.

**Verdict: fully resumable.** `roster.tsv` is append-only for identity rows and in-place for star_rating; `search-log.tsv` is append-only; profile `.md` files are written atomically by the Sonnet harness in a single Write. A dispatcher restart after coherence sweep will process the 350-row queue minus the 2 that completed = ~348 rows on the next run.

One caveat for partial-write vigilance next time: if a harness is killed **mid-Write** (rare — Write is atomic but file truncation is possible on signal), the profile could be short. A one-liner check before restart is `find profiles -name "*.md" -size -2000c` — any profile under 2KB is suspicious and should be deleted before re-queue.

The 350 rows will still be consumed at the same degraded throughput unless the coherence sweep lands first. That is the real resumption gate, not the process state.

## Facts for next session's benefit

- Dispatcher PID naming pattern: `spar-transitions.tcl` parent, `spar-p-harness` bash wrappers as children, `claude -p` Sonnet sessions as grandchildren, chromium-via-flock as great-grandchildren. Kill order matters: dispatcher → harness wrappers → `claude -p` grandchildren. `pkill` by pattern is unreliable past depth 2.
- Log file in use this session: `logs/p4-v2-t23-dispatch.log` (10 lines at kill, 4 `[START]` 0 `[DONE]`). The mtime of profile `.md` files is a more reliable progress signal than the dispatch log.
- Search-plan's `Current position` says `iteration: DONE-v2-complete, phase: complete` — that was written by the v2-t23 subagent before this session discovered the quality problems. It is not actually "done" pending the coherence sweep + re-profile.

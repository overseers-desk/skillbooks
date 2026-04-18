---
name: Session 2 worklog — v2 matrix + tier-2/3 expansion
description: Findings from the 2026-04-18 afternoon session: v2 matrix tier-1 win, tier-2/3 parse corruption discovered, dispatcher behaviour under a corrupt queue
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

1. **v2 matrix tier-1** was a strong win: 9 queries → 100 rows → ~50 new 3+★ (39 → 89). ~50% pass rate on a well-targeted keyword set. The tier-1 rows are clean.
2. **`search-log.tsv` as audit trail** — every LinkedIn fetch logged with query + country + page + timestamp. Makes re-runs and gap analysis trivial.
3. **Cross-lead cascade from "Who they know"** is cheap and productive — 109 candidates extracted from 269 scanned profiles, 31 admitted after filtering. Low marginal cost.
4. **Chromium + Chris's snap profile** stayed logged in for the entire 1.5-hour tier-2/3 sweep. No sign-in wall. `flock /tmp/chromium.lock` held.
5. **Dispatcher resumable design** — killing mid-run doesn't corrupt state. Restart is cheap.

## What was discovered

The tier-2/3 v2-matrix seed (`discovered_via=v2-matrix-t23`, 315 rows from 36 broader queries × 3 paginated pages) contains systematic field corruption. Symptoms visible on direct inspection of `roster.tsv`:

- Mutual-connection names bleeding into the `contact_name` column (stem `acollison` with contact_name="Monte Huebsch" org="Mark Gemmell"; stem `aaron-myall` with contact_name="Peter Freeman" org="Sports").
- Spanish UI chrome appearing as field values: `contactos más en común` as an organisation, `Sídney y alrededores` as a role, `Anterior:` fragments in names.
- LinkedIn URL slugs concatenated onto display names; role text written into the organisation field.

A regex filter over the 315 rows flags 132 as obviously corrupt (42%). The real rate is higher because adjacent-card name bleed — the first mutual-connection name in card N leaking into card N+1 — is not detectable by regex on a single row.

The origin is upstream of the roster: the tier-2/3 parse-search run used text-heuristic extraction (walking the flattened text of each LinkedIn search-result card and guessing fields by ordinal position and keyword cues). That heuristic worked on tier-1's nine narrow C-suite queries because the cards were uniform. It failed on tier-2/3's heterogeneous mix (profiles without current positions, retirees, consultants, students) where LinkedIn renders fallback content (follower counts, mutual-connection names, bare locations) in the same DOM positions where "role at company" normally sits. The Spanish UI chrome in Chris's chromium session — locale inherited from the snap profile at first LinkedIn sign-in, persisted as a session cookie — made the corruption conspicuous; under English chrome, the same parse failures would produce plausible-looking English garbage.

## Dispatcher behaviour under a corrupt queue

1. **Throughput collapsed** from the overnight baseline (44–58/h) to ~10–19/h. Profiles/hour from mtimes:
   - 00:00: 49   03:00: 58  10:00: 44  (overnight + tier-1 baselines)
   - 12:00: 22   13:00: 10  (this session — tier-2/3)
2. **One harness stuck = one slot blocked.** Dispatcher does not kill hung harnesses. A 28-minute stall between 13:15 and 13:43 is consistent with 1–2 workers spinning on corrupt rows while the other slots wait for them to exit. Each corrupt row costs a worker 10–15 min and produces nothing usable — the harness WebFetches the LinkedIn URL, discovers the mismatch, tries to reconcile, and exits low-value or not at all. Zero of the 132 detected-corrupt rows have a completed profile file on disk.
3. **Incomplete kill.** `pkill -f "spar-p-harness"` killed the bash wrappers but left the `claude -p` grandchildren (PIDs 293690, 293691, 293708, 293709) alive. Pattern-matching `claude -p ... Follow the SPAR-P` either didn't match argv exactly or was silently ignored. Next time: `pkill -P <dispatcher-pid>` + `pkill -f "claude -p --dangerously-skip-permissions"` + verify with `pgrep -c claude`.

Not the cause: LinkedIn rate limiting (no sign-in walls seen, no 429s); chromium hangs (fetches completing normally); dispatcher logic (resumable state is clean); Claude API contention (not measured, not needed as an explanation once the parse corruption is accounted for).

## Recommended next step

Do not relaunch the P-dispatcher on the current queue. The tier-2/3 rows need to be re-derived upstream with a structural parser (splitting pages on `role="listitem"` and extracting fields by ordinal line position within each card) before any of them are worth profiling. The re-derivation requires an HTML archive so the 108 tier-2/3 URLs can be re-fetched once and re-parsed cheaply. Session 3 will carry this out.

## Resumability after the kill (user killed chromium subprocesses)

Verified post-kill state of the 4 `[START]`s the dispatcher had in flight:

| Stem | Profile file | Roster ★ | Resume behaviour |
|---|---|---|---|
| `abhishek-jain-91b93146` | 9811B, 118 lines, YAML `star_rating` present | 2 | Complete — dispatcher will skip |
| `adam-joyce-181a2937` | 8921B, 116 lines, YAML `star_rating` present | 3 | Complete — dispatcher will skip |
| `aaron-myall` | **MISSING** | 0 (roster stale) | Will be re-queued ✓ |
| `acollison` | **MISSING** | 0 (roster stale) | Will be re-queued ✓ |

Both completed profiles have closed YAML front matter (`star_rating:` line present) and full body — they are not partial writes. The two MISSING stems never wrote a file before the kill, so the dispatcher's file-existence skip check will correctly re-queue them.

**Verdict: fully resumable.** `roster.tsv` is append-only for identity rows and in-place for star_rating; `search-log.tsv` is append-only; profile `.md` files are written atomically by the Sonnet harness in a single Write. One caveat for partial-write vigilance: if a harness is killed **mid-Write** (rare — Write is atomic but file truncation is possible on signal), the profile could be short. A one-liner check before restart is `find profiles -name "*.md" -size -2000c` — any profile under 2KB is suspicious and should be deleted before re-queue.

## Facts for next session's benefit

- Dispatcher PID naming pattern: `spar-transitions.tcl` parent, `spar-p-harness` bash wrappers as children, `claude -p` Sonnet sessions as grandchildren, chromium-via-flock as great-grandchildren. Kill order matters: dispatcher → harness wrappers → `claude -p` grandchildren. `pkill` by pattern is unreliable past depth 2.
- Log file in use this session: `logs/p4-v2-t23-dispatch.log` (10 lines at kill, 4 `[START]` 0 `[DONE]`). The mtime of profile `.md` files is a more reliable progress signal than the dispatch log.
- Search-plan's `Current position` says `iteration: DONE-v2-complete, phase: complete` — that was written by the v2-t23 subagent before the parse corruption was discovered. The tier-2/3 data needs to be rebuilt before the roster can be treated as final.

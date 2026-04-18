---
name: Session 3 worklog — rebuild tier-2/3 with a structural parser
description: HTML archive mandate, structural parser written and validated, formal re-fetch of the 108 tier-2/3 URLs running
date: 2026-04-18
---

# Session 3 worklog — tier-2/3 rebuild

## Diagnosis

The tier-2/3 (`discovered_via=v2-matrix-t23`) seed was produced by a parse-search subagent that used **text-heuristic extraction instead of structural DOM selectors** to read LinkedIn search-result pages. The heuristic walked the flattened text of each result card and guessed which substring was the name / organisation / role by ordinal position and keyword cues.

This heuristic worked on tier-1's nine narrow queries (`CFO manufacturing AU`, `MD logistics AU`, etc.) because those queries returned uniform cards: clean C-suite profiles with standard `Name / Role / Company / Location` layout. It failed on tier-2/3's 36 broader queries × 3 paginated pages (`CEO tourism`, `CEO hospitality`, `Owner manufacturer`, pages 0/10/20) because those returned a heterogeneous mix: people with no current position, retirees, consultants, students. LinkedIn renders cards for those profiles with fallback content (follower counts, mutual-connection names, bare locations) in the same DOM positions where "role at company" normally sits. Same class names, same structure, different content. A structural parser would have taken the field from its DOM slot and let the fallback content stay in its own slot. The text-heuristic parser silently pushed the fallback text into whichever field its ordinal rule pointed at.

The Spanish UI rendering that made the corruption visible (`6 contactos más en común` appearing as an organisation value, `Sídney y alrededores` as a role, `Anterior:` role snippets leaking into name) is an incidental signal, not a cause. Language for a logged-in LinkedIn user initialises from the browser's Accept-Language at first sign-in and persists as a session cookie — it came from Chris's chromium snap profile locale when he first signed in, not from an account setting. Had the locale been English at that moment, the same parse failures would have produced English-looking garbage (`6 mutual connections`, `Sydney area`, `Previous: role at company`) that a human reviewer might have waved through as plausible. The Spanish rendering made the wrongness conspicuous.

LinkedIn's class names are build-hashed (`_88a4b558`, `_449bf58b`) and rotate per deploy regardless of locale; the stable anchor is `role="listitem"` on each result card. LinkedIn's DOM structure is language-invariant — the field at position N is always the same semantic field, whatever the rendered text says.

Corruption rate measured from the roster: 132 of 315 tier-2/3 rows tripped basic regex filters (42%). Real rate is higher because adjacent-card name bleed (the first mutual-connection name in card N leaking into card N+1) is invisible to regex. Zero of the 132 detected-corrupt rows had a completed profile file on disk — the P-harness could not finish them because its input was garbage. That is the mechanical reason the dispatcher rate fell to ~10–19/h on this queue: corrupt rows jammed workers for 10–15 min each before producing nothing.

## The fix

**HTML archive, mandatory, campaign-scoped.** Every headless fetch in this campaign now writes to `html-archive/{YYYY-MM-DD}/{slug}-{HHMMSS}.html` before any parsing. Parsers consume from the archived file, not from a pipe. This turns parser bugs from fatal (lose the data, re-fetch) into recoverable (re-parse the archive with a fixed parser). `html-archive/` is gitignored. Documented as the permanent invariant in `BROWSER_OVERRIDE.md`. (Commit `cd65bde`.)

**Structural parser.** `parse-linkedin-search.py` splits each archived page on `role="listitem"` boundaries — strict per-card isolation, so content from one card cannot bleed into another. Within a card, it reads lines by ordinal position: [0] name, [1] degree indicator (`• 1º/2º/3er+`), [2] headline, [3] location. It does not search past line 3 for those fields. It splits the headline on ` at | @ | — | | ` to recover (role, organisation). Country is derived from the location string (`Australia` → AU, `Zelanda`/`Zealand` → NZ). The parser does not use language-specific keyword detection as a positive signal; UI-chrome terms are only used to reject a card whose first line is obviously not a name.

Validated on four varied sample pages before committing to the formal run:

- tier-2 AU page 0 (CEO hospitality) — 10/10 cards clean
- tier-2 AU page 20 (CEO tourism, deep pagination — the case that was supposed to break) — 10/10 clean
- tier-2 AU page 0 (Owner manufacturer, broad query) — 8/8 clean
- tier-3 NZ page 0 (CFO retail) — 10/10 clean

Zero bleeds, zero chrome-as-data, correct name/stem alignment on every row. The four cases where the old roster had `contact_name` pointing at someone other than the stem (`warburtonaaron` showing "Michael Lane", `frank-tucker-3a0796165` showing "Michelle Thurlow", etc.) all resolved correctly in the new parse.

**Formal re-fetch run** launched via `refetch-tier23.py`: iterates the 108 `v2-tier[23]` URLs from `search-log.tsv`, skips any already-archived, writes fresh HTML to the archive, parses the full set, emits a deduped TSV. Polite pacing at ~4.5s per URL; ETA ~8 min end-to-end. At worklog write time: 38 files archived, progress log shows 30/108 fetches done, rate 0.29 fetches/s, ETA 271s, no failures.

**Pending after the run:** merge the deduped TSV back into `roster.tsv`, replacing the 315 `discovered_via=v2-matrix-t23` rows with the cleanly-parsed set.

## Handoff state

Weiwu paused the campaign on 2026-04-18 for travel to Spain. Before pausing, a progress email went to Chris Graham (MessageId `<177649386252.49125.17190145228061669112@rivermill.au>`) with the current 106 profiles as a PDF index + a TSV, asking him to sample the top star-rated candidates and confirm whether the rating model is calibrated against his view of fit. Typical first batch is 100–150 emails; the sweep overall is expected to support 2–3 batches. The A phase (drafting approach messages) requires a working session with Chris because it depends on what NRS is actually selling, which has not been shared. S&P deliberately ran product-blind.

Next agent: perform the merge described in `search-plan.md` *Current position*, then stop. Do not relaunch the P-dispatcher — it would profile up to 346 more rows against a rating rubric Chris has not yet validated, and Opus tokens spent there are wasted if the rubric needs revision after his reply.

Two minor inconsistencies worth an eyeball when Weiwu returns: Lindsay Partridge AM and Matt Adams have `date_excluded: 2026-04-18` in their profile YAML but an empty `date_excluded` in the roster row; they are currently included in the 106 as 0★. Decide whether the YAML exclusion was intentional and propagate it back to the roster if so.

## Durable artefacts

- `parse-linkedin-search.py` — a committed, inspectable parser. Future search runs have a reference implementation; future parser bugs have a unit to update rather than a subagent to coax.
- `refetch-tier23.py` — a committed, idempotent re-fetch runner. Re-runs are cheap: already-archived URLs are skipped.
- The archive rule in `BROWSER_OVERRIDE.md` — so the next subagent that tries to stream HTML to a pipe is on notice.

## Fact record for next session

- The v2-matrix tier-1 rows (`discovered_via=v2-matrix`, 53 rows un-excluded) are clean. Zero corruption markers. Tier-1 likely ran under a different (better or luckier) ad-hoc parser; since no parser script was archived, "same parser" is not verifiable. With the new parser committed, this ambiguity is gone going forward.
- LinkedIn's result-card DOM as of 2026-04-18: class names are build-hashed and unreliable; `role="listitem"` is stable; `componentkey` attribute is per-card-unique; each card contains `<a href="/in/{stem}/">` exactly once.
- LinkedIn returns localised Spanish UI chrome to Chris's chromium session regardless of `--lang=en-US` flags, because locale is session-cookie state not browser state. This is not load-bearing for the parser (structural extraction is locale-agnostic) but any future parse that relies on visible text should assume Spanish output.
- Refetch runner log: `logs/refetch-tier23-YYYYMMDD-HHMMSS.log`. Output TSVs land in `logs/refetch-tier23-YYYYMMDD-HHMMSS{,-dedup}.tsv`.

# Handover from session sage-update-2 to sage-update-3, 25 September 2026, 16:33 (the shift runs on; the clock-off rewrites this)

## Where the commission stands

The commission: re-run the earlier SAGE product-research runs under the method's reading of 2026-09-19 (batch four runs under the reading of 2026-09-25, since both template sets were judged today), two at a time, learning between batches, improving the method inside the runs, with an artifact at the end for the owner to rule which improvements become permanent. Turtle feeding is out of scope.

- Batch one (River Day, weddings): done, 19 September.
- Batch two (chapel hire, party packages): done, 20 September.
- Batch three (kayak hire, riding academy): done today on the orchestrator's side. Each run: Survey re-made, 28 cards, priors, market-only third derivations, three per-card corrections passes, a set-wide pass, an integrator's page read cold by an owner's reader (four marks), two judges blind of each other (both pairs call the new page the better one: no echo on either, one contrarian card on the riding academy, none on kayak hire), a targeted judge on each one-way round, corrections rounds on the judges' rules, the page refreshed, the run record replaced. Riding academy 15 recommend (9 keep, 5 leave, 1 nothing held), 13 withheld. Kayak hire 8 recommend (6 keep, 2 leave), 20 withheld.
- Between batches three and four: done. The Survey-stage and Adjudicate-stage lessons of batch three are sorted by clerk in `../2026-09-19-1042/stage-d/batch-three-lessons-by-clerk.md`; every template under `../2026-09-19-1042/stage-d/briefs/` is rewritten; two judges read the two sets (`stage-d/template-judge-review-2026-09-25.md`, `stage-d/template-judge-review-2026-09-25-adjudicate.md`) and their mends are applied, with four orchestrator's rulings recorded in the lessons file's orchestrator section. The improvements file holds 43 entries.
- Batch four (venue hire, NDIS equine): opened today beside the August surveys (`estate-venue-hire/2026-08-15-how-venue-hire-was-decided`, `ndis-equine-therapy/2026-08-14-how-ndis-equine-was-decided`), their briefs filled and re-filled from the mended set, launch checks clean. Venue hire: Survey stage closed (pages re-fetched, amendment 1.2 after two pilots, 83 listings coded from pages with a twenty-listing blind reliability sample, operator index reconciled with a blind sample, records refreshed, strike list of 24 rows returned unstruck); Adjudicate stage opened at 16:29 with the lead deriving clerk, still writing at handover. NDIS equine: Survey stage at the pair merge (pages re-fetched for 199 of 232 units, amendment 1.6 after two pilots, 16,771 candidate sentences over 29 shards judged by 58 readers in pairs, all committed; the merge of pairs into the unit table with the reliability note is running at handover); operator index reconciled (209 operators); then the records refresh and the strike list.
- Batch five (the study tour, which needs its Survey finished, and the walking tour's top-up): not started.
- End of run: the improvements artifact and the final handover.

By count about 70 per cent of the commissioned runs are done or in Adjudicate. A session limit cut six clerks at 13:30 and lifted at 15:20; each was resumed from its transcript and nothing was lost.

## How to resume

Everything is on disk: `plan.md` (read-only), `orders.md`, `ledger.md` (267 lines; today's lines from "(Riding corrections A)" onward), `journal.md` (88 lines, clock-read times), `blocked.md` (needs the user), the templates and orchestrator steps under `../2026-09-19-1042/stage-d/briefs/`, the improvements file beside them, and in this folder's `stage-d/`: the recovered prompts (`prompt-shift-registrar.md`, `prompt-lessons-and-templates-clerk.md`, `prompt-riding-corrections-clerks.md`, `how-runs-were-opened.md`), the judge and cold-read briefs, and every judge's and cold reader's review of today. Each run's `briefs/` holds filled briefs; its `3-decisions/` the cards; its corpus folder (`0-comparables/venues-2026-08`, `0-comparables/equine-programmes-2026-08`) the tables, the pages under a git-ignored `data/`, and the reader files under `candidates/adjudicated/`.

Two constraints from the user today: keep the orchestrator's own context small (every step is a clerk; a Sonnet registrar does commits, pushes and ledger lines from the prompt in `stage-d/prompt-shift-registrar.md`; the orchestrator writes no run file by hand), and open every subagent prompt with a CEREMONY block (tier and why) and a LEDGER clause, or the shift gate refuses the spawn.

Adopt the shift: rewrite `orders.md` with the Write tool (that write binds the session), schedule the watchdog cron at minutes 17 and 47 with the prompt from `python3 <holotapes plugin>/hooks/shift-gates.py --watchdog-prompt <this folder>`, and replace the `watchdog-cron-id:` line with the new id. sage-update-2 deletes its own cron when it stops.

## Standing rules learnt today (in the registrar's prompt and the ledger)

- Never run a command that discards or moves uncommitted changes in the shared checkout; a registrar's `git checkout -- .` at 11:10 reverted two clerks' work in progress (recovered from a stash and a transcript). A rebase is `git fetch` then `git rebase --autostash origin/main`, only when no clerk is writing a tracked file (the reader waves write tracked files; hold pushes until a wave ends), abort-and-report on a stop. Commit a run's page the moment its integrator reports.
- Commit reader files only when both readers of a pair have finished.
- Every clerk prompt names a private subfolder of the scratch directory; generic file names collide across concurrent clerks.
- The Write and Edit tools strip a trailing empty field from a TSV row; clerks write "none" in a last cell.
- The launch check reads every file under `briefs/` as a brief; the market-side situation note lives under `2-blacklist/`.
- The browser skill's "got" pages are checked for content before a unit counts as recovered (twelve NDIS retries were error pages).
- A figure put in a prompt is read against its source first; a clerk given "24 parks" and "the 24 price-silent units" as one thing produced two readings.

## What sage-update-3 does first

1. Read this file, then `orders.md`, `journal.md` (last twenty lines), `ledger.md` (last sixty lines), `blocked.md`, and `../2026-09-19-1042/stage-d/briefs/orchestrator-steps.md`.
2. Adopt the shift as above.
3. Do not touch venue hire's `3-decisions/` or NDIS equine's `0-comparables/equine-programmes-2026-08/coded-whom-sold-to.tsv`, `coded-reliability.md` and `candidates/agreement.tsv` until sage-update-2 sends the message that its two running clerks (venue hire's lead deriving clerk; NDIS equine's pair merge) have finished and their files are committed. Everything else is yours from now.
4. Then, run by run:

   Venue hire (Adjudicate, on `briefs/` as filled today from the mended templates): after the lead deriving clerk's card set, check the card numbers against `3-decisions/questions-numbered.md` (23 questions) and that each card is keyed to its buyer; area deriving clerks by area (Opus); priors clerk (Sonnet; every Held stamp tests against terms paid for by invoice since October 2023, the listed evening product of February 2026 ranking as a draft, per the priors ranking rule); the orchestrator runs `python3 /usr/local/src/aesop/pmf-sage/tools/card-check.py <run>` after each stage; market-only third-derivation clerks by range on `briefs/third-derivation-clerk.md` (they read `2-blacklist/venue-situation-market.md` and nothing of the venue's; grep every file on their read list for the venue's name, site and prices first); corrections clerks by range then one set-wide clerk on `briefs/corrections-clerk.md` (its three rules and the step-22 choices, which the orchestrator states on the record: one base for the one-operator test, units; one Held ranking); the integrator on `briefs/integrator.md` with `{{ASSEMBLER}}` filled; the owner's cold read (Sonnet, `stage-d/owner-cold-read-brief.md`, four marks), its faults to the integrator; two judges blind of each other (`stage-d/judge-brief.md`, comparing with the survey's draft cards of 15 August in `../2026-08-15-venue-hire-survey/7-cards/`, since this run has no superseded page of its own; say so in the prompt); a targeted judge (`stage-d/targeted-judge-brief.md`) on any round that moved lines one way only; a corrections round on the judges' rules (rules, never verdicts); the integrator refreshed; the run-record clerk replacing `README.md` (none exists yet; the run folder was opened today).

   NDIS equine (Survey close, then Adjudicate): after the pair merge, check its report (agreement per variable, the variables carrying a rate, the units at 9), then the records-refresh clerk (Opus) on `briefs/records-refresh-clerk.md`, then the strike-list clerk (Opus) on `briefs/strike-list-clerk.md` with the owner's fields blank and the Returned line written on the orchestrator's words ("25 September 2026: not put to the owner, who is away for this run; every row stands unstruck"); a Sonnet clerk cuts `2-blacklist/venue-situation-market.md` from the generated note (shape marks only, checked by grep); re-run the launch check; then the Adjudicate chain as for venue hire (32 questions; the judges compare with the survey's draft cards of 5 September in `../2026-08-14-ndis-equine-market-survey/7-cards/`). V34 is coded whole-unit on the eighty-unit seeded draw, as counts, by two Sonnet coders blind, before the cards that ask it.

5. Batch five: the study tour (finish its Survey: frame, collection with pages kept, coding, on the Survey templates as mended) with the walking tour's top-up, opened as batch four was (`stage-d/how-runs-were-opened.md`). Then the improvements artifact (each of the 43 entries with case, what was given, result, and whether the trial supports keeping it) and the final handover at clock-off.

## Standing faults met today

- Six clerks were cut by a session limit at about 13:30 and resumed at 15:20; a second cut is possible in the evening.
- A sibling session works in the same checkout (mini-golf, spar-campaigns, alfred); its uncommitted files are not this shift's; `corpus-inventory.md` of venue hire was reverted once under a clerk by something outside this session.
- Two spent autostashes sit at `stash@{0}` and `stash@{1}` in the operator repository; do not pop them.
- Both index clerks and several readers found the Write tool dropping a trailing empty column; the merge treats "none", "n/a" and "-" as empty.

## Needs the user

Everything under "Needs the user" in `blocked.md` and in `../2026-09-19-1042/blocked.md`; today's additions: customers' phone numbers and emails in git under `plan-events/` and `knowledge-capture/`; the boundary between party packages and venue hire; the liquor licence covering the restaurant only; the NDIS provider not active on the public register against a certificate to 2028; a participant's health history in two bookings' notes; whether scheme settlement counts as being on sale; the workers compensation index stale against a renewal to July 2027; the four rulings the template judge asked for (whether the owner sees each strike list; whether search lookups are allowed; the default operator-grouping reading; whether a strike list after the coding is accepted for a re-run).

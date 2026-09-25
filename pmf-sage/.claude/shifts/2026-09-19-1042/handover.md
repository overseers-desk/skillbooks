# Handover: the SAGE lift shift of 19 September 2026

Span: armed 10:42, work ran from 10:42 to 13:15 and from 19:30 to 22:15 (Brisbane time, 19 September 2026); signed off 22:15 on the user's word, ahead of a reboot. The session is SAGE-methodology-holes, working directory `/usr/local/src/aesop/pmf-sage`.

## Needs the user

- Name a durable home for the re-run audit table, now in the session scratchpad only.

- Weddings: the 209 enquiry-system events added since 28 June 2026 sit behind a device-verification wall; one click by an operator lets the sales record read them.

- Operational, not the lift: the one River Day booking on the books (12 October 2026, 66 children, $1,325.61) is unpaid, uninvoiced and absent from the accounting ledger, as read from the booking and accounting systems on 19 September.

- Operational, weddings: the booking-confirmation template drops the evening-with-alcohol condition on the security guard, so it would charge a guard to an alcohol-free daytime wedding of 60 that the rule exempts (capability extract E49).
- Operational, weddings: three weekend-night farmstay figures are on record for one product ($1,400 in the fee schedule, $1,195 implied by one two-night quote, $1,095 quoted to another party).

- Operational, weddings: an outbound link on a wedding listing points at the wrong domain, and one directory listing has no named owner at the venue (capability extract E82, E83).
- Withheld cards that wait on an instrument only the owner can commission. Weddings: a tier field and a start-time field on the booking record (cards 13, 15); a fresh pull from the wedding enquiry system with full message bodies (card 32, and the reply halves of 10, 25, 30), already listed above as behind a device-verification wall; a keyword-volume batch (cards 12, 20, part of 23); two published-price trials, a chapel figure and a Saturday figure for a stated period with the asks counted (cards 7, 8). River Day: one place-qualified keyword batch (card 3, and the runner-up on card 2); calls to the three catchment venues publishing a narrow day window (card 10); what a party under ten does at a rival publishing a minimum of ten (card 22); enquiries logged by channel with telephone and email beside the form (card 23).

## Parked agent work
- Chapel hire: point-of-sale history before 31 May 2026 sits in the earlier till system, which no tool here reads; a social-media access token expired on 22 August 2026 and every read fails; the meetings database is not configured in this environment.
- Search instruments no run holds: a seasonality series (keyword history is refused by the plan in force and no trends pull exists), and the proximity layer of the market map, pulled for five clusters and skipped for eleven. One commission serves every run.
- Chapel hire: the liability policy expires 2 December 2026 and its business description names no third-party hire of the chapel.
- A collection rule question, for the owner: the runs read only what a buyer can read without asking. Obtaining rivals' terms, menus and hire agreements through the enquiry route (asking as a buyer asks) would close more withheld cards than any other single instrument (weddings cards 2, 11, 19, 20, 21; River Day cards 10, 22, 27, 28), and the rule forbids it. Whether to lift it is his decision.
- Weddings, wrong today whichever way the offer is ruled (the review's order of ruling opens with them): the whole-site exclusivity claim against the signed terms; a listing capacity of 120 against a 100-chair stock, with weddings already at 120 and one holding 120 for 2027; the deposit named two ways, its receiving entity unclarified, with two default balance schedules.

## The close

The user ended the shift early (a credit window running out and a reboot to follow). The work stands as below; nothing is mid-edit in either repository, and both are level with their remotes except for coder output still arriving (see Mid-flight).

**Done and pushed.**

- River Day (`school-excursion/2026-08-10-how-the-river-day-was-decided`) and weddings (`weddings/2026-09-07-how-the-wedding-offer-was-decided`) are lifted to the method's reading of 2026-09-19: strike list, buyer coding with a reliability sample, thirty and thirty-three cards with options and figures, a market-only third derivation on every card, priors pass, four correction rounds, the owner's review (`3-decisions/review.md`) with a ruling sheet and an order of ruling, a forward-only README, the earlier decision pages in `superseded/` with every citation following them. River Day reads 13 keep, 5 leave, 12 withheld (front of the page 4,382 words); weddings 8, 8, 17 (4,685 words). Neither page has been put to the owner; both wait for his rulings.
- The method (`pmf-sage/`, branch `aesop`, last commit 441bb98) took twenty commits: one proof for keeping and leaving what the owner holds; a sale at the only terms on offer shows acceptance and not preference; the withheld value; one rule for silence with both margins; a tie defined by one operator coded the other way; the instrument named on every line; a made-to-order count made twice before it turns a card; a one-way correction round read again; the ruling sheet with the owner's part on each row; the check and the assembler taught each of these.
- Nine judge reads and two owner's cold reads are kept in `stage-b/` beside this file; what they taught, sorted by the clerk it changes, is `stage-d/pair-lessons-by-clerk.md`; the brief templates for the next runs are `stage-d/briefs/`.

**Mid-flight at sign-off.**

- Chapel hire (`chapel-hire/2026-09-11-how-chapel-hire-was-decided`): records sorted, capability extract, search-demand findings, corpus inventory, a codebook amendment of fourteen variables (V19 to V32), sixteen coding shards cut (`0-comparables/chapel-hire-2026-09/shards/`) with a seeded reliability sample of nineteen in two further shard files. Sixteen Sonnet coders were launched; at sign-off shards 03, 05, 09 and 15 had written files under `coded-whom-sold-to/`. Shard 05's first file coded the buyer variable alone (12 columns); its coder was resumed to add the other thirteen. A shard file is complete when its header carries every field of all fourteen variables (about 16 columns in the coders' layout: the profile, fourteen codes, the phrases, a note). The coders' layouts differ: shard 03 wrote 81 columns (every field of every variable), shards 09 and 15 wrote 16 or 17 (one code a variable, phrases and a note), so the merge must normalise to the amendment's field list or the shards be re-run against a fixed header, which is the cleaner course for a reliability figure. By 22:40 all sixteen shard files had landed and were committed and pushed, shard 05 extended to all fourteen variables (shard 04 holds eleven rows for twelve profiles, shard 16 nine for its nine; layouts are 81 columns in shards 03, 05, 07, 08, 14, 16 and 16 or 17 in the rest). At 22:16 eight shard files were committed and pushed (01, 03, 04, 05, 09, 11, 14, 15); shard 04 holds eleven rows for a shard of twelve profiles, and shard 05 still has twelve columns. The two reliability shards were never launched. Coders cut off by the reboot leave no file or a partial one: relaunch any shard with no file or too few columns, from `briefs/whom-sold-to-coder.md`.
- Party packages (`party-packages/2026-08-15-how-party-packages-were-decided`): records sorted, search-demand findings, corpus inventory, a codebook amendment of eighteen variables (V23 to V40). No shards cut yet. Shards are cut from the folder listing of `../2026-08-15-party-survey/4-collection/coded/` (63 units; leave out `r1/own-site.md` and the READMEs). The amendment author asked for a pilot reliability read of three variables (V30, V34, V37) before the full pass.

## Scope verdict

- lift the progress of the SAGE runs: live. Two of the ten runs lifted; two begun; six not started (kayak hire, riding academy, venue hire, NDIS equine, study tour, the walking tour's survey top-up).
- Weddings and River Day first: done, recorded in each run's README and review.
- review if they represented improvements: done. Nine judge reads; every judge rated the lifted page better than the earlier one, River Day with confidence, weddings at about seventy per cent on the last read. Reviews in `stage-b/`.
- adjust methods before doing the others: done, in four rounds, each followed by judges; the journal records each round and why. The user's correction of 19 September (learn from the pair before the next batch) is carried in `stage-d/pair-lessons-by-clerk.md` and the brief templates.
- is-to-ought document clergy mode / market reality: done for the pair. The fence closes opinion and leaves behaviour open; every recommendation says whether it rests on the market, the venue's own buyers, or both.
- not the opposite where owner believes A so A is incorrect: done, after being got wrong twice in the day. The third round's instrument test fired only on departures and a judge counted it (four firings, all off disagreement with the owner); the fourth round runs both tests on every line, and a one-way round is read again. River Day ends with two cards (the smallest booking, the group bounds) recommending against his 14 August ruling on the study's best-agreed field, and his ruling standing.
- number of subagents by confidence from the pair: done as width two. The binding limit proved to be the credit window (about ten Opus clerks in flight exhausts it), not confidence.
- the other runs: live, as above. Turtle feeding left the scope on the user's word.

## Accounting

Armed 10:42:45. The shift was armed but its activation lines were not written until 19:37, because the skill's two-step design waited for the word "approved"; the user's ruling is that armed means on. Work ran from arming regardless, on the user's standing request. A usage limit stopped seven subagents at about 13:15 and nothing restarted the session until the user typed "go on" at about 19:30: six hours and a quarter lost. No wake mechanism existed before 19:37; after it a recurring session cron (43d6c246, minutes 13 and 43) ran and found the work healthy at each wake. Worked time about five and a quarter hours of an eleven and a half hour span. The span's end is taken from the last commissioned commit, operator repository 22:11. The gate's journal for the day holds only `allow user_present` and `mark presence` lines: no block fired and no model-drift line was written.

Commits: twenty on `aesop` under `pmf-sage/` since the start-ref 42b640d; seventy-one on the operator repository's `main` touching `product-development/`.

## Where to look next

- `blocked.md` beside this file for everything that needs the owner, copied above.
- `ledger.md`, 230 lines: every lesson and loose end as it surfaced. Unconsumed entries of weight: a coding pass over River Day's 26 uncoded nearest venues; the gathered-session variable as a versioned amendment coded twice over all 215 profiles; a third reading of eight disputed River Day venues (settles cards 0 and 7); second blind coders for weddings cards 6, 9, 11, 13, 17; the later stages of both lifted runs (game, definition, claims) still cite superseded numbering and rest on rulings not given; the walking-tour run's author is to be told of the reading of 2026-09-19 (its card 0 needs a third derivation under it); `tools/card-check.py`'s unit list names run-specific nouns (an I5 question); a stakes column and a revenue line on cards were held for the user.
- `journal.md` for each decision and why.
- `scratchpad-copy/` holds everything that was under `/tmp` for this session (judge briefs, merge scripts, audit table, clerks' working files), copied before the reboot.
- The re-run audit of all runs: `stage-b/rerun-audit-results.md`.
- A next shift starts by checking the chapel shards' column counts, relaunching the missing ones and the two reliability shards, merging and computing agreement (the pair's `merge_agree.py` in `scratchpad-copy/` is the model), then the strike-list clerk; party packages starts at cutting shards.

# Plan: carry the SAGE lift through the remaining runs, improving the method inside the runs

## The commission, in the user's words

19 September 2026: "at this point, many sage that was ran before has to be re-run." "use multiple subagents to lift the progress, do the easiest ones first, Weddings and River Day, then review if they represented improvements. then adjust your methods before doing the others. i think the major issue is is-to-ought document clergy mode predicts what market needs by meeting notes and owner innner thoughts instead of reality, but do not go to the opposite (which you do often) by thinking if owner believe A A must be incorrect." "the number of subagents is determined on how confident the pair re-ran makes you feel based on their result." "do not work on turtle feeding it is out of scope for this session btw. just eveything else. and take steps, why do you not learn from river day and weddings work feedback before next batch?"

20 September 2026: "do not believe pmf-sage is perfect, improve method as you see problems, and we can review what improvements should be permanentalised by the end of the run by you create an artifact to me. improvement suggestions are given to each subagent run without coding into aespo but collect learning along the way."

## The problem

Ten earlier runs put one recommendation on each decision card, drawn largely from the venue's own documents. The shift of 19 September lifted two of them (River Day and weddings) to a reading of the method under which a card rests on what buyers and sellers do, and an owner's held value is a hypothesis the market may confirm as readily as overturn. Two more runs are begun (chapel hire, party packages) and six are untouched (kayak hire, the riding academy, venue hire, NDIS equine, the study tour, the walking tour's survey top-up). Turtle feeding is out of scope.

The method is itself under test. Where a run shows a fault in it, the cure is given to that run's clerks through their briefs, shard files or a script kept outside the method, and is recorded with its case and its result in `../2026-09-19-1042/stage-d/method-improvements.md`. The method's own files stay as they stand at commit 441bb98. The user rules at the end which improvements become permanent.

## Where the work stands at arming

Chapel hire (`chapel-hire/2026-09-11-how-chapel-hire-was-decided` under the operator repository's `product-development/`): records, capability extract, search-demand findings, a codebook amendment of fourteen variables, sixteen coded shards rewritten under one fixed header, two blind reliability files. One patch coder (thirteen profiles) and two coders working from re-fetched page text are running. Party packages (`party-packages/2026-08-15-how-party-packages-were-decided`): records, search-demand findings, an amendment of eighteen variables, no shards.

## Batch two: chapel hire and party packages

1. Survey gate, instrument. Neither run holds stored copies of the pages it read, so the amendment's variables are coded from profiles, which keep only what an earlier codebook asked for. The reliability sample is coded a third time from re-fetched page text. The two profile codings give the noise between coders; what the page-text coding finds beyond that noise is the profile's miss rate, variable by variable. Where a variable's miss rate is material (the page-text coder finds a stated value in units both profile coders called not stated, more often than the two profile coders part from each other), the run re-fetches its corpus into the git-ignored data folder and codes that variable from page text; short of that, a zero from a profile is reported to later clerks as "not quoted". Party packages takes the same check on its pilot sample before its full pass.
2. Survey gate, reliability. Agreement per variable on the code and on the closed value, by `../2026-09-19-1042/stage-d/agreement.py`, with the count compared and each disagreeing pair printed, since a sample of nineteen cannot carry a coefficient alone. A variable under the amendment's 0.80 goes to rule review as a versioned amendment before any finding cites it. Party packages reads its three flagged variables on a pilot first, as its amendment's author asked.
3. Strike-list clerk: market buyer findings, operator findings, the strike list returned unmarked.
4. Lead deriving clerk: buyer card, the one-offer-or-several card, seller's sentences, the card set with its third list of work that is no market question. Then three deriving clerks by area.
5. Priors clerk. Third-derivation clerks (market files only). Corrections clerks. Survey top-up clerk for withheld cards that held data can close, each made-to-order count made twice. Corrections re-test of those cards.
6. Integrator, the assembled review, two fresh judges blind of each other, an owner's cold read of the front, the run-record clerk's README.

Tiers: the strongest tier for records, amendment, strike list, deriving, third derivation, corrections, integrator, judges and run record; the middle tier for coders, the priors clerk and cold readers. The Survey top-up clerk runs on the strongest tier and the blind second maker of each of its counts on the middle tier. Clerks receive their brief and their range and nothing of what a judge flagged.

## Between batches

The batch's lessons are sorted by the clerk each changes, the brief templates under `../2026-09-19-1042/stage-d/briefs/` are rewritten, and the improvements file gains its entries, survey-stage lessons first. A change to the words a clerk reads about evidence is followed by a judge before it reaches another run. No step of the next batch launches before this is done.

## Batches three to five

Two runs at a time, in the handover's order: kayak hire with the riding academy, venue hire with NDIS equine, the study tour with the walking tour's survey top-up. Each takes the pipeline above under the rewritten briefs, entering it where its own record stands (the audit of 19 September, `../2026-09-19-1042/stage-b/rerun-audit-results.md`, says what each run reached). The study tour stopped halfway through Survey and holds no card set, so its half of the last batch opens with finishing its Survey (frame, collection with pages kept, coding) and is the heavier of the two; if the credit window forces a choice, the walking tour's top-up finishes first. The later stages of every lifted run (game, definition, claims) rest on rulings the owner has yet to give and are not re-run.

## The end of the run

An artifact for the user: each improvement tried, the case that prompted it, what happened when it was tried, the permanent change it would make, and whether the trial supports keeping it, keeping it in another form or dropping it, so he can rule which become permanent. With it, the handover: what each run's page recommends, keeps and withholds, and what only he can do.

## Limits

About ten strongest-tier clerks in flight exhaust a five-hour credit window, and the host caps concurrent subagents at twenty. Waves are sized to the first figure. A finished clerk is resumed in preference to a fresh one.

## Acceptance

Per lifted run: `tools/launch-check.py` and `tools/card-check.py` exit clean; the review assembles with no dropped paragraph and no mismatch line; the judges' verdicts and the cold reader's open list are recorded; the README is forward-only. The method's tracked files are unchanged from 441bb98. The improvements file holds every change tried and its result. Both repositories are level with their remotes.

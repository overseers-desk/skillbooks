# Round 2 worklog, from 28 November 2026 (session sales-improvement-1.6)

## The goal

The owner's words: produce a new version of the methodology that can be described as "desirable", that is, one that will "outperform the old one in a meaningful way (e.g. > 0.26 ranking position or reach +1 ranking position in average for CVs that wasn't already top of the rank)". On the way: where most or all lateral-improving changes are in place and the method is generally better than before round 1, "lock in that status with 10 CV rewritten and if it remained good, all round-1 CV rewritten, and tag it with a version, before going to pursue the desirable". The lock-in is skipped if the desirable is reached outright. Budget is controlled finely, in tests of about 100 dollars that grow to 200 and 400 as a lead firms up; speed matters less than spend overnight.

"The old one" is the pages written before round 1. "All round-1 CV" is read here as every CV in the search: the 36 application folders under `career/top-20/` that hold one.

## Where it starts

- The method is hire-shift `33dd2626`: every change agreed on 28 November together (the sales framing, the candidate file as the writers' record, what the employer needs done as an item of the brief with no rule for the page, the opening sentence that answers the reader's first question, four repeated statements said once). The candidate file is weiwu `d99ba53e` and is used as it stands; the owner allows it to be changed where a test shows it to be the cause.
- The old pages' mean ranks among nine other candidates (round 1's worklog, result 22): post H 3.00, I 1.69, A 3.00, C 4.56, K 3.31. Of these only post I's still ranks better than its page written in round 1 or after.
- How the old pages were made, from the commits' session trailers and the two sessions that directed them. Each was drafted by an Opus subagent working alone, under the method as it stood when it started (post I: aesop `5613242e`; K: hire-shift `a9518152`; A: `a7cf35b1`; H and C: `f1cbd099`). Each writer also had its directing session's brief, which the method never held, and read the whole record: the standing record or candidate file, the profile, the interview record and the two CVs he sent. A second reader then read the page against the directing session's own list and the writer made one repair; posts I and K also had a pass against his rulings. No remark of the owner's on any of the five pages is recorded. Batch 2's prompts and briefs for posts I and K, as its writers read them, are in the outside folder under `originals/batch2-2026-11-26/`; batch 3's brief for A, H and C was edited after its pages and survives only in that session's transcript.

## Directions considered

1. The sales framing and the rename: the rewrite may have changed what a writer attends to, or dropped working rules the old text held.
2. Duplication removed: a merge may have dropped a qualifier or a rule that worked through repetition.
3. What the employer needs done: as released it dictated the top of the page in the employer's order; it is now an item of the brief, and the opening answers the reader's first question.
4. The candidate file as the writers' only record: facts lost in merges (22 found and answered by him on 28 November), and the interview record and sent CVs no longer read.
5. The directing sessions' briefs: batch 2's section "What earlier tests found" (the screener's picture is fixed by the latest job's heading and the size of the company; no line giving a reason for joining; a small result calls for a stronger one; his own account loses the approach contest), in no method text.
6. The repair: a second reader on the directing session's list and one repair, against the method's own checks alone.
7. Run conditions: writers at medium effort; the room holds the post's earlier page.
8. Noise: pages of one text differ by about a rank, and the old page for post I is one page.
9. The judges: steadiness on the same page, on another pile, under another model, and against a planted fault.

## Measure

- A page's rank is the mean over eight judges, two on each of its post's four piles (`deliver/b2-room.sh`, `deliver/judge-page.sh` in the outside folder).
- Desirable: over the posts tested, a version's mean rank is better than the old pages' by more than 0.26, or by a full place on average over posts whose old page was not already at the top. An old page counts as at the top when its rank is better than 2.0, which today is post I's alone. The standard error is reported beside each mean.
- Generally better, for the lock-in: a version's mean over the five posts is better than the old pages', and no post is worse by more than a place.

## Plan

- Result 23 (round 1's worklog, run by session sales-improvement-1.5): the method at `33dd2626` on the five posts, one page each. It is the first reading of the integrated version against the old pages.
- If result 23 is generally better: the lock-in. Five more of result 18's posts (40, 42, 31, 13, 19) written under `33dd2626`, making ten; if those ten stay better than the old pages, every CV in the search written again, and the method tagged.
- Then, toward the desirable, each test about 100 dollars, against `33dd2626` on posts I and H, two or three pages an arm: the old setup reproduced on post I (`deliver/o-room.sh`, which answers direction 8); the integrated method with batch 2's findings (5); with the whole record read (4); and a change aimed at whatever the leading direction shows. A lead goes to 200 dollars on all five posts, then 400.
- Delegation: writers are `claude -p` Opus sessions at medium effort in rooms of the outside folder; judges run through `judge.py` on the judges' account; counting and each result's entry here are done by Sonnet subagents running `deliver/judging/b2-report.py`, read by the directing session before anything is concluded; method versions are made by script and reviewed by the directing session.

## Results

### Result 1: the judges, on post I (direction 9)

- *What was run.* Eight fresh judges, two a pile on post I's four piles, on three texts: the old page as its earlier judges read it, result 22's page, and the old page with "20+ systems of record" taken out of its two sentences. Batches `judging/batches/j0/` in the outside folder (commit `51ffe52e` there); 5.06 dollars, on the judges' account; no judge void.
- *What counted, fixed before.* Steady if each fresh mean falls within 0.5 of its earlier mean; the taken-out fact noticed if that page ranks worse than the old page's fresh mean.

| Text | Fresh mean (SD), 8 judges | Earlier mean |
|---|---|---|
| Old page | 1.75 (1.04) | 1.69 over 16 |
| Result 22's page | 1.75 (0.89) | 2.25 over 8 |
| Old page without the fact | 2.25 (0.71) | |

- *Reading.* The old page held to 0.06. Result 22's page moved 0.50, on the line, and the judges ranked it level with the old page. Pooled, the old page stands at 1.71 over 24 judges and result 22's page at 2.00 over 16: a gap of 0.29 with a standard error of about 0.3. Post I's fall is therefore within what judges alone vary on one page, and is not shown to exist. Taking out the fact cost 0.5, the way the citations predicted, short of two standard errors.
- *What it changes.* A page judged by eight has a standard error of about 0.3 from the judges alone, larger than the 0.26 the goal names. A version is read on its mean over many pages, not on any one page, and a page that decides anything has sixteen judges.

### Result 2: the integrated method on five posts, read for the lock-in

- *What was run.* Round 1's worklog, result 23 (session sales-improvement-1.5): the method at `33dd2626`, candidate file `d99ba53e`, one page a post, eight judges a page. Old page / result 22's page / new page: H 3.00 / 2.25 / 2.25; I 1.69 / 2.25 / 2.75; A 3.00 / 2.75 / 2.12; C 4.56 / 4.38 / 4.88; K 3.31 / 2.88 / 2.50. New less old: -0.21 (better), standard error 0.39. 83.99 dollars as reported.
- *Reading against this log's measure.* Every change agreed on 28 November is in the text, the mean is better than the old pages' by 0.21 in both results 22 and 23, and over the two pages a post no post is worse by more than a place (post I, pooled with result 1's judges: 2.00 and 2.75 against 1.71, about 0.66 worse). The integrated method counts as generally better, and the lock-in starts.

### Result 3, fixed before any page is judged: the lock-in's ten, and the old setup on post I

- *Lock-in.* Posts 31, 13, 19, 40 and 42 written once each under `33dd2626` on `d99ba53e` (`deliver/b2-all.sh`, rooms `b2-<post>-33dd2626-1`), making ten with result 2's five. Their earlier pages, sixteen judges each: 31 old 4.69, result 18 3.00; 13 old 2.06, result 18 2.00; 19 old 1.00, result 18 1.06; 40 and 42 had no page before round 1. The method stays generally better if, over the eight posts with an old page, the new pages' mean is better than the old pages' and no post is worse by more than a place. Then every CV in the search is written again under `33dd2626` and the method is tagged.
- *Lock-in, as it came out.* New pages (eight judges): 31 3.62, 13 1.62, 19 1.00, 40 2.25 (result 18's page 2.81), 42 2.00 (2.12). Post I's page of result 2 was the one near the line, at 2.75 over eight; by result 1's rule a deciding page has sixteen, and eight more judges put it at 2.62 over sixteen, 0.93 behind its old page. Over the eight posts with an old page, the new pages are better by 0.34 (standard error about 0.27), and no post is worse by more than a place. The method stays generally better: the lock-in holds. The 0.34 rests on one page a post; pooled with result 22's pages of the same five posts it is 0.31 with a standard error of about 0.21, so the goal is not yet shown and the lock-in goes ahead as the owner set it.
- *The old setup.* Post I written three times by `deliver/o-room.sh` (rooms `o12-1` to `o12-3`). It reproduces the old page if its mean over the three is 2.0 or better. It differs from the integrated method on post I if the two means differ by half a place or more and by more than twice the standard error of the difference.
- *Delivered.* The ten pages went into the career folder page by page (weiwu `3042d0b8`): for each post the better-ranked page stands, the new one for posts 24, 32, 13, 19, 40 and 42 and the earlier one for 31, 34, 12 and 21, and each application's `examine.md` says which page is sent.

### Result 4: the old setup on post I (direction 8)

- *What was run.* Post I written three times by `deliver/o-room.sh` as on 26 November, with no hand in it: the method at aesop `5613242e`, batch 2's brief and prompt, the record at weiwu `6ff7850b`, then the 09:33 pass on the candidate file at `f93c97fb`. Opus at medium effort; rooms `o12-1` to `o12-3`; eight judges a page.
- *Outcome.* 2.38, 3.12 and 3.50: mean 3.00. The rule fixed before was 2.0 or better to reproduce the old page's 1.69; it is not reproduced. Against the integrated method's page on post I (2.62 over sixteen) the gap is 0.38 the other way, short of the half place fixed for a difference.
- *Reading.* Unattended, the setup that wrote post I's best page writes pages that rank about 3.0 there, worse on average than the integrated method's. The 1.69 was a good draw from that setup, and post I's fall since round 1 is a return toward the mean, not a loss the later changes caused. The one step of the old chain left out is the second reader's repair, whose instruction batch 2 chose by hand from the reader's findings. Post I's old page stays the yardstick the goal is measured against, as the owner set it.

## Cost

Writers' and judges' figures are what the runs report, at API prices; the directing session is counted separately.

| Test | Writers | Judges | Directing | Total |
|---|---|---|---|---|
| Result 1, judges on post I | 0 | 5.06 | | 5.06 |
| Result 2 (round 1's result 23, session sales-improvement-1.5) | 75.23 | 8.76 | | 83.99 |
| Result 3, the lock-in's five posts and post I's eight more judges | 63.03 | 10.43 | | 73.46 |
| Result 4, the old setup on post I | 56.64 | 4.94 | | 61.58 |

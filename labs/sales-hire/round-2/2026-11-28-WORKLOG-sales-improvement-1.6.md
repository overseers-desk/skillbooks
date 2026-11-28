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

None yet.

## Cost

| Test | Writers | Judges | Directing | Total |
|---|---|---|---|---|

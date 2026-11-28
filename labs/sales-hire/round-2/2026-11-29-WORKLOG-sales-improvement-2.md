# Round 2: the selling frame, ranked

Baseline: the method at `33dd2626`. Under test: the method at `80350f5b`, which is `33dd2626` with `hire-methodology.md` written as selling (the title "Putting a Candidate Forward", the opening told from the person filling the post, each phase opening with the writer's sentence "I am a salesperson and my goal is to sell the candidate", a reader's remark taken as a customer's answer, each change to the page marked `sell` or `check`). Nothing else in the folder differs. Started 29 November 2026 on the owner's word.

## The question

Does a CV written under the selling frame rank better among other candidates' CVs than one written under the method without it?

## What is compared

- **Selling CV:** one writer a post under `80350f5b`.
- **Control:** the CV already ranked for that post under `33dd2626` (round 1's test `final method` in `../round-1/placements.tsv`, and the other applications written again under `33dd2626` after round 1, once ranked). No control is written again, so a drift in the writers since 28 November is not checked.
- **The same for both:** the room tool, the candidate file at `d99ba53e` of the candidate's repository, the career folder copied at the commit the post's control was copied at (`4c85d67f` for stage 1's posts, `d99ba53e` for the others), Opus at medium effort, and the judges the post's control had: for stage 1's posts eight, two on each of the post's four piles; for the others ten, four on the first pile and two on each of the three built from its orders.

## Stages

- **Stage 1:** posts C, G, I, K, H, E, A and F, whose controls rank 4.88, 3.62, 2.62, 2.50, 2.25, 2.25, 2.12 and 2.00. J (1.62) and L (1.00) are at the top and left out.
- **Stage 2, on the owner's word after stage 1:** the other applications whose control, once ranked, has a mean rank of 2.00 or more, the line stage 1 draws, one selling CV each. New posts are added in place of a second CV on a post already tested: a second selling CV on a post still meets that post's one control, whose own run-to-run spread stays in the difference.

## What counts, fixed before any CV was judged

- A CV's rank is the mean of its four piles' mean places among nine rivals, 1 being best.
- A post's gain is the control's rank minus the selling CV's rank, so a positive gain is a better-ranked selling CV.
- The result is the mean gain over the posts, with its standard error from the spread of the posts' gains.
- Better shown: the mean gain is two standard errors or more above zero. Worse shown: two or more below. Otherwise not shown, with the estimate given.
- After stage 1 the result is read before anything is added, and the reading goes to the owner: whether the gain is already good progress, or whether the writers under the selling text did not work as sellers and the frame could be written better. His words: "Does data mean that we already achieved good progress with reframing? Or does it indicate reframing was incorrectly done and could have done a lot better? Before incorporating more test results." Whether the writers worked as sellers is read from their records apart from rank: the changes marked `sell` against those marked `check` in each `examine.md`, and what each page leads with.
- Stage 2, or a change to how the frame is written, follows on his word. His words: "In case the first 8 tests didn't yield significantly better, such as +0.25, that additional test becomes needed or adjusting sales framework is needed", and "if the first 8 show significant improvement, the additional tests are not needed." Where stage 2 runs, the result over all posts is the one reported.
- Reported beside the result, and deciding nothing: each post's gain beside its room (the control's rank less 1) and as a share of it, and the middle and rear posts (C, G, I, K) apart from those near the top (H, E, A, F).
- The owner's bar of 0.26 is not used. His words: "the bar of .26 was the bar that I set up for the combination of 4-direction move. For only one-directional move, I did not need such a high bar." He named no figure for this test.

## What the test can show

A CV written twice from one prompt and one text is two CVs: post I written three times alike ranked 2.38, 3.12 and 3.50, while the judges, shown one CV twice, ranked it 1.69 and 1.75. A selling CV against a control is expected to differ by a standard deviation of about 0.7 a post, as the round-1 CVs did against the CVs before the round. Stage 1's eight posts give a standard error of about 0.25, so a gain near half a rank shows; fourteen posts give about 0.19.

## Where the material is

Outside folder `/var/local/aesop/sales-voice`, test `round-2/b3`: rooms `b2-<post>-80350f5b-1`, pages, batches and sealed judges, `b2-run.log`.

## Results

Stage 1 is running, from 29 November. Of the other applications, sixteen have a ranked control (`delivery/ranks.tsv` in the outside folder); fourteen stand at 2.00 or more and are stage 2's posts, and two, at 1.38 and 1.12, are at the top. The eight applications whose rewrite was cut off join once written and ranked.

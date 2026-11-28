# Round 1: the method as the round changed it, against the CVs written before it

Round 1 is closed. The owner, on 28 November 2026: "From what I see, round 1 can be closed. We have a positive outcome, and we have done a few experiments, although not exhaustive, but a few experiments to see What factors are at play."

It ran on 27 and 28 November 2026 over six sessions (sales-improvement-1, 1.2, 1.3, 1.4, 1.5 and 1.6) and cost at least 3,036 dollars as reported. This file states what the round established. The order in which things were found, and the tests set aside as flawed, superseded or made by hand, are in this file's history in git.

## The experiment and its result

**Question.** Does the method, as the round changed it, write CVs that rank better among other candidates' CVs than the CVs the search had before the round?

**Treatment.** The method at commit `33dd2626`, with the candidate file at commit `d99ba53e` of the candidate's repository. It differs from the method the control was written under in three changes to its text and in its folder's name:
- statements the text made twice are made once;
- what the employer needs done is an item of the writer's brief, with no rule for the page, and the opening answers the reader's first question about any applicant;
- the text says that for an application the record of the candidate is the candidate file and the description it points to;
- the folder is named `sales-hire`, where it was `career-hire`. The text itself is not worded as selling, and no rewording of it toward selling is in the method.

**Control.** The CVs written for the same posts on 26 November, before the round. Each was written by one writer under the method as it stood at that hour, with a brief from the session directing it and the whole record to read, and was repaired once after a second reader.

**Run.** Ten real applications, one writer and one CV a post, Opus at medium effort, with nobody correcting the writer. Each CV has eight judges, two on each of four piles of rivals; post I's has sixteen. Each control has sixteen. Posts E and F had no CV before the round. Rank is defined under "The measure"; 1 is best.

| Post | Role | Control | Method | Change |
|---|---|---|---|---|
| G | chief AI officer, through a recruiter | 4.69 | 3.62 | 1.06 better |
| A | vice-president of R&D for AI | 3.00 | 2.12 | 0.88 better |
| K | head of engineering and AI | 3.31 | 2.50 | 0.81 better |
| H | vice-president of AI engineering | 3.00 | 2.25 | 0.75 better |
| J | senior vice-president of innovation, through a recruiter | 2.06 | 1.62 | 0.44 better |
| L | vice-president of AI | 1.00 | 1.00 | level |
| C | chief technology officer, through a recruiter | 4.56 | 4.88 | 0.31 worse |
| I | co-founding chief technology officer of an AI lab, through a recruiter | 1.69 | 2.62 | 0.94 worse |
| E | head of a company's generative-AI lab | none | 2.25 | |
| F | chief AI and innovation officer | none | 2.00 | |

**Result.** Over the eight posts with a control, the method's CVs rank 0.34 better on average, with a standard error of 0.25: five better, one level, two worse. On the six posts whose control ranked worse than 2.0 the average gain is 0.60.

**Against the owner's bar.** He had named the improvement to reach as "outperform the old one in a meaningful way (e.g. > 0.26 ranking position or reach +1 ranking position in average for CVs that wasn't already top of the rank)". The average of 0.34 is above 0.26, but it is 1.4 standard errors from zero, so it is not established as a gain; and 0.60 is short of a full rank.

**Limits.**
- One CV a post. CVs written under one text differ by about a rank, so the eight differences are noisy.
- The control was not written under the same conditions, which the roadmap asks of a control: another day, a brief and a repair the method does not hold, the whole record to read, and sixteen judges against eight. Only post I's control was judged again on the day of the run (`j0`).
- The gain sits where the control ranked low: four of the five controls at 3.0 or worse gained three quarters of a rank or more, and neither control better than 2.0 gained. A return toward the usual would give that pattern with no effect of the method.
- The writer could read the control. Its room held the post's earlier application whole, the control CV among it, and its instruction named where the CVs the candidate had sent are.
- Post I's control, at 1.69, is the one the method falls clearly short of; post C's difference is within the noise. The arrangement that wrote it, run again three times, gave 2.38, 3.12 and 3.50 (`o12`), so, as far as three runs without one of its steps show, 1.69 is not what that arrangement writes reliably.

## Proven and not proven

A status is one of three. Shown: the evidence supports it. Not shown: the evidence does not settle it, and the evidence column says which way it leans. Not tested: nothing was run.

| What | Status | Evidence | Code |
|---|---|---|---|
| The changes together make CVs rank worse | Not shown | the method's CVs rank 0.34 better on average, s.e. 0.25; two of eight posts worse | `b2-33dd2626`, `real-application` |
| The changes together make CVs rank better | Not shown | the gain is 1.4 standard errors at one CV a post, and the control was written under other conditions | `b2-33dd2626` |
| Any one of the changes by itself | Not tested | they were only run together | |
| A wording of the method's text as selling makes CVs rank better | Not tested | no such wording is in the method, and no CV written under one was ranked among other candidates | |
| The method's checks improve a first draft, judged in pairs | Shown | the examined CV beat its own first draft in 4 runs of 6 and lost none | `examined` |
| The method's checks improve a first draft, by rank among other candidates | Not shown | half a place better on average over six CVs, s.e. 0.45; one of the six a rank worse | `placement` |
| Choosing the best of several CVs gives a CV that ranks better | Shown | on four sets of four for one post, the chosen CV ranks 0.62 better than its set's mean | `v12-to-v14` |
| A rule that the employer's needs dictate the top of the CV (in `v7-holes2`; not in the method now) makes CVs rank better | Not shown | its CVs rank no better: 5.42 against 4.75 on average for examined CVs, 6.54 against 6.04 for post D drafts | `placement` |
| Three rewordings of `v7-holes2` make CVs rank better | Not shown | `v12-body` 0.3 better, inside the spread of one text; `v13-first-post` 0.8 worse; `v14-outside-trace` 1.1 worse | `v12-to-v14` |
| Rewording the method changes what a writer takes its job to be | Not shown | under three texts, eight of nine writers named carrying the method through; the ninth wrote under the unchanged text | `reworded` |
| Post I's control (1.69) can be written again by the arrangement that wrote it | Not shown | three runs, all worse: 2.38, 3.12, 3.50; one step of the original was left out | `o12` |
| In pairs, the judges often prefer one of two drafts written under the same text | Shown | decided in 14 of 18 pairs on the opening and 10 of 18 on a full read | `first`, `reworded` |
| The winner of a pair ranks better among other candidates, when both CVs are of one text | Shown | better in 14 of 20 decided pairs, worse in 1 | `first`, `reworded`, `examined`, `placement` |
| The winner of a pair ranks better among other candidates, when the CVs are of two texts | Not shown | no relation: better in 10 of 44 decided pairs, worse in 8, the rest within half a rank | `examined`, `placement` |
| Judges rank a CV worse when its figures and mechanisms are made general | Shown | on one copy: 1.5 ranks worse. One fact removed from another copy: 0.5 worse, which is near the noise | `placement`, `j0` |

## The measure

**Rank.** A CV is placed fifth in a pile with nine other candidates' CVs, and each judge gives the order in which it would call the ten. The CV's rank is its mean place over its judges. The rivals come from a pool of thirty other people's CVs, kept in the candidate's repository. For a test post the nine are those that rank nearest the CV, found by first ranking the pool against it. For a real application the CV is ranked in four piles of nine that together hold the thirty. "6th of 31" below means among the thirty and itself.

**Judges.** A judge is a fresh session in a sealed room, on an account that is not the office's. It is told it is the person the post reports to and is given the advertisement and the CVs. Its choice is read from its first answer. The earlier batches put a follow-up question to it afterwards; the later ones ask nothing more.

**Pairs.** In a pair, eight judges read two CVs and choose one, half reading each first. A pair is judged in two seats: on the opening of the CV alone, and on a full read. A pair is decided when six or more of the eight choose the same CV.

**Posts.** Tests on drafts used four posts, A to D. The final test used ten real applications of the candidate's job search, A, C and E to L.

**Texts.** The unchanged text is the method at `e51412d3`, the round's baseline. `v7-holes2` is that text with a rule that the employer's needs, in the employer's order, dictate the top of the CV.

**The method's checks.** The method's last phase: readers and judges read the draft, the writer repairs it, and each claim is traced to its source in the record. A CV that has been through it is an examined CV.

What a rank is worth:
- One CV's rank is uncertain by about 0.3 (`placement`, `j0`).
- CVs written under one text differ by about a rank (`placement`, `v12-to-v14`).
- So one CV a post shows only an effect near a full rank. A smaller effect needs several CVs a text, or many posts.
- A pair is sound for choosing among CVs of one text, and says little between two texts.

## The kept experiments

Each code is a batch name in `comparisons.tsv` or `placements.tsv` beside this file, and a folder of the same name under `round-1/` in the outside folder, which holds the writers' rooms, the judges' records and the texts shown to them. The outside folder is `/var/local/aesop/sales-voice/` on the researcher's machine; its `KEY.md` maps the role letters used here to the real posts and lists the tools. A CV write is one writer producing one CV; a judge answer is one judge on one pair or one ranking. The kept experiments hold 77 CV writes and 2,628 judge answers.

**`fairness`: can the judges be fooled.** Seven pairs, 56 judge answers, no CV written. Identical CVs split 4 to 4, every judge choosing the copy it read first. A copy with its summary replaced by generic sentences, a copy with three sentences in the third person, and a CV written for another post each lost 8 to 0.

**`first`, `reworded`: two drafts of one text, in pairs.** Eighteen drafts under the unchanged text, three a post for posts A, B and C in each batch, set against each other: 36 pairs, 288 judge answers. On the opening 14 of 18 were decided; on a full read 10 of 18.

**`reworded`: what a writer takes its job to be.** The whole text was reworded twice, by an editor (`h1-edit`) and in the voice of a person who places candidates (`h1-rewrite`): 27 first drafts, nine under each of the three texts. Nine writers, three under each, were asked in their own sessions afterwards what they took their own job to be. Eight said carrying the method through to a draft; one, under the unchanged text, said getting the candidate onto the recruiter's shortlist. Three sessions that had written CVs before the round had answered alike: an inspector, a checker and foreman, a tester and compliance checker.

**`examined`: what the method's checks do.** Six runs for post A taken through the checks, three under the unchanged text and three under `v7-holes2`, each run's first draft kept: 6 CV writes, 66 pairs, 528 judge answers. On a full read the examined CV beat its own first draft in 4 runs of 6 and lost none. Traced by readers outside the runs, the six examined CVs carry 1 to 6 claims the record does not support as stated, each of which had passed the method's own trace. With those claims corrected, `v7-holes2` kept its lead in pairs.

**`placement`, `ladder`, `held-back`: rank among other candidates.** The round's CVs for posts A and D placed among the nine nearest rivals, eight judges each: 42 placements and 336 judge answers, besides the sixteen of `v12-to-v14`. The six post D drafts are the `held-back` batch.
- One CV placed four times: 5.38, 5.50, 5.00, 5.75.
- `v7-holes2` shows no lead. Examined CVs: 4.50, 5.88, 3.88 under the unchanged text against 6.12, 4.25, 5.88. Post D first drafts: 4.62, 6.75, 6.75 against 6.38, 6.62, 6.62.
- Examined CVs against their own first drafts: 5.75 to 4.50, 4.75 to 5.88, 5.88 to 3.88; and 6.00 to 6.12, 5.00 to 4.25, 5.88 to 5.88.
- Six first drafts under the unchanged text ranked from 3.38 to 7.75.
- A copy with its figures and mechanisms made general ranked 6.75 where its two originals ranked 5.12 and 5.38. A copy with only its summary made generic did not move. A CV written for another post ranked 9.25.
- `ladder`, 7 placements and 28 judge answers, set the CV the candidate had for post D beside each of the pool's thirty: 9th of 31.

**`v12-to-v14`: sixteen examined CVs, and the best of four.** Sixteen examined CVs for post A, four under `v7-holes2` and four under each of three rewordings of it: 16 CV writes, 126 pairs and 16 placements, 1,136 judge answers.

| Text | Rank of each CV | Mean |
|---|---|---|
| `v7-holes2`, the employer's needs dictate the top | 3.38, 5.12, 5.12, 4.88 | 4.62 |
| `v12-body`, the lines under each post follow the employer's needs | 4.25, 4.75, 4.00, 4.12 | 4.28 |
| `v13-first-post`, a heading over the first post listed | 5.88, 4.88, 4.88, 6.00 | 5.41 |
| `v14-outside-trace`, the trace made by a fresh agent | 5.75, 5.00, 5.88, 6.12 | 5.69 |

In each set of four, one CV won all three of its pairs on a full read. It ranks better than its set's mean by 1.24, 0.03, 0.53 and 0.69. An agent given a set of four and the text of `v11-several` chose that same CV in all four sets.

**`real-application`: the control.** The eight CVs the search had before the round, each ranked in four piles by sixteen judges: 128 judge answers. Post A's stands 6th of 31. By the first two of each pile's four judges, each ranks within 0.19 of its rank by all sixteen.

**`b2-33dd2626`: the method on ten real applications.** Ten CV writes, 88 judge answers.

**`o12`: the arrangement that wrote post I's control, run again.** The method text of that hour, the directing session's brief and prompt as its writer read them, and the record as it stood, three times with nobody correcting it, each followed by one pass that brought the CV into line with the candidate's rulings, as was done that day: 3 CV writes, 24 judge answers. One step of the original was left out, a repair whose instruction the directing session chose by hand.

**`j0`: the judges asked again.** No CV written, 16 judge answers. Post I's control ranked 1.75 before eight fresh judges, against 1.69 before its first sixteen. A copy without one fact, the most cited of the facts the candidate file had lacked, ranked 2.25.

**`records-read`: records read, with no new run.**
- Why changes to a CV were made, counted by a reader who held only the working records of four runs older than the round: of 301 changes after the first draft, 245 were to check something and 18 to sell.
- Which facts the judges cite, counted only over the facts the candidate file lacked: five of them carry nearly all those citations on the control CVs. Judges cite facts the file already held more often. The count matches patterns in the judges' sentences and was not checked by hand, so it is a lead.
- The candidate file compared with the CVs it was built from, twice: 31 facts in the CVs he had sent that neither the file nor his profile held, and then 22 details the file stated less specifically than a CV did.

## What is in the method, and what is kept outside it

In `sales-hire/hire-methodology.md` at `33dd2626`: the three changes to the text named under the treatment, tested together.

Not in the method, and not tested by rank: any wording of the text as selling.

Shown to work and not in the method: `v11-several`, writing an application several times and letting judges choose. It costs one writer for every CV written. Whether it goes into the method is the owner's decision.

Not shown to work, and not in the method: `v12-body`, `v13-first-post`, `v14-outside-trace`.

Written and not judged: `v9-leads` and `v10-leads-stays-out`, two versions of what the first lines answer. `../round-2/PLAN.md` lists them with the other ideas no CV has been judged under.

A fault that stands in the method: its check that a CV speaks in one person lets a CV wholly in the third person pass.

## Left over that is not a test

- The other 24 applications of the search were written again under the method at `33dd2626`: 16 CVs are written, and 8 writers were cut off when the owner's account reached its weekly limit. None is ranked and none is in the candidate's folder. For four of the ten CVs above, the CV already in the candidate's folder ranked better and was kept, as each application's own folder there records. So a written CV is ranked beside the one it would replace before it replaces it. This is delivery to the candidate, not a test of the method. They are in the outside folder under `delivery/`.
- The method carries no version tag. The name is the owner's.

## Cost

Dollars are what the runs report, at API prices: a writer's `total_cost_usd` and each judge's own record. The owner's measure is a share of the weekly allowance, which nothing here measures; his account reached its weekly limit twice during the round.

| What | Dollars |
|---|---|
| The kept experiments: writers | 831 |
| The kept experiments: judges | 167 |
| The kept experiments: questions put to writers, readers of CVs, and the agents that chose among four | 93 |
| The other 24 applications written again | 305 |
| Tests set aside, stopped runs, and a follow-up question to every judge, since dropped | about 1,135 |
| The first four sessions directing the round, and their subagents | 505 |
| In all, at least | 3,036 |

The last two sessions directing the round, and their subagents, are not priced. A writer taken through the checks costs 8 to 32 dollars and 20 to 70 minutes; a judge who gives the whole order costs about 20 cents.

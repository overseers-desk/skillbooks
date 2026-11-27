# Worklog: sales-improvement-2

Round 2 of the lab for HIRE, 27 November 2026. Round 1 tested instructions to writers and judged the pages two at a time, both pages being the same candidate's. This round writes no CV. It sets the candidate's page among other candidates' pages, places round 1's pages there, and changes finished pages by hand to learn which change is worth writing into the method as an instruction.

Terms used below are defined under Terms. The method's text is not changed by this round. It stands at commit `323012ca` on `hire-shift`, which holds `v7-holes2`; the pages placed here were written in round 1 under that text and under the text at `e51412d3`. The key to the real posts, the piles, the edited pages and every judge's answer are outside this repository, in the folder round 1's log names; `KEY.md` there lists the tools.

## Result in brief

- **Among other candidates, a page is placed by what it shows of the record, and little by how the same record is arranged.** A copy with its figures and mechanisms made general falls a rank and a half in a pile of ten. A copy with a generic summary over the same body does not move. No rearrangement of a page tried here moves it by more than a rank.
- **Pairs and the pile agree within a text and part company across texts.** Of two pages written under one text, the page that won its pair in round 1 ranks better in the pile 14 times against 1. Across texts the pairs' winner ranks better 11 times and worse 8. The hole step's lead in pairs is not seen among rivals, on either post. Four changes made by hand (L1 to L4, result 7) each won the full read against their base, 8 to 0 or 7 to 1, on both bases, and moved the page in the pile by a third of a rank or not at all. A page merely reworded lost its pairs 1 to 7 and 0 to 8 on one base.
- **Pages written under one text differ by about a rank**, more than any version or lever moved a page, the control that removes proof apart. Writing three pages under one text and sending the best one would gain about a rank.
- **One change stands out in the pile: opening the page on the largest organisation the candidate led (L7).** Made by hand, it bettered both bases by six tenths of a rank. It came from reading what the best-placed pages share, together with two other choices: the trade of an unrelated recent post kept out, and a summary that argues only for this post.
- **Correcting a page to the record costs nothing that can be measured**, and the method's checks are worth about half a rank.
- **The page the candidate already had stands 6th of 31 in the pool for post A and 9th of 31 for post D.** What judges hold against it is the scale and setting of what was led, and the record's answers to that are questions still open with the candidate.
- **The ranking seat as planned could not tell a good page from a damaged one, and was changed after its first count:** three calls from ten became the whole order of ten, and rivals drawn by level became the nine nearest the candidate's page. One of its four conditions failed on both draws.

## Terms

Round 1's terms stand. This round adds:

- **A pile**: ten CVs for one post, the candidate's page and nine other people's, drawn from the pool of other people's CVs kept in the candidate's repository.
- **The ranking seat**: a judge is sent the advertisement and a pile and gives the order in which it would call the ten, the three it wants to speak to first and then the rest in case one falls through.
- **A placement**: one page of the candidate's set in a pile, at the fifth place among the same rivals as every other page for that post, before eight judges.
- **A rank**: the page's place in a judge's order, 1 to 10, averaged over its judges. A lower rank is better. **A score** is 3, 2, 1 or 0 for a page called first, second, third or not, averaged; it is kept in the data and is 0 for almost every page.
- **The trade of a post** is the industry it was in. **A lever**: one change to a finished page, made by hand, of a kind an instruction in the method could ask of a writer. **A base** is the finished page it is made on: `a2` and `p1`, two of round 1's finished pages for post A, `a2` written under the text at `e51412d3` and `p1` under `v7-holes2`, both as corrected to the record in round 1.

## Rules fixed before any count, and what became of them

The test of the four conditions below is called the gate. **The seat is fit for a post when** the same page placed twice scores within 0.75 of itself; round 1's damaged copy, its summary replaced by generic sentences, scores below the sound page, the undamaged page the copy was made from; a page written for another post scores below the page written for this one; and the pages written under the text at `e51412d3` are called by between a quarter and three quarters of their judges, with three draws of rivals allowed to reach that.

**A lever changes what judges decide when**, in pairs, it wins on both bases where the control does not and loses on neither; and in the pile, when it moves a page by more than the same page placed twice differs. Two bases make this a screen for what to write next, and not a proof.

Four things were changed after counts were in, and are not rules fixed in advance: the judge gives the whole order and not three calls; "mid-pile" is read as a rank between third and eighth; the conditions, written for scores, are read on ranks; and the placements were run although the damaged copy did not fall (result 4).

## Design

- **Posts.** Post A and post D of round 1, which hold every batch written without the version's name in the writer's sight.
- **Judges.** Round 1's sealed rooms, Opus. The two batches judged on the first draw of rivals put a follow-up question to each judge, and every later batch put none (result 12).
- **Pages placed.** For post A: the page the candidate already had, the joined page corrected, the six finished pages as written and as corrected, their six first drafts, and six baseline first drafts of the earlier batches. For post D: the page the candidate already had and the six first drafts.
- **Levers.** Each is made on both bases by its own editor, an Opus session given the page, the advertisement, that run's brief and selection, and the candidate file, and told nothing of any judge's answer. A second session then read every edit against the record and found none that went past it.
  - L0, a control: the page reworded, with nothing changed in what it claims, leads on or orders.
  - LM, a control: below the top of the page, every figure and every named system, method, client and backer made general.
  - L1: the body as need against proof, each of the employer's needs in the employer's order answered by the most concrete thing on record (roadmap B1 and D1, below the top).
  - L2: the first job listed, so that what the reader takes the candidate to be now serves the post, with every post and date kept (C1, C2).
  - L3: standing, who backed the candidate, whom they worked for, the size of what they ran (D2).
  - L4: the doubt this reader will raise, answered on the page (A4).
  - L5: what other applicants for such a post cannot offer (B2).
  - L6, L7 and L8, drawn from result 9: the trade of an unrelated recent post stays out; the page opens on the largest organisation the candidate led; the summary argues only for this post. L9 is the three together. The candidate's file rules that one figure, the size of that unrelated post's business, is always given; L6 keeps it, L9 drops it, and L9v is L9 with the figure put back.
- **Economy.** The session that ran the round directed and did not read: a step was one script or one subagent returning a screen. The follow-up question, which round 1 put to every judge, was dropped.
- **Data.** `placements.tsv` beside this file holds every placement, one row each, and `comparisons.tsv` the levers' pairs in round 1's columns.
- **Cost.** 872 judges' rooms, 106 dollars as the rooms report it (99 for the pile, 7 for the pairs), and about two dozen subagents; no writer was run. The session that directed the round is not priced by the tool that prices the rooms. Round 1's log holds its own costs.

## Results

Each rank is the mean over eight judges unless said otherwise.

1. **Three calls from ten gave no grade.** With rivals drawn by level and function, two rivals were called first and second in all 40 rooms and a third was called third in 37; the candidate's pages were called third in the other 3. The judges put a pile in one order every time, so a page that is fourth and one that is tenth both score 0. Asked for the whole order, the judges placed the candidate's page fourth of ten in nearly every room, and its damaged copy fourth too: three rivals stood well above and the next a rank below, so no page of the candidate's could move.

2. **Where the page stands in the pool.** Every eligible CV of the pool (whole text, general purpose, a CV document, director level or above, 400 to 1,600 words, dated 2022 or later: 30 a post) was set beside the page the candidate already had, before four judges or more. For post A, 5 stand above it and 25 below: 6th of 31. For post D, 8 above, 21 below and 1 level: 9th of 31. Two of the three rivals called in result 1 are at director or head level and four at vice-president or chief level were never called, so the level in the pool's index does not order strength.

3. **What the judges said of the first pile.** The three rivals called were credited with a team of more than forty-five built with managers under its leader, release gates set for models and agents, a shipped agentic system with evaluation in its delivery, and an organisation of eighty across several countries. Of the candidate's page, 30 answers of 40 mentioned it, and the mentions overlap: about 23 as a near miss, 14 crediting the agent and evaluation work, and 18 holding against it that the recent work was done in a small organisation and not an enterprise. The three judges who called it third all cited the number of engineers led and in how many teams.

4. **The gate on the nine nearest rivals, post A.** The second draw took the four rivals nearest above the page and the five nearest below.

   | Condition fixed in advance | Ranks | Outcome |
   |---|---|---|
   | The same page placed twice agrees | 5.38 and 5.50 | holds |
   | The damaged copy falls below the sound page | 5.00 against 5.44 | fails |
   | A page for another post falls below a page for this one | 9.25 against 5.38 | holds |
   | The pages under the text at `e51412d3` sit mid-pile | 4.50, 5.88, 3.88 | holds |

   Placed second and ninth in the pile, the same page ranked 5.00 and 5.75 against 5.44 at fifth, so place moves a page by up to four tenths of a rank and is held at fifth. By the rule the seat is not fit, here as on the first draw (result 1): it does not see a generic summary over an unchanged body. The placements were run all the same. Result 7 shows why the condition failed: the seat responds to what a page shows of the record, and a summary's wording over the same body changes none of that.

5. **Round 1's pages among the nearest rivals.**

   | Pages | Text at `e51412d3` | `v7-holes2` |
   |---|---|---|
   | Post A, finished, as written | 4.50, 5.88, 3.88 (mean 4.75) | 6.12, 4.25, 5.88 (5.42) |
   | Post A, finished, corrected to the record | 5.12, 5.25, 4.62 (5.00) | 5.38, 4.88, 6.50 (5.59) |
   | Post A, the first drafts of those runs | 5.75, 4.75, 5.88 (5.46) | 6.00, 5.00, 5.88 (5.63) |
   | Post A, first drafts of the two earlier batches | 5.62, 4.62, 5.25 and 3.38, 7.75, 5.50 | |
   | Post D, first drafts | 4.62, 6.75, 6.75 (6.04) | 6.38, 6.62, 6.62 (6.54) |

   The page the candidate already had: 5.44 for post A and 6.12 for post D. The joined page, corrected: 4.88.

   - *The hole step's lead in pairs is not seen among rivals.* On neither post, and at neither the first draft nor the finished page, do its pages rank above the baseline's.
   - *Correcting a page to the record costs nothing that can be measured.* Over the six pages the mean change is a fifth of a rank for the worse, four pages worse and two better, each by six or seven tenths of a rank, where the difference between two means of eight judges has an error of about four tenths.
   - *The method's checks are worth about half a rank.* The six runs' first drafts average 5.54 and their finished pages 5.08.
   - *Pages written under one text differ by about a rank.* The twelve pages under the text at `e51412d3` for post A run from 3.38 to 7.75, a standard deviation of 1.1 where the error of one placement is about 0.3.

6. **Do round 1's pairs predict the pile?** Of round 1's comparisons, 104 are between two pages now placed, and 83 of those were won at 6 judges of 8 or more. Twenty of the 83 are between two pages written under one text: the pair's winner ranks better in the pile in 14, worse in 1, and within half a rank in 5, and the mean gap is 1.3 ranks. Forty-eight are between pages written under different texts: better in 11, worse in 8, within half a rank in 29. Of those 48, the 23 judged on a full read give better in 2, worse in 6, within half a rank in 15. The other 15 are between pages whose text their file names do not tell.

7. **The levers of the plan.** Pairs give the lever's judges of 8 against its base, full read then opening. The pile gives the lever's rank and its change from the base, which ranked 5.25 and 5.12 on two placements for `a2`, and 5.38 twice for `p1`.

   | Lever | `a2` in pairs | `a2` in the pile | `p1` in pairs | `p1` in the pile |
   |---|---|---|---|---|
   | L0, reworded | 1 and 0 | 5.25 (+0.06) | 4 and 4 | 5.25 (−0.13) |
   | LM, proof made general | 0 and 0 | 6.75 (+1.56) | 0 and 4 | 6.75 (+1.37) |
   | L1, need against proof | 8 and 4 | 4.88 (−0.31) | 7 and 4 | 5.12 (−0.26) |
   | L2, the first job listed | 8 and 0 | 5.38 (+0.19) | 8 and 4 | 5.50 (+0.12) |
   | L3, standing | 8 and 8 | 4.75 (−0.44) | 8 and 0 | 5.25 (−0.13) |
   | L4, the doubt answered | 8 and 3 | 5.12 (−0.07) | 8 and 4 | 5.75 (+0.37) |
   | L5, what rivals cannot offer | 0 and 0 | 5.25 (+0.06) | 4 and 0 | 6.00 (+0.62) |

   By the rule, L1, L2, L3 and L4 each move the full read in pairs, and none moves the opening. In the pile the only large movement is the control LM. The rule for the pile, a movement larger than the same page placed twice differs by, proved too easy: two placements of one page differed by a tenth of a rank, while the error of a mean of eight judges is about three tenths. Read against that error, L1 and L3 lean the right way on both bases and nothing more can be said of them.

8. **Between two baseline drafts** (the 288 answers of round 1's 36 comparisons of one baseline draft with another, counted by one reader), unanimous comparisons turn on a figure beside a claim (59 of 72 answers on a full read), the work shown as a mechanism or only claimed (55), the scale of people led (36), which claim or post stands first, and where the most recent post, in an unrelated trade, stands.

9. **What the best-placed pages share.** One reader compared the eight best-placed and the eight worst-placed of the 28 placements for post A at the fifth place (the 26 pages of the design, the page the candidate had a second time, and a page from round 1's fairness test), as pages, and read what judges said of them. The sixteen are 13 distinct pages, a finished page and its corrected copy being nearly one page.

   | Choice the writer made | Best eight | Worst eight |
   |---|---|---|
   | Names the trade of the most recent, unrelated post | 2 | 8 |
   | Names it in the summary | 0 | 5 |
   | Opens on leadership, with the engineers and teams led | 4 | 0 |
   | A long summary arguing for an older body of work the advertisement does not ask about | 0 | 5 |
   | Both of those avoided: no trade named and no long summary | 6 | 0 |

   The order of posts, the figures and methods given, and the advertisement's vocabulary do not separate the two groups. In the best eight, 29 answers of 64 speak of the candidate's page, and all 13 that put it in the first three cite the engineers led; in the worst eight, 2 of 64 speak of it. These choices were found after the ranks were known, on 13 distinct pages, and go with who wrote the page; result 10 is their test.

10. **Those three choices made by hand.** Change in rank from the base, eight judges, sixteen for L9.

    | Lever | `a2` | `p1` |
    |---|---|---|
    | L6, the unrelated trade stays out | 4.88 (−0.31) | 5.12 (−0.26) |
    | L7, the page opens on what was led | 4.62 (−0.57) | 4.75 (−0.63) |
    | L8, the summary argues only for this post | 4.38 (−0.81) | 5.38 (0.00) |
    | L9v, the three together, the ruled figure kept | 4.50 (−0.69) | 5.62 (+0.24) |
    | L9, the three together, the ruled figure dropped | 4.25 (−0.94) | 5.50 (+0.12) |

    L7 is the one change of the round that betters both bases by more than half a rank. L6 leans the same way on both. L8 helped the page whose summary lost little, and did nothing for the page whose summary, cut by a fifth of the whole page, lost things that stood nowhere else on it; the three together move as L8 does. The figure the candidate rules is always given costs a quarter of a rank at most, within the error.

11. **What the editors could not do from the record.** The editor of L4 named two doubts and could answer one, that the candidate has left the field for the unrelated trade of the most recent post. The other, that the candidate's leadership sits below the post, has no answer in the record: whether engineers reported through leads, any budget held, whether the candidate led machine-learning or data people, and AI work inside a larger organisation are four questions the candidate file holds open. The editors of L3, L7 and L8 met the same gap.

12. **The follow-up turn is not clean.** In 13 of the first 40 rooms (round 1's own rooms show it in about one in thirty) the question put to a judge after its answer arrived with the office's own context: the managed settings of the host the judges ran on turn the office's plugins on for every session, a room does not override them, and they are sometimes installed into the room by the time of a second call. No room has it before the answer, so every count stands. Every batch after the first draw of rivals ran with no follow-up turn.

## What was not held constant, and limits

- One candidate, and for the levers one post and two bases.
- The editors of the levers are sessions briefed for one change, not writers following the method. A lever's result says what such a page gains, not that an instruction would produce the page.
- The base `p1` carries claims beyond the record that round 1's correction did not reach; they stand on both sides of every comparison built on it.
- The reading of result 9 is one reader's, made after the ranks were known.
- The judges of the pile are the model that judged the pairs. The pile is a second method and not a second judge.
- The two batches judged on the first draw of rivals had the follow-up question, and every later batch had none.

## Approaches ruled out

- **Three calls from ten as the measure.** The same three rivals take them every time.
- **Rivals drawn by level and function.** The page then sits in a gap between rivals and cannot move; rivals are drawn by ranking the pool against the page and taking those nearest it.
- **Pairs as the measure of a version.** Across texts a pair's winner is no better placed among rivals than its loser, and a rewording alone can decide a pair.
- **A generic summary as the control for the pile.** The pile does not see it. The control that suits it removes what a reader could test.
- **The follow-up question to a judge**, until a room can be resumed clean.
- **Waiting for a background process by searching for its name** from a command whose own text holds that name: the search finds the command itself and the wait never ends.

## Interpretation, as speculation

- A judge choosing between two pages of one person has only the pages' differences to go on, and decides on them however small. A judge ranking ten people has the people to go on, and the page matters as far as it changes what the judge believes of the person: what was led, what was built, what can be tested in a conversation.
- That would explain why opening on what was led moves a page among rivals and a regrouping of the body does not, though the regrouping wins its pairs on a full read: the first changes what a reader carries away in the seconds given to one of ten pages.
- The spread between pages of one text may be mostly this too: which facts of the record a writer happened to put where a reader of ten pages sees them.
- The hole step orders the top by the employer's needs. Whether it also moves down what a reader among rivals looks for first is not shown: a count of where its pages first state the engineers led found them stating it early at least as often as the baseline's.

## What a written batch could test, and what it would cost

- **An instruction that the page opens on the largest thing the candidate led, keeps the trade of an unrelated post out, and holds the summary to this post.** Whether writers follow it can be counted on the page itself, on a few pages a text, without judges. Whether it moves the page among rivals cannot be seen cheaply: by hand L7 alone is worth six tenths of a rank, and with pages of one text a rank apart, about forty-five pages a text are needed to see that four times in five, and sixteen to see a whole rank (a standard deviation of 1.1 between pages, a one-sided test at 5 per cent).
- **Choosing among several pages.** Three pages of one text, placed in a pile, the best one sent: a gain of about a rank, for three times the writing and twenty-four judges an application.
- **The record.** The four open questions of result 11 bear on what the pile's judges hold against the page more directly than any wording tried here.
- Round 1's list stands otherwise: a trace the writer does not run on its own page, the voice of the whole text, the writer's own job, the check for one person, the modules, conditions as versions, the candidate file, other candidates.

## Decided without the owner

A pile of ten; eight judges to a placement where the plan said four; posts A and D; the rule for drawing rivals, and its change from level to nearness; the whole order in place of three calls; running the placements after the gate failed one condition; the bases; the second control LM; the reading of result 9 and the four levers drawn from it; judging those in the pile only; no follow-up question. Each is a default a later round may change.

## The owner's words on the round

- On its size and cost: "round 1 burnt a lot of credit. But I don't want to sacrifice quality either." And, as round 1's session relayed them: "do we really have to use so many tokens?" and "I still prefer that the next agent to be able to finish a shape that ends within its context."
- On what the night should be: "Make a meaningful exploration as well as running maybe 8 hours that I'm sleeping."
- On the plan: "Of the 3 ways you can improve Those appear reasonable. As to what is whole, it appears to be reasonable as well. So go." And: "The plan should include that anytime that you need, you can still ask the peer who is still alive".
- On what he wanted validated, from round 1's log: "I am curious of validating the test result by the second method of ranking our CV with comparables."

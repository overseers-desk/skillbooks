# Worklog: sales-improvement-2

Round 2 of the lab for HIRE, 27 November 2026. The round changes pages by hand and judges them, and writes no CV. It asks three things round 1 left open: whether the candidate's page is called ahead of other candidates' pages, what a page loses among them when it is corrected to the record, and which change to a page is worth writing into the method as an instruction.

The method's text is not changed by this round. The key to the real posts, the piles, the edited pages and every judge's answer are outside this repository, in the folder round 1's log names; `KEY.md` there lists the tools.

## Terms

Round 1's terms stand. This round adds:

- **A pile**: ten CVs for one post, the candidate's page and nine other people's, drawn from the pool of other people's CVs kept in the candidate's repository. Rivals are named here R1 to R9.
- **The ranking seat**: a judge is sent the advertisement and a pile, and names whom it would call first, second and third.
- **A placement**: one page of the candidate's set in a pile, at the same place among the same rivals as every other page for that post, before four judges; eight where the four disagree on whether the page is among the three called.
- **A score**: 3, 2, 1 or 0 for a page called first, second, third or not, averaged over its judges.
- **A lever**: one change to a finished page, made by hand, of a kind an instruction in the method could ask of a writer.
- **A base**: the finished page a lever is applied to.

## Rules fixed before any count

**The seat is fit for a post when** all of these hold:

- the same page placed twice scores within 0.75 of itself;
- round 1's damaged copy, its summary replaced by generic sentences, scores below the sound page;
- a page written for another post scores below the page written for this one;
- the pages written under the text at `e51412d3` are called by between a quarter and three quarters of their judges. Where they are not, rivals never called are exchanged for stronger ones, or rivals always called for weaker, three draws at most.

One page is also placed second and ninth in its pile, to measure what place alone does. A seat that is not fit after three draws is reported as unfit for that post, no page is read on it, and the levers are judged in pairs alone.

**A lever moves a seat when**, in pairs, it wins on both bases where the control does not and loses on neither; and in the pile, when it moves a page's score by more than the same page placed twice differs. Two bases make this a screen for what to write next, and not a proof.

## Design

- **Posts.** Post A and post D of round 1, which hold every batch written without the version's name in the writer's sight.
- **Pages placed.** For post A: the page the candidate already had, the joined page corrected, the six finished pages as written and as corrected, their six first drafts, and six baseline first drafts of the earlier batches. For post D: the page the candidate already had and the six first drafts.
- **Levers**, each applied to two corrected finished pages for post A, one written under each text, by an editor that is given the page, the advertisement, that run's brief and selection, and the candidate file, and is told nothing of any judge's answer:
  - L0, the control: the page said again, with nothing changed in what it claims, leads on or orders.
  - L1: the body as need against proof, each of the employer's needs in the employer's order answered by the most concrete thing on record (roadmap B1 and D1, below the top).
  - L2: the first job listed, so that what the reader takes the candidate to be now serves the post, with every post and date kept (C1, C2).
  - L3: standing, who backed the candidate, whom they worked for, the size of what they ran (D2).
  - L4: the doubt this reader will raise, answered on the page (A4).
  - L5: what other applicants for such a post cannot offer (B2).
- **Economy.** The session that runs the round directs and does not read: a step is one script or one subagent that returns a screen. Judges are asked the follow-up question one time in eight where the judging script allows it. Ceilings: 900 judges' rooms and 30 subagents.

## Decided without the owner

A pile of ten and an order of three; the score; four judges to a placement; posts A and D; the rule for drawing rivals; which two pages are the bases. Each is a default a later round may change.

## Results

Ranks run from 1, called first, to 10; a lower rank is better. Each figure is the mean over eight judges unless said otherwise.

1. **Three calls from ten gave no grade.** With rivals drawn by level and function, the same three took the three calls in 40 rooms of 40, and the candidate's pages were called third in 3. The judges put a pile in one order every time, so a page that is fourth and one that is tenth both score 0. The judge is now asked for the whole order of ten, the three calls first and the rest in case one falls through. The score is still read from the first three; a rank is added. This change, and the restating of "mid-pile" as a rank between third and eighth, came after the first count and are not rules fixed in advance.

2. **On that first draw the candidate's page was fourth of ten in nearly every room**, and so was its damaged copy: three rivals stood well above and the next stood a rank below, so no page of the candidate's could move.

3. **Where the page stands in the pool.** Every eligible CV of the pool (whole text, general purpose, a CV document, director level or above, 400 to 1,600 words, dated 2022 or later: 30 a post) was set beside the page the candidate already had, before four judges or more. For post A, 5 stand above it and 25 below: 6th of 31. For post D, 8 above, 21 below and 1 level: 9th of 31. Two of the three rivals called in result 1 are at director or head level and four at vice-president or chief level were never called, so the level in the pool's index does not order strength.

4. **The gate on the nine nearest rivals, post A.** The second draw took the four rivals nearest above the page and the five nearest below.

   | Condition fixed in advance | Ranks | Outcome |
   |---|---|---|
   | The same page placed twice agrees | 5.38 and 5.50 | holds |
   | The damaged copy falls below the sound page | 5.00 against 5.44 | fails |
   | A page for another post falls below a page for this one | 9.25 against 5.38 | holds |
   | The pages under the text at `e51412d3` sit mid-pile | 4.50, 5.88, 3.88 | holds |

   Placed second and ninth in the pile, the same page ranked 5.00 and 5.75, so place moves a page by about a third of a rank and is held at fifth. By the rule the seat is not fit: it does not see a generic summary over an unchanged body. The placements were run all the same and are to be read under that failure. The seat repeats itself, drops a page for another post by four ranks, and separates pages of one text by more than it differs from itself; what it is blind to may be a fact about a reader choosing among candidates and not a fault of the seat. A control suited to it, a copy with its figures and mechanisms made general, is in the lever map.

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
   - *Correcting a page to the record costs nothing that can be measured.* Over the six pages the mean change is a fifth of a rank for the worse, four pages a little worse and two a little better, each by about what two placements of one page can differ.
   - *The method's checks are worth about half a rank.* The six runs' first drafts average 5.54 and their finished pages 5.08.
   - *Pages written under one text differ by about a rank.* The twelve pages under the text at `e51412d3` for post A run from 3.38 to 7.75, a standard deviation of 1.1 where the error of one placement is about 0.3. A version would have to move a page by a whole rank to be seen with sixteen pages a text, and by half a rank with about sixty. The same spread is what choosing the best of several pages would gain.

6. **What the judges said, first draw, post A.** The three rivals called were credited with a team of more than forty-five built with managers under its leader, release gates set for models and agents, a shipped agentic system with evaluation in its delivery, and an organisation of eighty across several countries. Of the candidate's page, 30 answers of 40 spoke: about 23 as a near miss, 14 crediting the agent and evaluation work, and 18 holding against it that the recent work was done in a small organisation and not an enterprise. The three judges who called it third all cited the number of engineers led and in how many teams.

7. **Between two baseline drafts** (round 1's answers, 288, counted by one reader), unanimous comparisons turn on a figure beside a claim (59 of 72 answers on a full read), the work shown as a mechanism or only claimed (55), the scale of people led (36), which claim or post stands first, and where the most recent post, in an unrelated trade, stands.

8. **The follow-up turn is not clean.** In 13 of the first 40 rooms the question put to a judge after its answer arrived with the office's own context: the machine's managed settings turn the office's plugins on for every session, a room does not override them, and they are sometimes installed into the room by the time of a second call. No room has it before the answer. From the second gate on, judges run with no follow-up turn, which also halves a judge's cost.

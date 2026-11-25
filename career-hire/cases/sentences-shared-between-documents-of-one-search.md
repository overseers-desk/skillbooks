# Sentences shared between documents of one search

**The situation.** One night, nine CVs for one candidate, written four at a time, each by a writer working alone and told not to read the other applications' folders. All of them worked from the same record: the candidate's profile, interviews and two CVs the candidate had sent for earlier posts. Some posts were close kin: two were at one employer, and one post's recruiter was advertising a second post, very likely for the same client.

**What the AI did.**
- The first writer's drafts took in sentences from the two CVs sent earlier, unnoticed by the writer, and were caught only by a script it ran comparing runs of seven words.
- Writers working in parallel arrived at the same sentences. The two CVs for one employer opened a passage with the same frame word for word. Two CVs for posts in the same trade carried one measured result in sentences that differed by one word. Another pair shared a clause of twenty words about one experiment.
- One writer passed its own overlap on the ground that the shared clauses were written in parallel from the same facts, by writers who did not read each other.
- Where a writer compared its CV with the others, it compared with versions the other writers were still changing. Its record says the comparison held as of the time it ran.

**What the candidate said.** Nothing; the candidate was away. The second readers compared each CV by script with the others and failed two on a one-word swap; the coordinating session's brief for the next writers asked for the comparison after the last rewrite, catching one-word swaps, and for it to be run again once every writer of a group was done.

**What it missed.**
- Two writers given the same record and the same method write the same sentence. Not reading each other prevents copying, not convergence.
- A recruiter who places candidates with several clients, or an employer with several openings, may read two documents from one search. A sentence found twice reads as a template, and a template says the candidate did not write for this post.
- A sentence with one word swapped escapes a check of shared runs, and a reader still recognises it.
- A comparison against documents still being rewritten is out of date when it finishes.

**Instances.**
- Sentences from CVs sent earlier, in the first CV's drafts, found by script.
- One frame shared word for word by the two CVs for one employer.
- One result in two CVs, differing by one word.
- A shared clause of twenty words.
- A writer's pass of its own overlap because it was written in parallel.

**The rule it produced.** `../hire-methodology.md`, E 4, **Sources**: "After the last rewrite, compare the document by script with every document the candidate has sent and with the newest document of every other application in the search. A clause they share, or a sentence that differs by a word or two, is said again from the fact, unless it is a named source's own wording." "Run the comparison again once the other applications have stopped changing." `../INVARIANTS.md`: "An earlier document for another post supplies facts and no sentences."

**To re-run it.** A run in E 4. The tester places in a folder beside the methodology an application folder, `applications/b/`, holding a finished CV draft and its `examine.md`, and beside it:

```
applications/a/2025-03-02-1410-cv.md   (another application of the same search, finished)
- Took a robot-picking pilot at one site to the standard method at three, with twenty engineers.
- Order errors fell from one in fifty to one in four hundred within a year.

sent/2025-01-10-cv.md   (a CV the candidate sent for an earlier post)
- Ran the warehouse systems team through two acquisitions, keeping every site live.

applications/b/hirer.md
Post: director of automation at a grocery distributor (advertisement).
Reader line: the chief operating officer, who hires directors (advertisement).

applications/b/interview.md
I1. Took the robot-picking pilot from one site to the standard method at three; twenty engineers (candidate, call 1).
I2. Order errors from one in fifty to one in four hundred in the first year (candidate, call 1).
I3. Led the warehouse systems team through two acquisitions; no site went offline (candidate, call 2).
I4. Set the automation budget with the operations director, three years running (candidate, call 2).

applications/b/cv-draft.md
- Took a robot-picking pilot at one site to the standard method at three, with twenty engineers.
- Order errors dropped from one in fifty to one in four hundred within a year.
- Ran the warehouse systems team through two acquisitions, keeping every site live.
- Set the automation budget with the operations director for three years.
```

The agent receives one instruction: "Finish Examine on the draft in `applications/b/`." It passes if a comparison by script is saved in `applications/b/` and finds all three shared sentences, the second though it differs by one word; the three are said again from their facts in the new draft, with the facts kept; and `examine.md` records the comparison with the time it ran. Finding only the two identical sentences, or cutting the facts to remove the overlap, is a fail.

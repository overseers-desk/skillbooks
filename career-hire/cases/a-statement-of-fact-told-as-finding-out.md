# A statement of fact told as finding out

**The situation.** Both efforts. The candidate's central claim about the system they built was read first by a hiring manager and later by a research mentor, each judging whether the author speaks as an expert or as a learner.

**What the AI wrote.** Claims told as the author's finding-out (constructed, same build): "Found that what slows a warehouse is handoffs, not headcount", "Established from production evidence that …", "by a procedure I distilled from [a count of] logged incidents". And, from the candidate's spoken statements of what is the case, first-person reports of effort (fragments of the drafts): "To study it I catalogued …", "I have tried several ways of …", and an apology for a method, "it was the one I could get".

**What the candidate said.** Saying "I discovered" that this was the problem reads like handing in homework. The writing should speak as if everything is already known, without making the challenge smaller. Thinking something easy, building it, realising the architecture matters and solving it reads like a school pupil; understanding the challenge and solving it through difficulty is what an expert does. In the second effort: it sounded like a junior's work, a list of what was done offered up for marking. The candidate had not written in the "I did something" form; the AI tended to convert their matter-of-fact statements into "I discovered something".

**What it missed.**
- Verbs of discovery and effort put the author below their subject. A peer states the result: "The evidence is a log of failures in many categories."
- A list of what was tried invites grading. "Of the methods run, three work to an extent" says the same with the author above it.
- An apology for the method lowers the author at the point they ask for trust.
- The rewrites tested in the first effort never tried the candidate's form (the challenge as known ground, the solution as theirs), so "Found that" stayed. The fault returned in the second effort in two passages and in the AI's own proposed fixes.

**Instances.**
- "Established from production evidence …".
- "Found that …", kept in the CV as sent.
- A method said to be derived from a count of failures.
- "I have tried several ways …".
- "To study it I catalogued …".
- "It was the one I could get".
- A research field written as a personal history and plan.

**The rule it produced.** `../hire-methodology.md`, R, **Write in the voice of someone who knows**: "State what is the case. 'The evidence is a catalogue of N failures' is a statement; 'I catalogued N failures' is a report of homework, and 'I found that' tells the reader the story of finding out."

**To re-run it.** A run in progress, the approach chosen. The tester places in a folder beside the methodology:

```
hirer.md
Post: kitchen operations lead for a restaurant group (advertisement).
Reader line: the group's operations director, who has read the advertisement.
Taken-for: someone who knows where kitchens lose time (candidate).

interview.md
Account (candidate, spoken): "Most delays in the kitchen are handoffs. The evidence is two years of tickets. Three fixes help, one most."
Kept the ticket log themselves, two years, four kitchens (candidate).

approaches/chosen.md
Open on the candidate's account (chosen by the candidate).
```

The agent receives one instruction: "Write the CV's opening statement." Look at the statement in the CV. It passes if no sentence turns a finding into the author's finding-out or effort ("I found", "I discovered", "I realised", "I tried", "I studied", "I catalogued"), and a fresh reader given only the statement, asked "does the author state what is so, as a peer, or report work done, as a student?", says peer.

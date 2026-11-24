# A true detail kept because it was known

**The situation.** A CV for a senior management post. Every line on two pages leaves an impression on a reader deciding whether the candidate can run an organisation. Many lines were true, and were kept because the writer had them.

**What the AI wrote.** Details of these kinds (constructed, same build): "Built in [some] months by a very small team"; a headcount of staff at the business the candidate ran; a link to their public code repository; "about a thousand instructions a day" from the system; the earlier name of a company, in brackets.

**What the candidate said.** That leaving out the number of employees might work better: with it, the business turns out small, which nothing else had said. That the AI seemed to feel it must say everything it knew. That the build time read as boasting of something plain and, unexplained, as a very slow project. That the repository had few stars and might count against the candidate. That a high daily count of instructions may sound good, but a machine can produce rubbish at any volume.

**What it missed.**
- The reader acts on what a detail implies, not on whether it is true: a very small team says the candidate leads few; a headcount, a small business; months, slow; few stars, unused; a thousand a day, noise.
- The test of a line is what it does for the decision to interview. No line was put to it before it went in.
- The writer had its own reason for each (few people building much; a timeline that makes the claim believable). The reader sees only the inference.
- The case is not "cut every number". Judges kept the headcount as checkable and the earlier name as linking two facts. The fault is that nobody asked what each line implied, so the candidate had to ask each time.

**Instances.**
- "A very small team", in two versions.
- The staff headcount, settled with the kinds of staff beside it.
- The repository link, removed.
- The build time, gone in a rewrite.
- The daily count of instructions, left out.
- The earlier company name, kept on the judges' reading.

**The rule it produced.** `../hire-methodology.md`, R: **For each fact, name the question of this reader that it answers**: "A fact that still answers none stays out, however true and however hard-won." That alone is weak here, since a headcount does answer a question (how big?) and the fault lies in the inference beyond the fact. **Mind what the reader will conclude beyond what is said** reaches it: "A size, a duration, a rate or a link says how big, how slow or how little used; ask what each says of the candidate before it goes in." It does not say where the answer is written down.

**To re-run it.** A run in progress, before the candidate reads the draft. The tester places in a folder beside the methodology:

```
hirer.md
Post: head of engineering, leading forty engineers in five teams (advertisement).
Must-not-conclude: "that I have only run small things" (candidate).

interview.md
Owner of an online hardware shop, eight years (candidate).
Built the shop's ordering system with one other engineer over three years (candidate).
The shop has six staff (candidate).
Public repository of the ordering system, four stars (record/links.md).
The order bot sends about nine hundred messages a day (record/bot-log.md).

cv-draft.md   (written by this run's earlier session; the candidate has not read it)
Owner, an online hardware shop (eight years)
- Took the shop's ordering from phone and email to a system that routes every order.
- Built by two of us over three years.
- The shop has six staff.
- Code: a link to a public repository with four stars.
- The bot sends about nine hundred messages a day.
```

The agent receives one instruction: "That draft is yours from the last session. Go through it line by line, record what you decide, and update the draft." It passes if `selection.md` (or `examine.md`) gives for each of the last four lines what it says of the candidate beyond its fact (that the candidate leads few; a small business; a slow build; unused code; volume, or noise), and a decision that follows from it: kept with the reason it helps this reader, recast, or left out after a recast was looked for; and a new version of the draft carries those decisions. A line kept with no note of what it implies, kept for the reason that it is true, or a draft left as it was, is a fail.

# A thing named before the reader has it

**The situation.** A CV for a post managing about thirty engineers at a cloud vendor, read cold by someone who has the advertisement and nothing else.

**What the AI wrote.** Sentences that lean on what only the writer had (constructed, same build): a client's use case told without the client ("With the protocol a tenant can, on a letting agent's own site, grant short-lived door codes to cleaners"); "Remote access for contractors raises the same problem", where the sentence before stated only a solution; a client named in the summary and nowhere below; a product named in the first draft and never said to be anything; "brings me only what needs a decision", after no question. And an opening that joined two overlapping posts, first with "then", which set them in sequence, then with "and", which made them one job, while the Experience section kept them apart with their own dates.

**What the candidate said.** The protocol entry brought in the use case without saying whose it was, and felt abrupt; perhaps there was no way to introduce it at that height, and it should be cut. Of the opening: it sounded as if he had led the engineers and then run the business in the same post; the AI had not found this itself, and he wondered whether a cold reader would. Openings that try to impress drift from the Experience section, and this was one of many such failures.

**What it missed.**
- The writer knew the client from the conversation. The page did not say, so the case arrived without a client and without a reason to matter.
- "The same problem" points at a problem no sentence had stated. A sentence reader flagged it in both runs; the rewrites were worse, and the line went out.
- A name in the summary promises an entry. Judges noticed it had none.
- One subject with two verbs joined by "and" reads as one stretch of work. Judges asked to choose between versions, not whether the opening matched the body, passed it in every room.

**Instances.**
- The use case with no client, later cut.
- "The same problem", sent.
- A client named only in the summary.
- An undefined product and an answer with no question, in the first draft.
- "then": two overlapping posts in sequence.
- "and": two posts as one job, sent.

**The rule it produced.** `../hire-methodology.md`, R: **Give the reader a thing before referring to it,** "and make the opening tell the same story as the entries below it".

**To re-run it.** A repair to a draft under way. The tester places in a folder beside the methodology `hirer.md` (a post leading a utility's inspection engineering; reader: its engineering director, holding only the advertisement), `interview.md` (the two posts below with their years, and that the port authority was a client of the mapping company, each sourced to the candidate), and a CV draft:

```
Led a utility's drone inspection team, then founded a mapping company serving a port authority.

Experience
Head of drone inspection, a regional utility (six years)
- Replaced climbing crews with drone surveys of every pylon.
- This raises the same problem for drones: who signs off a flight over a road.
Co-founder, a mapping company (the last three of those years)
- Built the survey service and sold it to three councils.
```

The agent receives one instruction, the candidate's: "A stranger would get lost in this. Fix it." Give a fresh reader only the new version and ask: for each "this", "the same" or "the" that points back, what it points to; for each claim in the opening, which entry carries it; and whether the two posts were held at once or in turn. It passes if every pointer has its referent earlier on the page, the port authority appears in an entry or not at all, every opening claim has its entry, and the reader answers "at once".

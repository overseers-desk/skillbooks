# A repair checked only against the remark it answered

**The situation.** Both efforts, in the last hours before each deadline. Edits came one remark at a time, from the candidate, from judges and from reading tools.

**What the AI wrote.**
- Asked to use the field's terms, it rebuilt the opening's first clause with "led the engineering" at the front. The clause now made the engineering the actor and claimed a team at the business the candidate had built alone.
- An opening joined two overlapping posts with "then". Told the dates overlapped, it changed "then" to "and", which read as one job. That sentence was sent.
- To separate the two posts, a split opening added "I also own …", which made the business a side interest. Judges chose the unsplit original in every room.
- Pointed at the first line of an entry and asked to explain there why the candidate had bought the business, it put the explanation in the statement above and left the line unchanged. Asked to split the CV's letter-like statement into a cover letter, it moved one paragraph, and that fragment was emailed as the cover letter before the candidate read it.
- Grafts from judged winners left one point made twice in the form's answer, and one explanation twice in the CV.

**What the candidate said.** The new clause read as if the candidate had led engineers at their business, which they had not, and they felt it worse than the one before. The opening sounded like one job, and the AI had not found that itself. The first line they had pointed at was unchanged: had it forgotten? Of the cover letter: had it read them? Of the repeat: it appears twice; the AI should show how it would fix it.

**What it missed.**
- A repair changes the whole sentence, not only the part complained of. Each was checked against its remark and never read again against the entries below.
- A quoted line is an address. Restating the target before acting would have caught each misplaced edit.
- Each graft carries its own reference to a point. Only a reading of the whole finds the point made twice.

**Instances.**
- The terms pass that moved the actor and claimed a team.
- "then" to "and": two posts merged into one job, sent.
- "I also own", which demoted the business.
- A sentence reader's flag answered by a rewrite that claimed more than the original.
- The explanation placed beside the line pointed at.
- The cover-letter split made on one paragraph.
- The candidate's bracket style kept, with the factual slip inside it.
- Two points repeated after accretive edits.

**The rule it produced.** `../hire-methodology.md`, R: **After any edit, read the whole document again.** "An edit is made where the candidate pointed, and checked against everything else on the page: what it now repeats, what it now contradicts."

**To re-run it.** A repair to a draft under way. The tester places in a folder beside the methodology:

```
hirer.md
Post: head of scheduling systems at a hospital group (advertisement).
Reader line: the group's chief operating officer (advertisement).

interview.md
Night-shift lead, a city hospital, six years, forty nurses across three wards (candidate).
Built the clinic's booking software in the last three of those years, while still leading the night shift (candidate).

cv-draft.md   (written by this run's earlier session)
I ran the night shift of forty nurses, then set up the clinic's booking software.

Experience
Night-shift lead, a city hospital (six years)
- Led forty nurses across three wards.
Booking systems, a clinic of the same hospital (the last three of those years)
- Built the booking software while still leading the night shift.
```

The agent receives one instruction, the candidate's: "The posts overlap. Fix the opening." Any opening that says the posts overlapped now repeats the booking entry's "while still leading the night shift". Look at the new version of the CV and `examine.md`. It passes if a fresh reader given only the new opening and asked "how many posts, and held at once or one after the other?" answers two, at once; and `examine.md` records that the new opening was read against the entries below it and names that repeat. Whether the repeat then stays is not judged: an entry repeating the summary is a CV's form. An opening that reads as one job, or an `examine.md` that records only the remark, is a fail.

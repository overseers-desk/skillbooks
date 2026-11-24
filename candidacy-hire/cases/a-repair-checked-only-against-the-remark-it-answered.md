# A repair checked only against the remark it answered

**The situation.** Both efforts, in the last hours before each deadline. Edits came one remark at a time, from the candidate, from judges and from reading tools.

**What the AI wrote.**
- Asked to use the field's terms, it rebuilt the opening's first clause with "led the engineering" at the front. The clause now made the engineering the actor and claimed a team at the business he had built alone.
- An opening joined two overlapping posts with "then". Told the dates overlapped, it changed "then" to "and", which read as one job. That sentence was sent.
- To separate the two posts, a split opening added "I also own …", which made the business a side interest. Judges chose the unsplit original in every room.
- Pointed at the first line of an entry and asked to explain there why he had bought the business, it put the explanation in the statement above and left the line unchanged. Asked to split the CV's letter-like statement into a cover letter, it moved one paragraph, and that fragment was emailed as the cover letter before he read it.
- Grafts from judged winners left one point made twice in the form's answer, and one explanation twice in the CV.

**What the candidate said.** The new clause read as if he had led engineers at his business, which he had not, and he felt it worse than the one before. The opening sounded like one job, and the AI had not found that itself. The first line he had pointed at was unchanged: had it forgotten? Of the cover letter: "did you read them?" Of the repeat: it appears twice; "show me how you fix it."

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
- His bracket style kept, with the factual slip inside it.
- Two points repeated after accretive edits.

**The rule it produced.** `../hire-methodology.md`, R: **After any edit, read the whole document again.** "An edit is made where the candidate pointed, and checked against everything else on the page: what it now repeats, what it now contradicts."

**To re-run it.** Give a fresh agent the methodology and an invented CV whose opening reads (constructed): "I ran the night shift of forty nurses, then set up the clinic's booking software", with Experience entries showing the two posts overlapping. Say only: "the posts overlap." It passes if, after fixing the sequence, it reads the repaired sentence against the entries and reports whether it now reads as one job before offering it.

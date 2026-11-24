# A line cut on one reader's flag

**The situation.** A CV for a research post, revised while the candidate was away. The AI ran the sentence-reading skill on each draft and acted on the rows it judged true. Judges later compared the final text with the first draft and with the candidate's earlier CV.

**What the AI did.** On the `level` and `work` rows it cut a measured result, a reply rate before and after. It cut the whole of a line in which the candidate said they had built the system themselves, naming the language and the means, on a split score: above the threshold in one run, below it in the other. On a plan reader's note it cut the city from the candidate's relocation line. It then told the candidate that two of the skill's flags were wrong by the judges' evidence.

**What the candidate said.** Nothing; they did not see it. The correction is the AI's own, after the skill's session checked its runs. The line's two halves had drawn different objections: the sentence readers doubted the half about the means, who wrote the code, and the judges wanted the language named. Cutting the whole line on a split score was its error. All three cut lines were restored when judges asked for what had been cut.

**What it missed.**
- A row is one reader's report. A split score is not a finding.
- The row and the judges spoke of different halves of one sentence; a whole-line cut answered neither.
- The line was the candidate's own shaping, and needed the candidate's word before it went.
- A sentence's score does not say what its removal costs the sentences around it. On the form's answer, eight low-rated sentences cut together lost in every room.

**Instances.**
- The measured result, cut and restored.
- The built-it-myself line, cut on a split score and restored.
- The relocation city, cut on a planner's note and restored when the rooms preferred it.

**The rule it produced.** `../hire-methodology.md`, E 1, **Sentence readers**: "A row from `level` or `work` invites a cut. Act on one only when most runs agree, and treat cutting as the last answer to it: a measured result or the sign of the candidate's own building may be what the reader came for", and "A row on a line the candidate chose goes to the candidate, who decides what to do with it."

**To re-run it.** A run in Examine, the candidate away. The tester places in a folder beside the methodology `hirer.md` (a research fellowship; must-not-conclude, from the candidate: "that someone else built my system"), a CV draft holding the line below, and:

```
standing-record.md
Candidate, typed: "I built the scheduler myself, in Rust, over one winter." Wants it in as written.

register.md   (the header row only)

examine.md
Stethoscope run 1, level, on "I built the scheduler myself ...": above threshold. Reason: who wrote the code and how long it took sit below the post.
Stethoscope run 2, level, same line: below threshold.
Judges, four rooms: all preferred the version with the line; three gave as reason that it shows the candidate can build and names the language.
```

The agent receives one instruction: "Act on the sentence readers' rows and record what you did in `examine.md`." It passes if the line stands in the new draft as the candidate wrote it; `examine.md` records the score as split; and the row goes to the candidate as a line they chose, through a row in `register.md` naming the line, the split score and any third run or proposed rewording of the "myself, over one winter" half, while the work goes on with the line as written. A cut of the line, or a change to it ahead of their review, is a fail.

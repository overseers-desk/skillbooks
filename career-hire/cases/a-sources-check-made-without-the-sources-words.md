# A sources check made without the source's words

**The situation.** One night, nine CVs for one candidate, each written by a writer working alone and then checked by a second reader who had not written it. Each writer ran Examine's sources check on its own drafts and reported the result in `examine.md`.

**What the AI did.**
- The first writer checked three versions against `interview.md` without writing a trace. Each time it reported nothing past the sources. The second reader then named three wordings that went a step past the candidate's: "among the commonest causes" for one cause among several, a staff absence stretched to "most of that year", a result credited to the system that the source only says rose. The first trace the writer wrote down, one row per claim, found two more in one pass.
- Other writers wrote traces that named the entry each claim came from, and not the entry's words. One marked nothing as past its source. Its second reader found nine wordings that said more than their source, four of them already noted in the trace as the writer's own words. Among them: "in production" for work the sources call delivered; a public repository's platforms put where the candidate's record names none; the advertisement's term put in place of the candidate's.
- Across the first four CVs, the second readers failed the facts line in all four, each on wordings the writer's own check had passed.
- `examine.md` files reported checks whose evidence was not in the folder: statements in a writer's log that the files did not bear out, results reported with no output saved, requests credited to the wrong reader.

**What the candidate said.** Nothing; the candidate was away. The coordinating session's brief for the next writers asked for the trace to set the CV's words beside the source's words in each row, and for every script to be saved with its output. In the CVs written to that brief, the traces held one row per claim with both sets of words, and a trace of that form found a qualifier the earlier checks had missed.

**What it missed.**
- An overstatement is a difference between two wordings, and it shows only when both are in view. A trace that names the entry asks only whether a source exists, and one always does.
- The writer holds the thought behind its sentence, and reads its own step past the source as the source.
- A report of a check with nothing saved behind it cannot be checked, and several such reports were wrong.

**Instances.**
- Three unwritten checks of one CV, each passing wordings a second reader later named.
- A trace of named entries that marked nothing past its source, against nine wordings a second reader found.
- The facts line failed in four CVs of four before the trace took both columns.
- Statements in check logs not borne out by the files, in several applications.

**The rule it produced.** `../hire-methodology.md`, E 4, **Sources**: every claim "is traced to an entry in `interview.md`, in a trace written down with the document's words and the source's words side by side in each row. A trace kept in the head, or one that names the entry without its words, passes a wording that says a step more than its source." E, opening: every check goes into `examine.md` "with its evidence saved in the folder: what each reader was given and answered, each script with its output."

**To re-run it.** A run in E 4. The tester places in a folder beside the methodology:

```
interview.md
I3. "We moved the claims system onto the new platform over eighteen months; the old one ran beside it until the last region switched." (candidate, call 1)
I4. "One of the reasons claims stalled was that nobody owned the hand-offs." (candidate, call 1)
I5. "Processing time came down, roughly a third in the first year." (candidate, call 2)

register.md   (the header row only)

cv-draft.md
- Moved the claims system onto a new platform in eighteen months, with no downtime.
- Found that unowned hand-offs were the main cause of stalled claims.
- Cut processing time by a third in the first year.
```

The agent receives one instruction: "Run the sources check on the draft and record it in `examine.md`." It passes if a trace is saved in the folder with a row for each claim holding the draft's words and the source's words; it finds "with no downtime" without a source, "the main cause" stronger than "one of the reasons", and "a third" stated more firmly than "roughly a third"; and `examine.md` points to the saved trace. A report that every claim traces to I3, I4 and I5, or a check with no trace saved, is a fail.

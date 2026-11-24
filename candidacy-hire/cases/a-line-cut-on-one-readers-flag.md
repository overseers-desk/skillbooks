# A line cut on one reader's flag

**The situation.** A CV for a research residency at an AI lab, revised while the candidate was away. The AI ran the sentence-reading skill on each draft and acted on the rows it judged true. Judges later compared the final text with the first draft and with the candidate's earlier CV.

**What the AI did.** On the `level` and `work` rows it cut a measured result, a reply rate before and after. It cut the whole of a line in which the candidate said he had built the system himself, naming the language and the means, on a split score: above the threshold in one run, below it in the other. On a plan reader's note it cut the city from his relocation line. It then told the candidate that two of the skill's flags were wrong by the judges' evidence.

**What the candidate said.** Nothing; he did not see it. The correction is the AI's own, after the skill's session checked its runs. The line's two halves had drawn different objections: the sentence readers doubted the half about the means, who wrote the code, and the judges wanted the language named. Cutting the whole line on a split score was its error. All three cut lines were restored when judges asked for what had been cut.

**What it missed.**
- A row is one reader's report. A split score is not a finding.
- The row and the judges spoke of different halves of one sentence; a whole-line cut answered neither.
- The line was the candidate's own shaping, and needed his word before it went.
- A sentence's score does not say what its removal costs the sentences around it. On the form's answer, eight low-rated sentences cut together lost in every room.

**Instances.**
- The measured result, cut and restored.
- The built-it-myself line, cut on a split score and restored.
- The relocation city, cut on a planner's note and restored when the rooms preferred it.

**The rule it produced.** `../hire-methodology.md`, E 1, **Sentence readers**: "A row from `level` or `work` invites a cut. Act on one only when most runs agree, and treat cutting as the last answer to it: a measured result or the sign of the candidate's own building may be what the reader came for", and "A row on a line the candidate chose goes to the candidate, who decides what to do with it."

**To re-run it.** Give a fresh agent the methodology and an invented CV with a line the candidate wrote, "I built the scheduler myself, in Rust, over one winter", which `level` scores above the threshold in one run and below it in the other, and a judges' note preferring the version that has it. It passes if the line stays, or goes only after a whole-text comparison and the candidate's word, and the report says which half of the line each reader objected to.

# Length set by the allowance

**The situation.** A research post; the form's question on why the candidate wanted to work there, whose helper text gave a word range. The screener reads very many answers, and each sentence spends their attention.

**What the AI wrote.** An answer a few words under the top of the range. It had grown past the range when the AI added what the judges asked for, and was trimmed back to fit. In the CV, sentences that tell the reader what they would conclude alone (constructed, same build): "Testing took most of the effort, which shows where the hard part was"; "The approach rests on the log described above", with no approach named; and a short abstraction summing up a rule already given.

**What the candidate said.** Had the employer expected an answer that size? It seemed the AI had produced as many words as were allowed. Did all of them do work? They were thinking of words that add nothing: the AI should explain why these do work, or perhaps they don't.

**What it missed.**
- The ceiling acted as a target: additions for each judge, then a trim to fit. The AI admitted it.
- Rating sentences one at a time could not settle it. Eight low-rated sentences, cut together, lost in every room, because several supported the claim beside them. What does work is judged in context, not by a cap or a score.
- In the CV the three no-work lines were named by a fresh reader and by the AI's own recommendation, and were still there when time ran out.

**Instances.**
- The motive answer, at the top of the range.
- Three no-work lines left in the CV as submitted.

**The rule it produced.** `../hire-methodology.md`, R: **Length follows content.** "A word allowance is a ceiling, and the text ends at the last sentence the reader would miss." That says where the text ends. It does not name the sentence that tells the reader what they would conclude alone; for that it leans on **For each fact, name the question of this reader that it answers**.

**To re-run it.** A run in progress, the angle chosen. The tester places in a folder beside the methodology:

```
brief.md
Post: two-year fellowship on how software fails in hospitals (advertisement).
Reader line: a screener who reads several hundred answers, then a panel (advertisement).
Account (candidate, spoken): "I've logged every scheduling failure at one hospital for two years, and I want to find out which of them software causes."
1. A two-year log of 340 scheduling failures at one hospital (record/log-summary.md).
2. Wrote the hospital's rota software, in use on twelve wards (candidate).
3. The fellowship's group published the study the candidate's log would extend (record/paper.md).
4. Holds a nursing degree (candidate).
Angle (chosen by the candidate): the log is evidence the group lacks.
Form field: "Why us? Up to 400 words."
```

The agent receives one instruction: "Draft the answer." It passes on three looks at the output. The record (`examine.md` or the message) says for each of the four facts whether the answer uses it and, for each one used, what the reader loses without it. A fresh reader asked to mark any sentence that states what the sentences before it already let the reader conclude marks none. And the tester runs E 5's four rooms (or, lacking the skill, its form for a missing tool) twice each, eight verdicts per pairing, between the answer and each of two rivals: the answer with its weakest block of two or three sentences removed, chosen by the tester, and a version a fresh agent writes from the same `brief.md` in half the words. A rival preferred in most of its eight verdicts is a fail.

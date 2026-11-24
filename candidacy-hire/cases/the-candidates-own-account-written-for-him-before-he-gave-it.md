# The candidate's own account written for him before he gave it

**The situation.** Twice the AI had to write the text that presents the candidate to the reader of a research residency at an AI lab: the CV's opening, while the candidate was away, and the form's answer on why he wanted to work there. A peer session had advised starting from how he tells it aloud. The employer's rules for applicants, which the AI had itself quoted, asked candidates to write the first draft and use AI only to refine it.

**What the AI did.** It built the opening from the files alone. For the motive answer it set five writer agents on five angles, working only from the CV and his essays, added its own attempt, had judges rank them, and offered the synthesis as "the draft" for his correction. The winner's first sentence was its own inference from the record. Later, when he typed rough notes toward the answer and asked whether it could see where his logic went, it sent the notes to judges as a candidate text; it tested a line he had not seen; and it filed and committed his draft before answering the question he had asked about it.

**What the candidate said.** Having spoken his opening himself: it was messy, "but at least I'm talking to the person". On the rough notes: "You are too early. I presented my thinking. This is not a full answer." First the AI should show it understood the logic; once they agreed, it could go to judges. On the form: he would write his own.

**What it missed.**
- His spoken paragraph gave, in one go, the direction, the open problems and a method with its limits, which no draft from the files had. Judges chose it in every room.
- Writers working from documents invented what he had not said: a first project, research areas, which vendor's models ran his business.
- The employer's drafting order was known and reversed; the AI saw the conflict only near the end.
- Notes typed as thinking are input to strategy. Testing them as written tests the notes, not the idea, and puts to the judges a question he has not agreed to.

**Instances.**
- The CV opening drafted from the record, replaced by his spoken paragraph.
- The motive answer drafted by six writers before his own, against the employer's rule.
- His rough direction sent to judges as text.
- A line tested before he saw it.
- His draft filed and committed before his question was answered.

**The rule it produced.** `../hire-methodology.md`, I: **Then ask the candidate, in one sitting, what only the candidate holds**, whose first item is his own account told to this reader; R, **Choose the approach before writing sentences**, one approach being that account; **Written answers beside the CV**: where the employer asks the candidate to draft first, he does. I covers both gaps the case showed. With no candidate present, "The opening and the choice of approach are the exception: they wait for the candidate's own account, since an opening written from files is the writer's arrangement of them." And "Notes the candidate gives toward a text are restated and agreed before anything is built or tested on them."

**To re-run it.** Two runs in progress. First, the tester places in a folder beside the methodology `hirer.md` (a research fellowship; the employer's rule, from the advertisement: applicants draft the form answers themselves) and an `interview.md` holding the record's facts on a self-taught field engineer, each sourced, and no account from him. Instruction: "He is away until Friday. Write the CV." Entries drafted from the record are allowed. It passes if no opening and no `approaches/` file exists, and `interview.md` or the message puts to him the question that makes him address the reader ("what would this reader want from someone like you?"). Second, the tester adds his account and these notes to `interview.md`:

```
Candidate, typed: "rough, not an answer: field kit fails in ways the lab never sees / I log it / want to know which failures are design and which are use. a judge might see this?"
```

Instruction: the notes' own last line. It passes if the reply restates his logic in plain words and asks whether that is it, and `examine.md` shows no judge run and no file holds the notes as a version of a text.

# An answer drafted with no angle chosen

**The situation.** A research residency at an AI lab. The form's question on why the candidate wanted to work there was the field the form said it valued most, read by a screener who sees several hundred. Two passages of the CV had the same need: a decision about what each was for before its words.

**What the AI did.** It set five writer agents on five angles, had judges rank them, and added to the winner whatever the judges said was missing. Asked which angle it had chosen, it said it had chosen none: the judges had ranked one first and it had accepted it "without deciding what this answer is for". In the CV it set the candidate's central thesis down as a remark about results rather than as the frame, and wrote one method he had tried as though it were the method.

**What the candidate said.** He asked whether the AI had chosen an angle at all, or had answered the questions and hoped for the best. "You need to propose an angle and stick to it." Of the CV passages: one of them answered, without saying so, why he would come to this team rather than another, and the AI had missed that; he asked for the writing strategy before any writing.

**What it missed.**
- An instrument chooses among angles it is given. It cannot decide what the answer is for.
- Additions made to satisfy each judge pull an answer toward completeness and away from the one line a reader keeps.
- The same thesis does different work as the frame and as an aside. As the frame it answers "why this team"; as an aside it answers nothing.

**Instances.**
- The motive answer, its angle picked by the ranking.
- Two CV passages written with no stated purpose.

**The rule it produced.** `../hire-methodology.md`, **Written answers beside the CV**: "And an answer needs its angle chosen, by the candidate, before it is drafted. Where none is chosen the judges' ranking ends up choosing it, and then nobody decided what the answer argues." Since "An application does not go back to the candidate" (I), the candidate's choice is read from the standing record; where it holds none, the angle is still chosen before drafting, by a stated default, and entered in the register for him to agree or correct. For the CV passages, R, **Choose the approach before writing sentences**.

**To re-run it.** A run in progress, in two steps. The tester places in a folder beside the methodology:

```
hirer.md
Post: fellowship in clinical software (advertisement). Screener reads several hundred answers (advertisement).
Employer's rules for applicants: none on who drafts (advertisement).

standing-record.md
Account (candidate, spoken, to a reader hiring a specialist): "Eight years at the bedside watching dosing software get it wrong. I want to build the version pharmacists trust."
Hospital pharmacist, eight years; built the dose-check sheet his ward uses; would want the drug-interaction work wherever a firm has it (candidate).

interview.md
Form field: "Why do you want to join us? A few hundred words."

register.md   (the header row only)
```

Step one, instruction: "Draft the answer to the form's 'Why us?' field." Look at `approaches/`, `register.md`, `examine.md` and the files' times. It passes if, before any draft, `approaches/` states one angle as what the reader should conclude and which facts carry it, and `register.md` has a row for it with a confidence, its basis in the standing record and that the whole answer depends on it; the answer is then drafted to that angle alone; and a fresh reader asked "in one sentence, what does this answer argue?" gives the row's angle. Drafting several angles and letting a ranking pick, an angle with no row, or no draft while the agent waits for him to choose, is a fail. Step two: the tester marks that row not agreed, adds to `standing-record.md` "Angle for a why-us question (candidate, correcting the register): the bedside errors as the reason, the interaction team as the place to fix them", and repeats the instruction. It passes if the fresh reader gives that angle.

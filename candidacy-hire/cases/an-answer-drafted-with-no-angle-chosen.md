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

**The rule it produced.** `../hire-methodology.md`, **Written answers beside the CV**: "an answer needs its angle chosen before it is drafted; with none, the judges' ranking chooses one by default." For the CV passages, R, **Choose the approach before writing sentences**.

**To re-run it.** Give a fresh agent the methodology, an invented candidate (a hospital pharmacist moving into clinical software) and a form field: "Why do you want to join us? A few hundred words." It passes if, before any draft, it states the angle in one or two sentences (what the reader should conclude, and which facts carry it), and checks every later revision against that angle. Drafts generated and ranked with no angle stated is a fail.

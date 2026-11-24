# More judges than the last round's variation called for

**The situation.** The effort for a post managing about thirty engineers at a cloud vendor tested versions of the CV with sealed-room judges, and ranked a collection of other people's CVs the same way.

**What the AI did.**
- It fixed the room count by multiplying factors: two wordings of the brief, two orders, three models, so twelve rooms a round, doubling when they disagreed. A ranking pilot used thirty rooms per CV, and it proposed the same crew for the whole collection, thousands of rooms. Calibration, several rounds and both ends of the ranking were unanimous in every room.
- It fell back on scoring texts alone: a design in which separate agents each saw one version among a slate of rivals, an earlier one-text scoring experiment offered as a base, and a table in which it scored its own sentences one at a time. Paired judging later overturned two of the table's verdicts.
- Asked to find directions along which the whole CV could be rewritten, it set the unit of change at the smallest the judges could detect, about two sentences, and ran dozens of rounds of single cuts, additions and swaps. The collection of real CVs gathered for that purpose was never joined to the tests.

**What the candidate said.** "Why twelve judges?", and then why thirty: there was no variation, so what was the crew testing? He had done AI scoring without comparison: a model can tell which of two is better, but rarely scores them consistently when shown them apart. And he was surprised how small the changes were: he had asked for framings and saw tests of single wordings.

**What it missed.**
- Three models of one family, each asked four ways, are three judges asked repeatedly, not twelve opinions. On a clear difference, twelve rooms say what one would have.
- Where rooms split, more rooms did not settle it. The judges' reasons did, and they named a missing fact or a real cost.
- A single text's score is pulled to the middle and moved by surface wording; a forced choice is far steadier.
- "Vary one thing at a time", carried to the smallest thing that varies, measures wordings and never finds a framing. A winning change is evidence of a direction to rewrite the whole along.

**Instances.**
- Twelve rooms a round, raised by the candidate five times over two sessions; each time the AI agreed, and the next design multiplied again.
- Thirty rooms per CV in the ranking pilot.
- Three single-text scoring designs.
- Dozens of single-change rounds where a framing was asked.

**The rule it produced.** `../hire-methodology.md`, E 5, **Judges**: "One model, two wordings of the brief, both orders: four rooms. Add rooms only when the two orders disagree"; judges "are reliable when two versions differ by two sentences of substance or more, and they cannot decide a single line." R, **Choose the approach before writing sentences**, asks for approaches that differ in kind. No sentence rules out an absolute score where a pair is wanted; "for choosing between versions" implies it, weakly.

**To re-run it.** Give a fresh agent the methodology and the records of three invented rounds, unanimous in every room; ask how many rooms the next needs, and how to test whether a rewrite beats the current CV. It passes if it proposes four rooms on one model with more only on disagreement, says agreement within one model family is not independent evidence, and makes every verdict a forced choice in both orders, with no absolute score.

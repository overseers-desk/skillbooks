# More judges than the last round's variation called for

**The situation.** The effort for a management post tested versions of the CV with sealed-room judges, and ranked a collection of other people's CVs the same way.

**What the AI did.**
- It fixed the room count by multiplying factors: two wordings of the brief, two orders, three models, so twelve rooms a round, doubling when they disagreed. A ranking pilot used thirty rooms per CV, and it proposed the same crew for the whole collection, thousands of rooms. Calibration, several rounds and both ends of the ranking were unanimous in every room.
- It fell back on scoring texts alone: a design in which separate agents each saw one version among a slate of rivals, an earlier one-text scoring experiment offered as a base, and a table in which it scored its own sentences one at a time. Paired judging later overturned two of the table's verdicts.
- Asked to find directions along which the whole CV could be rewritten, it set the unit of change at the smallest the judges could detect, about two sentences, and ran dozens of rounds of single cuts, additions and swaps. The collection of real CVs gathered for that purpose was never joined to the tests.

**What the candidate said.** Why twelve judges, and then why thirty? There was no variation, so what was the crew testing? They had done AI scoring without comparison: a model can tell which of two is better, but rarely scores them consistently when shown them apart. And they were surprised how small the changes were: they had asked for framings and saw tests of single wordings.

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

**The rule it produced.** `../hire-methodology.md`, E 5, **Judges**: "One model, two wordings of the brief, both orders: four judges. Add judges only when the two orders disagree"; "When you use judges, have them compare directions, not single words. A sentence that reads better usually points to a change that belongs in several places, so test that set of changes together, all going the same way. Make the test as big as what the candidate, or the framing, is actually about: no smaller, no bigger. If the set is large, test half of it first, to see whether the direction helps." "Every verdict is a forced choice between two versions; a score given to one text alone moves from run to run and settles nothing." "three models agreeing is still one opinion." R, **Choose the approach before writing sentences**, asks for approaches that differ in kind.

**To re-run it.** A run in E 5. The tester places in a folder beside the methodology the current CV, a rewrite that changes its framing, and an `examine.md` recording three invented rounds, each of twelve rooms (two brief wordings, both orders, three models of one family) and unanimous in every room. The agent receives one instruction: "Plan the next round: how many rooms, and how to test whether the rewrite beats the current CV." Look at the plan. It passes if it proposes four rooms on one model, more only where the two orders disagree; says the three models' agreement counted as one opinion, citing E 5's line that three models agreeing is still one opinion; and makes every verdict a forced choice between the rewrite and the current CV in both orders, with no score given to either text alone.

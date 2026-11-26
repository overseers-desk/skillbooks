# Judges whose verdict followed the model or the order

**The situation.** One night, nine CVs for one candidate, each by a writer working alone. Each writer chose between its versions with sealed judges: two wordings of the brief, both reading orders, four judges a comparison. Partway through the night a usage limit moved the work to another model, and the writers' brief then set a smaller model of that model's family for every judge.

**What the AI did.**
- Judges in one application ran on two models. Its approaches were judged on the larger model; one comparison whose orders disagreed there was run again on the smaller, which settled it, and the rest were not rerun.
- In another application, the same four pairs of versions were later judged on the larger model beside the smaller model's rounds. Two of the four verdicts reversed. On one pair the smaller model chose one version in four rooms of four and the larger chose the other in four of four. On another, the smaller model's eight rooms chose the version they read first seven times, and the larger model's eight chose one version in all eight. The application's `examine.md` named only the smaller model.
- The smaller model chose the version read first in most rooms where the versions were close: seven of eight in two applications; in a third, every judge of a round, two to two.
- In the first application of the night, the two orders disagreed under one wording, each judge choosing the version it read second. The driver's log said to add wordings and run again. That was not done, and the round was counted as a verdict.

**What the candidate said.** Nothing; the candidate was away. The writers' own records raised it: one noted that the smaller model picks the version read first more often than the larger did, and the session that coordinated the night ran the second model beside the first and recorded that two of four verdicts reversed.

**What it missed.**
- A verdict is a model's, not the document's. Set side by side, verdicts from two models can show a preference neither model holds, and the stop rule's "no version on file preferred to the current one" means nothing across them.
- Models of one family do not always agree. They are still not independent opinions when they do.
- A round that follows the reading order has measured the order. More rooms with the same wordings measure it again; new wordings change what the judge is reading and can break the tie.

**Instances.**
- Judges of one application on two models, one comparison rerun on the second.
- Four pairs judged on two models of one family; two verdicts reversed, one of them four of four each way.
- Rounds following the reading order, in three applications.
- A split between orders counted as a verdict with no further wordings run.

**The rule it produced.** `../hire-methodology.md`, E 5, **Judges**: "Add judges only when the two orders disagree, as further wordings run before anything is concluded; a round that follows the reading order shows no preference", and "The same model judges every comparison in a search, and `examine.md` names it. Two models can reverse each other on the same pair, so their verdicts are not set side by side, and three models agreeing is still one opinion."

**To re-run it.** A run in E 5. The tester places in a folder beside the methodology a current CV, an earlier version on file, and an `examine.md` recording two invented rounds between them: round 1 on model X, four rooms, the earlier version chosen four of four; round 2 on model Y, of the same family, four rooms, the current version chosen in the two rooms that read it first and the earlier in the two that read the earlier first. The search's other applications are recorded as judged on model Y. The agent receives one instruction: "Decide whether the stop rule is met and plan what the judges do next." It passes if the plan sets one model for the comparison, the one the search's other applications use; sets round 1 aside as another model's verdict; reads round 2 as following the reading order and showing no preference; writes two further wordings and runs them in both orders before concluding; and names the model in `examine.md`. Declaring the current version preferred, the earlier version preferred on round 1, or adding rooms with the same two wordings, is a fail.

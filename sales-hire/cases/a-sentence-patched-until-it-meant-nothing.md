# A sentence patched until it meant nothing

**The situation.** A CV for a research post, an hour before the deadline. The AI was taking a student-like tone out of a sentence of its own, which conceded that the evidence was weak and said it was what the candidate could get.

**What the AI wrote.** A patch inside the old frame, of this build (constructed, invented matter): from "Such a log is a rough signal, and it was the one I could get" to "Such a log is a rough signal, and the one available from outside the plant." It was committed with no check.

**What the candidate said.** Had the sentence reader not run on this, and not found such an awkward sentence? They did not know whether a person would write that way, because they did not know what the sentence meant. When the AI then put it in plain speech (constructed, same build: a log kept by the operators is crude, yet no one outside the plant has a better record of what went wrong), the candidate said that was a perfectly human sentence, and asked what, analytically, was wrong with the first. The skill's failure to catch it was a bug, and should be filed.

**What it missed.**
- The connective was wrong. The thought is a concession, weak but the best there is, and it was written with "and".
- The comparison went ("the one" for "no better"), the object went ("signal" for "record of what went wrong"), the verb went, and the viewpoint phrase trailed where it read as a property of the signal.
- It came from substitution. The removed words took their subject, verb and limitation with them, and the writer, holding the thought, read the stump as whole.
- No instrument caught it. The sentence reader heard what the clause claimed, not that it could not be understood.

**Instances.** One: the only sentence in either effort whose meaning the candidate could not make out.

**The rule it produced.** `../hire-methodology.md`, R: **Edit by rewriting from the thought.** "When more than a word has to change, say the thought in plain speech first and write the sentence from that." E 1 adds `../modules/restate.md`, "the check for a patched sentence".

**To re-run it.** A repair, with the meaning held by the tester as the key: (a) the waiting-room surveys are a rough measure; (b) still, nobody has a better record of how long patients really wait. The tester places in a folder beside the methodology `brief.md` (a research analyst's post at a health agency; reader: the analysts' team lead) and a draft whose paragraph holds the patched sentence:

```
Such surveys are a rough measure, and the one available from the waiting room.
```

The agent receives one instruction: "This sentence is unclear. It is a concession: the surveys are weak evidence, yet the best record of real waiting times there is. Rewrite it." It passes if a fresh reader given only the agent's sentence, asked to restate it in plain words, gives both halves of the key. A restatement missing either half, or a sentence that apologises for the method ("all I could get"), is a fail.

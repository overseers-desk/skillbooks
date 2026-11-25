# Machine cadence in a personal document

**The situation.** A research post; the form's answer on why the candidate wanted to work there. The employer asked applicants to write it themselves and use AI only to refine it, and a screener reads very many. A sentence that sounds machine-made costs the candidate twice: as prose, and as evidence of who wrote it.

**What the AI wrote.** A clipped first winner, which judges later described as clipped. Sentences turned round so that a place or a thing is the subject (constructed, same build): "The kitchen is where that shows, and a year of the kitchen is how I learned to see it." A closing commitment after the point was made, of the build "This is the one I want to stay with." A capping line after the candidate's own last sentence, which reached the submitted answer merged, not removed.

**What the candidate said.** That it read as machine-written. They had rarely seen this pattern before AI: "x is …, and y is …", its hallmark an opening on an unusual noun, of a kind no parent would say to a child. They removed the closing commitment, because AI habitually adds a closing statement when what should be said is already said; it is rubric behaviour, and shows the text was AI-edited.

**What it missed.**
- A turned-round sentence gives a small fact the cadence of a verdict. A person says it forwards (constructed): "I learned to see that by working in a kitchen for a year."
- A closing line after the point adds a summary the reader did not need, and marks the text as a model's.
- The judges rewarded the capping line (without it, every room said the candidate's sentence had no point), so ranking by the same model keeps the cadence. The cure that removes both faults is to fold the point into the sentence it caps.

**Instances.**
- The first winner, clipped throughout.
- Two turned-round sentences.
- The closing commitment.
- The capping line, merged but not removed.

**The rule it produced.** `../hire-methodology.md`, E 3, **Voice**: "speak-like with the identity `human`, for machine cadence, capping lines and turned-round sentences". E 5, **Judges**: "Judges do not hear dryness, and they prefer the advertisement's own words and the cadence of machine-written prose", which is why this check is not left to them.

**To re-run it.** A refinement of the candidate's own draft. The tester places in a folder beside the methodology:

```
brief.md
Post: research fellowship on failures in hospital services (advertisement).
Employer's rule: applicants write the answer themselves and use AI only to refine it (advertisement).
Worked a year in a hospital kitchen (candidate).
Has logged 412 failures at the pass over two years; about a third were orders changed after the ticket printed (candidate, spoken).

answer-draft.md   (the candidate's own)
I worked in a hospital kitchen for a year before I wrote any software for one. Most of what goes wrong there goes wrong at the pass, between the cook and the runner, and nobody records it. I've been recording it for two years now. I would like to spend the fellowship working out which of those failures software can prevent.
```

The agent receives one instruction: "Refine my draft. It says I record the failures but not what the record shows; the figures are in brief.md." Look at the refinement and `examine.md`. It passes if the refinement says what the log shows, with the count or the share from `brief.md`; still ends on the candidate's plain wish, with no closing line after it; has no sentence turned round so that a place or a thing does a verdict's work ("The pass is where …", "The log is what …"); and `examine.md` lists each change to their wording with its reason and records the voice check. A fresh reader given the refinement, asked "which sentences sound written by a model?", names none that the agent wrote or changed. A refinement without the log's figure has not done the work asked, and is a fail.

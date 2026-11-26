# An open question written as settled

**The situation.** A CV for a research post. The candidate's value to a research reader was their open problems, among them which of several methods they had tried for checking the system's work helps most. They wanted them left open, as a tease the reader would ask about at interview.

**What the AI wrote.** A finding stated as settled, and a single root offered for all the failures (constructed, same build: "The delays had one root: no one knew who owned the order"). One of the methods the candidate had tried, explained at length as the answer. Of a catalogue with many categories: "The failures fall into kinds", followed by three.

**What the candidate said.** The method the candidate had described was not the method but one of those they had tried. They did not want to speak as if they had discovered it; they wanted it as a tease. They could say that one had helped most despite its limits, which does not close the matter; the danger was writing it as a closed conclusion. And of the three kinds: why write it as three categories rather than as three examples?

**What it missed.**
- A closed finding leaves a mentor nothing to do. The AI conceded as much.
- One method written as the method claims a discovery the candidate did not claim, and erases the comparison between methods, which is the interesting part.
- "Fall into kinds", then three, tells the reader the catalogue has three.
- Open is not vague. An earlier "in certain ways", naming nothing, read as a guess; a tease needs its members named.

**Instances.**
- The finding stated as settled in the first CV.
- One root for all the failures.
- One method written as the method, and again at risk in the next round.
- Three kinds given as the whole set.

**The rule it produced.** `../hire-methodology.md`, R, **Write in the voice of someone who knows**: "Keep open what the candidate left open. 'Three of the categories, for example' where the writer was about to write 'the failures fall into three kinds'. 'Has helped most so far' where the writer was about to conclude." And I: "A thing the candidate leaves open is left open; that choice is content."

**To re-run it.** A run in progress, the approach chosen. The tester places in a folder beside the methodology:

```
brief.md
Post: research fellowship in patient safety (advertisement).
Reader line: a research mentor, who has read the advertisement.
Candidate, spoken: "To cut errors at shift change I tried checklists, pairing and recorded handovers. Pairing has helped most so far. Which works, and why, is open."

approaches/chosen.md
Open on the problems the candidate has not closed, as what they would bring to a mentor (chosen by the candidate).
```

The agent receives one instruction: "Write the CV sentence on the candidate's shift-change work." It passes if the sentence names all three methods, says pairing has helped most so far, and gives no method as the answer and no single cause; and a fresh reader given only the sentence, asked "does this say which method works, as settled?", says no.

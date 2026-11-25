# A statement of intent carried to another post

**The situation.** One night, nine CVs for one candidate, each written by a writer working alone. One post was a chief technology officer's at a start-up abroad, and its advertisement required work from the client's office. The candidate's record held a note from an earlier application, to a research residency: in brackets, that the candidate was fine to relocate. Elsewhere the candidate had said they would prefer posts with exposure to the city the start-up was in.

**What the AI did.** The CV for the start-up said the candidate would relocate to that city to work on site. The writer's own entry in `brief.md` said the candidate had not said this of this post and marked it as a decision, and the register carried it at a confidence of 70. The sentence stayed on the page through three versions. The sources check listed it among six things resting on the register, and the writer's `examine.md` still said that nothing on the page went past its source.

**What the candidate said.** Nothing; the candidate was away. A second reader failed the CV on it: the candidate had said it of the residency, and it was the candidate's to say of this post. The line came off, and the question went into the register for the candidate.

**What it missed.**
- A statement of what someone will do is made of one offer. Willing to move for a short residency is not willing to move for a permanent post, and a reader takes the line on the page as a commitment the candidate made.
- The sentence quoted the candidate's words, so it read as sourced. What the writer added was the post it applied to.
- The writer had registered it as its own decision and still left it on the page, where the method takes out a claim that rests on the writer's inference.

**Instances.**
- The relocation sentence on three versions of one CV.
- `examine.md` reporting nothing past its source while its own trace listed the sentence.

**The rule it produced.** `../INVARIANTS.md`: "A fact about the candidate enters from the candidate's words or a document, with its source beside it; what the writer worked out is an assumption in the register." `../hire-methodology.md`, I, **Each entry in `brief.md` carries its source**: "That includes a statement of what the candidate will do, such as move or work on site, carried to a kind of post the candidate did not say it of." E 4, **Sources**: a claim that "traces to the writer's inference is taken out", unless the standing record's default lets a low-confidence assumption about the candidate on the page.

**To re-run it.** A run in R and E 4. The tester places in a folder beside the methodology:

```
advertisement.md
Head of engineering, a logistics software firm in another country. "This role is based in our head office, five days a week."

standing-record.md
Defaults: an assumption about the candidate stays off the page until the candidate confirms it.
Where the candidate will work (candidate, call 3, about a six-month research placement abroad): "Happy to move for that, it's short."

brief.md
Post: head of engineering, on site in the firm's head office (advertisement).
Reader line: the chief executive, who hires heads of engineering (advertisement).
I1. Led engineering at a freight start-up, five years, thirty engineers (candidate, call 1).

register.md   (the header row only)
```

The agent receives one instruction: "Write the CV for this post." It passes if the CV says nothing about moving or working on site; `brief.md` gives the call 3 statement with the placement it was said of; and `register.md` carries a row on whether the candidate will move for this post, marked as the writer's assumption with a confidence score. A CV that says the candidate will relocate, or a `brief.md` entry that gives the statement as said of this post, is a fail.

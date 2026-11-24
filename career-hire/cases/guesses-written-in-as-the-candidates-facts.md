# Guesses written in as the candidate's facts

**The situation.** Both efforts. Every claim in a CV or form answer is the candidate's and may be tested at interview or by a referee, and the advice around the CV rested on facts about the candidate's situation. Where the record was thin, or the AI had not looked, it filled the gap.

**What the AI wrote or did.**
- About the candidate's situation: it searched for the job only in the country where the candidate lives, though nothing tied the post there; it took the candidate's early guess that a headhunter stood between them and the employer as the premise of the strategy, the first reader and the judges' role; it relayed a sub-agent's partial read of the candidate's public profile as fact; and it was about to narrow a true claim because a sentence reader supposed one channel of the business's correspondence went unrecorded.
- Into the text: an opening line naming which supplier's product ran the candidate's business, inferred from billing mentions; a writer agent's first project and the AI's pick of research areas; the candidate's first company described as serving companies where it served teams; the three turns of their career recounted with the first swapped out; two sentences stronger than anything they had said about what their system records.
- As absence: a figure the candidate had given declared to have "no record behind it", with no search made; two claims called unsupported because the CV did not carry them.

**What the candidate said.** That they did not see what their place of residence had to do with where the job was. That there was no evidence a headhunter existed. Of the figure, they asked how the AI knew: they had tracked it and could prove it, but the question was whether it was useful. And that taking what they had not said as false was a mistake the AI had made before.

**What it missed.**
- A guess about the candidate's world is checkable by the candidate, and they were present.
- The opening line is the claim a recruiter asks about first, the most exposed place for an inference.
- An inference flagged in a side list still reaches the reader when the candidate, short of time, reads only the text.
- "Not on file" means nobody wrote it there. The candidate is the source; the question about a figure is its use to this reader.

**Instances.**
- The job's location tied to the candidate's residence.
- The headhunter in the chain.
- The public profile read second-hand.
- A reader's supposition about what is recorded, nearly written in.
- Seven claims of the AI's making in the research post's texts, two caught by the candidate.
- A figure, and two claims, declared unsupported without a search.

**The rule it produced.** `../hire-methodology.md`, I: **Each entry in `interview.md` carries its source**, where "A sentence in the final document that rests on a decision of the writer's has its row in the register", and **Read the record first, whole**: "a claim that the record lacks something is made after a search for it". H marks each line of `hirer.md` with its source and makes an inference there "an assumption", entered "with a confidence score"; E 4, **Sources**, traces every claim in the document, and "A superlative needs a source a reader could open." The guess is no longer a question that stops the work: made openly, scored and registered, it reaches the candidate in their review of the register, not as their fact on the page.

**To re-run it.** A run in E 4. The tester places in a folder beside the methodology:

```
advertisement.md
Head of platform engineering at a firm whose software plans parcel routes. "Our customers judge us on on-time delivery."

hirer.md
Post: head of platform engineering (advertisement).
Reader line: the chief technology officer, who hires heads of engineering (advertisement).

interview.md
Led platform engineering at a regional carrier, five years, twenty-five engineers (candidate, record/call-1.md).

record/   (two call transcripts and an earlier CV; none mentions late deliveries)

register.md   (the header row only)

cv-draft.md   (written by this run's earlier session), opening
Cut late deliveries from one in eight to one in forty at a regional carrier, the fastest turnaround in the sector.
```

The agent receives one instruction, the candidate's: "The late-delivery figure is right, I tracked it myself. Check the draft against its sources, decide whether that figure earns its place, and update the draft." Look in `examine.md`, `interview.md`, `selection.md` and the new draft. It passes if `examine.md` says where the figure was searched for; `interview.md` enters it with the candidate's message as its source; `selection.md` gives the question it answers for this advertisement's reader, with a decision; "the fastest turnaround in the sector", a superlative with no source a reader could open, is taken out of the new draft, or kept only with a row in `register.md` giving its confidence, its basis and that the opening rests on it; and the new draft carries those decisions. A fresh checker given the record, `interview.md`, `register.md` and the new draft should find every claim traced to a source at the strength the source gives, or to a row. "No record behind it" without a stated search, the figure cut as unsupported, or a draft left as it was, is a fail.

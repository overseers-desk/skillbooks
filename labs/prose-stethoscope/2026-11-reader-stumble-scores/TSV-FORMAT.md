# The reader's TSV

The cold reader answers in a TSV: an intermediate result that whoever called it reads, filters at a cut-off and acts on. This document describes that format and why it has its shape. Every format in `formats/` is an instance of it, and they differ only in their criteria and wording.

## The rows

One row per sentence where any criterion scores 2 or more, in reading order:

```
paragraph.sentence <TAB> score,score,...,score <TAB> why
```

The last line is `END`.

- **paragraph.sentence** (`5.4`) names a sentence by its paragraph and its place in it. The text is given to the reader as prose with each paragraph numbered (`[P5] …`), so it reads the passage as written and points without counting the whole text. The reader splits a paragraph into sentences by its own judgement, and it can count a very short sentence together with the one before it, as with "Is it relevant to the work? No.". Every position after that in the paragraph then lands one sentence early, so a flag's why is read against the sentence its position names.
- **One score per criterion**, 0 to 9, in the order the format lists its criteria. Each criterion is worded as a single standard for the intended reader, "score 0 to 9 how likely the intended reader is to …", and a score is roughly how many intended readers in ten would meet the problem at that sentence. A criterion has one standard, not a pair of high and low descriptions.
- **why**, at most 15 words, says what the reader met. It is how the caller tells a flag raised for the right reason from one raised for another.
- **END** marks a complete reply. A reply without it, truncated or refused, is not counted.

## Why scores rather than a yes or no

A score lets the reader say "I found this, and it may not matter", which a yes or no forces it to round one way or the other. The caller then chooses the cut-off. Here a score of 4 or more is a stumble. The forgotten beat counts at 4 or more on either sentence of a paragraph join, because readers place it on the sentence that sets something up as well as on the one that turns away.

Because a score is a share of readers, it is relative to the reader the text declares. Each text carries one reader line saying who reads it and what they have read before, and the same sentence can score differently for a different reader or within a different stretch of text.

## Why rows only at 2 or more

Most sentences have no problem. Leaving them out keeps the reply short, so the caller reads the problems and not the text again, and a missing row means every score was below 2.

## Measurement apart from diagnosis

A format may add a special instruction for one criterion. Where contradiction scores 5 or more, the why must also say whether the conflict is real or only apparent. For an apparent conflict it names the wording that would stop it feeling like one. For a real conflict it says the point itself needs deciding. The score stays on what the reader feels, whatever the diagnosis. An agent that edits the text afterwards then reads a judgement to weigh, not an order to fix.

---
columns: must-not-conclude
---
{reader}

The text, each paragraph starting with its number:

{text}

Score each sentence on the offence below. A score is roughly how many intended readers in ten would meet the problem at that sentence (0 = none, 9 = nearly all).

1. Must not conclude: {must-not-conclude} Score 0 to 9 how likely the intended reader is to be led toward one of those by this sentence.

Spelling and grammar do not count.

Write a TSV and nothing else. One row per sentence where the score is 2 or more, in reading order: paragraph.sentence (e.g. 3.2), TAB, the score, TAB, why: in at most 15 words, what the reader meets at this sentence. Describe the stumble, not a way to fix it. Where the score is 4 or more, the why names what the reader concludes. Last line: END.

---
columns: grain
---
{reader}

The text, each paragraph starting with its number:

{text}

Score each sentence on the offence below. A score is roughly how many intended readers in ten would meet the problem at that sentence (0 = none, 9 = nearly all).

1. Grain: score 0 to 9 how likely the intended reader is to feel at this sentence that the document has dropped to a much finer level of detail than the rest of it keeps, and than a document of this kind from this author would carry: an incident told with its time and place, the steps of a procedure, a tool or setting named, the middle of an argument walked through, where the passages around it speak in claims, scale and results. One instance given briefly in support of a claim scores 0. A sentence that is the first of a run at the finer grain takes the score for the run.

Spelling and grammar do not count.

Write a TSV and nothing else. One row per sentence where the score is 2 or more, in reading order: paragraph.sentence (e.g. 3.2), TAB, the score, TAB, why: in at most 15 words, what the reader meets at this sentence. Describe the stumble, not a way to fix it. Last line: END.

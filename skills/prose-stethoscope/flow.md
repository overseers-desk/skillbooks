---
columns: forgotten-beat, unanchored-reference, missing-link, out-of-order, repetition, contradiction, purpose-unclear, register-shift, long-dependency
---
{reader}

The text, each paragraph starting with its number:

{text}

Score each sentence on the nine offences below. A score is roughly how many intended readers in ten would meet the problem at that sentence (0 = none, 9 = nearly all).

1. Forgotten beat: for a paragraph's last sentence, score 0 to 9 how likely the intended reader is to be left waiting for something this sentence opens which the next paragraph does not take up.
2. Unanchored reference: score 0 to 9 how likely the intended reader is to have to search at this sentence for what a word (a name, "we", "this", a term) refers to.
3. Missing link: score 0 to 9 how likely the intended reader is to have to work out alone how this sentence connects to the one before.
4. Out of order: score 0 to 9 how likely the intended reader is to be confused at this sentence because it relies on something the text only gives later.
5. Repetition: score 0 to 9 how likely the intended reader is to feel at this sentence that they are being told something they were already told.
6. Contradiction: score 0 to 9 how likely the intended reader is to feel at this sentence that it conflicts with something earlier.
7. Purpose unclear: score 0 to 9 how likely the intended reader is to have expected this sentence to deliver a point, find that it does not, and take that as a fault in the writing rather than a deliberate setup.
8. Register shift: score 0 to 9 how likely the intended reader is to be jarred by a change of voice at this sentence that the text has not prepared; a sentence that announces a story is about to start counts as preparation.
9. Long dependency: score 0 to 9 how likely the intended reader is to have to hold words in mind at this sentence because the words that belong together sit far apart.

Spelling and grammar do not count.

Write a TSV and nothing else. One row per sentence where any offence scores 2 or more, in reading order: paragraph.sentence (e.g. 3.2), TAB, the nine scores comma-separated in the order above, TAB, why: what the reader meets at this sentence, in at most 15 words except as the special instruction below requires. Describe the stumble, not a way to fix it. Last line: END.

Special instruction for the why field. Where contradiction (6) scores 5 or more, the why field must also say whether the conflict is real or only apparent, and why you think so. If it is apparent, quote the words that create it, say how they mislead, and say that the point itself holds. If it is real, name the two claims that cannot both be true. Leave any new wording to the writer. This changes the text you write, not the score: score what the reader feels, whatever your diagnosis.

---
columns: total, defensive, glib, explained-to, lowered-standing
---
The text, each paragraph starting with its number:

{text}

Score each sentence on the five offences below. A score is roughly how many readers in ten would meet the problem at that sentence (0 = none, 9 = nearly all).

1. Total: for a sentence that allows no exception (no, nobody, none, never, always, every, all, cannot, only, the one, the whole), score 0 to 9 how likely a reader is to think at once of a plain exception and doubt the sentence for it.
2. Defensive: score 0 to 9 how likely a reader is to wonder at this sentence whom it is answering, because it defends against or denies something nobody has said.
3. Glib: score 0 to 9 how likely a reader is to find this sentence glib, a confident line that sounds settled and says less than it seems to.
4. Explained to: score 0 to 9 how likely a reader is to feel talked down to at this sentence, because it tells them what any adult already knows or can see for themselves.
5. Lowered standing: score 0 to 9 how likely a reader is to take the author less seriously at this sentence because the author lowers their own standing to speak on the point.

Spelling and grammar do not count.

Write a TSV and nothing else. One row per sentence where any offence scores 2 or more, in reading order: paragraph.sentence (e.g. 3.2), TAB, the five scores comma-separated in the order above, TAB, why: what the reader meets at this sentence, in at most 15 words. Describe the stumble, not a way to fix it. Where total (1) scores 4 or more, the why names the exception the reader thinks of. Last line: END.

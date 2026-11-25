# Terms of art paraphrased for an expert reader

**The situation.** The opening of a CV for a management post, read by a technical director. A protocol the candidate designed, and another part of their technical work, both had exact names in their fields. The writer worked under a plain-words habit meant for general readers.

**What the AI wrote.** Paraphrase where the field has its term (constructed, same build, from another field): "which lets one hospital's records be read safely inside another hospital's system", where an expert would write of federated access under the source's own controls. Elsewhere, ordinary words for things the trade names.

**What the candidate said.** The candidate asked whether using only the commonest words was intentional. Expressions like that one usually have a technical equivalent, and each sentence should be checked for whether it had been dumbed down for a news reader or would be better in the right terminology. Later they asked for a round swapping every ordinary expression that has an industry equivalent.

**What it missed.**
- For an expert reader, the field's term is evidence that the writer knows the field. A paraphrase reads as an outsider explaining to an outsider. The AI conceded the plain wording was intentional, and wrong for this reader.
- A style rule is a rule about a reader, and it was applied without asking who this reader was.
- Plain words can mislead an expert. In the terms round, two plain words were read in another field's sense.

**Instances.**
- The opening's phrasing of the protocol and of two other parts of the candidate's work.
- The ordinary expressions left in the later CV, swapped at the candidate's request.

**The rule it produced.** `../hire-methodology.md`, H, **The readers' own subject and terms**: "Read what the employer has published on the matter the candidate will speak of. An expert reader expects the field's terms." E 3, **Voice**: this-guy-aint with the reader's own trade as the identity, "for a plain word where the trade has its term".

**To re-run it.** A run in progress. The tester places in a folder beside the methodology:

```
brief.md
Post: director of health-data engineering at a firm that links clinics' records (advertisement).
Reader line: the firm's chief engineer, an expert in the field (advertisement).
Candidate, spoken: "My system lets a clinic's data stay put and still be searched by the network."
Built it alone; forty clinics on it (candidate).
```

The agent receives one instruction: "Write the CV sentence on this system." The tester's key: the field's term for searching data that stays at each site is federated (federated search, query or analytics). It passes if the sentence uses that term where the plain phrase stood, and `examine.md` lists the change from the candidate's wording with its reason. A sentence that keeps "stay put" or another paraphrase in its place is a fail.

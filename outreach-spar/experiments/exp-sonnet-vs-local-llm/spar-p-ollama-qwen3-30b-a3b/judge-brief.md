# Judging the sixth version: method, fixed in advance

Written 22 September 2026 at 00:06 AEST, before the first profile from this run exists, so that the judging cannot be shaped by what the model produces.

## Packets

For each of the twelve contacts, six files: the five July versions, taken from `../2026-07-02-blind-quality-12x5/` as they are (already stripped of `profile_date:` and provenance), and this run's profile with `profile_date:` removed and any line carrying a machine path, a model name or run boilerplate removed. Each of the six is renamed to a codename drawn at random per contact from a pool of neutral Greek letters, so a codename means nothing across contacts and the July key does not carry over. The key is written to `judging/key.tsv` and read only after every verdict is in. The order in which the six are presented is rotated per contact against position bias.

## The judge

One fresh, context-free judge per contact, told nothing about engines, machines, dates, this experiment or the July study. The brief is the July brief with the count changed:

> Six research teams were each asked to produce a profile of the same person for an outreach decision. Their six documents follow, in no particular order. Rank them 1 (best) to 6 (worst) on common-sense standards: factual specificity and density, internal consistency, plausibility, coverage, and usefulness to someone deciding whether and how to approach this person. Judge from the documents alone; do no external research. Give the ranking as a list of codenames with a one-sentence reason for each placing, and name the single strongest thing about the document you ranked last.

## What is reported

Per contact, the rank of each version. Mean rank and wins per version across the twelve, beside the July table for reference, with the caveat that adding a sixth entrant re-ranks the other five, so July's numbers and these are two studies, not one. Star-rating calibration as July reported it: this run's `star_rating` against the Sonnet baseline's, per contact, with the mean signed and absolute difference. Production cost stays out of the judge's sight and is reported from `factsfed.progress` and the server's figures.

## What this measures and what it does not

The facts-fed condition measures writing and judgement over a shared, Sonnet-derived fact base; it does not measure retrieval. That is the same asymmetry the July study recorded, and it is why this arm cannot be read as "P on a local model" whole; the live P run on the horse rows, if it lands, covers the retrieval half without a control.

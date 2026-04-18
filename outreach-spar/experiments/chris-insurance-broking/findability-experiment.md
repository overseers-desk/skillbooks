# Findability probe — experimental P-phase substep

**Scope:** this campaign only. Not part of the SPAR methodology. If the experiment yields useful signal, propose promotion to `spar-P-profile.md`.

## What it tests

Whether a candidate contact is discoverable on Google **without using their name**, using only inferred keys (role + industry + geography + any topical phrase they posted about). A contact who can be re-found this way has public visibility, which correlates with willingness to engage and with warmth for outreach. A contact who cannot be re-found may still be valid — but the cue-building for approach will be harder.

The probe doubles as a diagnostic of our own search vocabulary: routine failures to re-find valid contacts suggest our 1B query matrix is narrower than the space our targets actually occupy.

## Procedure (runs at end of normal P profile work)

1. From the profile you just built, pick the 2–4 strongest non-name keys. Good keys:
   - Current role title (use the specific phrasing the contact uses, not a generic version)
   - Current company name OR a distinctive industry descriptor
   - City or region
   - A topical phrase they have posted about or been quoted on ("supply chain resilience", "parametric cover", "D&O renewal")
2. Combine 2–4 of those into a single Google query. Favour quoted phrases where the contact's exact wording is distinctive.
3. Scan the first 20 results (one result page).
4. If the contact does not appear, try ONE refinement: add a more contact-specific detail (rare venue, named event, unique role phrasing). Do not try more than two total queries — the point is to test findability, not to prove it.
5. Record outcome:

| Score | Meaning |
|-------|---------|
| 2 | Contact surfaces in the first 10 results of the initial generic query (role + industry + geography). Highly discoverable. |
| 1 | Contact surfaces only after the refined query. Searchable given partial context. |
| 0 | Contact does not surface after both queries. Low public visibility. |

6. Write a `## Findability probe` section at the bottom of the profile markdown file with three items:
   - `findability_score: <0, 1, or 2>`
   - `query_used: <the final query that surfaced them, or the last query tried if 0>`
   - `note: <one short sentence — what the result suggests about warmth or next-step cue availability>`

## Not in the roster yet

The `findability_score` column will be added to `roster.tsv` after S₁ completes. Adding it now would desynchronise the columns the in-flight S₁ subagent is writing. The P-phase writes the section to the profile markdown; a post-P₁ sweep extracts the score into the roster column.

## Known failure mode to tolerate

Some contacts have very common names and their non-name keys will surface many people named the same thing. A high score from this kind of false match is a false positive. If the probe surfaces a different person with the same role/company combo, record score 0 with note `namesake-collision — inferred keys insufficient`.

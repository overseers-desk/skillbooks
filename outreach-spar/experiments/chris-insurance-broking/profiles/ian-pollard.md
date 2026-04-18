---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Ian Pollard
  organisation: National Risk Solutions (Auckland, NZ — see note)
  role: Founder
  date_excluded: 2026-04-18
---

# Profile: Ian Pollard

## Identity reconciliation (read first)

The roster row `stem=ian-pollard` was seeded with `contact_name=Robert Dang` and `linkedin_url=https://www.linkedin.com/in/ian-pollard-5174b512/`. The LinkedIn URL resolves to **Ian Pollard** in Auckland, NZ — not Robert Dang. The adjacent row `stem=robert-dang` likewise carries a mismatched name (`Thomas Dillon`) against `linkedin_url=https://www.linkedin.com/in/robert-dang/`. Both rows look like a systematic sweep ingestion bug where contact_name and linkedin_url were shifted across rows.

This profile treats the LinkedIn URL as canonical (it is independently verifiable) and corrects `contact_name` to Ian Pollard. The displaced "Robert Dang" string is discarded; if Robert Dang is a real intended target he must be re-discovered with a verified URL.

## Prior correspondence (IMAP)

Not checked. Pre-empted by the §4.0 exclusion below — no outreach is contemplated, so warmth is moot. Defaulted to `cold` in front matter.

## Current role

**Founder**, National Risk Solutions — Auckland, Auckland, New Zealand.

LinkedIn About-section tagline associated with the company: "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model."

LinkedIn headline: "Founder, Non Exec Director, Investor, Entrepreneur and Business Strategist."

**Note on the company name collision:** the tagline is verbatim-identical to the brief Chris Graham gave for *his* National Risk Solutions Pty Ltd (Melbourne, ABN 28 673 638 929 — see `nrs-overview.md`). Either Pollard is a co-director / NZ counterpart of Chris's NRS, or there are two firms sharing a name and a tagline (unlikely by chance), or Pollard's About text was copied. Flagged for human reconciliation before any further use of this row.

## Career history

Not rendered in the dumped DOM — only the About teaser and a single experience-block stub for "National Risk Solutions" surfaced. The Experience and Education sections did not expand. A `/details/experience/` sub-fetch was not pursued because exclusion (below) made fuller research uneconomic.

## Certifications and education

- Loughborough University (degree and dates not rendered in the DOM).

## Volunteer and mentorship

Not rendered.

## What they have said publicly

No public statements were extracted. The dump returned only the About-section tagline and headline.

**Absent themes:** no LinkedIn posts, articles, comments, or external press surfaced in the single profile fetch. Not investigated further given the §4.0 exclusion.

## Who they know (connections relevant to campaign)

Not investigated. 10 shared connections with the viewer (Chris Graham's account); identities not enumerated.

## Segment fit (§4.0 structural check)

**Result: fails — exclude.**

Segment rule 5 hard-excludes "brokers, underwriters, insurer staff, loss adjusters, claims managers, insurance lawyers, actuaries, reinsurers, and competing risk consultants." The subject's own About text describes him as a "corporate insurance specialist" providing "multi-sector program advisory, complex program structuring and global insurer placement" — the exact ecosystem the campaign excludes. He is in the trade, not a buyer of it.

Even setting aside the National Risk Solutions name collision, the activity description alone disqualifies him under rule 5.

## Relevance assessment

**What they have NOT said:** nothing publicly extractable in this fetch.

**What IS relevant:** nothing to the campaign. Subject is on the supply side of the insurance/risk-advisory market, which the segment is built to exclude.

## Angles (ordered by fit)

None. Excluded contact — no angle assessment performed.

## Verification corrections

- `contact_name`: "Robert Dang" → "Ian Pollard" (LinkedIn URL is canonical; original name appears to be a sweep mis-attribution).
- `organisation`: "(unknown)" → "National Risk Solutions" (Auckland, NZ — pending reconciliation with Chris Graham's NRS).
- `role`: empty → "Founder".
- `country`: was already "NZ" — confirmed.
- `date_excluded`: empty → "2026-04-18".
- `star_rating`: was "1" → "0".
- `p_note`: appended exclusion rationale and identity-reconciliation note.

## Findability probe

- `findability_score: 1`
- `query_used: "National Risk Solutions" Auckland founder`
- `note: generic role+industry+geography query did not surface him in the first 10 results; refined query naming the firm and city did. Public visibility outside his own LinkedIn page appears low — but moot here since the contact is excluded.`

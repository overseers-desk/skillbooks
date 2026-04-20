---
profile_date: 2026-04-18
star_rating: 1
richness: limited
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Richard Moxham
  organisation: Bright Insurance Pty Ltd
  role: Founder
  date_excluded: 2026-04-18
---

# Profile: Richard Moxham

**Segment exclusion (rule 5):** Richard Moxham is the Founder of Bright Insurance Pty Ltd, an Australian insurance broking business operating as an Authorised Representative under an AFSL. The segment hard-excludes the insurance ecosystem — brokers, underwriters, insurer staff, loss adjusters, insurance lawyers, and competing risk consultants — because they are peers and competitors of National Risk Solutions, not C-suite buyers of insurance programs. This profile is retained only because the user explicitly requested the file; the roster carries `date_excluded=2026-04-18` and `star_rating=0`, and the A-phase must not consume this profile.

## Prior correspondence (IMAP)

Not checked. IMAP lookup was skipped once segment-exclusion was confirmed; warmth is irrelevant for a contact the campaign cannot approach.

## Current role

Founder, Bright Insurance Pty Ltd (Melbourne, Australia). LinkedIn headline: "De-risking High-Growth Businesses | Founder, Bright Insurance". Bright Insurance's website (brightinsurance.com.au) confirms broker positioning — AFSL-authorised, Insurance Advisernet-style AR model.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| present | Founder | Bright Insurance Pty Ltd | Insurance broker, Melbourne |

LinkedIn's lazy-loaded Experience section did not render in the `--dump-dom` snapshot; prior roles not captured. Not pursued further because the current role alone triggers segment exclusion.

## Certifications and education

- University of Wollongong (degree and dates not visible in DOM)

## Volunteer and mentorship

- None captured.

## What they have said publicly

**Absent themes:** No public statements captured. LinkedIn About section and posts did not render in the available DOM, and no further research was conducted post-exclusion.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| — | — | Not researched — segment-excluded contact. |

## Relevance assessment

**What they have NOT said:** Not assessed.

**What IS relevant:** Nothing — the contact is structurally excluded by segment rule 5. He sits on the supply side of the insurance value chain (broker competing for the same corporate clients NRS targets), not on the buyer side the segment is scoped to reach.

## Angles (ordered by fit)

None. No angle in the campaign's angle table applies to an insurance broker, because the campaign's offering *is* broking services. Any A-phase approach would be peer-to-peer or competitive, not the C-suite-buyer conversation the campaign is designed for.

## Verification corrections

- **contact_name:** Kathleen Warden → Richard Moxham. The roster row under stem `richard-moxham` carried `contact_name=Kathleen Warden`, which is not the person at the LinkedIn URL `https://www.linkedin.com/in/richard-moxham/`. Corrected via sqlite3.
- **organisation:** (unknown) → Bright Insurance Pty Ltd. Backfilled from LinkedIn headline and the company website.
- **role:** (empty) → Founder. Backfilled from LinkedIn headline.
- **industry:** unknown → insurance.
- **date_excluded:** set to 2026-04-18 with reason recorded in `p_note` (segment rule 5 — insurance/broker ecosystem).
- **star_rating (roster TSV):** 0.

## Findability probe

- findability_score: 0
- query_used: `"Bright Insurance" founder Melbourne broker`
- note: Not executed — segment-excluded contact; findability is moot when the campaign cannot approach. Recorded as 0 for schema completeness only.

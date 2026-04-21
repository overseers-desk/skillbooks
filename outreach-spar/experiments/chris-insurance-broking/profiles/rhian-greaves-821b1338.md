---
profile_date: 2026-04-18
star_rating: 0
yield: 0
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Rhian Greaves
  organisation: McLardy McShane Yarra Valley
  role: Principal / Branch owner (insurance broker)
  date_excluded: '2026-04-18'
---

# Profile: Rhian Greaves

**Status:** EXCLUDED at SPAR-P §4.0 — structural fit check failed. This file is written because the operator requested a profile artefact for the roster row; per SPAR-P §5.4 an excluded contact normally has no profile. Do not pass this contact to the A phase. The authoritative record is the roster's `date_excluded=2026-04-18` and `star_rating=0`.

## Exclusion rationale

The LinkedIn URL in the roster (`https://www.linkedin.com/in/rhian-greaves-821b1338/`) resolves to **Rhian Greaves, McLardy McShane Yarra Valley** — a general insurance brokerage branch in the Yarra Valley, Victoria, Australia. Confirmed via:

- LinkedIn public indexing: "Rhian Greaves - McLardy McShane Yarra Valley" (au.linkedin.com/in/rhian-greaves-821b1338).
- Insurance Business Australia trade-press coverage of McLardy McShane's Yarra Valley JV expansion, naming Rhian Greaves as the incoming branch lead with a prior career at Marsh.

Segment rule 5 (`/home/weiwu/code/aesop/chris-insurance-broking/segment.yaml`) hard-excludes contacts whose current employer is in insurance, and names broker brand families including **Marsh** (prior role) explicitly. McLardy McShane is a general-insurance-broker network operating under its own AFSL / AR arrangements — the same category.

The roster fields `organisation=(unknown)`, `role=CFO`, `industry=manufacturing`, `country=NZ` were v2-matrix false positives: the LinkedIn search query (`CFO manufacturing geo:NZ`) admitted a profile whose actual attributes do not match any of those tags. The stem and LinkedIn URL are preserved so re-discovery under a future sweep is suppressed by the existing `date_excluded`.

## Prior correspondence (IMAP)

Not searched — contact is excluded at §4.0 before §4.4 runs.

## Current role

Principal / branch lead of **McLardy McShane Yarra Valley** (insurance brokerage). Not CFO, not a NZ resident, not in manufacturing.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Principal, Yarra Valley branch | McLardy McShane | Insurance broker — segment rule 5 hard-exclude |
| prior (~9 years) | AR / company director | Marsh | Marsh is named in segment.yaml rule 5 as a hard-exclude broker |
| earlier | — | — | Not researched; contact excluded |

## Certifications and education

Not researched.

## Volunteer and mentorship

Not researched.

## What they have said publicly

Not researched beyond confirming identity.

**Absent themes:** not applicable — contact is excluded.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| — | — | Not researched — contact is excluded |

## Relevance assessment

**What they have NOT said:** not applicable.

**What IS relevant:** nothing. The contact is on the broker side of the insurance industry — a parallel population, not a prospect for Chris Graham's broking practice.

## Angles (ordered by fit)

None. Contact is excluded by segment rule 5.

## Verification corrections

- `organisation` — roster held `(unknown)`; actual is `McLardy McShane Yarra Valley`. Not written to roster because the row is excluded; correcting the org field on an excluded row invites re-validation. The exclusion reason in `p_note` names the true employer for audit.
- `role` — roster held `CFO`; actual is broker principal. Same treatment.
- `country` — roster held `NZ`; actual is Australia (Victoria). Same treatment.
- `industry` — roster held `manufacturing`; actual is insurance. Same treatment.
- `linkedin_url` — confirmed accurate (this is what surfaced the mismatch).
- `email`, `facebook_url`, `phone` — not researched; contact excluded before §4.4a.

## Findability probe

- findability_score: 2
- query_used: `"Rhian Greaves" "McLardy McShane"`
- note: The person is highly findable under her true role/employer; the finding is what triggered the §4.0 exclusion, so high findability here is an indictment of the v2-matrix query vocabulary, not a warmth signal for this campaign.

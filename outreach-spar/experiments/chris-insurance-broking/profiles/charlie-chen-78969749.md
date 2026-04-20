---
profile_date: 2026-04-18
star_rating: 0
richness: limited
richness_count: 2
warmth_finding: existing
applicable_angles: []
dependent_data:
  contact_name: Charlie Chen
  organisation: National Risk Solutions
  role: CFO
  date_excluded: 2026-04-18
---

# Profile: Charlie Chen

**Exclusion note:** Per SPAR-P §5.4 this contact would not normally receive a profile document (structural exclusion, `date_excluded` set). File written at explicit operator request; `star_rating: 0` is retained in the front matter to reflect the §4.9 assessment even though §5.1 states 0 should not appear there.

## Prior correspondence (IMAP)

Not searched — Charlie Chen is an internal colleague at the sending organisation (National Risk Solutions). Any correspondence in the director mailbox would be internal operational traffic, not outreach warmth. Treated as `warmth_finding: existing` by definition of shared employer.

## Current role

CFO, National Risk Solutions. Location: The Rocks, New South Wales, Australia. LinkedIn headline carries the NRS marketing tagline verbatim: "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model."

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CFO | National Risk Solutions | Only role hydrated in the LinkedIn DOM snapshot |

LinkedIn Experience and Education sections did not hydrate in the fetched DOM (top-card only). Not pursued further — the structural exclusion makes a full career reconstruction unnecessary.

## Certifications and education

- Not extracted (DOM limitation, see above).

## Volunteer and mentorship

- None extracted.

## What they have said publicly

**Absent themes:** No public statements extracted. The visible headline is a firm-level marketing line, not a personal statement. Nothing surfaced on insurance renewals, claims handling, D&O, cyber, or any of the segment's rule-4 topics as a personal voice.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| Chris Graham | Colleague / Director at NRS | Same firm — this contact is internal to the campaign sender, not a prospect |

## Relevance assessment

**What they have NOT said:** Nothing personal on the segment's topics; headline is shared firm messaging.

**What IS relevant:** Nothing — the contact sits inside the selling organisation. Structural mismatch, not a relevance-weakness case.

## Angles (ordered by fit)

No angles applicable. The campaign targets external ANZ C-suite buyers of corporate insurance programs; Charlie Chen is CFO of the broker doing the selling.

## Verification corrections

- `organisation` backfilled on roster: `(unknown)` → `National Risk Solutions`.
- `industry` corrected on roster: `manufacturing` → `insurance`.
- `date_excluded` set to 2026-04-18 with reason recorded in `p_note`.
- `star_rating` set to 0.

**Basis for exclusion:**

1. §4.0 structural mismatch — the segment seeks external ANZ buyers of corporate insurance programs. An internal CFO of the selling firm cannot deliver the segment's outcome through its mechanism.
2. Segment `discovery_criteria` rule 5 — National Risk Solutions operates as a corporate insurance broker (licensed AR under Insurance Advisernet AFSL 240549), placing it in the insurance-ecosystem hard-exclude category.

The original v2-matrix sweep query (`CFO manufacturing geo:AU`) surfaced this row because the roster entry had `organisation=(unknown)` and `industry=manufacturing` — neither of which held up against the LinkedIn headline. This is a sweep-stage false positive that P resolves by exclusion.

## Findability probe

- **findability_score:** 0
- **query_used:** `"CFO" "National Risk Solutions" Sydney` (hypothetical — not executed; see note)
- **note:** Probe not meaningful for an internal colleague of the sender. Structural exclusion makes public discoverability irrelevant to outreach cue-building for this campaign. Recorded as 0 to avoid false-positive signal.

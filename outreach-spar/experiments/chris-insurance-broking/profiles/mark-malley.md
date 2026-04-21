---
profile_date: 2026-04-18
star_rating: 0
yield: 0
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Laura Stonehouse
  organisation: (unknown)
  role: (unknown)
  date_excluded: 2026-04-18
---

# Profile: mark-malley (malformed roster row — no individual)

This profile documents a data-integrity finding. Per SPAR-P §5.4 an excluded contact normally has no profile; this file exists because it was explicitly requested. It should not be consumed by the A phase.

## Prior correspondence (IMAP)

Not checked — no valid target to search for.

## Current role

None. The roster row with `stem=mark-malley` does not correspond to a real individual:

- `contact_name` is "Laura Stonehouse" — a data leak from the separate, legitimate `laurastonehouse` row (Laura Stonehouse, CFO, Trust Tairāwhiti, NZ; LinkedIn https://www.linkedin.com/in/laurastonehouse/).
- `linkedin_url` is https://www.linkedin.com/in/mark-o-malley-23698b89/ — which, per prior verification recorded in the `andrew-donaldson` row, resolves to Andrew Donaldson, CFO at FirstCape (NZ wealth-advisory / financial-services group formed from JBWere NZ + Jarden Wealth + Harbour Asset Management).
- `organisation`, `role`, `email`, `phone` are blank.

The two identifying fields point to two different people, neither of whom belongs to this row.

## Career history

Not applicable.

## Certifications and education

Not applicable.

## Volunteer and mentorship

Not applicable.

## What they have said publicly

Not applicable — no individual to attribute statements to.

**Absent themes:** n/a.

## Who they know (connections relevant to campaign)

Not applicable.

## Relevance assessment

**What they have NOT said:** n/a.

**What IS relevant:** nothing. The row has no valid referent.

## Angles (ordered by fit)

None. No individual to approach.

## Verification corrections

- Row excluded: `date_excluded=2026-04-18`, `star_rating=0`, reason recorded in `p_note` — "malformed duplicate row. LinkedIn URL mark-o-malley-23698b89 resolves to Andrew Donaldson (CFO FirstCape, NZ), already captured in andrew-donaldson row and excluded under rule 5 (financial services). contact_name 'Laura Stonehouse' is a data leak from the laurastonehouse row (distinct LinkedIn). No distinct individual corresponds to this stem."
- Legitimate Laura Stonehouse entry is preserved at `stem=laurastonehouse` with her correct LinkedIn URL.
- Andrew Donaldson entry at `stem=andrew-donaldson` already carries the correct resolution for the `mark-o-malley-23698b89` LinkedIn URL and is excluded under segment rule 5.

## Findability probe

- findability_score: 0
- query_used: n/a — no valid individual to probe
- note: Row is a malformed duplicate; the two identifying fields point to two different people already accounted for elsewhere in the roster. Findability is undefined.

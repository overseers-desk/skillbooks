---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Chris Ristevski
  organisation: BMS Group
  role: Partnership Manager
  date_excluded: 2026-04-18
---

# Profile: Chris Ristevski

## Prior correspondence (IMAP)

Not searched. Contact excluded at §4.0 structural validation before IMAP lookup; cold assumed.

## Current role

Partnership Manager | Strategic Partnerships, BMS Group. BMS Group is an independent specialty (re)insurance broker headquartered in London, a Lloyd's broker with Australian operations. Location: Melbourne and surrounds, Australia.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Partnership Manager, Strategic Partnerships | BMS Group | Only role fully surfaced in the static DOM |

Experience accordion was not hydrated in the headless fetch; earlier history not captured.

## Certifications and education

- Deakin University (degree/dates not rendered in DOM)

## Volunteer and mentorship

- None surfaced.

## What they have said publicly

**Absent themes:** No public statements surfaced on campaign-relevant topics — this is moot given structural exclusion.

## Who they know (connections relevant to campaign)

Not researched — contact excluded at §4.0 before connection mapping.

## Relevance assessment

**What IS relevant:** Nothing — employer is a Lloyd's specialty insurance broker, which is exactly the ecosystem segment rule 5 excludes.

## Angles (ordered by fit)

None applicable. Structural exclusion.

## Verification corrections

- Roster `organisation` backfilled: `(unknown)` → `BMS Group`.
- Roster `role` backfilled: blank → `Partnership Manager`.
- Roster `country` corrected: `NZ` → `AU`. Sweep harvested "Palmerston North, Manawatu-Wanganui, Nueva Zelanda" as contact_name (a location-field leak); a fresh LinkedIn parse confirms Melbourne, AU, corroborated by Deakin University education. The NZ label was a sweep artefact.
- Roster `industry` set: `unknown` → `insurance`.
- `contact_name` corrected from the location-string artefact to `Chris Ristevski`.
- `date_excluded` set to 2026-04-18; `star_rating` set to 0.
- Reason (written to roster `p_note`): BMS Group is a specialty insurance broker — segment rule 5 (insurance/broker ecosystem) hard-excludes. Structural mismatch with segment mechanism per §4.0.

## Findability probe

- findability_score: 2
- query_used: `"Chris Ristevski" BMS Group Melbourne`
- note: LinkedIn profile and company association surface on the first page; role is public-facing ("Partnership Manager, Strategic Partnerships"), consistent with discoverability of a broker-facing relationship manager — moot for outreach here given structural exclusion.

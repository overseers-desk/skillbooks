---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Mitchell Easton
  organisation: Pinnacle Resources
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Mitchell Easton

## Exclusion summary

Two compounding mismatches:

1. **Person-vs-company (§4.11).** The roster placed Mitchell Easton at Mills-Tui (NZ heavy-vehicle manufacturer). LinkedIn (`/in/mitchelleaston/`) and the Pinnacle Resources contact page both confirm his current role is Managing Director at Pinnacle Resources, not Mills-Tui. Mills-Tui's actual MD is Dean Purves, who bought the business in 2018 (NZ Trucking, TRANSPORTtalk). Cross-reference (§4.7a): Dean Purves is already in the roster as `dean-purves-0a303b22` with a profile (rated 3 stars, organisation correctly recorded as Mills-Tui Ltd) — independently discovered via the same v2-matrix sweep. No new row needed.
2. **Segment rule 3 (§4.0).** At Pinnacle Resources, Mitchell sits in construction services — "procurement and installation of quality construction products" for vertical construction (apartments, hotels) across NZ and the Pacific. Construction is not in the segment's seven verticals (manufacturing, transportation/logistics, sports, tourism, hospitality/leisure, retail, wholesale). This matches the precedent set for `jatin-rangras` (Delta Group, demolition/construction).

Either failure alone would trigger exclusion; together they make the assessment unambiguous.

## Prior correspondence (IMAP)

Searched director-rivermill-au and admin-rivermill-au for "easton" and "pinnacleresources". Only matches were unrelated bookings from a customer named Carly Easton (Rivermill venue, Jan 2026). No prior contact with Mitchell Easton or Pinnacle Resources. Cold.

## Current role

Managing Director, Pinnacle Resources (Palmerston North, NZ — registered postal address PO Box 4130, Manawatu Mail Centre, Palmerston North 4442). Self-described as "first port of call for sales and marketing" on the company contact page. Pinnacle Resources is a small / "boutique" team accredited with Site Safe NZ and Site Wise; brother (or other relative) Cameron Easton is General Manager / Director, and Amanda Easton runs the office — a family-run business.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Managing Director | Pinnacle Resources | NZ construction-products procurement & installation (structural steel, composite flooring, precast concrete, base isolators) |
| prior (per LinkedIn meta — exact dates not retrievable) | Senior management | RCR, Brightwater, HELiPRO | Industrial / engineering; sales, marketing, business development, service |

LinkedIn experience and education detail did not render in the static `--dump-dom` capture (the activity module emitted "Error al cargar las publicaciones"); only the header card and a single LinkedIn-meta line about prior employers were extractable. Not pursued further because §4.0/§4.11 exclusion was already established.

## Certifications and education

Not retrievable from the LinkedIn dump. Not pursued — excluded contact.

## Volunteer and mentorship

Not assessed (excluded contact).

## What they have said publicly

No public statements were extracted. The LinkedIn activity module failed to hydrate; web search returned only directory entries and the company website. No conference talks, posts, or media quotes surfaced.

**Absent themes:** all campaign-relevant themes (insurance program buying, broker selection, renewal, claims, D&O, cyber, business interruption, supply chain risk).

## Who they know (connections relevant to campaign)

Not catalogued (excluded contact). The only named connection of note is Cameron Easton (General Manager / Director at Pinnacle Resources), apparent family-business co-leader — also outside segment verticals.

## Relevance assessment

**What they have NOT said:** nothing relevant surfaced.

**What IS relevant:** nothing for this campaign. Mitchell is a small-business MD in a vertical the segment explicitly does not target. Even setting aside the person-vs-company misattribution, the construction-sector exclusion stands.

## Angles (ordered by fit)

None. Compound exclusion under §4.0 (segment rule 3, vertical mismatch) and §4.11 (person-vs-company: target was the role at Mills-Tui, currently held by Dean Purves).

## Verification corrections

- `organisation`: roster held "Mills-Tui" → corrected to "Pinnacle Resources" (Mitchell's actual current employer per LinkedIn and pinnacleresources.co.nz/contact). The Mills-Tui association in the roster appears to be a stale-LinkedIn discovery artefact from `discovered_via=v2-matrix`.
- `role`: confirmed "Managing Director" (was already correct).
- `industry`: roster held "manufacturing" → corrected to "construction" (Pinnacle Resources' actual sector).
- `email`: roster blank → backfilled `mitchell.easton@pinnacleresources.co.nz` (verified on Pinnacle Resources contact page; unique to him, not a shared inbox).
- `phone`: roster blank → backfilled `+64 27 2299139` (mobile, listed under Mitchell on Pinnacle Resources contact page).
- `linkedin_url`: confirmed `https://www.linkedin.com/in/mitchelleaston/` (already in roster).
- `facebook_url`: not searched (excluded contact; Pinnacle Resources has a company Facebook page but no personal handle was the goal of search).
- `star_rating`: set to 0 per §4.9.
- `date_excluded`: set to 2026-04-18 with reason recorded in `p_note`.
- **No new roster row added for Dean Purves:** §4.7a grep found him already at `dean-purves-0a303b22` with a complete profile (rated 3 stars, organisation Mills-Tui Ltd, MD, manufacturing/NZ) from an earlier v2-matrix sweep on the same day. Mitchell's exclusion does not change Dean's record. A duplicate row briefly created during this run was reverted.

## Findability probe

- `findability_score: 2`
- `query_used: "Pinnacle Resources" managing director Palmerston North`
- `note: Pinnacle Resources publishes a named team page with Mitchell as MD; he surfaces trivially via company + role + city. High public visibility — though irrelevant to this campaign because he is excluded on vertical grounds.`

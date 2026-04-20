---
profile_date: 2026-04-18
star_rating: 0
richness: limited
richness_count: 1
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Ben McMullan
  organisation: Jenkin Beattie
  role: Associate Director
  date_excluded: 2026-04-18
---

# Profile: Ben McMullan

## Prior correspondence (IMAP)

Not checked — contact excluded at §4.0 structural validation before IMAP step. No prior correspondence assumed.

## Current role

**Associate Director, Jenkin Beattie** (Sydney, New South Wales, Australia).

Headline: "Associate Director - Building GTM tech sales teams | Executive Leadership & IT Sales Recruitment | 0401 512 254 | 12+ years recruitment experience". Jenkin Beattie is a tech-sales / GTM executive recruitment firm. The headline declares 12+ years in recruitment.

Direct phone in headline: 0401 512 254.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Associate Director | Jenkin Beattie | GTM / tech sales recruitment, Sydney |

Full career history not retrievable — LinkedIn SSR delivered only the top intro card; Experience/Education/Activity panels were not hydrated in the `--dump-dom` capture.

## Certifications and education

- Northumbria University (institution visible in the profile header chip; degree and dates not exposed in the fetched DOM).

## Volunteer and mentorship

Not retrievable from the fetched DOM.

## What they have said publicly

**Absent themes:** no mention of insurance, risk, renewal, claim, D&O, cyber policy, business interruption, policy wording, or broker anywhere in the fetched content. No public posts surfaced. Activity container was present but empty in the SSR render.

## Who they know (connections relevant to campaign)

21 shared connections with the Chris Graham / National Risk Solutions network (visible in the "people in common" indicator). No named bridges identifiable from the fetched DOM. Specific names would require an authenticated panel fetch the current plumbing did not deliver.

## Relevance assessment

**What they have NOT said:** nothing on the campaign's technical themes (insurance, risk, corporate insurance program, any of the seven target verticals).

**What IS relevant:** nothing structural. Recruitment is adjacent to professional services but is not one of the seven qualifying industries (manufacturing, transport/logistics, sports, tourism, hospitality/leisure, retail, wholesale). The role ("Associate Director") is not in the segment's role whitelist (CEO/CFO/CIO/Owner/Founder/Managing Director).

## Angles (ordered by fit)

None applicable. Contact excluded at §4.0 structural check.

## Verification corrections

Roster entry was corrupted at sweep time — `contact_name` read "Actual: Managing Director and" (a malformed parse artifact), `organisation` was "(unknown)", `role` was empty. Corrected from LinkedIn intro card:

- `contact_name`: "Actual: Managing Director and" → "Ben McMullan"
- `organisation`: "(unknown)" → "Jenkin Beattie"
- `role`: "" → "Associate Director"
- `phone`: "" → "0401512254" (self-declared in headline)
- `industry`: "unknown" → "recruitment"
- `country`: "NZ" → "AU" (LinkedIn location: Sydney NSW; the NZ tag from sweep was wrong)
- `star_rating`: 1 → 0
- `date_excluded`: "" → "2026-04-18" (structural: fails segment rules 2 and 3)
- `p_note`: populated with exclusion reason.

## Findability probe

- **findability_score:** 0
- **query_used:** `"Associate Director" "Jenkin Beattie" Sydney recruitment`
- **note:** not run end-to-end — contact is outside segment scope, so findability from campaign-relevant inferred keys (C-suite + seven industries + insurance terms) is structurally 0 because none of those keys apply to him. A namesake / role-based probe would surface the Jenkin Beattie profile, but that is not the findability this campaign measures.

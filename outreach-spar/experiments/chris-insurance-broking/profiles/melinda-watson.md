---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Melinda Watson
  organisation: St Luke's Grammar School
  role: CFO
  date_excluded: 2026-04-18
---

# Profile: Melinda Watson

**Note on this file.** Per SPAR-P §5.4 excluded contacts (date_excluded set, star_rating 0) do not normally receive a profile — the roster entry is the permanent record. This document was produced on explicit user override after exclusion was decided. It exists so the identity correction is traceable in the profiles directory alongside the roster update.

## Identity correction

The roster row `melinda-watson` originally carried `contact_name = "Vickie Robinson"` against the LinkedIn URL `https://www.linkedin.com/in/melinda-watson-50259759/`. Fetching that URL resolves to **Melinda Watson** — confirmed by the profile card, page title, and LinkedIn's internal JSON (`"firstName":"Melinda","lastName":"Watson","isVanityNameResolved":true`). The "Vickie Robinson" attribution was a sweep-stage error. Roster row updated in this P run (see Verification corrections).

## Prior correspondence (IMAP)

Not searched. Contact was excluded at §4.0 on structural grounds (employer sector outside segment scope); IMAP warmth is moot for an excluded contact.

## Current role

**CFO**, Australian Mentoring Services and St Luke's Grammar School. Location: Australia (LinkedIn location field). St Luke's Grammar is an independent Anglican K–12 school in Dee Why, NSW. Australian Mentoring Services appears alongside the school in Melinda's employer cluster on the LinkedIn top card — likely a related or parallel engagement rather than a second primary employer.

Profile visibility is 2nd-degree from Chris Graham's session; the full experience and education sections did not render in the DOM and were not click-through-fetched, because the §4.0 structural check resolved on the top-card data alone.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CFO | St Luke's Grammar School / Australian Mentoring Services | Only role visible on the top card; prior history not fetched |

## Certifications and education

Not fetched — §4.0 exclusion resolved before full-profile retrieval.

## Volunteer and mentorship

Not fetched — as above.

## What they have said publicly

No public statements retrieved. No LinkedIn post content was parsed because the top-card fetch was sufficient to resolve §4.0.

**Absent themes:** insurance, risk, renewal, claim, broker, D&O, cyber policy, business interruption, policy wording — none surfaced in the parsed top card. Keyword hits for "insurance", "risk", "CEO", "founder", "manufacturing" in the raw DOM all resolved to the logged-in user's nav menu or the "People Also Viewed" sidebar (Chris Graham / NRS / adjacent profiles), not to Melinda's own content.

## Who they know (connections relevant to campaign)

2nd-degree from Chris Graham with visible mutuals "Scott, George, and 4 more" on the top card. Not enumerated further — not pursued on an excluded contact.

## Relevance assessment

**What they have NOT said:** anything surfaced in this fetch. No campaign-relevant topical signal on the top card.

**What IS relevant:** Melinda holds a CFO title (segment rule 2 pass) and is Australia-resident (rule 1 pass). She fails segment rule 3: St Luke's Grammar is an independent school (education); Australian Mentoring Services, whatever its exact form, is not in manufacturing, transportation/logistics, sports, tourism, hospitality/leisure, retail, or wholesale. Rule 4 (public signal of insurance-program engagement) was not tested because rule 3 already fails.

This is a structural §4.0 miss, not a judgement on the person. A CFO at a school does control an insurance program, but schools are not in the seven verticals the segment targets, and the segment file does not carve out an education exception.

## Angles (ordered by fit)

None. The contact is excluded; no angle applies.

## Verification corrections

- `contact_name`: "Vickie Robinson" → "Melinda Watson" (LinkedIn vanity slug resolution).
- `organisation`: "(unknown)" → "St Luke's Grammar School".
- `role`: empty → "CFO".
- `industry`: "unknown" → "education".
- `date_excluded`: empty → "2026-04-18".
- `star_rating`: empty → "0".
- `p_note`: populated with the correction + exclusion record.

Roster updated via `sqlite3 :memory:` `.mode tabs` UPDATE, flock-serialised on `roster.tsv.lock`, per the campaign's TSV-editing convention.

## Findability probe

- `findability_score`: 0
- `query_used`: `"CFO" "St Luke's Grammar" Australia` (initial) → `"Melinda Watson" CFO "St Luke's Grammar"` (refined, still declining to execute since contact is excluded)
- `note`: Not executed — probe has no campaign utility on an excluded contact; recording 0 by convention so the post-P₁ sweep extracting scores into the roster sees a defined value.

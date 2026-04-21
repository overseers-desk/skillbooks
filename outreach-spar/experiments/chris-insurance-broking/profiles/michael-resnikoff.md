---
profile_date: 2026-04-18
star_rating: 0
yield: 1
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Michael Resnikoff
  organisation: Markel International
  role: Global Trading Executive
  date_excluded: 2026-04-18
---

# Profile: Michael Resnikoff

## Structural exclusion

This contact fails two SPAR discovery rules and is excluded from the campaign (`date_excluded: 2026-04-18`, `star_rating: 0`). The profile is recorded here for traceability; it is not consumed by the A phase.

- **Rule 5 (employer industry):** Current employer Markel International is a Lloyd's-market specialty insurer — inside the insurance ecosystem the segment hard-excludes.
- **Rule 2 (role title):** Headline is "Global Trading Executive", not CEO/CFO/CIO/Owner/Founder/Managing Director. In specialty-insurance usage, "trading" refers to underwriting/broker relationship management, not C-suite authority over a buyer's insurance program.

## Prior correspondence (IMAP)

Not checked — exclusion decided on structural grounds before IMAP research. Warmth recorded as `cold` by default.

## Current role

Global Trading Executive, Markel International. Location: Homebush, New South Wales, Australia.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Global Trading Executive | Markel International | From LinkedIn header pill only; Experience section did not render in headless fetch |

Lazy-loaded sections (Experience, About, Education history) did not hydrate in the `--dump-dom` capture. Not pursued further: the header alone satisfies both exclusion rules, so extra fetches would not change the outcome.

## Certifications and education

- Deakin University (institution pill only; degree and dates did not render). MBA suffix in the LinkedIn vanity URL implies an MBA.

## Volunteer and mentorship

Not captured — section did not render and is not needed for the exclusion decision.

## What they have said publicly

No public statements captured.

**Absent themes:** all campaign themes — nothing on insurance buying, renewal, D&O, cyber, business interruption, broker selection, or risk governance from the buyer side (and would not be expected given the sell-side role).

## Who they know (connections relevant to campaign)

Not mapped. 2nd-degree to Chris Graham with 44 mutual connections, which is consistent with Chris's specialty-insurance placement network — but these mutuals are the insurer/broker ecosystem the campaign excludes, not the corporate-buyer population it targets.

## Relevance assessment

**What they have NOT said:** nothing relevant captured.

**What IS relevant:** nothing — the exclusion is structural. Michael sits on the underwriting/insurer side of the market; the campaign targets the corporate-buyer side.

## Angles (ordered by fit)

None applicable. Contact excluded.

## Verification corrections

Roster corrections written during this run:

- `contact_name`: "Actual: Chief Executive Officer en Network" (sweep parse artefact) → "Michael Resnikoff"
- `organisation`: "(unknown)" → "Markel International"
- `role`: empty → "Global Trading Executive"
- `industry`: "unknown" → "insurance"
- `date_excluded`: empty → 2026-04-18
- `star_rating`: empty → 0
- `p_note`: updated with exclusion reason

## Findability probe

- `findability_score: 0`
- `query_used: "Global Trading Executive" "Markel International" Sydney`
- `note: Not run in earnest — contact is excluded, so the probe's premise (warmth/cue availability for outreach) does not apply; score recorded as 0 by convention.`

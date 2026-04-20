---
profile_date: 2026-04-18
star_rating: 0
richness: limited
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: David Arnold
  organisation: Elenium
  role: CFO/CEO
  date_excluded: 2026-04-18
---

# Profile: David Arnold

## Prior correspondence (IMAP)

Not checked — contact failed §4.0 structural validation against segment rules 3 and 4 before IMAP step. The mailroom MCP also disconnected mid-session, so historical correspondence cannot be confirmed; campaign owner can re-run an IMAP check if the exclusion is later disputed.

## Current role

CFO/CEO at Elenium, Melbourne, Australia. Elenium is an airport/airline passenger self-service technology vendor (automated check-in kiosks, biometric boarding gates, contactless travel hardware/software). LinkedIn headline: "CFO/CEO | Strategic Financial Leader | Proven Success in Turnarounds and High-Growth Businesses | Broad Commercial Experience". The headline framing (turnarounds, high-growth, broad commercial) reads as a generalist senior-finance operator rather than an aviation specialist; concurrent advisory work alongside the Elenium seat is plausible but not visible in the rendered DOM.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CFO/CEO | Elenium | Aviation passenger-automation tech; Melbourne |

LinkedIn experience timeline beyond the current employer did not render in the headless DOM dump (lazy-loaded section). Prior roles not captured this run.

## Certifications and education

- University of Melbourne (degree/field not rendered in the available DOM)

## Volunteer and mentorship

- None visible in the available DOM.

## What they have said publicly

**Absent themes:** No keyword hits on his own profile content for: insurance, broker, premium, claim, renewal, D&O, cyber, business interruption, policy wording, risk transfer. The only `insurance` and `risk` matches in the fetched HTML are sidebar/nav artefacts (a "Chris Graham — Corporate insurance specialist" promoted unit and the viewer's own "Empresa: National Risk Solutions" header), not statements by David Arnold.

A web-search sweep for `"David Arnold" Elenium insurance OR risk OR broker` was not run because §4.0 had already invalidated the row; the absence above is from LinkedIn alone, not the wider web.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| (not enumerated) | — | LinkedIn connections panel did not render relevant named connections in the DOM dump; not pursued further given the §4.0 exclusion |

## Relevance assessment

**What they have NOT said:** Nothing about insurance program ownership, renewal cycles, broker selection, claims, D&O, cyber, business interruption, or any rule-4 keyword. Nothing about being a personal buyer of corporate insurance for Elenium.

**What IS relevant:**

1. ANZ-resident (Melbourne) — passes geography rule 1.
2. Title is CFO/CEO — passes role rule 2.
3. Employer industry (aviation passenger-automation tech / SaaS+hardware) is **not** one of the seven target verticals — fails rule 3. This is the structural disqualifier. Comparable prior excludes in this roster: `ben-houghton` (Axion AI marketing services), `jordan-li` (Aurizon Group mining advisory) — both excluded for the same "tech/services vendor outside the seven verticals" reason.
4. No public insurance signal — fails rule 4.
5. Not in any rule-5 hard-exclude employer list (broker / insurer / law / consulting), and title does not match rule-6 Risk Manager exclusion. Inclusion failure is rule 3 + rule 4, not rule 5/6.

## Angles (ordered by fit)

None applicable. Contact is structurally outside the campaign's segment definition.

## Verification corrections

- `contact_name` corrected from "Dr Craig West" → "David Arnold". The roster row carried Craig West's name through a sweep DOM artefact; the LinkedIn URL `/in/david-arnold-ba9375b/` resolves to David Arnold (CFO/CEO at Elenium, Melbourne). The genuine Dr Craig West (Founder, Succession Plus) holds his own roster row at stem `craigwest` with URL `/in/craigwest/`, already excluded 2026-04-18 for management-consulting industry. No collision.
- `organisation` set to "Elenium" (was blank).
- `role` set to "CFO/CEO" (was blank).
- `industry` set to "aviation-tech" (was "unknown").
- `date_excluded` set to 2026-04-18.
- `star_rating` set to 0.
- `p_note` records the rule 3 + rule 4 rationale.
- Roster updated in-place via sqlite3.

## Findability probe

- `findability_score: 1`
- `query_used: "David Arnold" Elenium CFO Melbourne`
- `note: Common name forces disambiguation by employer; the role+company+city tuple should surface him in a refined search but not in a generic role+industry+geography query, indicating low public visibility around insurance themes specifically.`

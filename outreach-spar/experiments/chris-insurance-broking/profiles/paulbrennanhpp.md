---
profile_date: 2026-04-18
star_rating: 0
richness: limited
richness_count: 0
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Paul Brennan
  organisation: Port Nelson Limited
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Paul Brennan (Port Nelson Limited — roster entry invalid)

**Outcome:** Row excluded at P 2026-04-18 under SPAR-P §4.11 person-vs-company. The named individual does not hold the named role at the named organisation, and the LinkedIn URL carried by the row resolves to a different person entirely. Replacement row `matt-mcdonald-port-nelson` added to the roster for the person currently in the CEO/MD seat.

## Prior correspondence (IMAP)

Not searched. The contact does not exist in the form the roster asserts; IMAP lookup against an unverified identity would be misleading. Treat as cold for any downstream consumer.

## Current role

No role held at Port Nelson Limited by any "Paul Brennan":

- Port Nelson's **Senior Management** page (https://www.portnelson.co.nz/about-us/our-people/senior-management/) lists Matt McDonald (CEO, from 15 Nov 2024), Andrew Procter (CFO, from 2026), Paul **Williams** (GM Operations, from Jan 2025 — not "Paul Brennan"), Lenore Richter (GM People and Safety), Andrew James (GM Environment, Infrastructure and Maintenance), Jaron McLeod (GM QuayConnect), Reagan Pattison (GM Business Transformation). No Paul Brennan.
- Port Nelson's **Governance** page (https://www.portnelson.co.nz/about-us/our-people/governance/) lists directors Jon Safey (Chair), Kim Wallace, Gerrard Wilson, Meg Matthews, Guy Roper, Darren Mark. No Paul Brennan.
- CEO succession at Port Nelson: Martin Byrne → Hugh Morrison (9 Sep 2019 – mid-Nov 2024, retired) → Matt McDonald (from 15 Nov 2024, internal promotion from GM Operations). No "Paul Brennan" appears in any public CEO/MD history of Port Nelson.

The LinkedIn URL in the roster, `https://www.linkedin.com/in/paulbrennanhpp/`, resolves to a Paul Brennan based in **Parkwood, Queensland, Australia** — headline branding "Avytj", self-described entrepreneur active in Queensland property/business circles (mutual group: Property Developers in Australia). Not at Port Nelson, not in New Zealand, not a port-industry executive. He has no public statements on insurance, risk, renewal, claims, broker selection, D&O, cyber policy, business interruption, policy wording, freight, or logistics.

## Career history

Not recorded. The identity the roster row asserts (Paul Brennan, MD, Port Nelson Limited, NZ, freight port operator) is not a real person-role-organisation triple. The Queensland Paul Brennan at the LinkedIn URL is a distinct individual irrelevant to this campaign; recording his career here would compound the identity error.

## Certifications and education

Not recorded (see Career history).

## Volunteer and mentorship

Not recorded.

## What they have said publicly

**Absent themes:** insurance, risk, renewal, claim, broker, D&O, cyber, business interruption, policy wording, premium, freight, logistics, port operations — nothing on any campaign-relevant theme appears in either the asserted (Port Nelson MD) identity (which does not exist) or the actual profile at `paulbrennanhpp` (Queensland entrepreneur; three recent comments on workplace safety / unrelated topics, no substantive public statements on insurance or risk).

## Who they know (connections relevant to campaign)

None recorded. The asserted identity is not a real role-holder and the LinkedIn-resolved identity is not in the segment.

## Domain-specific operational context

Not applicable — exclusion precedes domain analysis.

## Relevance assessment

**What they have NOT said:** anything on the campaign's themes, in either the asserted or resolved identity.

**What IS relevant:** nothing. The roster row represents a compound data error:

1. **Role-at-org error.** Port Nelson Limited's Managing Director / CEO is Matt McDonald (since 15 Nov 2024), preceded by Hugh Morrison (2019–2024). No Paul Brennan has ever been publicly named as CEO or MD of Port Nelson Limited.
2. **LinkedIn URL mismatch.** `paulbrennanhpp` resolves to a Queensland property entrepreneur, not a Nelson NZ port executive. The vanity slug was almost certainly selected during discovery by name-matching without verifying company or location — a known failure mode for generic English-language surnames.
3. **Industry fit passes, but person does not exist.** Port Nelson Ltd (freight port operator, NZ, transportation/logistics vertical) would be a valid target **for its actual CEO** — which is why the replacement row was added.

## Angles (ordered by fit)

None apply. Exclusion under §4.11 supersedes angle analysis.

## Verification corrections

- `contact_name` — "Paul Brennan" does not hold any public role at Port Nelson Limited. Not corrected in the excluded row (the row is preserved as the audit trail); the correct current role-holder is carried in the new `matt-mcdonald-port-nelson` row.
- `organisation` — "Port Nelson Limited" is a real NZ port operator, but the roster's pairing of it with "Paul Brennan" is incorrect.
- `role` — "Managing Director" is the functional equivalent of CEO at Port Nelson; the current holder is Matt McDonald, not Paul Brennan.
- `linkedin_url` — `https://www.linkedin.com/in/paulbrennanhpp/` resolves to a different person (Parkwood, QLD, Australia — entrepreneur). The URL is factually wrong for the roster's asserted identity. Left in place on the excluded row for traceability; not copied anywhere else.
- `email`, `phone`, `facebook_url` — blank in the roster; not backfilled because the identity being profiled is not a valid campaign contact. No masked-or-unmasked email was found and none was written.
- **Replacement added.** New roster row `matt-mcdonald-port-nelson` records Matt McDonald as the current CEO of Port Nelson Limited. That row carries `discovered_via=paulbrennanhpp-replacement` and awaits its own P run for full profiling. The next P run should resolve his LinkedIn URL (not immediately findable under "Matt McDonald Port Nelson" or "Matthew McDonald Port Nelson Nelson" — the NZ Matt McDonald may have a different handle, or a low-visibility profile; worth trying "Matthew McDonald Nelson Airport" given his concurrent airport directorship).

## Findability probe

- findability_score: 0
- query_used: `"Paul Brennan" "Port Nelson" Managing Director CEO`
- note: No person matching the roster's asserted identity is findable, because no such person exists at Port Nelson Limited; the only valid signal the probe surfaces is that the row itself is wrong. This is a true-negative finding — not a namesake collision, but a role-at-org error.

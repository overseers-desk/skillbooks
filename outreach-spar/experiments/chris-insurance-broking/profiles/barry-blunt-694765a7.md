---
profile_date: 2026-04-18
star_rating: 0
yield: 3
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Barry Blunt
  organisation: Colas Limited
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Barry Blunt

## Prior correspondence (IMAP)

Not searched — NRS / Chris Graham mailboxes are not indexed locally. Treated as cold.

## Current role

Managing Director, Colas Limited (NZ), Auckland. Colas NZ is a road construction / asphalt / bituminous surfacing contractor (SAMI products, pavement and road surfacing); part of the global Colas Group (French civil-engineering major). Appointed MD in May 2023 following Colas's full acquisition of ASCO Asphalt. Website: colas.co.nz (formerly ascoltd.co.nz).

The sweep attached this person to "Myriad Engineering Ltd" (Lower Hutt). That is an unrelated CNC machining / MIG-TIG welding shop owned by Jayden and Ashley Jessup — different city, different industry, no connection to Barry Blunt in any public source. Corrected to Colas Limited (see Verification corrections).

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| May 2023–present | Managing Director | Colas Limited (NZ) | Auckland; road surfacing / asphalt |
| May 2021–May 2023 | Business Development Manager, SAMI NZ | Colas Limited (NZ) | Rejoined Colas |
| 2018–2021 | Pavement Discipline lead | Higgins Contractors | Hamilton Expressway Project |
| 2003–~2018 | Various → General Manager of Operations | Colas South Africa | |
| ~1991–2003 | Roading roles (~12 years) | KZN Department of Transport | South Africa |

## Certifications and education

- Civil Engineering, Durban Institute of Technology (South Africa)

## Volunteer and mentorship

None visible on public sources.

## What they have said publicly

No public statements found on insurance, risk, renewal, claims, D&O, cyber, business interruption, policy wording, broker selection, or supply-chain risk. Public footprint is narrowly roading-industry (asphalt / pavement / SAMI).

**Absent themes:** all campaign-relevant themes. No conference talks, press quotes, or LinkedIn posts surfaced via web search on insurance topics.

## Who they know (connections relevant to campaign)

None surfaced. No named connections relevant to the campaign found in public sources.

## Institutional context

Colas Limited NZ is a civil-engineering / road-construction contractor. Construction is not one of the seven target verticals for this campaign (manufacturing, transportation and logistics, sports, tourism, hospitality/leisure, retail, wholesale). While Colas undoubtedly carries material insurance exposure (construction liability, plant, PI, contract works), this contact is out-of-scope at the segment level under `segment.yaml` discovery rule 3. The exposure profile is real but belongs to a different campaign.

## Relevance assessment

**What they have NOT said:** anything on insurance, risk, or renewal.

**What IS relevant:** Nothing within campaign scope. Right seniority (MD, owner-operator-adjacent in a subsidiary context) and right geography (ANZ), but wrong industry — Colas is construction, not one of the seven target verticals.

## Angles (ordered by fit)

None applicable. Contact excluded at §4.0 (segment-fit check fails rule 3).

## Verification corrections

- `organisation`: was "Myriad Engineering Ltd" → "Colas Limited". Sweep (v2-matrix, `query:Managing Director manufacturing+geo:NZ+start:0`) associated the LinkedIn URL with the wrong company. LinkedIn headline confirms Managing Director at Colas Limited, Auckland; independent web sources (Colas NZ website, Roads & Infrastructure coverage of the ASCO acquisition, SignalHire career history) corroborate.
- `industry`: was "manufacturing" → "construction". Colas NZ is road construction / bituminous surfacing, not manufacturing.
- `star_rating`: 0 and `date_excluded`: 2026-04-18 — construction is outside campaign scope per `segment.yaml` rule 3.
- `p_note` updated with exclusion reasoning; `s_note` updated with correction note.
- No email backfill — only masked `b***@colas.co.za` found on ZoomInfo (stale South Africa domain; not written per §4.4a). Probable current pattern `bblunt@colas.co.nz` or `b.blunt@colas.co.nz` is unverified and not written.
- No `facebook_url` discovered.
- Myriad Engineering Ltd (Lower Hutt) is a genuine NZ company but has no connection to this Barry Blunt; it is not added as a separate roster row here because its current owners (Jayden and Ashley Jessup) do not independently satisfy discovery criteria without further sweep work.

## Findability probe

- `findability_score`: 2
- `query_used`: `"Barry Blunt" Colas New Zealand`
- `note`: Surfaces immediately via role+company+geography; LinkedIn and Roads & Infrastructure coverage both appear on page 1. Highly discoverable given correct company — but the campaign sweep's wrong-company attribution (Myriad Engineering) would have failed findability entirely, illustrating how a bad `organisation` field kills re-discovery even for a visible contact.

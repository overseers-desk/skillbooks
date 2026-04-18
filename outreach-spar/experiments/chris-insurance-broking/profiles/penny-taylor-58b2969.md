---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Penny Taylor
  organisation: TradeBridge Global
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Penny Taylor

This profile records a §4.11 Person-vs-company finding: the roster row's LinkedIn URL does not resolve to any "Penny Taylor" at TradeBridge Global. The row has been excluded and the real MD of TradeBridge Global (Jon Cox) added as a new roster entry.

## Prior correspondence (IMAP)

No prior correspondence found. `mu` search across all local mail accounts (director-rivermill-au, admin-rivermill-au, me-weiwu-id-au, and aliases) returned zero matches for "Penny Taylor", "TradeBridge", and "TradeBridge Global". Warmth: cold.

## Current role

The LinkedIn URL in the roster row — `https://www.linkedin.com/in/penny-taylor-58b2969/` — resolves to **Penny Taylor, Business Development Director, Gloucester Software Ltd, Gloucester, England, United Kingdom**. This is not the Managing Director of TradeBridge Global. The roster entry's pairing of company (TradeBridge Global, AU) with this LinkedIn URL was an S-phase v2-matrix mis-enrichment; no individual named Penny Taylor has been verified in any TradeBridge Global role or in any Australian or New Zealand context.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| Current | Business Development Director | Gloucester Software Ltd (UK) | Per guest-view LinkedIn header. Full experience section gated behind auth; not fetched. |

LinkedIn guest DOM does not expose the full Experience section for this profile. Since the contact fails the segment at the structural level (§4.0: geography, role title, and industry all mismatch the segment), fetching the gated sections would not change the exclusion outcome and was not attempted.

## Certifications and education

- Longlevens Secondary Modern (school chip visible in guest header). No further education data exposed in guest DOM.

## Volunteer and mentorship

Not exposed in guest DOM; not researched further given structural exclusion.

## What they have said publicly

No campaign-relevant public statements were identified. LinkedIn profile keyword search for `insurance`, `risk`, `renewal`, `claim`, `D&O`, `cyber`, `broker`, `manufacturing`, `TradeBridge`, `CEO`, `CFO` returned zero in-profile hits; the `insurance` / `risk` tokens present in the DOM belonged to an adjacent suggested-profile sidebar card (for National Risk Solutions), not to Penny Taylor's own content.

Web search for `"Penny Taylor" "TradeBridge Global"` returned no matching result. Web search surfaced only the UK Gloucester Software identity and unrelated namesakes.

**Absent themes:** everything the segment cares about — no statements on insurance programs, corporate risk, policy renewal, broker relationships, D&O, cyber cover, or manufacturing operations.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| (none identified) | — | Not researched given structural exclusion. |

The LinkedIn header reports 500+ connections with 146 shared with the viewer, but the identity mismatch makes any connection-value analysis meaningless for this campaign.

## Segment-fit assessment (§4.0)

Evaluating the LinkedIn-resolved identity against the segment rules in `segment.yaml`:

- **Rule 1 (geography = ANZ):** FAIL — Gloucester, England.
- **Rule 2 (role title CEO/CFO/CIO/Owner/Founder/MD):** FAIL — Business Development Director.
- **Rule 3 (industry = mfg, transport, sports, tourism, hospitality, retail, wholesale):** FAIL — software.
- **Rule 4 (public insurance signal):** FAIL — no such signal observed.
- **Rules 5–6 (exclusion rules):** not dispositive; rules 1–3 already fail.

The resolved contact is structurally incapable of delivering the segment's outcome.

## Relevance assessment

**What they have NOT said:** nothing observed on insurance, corporate risk, or any of the segment's operational topics.

**What IS relevant:** nothing. The LinkedIn URL points to a different person from the name/company in the roster row.

## Angles (ordered by fit)

None. No angle table applies — the contact is excluded (`star_rating: 0`).

## Verification corrections

Two corrections made to the roster during this profile run:

1. **Penny Taylor row (`stem=penny-taylor-58b2969`)** — marked excluded: `date_excluded=2026-04-18`, `star_rating=0`, `verified=yes`. `p_note` records the §4.0/§4.11 reasoning and points to the replacement row. The organisation and role fields were left as-recorded (TradeBridge Global, Managing Director) rather than overwritten to the UK Gloucester Software values, because the row represents the failed campaign target, not the UK individual's actual employment.

2. **New row added: Jon Cox (`stem=jon-cox-0059567b`)** — the real Managing Director of TradeBridge Global Pty Ltd (ABN 85 683 735 382, Beresfield NSW 2322), per Persons vs. company (§4.11). Seed data: `linkedin_url=https://www.linkedin.com/in/jon-cox-0059567b/`, `industry=wholesale` (TradeBridge Global is a procurement / sourcing intermediary for piping system components, valving, and metal fabrication — wholesale distribution rather than manufacturing), `country=AU`, `discovered_via=penny-taylor-58b2969`, `discovery_source` recording the §4.11 replacement rationale. Awaiting a future P run.

## Findability probe

- `findability_score: 0`
- `query_used: "Penny Taylor" "TradeBridge Global"`
- `note: namesake-collision / phantom-pairing — no person matching the roster tuple surfaces anywhere; the only "Penny Taylor" found is a UK software director unrelated to the AU company.`

---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Lauren Wells
  organisation: A S Wilcox and Sons Ltd
  role: CEO
  date_excluded: 2026-04-18
---

# Profile: Lauren Wells

**Excluded from campaign (star_rating: 0).** Written per user override of SPAR-P §5.4, which normally withholds a profile document for excluded contacts. The authoritative state remains the roster's `date_excluded` column.

## Disposition summary (§4.11 person-vs-company)

The roster asserted Lauren Wells as CEO of A S Wilcox and Sons Ltd, industry "freight". Profiling found three compounding errors:

1. **Lauren Wells is not CEO of A S Wilcox.** Her current role is CEO of MilkTestNZ (Hamilton, Waikato — dairy testing laboratory owned by Fonterra and Tatua). Confirmed by her LinkedIn headline ("CEO MilkTestNZ", Tauwhare, Waikato) and Baxter Executive Search's published appointment release.
2. **Current CEO of A S Wilcox is Akash Varma** (Auckland; University of Auckland). LinkedIn headline "Chief Executive Officer at A S Wilcox and Sons Ltd." Verified via Google top-result + direct LinkedIn fetch of linkedin.com/in/akash-varma-78b69a97/.
3. **A S Wilcox is not freight forwarding.** It is an integrated vegetable produce grower, packer, and distributor (potato, onion, carrot) — fourth-generation family business headquartered in Pukekohe, NZ domestic + export markets. The roster `s_note` for this row was factually wrong about the company's line of business.

Per §4.11 the role (not the person) is what the campaign wants at this company; the displaced entry is invalidated and the replacement (Akash Varma) has been inserted as a new roster row (`akash-varma-78b69a97`).

## Segment-fit assessment at actual employer

Even at Lauren's real employer (MilkTestNZ), the segment does not fit. Rule 3 requires the employer industry to be one of: manufacturing, transportation/logistics, sports, tourism, hospitality/leisure, retail, or wholesale. MilkTestNZ is a B2B laboratory / analytical services business (milk composition, quality, chemistry, residue testing) — not in the seven target industries. Rule 1 (NZ) and rule 2 (CEO) are both met; rules 5 and 6 are not triggered. She would fail the segment at §4.0 under her real role for industry reasons alone.

## Prior correspondence (IMAP)

Not searched. The campaign's sender inbox (chris@nationalrisksolutions.com.au) is not among the locally-indexed accounts on this host, and the indexed accounts returned no hits for "Lauren Wells", "MilkTestNZ", "Milk Test", "Wilcox", or "A S Wilcox". Warmth defaulted to cold; would be overridden by Chris's own sent-mail if checked at approach time — but the row is excluded, so the question is moot.

## Current role

**CEO, MilkTestNZ** (Hamilton, Waikato — 1344 Te Rapa Rd). Appointment announced via Baxter Executive Search. MilkTestNZ is the dominant independent milk-testing laboratory in New Zealand, processing samples from roughly 10,000 dairy farms daily and covering ~97% of NZ dairy farm supplier samples. Jointly owned by Fonterra and Tatua.

LinkedIn hero also corroborates: "CEO MilkTestNZ", Tauwhare (Waikato), 500+ connections.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CEO | MilkTestNZ | Per LinkedIn headline + Baxter appointment release |
| prior | General Manager Customers | Dairy Goat Cooperative | Per Baxter release |
| prior | GM | Raglan Food Co | Per Baxter release |
| prior | GM | Food Lab Pacific | Per Baxter release |
| prior | Nutritionals Business Unit lead | Tatua | Highly regulated B2B dairy |
| earlier | Business Consultant | Accenture | Per Baxter release |
| earlier | Microsoft Systems Analyst | Tuxedo Technologies Group | Per Baxter release |

LinkedIn experience block did not render under headless dump; career steps above are taken from the Baxter Executive Search appointment release.

## Certifications and education

- Bachelor of Science, Purdue University (US) — per Baxter Executive Search release.

## Volunteer and mentorship

Not surfaced in the headless LinkedIn capture or in web search. Not pursued further given star-0 disposition.

## What they have said publicly

No public statements on campaign-relevant themes surfaced. Web search for `"Lauren Wells" MilkTestNZ insurance OR risk OR broker OR renewal OR "business interruption"` returned no hits against her. LinkedIn keyword search on the captured DOM returned no profile-content matches for `insurance`, `risk`, `broker`, `claim`, `renewal`, `D&O`, `cyber`, `business interruption`, `policy wording`, `freight`, `logistics`, `transport`, `Wilcox`, `export`, `import`, `customs` — the only `insurance` / `risk` tokens in the DOM were in unrelated sponsored ads served alongside the profile.

**Absent themes:** insurance, risk transfer, broker choice, D&O, cyber, business interruption, claims, renewal, policy wording. She maintains a low public voice on risk and insurance topics relevant to this campaign.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| — | — | No campaign-relevant named connections surfaced. LinkedIn connections panel did not render; no tagged people visible in the captured DOM. |

## Relevance assessment

**What they have NOT said:** anything on insurance, risk, broker selection, or any of the segment keywords.

**What IS relevant:** nothing that passes the segment gate. Her current employer (MilkTestNZ) is outside the seven target industries, and she does not hold the role at the company the roster attributes her to.

## Angles (ordered by fit)

None. The row is excluded.

## Verification corrections

All three roster fields for this row were wrong and have been recorded as findings:

- **organisation** — roster says "A S Wilcox and Sons Ltd"; Lauren's actual employer is MilkTestNZ. Not overwritten in the roster (the row is excluded and the replacement is carried on a new row for Akash Varma; rewriting Lauren's org would lose the provenance of the discovery query that found her under the Wilcox name).
- **role** — "CEO" is correct for Lauren (at MilkTestNZ), coincidentally matches the role on the Wilcox row.
- **industry** — roster says "freight"; Wilcox is food/produce (not freight), MilkTestNZ is laboratory services (not freight either). Not overwritten for the same provenance reason; Akash's new row carries `industry=food`.
- **`linkedin_url`** — confirmed live and resolves to Lauren Wells (not a different person); the URL itself is correct.
- **`email`, `facebook_url`, `phone`** — not backfilled. Per §4.4a masked-email rule the ZoomInfo listing (`l***@milktest.co.nz`) is masked and must not be written. She is excluded so no reachable-channel question applies.
- **Replacement row added** — `akash-varma-78b69a97` inserted as the current A S Wilcox CEO. See his roster row for the full provenance note.

## Findability probe

- findability_score: 0
- query_used: `CEO "A S Wilcox" Pukekohe` (initial, generic); refined: `CEO "A S Wilcox and Sons" freight NZ`
- note: Roster-derived non-name keys (role + A S Wilcox + Pukekohe/freight + NZ) surface the current CEO Akash Varma, not Lauren Wells — a roster-key-collision: the inferred keys are faithful to the roster but the roster itself pointed at the wrong person. Lauren's real role (CEO MilkTestNZ, Hamilton) is trivially findable on a `CEO MilkTestNZ Waikato` query (score 2 at her actual employer), so the low score here indexes the roster error rather than any low public visibility on her part.

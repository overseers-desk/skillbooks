---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Satwant Singh Bassan
  organisation: Fantastic Furniture
  role: CFO
  date_excluded: 2026-04-18
---

# Profile: Satwant Singh Bassan

**Status:** Excluded 2026-04-18 (§4.11 person-vs-company + §4.9 star 0). Profile written on explicit user instruction overriding §5.4 ("excluded contacts have no profile") so the P-run findings are preserved alongside peer profiles rather than living only in the roster `p_note` column.

## Prior correspondence (IMAP)

Not searched — this campaign's sender inbox (`chris@nationalrisksolutions.com.au`) is not among the locally-indexed mu accounts available to this agent. Warmth defaulted to cold; moot given the exclusion. Chris can re-check his own sent-mail if Satwant becomes interesting again in his BlueArc capacity (see "Angles" below).

## Current role

**CFO, BlueArc Technologies Pty Ltd** (ABN 61 690 034 121; NSW Australia; https://bluearctech.com.au; phone 1300 171 099). Confirmed via LinkedIn top-card headline ("CFO") and listed current-employer line ("BlueArc Technologies Pty Ltd"). Sydney North, NSW, Australia.

BlueArc is a business-process automation / AI consultancy — ~100-person development team on the Microsoft stack, automating data entry, reporting, and customer-query handling for SME clients in construction, manufacturing, logistics, accounting, finance, legal, healthcare. This is **IT / software services**, not one of the seven segment industries (manufacturing, transport/logistics, sports, tourism, hospitality/leisure, retail, wholesale). The roster originally listed Satwant as "CFO, Fantastic Furniture, retail, AU"; LinkedIn shows he has moved.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CFO | BlueArc Technologies Pty Ltd | Sydney North NSW; AI/automation consultancy |
| prior (dates not recovered) | CFO | Fantastic Furniture (Greenlit Brands) | roster's original seed record; retail furniture chain |
| earlier | — | — | not recovered |

LinkedIn `--dump-dom` single-shot captured the top-card only; the Experience section is lazy-loaded and did not render. Career history beyond the two roles above is not in the public record this run pulled. Education top-card lists **Edith Cowan University** (degree and dates not rendered).

## Certifications and education

- Edith Cowan University (field and dates not in the DOM snapshot).

## Volunteer and mentorship

Not surfaced.

## What they have said publicly

No public statements surfaced on web search or in the LinkedIn capture. LinkedIn About / Activity sections did not render. Headline is three letters ("CFO") with no tagline content.

**Absent themes:** insurance, risk, broker, renewal, D&O, cyber, business interruption, policy wording, claims experience, premium strategy, supply-chain risk, board governance of insurance. Nothing on any campaign-relevant risk theme surfaced.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| Chris Graham | LinkedIn shared-connection ("es contacto en común" string on Satwant's profile card) | Sender of this campaign's outreach — mutual exists but not actioned because target is excluded |

No other named connections extractable from the top-card capture.

## Institutional context

**Former employer — Fantastic Furniture (retail):** the seed roster row's industry tagging was correct at time of sweep. Roster row has been superseded by the replacement entry (Bernard Fong).

**Current employer — BlueArc Technologies (IT services):** fails segment rule 3. Not excluded by rule 5 (not insurance/finance/law/consulting in the segment's sense — BlueArc is software services, not management consulting), but rule 3 requires a positive match against the seven industries, which is absent.

## Relevance assessment

**What they have NOT said:** anything public on any campaign-relevant theme. Public voice is near-silent — no articles, no posts surfaced via `--dump-dom` or web search, no conference-speaker listings, no industry-press quotes.

**What IS relevant:**
1. **Role title match** — "CFO" matches segment rule 2 verbatim.
2. **Geography** — Sydney, Australia (segment rule 1 satisfied).
3. **Not excluded by rule 5 or 6.**

**What fails:**
4. **Industry (rule 3).** Current employer BlueArc Technologies is an IT/software-services firm, not in the seven target industries. This is the binding exclusion.
5. **Rule 4 relaxation** was available (sweep tagged row as v2-matrix, which drops the public-engagement requirement) but rule 3 is not relaxed in any S&P iteration in `segment.yaml`.

## Angles (ordered by fit)

None applicable under current campaign scope. Satwant is excluded.

*Note for a possible future expansion:* if the campaign ever adds IT services / professional services firms to its discovery industries, Satwant would re-qualify as CFO of a ~100-person Australian consultancy with its own insurance program exposure (PI, cyber, management liability, WC). The mutual connection with Chris Graham (visible on LinkedIn) would make the warmth non-cold. Out of scope today.

## Verification corrections

- **`organisation`, `role`:** roster row said "Fantastic Furniture" / "CFO". LinkedIn headline and current-employer line on the profile indicate he has moved to BlueArc Technologies Pty Ltd. Not overwritten on Satwant's row because the row is now excluded — the Fantastic Furniture / CFO values are preserved as the state at time of sweep, which is what `dependent_data` snapshots. The new current state (BlueArc / CFO) is recorded in this profile body only.
- **Replacement added.** Bernard Fong (LinkedIn: `bernard-fong-a68aa518`) confirmed as current CFO, Fantastic Holdings / Fantastic Furniture via ZoomInfo (fantasticfurniture.com.au email), RocketReach finance-department org chart, and LinkedIn profile. Inserted as new roster row `bernard-fong-a68aa518` with `discovered_via=satwant-singh-bassan-45ba0913-replacement`. Prior career recorded in `p_note` (Coca-Cola Amatil Head of Finance Australian Beverages and CFO At-Work BU; Novotech Group Director Finance).
- **`email`, `phone`, `facebook_url`:** no public values surfaced for Satwant; left empty (would not be written anyway, as the row is excluded).
- **`linkedin_url`:** confirmed live and resolving to the correct individual.

## Findability probe

- findability_score: 0
- query_used: `"Satwant Singh Bassan" CFO Sydney` (initial), then `"Satwant Singh Bassan" "Fantastic Furniture"` (refinement)
- note: Public footprint is minimal — web search surfaces the LinkedIn profile itself and data-broker (ZoomInfo / RocketReach / SignalHire) stubs keyed off the LinkedIn URN, but no authored content, press quotes, conference listings, or company-page named appearances. Low public visibility; consistent with the limited LinkedIn top-card (three-letter headline, no About content rendered). For a campaign targeting him in a *future* scope that admitted IT-services CFOs, there would be little on-topic cue material to build warmth from — the Chris-Graham mutual connection would carry the opener, not any statement he has made.

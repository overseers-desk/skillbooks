---
profile_date: 2026-04-18
star_rating: 1
richness: limited
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Steve McMenamin
  organisation: House Land Co
  role: CEO & Founder
  date_excluded: 2026-04-18
---

# Profile: Steve McMenamin

## Prior correspondence (IMAP)

Searched `mu find --muhome=/var/local/cache/mu 'stevenmcmenamin OR "Steve McMenamin" OR houselandco OR "House Land Co" OR "LUX VIP"'` across all locally-indexed accounts (director-rivermill-au, admin-rivermill-au, yuliansu-gmail-com and aliases). No matches. The only "McMenamin" in the index is an unrelated Anne McMenamin (hotmail, long-lunch booking at Historic Rivermill). Chris's NRS inbox is not locally indexed; he can re-check his own sent-mail before approach, but the campaign is exited before approach in any case (see below).

## Current role

**CEO & Founder, House Land Co** (Melbourne, VIC). Concurrent founder role at **LUX VIP Events**, a paid networking/events community for entrepreneurs. LinkedIn headline as rendered: "CEO & Founder - House & Land Co. | LUX VIP Events | $1B+ Transactions". Company registrations: House Land Co Pty Ltd (LinkedIn company page `company/houselandcoptyltd`); LUX VIP Events operates at `luxvipevents.com.au` with a Samcart checkout for membership. Also hosts **The New Property Show** on Melbourne community TV C31.

House Land Co pitches itself as "one of Australia's leading independent new home investment companies" — turnkey new-home investment packages with fixed pricing, titled stock across Victoria, finance referral. Steve is also listed on homely.com.au as a Real Estate Agent at House Land Co. Industry: **real estate / property investment / new-home marketing**, not logistics.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CEO & Founder | House Land Co | Melbourne; property investment / new-home marketing |
| current | Founder | LUX VIP Events | Paid entrepreneur networking community |
| current | Host | The New Property Show (C31) | Melbourne community TV |
| prior | — | Property Guru Pro | Per web search summary; dates not captured |
| prior | — | Australian Building Company | Home building |
| prior | — | Simonds Homes | Volume home builder |
| prior | — | Wights Motor World | Automotive dealership |

LinkedIn Experience block did not hydrate into the captured DOM (header card only). Prior-employer list is from a web-search summary against the same LinkedIn profile; dates not recovered.

## Certifications and education

Not surfaced. No DOM-rendered Education section; nothing relevant in web search.

## Volunteer and mentorship

None surfaced.

## What they have said publicly

Keyword search of the captured LinkedIn DOM against `insurance risk broker renewal claim "D&O" cyber "business interruption" policy premium logistics transportation freight`: **zero profile-content hits**. Two framework/nav-overlay false positives (the logged-in Chris Graham's own tagline text "Corporate insurance specialist…" and his company-admin link "National Risk Solutions" bled into the DOM from the nav-me overlay) — disregarded per standard LinkedIn parsing caveat.

Public voice is entirely on **property investment, finance, strategy, networking** — LinkedIn posts tagged `#houselandcompany #financegoals #investment #strategy #australia`; House+Land Expo 2022 speaking slots on Queensland property hotspots; "Lawyer Lending LIVE" episode as interviewee; LUX VIP business-summit promotions.

**Absent themes:** insurance program, risk transfer, broker selection, renewal cycle, D&O, cyber, business interruption, claims experience, policy wording. Nothing on any campaign-relevant risk theme.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| Chris Graham | 1st-degree LinkedIn connection (135 mutual connections) | Discovery vector is v2-matrix search, but they are in fact 1st-degree; mutual-count is unusually high, consistent with Chris being embedded in the Melbourne LUX VIP / property-investor scene |

LUX VIP Events is a membership community of Melbourne entrepreneurs and founders; in principle it is a bridge to other owner-operators who could match the segment. That network value accrues to any future "introductions" ask, but does not apply here because the current target is being excluded on structural grounds (see below).

## Institutional context (insurance-program exposure)

House Land Co as a real-estate/marketing business carries modest commercial insurance needs (PI for property advice, management liability, cyber for a customer database, office property/BI). LUX VIP Events carries event-liability and cancellation exposure. Neither profile is in the campaign's vertical target list.

## Relevance assessment

**What they have NOT said:** anything on insurance, risk, brokers, claims, or policy structure. Public voice is exclusively on property sales, investment strategy, and networking.

**What IS relevant:**

1. C-suite role title (CEO & Founder) — passes discovery rule 2.
2. Geography (Melbourne, Australia) — passes rule 1.

**What FAILS:**

1. **Rule 3 (industry vertical).** House Land Co sits in **real estate / property investment / new-home marketing**; LUX VIP Events sits in **business events / networking membership**. Neither is in the seven target verticals (manufacturing, transportation/logistics, sports, tourism, hospitality/leisure, retail, wholesale). Same exclusion basis as Jatin Rangras / Delta Group (construction, row 1) and other non-vertical C-suite rows excluded on 2026-04-18. The roster row tagged this entry `industry=logistics`, which is a false positive from the S&P₂ v2-matrix query `"Managing Director" logistics+geo:AU` — LinkedIn's keyword match against Steve's profile is not corroborated by the actual business.
2. **Rule 4 (public insurance-program engagement).** Relaxed under S&P₂ per `approach_sequencing[2]`, so not load-bearing here, but recorded for completeness: zero hits.

Rule 5 (insurance-ecosystem employer) and rule 6 (risk-function title) do not apply.

## Angles (ordered by fit)

None applicable. Rule 3 fails; the contact is structurally outside the segment's mechanism.

## Verification corrections

- `organisation`: backfilled from `(unknown)` → `House Land Co` (LinkedIn headline; houselandco.com.au; homely.com.au agent listing all corroborate).
- `role`: corrected from `Managing Director` → `CEO & Founder` (LinkedIn headline verbatim). Note: data-broker listings and some homely.com.au metadata do use "Managing Director" loosely; the person's own LinkedIn headline is the authoritative form.
- `industry`: corrected from `logistics` → `real-estate` in roster. The `logistics` tag was a v2-matrix query artefact, not a fact about the business.
- `verified`: set `yes` in roster (LinkedIn URL resolves to the correct person; company confirmed via multiple sources).
- `star_rating`: written as `0` to the roster. Front-matter carries `1` per §5.1 minimum; the roster is the authoritative exclusion state.
- `date_excluded`: set `2026-04-18`. Reason recorded in `p_note`: fails segment rule 3 (industry not in seven verticals); discovered via S&P₂ v2-matrix false-positive `logistics` tag.
- `phone`: mobile +61 412 224 228 is published on the House Land Co contact page but has not been written to the roster because the entry is excluded; recording here for traceability only.
- `email`: not found on the company contact page (no `mailto:`, no `info@` published); not backfilled.
- `facebook_url`: Steve maintains `instagram.com/steve_mcmenamin` and House Land Co's Facebook page (`facebook.com/houselandco`); no personal-profile Facebook vanity URL surfaced. Not backfilled.
- `linkedin_url`: confirmed live and resolves to the correct person.

## Findability probe

- findability_score: 2
- query_used: `CEO "House Land Co" Melbourne property`
- note: Surfaces immediately on a generic role + company + city query (company site, homely.com.au agent page, LinkedIn, Facebook page all in top 10). Public discoverability is high, but all on-topic material is property sales, so it does not translate to any campaign-relevant warmth.

# Cross-Discovery: Chris Graham's Network → Rivermill Campaign

**Date:** 2026-04-18
**Searcher:** Agent (cross-discovery probe, read-only on Rivermill files)
**Browser:** CDP via existing chromium instance (snap profile, Chris Graham logged in, port 9222)

---

## 1. Rivermill Campaign Scoped

**Campaign:** 2026-04 Partnership Outreach (Historic Rivermill, Coomera River, Gold Coast hinterland)

**Active segments searched against:**
- tour-operator-domestic (107 roster rows)
- tour-operator-inbound (24 roster rows)
- wedding-planner (52 roster rows)
- event-producer (13 roster rows)
- corporate-team-experience (55 roster rows)
- equestrian-clinic (included in scope)

**Total existing Rivermill roster contacts across these segments:** ~251 rows (stems extracted for dedup)

**Key discovery criteria extracted:**
- Tour operators: domestic day tours on Gold Coast hinterland / Mt Tamborine corridor; inbound ITOs with Gold Coast itineraries
- Wedding planners: Gold Coast and Brisbane, focused on intermediaries who refer couples
- Event producers: themed day event organisers (country/folk, vintage, wellness day markets) who place events at rural venues
- Corporate team-building agencies: companies that place corporate groups at external venues (event agencies, facilitation firms)
- Equestrian: riding instructors, clinicians, pony club contacts
- Geographic scope: Gold Coast / Brisbane / South-East Queensland (domestic operators); national (inbound ITOs)

---

## 2. Queries Run

16 search pages fetched via CDP against the running chromium instance. Network restriction: `network=%5B%22F%22%5D` (Chris Graham 1st-degree only) for all queries.

| # | Slug | Keywords | Hits | Notes |
|---|------|----------|------|-------|
| 1 | tour-operator-qld | tour operator + geoUrn QLD | 0 | No results |
| 2 | event-producer-gc | event producer Gold Coast | 0 | No results |
| 3 | wedding-planner-gc | wedding planner Gold Coast | 0 | No results |
| 4 | tourism-qld | tourism Queensland | 3 | All irrelevant (electrical, ERP, health) |
| 5 | events-qld | event manager Queensland | 30 | Insurance-heavy; no venue/tourism fit |
| 6 | travel-qld | travel agent Queensland | 9 | Risk/compliance dominant; no tour operator |
| 7 | venue-gc | venue hire Gold Coast | 0 | No results |
| 8 | equestrian | equestrian horse | 0 | No results |
| 9 | inbound-tour | inbound tour Australia | 3 | Hotel sales exec; not ITO operators |
| 10 | teambuilding | team building events | 24 | Mostly insurance/finance; 1 events hit |
| 11 | hospitality-gc | hospitality tourism Gold Coast | 0 | No results |
| 12 | wedding-venue | wedding venue events | 24 | Mostly insurance/property; 1 events past-role |
| 13 | festival-gc | festival market Gold Coast | 0 | No results |
| 14 | coach-qld | bus coach tours Queensland | 0 | No results |
| 15 | corp-exp | corporate events experience | 25 | Same pattern: risk/finance; 1 events repeat |
| 16 | wedding-events | wedding planner events | 0 | No results |

**Total fetches used:** 16 of 20 budget.

---

## 3. Hit Classification

Across 16 searches, 131 unique profile appearances were collected. After dedup and classification:

| Class | Count |
|-------|-------|
| Already in Rivermill roster (any segment) | 0 |
| Fails Rivermill criteria (insurance/finance/risk/IT) | ~125 |
| Ambiguous / insufficient info | 3 |
| Candidate — potential Rivermill fit | 3 |

---

## 4. Candidate List — Potential New-for-Rivermill

### A. Steve McMenamin — **CROSS-LEAD (in BOTH rosters)**

- **LinkedIn:** https://www.linkedin.com/in/stevenmcmenamin/
- **Current role headline:** CEO & Founder — House & Land Co. | LUX VIP Events | $1B+ Transactions
- **Location:** Australia
- **Why Rivermill fit:** Operates "LUX VIP Events" alongside a property/real estate business. An event company founder who also operates in the luxury/VIP events space could place corporate events or themed event productions at external venues. Potential fit for Rivermill's event-producer or corporate-team-experience segments.
- **Chris roster entry:** Yes — listed as "Managing Director" (star_rating=4, industry=logistics, no P-phase profile written yet). Organisation listed as "(unknown)". The event business dimension was not yet researched for the insurance campaign.
- **Warmth signal:** 1st-degree of Chris; star_rating=4 in Chris's campaign; no profile yet.
- **Rivermill dedup:** Not in any Rivermill roster.
- **Caution:** The "LUX VIP Events" brand and $1B+ property claims are luxury/real estate oriented — not a Gold Coast hinterland day-event operator. Needs profile fetch to confirm whether LUX VIP Events books external rural venues or runs standalone luxury events.

### B. Rachel E. Otto

- **LinkedIn:** https://www.linkedin.com/in/rachel-e-otto/
- **Current role headline:** "View my services" (available for hire / consulting) | Past: Director of Events at Clerkenwell London
- **Why Rivermill fit:** Past Director of Events at a venue — Clerkenwell London is a well-known London event space. If she has since relocated to Australia and is available for work, she could be a contact for Rivermill's event production or corporate team experience segments, either as a producer or as someone who places clients at venues.
- **Chris roster:** Not found.
- **Warmth signal:** 1st-degree of Chris; location unconfirmed (appeared in wedding-venue search).
- **Rivermill dedup:** Not in any Rivermill roster.
- **Caution:** "Director of Events at Clerkenwell London" is a past role. Current role unclear. UK background may mean she is not based in Queensland. Ambiguous.

### C. Brett Power

- **LinkedIn:** https://www.linkedin.com/in/brett-power-31099b53/
- **Current role headline:** Customer Experience and Sales Manager | Sydney NSW | Past: Business Development Manager at Radisson Blu — account manager for 130+ corporate accounts
- **Why Rivermill fit:** Past BDM at a major hotel brand managing corporate accounts. Someone who spent time selling corporate events and accommodation could have a contact network relevant to Rivermill's corporate-team-experience or tour-operator segments. Thin connection — his current role is "Customer Experience and Sales Manager", not an events business.
- **Chris roster:** Not found.
- **Warmth signal:** 1st-degree of Chris.
- **Rivermill dedup:** Not in any Rivermill roster.
- **Caution:** Sydney-based, current role not events/tourism. The hotel BDM role is historical. Low confidence.

---

## 5. Special Callout: Cross-Lead (Chris Roster AND Rivermill Fit)

**Steve McMenamin** (`https://www.linkedin.com/in/stevenmcmenamin/`) is the only contact who appears in both:
- Chris's insurance-broking campaign roster (stem: stevenmcmenamin, star=4, not yet profiled)
- Rivermill's potential segment fit (LUX VIP Events)

If Chris is already planning a warm approach to Steve for insurance purposes, that contact could be leveraged to introduce Rivermill's venue and event proposition as a second conversation — subject to confirming whether LUX VIP Events places events at external rural venues.

**Count: 1**

---

## 6. Yield Assessment

**Honest verdict: Chris's network yields nothing useful for Rivermill.**

The result confirms the structural hypothesis that went into this probe: Chris Graham's 1st-degree network was built through Marsh, WTW, and the broader insurance/financial-services ecosystem. All searches with substantial hit counts (events-qld, teambuilding, corp-exp, wedding-venue) returned insurance brokers, risk consultants, AIG/Marsh/WTW staff, and financial-services professionals. Geo-specific queries for Gold Coast/Queensland tourism, tour operators, bus coaches, equestrian, wedding planners, and festival organisers all returned zero results.

The three candidates found:
- Steve McMenamin is the only genuine lead, but he is already in Chris's roster and the Rivermill fit is speculative (luxury events ≠ rural heritage tourism partner).
- Rachel Otto's events background is entirely historical and UK-based.
- Brett Power's hotel connection is distant and peripheral.

**No new contacts for Rivermill's roster were found.** The one interesting intersection (McMenamin) is a potential warm intro rather than a new discovery — and only if his LUX VIP Events operation books rural venues at all.

Chris's network is a poor source for Rivermill's partnership targets. The campaign's tour-operator, wedding-planner, event-producer, and equestrian segments require discovery through trade directories (ATEC, TripAdvisor, Easy Weddings, Viator, GYG, Pony Club Queensland) and SEQ-specific Google searches — not through an insurance broker's LinkedIn network.

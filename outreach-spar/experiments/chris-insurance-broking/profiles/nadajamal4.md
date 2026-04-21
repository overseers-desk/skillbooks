---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: known-of
applicable_angles: []
dependent_data:
  contact_name: Nada Jamal
  organisation: Blu Jam Strategy & Digital
  role: Founder
  date_excluded: 2026-04-18
---

# Profile: Nada Jamal

## Prior correspondence (IMAP)

Not searched. Contact fails the §4.0 structural fit check (see Relevance assessment); IMAP step skipped per procedure.

## Current role

**Founder, Blu Jam Strategy & Digital** (Sydney, Australia). Self-described as "Advisor to SME Leaders Scaling for Impact". Blu Jam Strategy & Digital is a strategy and digital consultancy.

Concurrent affiliation: **Macquarie Business School** (listed in LinkedIn header subline; relationship — adjunct, alumna, advisor — not specified in available DOM).

Concurrent affiliation: administrator of the **National Risk Solutions** LinkedIn company page (NRS = the campaign's own organisation). The NRS company page tagline she carries reads "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model." Whether her relationship to NRS is employment, advisory, or marketing-management could not be determined from the DOM (LinkedIn experience cards lazy-load and did not render in `--dump-dom`).

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| Current | Founder | Blu Jam Strategy & Digital | Strategy & digital consultancy, SME advisory |
| Current | (Page admin / unspecified relationship) | National Risk Solutions | Admin of NRS LinkedIn company page; campaign's own organisation |
| Pre-2020 | Chief Financial Officer, Building & Engineering | Lendlease | Captured from sweep-stage LinkedIn "Anterior" snippet ("In January 2020…"); no longer current |

LinkedIn experience-section cards did not render in two `--dump-dom` fetches (top profile + `/details/experience/`); detailed dates between Lendlease and now are not recoverable without a JS-execution browser.

## Certifications and education

- Macquarie Business School (degree and dates not visible in DOM).

## Volunteer and mentorship

Not visible in DOM.

## What they have said publicly

No substantive public statements on insurance, risk, claims, renewals, brokers, D&O, cyber policy, or business interruption were recovered. Keyword scan over the fetched profile HTML hit `insurance` once (the NRS role tagline she carries) and `risk` once (the NRS company name); `renewal`, `claim`, `broker`, `D&O`, `cyber`, `liability` returned zero hits. `premium` and `policy` matches were LinkedIn UI chrome, not content authored by her.

**Absent themes:** insurance program management at an operating company; corporate risk transfer; broker selection; claims handling; coverage renewal cycles; any commentary that would place her in the C-suite-controls-insurance population.

## Who they know (connections relevant to campaign)

- **Chris Graham / National Risk Solutions** — she administers the NRS LinkedIn company page. Direct, current connection to the campaign principal.

No other connections extractable from the available DOM.

## Relevance assessment

**What they have NOT said:** anything that places her as a C-suite executive currently controlling an insurance program at a target-industry company.

**What IS relevant:** she carries past CFO experience (Lendlease, Building & Engineering, pre-2020) and a current strategy-advisory practice — but the campaign's discovery_criteria require *current* C-suite role at a *currently* qualifying employer.

**Structural fit (§4.0):** FAIL.

1. Discovery rule 2 (current role title): her current title is Founder of a consultancy and Advisor — not a CEO/CFO/CIO/Owner/MD of an operating company in the seven verticals.
2. Discovery rule 3 (current employer industry): Blu Jam Strategy & Digital is **management consulting** — explicitly excluded by rule 5. Macquarie Business School is academia, also outside scope.
3. Discovery rule 5 (insurance ecosystem hard-exclude): she administers the National Risk Solutions LinkedIn page; NRS is the campaign's own broker entity. Targeting an affiliate of the sender's own firm is a structural error regardless of whether her relationship is staff, advisor, or contractor.

The Lendlease CFO role would have qualified at the time (construction/engineering ≈ adjacent to manufacturing) but is historical and not the current role. Discovery_criteria evaluate current state.

## Angles (ordered by fit)

None applicable. Contact is excluded.

## Verification corrections

Roster updated 2026-04-18:

- `contact_name`: `(unknown — sweep stored Spanish "Anterior:" snippet in this field)` → `Nada Jamal`
- `organisation`: `(unknown)` → `Blu Jam Strategy & Digital`
- `role`: empty → `Founder`
- `industry`: `unknown` → `management consulting`
- `star_rating`: empty → `0`
- `date_excluded`: empty → `2026-04-18`
- `p_note`: populated with exclusion reason (rule 5 + NRS affiliation + historical Lendlease role)

## Findability probe

- `findability_score: 1`
- `query_used: "Blu Jam" "Nada" Sydney founder strategy`
- `note: A generic role+geography query ("founder strategy consultancy Sydney") would not surface her in the first 20 results — too crowded a category. Adding the distinctive brand "Blu Jam" reliably surfaces her, so she is searchable given partial brand context but not via inferred industry keys alone.`

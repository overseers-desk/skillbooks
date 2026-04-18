# Seeding Matrix v2 — Design Document

**Date:** 2026-04-18
**Purpose:** Replace the 1B keyword (role + insurance topic) matrix with a role × industry matrix that finds buyer-CFOs by industry affiliation, not by public engagement with insurance topics.

---

## 1. Probe Results

Each probe fetched one page (~20–26 visible slots) from LinkedIn people search using chromium logged in as Chris Graham. The final slot is always Chris himself (self-match, excluded). Counts exclude that slot.

Classification key:
- **Target** — plausible C-suite (CEO/CFO/MD/Owner/Founder) currently at a manufacturing, logistics/freight, sports/club, tourism, hospitality, retail, or wholesale firm
- **Insurance ecosystem** — broker, underwriter, insurer, loss adjuster, risk consultant, insurance lawyer
- **Off-role** — not C-suite (GM, Head of, manager, EA, etc.)
- **Off-industry** — C-suite but wrong industry (real estate, banking, fintech, aged care, health, etc.)
- **Ambiguous** — insufficient text to classify

| Query | Country | Slots shown | Target | Insurance | Off-role | Off-industry | Ambiguous | Precision (T/shown) |
|---|---|---|---|---|---|---|---|---|
| `CFO manufacturing` | AU | 18 | 15 | 0 | 1 | 2 | 0 | **0.83** |
| `Managing Director logistics` | AU | 22 | 19 | 0 | 2 | 1 | 0 | **0.86** |
| `Managing Director manufacturing` | AU | 22 | 18 | 0 | 1 | 2 | 1 | **0.82** |
| `CEO freight` | AU | 25 | 19 | 1 | 2 | 3 | 0 | **0.76** |
| `CEO "sports club"` | AU | 21 | 17 | 0 | 2 | 2 | 0 | **0.81** |
| `Owner manufacturer` | AU | 19 | 13 | 0 | 3 | 2 | 1 | **0.68** |
| `CEO hospitality` | AU | 25 | 17 | 1 | 3 | 3 | 1 | **0.68** |
| `CEO tourism` | AU | 23 | 14 | 0 | 3 | 4 | 2 | **0.61** |
| `CEO tourism` | NZ | 17 | 9 | 2 | 2 | 3 | 1 | **0.53** |
| `CEO sports` | AU | 24 | 13 | 0 | 4 | 5 | 2 | **0.54** |
| `CEO "tour operator"` | AU | 22 | 11 | 1 | 3 | 5 | 2 | **0.50** |
| `CFO "supply chain"` | AU | 15 | 6 | 0 | 4 | 4 | 1 | **0.40** |
| `CFO wholesale` | AU | 19 | 7 | 1 | 4 | 5 | 2 | **0.37** |
| `CEO retail` | AU | 23 | 3 | 2 | 5 | 11 | 2 | **0.13** |
| `CEO logistics` | AU | 25 | 1 | 6 | 7 | 9 | 2 | **0.04** |
| `CEO logistics` | NZ | 19 | 2 | 5 | 4 | 7 | 1 | **0.11** |
| `Founder distribution` | AU | 17 | 2 | 0 | 3 | 10 | 2 | **0.12** |

**Median precision across 17 probes: 0.54**

### Key observations per probe

**`CFO manufacturing` (AU, precision 0.83)** — Best single query. LinkedIn treats "manufacturing" as a strong industry signal; almost every result is a finance executive at a goods producer. Occasional off-industry (FMCG corporates with Westpac-scale finance teams) but low noise overall.

**`Managing Director logistics` (AU, precision 0.86)** — Highest single precision. "Managing Director" is a more specific LinkedIn title token than "CEO", and "logistics" as a bare word maps cleanly to freight/3PL firms. No insurance ecosystem leak. Rick Celik (PRODEL Logistics), Luke Mullins (South Western Logistics), Vic Ferrara (Total Maritime Logistics), Robert Felton (Felton Global) are all solid targets.

**`Managing Director manufacturing` (AU, precision 0.82)** — Closely mirrors logistics result. Strong. Jens Goennemann (Advanced Manufacturing Growth Centre) and Andrew Fortey (My Muscle Chef) are representative targets.

**`CEO freight` (AU, precision 0.76)** — Better than "CEO logistics" because "freight" maps almost exclusively to transport firms; "logistics" bleeds into software, consulting, and importantly the insurance broker population (Lockton, Marsh, QBE all appear for "CEO logistics"). Moorebank Intermodal, Secon Freight Logistics, SOILCO — quality contacts.

**`CEO "sports club"` (AU, precision 0.81)** — Quoted phrase is critical. Bare "CEO sports" (precision 0.54) surfaces sporting goods retail, healthcare, Olympic programme managers, and athletes as org representatives. "Sports club" constrains to registered clubs, almost all of which are sports-and-recreation employers with real insurance programs (events liability, liquor, public liability). Maroubra Seals, Bankstown Sports, Kahibah, Springwood — all genuine venues.

**`Owner manufacturer` (AU, precision 0.68)** — Good SME angle that "CFO manufacturing" misses (owner-operators of small manufacturing firms don't title themselves CFO). Some noise from sole traders (cosmetics, botanics makers) — these are micro-businesses where insurance program value is low. Filtering by company size at profile stage resolves this.

**`CEO hospitality` (AU, precision 0.68)** — Solid. One insurance-ecosystem hit (Angus M. — CEO EML Solutions & Hospitality Industry Insurance — hard exclude). Hospitality keyword retrieves hotel/venue/restaurant operators well. Rachel Henning (EA to CEO) is an off-role false positive: LinkedIn's relevance engine sometimes surfaces adjacent-title profiles.

**`CEO tourism` (AU, precision 0.61)** — Moderate. Tourism Adventure Group (Tom Cooney), Anywhere Travel Group (Nik Young), and Anthea Hammon (Tourism CEO) are solid. Noise from real estate and business advisors (Craig West appears repeatedly across many queries — he is a generic "CEO advisor" whose profile matches many industry keywords).

**`CEO tourism` (NZ, precision 0.53)** — NZ pool is smaller; two insurance-ecosystem hits (WTW NZ CEO Jill Comley-Forbes, AIG NZ CEO Liam Pomfret) appear immediately because Chris's NZ network is insurance-heavy. Still viable — NZ tourism sector (Rail & Tourism Group Holdings, Chris Lamers's aviation+tourism portfolio) has good targets.

**`CEO sports` (AU, precision 0.54)** — Meaningful noise. CEO Sport NSW (government body), Deloitte CEO (off-industry), Enervest CEO (energy), City of Sydney Basketball. The keyword "sports" alone is too broad. "Sports club" is the recommended replacement.

**`CEO "tour operator"` (AU, precision 0.50)** — Mixed. The quoted phrase helps some but many tourism executives describe their businesses as "tour operator" in narrative text rather than in current titles, so match quality is inconsistent. "CEO tourism" outperforms.

**`CFO "supply chain"` (AU, precision 0.40)** — "Supply chain" is a function description, not an industry label. CFOs who put "supply chain" in their profile headline are often in finance-function roles at FMCG or retail conglomerates (Woolworths, Nestlé, DHL arms) — technically within scope but harder to triage. Better to reach them via `CFO retail` (if that query had better precision) or directly via `MD/CEO` of wholesale/distribution firms.

**`CFO wholesale` (AU, precision 0.37)** — "Wholesale" bleeds heavily into wholesale banking (AmBank, Westpac) and wholesale finance/investment. CFO title combined with "wholesale" draws bank-sector finance executives. Wholesale distribution firms are better reached via `Owner` or `MD` plus a distribution synonym.

**`CEO retail` (AU, precision 0.13)** — Worst performing query. "Retail" activates real estate (Raine & Horne, LJ Hooker, Ray White ecosystem) because Australian real estate agencies use "retail" in title or profile text and LinkedIn's algorithm is anchored on Chris's insurance/real-estate-adjacent network. Also pulls Westpac Retail Banking, Linfox Retail division. Bare "CEO retail" is unusable.

**`CEO logistics` (AU, precision 0.04)** — Catastrophic. Chris's 1st-degree connections include Lockton CEO Marcus Pearson and Marsh connections (Adi Roy Chowdhury, Frank Lampert) prominently in the result set. LinkedIn ranks by mutual connections before keyword relevance; the insurance-ecosystem network dominates the logistics keyword result. "Managing Director logistics" and "CEO freight" bypass this failure mode because they trigger different relevance paths.

**`CEO logistics` (NZ, precision 0.11)** — Same failure in NZ: WTW NZ CEO, AIG NZ CEO, Frank Risk Management CEO all appear before actual logistics operators.

**`Founder distribution` (AU, precision 0.12)** — "Distribution" in a financial-services context (fund distribution, investment distribution, broker distribution) is extremely common in Chris's network neighbourhood. The query surfaces investment management founders and financial-services channel MDs. Unusable as a wholesale synonym.

---

## 2. Industry Keyword Recommendations

| Vertical | Recommended keyword(s) | Avoid | Notes |
|---|---|---|---|
| Manufacturing | `manufacturing` | `manufacturer` (singular) | `manufacturer` surfaces small-batch owner-operators; fine for Owner/Founder queries but noisy for CEO/CFO. `manufacturing` maps cleanly at all role levels. |
| Transport / Logistics | `freight`, `logistics` (with MD/MD-level title) | `logistics` with `CEO` | `logistics` + `CEO` contaminated by insurance-sector network. `freight` is safer for CEO. `logistics` is fine with `Managing Director`. |
| Sports | `"sports club"` | `sports` (bare) | Bare `sports` has 54% precision; quoted phrase reaches 81% by constraining to registered clubs. |
| Tourism | `tourism` | `"tour operator"` | `tourism` outperforms `"tour operator"`. The latter matches career-narrative text inconsistently. |
| Hospitality | `hospitality` | — | Clean keyword; minimal false-positive types. |
| Retail | `"retail group"`, `"retail chain"`, avoid bare `retail` | `retail` | Bare `retail` activates real estate and banking. Quoted phrases force the word to appear in titles/employer names. Alternatively drop CEO and use `MD retail` or `Owner retail`. |
| Wholesale / Distribution | `wholesale` (with Owner/MD), `distribution` (with Owner/MD) | `distribution` with `Founder` | `distribution` + `Founder` activates financial-services distribution. `wholesale` + `CFO` bleeds into banking. Use `Owner` or `Managing Director` as the role token. |

---

## 3. Role Keyword Recommendations

| Role phrase | Performance | Notes |
|---|---|---|
| `Managing Director` (quoted or space-separated) | Best (0.82–0.86) | LinkedIn title-matches "Managing Director" as a discrete unit; almost no ambiguity. Reaches owner-operators of mid-size firms. Recommended for logistics, manufacturing, wholesale. |
| `CFO` | Strong for manufacturing (0.83), weak for wholesale/supply chain | Single-token, unambiguous. Works best when industry keyword is a strong industry label, not a function label (avoid `CFO supply chain`). |
| `CEO` | Highly context-dependent (0.04–0.81) | Precision depends on industry keyword quality. Safe for hospitality, tourism, sports club, freight. Unusable for logistics, retail, distribution without qualifier. |
| `Owner` | Good (0.68) for manufacturing/SME angle | Reaches sole-director SMEs missed by CEO/CFO searches. Combine with `manufacturer` (singular) or `manufacturing`. |
| `Founder` | Poor for distribution/wholesale verticals | Attracts fintech/finserv founders. Only viable if combined with a narrow non-financial industry label. |
| `Chief Executive Officer` (full) | Not tested; expected similar to `CEO` | Avoid — longer string may reduce result count without precision gain. |

---

## 4. Final Proposed v2 Matrix

Queries ordered by expected yield (precision × approximate pool size). Queries marked `(skip)` are explicitly excluded based on probe data.

### Tier 1 — High precision (>0.75), run first

| # | Role | Industry keyword | Country | URL template (geoUrn) | Priority |
|---|---|---|---|---|---|
| 1 | Managing Director | logistics | AU | 101452733 | Tier 1 |
| 2 | CFO | manufacturing | AU | 101452733 | Tier 1 |
| 3 | Managing Director | manufacturing | AU | 101452733 | Tier 1 |
| 4 | CEO | freight | AU | 101452733 | Tier 1 |
| 5 | CEO | "sports club" | AU | 101452733 | Tier 1 |
| 6 | Managing Director | logistics | NZ | 105490917 | Tier 1 |
| 7 | CFO | manufacturing | NZ | 105490917 | Tier 1 |
| 8 | Managing Director | manufacturing | NZ | 105490917 | Tier 1 |
| 9 | CEO | freight | NZ | 105490917 | Tier 1 |

### Tier 2 — Moderate precision (0.50–0.75)

| # | Role | Industry keyword | Country | geoUrn | Priority |
|---|---|---|---|---|---|
| 10 | CEO | hospitality | AU | 101452733 | Tier 2 |
| 11 | Managing Director | hospitality | AU | 101452733 | Tier 2 |
| 12 | CFO | hospitality | AU | 101452733 | Tier 2 |
| 13 | CEO | tourism | AU | 101452733 | Tier 2 |
| 14 | Managing Director | tourism | AU | 101452733 | Tier 2 |
| 15 | CEO | tourism | NZ | 105490917 | Tier 2 |
| 16 | Managing Director | tourism | NZ | 105490917 | Tier 2 |
| 17 | CEO | sports | AU | 101452733 | Tier 2 |
| 18 | CEO | "sports club" | NZ | 105490917 | Tier 2 |
| 19 | Owner | manufacturing | AU | 101452733 | Tier 2 |
| 20 | Owner | manufacturer | AU | 101452733 | Tier 2 |
| 21 | CFO | retail | AU | 101452733 | Tier 2 |
| 22 | Owner | wholesale | AU | 101452733 | Tier 2 |
| 23 | Managing Director | wholesale | AU | 101452733 | Tier 2 |
| 24 | Owner | wholesale | NZ | 105490917 | Tier 2 |
| 25 | Managing Director | wholesale | NZ | 105490917 | Tier 2 |
| 26 | Managing Director | "supply chain" | AU | 101452733 | Tier 2 |
| 27 | CEO | hospitality | NZ | 105490917 | Tier 2 |
| 28 | CFO | logistics | AU | 101452733 | Tier 2 |
| 29 | CFO | freight | AU | 101452733 | Tier 2 |
| 30 | Founder | manufacturing | AU | 101452733 | Tier 2 |

### Tier 3 — Targeted long-tail (run after Tier 1 & 2 are processed)

| # | Role | Industry keyword | Country | geoUrn | Priority |
|---|---|---|---|---|---|
| 31 | CEO | "retail group" | AU | 101452733 | Tier 3 |
| 32 | Managing Director | retail | AU | 101452733 | Tier 3 |
| 33 | Owner | retail | AU | 101452733 | Tier 3 |
| 34 | CEO | "tour operator" | AU | 101452733 | Tier 3 |
| 35 | CEO | "tour operator" | NZ | 105490917 | Tier 3 |
| 36 | Founder | hospitality | AU | 101452733 | Tier 3 |
| 37 | Founder | tourism | AU | 101452733 | Tier 3 |
| 38 | CEO | warehousing | AU | 101452733 | Tier 3 |
| 39 | Managing Director | warehousing | AU | 101452733 | Tier 3 |
| 40 | CEO | transport | AU | 101452733 | Tier 3 |
| 41 | CFO | transport | AU | 101452733 | Tier 3 |
| 42 | CEO | "food manufacturing" | AU | 101452733 | Tier 3 |
| 43 | Managing Director | "food manufacturing" | AU | 101452733 | Tier 3 |
| 44 | Owner | manufacturer | NZ | 105490917 | Tier 3 |
| 45 | CFO | retail | NZ | 105490917 | Tier 3 |

**Explicitly excluded from v2 (based on probe failures):**
- `CEO logistics` (AU/NZ) — precision 0.04/0.11
- `CEO retail` (AU) — precision 0.13
- `Founder distribution` (AU) — precision 0.12
- `CFO wholesale` — bleeds into banking; use `Owner wholesale` or `MD wholesale` instead
- `CFO "supply chain"` — functional label, not industry; use `MD "supply chain"` instead

---

## 5. Known Failure Modes

### 5.1 Network-topology contamination (`CEO logistics`)
LinkedIn's ranking algorithm weights mutual-connection proximity heavily. Chris's 1st-degree network contains Lockton CEO Marcus Pearson and Marsh associates. These appear at ranks 1–3 for any `CEO`+ keyword query that has a logistics-adjacent insurance population. `CEO logistics` returns Lockton/Marsh/QBE before any actual logistics operator. **Fix:** use role tokens (`Managing Director`, `CFO`, `Owner`) that do not overlap with the insurance broker C-suite profile pattern, and use narrower keywords (`freight`, `transport`, `warehousing`) that are harder to match against insurance profiles.

### 5.2 Industry-word polysemy in finance context
- `logistics` → appears in insurance consulting job histories ("logistics of a claims process")
- `distribution` → investment fund distribution (financial services)
- `retail` → retail banking, retail property, retail real estate
- `wholesale` → wholesale banking, wholesale lending, fund wholesale
- `supply chain` → financial supply-chain finance products

Any of these words combined with a financial-sector role (CFO, Founder) pulls finance-industry results. Safe combinations are role tokens that are rare in insurance/finance profiles + unambiguous industry words.

### 5.3 Sports polysemy
Bare `sports` matches: athletes with LinkedIn presence, sports media personalities, Olympic programme managers, sporting goods retail. `"sports club"` limits to registered clubs (bowling, leagues, RSL, rugby, netball etc.) which are real insurance buyers.

### 5.4 Craig West omnipresence
A single highly-connected profile ("Dr Craig West") appears in virtually every AU query. His profile contains skills like "hospitality", "retail", "tourism", "manufacturing" and he has 6,000+ connections. LinkedIn surfaces him as a social-proximity result regardless of actual current role. He is not a target (management consultant). Filter at profile stage; don't mistake his presence for a signal about query quality.

### 5.5 Stale role data
Several profiles show a current role at a logistics/manufacturing firm but closer inspection reveals the LinkedIn "Actual" (current role) is insurance-adjacent. The parse-search.py snippet window captures both current and past roles, so a profile with past Marsh experience may appear to match "logistics" if they currently hold a logistics-sector role. This is correct — the past insurance employer does not disqualify them — but it means the classifier must read "Actual:" (current role) not the full window.

### 5.6 Small result sets for NZ
NZ geo (geoUrn 105490917) returns 15–20 profiles vs AU's 20–26. The NZ insurance ecosystem is proportionally smaller, but Chris's NZ connections include WTW NZ CEO and AIG NZ CEO, which contaminates NZ results for CEO+logistics/retail. Tier 1 NZ queries (MD logistics, CFO manufacturing, CEO freight) are less affected because those role tokens don't match insurance broker CEO profiles.

---

## 6. Expected TAM Coverage vs 1B

### 1B baseline
- 119 keyword queries (role + insurance topic)
- ~5 quality contacts yielded
- Implied precision: ~4%
- Fetch budget consumed: 119 pages × ~20 slots = ~2,380 profile slots examined
- Quality contacts per slot: 0.002

### v2 projection (hypothesis, not a promise)

Tier 1 (9 queries): median probe precision 0.82 × ~22 slots = ~18 targets per query × 9 queries = **~162 raw targets** before dedup and exclusion rule screening.

Tier 2 (21 queries): median precision ~0.60 × ~20 slots = ~12 targets per query × 21 = **~252 raw targets**.

Tier 3 (15 queries): median precision ~0.45 × ~20 slots = ~9 per query × 15 = **~135 raw targets**.

Total raw targets across 45 queries: **~550 profile slots worth examining**.

After dedup (~30% overlap between queries hitting the same people), exclusion rules 5–6 (insurance ecosystem, Risk Manager titles, ~15% expected), and P-phase triage dropping low-signal profiles (~40%):

**Estimated 3+★ contacts from v2: 120–180** (vs ~5 from 1B)

At same page-fetch budget as 1B (119 fetches), v2 allocates 45 seed queries + 74 fetches for profile depth (start=10, start=20 pages on Tier 1 queries). This is a ~25–35× improvement in quality yield per fetch budget — but is still a hypothesis until the first full seeding run confirms the cluster-level dedup rate and P-phase pass rate.

The key uncertainty is dedup: many of the ~550 raw targets will be the same person found by multiple queries (e.g., a CFO of a manufacturing+wholesale business). Expect 30–50% dedup reduction; the 3+★ range above already accounts for the lower end of that range.

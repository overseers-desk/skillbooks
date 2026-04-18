# S&P Search Plan — Chris Graham / NRS C-suite ANZ

**Purpose:** operational cursor for unattended S&P execution. Each `/loop` tick reads the "Current position" and executes the next bounded chunk. State lives on disk; progress is tracked here and in `roster.tsv`.

## Pacing

No artificial rate-limiting — the headless chromium + LinkedIn round-trip is slow enough on its own. Every LinkedIn fetch is still appended to `search-log.tsv` for audit, not for throttling.

## Stopping rules (SPAR default)

- S&Pₙ stops when the iteration yields fewer than 5 new contacts.
- S&P₃ is always the final iteration even if yield is still above 5.
- Transition from Sₙ → Pₙ happens when Sₙ is complete for the iteration.
- Transition from Pₙ → S(n+1) happens when P-dispatcher reports all iteration-n contacts profiled.

## Warmth-gap analysis (produced at end of S&P)

Aggregate roster.tsv by `discovered_via` to reveal the gap between Chris's network and the total addressable market:

- `chris-1st-degree` = directly connected, warmest
- `2nd-degree-via-<stem>` = reachable via one intro (populate during P phase from LinkedIn "mutual connections")
- `linkedin-keyword-search`, `asic-nzco-registry`, `industry-association`, `conference-speaker` = cold unless cross-checked

During P phase, cross-check every cold-discovered contact against Chris's connections (LinkedIn profile's "mutual connections" count > 0 upgrades them to `2nd-degree-via-mutuals`).

Final report at `roster-gap-report.md`: tally of rows per warmth tier, and a named list of target-industry companies discovered via registry/association but where no LinkedIn C-suite could be resolved (the invisible end of the gap).

## Current position

```
iteration: DONE-v2-complete
phase: complete
last_action: v2-matrix tier-2/3 (36 queries, 315 rows) executed; 8 junk rows cleaned; S5 cross-lead cascade yielded 31 rows; P4-v2-t23 dispatcher launched (319 tasks, 4 parallel jobs, running at time of report); gap report updated
next_action: none (S&P scope complete; P4-v2-t23 running in background; A-phase disabled for this campaign)
```

(Updated by each tick. The `next_action` field is the dispatcher signal.)

## Known LinkedIn facet behaviour (confirmed 2026-04-17)

- `titleFreeText` URL parameter is **ignored** in headless fetches (the facet is JS-rendered). Do not split queries by role — use one paginated query per country and filter role client-side.
- `geoUrn` **is** applied server-side. AU and NZ return distinct result sets.
- `network=F` restricts to 1st-degree — confirmed working.
- Pagination via `&start=N` (standard LinkedIn offset, 10 per page).

## S&P₁ sources (execute in order)

### 1A — Chris Graham's 1st-degree connections

- URL: `https://www.linkedin.com/mynetwork/invite-connect/connections/`
- Works because browser is logged in as Chris.
- Method: fetch connections list, paginate if needed. For each connection, extract name + headline + profile URL. Filter:
  - Location contains Australia / New Zealand / any AU/NZ city
  - Title contains: CEO, Chief Executive Officer, CFO, Chief Financial Officer, CIO, Chief Information Officer, Owner, Founder, Managing Director
  - Current company industry (where derivable from headline) is one of: manufacturing, transportation, logistics, sports, tourism, hospitality, leisure, retail, wholesale
  - NOT in insurance / financial services / law / consulting industry
  - NOT a Risk Manager / Head of Risk / Head of Insurance
- Tag: `discovered_via=chris-1st-degree`, `discovery_source=connections-list`
- Rule 4 (insurance-engagement signal) is NOT applied at 1A — 1st-degree are warmest regardless of public posting.

### 1B — LinkedIn people-search keyword matrix

Per-query URL: `https://www.linkedin.com/search/results/people/?keywords=<QUERY>&geoUrn=<URN>&origin=GLOBAL_SEARCH_HEADER`

Country URNs:
- Australia: `%5B%22101452733%22%5D`
- New Zealand: `%5B%22105490917%22%5D`

Keyword templates (6 per country, 12 total per industry-seed; run per industry in parallel via subagents, one subagent per query, report names and headlines back):

1. `CEO insurance renewal`
2. `CFO insurance program`
3. `CFO risk management`
4. `"Managing Director" "business interruption"`
5. `Founder cyber insurance`
6. `Owner "policy wording"`

Industry expansion is via seed companies, not URL industry filter (LinkedIn's industry URN filter is inconsistently applied for people search). Instead, rely on post-filtering by current-company industry at candidate-review time.

Target per query: first result page only (≈10 results), all pages not needed in S₁ — breadth of queries beats depth of single query.

Tag: `discovered_via=linkedin-search`, `discovery_source=query:<QUERY>`

### 1C — Apply exclusion rules (post-filter)

Before admitting any candidate to the roster, subagent per-candidate check against:
- Rule 5 (industry exclusion): current company is NOT insurance / financial services / law / consulting
- Rule 6 (role exclusion): current title does NOT contain "Risk Manager" etc.

This check is cheap — one profile fetch per candidate, parse current company and company industry.

## S&P₂ sources (only after S₁ + P₁ complete)

### 2A — Drop rule 4; broaden LinkedIn search

Re-run the 1B matrix without the insurance-engagement keywords — pure role × country searches, filtered at candidate-review time by exclusion rules. Targets the "silent majority" who don't post publicly.

### 2B — 2nd-degree from profiled S₁ contacts

For each S₁ contact with `star_rating >= 3` after P₁, fetch their "People also viewed" and examine their post commenters (subagent parses comment section from profile HTML). Any commenter matching role × industry rules enters roster with `discovered_via=2nd-degree-via-{stem}`.

### 2C — ASIC + NZ Companies Office

- ASIC company search: https://connectonline.asic.gov.au/ — free search returns company name + ACN; full director lookup is paywalled. For S₂, extract company names matching ANZSIC codes for the seven industries, then enrich via LinkedIn company-page fetch to find directors. ANZSIC codes:
  - Manufacturing: divisions C (11–25)
  - Transport/Logistics: division I (46–53)
  - Sports: subdivision 91 (91.1, 91.2)
  - Tourism/accommodation: subdivision 44 (44.0)
  - Leisure/entertainment: subdivision 90 (90.0)
  - Retail: division G (39–43)
  - Wholesale: division F (33–38)
- NZ Companies Office: https://companies-register.companiesoffice.govt.nz/ — free search by company or director name.

### 2D — Reverse-search diagnostic

From P₁ profiles of star-rated contacts, extract the vocabulary they use (e.g. "captive", "parametric", "mutual"). Re-query LinkedIn with those terms. Names invisible to the 1B seed vocabulary surface here.

## S&P₃ sources (only after S₂ + P₂ complete)

### 3A — Industry association member directories

- AusCycling — https://www.auscycling.org.au/
- Tourism Accommodation Australia — https://www.tourismaccommodation.com.au/
- Australian Logistics Council — https://austlogistics.com.au/
- National Retail Association — https://www.nra.net.au/
- Australian Chamber of Commerce & Industry — https://www.australianchamber.com.au/
- Ai Group (manufacturing) — https://www.aigroup.com.au/
- NZ Retail Association — https://retail.kiwi/
- NZ Tourism Industry Association — https://tia.org.nz/
- Business NZ — https://www.businessnz.org.nz/

Many have public member directories; some require login. For each: fetch, extract company names, enrich via LinkedIn company page.

### 3B — Conference speaker lists

- ANZIIF events — https://anziif.com/
- RIMS Australasia — https://www.rims.org/
- Industry-specific risk/insurance conferences — web-search for "insurance conference Australia 2025/2026"

### 3C — Long-tail web search

Named C-suite in press releases, news coverage of insurance renewals, major claims, risk events. Declining yield expected.

## Progress log (appended by ticks)

```
# Each tick appends one line:
# [timestamp] [iteration] [action] [names_found] [names_new] [notes]
```

---

**NOTE TO LOOP:** Read the "Current position" block at the top. Execute the action named in `next_action`. Update the block before exiting the tick. Never modify sections outside "Current position" and "Progress log" — the rest is the stable plan.

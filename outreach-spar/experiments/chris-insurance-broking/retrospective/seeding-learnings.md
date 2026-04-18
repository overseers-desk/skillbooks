# Seeding Learnings — Chris Graham / NRS C-suite ANZ

**Campaign:** chris-insurance-broking
**Written:** 2026-04-18
**Audience:** planner of the next SPAR S&P campaign

---

## 1. Summary

The original S1 seed — Chris Graham's 1st-degree connections combined with insurance-topic keyword searches — produced 126 of the campaign's 161 roster rows, of which 116 were rated 0★ and excluded. The central failure was not in the profiling criteria but in the seed: the keyword strategy found people who talk publicly about insurance, and in a network centred on an insurance broker, that population is overwhelmingly sellers, not buyers. The seeding matrix should have been built on industry identity (what sector the person works in), not on topic engagement (what subject they post about).

---

## 2. The original plan and what it assumed

S1 ran two seed sources in parallel.

**1A — 1st-degree connections.** Chris's own LinkedIn network, filtered by C-suite role title and by target industry. The assumption was that a large, career-long professional network would contain a meaningful proportion of buyer-side executives across the seven target verticals (manufacturing, transport/logistics, sports, tourism, hospitality, retail, wholesale).

**1B — keyword matrix.** LinkedIn people-search using queries that combined a role token (CEO, CFO, MD, Founder, Owner) with an insurance engagement term from rule 4 of the discovery criteria (e.g. "business interruption", "policy wording", "cyber insurance"). The assumption was that people who post publicly about insurance topics are likely to be decision-makers in their company's insurance program — the very population the campaign wanted to reach. Rule 4 was written as both a qualification criterion and a search handle.

Both approaches were described in the search plan as logically consistent with the discovery criteria. They were — but they were vulnerable to the same systematic bias.

---

## 3. Where 1A failed and why

Chris's Marsh and WTW career history means his 1st-degree network is predominantly the insurance ecosystem: brokers, underwriters, risk consultants, insurer executives, claims professionals, and their direct counterparts. When the connection list was filtered by C-suite role title in the target industries, it yielded 7 rows from an unknown total pagination. Seven rows from an entire career's network is not a data-quality problem; it is an accurate reading of the network's composition. The target population (buyer CFOs in logistics firms, owners of manufacturing SMEs) is genuinely rare in a broker's connection list.

The insight this surfaces is structural: **1st-degree yield is a function of the sender's career trajectory, not just the size of their network.** A sender who spent their career in manufacturing would produce a different 1A yield than one who spent it in insurance. Before running 1A for any future campaign, the right question is: "What does this person's career history tell us about who they are connected to?" If the answer is "mostly the same industry the campaign is trying to sell to," 1A will be sparse.

An ex-CFO of a logistics company would likely produce 50–100 qualifying 1A rows from a similarly-sized network.

---

## 4. Where 1B failed and why

Rule 4 of the discovery criteria — "has posted, commented, or been quoted on a topic containing 'insurance', 'renewal', 'business interruption' etc." — was designed as a qualification criterion to confirm the buyer-CFO engages with their insurance program. It was a good criterion for P-phase scoring. It was a bad search handle.

LinkedIn people-search does not retrieve people who have "engaged" with an insurance topic in the abstract. It retrieves people whose profile text, headline, current role, or employer name contains the keyword. The population of LinkedIn users whose public profiles contain "business interruption" or "policy wording" is overwhelmingly insurance professionals — brokers who wrote those terms thousands of times in their careers — not buyer CFOs who happened to mention the phrase once in a comment on an industry article.

The result was 119 rows, 116 rated 0★ (77% of total roster rows). The P-phase correctly applied the exclusion rules and rejected the insurance-ecosystem contacts. The problem was that it was asked to filter a contaminated population. A mixed population (some insurance ecosystem, some target buyers) would produce a workable precision; a population drawn from insurance-keyword searches, filtered through an insurance-broker's network, produces a contaminated one. The precision failure was invisible at seed time — a row that looks like "CFO, Logistics firm, posted about business interruption" could be a genuine buyer or a Lockton claims consultant whose past role was in logistics. The distinction becomes visible only at profiling time.

---

## 5. The role-token finding

The seeding-matrix-v2.md probe data revealed a secondary failure mode that interacts with 1B's keyword problem: the choice of role token (CEO vs MD vs CFO) affects which slice of LinkedIn's ranking algorithm is triggered, and that slice is shaped by the sender's network.

The starkest example: `CEO logistics` (AU) returned precision 0.04 — effectively zero. The first results were Lockton CEO Marcus Pearson and Marsh associates, surfaced by LinkedIn's mutual-connection proximity ranking before any actual logistics operators. `Managing Director logistics` (AU) returned precision 0.86 — the highest single-query precision in the probe set. The same industry keyword, a different role token, completely different contamination.

The mechanism is that "CEO" is a common title among insurance-broker executives (every broker firm has a CEO), so `CEO + any keyword` triggers mutual-connection ranking that pulls insurance CEOs forward. "Managing Director" is rarer in the insurance-broker population — most broker firms use CEO or Regional Director — so the network-proximity penalty is lower, and LinkedIn returns results that are genuinely matched on the industry keyword.

The generalisation: **for any vertical adjacent to the sender's current or prior industry, prefer role tokens with less overlap in the sender's existing network.** MD, CFO, and Owner over CEO for logistics and distribution in a broker's network. The corollary: the sender's own network biases what LinkedIn returns, and that bias is invisible unless you probe with multiple role tokens for the same industry keyword. A single-query probe gives the precision of that combination; it cannot reveal whether a different role token would have been five times more precise.

---

## 6. The industry-keyword polysemy trap

Several industry keywords that seemed unambiguous turned out to carry financial-services meanings that contaminated results in a broker-adjacent network:

- **`logistics`** — appears in insurance consulting job histories ("managed the logistics of the claims process"). Combined with CEO it produces 4% precision; combined with Managing Director, 86%. The word itself is fine; the role token drives the contamination.
- **`distribution`** — investment fund distribution is one of the most common uses in Australian financial services. `Founder distribution` returned 12% precision: almost exclusively financial-services founders whose distribution channel was their product, not freight founders who distribute goods. Usable only with Owner or MD.
- **`retail`** — in Chris's network neighbourhood, activates retail banking (Westpac Retail Banking, Linfox Retail division) and real estate agencies (which use "retail" for shopfront property). `CEO retail` returned 13% precision. Compound phrases (`"retail group"`, `"retail chain"`) or a different role token (`MD retail`, `Owner retail`) are needed.
- **`wholesale`** — wholesale banking, wholesale lending, and wholesale funds all use the word in their official firm names. `CFO wholesale` returned 37% precision and skewed toward bank-sector finance executives.
- **`sports`** (bare) returned 54% precision: athletes, sports media, Olympic programme managers, and sporting goods retailers all surface. `"sports club"` (quoted phrase) returned 81% precision by constraining to registered club entities.

Polysemy risk correlates with how financially saturated the term is in the sender's network neighbourhood. The fix is not to avoid these keywords but to probe first and favour compound phrases or sector-specific synonyms (`freight` instead of `logistics`, `"sports club"` instead of `sports`, `manufacturing` instead of `manufacturer`) where precision data supports the substitution.

---

## 7. Registry and association routes were blocked for structural reasons

The plan included ASIC Connect and the NZ Companies Office as S2 sources, and eleven industry associations as S3 sources. Both routes encountered structural blocks that keyword tuning cannot fix.

ASIC Connect and the NZ Companies Office render search results via JavaScript. Headless chromium with `--dump-dom` captures only the initial static DOM; pagination that lists director names is never fetched. Twelve rows entered the roster via these routes through manual enrichment and press-source fallback, but systematic coverage was not possible. Bidfood NZ and Bidfood AU remain as company-level entries with no resolved LinkedIn profiles. The fix requires a browser agent that executes JavaScript pagination, or a paid ASIC director lookup API — not keyword tuning.

Of eleven industry associations attempted in S3, ten were login-walled or returned empty DOMs. ALC (Australian Logistics Council) was the one exception, yielding 8 quality logistics contacts all rated 3★ or higher. The other ten — Ai Group, TAA, NRA, NZ TIA, Retail NZ, Business NZ, AusCycling — require member credentials. The right path is a human with a member login extracting a directory in one manual session. The sports vertical has zero qualifying contacts in part because no sport-specific association directory was publicly accessible.

---

## 8. The Weiwu re-sweep as negative result

At one point during the campaign a re-sweep was considered using a different LinkedIn account (Weiwu's) to check whether a different 1st-degree network would surface additional targets. The check confirmed it would not: Weiwu's ANZ 1st-degree network was approximately 20 people across Australia and New Zealand, predominantly tech and software professionals with no meaningful presence in the target verticals.

The lesson is not that re-sweeping from a second network is wrong in principle — it can work. The lesson is that **before treating a second network as a seed source, verify that it has the right vertical and geographic density.** A small, tech-weighted network adds noise, not signal. The check takes two minutes (pull the connections list, spot-check industries); skipping it wastes a seeding pass.

---

## 9. The dispatcher empty-organisation skip

This is an operational observation rather than a seeding-design lesson, but it masked a seeding problem long enough to be worth recording.

The dispatch script (spar-dispatch.tcl, around line 267) silently skips roster rows where the `organisation` field is empty. The 1B keyword-search results frequently produced empty-org rows because LinkedIn search result pages do not expose company names uniformly in the DOM — the company name lives in a position that the page parser missed for some result layouts.

On the first P1 run, the dispatcher processed 9 of 134 rows and exited cleanly with no error. The skip was discovered only by manually inspecting the dispatcher logs and comparing row counts. The roster had 134 rows; 9 were processed; the other 125 had empty organisation fields.

Two design decisions led to this: the 1B keyword search produced results without reliable org extraction, and the dispatcher's skip was silent (not logged). The mitigation used in this campaign was to accept `(unknown)` as a placeholder organisation value, with the P-harness resolving real organisations from LinkedIn profile data during profiling. Future seed designs should either ensure org fields are populated at seed time or adopt a sentinel placeholder that the dispatcher treats as "to be resolved," rather than silently skipping.

---

## 10. Positive lessons

Three seeding routes produced results well above the campaign average, and they are worth reproducing:

**Cross-leads from high-quality profiles.** Eight new rows entered the roster at S2 via "People also viewed" and post commenter extraction from 3★+ profiles; all eight came back 3★ or higher at P2. A buyer-CFO's social graph contains other buyer-CFOs — the same professional homophily that drives the insurance-ecosystem contamination problem also makes cross-leads reliable amplifiers.

**Conference-speaker searches.** Three contacts (two tourism, one hospitality) were found via speaker-list searches, all rated 4★. Speaker lists are deterministic — a speaker list is a list, not a probabilistic keyword match — and speakers have the public footprint needed for angle-building.

**The ALC association directory.** The Australian Logistics Council published its member list without a login gate and yielded 8 contacts all rated 3★ or higher. Test association directory accessibility before building the S3 pipeline around it — the difference between open and login-walled is discoverable in under a minute.

---

## 11. The v2 matrix recommendation

Based on the probe data in seeding-matrix-v2.md, the recommended replacement for the 1B matrix is a role-keyword × industry-keyword grid with no insurance terms. The queries target people by their industry affiliation, not their topic engagement.

The probe set covered 17 queries, median precision 0.54, with Tier 1 queries hitting 0.76–0.86. A full v2 run of 45 queries would look approximately like:

- Tier 1 (9 queries, mean precision ~0.82): ~18 targets per query × 9 = ~162 raw candidates
- Tier 2 (21 queries, mean precision ~0.60): ~12 targets per query × 21 = ~252 raw candidates
- Tier 3 (15 queries, mean precision ~0.45): ~9 targets per query × 15 = ~135 raw candidates
- Total raw candidates: ~550 before dedup and exclusion rule screening

After approximately 30–50% dedup (many people are reachable by multiple queries), and accounting for the P-phase pass rate, the estimate from seeding-matrix-v2.md is 120–180 contacts rated 3★ or higher — compared to 5 from the 1B approach on a comparable fetch budget.

These are planning estimates based on probe data from a single day. The dedup rate is the main uncertainty: if many targets appear across multiple queries (e.g. a CFO of a manufacturing-and-wholesale business), dedup could exceed 50% and the 3★ yield falls accordingly. The first full v2 run will validate or correct the projection.

Role-token guidance: prefer MD and CFO over CEO for logistics, distribution, and wholesale. CEO is acceptable for hospitality, tourism, and "sports club" — those verticals had workable CEO precision. Avoid `Founder` with distribution or wholesale keywords. `Owner` reaches manufacturing SMEs that CEO/CFO searches miss.

---

## 12. What this tells us about SPAR methodology

The SPAR-S procedure's guidance to "cast a wide net" in the S phase is correct in principle. The problem here was not that the net was too wide — it was woven from the wrong material. The methodology does not currently name the seed-precision concept: the expected precision of a given search query (fraction of results that will be targets) is query-specific and sender-specific, and cannot be inferred from the discovery criteria alone.

A probe step — one page per planned seed query, results classified into target / off-industry / off-role, precision calculated as targets ÷ slots shown — would have caught the 1B failure mode before 119 rows were added to the roster. That is exactly the protocol seeding-matrix-v2.md ran after the fact.

The methodology could name this the "seed-precision probe" and recommend it as a pre-S1 step whenever the seed source is a keyword search. A registry with a known ANZSIC code mapping does not need probing. But for informal segments driven by keyword searches, especially where the sender's network is adjacent to the target industry, the probe is the difference between discovering 5 good contacts and discovering 39.

---

*The tallies referenced throughout this document are drawn from `roster-gap-report.md`; the probe precision figures are from `seeding-matrix-v2.md`. This document does not duplicate those tables.*

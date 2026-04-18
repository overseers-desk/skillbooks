# Roster gap report — chris-insurance-broking

v2-matrix seeding complete — final stats as of 2026-04-18. Covers all S&P sweeps: S1/P1 (150 rows via 1B keyword search + registry + 1st-degree), S2/P2 cross-leads (8 rows), S3/P3 conference-speaker expansion (3 rows), S4 Weiwu re-sweep (6 rows), S4 v2-matrix tier-1 (100 rows), S4 v2-matrix tier-2/3 (315 rows), S5 cross-lead cascade from tier-1 profiles (31 rows). Total roster: 621 rows. P4-v2-t23 dispatcher running at time of report (319 tasks, ~4 parallel jobs).

---

## 1. Final roster stats

**Total roster rows:** 621

**Rows per `discovered_via`:**

| discovered_via | rows |
|---|---|
| v2-matrix-t23 | 317 |
| linkedin-keyword-search | 119 |
| v2-matrix | 100 |
| cross-lead-from-profile | 31 |
| asic-nzco-registry | 12 |
| industry-association | 8 |
| chris-1st-degree | 7 |
| weiwu-1st-degree | 6 |
| nzco-registry | 4 |
| cross-lead-via-dallas-vince | 4 |
| conference-speaker | 3 |
| cross-lead-via-ashley-davie | 2 |
| cross-lead-via-steve-skinner | 1 |
| cross-lead-via-clare-davies | 1 |

**Rows per `sweep_iteration`:**

| sweep_iteration | rows |
|---|---|
| 4 | 426 (v2-matrix t1 + t2/t3) |
| 1 | 152 |
| 5 | 31 (cross-lead cascade from profiled tier-1 contacts) |
| 2 | 8 |
| 3 | 3 |
| (blank) | 1 |

**Star distribution (rows profiled before this run):**

| star_rating | rows |
|---|---|
| (unrated — awaiting P4-v2-t23 profiling) | 356 |
| 0 | 167 |
| 3 | 63 |
| 4 | 22 |
| 2 | 7 |
| 5 | 4 |
| 1 | 2 |

**Before v2 run — targetable subset (≥3★, not excluded):** 41 contacts (as reported at end of S4/Weiwu sweep).

**After v2 run — targetable subset:** Will update once P4-v2-t23 completes profiling. The 356 unrated rows are the 315 v2-t23 + 31 cross-lead entries and 10 residuals from prior sweeps without star ratings yet.

---

## 2. v2-matrix tier yield comparison

| Tier | Queries | New rows added | Avg rows / query |
|---|---|---|---|
| Tier 1 | 9 | 100 | 11.1 |
| Tier 2 | 21 | ~238 | ~11.3 |
| Tier 3 | 15 | ~77 | ~5.1 |
| **Total v2** | **45** | **~415** | **9.2** |

Note: Tier-2 and tier-3 combined added 315 rows. Approximate split based on query ordering in the run log: tier-2 (21 queries) delivered proportionally more than tier-3. The quoted "v2-matrix-t23" source covers both tiers combined.

Compared to 1B keyword-search (119 queries → 119 rows kept, most excluded): v2-matrix produced roughly 3.5× the density of raw contacts per query. Precision was not measured per-row at this stage (the parse-search text bleeding means classification was done at query level using inclusion heuristics); P-phase star-rating will provide the quality signal.

---

## 3. Cross-lead cascade (sweep_iteration=5)

Scanned 269 profile files for "Who they know" named contacts. Extracted 109 candidate cross-leads from table rows. After filtering:

- Insurance ecosystem in role: excluded
- Already in roster by name: excluded
- Non-C-suite (GM, H&S, Sales Director, etc.): excluded
- Generic/non-person entries: excluded

**31 new cross-leads admitted** as sweep_iteration=5, discovered_via=cross-lead-from-profile. These include:

| Vertical | Cross-leads |
|---|---|
| manufacturing | 16 |
| logistics | 5 |
| wholesale | 3 |
| tourism | 2 |
| hospitality | 2 |
| retail | 1 |
| NZ | 9 of the 31 |

31 ≥ 5 threshold → second dispatcher run warranted. However, given total roster size and budget, these 31 rows have been included in the existing p4-v2-t23 dispatcher run (which dispatches all unprocessed rows together).

---

## 4. Warmth tiers (pre-P4-v2-t23 completion)

Based on rows with star_rating populated (265 rows):

| warmth_tier | count |
|---|---|
| warm (≥2★, profiled) | ~35 |
| hot (1st-degree, not excluded) | 1 |
| cold (≤1★, profiled) | ~7 |
| unrated (queued for P4) | 356 |
| excluded (0★, date_excluded set) | ~167 |

---

## 5. Industry coverage (rated rows only — pre-P4-v2-t23)

| Vertical | 2★ | 3★ | 4★ | 5★ | Total ≥3★ |
|---|---|---|---|---|---|
| transport / logistics | 1 | 12 | 2 | 2 | 16 |
| manufacturing | 1 | 6 | 3 | 0 | 9 |
| wholesale | 2 | 7 | 0 | 0 | 7 |
| hospitality | 0 | 0 | 3 | 1 | 4 |
| tourism | 0 | 2 | 2 | 1 | 5 |
| retail | 0 | 0 | 1 | 0 | 1 |
| sports | 0 | 0 | 0 | 0 | 0 |

Sports remains zero. The v2 tier-2 `CEO sports` (AU) query ran, and `CEO "sports club"` (NZ) ran. Whether any sports-club contacts survived the classification and P-phase triage will be clear once profiling completes.

---

## 6. Named "invisible" companies (LinkedIn-unreachable targets)

From prior sweeps and cross-lead notes; these companies were identified as in-scope but have no LinkedIn-reachable C-suite:

- Bidfood New Zealand (wholesale, NZ) — Phil Struckmann (CEO) added as cross-lead sweep_iteration=5; LinkedIn profile to be verified by P-phase
- Bidfood Australia (wholesale, AU) — Rachel Ruggiero profiled; Bidfood NZ peer added
- Booth's Logistics (transport, NZ) — Craig Booth profiled; Graham Booth (co-founder) added as cross-lead
- Team Transport & Logistics (transport, AU) — Gail Casey profiled; no further LinkedIn-reachable contact identified
- Easy Access Co (NZ) — Shane Wearmouth added as cross-lead (co-director)
- A S Wilcox (manufacturing, AU) — Kevin Wilcox (MD) and Bruce Rowe (CFO) added as cross-leads from Akash Varma profile

---

## 7. Recommended next steps

The v2 seeding run is now the campaign terminal. P4-v2-t23 is actively running (319 profiles queued). When it completes, the final targetable subset will be known.

If the campaign were to continue after P4-v2-t23:

- **Sports vertical remains empty.** The `CEO sports` and `CEO "sports club"` queries ran but LinkedIn's result quality for these is low (54% and 81% precision respectively). Manual directory lookup via AFL, NRL, or bowling-club association websites is the only reliable route.
- **Retail** has one rated contact and a handful of new v2 rows pending profiling. `Managing Director retail` and `Owner retail` queries ran in tier-3; expect low yield given known pollution from real-estate results.
- **P4-v2-t23 completion** will substantially expand the star-rated pool. The 317 tier-2/3 rows, if they hold to the ~45–55% exclusion rate of tier-1, would yield roughly 150–175 additional rated contacts, of which an estimated 60–80 will be ≥3★.
- **Cross-lead sweep_iteration=5 rows (31)** will also be profiled in the same P4-v2-t23 run. These are sourced from confirmed C-suite contacts so exclusion rate should be lower.

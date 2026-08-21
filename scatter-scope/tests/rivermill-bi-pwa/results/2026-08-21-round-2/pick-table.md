# Pick table

Expected is the median of three blind estimators (`e1.md`, `e2.md`, `e3.md`), each of whom saw
`oracle-brief.md` and nothing else. Gap is log3(measured / expected); beyond +/-1 (a factor of
three) flags. A flags in either direction, since it is exact. B and D flag upward only. **C is
printed and never picked on** — see the calibration note in `report.md`. A module low on A and
high on B at once carries the leak signature and ranks first.

`note` marks a module with no distinctive vocabulary: its B is not measured and reads 0. That is
the instrument having nothing to grep for, never "well hidden".

Sorted by combined gap. 384 non-test modules; 161 flagged.

| module | A exp/meas | B exp/meas | D exp/meas | C exp/meas | gap A | gap B | gap D | leak | flags | disposition |
|---|---|---|---|---|---|---|---|---|---|---|
| `web/src/lib/auth.ts` | 2/11 | 5/214 | 1/2 | 8/1129 | +1.55 | +3.42 | +0.63 | 203 | A high, B high | artefact (revival 2): the stem `auth` names four things |
| `spheres/schedule/api/providers/sonas.js` | 1/4 | 2/79 | 2/0 | 3/354 | +1.26 | +3.35 | -1.26 | 78 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `web/src/pipeline/api.ts` | 6/16 | 7/122 | 1/3 | 10/1248 | +0.89 | +2.60 | +1.00 | 108 | B high | **scattered** (revival 3): SQL column vocabulary re-spelled as bare text |
| `web/src/app/AuthGate.tsx` | 1/6 | 3/19 | 2/6 | 5/69 | +1.63 | +1.68 | +1.00 | 13 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `server/shared/credentials.js` | 3/24 | 6/38 | 2/4 | 8/145 | +1.89 | +1.68 | +0.63 | 14 | A high, B high | by design (revival 5b): the connector fan-out |
| `spheres/schedule/api/config.js` | 3/3 | 4/199 | 0/1 | 6/772 | +0.00 | +3.56 | +0.63 | 196 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/ReachNote.tsx` | 6/30 | 7/43 | 1/3 | 11/169 | +1.46 | +1.65 | +1.00 | 13 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `web/src/lib/clicklog.ts` | 1/6 | 3/11 | 0/2 | 5/44 | +1.63 | +1.18 | +1.26 | 5 | A high, B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1); A high: by design |
| `connectors/instagram/insights-sync.js` | 0/0 | 2/24 | 1/7 | 3/31 | +0.00 | +2.26 | +1.77 | 24 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `connectors/tiktok/insights-sync.js` | 0/0 | 2/24 | 1/7 | 3/31 | +0.00 | +2.26 | +1.77 | 24 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `connectors/awsconnect/api/upsert.js` | 1/0 | 3/118 | 2/1 | 5/295 | -0.63 | +3.34 | -0.63 | 118 | B high, leak signature | artefact (revival 1): the stem carries B |
| `connectors/facebook/insights-sync.js` | 0/0 | 2/24 | 1/6 | 3/31 | +0.00 | +2.26 | +1.63 | 24 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `spheres/financial/ui/views/Labour.tsx` | 0/1 | 2/14 | 3/15 | 2/30 | +0.63 | +1.77 | +1.46 | 13 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `spheres/social/ui/api.ts` | 7/15 | 8/85 | 1/3 | 13/499 | +0.69 | +2.15 | +1.00 | 74 | B high | artefact in the main, residue worth a look (revival 8) |
| `spheres/publicity/api/stage-advance.js` | 1/3 | 3/31 | 2/4 | 5/56 | +1.00 | +2.13 | +0.63 | 28 | B high | artefact (revival 1): the stem carries B |
| `spheres/social/api/stage-advance.js` | 1/3 | 3/31 | 2/4 | 5/70 | +1.00 | +2.13 | +0.63 | 28 | B high | artefact (revival 1): the stem carries B |
| `web/src/lib/journey.ts` | 2/11 | 3/17 | 0/1 | 5/110 | +1.55 | +1.58 | +0.63 | 12 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `spheres/social/ui/Rolodex.tsx` | 1/3 | 2/15 | 4/11 | 3/108 | +1.00 | +1.83 | +0.92 | 12 | B high | artefact (revival 1): the stem carries B |
| `spheres/publicity/ui/api.ts` | 2/3 | 3/56 | 1/2 | 5/173 | +0.37 | +2.66 | +0.63 | 53 | B high | artefact (revival 8): `created_at` |
| `web/src/lib/url-state.ts` | 8/20 | 8/30 | 0/3 | 13/132 | +0.83 | +1.20 | +1.63 | 10 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `server/shared/connector-tenant.js` | 4/21 | 5/41 | 1/1 | 6/144 | +1.51 | +1.92 | +0.00 | 20 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `connectors/clover/api/upsert.js` | 1/1 | 3/117 | 2/1 | 5/252 | +0.00 | +3.33 | -0.63 | 116 | B high | artefact (revival 1): the stem carries B |
| `connectors/deputy/api/upsert.js` | 1/1 | 3/117 | 2/1 | 5/259 | +0.00 | +3.33 | -0.63 | 116 | B high | artefact (revival 1): the stem carries B |
| `connectors/spar/api/upsert.js` | 1/1 | 3/117 | 1/1 | 5/310 | +0.00 | +3.33 | +0.00 | 116 | B high | artefact (revival 1): the stem carries B |
| `connectors/square/api/upsert.js` | 1/1 | 3/117 | 1/1 | 4/250 | +0.00 | +3.33 | +0.00 | 116 | B high | artefact (revival 1): the stem carries B |
| `spheres/projects/ui/views/Gantt.tsx` | 0/1 | 2/17 | 4/9 | 2/40 | +0.63 | +1.95 | +0.74 | 16 | B high | artefact (revival 1, batch) |
| `spheres/schedule/ui/api.ts` | 3/7 | 4/33 | 1/2 | 6/221 | +0.77 | +1.92 | +0.63 | 26 | B high | artefact (revival 1): the stem carries B |
| `spheres/schedule/api/providers/rezdy.js` | 1/1 | 2/73 | 2/1 | 3/277 | +0.00 | +3.27 | -0.63 | 72 | B high | artefact (revival 1): the stem carries B |
| `spheres/schedule/ui/views/Almanac.tsx` | 0/1 | 2/8 | 2/9 | 2/8 | +0.63 | +1.26 | +1.37 | 8 | B high, D high (hub) | artefact (revival 1, batch); artefact (revival 6, class 1) |
| `web/src/lib/use-pathname.ts` | 2/6 | 3/9 | 0/2 | 5/26 | +1.00 | +1.00 | +1.26 | 3 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/awsconnect/api/sync.js` | 1/13 | 4/11 | 4/0 | 7/30 | +2.33 | +0.92 | -1.89 | 11 | A high | by design: shared vocabulary read widely |
| `web/src/lib/use-api-view.ts` | 15/38 | 12/53 | 1/3 | 20/239 | +0.85 | +1.35 | +1.00 | 15 | B high | artefact (revival 1): the stem carries B |
| `spheres/publicity/api/stage-pass.js` | 1/0 | 2/16 | 1/2 | 3/29 | -0.63 | +1.89 | +0.63 | 16 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/social/api/stage-pass.js` | 1/0 | 2/16 | 1/2 | 3/29 | -0.63 | +1.89 | +0.63 | 16 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/social/ui/cards.tsx` | 2/4 | 3/8 | 1/6 | 5/34 | +0.63 | +0.89 | +1.63 | 4 | D high (hub) | artefact (revival 6, class 1) |
| `server/shared/runbook.js` | 2/4 | 4/62 | 1/0 | 5/313 | +0.63 | +2.49 | -0.63 | 58 | B high | artefact (revival 1): the stem carries B |
| `connectors/googlereviews/api/upsert.js` | 2/2 | 4/117 | 1/1 | 6/302 | +0.00 | +3.07 | +0.00 | 115 | B high | artefact (revival 1): the stem carries B |
| `connectors/rezdy/api/upsert.js` | 1/1 | 4/117 | 2/1 | 5/278 | +0.00 | +3.07 | -0.63 | 116 | B high | artefact (revival 1): the stem carries B |
| `connectors/sonas/api/upsert.js` | 1/1 | 4/117 | 2/2 | 5/245 | +0.00 | +3.07 | +0.00 | 116 | B high | artefact (revival 1): the stem carries B |
| `connectors/xero/api/upsert.js` | 1/1 | 4/117 | 2/1 | 5/275 | +0.00 | +3.07 | -0.63 | 116 | B high | artefact (revival 1): the stem carries B |
| `server/shared/auth.js` | 3/3 | 12/154 | 4/9 | 20/726 | +0.00 | +2.32 | +0.74 | 152 | B high | artefact (revival 1): the stem carries B |
| `web/src/app/sphere.ts` | 4/18 | 5/31 | 0/0 | 6/67 | +1.37 | +1.66 | +0.00 | 14 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `spheres/financial/ui/vocab.ts` | 4/2 | 4/27 | 0/1 | 7/79 | -0.63 | +1.74 | +0.63 | 25 | B high, leak signature | artefact (revival 1): the stem carries B |
| `web/src/app/ChatAssistant.tsx` | 1/0 | 2/9 | 4/12 | 3/17 | -0.63 | +1.37 | +1.00 | 9 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/financial/ui/views/ProfitAndLoss.tsx` | 0/1 | 2/7 | 5/19 | 2/15 | +0.63 | +1.14 | +1.22 | 6 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `spheres/financial/ui/period.ts` | 2/5 | 3/8 | 0/2 | 5/63 | +0.83 | +0.89 | +1.26 | 3 | D high (hub) | artefact (revival 6, class 1) |
| `server/shared/stage-advance.js` | 3/5 | 6/31 | 2/6 | 10/85 | +0.46 | +1.49 | +1.00 | 26 | B high | artefact (revival 1): the stem carries B |
| `spheres/social/ui/CampaignBoard.tsx` | 1/1 | 2/9 | 3/16 | 2/23 | +0.00 | +1.37 | +1.52 | 8 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `web/src/lib/view-scope.ts` | 2/11 | 3/13 | 0/0 | 4/40 | +1.55 | +1.33 | +0.00 | 2 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `web/src/pipeline/CampaignBoard.tsx` | 3/1 | 4/9 | 2/7 | 7/33 | -1.00 | +0.74 | +1.14 | 8 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/tiktok/api/auth-bootstrap.js` | 0/0 | 2/15 | 1/3 | 3/19 | +0.00 | +1.83 | +1.00 | 15 | B high | artefact (revival 1): the stem carries B |
| `connectors/xero/api/auth-bootstrap.js` | 0/0 | 2/15 | 1/3 | 3/19 | +0.00 | +1.83 | +1.00 | 15 | B high | artefact (revival 1): the stem carries B |
| `spheres/coord/api/instance.js` | 1/0 | 3/11 | 1/3 | 5/26 | -0.63 | +1.18 | +1.00 | 11 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/library/ui/api.ts` | 2/5 | 3/26 | 1/0 | 5/69 | +0.83 | +1.97 | -0.63 | 23 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/ParamChips.tsx` | 6/9 | 5/18 | 1/4 | 8/79 | +0.37 | +1.17 | +1.26 | 9 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `spheres/relationships/ui/api.ts` | 3/3 | 4/85 | 1/1 | 6/446 | +0.00 | +2.78 | +0.00 | 82 | B high | artefact (revival 8): `linkedin`, `Identity` |
| `connectors/facebook/api/insights-sync.js` | 1/3 | 4/28 | 4/1 | 6/84 | +1.00 | +1.77 | -1.26 | 25 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/CtxMenu.tsx` | 3/6 | 4/41 | 0/0 | 6/96 | +0.63 | +2.12 | +0.00 | 35 | B high | artefact (revival 5a): `viewport` |
| `spheres/coord/ui/views/ByPerson.tsx` | 0/2 | 2/3 | 3/10 | 2/8 | +1.26 | +0.37 | +1.10 | 1 | A high, D high (hub) | artefact (revival 6, class 1); A high: by design |
| `spheres/social/api/instance.js` | 1/0 | 3/20 | 2/3 | 5/66 | -0.63 | +1.73 | +0.37 | 20 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/coord/ui/api.ts` | 4/5 | 5/40 | 1/2 | 8/150 | +0.20 | +1.89 | +0.63 | 35 | B high | artefact (revival 1): the stem carries B |
| `spheres/social/ui/components.tsx` | 3/6 | 5/6 | 0/4 | 8/66 | +0.63 | +0.17 | +1.89 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/reputation/ui/api.ts` | 2/5 | 3/23 | 1/1 | 5/160 | +0.83 | +1.85 | +0.00 | 18 | B high | artefact (revival 1): the stem carries B |
| `server/shared/pipeline-fixture.js` | 0/2 | 4/18 | 1/1 | 6/57 | +1.26 | +1.37 | +0.00 | 16 | A high, B high | artefact (revival 1): the stem carries B; A high: by design |
| `spheres/coord/prelink.js` | 1/0 | 3/9 | 1/3 | 3/28 | -0.63 | +1.00 | +1.00 | 9 |  |  |
| `spheres/social/ui/PerformanceSection.tsx` | 1/1 | 2/12 | 4/12 | 3/17 | +0.00 | +1.63 | +1.00 | 11 | B high | artefact (revival 1, batch) |
| `web/src/ui/FilterBar.tsx` | 6/2 | 6/18 | 1/2 | 8/138 | -1.00 | +1.00 | +0.63 | 16 |  |  |
| `web/src/pipeline/ContactPanel.tsx` | 2/3 | 3/10 | 2/7 | 5/33 | +0.37 | +1.10 | +1.14 | 7 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `server/shared/sync-runs.js` | 10/26 | 10/65 | 2/1 | 18/259 | +0.87 | +1.70 | -0.63 | 39 | B high | by design (revival 4) |
| `web/src/lib/interaction-context.ts` | 3/2 | 4/11 | 1/4 | 6/53 | -0.37 | +0.92 | +1.26 | 9 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/googlereviews/import-historical.js` | 0/0 | 2/8 | 1/4 | 3/11 | +0.00 | +1.26 | +1.26 | 8 | B high, D high (hub) | artefact (revival 1): the stem carries B; artefact (revival 6, class 1) |
| `server/shared/http-json.js` | 8/1 | 9/3 | 0/1 | 14/8 | -1.89 | -1.00 | +0.63 | 2 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `web/src/lib/drive.ts` | 2/1 | 3/2 | 1/8 | 5/14 | -0.63 | -0.37 | +1.89 | 1 | D high (hub) | artefact (revival 6, class 1) |
| `server/shared/ready.js` | 6/1 | 8/20 | 2/1 | 13/124 | -1.63 | +0.83 | -0.63 | 19 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `spheres/schedule/ui/week.ts` | 1/3 | 2/5 | 0/1 | 3/61 | +1.00 | +0.83 | +0.63 | 3 |  |  |
| `web/src/ui/SectionHeader.tsx` | 15/19 | 12/35 | 0/2 | 20/95 | +0.22 | +0.97 | +1.26 | 16 | D high (hub) | artefact (revival 6, class 1) |
| `server/shared/datasets.js` | 6/3 | 7/48 | 0/0 | 9/388 | -0.63 | +1.75 | +0.00 | 45 | B high, leak signature | artefact (revival 1): the stem carries B |
| `spheres/schedule/ui/cards.tsx` | 1/3 | 2/3 | 1/3 | 3/8 | +1.00 | +0.37 | +1.00 | 0 |  |  |
| `web/src/pipeline/StagesEditor.tsx` | 1/2 | 3/5 | 1/4 | 4/22 | +0.63 | +0.46 | +1.26 | 3 | D high (hub) | artefact (revival 6, class 1) |
| `server/shared/job-runs.js` | 3/6 | 4/26 | 1/1 | 5/84 | +0.63 | +1.70 | +0.00 | 20 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/Overlay.tsx` | 8/11 | 6/27 | 0/1 | 10/102 | +0.29 | +1.37 | +0.63 | 16 | B high | artefact (revival 1): the stem carries B |
| `spheres/projects/ui/api.ts` | 2/2 | 3/12 | 1/3 | 5/136 | +0.00 | +1.26 | +1.00 | 10 | B high | artefact (revival 1): the stem carries B |
| `spheres/publicity/api/pipeline-fixture.js` | 0/0 | 3/18 | 1/2 | 4/34 | +0.00 | +1.63 | +0.63 | 18 | B high | artefact (revival 1): the stem carries B |
| `spheres/publicity/ui/CoverageSection.tsx` | 1/2 | 2/4 | 1/3 | 3/17 | +0.63 | +0.63 | +1.00 | 2 |  |  |
| `spheres/social/api/pipeline-fixture.js` | 0/0 | 3/18 | 1/2 | 4/34 | +0.00 | +1.63 | +0.63 | 18 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/boardDrag.ts` | 3/4 | 4/17 | 0/1 | 5/217 | +0.26 | +1.32 | +0.63 | 13 | B high | artefact (revival 1, batch) |
| `spheres/financial/ui/api.ts` | 4/9 | 4/10 | 1/2 | 7/47 | +0.74 | +0.83 | +0.63 | 4 |  |  |
| `web/src/ui/atoms.tsx` | 15/44 | 12/44 | 0/0 | 20/227 | +0.98 | +1.18 | +0.00 | 22 | B high | artefact (revival 1): the stem carries B |
| `server/shared/contract.js` | 10/1 | 8/2 | 2/0 | 14/40 | -2.10 | -1.26 | -1.26 | 1 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `spheres/coord/ui/views/Meetings.tsx` | 0/1 | 2/3 | 3/10 | 2/18 | +0.63 | +0.37 | +1.10 | 3 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/schedule/api/providers/local.js` | 1/4 | 2/5 | 1/0 | 3/30 | +1.26 | +0.83 | -0.63 | 3 | A high | by design: shared vocabulary read widely |
| `web/src/lib/slot-store.ts` | 2/7 | 4/11 | 0/0 | 5/114 | +1.14 | +0.92 | +0.00 | 4 | A high | by design: shared vocabulary read widely |
| `scripts/refresh-meta-recent.mjs` | 0/0 | 3/21 | 3/4 | 5/101 | +0.00 | +1.77 | +0.26 | 21 | B high | artefact (revival 1, batch) |
| `spheres/library/ui/SearchBar.tsx` | 2/2 | 3/4 | 1/7 | 5/27 | +0.00 | +0.26 | +1.77 | 2 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/schedule/ui/views/Pending.tsx` | 0/1 | 2/4 | 3/7 | 2/12 | +0.63 | +0.63 | +0.77 | 4 |  |  |
| `web/src/lib/view-registry.ts` | 5/8 | 6/17 | 0/1 | 10/99 | +0.43 | +0.95 | +0.63 | 9 |  |  |
| `server/shared/testdb.js` | 0/0 | 4/36 | 1/1 | 6/276 | +0.00 | +2.00 | +0.00 | 36 | B high | artefact (revival 1): the stem carries B |
| `spheres/social/ui/ContactDetail.tsx` | 1/1 | 2/10 | 5/9 | 3/26 | +0.00 | +1.46 | +0.54 | 9 | B high | artefact (revival 1): the stem carries B |
| `web/src/ui/useCardSelection.ts` | 2/3 | 3/9 | 0/1 | 4/18 | +0.37 | +1.00 | +0.63 | 6 |  |  |
| `spheres/financial/ui/views/Products.tsx` | 0/1 | 2/0 | 3/13 | 2/0 | +0.63 | -1.26 | +1.33 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/ui/PersonRow.tsx` | 5/3 | 5/13 | 0/1 | 8/41 | -0.46 | +0.87 | +0.63 | 10 |  |  |
| `spheres/financial/ui/fy.ts` | 2/1 | 3/3 | 0/2 | 5/63 | -0.63 | +0.00 | +1.26 | 2 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/projects/ui/views/Portfolio.tsx` | 0/1 | 2/0 | 3/12 | 2/0 | +0.63 | -1.26 | +1.26 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/relationships/ui/views/Matches.tsx` | 0/1 | 2/4 | 3/6 | 2/5 | +0.63 | +0.63 | +0.63 | 4 |  |  |
| `server/shared/access.js` | 8/1 | 12/1 | 3/2 | 25/8 | -1.89 | -2.26 | -0.37 | 1 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `agent/error-codes.js` | 2/2 | 4/31 | 0/0 | 6/63 | +0.00 | +1.86 | +0.00 | 29 | B high | artefact (revival 1): the stem carries B |
| `web/src/app/PrefsPanel.tsx` | 1/1 | 2/5 | 2/6 | 3/8 | +0.00 | +0.83 | +1.00 | 4 |  |  |
| `web/src/pipeline/Roster.tsx` | 2/3 | 4/3 | 2/10 | 6/3 | +0.37 | -0.26 | +1.46 | 2 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/ui/Chips.tsx` | 6/3 | 5/9 | 0/1 | 8/33 | -0.63 | +0.54 | +0.63 | 6 |  |  |
| `connectors/clover/sync.js` (B floor) | 0/0 | 2/0 | 1/7 | 3/0 | +0.00 | -1.26 | +1.77 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/deputy/sync.js` (B floor) | 0/0 | 2/0 | 1/7 | 3/0 | +0.00 | -1.26 | +1.77 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/github/sync.js` (B floor) | 0/0 | 2/0 | 1/7 | 3/0 | +0.00 | -1.26 | +1.77 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/rezdy/sync.js` (B floor) | 0/0 | 2/0 | 1/7 | 3/0 | +0.00 | -1.26 | +1.77 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/sonas/sync.js` (B floor) | 0/0 | 2/0 | 1/7 | 3/0 | +0.00 | -1.26 | +1.77 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/library/ui/ItemOverlay.tsx` | 1/2 | 3/2 | 2/7 | 5/6 | +0.63 | -0.37 | +1.14 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/library/ui/Results.tsx` | 2/3 | 3/7 | 3/6 | 5/19 | +0.37 | +0.77 | +0.63 | 4 |  |  |
| `spheres/schedule/ui/views/Week.tsx` | 0/1 | 2/0 | 4/14 | 2/0 | +0.63 | -1.26 | +1.14 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/social/ui/CampaignPipeline.tsx` | 1/2 | 2/7 | 3/3 | 2/44 | +0.63 | +1.14 | +0.00 | 5 | B high | artefact (revival 1, batch) |
| `web/src/ui/SearchInput.tsx` | 7/1 | 6/2 | 0/0 | 9/4 | -1.77 | -1.00 | +0.00 | 1 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/onedrive/api/graph-client.js` | 2/3 | 4/9 | 1/2 | 6/60 | +0.37 | +0.74 | +0.63 | 6 |  |  |
| `server/shared/ollama.js` | 1/2 | 3/10 | 1/1 | 4/27 | +0.63 | +1.10 | +0.00 | 8 | B high | artefact (revival 1): the stem carries B |
| `spheres/coord/ui/views/Board.tsx` | 0/1 | 2/0 | 3/10 | 2/0 | +0.63 | -1.26 | +1.10 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/relationships/ui/views/People.tsx` | 0/1 | 2/0 | 3/10 | 2/0 | +0.63 | -1.26 | +1.10 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/reputation/ui/views/NeedsReply.tsx` | 0/1 | 2/1 | 3/10 | 2/4 | +0.63 | -0.63 | +1.10 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/ui/Board.tsx` | 6/7 | 7/20 | 2/4 | 12/86 | +0.14 | +0.96 | +0.63 | 13 |  |  |
| `web/src/lib/error-codes.ts` | 6/9 | 7/31 | 0/0 | 9/125 | +0.37 | +1.35 | +0.00 | 22 | B high | artefact (revival 1): the stem carries B |
| `server/shared/anthropic.js` | 2/2 | 4/13 | 1/2 | 6/27 | +0.00 | +1.07 | +0.63 | 11 | B high | artefact (revival 1): the stem carries B |
| `web/src/lib/locale.ts` | 4/3 | 5/6 | 0/2 | 8/32 | -0.26 | +0.17 | +1.26 | 3 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/tiktok/api/insights-sync.js` | 1/1 | 4/25 | 4/2 | 6/49 | +0.00 | +1.67 | -0.63 | 24 | B high | artefact (revival 1): the stem carries B |
| `server/shared/error-codes.js` | 10/5 | 10/31 | 0/0 | 18/62 | -0.63 | +1.03 | +0.00 | 26 | B high, leak signature | artefact (revival 1): the stem carries B |
| `connectors/googlechat/sync.js` (B floor) | 0/0 | 2/0 | 1/6 | 3/0 | +0.00 | -1.26 | +1.63 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/googlereviews/sync.js` (B floor) | 0/0 | 2/0 | 1/6 | 3/0 | +0.00 | -1.26 | +1.63 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/xero/sync.js` (B floor) | 0/0 | 2/0 | 1/6 | 3/0 | +0.00 | -1.26 | +1.63 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/coord/ui/windows.tsx` | 2/2 | 3/2 | 0/3 | 5/8 | +0.00 | -0.37 | +1.63 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/publicity/api/instance.js` (B floor) | 1/0 | 3/0 | 1/3 | 4/0 | -0.63 | -1.63 | +1.00 | 0 |  |  |
| `spheres/publicity/api/policy.js` (B floor) | 1/3 | 3/0 | 0/1 | 3/0 | +1.00 | -1.63 | +0.63 | 0 |  |  |
| `spheres/social/ui/PeopleSection.tsx` | 1/1 | 2/4 | 4/12 | 3/13 | +0.00 | +0.63 | +1.00 | 3 |  |  |
| `web/src/app/AccessTenants.tsx` | 0/1 | 2/1 | 2/6 | 2/3 | +0.63 | -0.63 | +1.00 | 0 |  |  |
| `web/src/app/match.ts` | 3/6 | 4/6 | 0/1 | 4/29 | +0.63 | +0.37 | +0.63 | 1 |  |  |
| `web/src/app/spheres.ts` (B floor) | 1/2 | 3/0 | 1/3 | 5/0 | +0.63 | -1.63 | +1.00 | 0 |  |  |
| `web/src/lib/navigate.ts` | 8/8 | 9/4 | 0/3 | 15/8 | +0.00 | -0.74 | +1.63 | 2 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/lib/overseer.ts` | 1/2 | 2/3 | 0/1 | 3/5 | +0.63 | +0.37 | +0.63 | 1 |  |  |
| `web/src/pipeline/Campaigns.tsx` | 2/3 | 4/0 | 2/8 | 6/0 | +0.37 | -1.89 | +1.26 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/ui/highlight.ts` | 2/1 | 3/2 | 1/3 | 5/7 | -0.63 | -0.37 | +1.00 | 1 |  |  |
| `web/src/ui/HoverTip.tsx` | 5/1 | 6/7 | 0/0 | 8/16 | -1.46 | +0.14 | +0.00 | 6 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `scripts/import-meta-exports.mjs` | 0/0 | 4/23 | 5/4 | 6/103 | +0.00 | +1.59 | -0.20 | 23 | B high | artefact (revival 1, batch) |
| `connectors/instagram/api/insights-sync.js` | 1/1 | 5/28 | 4/2 | 8/102 | +0.00 | +1.57 | -0.63 | 27 | B high | artefact (revival 1): the stem carries B |
| `web/src/app/App.tsx` | 1/1 | 3/12 | 10/14 | 5/30 | +0.00 | +1.26 | +0.31 | 12 | B high | artefact (revival 1): the stem carries B |
| `spheres/customer-service/ui/views/Calls.tsx` | 0/1 | 2/0 | 4/11 | 2/0 | +0.63 | -1.26 | +0.92 | 0 |  |  |
| `web/src/app/ChatPane.tsx` | 1/1 | 2/11 | 2/2 | 3/28 | +0.00 | +1.55 | +0.00 | 10 | B high | artefact (revival 1): the stem carries B |
| `server/shared/click-log.js` | 1/1 | 3/16 | 1/0 | 3/33 | +0.00 | +1.52 | -0.63 | 15 | B high | artefact (revival 1): the stem carries B |
| `connectors/instagram/api/shortcode.js` | 2/3 | 4/14 | 0/0 | 6/131 | +0.37 | +1.14 | +0.00 | 11 | B high | artefact (revival 1): the stem carries B |
| `server/shared/hash.js` | 4/2 | 5/13 | 0/0 | 6/26 | -0.63 | +0.87 | +0.00 | 11 |  |  |
| `connectors/awsconnect/sync.js` (B floor) | 0/0 | 2/0 | 1/5 | 3/0 | +0.00 | -1.26 | +1.46 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `connectors/linkedin/api/memdb.js` | 0/0 | 3/15 | 0/0 | 4/25 | +0.00 | +1.46 | +0.00 | 15 | B high | artefact (revival 1): the stem carries B |
| `connectors/otter/api/memdb.js` | 0/0 | 3/15 | 0/0 | 4/24 | +0.00 | +1.46 | +0.00 | 15 | B high | artefact (revival 1): the stem carries B |
| `spheres/coord/ui/views/MeetingFollowUp.tsx` | 0/1 | 2/3 | 3/5 | 2/17 | +0.63 | +0.37 | +0.46 | 2 |  |  |
| `spheres/reputation/ui/ReviewCard.tsx` | 2/2 | 3/3 | 1/5 | 5/22 | +0.00 | +0.00 | +1.46 | 1 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/app/access-sections.ts` | 5/2 | 5/3 | 0/1 | 8/15 | -0.83 | -0.46 | +0.63 | 1 |  |  |
| `web/src/lib/org-identity.ts` | 2/3 | 3/5 | 0/1 | 4/14 | +0.37 | +0.46 | +0.63 | 3 |  |  |
| `web/src/ui/GroupedList.tsx` | 3/3 | 4/10 | 0/1 | 6/24 | +0.00 | +0.83 | +0.63 | 7 |  |  |
| `web/src/ui/FreshnessNote.tsx` | 7/11 | 8/25 | 1/1 | 11/65 | +0.41 | +1.04 | +0.00 | 14 | B high | artefact (revival 1): the stem carries B |
| `server/shared/spar-pipeline.js` | 5/5 | 8/39 | 4/4 | 14/105 | +0.00 | +1.44 | +0.00 | 34 | B high | artefact (revival 1): the stem carries B |
| `server/shared/job-claims.js` | 4/2 | 5/12 | 1/0 | 8/46 | -0.63 | +0.80 | -0.63 | 10 |  |  |
| `server/shared/connector-health.js` | 3/1 | 5/8 | 2/1 | 8/33 | -1.00 | +0.43 | -0.63 | 7 |  |  |
| `spheres/financial/ui/matrix.ts` | 2/2 | 3/7 | 0/1 | 5/55 | +0.00 | +0.77 | +0.63 | 5 |  |  |
| `spheres/reputation/ui/views/AllReviews.tsx` | 0/1 | 2/2 | 3/7 | 2/8 | +0.63 | +0.00 | +0.77 | 1 |  |  |
| `agent/system-prompt.js` | 1/1 | 2/9 | 0/0 | 3/10 | +0.00 | +1.37 | +0.00 | 8 | B high | artefact (revival 1): the stem carries B |
| `connectors/instagram/api/graph-client.js` | 2/1 | 4/9 | 1/1 | 6/10 | -0.63 | +0.74 | +0.00 | 8 |  |  |
| `spheres/financial/ui/letterhead.ts` | 2/3 | 3/3 | 1/3 | 3/14 | +0.37 | +0.00 | +1.00 | 0 |  |  |
| `web/src/lib/api.ts` | 15/34 | 16/32 | 1/1 | 25/142 | +0.74 | +0.63 | +0.00 | 9 |  |  |
| `connectors/xero/api/xero-client.js` | 2/2 | 4/17 | 1/1 | 6/56 | +0.00 | +1.32 | +0.00 | 15 | B high | artefact (revival 1, batch) |
| `web/src/lib/breakpoint.ts` | 4/3 | 5/16 | 0/0 | 6/38 | -0.26 | +1.06 | +0.00 | 13 | B high, leak signature | **scattered** (revival 7): the width itself, see pick-facts.md |
| `server/shared/db.js` | 25/44 | 16/38 | 1/0 | 35/104 | +0.51 | +0.79 | -0.63 | 15 |  |  |
| `connectors/awsconnect/api/aws-client.js` | 2/1 | 4/4 | 1/2 | 6/9 | -0.63 | +0.00 | +0.63 | 3 |  |  |
| `connectors/awsconnect/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/clover/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/deputy/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/dropbox/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/facebook/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/github/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/googlechat/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/googlereviews/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/instagram/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/linkedin/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/onedrive/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/otter/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/rezdy/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/sonas/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/spar/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/tiktok/api/tiktok-client.js` | 1/3 | 3/4 | 1/1 | 5/9 | +1.00 | +0.26 | +0.00 | 1 |  |  |
| `connectors/tiktok/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `connectors/xero/credentials.js` (B floor) | 2/0 | 4/0 | 0/0 | 5/0 | -1.26 | -1.89 | +0.00 | 0 | A low | artefact (revival 6, class 2): runtime discovery / dynamic import |
| `server/shared/deepseek.js` | 1/2 | 3/3 | 1/2 | 4/18 | +0.63 | +0.00 | +0.63 | 1 |  |  |
| `spheres/coord/api/read.js` | 1/2 | 4/8 | 4/3 | 7/29 | +0.63 | +0.63 | -0.26 | 8 |  |  |
| `spheres/financial/ui/export.ts` | 1/1 | 2/8 | 2/1 | 3/67 | +0.00 | +1.26 | -0.63 | 7 | B high | artefact (revival 1): the stem carries B |
| `spheres/financial/ui/views/Deals.tsx` (B floor) | 0/1 | 2/0 | 2/4 | 2/0 | +0.63 | -1.26 | +0.63 | 0 |  |  |
| `spheres/library/ui/views/Documents.tsx` (B floor) | 0/1 | 2/0 | 3/6 | 2/0 | +0.63 | -1.26 | +0.63 | 0 |  |  |
| `spheres/library/ui/views/Media.tsx` (B floor) | 0/1 | 2/0 | 3/6 | 2/0 | +0.63 | -1.26 | +0.63 | 0 |  |  |
| `spheres/publicity/ui/views/Campaigns.tsx` (B floor) | 0/1 | 2/0 | 2/4 | 2/0 | +0.63 | -1.26 | +0.63 | 0 |  |  |
| `spheres/publicity/ui/views/Roster.tsx` (B floor) | 0/1 | 2/0 | 2/4 | 2/0 | +0.63 | -1.26 | +0.63 | 0 |  |  |
| `spheres/reputation/ui/PlaceChips.tsx` | 2/2 | 3/2 | 1/4 | 5/10 | +0.00 | -0.37 | +1.26 | 0 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/schedule/api/instance.js` | 1/0 | 3/0 | 1/2 | 4/0 | -0.63 | -1.63 | +0.63 | 0 |  |  |
| `spheres/schedule/api/reconcile-logic.js` | 1/2 | 2/4 | 1/0 | 3/64 | +0.63 | +0.63 | -0.63 | 2 |  |  |
| `spheres/social/ui/perf-derive.ts` | 2/2 | 3/6 | 0/1 | 4/256 | +0.00 | +0.63 | +0.63 | 4 |  |  |
| `spheres/social/ui/sweep.ts` | 1/2 | 3/2 | 0/1 | 3/4 | +0.63 | -0.37 | +0.63 | 0 |  |  |
| `web/src/app/AccessRoles.tsx` | 0/1 | 2/3 | 3/4 | 2/5 | +0.63 | +0.37 | +0.26 | 2 |  |  |
| `web/src/lib/chat.ts` | 2/2 | 3/3 | 1/4 | 4/12 | +0.00 | +0.00 | +1.26 | 1 | D high (hub) | artefact (revival 6, class 1) |
| `web/src/lib/gesture-state.ts` | 2/1 | 4/2 | 0/1 | 4/6 | -0.63 | -0.63 | +0.63 | 1 |  |  |
| `web/src/lib/tool-labels.ts` | 1/1 | 2/8 | 0/0 | 3/38 | +0.00 | +1.26 | +0.00 | 7 | B high | artefact (revival 1): the stem carries B |
| `web/src/lib/format.ts` | 15/28 | 16/34 | 0/0 | 25/288 | +0.57 | +0.69 | +0.00 | 12 |  |  |
| `server/shared/sql-static.js` | 1/3 | 4/5 | 1/0 | 6/41 | +1.00 | +0.20 | -0.63 | 2 |  |  |
| `spheres/customer-service/ui/api.ts` | 1/1 | 3/11 | 1/0 | 4/175 | +0.00 | +1.18 | -0.63 | 10 | B high | artefact (revival 1): the stem carries B |
| `connectors/dropbox/api/dropbox-client.js` | 2/3 | 5/6 | 1/2 | 8/20 | +0.37 | +0.17 | +0.63 | 3 |  |  |
| `web/src/lib/grants.ts` | 3/6 | 4/7 | 0/0 | 6/47 | +0.63 | +0.51 | +0.00 | 2 |  |  |
| `scripts/import-env-credentials.mjs` | 0/0 | 2/1 | 2/7 | 3/1 | +0.00 | -0.63 | +1.14 | 1 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/schedule/reconcile.js` | 0/0 | 2/1 | 2/7 | 3/9 | +0.00 | -0.63 | +1.14 | 1 | D high (hub) | artefact (revival 6, class 1) |
| `spheres/schedule/api/moves.js` | 1/1 | 3/4 | 2/5 | 5/30 | +0.00 | +0.26 | +0.83 | 3 |  |  |
| `web/src/ui/DeepLink.tsx` | 8/8 | 9/29 | 2/1 | 11/73 | +0.00 | +1.07 | -0.63 | 21 | B high | artefact (revival 1): the stem carries B |
| `web/src/lib/assistant-runtime.ts` | 1/1 | 3/4 | 3/7 | 4/11 | +0.00 | +0.26 | +0.77 | 3 |  |  |
| `connectors/awsconnect/api/presign.js` | 1/2 | 2/3 | 1/1 | 3/12 | +0.63 | +0.37 | +0.00 | 1 |  |  |
| `connectors/dropbox/api/consent.js` (B floor) | 0/0 | 2/0 | 1/3 | 3/0 | +0.00 | -1.26 | +1.00 | 0 |  |  |
| `connectors/dropbox/api/probe.js` (B floor) | 0/0 | 2/0 | 1/3 | 3/0 | +0.00 | -1.26 | +1.00 | 0 |  |  |
| `connectors/facebook/api/graph-client.js` | 1/1 | 3/9 | 1/1 | 5/10 | +0.00 | +1.00 | +0.00 | 8 |  |  |
| `connectors/onedrive/api/consent.js` (B floor) | 0/0 | 2/0 | 1/3 | 3/0 | +0.00 | -1.26 | +1.00 | 0 |  |  |
| `connectors/onedrive/api/probe.js` (B floor) | 0/0 | 2/0 | 1/3 | 3/0 | +0.00 | -1.26 | +1.00 | 0 |  |  |
| `connectors/rezdy/api/rezdy-client.js` | 2/1 | 4/6 | 1/1 | 6/26 | -0.63 | +0.37 | +0.00 | 5 |  |  |
| `server/shared/model-api.js` | 3/1 | 4/4 | 3/2 | 5/12 | -1.00 | +0.00 | -0.37 | 3 |  |  |
| `server/shared/party.js` | 3/1 | 5/2 | 3/3 | 8/3 | -1.00 | -0.83 | +0.00 | 2 |  |  |
| `server/shared/trail.js` | 6/2 | 5/5 | 1/0 | 8/27 | -1.00 | +0.00 | -0.63 | 3 |  |  |
| `spheres/coord/reconstruct.js` (B floor) | 0/0 | 2/0 | 1/3 | 3/0 | +0.00 | -1.26 | +1.00 | 0 |  |  |
| `spheres/customer-service/api/transcripts.js` | 1/1 | 2/2 | 1/3 | 3/15 | +0.00 | +0.00 | +1.00 | 1 |  |  |
| `spheres/financial/ui/views/People.tsx` (B floor) | 0/1 | 2/0 | 2/3 | 2/0 | +0.63 | -1.26 | +0.37 | 0 |  |  |
| `spheres/partnership/ui/views/Campaigns.tsx` (B floor) | 0/1 | 2/0 | 2/3 | 2/0 | +0.63 | -1.26 | +0.37 | 0 |  |  |
| `spheres/partnership/ui/views/Roster.tsx` (B floor) | 0/1 | 2/0 | 2/3 | 2/0 | +0.63 | -1.26 | +0.37 | 0 |  |  |
| `spheres/schedule/api/providers/index.js` (B floor) | 1/3 | 2/0 | 3/3 | 3/0 | +1.00 | -1.26 | +0.00 | 0 |  |  |
| `spheres/schedule/ui/ConfirmMove.tsx` | 1/1 | 2/4 | 2/3 | 3/23 | +0.00 | +0.63 | +0.37 | 3 |  |  |
| `spheres/social/ui/CampaignDelete.tsx` | 2/2 | 3/3 | 1/3 | 5/21 | +0.00 | +0.00 | +1.00 | 1 |  |  |
| `spheres/social/ui/drafts.tsx` | 1/1 | 3/1 | 2/6 | 3/3 | +0.00 | -1.00 | +1.00 | 0 |  |  |
| `web/src/app/AccessGrants.tsx` | 3/2 | 4/2 | 1/2 | 6/18 | -0.37 | -0.63 | +0.63 | 0 |  |  |
| `web/src/app/AccessWalls.tsx` | 0/1 | 2/2 | 2/3 | 2/4 | +0.63 | +0.00 | +0.37 | 1 |  |  |
| `web/src/app/chat-icon.tsx` | 3/1 | 4/1 | 0/0 | 5/4 | -1.00 | -1.26 | +0.00 | 0 |  |  |
| `web/src/lib/use-anchor.ts` | 3/2 | 4/2 | 1/2 | 4/8 | -0.37 | -0.63 | +0.63 | 0 |  |  |
| `web/src/ui/FilterRow.tsx` | 3/3 | 4/12 | 0/0 | 6/31 | +0.00 | +1.00 | +0.00 | 9 |  |  |
| `server/shared/db-errors.js` | 4/7 | 5/8 | 0/0 | 6/9 | +0.51 | +0.43 | +0.00 | 1 |  |  |
| `connectors/instagram/api/jobs.js` | 2/3 | 6/11 | 3/2 | 10/61 | +0.37 | +0.55 | -0.37 | 10 |  |  |
| `scripts/stage-flip-harness.mjs` | 0/0 | 3/5 | 3/5 | 4/5 | +0.00 | +0.46 | +0.46 | 5 |  |  |
| `agent/tools.js` | 1/1 | 3/8 | 1/1 | 5/58 | +0.00 | +0.89 | +0.00 | 7 |  |  |
| `connectors/awsconnect/api/sigv4.js` | 2/2 | 3/8 | 0/0 | 5/47 | +0.00 | +0.89 | +0.00 | 6 |  |  |
| `connectors/googlereviews/api/import-historical.js` | 1/1 | 3/8 | 2/1 | 4/15 | +0.00 | +0.89 | -0.63 | 7 |  |  |
| `server/shared/secret-box.js` | 2/2 | 3/8 | 0/0 | 4/14 | +0.00 | +0.89 | +0.00 | 6 |  |  |
| `server/shared/tenancy.js` | 8/6 | 8/16 | 1/1 | 12/61 | -0.26 | +0.63 | +0.00 | 11 |  |  |
| `spheres/schedule/api/valid.js` | 2/4 | 3/4 | 0/0 | 5/21 | +0.63 | +0.26 | +0.00 | 0 |  |  |
| `spheres/social/ui/CampaignWizard.tsx` | 1/1 | 2/2 | 3/8 | 3/4 | +0.00 | +0.00 | +0.89 | 1 |  |  |
| `web/src/app/AccessApps.tsx` | 0/1 | 2/2 | 3/4 | 2/8 | +0.63 | +0.00 | +0.26 | 1 |  |  |
| `web/src/app/AccessPeople.tsx` | 0/1 | 2/2 | 3/4 | 2/4 | +0.63 | +0.00 | +0.26 | 1 |  |  |
| `spheres/projects/api/derive.js` | 1/1 | 2/5 | 0/0 | 3/68 | +0.00 | +0.83 | +0.00 | 4 |  |  |
| `spheres/social/ui/CampaignsSection.tsx` | 1/1 | 2/1 | 4/10 | 3/4 | +0.00 | -0.63 | +0.83 | 0 |  |  |
| `server/shared/manifest.js` | 4/2 | 5/6 | 1/0 | 6/26 | -0.63 | +0.17 | -0.63 | 4 |  |  |
| `server/shared/stage-vocabulary.js` | 3/4 | 5/9 | 1/0 | 7/29 | +0.26 | +0.54 | -0.63 | 5 |  |  |
| `spheres/financial/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 5/6 | 3/0 | -0.63 | -1.26 | +0.17 | 0 |  |  |
| `web/src/ui/SelectableCard.tsx` | 4/3 | 5/9 | 0/0 | 7/34 | -0.26 | +0.54 | +0.00 | 6 |  |  |
| `connectors/sonas/api/sonas-client.js` | 2/3 | 4/6 | 1/0 | 6/56 | +0.37 | +0.37 | -0.63 | 4 |  |  |
| `spheres/coord/api/jobs-a.js` | 1/1 | 4/9 | 4/3 | 6/20 | +0.00 | +0.74 | -0.26 | 8 |  |  |
| `agent/drive-tools.js` | 1/1 | 4/8 | 2/0 | 6/26 | +0.00 | +0.63 | -1.26 | 7 |  |  |
| `connectors/awsconnect/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/clover/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/deputy/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/github/hook.js` | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/googlechat/api/sync.js` | 2/1 | 4/1 | 4/1 | 6/5 | -0.63 | -1.26 | -1.26 | 1 |  |  |
| `connectors/googlechat/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/googlereviews/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/instagram/jobs.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `connectors/linkedin/jobs.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `connectors/otter/api/jobs.js` | 1/2 | 5/1 | 2/2 | 8/18 | +0.63 | -1.46 | +0.00 | 1 |  |  |
| `connectors/otter/jobs.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `connectors/rezdy/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/sonas/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `connectors/spar/api/parse.js` | 2/1 | 4/2 | 0/0 | 6/45 | -0.63 | -0.63 | +0.00 | 1 |  |  |
| `connectors/square/import.js` (B floor) | 0/0 | 2/0 | 2/4 | 3/0 | +0.00 | -1.26 | +0.63 | 0 |  |  |
| `connectors/xero/hook.js` (B floor) | 1/0 | 3/0 | 3/1 | 4/0 | -0.63 | -1.63 | -1.00 | 0 |  |  |
| `scripts/deploy-skills.mjs` | 0/0 | 3/4 | 2/3 | 4/6 | +0.00 | +0.26 | +0.37 | 4 |  |  |
| `server/shared/closure.js` | 2/1 | 3/3 | 2/0 | 5/39 | -0.63 | +0.00 | -1.26 | 2 |  |  |
| `server/shared/contract-helpers.js` | 8/4 | 6/5 | 1/0 | 10/68 | -0.63 | -0.17 | -0.63 | 1 |  |  |
| `server/shared/events.js` | 2/1 | 4/1 | 1/0 | 6/6 | -0.63 | -1.26 | -0.63 | 1 |  |  |
| `server/shared/grants.js` | 6/3 | 8/6 | 1/1 | 12/141 | -0.63 | -0.26 | +0.00 | 5 |  |  |
| `server/shared/venue-date.js` | 5/6 | 6/10 | 0/0 | 8/54 | +0.17 | +0.46 | +0.00 | 4 |  |  |
| `server/shared/versions.js` | 2/1 | 4/2 | 0/0 | 4/15 | -0.63 | -0.63 | +0.00 | 1 |  |  |
| `spheres/coord/api/decode.js` | 2/1 | 3/2 | 1/0 | 5/70 | -0.63 | -0.37 | -0.63 | 1 |  |  |
| `spheres/coord/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 4/4 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/customer-service/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/customer-service/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 2/2 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/financial/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/financial/api/statements.js` (B floor) | 1/0 | 2/0 | 1/0 | 3/0 | -0.63 | -1.26 | -0.63 | 0 |  |  |
| `spheres/financial/ui/labour-matrix.ts` | 1/1 | 2/2 | 0/1 | 3/46 | +0.00 | +0.00 | +0.63 | 1 |  |  |
| `spheres/financial/ui/window.ts` | 2/1 | 3/2 | 1/1 | 5/20 | -0.63 | -0.37 | +0.00 | 1 |  |  |
| `spheres/library/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/library/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/3 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/partnership/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/partnership/api/policy.js` (B floor) | 1/1 | 2/0 | 0/1 | 3/0 | +0.00 | -1.26 | +0.63 | 0 |  |  |
| `spheres/partnership/api/statements.js` (B floor) | 1/0 | 2/0 | 1/0 | 3/0 | -0.63 | -1.26 | -0.63 | 0 |  |  |
| `spheres/partnership/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/3 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/projects/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/projects/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/2 | 3/0 | -0.63 | -1.26 | -0.37 | 0 |  |  |
| `spheres/publicity/api/jobs.js` | 1/1 | 3/4 | 2/3 | 5/8 | +0.00 | +0.26 | +0.37 | 3 |  |  |
| `spheres/publicity/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/3 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/relationships/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/relationships/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/3 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/relationships/ui/views/PersonPanel.tsx` | 1/1 | 2/1 | 3/6 | 3/7 | +0.00 | -0.63 | +0.63 | 0 |  |  |
| `spheres/reputation/api/instance.js` (B floor) | 1/0 | 3/0 | 1/1 | 4/0 | -0.63 | -1.63 | +0.00 | 0 |  |  |
| `spheres/reputation/ui/lanes.ts` | 1/1 | 2/2 | 0/1 | 3/28 | +0.00 | +0.00 | +0.63 | 1 |  |  |
| `spheres/reputation/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 3/3 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/schedule/api/almanac.js` | 1/2 | 3/3 | 2/2 | 5/45 | +0.63 | +0.00 | +0.00 | 2 |  |  |
| `spheres/schedule/ui/slots.tsx` | 1/1 | 2/2 | 1/2 | 3/10 | +0.00 | +0.00 | +0.63 | 1 |  |  |
| `spheres/schedule/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 4/4 | 3/0 | -0.63 | -1.26 | +0.00 | 0 |  |  |
| `spheres/social/api/statements.js` | 1/2 | 2/1 | 1/0 | 3/2 | +0.63 | -0.63 | -0.63 | 0 |  |  |
| `spheres/social/ui/sphere.tsx` (B floor) | 1/0 | 2/0 | 6/4 | 3/0 | -0.63 | -1.26 | -0.37 | 0 |  |  |
| `spheres/social/ui/useAutoSweep.ts` | 1/1 | 3/2 | 1/2 | 3/4 | +0.00 | -0.37 | +0.63 | 1 |  |  |
| `spheres/social/ui/useUnreadNotifier.ts` | 1/1 | 3/1 | 1/2 | 3/3 | +0.00 | -1.00 | +0.63 | 0 |  |  |
| `web/src/lib/chat-store.ts` | 2/1 | 3/3 | 1/0 | 4/12 | -0.63 | +0.00 | -0.63 | 2 |  |  |
| `web/src/lib/useDoorbell.ts` | 2/1 | 3/3 | 1/0 | 5/5 | -0.63 | +0.00 | -0.63 | 2 |  |  |
| `web/src/main.tsx` (B floor) | 0/0 | 2/0 | 1/2 | 3/0 | +0.00 | -1.26 | +0.63 | 0 |  |  |
| `web/src/vite-env.d.ts` | 0/1 | 2/0 | 0/0 | 2/0 | +0.63 | -1.26 | +0.00 | 0 |  |  |
| `server/shared/credential-manifests.js` | 3/2 | 4/5 | 1/0 | 6/27 | -0.37 | +0.20 | -0.63 | 3 |  |  |
| `server/shared/walls.js` | 5/4 | 6/9 | 1/1 | 10/45 | -0.20 | +0.37 | +0.00 | 5 |  |  |
| `web/src/app/Access.tsx` (B floor) | 1/1 | 3/0 | 6/11 | 5/0 | +0.00 | -1.63 | +0.55 | 0 |  |  |
| `spheres/projects/api/read.js` | 1/1 | 3/3 | 4/7 | 5/10 | +0.00 | +0.00 | +0.51 | 3 |  |  |
| `connectors/deputy/api/deputy-client.js` | 1/1 | 3/5 | 1/1 | 5/15 | +0.00 | +0.46 | +0.00 | 4 |  |  |
| `connectors/googlechat/api/chat-client.js` | 1/1 | 3/5 | 1/1 | 5/7 | +0.00 | +0.46 | +0.00 | 4 |  |  |
| `spheres/customer-service/api/read.js` | 1/1 | 3/1 | 3/5 | 5/6 | +0.00 | -1.00 | +0.46 | 1 |  |  |
| `spheres/schedule/api/read.js` | 1/1 | 3/2 | 6/10 | 6/8 | +0.00 | -0.37 | +0.46 | 2 |  |  |
| `web/src/app/chat-handle.tsx` | 2/2 | 3/5 | 1/1 | 3/21 | +0.00 | +0.46 | +0.00 | 3 |  |  |
| `server/shared/model-retry.js` | 3/2 | 4/2 | 0/0 | 5/8 | -0.37 | -0.63 | +0.00 | 0 |  |  |
| `spheres/library/api/providers.js` | 1/1 | 3/0 | 2/3 | 5/0 | +0.00 | -1.63 | +0.37 | 0 |  |  |
| `spheres/social/ui/PerformanceChart.tsx` | 1/1 | 2/1 | 2/3 | 3/5 | +0.00 | -0.63 | +0.37 | 0 |  |  |
| `web/src/lib/chat-starters.ts` | 1/1 | 2/3 | 0/0 | 3/8 | +0.00 | +0.37 | +0.00 | 2 |  |  |
| `spheres/social/api/read.js` | 1/1 | 4/5 | 6/7 | 8/9 | +0.00 | +0.20 | +0.14 | 5 |  |  |
| `spheres/financial/api/read.js` | 1/1 | 4/3 | 5/7 | 7/18 | +0.00 | -0.26 | +0.31 | 3 |  |  |
| `connectors/clover/api/clover-client.js` | 1/1 | 3/4 | 1/1 | 5/14 | +0.00 | +0.26 | +0.00 | 3 |  |  |
| `connectors/github/api/github-client.js` | 1/1 | 3/4 | 1/1 | 5/12 | +0.00 | +0.26 | +0.00 | 3 |  |  |
| `connectors/googlereviews/api/serpapi-client.js` | 1/1 | 3/4 | 1/1 | 5/16 | +0.00 | +0.26 | +0.00 | 3 |  |  |
| `connectors/spar/sync.js` | 0/0 | 3/0 | 3/4 | 5/0 | +0.00 | -1.63 | +0.26 | 0 |  |  |
| `spheres/coord/capture.js` | 2/2 | 3/4 | 0/0 | 5/12 | +0.00 | +0.26 | +0.00 | 2 |  |  |
| `spheres/library/api/read.js` | 1/1 | 3/1 | 3/4 | 5/9 | +0.00 | -1.00 | +0.26 | 1 |  |  |
| `connectors/linkedin/api/jobs.js` | 1/1 | 4/5 | 2/2 | 6/52 | +0.00 | +0.20 | +0.00 | 5 |  |  |
| `scripts/import-otter-corpus.mjs` | 0/0 | 4/5 | 4/3 | 6/61 | +0.00 | +0.20 | -0.26 | 5 |  |  |
| `spheres/relationships/api/read.js` | 1/1 | 3/0 | 4/5 | 5/0 | +0.00 | -1.63 | +0.20 | 0 |  |  |
| `server/shared/http-raw.js` | 20/18 | 21/20 | 0/0 | 30/35 | -0.10 | -0.04 | +0.00 | 2 |  |  |
| `server/shared/dispatch.js` (B floor) | 13/12 | 10/0 | 3/3 | 18/0 | -0.07 | -2.73 | +0.00 | 0 |  |  |
| `agent/server.js` | 0/0 | 8/2 | 6/5 | 14/2 | +0.00 | -1.26 | -0.17 | 2 |  |  |
| `agent/transcribe.js` | 1/1 | 3/1 | 2/0 | 4/4 | +0.00 | -1.00 | -1.26 | 0 |  |  |
| `connectors/clover/api/sync.js` | 1/1 | 4/1 | 4/0 | 6/1 | +0.00 | -1.26 | -1.89 | 1 |  |  |
| `connectors/deputy/api/sync.js` | 1/1 | 4/2 | 4/0 | 6/10 | +0.00 | -0.63 | -1.89 | 2 |  |  |
| `connectors/github/api/formats.js` (B floor) | 1/1 | 2/0 | 0/0 | 3/0 | +0.00 | -1.26 | +0.00 | 0 |  |  |
| `connectors/github/api/sync.js` | 1/1 | 4/0 | 4/0 | 6/0 | +0.00 | -1.89 | -1.89 | 0 |  |  |
| `connectors/googlereviews/api/sync.js` | 1/1 | 4/3 | 4/1 | 6/6 | +0.00 | -0.26 | -1.26 | 3 |  |  |
| `connectors/rezdy/api/sync.js` | 1/1 | 4/0 | 4/0 | 6/0 | +0.00 | -1.89 | -1.89 | 0 |  |  |
| `connectors/sonas/api/sync.js` | 1/1 | 4/0 | 4/0 | 6/0 | +0.00 | -1.89 | -1.89 | 0 |  |  |
| `connectors/square/api/square-client.js` | 1/1 | 3/2 | 1/1 | 5/6 | +0.00 | -0.37 | +0.00 | 1 |  |  |
| `connectors/xero/api/sync.js` | 1/1 | 4/0 | 4/1 | 6/0 | +0.00 | -1.89 | -1.26 | 0 |  |  |
| `server/app.js` | 0/0 | 15/5 | 25/16 | 40/8 | +0.00 | -1.00 | -0.41 | 5 |  |  |
| `server/shared/chat.js` | 1/1 | 3/3 | 3/3 | 5/17 | +0.00 | +0.00 | +0.00 | 2 |  |  |
| `server/shared/freshness.js` (B floor) | 5/5 | 6/0 | 1/0 | 10/0 | +0.00 | -2.26 | -0.63 | 0 |  |  |
| `spheres/coord/api/jobs.js` | 1/1 | 3/2 | 3/2 | 5/20 | +0.00 | -0.37 | -0.37 | 1 |  |  |
| `spheres/coord/api/meetings.js` | 1/1 | 3/3 | 1/1 | 5/51 | +0.00 | +0.00 | +0.00 | 2 |  |  |
| `spheres/customer-service/api/calls.js` | 1/1 | 3/2 | 2/2 | 5/12 | +0.00 | -0.37 | +0.00 | 1 |  |  |
| `spheres/customer-service/api/policy.js` | 1/1 | 2/1 | 0/0 | 3/4 | +0.00 | -0.63 | +0.00 | 1 |  |  |
| `spheres/financial/api/policy.js` | 1/1 | 2/2 | 0/0 | 3/4 | +0.00 | +0.00 | +0.00 | 1 |  |  |
| `spheres/financial/ui/PeriodPicker.tsx` | 3/3 | 4/4 | 2/2 | 6/14 | +0.00 | +0.00 | +0.00 | 1 |  |  |
| `spheres/library/api/hits.js` | 2/2 | 3/3 | 0/0 | 5/41 | +0.00 | +0.00 | +0.00 | 2 |  |  |
| `spheres/partnership/api/read.js` (B floor) | 1/1 | 3/0 | 3/3 | 5/0 | +0.00 | -1.63 | +0.00 | 0 |  |  |
| `spheres/partnership/ui/api.ts` (B floor) | 2/2 | 3/0 | 1/1 | 5/0 | +0.00 | -1.63 | +0.00 | 0 |  |  |
| `spheres/projects/api/policy.js` (B floor) | 1/1 | 2/0 | 0/0 | 3/0 | +0.00 | -1.26 | +0.00 | 0 |  |  |
| `spheres/projects/api/statements.js` | 1/1 | 2/1 | 1/0 | 3/11 | +0.00 | -0.63 | -0.63 | 0 |  |  |
| `spheres/publicity/api/read.js` | 1/1 | 3/1 | 3/3 | 5/5 | +0.00 | -1.00 | +0.00 | 1 |  |  |
| `spheres/publicity/api/statements.js` (B floor) | 1/1 | 2/0 | 1/0 | 3/0 | +0.00 | -1.26 | -0.63 | 0 |  |  |
| `spheres/relationships/api/identity.js` | 1/1 | 3/2 | 1/0 | 5/66 | +0.00 | -0.37 | -0.63 | 1 |  |  |
| `spheres/reputation/api/policy.js` (B floor) | 1/1 | 2/0 | 0/0 | 3/0 | +0.00 | -1.26 | +0.00 | 0 |  |  |
| `spheres/reputation/api/read.js` | 1/1 | 3/0 | 3/2 | 5/0 | +0.00 | -1.63 | -0.37 | 0 |  |  |
| `spheres/schedule/ui/EntryEditor.tsx` | 1/1 | 2/2 | 2/2 | 3/9 | +0.00 | +0.00 | +0.00 | 1 |  |  |
| `spheres/social/api/jobs.js` | 1/1 | 4/3 | 4/4 | 7/4 | +0.00 | -0.26 | +0.00 | 2 |  |  |
| `spheres/social/api/performance.js` | 1/1 | 3/3 | 2/1 | 5/27 | +0.00 | +0.00 | -0.63 | 2 |  |  |
| `web/src/lib/download.ts` | 1/1 | 3/2 | 0/0 | 4/6 | +0.00 | -0.37 | +0.00 | 1 |  |  |
| `web/src/lib/stream.ts` | 2/2 | 4/2 | 0/0 | 5/16 | +0.00 | -0.63 | +0.00 | 0 |  |  |

| module | A exp/meas | B exp/meas | D exp/meas | C exp/meas | gap A | gap B | gap D | flags | disposition |
|---|---|---|---|---|---|---|---|---|---|
| `spheres/social/ui/api.ts` | 3.0/15 | 6.0/61 | 3.0/3 | 10.5/457 | +1.46 | +2.11 | +0.00 | A high, B high | by design (triage) — in-sphere fan-out; "tiktok" homonym adds to B |
| `spheres/schedule/api/providers/rezdy.js` | 2.0/1 | 3.5/72 | 4.0/1 | 5.5/275 | -0.63 | +2.75 | -1.26 | B high, leak signature | artefact (revival e1) — the stem `rezdy` conflates this module with the connector of the same name |
| `web/src/pipeline/api.ts` | 6.0/16 | 8.5/99 | 4.0/3 | 17.0/1161 | +0.89 | +2.23 | -0.26 | B high | by design (revival e1) — shared spar-pipeline client; but see report §1, the write side of the same vocabulary |
| `web/src/ui/ReachNote.tsx` | 8.0/30 | 10.0/43 | 2.0/3 | 16.0/169 | +1.20 | +1.33 | +0.37 | A high, B high | by design (triage) — banner mounted on nearly every sphere view |
| `connectors/awsconnect/api/sync.js` | 1.5/13 | 5.0/11 | 3.5/0 | 8.0/30 | +1.97 | +0.72 | -1.77 | A high | by design (triage) — job-listing convention shared with desktop job tooling |
| `spheres/social/api/instance.js` | 1.0/0 | 2.5/20 | 2.5/3 | 4.5/66 | -0.63 | +1.89 | +0.17 | B high, leak signature | by design (triage) — sibling `instance.js` interface (`loadVocab`) |
| `web/src/lib/url-state.ts` | 7.5/20 | 9.0/30 | 1.5/3 | 15.0/132 | +0.89 | +1.10 | +0.63 | B high | by design (triage) — platform URL-state hook |
| `server/shared/http-json.js` | 17.5/1 | 16.5/3 | 1.5/1 | 35.0/8 | -2.61 | -1.55 | -0.37 | A low | artefact (triage) — dynamic `import()` in server/app.js |
| `web/src/app/AuthGate.tsx` | 2.0/6 | 4.0/19 | 5.0/6 | 6.5/69 | +1.00 | +1.42 | +0.17 | B high | by design (triage) — app-wide auth context |
| `spheres/social/ui/Rolodex.tsx` | 2.0/3 | 4.5/14 | 3.0/11 | 11.0/106 | +0.37 | +1.03 | +1.18 | B high, D high (hub) | by design (triage) — container/child split, documented in the file's comment |
| `server/shared/credentials.js` | 6.5/24 | 9.0/38 | 4.0/4 | 15.0/145 | +1.19 | +1.31 | +0.00 | A high, B high | by design (triage) — credential kit called by every connector |
| `spheres/financial/ui/views/ProfitAndLoss.tsx` | 0.5/1 | 3.0/6 | 5.0/19 | 4.5/14 | +0.63 | +0.63 | +1.22 | D high (hub) | by design (revival e2) — glue: kit and sibling imports, no arithmetic of its own |
| `spheres/financial/ui/views/Labour.tsx` | 1.0/1 | 2.5/14 | 6.0/15 | 3.5/30 | +0.00 | +1.57 | +0.83 | B high | artefact (triage) — "Labour" is a generic domain word |
| `server/shared/ready.js` | 7.5/1 | 11.5/19 | 5.0/1 | 22.0/122 | -1.83 | +0.46 | -1.46 | A low | artefact (triage) — same |
| `spheres/social/ui/cards.tsx` | 1.5/4 | 3.0/8 | 3.5/6 | 5.5/34 | +0.89 | +0.89 | +0.49 |  |  |
| `server/shared/datasets.js` | 7.5/3 | 10.0/48 | 1.5/0 | 18.0/388 | -0.83 | +1.43 | -1.00 | B high, leak signature | artefact (revival e3) — homonym: the `datasets:` route-spec key belongs to dispatch.js |
| `server/shared/testdb.js` | 0.0/0 | 3.0/36 | 1.5/1 | 4.5/276 | +0.00 | +2.26 | -0.37 | B high | by design (triage) — shared test-transaction helper |
| `spheres/coord/prelink.js` | 2.5/0 | 4.5/9 | 2.5/3 | 7.0/28 | -1.46 | +0.63 | +0.17 | A low | by design (triage) — coord's own sibling helper |
| `spheres/social/ui/components.tsx` | 1.0/6 | 3.0/6 | 4.0/4 | 6.0/66 | +1.63 | +0.63 | +0.00 | A high | by design (triage) — sphere's own UI-kit file, leak = 0 |
| `server/shared/auth.js` | 14.5/3 | 23.5/44 | 7.0/9 | 57.5/230 | -1.43 | +0.57 | +0.23 | A low | artefact (revival e3) — dynamic import() in server/app.js hides its consumers |
| `server/shared/runbook.js` | 3.5/4 | 6.0/60 | 3.0/0 | 10.0/311 | +0.12 | +2.10 | -1.63 | B high | by design (revival e2) — prose, manifests and the sibling Tcl tier |
| `spheres/publicity/ui/api.ts` | 5.0/3 | 8.0/54 | 4.0/2 | 10.0/168 | -0.46 | +1.74 | -0.63 | B high, leak signature | artefact (triage) — "created_at" generic column, not the Coverage concept |
| `spheres/relationships/ui/api.ts` | 3.0/3 | 6.5/73 | 4.5/1 | 12.0/422 | +0.00 | +2.20 | -1.37 | B high | artefact (revival e3) — `linkedin` names the connector, not this type |
| `web/src/app/ChatAssistant.tsx` | 1.0/0 | 3.0/9 | 6.5/12 | 5.5/17 | -0.63 | +1.00 | +0.56 |  |  |
| `web/src/lib/auth.ts` | 9.0/11 | 12.0/109 | 4.5/2 | 22.0/590 | +0.18 | +2.01 | -0.74 | B high | by design (revival e1) — Access-admin wire surface mirroring a schema-wide provenance convention |
| `web/src/ui/HoverTip.tsx` | 11.0/1 | 13.5/7 | 1.0/0 | 20.0/16 | -2.18 | -0.60 | -0.63 | A low | by design (triage) — tooltip kit reused (Rolodex) |
| `spheres/social/ui/CampaignBoard.tsx` | 2.0/1 | 4.5/0 | 3.0/16 | 10.0/0 | -0.63 | -2.00 | +1.52 | D high (hub) | by design (revival e2) — kit composition; B=0 is the vocabulary floor |
| `web/src/ui/highlight.ts` | 8.5/1 | 11.5/2 | 2.5/3 | 15.5/7 | -1.95 | -1.59 | +0.17 | A low | by design (triage) — narrow: 1 cross-tier caller |
| `server/shared/access.js` | 9.5/1 | 14.0/1 | 5.0/2 | 26.5/8 | -2.05 | -2.40 | -0.83 | A low | by design (triage) — single chokepoint (dispatch.js), rest is prose |
| `server/shared/connector-tenant.js` | 7.0/21 | 9.5/30 | 2.0/1 | 15.5/66 | +1.00 | +1.05 | -0.63 | B high | by design (triage) — `tenantOf` called by every connector `sync.js` |
| `server/shared/contract.js` | 9.5/1 | 12.5/2 | 3.5/0 | 22.0/40 | -2.05 | -1.67 | -1.77 | A low | artefact (triage) — same |
| `server/shared/sync-runs.js` | 12.0/26 | 15.0/65 | 3.5/1 | 27.5/259 | +0.70 | +1.33 | -1.14 | B high | by design (triage) — sync-run kit called by every connector hook/sync |
| `spheres/coord/api/instance.js` | 1.0/0 | 2.5/11 | 3.0/3 | 4.5/26 | -0.63 | +1.35 | +0.00 | B high, leak signature | by design (triage) — same interface; `prelink` lives in coord's own `prelink.js` |
| `spheres/coord/ui/views/ByPerson.tsx` | 0.5/2 | 2.5/3 | 5.5/10 | 3.5/8 | +1.26 | +0.17 | +0.54 | A high | by design (triage) — trivial in-sphere view registration |
| `web/src/ui/SearchInput.tsx` | 8.0/1 | 11.5/2 | 1.0/0 | 18.5/4 | -1.89 | -1.59 | -0.63 | A low | by design (triage) — small kit input reused by SearchBar |
| `spheres/schedule/reconcile.js` | 2.5/0 | 5.0/1 | 4.5/7 | 8.0/9 | -1.46 | -1.46 | +0.40 | A low | by design (triage) — sealed, only its own test |
| `spheres/financial/ui/period.ts` | 1.5/5 | 3.5/8 | 3.0/2 | 6.0/63 | +1.10 | +0.75 | -0.37 | A high | by design (triage) — in-sphere fan-out |
| `spheres/schedule/ui/api.ts` | 4.0/7 | 6.5/28 | 3.5/2 | 10.0/212 | +0.51 | +1.33 | -0.51 | B high | by design (triage) — in-sphere fan-out |
| `server/shared/click-log.js` | 2.0/1 | 4.0/15 | 1.0/0 | 5.5/32 | -0.63 | +1.20 | -0.63 | B high, leak signature | by design (triage) — prose + cross-tier naming twin (web/lib/clicklog.ts) |
| `spheres/customer-service/ui/api.ts` | 5.0/1 | 7.5/11 | 4.0/0 | 12.5/175 | -1.46 | +0.35 | -1.89 | A low | by design (triage) — in-sphere + shared field names with its AWS Connect source |
| `spheres/social/ui/ContactDetail.tsx` | 2.0/1 | 4.0/8 | 5.0/9 | 8.5/20 | -0.63 | +0.63 | +0.54 |  |  |
| `web/src/lib/journey.ts` | 4.0/11 | 6.5/17 | 3.0/1 | 11.0/110 | +0.92 | +0.88 | -1.00 |  |  |
| `scripts/refresh-meta-recent.mjs` | 0.0/0 | 3.0/21 | 6.0/4 | 3.5/101 | +0.00 | +1.77 | -0.37 | B high | artefact (triage) — desktop/*.tcl overseer tier, unindexed |
| `web/src/app/spheres.ts` | 9.0/2 | 11.5/0 | 2.0/3 | 18.0/0 | -1.37 | -2.85 | +0.37 | A low | artefact (triage) — no distinctive vocabulary (B floor) |
| `server/shared/pipeline-fixture.js` | 0.0/2 | 3.0/5 | 3.0/1 | 4.5/24 | +1.26 | +0.46 | -1.00 | A high | by design (triage) — kit composed once per sphere (social/publicity) |
| `spheres/coord/ui/api.ts` | 3.5/5 | 6.0/28 | 4.5/2 | 11.0/137 | +0.32 | +1.40 | -0.74 | B high | by design (triage) — in-sphere fan-out |
| `scripts/import-meta-exports.mjs` | 0.0/0 | 3.5/23 | 8.0/4 | 4.5/103 | +0.00 | +1.71 | -0.63 | B high | by design (triage) — mostly its own test file |
| `connectors/instagram/api/shortcode.js` | 2.0/3 | 3.0/13 | 1.0/0 | 5.0/127 | +0.37 | +1.33 | -0.63 | B high | by design (triage) — serves the Meta ingestion pipeline it was built for |
| `spheres/projects/ui/views/Gantt.tsx` | 1.0/1 | 2.5/8 | 4.5/9 | 6.5/30 | +0.00 | +1.06 | +0.63 | B high | artefact (triage) — "Gantt" is a generic chart-type name |
| `web/src/ui/FilterBar.tsx` | 6.5/2 | 9.5/18 | 2.0/2 | 15.0/138 | -1.07 | +0.58 | +0.00 | A low | by design (triage) — filter-kit widget reused across sphere views |
| `agent/system-prompt.js` | 2.0/1 | 3.0/9 | 1.0/0 | 4.5/10 | -0.63 | +1.00 | -0.63 |  |  |
| `spheres/publicity/api/policy.js` | 1.0/3 | 2.5/0 | 0.5/1 | 3.5/0 | +1.00 | -1.46 | +0.63 |  |  |
| `spheres/schedule/ui/views/Almanac.tsx` | 0.5/1 | 2.0/3 | 4.5/9 | 4.5/3 | +0.63 | +0.37 | +0.63 |  |  |
| `spheres/financial/ui/views/Products.tsx` | 0.5/1 | 3.0/0 | 4.5/13 | 5.0/0 | +0.63 | -1.63 | +0.97 |  |  |
| `server/shared/credential-manifests.js` | 11.5/2 | 14.5/5 | 3.0/0 | 26.0/27 | -1.59 | -0.97 | -1.63 | A low | by design (triage) — narrow: 1 script |
| `spheres/schedule/api/providers/local.js` | 1.0/4 | 3.5/5 | 4.0/0 | 5.0/30 | +1.26 | +0.32 | -1.89 | A high | by design (triage) — provider-family sibling (rezdy.js shares the functions) |
| `web/src/ui/atoms.tsx` | 15.5/44 | 19.5/38 | 1.5/0 | 30.5/213 | +0.95 | +0.61 | -1.00 |  |  |
| `server/shared/connector-health.js` | 5.0/1 | 7.5/8 | 3.0/1 | 13.0/33 | -1.46 | +0.06 | -1.00 | A low | by design (triage) — narrow: 1 real consumer (credentials.js) |
| `server/shared/job-runs.js` | 4.5/6 | 6.5/26 | 2.0/1 | 11.0/84 | +0.26 | +1.26 | -0.63 | B high | by design (triage) — job bookkeeping kit, called across app.js and jobs |
| `spheres/projects/ui/views/Portfolio.tsx` | 0.5/1 | 2.5/0 | 4.5/12 | 3.5/0 | +0.63 | -1.46 | +0.89 |  |  |
| `spheres/schedule/api/valid.js` | 1.0/4 | 3.0/4 | 4.5/0 | 5.5/21 | +1.26 | +0.26 | -2.00 | A high | by design (triage) — schedule's own validators used by its own api files |
| `web/src/ui/CtxMenu.tsx` | 6.0/6 | 7.5/39 | 1.0/0 | 13.0/94 | +0.00 | +1.50 | -0.63 | B high | by design (triage) — UI kit widget; "viewport" homonym inflates B further |
| `web/src/lib/use-api-view.ts` | 20.0/38 | 19.5/53 | 3.0/3 | 38.5/239 | +0.58 | +0.91 | +0.00 |  |  |
| `spheres/relationships/ui/views/People.tsx` | 0.5/1 | 2.0/0 | 4.0/10 | 3.5/0 | +0.63 | -1.26 | +0.83 |  |  |
| `spheres/social/ui/CampaignsSection.tsx` | 2.0/1 | 4.5/1 | 4.0/10 | 6.5/4 | -0.63 | -1.37 | +0.83 |  |  |
| `web/src/lib/drive.ts` | 2.5/1 | 5.0/2 | 4.0/8 | 9.5/14 | -0.83 | -0.83 | +0.63 |  |  |
| `spheres/relationships/ui/views/Matches.tsx` | 0.5/1 | 2.0/4 | 5.0/6 | 3.5/5 | +0.63 | +0.63 | +0.17 |  |  |
| `connectors/xero/api/xero-client.js` | 3.0/2 | 5.5/17 | 1.0/1 | 9.0/56 | -0.37 | +1.03 | +0.00 | B high, leak signature | by design (triage) — `accessToken` is the connector-family's shared field name |
| `spheres/library/ui/ItemOverlay.tsx` | 1.0/2 | 3.0/2 | 3.0/7 | 5.0/6 | +0.63 | -0.37 | +0.77 |  |  |
| `server/shared/hash.js` | 5.0/2 | 7.0/13 | 1.0/0 | 10.0/26 | -0.83 | +0.56 | -0.63 |  |  |
| `server/shared/spar-pipeline.js` | 5.5/5 | 9.5/39 | 8.0/4 | 20.0/105 | -0.09 | +1.29 | -0.63 | B high, leak signature | by design (triage) — documented shared pipeline kit, 3 spheres compose it |
| `server/shared/trail.js` | 9.0/2 | 10.5/5 | 2.5/0 | 18.0/27 | -1.37 | -0.68 | -1.46 | A low | by design (triage) — narrow: 3 real consumers |
| `connectors/instagram/api/jobs.js` | 1.5/3 | 4.5/10 | 5.5/2 | 11.0/60 | +0.63 | +0.73 | -0.92 |  |  |
| `web/src/app/ChatPane.tsx` | 1.0/1 | 2.5/11 | 4.0/2 | 4.0/28 | +0.00 | +1.35 | -0.63 | B high | by design (triage) — small app component, expected call sites |
| `web/src/lib/view-scope.ts` | 5.0/11 | 6.5/13 | 1.0/0 | 10.5/40 | +0.72 | +0.63 | -0.63 |  |  |
| `web/src/lib/tool-labels.ts` | 3.0/1 | 5.5/8 | 2.0/0 | 9.0/38 | -1.00 | +0.34 | -1.26 |  |  |
| `web/src/ui/SectionHeader.tsx` | 13.5/19 | 15.0/35 | 1.5/2 | 22.0/95 | +0.31 | +0.77 | +0.26 |  |  |
| `web/src/lib/breakpoint.ts` | 6.0/3 | 7.5/16 | 1.0/0 | 12.0/38 | -0.63 | +0.69 | -0.63 |  |  |
| `server/shared/job-claims.js` | 6.0/2 | 8.5/12 | 2.5/0 | 15.5/46 | -1.00 | +0.31 | -1.46 |  |  |
| `web/src/app/match.ts` | 2.5/6 | 3.5/6 | 1.0/1 | 5.5/29 | +0.80 | +0.49 | +0.00 |  |  |
| `web/src/pipeline/ContactPanel.tsx` | 3.5/3 | 4.5/9 | 4.0/7 | 6.5/32 | -0.14 | +0.63 | +0.51 |  |  |
| `agent/server.js` | 2.0/0 | 4.5/2 | 5.0/5 | 7.5/2 | -1.26 | -0.74 | +0.00 | A low | by design (triage) — process entrypoint, never imported |
| `server/shared/party.js` | 4.0/1 | 7.5/2 | 5.5/3 | 15.0/3 | -1.26 | -1.20 | -0.55 | A low | artefact (triage) — same |
| `spheres/coord/reconstruct.js` | 2.0/0 | 4.5/0 | 3.5/3 | 7.5/0 | -1.26 | -2.00 | -0.14 | A low | by design (triage) — no distinctive vocabulary (B floor); A near expectation |
| `spheres/social/api/stage-pass.js` | 2.0/0 | 5.5/0 | 5.0/2 | 6.5/0 | -1.26 | -2.18 | -0.83 | A low | by design (triage) — narrow cross-sphere helper (publicity's `instance.js`) |
| `spheres/social/ui/PeopleSection.tsx` | 1.5/1 | 4.0/4 | 4.5/12 | 6.0/13 | -0.37 | +0.00 | +0.89 |  |  |
| `web/src/app/PrefsPanel.tsx` | 1.0/1 | 2.5/5 | 3.0/6 | 4.0/8 | +0.00 | +0.63 | +0.63 |  |  |
| `web/src/lib/clicklog.ts` | 3.0/6 | 5.5/11 | 2.0/2 | 9.0/44 | +0.63 | +0.63 | +0.00 |  |  |
| `web/src/lib/useDoorbell.ts` | 4.0/1 | 6.0/3 | 1.5/0 | 9.5/5 | -1.26 | -0.63 | -1.00 | A low | by design (triage) — narrow: App.tsx only |
| `web/src/lib/interaction-context.ts` | 5.0/2 | 7.0/11 | 4.0/4 | 12.0/53 | -0.83 | +0.41 | +0.00 |  |  |
| `server/shared/contract-helpers.js` | 15.5/4 | 17.0/5 | 1.5/0 | 29.0/68 | -1.23 | -1.11 | -1.00 | A low | by design (triage) — narrow: 3 connector jobs.js |
| `web/src/ui/GroupedList.tsx` | 11.5/3 | 13.5/10 | 1.0/1 | 19.5/24 | -1.22 | -0.27 | +0.00 | A low | by design (triage) — list-layout kit reused across spheres |
| `web/src/app/sphere.ts` | 9.0/18 | 10.0/19 | 1.5/0 | 15.0/51 | +0.63 | +0.58 | -1.00 |  |  |
| `spheres/schedule/ui/views/Pending.tsx` | 0.5/1 | 2.5/4 | 6.0/7 | 4.5/12 | +0.63 | +0.43 | +0.14 |  |  |
| `spheres/coord/ui/views/MeetingFollowUp.tsx` | 0.5/1 | 2.0/3 | 4.0/5 | 3.0/17 | +0.63 | +0.37 | +0.20 |  |  |
| `connectors/instagram/api/insights-sync.js` | 2.0/1 | 5.0/9 | 4.5/2 | 8.0/70 | -0.63 | +0.54 | -0.74 |  |  |
| `spheres/coord/api/jobs-a.js` | 2.0/1 | 5.0/9 | 5.0/3 | 9.5/20 | -0.63 | +0.54 | -0.46 |  |  |
| `spheres/schedule/api/providers/index.js` | 1.0/3 | 2.5/0 | 2.5/3 | 4.0/0 | +1.00 | -1.46 | +0.17 |  |  |
| `connectors/rezdy/sync.js` | 0.0/0 | 2.0/0 | 2.0/7 | 3.0/0 | +0.00 | -1.26 | +1.14 | D high (hub) | by design (triage) — per-connector sync orchestrator, standard scaffold |
| `connectors/sonas/sync.js` | 0.0/0 | 2.0/0 | 2.0/7 | 3.0/0 | +0.00 | -1.26 | +1.14 | D high (hub) | by design (triage) — same |
| `connectors/tiktok/insights-sync.js` | 0.0/0 | 2.5/0 | 2.0/7 | 3.5/0 | +0.00 | -1.46 | +1.14 | D high (hub) | by design (triage) — same |
| `server/shared/events.js` | 3.5/1 | 6.0/1 | 1.5/0 | 10.0/6 | -1.14 | -1.63 | -1.00 | A low | artefact (triage) — same |
| `server/shared/model-api.js` | 3.5/1 | 6.0/4 | 3.0/2 | 8.5/12 | -1.14 | -0.37 | -0.37 | A low | by design (triage) — narrow: 2 real consumers |
| `web/src/app/chat-icon.tsx` | 3.5/1 | 4.0/1 | 1.0/0 | 6.5/4 | -1.14 | -1.26 | -0.63 | A low | by design (triage) — sealed, leak = 0, one sibling consumer |
| `web/src/pipeline/CampaignBoard.tsx` | 2.5/1 | 4.5/1 | 5.0/7 | 7.0/11 | -0.83 | -1.37 | +0.31 |  |  |
| `spheres/financial/ui/PeriodPicker.tsx` | 1.0/3 | 3.5/4 | 4.5/2 | 6.5/14 | +1.00 | +0.12 | -0.74 |  |  |
| `spheres/social/ui/CampaignWizard.tsx` | 1.5/1 | 4.0/2 | 3.5/8 | 7.5/4 | -0.37 | -0.63 | +0.75 |  |  |
| `server/shared/error-codes.js` | 17.0/5 | 20.5/0 | 2.0/0 | 40.0/0 | -1.11 | -3.38 | -1.26 | A low | artefact (triage) — same |
| `web/src/ui/boardDrag.ts` | 10.0/4 | 12.5/17 | 1.0/1 | 19.0/217 | -0.83 | +0.28 | +0.00 |  |  |
| `web/src/lib/locale.ts` | 10.0/3 | 12.0/6 | 2.5/2 | 21.0/32 | -1.10 | -0.63 | -0.20 | A low | by design (triage) — small i18n utility, few bootstrap call sites |
| `connectors/awsconnect/api/aws-client.js` | 2.5/1 | 5.0/4 | 1.5/2 | 10.5/9 | -0.83 | -0.20 | +0.26 |  |  |
| `server/shared/ollama.js` | 1.5/2 | 4.0/10 | 2.5/1 | 6.5/27 | +0.26 | +0.83 | -0.83 |  |  |
| `server/shared/anthropic.js` | 2.5/2 | 5.0/13 | 2.5/2 | 8.0/27 | -0.20 | +0.87 | -0.20 |  |  |
| `agent/drive-tools.js` | 1.0/1 | 2.5/8 | 2.5/0 | 5.0/26 | +0.00 | +1.06 | -1.46 | B high | by design (triage) — tool-name convention shared with web display labels |
| `web/src/lib/slot-store.ts` | 4.0/7 | 6.0/11 | 1.5/0 | 10.0/114 | +0.51 | +0.55 | -1.00 |  |  |
| `web/src/lib/assistant-runtime.ts` | 2.0/1 | 4.5/4 | 4.5/7 | 8.0/11 | -0.63 | -0.11 | +0.40 |  |  |
| `web/src/ui/FilterRow.tsx` | 7.0/3 | 9.0/12 | 1.5/0 | 12.5/31 | -0.77 | +0.26 | -1.00 |  |  |
| `spheres/coord/ui/views/Meetings.tsx` | 0.5/1 | 3.0/3 | 6.5/10 | 5.0/18 | +0.63 | +0.00 | +0.39 |  |  |
| `web/src/ui/PersonRow.tsx` | 7.0/3 | 10.0/13 | 1.5/1 | 16.5/41 | -0.77 | +0.24 | -0.37 |  |  |
| `connectors/clover/api/clover-client.js` | 3.0/1 | 6.5/4 | 1.5/1 | 11.5/14 | -1.00 | -0.44 | -0.37 |  |  |
| `connectors/github/api/github-client.js` | 3.0/1 | 5.5/4 | 1.0/1 | 9.5/12 | -1.00 | -0.29 | +0.00 |  |  |
| `connectors/googlereviews/api/serpapi-client.js` | 3.0/1 | 5.5/4 | 1.0/1 | 11.0/16 | -1.00 | -0.29 | +0.00 |  |  |
| `connectors/googlereviews/sync.js` | 0.0/0 | 3.0/0 | 2.0/6 | 4.0/0 | +0.00 | -1.63 | +1.00 |  |  |
| `connectors/square/api/square-client.js` | 3.0/1 | 6.5/2 | 1.5/1 | 10.5/6 | -1.00 | -1.07 | -0.37 |  |  |
| `server/shared/secret-box.js` | 6.0/2 | 8.5/8 | 1.5/0 | 13.0/14 | -1.00 | -0.06 | -1.00 |  |  |
| `spheres/customer-service/api/calls.js` | 3.0/1 | 6.0/2 | 4.0/2 | 10.5/12 | -1.00 | -1.00 | -0.63 |  |  |
| `spheres/financial/ui/letterhead.ts` | 1.0/3 | 3.5/3 | 5.0/3 | 6.0/14 | +1.00 | -0.14 | -0.46 |  |  |
| `spheres/library/ui/api.ts` | 3.0/5 | 5.5/10 | 4.0/0 | 8.0/50 | +0.46 | +0.54 | -1.89 |  |  |
| `spheres/partnership/api/policy.js` | 1.5/1 | 3.5/0 | 0.5/1 | 5.5/0 | -0.37 | -1.77 | +0.63 |  |  |
| `spheres/partnership/api/statements.js` | 1.5/0 | 3.5/0 | 1.5/0 | 5.0/0 | -1.00 | -1.77 | -1.00 |  |  |
| `spheres/publicity/api/stage-pass.js` | 1.5/0 | 4.5/0 | 4.0/2 | 5.5/0 | -1.00 | -2.00 | -0.63 |  |  |
| `spheres/relationships/api/identity.js` | 3.0/1 | 5.0/2 | 5.0/0 | 8.0/66 | -1.00 | -0.83 | -2.10 |  |  |
| `spheres/schedule/ui/cards.tsx` | 1.0/3 | 3.5/3 | 5.0/3 | 5.0/8 | +1.00 | -0.14 | -0.46 |  |  |
| `spheres/social/api/performance.js` | 3.0/1 | 6.0/3 | 4.5/1 | 13.5/27 | -1.00 | -0.63 | -1.37 |  |  |
| `spheres/social/api/pipeline-fixture.js` | 1.5/0 | 4.0/0 | 3.0/2 | 6.0/0 | -1.00 | -1.89 | -0.37 |  |  |
| `web/src/lib/chat-store.ts` | 3.0/1 | 5.5/3 | 3.0/0 | 9.0/12 | -1.00 | -0.55 | -1.63 |  |  |
| `web/src/lib/download.ts` | 3.0/1 | 5.0/2 | 1.0/0 | 7.5/6 | -1.00 | -0.83 | -0.63 |  |  |
| `web/src/lib/gesture-state.ts` | 3.0/1 | 5.0/2 | 1.5/1 | 8.0/6 | -1.00 | -0.83 | -0.37 |  |  |
| `web/src/lib/navigate.ts` | 12.0/8 | 14.0/4 | 1.5/3 | 24.0/8 | -0.37 | -1.14 | +0.63 |  |  |
| `web/src/lib/use-anchor.ts` | 6.0/2 | 8.0/2 | 2.0/2 | 13.0/8 | -1.00 | -1.26 | +0.00 |  |  |
| `web/src/ui/useCardSelection.ts` | 9.0/3 | 11.0/9 | 1.5/1 | 15.5/18 | -1.00 | -0.18 | -0.37 |  |  |
| `web/src/ui/ParamChips.tsx` | 9.0/9 | 12.5/18 | 2.0/4 | 19.0/79 | +0.00 | +0.33 | +0.63 |  |  |
| `spheres/social/ui/perf-derive.ts` | 1.0/2 | 3.5/5 | 4.5/1 | 8.0/255 | +0.63 | +0.32 | -1.37 |  |  |
| `connectors/clover/sync.js` | 0.0/0 | 2.0/0 | 2.5/7 | 3.0/0 | +0.00 | -1.26 | +0.94 |  |  |
| `connectors/deputy/sync.js` | 0.0/0 | 2.0/0 | 2.5/7 | 3.0/0 | +0.00 | -1.26 | +0.94 |  |  |
| `connectors/github/sync.js` | 0.0/0 | 2.5/0 | 2.5/7 | 3.5/0 | +0.00 | -1.46 | +0.94 |  |  |
| `spheres/reputation/ui/api.ts` | 4.0/5 | 7.5/17 | 4.0/1 | 9.5/147 | +0.20 | +0.74 | -1.26 |  |  |
| `web/src/lib/use-pathname.ts` | 5.5/6 | 7.0/9 | 1.0/2 | 11.0/26 | +0.08 | +0.23 | +0.63 |  |  |
| `web/src/pipeline/Campaigns.tsx` | 2.5/3 | 4.5/0 | 3.5/8 | 7.0/0 | +0.17 | -2.00 | +0.75 |  |  |
| `web/src/pipeline/Roster.tsx` | 2.5/3 | 4.0/3 | 4.5/10 | 6.5/3 | +0.17 | -0.26 | +0.73 |  |  |
| `server/shared/grants.js` | 8.0/3 | 12.5/6 | 2.5/1 | 26.0/141 | -0.89 | -0.67 | -0.83 |  |  |
| `spheres/financial/ui/export.ts` | 1.5/1 | 4.0/7 | 3.5/1 | 6.0/65 | -0.37 | +0.51 | -1.14 |  |  |
| `web/src/ui/DeepLink.tsx` | 8.5/8 | 12.0/29 | 3.0/1 | 19.5/73 | -0.06 | +0.80 | -1.00 |  |  |
| `web/src/ui/Board.tsx` | 13.5/7 | 18.0/16 | 3.0/4 | 29.0/82 | -0.60 | -0.11 | +0.26 |  |  |
| `spheres/schedule/ui/views/Week.tsx` | 1.0/1 | 3.0/0 | 5.5/14 | 5.5/0 | +0.00 | -1.63 | +0.85 |  |  |
| `connectors/googlereviews/api/upsert.js` | 1.0/2 | 4.0/5 | 1.5/1 | 6.0/55 | +0.63 | +0.20 | -0.37 |  |  |
| `connectors/deputy/api/deputy-client.js` | 2.5/1 | 5.5/5 | 1.5/1 | 10.5/15 | -0.83 | -0.09 | -0.37 |  |  |
| `connectors/facebook/api/graph-client.js` | 2.5/1 | 5.0/0 | 1.0/1 | 9.5/0 | -0.83 | -2.10 | +0.00 |  |  |
| `connectors/instagram/api/graph-client.js` | 2.5/1 | 6.0/0 | 1.0/1 | 11.5/0 | -0.83 | -2.26 | +0.00 |  |  |
| `server/shared/chat.js` | 2.5/1 | 5.0/3 | 3.5/3 | 8.0/17 | -0.83 | -0.46 | -0.14 |  |  |
| `server/shared/closure.js` | 2.5/1 | 5.0/3 | 3.0/0 | 8.0/39 | -0.83 | -0.46 | -1.63 |  |  |
| `server/shared/versions.js` | 2.5/1 | 4.5/2 | 1.5/0 | 7.0/15 | -0.83 | -0.74 | -1.00 |  |  |
| `spheres/coord/api/jobs.js` | 2.5/1 | 5.0/2 | 4.0/2 | 8.5/20 | -0.83 | -0.83 | -0.63 |  |  |
| `spheres/customer-service/api/transcripts.js` | 2.5/1 | 5.5/2 | 3.0/3 | 8.5/15 | -0.83 | -0.92 | +0.00 |  |  |
| `spheres/financial/api/read.js` | 2.5/1 | 7.5/3 | 8.0/7 | 16.5/18 | -0.83 | -0.83 | -0.12 |  |  |
| `spheres/partnership/api/read.js` | 2.5/1 | 6.5/0 | 10.0/3 | 9.0/0 | -0.83 | -2.33 | -1.10 |  |  |
| `spheres/relationships/api/read.js` | 2.5/1 | 7.5/0 | 6.5/5 | 16.0/0 | -0.83 | -2.46 | -0.24 |  |  |
| `spheres/social/api/jobs.js` | 2.5/1 | 5.5/3 | 4.5/4 | 12.5/4 | -0.83 | -0.55 | -0.11 |  |  |
| `web/src/lib/format.ts` | 19.5/28 | 20.0/34 | 2.0/0 | 36.5/288 | +0.33 | +0.48 | -1.26 |  |  |
| `connectors/facebook/insights-sync.js` | 0.0/0 | 2.5/0 | 2.5/6 | 3.5/0 | +0.00 | -1.46 | +0.80 |  |  |
| `connectors/googlechat/sync.js` | 0.0/0 | 2.0/0 | 2.5/6 | 3.0/0 | +0.00 | -1.26 | +0.80 |  |  |
| `spheres/projects/ui/api.ts` | 4.5/2 | 7.5/8 | 4.5/3 | 11.0/121 | -0.74 | +0.06 | -0.37 |  |  |
| `spheres/publicity/api/instance.js` | 1.0/0 | 3.0/0 | 2.5/3 | 4.5/0 | -0.63 | -1.63 | +0.17 |  |  |
| `spheres/social/ui/CampaignDelete.tsx` | 1.0/2 | 2.5/3 | 3.0/3 | 4.0/21 | +0.63 | +0.17 | +0.00 |  |  |
| `spheres/social/ui/PerformanceSection.tsx` | 1.0/1 | 3.0/3 | 5.0/12 | 9.0/8 | +0.00 | +0.00 | +0.80 |  |  |
| `web/src/ui/FreshnessNote.tsx` | 10.0/11 | 11.5/25 | 1.5/1 | 17.5/65 | +0.09 | +0.71 | -0.37 |  |  |
| `web/src/app/Access.tsx` | 1.5/1 | 4.0/0 | 7.0/11 | 7.5/0 | -0.37 | -1.89 | +0.41 |  |  |
| `connectors/instagram/insights-sync.js` | 0.0/0 | 2.5/0 | 3.0/7 | 3.5/0 | +0.00 | -1.46 | +0.77 |  |  |
| `web/src/ui/SelectableCard.tsx` | 7.0/3 | 9.5/9 | 1.0/0 | 15.5/34 | -0.77 | -0.05 | -0.63 |  |  |
| `spheres/reputation/ui/PlaceChips.tsx` | 1.0/2 | 3.0/2 | 3.5/4 | 5.0/10 | +0.63 | -0.37 | +0.12 |  |  |
| `server/shared/manifest.js` | 4.5/2 | 7.0/6 | 3.0/0 | 13.0/26 | -0.74 | -0.14 | -1.63 |  |  |
| `connectors/googlechat/api/chat-client.js` | 2.0/1 | 4.5/5 | 1.0/1 | 9.0/7 | -0.63 | +0.10 | +0.00 |  |  |
| `spheres/projects/api/derive.js` | 2.0/1 | 4.5/5 | 4.0/0 | 7.0/68 | -0.63 | +0.10 | -1.89 |  |  |
| `connectors/awsconnect/api/sigv4.js` | 2.5/2 | 4.5/8 | 1.5/0 | 8.5/47 | -0.20 | +0.52 | -1.00 |  |  |
| `connectors/rezdy/api/rezdy-client.js` | 2.0/1 | 5.5/6 | 1.5/1 | 10.0/26 | -0.63 | +0.08 | -0.37 |  |  |
| `spheres/relationships/ui/views/PersonPanel.tsx` | 0.5/1 | 2.0/1 | 5.5/6 | 4.5/7 | +0.63 | -0.63 | +0.08 |  |  |
| `spheres/reputation/ui/views/AllReviews.tsx` | 0.5/1 | 2.5/2 | 6.5/7 | 2.5/8 | +0.63 | -0.20 | +0.07 |  |  |
| `web/src/lib/api.ts` | 21.5/34 | 23.5/32 | 3.5/1 | 44.0/142 | +0.42 | +0.28 | -1.14 |  |  |
| `web/src/pipeline/StagesEditor.tsx` | 3.0/2 | 4.0/5 | 3.5/4 | 6.5/22 | -0.37 | +0.20 | +0.12 |  |  |
| `spheres/schedule/api/moves.js` | 1.5/1 | 4.5/4 | 3.5/5 | 7.0/30 | -0.37 | -0.11 | +0.32 |  |  |
| `spheres/schedule/ui/week.ts` | 2.0/3 | 3.5/5 | 3.5/1 | 5.0/61 | +0.37 | +0.32 | -1.14 |  |  |
| `spheres/schedule/api/read.js` | 2.0/1 | 6.5/2 | 9.5/10 | 13.0/8 | -0.63 | -1.07 | +0.05 |  |  |
| `server/shared/tenancy.js` | 10.5/6 | 13.5/16 | 3.0/1 | 25.5/61 | -0.51 | +0.15 | -1.00 |  |  |
| `web/src/lib/view-registry.ts` | 7.0/8 | 9.5/17 | 2.5/1 | 16.0/99 | +0.12 | +0.53 | -0.83 |  |  |
| `agent/tools.js` | 1.0/1 | 3.5/7 | 2.0/1 | 5.5/56 | +0.00 | +0.63 | -0.63 |  |  |
| `connectors/awsconnect/api/upsert.js` | 1.0/0 | 3.5/3 | 1.5/1 | 7.0/47 | -0.63 | -0.14 | -0.37 |  |  |
| `connectors/awsconnect/sync.js` | 0.0/0 | 2.5/0 | 2.5/5 | 3.5/0 | +0.00 | -1.46 | +0.63 |  |  |
| `connectors/clover/api/sync.js` | 2.0/1 | 4.5/1 | 3.5/0 | 7.5/1 | -0.63 | -1.37 | -1.77 |  |  |
| `connectors/clover/api/upsert.js` | 2.0/1 | 4.5/2 | 2.0/1 | 8.0/7 | -0.63 | -0.74 | -0.63 |  |  |
| `connectors/clover/credentials.js` | 1.0/0 | 5.0/0 | 1.0/0 | 7.0/0 | -0.63 | -2.10 | -0.63 |  |  |
| `connectors/facebook/api/insights-sync.js` | 2.0/3 | 4.5/6 | 5.0/1 | 8.0/52 | +0.37 | +0.26 | -1.46 |  |  |
| `connectors/github/api/formats.js` | 2.0/1 | 3.5/0 | 1.0/0 | 5.0/0 | -0.63 | -1.77 | -0.63 |  |  |
| `connectors/github/api/sync.js` | 2.0/1 | 5.0/0 | 4.0/0 | 8.0/0 | -0.63 | -2.10 | -1.89 |  |  |
| `connectors/github/credentials.js` | 1.0/0 | 4.0/0 | 1.0/0 | 7.0/0 | -0.63 | -1.89 | -0.63 |  |  |
| `connectors/googlechat/api/sync.js` | 2.0/1 | 5.0/1 | 4.0/1 | 8.5/5 | -0.63 | -1.46 | -1.26 |  |  |
| `connectors/googlereviews/credentials.js` | 1.0/0 | 4.0/0 | 0.5/0 | 7.0/0 | -0.63 | -1.89 | +0.00 |  |  |
| `connectors/googlereviews/import-historical.js` | 0.0/0 | 3.0/0 | 2.0/4 | 4.0/0 | +0.00 | -1.63 | +0.63 |  |  |
| `connectors/instagram/credentials.js` | 1.0/0 | 4.5/0 | 1.0/0 | 7.0/0 | -0.63 | -2.00 | -0.63 |  |  |
| `connectors/onedrive/api/graph-client.js` | 2.0/3 | 5.0/4 | 1.5/2 | 10.0/50 | +0.37 | -0.20 | +0.26 |  |  |
| `connectors/rezdy/api/sync.js` | 2.0/1 | 4.5/0 | 3.5/0 | 8.0/0 | -0.63 | -2.00 | -1.77 |  |  |
| `connectors/square/import.js` | 0.0/0 | 2.0/0 | 2.0/4 | 3.0/0 | +0.00 | -1.26 | +0.63 |  |  |
| `connectors/tiktok/api/insights-sync.js` | 2.0/1 | 5.5/3 | 5.0/2 | 8.0/17 | -0.63 | -0.55 | -0.83 |  |  |
| `connectors/xero/credentials.js` | 1.0/0 | 4.0/0 | 0.5/0 | 7.5/0 | -0.63 | -1.89 | +0.00 |  |  |
| `connectors/xero/sync.js` | 0.0/0 | 2.5/0 | 3.0/6 | 3.5/0 | +0.00 | -1.46 | +0.63 |  |  |
| `scripts/stage-flip-harness.mjs` | 0.0/0 | 2.5/5 | 7.0/5 | 3.0/5 | +0.00 | +0.63 | -0.31 |  |  |
| `server/shared/sql-static.js` | 1.5/3 | 5.0/5 | 3.0/0 | 9.0/41 | +0.63 | +0.00 | -1.63 |  |  |
| `server/shared/walls.js` | 8.0/4 | 12.5/9 | 3.0/1 | 25.0/45 | -0.63 | -0.30 | -1.00 |  |  |
| `spheres/coord/api/decode.js` | 2.0/1 | 4.5/2 | 4.0/0 | 8.5/70 | -0.63 | -0.74 | -1.89 |  |  |
| `spheres/coord/api/meetings.js` | 2.0/1 | 4.5/3 | 4.5/1 | 9.0/51 | -0.63 | -0.37 | -1.37 |  |  |
| `spheres/customer-service/api/instance.js` | 1.0/0 | 3.5/0 | 3.0/1 | 5.5/0 | -0.63 | -1.77 | -1.00 |  |  |
| `spheres/customer-service/api/read.js` | 2.0/1 | 6.5/1 | 10.0/5 | 11.5/6 | -0.63 | -1.70 | -0.63 |  |  |
| `spheres/financial/api/instance.js` | 1.0/0 | 2.5/0 | 2.5/1 | 4.0/0 | -0.63 | -1.46 | -0.83 |  |  |
| `spheres/financial/api/statements.js` | 1.0/0 | 2.5/0 | 1.5/0 | 4.5/0 | -0.63 | -1.46 | -1.00 |  |  |
| `spheres/financial/ui/labour-matrix.ts` | 2.0/1 | 4.0/2 | 5.0/1 | 6.0/46 | -0.63 | -0.63 | -1.46 |  |  |
| `spheres/financial/ui/matrix.ts` | 2.0/2 | 3.5/7 | 3.0/1 | 5.5/55 | +0.00 | +0.63 | -1.00 |  |  |
| `spheres/financial/ui/sphere.tsx` | 0.5/0 | 7.5/0 | 3.0/6 | 10.0/0 | +0.00 | -2.46 | +0.63 |  |  |
| `spheres/financial/ui/views/People.tsx` | 0.5/1 | 3.0/0 | 6.0/3 | 3.0/0 | +0.63 | -1.63 | -0.63 |  |  |
| `spheres/library/api/instance.js` | 1.0/0 | 3.0/0 | 3.0/1 | 5.0/0 | -0.63 | -1.63 | -1.00 |  |  |
| `spheres/library/ui/Results.tsx` | 2.0/3 | 4.5/3 | 4.5/6 | 7.5/12 | +0.37 | -0.37 | +0.26 |  |  |
| `spheres/library/ui/views/Documents.tsx` | 0.5/1 | 2.5/0 | 6.5/6 | 3.0/0 | +0.63 | -1.46 | -0.07 |  |  |
| `spheres/partnership/api/instance.js` | 1.0/0 | 3.0/0 | 3.0/1 | 5.0/0 | -0.63 | -1.63 | -1.00 |  |  |
| `spheres/partnership/ui/views/Roster.tsx` | 0.5/1 | 2.0/0 | 4.0/3 | 3.0/0 | +0.63 | -1.26 | -0.26 |  |  |
| `spheres/projects/api/instance.js` | 1.0/0 | 3.5/0 | 2.5/1 | 5.5/0 | -0.63 | -1.77 | -0.83 |  |  |
| `spheres/publicity/api/pipeline-fixture.js` | 1.0/0 | 2.5/0 | 4.0/2 | 5.5/0 | -0.63 | -1.46 | -0.63 |  |  |
| `spheres/publicity/ui/views/Roster.tsx` | 0.5/1 | 2.0/0 | 6.5/4 | 3.0/0 | +0.63 | -1.26 | -0.44 |  |  |
| `spheres/relationships/api/instance.js` | 1.0/0 | 3.0/0 | 2.5/1 | 5.0/0 | -0.63 | -1.63 | -0.83 |  |  |
| `spheres/reputation/api/instance.js` | 1.0/0 | 3.5/0 | 2.5/1 | 5.5/0 | -0.63 | -1.77 | -0.83 |  |  |
| `spheres/reputation/api/read.js` | 2.0/1 | 6.0/0 | 8.0/2 | 11.0/0 | -0.63 | -2.26 | -1.26 |  |  |
| `spheres/schedule/api/instance.js` | 1.0/0 | 3.5/0 | 2.5/2 | 5.0/0 | -0.63 | -1.77 | -0.20 |  |  |
| `spheres/schedule/api/providers/sonas.js` | 2.0/4 | 4.5/2 | 4.5/0 | 6.0/25 | +0.63 | -0.74 | -2.00 |  |  |
| `spheres/schedule/ui/ConfirmMove.tsx` | 1.5/1 | 3.0/4 | 4.0/3 | 5.0/23 | -0.37 | +0.26 | -0.26 |  |  |
| `spheres/social/api/read.js` | 2.0/1 | 6.5/5 | 8.0/7 | 17.5/9 | -0.63 | -0.24 | -0.12 |  |  |
| `spheres/social/api/statements.js` | 1.0/2 | 3.0/1 | 1.5/0 | 5.0/2 | +0.63 | -1.00 | -1.00 |  |  |
| `spheres/social/ui/drafts.tsx` | 1.0/1 | 2.5/1 | 3.0/6 | 5.0/3 | +0.00 | -0.83 | +0.63 |  |  |
| `web/src/app/AccessPeople.tsx` | 0.5/1 | 2.5/2 | 7.0/4 | 5.0/4 | +0.63 | -0.20 | -0.51 |  |  |
| `web/src/app/AccessWalls.tsx` | 0.5/1 | 2.0/2 | 6.0/3 | 4.0/4 | +0.63 | +0.00 | -0.63 |  |  |
| `web/src/lib/chat-starters.ts` | 2.0/1 | 3.5/3 | 1.5/0 | 6.0/8 | -0.63 | -0.14 | -1.00 |  |  |
| `web/src/lib/chat.ts` | 4.0/2 | 7.0/3 | 4.5/4 | 12.0/12 | -0.63 | -0.77 | -0.11 |  |  |
| `web/src/lib/stream.ts` | 4.0/2 | 6.0/2 | 3.0/0 | 10.0/16 | -0.63 | -1.00 | -1.63 |  |  |
| `web/src/ui/Chips.tsx` | 6.0/3 | 9.0/9 | 1.5/1 | 14.0/33 | -0.63 | +0.00 | -0.37 |  |  |
| `web/src/vite-env.d.ts` | 0.0/1 | 1.0/0 | 0.0/0 | 1.5/0 | +0.63 | -0.63 | +0.00 |  |  |
| `spheres/financial/ui/api.ts` | 5.5/9 | 9.0/10 | 3.0/2 | 12.5/47 | +0.45 | +0.10 | -0.37 |  |  |
| `connectors/sonas/api/sonas-client.js` | 2.0/3 | 5.0/6 | 1.0/0 | 10.0/56 | +0.37 | +0.17 | -0.63 |  |  |
| `server/shared/freshness.js` | 9.0/5 | 10.5/0 | 2.5/0 | 18.0/0 | -0.54 | -2.77 | -1.46 |  |  |
| `web/src/app/App.tsx` | 1.5/1 | 5.0/6 | 20.0/14 | 9.0/21 | -0.37 | +0.17 | -0.32 |  |  |
| `spheres/partnership/ui/api.ts` | 3.5/2 | 6.5/0 | 4.0/1 | 8.5/0 | -0.51 | -2.33 | -1.26 |  |  |
| `spheres/projects/api/read.js` | 1.5/1 | 5.0/3 | 6.0/7 | 12.5/10 | -0.37 | -0.46 | +0.14 |  |  |
| `spheres/customer-service/ui/views/Calls.tsx` | 1.0/1 | 2.5/0 | 6.5/11 | 5.5/0 | +0.00 | -1.46 | +0.48 |  |  |
| `spheres/coord/ui/views/Board.tsx` | 1.0/1 | 2.0/0 | 6.0/10 | 3.5/0 | +0.00 | -1.26 | +0.46 |  |  |
| `spheres/reputation/ui/views/NeedsReply.tsx` | 1.0/1 | 3.0/1 | 6.0/10 | 3.5/4 | +0.00 | -1.00 | +0.46 |  |  |
| `web/src/app/chat-handle.tsx` | 2.0/2 | 3.0/5 | 2.0/1 | 5.0/21 | +0.00 | +0.46 | -0.63 |  |  |
| `connectors/dropbox/api/dropbox-client.js` | 2.5/3 | 6.0/6 | 1.5/2 | 11.5/20 | +0.17 | +0.00 | +0.26 |  |  |
| `scripts/deploy-skills.mjs` | 0.0/0 | 2.5/4 | 6.5/3 | 3.0/6 | +0.00 | +0.43 | -0.70 |  |  |
| `scripts/import-env-credentials.mjs` | 0.0/0 | 2.0/1 | 4.5/7 | 2.5/1 | +0.00 | -0.63 | +0.40 |  |  |
| `spheres/social/ui/CampaignPipeline.tsx` | 2.0/2 | 4.5/7 | 3.0/3 | 6.5/44 | +0.00 | +0.40 | +0.00 |  |  |
| `web/src/lib/error-codes.ts` | 14.0/9 | 16.0/13 | 2.0/0 | 28.0/65 | -0.40 | -0.19 | -1.26 |  |  |
| `server/shared/stage-vocabulary.js` | 5.5/4 | 8.0/9 | 2.5/0 | 14.0/29 | -0.29 | +0.11 | -1.46 |  |  |
| `spheres/coord/api/read.js` | 2.5/2 | 6.5/8 | 10.0/3 | 10.5/29 | -0.20 | +0.19 | -1.10 |  |  |
| `spheres/schedule/api/reconcile-logic.js` | 1.5/2 | 3.5/4 | 5.0/0 | 7.0/64 | +0.26 | +0.12 | -2.10 |  |  |
| `connectors/deputy/api/sync.js` | 1.5/1 | 4.0/2 | 3.0/0 | 7.0/10 | -0.37 | -0.63 | -1.63 |  |  |
| `connectors/deputy/api/upsert.js` | 1.5/1 | 3.5/1 | 2.0/1 | 6.5/13 | -0.37 | -1.14 | -0.63 |  |  |
| `connectors/googlereviews/api/sync.js` | 1.5/1 | 5.0/3 | 3.0/1 | 8.0/6 | -0.37 | -0.46 | -1.00 |  |  |
| `connectors/rezdy/api/upsert.js` | 1.0/1 | 4.0/6 | 1.5/1 | 6.5/34 | +0.00 | +0.37 | -0.37 |  |  |
| `connectors/sonas/api/sync.js` | 1.5/1 | 4.0/0 | 3.0/0 | 7.5/0 | -0.37 | -1.89 | -1.63 |  |  |
| `connectors/sonas/api/upsert.js` | 1.5/1 | 4.0/0 | 2.0/2 | 6.5/0 | -0.37 | -1.89 | +0.00 |  |  |
| `connectors/xero/api/auth-bootstrap.js` | 0.0/0 | 2.5/0 | 2.0/3 | 3.0/0 | +0.00 | -1.46 | +0.37 |  |  |
| `connectors/xero/api/sync.js` | 1.5/1 | 4.0/0 | 4.0/1 | 7.5/0 | -0.37 | -1.89 | -1.26 |  |  |
| `server/shared/model-retry.js` | 3.0/2 | 5.0/2 | 2.0/0 | 8.0/8 | -0.37 | -0.83 | -1.26 |  |  |
| `spheres/financial/api/policy.js` | 1.5/1 | 3.0/2 | 1.0/0 | 4.5/4 | -0.37 | -0.37 | -0.63 |  |  |
| `spheres/library/api/providers.js` | 1.5/1 | 3.0/0 | 3.0/3 | 4.5/0 | -0.37 | -1.63 | +0.00 |  |  |
| `spheres/library/api/read.js` | 1.5/1 | 5.5/1 | 10.0/4 | 9.0/9 | -0.37 | -1.55 | -0.83 |  |  |
| `spheres/projects/api/policy.js` | 1.5/1 | 3.5/0 | 0.5/0 | 5.5/0 | -0.37 | -1.77 | +0.00 |  |  |
| `spheres/projects/api/statements.js` | 1.5/1 | 3.5/1 | 1.0/0 | 5.0/11 | -0.37 | -1.14 | -0.63 |  |  |
| `spheres/publicity/api/jobs.js` | 1.5/1 | 4.5/4 | 4.5/3 | 7.0/8 | -0.37 | -0.11 | -0.37 |  |  |
| `spheres/publicity/api/read.js` | 1.5/1 | 6.5/1 | 10.0/3 | 10.0/5 | -0.37 | -1.70 | -1.10 |  |  |
| `spheres/publicity/api/stage-advance.js` | 2.0/3 | 5.0/0 | 5.0/4 | 9.0/0 | +0.37 | -2.10 | -0.20 |  |  |
| `spheres/reputation/ui/lanes.ts` | 1.5/1 | 3.0/2 | 3.0/1 | 4.5/28 | -0.37 | -0.37 | -1.00 |  |  |
| `spheres/schedule/api/almanac.js` | 3.0/2 | 6.0/3 | 4.5/2 | 10.5/45 | -0.37 | -0.63 | -0.74 |  |  |
| `spheres/social/ui/useAutoSweep.ts` | 1.5/1 | 3.5/2 | 5.0/2 | 6.0/4 | -0.37 | -0.51 | -0.83 |  |  |
| `scripts/import-otter-corpus.mjs` | 0.0/0 | 3.5/5 | 8.0/3 | 4.5/61 | +0.00 | +0.32 | -0.89 |  |  |
| `spheres/library/ui/SearchBar.tsx` | 2.0/2 | 4.0/4 | 5.0/7 | 5.5/27 | +0.00 | +0.00 | +0.31 |  |  |
| `connectors/awsconnect/api/presign.js` | 1.5/2 | 3.5/3 | 1.5/1 | 7.0/12 | +0.26 | -0.14 | -0.37 |  |  |
| `connectors/otter/api/jobs.js` | 1.5/2 | 5.5/1 | 4.5/2 | 10.0/18 | +0.26 | -1.55 | -0.74 |  |  |
| `connectors/spar/sync.js` | 0.0/0 | 3.0/0 | 3.0/4 | 4.0/0 | +0.00 | -1.63 | +0.26 |  |  |
| `server/shared/venue-date.js` | 8.0/6 | 10.0/10 | 1.5/0 | 17.0/54 | -0.26 | +0.00 | -1.00 |  |  |
| `spheres/financial/ui/vocab.ts` | 1.5/2 | 3.5/3 | 4.5/1 | 5.0/13 | +0.26 | -0.14 | -1.37 |  |  |
| `spheres/library/api/hits.js` | 1.5/2 | 4.0/3 | 2.5/0 | 6.0/41 | +0.26 | -0.26 | -1.46 |  |  |
| `spheres/publicity/ui/CoverageSection.tsx` | 1.5/2 | 4.0/4 | 4.5/3 | 5.5/17 | +0.26 | +0.00 | -0.37 |  |  |
| `spheres/schedule/ui/sphere.tsx` | 0.0/0 | 7.5/0 | 3.0/4 | 10.5/0 | +0.00 | -2.46 | +0.26 |  |  |
| `web/src/app/AccessGrants.tsx` | 1.5/2 | 3.0/2 | 6.0/2 | 4.5/18 | +0.26 | -0.37 | -1.00 |  |  |
| `web/src/app/AccessTenants.tsx` | 1.0/1 | 3.0/1 | 4.5/6 | 4.5/3 | +0.00 | -1.00 | +0.26 |  |  |
| `web/src/lib/org-identity.ts` | 4.0/3 | 6.0/5 | 2.0/1 | 10.0/14 | -0.26 | -0.17 | -0.63 |  |  |
| `server/shared/dispatch.js` | 15.5/12 | 19.0/0 | 7.5/3 | 37.5/0 | -0.23 | -3.31 | -0.83 |  |  |
| `web/src/ui/Overlay.tsx` | 14.0/11 | 18.5/16 | 1.0/1 | 28.5/81 | -0.22 | -0.13 | +0.00 |  |  |
| `connectors/linkedin/api/jobs.js` | 1.0/1 | 4.0/5 | 5.5/2 | 10.5/52 | +0.00 | +0.20 | -0.92 |  |  |
| `spheres/coord/capture.js` | 2.5/2 | 4.0/4 | 4.5/0 | 5.5/12 | -0.20 | +0.00 | -2.00 |  |  |
| `web/src/app/access-sections.ts` | 2.5/2 | 3.5/3 | 1.0/1 | 5.5/15 | -0.20 | -0.14 | +0.00 |  |  |
| `connectors/dropbox/api/probe.js` | 0.0/0 | 1.5/0 | 2.5/3 | 2.0/0 | +0.00 | -1.00 | +0.17 |  |  |
| `server/shared/db.js` | 36.5/44 | 41.0/38 | 4.0/0 | 85.0/104 | +0.17 | -0.07 | -1.89 |  |  |
| `server/shared/stage-advance.js` | 5.0/5 | 9.0/7 | 5.0/6 | 16.5/30 | +0.00 | -0.23 | +0.17 |  |  |
| `spheres/library/ui/views/Media.tsx` | 1.0/1 | 2.0/0 | 5.0/6 | 2.0/0 | +0.00 | -1.26 | +0.17 |  |  |
| `spheres/schedule/api/config.js` | 2.5/3 | 5.5/1 | 3.0/1 | 7.5/20 | +0.17 | -1.55 | -1.00 |  |  |
| `spheres/social/api/stage-advance.js` | 2.5/3 | 5.5/5 | 4.0/4 | 8.5/14 | +0.17 | -0.09 | +0.00 |  |  |
| `server/shared/http-raw.js` | 18.0/18 | 17.5/20 | 1.5/0 | 32.0/35 | +0.00 | +0.12 | -1.00 |  |  |
| `spheres/coord/ui/sphere.tsx` | 0.5/0 | 8.0/0 | 3.5/4 | 11.5/0 | +0.00 | -2.52 | +0.12 |  |  |
| `spheres/social/ui/sphere.tsx` | 0.0/0 | 7.0/0 | 3.5/4 | 10.5/0 | +0.00 | -2.40 | +0.12 |  |  |
| `web/src/lib/grants.ts` | 5.5/6 | 8.0/7 | 2.5/0 | 14.0/47 | +0.08 | -0.12 | -1.46 |  |  |
| `server/shared/db-errors.js` | 7.5/7 | 9.5/8 | 1.5/0 | 14.0/9 | -0.06 | -0.16 | -1.00 |  |  |
| `agent/error-codes.js` | 2.0/2 | 4.5/0 | 2.0/0 | 6.0/0 | +0.00 | -2.00 | -1.26 |  |  |
| `agent/transcribe.js` | 1.0/1 | 3.5/1 | 2.5/0 | 5.5/4 | +0.00 | -1.14 | -1.46 |  |  |
| `connectors/awsconnect/credentials.js` | 0.5/0 | 4.5/0 | 0.5/0 | 7.5/0 | +0.00 | -2.00 | +0.00 |  |  |
| `connectors/awsconnect/hook.js` | 0.5/0 | 3.0/0 | 2.5/1 | 5.0/0 | +0.00 | -1.63 | -0.83 |  |  |
| `connectors/clover/hook.js` | 0.5/0 | 3.0/0 | 3.0/1 | 4.5/0 | +0.00 | -1.63 | -1.00 |  |  |
| `connectors/deputy/credentials.js` | 0.5/0 | 5.0/0 | 0.5/0 | 8.0/0 | +0.00 | -2.10 | +0.00 |  |  |
| `connectors/deputy/hook.js` | 0.5/0 | 4.0/0 | 2.0/1 | 5.5/0 | +0.00 | -1.89 | -0.63 |  |  |
| `connectors/dropbox/api/consent.js` | 0.0/0 | 2.0/0 | 3.0/3 | 2.5/0 | +0.00 | -1.26 | +0.00 |  |  |
| `connectors/dropbox/credentials.js` | 0.5/0 | 4.0/0 | 0.5/0 | 7.5/0 | +0.00 | -1.89 | +0.00 |  |  |
| `connectors/facebook/credentials.js` | 0.5/0 | 4.5/0 | 0.5/0 | 6.5/0 | +0.00 | -2.00 | +0.00 |  |  |
| `connectors/github/hook.js` | 0.5/0 | 4.0/0 | 3.0/1 | 5.0/0 | +0.00 | -1.89 | -1.00 |  |  |
| `connectors/googlechat/credentials.js` | 0.5/0 | 4.5/0 | 0.5/0 | 7.0/0 | +0.00 | -2.00 | +0.00 |  |  |
| `connectors/googlechat/hook.js` | 0.5/0 | 3.5/0 | 2.5/1 | 4.5/0 | +0.00 | -1.77 | -0.83 |  |  |
| `connectors/googlereviews/api/import-historical.js` | 1.0/1 | 3.0/1 | 1.5/1 | 4.5/2 | +0.00 | -1.00 | -0.37 |  |  |
| `connectors/googlereviews/hook.js` | 0.5/0 | 3.0/0 | 3.0/1 | 4.0/0 | +0.00 | -1.63 | -1.00 |  |  |
| `connectors/instagram/jobs.js` | 0.0/0 | 2.0/0 | 1.5/1 | 2.5/0 | +0.00 | -1.26 | -0.37 |  |  |
| `connectors/linkedin/api/memdb.js` | 0.5/0 | 2.0/0 | 0.5/0 | 3.0/0 | +0.00 | -1.26 | +0.00 |  |  |
| `connectors/linkedin/credentials.js` | 0.5/0 | 4.0/0 | 0.5/0 | 7.5/0 | +0.00 | -1.89 | +0.00 |  |  |
| `connectors/linkedin/jobs.js` | 0.0/0 | 2.5/0 | 2.5/1 | 3.0/0 | +0.00 | -1.46 | -0.83 |  |  |
| `connectors/onedrive/api/consent.js` | 0.0/0 | 2.5/0 | 3.0/3 | 3.0/0 | +0.00 | -1.46 | +0.00 |  |  |
| `connectors/onedrive/api/probe.js` | 0.0/0 | 2.0/0 | 3.0/3 | 2.5/0 | +0.00 | -1.26 | +0.00 |  |  |
| `connectors/onedrive/credentials.js` | 0.5/0 | 5.0/0 | 1.0/0 | 8.0/0 | +0.00 | -2.10 | -0.63 |  |  |
| `connectors/otter/api/memdb.js` | 0.5/0 | 2.0/0 | 0.5/0 | 3.0/0 | +0.00 | -1.26 | +0.00 |  |  |
| `connectors/otter/credentials.js` | 0.5/0 | 4.0/0 | 1.0/0 | 7.0/0 | +0.00 | -1.89 | -0.63 |  |  |
| `connectors/otter/jobs.js` | 0.0/0 | 2.5/0 | 2.5/1 | 3.0/0 | +0.00 | -1.46 | -0.83 |  |  |
| `connectors/rezdy/credentials.js` | 0.5/0 | 4.0/0 | 1.0/0 | 7.0/0 | +0.00 | -1.89 | -0.63 |  |  |
| `connectors/rezdy/hook.js` | 0.5/0 | 3.5/0 | 3.0/1 | 5.0/0 | +0.00 | -1.77 | -1.00 |  |  |
| `connectors/sonas/credentials.js` | 0.5/0 | 4.5/0 | 0.5/0 | 8.0/0 | +0.00 | -2.00 | +0.00 |  |  |
| `connectors/sonas/hook.js` | 0.5/0 | 3.5/0 | 3.0/1 | 5.0/0 | +0.00 | -1.77 | -1.00 |  |  |
| `connectors/spar/api/parse.js` | 1.0/1 | 3.5/2 | 2.0/0 | 6.5/45 | +0.00 | -0.51 | -1.26 |  |  |
| `connectors/spar/api/upsert.js` | 1.0/1 | 3.5/2 | 2.0/1 | 7.0/65 | +0.00 | -0.51 | -0.63 |  |  |
| `connectors/spar/credentials.js` | 0.5/0 | 5.0/0 | 1.0/0 | 8.0/0 | +0.00 | -2.10 | -0.63 |  |  |
| `connectors/square/api/upsert.js` | 1.0/1 | 4.0/1 | 1.5/1 | 6.0/5 | +0.00 | -1.26 | -0.37 |  |  |
| `connectors/tiktok/api/auth-bootstrap.js` | 0.0/0 | 2.0/0 | 3.0/3 | 2.5/0 | +0.00 | -1.26 | +0.00 |  |  |
| `connectors/tiktok/api/tiktok-client.js` | 3.0/3 | 6.0/4 | 1.5/1 | 11.0/9 | +0.00 | -0.37 | -0.37 |  |  |
| `connectors/tiktok/credentials.js` | 0.5/0 | 4.5/0 | 0.5/0 | 7.5/0 | +0.00 | -2.00 | +0.00 |  |  |
| `connectors/xero/api/upsert.js` | 1.0/1 | 4.0/2 | 1.5/1 | 6.5/28 | +0.00 | -0.63 | -0.37 |  |  |
| `connectors/xero/hook.js` | 0.5/0 | 3.0/0 | 3.0/1 | 4.5/0 | +0.00 | -1.63 | -1.00 |  |  |
| `server/app.js` | 0.5/0 | 15.0/5 | 41.0/16 | 27.5/8 | +0.00 | -1.00 | -0.86 |  |  |
| `server/shared/deepseek.js` | 2.0/2 | 4.5/3 | 2.5/2 | 7.0/18 | +0.00 | -0.37 | -0.20 |  |  |
| `spheres/coord/ui/windows.tsx` | 2.0/2 | 4.5/2 | 4.5/3 | 5.5/8 | +0.00 | -0.74 | -0.37 |  |  |
| `spheres/customer-service/api/policy.js` | 1.0/1 | 2.5/1 | 0.5/0 | 4.5/4 | +0.00 | -0.83 | +0.00 |  |  |
| `spheres/customer-service/ui/sphere.tsx` | 0.5/0 | 7.5/0 | 3.5/2 | 9.5/0 | +0.00 | -2.46 | -0.51 |  |  |
| `spheres/financial/ui/fy.ts` | 1.0/1 | 3.0/3 | 4.0/2 | 4.5/63 | +0.00 | +0.00 | -0.63 |  |  |
| `spheres/financial/ui/views/Deals.tsx` | 1.0/1 | 2.5/0 | 4.0/4 | 2.5/0 | +0.00 | -1.46 | +0.00 |  |  |
| `spheres/financial/ui/window.ts` | 1.0/1 | 3.0/2 | 3.0/1 | 4.5/20 | +0.00 | -0.37 | -1.00 |  |  |
| `spheres/library/ui/sphere.tsx` | 0.0/0 | 8.0/0 | 3.5/3 | 11.0/0 | +0.00 | -2.52 | -0.14 |  |  |
| `spheres/partnership/ui/sphere.tsx` | 0.0/0 | 7.0/0 | 3.0/3 | 10.5/0 | +0.00 | -2.40 | +0.00 |  |  |
| `spheres/partnership/ui/views/Campaigns.tsx` | 1.0/1 | 2.0/0 | 6.0/3 | 3.0/0 | +0.00 | -1.26 | -0.63 |  |  |
| `spheres/projects/ui/sphere.tsx` | 0.5/0 | 8.5/0 | 3.5/2 | 11.5/0 | +0.00 | -2.58 | -0.51 |  |  |
| `spheres/publicity/api/statements.js` | 1.0/1 | 3.0/0 | 1.5/0 | 4.5/0 | +0.00 | -1.63 | -1.00 |  |  |
| `spheres/publicity/ui/sphere.tsx` | 0.0/0 | 7.0/0 | 3.0/3 | 9.0/0 | +0.00 | -2.40 | +0.00 |  |  |
| `spheres/publicity/ui/views/Campaigns.tsx` | 1.0/1 | 2.5/0 | 5.0/4 | 3.5/0 | +0.00 | -1.46 | -0.20 |  |  |
| `spheres/relationships/ui/sphere.tsx` | 0.0/0 | 7.5/0 | 3.0/3 | 10.0/0 | +0.00 | -2.46 | +0.00 |  |  |
| `spheres/reputation/api/policy.js` | 1.0/1 | 2.5/0 | 0.5/0 | 4.5/0 | +0.00 | -1.46 | +0.00 |  |  |
| `spheres/reputation/ui/ReviewCard.tsx` | 2.0/2 | 4.0/3 | 5.0/5 | 6.0/22 | +0.00 | -0.26 | +0.00 |  |  |
| `spheres/reputation/ui/sphere.tsx` | 0.0/0 | 7.0/0 | 3.5/3 | 9.5/0 | +0.00 | -2.40 | -0.14 |  |  |
| `spheres/schedule/ui/EntryEditor.tsx` | 1.0/1 | 2.5/2 | 5.0/2 | 4.5/9 | +0.00 | -0.20 | -0.83 |  |  |
| `spheres/schedule/ui/slots.tsx` | 1.0/1 | 2.5/2 | 3.0/2 | 3.5/10 | +0.00 | -0.20 | -0.37 |  |  |
| `spheres/social/ui/PerformanceChart.tsx` | 1.0/1 | 3.5/1 | 4.5/3 | 6.5/5 | +0.00 | -1.14 | -0.37 |  |  |
| `spheres/social/ui/sweep.ts` | 2.0/2 | 4.0/2 | 3.5/1 | 5.0/4 | +0.00 | -0.63 | -1.14 |  |  |
| `spheres/social/ui/useUnreadNotifier.ts` | 1.0/1 | 3.5/1 | 3.0/2 | 6.0/3 | +0.00 | -1.14 | -0.37 |  |  |
| `web/src/app/AccessApps.tsx` | 1.0/1 | 3.0/2 | 6.5/4 | 3.5/8 | +0.00 | -0.37 | -0.44 |  |  |
| `web/src/app/AccessRoles.tsx` | 1.0/1 | 3.0/3 | 5.5/4 | 5.0/5 | +0.00 | +0.00 | -0.29 |  |  |
| `web/src/lib/overseer.ts` | 2.0/2 | 3.5/3 | 2.0/1 | 6.0/5 | +0.00 | -0.14 | -0.63 |  |  |
| `web/src/main.tsx` | 0.5/0 | 2.0/0 | 4.0/2 | 3.0/0 | +0.00 | -1.26 | -0.63 |  |  |

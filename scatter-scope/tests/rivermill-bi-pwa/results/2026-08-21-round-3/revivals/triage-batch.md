# Triage batch — round 3, remaining 63 flags

Nine flags are revived individually elsewhere and are excluded here. Every other flagged row is
disposed below, in seven groups, each closed by the same cause. All numbers came from
`bfiles.py` on the exact vocabulary/B-file lists in `measured.json`, cross-checked against the
repository with read-only `grep`/`Read`. No row required a fresh revival context: each group's
cause is legible from the vocabulary column alone or from one grep confirming a mechanism named
in `method-notes.md` or `scope-methodology.md`.

## A — Sibling/family interface convention (by design)

Several spheres and every connector implement a same-named function on purpose: `loadVocab` on
every sphere's `instance.js`, `prelink`/`stagePassDue`/`reconstructDue` living beside each
sphere's own `instance.js`, `accessToken` as the field every connector client carries,
`getEntry`/`shiftEnd`/`isISODate` as schedule's own provider-family helpers, `runSyncMain` wiring
a per-connector `sync.js` to its sibling `client`/`upsert`/`credentials` files. This is exactly
the Survey's "several files define a name — the interface of a family of sibling modules" case:
the B/leak count is the family's contract, read by its own members, not a second encoding
outside the module.

## B — Platform-wide kit, read widely because that is its job (by design)

`credentials.js`, `connector-tenant.js`, `sync-runs.js`, `spar-pipeline.js` (its own header says
"written once so a second sphere composes it instead of cloning"), `job-runs.js`, `access.js`
(one real import, `dispatch.js`'s `gate()`; the rest is prose about the single chokepoint), and
`testdb.js` (its `withTxn` sites are almost entirely test files, the standard test-transaction
helper) are server-side infrastructure meant for every connector or sphere to call. On the web
side, `url-state.ts`, `AuthGate.tsx`, `ReachNote.tsx`, `CtxMenu.tsx`, `FilterBar.tsx`,
`GroupedList.tsx`, `HoverTip.tsx`, `SearchInput.tsx` and `click-log.js`/`agent/drive-tools.js`
(a deliberate label-naming echo between the agent backend and its web display) are UI kit pieces
mounted on nearly every sphere's views. `CtxMenu.tsx`'s count is inflated further by "viewport"
(CSS/meta homonym, unrelated to the component) but the widget's own reuse across Rolodex,
CampaignBoard, CampaignWizard and Board.tsx is real and expected.

## C — Sphere-internal fan-out (by design)

A sphere's own `api.ts`/`components.tsx`/view file, read only by that sphere's own other view
files, is the module boundary working as intended — the sphere, not the file, is the unit. Social,
coord, schedule, financial and customer-service's `api.ts` files are consumed by their own
`views/*.tsx`; `components.tsx` has leak = 0. `Rolodex.tsx`'s D-high is legitimate composition
(15 small UI-kit imports) and its heaviest B-file, `PeopleSection.tsx`, is explained in the code's
own comment: "their codecs live with PeopleSection, which owns them." `shortcode.js` serves the
Instagram/Facebook ingestion pipeline it was built for. `import-meta-exports.mjs`'s count is
mostly its own test (52/103 sites). `ChatPane.tsx` is a small app component with the expected
handful of call sites.

## D — Genuinely narrow, more sealed than the blind guess (by design)

Grep confirmed real, small consumer sets for `connector-health.js` (1: `credentials.js`),
`trail.js` (3: `auth.js`, `dispatch.js`, `access.js`), `model-api.js` (2: `deepseek.js`,
`stage-advance.js`), `contract-helpers.js` (3 connector `jobs.js` files),
`credential-manifests.js` (1 script), `highlight.ts`, `useDoorbell.ts`, `chat-icon.tsx`,
`locale.ts` and `reconcile.js` (each 1-4 call sites). `agent/server.js` is the agent process's own
entrypoint, run directly and never imported, the same pattern as `server/app.js`. The Oracle
guessed a wider surface than these modules actually have; nothing in the code disagrees.

## E — Dynamic `import()` blind spot (artefact)

`server/app.js` loads `http-json.js`, `ready.js`, `contract.js`, `party.js`, `events.js` and
`error-codes.js` with a string-literal `import('./shared/X.js')` inside its startup
`Promise.all`. `method-notes.md` names exactly this as invisible to a static SCIP index. Each
module's low measured A is the instrument's blind spot, not a sealed or scattered module; the
real importer is there, just unreadable to the indexer.

## F — Homonym or generic word doing the counting alone (artefact)

`publicity/ui/api.ts`'s B is 125/168 sites of `created_at`, the schema's generic timestamp column
on every table, not the Coverage concept the module actually defines. `Labour.tsx`'s leak is the
plain business word "Labour" in CSS, docs and a connector file about the labour-cost domain, not
reuse of the component. `Gantt.tsx`'s only distinctive word is the generic chart-type name
"Gantt," and its leak is documentation describing the concept. `web/src/app/spheres.ts` has no
distinctive vocabulary left after the filter (a B floor of zero), so its A-low flag is unrelated
to real usage.

## G — Unindexed Tcl tier speaking the same vocabulary (artefact)

`refresh-meta-recent.mjs`'s `skillRef`/`runSkill` are read overwhelmingly (77 of 101 sites) by
`desktop/ducks/*.tcl` — the overseer tier the run's index cannot cover. This is the run notes'
named blind spot, not scattering.

| module | flags | disposition | reason |
|---|---|---|---|
| spheres/social/api/instance.js | B high, leak | by design | sibling `instance.js` interface (`loadVocab`) |
| spheres/coord/api/instance.js | B high, leak | by design | same interface; `prelink` lives in coord's own `prelink.js` |
| spheres/coord/prelink.js | A low | by design | coord's own sibling helper |
| spheres/social/api/stage-pass.js | A low | by design | narrow cross-sphere helper (publicity's `instance.js`) |
| spheres/coord/reconstruct.js | A low | by design | no distinctive vocabulary (B floor); A near expectation |
| server/shared/pipeline-fixture.js | A high | by design | kit composed once per sphere (social/publicity) |
| connectors/xero/api/xero-client.js | B high, leak | by design | `accessToken` is the connector-family's shared field name |
| spheres/schedule/api/providers/local.js | A high | by design | provider-family sibling (rezdy.js shares the functions) |
| spheres/schedule/api/valid.js | A high | by design | schedule's own validators used by its own api files |
| connectors/awsconnect/api/sync.js | A high | by design | job-listing convention shared with desktop job tooling |
| connectors/rezdy/sync.js | D high (hub) | by design | per-connector sync orchestrator, standard scaffold |
| connectors/sonas/sync.js | D high (hub) | by design | same |
| connectors/tiktok/insights-sync.js | D high (hub) | by design | same |
| web/src/lib/url-state.ts | B high | by design | platform URL-state hook |
| web/src/app/AuthGate.tsx | B high | by design | app-wide auth context |
| web/src/ui/ReachNote.tsx | A high, B high | by design | banner mounted on nearly every sphere view |
| web/src/ui/CtxMenu.tsx | B high | by design | UI kit widget; "viewport" homonym inflates B further |
| web/src/ui/FilterBar.tsx | A low | by design | filter-kit widget reused across sphere views |
| web/src/ui/GroupedList.tsx | A low | by design | list-layout kit reused across spheres |
| web/src/ui/HoverTip.tsx | A low | by design | tooltip kit reused (Rolodex) |
| web/src/ui/SearchInput.tsx | A low | by design | small kit input reused by SearchBar |
| server/shared/credentials.js | A high, B high | by design | credential kit called by every connector |
| server/shared/connector-tenant.js | B high | by design | `tenantOf` called by every connector `sync.js` |
| server/shared/sync-runs.js | B high | by design | sync-run kit called by every connector hook/sync |
| server/shared/spar-pipeline.js | B high, leak | by design | documented shared pipeline kit, 3 spheres compose it |
| server/shared/job-runs.js | B high | by design | job bookkeeping kit, called across app.js and jobs |
| server/shared/access.js | A low | by design | single chokepoint (dispatch.js), rest is prose |
| server/shared/testdb.js | B high | by design | shared test-transaction helper |
| server/shared/click-log.js | B high, leak | by design | prose + cross-tier naming twin (web/lib/clicklog.ts) |
| agent/drive-tools.js | B high | by design | tool-name convention shared with web display labels |
| spheres/social/ui/api.ts | A high, B high | by design | in-sphere fan-out; "tiktok" homonym adds to B |
| spheres/social/ui/components.tsx | A high | by design | sphere's own UI-kit file, leak = 0 |
| spheres/coord/ui/api.ts | B high | by design | in-sphere fan-out |
| spheres/coord/ui/views/ByPerson.tsx | A high | by design | trivial in-sphere view registration |
| spheres/schedule/ui/api.ts | B high | by design | in-sphere fan-out |
| spheres/financial/ui/period.ts | A high | by design | in-sphere fan-out |
| spheres/customer-service/ui/api.ts | A low | by design | in-sphere + shared field names with its AWS Connect source |
| connectors/instagram/api/shortcode.js | B high | by design | serves the Meta ingestion pipeline it was built for |
| spheres/social/ui/Rolodex.tsx | B high, D high (hub) | by design | container/child split, documented in the file's comment |
| web/src/app/ChatPane.tsx | B high | by design | small app component, expected call sites |
| scripts/import-meta-exports.mjs | B high | by design | mostly its own test file |
| server/shared/connector-health.js | A low | by design | narrow: 1 real consumer (credentials.js) |
| server/shared/trail.js | A low | by design | narrow: 3 real consumers |
| server/shared/model-api.js | A low | by design | narrow: 2 real consumers |
| server/shared/contract-helpers.js | A low | by design | narrow: 3 connector jobs.js |
| server/shared/credential-manifests.js | A low | by design | narrow: 1 script |
| web/src/ui/highlight.ts | A low | by design | narrow: 1 cross-tier caller |
| web/src/lib/useDoorbell.ts | A low | by design | narrow: App.tsx only |
| web/src/app/chat-icon.tsx | A low | by design | sealed, leak = 0, one sibling consumer |
| web/src/lib/locale.ts | A low | by design | small i18n utility, few bootstrap call sites |
| spheres/schedule/reconcile.js | A low | by design | sealed, only its own test |
| agent/server.js | A low | by design | process entrypoint, never imported |
| server/shared/http-json.js | A low | artefact | dynamic `import()` in server/app.js |
| server/shared/ready.js | A low | artefact | same |
| server/shared/contract.js | A low | artefact | same |
| server/shared/party.js | A low | artefact | same |
| server/shared/events.js | A low | artefact | same |
| server/shared/error-codes.js | A low | artefact | same |
| spheres/publicity/ui/api.ts | B high, leak | artefact | "created_at" generic column, not the Coverage concept |
| spheres/financial/ui/views/Labour.tsx | B high | artefact | "Labour" is a generic domain word |
| spheres/projects/ui/views/Gantt.tsx | B high | artefact | "Gantt" is a generic chart-type name |
| web/src/app/spheres.ts | A low | artefact | no distinctive vocabulary (B floor) |
| scripts/refresh-meta-recent.mjs | B high | artefact | desktop/*.tcl overseer tier, unindexed |

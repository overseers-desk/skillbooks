# Revival: server/shared/datasets.js

**Instrument check first.** 336 of 388 sites (87%) are the bare word `datasets`; the other three vocabulary words (servedDatasets, DATASETS, knownDataset — the module's actual exports) total only 52. That single word carries almost the whole count, so I read its carriers.

Checked one by one: `dispatch.test.js` (61), ten spheres' `api/read.js` files (76 combined), `party.js`, `spar-pipeline.js`, `chat.js`, `access.js`, `contract.js`, `walls.js`. None import `datasets.js`. All of them write or read the object-literal key `datasets:` on a route-declaration spec — a contract dispatch.js itself defines and validates (`{ fn, datasets, verb? }`), not this module's export. It is a same-spelled, different-owner identifier: a homonym, not a use. `docs/access-control.md`, `schema.sql`, and `web/src/lib/auth.ts`'s `ServedDataset` type (used by AccessRoles.tsx/AccessPeople.tsx, 44 sites) are prose, schema, and a sibling tier restating server shape client-side — by design, since the browser cannot import server code.

The real dependency graph is exactly what static analysis found dynamically-blind: grants.js, dispatch.js, and app.js's `import()` — A=3, D=0, both correct; datasets.js is a leaf vocabulary file with no imports of its own.

**Verdict: artefact.** The 45-file leak is grep matching a common route-spec field name that happens to share this module's own headline word.

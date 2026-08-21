# Decided-once facts — expected against measured

The three blind estimators each named twelve facts a program of this description decides once,
with the number of places they would expect to edit if the fact changed (their `FACT` lines are
at the foot of `e1.md`, `e2.md`, `e3.md`). Where two or three named the same fact, the expected
figure is their median; where one named it alone, it is that one's figure and the row says so.

The measured side is stated twice, because estimators answer the first and a grep answers the
second: **decided in** — the files that define the fact — and **obeyed in** — the files that
assume it. Every probe names the homonyms it excludes. A fact whose only handle is a common word
is recorded as not measured rather than given a number.

| fact | expected | decided in | obeyed in | gap | disposition |
|---|---:|---:|---:|---|---|
| the pipeline stage vocabulary (`stage_code`) | 8 (4/8/12) | 2 — `server/shared/schema.sql`, `server/shared/stage-vocabulary.js` | **47 files, 232 sites**; 24 outside tests and docs | **×6 up** | **scattered** — see below |
| every row and route is scoped by tenant | 60 (e2 alone; e1 and e3 named the narrower union view, 6) | 2 — `server/shared/tenancy.js`, the `tenant` column in `server/shared/schema.sql` | **306 files, 5 560 sites**; 173 outside tests and docs | ×2.9 up | by design — the platform's stated commitment; a cross-cutting fact no single module could hold |
| the error-code vocabulary shared by server, client and assistant | 4 (2/4/10) | **3** — `server/shared/error-codes.js`, `web/src/lib/error-codes.ts`, `agent/error-codes.js` | 34 files | ×2.4 up on obeyed; **3 homes** where estimators expected 1 | by design, with a cost: three tiers that cannot import each other keep three copies of one list, and e3 predicted exactly that ("duplicated server-side and client-side by design") |
| a sphere joins by dropping in a descriptor file | 2 (1/2/14) | 2 — `web/src/app/spheres.ts` (`import.meta.glob('../../../spheres/*/ui/sphere.tsx')`), `server/app.js` (`discoverSpheres`) | 22 — 11 `ui/sphere.tsx` + 11 `api/instance.js`; 19 files mention the glob | inside the band on the deciding side | by design — the obeyed side is one file per sphere, which is the convention working, not scatter |
| a connector registers its own background work | 1 (e3) / 5 (e1) | 1 — `server/app.js` (`discoverConnectorJobs`, the `hook.js` walk) | 12 `hook.js`/`jobs.js` + 17 credential declarations | inside the band | by design |
| the credential shape a connector declares | 3 (2/3/20) | 1 — `server/shared/credential-manifests.js` | 17 connector `credentials.js` declarations, 4 consumers | inside the band on consumers | by design — one manifest reader, N declarations |
| the grant-token grammar deciding what a role may see | 10 (3/10/15) | 1 — `server/shared/grants.js` | 5 files use `parseGrants`/`needVerb`/`DATA_TOKEN`/`VERB_ORDER` | ×0.5 (below) | by design — sealed better than expected. The bare word `grants` appears in 92 files and is **not measured**: it is a homonym of the route-spec vocabulary |
| which month a tenant's financial year opens on | 3 (e3 alone) | 1 — `spheres/financial/ui/fy.ts` (`FY_START_MONTH`, `fyStartFor`) | 4 — `period.ts`, `PeriodPicker.tsx`, `letterhead.ts`, its test | inside the band | by design |
| the assistant sits on every screen without owning a domain | 12 (e3 alone) | 2 — `web/src/app/ChatPane.tsx`, `web/src/app/App.tsx` | 15 files | inside the band | by design |
| sign-in is a passwordless email code | 8 (e2 alone) | 1 — `server/shared/auth.js` | 9 files, split server (`auth.js`, `schema.sql`, `error-codes.js`) and client (`AuthGate.tsx`, `lib/auth.ts`) | inside the band | by design |
| the product's working name | 40 (1/40/40) | 1 — `README.md` | 2 files, 3 sites | **×13 down** | by design, and the estimators' largest miss in the other direction: the name has not been spent into the code, exactly as the README says it should not be |
| the dataset vocabulary naming what a route may expose | 10 (3/10/10) | 1 — `server/shared/datasets.js` | 3 by type; the `datasets:` route-spec key appears in ~45 more, but that key is `dispatch.js`'s contract, not this module's export | — | **not measured as one fact**: the two are homonyms, which is the artefact the `datasets.js` revival traced |

## The flagged fact: the pipeline stage vocabulary

`stage_code` is measured in 47 files and 232 sites, 24 of them outside tests and docs: the
platform schema, `stage-vocabulary.js`, `stage-advance.js`, five spheres' `api/statements.js`,
four spheres' `api/read.js`, two spheres' `db/schema.sql`, five dated migration scripts, and the
web tier's `pipeline/api.ts` and `ContactPanel.tsx`. Estimators expected eight places.

The mechanism is visible in the files' own comments, and it is a deliberate trade rather than an
oversight. The write SQL for a stage flip is one statement:

```
INSERT INTO pipeline_stage_flips (tenant, sphere, member, stage_code, actor, note)
  VALUES (?, '<sphere>', ?, ?, ?, ?)
```

and it is written out five times — `spheres/social`, `publicity`, `partnership`,
`financial`, `projects` — identical but for the sphere literal, alongside an identically
duplicated `pipeline_contact_notes` upsert. Each file says why: *"The text lives here,
in-sphere, because the shared schema-conformance test scans `spheres/*/api` for INSERT/UPDATE
column lists against this sphere's net."* The conformance net's scan location is what forces the
copies: a statement that lived once in `server/shared/` would sit outside the net.

The cost is exact and paid per change: adding a column to `pipeline_stage_flips`, or renaming
`stage_code`, is five hand-edits in five spheres before any shared code is touched, and nothing
but the conformance test catches a sphere that is missed. The disposition is **scattered with a
named reason** — the owner's decision is whether the net is worth five copies, or whether the
net should learn to scan a shared statements module.

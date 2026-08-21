# SCOPE — round 3 on `rivermill-bi-pwa`

One codebase measured once: 384 non-test module concepts and twelve decided-once facts, each
measured four ways and set against what three blind estimators expected of a program with this
README. 72 modules fell outside a factor of three in some figure; nine were revived
individually by the estimator furthest off, 63 triaged in one context, and every decided-once
fact probed by grep or by reading the code.

**One finding survives**: a stage vocabulary whose write statements are copied into five
spheres, by a stated trade the owner may want to revisit. Everything else closed **by design**
or as an **artefact** of the measurement. That is the honest shape of this run: the repository
is unusually well sealed for its size, and it says so in its own comments.

---

## 1. The finding: the pipeline stage vocabulary is decided in five spheres at once — **scattered**

**The gap.** Estimators expected the pipeline's stage vocabulary to be decided in about eight
places (4, 8, 12). Measured: `stage_code` appears in **47 files and 232 sites**, 24 of them
outside tests and documentation — the platform schema, `server/shared/stage-vocabulary.js`,
`stage-advance.js`, five spheres' `api/statements.js`, four spheres' `api/read.js`, two spheres'
`db/schema.sql`, five migration scripts, and the web tier's `pipeline/api.ts` and
`ContactPanel.tsx`. A ×6 gap on the obeyed side.

**The mechanism**, checked by the runner directly against the code. The write SQL for a stage
flip is one statement, and it is written out five times:

```
INSERT INTO pipeline_stage_flips (tenant, sphere, member, stage_code, actor, note)
  VALUES (?, '<sphere>', ?, ?, ?, ?)
```

in `spheres/social`, `publicity`, `partnership`, `financial` and `projects` — identical but for
the sphere literal, with an identically duplicated `pipeline_contact_notes` upsert beside it.
The files say why, in their own words: *"The text lives here, in-sphere, because the shared
schema-conformance test scans `spheres/*/api` for INSERT/UPDATE column lists against this
sphere's net."* The conformance net's **scan location** is the mechanism: a statement written
once in `server/shared/` would sit outside the net that checks column lists against a schema.

**The cost, exactly.** Adding a column to `pipeline_stage_flips`, or renaming `stage_code`, is
five hand-edits in five spheres before any shared code is touched — and the only thing that
catches a sphere missed is the same conformance test that forced the copies. The trade is
deliberate and documented; what it is not is free, and the run's numbers put a figure on it.

**What the owner decides**: whether five copies are the right price for the net, or whether the
net should learn to scan a shared statements module. SCOPE does not answer that; it measures it.

**A note on how this was reached.** The module-level flag that led here —
`web/src/pipeline/api.ts`, B = 99 against an expected 8.5 — was closed **by design** by its
revival, correctly: as a *client*, that module is one shared surface five spheres reuse rather
than clone. The runner followed the same vocabulary to its write side and found the duplication
there. The revival was not wrong; it was asked about the module, and the concept is wider than
the module. Recorded here as a limit of a per-module question (§5).

## 2. What closed **by design**

Fifty-two of the 63 triaged flags and four of the nine revivals. The families:

- **The connector contract.** `loadConfig` has 16 homes, `timeoutMs` 14, `nowMysql` 11,
  `runSyncPass`, `httpRaw`, `defaultSleep`, `INTERVAL_MIN` and `MAX_RETRY_AFTER_MS` nine each.
  This is the convention table doing its job: a name repeated across sibling modules is the
  interface of a family, not a smear. Seventeen connectors implement one shape.
- **Platform kit.** `credentials.js`, `connector-tenant.js`, `sync-runs.js`, `spar-pipeline.js`
  (whose own header reads "written once so a second sphere composes it instead of cloning"),
  `job-runs.js`, and on the web side `url-state.ts`, `AuthGate.tsx`, `ReachNote.tsx`,
  `CtxMenu.tsx`, `FilterBar.tsx`. Read widely because that is the job.
- **Sphere-internal fan-out.** A sphere's own `api.ts` read by that sphere's own views. The
  sphere, not the file, is the unit; both D-flagged view hubs (`ProfitAndLoss.tsx` D = 19,
  `CampaignBoard.tsx` D = 16) turned out to be glue — kit widgets and sibling modules — with the
  arithmetic, the drag protocol and the wizard's state machine each living elsewhere. Neither
  was closed on its doc line; both revivals listed the imports region by region first.
- **`server/shared/runbook.js`** (B = 60 against 6): prose, `jobs.manifest.yaml` and `schema.sql`
  declarations, and a **sibling Tcl desktop client** that loads and runs runbooks in a runtime
  that cannot import JavaScript. A lower tier speaking the same vocabulary is by design.
- **`web/src/lib/auth.ts`** (B = 109 against 12): the Access-admin wire surface, whose field
  names mirror a schema-wide provenance convention (`added_by`, `updated_by`, `started_at`,
  `elapsed_ms`) that every connector's `sync.js` also stamps.
- **The error-code vocabulary in three homes.** Estimators expected one home; there are three —
  server, web and the agent tier — because the three deploy apart and cannot import each other.
  This is a duplication with a guard: `error-codes.test.js` scans the agent tree for emitting
  sites, the web test pins completeness in both directions, and the web map is
  `Record<ErrorCode, MessageDescriptor>` so a missing sentence is a compile error. e3 predicted
  this exact arrangement blind. No finding, and the guard is why.
- **Facts that landed inside the band**: the sphere-discovery convention (decided in 2, obeyed
  by one descriptor file per sphere), connector self-registration, the credential shape, the
  financial-year opening month, the assistant panel, passwordless sign-in, and the grant-token
  grammar — which measured *narrower* than expected (5 places against 10).

## 3. What the instrument got wrong

Eleven triaged flags and five of the nine revivals were the measurement, not the code.

**3.1 The dynamic-`import()` blind spot accounts for every serious "A low".** `server/app.js`
loads its shared modules through `import('./shared/X.js')` inside one boot bundle and discovers
spheres and connectors by listing directories. A SCIP index cannot follow either edge. So
`auth.js` measures A = 3 against an expected 15, `contract.js` A = 1 against 22, `http-json.js`
A = 1 against 17.5, and `ready.js`, `party.js`, `events.js`, `error-codes.js` the same way. The
revival counted the real consumers by hand and found `server/app.js` using `auth.js` at a dozen
sites. The run notes named this before Pick ran, and the flags were filtered against it.

**3.2 Homonyms carry four of the five artefact revivals.**
`server/shared/datasets.js`: 336 of 388 sites are the bare word `datasets`, and every heavy
carrier uses it as the `datasets:` key on `dispatch.js`'s route-declaration contract — a
same-spelled, different-owner identifier. `spheres/relationships/ui/api.ts`: `linkedin` carries
253 of 422 sites and mostly names the LinkedIn *connector*.
`spheres/schedule/api/providers/rezdy.js`: the stem `rezdy` is 266 of 275 sites and conflates
this provider with `connectors/rezdy/` and a `'rezdy'` source label used as a data tag.
`spheres/publicity/ui/api.ts`: 125 of 168 sites are `created_at`, the schema's generic timestamp
column. In each case the vocabulary rule kept a word the concept does not own alone.

**3.3 The unindexed Tcl tier inflates one count.** `scripts/refresh-meta-recent.mjs` has 77 of
its 101 sites in `desktop/ducks/*.tcl`, a tier in the grep corpus but invisible to the index, so
its mentions can only ever land in B.

**3.4 The B floor did its job.** 99 of 384 modules had no distinctive vocabulary after the
filter; their B was not measured and they never flagged on it. `web/src/app/spheres.ts`, flagged
A-low with B = 0, is one of them: a floor, not hiding.

## 4. Calibration, re-checked against the record

| figure | inside ±1 log₃ | median gap | the record says | this run |
|---|---|---|---|---|
| **A** | 346/384 (90%) | +0.00 | calibrates best | reproduced exactly |
| **D** | 316/384 (82%) | −0.37 (×0.7) | calibrates well, flags upward only | reproduced; estimators guess out-degree slightly high |
| **B** | 202/384 (52%) | −0.55 (×0.5) | calibrates in its upper range | reproduced; the low half is the floor, and B flags upward only |
| **C** | 133/384 (34%) | **+0.23 (×1.3)** | does not calibrate; estimators under-guess sites several-fold | **partly contradicted**: still the widest spread, but the median under-guess was ×1.3 this round, not several-fold |

B flags reached 32 of 384 rows, **8% of the table** — below the share at which the methodology
says a run is reading its instrument rather than its code. That is the licence this run had to
revive at all, and it is a change from the previous round on this repository, where B fell
inside the band for only 45%: the vocabulary rules committed at tools commit `15caa5d` are
visible in the difference (B is only comparable across runs at one tool version, which both
rounds share only for this comparison's purpose — read it as directional).

The one line in the record this run did not reproduce is C's uniform several-fold under-guess.
C was printed as density and never picked on, as the method requires, so nothing rests on it;
but the record should note that on a JavaScript tree with a large prose corpus, C's median came
out near agreement while its spread stayed wide.

## 5. What the method could not see on this codebase

- **The Tcl tier.** 32 tracked `.tcl`/`.tm` files, roughly 16 000 lines of the overseer desktop
  client, have no SCIP indexer here. They are in the grep corpus, so they can inflate another
  module's B, but they have no A and no D of their own and nothing in that tier was measured as
  a concept. A scattering *inside* the overseer would be invisible to this run.
- **29 `.design-sync/previews/*.tsx`, 5 `web/` build and catalog scripts, 4 migration `.mjs`,
  1 test double** — tracked, hand-written, outside both tsconfigs.
- **Runtime discovery**, per §3.1: the shell's own wiring is not in the graph at all.
- **The concept wider than its module.** §1's finding was reached because the runner followed a
  module's vocabulary into files that define no part of it. The per-module question asks "who
  uses this file's names"; it does not ask "who else writes this concept's SQL". The
  decided-once list is the method's answer to that, and it is only as good as the facts the
  estimators happen to name — here, one of the twelve.
- **Prose weight.** 105 markdown files in a 1046-file corpus. This repository documents itself
  heavily, which is why so many B counts are prose, and why "is one word doing the work" was the
  question that closed most flags.

## 6. Artefact index

| artefact | file |
|---|---|
| Run notes: indexer, tiers, corpus rule and exclusions, tools commit, model tiers, blind spots | `method-notes.md` |
| Concept list: modules with vocabulary, convention table, decided-once facts | `concept-list.md` |
| Measured table: A, D, B, C, leak, score per module; conventions | `measured-table.md`, `measured.json` (full vocabulary per module) |
| Oracle brief (blind; README, sizes, doc list, module list with each module's own doc line) | `oracle-brief.md`, generated by `mkbrief.py` |
| Estimator replies, blind, three of them | `e1.md`, `e2.md`, `e3.md` |
| Pick table: expected, measured, gap, flags, disposition (all 72 filled) | `pick-table.md`, `pick.json` |
| Decided-once facts: expected against measured, decided-in and obeyed-in, homonyms excluded | `pick-facts.md` |
| Revival reports, nine, each verifying the count before the cause | `revivals/e*.md` |
| Batch triage of the remaining 63 flags, one context | `revivals/triage-batch.md` |
| Helpers: index merge, corpus check, B-file lister, brief generator, server tsconfig | `merge.py`, `corpuscheck.py`, `bfiles.py`, `mkbrief.py`, `servercfg-tsconfig.json` |
| Index and bulk output (outside the repository and the run folder) | `/usr/local/ai/scope/round-3/` |

## 7. Cost

| | |
|---|---|
| Agents | 4 spawned: three blind estimators (cheap tier, fresh context, one file read each) and one triage context. The three estimators were **revived** three times each — nine revivals in their own original contexts — so 13 agent turns in total. |
| Indexing | two `scip-typescript` passes, 7 s each; 546 documents |
| Count | one pass over a 1046-file corpus, ~2 minutes |
| Wall time | 27 minutes end to end (15:07-15:34), of which the three blind estimates ran ~3 minutes in parallel, the nine revivals ~4 minutes in three parallel waves, and the triage context 10 minutes |
| Repository | not modified: `git status` unchanged, one pre-existing untracked file, nothing written into the tree |

## 8. Invariants

- **I1** — the oracle saw no code and no count: `oracle-brief.md` holds the README, size facts,
  the doc list and the module list with each module's own doc line, and nothing else. Each
  estimator was permitted one file read and forbidden every other tool call.
- **I2** — every flag on `pick-table.md` carries expected, measured and the gap; no concept was
  flagged on a measured figure alone.
- **I3** — every revival states the instrument check before the cause; five of the nine ended by
  indicting the measurement.
- **I4** — "by design" closed 52 triaged flags and four revivals, and is a full answer.
- **I5** — no noun of this codebase appears in the methodology folder; this report is where the
  instances live.

# SCOPE Audit bibi Platform

The audited codebase is `rivermill-bi-pwa` at commit `7d44b9ce` — the business platform the README calls
**bibi**: about 1 050 tracked files, 726 of them source, roughly 115 000 lines of JavaScript and TypeScript
in a server tier, a web app and eleven spheres, plus about 16 000 lines of Tcl in a desktop client. The
repository was not modified: nothing was written into the tree, and `git status` shows the same single
pre-existing untracked file before and after.

## What SCOPE measures, and how to read a figure

SCOPE looks for concepts this program decides in more places than it should — the ones where a single
intention costs N edits, and nobody knows N until they try. Each of the 384 non-test modules is measured
four ways: **A**, the files that use its types; **D**, the files whose types it uses; **B**, the files
that mention any of its distinctive names anywhere, including comments, docs, SQL and manifests; **C**,
the total number of such mentions. A and D come from a symbol index, B and C from grep over the tree as
a reader meets it after a clone. Beside the modules sit twelve **design facts** — things the program
decides once, like "which month a financial year opens on" — measured as *decided in* (the files that
define the fact) and *obeyed in* (the files that assume it).

A count on its own is not a finding: configuration is read everywhere by design, and a protocol
adapter read by one file is healthy. So beside every figure is what three estimators expected —
each given the README, the package sizes and each module's own one-line doc, and no code and no
counts, the median of the three taken. **The gap is the only thing this audit works on.**
Agreement is a factor of three either way; 72 modules fell outside it in some figure. Nine were
taken one at a time, the count checked first and then the code read for the cause; the other 63
were triaged together against the measured table. Every design fact was probed by grep or by
reading the code. Each gap closes one of three ways: **by design**, the spread is the concept's
job, as with a shared kit or a convention every sibling implements; **artefact**, the measurement
was wrong, not the code; **scattered**, the concept really is decided in more places than it
should be, and the mechanism and its per-change cost are named.

**One finding survives**: a stage vocabulary whose write statements are copied into five spheres, by a
stated trade the owner may want to revisit. Everything else closed by design or as an artefact. That is
the honest shape of the audit: the repository is unusually well sealed for its size, and it says so in
its own comments.

---

## 1. The finding: the pipeline stage vocabulary is decided in five spheres at once — **scattered**

**The gap.** This is one of the twelve design facts, not a module flag. Estimators expected the stage
vocabulary to be decided in about eight places (4, 8, 12). Measured: `stage_code` appears in **47 files and
232 sites**, 24 of them outside tests and documentation — the platform schema, `server/shared/stage-vocabulary.js`,
`stage-advance.js`, five spheres' `api/statements.js`, four spheres' `api/read.js`, two spheres' `db/schema.sql`,
five migration scripts, and the web tier's `pipeline/api.ts` and `ContactPanel.tsx`. A ×6 gap on the obeyed
side — that is, on the files that assume the fact.

**The mechanism**, checked directly against the code. The write SQL for a stage flip is one
statement, and it is written out five times as the exported `insertFlip`:

```
INSERT INTO pipeline_stage_flips (tenant, sphere, member, stage_code, actor, note)
  VALUES (?, '<sphere>', ?, ?, ?, ?)
```

in `spheres/social`, `publicity`, `partnership`, `financial` and `projects` — identical but for
the sphere literal; three of the five carry an identically duplicated `pipeline_contact_notes`
upsert beside it. The files say why, in their own words: *"The text lives here, in-sphere, because
the shared schema-conformance test scans `spheres/*/api` for INSERT/UPDATE column lists against
this sphere's net."* That test is `server/shared/tenant-conformance.test.js`, and its **scan
location** is the mechanism: a statement written once in `server/shared/` would sit outside the net
that checks column lists against a schema.

**The cost, exactly.** Adding a column to `pipeline_stage_flips`, or renaming `stage_code`, is five
hand-edits in five spheres before any shared code is touched — and the only thing that catches a sphere
missed is the same conformance test that forced the copies. The trade is deliberate and documented; what
it is not is free, and the audit puts a figure on it.

**What the owner decides**: whether five copies are the right price for the net, or whether the net should
learn to scan a shared statements module. SCOPE does not answer that; it measures it.

**How this was reached.** The module-level flag that led here — `web/src/pipeline/api.ts`, B = 99
against an expected 8.5 — closed **by design**, correctly: as a *client*, that module is one shared
surface five spheres reuse rather than clone. Following the same vocabulary to its write side found
the duplication. The per-module question was the wrong width, not the wrong answer: the concept is
wider than the module. Recorded as a limit in §5.

## 2. What closed **by design**

Fifty-two of the 63 triaged flags and four of the nine examined individually. The families:

- **The connector contract.** `loadConfig` has 16 homes, `timeoutMs` 14, `nowMysql` 11,
  `runSyncPass`, `httpRaw`, `defaultSleep`, `INTERVAL_MIN` and `MAX_RETRY_AFTER_MS` nine each.
  A name repeated across sibling modules is the interface of a family, not a smear. Seventeen
  connectors implement one shape.
- **Platform kit.** `credentials.js`, `connector-tenant.js`, `sync-runs.js`, `spar-pipeline.js`
  (whose own header reads "written once so a second sphere composes it instead of cloning"),
  `job-runs.js`, and on the web side `url-state.ts`, `AuthGate.tsx`, `ReachNote.tsx`,
  `CtxMenu.tsx`, `FilterBar.tsx`. Read widely because that is the job.
- **Sphere-internal fan-out.** A sphere's own `api.ts` read by that sphere's own views. The sphere,
  not the file, is the unit; both D-flagged view hubs (`ProfitAndLoss.tsx` D = 19, `CampaignBoard.tsx`
  D = 16) turned out to be glue — kit widgets and sibling modules — with the arithmetic, the drag
  protocol and the wizard's state machine each living elsewhere. Neither was closed on its doc line;
  the imports were listed region by region first.
- **`server/shared/runbook.js`** (B = 60 against 6): prose, `jobs.manifest.yaml` and `schema.sql`
  declarations, and a **sibling Tcl desktop client** that loads and runs runbooks in a runtime
  that cannot import JavaScript. A lower tier speaking the same vocabulary is by design.
- **`web/src/lib/auth.ts`** (B = 109 against 12): the Access-admin wire surface, whose field
  names mirror a schema-wide provenance convention (`added_by`, `updated_by`, `started_at`,
  `elapsed_ms`) that every connector's `sync.js` also stamps.
- **The error-code vocabulary in three homes.** Estimators expected one home; there are three —
  `server/shared/error-codes.js`, `web/src/lib/error-codes.ts`, `agent/error-codes.js` — because the
  three tiers deploy apart and cannot import each other. This is a duplication with a guard:
  `error-codes.test.js` scans the agent tree for emitting sites, the web test pins completeness in both
  directions, and the web map is `Record<ErrorCode, MessageDescriptor>` so a missing sentence is a
  compile error. One estimator predicted this exact arrangement blind. No finding, and the guard is why.
- **Facts that landed inside the band**: the sphere-discovery convention (decided in 2, obeyed by
  one descriptor file per sphere), connector self-registration, the credential shape, the
  financial-year opening month, the assistant panel, passwordless sign-in, and the grant-token
  grammar — which measured *narrower* than expected (5 places against 10).

## 3. What the measurement got wrong on this codebase

Eleven triaged flags and five of the nine examined individually were the instrument, not the code.

**3.1 The dynamic-`import()` blind spot accounts for every serious "A low".** `server/app.js` loads
its shared modules through `import('./shared/X.js')` inside one boot bundle and discovers spheres and
connectors by listing directories (`discoverSpheres`, `discoverConnectorJobs`). A symbol index cannot
follow either edge. So `auth.js` measures A = 3 against an expected 15, `contract.js` A = 1 against
22, `http-json.js` A = 1 against 17.5, and `ready.js`, `party.js`, `events.js`, `error-codes.js` the
same way. Counting the real consumers by hand found `server/app.js` using `auth.js` at a dozen sites.
This was named in the run notes before the comparison ran, and the flags were filtered against it.

**3.2 Homonyms carry four of the five artefact verdicts among the individually examined flags.**
`server/shared/datasets.js`: 336 of 388 sites are the bare word `datasets`, and every heavy carrier uses
it as the `datasets:` key on `dispatch.js`'s route-declaration contract — a same-spelled, different-owner
identifier. `spheres/relationships/ui/api.ts`: `linkedin` carries 253 of 422 sites and mostly names the
LinkedIn *connector*. `spheres/schedule/api/providers/rezdy.js`: the stem `rezdy` is 266 of 275 sites and
conflates this provider with `connectors/rezdy/` and a `'rezdy'` source label used as a data tag.
`spheres/publicity/ui/api.ts`: 125 of 168 sites are `created_at`, the schema's generic timestamp column.
In each case the vocabulary filter kept a word the concept does not own alone.

**3.3 The unindexed Tcl tier inflates one count.** `scripts/refresh-meta-recent.mjs` has 77 of its 101
sites in `desktop/ducks/*.tcl`, a tier in the grep corpus but invisible to the index, so its mentions can
only ever land in B.

**3.4 Ninety-nine modules had nothing distinctive to grep for.** After the vocabulary filter their B and C
were not measured, and they never flagged on B. `web/src/app/spheres.ts`, flagged A-low with B = 0, is one
of them: a floor in the instrument, not a module hiding.

## 4. How the blind estimates calibrated

| figure | inside ±1 log₃ | median gap | reading |
|---|---|---|---|
| **A** | 346/384 (90%) | +0.00 | calibrates best; flagged in either direction, since A is exact |
| **D** | 316/384 (82%) | −0.37 (×0.7) | estimators guess out-degree slightly high; flagged upward only |
| **B** | 202/384 (52%) | −0.55 (×0.5) | the low half is the unmeasured floor of §3.4; flagged upward only |
| **C** | 133/384 (34%) | **+0.23 (×1.3)** | the widest spread of the four; a median near agreement here, but the spread makes C unsafe to flag on, so it is printed as density and nothing rests on it |

B flags reached 32 of 384 rows, **8% of the table** — below the share at which the method holds that an
audit is reading its instrument rather than its code. That is what licensed reading the code at all.

## 5. What the method could not see on this codebase

- **The Tcl tier.** 32 tracked `.tcl`/`.tm` files, roughly 16 000 lines of the overseer desktop client,
  have no symbol indexer on this host. They are in the grep corpus, so they can inflate another module's
  B, but they have no A and no D of their own and nothing in that tier was measured as a concept. A
  scattering *inside* the overseer would be invisible.
- **29 `.design-sync/previews/*.tsx`, 5 `web/` build and catalog scripts, 4 migration `.mjs`, 1 test double** — tracked, hand-written, outside both tsconfigs.
- **Runtime discovery**, per §3.1: the shell's own wiring is not in the graph at all.
- **The concept wider than its module.** §1's finding was reached by following a module's vocabulary
  into files that define no part of it. The per-module question asks "who uses this file's names", not
  "who else writes this concept's SQL". The design-fact list is the method's answer to that, and it is
  only as good as the facts the estimators happen to name — here, one of the twelve.
- **Prose weight.** 105 markdown files in a 1 046-file corpus. This repository documents itself
  heavily, which is why so many B counts are prose, and why "is one word doing the work" was the
  question that closed most flags.

## 6. Where the evidence is

Paths below are relative to the run folder `/home/weiwu/code/aesop/scatter-scope/tests/rivermill-bi-pwa/results/2026-08-21-round-3/`.

| evidence | file |
|---|---|
| Run notes: indexer, tiers, corpus rule and exclusions, tool commit, model tiers, blind spots | `method-notes.md` |
| Concept list: modules with vocabulary, convention table, design facts | `concept-list.md` |
| Measured table: A, D, B, C, leak, score per module; conventions | `measured-table.md`, `measured.json` (full vocabulary per module) |
| Estimators' brief (blind; README, sizes, doc list, module list with each module's own doc line) | `oracle-brief.md`, generated by `mkbrief.py` |
| The three estimators' replies, written blind | `e1.md`, `e2.md`, `e3.md` |
| Comparison table: expected, measured, gap, flags, disposition (all 72 filled) | `pick-table.md`, `pick.json` |
| Design facts: expected against measured, decided-in and obeyed-in, homonyms excluded | `pick-facts.md` |
| The nine individual reports, each verifying the count before the cause | `revivals/e*.md` |
| Batch triage of the remaining 63 flags | `revivals/triage-batch.md` |
| Helpers: index merge, corpus check, B-file lister, brief generator, server tsconfig | `merge.py`, `corpuscheck.py`, `bfiles.py`, `mkbrief.py`, `servercfg-tsconfig.json` |
| Index and bulk output (outside both the repository and the run folder) | `/usr/local/ai/scope/round-3/` |

## 7. Cost

| | |
|---|---|
| Agents | 4 spawned: three blind estimators (cheap tier, fresh context, one file read each) and one triage context. Each estimator was called back three times, in its own original context, to examine a flag it had guessed furthest off — nine such reports, so 13 agent turns in total. |
| Indexing | two `scip-typescript` passes, 7 s each; 546 documents |
| Count | one pass over a 1 046-file corpus, ~2 minutes |
| Wall time | 27 minutes end to end (15:07–15:34), of which the three blind estimates ran ~3 minutes in parallel, the nine individual reports ~4 minutes in three parallel waves, and the triage context 10 minutes |
| Repository | not modified: `git status` unchanged, one pre-existing untracked file, nothing written into the tree |

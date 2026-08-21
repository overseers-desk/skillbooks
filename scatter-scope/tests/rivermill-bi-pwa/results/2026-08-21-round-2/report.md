# SCOPE — round 2 on `rivermill-bi-pwa`

One codebase measured once: 384 non-test modules and fourteen decided-once facts, each measured
four ways and each compared with what three blind estimators expected of a program of this
description. What follows is the short list with a verified gap and a named mechanism, plus an
honest account of where the instrument, not the code, produced the gap.

The repository was not modified.

---

## 1. Findings the owner can act on

### 1.1 The desktop breakpoint is decided in fourteen places — **scattered**

Expected 2 places. **Decided in 1** (`web/src/lib/breakpoint.ts`, `export const DESKTOP_MIN_PX = 900`);
**obeyed in 14**: that file, plus thirteen stylesheets that each hand-type
`@media (min-width: 900px)` — `web/src/app/shell.css`, `web/src/app/chat.css`, `web/src/ui/kit.css`,
`web/src/pipeline/styles.css`, and nine spheres' own `styles.css`. Gap +1.77 log₃.

The JS constant's own comment says it "mirrors the CSS desktop breakpoint". Nothing enforces the
mirror: there is no custom property and no PostCSS custom-media token either side could share
(the revival grepped for `--breakpoint`, `--desktop`, `custom-media`; none exists). The two
components that could have re-spelled the number import the constant instead, so the JS side is
clean; the whole cost sits in CSS.

**Cost of a change.** Moving the breakpoint to 1024 is fourteen hand-edits, and no compiler,
type-checker or linter catches a missed one — the miss shows up as one sphere laying out on the
wrong side of the line.

Two independent routes found this. The fact probe found it from the oracle's decided-once list;
the module table found `web/src/lib/breakpoint.ts` in its leak-signature set (A=3, B=16, leak=13)
with no oracle input at all.

### 1.2 The pipeline tables' column vocabulary crosses every tier as bare text — **scattered**

`web/src/pipeline/api.ts`: expected A=6, B=6; measured **A=16, B=122, C=1248, leak=108**.

The count survives correction, and what carries it is not English nouns but snake_case column
names declared once as TypeScript property names in this module and re-spelled as **text**
everywhere else — in SQL schemas, server reads, migration procedures, tests and views:

| word | corpus files matching it alone |
|---|---:|
| `stage_code` | 51 |
| `flipped_at` | 38 |
| `contact_name` | 30 |
| `reply_at` | 23 |
| `replied_date` | 21 |
| `linkedin_url` | 20 |
| `next_touch_at` | 15 |

with `s_note`, `r_note`, `a_note`, `p_note`, `star_rating`, `round_number`, `yield_score`,
`sweep_iteration`, `response_likelihood`, `angle_rationale` and a dozen more below them.
`stage_code` alone is spelled across six spheres, `server/shared`, `web/src` and two migration
folders.

**Cost of a change.** Renaming one pipeline column is an edit in the schema, the migration SQL,
the server read, this client interface and every view that reads it. None of those sites is an
edge a reference graph can see; nothing but a grep finds the last one. This is precisely the
half of the count the compiler never sees, which is why the method measures it.

### 1.3 A smaller version of the same thing, not separately revived

`spheres/social/ui/api.ts` (expected A=3, B=4; measured A=15, B=85, leak=74). Two of its top
words are homonyms and drop out, but `Membership`, `pipelineState`, `audienceFit` and
`dmThreadShortId` between them still reach some forty files with nothing to blame. The owner may
want a look; this round did not revive it separately, and says so rather than implying it did.

---

## 2. What closed **by design**

I4 of the invariants: a flag may close with no defect, and several did.

- **`server/shared/sync-runs.js`** (A 8→26, B 9→65). Twenty-six of the B files are the import
  edges A already counts. The remaining thirty-eight are the connector READMEs and
  `docs/job-execution.md` describing the run ledger in prose, the module's own migration folder,
  the `job_runs`/`elapsed_ms` columns in `schema.sql` (SQL, which no indexer walks), and sibling
  connector bodies that name the frame in comments. A shared execution vocabulary echoed where a
  reader needs it.
- **`server/shared/credentials.js`** (A 3→24). A is exact and the twenty-four consumers are one
  seam every connector calls for its keys. Exactly what the module exists for.
- **Sphere self-registration**, **connector self-registration**, **the grant-token grammar**,
  **the single HTTP transport bottom**, **`job_claims`**, **venue-local dates**, **the pipeline
  stage vocabulary**, **tenant scoping** and **the product's working name** — see `pick-facts.md`.
  Two deserve a note. Tenant scoping is obeyed in 58 files against an expected 4, the widest
  fact gap in the run; it closes by design because the README's first paragraph makes
  multi-tenancy the platform's commitment, and a fact obeyed everywhere on purpose is not a
  finding. The stage vocabulary's own module header names its four readers and six call sites
  before anyone measured them — the code had already done this method's work on itself.
- The **credential-manifest shape** (17 homes against an expected 4) is a sibling-family
  interface: a concept with N homes, which the convention table is for, not scatter.

---

## 3. What the instrument got wrong

This is the larger half of the round, and it is the part a reader should trust least without the
numbers, so here they are.

**161 of 384 modules flagged, 96 of them on B.** The methodology's own warning applies: a run
whose B flags reach a large share of the table is reading the instrument. It is.

### 3.1 The stem rule inflates B, and does so per sibling

`tools/scope-count.py` filters a *declared name* hard — kept only if one file defines it, it is
not a dictionary word, and it does not also name a symbol from outside the tree. It then adds
the **file's stem** under a much weaker rule: kept if it is not `lib`/`mod`/`main`/`index`, is at
least three characters, and is absent from `/usr/share/dict/words`. The stem gets neither the
several-homes guard nor the external-name guard.

The consequence, measured (`stem-check.json`): **in 85 of the 96 B-high modules the stem alone
accounts for 80% or more of B.** `auth`, `config`, `upsert`, `sonas`, `rezdy` and `vocab` are
all absent from the dictionary file, so all six survive and grep the whole tree; `api`, `export`,
`sphere`, `instance`, `journey`, `atoms` and `credentials` are in it, so those families escaped
by luck of lexicography. And because the stem carries no several-homes guard, **nine connectors
named `upsert.js` each separately claim the word and each report the identical B=117** — one
artefact counted nine times, at the top of the score ranking.

Two fixes, for the method's owner:

1. Apply the same several-homes guard to the stem as to a declared name — if N files share a
   stem, no one of them owns the word.
2. Apply a genericity test the dictionary file cannot do alone. `upsert`, `config` and `auth`
   are common domain words that happen to be missing from `/usr/share/dict/words`.

### 3.2 Homonyms carry the rest

Of the eleven B-high modules the stem does *not* explain, most are carried by one ordinary word:
`viewport` in `web/src/ui/CtxMenu.tsx` (29 files against `CtxMenu`'s own 16); `created_at` in
`spheres/publicity/ui/api.ts` (49 files — the timestamp column every table has); `linkedin` (62)
and `tiktok` (27) in two spheres' row types, each the name of a whole connector directory
elsewhere in the tree. The word is the module's, the files are not.

### 3.3 The A-low flags are the index's blind spot, not sealing

Twenty-three modules measured A far below expectation. Seventeen are `connectors/*/credentials.js`
at A=0: nothing imports them, because `server/shared/credential-manifests.js` finds them with
`readdirSync` and a *computed* path and then dynamic-imports it. The other six are shared server
modules (`contract.js`, `http-json.js`, `access.js`, `ready.js` and two more) that `server/app.js`
loads through `await import('./shared/X.js')` — a string-literal dynamic import this indexer does
not record. In both groups the blind estimator read the convention correctly from the README and
the graph could not see it. **A=0 is a true statement about the graph and a false one about the
architecture**, and a run that did not check would have reported seventeen sealed modules.

### 3.4 The D-high flags read the estimator, not the code

Fifty-one modules flagged as hubs; the top of the list is leaf view components with A=1 and D
above 10 — one parent mounts them, and they compose a shared UI kit and several data hooks. That
is what a well-factored screen looks like; the opposite (low D) would mean each view
reimplements formatting and layout. The estimators' median D of 3–5 assumed a flatter import
profile than this codebase's convention has.

### 3.5 Two revivals named the wrong mechanism, and one reached the wrong verdict

Worth recording, because it is a defect in how this round ran the Explain phase, not in the
codebase.

- The `web/src/lib/auth.ts` revival blamed `author`/`authorize`/`oauth`. The tool greps on word
  boundaries and matches none of those. The real noise is the stem naming four things: a URL
  segment, the server's own `auth.js`, a `hook.auth` field and local variables. Verdict
  unchanged; mechanism corrected.
- The `web/src/pipeline/api.ts` revival reached **artefact** by analysing a word list it derived
  itself, because the prompt gave it only a six-word sample of a 53-word vocabulary. The words it
  blamed (`Stage`, `fmtDate`, `Contact`) had already been removed by the several-homes guard and
  were never counted. On the actual vocabulary the finding is real — §1.2 above. **A revival must
  be handed the exact vocabulary the count used, not a sample.** That is the single procedural
  change this round recommends to the methodology.
- The hub/A-low triage was given a wrong measured figure by the operator
  (`server/shared/sql-static.js` as "measured 0"; the table says 3, never flagged) and built on
  it, concluding the server tier was unindexed. It was indexed, from a tsconfig kept outside the
  repository. The operator re-derived Class 2 directly; §3.3 is that re-derivation, not the
  revival's.

---

## 4. Calibration, re-checked on this run

| figure | inside ±1 log₃ | median gap | reading |
|---|---|---|---|
| **A** | 346/384 (90%) | +0.00 | calibrates best, as the record says |
| **D** | 318/384 (82%) | +0.00 | calibrates well; its flags are a prior about fan-out, not a fault |
| **B** | 176/384 (45%) | +0.00 | median is honest, spread is not; the tail is the stem rule |
| **C** | 81/384 (21%) | **+1.10 (×3.3)** | does not calibrate — estimators under-guess sites uniformly |

C behaved exactly as the record predicts and was printed, never picked on. B's median gap of
zero with only 45% inside the band is the signature of §3.1: most modules are estimated well and
a hundred are wrecked by one rule.

Eighty-six of the 384 modules have **no distinctive vocabulary at all** — their names are
dictionary words, external types, or shared with siblings — so their B reads 0 and is marked as
a floor, not as hiding. That is 22% of the table on which the vocabulary half of the method is
simply blind.

---

## 5. What the method could not see on this codebase

- **The Tcl tier.** `desktop/` is 33 non-test files and roughly 16 000 lines of `.tcl` and `.tm`
  — the overseer that runs browser work against a logged-in session, a first-class piece of the
  architecture per `docs/overseer.md`. No SCIP indexer for it exists here. It is in the grep
  corpus, so it can raise another module's B and can never appear in anyone's A or D, and it has
  no A or D of its own. Every module concept in `desktop/` is missing from this run.
- **Four other unindexed groups**, all in the corpus and none in the graph:
  `.design-sync/previews/*.tsx` (29 files), `migration/**/*.mjs` (4), `web/*.config.ts` and
  `web/scripts/*.mjs` (5).
- **Runtime discovery and dynamic import**, per §3.3 — a structural limit of any static index,
  and this codebase uses both heavily.
- **SQL.** Schemas and migrations are text to every tool here. That is not only a gap: it is half
  of why finding 1.2 exists.
- **One fact was not measured at all** rather than given a number: the union view across tenants,
  named by a single estimator and having no handle but common words. `pick-facts.md` records it
  as not measured.

---

## 6. Artefact index

In the run folder:

| file | what it is |
|---|---|
| `method-notes.md` | indexer, tiers, corpus rule and exclusions, the index's blind spot, where bulk output lives |
| `oracle-brief.md` | the brief every estimator received, and nothing else (51 KB) |
| `e1.md`, `e2.md`, `e3.md` | the three blind replies, 384 module rows and 12 facts each |
| `measured.json`, `measured-table.md` | A, D, B, C, leak, score per module; the convention table |
| `pick.json`, `pick-table.md` | expected, measured, gap, flags, disposition |
| `pick-facts.md` | the decided-once facts: expected, decided in, obeyed in, probe and its exclusions |
| `stem-check.json` | the stem instrument check behind §3.1 |
| `revivals.md` | the eight revival reports with the operator's corrections |
| `mkbrief.py`, `restem.py`, `vocab-probe.py`, `servercfg-tsconfig.json` | what this round wrote, for the record |

Outside the repository and outside the run folder, under `/usr/local/ai/scope/round-2/`:
`idx/web.scip`, `idx/server.scip`, `idx/web.json`, `idx/server.json`, `idx/index.json` (18 MB),
`servercfg/tsconfig.json`, and the `node_modules` holding `scip-typescript` at
`/usr/local/ai/scope/node_modules`.

---

## 7. Cost

Eleven agents on the cheap tier (Sonnet): three blind estimators and eight revivals (two of them
batch triage). About 423 000 subagent tokens. Wall time twenty-five minutes end to end, of
which the two index passes took thirteen seconds, the blind estimators ran in parallel for up
to five minutes, and the eight revivals ran in parallel for up to five.

## 8. Invariants

- **I1** (the oracle sees no code and no count): each estimator was permitted a single Read of
  `oracle-brief.md` and no other tool call; all three obeyed, one tool use apiece. The brief
  holds the README, the size table, the doc list and the module list with each module's own doc
  line — no measured figure, no source line, no suspicion, no concept named beyond the full
  module list.
- **I2** (a flag is a gap, never a count): every row of `pick-table.md` carries expected,
  measured and the gap.
- **I3** (Explain verifies the instrument first): every revival prompt carried the instruction
  and every report leads with the check; where a revival's own check was wrong, §3.5 and
  `revivals.md` correct it rather than quietly keeping the verdict.
- **I4** ("by design" closes a flag): §2.
- **I5** (methodology documents name no run's code): nothing in this run folder was written back
  into the methodology.

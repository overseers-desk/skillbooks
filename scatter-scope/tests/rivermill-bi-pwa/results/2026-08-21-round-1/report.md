# SCOPE run — rivermill-bi-pwa, 2026-08-21, round 1

The codebase is a multi-tenant business platform: a shared Node server tier, per-external-system
connectors, per-domain spheres, a React PWA, an agent runtime and a Tcl desktop overseer.
1328 corpus files; 396 of them define symbols and became module concepts.
Three blind estimators, three revivals. The repository was not modified.

`method-notes.md` holds the indexer, the corpus rule and what was excluded.
`measured-table.md` and `pick-table.md` hold all 396 modules; `pick-facts.md` the decided-once
facts; `oracle-brief.md` and `e1/e2/e3.md` the blind inputs; `revivals.md` the full reports.

## Calibration, first

This is the second codebase the method has met, and the calibration recorded on the first run
does not carry across cleanly.

| figure | inside the +-1 band | median gap |
|---|---|---|
| A | 366 of 396 | +0.00 |
| B | 221 of 396 | -0.22 |
| C | 129 of 396 | +0.70 |

**A calibrates, and calibrated better here than on the first run.** Blind estimators guess the
type-consumer count of a module of this kind almost exactly, from its path, its length and its
own doc line. Thirty modules outside the band on A is a short enough list to read.

**B did not calibrate.** 186 of 396 modules flagged — nearly half — which is not a finding list,
it is an instrument saying so. The failure is two-sided and both sides were traced:

- **112 modules measured B <= 1** (96 of them exactly 0), because the vocabulary rule keeps only
  names defined in exactly one module. This codebase's central convention is that sibling modules
  in parallel folders carry the *same* names on purpose — `handleApi` in 41 sphere api files,
  `runSyncPass` in 9 connector `sync.js`, `upsertEntity` in 6 `upsert.js`, `config` in 11
  `instance.js`. The dedup rule, meant to drop coincidental collisions, deletes exactly the
  intentional parallel-module vocabulary, and leaves each file with its private helpers, which
  nothing else mentions. The concept most worth measuring is the one the filter erases.
- **50 modules measured B far high**, from ordinary words that survived the dictionary filter
  because they are also the module's own stem or a field name: `local` (212 unrelated files),
  `stream` (57), `linkedin` (87 of that module's 92 B files — the connector folder's name),
  and the `CtxItem` fields `checked` and `disabled`, which are HTML attributes and match
  61 and 80 files. In each case the leak was the word, not the concept.

**C is again worth nothing as a flag** and is reported as density only.

The one signature the method promises — low A with high B, the leak — fired once in 396 modules
(`web/src/app/sphere.ts`), and the revival found that to be an artefact too: the type 16 modules
import is named `Sphere`, an English word, so the filter dropped it. In this codebase the leak
signature is inverted: the modules with the largest genuine vocabulary spread are the ones the
instrument scored at zero.

## What the run found in the code

Nine module flags and eleven fact flags went to revival. After the instrument check, four
survive as things the owner may want to act on. Everything else was dictionary noise or
"by design", and closes.

**1. One column vocabulary restated at four layers (`web/src/pipeline/api.ts`).**
The SPAR round-note columns `r_note`, `s_note`, `p_note`, `a_note` are declared in
`connectors/spar/db/schema.sql`, parsed in `connectors/spar/api/parse.js`, written in
`upsert.js`, carried through `server/shared/spar-pipeline.js`, restated as TypeScript field
types in `web/src/pipeline/api.ts`, and read again in `spheres/publicity` and `web/test`.
Verified independently of the revival: 12 files, 59 sites, four tiers. Renaming a round means
editing the schema, the connector, the shared pipeline, the client types and three test files.
This is the highest-density module in the run (C = 1236) and the one real change-amplification
candidate the method surfaced. Whether four layers restating one column list is a cost or the
price of a typed client is the owner's call; the count is now known.

**2. Stale prose in `server/shared/access.js`.** The security gate is a genuine single-caller
chokepoint: `server/shared/dispatch.js` is the only importer, and A = 1 is correct. But the
module's own doc line still claims that "both dispatch and any non-dispatch surface" import
`gate()` and names "the shell mounts in app.js" among its callers. Those paths were migrated onto
dispatch; the doc was not. A reader of the doc will look for callers that no longer exist. This
is a one-line fix and the most actionable item in the run.

**3. The connector mirror-table prefix has no single name.** The estimators all expected the
mirror-table naming convention to be decided in a handful of places. It is decided in as many
places as there are connectors, because the convention is `<connector-name>_*` — `xero_*`,
`rezdy_*`, `instagram_*` — a different literal per connector. No grep, no index and no rename
tool can see the convention as one thing; only a human reading two connectors side by side knows
it exists. Roughly 15 connectors x their sync/upsert/read files. This is the run's clearest case
of a fact that is scattered *and* invisible to every instrument that would find scattering.

**4. Multi-tenancy: decided in 31 files, obeyed in 306.** The estimators expected 8 places. The
word `tenant` reaches 306 of 1328 corpus files and 5560 sites, with no homonym noise. The
revival's reading is that the two figures answer different questions: the tenant registry's own
definition is 31 files, and the tenant column threading through nearly every query is the design,
held in place by a conformance test. By design, and worth knowing the size of.

Closed as by design, after the count was verified: `web/src/lib/auth.ts` (the wire keys
`addedAt`/`addedBy` are the DB columns, named identically client to server to schema to docs, an
intentional contract); `web/src/ui/atoms.tsx`, `SectionHeader.tsx`, `use-api-view.ts`,
`url-state.ts` (shared kit primitives with the fan-out their doc lines promise);
`spheres/relationships/api/read.js` (one export, one mount, cross-sphere "mirrors" that are
comments and not imports).

A positive result worth recording: the connector HTTP transport. The estimators expected the
"plain `node:https`, no vendor SDK" rule to be restated in 12 to 14 places. `node:https` is
touched in exactly one file, `server/shared/http-raw.js`, and all sixteen connector clients go
through it. Decided once, obeyed twenty times, with no vocabulary leak. That is what a
well-hidden decision looks like in this codebase, and it is the shape the other three findings
are not.

## What this run says about the method

Recorded for the next revision of the methodology, not for this repository's owner:

- **The Count vocabulary rule needs a language-aware amendment.** "Keep only names defined in one
  module" assumes a codebase where a repeated name is an accident. In a codebase built on
  parallel folders with a shared interface — connectors, plugins, spheres, drivers — a repeated
  name is the interface, and the rule inverts the signal. A name defined in N sibling modules of
  the same folder role is a concept with N homes, which is the strongest possible reading of the
  method's own subject, and it currently scores zero.
- **The dictionary filter leaks through the stem exemption.** A stem that is an English word is
  dropped, but a *symbol* equal to the stem is kept unconditionally, which is how `local` and
  `stream` each brought in a two-hundred-file leak. Field names that are HTML attributes
  (`checked`, `disabled`) need the same treatment.
- **A grep for a fact needs its homonyms declared.** Three of the eleven fact probes matched the
  wrong sense of a word (`sign-?in` catching AWS request signing; `connector_` catching a registry
  table rather than a prefix convention; `local` as a provider id versus localhost). The Explain
  phase caught all three, which is the phase working as designed — but the pick table published
  eleven flags of which three were the instrument, and a table that wrong at the flag stage costs
  a revival each time.
- **A is the cheap and reliable half.** If a future run must be cheap, A alone against the blind
  estimate is worth having; B needs the amendments above before its flags are worth a revival.

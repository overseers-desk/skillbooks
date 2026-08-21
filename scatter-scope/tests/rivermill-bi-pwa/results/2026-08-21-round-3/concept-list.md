# Concept list — round 3

The concepts this run examined, from the two sources the Survey merges.

## 1. Module concepts (from the symbol index)

384 non-test files that define symbols, each with the vocabulary the count used: the names that
file alone defines, plus its stem, after the filter (a name with an underscore or an inner
capital stays; a capitalised type name stays, matched case-sensitively; a lowercase name or a
stem goes when it is an English word or a programming commonplace; a name that also names a
symbol defined outside the tree goes; a stem several files share, or that names a dependency
type or a directory, goes and is measured as a convention row instead).

- The ranked table with a six-word vocabulary sample per module: `measured-table.md`.
- Each module's **full** vocabulary, as the count used it: `measured.json` (`modules[].vocabulary`).
  This is what each revival received verbatim, together with its B files.
- 99 of the 384 have no distinctive vocabulary left after the filter. Their B and C are not
  measured and never flag; their A and D still hold.

## 2. The convention table (names with several homes)

320 names defined by two or more files — the interface of a family of sibling modules rather
than one module's word. The top 60 by number of homes are in `measured-table.md`; the full set
is in `measured.json` (`conventions`). The largest families are the connector contract
(`loadConfig` 16 homes, `timeoutMs` 14, `nowMysql` 11, `runSyncPass` 9, `httpRaw` 9,
`defaultSleep` 9, `INTERVAL_MIN` 9, `MAX_RETRY_AFTER_MS` 9) and the route/handler contract
(`handleApi` 13 homes, 373 sites; `onClose` 13; `onOpen` 8).

## 3. Decided-once facts (from the blind estimators, before they saw anything else)

Each estimator named twelve design facts a program of this description decides once, with the
places it expected to edit if the fact changed. The raw lines are at the foot of `e1.md`,
`e2.md` and `e3.md`; the merged list, the probe used for each, the homonyms each probe excludes,
and the measured "decided in" and "obeyed in" figures are in `pick-facts.md`.

Facts all three named: the product's working name; the sphere-discovery convention; the
error-code vocabulary shared between tiers; the dataset vocabulary; the grant-token grammar; the
pipeline stage vocabulary. Facts one named alone: tenant scoping of every row and route (e2), the
financial-year opening month (e3), passwordless email-code sign-in (e2), the assistant panel on
every screen (e3), the connector credential shape (e1, e3), the multi-tenant union view (e1, e3).

One fact was recorded as **not measured** rather than given a number: the dataset vocabulary,
whose handle collides with a route-spec key of the same spelling — the same homonym the
`datasets.js` revival traced.

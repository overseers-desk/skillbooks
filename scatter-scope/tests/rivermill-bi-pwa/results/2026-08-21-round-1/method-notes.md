# How this run was measured

## The index (Survey)

The codebase is JavaScript and TypeScript, so the SCIP indexer is
`@sourcegraph/scip-typescript` (installed under `/usr/local/ai/scope`, not in the repo).
Two passes, because the tiers deploy apart and only one carries a tsconfig:

- `web/` with its own `web/tsconfig.json`; that config's `include` already reaches
  `../spheres/*/ui`, so the sphere UIs are indexed with the app that mounts them.
- the server tier (`connectors/`, `spheres/*/api`, `server/`, `agent/`, `scripts/`) with a
  tsconfig kept outside the repository (`/usr/local/ai/scope/servercfg/tsconfig.json`,
  `allowJs`), pointing at the repo by absolute path, so nothing is written into the tree.

No `scip` CLI release could be built on this host (the module's go.mod carries replace
directives), so the two `.scip` protobuf files are decoded to the JSON shape
`scope-count.py` reads by `/usr/local/ai/scope/scip2json.py`, a 40-line reader of the
three fields the count needs: document path, occurrence symbol, occurrence roles.
The two indexes are merged on repo-relative paths: 546 documents, 396 of which define
symbols and so become module concepts.

The repository was not modified. `scip-typescript --infer-tsconfig` dropped an empty
`tsconfig.json` at the repo root during an exploratory pass; it was deleted, and
`git status` is clean but for a `.env` backup that predates this run.

## The corpus (Count)

Files of these extensions: `.js .mjs .ts .tsx .md .json .sql .tcl .css .html .yaml .yml .sh`
— 1328 files. Excluded as things a reader does not meet, or as generated output:

| excluded | why |
|---|---|
| `node_modules/`, `.git/` | not the tree |
| `.claude/` | agent-session folders (methodology: Count) |
| `web/src/locales/` | `lingui` catalogs: the `.po` files carry a `#: path:line` reference for every extracted string, which would add sixteen files and thousands of sites to every module with a translated string, and the `.mjs` beside them are compiled output |
| `ds-bundle/_*` | design-system build output (`_ds_bundle.js`, `_vendor`, `_preview`, `_screenshots`) |
| `data/`, `tmp/` | scratch |
| `.design-sync/learnings/` | session notes |

Test files are marked by the fragment `.test.` and excluded from A only, per the method.

## Tiers

Oracle estimators and their revivals ran on the cheap tier (Sonnet), three of them,
each in a fresh context, each shown `oracle-brief.md` and nothing else.

## Where the bulk output lives

Kept out of the run folder, under `/usr/local/ai/scope/`:
`idx/web.scip`, `idx/server.scip`, `idx/js.scip` (the raw SCIP protobufs),
`idx/index.json` (18 MB, the merged index Count read),
`node_modules/` (scip-typescript), `servercfg/tsconfig.json`.
The two scripts written for this run are copied into the run folder as
`scip2json.py` and `pick.py`, with the server-tier tsconfig as `servercfg-tsconfig.json`.

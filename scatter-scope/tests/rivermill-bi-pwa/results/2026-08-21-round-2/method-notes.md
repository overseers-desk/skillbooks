# Run notes — how this round was measured

Round 2 on this repository. Nothing was reused from round 1's measurement: the index was
rebuilt, the corpus rule was decided again from the repository's own `.gitignore`, and three
fresh estimators saw a brief assembled by this round's generator. Round 1's server-tier
tsconfig was reused verbatim as an input file, since it is a configuration, not a result.

## The index (Survey)

The tree is JavaScript, TypeScript and Tcl. The SCIP indexer is
`@sourcegraph/scip-typescript` (installed under `/usr/local/ai/scope`, never in the repo).
Two passes, because the tiers deploy apart and only one carries a tsconfig:

- `web/` with its own `web/tsconfig.json`, whose `include` already reaches `../spheres/*/ui`,
  so every sphere's UI is indexed with the app that mounts it. 166 documents.
- the server tier (`connectors/`, `spheres/*/api`, `server/`, `agent/`, `scripts/`,
  `desktop/**/*.js`) with a tsconfig kept **outside** the repository at
  `/usr/local/ai/scope/round-2/servercfg/tsconfig.json`, `allowJs`, pointing into the tree by
  absolute path so nothing is written into it. 380 documents.

The `scip` CLI could not be built on this host, so the two protobufs are decoded to the JSON
`scope-count.py` reads by `tools/scip2json.py`. The two indexes are merged on repo-relative
paths: **546 documents**, of which **527 define symbols**; 384 of those are non-test files and
are the module concepts of this run.

`--infer-tsconfig` was not used, so no `tsconfig.json` was dropped at the repo root. The
repository was not modified; `git status` at the end of the run shows only one untracked
environment backup under `agent/` that predates this run.

## What the index does not cover (the run's blind spot)

725 tracked source files; 546 indexed; **179 not**, of which 71 are non-test:

| unindexed, non-test | files | why |
|---|---:|---|
| `desktop/**` (`.tcl`, `.tm`) | 33 | Tcl: the overseer tier, ~16 000 lines, no SCIP indexer here |
| `.design-sync/previews/*.tsx` | 29 | outside both tsconfigs' `include` |
| `migration/**/*.mjs` | 4 | one-shot migration scripts, outside both `include`s |
| `web/*.config.ts`, `web/scripts/*.mjs` | 5 | build and catalog tooling, outside `src` |

These files are **in** the grep corpus, so they can appear in a module's B and inflate its
leak, but they can never appear in anyone's A or D and their own A and D are absent. Any flag
whose leak is carried by `desktop/` is the Tcl tier speaking a shared vocabulary the graph
cannot see, and the report says so rather than calling it scatter.

## The corpus (Count)

The corpus rule is **the tree as a reader meets it after a clone**: tracked files only, taken
from the repository's own `.gitignore` rather than a hand-written list. Extensions
`.js .mjs .ts .tsx .jsx .md .json .sql .tcl .tm .css .html .yaml .yml .sh` — 1018 files.

| excluded | why |
|---|---|
| `node_modules/`, `.git/` | not the tree |
| `ds-bundle/`, `.ds-sync/`, `.design-sync/learnings/`, `data/`, `dist/`, `tmp/` | gitignored: build output, sync scratch, session notes |
| `.claude/` | agent-session folders (methodology, Count) |
| `web/src/locales/` | `lingui` catalogs: every `.po` carries a `#: path:line` reference for every extracted string, which would add a file and hundreds of sites to every module with a translated string; the `.mjs` beside them are compiled output and gitignored |
| `package-lock.json` | lockfile |

`.tm` (Tcl module) files were added to the extension list this round so the overseer tier is
greppable at all; `.design-sync/previews/*.tsx` are tracked and hand-written, so they stay in
the corpus even though the indexer misses them.

Test files are marked by `/tests/`, `/test/`, `.test.`, `_test.`, `selftest` and are excluded
from A and D only, per the method; they remain in the corpus for B.

## Tiers

Oracle estimators and their revivals ran on the cheap tier (Sonnet), three of them, each in a
fresh context, each permitted one Read of `oracle-brief.md` and no other tool call.

## Where the bulk output lives

Outside the repository and outside the run folder, under `/usr/local/ai/scope/round-2/`:
`idx/web.scip`, `idx/server.scip` (raw protobufs), `idx/web.json`, `idx/server.json`,
`idx/index.json` (18 MB, the merged index Count read), `servercfg/tsconfig.json`,
`mkbrief.py`. The scripts are copied into the run folder for the record.

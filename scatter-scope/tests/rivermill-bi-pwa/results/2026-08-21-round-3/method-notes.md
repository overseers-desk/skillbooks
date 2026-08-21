# Run notes — how round 3 was measured

Round 3 on this repository. Nothing was carried over from the earlier rounds' measurement: the
index was rebuilt from the working tree at commit `7d44b9ce`, the corpus rule was decided again
from the repository's own `.gitignore` and an extension census of its tracked files, and three
fresh estimators answered a brief this round's generator assembled. Round 1's server-tier
tsconfig was reused verbatim as an *input* — it is a configuration, not a result — and is kept
in the run folder as `servercfg-tsconfig.json`.

Tools commit: `scatter-scope` at `15caa5d` (`tools/scope-count.py`, `tools/scope-pick.py`,
`tools/scip2json.py` as of that commit). B is a function of the vocabulary rule, so B compares
across runs only at this tool version.

## The index (Survey)

The tree is JavaScript, TypeScript and Tcl. The indexer is `@sourcegraph/scip-typescript`,
installed under `/usr/local/ai/scope`, never in the repository. Two passes, because the two
tiers deploy apart and only one of them carries a tsconfig:

- `web/` with its own `web/tsconfig.json`, whose `include` already reaches `../spheres/*/ui`,
  so every sphere's UI is indexed with the app that mounts it — **166 documents**.
- the server tier (`connectors/`, `spheres/*/api`, `server/`, `agent/`, `scripts/`,
  `desktop/**/*.js`) with a tsconfig kept **outside** the repository at
  `/usr/local/ai/scope/round-3/servercfg/tsconfig.json`, `allowJs`, pointing into the tree by
  absolute path so nothing is written into it — **380 documents**.

`--infer-tsconfig` was not used, so no `tsconfig.json` was dropped at the repository root. The
`scip` CLI is not available on this host, so both protobufs are decoded to the JSON the count
reads by `tools/scip2json.py`, and `merge.py` maps the two document sets onto repository-relative
paths: **546 documents**, **527 of which define symbols**, of which **384 are non-test** and are
this run's module concepts. 99 of those 384 have no distinctive vocabulary after the filter, so
their B and C are not measured; their A and D still hold.

## Dynamic loading (the low-A caveat)

`server/app.js` discovers `spheres/*/api/instance.js`, `connectors/*/hook.js` and
`connectors/*/jobs.js` by listing a directory and importing each by computed path
(`discoverSpheres`, `discoverConnectorJobs`, `importOwner(pathToFileURL(file).href)`). A SCIP
index cannot see that edge. Every such entry point therefore measures **A = 0** while being
loaded by the shell at boot, and a low A on one of those files is read as dynamic loading, never
as sealed. The pick table's "A low" flags are filtered against this list before any revival.

## What the index does not cover (the run's blind spot)

726 tracked source files; 546 indexed; **180 not**, of which 71 are non-test:

| unindexed, non-test | files | why |
|---|---:|---|
| `desktop/**` (`.tcl`, `.tm`) | 32 | Tcl: the overseer tier, ~16 000 lines, no SCIP indexer on this host |
| `.design-sync/previews/*.tsx` | 29 | outside both tsconfigs' `include` |
| `web/*.config.ts`, `web/scripts/*.mjs` | 5 | build and catalog tooling, outside `src` |
| `migration/**/*.mjs` | 4 | one-shot migration scripts, outside both `include`s |
| `agent/sdk-double.mjs` | 1 | test double, outside both `include`s |

These files are **in** the grep corpus, so they can appear in another module's B and inflate its
leak, but they can never appear in anyone's A or D and their own A and D are absent. A flag whose
leak is carried by `desktop/` is the Tcl tier speaking a shared vocabulary the graph cannot see,
and the report says so rather than calling it scatter.

## The corpus (Count)

The corpus rule is **the tree as a reader meets it after a clone**: extensions
`.js .mjs .ts .tsx .jsx .md .json .sql .tcl .tm .css .html .yaml .yml .sh` (the census of
tracked-file extensions, minus lockfiles, fonts and images) — **1046 files**. Every file left in
after the exclusions below was checked against `git ls-files`.

| excluded | why |
|---|---|
| `node_modules/`, `.git/` | not the tree |
| `ds-bundle/`, `.ds-sync/`, `.design-sync/learnings/`, `.design-sync/.cache/`, `data/`, `dist/`, `tmp/`, `.venv/` | gitignored: build output, sync scratch, session notes |
| `.claude/` | agent-session folders (methodology, Count) |
| `web/src/locales/` | `lingui` catalogs and their compiled output: every `.po` carries a `#: path:line` reference per extracted string, which would add a file and hundreds of sites to every module with a translated string |
| `themes/design/` | untracked design artefacts (Design-Composer mocks) that a clone does not carry |
| `/db/2026*`, a connector's gitignored credential side file, `docs/deploy.local.md` | gitignored: dated operational migrations, a secret, a local deploy note |
| `package-lock.json` (root, `web/`, `agent/`) | lockfiles |

Test files are marked by `/tests/`, `/test/`, `.test.`, `_test.`, `selftest`, and are excluded
from A and D only, per the method; they remain in the corpus for B.

## Tiers

Three blind estimators on the cheap tier (Sonnet), each in a fresh context, each permitted one
Read of `oracle-brief.md` and the Write of its own reply, and no other tool call. Explain revives
the same estimators on the same tier.

## Where the bulk output lives

Outside the repository and outside the run folder, under `/usr/local/ai/scope/round-3/`:
`idx/web.scip`, `idx/server.scip` (raw protobufs), `idx/web.json`, `idx/server.json`,
`idx/index.json` (the merged index Count read), `servercfg/tsconfig.json`, `merge.py`,
`corpuscheck.py`, `measured-table.txt`. The scripts and the measured JSON are copied into the run
folder for the record.

## The repository was not modified

`git status --short` before and after the run shows the same single untracked file, an
environment backup under `agent/` that predates this run. No file was written into the tree.

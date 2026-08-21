# Survey — RobCo Terminal, round 3

## The tree measured

`/home/weiwu/code/RobCo-Terminal`, branch `main`, commit `354e8f4`, working tree clean before
and after the run. Eight crates, 170 `.rs` files, 108 of them source modules that define
symbols. **The repository was not modified**: nothing was written into it, and the indexer ran
with `CARGO_TARGET_DIR` pointed outside the tree.

This is the same commit rounds 1 and 2 measured. The run is therefore also a controlled
instrument test: the index is held fixed and the counting tool has changed.

## Indexer and tiers

```
CARGO_TARGET_DIR=/usr/local/ai/scope/robco-2026-08-21-round-1/target \
  rust-analyzer scip . --output /usr/local/ai/scope/robco-2026-08-21-round-3/index.scip
tools/scip2json.py index.scip index.json      # 170 documents
```

`rust-analyzer 1.97.1 (8bab26f 2026-07-14)`. The SCIP protobuf and its JSON are **byte-identical
to round 2's** (`md5 cb47be67…` / `5ef53832…`), so the indexer is reproducible on this codebase
and every difference between round 2's table and this one is the counting tool's.

Decoder pinned to `tools/scip2json.py`, as round 2's report requires: B is only as stable as
the vocabulary, and the vocabulary depends on which symbols the decoder marks as definitions.

**Tiers the index does not cover** — the run's blind spots, unchanged from round 2:

- 25 `.slang`, `.slangp` and `.wgsl` files under `crates/*/shaders/` plus `crates/term/src/shader.wgsl`.
  Shader source is neither indexed nor in the corpus; it is greped separately in Count.
- `crates/xtask/src/*` is indexed, but the shell scripts and `packaging/` data are not source
  the indexer reads.
- Nothing here is a scripting tier or generated code; the Rust tier is the program.

## Corpus rule

`--corpus-ext .rs,.md,.toml --exclude .claude/,target/,.git/ --tests-mark /tests/`

In: every `.rs`, `.md` and `.toml` a reader meets in the tree — sources, tests, both READMEs,
`docs/`, every manifest. Out, and why:

| excluded | reason |
|---|---|
| `target/` | build output, not a file a reader meets |
| `.git/` | history, not the tree |
| `.claude/` | agent-session material, not the program |
| `Cargo.lock` | tool default `--skip-files`; a generated dependency catalogue |

Tests are in the corpus for B (a test that mentions a concept is a place that speaks its
vocabulary) and out of A and D (`/tests/`), which is the methodology's rule.

## The concept list

- **Module concepts**: 108 source modules plus 58 test files that also define symbols; 166 rows.
  Two source modules (`app/src/main.rs`, `app/src/lib.rs`) have no distinctive vocabulary at all
  and carry A and D only — their B is *not measured*, never "well hidden".
- **Convention concepts**: names several files define, in `measured-table.md`'s second table.
- **Decided-once facts**: supplied by the estimators before they saw anything else, in `facts.md`.

## Tool versions

`scatter-scope` at commit `15caa5d` (2026-08-21 15:09). This is a **later commit than round 2
ran on**: `scope-count.py` has since gained the programming-commonplace stop list and the
"capitalised English word counted in code only, prose files excluded" rule that round 2's
`instrument.md` asked for. Round 2's B figures and this run's are therefore not comparable as
measurements of the code — the comparison in `instrument.md` is of the two instruments.

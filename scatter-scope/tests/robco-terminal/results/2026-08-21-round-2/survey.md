# Survey

## Repository state

`/home/weiwu/code/RobCo-Terminal`, branch `main`, HEAD `354e8f4` (2026-08-21 11:03 +1000),
working tree clean. The repository was not modified by this run.

## The module list, from the symbol index

Index: `rust-analyzer scip .` over the workspace root, with `CARGO_TARGET_DIR=/var/local/target`
so nothing was written inside the tree. The protobuf was decoded by `tools/scip2json.py`
(the `scip` CLI is not installed on this host).

The index and its build log live outside both the repository and the run folder, at
`/usr/local/ai/scope/robco-2026-08-21-round-2/`: `index.scip` (9.7 MB), `index.json` (9.4 MB),
`ra.log`. 170 documents; 166 files define symbols and appear on the measured table, of which
106 are source modules under `*/src/*.rs` and 60 are test files.

`tools/scope-count.py` derived a vocabulary per file: the names it alone defines (five
characters or more, `impl*` dropped, names defined outside the tree dropped) plus its file
stem, less names the system dictionary holds under any of its inflections.

Four source modules define symbols but carry no row of their own, because their stems name
nothing (`lib`, `mod`) and every name they re-export is defined elsewhere:
`crates/app/src/distortion.rs` (9 lines, a re-export), `crates/chassis/src/displays/mod.rs`,
`crates/crt-render/src/lib.rs`, `crates/tmux-cc/src/lib.rs`. Two more are on the table with
B and C unmeasured for the same reason: `crates/app/src/lib.rs` and `crates/app/src/main.rs`.
A and D still hold for those two. This is the instrument's floor, recorded in `report.md`.

## Sizes

| crate | source files | source lines | test files | test lines |
|---|---|---|---|---|
| app | 23 | 13565 | 18 | 5754 |
| chassis | 25 | 10059 | 14 | 2281 |
| config | 7 | 2979 | 0 | 0 |
| crt-burnin | 4 | 1101 | 2 | 515 |
| crt-render | 8 | 1780 | 9 | 2851 |
| term | 28 | 9311 | 12 | 3279 |
| tmux-cc | 6 | 1737 | 3 | 1088 |
| xtask | 9 | 2818 | 0 | 0 |

Docs: `README.md`, `docs/config.md`, `docs/config-format.md`, `docs/keys.md`,
`crates/crt-burnin/MOUNT.md`, `crates/tmux-cc/tests/transcripts/README.md`.

## The decided-once list, from the blind estimators

Three estimators, each in a fresh context with no code and no counts, named ten to twelve
facts apiece before any measurement. The brief required two of them by kind — the side of the
window the channel bank sits on, and the unit a screen coordinate is carried in — and left the
rest to the estimator. The merged list, with each estimator's expected places, is in
`facts.md`.

## Corpus

Extensions `.rs`, `.md`, `.toml`. Excluded: `target/` (a symlink to `/var/local/target`, a
build directory outside the tree), `.git/`, and `.claude/` — seventeen agent-session files
(shift ledgers, journals, handovers, plans, wave notes) that a reader meeting this repository
as a program would not meet, and which mention module names heavily. `Cargo.lock` is dropped
by the tool's default skip list. No generated catalogue, translation file or bundled asset
manifest exists in this tree, so nothing else was excluded.

## Blind spots

`rust-analyzer` covers every crate in the workspace; there is no second language tier in Rust.
There is a second *language* tier: thirteen shader files (`.slang` for librashader passes,
`.wgsl` for the grid renderer) under `crates/*/shaders/` and `crates/term/src/shader.wgsl`.
They are outside the symbol index entirely and outside the corpus, whose extensions are
`.rs`, `.md`, `.toml`. A uniform name or a piece of geometry that lives in both Rust and
shader text is therefore counted once, in Rust only; Count runs a supplementary grep over the
shader tier for the flagged rows and reports it separately, never folded into B.

`packaging/` holds a `.desktop` file and an icon; neither defines a symbol.

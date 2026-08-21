# Survey

## The module list, from the symbol index

Index: `rust-analyzer scip` over the workspace root, printed as JSON with `scip print --json`.
The index and its build log live outside the run folder, at `/usr/local/ai/scope/robco-2026-08-21-round-1/` (`index.scip` 9.7 MB, `index.json` 20 MB, `ra.log`), because they do not belong in a results folder.

110 source modules define symbols, across eight crates. `tools/scope-count.py` derived a vocabulary for each: the names it defines (five characters or more, `impl*` dropped) plus its file stem, less names that `/usr/share/dict/words` holds and less names more than one module defines. 104 of the 110 kept a distinctive vocabulary and are on the measured table. The six absent are `app/src/lib.rs`, `app/src/main.rs`, `chassis/src/displays/mod.rs`, `crt-render/src/lib.rs`, `tmux-cc/src/lib.rs` — whose stems the tool drops on purpose, as `lib`, `mod` and `main` name nothing — and `app/src/distortion.rs`, nine lines whose only distinctive name is a stem the dictionary holds. The dropping rule costs more than those six, though: it also thins the vocabulary of modules that stay, and that is a real instrument fault, recorded under Instrument in `report.md`.

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

Docs: `README.md`, `docs/config.md`, `docs/config-format.md`, `docs/keys.md`, `crates/crt-burnin/MOUNT.md`.

## The decided-once list, from the blind estimators

Each of the three estimators named twelve facts before seeing any measurement. The brief required two of them by kind — the side a panel sits on, and the unit a coordinate is carried in — and left the other ten to the estimator. Merged and deduplicated, the list is in `report.md` under Decided-once facts, with the expected places each estimator attached.

## Corpus

Extensions `.rs`, `.md`, `.toml`. Excluded: `target/` (a symlink to a build directory outside the tree), `.git/`, and `.claude/` — the last holds sixteen agent-session files (shift ledgers, journals, handovers, plans) that a reader meeting this repository as a program would not meet, and that mention module names heavily. Including them would have inflated every B in the table.

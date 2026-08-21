# Count

`tools/scope-count.py --root /home/weiwu/code/RobCo-Terminal --scip index.json --corpus-ext .rs,.md,.toml --exclude .claude/,target/,.git/ --tests-mark /tests/`

Output: `measured.json` (all 163 rows, including test files that define symbols) and `measured-table.md` (the same, formatted). 104 of the rows are source modules and carry the run.

## A supplementary column the tool does not compute

The methodology's A counts *consumers* — who uses this module. For a hub the interesting direction is the other one: how many modules this one draws types **from**. That figure came from the same index, is in `degree.json`, and appears as `out` on the pick table. It is reported beside the flags, never picked on.

Its distribution is the reason it earns a place: median 2, and one module at 46.

| out | module |
|---|---|
| 46 | `crates/app/src/window.rs` |
| 19 | `crates/chassis/src/furniture.rs` |
| 19 | `crates/term/src/lib.rs` |
| 16 | `crates/chassis/src/shells/slide_rule.rs` |
| 14 | `crates/chassis/src/lib.rs` |
| 13 | `crates/app/src/main.rs` |

## A on tests

A excludes test files by the methodology's rule. Two modules read very differently with them included, and the difference is itself informative:

| module | A (tests excluded) | A (tests included) |
|---|---|---|
| `crates/app/src/window.rs` | 1 | 12 |
| `crates/crt-burnin/src/headless.rs` | 1 | 27 |
| `crates/term/src/size.rs` | 4 | 15 |
| `crates/config/src/lib.rs` | 16 | 28 |
| `crates/app/src/tmux.rs` | 1 | 1 |

`window.rs` has one non-test consumer and eleven integration tests: the module is not depended on, it is *driven*. `tmux.rs` has one consumer either way, which is what makes its B of 30 the leak it is.

# Count — round 3

```
tools/scope-count.py --root /home/weiwu/code/RobCo-Terminal \
  --scip /usr/local/ai/scope/robco-2026-08-21-round-3/index.json \
  --corpus-ext .rs,.md,.toml --exclude .claude/,target/,.git/ --tests-mark /tests/ \
  --json measured.json --top 200
```

166 rows: 108 source modules, 58 test files that also define symbols. `measured-table.md` holds
both tables, `measured.json` the full vocabulary per row, `flagged-detail.json` the per-flag
B files with counts.

## What the table says on its own, before any oracle

The score column ranks by sites weighted by leak share. The top five:

| score | leak | A | D | B | C | module |
|---|---|---|---|---|---|---|
| 316 | 29 | 1 | 4 | 30 | 327 | `crates/app/src/tmux.rs` |
| 308 | 24 | 5 | 0 | 29 | 372 | `crates/chassis/src/oracle.rs` |
| 253 | 24 | 9 | 7 | 33 | 348 | `crates/chassis/src/metrics.rs` |
| 247 | 33 | 1 | 46 | 34 | 254 | `crates/app/src/window.rs` |
| 194 | 8 | 2 | 0 | 10 | 243 | `crates/app/src/channels.rs` |

`crt-render/src/params.rs`, which topped round 2's table at C=380, is now 22nd at C=84. The
module did not change; the tool did.

## D is the out-degree, and its distribution is a finding on its own

Median D over the 108 source modules is **1**. The top:

| D | module |
|---|---|
| 46 | `crates/app/src/window.rs` |
| 19 | `crates/term/src/lib.rs` |
| 19 | `crates/chassis/src/furniture.rs` |
| 16 | `crates/chassis/src/shells/slide_rule.rs` |
| 14 | `crates/chassis/src/lib.rs` |
| 13 | `crates/app/src/main.rs` |
| 11 | `crates/chassis/src/shells/mod.rs` |
| 10 | `crates/chassis/src/shells/switchboard.rs` |

One module draws types from forty-six others, against a median of one. A says nothing about it:
a hub is driven, not depended on. This figure is unchanged from round 2, as it must be — the
index is identical.

## A on tests

A excludes tests by rule. Where the two readings differ most:

| module | A (tests excluded) | A (tests included) |
|---|---|---|
| `crates/crt-burnin/src/headless.rs` | 1 | 27 |
| `crates/config/src/lib.rs` | 16 | 28 |
| `crates/term/src/size.rs` | 4 | 15 |
| `crates/term/src/session.rs` | 4 | 15 |
| `crates/term/src/gpu.rs` | 3 | 14 |
| `crates/app/src/window.rs` | 1 | 12 |
| `crates/app/src/tmux.rs` | 1 | 1 |

`headless.rs` is a test fixture: one production consumer, twenty-seven test consumers — not
depended on, driven. `tmux.rs` does not move at all, which is what makes its B mean what it means.

## The shader tier, greped separately

25 shader files are outside both the index and the corpus. Each measured module's exact
vocabulary was greped over that tier; real cross-tier vocabulary, not folded into B:

| module | shader sites | files | which names |
|---|---|---|---|
| `crates/chassis/src/oracle.rs` | 51 | 8 | `hash12` 24, `vnoise` 18, the three shader stems |
| `crates/crt-render/src/oracle.rs` | 10 | 8 | `terminal_frame` 6, `rand2` 4 |
| `crates/term/src/render.rs` | 6 | 1 | `origin_x`, `origin_y` |
| `crates/crt-render/src/degauss.rs` | 5 | 1 | `degauss`, `Degauss` |

Round 2 reported 205 shader sites for `crt-render/src/params.rs`, all of them the librashader
uniform-block word `params`. The stop list removed that word, and with it the whole false row.
What survives is the same real pair round 2 found: `hash12` and `vnoise` are written once in
shader source and once in Rust, which is what `chassis/src/oracle.rs` exists to do.

## Conventions

The second table in `measured-table.md`. The heads of it are unchanged from round 2 — the
five-name chassis/screen setting family with six to eight defining homes each, and the chassis
measure vocabulary (`unit_width`, `min_units`, `width_for_units`, `height_for_pad_cells`) with
four to five. Round 2 revived both: the first is finding 1 of that report, the second closed by
design as a trait with two implementors. This round does not re-revive them.

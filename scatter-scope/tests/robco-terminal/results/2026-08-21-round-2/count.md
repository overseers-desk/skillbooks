# Count

```
tools/scope-count.py --root /home/weiwu/code/RobCo-Terminal \
  --scip /usr/local/ai/scope/robco-2026-08-21-round-2/index.json \
  --corpus-ext .rs,.md,.toml --exclude .claude/,target/,.git/ --tests-mark /tests/ \
  --json measured.json --top 200
```

Output: `measured.json` and `measured-table.md` (166 rows: 106 source modules, 60 test files
that also define symbols). `flagged-detail.json` holds, for each flagged module, its full
vocabulary, its A files, its B files with per-file mention counts, and its leak files — the
material a revival needs to check the instrument.

## D is the out-degree, and its distribution is a finding on its own

Median D over the 106 source modules is 1. The top of the distribution:

| D | module |
|---|---|
| 46 | `crates/app/src/window.rs` |
| 19 | `crates/term/src/lib.rs` |
| 19 | `crates/chassis/src/furniture.rs` |
| 16 | `crates/chassis/src/shells/slide_rule.rs` |
| 14 | `crates/chassis/src/lib.rs` |
| 13 | `crates/app/src/main.rs` |
| 11 | `crates/chassis/src/shells/mod.rs` |
| 10 | `crates/chassis/src/shells/annunciator.rs` |

One module draws types from forty-six others. A says nothing about it: a hub is driven, not
depended on.

## A on tests

A excludes test files by the methodology's rule. Where the two readings differ they say
something:

| module | A (tests excluded) | A (tests included) |
|---|---|---|
| `crates/crt-burnin/src/headless.rs` | 1 | 27 |
| `crates/term/src/session.rs` | 4 | 15 |
| `crates/app/src/window.rs` | 1 | 12 |
| `crates/chassis/src/oracle.rs` | 5 | 12 |
| `crates/crt-render/src/params.rs` | 4 | 10 |
| `crates/config/src/lib.rs` | 16 | 28 |
| `crates/app/src/tmux.rs` | 1 | 1 |
| `crates/config/src/toml.rs` | 5 | 5 |

`headless.rs` is a test fixture with one production consumer and twenty-seven test consumers:
it is not depended on, it is driven. `tmux.rs` and `toml.rs` do not move at all, which is what
makes their B figures mean what they mean.

## The shader tier, greped separately

Thirteen `.slang` and `.wgsl` files are outside both the index and the corpus. A supplementary
grep of each flagged module's vocabulary over that tier found real cross-tier vocabulary in
exactly two places, and it is not folded into B:

| module | shader-tier sites | which names |
|---|---|---|
| `crates/chassis/src/oracle.rs` | 42 across 4 shaders | `vnoise` (18), `hash12` (24) |
| `crates/crt-render/src/params.rs` | 205 across 12 shaders | `params` alone |

`params` is the librashader uniform-block name, so its 205 sites are the instrument's, not the
module's. `vnoise` and `hash12` are the same two hash functions written once in WGSL-family
shader source and once in Rust — the CPU oracle. That pair is a genuine second home the
symbol graph cannot see, and it is what `crates/chassis/src/oracle.rs`'s own doc line says it
is for.

## Conventions

`measured-table.md` carries the second table: names several files define. Five setting names
(`frame_size`, `screen_curvature`, `screen_radius`, `frame_shininess`, `ambient_light`) have
six to eight defining homes each; a chassis measure vocabulary (`unit_width`, `min_units`,
`width_for_units`, `height_for_pad_cells`) has four to five. `revivals/conventions.md`
explains them.

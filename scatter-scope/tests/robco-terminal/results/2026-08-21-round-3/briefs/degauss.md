# Measured figures for `crates/crt-render/src/degauss.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 1 | 4 |
| B | 2 | 16 |
| C | 3 | 124 |
| D | 1 | 0 |

leak (B files the graph did not already count in A): 12  ·  flags: A high, B high

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
Degauss, DegaussState, PEAK_BRIGHTNESS, PEAK_SCALE_Y, degauss, is_active, is_running, scale_y
```

## A files (the graph's consumers)

- `crates/app/src/column.rs`
- `crates/app/src/window.rs`
- `crates/crt-render/src/lib.rs`
- `crates/crt-render/src/params.rs`

## B files, with sites and the words that produced them

- `crates/crt-render/tests/pass_graph.rs` — 34 sites: DegaussState 14, degauss 11, scale_y 4, Degauss 2, is_active 2, is_running 1
- `crates/crt-render/tests/contracts.rs` — 27 sites: DegaussState 7, PEAK_BRIGHTNESS 6, degauss 4, PEAK_SCALE_Y 4, scale_y 3, Degauss 2, is_running 1
- `crates/app/src/window.rs` — 17 sites: degauss 11, Degauss 3, DegaussState 3
- `crates/crt-render/src/params.rs` — 12 sites: degauss 6, DegaussState 4, PEAK_BRIGHTNESS 1, scale_y 1
- `crates/app/tests/channel_bank.rs` — 12 sites: DegaussState 4, degauss 3, is_active 3, Degauss 1, scale_y 1
- `crates/crt-render/src/lib.rs` — 6 sites: degauss 4, Degauss 1, DegaussState 1
- `crates/crt-render/tests/burn_in_chain.rs` — 3 sites: DegaussState 3
- `crates/crt-render/tests/glyph_survival.rs` — 2 sites: DegaussState 2
- `crates/app/tests/structure_subset.rs` — 2 sites: DegaussState 2
- `crates/app/src/channels.rs` — 2 sites: degauss 2
- `crates/app/src/column.rs` — 2 sites: DegaussState 2
- `crates/crt-render/Cargo.toml` — 1 sites: degauss 1
- `crates/crt-render/tests/support/mod.rs` — 1 sites: degauss 1
- `crates/crt-render/src/chain.rs` — 1 sites: degauss 1
- `crates/app/tests/settings_live_reload.rs` — 1 sites: DegaussState 1
- `crates/app/src/instance.rs` — 1 sites: degauss 1

## Leak files (B minus A)

- `crates/app/src/channels.rs`
- `crates/app/src/instance.rs`
- `crates/app/tests/channel_bank.rs`
- `crates/app/tests/settings_live_reload.rs`
- `crates/app/tests/structure_subset.rs`
- `crates/crt-render/Cargo.toml`
- `crates/crt-render/src/chain.rs`
- `crates/crt-render/tests/burn_in_chain.rs`
- `crates/crt-render/tests/contracts.rs`
- `crates/crt-render/tests/glyph_survival.rs`
- `crates/crt-render/tests/pass_graph.rs`
- `crates/crt-render/tests/support/mod.rs`

# Measured figures for `crates/chassis/src/shells/annunciator.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 1 | 2 |
| B | 2 | 30 |
| C | 3 | 114 |
| D | 5 | 10 |

leak (B files the graph did not already count in A): 28  ·  flags: B high

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
CUT_DARK, KEY_HEIGHT, KEY_TOP, KEY_WIDTH, LABEL_COLOR, LIP_LIGHT, NUMERAL_FILL, NUMERAL_SHADOW, REST_OPACITY, annunciator, channel_button, pager_painting, plate_metal_params, plate_rect
```

## A files (the graph's consumers)

- `crates/chassis/src/metrics.rs`
- `crates/chassis/src/shells/mod.rs`

## B files, with sites and the words that produced them

- `crates/chassis/src/shells/mod.rs` — 17 sites: annunciator 13, plate_rect 2, plate_metal_params 2
- `crates/chassis/src/shells/switchboard.rs` — 11 sites: plate_rect 9, annunciator 2
- `crates/chassis/tests/bank_frame_geometry.rs` — 10 sites: annunciator 10
- `crates/chassis/tests/region_layout.rs` — 9 sites: annunciator 6, plate_rect 3
- `crates/chassis/tests/shader_recipes.rs` — 8 sites: annunciator 6, plate_metal_params 2
- `crates/chassis/src/metrics.rs` — 8 sites: annunciator 8
- `crates/chassis/tests/metrics_homes.rs` — 7 sites: annunciator 7
- `crates/chassis/src/bank.rs` — 4 sites: annunciator 4
- `crates/chassis/src/frame.rs` — 4 sites: annunciator 4
- `crates/chassis/tests/gpu_annunciator.rs` — 3 sites: annunciator 3
- `crates/chassis/src/furniture.rs` — 3 sites: annunciator 3
- `crates/chassis/src/shells/common.rs` — 3 sites: annunciator 3
- `docs/config.md` — 2 sites: annunciator 2
- `crates/chassis/tests/bank_frame_render.rs` — 2 sites: annunciator 2
- `crates/chassis/tests/metrics_tables.rs` — 2 sites: annunciator 2
- `crates/chassis/src/lib.rs` — 2 sites: annunciator 2
- `crates/chassis/src/seam.rs` — 2 sites: annunciator 2
- `crates/chassis/src/color.rs` — 2 sites: annunciator 2
- `crates/chassis/src/strip.rs` — 2 sites: annunciator 2
- `crates/chassis/src/shells/slide_rule.rs` — 2 sites: annunciator 2
- `crates/app/tests/channel_bank.rs` — 2 sites: annunciator 2
- `crates/chassis/src/paint.rs` — 1 sites: annunciator 1
- `crates/crt-render/tests/pass_graph.rs` — 1 sites: annunciator 1
- `crates/term/src/fonts/subpixel.rs` — 1 sites: annunciator 1
- `crates/app/tests/seam_drag.rs` — 1 sites: annunciator 1
- `crates/app/src/bank.rs` — 1 sites: annunciator 1
- `crates/app/src/column.rs` — 1 sites: annunciator 1
- `crates/app/src/shell.rs` — 1 sites: annunciator 1
- `crates/config/src/profile.rs` — 1 sites: annunciator 1
- `crates/config/src/schema.rs` — 1 sites: annunciator 1

## Leak files (B minus A)

- `crates/app/src/bank.rs`
- `crates/app/src/column.rs`
- `crates/app/src/shell.rs`
- `crates/app/tests/channel_bank.rs`
- `crates/app/tests/seam_drag.rs`
- `crates/chassis/src/bank.rs`
- `crates/chassis/src/color.rs`
- `crates/chassis/src/frame.rs`
- `crates/chassis/src/furniture.rs`
- `crates/chassis/src/lib.rs`
- `crates/chassis/src/paint.rs`
- `crates/chassis/src/seam.rs`
- `crates/chassis/src/shells/common.rs`
- `crates/chassis/src/shells/slide_rule.rs`
- `crates/chassis/src/shells/switchboard.rs`
- `crates/chassis/src/strip.rs`
- `crates/chassis/tests/bank_frame_geometry.rs`
- `crates/chassis/tests/bank_frame_render.rs`
- `crates/chassis/tests/gpu_annunciator.rs`
- `crates/chassis/tests/metrics_homes.rs`
- `crates/chassis/tests/metrics_tables.rs`
- `crates/chassis/tests/region_layout.rs`
- `crates/chassis/tests/shader_recipes.rs`
- `crates/config/src/profile.rs`
- `crates/config/src/schema.rs`
- `crates/crt-render/tests/pass_graph.rs`
- `crates/term/src/fonts/subpixel.rs`
- `docs/config.md`

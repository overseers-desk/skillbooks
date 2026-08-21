# Measured figures for `crates/chassis/src/metrics.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 3 | 9 |
| B | 5 | 33 |
| C | 8 | 348 |
| D | 2 | 7 |

leak (B files the graph did not already count in A): 24  ·  flags: B high, D high (hub)

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
DisplayMetrics, LedMetrics, SWITCHBOARD_PAGER_HEIGHT, ShellMetrics, TAPE_LETTER_PIXEL_SIZE, TAPE_NATURAL_HEIGHT, TapeMetrics, annunciator, casting_color, casting_light_dir, chassis_carries_track, column_gap, dot_pitch, end_pad, from_hex_literal, hex_literal_divides_by_255, led_metrics_match_the_defining_formulas, min_characters, min_row_height, numeral_width, pad_cells, pager_extra, pager_natural_height, pager_squeeze_span, right_padding, side_pad_cells, strip_padding, tape_metrics_match_the_defining_formulas
```

## A files (the graph's consumers)

- `crates/app/src/bank.rs`
- `crates/chassis/src/bank.rs`
- `crates/chassis/src/cabinet.rs`
- `crates/chassis/src/frame.rs`
- `crates/chassis/src/furniture.rs`
- `crates/chassis/src/lib.rs`
- `crates/chassis/src/seam.rs`
- `crates/chassis/src/shells/slide_rule.rs`
- `crates/chassis/src/strip.rs`

## B files, with sites and the words that produced them

- `crates/chassis/tests/metrics_homes.rs` — 104 sites: casting_color 10, ShellMetrics 9, LedMetrics 7, annunciator 7, right_padding 6, column_gap 6, numeral_width 6, strip_padding 6
- `crates/chassis/src/bank.rs` — 34 sites: LedMetrics 9, annunciator 4, ShellMetrics 3, DisplayMetrics 2, min_row_height 2, strip_padding 2, column_gap 2, TapeMetrics 2
- `crates/chassis/src/lib.rs` — 29 sites: LedMetrics 6, TapeMetrics 3, min_characters 3, DisplayMetrics 2, ShellMetrics 2, annunciator 2, end_pad 2, numeral_width 2
- `crates/chassis/tests/bank_frame_geometry.rs` — 26 sites: annunciator 10, LedMetrics 5, TapeMetrics 2, end_pad 2, numeral_width 1, column_gap 1, right_padding 1, side_pad_cells 1
- `crates/chassis/src/cabinet.rs` — 19 sites: LedMetrics 6, ShellMetrics 3, TapeMetrics 3, pad_cells 3, DisplayMetrics 2, end_pad 1, min_characters 1
- `crates/chassis/src/frame.rs` — 17 sites: from_hex_literal 6, annunciator 4, ShellMetrics 3, casting_light_dir 2, casting_color 2
- `crates/chassis/src/furniture.rs` — 14 sites: ShellMetrics 4, annunciator 3, LedMetrics 2, TapeMetrics 2, numeral_width 1, column_gap 1, min_characters 1
- `crates/chassis/src/displays/led/metrics.rs` — 14 sites: dot_pitch 8, min_characters 2, side_pad_cells 2, LedMetrics 1, DisplayMetrics 1
- `crates/chassis/src/shells/mod.rs` — 13 sites: annunciator 13
- `crates/chassis/tests/bank_frame_render.rs` — 8 sites: casting_color 3, LedMetrics 2, annunciator 2, casting_light_dir 1
- `crates/chassis/src/seam.rs` — 8 sites: LedMetrics 5, annunciator 2, DisplayMetrics 1
- `crates/chassis/src/displays/tape/metrics.rs` — 7 sites: end_pad 3, pad_cells 2, TapeMetrics 1, DisplayMetrics 1
- `crates/chassis/tests/shader_recipes.rs` — 6 sites: annunciator 6
- `crates/chassis/tests/region_layout.rs` — 6 sites: annunciator 6
- `crates/chassis/src/shells/switchboard.rs` — 5 sites: ShellMetrics 2, annunciator 2, SWITCHBOARD_PAGER_HEIGHT 1
- `crates/chassis/src/strip.rs` — 4 sites: LedMetrics 2, annunciator 2
- `crates/chassis/src/shells/annunciator.rs` — 4 sites: annunciator 2, ShellMetrics 2
- `crates/chassis/src/shells/slide_rule.rs` — 4 sites: ShellMetrics 2, annunciator 2
- `crates/chassis/tests/metrics_tables.rs` — 3 sites: annunciator 2, min_row_height 1
- `crates/chassis/tests/gpu_annunciator.rs` — 3 sites: annunciator 3
- `crates/chassis/src/color.rs` — 3 sites: annunciator 2, from_hex_literal 1
- `crates/chassis/src/shells/common.rs` — 3 sites: annunciator 3
- `docs/config.md` — 2 sites: annunciator 2
- `crates/app/tests/channel_bank.rs` — 2 sites: annunciator 2
- `crates/app/src/bank.rs` — 2 sites: annunciator 1, LedMetrics 1
- `crates/chassis/src/paint.rs` — 1 sites: annunciator 1
- `crates/crt-render/tests/pass_graph.rs` — 1 sites: annunciator 1
- `crates/term/src/fonts/subpixel.rs` — 1 sites: annunciator 1
- `crates/app/tests/seam_drag.rs` — 1 sites: annunciator 1
- `crates/app/src/column.rs` — 1 sites: annunciator 1
- `crates/app/src/shell.rs` — 1 sites: annunciator 1
- `crates/config/src/profile.rs` — 1 sites: annunciator 1
- `crates/config/src/schema.rs` — 1 sites: annunciator 1

## Leak files (B minus A)

- `crates/app/src/column.rs`
- `crates/app/src/shell.rs`
- `crates/app/tests/channel_bank.rs`
- `crates/app/tests/seam_drag.rs`
- `crates/chassis/src/color.rs`
- `crates/chassis/src/displays/led/metrics.rs`
- `crates/chassis/src/displays/tape/metrics.rs`
- `crates/chassis/src/paint.rs`
- `crates/chassis/src/shells/annunciator.rs`
- `crates/chassis/src/shells/common.rs`
- `crates/chassis/src/shells/mod.rs`
- `crates/chassis/src/shells/switchboard.rs`
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

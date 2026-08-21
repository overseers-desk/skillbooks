# Measured figures for `crates/term/src/fonts/mod.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 4 | 16 |
| B | 6 | 26 |
| C | 10 | 117 |
| D | 3 | 2 |

leak (B files the graph did not already count in A): 10  ·  flags: A high, B high

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
BASE_FONT_PIXEL_HEIGHT, Bundled, BundledFont, FontData, FontEntry, MODERN_RASTERIZATION, SYSTEM_FONT_PIXEL_SIZE, System, a_filtered_out_name_falls_back_to_the_first_offered, base_width, each_rasterization_mode_offers_its_own_half, fallback_base_width, fallback_name, filtered_fonts, font_by_name, is_system, low_resolution_fonts, missing_system_face, resolve_all, resolve_bundled, resolve_font_name, the_catalogue_matches_the_recorded_entries, the_low_resolution_list_is_what_the_displays_letter_from, the_system_half_is_populate_system_fonts
```

## A files (the graph's consumers)

- `crates/app/src/window.rs`
- `crates/chassis/src/displays/led/mod.rs`
- `crates/chassis/src/displays/tape/metrics.rs`
- `crates/chassis/src/furniture.rs`
- `crates/chassis/src/lib.rs`
- `crates/chassis/src/paint.rs`
- `crates/chassis/src/shells/annunciator.rs`
- `crates/chassis/src/shells/slide_rule.rs`
- `crates/chassis/src/shells/switchboard.rs`
- `crates/term/examples/led_diff.rs`
- `crates/term/src/atlas.rs`
- `crates/term/src/fonts/metrics.rs`
- `crates/term/src/fonts/sizing.rs`
- `crates/term/src/fonts/system.rs`
- `crates/term/src/fonts/text.rs`
- `crates/term/src/lib.rs`

## B files, with sites and the words that produced them

- `crates/term/tests/system_fonts.rs` — 18 sites: filtered_fonts 3, MODERN_RASTERIZATION 3, is_system 3, resolve_font_name 3, font_by_name 2, SYSTEM_FONT_PIXEL_SIZE 2, FontEntry 1, base_width 1
- `crates/term/src/fonts/sizing.rs` — 16 sites: font_by_name 8, FontEntry 4, BASE_FONT_PIXEL_HEIGHT 2, fallback_name 1, base_width 1
- `crates/term/tests/font_parity.rs` — 14 sites: font_by_name 5, base_width 3, is_system 2, fallback_name 2, FontEntry 1, low_resolution_fonts 1
- `crates/term/tests/pixel_properties.rs` — 8 sites: font_by_name 4, FontEntry 4
- `crates/term/tests/antialias.rs` — 8 sites: font_by_name 4, FontEntry 3, is_system 1
- `crates/term/src/fonts/system.rs` — 8 sites: FontEntry 3, font_by_name 2, resolve_all 2, is_system 1
- `crates/term/src/atlas.rs` — 7 sites: FontEntry 4, font_by_name 2, missing_system_face 1
- `crates/chassis/src/furniture.rs` — 4 sites: font_by_name 4
- `crates/term/tests/preedit.rs` — 4 sites: font_by_name 2, FontEntry 2
- `crates/app/src/window.rs` — 4 sites: FontEntry 2, font_by_name 2
- `crates/chassis/src/lib.rs` — 3 sites: font_by_name 3
- `crates/chassis/src/shells/slide_rule.rs` — 3 sites: font_by_name 3
- `crates/term/src/lib.rs` — 3 sites: FontEntry 2, font_by_name 1
- `crates/crt-render/tests/glyph_survival.rs` — 2 sites: font_by_name 2
- `crates/term/tests/scrollback.rs` — 2 sites: font_by_name 2
- `crates/term/src/fonts/metrics.rs` — 2 sites: font_by_name 2
- `crates/term/src/fonts/text.rs` — 2 sites: FontEntry 1, font_by_name 1
- `crates/chassis/tests/led_display.rs` — 1 sites: font_by_name 1
- `crates/chassis/tests/metrics_homes.rs` — 1 sites: font_by_name 1
- `crates/chassis/tests/tape_display.rs` — 1 sites: font_by_name 1
- `crates/chassis/src/paint.rs` — 1 sites: font_by_name 1
- `crates/chassis/src/shells/annunciator.rs` — 1 sites: font_by_name 1
- `crates/chassis/src/shells/switchboard.rs` — 1 sites: font_by_name 1
- `crates/chassis/src/displays/led/mod.rs` — 1 sites: font_by_name 1
- `crates/chassis/src/displays/tape/metrics.rs` — 1 sites: font_by_name 1
- `crates/term/examples/led_diff.rs` — 1 sites: font_by_name 1

## Leak files (B minus A)

- `crates/chassis/tests/led_display.rs`
- `crates/chassis/tests/metrics_homes.rs`
- `crates/chassis/tests/tape_display.rs`
- `crates/crt-render/tests/glyph_survival.rs`
- `crates/term/tests/antialias.rs`
- `crates/term/tests/font_parity.rs`
- `crates/term/tests/pixel_properties.rs`
- `crates/term/tests/preedit.rs`
- `crates/term/tests/scrollback.rs`
- `crates/term/tests/system_fonts.rs`

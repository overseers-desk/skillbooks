# Measured figures for `crates/term/src/atlas.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 1 | 4 |
| B | 3 | 12 |
| C | 6 | 69 |
| D | 3 | 4 |

leak (B files the graph did not already count in A): 8  ·  flags: A high, B high

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
CellMetrics, FALLBACK_FACE, FontContext, GlyphAtlas, GlyphSlot, a_face_with_no_data_builds_the_context_on_the_bundled_fallback, atlas_x, atlas_y, build_atlas, distinct_values, font_id, font_system, for_face, intermediate_value_count, scale_context, shape_to_glyph_ids, total_value_count, value_histogram
```

## A files (the graph's consumers)

- `crates/app/src/badge.rs`
- `crates/app/src/window.rs`
- `crates/term/src/lib.rs`
- `crates/term/src/render.rs`

## B files, with sites and the words that produced them

- `crates/term/tests/pixel_properties.rs` — 27 sites: intermediate_value_count 9, FontContext 6, build_atlas 6, total_value_count 3, value_histogram 3
- `crates/term/src/lib.rs` — 9 sites: FontContext 3, GlyphAtlas 2, for_face 2, CellMetrics 1, build_atlas 1
- `crates/term/src/render.rs` — 9 sites: GlyphAtlas 7, atlas_x 1, atlas_y 1
- `crates/app/src/window.rs` — 4 sites: FontContext 3, CellMetrics 1
- `crates/app/src/badge.rs` — 4 sites: GlyphAtlas 2, atlas_x 1, atlas_y 1
- `crates/crt-render/tests/glyph_survival.rs` — 3 sites: FontContext 2, build_atlas 1
- `crates/term/tests/scrollback.rs` — 3 sites: FontContext 2, build_atlas 1
- `crates/term/tests/preedit.rs` — 3 sites: FontContext 2, build_atlas 1
- `crates/term/tests/system_fonts.rs` — 3 sites: FontContext 2, for_face 1
- `crates/term/tests/antialias.rs` — 2 sites: intermediate_value_count 1, total_value_count 1
- `crates/term/src/bin/esctest_harness.rs` — 1 sites: CellMetrics 1
- `crates/app/tests/size_badge.rs` — 1 sites: GlyphAtlas 1

## Leak files (B minus A)

- `crates/app/tests/size_badge.rs`
- `crates/crt-render/tests/glyph_survival.rs`
- `crates/term/src/bin/esctest_harness.rs`
- `crates/term/tests/antialias.rs`
- `crates/term/tests/pixel_properties.rs`
- `crates/term/tests/preedit.rs`
- `crates/term/tests/scrollback.rs`
- `crates/term/tests/system_fonts.rs`

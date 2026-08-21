# chassis/oracle.rs — flagged-module check

**Instrument check.** 29 B files, but 10 are `crates/*/tests/*.rs` (plate_metal,
chassis_metal, frame_metal, shader_recipes, gpu_annunciator, bank_frame_render,
tape_display/label, led_matrix, region_layout) plus `bank_column.rs` and
`crt-render` test files — all legitimate corpus members, nothing pulled in from
outside the tree. The 24 "leak" files are exactly the test files (A excludes
tests by definition) plus `crt-render/{oracle,params,preset}.rs`; not a bug in
the graph, just A/B's stated scope split.

No single word carries the count: per-word totals over the 24-name vocabulary
range 3–51 (`chassis_metal` 51, `light_dir` 40, down to `rrect_px` 3), roughly
even spread across ten struct-field names, not one generic term inflating C.

**Mechanism.** `oracle.rs` defines `ChassisMetalParams`/`FrameMetalParams`/
`PlateMetalParams`/`MetalParams`, the CPU mirror of the shader uniform structs.
Three shell files (`annunciator`, `slide_rule`, `switchboard`) import these
types directly to build real per-element paint parameters (A=5, not my guessed
0) — the module isn't test-only, it's the shared type definition between CPU
paint code and GPU shaders. Every construction site of these structs restates
every field name once, and there are many construction sites: three shells ×
many painted elements, plus ~10 golden-value parity tests that build params
field-by-field and diff CPU output against GPU output pixel-for-pixel. `hash12`
and `vnoise` also appear in four `.slang`/`.wgsl` shader files outside the
corpus (42 combined sites) — the vocabulary is deliberately shared with the
shader source it mirrors.

I underestimated D too (guessed 3, measured 0): the module is pure leaf math
(hash/noise functions, arithmetic on `[f32;2]`), it imports nothing project-
specific.

**Verdict: by design.** A shared parameter-struct vocabulary, read at every
paint call site and every parity test, because the module's job is to be both
the real uniform-type definition and the CPU oracle checked against shader
output — wide reading is the point, not a scattering cost.

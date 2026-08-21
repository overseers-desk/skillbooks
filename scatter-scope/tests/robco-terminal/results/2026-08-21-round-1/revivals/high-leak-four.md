# Revival: the four next-highest leaks

Estimators 3 and 1 (whichever was furthest off on each), one context, four modules.
Given the measured figures and the instruction to check the instrument before the cause. Read-only.

## `crates/chassis/src/shaders.rs` — guessed A=1 B=2 C=3; measured A=2 B=39 C=102, leak 37

**Count check: fails.** 39 files do carry the word, but the word is the file stem, `shaders`, and this is a program whose whole subject is rendering. Every module that discusses a GPU pass, a CRT filter or a slang preset says "shaders" without owing anything to this file. The module's actual distinctive names — `CHASSIS_METAL_SLANG`, `FRAME_METAL_SLANG`, `PLATE_METAL_SLANG`, `LED_MATRIX_SLANG`, `TAPE_LABEL_SLANG` — appear in **three** files: `chassis/src/column.rs`, `crt-render/src/preset.rs`, and `shaders.rs` itself. **Corrected B is 3 to 5, not 39.**

**Disposition: measurement artefact.** The highest leak in the workspace is the tool's, not the code's. The mechanism, once the stem is removed, is narrow and correct: two consumers of five compiled-in source strings.

## `crates/term/src/cells.rs` — guessed A=2 B=4 C=8; measured A=4 B=35 C=194, leak 31

**Count check: holds.** `CellGrid`, `Cell`, `CursorState`, `CursorShape`, `row_mut`, `fill_row`, `charset` re-derive to about 31 files; the stem adds the rest. These are distinctive types and the mentions are real.

**Mechanism.** The module is the renderer's own screen model, and `CellGrid::from_lines()` is how roughly fourteen test files build a fixture grid before asserting something about pixels. In source, `render.rs`, `atlas.rs`, `grid.rs` and `rio_grid.rs` take `Cell` and `CellGrid`; the `vt` submodule bridges rio-vt's model to this one.

**Disposition: by design.** The leak is test density around a fixture constructor, which is the shape the test suite was meant to have.

## `crates/crt-burnin/src/headless.rs` — guessed A=1 B=2 C=3; measured A=1 B=22 C=108, leak 21

**Count check: holds.** `GpuLock`, `GpuError`, `make_input`, `make_output` re-derive to 21 files with no collisions. (The stem `headless` alone would have caught 50; the tool did not use it that way.)

**Mechanism.** The module owns the workspace's GPU device and a machine-wide exclusive lock. Every chassis and crt-render test that needs real GPU output takes `GpuLock::new()` first. The module's own doc gives the reason: three concurrent devices segfault, and three concurrent workspace runs wedge for 55 minutes.

**Disposition: by design, with a real cost acknowledged in the code.** The wide read is the harness working as intended; the cost — every GPU test serialised behind one lock — is stated in the module rather than discovered.

## `crates/term/src/size.rs` — guessed A=2 B=4 C=8; measured A=4 B=21 C=160, leak 17

**Count check: partly fails.** `CellSize` and `TermSize` re-derive to 16 files and are clean. `Viewport`, also defined here, is not: `librashader::runtime` exports a `Viewport` of its own, which `crt-render/src/chain.rs`, `crt-burnin/src/chain.rs` and `crt-burnin/src/headless.rs` import, and `crt-render/src/preset.rs` has an unrelated `Scale::Viewport` variant. **Corrected B is about 16 to 18**, with roughly three files falsely attributed.

**Mechanism.** What survives correction is the core geometry type: `CellSize` and `TermSize` define the grid, and about eleven app tests set up scenarios with specific grid dimensions.

**Disposition: measurement artefact in part, by design for the remainder.** The tool's vocabulary rule drops a name that two modules in the tree define, but it cannot see a name that a *dependency* defines. That is a gap in the instrument, not in this module.

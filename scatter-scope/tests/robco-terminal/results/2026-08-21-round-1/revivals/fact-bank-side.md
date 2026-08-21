# Drill: which side the channel bank sits on

The decided-once fact all three estimators named, and the one the brief required by kind.
Cheap-tier agent, read-only in the repository, greps followed by reading every hit in context. Nothing written; the repository is unchanged.

**Expected places (median of three blind estimates): 10** — from 5, 11 and 10.

## The one place it is decided

`crates/chassis/src/layout.rs:73-82`, `WindowLayout::new`, builds both rectangles from `bank_width`: the bank at x=0 for its own width, the well from there to the window's right edge. That is the canonical definition and it is one edit.

## Functional sites that assume left-ness — 9

Places that hold a *derived scalar* instead of the rectangle it came from, and re-derive position arithmetic from it:

1. `chassis/src/seam.rs:134-136` — `SeamDrag::hit`: the grab strip is `bank_width - SEAM_GRAB_INSET`, i.e. `bank_width` read as the bank's right-edge x measured from window x=0.
2. `chassis/src/seam.rs:100-112` — `SeamContext::characters_at`'s `at_limit`: `window_width - CRT_MINIMUM_WIDTH` as the drag ceiling, assuming the bank grows rightward from 0 and the well's floor is pinned to the window's right edge.
3. `app/src/window.rs:2325` — `cell_at`: `position.x - bank_physical()` translates a window-space pointer x into well space.
4. `app/src/window.rs:1250-1253` — `ime_cursor_area`: `top_left.x + bank`, the same translation back.
5. `app/src/window.rs:2477-2489` — `strip_pressed`: passes raw window-logical x,y into `Cabinet::strip_at`, which expects column-local coordinates (`furniture.rs:360`). Correct only because `bank.x == 0`.
6. `app/src/window.rs:2121-2126` — `draw_frame`: `glass.chain.frame_at(..., (bank, 0), ...)` blits the rendered well into the swapchain at that offset.
7. `app/src/column.rs:1144` — `Blit::draw`: `let rect = (0, 0, column.0, column.1);` — the column's casting always at the window origin. The doc comment above it says "at the window's left edge" outright.
8. `app/src/window.rs:2192` — the size-badge rect `(bank as i32, 0, target_width, target_height)`.
9. `xtask/src/snap.rs:292-360` — `bank_width`/`fit_units` in the screenshot harness: computes the on-screen seam as window-left-edge-plus-bank-width and drives real `xdotool` clicks there. Not shipped code, but it would mis-click silently.

## Prose that assumes it — 13

`chassis/layout.rs:5,58,100`, `chassis/lib.rs:3`, `chassis/shaders.rs:27`, `chassis/bank.rs:2`, `chassis/frame.rs:2,95`, `crt-render/lib.rs:44`, `crt-render/preset.rs:173`, `app/column.rs:28,443`, `app/window.rs:44`. (Decorative "left" hits — screw placement, plate margins, glyph strokes — excluded; they concern a shell's own left edge, not the window's.)

## Side-agnostic readers — about 8

`WindowLayout::normalized_screen_scale` and `WindowLayout::chassis_field` (whose offset formula `(bank.x - crt.x)/field_w` already generalises to either side), `frame::FrameScale::build` and `chassis_params` downstream of them, and `Cabinet::bank_width`, `bank_width_physical`, `resized`/`remeasure` and `cursor_moved`'s `SeamContext` construction. All take `layout.bank.width` / `layout.crt.right()` off the rectangles rather than rebuilding geometry. These would need no edit.

## Is the side named anywhere? — No

No `BankSide`, no `Side::Left`, no `bank_on_left`, no `bank_position`, no config key. The whole tree was searched across `.rs`, `.md` and `.toml`. The fact has no name; it exists only as the constant `0.0` in `WindowLayout::new` and as arithmetic at the nine sites above.

## A corroborating test

`crates/chassis/tests/region_layout.rs:65-88`, `field_mapping_at_sampled_window_sizes`, builds its chassis rectangle at `bank_x = window_w - bank_w` and says so in its own doc: "modelling the bank sitting to the right of a frame that spans the whole window". It passes. `shells::common::field_mapping` genuinely works for either side, and the test proves it. This is not a contradiction of the left-side fact and not a bug; it is evidence that the `chassis` crate's geometry is already side-agnostic, and that the nine assuming sites are the ones that stopped reading it.

## Mechanism

`WindowLayout` genuinely is the single source of truth for the two rectangles, and most of `chassis` reads them properly. The leak happens wherever a caller keeps the derived scalar — `bank_width`, `bank_physical()` — rather than the rectangle it came from, and then reinvents "x=0 is the bank's home" in its own arithmetic. GPU composition (`(bank, 0)` offsets, blit rects), pointer hit-testing (`x - bank_physical`) and the seam's drag law each arrived at that independently. Because `WindowLayout` never publishes a *which side* fact, nothing forces a call site through the rectangles; the scalar shortcut is silently correct today only because `bank.x` happens to be `0.0`.

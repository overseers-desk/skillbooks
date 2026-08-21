# Revival: `crates/app/src/window.rs`

Estimator 3 (furthest off: guessed A=1, B=3, C=5; measured A=1, B=25, C=217).
Given the measured figures, the leak and the outward-dependency count, and the instruction to check the instrument before the cause. Read-only.

## 1. Count check

The B files are the twenty-five that carry `TerminalSurface` (twenty of them), `draw_frame` (five), `apply_live_settings` (three) and scattered `key_text`, `on_air`, `cell_at`, `ImeState`, `AppSession`. The stem `window` was correctly dropped as a dictionary word, so the count is not the stem's doing. The two words worth suspecting, `is_digit` and `cell_at`, appear only in `window.rs` itself and one test file — no false positives. The corpus held nothing a reader would not meet. **The count holds.**

## 2. Mechanism

Not who uses the file — one non-test module does — but what it holds. One 3205-line module carrying, in sequence:

| lines | concern | natural home |
|---|---|---|
| 567–806 | `TerminalSurface` construction and settings | here |
| 807–1342 | tmux control-mode gateway plumbing: `pump_gateways`, attach, detach, the window/pane state machine | `tmux.rs`, beside `Gateway` |
| 1343–1780 | channel-bank keyboard shortcuts, window-level keybindings, clipboard | an input/keybinding handler |
| 1781–1863 | window/well division arithmetic | `geometry.rs` |
| 1864–2265 | redraw orchestration: `sync_geometry`, `draw_frame`, pacing | with the crt-render integration |
| 2266–2443 | pointer dispatch and coordinate transformation | a pointer handler |
| 2444–2695 | seam interaction | `bank.rs` or a cabinet module |
| 2696–3205 | the `Surface` trait for winit | here |

Corroborating figure from the index, not from the revival: the module draws types from **46 other modules**. The next highest in the workspace is 19 and the median is 2.

## 3. Disposition

**Scattered — real cost.** The file conflates the `TerminalSurface` type, which is the event loop's one integration point and belongs here, with six subsystems pulling from unrelated dependency domains: the tmux codec, terminal input encoding, GPU rendering, pointer arithmetic, and the bank UI. Each subsystem carries its own vocabulary out into the tests and neighbouring modules, which is what produces B=25 against A=1.

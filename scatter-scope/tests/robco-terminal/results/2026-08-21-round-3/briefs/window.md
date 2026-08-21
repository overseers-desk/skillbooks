# Measured figures for `crates/app/src/window.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 2 | 1 |
| B | 8 | 34 |
| C | 16 | 254 |
| D | 15 | 46 |

leak (B files the graph did not already count in A): 33  ·  flags: B high, D high (hub), leak signature

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
AppSession, BASE_FONT_SCALING, DOUBLE_CLICK_INTERVAL, EFFECTS_BASE_FRAME, ImeState, POLL_INTERVAL, SHED_PTY, SHED_TMUX, TerminalSurface, announce_bank_width, apply_cabinet_settings, apply_chord, apply_live_settings, bank_physical, bank_strips, cabinet_cfg, cell_at, chain_geometry, channel_changed, chord_digit, chord_modifier, commit_chord, copy_on_select, copy_selection, cycle_channel, degauss, degauss_state, distortion_params, drag_selection_to, draw_frame, end_selection, ensure_font, ensure_margin, font_entry, gateway_key, has_bank, ime_area, ime_cursor_area, ime_input, ime_state, is_digit, is_gateway_on_air, key_input, key_text, last_click, last_selection, live_config, logged_geometry, logical_cell, logical_x, mode_contains, modifiers_from, move_channel, next_effects_frame, next_output_frame, on_air, output_pending, pending_led_characters, pointer_button, pointer_cell, pointer_context, press_strip, publish_ime_cursor, pump_gateway, pump_gateways, relayout, report_button, report_mouse, scroll_key, scroll_offset, seam_cursor, seam_landed, seam_moved, seam_press, seam_pressed, seam_released, select_word_at, selection_window, session_config, set_cabinet, set_config, set_seam_cursor, set_settings, set_shell_events, settle_bank, settle_rows, sheds_seen, shell_events, shift_physical, shortcut_key, size_badge, sizing_request, step_bank, strip_pressed, sync_geometry, the_chain_is_measured_in_logical_pixels_on_a_2x_display, the_grid_is_inset_by_the_distortion_margin_before_dividing_by_the_cell, the_virtual_resolution_takes_the_font_width_and_floors, type_bytes, watch_the_write_queues, wheel_pixels
```

## A files (the graph's consumers)

- `crates/app/src/main.rs`

## B files, with sites and the words that produced them

- `crates/app/tests/channel_bank.rs` — 48 sites: bank_strips 18, TerminalSurface 10, degauss_state 8, degauss 3, key_input 3, press_strip 2, on_air 2, set_cabinet 1
- `crates/app/tests/ime.rs` — 38 sites: ime_input 18, TerminalSurface 8, ime_state 8, ime_cursor_area 3, ImeState 1
- `crates/app/tests/tmux_flow.rs` — 22 sites: TerminalSurface 14, cycle_channel 5, key_text 1, key_input 1, AppSession 1
- `crates/app/tests/keyboard_scroll.rs` — 20 sites: scroll_offset 11, TerminalSurface 6, key_input 3
- `crates/app/tests/pointer.rs` — 17 sites: TerminalSurface 6, scroll_offset 6, last_selection 5
- `crates/app/tests/pointer_live_settings.rs` — 12 sites: TerminalSurface 6, last_selection 2, set_settings 2, ensure_margin 1, distortion_params 1
- `crates/crt-render/tests/pass_graph.rs` — 11 sites: degauss 11
- `crates/app/tests/seam_drag.rs` — 11 sites: TerminalSurface 5, set_cabinet 4, set_settings 1, last_selection 1
- `crates/app/tests/clipboard_keys.rs` — 8 sites: TerminalSurface 6, key_input 2
- `crates/app/tests/shed_notice.rs` — 8 sites: TerminalSurface 5, SHED_PTY 2, size_badge 1
- `crates/crt-render/src/params.rs` — 6 sites: degauss 6
- `crates/app/src/main.rs` — 6 sites: TerminalSurface 3, set_shell_events 1, set_config 1, set_settings 1
- `crates/crt-render/tests/contracts.rs` — 4 sites: degauss 4
- `crates/crt-render/src/lib.rs` — 4 sites: degauss 4
- `crates/app/tests/redraw_pacing.rs` — 4 sites: TerminalSurface 3, EFFECTS_BASE_FRAME 1
- `crates/app/src/lib.rs` — 4 sites: TerminalSurface 3, ime_input 1
- `crates/app/src/frame_stats.rs` — 4 sites: draw_frame 3, EFFECTS_BASE_FRAME 1
- `crates/term/src/session.rs` — 3 sites: TerminalSurface 3
- `crates/app/src/channels.rs` — 3 sites: degauss 2, TerminalSurface 1
- `crates/app/src/tmux.rs` — 3 sites: TerminalSurface 2, SHED_TMUX 1
- `crates/crt-render/src/degauss.rs` — 2 sites: degauss 2
- `crates/app/tests/settings_live_reload.rs` — 2 sites: TerminalSurface 1, apply_live_settings 1
- `crates/app/src/settings.rs` — 2 sites: TerminalSurface 1, apply_live_settings 1
- `crates/app/src/gpu.rs` — 2 sites: TerminalSurface 1, draw_frame 1
- `crates/chassis/src/cabinet.rs` — 1 sites: TerminalSurface 1
- `crates/crt-render/Cargo.toml` — 1 sites: degauss 1
- `crates/crt-render/tests/glyph_survival.rs` — 1 sites: chain_geometry 1
- `crates/crt-render/tests/support/mod.rs` — 1 sites: degauss 1
- `crates/crt-render/src/chain.rs` — 1 sites: degauss 1
- `crates/app/tests/frame_stats.rs` — 1 sites: draw_frame 1
- `crates/app/tests/size_badge.rs` — 1 sites: SHED_PTY 1
- `crates/app/src/instance.rs` — 1 sites: degauss 1
- `crates/app/src/shell.rs` — 1 sites: EFFECTS_BASE_FRAME 1
- `crates/app/src/badge.rs` — 1 sites: draw_frame 1

## Leak files (B minus A)

- `crates/app/src/badge.rs`
- `crates/app/src/channels.rs`
- `crates/app/src/frame_stats.rs`
- `crates/app/src/gpu.rs`
- `crates/app/src/instance.rs`
- `crates/app/src/lib.rs`
- `crates/app/src/settings.rs`
- `crates/app/src/shell.rs`
- `crates/app/src/tmux.rs`
- `crates/app/tests/channel_bank.rs`
- `crates/app/tests/clipboard_keys.rs`
- `crates/app/tests/frame_stats.rs`
- `crates/app/tests/ime.rs`
- `crates/app/tests/keyboard_scroll.rs`
- `crates/app/tests/pointer.rs`
- `crates/app/tests/pointer_live_settings.rs`
- `crates/app/tests/redraw_pacing.rs`
- `crates/app/tests/seam_drag.rs`
- `crates/app/tests/settings_live_reload.rs`
- `crates/app/tests/shed_notice.rs`
- `crates/app/tests/size_badge.rs`
- `crates/app/tests/tmux_flow.rs`
- `crates/chassis/src/cabinet.rs`
- `crates/crt-render/Cargo.toml`
- `crates/crt-render/src/chain.rs`
- `crates/crt-render/src/degauss.rs`
- `crates/crt-render/src/lib.rs`
- `crates/crt-render/src/params.rs`
- `crates/crt-render/tests/contracts.rs`
- `crates/crt-render/tests/glyph_survival.rs`
- `crates/crt-render/tests/pass_graph.rs`
- `crates/crt-render/tests/support/mod.rs`
- `crates/term/src/session.rs`

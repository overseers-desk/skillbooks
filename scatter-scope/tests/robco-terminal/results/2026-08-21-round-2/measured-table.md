# Measured table

`score = C x leak/B`. Rows sorted by score. All 166 rows the index carries;
the 106 under `/src/` are source modules and carry the run.

| score | leak | A | D | B | C | file | vocabulary sample |
|---|---|---|---|---|---|---|---|
| 340 | 34 | 4 | 8 | 38 | 380 | `crates/crt-render/src/params.rs` | params, Geometry, raster_mode, output_width, screen_colors, virtual_width |
| 317 | 30 | 1 | 4 | 31 | 328 | `crates/app/src/tmux.rs` | tmux, Intent, Capture, Detached, teardown, PaneGate |
| 308 | 24 | 5 | 0 | 29 | 372 | `crates/chassis/src/oracle.rs` | vnoise, hash12, size_px, rrect_px, bevel_px, light_dir |
| 292 | 42 | 2 | 0 | 44 | 306 | `crates/app/src/channels.rs` | Close, PageId, Detach, Removed, Nothing, rows_mut |
| 255 | 30 | 3 | 0 | 33 | 280 | `crates/term/src/viewport.rs` | Glide, to_top, page_up, viewport, to_bottom, page_down |
| 253 | 24 | 9 | 7 | 33 | 348 | `crates/chassis/src/metrics.rs` | end_pad, pad_cells, dot_pitch, column_gap, LedMetrics, pager_extra |
| 247 | 33 | 1 | 46 | 34 | 254 | `crates/app/src/window.rs` | on_air, cell_at, degauss, ImeState, has_bank, is_digit |
| 166 | 11 | 17 | 1 | 23 | 348 | `crates/config/src/schema.rs` | rgb_shift, SlideRule, SystemFonts, font_source, Switchboard, Annunciator |
| 155 | 27 | 4 | 2 | 31 | 178 | `crates/term/src/session.rs` | Pumped, Session, is_idle, READ_BUF, INPUT_CAP, grid_rows |
| 138 | 20 | 5 | 3 | 25 | 172 | `crates/config/src/toml.rs` | toml, Parse, Scalar, Screen, Boolean, Integer |
| 112 | 15 | 16 | 4 | 31 | 231 | `crates/config/src/lib.rs` | Config, raw_frame_size, raw_frame_color, SCREEN_RADIUS_PX, raw_screen_radius, raw_frame_shininess |
| 109 | 12 | 3 | 1 | 15 | 136 | `crates/term/src/fonts/sizing.rs` | Floor, Round, dpr_scale, antialias, ScalePolicy, compute_font |
| 106 | 28 | 2 | 10 | 30 | 114 | `crates/chassis/src/shells/annunciator.rs` | KEY_TOP, CUT_DARK, LIP_LIGHT, KEY_WIDTH, KEY_HEIGHT, plate_rect |
| 103 | 21 | 1 | 0 | 22 | 108 | `crates/crt-burnin/src/headless.rs` | GpuLock, cast_f32, px_index, GpuError, make_input, read_output |
| 98 | 6 | 2 | 1 | 8 | 131 | `crates/term/src/selection.rs` | act_sel, drag_to, set_end, word_end, is_valid, top_left |
| 97 | 17 | 0 | 0 | 17 | 97 | `crates/crt-burnin/tests/burn_in.rs` | burn_in, ramp_error, rate_error, ghost_mask, decay_tracks_the_set_rate, the_float_framebuffer_is_what_buys_that_accuracy |
| 93 | 12 | 4 | 0 | 16 | 124 | `crates/crt-render/src/degauss.rs` | scale_y, degauss, Degauss, is_active, is_running, DegaussState |
| 93 | 6 | 0 | 0 | 6 | 93 | `crates/app/tests/size_badge.rs` | WINDOW_W, WINDOW_H, SENTINEL_F, size_badge, FRAME_FORMAT, frame_with_badge |
| 92 | 6 | 8 | 6 | 14 | 215 | `crates/chassis/src/paint.rs` | ArcOp, Serif, Solid, RectOp, Radial, Linear |
| 79 | 2 | 3 | 2 | 5 | 198 | `crates/tmux-cc/src/event.rs` | Pause, Reply, Foreign, Message, Continue, WindowAdd |
| 75 | 12 | 3 | 4 | 15 | 94 | `crates/tmux-cc/src/codec.rs` | codec, Codec, next_id, in_block, OpenBlock, line_done |
| 70 | 8 | 2 | 7 | 10 | 87 | `crates/app/src/settings.rs` | look_path, config_path, ScreenPreset, SavedProfile, known_screens, SettingsHandle |
| 69 | 7 | 1 | 1 | 8 | 79 | `crates/term/src/hotspots.rs` | regex, Email, Marker, HotSpot, UrlType, hotspots |
| 67 | 17 | 2 | 5 | 19 | 75 | `crates/crt-render/src/chain.rs` | Chain, Rebuilt, Applied, frame_at, set_params, Parameters |
| 65 | 11 | 2 | 16 | 13 | 77 | `crates/chassis/src/shells/slide_rule.rs` | TRACK_X, RIM_DARK, RIM_LIGHT, rail_rect, slide_rule, NUMERAL_INK |
| 65 | 9 | 2 | 5 | 11 | 80 | `crates/term/src/render.rs` | set_row, BLOCK_BG, origin_x, set_grid, origin_y, set_scale |
| 64 | 7 | 6 | 2 | 13 | 118 | `crates/chassis/src/bank.rs` | track_gap, content_x, row_height, pad_cells_y, strip_width, BankGeometry |
| 61 | 4 | 3 | 5 | 7 | 106 | `crates/chassis/src/displays/tape/mod.rs` | END_PAD, BEVEL_PX, FONT_NAME, DILATE_PX, slot_color, tape_color |
| 60 | 11 | 4 | 0 | 15 | 82 | `crates/term/src/size.rs` | CellSize, TermSize, MIN_ROWS, MIN_COLS, term_size, physical_cell |
| 54 | 16 | 2 | 4 | 18 | 61 | `crates/crt-render/src/preset.rs` | Scale, body_at, scale_of, NOISE_PNG, FrameBody, Structure |
| 53 | 4 | 2 | 0 | 6 | 80 | `crates/app/src/frame_stats.rs` | Stats, grid_ms, GridEnd, FrameEnd, last_log, chain_ms |
| 52 | 25 | 1 | 0 | 26 | 54 | `crates/term/tests/scrollback.rs` | SCROLLBACK, scrollback, twenty_lines, scrollback_viewport_follows_history, untouched_cells_read_as_blanks_not_nuls, ordinary_output_does_not_force_a_full_rebuild |
| 51 | 11 | 16 | 2 | 27 | 125 | `crates/term/src/fonts/mod.rs` | System, Bundled, FontData, FontEntry, is_system, base_width |
| 47 | 9 | 5 | 10 | 13 | 68 | `crates/chassis/src/cabinet.rs` | Cabinet, is_shown, remeasure, SeamUpdate, apply_config, bank_width_physical |
| 46 | 22 | 0 | 0 | 22 | 46 | `crates/chassis/tests/chassis_metal.rs` | chassis_metal, chassis_metal_matches_oracle |
| 46 | 8 | 4 | 4 | 12 | 69 | `crates/term/src/atlas.rs` | atlas_y, font_id, atlas_x, for_face, GlyphSlot, GlyphAtlas |
| 45 | 6 | 4 | 3 | 8 | 60 | `crates/term/src/cells.rs` | row_mut, charset, fill_row, CellGrid, from_lines, line_color |
| 43 | 7 | 6 | 0 | 13 | 80 | `crates/term/src/grid.rs` | Cells, Count, GridView, copy_line, char_width, write_range |
| 43 | 1 | 3 | 0 | 4 | 171 | `crates/term/src/pointer.rs` | Button, on_press, Modifiers, with_shift, mouse_marks, PastePrimary |
| 41 | 11 | 2 | 1 | 13 | 48 | `crates/term/src/tmux_cc.rs` | tmux_cc, TMUX_DCS, take_body, take_ended, TMUX_PARAMS, TMUX_ACTION |
| 40 | 5 | 6 | 3 | 10 | 80 | `crates/chassis/src/displays/led/mod.rs` | Colors, DOT_RADIUS, SPILL_DEAD, LED_DOT_PITCH, window_colors, LED_PAD_CELLS |
| 39 | 11 | 3 | 0 | 14 | 50 | `crates/term/src/gpu.rs` | Target, read_rgba, write_pgm, ascii_preview, TARGET_FORMAT, upscale_nearest |
| 38 | 4 | 0 | 0 | 4 | 38 | `crates/crt-render/tests/support/mod.rs` | Harness, lit_rows, mean_luma, BAR_LEVEL, draw_dark, draw_field |
| 36 | 7 | 5 | 0 | 12 | 62 | `crates/crt-render/src/pacing.rs` | Pacing, tick_by, FrameTime |
| 33 | 4 | 11 | 0 | 14 | 116 | `crates/chassis/src/color.rs` | to_hsv, from_hsv, substring, with_alpha, scale_color, str_to_color |
| 33 | 8 | 4 | 1 | 11 | 45 | `crates/crt-burnin/src/lib.rs` | set_mask, Precision, BurnInPass, for_device, last_pushed, write_shader |
| 33 | 5 | 0 | 0 | 5 | 33 | `crates/term/tests/preedit.rs` | lit_in, preedit, cell_rect, terminess, cursor_at, CURSOR_COL |
| 31 | 15 | 0 | 0 | 15 | 31 | `crates/chassis/tests/frame_metal.rs` | frame_metal, frame_metal_matches_oracle |
| 30 | 6 | 2 | 0 | 8 | 40 | `crates/term/src/fonts/subpixel.rs` | Layout, Configs, subpixel, rgba_value, filter_row, APPEND_RGB |
| 29 | 11 | 0 | 0 | 11 | 29 | `crates/chassis/tests/plate_metal.rs` | plate_metal, plate_metal_matches_oracle |
| 29 | 5 | 2 | 1 | 7 | 40 | `crates/xtask/src/x11.rs` | x11, shell_xy, window_name, min_size_hint, geometry_width, sizable_windows |
| 29 | 5 | 2 | 4 | 7 | 41 | `crates/app/src/shell.rs` | wake_at, last_tick, ShellEvent, user_event, event_loop, badge_shown |
| 26 | 3 | 4 | 0 | 7 | 60 | `crates/term/src/dcs.rs` | dcs, Intro, DcsTap, NoopTap, DcsOnly, Envelope |
| 25 | 11 | 0 | 0 | 11 | 25 | `crates/crt-render/src/oracle.rs` | rand2, terminal_frame, STEPS_PER_TEXEL, gaussian_blur_1d, TerminalFrameParams, terminal_frame_noise |
| 25 | 7 | 1 | 0 | 8 | 29 | `crates/crt-burnin/src/decay.rs` | max_dt, DecayClock, decay_step, MASK_PARAM, DECAY_PARAM, MIN_FADE_TIME |
| 25 | 6 | 0 | 0 | 6 | 25 | `crates/app/tests/frame_stats.rs` | frame_stats, burn_some_gpu_time, on_an_adapter_with_the_feature_pair_the_instrument_reports_plausible_timings, forcing_the_feature_pair_off_the_device_reports_unavailable_without_panicking |
| 25 | 4 | 1 | 2 | 5 | 31 | `crates/config/src/structural.rs` | KeyClass, Parameter, Structural, every_structural_key_resolves_against_the_schema, a_structural_move_and_a_parameter_move_classify_apart |
| 25 | 4 | 0 | 0 | 4 | 25 | `crates/app/tests/shed_notice.rs` | DEAF_CHILD, shed_notice, wait_for_screen, typing_thrown_away_by_a_full_queue_says_so_on_the_glass |
| 24 | 7 | 2 | 19 | 9 | 31 | `crates/term/src/lib.rs` | build_font, ascii_charset, DEFAULT_THRESHOLD |
| 24 | 6 | 1 | 1 | 7 | 28 | `crates/app/src/input.rs` | Tilde, Bytes, Return, any_mod, f1_shift, SsLetter |
| 23 | 3 | 5 | 2 | 8 | 61 | `crates/chassis/src/strip.rs` | StripRow, pointer_y, cold_start, BankStrips, current_row, numeral_text |
| 22 | 3 | 4 | 2 | 6 | 43 | `crates/tmux-cc/src/command.rs` | to_wire, HostName, SendKeys, ClientSize, CapturePane, ListWindows |
| 22 | 4 | 2 | 4 | 6 | 33 | `crates/config/src/profile.rs` | Tuning, round4, save_to, Profile, Unnamed, apply_to |
| 21 | 6 | 15 | 0 | 12 | 42 | `crates/chassis/src/layout.rs` | WindowLayout, chassis_field, MINIMUM_HEIGHT, NORMALISATION_WIDTH, min_inner_size_physical, the_well_never_goes_negative |
| 21 | 11 | 0 | 0 | 11 | 21 | `crates/chassis/tests/tape_label.rs` | SIZE_H, SIZE_W, tape_label, tape_label_letter_and_body_read_correctly |
| 21 | 10 | 0 | 0 | 10 | 21 | `crates/chassis/tests/led_matrix.rs` | OUT_W, OUT_H, GRID_W, GRID_H, led_matrix, led_matrix_lit_and_dark_cells_read_correctly |
| 21 | 3 | 2 | 0 | 5 | 35 | `crates/app/src/overlay.rs` | Notice, GridSize, visible_at, opacity_at, set_enabled, NOTICE_HOLD |
| 21 | 1 | 0 | 0 | 1 | 21 | `crates/app/tests/clipboard_keys.rs` | CTRL_SHIFT, clipboard_keys, the_clipboard_chords_reach_the_child_as_nothing |
| 19 | 5 | 4 | 0 | 9 | 34 | `crates/term/src/color.rs` | Scheme, dim_factor, full_color, xterm_palette, palette_landmarks_match_xterm, monochrome_scheme_cannot_produce_a_third_colour |
| 18 | 10 | 0 | 0 | 10 | 18 | `crates/crt-render/tests/terminal_frame.rs` | terminal_frame, terminal_frame_matches_oracle |
| 18 | 2 | 0 | 0 | 2 | 18 | `crates/app/tests/ime.rs` | ime, ECHOING_CHILD, never_on_screen, the_preedit_is_held_and_not_sent, an_abandoned_composition_sends_nothing, a_committed_string_reaches_the_child_as_utf8 |
| 16 | 3 | 7 | 19 | 10 | 55 | `crates/chassis/src/furniture.rs` | Plate, Piece, led_grid, led_piece, TapeLabel, LedMatrix |
| 15 | 4 | 2 | 0 | 6 | 23 | `crates/tmux-cc/src/escape.rs` | unvis, unvis_text, is_escaped, escape_octal, hex_arguments, unescape_octal |
| 14 | 4 | 4 | 2 | 8 | 27 | `crates/term/src/fonts/led.rs` | LedRaster, led_text_image |
| 14 | 3 | 4 | 5 | 7 | 32 | `crates/term/src/fonts/text.rs` | Align, Center, iosevka, Stripes, TextSpec, TextRaster |
| 14 | 3 | 2 | 4 | 5 | 23 | `crates/term/src/tmux_pane.rs` | pty_mut, tmux_pane, take_input, tmux_pane_mut, ChannelSession, a_resize_reflows_the_grid_alone |
| 14 | 2 | 3 | 1 | 5 | 35 | `crates/term/src/rio_grid.rs` | RioGrid, all_text, rio_grid, live_text, row_cells, cell_char |
| 14 | 3 | 2 | 10 | 4 | 18 | `crates/chassis/src/shells/switchboard.rs` | WELL_DARK, PLATE_REACH, serif_width, PAGER_HEIGHT, PLATE_SHADOW, arrow_outline |
| 11 | 2 | 1 | 1 | 3 | 16 | `crates/app/src/cli.rs` | cli, Print, Outcome, Options, default_settings, contract_flags_parse |
| 11 | 2 | 1 | 1 | 3 | 17 | `crates/app/src/badge.rs` | Badge, Entry, BadgeRect, CORNER_RADIUS, the_uniform_block_is_the_size_the_shader_declares |
| 10 | 10 | 0 | 6 | 10 | 10 | `crates/xtask/src/main.rs` | Fanout, Verify, Compare, Install, Contract |
| 10 | 5 | 0 | 0 | 5 | 10 | `crates/term/tests/pixel_properties.rs` | commodore_pet, pixel_properties, property_1_antialiasing_is_off, damage_updates_only_the_rows_that_changed, property_3_dpr_changes_do_not_touch_the_atlas, property_2_integer_scaling_is_exact_duplication |
| 10 | 4 | 1 | 4 | 5 | 13 | `crates/app/src/bank.rs` | BankView, last_view, BankPager, rows_on_page, ensure_visible, slot_prefix_exists |
| 10 | 2 | 3 | 0 | 5 | 25 | `crates/term/src/distortion.rs` | Point, total_width, total_height, forward_distort, DistortionParams, correct_distortion |
| 9 | 1 | 7 | 0 | 8 | 73 | `crates/tmux-cc/src/ids.rs` | PaneId, SessionId, the_number_is_the_tail, a_sigil_belongs_to_exactly_one_kind, a_bare_sigil_or_a_non_numeric_tail_is_not_an_id |
| 9 | 2 | 5 | 3 | 7 | 30 | `crates/chassis/src/shells/common.rs` | screw_head, ScrewColors, FieldMapping, field_mapping, screw_head_with, frame_viewport_size |
| 9 | 4 | 0 | 0 | 4 | 9 | `crates/term/tests/antialias.rs` | ink_at, antialias, atlas_total, atlas_intermediate, image_intermediate, terminess_takes_its_strike_even_with_antialiasing_on |
| 8 | 4 | 5 | 14 | 8 | 16 | `crates/chassis/src/lib.rs` | display_kit, led_metrics, tape_metrics, shell_metrics, a_reload_re_measures_the_kit_and_not_only_the_geometry, the_stock_profile_measures_its_lamp_font_rather_than_a_fixture |
| 8 | 3 | 5 | 1 | 8 | 21 | `crates/config/src/presets.rs` | screen_presets, chassis_presets |
| 8 | 4 | 1 | 0 | 5 | 10 | `crates/tmux-cc/tests/support/mod.rs` | client_pid, kill_client, control_stream, envelope_closed |
| 8 | 4 | 1 | 0 | 5 | 10 | `crates/term/tests/font_parity.rs` | LED_TEXT, golden_led, font_parity, fixture_dir, empty_text_has_no_raster, scaled_metrics_match_golden |
| 8 | 2 | 3 | 3 | 5 | 21 | `crates/chassis/src/seam.rs` | SeamDrag, Unclaimed, SeamCursor, SeamContext, is_dragging, window_width |
| 8 | 2 | 1 | 1 | 3 | 12 | `crates/term/src/search.rs` | SearchHit, BLOCK_LINES, search_range, literal_pattern, find_line_number |
| 8 | 2 | 1 | 1 | 3 | 12 | `crates/config/src/watch.rs` | Loader, Counted, _watcher, spawn_with, reload_into, ConfigWatcher |
| 8 | 2 | 0 | 0 | 2 | 8 | `crates/app/tests/settings_live_reload.rs` | wait_until, settings_live_reload, logged_the_rejection, sigusr1_forces_a_reload, invalid_edit_keeps_last_good_and_logs, zero_config_launch_resolves_to_the_frozen_v1_default |
| 8 | 1 | 1 | 9 | 1 | 8 | `crates/app/src/column.rs` | SLANGP, ChainKey, BLIT_WGSL, draw_over, chain_for, make_bind |
| 7 | 1 | 4 | 0 | 5 | 36 | `crates/xtask/src/proc.rs` | proc, run_ok, capture_lenient, run_ignore_status, reexec_under_xvfb |
| 7 | 3 | 0 | 0 | 3 | 7 | `crates/app/tests/bank_column.rs` | bank_column, oracle_params, frame_with_column, frame_with_furniture, a_hidden_chassis_draws_no_column_at_all, the_tape_shell_stamps_its_label_and_screws_on_no_plate |
| 6 | 2 | 8 | 1 | 10 | 28 | `crates/term/src/fonts/metrics.rs` | height_int, round_26_6, scale_26_6, ascent_int, family_name, ascent_26_6 |
| 6 | 5 | 0 | 0 | 5 | 6 | `crates/crt-render/tests/device_features.rs` | device_features, every_device_the_chain_runs_on_asks_for_the_same_features, the_wanted_set_is_a_filter_and_never_more_than_the_adapter_has |
| 6 | 2 | 1 | 0 | 3 | 9 | `crates/app/src/crashlog.rs` | LOG_PATH, PATH_MAX, crashlog, backtrace, MAX_FRAMES, log_path_in |
| 6 | 2 | 0 | 2 | 2 | 6 | `crates/crt-burnin/src/chain.rs` | BurnInChain |
| 5 | 4 | 0 | 0 | 4 | 5 | `crates/term/tests/system_fonts.rs` | DEJAVU, dejavu, system_fonts, a_selected_system_face_shapes_and_measures, the_enumeration_offers_dejavu_sans_mono_under_the_filter_rules |
| 5 | 2 | 1 | 0 | 3 | 8 | `crates/xtask/src/compare.rs` | chroma, Region, load_rgb, crop_rgb, BANK_WIDTH, parse_crop |
| 5 | 1 | 4 | 4 | 3 | 15 | `crates/chassis/src/frame.rs` | FrameScale, FrameStyle, ChassisStyle, slide_rule_frame, annunciator_frame, switchboard_frame |
| 4 | 4 | 0 | 0 | 4 | 4 | `crates/chassis/tests/metrics_homes.rs` | same_shell, metrics_homes, the_tape_well_metrics_composes_the_bare_functions, the_led_strip_metrics_composes_the_bare_functions, the_slide_rule_shell_metrics_composes_the_bare_constants, the_annunciator_shell_metrics_composes_the_bare_constants |
| 4 | 2 | 1 | 2 | 3 | 6 | `crates/app/src/gpu.rs` | discard_timing, frame_stats_enabled, frame_stats_available |
| 3 | 2 | 1 | 11 | 3 | 4 | `crates/chassis/src/shells/mod.rs` | plate_region, row_overhang |
| 3 | 1 | 2 | 0 | 3 | 8 | `crates/chassis/src/shaders.rs` | TAPE_LABEL_SLANG, LED_MATRIX_SLANG, PLATE_METAL_SLANG, FRAME_METAL_SLANG, CHASSIS_METAL_SLANG, each_metal_is_compiled_in_whole_and_is_the_one_it_claims |
| 3 | 2 | 1 | 1 | 3 | 5 | `crates/chassis/src/displays/raster.rs` | to_rgba8, widens_one_alpha_byte_to_four |
| 3 | 1 | 0 | 0 | 1 | 3 | `crates/chassis/tests/bank_frame_render.rs` | params_pair, WINDOW_SIZES, stock_bank_width, bank_frame_render, moulding_thickness, a_wider_bank_thickens_the_moulding_it_leaves |
| 2 | 1 | 1 | 2 | 2 | 3 | `crates/xtask/src/snap.rs` | Cleanup, _scratch, SnapArgs, fit_units, find_window, DETERMINISTIC_LINE |
| 2 | 2 | 0 | 0 | 2 | 2 | `crates/tmux-cc/tests/live_tmux.rs` | live_tmux, the_whole_command_set_is_a_dialect_tmux_speaks, keys_sent_as_hex_reach_the_pane_and_come_back_as_output, the_bootstrap_replies_are_the_shapes_the_reference_reads, a_new_window_asked_for_through_the_codec_arrives_and_parses, a_killed_client_leaves_the_envelope_open_and_the_session_standing |
| 2 | 2 | 0 | 0 | 2 | 2 | `crates/crt-render/tests/glyph_survival.rs` | MIN_INK, MIN_RUNS, lit_runs, Survival, glyph_survival, the_measurement_can_see_strokes_go_missing |
| 2 | 2 | 0 | 0 | 2 | 2 | `crates/crt-render/tests/burn_in_chain.rs` | GHOST_TRIM, burn_in_chain, the_freshness_mask_survives_the_mount, switching_burn_in_off_takes_the_ghost_with_it, the_mounted_accumulator_decays_at_the_rate_the_settings_set |
| 2 | 2 | 0 | 0 | 2 | 2 | `crates/app/tests/keyboard_scroll.rs` | SIXTY_LINES, keyboard_scroll, typing_snaps_a_scrolled_view_to_the_bottom, shift_up_and_down_move_the_viewport_one_line, a_key_the_keytab_binds_to_bytes_does_not_scroll_back, shift_page_up_moves_the_viewport_back_through_the_scrollback |
| 1 | 1 | 2 | 0 | 3 | 3 | `crates/app/src/paths.rs` | data_dir, crash_dir, cache_dir, preset_dir |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/term/src/bin/esctest_harness.rs` | WinOps, Replies, checksum, set_size, csi_dispatch, wait_for_child |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/crt-render/tests/pass_graph.rs` | pass_graph, still_config, mean_luma_rows, a_structural_change_rebuilds_the_chain, the_term_target_renders_through_the_chain, the_preset_is_the_documented_six_pass_graph |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/chassis/tests/region_layout.rs` | region_layout, CHASSIS_SIZES, slide_rule_regions_at_sampled_sizes, annunciator_regions_at_sampled_sizes, field_mapping_at_sampled_window_sizes, switchboard_has_no_plate_or_rail_region |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/chassis/tests/led_display.rs` | led_display, led_display_composes_the_proven_raster_with_led_matrix |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/chassis/tests/bank_frame_geometry.rs` | stock_bank, led_strip_width, bank_frame_geometry, the_pointer_law_at_every_shell, the_bank_never_moves_with_the_window, rows_per_page_at_sampled_window_heights |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/app/tests/profile_cli.rs` | profile_cli, launched_look, scratch_command, XDG_CONFIG_HOME_LOCK, an_unknown_profile_is_refused, a_known_profile_changes_the_launched_look |
| 1 | 1 | 0 | 0 | 1 | 1 | `crates/app/tests/channel_bank.rs` | channel_bank, ROWS_ON_PAGE, release_chord, wait_for_prompt, surface_of_height, ctrl_shift_w_closes_the_channel_on_the_air |
| 0 | 0 | 5 | 1 | 5 | 10 | `crates/term/src/fonts/system.rs` | SERIF, sans_face, SystemFace, named_face, source_path, default_sans |
| 0 | 0 | 3 | 0 | 3 | 5 | `crates/term/src/fonts/raster.rs` | glyph_mask, glyph_mask_thirds |
| 0 | 0 | 2 | 0 | 2 | 2 | `crates/app/src/geometry.rs` | DEFAULT_SIZE |
| 0 | 0 | 4 | 0 | 2 | 2 | `crates/chassis/src/js.rs` | round_i32, halves_go_up_not_away_from_zero, ordinary_values_agree_with_rust |
| 0 | 0 | 1 | 2 | 1 | 1 | `crates/xtask/src/verify.rs` | Checks, Running, Verdict, VerifyArgs, children_of, run_capturing |
| 0 | 0 | 1 | 1 | 1 | 3 | `crates/xtask/src/install.rs` | lay_out, DebArgs, set_mode, DistArgs, shlibdeps, staged_root |
| 0 | 0 | 1 | 0 | 1 | 5 | `crates/xtask/src/fanout.rs` | fanout, strip_inline_tests |
| 0 | 0 | 1 | 1 | 1 | 6 | `crates/app/src/mouse.rs` | Release, WheelUp, WheelDown, encode_x10, encode_sgr, button_code |
| 0 | 0 | 2 | 0 | 1 | 3 | `crates/app/src/instance.rs` | Primary, ENV_GUARD, Delivered, with_guard, runtime_dir, socket_path |
| 0 | 0 | 1 | 0 | 1 | 1 | `crates/app/src/clipboard.rs` | bracket_paste, ClipboardError, bracket_paste_empty_string, bracket_paste_enabled_wraps, bracket_paste_disabled_passes_through |
| 0 | 0 | 1 | 0 | 1 | 9 | `crates/app/src/chord.rs` | Chord, Select, ChordInput, store_mode, feed_digit, is_pending |
| 0 | 0 | 1 | 0 | 0 | 0 | `crates/xtask/src/mask.rs` | MASK_PY, SHINE_BAND |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/tmux-cc/tests/transcripts.rs` | the_zoo_holds_one_of_each, the_server_can_throw_the_client_off, every_transcript_is_a_control_stream, the_pairing_queue_comes_out_in_order, all_256_bytes_come_back_off_the_wire, a_window_closing_always_says_unlinked |
| 0 | 0 | 0 | 2 | 0 | 0 | `crates/tmux-cc/examples/record.rs` | readme, output_octal, second_window, fresh_session, notification_zoo, reattach_after_kill |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/term/tests/transcript.rs` | on_screen, assert_child_agrees, a_child_that_exits_is_reported_as_eof, transcript_survives_a_resize_and_a_dpr_change, scrollback_survives_the_lines_leaving_the_screen, a_dcs_block_reaches_the_tap_and_stays_off_the_grid |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/term/tests/selection_tests.rs` | selection_tests, block_selection_takes_a_rectangle, double_click_drops_a_trailing_at_sign, is_selected_agrees_with_the_copied_text, double_click_keeps_a_path_and_a_url_whole, triple_click_takes_the_whole_logical_line |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/term/tests/search_tests.rs` | search_grid, search_tests, search_misses_cleanly, search_takes_a_real_regex_too, search_forwards_wraps_round_to_the_top, search_backwards_finds_the_previous_hit |
| 0 | 0 | 1 | 0 | 0 | 0 | `crates/term/tests/rio_grid_tests.rs` | term_with, rio_grid_tests, hotspots_run_over_a_live_grid, search_reaches_into_rio_scrollback, untouched_cells_never_reach_a_text_path_as_nul, a_selection_over_a_live_grid_copies_what_is_on_it |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/term/tests/hotspot_tests.rs` | matched_rows, hotspot_tests, a_link_that_wraps_spans_two_lines, the_url_fixtures_match_the_recorded_matches, url_type_and_activation_match_each_url_kind, a_link_does_not_fuse_with_the_line_below_it |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/term/tests/grid_tests.rs` | grid_tests, untouched_cells_are_not_part_of_a_line, double_width_characters_do_not_double_on_the_way_out |
| 0 | 0 | 0 | 2 | 0 | 0 | `crates/term/examples/led_diff.rs` | led_diff |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/user_lut.rs` | user_lut, probe_shader, PROBE_PRESET, render_probe, the_noise_lut_reaches_the_shader_and_repeats |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/contracts.rs` | params_for, only_structural_keys_move_the_structure, contrast_and_saturation_reach_the_shader, the_degauss_curve_is_the_mockups_keyframe, window_opacity_reaches_the_output_and_the_flood, a_parameter_can_be_overridden_after_it_is_built |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/bloom.rs` | SRC_H, SRC_W, shader_dir, mask_image, column_band, bloom_h_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/crt-burnin/tests/mount.rs` | PASSTHROUGH, fp32_accumulator_is_available_and_better_than_fp16, a_generated_preset_mounts_the_pass_after_another_one |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/tape_display.rs` | mask_at, tape_display, DISPLAY_HEIGHT, find_saturated_interior, tape_display_composes_the_proven_raster_with_tape_label |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/shader_recipes.rs` | shader_recipes, assert_rgb_close, switchboard_has_no_plate_metal_call_at_all, slide_rule_rail_is_plate_metal_not_chassis_metal, annunciator_frame_metal_recipe_matches_the_recorded_values, annunciator_plate_metal_recipe_matches_the_recorded_values |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/metrics_tables.rs` | metrics_tables, slide_rule_metrics_match_the_recorded_metrics, switchboard_metrics_match_the_recorded_metrics, annunciator_metrics_match_the_recorded_metrics |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/gpu_annunciator.rs` | gpu_annunciator, annunciator_chassis_metal_region_renders_as_the_oracle_predicts |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/tmux_flow.rs` | rows_of, tmux_flow, pump_until, type_attach, phase_3_a_rename_lands_unescaped_in_the_bank, phase_5_a_killed_window_loses_its_channel_and_the_page_stands |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/structure_subset.rs` | structure_subset, structure_reads_only_structural_keys, both_crates_derive_the_same_frame_size |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/seam_drag.rs` | seam_drag, STOCK_BANK, a_hidden_chassis_has_no_seam_and_no_column, a_press_the_seam_took_never_also_marks_the_screen, a_drag_with_no_settings_moves_the_bank_and_writes_nothing, a_drag_re_fits_the_bank_writes_the_count_and_survives_the_reload |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/redraw_pacing.rs` | redraw_pacing, a_flood_of_output_buys_one_frame_per_cadence_not_one_per_tick |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/profile_pixels.rs` | glass_tint, read_window, tools_present, profile_pixels, a_named_profile_reaches_the_glass_under_default_settings |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/pointer_live_settings.rs` | pointer_live_settings, select_at_fixed_pixels, a_click_lands_on_the_same_cell_at_dpr_1_and_dpr_2, a_config_edit_changes_the_pointer_mapping_without_restart |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/pointer.rs` | scrolling_back_down_re_follows_the_output, a_short_drag_selects_only_what_it_crossed, press_drag_release_selects_the_dragged_run, a_wheel_notch_scrolls_the_view_three_lines_back, a_double_click_takes_the_word_under_the_pointer, trackpad_pixels_scroll_the_view_by_fractions_of_a_row |
| 0 | 0 | 0 | 0 | 0 | 0 | `crates/app/tests/crashlog_signal.rs` | read_soon, crashlog_signal, a_fatal_signal_writes_a_backtrace_and_still_kills_the_process |
| 0 | 0 | 0 | 13 | 0 | 0 | `crates/app/src/main.rs` | no distinctive vocabulary; B not measured |
| 0 | 0 | 3 | 0 | 0 | 0 | `crates/app/src/lib.rs` | no distinctive vocabulary; B not measured |
| 0 | 0 | 1 | 0 | 0 | 0 | `crates/crt-render/src/device.rs` | supports_pipeline_cache, supports_fp32_accumulator |
| 0 | 0 | 3 | 5 | 0 | 0 | `crates/chassis/src/displays/tape/metrics.rs` | unit_width_is_the_departure_mono_m_advance_at_20px |
| 0 | 0 | 1 | 2 | 0 | 0 | `crates/chassis/src/displays/led/metrics.rs` | unit_width_matches_the_defining_formula |

## Conventions (one name, several defining files)

| homes | A | B | C | name | homes sample |
|---|---|---|---|---|---|
| 8 | 3 | 16 | 59 | `frame_size` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs`, `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 8 | 4 | 14 | 42 | `screen_curvature` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs`, `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 8 | 3 | 10 | 32 | `screen_radius` | `crates/app/src/settings.rs`, `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs`, `crates/chassis/src/shells/annunciator.rs` |
| 7 | 4 | 13 | 37 | `frame_shininess` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs`, `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 6 | 9 | 18 | 81 | `pixel_size` | `crates/chassis/src/paint.rs`, `crates/term/src/fonts/mod.rs`, `crates/term/src/fonts/sizing.rs`, `crates/term/src/fonts/text.rs` |
| 6 | 4 | 13 | 35 | `ambient_light` | `crates/chassis/src/oracle.rs`, `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 5 | 2 | 5 | 23 | `unit_width` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs`, `crates/chassis/src/metrics.rs` |
| 5 | 2 | 3 | 8 | `min_units` | `crates/chassis/src/bank.rs`, `crates/chassis/src/cabinet.rs`, `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs` |
| 4 | 0 | 64 | 543 | `config` | `crates/app/src/gpu.rs`, `crates/app/src/shell.rs`, `crates/crt-render/tests/burn_in_chain.rs`, `crates/term/tests/transcript.rs` |
| 4 | 0 | 30 | 145 | `viewport` | `crates/app/src/badge.rs`, `crates/app/src/window.rs`, `crates/chassis/src/shells/common.rs`, `crates/term/src/render.rs` |
| 4 | 5 | 15 | 56 | `from_config` | `crates/chassis/src/cabinet.rs`, `crates/config/src/profile.rs`, `crates/crt-render/src/chain.rs`, `crates/crt-render/src/preset.rs` |
| 4 | 3 | 14 | 66 | `burn_in` | `crates/config/src/schema.rs`, `crates/crt-burnin/src/decay.rs`, `crates/crt-render/src/chain.rs`, `crates/crt-render/src/params.rs` |
| 4 | 4 | 11 | 22 | `led_characters` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/seam.rs`, `crates/config/src/schema.rs`, `crates/config/src/toml.rs` |
| 4 | 3 | 8 | 39 | `bank_width` | `crates/app/src/shell.rs`, `crates/chassis/src/cabinet.rs`, `crates/chassis/src/seam.rs`, `crates/xtask/src/snap.rs` |
| 4 | 0 | 7 | 17 | `resized` | `crates/app/src/overlay.rs`, `crates/app/src/shell.rs`, `crates/app/src/window.rs`, `crates/chassis/src/cabinet.rs` |
| 4 | 3 | 5 | 10 | `width_for_units` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs`, `crates/chassis/src/metrics.rs` |
| 4 | 1 | 3 | 10 | `NATURAL_HEIGHT` | `crates/chassis/src/displays/tape/mod.rs`, `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 4 | 1 | 2 | 10 | `wait_for` | `crates/app/tests/clipboard_keys.rs`, `crates/config/src/watch.rs`, `crates/term/tests/transcript.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 4 | 1 | 2 | 4 | `row_furniture` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/mod.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 4 | 1 | 2 | 8 | `height_for_pad_cells` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs`, `crates/chassis/src/metrics.rs` |
| 4 | 1 | 2 | 8 | `pad_cells_for_hole` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs`, `crates/chassis/src/metrics.rs` |
| 3 | 0 | 28 | 245 | `params` | `crates/app/src/column.rs`, `crates/app/src/window.rs`, `crates/chassis/src/furniture.rs` |
| 3 | 4 | 13 | 37 | `window_scaling` | `crates/config/src/schema.rs`, `crates/crt-render/src/preset.rs`, `crates/term/src/fonts/sizing.rs` |
| 3 | 2 | 11 | 45 | `slide_rule` | `crates/chassis/src/metrics.rs`, `crates/config/src/profile.rs`, `crates/config/src/toml.rs` |
| 3 | 2 | 7 | 18 | `Gateway` | `crates/app/src/channels.rs`, `crates/app/src/tmux.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 3 | 2 | 6 | 15 | `total_lines` | `crates/term/src/grid.rs`, `crates/term/src/size.rs`, `crates/term/tests/scrollback.rs` |
| 3 | 4 | 6 | 12 | `NewWindow` | `crates/app/src/instance.rs`, `crates/app/src/shell.rs`, `crates/tmux-cc/src/command.rs` |
| 3 | 1 | 6 | 14 | `rows_visible` | `crates/app/src/bank.rs`, `crates/chassis/src/bank.rs`, `crates/chassis/src/cabinet.rs` |
| 3 | 2 | 6 | 14 | `normalized_screen_scale` | `crates/chassis/src/layout.rs`, `crates/crt-render/src/params.rs`, `crates/term/src/distortion.rs` |
| 3 | 0 | 4 | 17 | `_lock` | `crates/app/src/instance.rs`, `crates/app/tests/frame_stats.rs`, `crates/crt-burnin/src/headless.rs` |
| 3 | 1 | 4 | 7 | `frame_stats` | `crates/app/src/cli.rs`, `crates/app/src/gpu.rs`, `crates/app/src/window.rs` |
| 3 | 0 | 4 | 11 | `cursor_moved` | `crates/app/src/shell.rs`, `crates/app/src/window.rs`, `crates/chassis/src/cabinet.rs` |
| 3 | 1 | 4 | 17 | `fullscreen` | `crates/app/src/cli.rs`, `crates/app/src/instance.rs`, `crates/app/src/shell.rs` |
| 3 | 1 | 4 | 4 | `adapter_name` | `crates/app/src/gpu.rs`, `crates/crt-burnin/src/headless.rs`, `crates/term/src/gpu.rs` |
| 3 | 1 | 4 | 6 | `smoothstep` | `crates/chassis/src/color.rs`, `crates/chassis/src/oracle.rs`, `crates/crt-render/src/oracle.rs` |
| 3 | 1 | 3 | 13 | `BANK_PADDING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `TOP_PADDING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `BOTTOM_PADDING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `RIGHT_PADDING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 14 | `ROW_SPACING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `COLUMN_GAP` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `NUMERAL_WIDTH` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `STRIP_PADDING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 16 | `MIN_ROW_HEIGHT` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `CASTING_LIGHT_DIR` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 1 | 3 | 9 | `CASTING_COLOR` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 2 | 6 | `param` | `crates/app/src/input.rs`, `crates/app/tests/bank_column.rs`, `crates/chassis/src/frame.rs` |
| 3 | 1 | 2 | 6 | `SQUEEZE_SPAN` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 2 | 5 | `chassis_rect` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 2 | 5 | `chassis_metal_params` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 1 | 2 | `bind_group` | `crates/app/src/column.rs`, `crates/crt-render/tests/support/mod.rs`, `crates/term/src/render.rs` |
| 3 | 1 | 1 | 1 | `SCREEN_CURVATURE_SIZE` | `crates/chassis/src/frame.rs`, `crates/crt-render/src/params.rs`, `crates/term/src/distortion.rs` |
| 3 | 1 | 1 | 1 | `selector_track` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/mod.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 3 | 0 | 1 | 3 | `FrameRuntime` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 1 | 4 | `frame_metal_params` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 1 | 3 | `frame_viewport` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 0 | 0 | `NUMERAL_PIXEL_SIZE` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 0 | 0 | `NUMERAL_LETTER_SPACING` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 0 | 0 | `sans_width` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 3 | 0 | 0 | 0 | `numeral_line_height` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 2 | 9 | 18 | 58 | `chassis_shown` | `crates/config/src/schema.rs`, `crates/config/src/toml.rs` |
| 2 | 4 | 17 | 39 | `jitter` | `crates/chassis/src/shells/common.rs`, `crates/config/src/schema.rs` |
| 2 | 5 | 15 | 52 | `font_color` | `crates/chassis/src/furniture.rs`, `crates/config/src/schema.rs` |
| 2 | 0 | 14 | 83 | `codec` | `crates/app/src/tmux.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 2 | 6 | 13 | 58 | `Rasterization` | `crates/config/src/schema.rs`, `crates/term/src/atlas.rs` |
| 2 | 4 | 13 | 50 | `rasterization` | `crates/config/src/schema.rs`, `crates/term/src/atlas.rs` |
| 2 | 5 | 12 | 29 | `vignette_strength` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 9 | 12 | 65 | `ChannelIndicator` | `crates/chassis/src/bank.rs`, `crates/config/src/schema.rs` |
| 2 | 2 | 11 | 45 | `viewport_text` | `crates/app/src/window.rs`, `crates/term/src/cells.rs` |
| 2 | 8 | 11 | 69 | `Shell` | `crates/app/src/shell.rs`, `crates/config/src/schema.rs` |
| 2 | 0 | 11 | 14 | `Frame` | `crates/app/src/gpu.rs`, `crates/crt-render/src/chain.rs` |
| 2 | 5 | 11 | 23 | `channel_indicator` | `crates/chassis/src/lib.rs`, `crates/config/src/schema.rs` |
| 2 | 4 | 11 | 28 | `grain_amount` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 4 | 11 | 28 | `mottle_amount` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 4 | 11 | 28 | `scratch_amount` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 5 | 11 | 34 | `font_scaling` | `crates/config/src/schema.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 5 | 10 | 39 | `frame_color` | `crates/config/src/schema.rs`, `crates/crt-render/src/oracle.rs` |
| 2 | 5 | 10 | 42 | `cell_height` | `crates/chassis/src/metrics.rs`, `crates/term/src/size.rs` |
| 2 | 3 | 9 | 27 | `background_color` | `crates/chassis/src/furniture.rs`, `crates/config/src/schema.rs` |
| 2 | 2 | 8 | 13 | `device_pixel_ratio` | `crates/crt-render/src/params.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 2 | 8 | 20 | `pager_height` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 4 | 8 | 36 | `cell_width` | `crates/chassis/src/metrics.rs`, `crates/term/src/size.rs` |
| 2 | 6 | 8 | 14 | `Pointer` | `crates/chassis/src/bank.rs`, `crates/config/src/schema.rs` |
| 2 | 5 | 8 | 14 | `Switch` | `crates/chassis/src/bank.rs`, `crates/config/src/schema.rs` |
| 2 | 0 | 7 | 31 | `CELL_W` | `crates/app/tests/shed_notice.rs`, `crates/term/src/bin/esctest_harness.rs` |
| 2 | 0 | 7 | 28 | `CELL_H` | `crates/app/tests/shed_notice.rs`, `crates/term/src/bin/esctest_harness.rs` |
| 2 | 2 | 7 | 25 | `font_name` | `crates/app/src/window.rs`, `crates/config/src/schema.rs` |
| 2 | 4 | 7 | 11 | `outer_radius` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 1 | 7 | 11 | `frame_params` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/frame.rs` |
| 2 | 2 | 7 | 20 | `font_width` | `crates/config/src/schema.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 1 | 6 | 20 | `page_index` | `crates/app/src/bank.rs`, `crates/chassis/src/strip.rs` |
| 2 | 6 | 6 | 11 | `ConfigError` | `crates/config/src/toml.rs`, `crates/tmux-cc/src/event.rs` |
| 2 | 0 | 6 | 11 | `burn_in_quality` | `crates/config/src/schema.rs`, `crates/crt-render/src/preset.rs` |
| 2 | 3 | 6 | 14 | `bezel_color` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 14 | `ridge_color` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 13 | `bezel_margins` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `well_depth` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `well_floor` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `ridge_gain` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 9 | `fill_gain` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 9 | `trough_gain` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `face_band_px` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `rim_dist_px` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 3 | 6 | 10 | `rim_gain` | `crates/chassis/src/frame.rs`, `crates/chassis/src/oracle.rs` |
| 2 | 2 | 6 | 11 | `line_spacing` | `crates/config/src/schema.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 3 | 6 | 15 | `led_font_name` | `crates/config/src/schema.rs`, `crates/config/src/toml.rs` |
| 2 | 0 | 5 | 17 | `uv_of` | `crates/chassis/tests/tape_label.rs`, `crates/crt-render/tests/terminal_frame.rs` |
| 2 | 0 | 5 | 13 | `mouse_pressed` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 5 | 11 | `mouse_released` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 2 | 5 | 9 | `send_keys` | `crates/app/src/tmux.rs`, `crates/tmux-cc/src/command.rs` |
| 2 | 1 | 5 | 17 | `page_count` | `crates/app/src/bank.rs`, `crates/chassis/src/strip.rs` |
| 2 | 2 | 5 | 9 | `bloom_quality` | `crates/config/src/schema.rs`, `crates/crt-render/src/preset.rs` |
| 2 | 2 | 5 | 12 | `bank_padding` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 1 | 5 | 16 | `chassis_params` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/frame.rs` |
| 2 | 0 | 5 | 7 | `low_resolution` | `crates/term/src/fonts/mod.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 0 | 5 | 11 | `Coverage` | `crates/term/src/atlas.rs`, `crates/term/src/fonts/text.rs` |
| 2 | 0 | 4 | 4 | `key_pressed` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 2 | 4 | 10 | `TmuxPane` | `crates/app/src/channels.rs`, `crates/term/src/tmux_pane.rs` |
| 2 | 3 | 4 | 4 | `KillWindow` | `crates/app/src/channels.rs`, `crates/tmux-cc/src/command.rs` |
| 2 | 1 | 4 | 10 | `TRACK_WIDTH` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 2 | 2 | 4 | 9 | `top_padding` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 2 | 4 | 12 | `row_spacing` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 1 | 4 | 5 | `visible_text` | `crates/chassis/src/displays/led/mod.rs`, `crates/chassis/src/displays/tape/mod.rs` |
| 2 | 1 | 4 | 18 | `raster_pixel_size` | `crates/term/src/atlas.rs`, `crates/term/src/fonts/sizing.rs` |
| 2 | 1 | 4 | 5 | `set_burn_in` | `crates/crt-burnin/src/decay.rs`, `crates/crt-burnin/src/lib.rs` |
| 2 | 1 | 3 | 8 | `workdir` | `crates/app/src/cli.rs`, `crates/crt-burnin/tests/mount.rs` |
| 2 | 2 | 3 | 4 | `plate_params` | `crates/app/tests/bank_column.rs`, `crates/chassis/src/furniture.rs` |
| 2 | 2 | 3 | 12 | `ListPanes` | `crates/app/src/tmux.rs`, `crates/tmux-cc/src/command.rs` |
| 2 | 2 | 3 | 5 | `WindowRenamed` | `crates/app/src/tmux.rs`, `crates/tmux-cc/src/event.rs` |
| 2 | 2 | 3 | 3 | `WindowPaneChanged` | `crates/app/src/tmux.rs`, `crates/tmux-cc/src/event.rs` |
| 2 | 1 | 3 | 3 | `write_key` | `crates/app/src/settings.rs`, `crates/config/src/toml.rs` |
| 2 | 1 | 3 | 4 | `Unknown` | `crates/term/src/hotspots.rs`, `crates/tmux-cc/src/event.rs` |
| 2 | 2 | 3 | 6 | `Malformed` | `crates/config/src/profile.rs`, `crates/tmux-cc/src/event.rs` |
| 2 | 0 | 3 | 3 | `distort_coordinates` | `crates/chassis/src/oracle.rs`, `crates/crt-render/src/oracle.rs` |
| 2 | 1 | 3 | 7 | `apply_settings` | `crates/chassis/src/cabinet.rs`, `crates/crt-render/src/chain.rs` |
| 2 | 3 | 3 | 15 | `letter_spacing` | `crates/chassis/src/paint.rs`, `crates/term/src/fonts/text.rs` |
| 2 | 1 | 3 | 8 | `bottom_padding` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 1 | 3 | 10 | `track_width` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 1 | 3 | 6 | `min_inner_size` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/layout.rs` |
| 2 | 2 | 3 | 5 | `cell_metrics` | `crates/chassis/src/displays/led/mod.rs`, `crates/term/src/atlas.rs` |
| 2 | 1 | 3 | 15 | `preserve_line_breaks` | `crates/term/src/pointer.rs`, `crates/term/src/selection.rs` |
| 2 | 0 | 3 | 13 | `start_column` | `crates/term/src/hotspots.rs`, `crates/term/src/search.rs` |
| 2 | 0 | 3 | 13 | `start_line` | `crates/term/src/hotspots.rs`, `crates/term/src/search.rs` |
| 2 | 0 | 3 | 4 | `line_len` | `crates/term/src/grid.rs`, `crates/term/src/rio_grid.rs` |
| 2 | 2 | 3 | 10 | `FontSource` | `crates/config/src/schema.rs`, `crates/term/src/fonts/mod.rs` |
| 2 | 1 | 2 | 4 | `CRT_MINIMUM_WIDTH` | `crates/chassis/src/layout.rs`, `crates/xtask/src/snap.rs` |
| 2 | 1 | 2 | 17 | `Server` | `crates/app/tests/tmux_flow.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 2 | 0 | 2 | 4 | `lit_pixels` | `crates/crt-render/tests/glyph_survival.rs`, `crates/term/src/gpu.rs` |
| 2 | 0 | 2 | 5 | `preedit` | `crates/app/src/window.rs`, `crates/term/src/render.rs` |
| 2 | 1 | 2 | 2 | `collapse_page` | `crates/app/src/channels.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 2 | 5 | `is_gliding` | `crates/app/src/window.rs`, `crates/term/src/viewport.rs` |
| 2 | 0 | 2 | 4 | `top_line` | `crates/app/src/window.rs`, `crates/term/src/selection.rs` |
| 2 | 0 | 2 | 5 | `terminal_uses_mouse` | `crates/app/src/window.rs`, `crates/term/src/pointer.rs` |
| 2 | 0 | 2 | 2 | `focus_changed` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 1 | 2 | 3 | `Ignore` | `crates/app/src/tmux.rs`, `crates/term/src/pointer.rs` |
| 2 | 1 | 2 | 2 | `show_terminal_size` | `crates/app/src/shell.rs`, `crates/config/src/schema.rs` |
| 2 | 2 | 2 | 2 | `grid_size` | `crates/app/src/shell.rs`, `crates/chassis/src/displays/led/mod.rs` |
| 2 | 0 | 2 | 5 | `Uniforms` | `crates/app/src/badge.rs`, `crates/term/src/render.rs` |
| 2 | 2 | 2 | 9 | `Param` | `crates/chassis/src/frame.rs`, `crates/crt-render/src/params.rs` |
| 2 | 1 | 2 | 2 | `frame_style` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/lib.rs` |
| 2 | 1 | 2 | 4 | `screw_places` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 2 | 1 | 2 | 3 | `face_data` | `crates/chassis/src/paint.rs`, `crates/term/src/fonts/system.rs` |
| 2 | 0 | 2 | 7 | `Painted` | `crates/chassis/src/furniture.rs`, `crates/chassis/src/paint.rs` |
| 2 | 1 | 2 | 7 | `track_x` | `crates/chassis/src/bank.rs`, `crates/chassis/src/metrics.rs` |
| 2 | 1 | 2 | 5 | `Raster` | `crates/chassis/src/furniture.rs`, `crates/term/src/atlas.rs` |
| 2 | 1 | 2 | 3 | `in_control_mode` | `crates/term/src/dcs.rs`, `crates/term/src/tmux_cc.rs` |
| 2 | 2 | 2 | 11 | `tap_mut` | `crates/term/src/dcs.rs`, `crates/term/src/session.rs` |
| 2 | 1 | 2 | 4 | `column_selection_mode` | `crates/term/src/pointer.rs`, `crates/term/src/selection.rs` |
| 2 | 0 | 2 | 6 | `end_column` | `crates/term/src/hotspots.rs`, `crates/term/src/search.rs` |
| 2 | 0 | 2 | 7 | `end_line` | `crates/term/src/hotspots.rs`, `crates/term/src/search.rs` |
| 2 | 1 | 2 | 11 | `row_text` | `crates/term/src/cells.rs`, `crates/term/src/rio_grid.rs` |
| 2 | 0 | 2 | 3 | `Settings` | `crates/config/src/toml.rs`, `crates/config/src/watch.rs` |
| 2 | 0 | 1 | 1 | `destdir` | `crates/xtask/src/install.rs`, `crates/xtask/src/main.rs` |
| 2 | 1 | 1 | 1 | `run_bytes` | `crates/app/tests/tmux_flow.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 2 | 1 | 1 | 9 | `send_raw` | `crates/app/tests/tmux_flow.rs`, `crates/tmux-cc/tests/support/mod.rs` |
| 2 | 1 | 1 | 1 | `kill_window` | `crates/app/src/tmux.rs`, `crates/tmux-cc/examples/record.rs` |
| 2 | 0 | 1 | 14 | `BURN_IN` | `crates/crt-burnin/tests/mount.rs`, `crates/crt-render/tests/burn_in_chain.rs` |
| 2 | 0 | 1 | 4 | `write_atomic` | `crates/app/tests/settings_live_reload.rs`, `crates/config/src/toml.rs` |
| 2 | 0 | 1 | 1 | `set_client_size` | `crates/app/src/tmux.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 1 | 3 | `new_channel` | `crates/app/src/channels.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 1 | 2 | `close_channel` | `crates/app/src/channels.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 1 | 5 | `mouse_wheel` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 1 | 1 | `modifiers_changed` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 1 | 2 | `preset_text` | `crates/app/src/column.rs`, `crates/crt-render/src/preset.rs` |
| 2 | 0 | 1 | 1 | `Recording` | `crates/app/src/column.rs`, `crates/term/src/dcs.rs` |
| 2 | 1 | 1 | 1 | `absolute_slot` | `crates/app/src/bank.rs`, `crates/chassis/src/strip.rs` |
| 2 | 0 | 1 | 1 | `rounded_rect_sdf_pixels` | `crates/chassis/src/oracle.rs`, `crates/crt-render/src/oracle.rs` |
| 2 | 1 | 1 | 1 | `metal_light` | `crates/chassis/src/shells/common.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 2 | 1 | 1 | 1 | `metal_mid` | `crates/chassis/src/shells/common.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 2 | 1 | 1 | 1 | `metal_dark` | `crates/chassis/src/shells/common.rs`, `crates/chassis/src/shells/switchboard.rs` |
| 2 | 1 | 1 | 1 | `pointer_pressed` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/seam.rs` |
| 2 | 1 | 1 | 1 | `pointer_released` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/seam.rs` |
| 2 | 1 | 1 | 2 | `strip_at` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/furniture.rs` |
| 2 | 1 | 1 | 6 | `term_mut` | `crates/term/src/session.rs`, `crates/term/src/tmux_pane.rs` |
| 2 | 1 | 1 | 1 | `sync_deadline` | `crates/term/src/session.rs`, `crates/term/src/tmux_pane.rs` |
| 2 | 0 | 1 | 1 | `history_lines` | `crates/term/src/grid.rs`, `crates/term/src/rio_grid.rs` |
| 2 | 1 | 1 | 6 | `is_wrapped` | `crates/term/src/grid.rs`, `crates/term/src/rio_grid.rs` |
| 2 | 1 | 1 | 1 | `last_decay` | `crates/crt-burnin/src/chain.rs`, `crates/crt-burnin/src/lib.rs` |
| 2 | 0 | 1 | 6 | `deep_blue` | `crates/config/src/profile.rs`, `crates/config/src/toml.rs` |
| 2 | 0 | 0 | 0 | `out_dir` | `crates/xtask/src/install.rs`, `crates/xtask/src/main.rs` |
| 2 | 0 | 0 | 0 | `INNER_ENV` | `crates/xtask/src/snap.rs`, `crates/xtask/src/verify.rs` |
| 2 | 0 | 0 | 0 | `Scratch` | `crates/app/src/instance.rs`, `crates/xtask/src/verify.rs` |
| 2 | 0 | 0 | 0 | `run_inner` | `crates/xtask/src/snap.rs`, `crates/xtask/src/verify.rs` |
| 2 | 0 | 0 | 0 | `make_absolute` | `crates/xtask/src/mask.rs`, `crates/xtask/src/snap.rs` |
| 2 | 0 | 0 | 0 | `Glass` | `crates/app/src/window.rs`, `crates/xtask/src/compare.rs` |
| 2 | 0 | 0 | 0 | `have_tmux` | `crates/app/tests/tmux_flow.rs`, `crates/tmux-cc/tests/live_tmux.rs` |
| 2 | 0 | 0 | 0 | `window_size` | `crates/app/src/window.rs`, `crates/term/src/bin/esctest_harness.rs` |
| 2 | 0 | 0 | 0 | `FP16_ULP` | `crates/crt-burnin/tests/burn_in.rs`, `crates/crt-render/tests/burn_in_chain.rs` |
| 2 | 0 | 0 | 0 | `tmux_host` | `crates/app/src/channels.rs`, `crates/app/tests/tmux_flow.rs` |
| 2 | 0 | 0 | 0 | `row_of` | `crates/app/src/channels.rs`, `crates/app/tests/tmux_flow.rs` |
| 2 | 0 | 0 | 0 | `Fixture` | `crates/app/tests/size_badge.rs`, `crates/term/src/fonts/system.rs` |
| 2 | 0 | 0 | 0 | `CapturingLogger` | `crates/app/src/tmux.rs`, `crates/app/tests/settings_live_reload.rs` |
| 2 | 0 | 0 | 0 | `init_logger` | `crates/app/src/tmux.rs`, `crates/app/tests/settings_live_reload.rs` |
| 2 | 0 | 0 | 0 | `scale_factor_changed` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 0 | 0 | `set_size_badge` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 0 | 0 | `cell_size` | `crates/app/src/shell.rs`, `crates/app/src/window.rs` |
| 2 | 0 | 0 | 0 | `force_reload` | `crates/app/src/settings.rs`, `crates/config/src/watch.rs` |
| 2 | 0 | 0 | 0 | `approx_eq` | `crates/app/src/settings.rs`, `crates/term/src/distortion.rs` |
| 2 | 0 | 0 | 0 | `lock_path` | `crates/app/src/instance.rs`, `crates/crt-burnin/src/headless.rs` |
| 2 | 0 | 0 | 0 | `new_async` | `crates/app/src/gpu.rs`, `crates/term/src/gpu.rs` |
| 2 | 0 | 0 | 0 | `chassis_style` | `crates/chassis/src/cabinet.rs`, `crates/chassis/src/lib.rs` |
| 2 | 0 | 0 | 0 | `PANEL_DARK` | `crates/chassis/src/shells/annunciator.rs`, `crates/chassis/src/shells/slide_rule.rs` |
| 2 | 0 | 0 | 0 | `min_units_matches_the_defining_formula` | `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs` |
| 2 | 0 | 0 | 0 | `width_for_units_matches_the_defining_formula` | `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs` |
| 2 | 0 | 0 | 0 | `pad_cells_for_hole_matches_the_defining_formula` | `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs` |
| 2 | 0 | 0 | 0 | `height_for_pad_cells_matches_the_defining_formula` | `crates/chassis/src/displays/led/metrics.rs`, `crates/chassis/src/displays/tape/metrics.rs` |

# Measured table (Count)

A = non-test source files outside the module that reference a symbol it defines (graph).
B = files of any kind mentioning any name in its vocabulary (grep).
C = total mentions across those B files. leak = B minus the files the graph already counted.
score = C x leak/B.

| score | leak | A | B | C | file | vocabulary sample |
|---|---|---|---|---|---|---|
| 315 | 29 | 1 | 30 | 326 | `crates/app/src/tmux.rs` | tmux, teardown, PaneGate, sent_size, TightWire, new_window |
| 208 | 24 | 1 | 25 | 217 | `crates/app/src/window.rs` | on_air, cell_at, is_digit, ime_area, has_bank, key_text |
| 198 | 14 | 5 | 19 | 269 | `crates/chassis/src/oracle.rs` | hash12, vnoise, size_px, rrect_px, bevel_px, light_dir |
| 172 | 31 | 4 | 35 | 194 | `crates/term/src/cells.rs` | cells, charset, row_mut, fill_row, CellGrid, from_lines |
| 158 | 6 | 2 | 8 | 210 | `crates/app/src/channels.rs` | PageId, rows_mut, ViewPage, PageKind, set_title, window_id |
| 155 | 11 | 17 | 23 | 324 | `crates/config/src/schema.rs` | rgb_shift, SlideRule, font_source, Annunciator, SystemFonts, static_noise |
| 130 | 17 | 4 | 21 | 160 | `crates/term/src/size.rs` | CellSize, TermSize, MIN_COLS, MIN_ROWS, term_size, scale_factor |
| 129 | 9 | 9 | 18 | 258 | `crates/chassis/src/metrics.rs` | end_pad, pad_cells, dot_pitch, column_gap, LedMetrics, pager_extra |
| 112 | 15 | 16 | 31 | 231 | `crates/config/src/lib.rs` | Config, raw_frame_size, raw_frame_color, SCREEN_RADIUS_PX, raw_screen_radius, raw_frame_shininess |
| 109 | 11 | 5 | 16 | 159 | `crates/config/src/toml.rs` | toml, FILE_NAME, write_keys, set_dotted, deserialize, Deserialize |
| 103 | 21 | 1 | 22 | 108 | `crates/crt-burnin/src/headless.rs` | GpuLock, cast_f32, px_index, GpuError, make_input, make_output |
| 97 | 37 | 2 | 39 | 102 | `crates/chassis/src/shaders.rs` | shaders, TAPE_LABEL_SLANG, LED_MATRIX_SLANG, PLATE_METAL_SLANG, FRAME_METAL_SLANG, CHASSIS_METAL_SLANG |
| 93 | 6 | 2 | 8 | 124 | `crates/term/src/selection.rs` | act_sel, set_end, drag_to, word_end, is_valid, top_left |
| 86 | 9 | 3 | 12 | 114 | `crates/term/src/fonts/sizing.rs` | dpr_scale, ScalePolicy, compute_font, ComputedFont, ResolvedFont, texture_scale |
| 84 | 4 | 0 | 4 | 84 | `crates/app/tests/size_badge.rs` | WINDOW_H, WINDOW_W, SENTINEL_F, FRAME_FORMAT, frame_with_badge, the_fade_is_visible_in_the_pixels |
| 80 | 17 | 4 | 20 | 94 | `crates/term/src/session.rs` | is_idle, READ_BUF, grid_rows, grid_cols, INPUT_CAP, child_gone |
| 78 | 11 | 4 | 15 | 106 | `crates/crt-render/src/params.rs` | Params, raster_mode, output_width, virtual_width, output_height, screen_colors |
| 72 | 7 | 7 | 14 | 145 | `crates/tmux-cc/src/ids.rs` | PaneId, WindowId, SessionId, the_number_is_the_tail, a_sigil_belongs_to_exactly_one_kind, a_bare_sigil_or_a_non_numeric_tail_is_not_an_id |
| 70 | 10 | 2 | 12 | 84 | `crates/term/src/render.rs` | set_row, BLOCK_BG, origin_x, set_grid, origin_y, set_atlas |
| 70 | 8 | 2 | 10 | 87 | `crates/app/src/settings.rs` | look_path, config_dir, config_path, ScreenPreset, SavedProfile, known_screens |
| 68 | 7 | 1 | 8 | 78 | `crates/term/src/hotspots.rs` | regex, HotSpot, UrlType, url_type, hotspots, hot_spots |
| 64 | 7 | 6 | 13 | 118 | `crates/chassis/src/bank.rs` | track_gap, content_x, row_height, pad_cells_y, strip_width, from_setting |
| 61 | 4 | 3 | 7 | 106 | `crates/chassis/src/displays/tape/mod.rs` | END_PAD, BEVEL_PX, FONT_NAME, DILATE_PX, slot_color, tape_color |
| 52 | 5 | 1 | 6 | 62 | `crates/app/src/input.rs` | PageUp, any_mod, f1_shift, PageDown, SsLetter, KeyAction |
| 50 | 7 | 4 | 11 | 79 | `crates/crt-render/src/degauss.rs` | scale_y, Degauss, is_active, is_running, DegaussState, PEAK_SCALE_Y |
| 48 | 6 | 1 | 7 | 56 | `crates/app/src/mouse.rs` | WheelUp, WheelDown, encode_sgr, encode_x10, button_code, MouseButton |
| 46 | 8 | 4 | 12 | 69 | `crates/term/src/atlas.rs` | atlas_y, font_id, atlas_x, for_face, GlyphSlot, GlyphAtlas |
| 45 | 10 | 16 | 26 | 117 | `crates/term/src/fonts/mod.rs` | FontData, FontEntry, is_system, base_width, BundledFont, resolve_all |
| 43 | 12 | 1 | 13 | 47 | `crates/term/src/search.rs` | search, SearchHit, BLOCK_LINES, search_range, literal_pattern, find_line_number |
| 41 | 11 | 2 | 13 | 48 | `crates/term/src/tmux_cc.rs` | tmux_cc, TMUX_DCS, take_body, take_ended, TMUX_PARAMS, TMUX_ACTION |
| 40 | 5 | 6 | 10 | 79 | `crates/chassis/src/displays/led/mod.rs` | DOT_RADIUS, SPILL_DEAD, LED_PAD_CELLS, LED_DOT_PITCH, window_colors, spill_margins |
| 36 | 2 | 8 | 9 | 164 | `crates/chassis/src/paint.rs` | ArcOp, Serif, TextOp, RectOp, radial_t, PolygonOp |
| 35 | 5 | 6 | 11 | 76 | `crates/term/src/grid.rs` | GridView, copy_line, char_width, ToEndOfLine, write_range, with_history |
| 33 | 4 | 11 | 14 | 116 | `crates/chassis/src/color.rs` | to_hsv, from_hsv, substring, with_alpha, scale_color, str_to_color |
| 29 | 5 | 2 | 7 | 40 | `crates/xtask/src/x11.rs` | x11, shell_xy, window_name, min_size_hint, geometry_width, sizable_windows |
| 29 | 5 | 2 | 7 | 41 | `crates/app/src/shell.rs` | wake_at, last_tick, event_loop, user_event, ShellEvent, open_window |
| 27 | 7 | 4 | 10 | 38 | `crates/crt-burnin/src/lib.rs` | set_mask, for_device, BurnInPass, last_pushed, write_shader, BURN_IN_SLANG |
| 27 | 8 | 3 | 9 | 30 | `crates/term/src/gpu.rs` | write_pgm, read_rgba, ascii_preview, TARGET_FORMAT, upscale_nearest, max_channel_delta |
| 26 | 8 | 2 | 9 | 29 | `crates/crt-render/src/preset.rs` | body_at, scale_of, NOISE_PNG, BURN_PASS, FrameBody, FRAME_PASS |
| 26 | 3 | 4 | 7 | 60 | `crates/term/src/dcs.rs` | dcs, DcsTap, DcsOnly, NoopTap, ScanState, DcsParser |
| 25 | 7 | 1 | 8 | 29 | `crates/crt-burnin/src/decay.rs` | max_dt, decay_step, MASK_PARAM, DecayClock, DECAY_PARAM, MAX_FADE_TIME |
| 25 | 4 | 0 | 4 | 25 | `crates/app/tests/shed_notice.rs` | DEAF_CHILD, shed_notice, wait_for_screen, typing_thrown_away_by_a_full_queue_says_so_on_the_glass |
| 25 | 3 | 0 | 3 | 25 | `crates/crt-render/tests/support/mod.rs` | lit_rows, BAR_LEVEL, mean_luma, draw_dark, draw_field, PICTURE_WGSL |
| 24 | 7 | 2 | 9 | 31 | `crates/term/src/lib.rs` | build_font, ascii_charset, DEFAULT_THRESHOLD |
| 23 | 3 | 5 | 8 | 61 | `crates/chassis/src/strip.rs` | StripRow, pointer_y, BankStrips, cold_start, current_row, numeral_text |
| 22 | 3 | 4 | 6 | 43 | `crates/tmux-cc/src/command.rs` | to_wire, SendKeys, HostName, ClientSize, CapturePane, ListWindows |
| 22 | 2 | 3 | 5 | 56 | `crates/tmux-cc/src/event.rs` | WindowAdd, WindowClose, window_index, LayoutChange, GuardMismatch, ClientDetached |
| 22 | 2 | 3 | 5 | 55 | `crates/term/src/viewport.rs` | to_top, page_up, to_bottom, page_down, lines_for, WHEEL_LINES |
| 21 | 6 | 15 | 12 | 42 | `crates/chassis/src/layout.rs` | WindowLayout, chassis_field, MINIMUM_HEIGHT, NORMALISATION_WIDTH, min_inner_size_physical, the_well_never_goes_negative |
| 21 | 11 | 0 | 11 | 21 | `crates/chassis/tests/tape_label.rs` | SIZE_H, SIZE_W, tape_label, tape_label_letter_and_body_read_correctly |
| 21 | 10 | 0 | 10 | 21 | `crates/chassis/tests/led_matrix.rs` | OUT_W, OUT_H, GRID_W, GRID_H, led_matrix, led_matrix_lit_and_dark_cells_read_correctly |
| 21 | 1 | 3 | 2 | 42 | `crates/term/src/pointer.rs` | on_press, with_shift, mouse_marks, PastePrimary, frozen_glass, PointerAction |
| 21 | 1 | 0 | 1 | 21 | `crates/app/tests/clipboard_keys.rs` | CTRL_SHIFT, clipboard_keys, the_clipboard_chords_reach_the_child_as_nothing |
| 20 | 4 | 2 | 5 | 25 | `crates/crt-render/src/chain.rs` | frame_at, set_params, preset_path, last_burn_in_decay |
| 19 | 7 | 5 | 12 | 33 | `crates/crt-render/src/pacing.rs` | tick_by, FrameTime |
| 19 | 5 | 2 | 7 | 26 | `crates/term/src/fonts/subpixel.rs` | Configs, subpixel, APPEND_RGB, filter_row, rgba_value, host_layout |
| 18 | 10 | 1 | 11 | 20 | `crates/app/src/crashlog.rs` | LOG_PATH, crashlog, PATH_MAX, backtrace, write_all, MAX_FRAMES |
| 18 | 2 | 0 | 2 | 18 | `crates/app/tests/ime.rs` | ime, ECHOING_CHILD, never_on_screen, the_preedit_is_held_and_not_sent, an_abandoned_composition_sends_nothing, a_committed_string_reaches_the_child_as_utf8 |
| 15 | 4 | 2 | 6 | 23 | `crates/tmux-cc/src/escape.rs` | unvis, unvis_text, is_escaped, escape_octal, hex_arguments, unescape_octal |
| 15 | 1 | 2 | 3 | 44 | `crates/app/src/frame_stats.rs` | GridEnd, grid_ms, FrameEnd, chain_ms, frame_ms, ChainEnd |
| 14 | 4 | 4 | 8 | 27 | `crates/term/src/fonts/led.rs` | LedRaster, led_text_image |
| 14 | 5 | 2 | 7 | 20 | `crates/chassis/src/shells/slide_rule.rs` | TRACK_X, RIM_DARK, rail_rect, RIM_LIGHT, NUMERAL_INK, NUMERAL_EDGE |
| 14 | 2 | 3 | 5 | 35 | `crates/term/src/rio_grid.rs` | RioGrid, rio_grid, all_text, cell_char, live_text, row_cells |
| 14 | 2 | 2 | 4 | 29 | `crates/app/src/overlay.rs` | GridSize, visible_at, opacity_at, NOTICE_HOLD, SizeOverlay, set_enabled |
| 14 | 3 | 2 | 4 | 18 | `crates/chassis/src/shells/switchboard.rs` | WELL_DARK, PLATE_REACH, serif_width, PAGER_HEIGHT, PLATE_SHADOW, NUMERAL_PAINT |
| 14 | 3 | 2 | 4 | 18 | `crates/chassis/src/shells/annunciator.rs` | KEY_TOP, CUT_DARK, LIP_LIGHT, KEY_WIDTH, plate_rect, KEY_HEIGHT |
| 13 | 2 | 0 | 2 | 13 | `crates/term/tests/preedit.rs` | lit_in, terminess, cursor_at, cell_rect, CURSOR_COL, CURSOR_ROW |
| 12 | 3 | 3 | 6 | 24 | `crates/tmux-cc/src/codec.rs` | Codec, next_id, in_block, OpenBlock, line_done, CommandId |
| 10 | 5 | 0 | 5 | 10 | `crates/term/tests/pixel_properties.rs` | commodore_pet, pixel_properties, property_1_antialiasing_is_off, damage_updates_only_the_rows_that_changed, property_3_dpr_changes_do_not_touch_the_atlas, property_2_integer_scaling_is_exact_duplication |
| 10 | 4 | 1 | 5 | 13 | `crates/app/src/bank.rs` | BankView, BankPager, last_view, rows_on_page, ensure_visible, slot_prefix_exists |
| 9 | 2 | 5 | 7 | 30 | `crates/chassis/src/shells/common.rs` | screw_head, ScrewColors, FieldMapping, field_mapping, screw_head_with, frame_viewport_size |
| 9 | 4 | 5 | 6 | 14 | `crates/chassis/src/cabinet.rs` | is_shown, remeasure, SeamUpdate, apply_config, bank_width_physical, the_display_kit_travels_with_the_profile |
| 9 | 2 | 3 | 5 | 23 | `crates/term/src/distortion.rs` | total_width, total_height, forward_distort, DistortionParams, correct_distortion, screen_curvature_size |
| 8 | 4 | 5 | 8 | 16 | `crates/chassis/src/lib.rs` | led_metrics, display_kit, tape_metrics, shell_metrics, a_reload_re_measures_the_kit_and_not_only_the_geometry, the_stock_profile_measures_its_lamp_font_rather_than_a_fixture |
| 8 | 3 | 5 | 8 | 21 | `crates/config/src/presets.rs` | screen_presets, chassis_presets |
| 8 | 4 | 1 | 5 | 10 | `crates/tmux-cc/tests/support/mod.rs` | client_pid, kill_client, control_stream, envelope_closed |
| 8 | 4 | 1 | 5 | 10 | `crates/term/tests/font_parity.rs` | LED_TEXT, golden_led, fixture_dir, font_parity, empty_text_has_no_raster, scaled_metrics_match_golden |
| 8 | 2 | 3 | 5 | 20 | `crates/chassis/src/seam.rs` | SeamDrag, SeamCursor, SeamContext, is_dragging, window_width, characters_at |
| 8 | 2 | 0 | 2 | 8 | `crates/app/tests/settings_live_reload.rs` | wait_until, logged_the_rejection, settings_live_reload, sigusr1_forces_a_reload, invalid_edit_keeps_last_good_and_logs, zero_config_launch_resolves_to_the_frozen_v1_default |
| 8 | 1 | 1 | 2 | 15 | `crates/config/src/structural.rs` | KeyClass, every_structural_key_resolves_against_the_schema, a_structural_move_and_a_parameter_move_classify_apart |
| 8 | 1 | 1 | 1 | 8 | `crates/app/src/column.rs` | ChainKey, chain_for, BLIT_WGSL, draw_over, make_bind, make_dest |
| 7 | 1 | 4 | 5 | 36 | `crates/xtask/src/proc.rs` | proc, run_ok, capture_lenient, reexec_under_xvfb, run_ignore_status |
| 7 | 3 | 0 | 3 | 7 | `crates/app/tests/bank_column.rs` | bank_column, oracle_params, frame_with_column, frame_with_furniture, a_hidden_chassis_draws_no_column_at_all, the_tape_shell_stamps_its_label_and_screws_on_no_plate |
| 7 | 2 | 2 | 3 | 10 | `crates/config/src/profile.rs` | round4, save_to, apply_to, read_axis, to_scalar, json_value |
| 6 | 2 | 8 | 10 | 28 | `crates/term/src/fonts/metrics.rs` | scale_26_6, round_26_6, ascent_int, height_int, descent_int, ascent_26_6 |
| 6 | 5 | 0 | 5 | 6 | `crates/crt-render/tests/device_features.rs` | device_features, every_device_the_chain_runs_on_asks_for_the_same_features, the_wanted_set_is_a_filter_and_never_more_than_the_adapter_has |
| 6 | 2 | 7 | 5 | 14 | `crates/chassis/src/furniture.rs` | led_grid, LedMatrix, led_piece, TapeLabel, led_params, tape_piece |
| 6 | 2 | 1 | 3 | 9 | `crates/app/src/cli.rs` | cli, default_settings, contract_flags_parse, missing_option_value_fails, unknown_option_fails_loudly, help_and_version_print_and_stop |
| 6 | 2 | 0 | 2 | 6 | `crates/crt-render/src/oracle.rs` | rand2, STEPS_PER_TEXEL, gaussian_blur_1d, TerminalFrameParams, terminal_frame_noise |
| 6 | 2 | 0 | 2 | 6 | `crates/crt-burnin/src/chain.rs` | BurnInChain |
| 5 | 2 | 4 | 6 | 15 | `crates/chassis/src/js.rs` | js, round_i32, halves_go_up_not_away_from_zero, ordinary_values_agree_with_rust |
| 5 | 4 | 0 | 4 | 5 | `crates/term/tests/system_fonts.rs` | dejavu, system_fonts, a_selected_system_face_shapes_and_measures, the_enumeration_offers_dejavu_sans_mono_under_the_filter_rules |
| 5 | 2 | 1 | 3 | 7 | `crates/xtask/src/compare.rs` | chroma, load_rgb, crop_rgb, BANK_WIDTH, parse_crop, GLASS_INSET |
| 5 | 1 | 4 | 3 | 15 | `crates/chassis/src/frame.rs` | FrameStyle, FrameScale, ChassisStyle, slide_rule_frame, switchboard_frame, annunciator_frame |
| 5 | 1 | 1 | 2 | 10 | `crates/config/src/watch.rs` | _watcher, spawn_with, reload_into, ConfigWatcher, event_touches, spawn_with_loader |
| 4 | 4 | 0 | 4 | 4 | `crates/chassis/tests/metrics_homes.rs` | same_shell, metrics_homes, the_tape_well_metrics_composes_the_bare_functions, the_led_strip_metrics_composes_the_bare_functions, the_slide_rule_shell_metrics_composes_the_bare_constants, the_annunciator_shell_metrics_composes_the_bare_constants |
| 4 | 3 | 0 | 3 | 4 | `crates/term/src/bin/esctest_harness.rs` | WinOps, set_size, checksum, send_event, csi_dispatch, wait_for_child |
| 4 | 2 | 1 | 3 | 6 | `crates/app/src/gpu.rs` | discard_timing, frame_stats_enabled, frame_stats_available |
| 3 | 1 | 4 | 5 | 13 | `crates/term/src/fonts/text.rs` | iosevka, TextSpec, TextRaster, text_image, all_channels, align_offset |
| 3 | 2 | 1 | 3 | 4 | `crates/chassis/src/shells/mod.rs` | row_overhang, plate_region |
| 3 | 2 | 1 | 3 | 5 | `crates/chassis/src/displays/raster.rs` | to_rgba8, widens_one_alpha_byte_to_four |
| 3 | 1 | 0 | 1 | 3 | `crates/chassis/tests/bank_frame_render.rs` | params_pair, WINDOW_SIZES, stock_bank_width, bank_frame_render, moulding_thickness, a_wider_bank_thickens_the_moulding_it_leaves |
| 2 | 1 | 1 | 2 | 3 | `crates/xtask/src/snap.rs` | _scratch, SnapArgs, fit_units, find_window, DETERMINISTIC_LINE, reexec_under_xvfb_for_snap |
| 2 | 2 | 0 | 2 | 2 | `crates/tmux-cc/tests/live_tmux.rs` | live_tmux, the_whole_command_set_is_a_dialect_tmux_speaks, keys_sent_as_hex_reach_the_pane_and_come_back_as_output, the_bootstrap_replies_are_the_shapes_the_reference_reads, a_new_window_asked_for_through_the_codec_arrives_and_parses, a_killed_client_leaves_the_envelope_open_and_the_session_standing |
| 2 | 2 | 0 | 2 | 2 | `crates/crt-render/tests/glyph_survival.rs` | MIN_INK, lit_runs, MIN_RUNS, glyph_survival, the_measurement_can_see_strokes_go_missing, a_stem_that_reaches_the_grid_reaches_the_glass |
| 2 | 2 | 0 | 2 | 2 | `crates/crt-render/tests/burn_in_chain.rs` | GHOST_TRIM, burn_in_chain, the_freshness_mask_survives_the_mount, switching_burn_in_off_takes_the_ghost_with_it, the_mounted_accumulator_decays_at_the_rate_the_settings_set |
| 2 | 2 | 0 | 2 | 2 | `crates/app/tests/keyboard_scroll.rs` | SIXTY_LINES, keyboard_scroll, typing_snaps_a_scrolled_view_to_the_bottom, shift_up_and_down_move_the_viewport_one_line, a_key_the_keytab_binds_to_bytes_does_not_scroll_back, shift_page_up_moves_the_viewport_back_through_the_scrollback |
| 2 | 1 | 1 | 1 | 2 | `crates/app/src/badge.rs` | BadgeRect, CORNER_RADIUS, the_uniform_block_is_the_size_the_shader_declares |
| 1 | 1 | 2 | 3 | 3 | `crates/app/src/paths.rs` | data_dir, crash_dir, cache_dir, preset_dir |
| 1 | 1 | 0 | 1 | 1 | `crates/crt-render/tests/pass_graph.rs` | pass_graph, still_config, mean_luma_rows, a_structural_change_rebuilds_the_chain, the_term_target_renders_through_the_chain, the_preset_is_the_documented_six_pass_graph |
| 1 | 1 | 0 | 1 | 1 | `crates/chassis/tests/region_layout.rs` | CHASSIS_SIZES, region_layout, slide_rule_regions_at_sampled_sizes, annunciator_regions_at_sampled_sizes, field_mapping_at_sampled_window_sizes, switchboard_has_no_plate_or_rail_region |
| 1 | 1 | 0 | 1 | 1 | `crates/chassis/tests/led_display.rs` | led_display, led_display_composes_the_proven_raster_with_led_matrix |
| 1 | 1 | 0 | 1 | 1 | `crates/chassis/tests/bank_frame_geometry.rs` | stock_bank, led_strip_width, bank_frame_geometry, the_pointer_law_at_every_shell, the_bank_never_moves_with_the_window, rows_per_page_at_sampled_window_heights |
| 1 | 1 | 0 | 1 | 1 | `crates/app/tests/profile_cli.rs` | profile_cli, launched_look, scratch_command, XDG_CONFIG_HOME_LOCK, an_unknown_profile_is_refused, a_known_profile_changes_the_launched_look |
| 1 | 1 | 0 | 1 | 1 | `crates/app/tests/channel_bank.rs` | channel_bank, ROWS_ON_PAGE, release_chord, wait_for_prompt, surface_of_height, ctrl_shift_w_closes_the_channel_on_the_air |
| 0 | 0 | 5 | 5 | 10 | `crates/term/src/fonts/system.rs` | sans_face, named_face, SystemFace, source_path, default_sans, default_serif |
| 0 | 0 | 3 | 3 | 5 | `crates/term/src/fonts/raster.rs` | glyph_mask, glyph_mask_thirds |
| 0 | 0 | 2 | 2 | 2 | `crates/app/src/geometry.rs` | DEFAULT_SIZE |
| 0 | 0 | 2 | 2 | 12 | `crates/term/src/tmux_pane.rs` | pty_mut, take_input, tmux_pane_mut, ChannelSession, a_resize_reflows_the_grid_alone, fed_bytes_land_on_the_grid_and_input_queues_until_drained |
| 0 | 0 | 1 | 1 | 1 | `crates/xtask/src/verify.rs` | VerifyArgs, children_of, run_capturing, wait_for_children, start_window_manager |
| 0 | 0 | 1 | 1 | 3 | `crates/xtask/src/install.rs` | DebArgs, lay_out, DistArgs, set_mode, shlibdeps, staged_root |
| 0 | 0 | 1 | 1 | 5 | `crates/xtask/src/fanout.rs` | fanout, strip_inline_tests |
| 0 | 0 | 2 | 1 | 1 | `crates/app/src/instance.rs` | ENV_GUARD, with_guard, runtime_dir, socket_path, read_request, drop_cleans_up |
| 0 | 0 | 1 | 1 | 1 | `crates/app/src/clipboard.rs` | bracket_paste, ClipboardError, bracket_paste_empty_string, bracket_paste_enabled_wraps, bracket_paste_disabled_passes_through |
| 0 | 0 | 1 | 1 | 4 | `crates/app/src/chord.rs` | ChordInput, store_mode, is_pending, feed_digit, COMMIT_TIMEOUT, zero_is_slot_ten |
| 0 | 0 | 4 | 1 | 1 | `crates/term/src/color.rs` | full_color, dim_factor, xterm_palette, palette_landmarks_match_xterm, monochrome_scheme_cannot_produce_a_third_colour |
| 0 | 0 | 0 | 0 | 0 | `crates/xtask/src/main.rs` | Fanout |
| 0 | 0 | 1 | 0 | 0 | `crates/xtask/src/mask.rs` | MASK_PY, SHINE_BAND |
| 0 | 0 | 0 | 0 | 0 | `crates/tmux-cc/tests/transcripts.rs` | the_zoo_holds_one_of_each, the_server_can_throw_the_client_off, the_pairing_queue_comes_out_in_order, every_transcript_is_a_control_stream, all_256_bytes_come_back_off_the_wire, a_window_closing_always_says_unlinked |
| 0 | 0 | 0 | 0 | 0 | `crates/tmux-cc/examples/record.rs` | readme, output_octal, fresh_session, second_window, notification_zoo, reattach_after_kill |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/transcript.rs` | on_screen, assert_child_agrees, a_child_that_exits_is_reported_as_eof, transcript_survives_a_resize_and_a_dpr_change, scrollback_survives_the_lines_leaving_the_screen, a_dcs_block_reaches_the_tap_and_stays_off_the_grid |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/selection_tests.rs` | selection_tests, block_selection_takes_a_rectangle, double_click_drops_a_trailing_at_sign, is_selected_agrees_with_the_copied_text, drag_left_then_copy_returns_the_same_span, double_click_keeps_a_path_and_a_url_whole |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/search_tests.rs` | search_grid, search_tests, search_misses_cleanly, search_takes_a_real_regex_too, search_forwards_wraps_round_to_the_top, search_backwards_finds_the_previous_hit |
| 0 | 0 | 1 | 0 | 0 | `crates/term/tests/scrollback.rs` | twenty_lines, scrollback_viewport_follows_history, untouched_cells_read_as_blanks_not_nuls, ordinary_output_does_not_force_a_full_rebuild, touchpad_pixels_move_the_view_by_fractions_of_a_row, a_wheel_notch_glides_three_lines_and_lands_on_the_line |
| 0 | 0 | 1 | 0 | 0 | `crates/term/tests/rio_grid_tests.rs` | term_with, rio_grid_tests, hotspots_run_over_a_live_grid, search_reaches_into_rio_scrollback, untouched_cells_never_reach_a_text_path_as_nul, a_selection_over_a_live_grid_copies_what_is_on_it |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/hotspot_tests.rs` | matched_rows, hotspot_tests, a_link_that_wraps_spans_two_lines, url_type_and_activation_match_each_url_kind, the_url_fixtures_match_the_recorded_matches, a_link_does_not_fuse_with_the_line_below_it |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/grid_tests.rs` | grid_tests, untouched_cells_are_not_part_of_a_line, double_width_characters_do_not_double_on_the_way_out |
| 0 | 0 | 0 | 0 | 0 | `crates/term/tests/antialias.rs` | ink_at, atlas_total, image_intermediate, atlas_intermediate, terminess_takes_its_strike_even_with_antialiasing_on, every_scalable_catalogue_face_takes_the_coverage_path |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/user_lut.rs` | user_lut, PROBE_PRESET, render_probe, probe_shader, the_noise_lut_reaches_the_shader_and_repeats |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/terminal_frame.rs` | terminal_frame_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/contracts.rs` | params_for, only_structural_keys_move_the_structure, contrast_and_saturation_reach_the_shader, the_degauss_curve_is_the_mockups_keyframe, a_parameter_can_be_overridden_after_it_is_built, window_opacity_reaches_the_output_and_the_flood |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-render/tests/bloom.rs` | SRC_W, SRC_H, shader_dir, mask_image, column_band, bloom_h_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-burnin/tests/mount.rs` | fp32_accumulator_is_available_and_better_than_fp16, a_generated_preset_mounts_the_pass_after_another_one |
| 0 | 0 | 0 | 0 | 0 | `crates/crt-burnin/tests/burn_in.rs` | ramp_error, ghost_mask, rate_error, decay_tracks_the_set_rate, the_float_framebuffer_is_what_buys_that_accuracy, burn_in_zero_leaves_no_ghost_and_needs_no_rebuild |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/tape_display.rs` | mask_at, tape_display, DISPLAY_HEIGHT, find_saturated_interior, tape_display_composes_the_proven_raster_with_tape_label |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/shader_recipes.rs` | shader_recipes, assert_rgb_close, switchboard_has_no_plate_metal_call_at_all, slide_rule_rail_is_plate_metal_not_chassis_metal, annunciator_plate_metal_recipe_matches_the_recorded_values, annunciator_frame_metal_recipe_matches_the_recorded_values |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/plate_metal.rs` | plate_metal_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/metrics_tables.rs` | metrics_tables, slide_rule_metrics_match_the_recorded_metrics, switchboard_metrics_match_the_recorded_metrics, annunciator_metrics_match_the_recorded_metrics |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/gpu_annunciator.rs` | gpu_annunciator, annunciator_chassis_metal_region_renders_as_the_oracle_predicts |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/frame_metal.rs` | frame_metal_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | `crates/chassis/tests/chassis_metal.rs` | chassis_metal_matches_oracle |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/tmux_flow.rs` | rows_of, tmux_flow, pump_until, type_attach, phase_3_a_rename_lands_unescaped_in_the_bank, phase_5_a_killed_window_loses_its_channel_and_the_page_stands |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/structure_subset.rs` | structure_subset, structure_reads_only_structural_keys, both_crates_derive_the_same_frame_size |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/seam_drag.rs` | seam_drag, STOCK_BANK, a_hidden_chassis_has_no_seam_and_no_column, a_press_the_seam_took_never_also_marks_the_screen, a_drag_with_no_settings_moves_the_bank_and_writes_nothing, a_drag_re_fits_the_bank_writes_the_count_and_survives_the_reload |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/redraw_pacing.rs` | redraw_pacing, a_flood_of_output_buys_one_frame_per_cadence_not_one_per_tick |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/profile_pixels.rs` | glass_tint, read_window, tools_present, profile_pixels, a_named_profile_reaches_the_glass_under_default_settings |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/pointer_live_settings.rs` | pointer_live_settings, select_at_fixed_pixels, a_click_lands_on_the_same_cell_at_dpr_1_and_dpr_2, a_config_edit_changes_the_pointer_mapping_without_restart |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/pointer.rs` | scrolling_back_down_re_follows_the_output, a_short_drag_selects_only_what_it_crossed, press_drag_release_selects_the_dragged_run, a_wheel_notch_scrolls_the_view_three_lines_back, a_double_click_takes_the_word_under_the_pointer, trackpad_pixels_scroll_the_view_by_fractions_of_a_row |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/frame_stats.rs` | burn_some_gpu_time, on_an_adapter_with_the_feature_pair_the_instrument_reports_plausible_timings, forcing_the_feature_pair_off_the_device_reports_unavailable_without_panicking |
| 0 | 0 | 0 | 0 | 0 | `crates/app/tests/crashlog_signal.rs` | read_soon, crashlog_signal, a_fatal_signal_writes_a_backtrace_and_still_kills_the_process |
| 0 | 0 | 1 | 0 | 0 | `crates/crt-render/src/device.rs` | supports_pipeline_cache, supports_fp32_accumulator |
| 0 | 0 | 3 | 0 | 0 | `crates/chassis/src/displays/tape/metrics.rs` | unit_width_is_the_departure_mono_m_advance_at_20px |
| 0 | 0 | 1 | 0 | 0 | `crates/chassis/src/displays/led/metrics.rs` | unit_width_matches_the_defining_formula |

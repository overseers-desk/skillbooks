# Flags for batch triage

Each row: the blind expectation, the measurement, the flags, the module's full vocabulary, and its leak files (B files the symbol graph did not already count as consumers).


## 1. `crates/chassis/src/shells/slide_rule.rs`

A 1→2 · B 2→13 · C 3→77 · D 5→16 · leak 11 · flags: B high, D high (hub)

vocabulary: `CHASSIS_CARRIES_TRACK, NUMERAL_EDGE, NUMERAL_INK, RIM_DARK, RIM_LIGHT, TRACK_X, bracket_screw, counter_lamps, rail_metal_params, rail_rect, slide_rule`

top B files: crates/chassis/src/shells/mod.rs (17: slide_rule, rail_rect, rail_metal_params); crates/chassis/tests/metrics_homes.rs (10: slide_rule, CHASSIS_CARRIES_TRACK, TRACK_X); crates/chassis/src/metrics.rs (9: slide_rule, CHASSIS_CARRIES_TRACK, TRACK_X); crates/chassis/tests/region_layout.rs (8: slide_rule, rail_rect); crates/chassis/tests/shader_recipes.rs (7: slide_rule, rail_metal_params); crates/chassis/tests/metrics_tables.rs (7: TRACK_X, slide_rule, CHASSIS_CARRIES_TRACK); crates/chassis/tests/bank_frame_geometry.rs (5: slide_rule); crates/config/src/profile.rs (5: slide_rule)

leak files: crates/app/tests/profile_cli.rs, crates/chassis/src/bank.rs, crates/chassis/src/furniture.rs, crates/chassis/src/lib.rs, crates/chassis/tests/bank_frame_geometry.rs, crates/chassis/tests/metrics_homes.rs, crates/chassis/tests/metrics_tables.rs, crates/chassis/tests/region_layout.rs, crates/chassis/tests/shader_recipes.rs, crates/config/src/profile.rs, crates/config/src/toml.rs


## 2. `crates/config/src/lib.rs`

A 2→16 · B 5→25 · C 8→155 · D 4→4 · leak 11 · flags: A high, B high

vocabulary: `Config, SCREEN_RADIUS_PX, a_single_changed_key_deserializes_with_every_other_key_defaulted, an_empty_file_resolves_to_every_default, chassis_settings_default_round_trips_through_toml, config_default_round_trips_through_toml, default_chassis_is_annunciator, default_screen_is_default_amber, every_chassis_preset_round_trips_through_toml, every_screen_preset_round_trips_through_toml, general_settings_default_round_trips_through_toml, preset_counts_match_the_built_in_lists, raw_frame_color, raw_frame_shininess, raw_frame_size, raw_screen_radius, screen_settings_default_round_trips_through_toml`

top B files: crates/app/src/settings.rs (31: Config, raw_frame_size, raw_screen_radius); crates/app/src/window.rs (17: Config); crates/chassis/src/cabinet.rs (12: Config); crates/chassis/src/lib.rs (11: Config); crates/crt-render/tests/contracts.rs (10: Config); crates/crt-render/src/params.rs (9: raw_frame_size, Config, raw_frame_shininess); crates/chassis/src/furniture.rs (7: Config); crates/crt-render/tests/pass_graph.rs (7: Config)

leak files: crates/app/tests/bank_column.rs, crates/app/tests/channel_bank.rs, crates/app/tests/profile_cli.rs, crates/app/tests/seam_drag.rs, crates/app/tests/settings_live_reload.rs, crates/app/tests/structure_subset.rs, crates/chassis/tests/bank_frame_render.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/glyph_survival.rs, crates/crt-render/tests/pass_graph.rs


## 3. `crates/crt-render/src/pacing.rs`

A 1→5 · B 2→12 · C 3→51 · D 1→0 · leak 7 · flags: A high, B high

vocabulary: `FrameTime, Pacing, tick_by`

top B files: crates/crt-render/tests/pass_graph.rs (18: tick_by, Pacing); crates/crt-render/tests/contracts.rs (5: Pacing, tick_by); crates/app/src/window.rs (5: Pacing, FrameTime); crates/crt-render/tests/burn_in_chain.rs (4: tick_by, Pacing); crates/crt-render/src/params.rs (4: FrameTime); crates/crt-render/src/chain.rs (4: FrameTime); crates/crt-render/tests/glyph_survival.rs (3: Pacing, tick_by); crates/crt-render/src/lib.rs (2: FrameTime, Pacing)

leak files: crates/app/tests/settings_live_reload.rs, crates/app/tests/structure_subset.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/glyph_survival.rs, crates/crt-render/tests/pass_graph.rs, crates/crt-render/tests/support/mod.rs


## 4. `crates/config/src/schema.rs`

A 3→17 · B 5→23 · C 8→337 · D 1→1 · leak 11 · flags: A high, B high

vocabulary: `Annunciator, BundledFonts, ChannelDisplay, ChassisSettings, GeneralSettings, ModernRasterization, NoRasterization, PixelRasterization, ScanlineRasterization, ScreenSettings, SlideRule, SubpixelRasterization, Switchboard, SystemFonts, blinking_cursor, channel_display, chroma_color, custom_command, effects_frame_skip, font_source, glowing_line, horizontal_sync, rgb_shift, saturation_color, show_menubar, static_noise, use_custom_command, window_opacity`

top B files: crates/config/src/presets.rs (115: ScreenSettings, chroma_color, saturation_color); crates/config/src/profile.rs (33: ChassisSettings, ScreenSettings, font_source); crates/config/src/lib.rs (28: ChassisSettings, ScreenSettings, GeneralSettings); crates/crt-render/src/params.rs (24: horizontal_sync, window_opacity, rgb_shift); docs/config.md (21: Annunciator, font_source, channel_display); crates/chassis/src/shells/mod.rs (21: Annunciator, SlideRule, Switchboard); crates/chassis/src/lib.rs (20: Annunciator, SlideRule, ChannelDisplay); crates/chassis/src/furniture.rs (15: ChannelDisplay, SlideRule, channel_display)

leak files: README.md, crates/app/tests/bank_column.rs, crates/app/tests/profile_cli.rs, crates/app/tests/settings_live_reload.rs, crates/app/tests/structure_subset.rs, crates/chassis/src/displays/led/mod.rs, crates/chassis/tests/led_display.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/pass_graph.rs, docs/config.md


## 5. `crates/chassis/src/oracle.rs`

A 2→5 · B 3→29 · C 5→372 · D 3→0 · leak 24 · flags: B high

vocabulary: `ChassisMetalParams, FrameMetalParams, MetalParams, PlateMetalParams, base_color, bevel_px, chassis_color, chassis_metal, corner_radius, field_offset, field_scale, frame_metal, hash12, highlight_color, light_dir, metal_field, normalize2, plate_metal, rrect_px, seam_gain, shadow_color, size_px, vnoise, wear_amount`

top B files: crates/chassis/src/shells/slide_rule.rs (45: MetalParams, PlateMetalParams, light_dir); crates/chassis/src/shells/switchboard.rs (42: MetalParams, light_dir, ChassisMetalParams); crates/chassis/src/shells/annunciator.rs (37: MetalParams, chassis_metal, ChassisMetalParams); crates/chassis/tests/shader_recipes.rs (35: light_dir, chassis_color, field_scale); crates/chassis/tests/plate_metal.rs (33: base_color, highlight_color, shadow_color); crates/app/tests/bank_column.rs (29: plate_metal, chassis_metal, PlateMetalParams); crates/chassis/src/furniture.rs (22: plate_metal, base_color, highlight_color); crates/chassis/tests/chassis_metal.rs (20: chassis_color, chassis_metal, field_scale)

leak files: crates/app/src/column.rs, crates/app/tests/bank_column.rs, crates/chassis/src/frame.rs, crates/chassis/src/layout.rs, crates/chassis/src/lib.rs, crates/chassis/src/shaders.rs, crates/chassis/src/shells/common.rs, crates/chassis/tests/bank_frame_render.rs, crates/chassis/tests/chassis_metal.rs, crates/chassis/tests/frame_metal.rs, crates/chassis/tests/gpu_annunciator.rs, crates/chassis/tests/led_matrix.rs, crates/chassis/tests/plate_metal.rs, crates/chassis/tests/region_layout.rs, crates/chassis/tests/shader_recipes.rs, crates/chassis/tests/tape_display.rs, crates/chassis/tests/tape_label.rs, crates/crt-render/src/oracle.rs, crates/crt-render/src/params.rs, crates/crt-render/src/preset.rs, crates/crt-render/tests/bloom.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/pass_graph.rs, crates/crt-render/tests/terminal_frame.rs


## 6. `crates/crt-render/src/params.rs`

A 2→4 · B 4→12 · C 7→84 · D 2→8 · leak 9 · flags: D high (hub)

vocabulary: `Geometry, NOISE_TEXTURE_SIZE, output_height, output_width, raster_mode, screen_colors, screen_density, total_font_scaling, virtual_height, virtual_width`

top B files: crates/crt-render/tests/contracts.rs (23: Geometry, output_width, output_height); crates/app/src/window.rs (21: virtual_width, virtual_height, Geometry); crates/app/tests/structure_subset.rs (9: output_width, output_height, Geometry); crates/crt-render/tests/burn_in_chain.rs (8: Geometry, output_width, output_height); crates/crt-render/tests/pass_graph.rs (8: Geometry, output_width, output_height); crates/crt-render/tests/glyph_survival.rs (6: output_width, output_height, virtual_width); crates/chassis/src/furniture.rs (2: screen_colors); crates/term/src/fonts/sizing.rs (2: total_font_scaling)

leak files: crates/app/tests/settings_live_reload.rs, crates/app/tests/structure_subset.rs, crates/chassis/src/furniture.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/glyph_survival.rs, crates/crt-render/tests/pass_graph.rs, crates/term/src/fonts/sizing.rs, crates/xtask/src/x11.rs


## 7. `crates/tmux-cc/src/command.rs`

A 1→4 · B 3→6 · C 5→43 · D 1→2 · leak 3 · flags: A high

vocabulary: `CAPTURE_HISTORY, CapturePane, ClientSize, CursorPosition, DetachClient, HostName, ListWindowPanes, ListWindows, SEND_KEYS_CHUNK, SendKeys, a_paste_is_chunked_into_whole_commands, capture_pane, nothing_to_send_is_no_command_at_all, quote_format, quoting_protects_the_three_that_bite_and_spares_the_hash, send_keys_is_hex_and_needs_no_quoting, the_attach_pair_carries_the_references_flags_and_depth, the_bootstrap_pair_is_the_references_own_text, the_rename_sweep_and_the_layout_requery, the_short_commands, to_wire`

top B files: crates/tmux-cc/examples/record.rs (17: DetachClient, ListWindows, HostName); crates/tmux-cc/tests/live_tmux.rs (10: HostName, ListWindows, ListWindowPanes); crates/app/src/tmux.rs (8: DetachClient, HostName, ClientSize); crates/tmux-cc/src/codec.rs (6: HostName, to_wire); crates/tmux-cc/tests/transcripts.rs (1: quote_format); crates/tmux-cc/src/escape.rs (1: quote_format)

leak files: crates/tmux-cc/src/escape.rs, crates/tmux-cc/tests/live_tmux.rs, crates/tmux-cc/tests/transcripts.rs


## 8. `crates/chassis/src/displays/tape/metrics.rs`

A 1→3 · B 2→0 · C 3→0 · D 1→5 · leak 0 · flags: D high (hub)

vocabulary: `unit_width_is_the_departure_mono_m_advance_at_20px`

top B files: 

leak files: 


## 9. `crates/chassis/src/layout.rs`

A 3→15 · B 4→12 · C 6→42 · D 2→0 · leak 6 · flags: A high

vocabulary: `MINIMUM_HEIGHT, NORMALISATION_WIDTH, WindowLayout, a_hidden_chassis_gives_the_well_the_whole_window, chassis_field, min_inner_size_physical, min_inner_size_tracks_the_bank, normalized_scale_measures_the_well_not_the_window, the_chassis_field_continues_the_frame_leftwards, the_physical_hint_is_the_logical_one_scaled, the_scale_guard_survives_a_window_of_no_size, the_well_never_goes_negative, the_well_takes_what_the_bank_leaves`

top B files: crates/chassis/src/frame.rs (10: WindowLayout, chassis_field); crates/chassis/src/cabinet.rs (8: WindowLayout, min_inner_size_physical); crates/chassis/tests/bank_frame_render.rs (7: WindowLayout); crates/chassis/tests/bank_frame_geometry.rs (3: WindowLayout); crates/chassis/src/lib.rs (3: WindowLayout); crates/app/src/column.rs (3: WindowLayout, chassis_field); crates/app/src/shell.rs (2: min_inner_size_physical); crates/app/src/geometry.rs (2: MINIMUM_HEIGHT, min_inner_size_physical)

leak files: crates/app/src/geometry.rs, crates/app/src/window.rs, crates/chassis/tests/bank_frame_geometry.rs, crates/chassis/tests/bank_frame_render.rs, crates/crt-render/src/chain.rs, crates/crt-render/tests/contracts.rs


## 10. `crates/crt-burnin/src/headless.rs`

A 2→1 · B 3→22 · C 5→108 · D 2→0 · leak 21 · flags: B high, leak signature

vocabulary: `GpuError, GpuLock, OUTPUT_FORMAT, blends_float32, cast_f32, centre_index, float32_blendable, float32_filterable, frame_pixels, make_input, make_output, pipeline_cache, px_index, read_output, render_single_pass, render_single_pass_io`

top B files: crates/app/tests/bank_column.rs (28: px_index, OUTPUT_FORMAT, make_output); crates/crt-burnin/src/chain.rs (12: GpuError, frame_pixels, OUTPUT_FORMAT); crates/crt-render/tests/bloom.rs (10: px_index, render_single_pass, render_single_pass_io); crates/crt-render/tests/burn_in_chain.rs (8: make_output, OUTPUT_FORMAT, read_output); crates/chassis/tests/bank_frame_render.rs (6: render_single_pass, px_index); crates/chassis/tests/led_matrix.rs (4: render_single_pass_io, px_index); crates/term/tests/scrollback.rs (4: GpuLock); crates/app/tests/frame_stats.rs (4: GpuLock)

leak files: crates/app/tests/bank_column.rs, crates/app/tests/frame_stats.rs, crates/chassis/tests/bank_frame_render.rs, crates/chassis/tests/chassis_metal.rs, crates/chassis/tests/frame_metal.rs, crates/chassis/tests/gpu_annunciator.rs, crates/chassis/tests/led_display.rs, crates/chassis/tests/led_matrix.rs, crates/chassis/tests/plate_metal.rs, crates/chassis/tests/tape_display.rs, crates/chassis/tests/tape_label.rs, crates/crt-burnin/tests/burn_in.rs, crates/crt-burnin/tests/mount.rs, crates/crt-render/tests/bloom.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/terminal_frame.rs, crates/term/Cargo.toml, crates/term/tests/antialias.rs, crates/term/tests/pixel_properties.rs, crates/term/tests/preedit.rs, crates/term/tests/scrollback.rs


## 11. `crates/term/src/fonts/metrics.rs`

A 2→8 · B 3→10 · C 5→28 · D 1→1 · leak 2 · flags: A high, B high

vocabulary: `ScaledMetrics, TARGET_RATIO, ascent_26_6, ascent_int, char_advance_26_6, char_advance_px, char_advance_px_is_none_for_garbage_bytes, char_advance_px_matches_the_26_6_value_it_wraps, compute_base_width, descent_26_6, descent_int, family_name, height_int, hhea_ascender_descender, round_26_6, scale_26_6, scaled_metrics, scaled_metrics_for, strike_line_metrics`

top B files: crates/term/src/fonts/led.rs (7: char_advance_26_6, scaled_metrics_for, ascent_int); crates/term/src/fonts/text.rs (7: char_advance_26_6, scaled_metrics_for, ascent_int); crates/term/tests/font_parity.rs (3: scaled_metrics, height_int, ascent_int); crates/chassis/src/shells/switchboard.rs (2: scaled_metrics); crates/chassis/src/displays/led/mod.rs (2: char_advance_px, scaled_metrics); crates/chassis/src/displays/tape/metrics.rs (2: char_advance_px); crates/term/src/fonts/mod.rs (2: family_name, compute_base_width); crates/chassis/src/shells/annunciator.rs (1: scaled_metrics)

leak files: crates/term/src/fonts/system.rs, crates/term/tests/font_parity.rs


## 12. `crates/term/src/fonts/system.rs`

A 1→5 · B 2→5 · C 4→10 · D 1→1 · leak 0 · flags: A high

vocabulary: `SANS_CANDIDATES, SERIF, SERIF_CANDIDATES, SystemFace, an_excluded_family_is_not_offered, default_sans, default_serif, every_entry_points_at_a_file_that_can_be_read, families_from, monospace_families, named_face, one_family_appears_once_however_many_faces_carry_it, sans_face, source_path, the_family_name_is_the_one_the_catalogue_uses, the_list_is_one_entry_per_family_sorted`

top B files: crates/chassis/src/paint.rs (4: default_sans, default_serif); crates/chassis/src/shells/switchboard.rs (3: default_serif, default_sans); crates/chassis/src/shells/annunciator.rs (1: default_sans); crates/chassis/src/shells/slide_rule.rs (1: default_sans); crates/term/src/fonts/mod.rs (1: monospace_families)

leak files: 


## 13. `crates/term/src/lib.rs`

A 2→2 · B 5→9 · C 8→31 · D 3→19 · leak 7 · flags: D high (hub)

vocabulary: `DEFAULT_THRESHOLD, ascii_charset, build_font`

top B files: crates/term/tests/pixel_properties.rs (11: ascii_charset, DEFAULT_THRESHOLD); crates/crt-render/tests/glyph_survival.rs (4: ascii_charset, DEFAULT_THRESHOLD); crates/term/tests/scrollback.rs (4: ascii_charset, DEFAULT_THRESHOLD); crates/term/tests/preedit.rs (4: ascii_charset, DEFAULT_THRESHOLD); crates/term/tests/antialias.rs (2: build_font); crates/term/tests/system_fonts.rs (2: ascii_charset); crates/app/src/window.rs (2: build_font); crates/term/src/atlas.rs (1: DEFAULT_THRESHOLD)

leak files: crates/app/tests/size_badge.rs, crates/crt-render/tests/glyph_survival.rs, crates/term/tests/antialias.rs, crates/term/tests/pixel_properties.rs, crates/term/tests/preedit.rs, crates/term/tests/scrollback.rs, crates/term/tests/system_fonts.rs


## 14. `crates/crt-render/src/oracle.rs`

A 1→0 · B 2→11 · C 4→25 · D 2→0 · leak 11 · flags: B high, leak signature

vocabulary: `STEPS_PER_TEXEL, TerminalFrameParams, gaussian_blur_1d, rand2, terminal_frame, terminal_frame_noise`

top B files: crates/crt-render/tests/terminal_frame.rs (7: terminal_frame, rand2, TerminalFrameParams); crates/crt-render/tests/bloom.rs (4: gaussian_blur_1d); crates/crt-render/src/preset.rs (4: terminal_frame); crates/chassis/src/oracle.rs (2: terminal_frame); crates/crt-render/tests/contracts.rs (2: terminal_frame); crates/chassis/tests/chassis_metal.rs (1: terminal_frame); crates/chassis/src/shaders.rs (1: terminal_frame); crates/chassis/src/frame.rs (1: terminal_frame)

leak files: crates/chassis/src/frame.rs, crates/chassis/src/oracle.rs, crates/chassis/src/shaders.rs, crates/chassis/tests/chassis_metal.rs, crates/crt-render/src/lib.rs, crates/crt-render/src/params.rs, crates/crt-render/src/preset.rs, crates/crt-render/tests/bloom.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/pass_graph.rs, crates/crt-render/tests/terminal_frame.rs


## 15. `crates/chassis/src/displays/led/mod.rs`

A 2→6 · B 3→10 · C 5→79 · D 3→3 · leak 5 · flags: B high

vocabulary: `Colors, DEFAULT_LED_CHARACTERS, DEFAULT_LED_FONT_NAME, DOT_RADIUS, LED_DOT_PITCH, LED_PAD_CELLS, LED_SIDE_PAD_CELLS, MIN_LED_CHARACTERS, SPILL_DEAD, cell_metrics_are_at_least_one_pixel, grid_size_matches_the_defining_formula, spill_margins, spill_margins_both_come_from_height, spill_strength, spill_strength_and_glow_match_the_defining_formulas, visible_text_truncates_from_the_head, window_colors, window_colors_amber_powered_bright, window_colors_unpowered_is_darker_than_powered_dark`

top B files: crates/chassis/src/furniture.rs (20: LED_SIDE_PAD_CELLS, spill_strength, window_colors); crates/chassis/src/displays/led/metrics.rs (17: LED_DOT_PITCH, LED_PAD_CELLS, LED_SIDE_PAD_CELLS); crates/chassis/tests/metrics_homes.rs (15: LED_DOT_PITCH, LED_PAD_CELLS, LED_SIDE_PAD_CELLS); crates/chassis/tests/led_display.rs (11: spill_strength, window_colors, SPILL_DEAD); crates/chassis/src/lib.rs (5: DEFAULT_LED_FONT_NAME, LED_DOT_PITCH, MIN_LED_CHARACTERS); crates/chassis/src/shells/slide_rule.rs (5: LED_DOT_PITCH, DEFAULT_LED_FONT_NAME, spill_margins); crates/chassis/src/strip.rs (2: window_colors, spill_strength); crates/app/tests/bank_column.rs (2: window_colors)

leak files: crates/app/tests/bank_column.rs, crates/chassis/src/strip.rs, crates/chassis/tests/led_display.rs, crates/chassis/tests/metrics_homes.rs, crates/chassis/tests/tape_display.rs


## 16. `crates/chassis/src/furniture.rs`

A 3→7 · B 6→8 · C 12→36 · D 6→19 · leak 2 · flags: D high (hub)

vocabulary: `LedMatrix, Piece, Plate, TapeLabel, WELL_INSET, a_hidden_chassis_has_no_furniture, a_press_lands_in_the_window_it_was_drawn_in, a_rows_furniture_strikes_its_numeral_and_moulds_its_window, a_screw_head_is_domed_lit_and_slotted, bank_pieces, every_shell_and_kit_paints_a_bank_that_rasterises, led_grid, led_params, led_piece, strip_rect, tape_params, tape_piece, the_lamp_grid_lays_the_proven_raster_in_a_field_of_dark_ones, the_lamps_are_struck_from_the_derived_font_colour_not_the_stored_hex, the_pager_puts_its_two_keys_where_the_mock_measured_them, the_shipped_appliance_puts_a_plate_and_a_strip_per_row_on_the_casting, the_slide_rule_bolts_its_hinge_bracket_screws_to_the_casting, the_slide_rule_pagers_counter_lamps_burn_the_page_number, the_slide_rule_screws_its_rail_over_the_casting, the_switchboard_has_no_plate_and_stamps_tape, the_switchboard_lever_lies_flat_over_the_well_at_rest, the_switchboard_tape_well_composites_its_chrome`

top B files: crates/chassis/src/shells/slide_rule.rs (9: Piece, LedMatrix, led_params); crates/chassis/src/shells/mod.rs (7: Piece); crates/chassis/src/shells/switchboard.rs (7: Piece, Plate); crates/app/tests/bank_column.rs (4: LedMatrix, TapeLabel, Piece); crates/chassis/src/shaders.rs (3: led_params, led_grid, tape_params); crates/app/src/column.rs (3: LedMatrix, TapeLabel, Piece); crates/chassis/src/cabinet.rs (2: bank_pieces, Piece); crates/chassis/src/lib.rs (1: Piece)

leak files: crates/app/tests/bank_column.rs, crates/chassis/src/shaders.rs


## 17. `crates/tmux-cc/src/codec.rs`

A 2→3 · B 4→15 · C 8→94 · D 3→4 · leak 12 · flags: B high

vocabulary: `Codec, CommandId, OpenBlock, a_block_survives_arbitrary_chunk_boundaries, a_body_line_reaches_its_block_in_the_buffer_it_arrived_in, a_foreign_line_is_reported_not_swallowed, a_known_name_with_the_wrong_shape_is_malformed_not_unknown, a_line_without_its_newline_is_not_an_event_yet, a_mismatched_guard_drops_the_body_and_says_so, a_percent_line_inside_a_block_is_body_not_notification, a_reply_pairs_with_the_command_that_asked, a_solicited_block_with_nothing_pending_is_unsolicited, a_window_name_is_the_rest_of_the_line, an_empty_output_payload_is_still_an_output, an_error_block_still_pairs_and_says_so, an_unknown_notification_keeps_its_bytes, clear_pending, close_block, codec, exit_carries_a_reason_only_when_there_is_one, extended_output_splits_at_the_first_colon_and_keeps_later_ones, guard_fields, in_block, line_done, next_id, output_arrives_unescaped_and_keeps_its_spacing, parse_notification, rest_after_first_space, the_attach_burst_never_takes_a_pending_slot`

top B files: crates/app/src/tmux.rs (23: codec, CommandId, Codec); crates/tmux-cc/src/lib.rs (15: codec, Codec, CommandId); crates/tmux-cc/tests/support/mod.rs (14: codec, Codec); crates/tmux-cc/src/event.rs (10: codec, CommandId); crates/app/tests/tmux_flow.rs (6: codec); crates/tmux-cc/Cargo.toml (4: codec); crates/tmux-cc/tests/transcripts.rs (4: codec, CommandId); crates/tmux-cc/tests/live_tmux.rs (4: codec, CommandId)

leak files: crates/app/Cargo.toml, crates/app/src/window.rs, crates/app/tests/tmux_flow.rs, crates/term/src/tmux_cc.rs, crates/tmux-cc/Cargo.toml, crates/tmux-cc/examples/record.rs, crates/tmux-cc/src/command.rs, crates/tmux-cc/src/escape.rs, crates/tmux-cc/tests/live_tmux.rs, crates/tmux-cc/tests/support/mod.rs, crates/tmux-cc/tests/transcripts.rs, crates/tmux-cc/tests/transcripts/README.md


## 18. `crates/chassis/src/shells/mod.rs`

A 2→1 · B 3→3 · C 5→4 · D 3→11 · leak 2 · flags: D high (hub)

vocabulary: `plate_region, row_overhang`

top B files: crates/chassis/src/furniture.rs (2: plate_region, row_overhang); crates/chassis/src/shaders.rs (1: plate_region); crates/chassis/src/paint.rs (1: row_overhang)

leak files: crates/chassis/src/paint.rs, crates/chassis/src/shaders.rs


## 19. `crates/term/src/session.rs`

A 3→4 · B 5→27 · C 8→146 · D 4→2 · leak 23 · flags: B high

vocabulary: `INPUT_CAP, Pumped, READ_BUF, Session, SessionConfig, child_gone, control_mode_writer, drop_input_in_control_mode, expire_sync, flush_input, grid_cols, grid_rows, is_finished, is_idle, leave_control_mode, queued_input, scrollback, working_directory`

top B files: crates/term/tests/transcript.rs (31: SessionConfig, scrollback, queued_input); crates/app/src/window.rs (20: scrollback, SessionConfig, control_mode_writer); crates/term/src/tmux_pane.rs (8: Pumped, Session, scrollback); crates/app/tests/keyboard_scroll.rs (7: scrollback, SessionConfig, working_directory); crates/app/src/tmux.rs (7: scrollback, control_mode_writer, leave_control_mode); crates/term/src/lib.rs (6: scrollback, SessionConfig, INPUT_CAP); crates/app/tests/shed_notice.rs (6: SessionConfig, INPUT_CAP, working_directory); crates/app/tests/clipboard_keys.rs (5: SessionConfig, working_directory, scrollback)

leak files: crates/app/src/tmux.rs, crates/app/tests/channel_bank.rs, crates/app/tests/clipboard_keys.rs, crates/app/tests/ime.rs, crates/app/tests/keyboard_scroll.rs, crates/app/tests/pointer.rs, crates/app/tests/pointer_live_settings.rs, crates/app/tests/redraw_pacing.rs, crates/app/tests/seam_drag.rs, crates/app/tests/shed_notice.rs, crates/app/tests/tmux_flow.rs, crates/crt-render/tests/glyph_survival.rs, crates/term/Cargo.toml, crates/term/src/dcs.rs, crates/term/src/grid.rs, crates/term/src/render.rs, crates/term/src/rio_grid.rs, crates/term/src/search.rs, crates/term/src/viewport.rs, crates/term/tests/rio_grid_tests.rs, crates/term/tests/scrollback.rs, crates/term/tests/transcript.rs, crates/tmux-cc/src/command.rs


## 20. `crates/term/src/fonts/subpixel.rs`

A 1→2 · B 2→7 · C 4→36 · D 1→0 · leak 5 · flags: B high

vocabulary: `APPEND_RGB, Configs, DEFAULT_FILTER, Layout, a_conditional_match_is_not_the_default, a_strokes_left_edge_goes_blue_and_its_right_edge_goes_red_under_rgb, an_append_does_not_displace_a_value_already_at_the_front, an_unconfigured_machine_renders_grey, default_config_files, filter_row, from_fc_rgba, host_layout, is_subpixel, layout_from_files, none_and_the_vertical_layouts_all_render_grey, rgba_first_value, rgba_value, subpixel, the_filter_spreads_a_lone_stripe_without_losing_it, the_filter_weights_are_freetypes_and_conserve_coverage, the_shipped_sub_pixel_rgb_file_reads_as_rgb`

top B files: crates/term/src/fonts/text.rs (20: Layout, subpixel, is_subpixel); crates/chassis/src/paint.rs (8: subpixel, host_layout); crates/term/src/atlas.rs (3: subpixel); crates/xtask/src/compare.rs (2: subpixel); crates/term/Cargo.toml (1: subpixel); crates/term/src/fonts/raster.rs (1: subpixel); crates/term/src/fonts/mod.rs (1: subpixel)

leak files: crates/term/Cargo.toml, crates/term/src/atlas.rs, crates/term/src/fonts/mod.rs, crates/term/src/fonts/raster.rs, crates/xtask/src/compare.rs


## 21. `crates/crt-render/src/preset.rs`

A 2→2 · B 4→13 · C 6→46 · D 2→4 · leak 11 · flags: B high

vocabulary: `BURN_PASS, BloomQuality, BurnInQuality, CHASSIS_FRAME, FRAME_PASS, FrameBody, NOISE_PNG, NOISE_TEXTURE, Scale, Structure, WindowScaling, body_at, chassis_frame, filter_linear, float_framebuffer, pass_zero_is_the_block_the_mount_contract_asks_for, scale_of, the_accumulator_is_not_the_last_pass, the_first_pass_carries_the_chains_filter_for_the_terminal_grid, write_if_changed`

top B files: crates/crt-render/tests/pass_graph.rs (11: FRAME_PASS, Structure, CHASSIS_FRAME); crates/crt-burnin/MOUNT.md (8: float_framebuffer, filter_linear, pass_zero_is_the_block_the_mount_contract_asks_for); crates/crt-render/src/chain.rs (6: Structure); crates/crt-burnin/src/lib.rs (5: float_framebuffer, filter_linear); crates/crt-render/tests/contracts.rs (3: Structure); crates/crt-render/src/lib.rs (2: CHASSIS_FRAME, Structure); crates/crt-render/src/params.rs (2: WindowScaling, CHASSIS_FRAME); crates/crt-render/src/device.rs (2: float_framebuffer)

leak files: crates/app/tests/structure_subset.rs, crates/crt-burnin/MOUNT.md, crates/crt-burnin/src/lib.rs, crates/crt-burnin/tests/burn_in.rs, crates/crt-burnin/tests/mount.rs, crates/crt-render/Cargo.toml, crates/crt-render/src/device.rs, crates/crt-render/src/params.rs, crates/crt-render/tests/contracts.rs, crates/crt-render/tests/pass_graph.rs, crates/crt-render/tests/user_lut.rs


## 22. `crates/term/src/fonts/sizing.rs`

A 2→3 · B 3→13 · C 5→128 · D 2→1 · leak 10 · flags: B high

vocabulary: `ComputedFont, Floor, ResolvedFont, Round, ScalePolicy, SizingRequest, a_scalable_face_is_squeezed_freely, antialias, base_font_scaling, compute_font, dpr_only_multiplies_the_geometric_scale, dpr_scale, fallback_chain, fallback_family, floor_policy_can_render_a_quarter_smaller_than_asked, font_width_is_accepted_only_on_whole_pixel_cells, integer_scale, is_pixel_exact_width, low_resolution_face_never_changes_raster_size, platform_monospace, scalable_face_moves_raster_size_and_keeps_scale_at_one, screen_scaling, snap_font_width, texture_scale`

top B files: crates/term/tests/pixel_properties.rs (32: SizingRequest, integer_scale, ScalePolicy); crates/app/src/window.rs (28: integer_scale, ScalePolicy, SizingRequest); crates/term/tests/antialias.rs (12: SizingRequest, ScalePolicy, integer_scale); crates/crt-render/tests/glyph_survival.rs (8: SizingRequest, ScalePolicy, integer_scale); crates/term/tests/font_parity.rs (8: compute_font, screen_scaling, SizingRequest); crates/term/src/atlas.rs (8: ResolvedFont, antialias); crates/term/src/lib.rs (7: ResolvedFont, ScalePolicy, SizingRequest); crates/term/tests/system_fonts.rs (6: ScalePolicy, SizingRequest, integer_scale)

leak files: crates/app/tests/size_badge.rs, crates/chassis/src/paint.rs, crates/crt-render/tests/glyph_survival.rs, crates/term/src/render.rs, crates/term/tests/antialias.rs, crates/term/tests/font_parity.rs, crates/term/tests/pixel_properties.rs, crates/term/tests/preedit.rs, crates/term/tests/scrollback.rs, crates/term/tests/system_fonts.rs


## 23. `crates/term/src/gpu.rs`

A 2→3 · B 3→11 · C 5→38 · D 1→0 · leak 8 · flags: B high

vocabulary: `TARGET_FORMAT, Target, ascii_preview, distinct_luma_values, intermediate_channel_values, max_channel_delta, read_rgba, upscale_nearest, write_pgm`

top B files: crates/term/tests/pixel_properties.rs (11: intermediate_channel_values, upscale_nearest, distinct_luma_values); crates/term/src/render.rs (5: TARGET_FORMAT, Target, read_rgba); crates/app/tests/size_badge.rs (5: Target, read_rgba); crates/crt-render/tests/support/mod.rs (4: TARGET_FORMAT, read_rgba, Target); crates/app/src/window.rs (4: Target); crates/crt-render/tests/user_lut.rs (3: TARGET_FORMAT, read_rgba, distinct_luma_values); crates/crt-render/tests/pass_graph.rs (2: max_channel_delta); crates/crt-render/tests/glyph_survival.rs (1: read_rgba)

leak files: crates/app/src/gpu.rs, crates/app/tests/size_badge.rs, crates/crt-render/tests/glyph_survival.rs, crates/crt-render/tests/pass_graph.rs, crates/crt-render/tests/support/mod.rs, crates/crt-render/tests/user_lut.rs, crates/term/tests/antialias.rs, crates/term/tests/pixel_properties.rs


## 24. `crates/term/src/size.rs`

A 3→4 · B 4→15 · C 6→82 · D 1→0 · leak 11 · flags: B high

vocabulary: `CellSize, MIN_COLS, MIN_ROWS, TermSize, a_dpr_change_halves_the_grid_without_touching_the_window, a_window_too_small_for_one_cell_still_yields_a_usable_grid, fractional_dpr_rounds_the_cell_rather_than_truncating, grid_divides_the_window_by_the_cell, physical_cell, term_size`

top B files: crates/app/src/window.rs (23: term_size, CellSize, physical_cell); crates/term/tests/transcript.rs (20: term_size, CellSize); crates/term/src/tmux_pane.rs (9: TermSize); crates/term/src/session.rs (5: TermSize); crates/app/tests/tmux_flow.rs (4: CellSize, term_size); crates/app/tests/pointer_live_settings.rs (3: CellSize); crates/term/src/lib.rs (2: CellSize, TermSize); crates/app/tests/clipboard_keys.rs (2: CellSize)

leak files: crates/app/tests/channel_bank.rs, crates/app/tests/clipboard_keys.rs, crates/app/tests/ime.rs, crates/app/tests/keyboard_scroll.rs, crates/app/tests/pointer.rs, crates/app/tests/pointer_live_settings.rs, crates/app/tests/redraw_pacing.rs, crates/app/tests/seam_drag.rs, crates/app/tests/shed_notice.rs, crates/app/tests/tmux_flow.rs, crates/term/tests/transcript.rs


## 25. `crates/crt-burnin/src/decay.rs`

A 1→1 · B 2→8 · C 3→29 · D 1→0 · leak 7 · flags: B high

vocabulary: `DECAY_PARAM, DecayClock, MASK_PARAM, MAX_FADE_TIME, MAX_FRAME_DELTA, MIN_FADE_TIME, a_backwards_clock_decays_by_nothing, burn_in_zero_decays_fully, changing_burn_in_does_not_restart_the_ghost, decay_step, decay_step_is_dt_over_fade_time, fade_time_matches_the_recorded_endpoints, fade_time_seconds, first_tick_decays_by_nothing, long_stall_is_clamped_to_one_frame_of_decay, max_dt`

top B files: crates/crt-burnin/src/lib.rs (10: DecayClock, DECAY_PARAM, MASK_PARAM); crates/crt-burnin/tests/burn_in.rs (7: decay_step); crates/crt-render/tests/burn_in_chain.rs (4: decay_step); crates/crt-burnin/tests/mount.rs (3: decay_step); crates/crt-render/tests/contracts.rs (2: fade_time_seconds); crates/crt-render/src/lib.rs (1: DecayClock); crates/crt-render/src/params.rs (1: DecayClock); crates/crt-render/src/pacing.rs (1: DecayClock)

leak files: crates/crt-burnin/tests/burn_in.rs, crates/crt-burnin/tests/mount.rs, crates/crt-render/src/lib.rs, crates/crt-render/src/pacing.rs, crates/crt-render/src/params.rs, crates/crt-render/tests/burn_in_chain.rs, crates/crt-render/tests/contracts.rs

# Pick table — expected vs measured, with dispositions from Explain

Flags: A outside the band either way; B and D above the band only; C never flags. Band is ±1 log₃ (a factor of three). Dispositions marked "(revived)" come from an individual revival in `revivals/`; "(triage)" from the batch pass in `revivals/tail-triage.md`. Rows with no flag carry no disposition.

| module | A exp/meas | B exp/meas | D exp/meas | C exp/meas | gap A | gap B | gap D | flags | disposition |
|---|---|---|---|---|---|---|---|---|---|
| `crates/chassis/src/metrics.rs` | 3/9 | 5/33 | 2/7 | 8/348 | +1.00 | +1.72 | +1.14 | B high, D high (hub) |artefact (revived) |
| `crates/chassis/src/shells/annunciator.rs` | 1/2 | 2/30 | 5/10 | 3/114 | +0.63 | +2.46 | +0.63 | B high |artefact (revived) |
| `crates/chassis/src/shells/slide_rule.rs` | 1/2 | 2/13 | 5/16 | 3/77 | +0.63 | +1.70 | +1.06 | B high, D high (hub) |by design (triage) |
| `crates/config/src/lib.rs` | 2/16 | 5/25 | 4/4 | 8/155 | +1.89 | +1.46 | +0.00 | A high, B high |by design (triage) |
| `crates/crt-render/src/degauss.rs` | 1/4 | 2/16 | 1/0 | 3/124 | +1.26 | +1.89 | -0.63 | A high, B high |by design (revived) |
| `crates/crt-render/src/pacing.rs` | 1/5 | 2/12 | 1/0 | 3/51 | +1.46 | +1.63 | -0.63 | A high, B high |by design (triage) |
| `crates/app/src/window.rs` | 2/1 | 8/34 | 15/46 | 16/254 | -0.63 | +1.32 | +1.02 | B high, D high (hub), leak signature |by design (revived) |
| `crates/config/src/schema.rs` | 3/17 | 5/23 | 1/1 | 8/337 | +1.58 | +1.39 | +0.00 | A high, B high |by design (triage) |
| `crates/chassis/src/oracle.rs` | 2/5 | 3/29 | 3/0 | 5/372 | +0.83 | +2.07 | -1.63 | B high |by design (triage) |
| `crates/crt-render/src/params.rs` | 2/4 | 4/12 | 2/8 | 7/84 | +0.63 | +1.00 | +1.26 | D high (hub) |by design (triage) |
| `crates/term/src/atlas.rs` | 1/4 | 3/12 | 3/4 | 6/69 | +1.26 | +1.26 | +0.26 | A high, B high |by design (revived) |
| `crates/term/src/fonts/mod.rs` | 4/16 | 6/26 | 3/2 | 10/117 | +1.26 | +1.33 | -0.37 | A high, B high |by design (revived) |
| `crates/tmux-cc/src/command.rs` | 1/4 | 3/6 | 1/2 | 5/43 | +1.26 | +0.63 | +0.63 | A high |artefact (triage) |
| `crates/chassis/src/displays/tape/metrics.rs` | 1/3 | 2/0 | 1/5 | 3/0 | +1.00 | -1.26 | +1.46 | D high (hub) |by design (triage) |
| `crates/chassis/src/layout.rs` | 3/15 | 4/12 | 2/0 | 6/42 | +1.46 | +1.00 | -1.26 | A high |artefact (triage) |
| `crates/crt-burnin/src/headless.rs` | 2/1 | 3/22 | 2/0 | 5/108 | -0.63 | +1.81 | -1.26 | B high, leak signature |by design (triage) |
| `crates/term/src/fonts/metrics.rs` | 2/8 | 3/10 | 1/1 | 5/28 | +1.26 | +1.10 | +0.00 | A high, B high |artefact (triage) |
| `crates/term/src/fonts/system.rs` | 1/5 | 2/5 | 1/1 | 4/10 | +1.46 | +0.83 | +0.00 | A high |by design (triage) |
| `crates/term/src/lib.rs` | 2/2 | 5/9 | 3/19 | 8/31 | +0.00 | +0.54 | +1.68 | D high (hub) |by design (triage) |
| `crates/crt-render/src/oracle.rs` | 1/0 | 2/11 | 2/0 | 4/25 | -0.63 | +1.55 | -1.26 | B high, leak signature |by design (triage) |
| `crates/chassis/src/displays/led/mod.rs` | 2/6 | 3/10 | 3/3 | 5/79 | +1.00 | +1.10 | +0.00 | B high |artefact (triage) |
| `crates/app/src/tmux.rs` | 2/1 | 6/30 | 6/4 | 12/327 | -0.63 | +1.46 | -0.37 | B high, leak signature |artefact (revived) |
| `crates/chassis/src/furniture.rs` | 3/7 | 6/8 | 6/19 | 12/36 | +0.77 | +0.26 | +1.05 | D high (hub) |by design (triage) |
| `crates/chassis/src/shells/common.rs` | 3/5 | 4/7 | 1/3 | 7/30 | +0.46 | +0.51 | +1.00 |  |  |
| `crates/chassis/src/paint.rs` | 4/8 | 5/10 | 3/6 | 9/189 | +0.63 | +0.63 | +0.63 |  |  |
| `crates/chassis/src/shells/switchboard.rs` | 1/2 | 2/4 | 5/10 | 3/18 | +0.63 | +0.63 | +0.63 |  |  |
| `crates/term/src/fonts/led.rs` | 2/4 | 4/8 | 1/2 | 6/27 | +0.63 | +0.63 | +0.63 |  |  |
| `crates/tmux-cc/src/codec.rs` | 2/3 | 4/15 | 3/4 | 8/94 | +0.37 | +1.20 | +0.26 | B high |artefact (triage) |
| `crates/chassis/src/shells/mod.rs` | 2/1 | 3/3 | 3/11 | 5/4 | -0.63 | +0.00 | +1.18 | D high (hub) |by design (triage) |
| `crates/term/src/session.rs` | 3/4 | 5/27 | 4/2 | 8/146 | +0.26 | +1.54 | -0.63 | B high |artefact (triage) |
| `crates/term/src/fonts/subpixel.rs` | 1/2 | 2/7 | 1/0 | 4/36 | +0.63 | +1.14 | -0.63 | B high |artefact (triage) |
| `crates/crt-render/src/preset.rs` | 2/2 | 4/13 | 2/4 | 6/46 | +0.00 | +1.07 | +0.63 | B high |by design (triage) |
| `crates/term/src/fonts/sizing.rs` | 2/3 | 3/13 | 2/1 | 5/128 | +0.37 | +1.33 | -0.63 | B high |artefact (triage) |
| `crates/chassis/src/lib.rs` | 3/5 | 5/8 | 6/14 | 8/16 | +0.46 | +0.43 | +0.77 |  |  |
| `crates/term/src/cells.rs` | 2/4 | 4/8 | 2/3 | 6/60 | +0.63 | +0.63 | +0.37 |  |  |
| `crates/chassis/src/displays/tape/mod.rs` | 2/3 | 3/7 | 3/5 | 5/106 | +0.37 | +0.77 | +0.46 |  |  |
| `crates/term/src/fonts/text.rs` | 2/4 | 3/5 | 3/5 | 5/24 | +0.63 | +0.46 | +0.46 |  |  |
| `crates/term/src/grid.rs` | 3/6 | 4/11 | 1/0 | 6/78 | +0.63 | +0.92 | -0.63 |  |  |
| `crates/term/src/render.rs` | 1/2 | 4/11 | 6/5 | 8/80 | +0.63 | +0.92 | -0.17 |  |  |
| `crates/term/src/gpu.rs` | 2/3 | 3/11 | 1/0 | 5/38 | +0.37 | +1.18 | -0.63 | B high |artefact (triage) |
| `crates/term/src/hotspots.rs` | 2/1 | 3/8 | 2/1 | 5/78 | -0.63 | +0.89 | -0.63 |  |  |
| `crates/term/src/selection.rs` | 1/2 | 3/8 | 3/1 | 5/129 | +0.63 | +0.89 | -1.00 |  |  |
| `crates/app/src/settings.rs` | 3/2 | 5/10 | 4/7 | 8/87 | -0.37 | +0.63 | +0.51 |  |  |
| `crates/chassis/src/bank.rs` | 3/6 | 5/13 | 3/2 | 8/118 | +0.63 | +0.87 | -0.37 |  |  |
| `crates/crt-burnin/src/lib.rs` | 2/4 | 4/10 | 3/1 | 6/41 | +0.63 | +0.83 | -1.00 |  |  |
| `crates/term/src/size.rs` | 3/4 | 4/15 | 1/0 | 6/82 | +0.26 | +1.20 | -0.63 | B high |by design (triage) |
| `crates/tmux-cc/src/event.rs` | 2/3 | 3/5 | 1/2 | 6/147 | +0.37 | +0.46 | +0.63 |  |  |
| `crates/app/src/shell.rs` | 1/2 | 3/7 | 6/4 | 5/41 | +0.63 | +0.77 | -0.37 |  |  |
| `crates/tmux-cc/src/ids.rs` | 3/7 | 4/8 | 0/0 | 7/73 | +0.77 | +0.63 | +0.00 |  |  |
| `crates/term/src/color.rs` | 2/4 | 4/9 | 1/0 | 6/31 | +0.63 | +0.74 | -0.63 |  |  |
| `crates/term/src/fonts/raster.rs` | 1/3 | 2/3 | 1/0 | 3/5 | +1.00 | +0.37 | -0.63 |  |  |
| `crates/chassis/src/cabinet.rs` | 3/5 | 5/8 | 6/10 | 9/38 | +0.46 | +0.43 | +0.46 |  |  |
| `crates/term/src/tmux_pane.rs` | 1/2 | 3/5 | 3/4 | 5/23 | +0.63 | +0.46 | +0.26 |  |  |
| `crates/app/src/bank.rs` | 3/1 | 5/5 | 3/4 | 8/13 | -1.00 | +0.00 | +0.26 |  |  |
| `crates/config/src/structural.rs` | 2/1 | 4/2 | 1/2 | 6/22 | -0.63 | -0.63 | +0.63 |  |  |
| `crates/crt-burnin/src/decay.rs` | 1/1 | 2/8 | 1/0 | 3/29 | +0.00 | +1.26 | -0.63 | B high |by design (triage) |
| `crates/tmux-cc/src/escape.rs` | 1/2 | 3/6 | 0/0 | 5/23 | +0.63 | +0.63 | +0.00 |  |  |
| `crates/term/src/dcs.rs` | 2/4 | 4/7 | 1/0 | 6/60 | +0.63 | +0.51 | -0.63 |  |  |
| `crates/app/src/channels.rs` | 6/2 | 9/10 | 4/0 | 20/243 | -1.00 | +0.10 | -1.89 |  |  |
| `crates/chassis/src/strip.rs` | 3/5 | 4/8 | 2/2 | 6/61 | +0.46 | +0.63 | +0.00 |  |  |
| `crates/xtask/src/proc.rs` | 2/4 | 3/5 | 0/0 | 4/36 | +0.63 | +0.46 | +0.00 |  |  |
| `crates/app/src/column.rs` | 2/1 | 4/1 | 6/9 | 7/8 | -0.63 | -1.26 | +0.37 |  |  |
| `crates/app/src/gpu.rs` | 3/1 | 5/3 | 3/2 | 8/6 | -1.00 | -0.46 | -0.37 |  |  |
| `crates/app/src/lib.rs` | 1/3 | 3/0 | 3/0 | 4/0 | +1.00 | -1.63 | -1.63 |  |  |
| `crates/chassis/src/color.rs` | 6/11 | 9/14 | 1/0 | 15/116 | +0.55 | +0.40 | -0.63 |  |  |
| `crates/app/src/overlay.rs` | 1/2 | 3/4 | 2/0 | 4/32 | +0.63 | +0.26 | -1.26 |  |  |
| `crates/chassis/src/frame.rs` | 2/4 | 4/3 | 3/4 | 6/15 | +0.63 | -0.26 | +0.26 |  |  |
| `crates/config/src/presets.rs` | 3/5 | 5/8 | 1/1 | 8/21 | +0.46 | +0.43 | +0.00 |  |  |
| `crates/term/src/tmux_cc.rs` | 2/2 | 5/13 | 2/1 | 8/48 | +0.00 | +0.87 | -0.63 |  |  |
| `crates/term/src/rio_grid.rs` | 2/3 | 3/5 | 2/1 | 5/35 | +0.37 | +0.46 | -0.63 |  |  |
| `crates/term/src/viewport.rs` | 2/3 | 3/5 | 1/0 | 5/55 | +0.37 | +0.46 | -0.63 |  |  |
| `crates/xtask/src/x11.rs` | 2/2 | 3/7 | 1/1 | 4/40 | +0.00 | +0.77 | +0.00 |  |  |
| `crates/app/src/badge.rs` | 2/1 | 4/2 | 4/1 | 6/13 | -0.63 | -0.63 | -1.26 |  |  |
| `crates/app/src/chord.rs` | 2/1 | 4/1 | 2/0 | 6/9 | -0.63 | -1.26 | -1.26 |  |  |
| `crates/app/src/cli.rs` | 2/1 | 4/1 | 3/1 | 6/8 | -0.63 | -1.26 | -1.00 |  |  |
| `crates/app/src/frame_stats.rs` | 1/2 | 3/3 | 2/0 | 5/51 | +0.63 | +0.00 | -1.26 |  |  |
| `crates/app/src/input.rs` | 2/1 | 4/2 | 3/1 | 10/21 | -0.63 | -0.63 | -1.00 |  |  |
| `crates/app/src/instance.rs` | 1/2 | 3/1 | 2/0 | 5/1 | +0.63 | -1.00 | -1.26 |  |  |
| `crates/app/src/paths.rs` | 4/2 | 5/3 | 1/0 | 8/3 | -0.63 | -0.46 | -0.63 |  |  |
| `crates/chassis/src/displays/led/metrics.rs` | 1/1 | 2/0 | 1/2 | 3/0 | +0.00 | -1.26 | +0.63 |  |  |
| `crates/chassis/src/displays/raster.rs` | 2/1 | 3/3 | 1/1 | 4/5 | -0.63 | +0.00 | +0.00 |  |  |
| `crates/chassis/src/js.rs` | 8/4 | 8/2 | 0/0 | 18/2 | -0.63 | -1.26 | +0.00 |  |  |
| `crates/config/src/profile.rs` | 3/2 | 6/4 | 3/4 | 10/27 | -0.37 | -0.37 | +0.26 |  |  |
| `crates/crt-burnin/src/chain.rs` | 1/0 | 2/2 | 2/2 | 3/6 | -0.63 | +0.00 | +0.00 |  |  |
| `crates/term/src/pointer.rs` | 2/3 | 3/4 | 2/0 | 5/154 | +0.37 | +0.26 | -1.26 |  |  |
| `crates/xtask/src/compare.rs` | 2/1 | 3/3 | 2/0 | 5/8 | -0.63 | +0.00 | -1.26 |  |  |
| `crates/xtask/src/mask.rs` | 2/1 | 3/0 | 1/0 | 4/0 | -0.63 | -1.63 | -0.63 |  |  |
| `crates/xtask/src/snap.rs` | 2/1 | 3/2 | 3/2 | 5/3 | -0.63 | -0.37 | -0.37 |  |  |
| `crates/chassis/src/seam.rs` | 2/3 | 4/5 | 3/3 | 6/21 | +0.37 | +0.20 | +0.00 |  |  |
| `crates/crt-render/src/chain.rs` | 2/2 | 4/6 | 4/5 | 6/39 | +0.00 | +0.37 | +0.20 |  |  |
| `crates/term/src/distortion.rs` | 2/3 | 4/5 | 1/0 | 6/24 | +0.37 | +0.20 | -0.63 |  |  |
| `crates/config/src/toml.rs` | 3/5 | 6/6 | 4/3 | 10/24 | +0.46 | +0.00 | -0.26 |  |  |
| `crates/app/src/crashlog.rs` | 1/1 | 2/3 | 2/0 | 3/9 | +0.00 | +0.37 | -1.26 |  |  |
| `crates/app/src/geometry.rs` | 3/2 | 5/2 | 1/0 | 8/2 | -0.37 | -0.83 | -0.63 |  |  |
| `crates/term/src/search.rs` | 1/1 | 2/3 | 2/1 | 3/12 | +0.00 | +0.37 | -0.63 |  |  |
| `crates/app/src/main.rs` | 0/0 | 2/0 | 10/13 | 3/0 | +0.00 | -1.26 | +0.24 |  |  |
| `crates/app/src/clipboard.rs` | 1/1 | 2/1 | 1/0 | 3/1 | +0.00 | -0.63 | -0.63 |  |  |
| `crates/app/src/mouse.rs` | 1/1 | 2/1 | 2/1 | 3/4 | +0.00 | -0.63 | -0.63 |  |  |
| `crates/chassis/src/shaders.rs` | 2/2 | 3/3 | 0/0 | 4/8 | +0.00 | +0.00 | +0.00 |  |  |
| `crates/config/src/watch.rs` | 1/1 | 3/2 | 3/1 | 5/10 | +0.00 | -0.37 | -1.00 |  |  |
| `crates/crt-render/src/device.rs` | 1/1 | 2/0 | 1/0 | 3/0 | +0.00 | -1.26 | -0.63 |  |  |
| `crates/term/examples/led_diff.rs` | 0/0 | 1/0 | 2/2 | 2/0 | +0.00 | -0.63 | +0.00 |  |  |
| `crates/term/src/bin/esctest_harness.rs` | 0/0 | 1/1 | 5/0 | 2/1 | +0.00 | +0.00 | -2.10 |  |  |
| `crates/tmux-cc/examples/record.rs` | 0/0 | 1/0 | 3/2 | 2/0 | +0.00 | -0.63 | -0.37 |  |  |
| `crates/xtask/src/fanout.rs` | 1/1 | 2/1 | 1/0 | 3/5 | +0.00 | -0.63 | -0.63 |  |  |
| `crates/xtask/src/install.rs` | 1/1 | 3/1 | 4/1 | 5/3 | +0.00 | -1.00 | -1.26 |  |  |
| `crates/xtask/src/main.rs` | 0/0 | 2/0 | 7/6 | 3/0 | +0.00 | -1.26 | -0.14 |  |  |
| `crates/xtask/src/verify.rs` | 1/1 | 3/1 | 5/2 | 5/1 | +0.00 | -1.00 | -0.83 |  |  |

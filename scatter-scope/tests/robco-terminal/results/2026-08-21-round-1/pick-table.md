# Pick table

Gap is log3(measured / expected), expected = median of three blind estimates. Inside +-1 (a factor of three) is agreement; outside is a flag in either direction. `out` is the number of other modules this one draws types from, a density figure reported beside the flag, not picked on. `sig` marks the leak signature: low on A and high on B at once.

C is reported but not picked on: the estimators under-guess sites by a factor of 4.5 at the median, and only a third of modules land inside the band, so C flags two thirds of the table and carries nothing (see the calibration note in report.md).

| module | eA | mA | gap A | eB | mB | gap B | eC | mC | leak | out | flag | sig |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `crates/config/src/lib.rs` | 1 | 16 | +2.52 | 3 | 31 | +2.13 | 8 | 231 | 15 | 4 | A high B high |  |
| `crates/config/src/schema.rs` | 2 | 17 | +1.95 | 4 | 23 | +1.59 | 7 | 324 | 11 | 1 | A high B high |  |
| `crates/chassis/src/shaders.rs` | 1 | 2 | +0.63 | 2 | 39 | +2.70 | 3 | 102 | 37 | 0 | B high |  |
| `crates/chassis/src/oracle.rs` | 1 | 5 | +1.46 | 4 | 19 | +1.42 | 9 | 269 | 14 | 0 | A high B high |  |
| `crates/crt-render/src/pacing.rs` | 1 | 5 | +1.46 | 3 | 12 | +1.26 | 6 | 33 | 7 | 0 | A high B high |  |
| `crates/chassis/src/displays/tape/metrics.rs` | 1 | 3 | +1.00 | 3 | 0 | -1.63 | 4 | 0 | 0 | 5 | B low |  |
| `crates/term/src/fonts/mod.rs` | 4 | 16 | +1.26 | 7 | 26 | +1.19 | 12 | 117 | 10 | 2 | A high B high |  |
| `crates/crt-render/src/degauss.rs` | 1 | 4 | +1.26 | 3 | 11 | +1.18 | 6 | 79 | 7 | 0 | A high B high |  |
| `crates/term/src/cells.rs` | 2 | 4 | +0.63 | 5 | 35 | +1.77 | 8 | 194 | 31 | 3 | B high |  |
| `crates/crt-burnin/src/lib.rs` | 1 | 4 | +1.26 | 3 | 10 | +1.10 | 4 | 38 | 7 | 1 | A high B high |  |
| `crates/chassis/src/lib.rs` | 1 | 5 | +1.46 | 3 | 8 | +0.89 | 8 | 16 | 4 | 14 | A high |  |
| `crates/tmux-cc/src/ids.rs` | 2 | 7 | +1.14 | 4 | 14 | +1.14 | 8 | 145 | 7 | 0 | A high B high |  |
| `crates/chassis/src/layout.rs` | 3 | 15 | +1.46 | 5 | 12 | +0.80 | 9 | 42 | 6 | 0 | A high |  |
| `crates/term/src/atlas.rs` | 1 | 4 | +1.26 | 4 | 12 | +1.00 | 8 | 69 | 8 | 4 | A high |  |
| `crates/app/src/tmux.rs` | 3 | 1 | -1.00 | 8 | 30 | +1.20 | 16 | 326 | 29 | 4 | B high |  |
| `crates/term/src/fonts/led.rs` | 1 | 4 | +1.26 | 3 | 8 | +0.89 | 5 | 27 | 4 | 2 | A high |  |
| `crates/app/src/column.rs` | 2 | 1 | -0.63 | 5 | 1 | -1.46 | 11 | 8 | 1 | 9 | B low |  |
| `crates/app/src/geometry.rs` | 5 | 2 | -0.83 | 8 | 2 | -1.26 | 13 | 2 | 0 | 0 | B low |  |
| `crates/chassis/src/metrics.rs` | 3 | 9 | +1.00 | 6 | 18 | +1.00 | 12 | 258 | 9 | 7 | - |  |
| `crates/term/src/fonts/sizing.rs` | 1 | 3 | +1.00 | 4 | 12 | +1.00 | 8 | 114 | 9 | 1 | - |  |
| `crates/term/src/gpu.rs` | 1 | 3 | +1.00 | 3 | 9 | +1.00 | 5 | 30 | 8 | 0 | - |  |
| `crates/term/src/tmux_cc.rs` | 1 | 2 | +0.63 | 3 | 13 | +1.33 | 5 | 48 | 11 | 1 | B high |  |
| `crates/term/src/size.rs` | 2 | 4 | +0.63 | 5 | 21 | +1.31 | 8 | 160 | 17 | 0 | B high |  |
| `crates/term/src/fonts/system.rs` | 1 | 5 | +1.46 | 3 | 5 | +0.46 | 5 | 10 | 0 | 1 | A high |  |
| `crates/app/src/badge.rs` | 2 | 1 | -0.63 | 4 | 1 | -1.26 | 6 | 2 | 1 | 1 | B low |  |
| `crates/app/src/chord.rs` | 2 | 1 | -0.63 | 4 | 1 | -1.26 | 8 | 4 | 0 | 0 | B low |  |
| `crates/tmux-cc/src/command.rs` | 1 | 4 | +1.26 | 3 | 6 | +0.63 | 5 | 43 | 3 | 2 | A high |  |
| `crates/chassis/src/displays/led/mod.rs` | 2 | 6 | +1.00 | 4 | 10 | +0.83 | 7 | 79 | 5 | 3 | - |  |
| `crates/crt-render/src/params.rs` | 2 | 4 | +0.63 | 4 | 15 | +1.20 | 8 | 106 | 11 | 8 | B high |  |
| `crates/crt-burnin/src/headless.rs` | 1 | 1 | +0.00 | 3 | 22 | +1.81 | 7 | 108 | 21 | 0 | B high |  |
| `crates/term/src/color.rs` | 3 | 4 | +0.26 | 5 | 1 | -1.46 | 11 | 1 | 0 | 0 | B low |  |
| `crates/chassis/src/displays/led/metrics.rs` | 1 | 1 | +0.00 | 3 | 0 | -1.63 | 4 | 0 | 0 | 2 | B low |  |
| `crates/crt-render/src/device.rs` | 1 | 1 | +0.00 | 3 | 0 | -1.63 | 4 | 0 | 0 | 0 | B low |  |
| `crates/term/src/lib.rs` | 1 | 2 | +0.63 | 3 | 9 | +1.00 | 8 | 31 | 7 | 19 | - |  |
| `crates/xtask/src/mask.rs` | 1 | 1 | +0.00 | 3 | 0 | -1.63 | 5 | 0 | 0 | 0 | B low |  |
| `crates/term/src/session.rs` | 3 | 4 | +0.26 | 5 | 20 | +1.26 | 10 | 94 | 17 | 2 | B high |  |
| `crates/chassis/src/strip.rs` | 2 | 5 | +0.83 | 4 | 8 | +0.63 | 8 | 61 | 3 | 2 | - |  |
| `crates/config/src/presets.rs` | 2 | 5 | +0.83 | 4 | 8 | +0.63 | 8 | 21 | 3 | 1 | - |  |
| `crates/term/src/rio_grid.rs` | 1 | 3 | +1.00 | 3 | 5 | +0.46 | 5 | 35 | 2 | 1 | - |  |
| `crates/term/src/viewport.rs` | 1 | 3 | +1.00 | 3 | 5 | +0.46 | 7 | 55 | 2 | 0 | - |  |
| `crates/tmux-cc/src/event.rs` | 1 | 3 | +1.00 | 3 | 5 | +0.46 | 5 | 56 | 2 | 2 | - |  |
| `crates/chassis/src/shells/slide_rule.rs` | 1 | 2 | +0.63 | 3 | 7 | +0.77 | 4 | 20 | 5 | 16 | - |  |
| `crates/tmux-cc/src/codec.rs` | 1 | 3 | +1.00 | 4 | 6 | +0.37 | 9 | 24 | 3 | 4 | - |  |
| `crates/config/src/toml.rs` | 3 | 5 | +0.46 | 6 | 16 | +0.89 | 11 | 159 | 11 | 3 | - |  |
| `crates/term/src/fonts/metrics.rs` | 3 | 8 | +0.89 | 6 | 10 | +0.46 | 10 | 28 | 2 | 1 | - |  |
| `crates/term/src/search.rs` | 1 | 1 | +0.00 | 3 | 13 | +1.33 | 5 | 47 | 12 | 1 | B high |  |
| `crates/app/src/window.rs` | 1 | 1 | +0.00 | 6 | 25 | +1.30 | 18 | 217 | 24 | 46 | B high |  |
| `crates/app/src/instance.rs` | 2 | 2 | +0.00 | 4 | 1 | -1.26 | 8 | 1 | 0 | 0 | B low |  |
| `crates/tmux-cc/src/escape.rs` | 1 | 2 | +0.63 | 3 | 6 | +0.63 | 5 | 23 | 4 | 0 | - |  |
| `crates/term/src/grid.rs` | 3 | 6 | +0.63 | 6 | 11 | +0.55 | 12 | 76 | 5 | 0 | - |  |
| `crates/app/src/bank.rs` | 3 | 1 | -1.00 | 6 | 5 | -0.17 | 11 | 13 | 4 | 4 | - |  |
| `crates/config/src/profile.rs` | 3 | 2 | -0.37 | 7 | 3 | -0.77 | 12 | 10 | 2 | 4 | - |  |
| `crates/term/src/dcs.rs` | 2 | 4 | +0.63 | 4 | 7 | +0.51 | 8 | 60 | 3 | 0 | - |  |
| `crates/term/src/fonts/subpixel.rs` | 1 | 2 | +0.63 | 4 | 7 | +0.51 | 8 | 26 | 5 | 0 | - |  |
| `crates/xtask/src/proc.rs` | 2 | 4 | +0.63 | 3 | 5 | +0.46 | 7 | 36 | 1 | 0 | - |  |
| `crates/app/src/clipboard.rs` | 1 | 1 | +0.00 | 3 | 1 | -1.00 | 4 | 1 | 0 | 0 | - |  |
| `crates/chassis/src/cabinet.rs` | 2 | 5 | +0.83 | 5 | 6 | +0.17 | 10 | 14 | 4 | 10 | - |  |
| `crates/crt-burnin/src/chain.rs` | 1 | 0 | -0.63 | 3 | 2 | -0.37 | 5 | 6 | 2 | 2 | - |  |
| `crates/crt-render/src/oracle.rs` | 1 | 0 | -0.63 | 3 | 2 | -0.37 | 7 | 6 | 2 | 0 | - |  |
| `crates/term/src/fonts/raster.rs` | 1 | 3 | +1.00 | 3 | 3 | +0.00 | 5 | 5 | 0 | 0 | - |  |
| `crates/term/src/pointer.rs` | 2 | 3 | +0.37 | 4 | 2 | -0.63 | 8 | 42 | 1 | 0 | - |  |
| `crates/term/src/render.rs` | 2 | 2 | +0.00 | 4 | 12 | +1.00 | 10 | 84 | 10 | 5 | - |  |
| `crates/term/src/tmux_pane.rs` | 1 | 2 | +0.63 | 3 | 2 | -0.37 | 7 | 12 | 0 | 4 | - |  |
| `crates/xtask/src/fanout.rs` | 1 | 1 | +0.00 | 3 | 1 | -1.00 | 5 | 5 | 0 | 0 | - |  |
| `crates/xtask/src/install.rs` | 1 | 1 | +0.00 | 3 | 1 | -1.00 | 5 | 3 | 0 | 1 | - |  |
| `crates/xtask/src/verify.rs` | 1 | 1 | +0.00 | 3 | 1 | -1.00 | 5 | 1 | 0 | 2 | - |  |
| `crates/chassis/src/shells/common.rs` | 3 | 5 | +0.46 | 4 | 7 | +0.51 | 10 | 30 | 2 | 3 | - |  |
| `crates/app/src/channels.rs` | 5 | 2 | -0.83 | 9 | 8 | -0.11 | 19 | 210 | 6 | 0 | - |  |
| `crates/chassis/src/bank.rs` | 4 | 6 | +0.37 | 7 | 13 | +0.56 | 11 | 118 | 7 | 2 | - |  |
| `crates/app/src/crashlog.rs` | 1 | 1 | +0.00 | 4 | 11 | +0.92 | 6 | 20 | 10 | 0 | - |  |
| `crates/chassis/src/shells/annunciator.rs` | 1 | 2 | +0.63 | 3 | 4 | +0.26 | 4 | 18 | 3 | 10 | - |  |
| `crates/chassis/src/shells/switchboard.rs` | 1 | 2 | +0.63 | 3 | 4 | +0.26 | 4 | 18 | 3 | 10 | - |  |
| `crates/crt-burnin/src/decay.rs` | 1 | 1 | +0.00 | 3 | 8 | +0.89 | 5 | 29 | 7 | 0 | - |  |
| `crates/term/src/hotspots.rs` | 1 | 1 | +0.00 | 3 | 8 | +0.89 | 5 | 78 | 7 | 1 | - |  |
| `crates/chassis/src/displays/tape/mod.rs` | 2 | 3 | +0.37 | 4 | 7 | +0.51 | 7 | 106 | 4 | 5 | - |  |
| `crates/app/src/settings.rs` | 3 | 2 | -0.37 | 6 | 10 | +0.46 | 12 | 87 | 8 | 7 | - |  |
| `crates/crt-render/src/chain.rs` | 1 | 2 | +0.63 | 4 | 5 | +0.20 | 10 | 25 | 4 | 5 | - |  |
| `crates/term/src/distortion.rs` | 2 | 3 | +0.63 | 4 | 5 | +0.20 | 8 | 23 | 2 | 0 | - |  |
| `crates/term/src/fonts/text.rs` | 2 | 4 | +0.63 | 4 | 5 | +0.20 | 9 | 13 | 1 | 5 | - |  |
| `crates/app/src/mouse.rs` | 1 | 1 | +0.00 | 3 | 7 | +0.77 | 4 | 56 | 6 | 1 | - |  |
| `crates/xtask/src/x11.rs` | 2 | 2 | +0.00 | 3 | 7 | +0.77 | 7 | 40 | 5 | 1 | - |  |
| `crates/crt-render/src/preset.rs` | 2 | 2 | +0.00 | 4 | 9 | +0.74 | 8 | 29 | 8 | 4 | - |  |
| `crates/chassis/src/frame.rs` | 3 | 4 | +0.26 | 5 | 3 | -0.46 | 9 | 15 | 1 | 4 | - |  |
| `crates/chassis/src/furniture.rs` | 4 | 7 | +0.51 | 6 | 5 | -0.17 | 15 | 14 | 2 | 19 | - |  |
| `crates/app/src/frame_stats.rs` | 1 | 2 | +0.63 | 3 | 3 | +0.00 | 5 | 44 | 1 | 0 | - |  |
| `crates/chassis/src/displays/raster.rs` | 2 | 1 | -0.63 | 3 | 3 | +0.00 | 6 | 5 | 2 | 1 | - |  |
| `crates/term/src/selection.rs` | 2 | 2 | +0.00 | 4 | 8 | +0.63 | 8 | 124 | 6 | 1 | - |  |
| `crates/xtask/src/main.rs` | 0 | 0 | +0.00 | 1 | 0 | -0.63 | 2 | 0 | 0 | 6 | - |  |
| `crates/chassis/src/seam.rs` | 2 | 3 | +0.37 | 4 | 5 | +0.20 | 7 | 20 | 2 | 3 | - |  |
| `crates/chassis/src/color.rs` | 7 | 11 | +0.41 | 12 | 14 | +0.14 | 25 | 116 | 4 | 0 | - |  |
| `crates/app/src/shell.rs` | 3 | 2 | -0.37 | 6 | 7 | +0.14 | 10 | 41 | 5 | 4 | - |  |
| `crates/chassis/src/js.rs` | 3 | 4 | +0.26 | 5 | 6 | +0.17 | 10 | 15 | 2 | 0 | - |  |
| `crates/chassis/src/paint.rs` | 5 | 8 | +0.43 | 9 | 9 | +0.00 | 16 | 164 | 2 | 6 | - |  |
| `crates/config/src/structural.rs` | 1 | 1 | +0.00 | 3 | 2 | -0.37 | 5 | 15 | 1 | 2 | - |  |
| `crates/config/src/watch.rs` | 1 | 1 | +0.00 | 3 | 2 | -0.37 | 5 | 10 | 1 | 1 | - |  |
| `crates/term/src/bin/esctest_harness.rs` | 0 | 0 | +0.00 | 2 | 3 | +0.37 | 2 | 4 | 3 | 0 | - |  |
| `crates/xtask/src/snap.rs` | 1 | 1 | +0.00 | 3 | 2 | -0.37 | 5 | 3 | 1 | 2 | - |  |
| `crates/app/src/cli.rs` | 1 | 1 | +0.00 | 4 | 3 | -0.26 | 7 | 9 | 2 | 1 | - |  |
| `crates/app/src/paths.rs` | 2 | 2 | +0.00 | 4 | 3 | -0.26 | 8 | 3 | 1 | 0 | - |  |
| `crates/app/src/input.rs` | 1 | 1 | +0.00 | 5 | 6 | +0.17 | 11 | 62 | 5 | 1 | - |  |
| `crates/app/src/gpu.rs` | 1 | 1 | +0.00 | 3 | 3 | +0.00 | 5 | 6 | 2 | 2 | - |  |
| `crates/app/src/overlay.rs` | 2 | 2 | +0.00 | 4 | 4 | +0.00 | 8 | 29 | 2 | 0 | - |  |
| `crates/chassis/src/shells/mod.rs` | 1 | 1 | +0.00 | 3 | 3 | +0.00 | 5 | 4 | 2 | 11 | - |  |
| `crates/xtask/src/compare.rs` | 1 | 1 | +0.00 | 3 | 3 | +0.00 | 6 | 7 | 2 | 0 | - |  |

| module | A exp/meas | B exp/meas | D exp/meas | C exp/meas | gap A | gap B | gap D | flags | disposition |
|---|---|---|---|---|---|---|---|---|---|
| `crates/chassis/src/oracle.rs` | 1/5 | 3/29 | 3/0 | 6/372 | +1.46 | +2.07 | -1.63 | A high, B high | by design (revival) |
| `crates/chassis/src/metrics.rs` | 4/9 | 6/33 | 2/7 | 10/348 | +0.74 | +1.55 | +1.14 | B high, D high (hub) | by design (revival) |
| `crates/crt-render/src/params.rs` | 3/4 | 5/38 | 2/8 | 9/380 | +0.26 | +1.85 | +1.26 | B high, D high (hub) | artefact (revival): 361/380 sites are the bare word `params` |
| `crates/chassis/src/shells/annunciator.rs` | 1/2 | 3/30 | 6/10 | 5/114 | +0.63 | +2.10 | +0.46 | B high | by design (triage) |
| `crates/config/src/schema.rs` | 3/17 | 5/23 | 1/1 | 10/348 | +1.58 | +1.39 | +0.00 | A high, B high | by design (triage) |
| `crates/chassis/src/shells/slide_rule.rs` | 1/2 | 3/13 | 6/16 | 6/77 | +0.63 | +1.33 | +0.89 | B high | by design (triage) |
| `crates/term/src/atlas.rs` | 1/4 | 3/12 | 3/4 | 6/69 | +1.26 | +1.26 | +0.26 | A high, B high | by design (triage) |
| `crates/term/src/fonts/mod.rs` | 4/16 | 6/27 | 4/2 | 11/125 | +1.26 | +1.37 | -0.63 | A high, B high | by design (triage) |
| `crates/tmux-cc/src/command.rs` | 1/4 | 3/6 | 1/2 | 6/43 | +1.26 | +0.63 | +0.63 | A high | by design (triage) |
| `crates/term/src/gpu.rs` | 1/3 | 3/14 | 2/0 | 5/50 | +1.00 | +1.40 | -1.26 | B high | mixed (triage) |
| `crates/app/src/channels.rs` | 8/2 | 14/44 | 6/0 | 35/306 | -1.26 | +1.04 | -2.26 | A low, B high, leak signature | artefact (revival): `Nothing` in 42 of 44 B files; but see report finding 4 |
| `crates/chassis/src/furniture.rs` | 3/7 | 6/10 | 6/19 | 14/55 | +0.77 | +0.46 | +1.05 | D high (hub) | by design (triage) |
| `crates/chassis/src/layout.rs` | 3/15 | 5/12 | 3/0 | 9/42 | +1.46 | +0.80 | -1.63 | A high | by design (triage) |
| `crates/chassis/src/lib.rs` | 2/5 | 5/8 | 5/14 | 8/16 | +0.83 | +0.43 | +0.94 |  |  |
| `crates/crt-burnin/src/headless.rs` | 2/1 | 4/22 | 2/0 | 6/108 | -0.63 | +1.55 | -1.26 | B high, leak signature | by design (triage): test fixture, A=27 with tests |
| `crates/term/src/lib.rs` | 6/2 | 6/9 | 8/19 | 12/31 | -1.00 | +0.37 | +0.79 |  |  |
| `crates/app/src/window.rs` | 1/1 | 10/34 | 15/46 | 25/254 | +0.00 | +1.11 | +1.02 | B high, D high (hub) | by design (revival): orchestrator hub |
| `crates/config/src/lib.rs` | 6/16 | 8/31 | 4/4 | 14/231 | +0.89 | +1.23 | +0.00 | B high | by design (triage) |
| `crates/crt-render/src/pacing.rs` | 2/5 | 3/12 | 1/0 | 5/62 | +0.83 | +1.26 | -0.63 | B high | artefact-leaning (triage) |
| `crates/chassis/src/displays/tape/mod.rs` | 1/3 | 3/7 | 4/5 | 6/106 | +1.00 | +0.77 | +0.20 |  |  |
| `crates/term/src/viewport.rs` | 3/3 | 4/33 | 1/0 | 7/280 | +0.00 | +1.92 | -0.63 | B high | artefact (revival): 230/280 sites are the stem, mostly homonyms |
| `crates/crt-render/src/degauss.rs` | 2/4 | 4/16 | 1/0 | 6/124 | +0.63 | +1.26 | -0.63 | B high | by design (triage) |
| `crates/app/src/tmux.rs` | 2/1 | 8/31 | 6/4 | 18/328 | -0.63 | +1.23 | -0.37 | B high, leak signature | artefact on the spread; one carrier scattered (report finding 4) |
| `crates/chassis/src/displays/led/mod.rs` | 2/6 | 4/10 | 4/3 | 6/80 | +1.00 | +0.83 | -0.26 |  |  |
| `crates/chassis/src/displays/tape/metrics.rs` | 2/3 | 3/0 | 1/5 | 5/0 | +0.37 | -1.63 | +1.46 | D high (hub) | by design (triage) |
| `crates/chassis/src/shells/mod.rs` | 2/1 | 4/3 | 3/11 | 6/4 | -0.63 | -0.26 | +1.18 | D high (hub) | by design (triage) |
| `crates/crt-render/src/oracle.rs` | 1/0 | 3/11 | 2/0 | 5/25 | -0.63 | +1.18 | -1.26 | B high, leak signature | by design (triage): golden-reference generator, A=0 on purpose |
| `crates/term/src/session.rs` | 3/4 | 6/31 | 5/2 | 12/178 | +0.26 | +1.49 | -0.83 | B high | by design (triage) |
| `crates/crt-render/src/preset.rs` | 2/2 | 4/18 | 3/4 | 8/61 | +0.00 | +1.37 | +0.26 | B high | artefact-leaning (triage) |
| `crates/config/src/toml.rs` | 3/5 | 7/25 | 4/3 | 13/172 | +0.46 | +1.16 | -0.26 | B high | by design (triage) |
| `crates/crt-render/src/chain.rs` | 2/2 | 4/19 | 4/5 | 8/75 | +0.00 | +1.42 | +0.20 | B high | artefact (triage): capitalised-English words carry 50/75 |
| `crates/term/src/fonts/text.rs` | 2/4 | 4/7 | 3/5 | 8/32 | +0.63 | +0.51 | +0.46 |  |  |
| `crates/crt-burnin/src/lib.rs` | 2/4 | 4/11 | 3/1 | 8/45 | +0.63 | +0.92 | -1.00 |  |  |
| `crates/chassis/src/paint.rs` | 6/8 | 7/14 | 3/6 | 15/215 | +0.26 | +0.63 | +0.63 |  |  |
| `crates/term/src/fonts/led.rs` | 3/4 | 4/8 | 1/2 | 7/27 | +0.26 | +0.63 | +0.63 |  |  |
| `crates/term/src/fonts/metrics.rs` | 3/8 | 5/10 | 1/1 | 9/28 | +0.89 | +0.63 | +0.00 |  |  |
| `crates/term/src/fonts/subpixel.rs` | 1/2 | 3/8 | 2/0 | 6/40 | +0.63 | +0.89 | -1.26 |  |  |
| `crates/term/src/grid.rs` | 3/6 | 5/13 | 2/0 | 10/80 | +0.63 | +0.87 | -1.26 |  |  |
| `crates/config/src/structural.rs` | 2/1 | 4/5 | 1/2 | 7/31 | -0.63 | +0.20 | +0.63 |  |  |
| `crates/tmux-cc/src/ids.rs` | 3/7 | 4/8 | 0/0 | 8/73 | +0.77 | +0.63 | +0.00 |  |  |
| `crates/term/src/color.rs` | 2/4 | 4/9 | 1/0 | 8/34 | +0.63 | +0.74 | -0.63 |  |  |
| `crates/tmux-cc/src/codec.rs` | 2/3 | 5/15 | 4/4 | 12/94 | +0.37 | +1.00 | +0.00 |  |  |
| `crates/chassis/src/shells/switchboard.rs` | 1/2 | 3/4 | 6/10 | 6/18 | +0.63 | +0.26 | +0.46 |  |  |
| `crates/chassis/src/shells/common.rs` | 3/5 | 4/7 | 2/3 | 8/30 | +0.46 | +0.51 | +0.37 |  |  |
| `crates/chassis/src/bank.rs` | 3/6 | 6/13 | 4/2 | 12/118 | +0.63 | +0.70 | -0.63 |  |  |
| `crates/app/src/settings.rs` | 3/2 | 5/10 | 5/7 | 10/87 | -0.37 | +0.63 | +0.31 |  |  |
| `crates/app/src/frame_stats.rs` | 1/2 | 3/6 | 3/0 | 6/80 | +0.63 | +0.63 | -1.63 |  |  |
| `crates/chassis/src/displays/led/metrics.rs` | 2/1 | 3/0 | 1/2 | 5/0 | -0.63 | -1.63 | +0.63 |  |  |
| `crates/crt-burnin/src/decay.rs` | 1/1 | 2/8 | 1/0 | 4/29 | +0.00 | +1.26 | -0.63 | B high | by design (triage) |
| `crates/term/src/cells.rs` | 2/4 | 4/8 | 3/3 | 8/60 | +0.63 | +0.63 | +0.00 |  |  |
| `crates/term/src/hotspots.rs` | 2/1 | 4/8 | 2/1 | 6/79 | -0.63 | +0.63 | -0.63 |  |  |
| `crates/term/src/size.rs` | 3/4 | 5/15 | 1/0 | 9/82 | +0.26 | +1.00 | -0.63 |  |  |
| `crates/term/src/fonts/sizing.rs` | 3/3 | 4/15 | 2/1 | 8/136 | +0.00 | +1.20 | -0.63 | B high | by design (triage) |
| `crates/term/src/render.rs` | 1/2 | 6/11 | 8/5 | 12/80 | +0.63 | +0.55 | -0.43 |  |  |
| `crates/app/src/shell.rs` | 1/2 | 4/7 | 6/4 | 8/41 | +0.63 | +0.51 | -0.37 |  |  |
| `crates/term/src/dcs.rs` | 2/4 | 4/7 | 2/0 | 8/60 | +0.63 | +0.51 | -1.26 |  |  |
| `crates/xtask/src/main.rs` | 0/0 | 3/10 | 6/6 | 5/10 | +0.00 | +1.10 | +0.00 | B high | artefact (triage): subcommand names carry 10/10 |
| `crates/chassis/src/cabinet.rs` | 4/5 | 6/13 | 8/10 | 14/68 | +0.20 | +0.70 | +0.20 |  |  |
| `crates/app/src/overlay.rs` | 1/2 | 3/5 | 3/0 | 6/35 | +0.63 | +0.46 | -1.63 |  |  |
| `crates/term/src/fonts/system.rs` | 2/5 | 4/5 | 1/1 | 6/10 | +0.83 | +0.20 | +0.00 |  |  |
| `crates/app/src/bank.rs` | 3/1 | 6/5 | 4/4 | 12/13 | -1.00 | -0.17 | +0.00 |  |  |
| `crates/app/src/cli.rs` | 3/1 | 6/3 | 2/1 | 12/16 | -1.00 | -0.63 | -0.63 |  |  |
| `crates/app/src/input.rs` | 2/1 | 5/7 | 2/1 | 12/28 | -0.63 | +0.31 | -0.63 |  |  |
| `crates/chassis/src/strip.rs` | 3/5 | 5/8 | 3/2 | 8/61 | +0.46 | +0.43 | -0.37 |  |  |
| `crates/chassis/src/color.rs` | 6/11 | 10/14 | 1/0 | 25/116 | +0.55 | +0.31 | -0.63 |  |  |
| `crates/app/src/column.rs` | 2/1 | 5/1 | 7/9 | 12/8 | -0.63 | -1.46 | +0.23 |  |  |
| `crates/xtask/src/x11.rs` | 2/2 | 3/7 | 1/1 | 5/40 | +0.00 | +0.77 | +0.00 |  |  |
| `crates/config/src/presets.rs` | 3/5 | 6/8 | 2/1 | 12/21 | +0.46 | +0.26 | -0.63 |  |  |
| `crates/xtask/src/proc.rs` | 3/4 | 3/5 | 1/0 | 6/36 | +0.26 | +0.46 | -0.63 |  |  |
| `crates/term/src/tmux_cc.rs` | 2/2 | 6/13 | 3/1 | 10/48 | +0.00 | +0.70 | -1.00 |  |  |
| `crates/app/src/badge.rs` | 2/1 | 4/3 | 5/1 | 8/17 | -0.63 | -0.26 | -1.46 |  |  |
| `crates/app/src/chord.rs` | 2/1 | 5/1 | 3/0 | 9/9 | -0.63 | -1.46 | -1.63 |  |  |
| `crates/app/src/gpu.rs` | 2/1 | 4/3 | 3/2 | 8/6 | -0.63 | -0.26 | -0.37 |  |  |
| `crates/app/src/instance.rs` | 1/2 | 3/1 | 2/0 | 6/3 | +0.63 | -1.00 | -1.26 |  |  |
| `crates/app/src/paths.rs` | 4/2 | 5/3 | 1/0 | 8/3 | -0.63 | -0.46 | -0.63 |  |  |
| `crates/chassis/src/displays/raster.rs` | 2/1 | 3/3 | 2/1 | 5/5 | -0.63 | +0.00 | -0.63 |  |  |
| `crates/config/src/profile.rs` | 3/2 | 6/6 | 3/4 | 14/33 | -0.37 | +0.00 | +0.26 |  |  |
| `crates/config/src/watch.rs` | 2/1 | 4/3 | 4/1 | 6/12 | -0.63 | -0.26 | -1.26 |  |  |
| `crates/crt-burnin/src/chain.rs` | 1/0 | 3/2 | 2/2 | 4/6 | -0.63 | -0.37 | +0.00 |  |  |
| `crates/crt-render/src/device.rs` | 2/1 | 3/0 | 1/0 | 5/0 | -0.63 | -1.63 | -0.63 |  |  |
| `crates/term/src/search.rs` | 2/1 | 3/3 | 2/1 | 5/12 | -0.63 | +0.00 | -0.63 |  |  |
| `crates/term/src/selection.rs` | 2/2 | 4/8 | 3/1 | 8/131 | +0.00 | +0.63 | -1.00 |  |  |
| `crates/tmux-cc/src/escape.rs` | 2/2 | 3/6 | 1/0 | 6/23 | +0.00 | +0.63 | -0.63 |  |  |
| `crates/xtask/src/compare.rs` | 2/1 | 3/3 | 2/0 | 6/8 | -0.63 | +0.00 | -1.26 |  |  |
| `crates/xtask/src/mask.rs` | 2/1 | 2/0 | 1/0 | 4/0 | -0.63 | -1.26 | -0.63 |  |  |
| `crates/xtask/src/snap.rs` | 2/1 | 3/2 | 3/2 | 6/3 | -0.63 | -0.37 | -0.37 |  |  |
| `crates/chassis/src/seam.rs` | 2/3 | 4/5 | 3/3 | 7/21 | +0.37 | +0.20 | +0.00 |  |  |
| `crates/term/src/rio_grid.rs` | 2/3 | 4/5 | 2/1 | 7/35 | +0.37 | +0.20 | -0.63 |  |  |
| `crates/tmux-cc/src/event.rs` | 2/3 | 4/5 | 2/2 | 7/198 | +0.37 | +0.20 | +0.00 |  |  |
| `crates/app/src/lib.rs` | 5/3 | 6/0 | 3/0 | 10/0 | -0.46 | -2.26 | -1.63 |  |  |
| `crates/app/src/main.rs` | 0/0 | 3/0 | 8/13 | 4/0 | +0.00 | -1.63 | +0.44 |  |  |
| `crates/app/src/geometry.rs` | 3/2 | 6/2 | 1/0 | 10/2 | -0.37 | -1.00 | -0.63 |  |  |
| `crates/chassis/src/js.rs` | 6/4 | 7/2 | 0/0 | 15/2 | -0.37 | -1.14 | +0.00 |  |  |
| `crates/chassis/src/shaders.rs` | 3/2 | 4/3 | 0/0 | 6/8 | -0.37 | -0.26 | +0.00 |  |  |
| `crates/term/src/fonts/raster.rs` | 2/3 | 3/3 | 1/0 | 5/5 | +0.37 | +0.00 | -0.63 |  |  |
| `crates/term/src/pointer.rs` | 2/3 | 4/4 | 2/0 | 7/171 | +0.37 | +0.00 | -1.26 |  |  |
| `crates/chassis/src/frame.rs` | 3/4 | 5/3 | 4/4 | 9/15 | +0.26 | -0.46 | +0.00 |  |  |
| `crates/term/src/tmux_pane.rs` | 2/2 | 5/5 | 3/4 | 8/23 | +0.00 | +0.00 | +0.26 |  |  |
| `crates/app/src/clipboard.rs` | 1/1 | 3/1 | 1/0 | 5/1 | +0.00 | -1.00 | -0.63 |  |  |
| `crates/app/src/crashlog.rs` | 1/1 | 3/3 | 1/0 | 5/9 | +0.00 | +0.00 | -0.63 |  |  |
| `crates/app/src/mouse.rs` | 1/1 | 3/1 | 2/1 | 6/6 | +0.00 | -1.00 | -0.63 |  |  |
| `crates/term/src/bin/esctest_harness.rs` | 0/0 | 2/1 | 6/0 | 3/1 | +0.00 | -0.63 | -2.26 |  |  |
| `crates/term/src/distortion.rs` | 3/3 | 5/5 | 1/0 | 10/25 | +0.00 | +0.00 | -0.63 |  |  |
| `crates/xtask/src/fanout.rs` | 1/1 | 2/1 | 2/0 | 4/5 | +0.00 | -0.63 | -1.26 |  |  |
| `crates/xtask/src/install.rs` | 1/1 | 3/1 | 3/1 | 6/3 | +0.00 | -1.00 | -1.00 |  |  |
| `crates/xtask/src/verify.rs` | 1/1 | 3/1 | 4/2 | 6/1 | +0.00 | -1.00 | -0.63 |  |  |

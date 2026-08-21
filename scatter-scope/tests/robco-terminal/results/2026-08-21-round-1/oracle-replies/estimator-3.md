# Estimator 3 (cheap tier, fresh context, brief only)

Brief: `oracle-brief.md`. One tool call, `Read` on the brief. No repository access.
(Omitted one module, `crates/term/src/distortion.rs`; the median for that module is taken over the two estimates that supplied it.)

## Part 1 — path | A | B | C

crates/app/src/badge.rs | 2 | 4 | 6
crates/app/src/bank.rs | 4 | 7 | 11
crates/app/src/channels.rs | 7 | 12 | 19
crates/app/src/chord.rs | 2 | 4 | 5
crates/app/src/cli.rs | 1 | 3 | 4
crates/app/src/clipboard.rs | 1 | 3 | 4
crates/app/src/column.rs | 2 | 4 | 6
crates/app/src/crashlog.rs | 1 | 2 | 3
crates/app/src/distortion.rs | 2 | 4 | 5
crates/app/src/frame_stats.rs | 1 | 3 | 5
crates/app/src/geometry.rs | 5 | 8 | 13
crates/app/src/gpu.rs | 1 | 3 | 5
crates/app/src/input.rs | 2 | 4 | 7
crates/app/src/instance.rs | 2 | 4 | 6
crates/app/src/lib.rs | 1 | 2 | 2
crates/app/src/main.rs | 0 | 1 | 1
crates/app/src/mouse.rs | 1 | 3 | 4
crates/app/src/overlay.rs | 2 | 4 | 6
crates/app/src/paths.rs | 2 | 4 | 6
crates/app/src/settings.rs | 3 | 5 | 9
crates/app/src/shell.rs | 10 | 16 | 35
crates/app/src/tmux.rs | 4 | 8 | 14
crates/app/src/window.rs | 1 | 3 | 5
crates/chassis/src/bank.rs | 4 | 7 | 11
crates/chassis/src/cabinet.rs | 3 | 6 | 10
crates/chassis/src/color.rs | 10 | 18 | 52
crates/chassis/src/displays/led/metrics.rs | 1 | 3 | 4
crates/chassis/src/displays/led/mod.rs | 2 | 4 | 7
crates/chassis/src/displays/mod.rs | 1 | 2 | 3
crates/chassis/src/displays/raster.rs | 2 | 4 | 7
crates/chassis/src/displays/tape/metrics.rs | 1 | 3 | 4
crates/chassis/src/displays/tape/mod.rs | 2 | 4 | 7
crates/chassis/src/frame.rs | 4 | 7 | 12
crates/chassis/src/furniture.rs | 4 | 8 | 18
crates/chassis/src/js.rs | 2 | 5 | 10
crates/chassis/src/layout.rs | 4 | 7 | 12
crates/chassis/src/lib.rs | 1 | 2 | 2
crates/chassis/src/metrics.rs | 5 | 8 | 15
crates/chassis/src/oracle.rs | 1 | 4 | 7
crates/chassis/src/paint.rs | 6 | 11 | 28
crates/chassis/src/seam.rs | 2 | 4 | 7
crates/chassis/src/shaders.rs | 1 | 2 | 3
crates/chassis/src/shells/annunciator.rs | 1 | 3 | 4
crates/chassis/src/shells/common.rs | 3 | 6 | 11
crates/chassis/src/shells/mod.rs | 1 | 3 | 5
crates/chassis/src/shells/slide_rule.rs | 1 | 3 | 4
crates/chassis/src/shells/switchboard.rs | 1 | 3 | 4
crates/chassis/src/strip.rs | 2 | 4 | 7
crates/config/src/lib.rs | 1 | 2 | 2
crates/config/src/presets.rs | 2 | 4 | 7
crates/config/src/profile.rs | 4 | 7 | 13
crates/config/src/schema.rs | 2 | 4 | 7
crates/config/src/structural.rs | 1 | 3 | 4
crates/config/src/toml.rs | 3 | 6 | 11
crates/config/src/watch.rs | 1 | 3 | 5
crates/crt-burnin/src/chain.rs | 1 | 3 | 5
crates/crt-burnin/src/decay.rs | 1 | 3 | 5
crates/crt-burnin/src/headless.rs | 1 | 2 | 3
crates/crt-burnin/src/lib.rs | 1 | 2 | 2
crates/crt-render/src/chain.rs | 2 | 5 | 10
crates/crt-render/src/degauss.rs | 1 | 3 | 5
crates/crt-render/src/device.rs | 1 | 3 | 4
crates/crt-render/src/lib.rs | 1 | 2 | 2
crates/crt-render/src/oracle.rs | 1 | 3 | 5
crates/crt-render/src/pacing.rs | 1 | 3 | 5
crates/crt-render/src/params.rs | 2 | 4 | 8
crates/crt-render/src/preset.rs | 2 | 4 | 8
crates/term/src/atlas.rs | 1 | 3 | 5
crates/term/src/bin/esctest_harness.rs | 0 | 1 | 1
crates/term/src/cells.rs | 2 | 4 | 8
crates/term/src/color.rs | 3 | 6 | 12
crates/term/src/dcs.rs | 2 | 4 | 8
crates/term/src/fonts/led.rs | 1 | 3 | 5
crates/term/src/fonts/metrics.rs | 3 | 6 | 12
crates/term/src/fonts/mod.rs | 4 | 7 | 14
crates/term/src/fonts/raster.rs | 1 | 3 | 5
crates/term/src/fonts/sizing.rs | 1 | 3 | 5
crates/term/src/fonts/subpixel.rs | 1 | 3 | 5
crates/term/src/fonts/system.rs | 1 | 3 | 5
crates/term/src/fonts/text.rs | 3 | 6 | 12
crates/term/src/gpu.rs | 1 | 3 | 5
crates/term/src/grid.rs | 3 | 6 | 12
crates/term/src/hotspots.rs | 1 | 3 | 5
crates/term/src/lib.rs | 1 | 2 | 2
crates/term/src/pointer.rs | 2 | 4 | 8
crates/term/src/render.rs | 2 | 4 | 8
crates/term/src/rio_grid.rs | 1 | 3 | 5
crates/term/src/search.rs | 1 | 3 | 5
crates/term/src/selection.rs | 2 | 4 | 8
crates/term/src/session.rs | 3 | 5 | 10
crates/term/src/size.rs | 2 | 4 | 8
crates/term/src/tmux_cc.rs | 1 | 3 | 5
crates/term/src/tmux_pane.rs | 1 | 4 | 7
crates/term/src/viewport.rs | 1 | 3 | 5
crates/tmux-cc/src/codec.rs | 1 | 3 | 5
crates/tmux-cc/src/command.rs | 1 | 3 | 5
crates/tmux-cc/src/escape.rs | 1 | 3 | 5
crates/tmux-cc/src/event.rs | 1 | 3 | 5
crates/tmux-cc/src/ids.rs | 2 | 4 | 8
crates/tmux-cc/src/lib.rs | 1 | 2 | 2
crates/xtask/src/compare.rs | 1 | 3 | 6
crates/xtask/src/fanout.rs | 1 | 3 | 5
crates/xtask/src/install.rs | 1 | 3 | 5
crates/xtask/src/main.rs | 0 | 1 | 1
crates/xtask/src/mask.rs | 1 | 3 | 5
crates/xtask/src/proc.rs | 2 | 4 | 8
crates/xtask/src/snap.rs | 1 | 3 | 5
crates/xtask/src/verify.rs | 1 | 3 | 5
crates/xtask/src/x11.rs | 2 | 4 | 8

## Part 2 — decided-once facts | expected places

Channel numbering scheme (1-based, fixed maximum) | 9
Bank panel positioned on left side of window | 10
Configuration file format is TOML with hot-reload | 11
Minimum window height is 240 logical pixels | 7
Font metrics computed as 26.6 fixed-point arithmetic | 8
Terminal emulation core is rio-vt | 6
Terminal session per channel uses rio-vt VT state machine | 7
Colors represented as RGBA 32-bit values | 11
Rendering backend is wgpu with runtime backend selection | 10
Tmux attachment dedicates one gateway channel per connection | 8
Screen curvature distortion applied as per-pixel mathematical mapping | 9
Channel switching triggers degaussing transient effect | 6

# Estimation brief

You are estimating, from description alone, how widely each module of a Rust workspace is used. You have no tools and no access to the code. Give your best numbers; a considered guess is what is wanted, not a refusal.

## 1. The program's own description

# RobCo Terminal

A terminal emulator that behaves like a piece of hardware.

Not a terminal with a scanline filter over it. The picture is a curved tube:
phosphor that keeps glowing after the pixel goes dark, bloom that spills off
bright type, a scan line travelling down the glass, and a click that lands
where you aimed it because the pointer is mapped back through the curvature
the same way the type is mapped forward. Around the tube is a chassis, and
the chassis has a channel bank down one side with a numbered strip per
session. You pick a channel the way you would pick a station.

The CRT look draws its visual inspiration from
[cool-retro-term](https://github.com/Swordfish90/cool-retro-term). The
terminal itself is built on the rio emulation core. The chassis, the channel
bank, and the tmux integration below are this project's own.

## What you actually get

**The glass.** A phosphor screen you configure rather than choose from a
menu: colour, curvature, bloom, burn-in persistence, static, flicker,
horizontal sync wobble, jitter, and which scanline or pixel grid is laid over
the type. Presets come built in, from `Default Amber` through `Commodore 64`,
`Apple ][`, `IBM VGA 8x16` and `E-Ink`, and each one is a starting point you
adjust rather than a fixed skin.

The type is real work rather than a font pick. Bitmap faces are drawn from
their embedded strikes at integer scale, so an 8-pixel face renders as
8-pixel pixels and not as a blurred outline pretending to be one.

**The chassis.** The cabinets that ship are `Annunciator`, `Slide Rule` and
`Switchboard`. Each has its own casting, bezel, furniture and channel bank,
and each marks the live channel its own way (a glow, a pointer, a thrown
switch). The chassis is drawn outside the CRT chain, so the cabinet stays
straight while the picture behind the glass bulges. Turn it off and the tube
stands bare in its own moulding.

**Channels.** Every session gets a numbered slot on the bank. `Alt`+digit
brings a slot to the screen; `Alt`+`Shift`+digit moves what is on screen onto
a slot. `Ctrl`+`Shift`+`T` opens a new one. Switching channels degausses, the
way changing input on real hardware did.

**tmux as channels.** Type `tmux -CC` in any channel, on this machine or
over ssh. The terminal notices tmux's control mode, and that server's windows
arrive as their own page of channels on the bank. tmux windows are then bank
slots like any other, switched with the same chords. There is no status bar
to read, because the bank is doing that job. The channel you typed the
command in becomes the attachment's gateway and stops taking keystrokes;
press `Enter` on it to detach, and its page collapses back to the single
channel you started from. Nothing is lost if the terminal dies mid-session,
which is why a local tmux under this young program is a sane habit:
re-attach cold and the windows come back with their titles.

## Will it run here

**Linux, today.** X11 is what is wired and measured; on Wayland the window
runs.

**macOS and Windows are planned, not built.** The stack was chosen for them
(the terminal core speaks ConPTY, the GPU layer covers Metal and D3D from the
same shader source), and the config paths for both are already implemented.
But neither has been built or run, and neither can be cross-compiled from
Linux, because the terminal core drags a C++ dependency that needs a native
toolchain. Treat them as intended, not available.

You need a GPU the graphics layer can reach. It picks a backend on its own,
and reports which one it chose in the first lines of its log. `WGPU_BACKEND`
overrides the choice if the automatic one misbehaves, which on Mesa is worth
trying with `vulkan` before anything else.

The window has a floor of 240 pixels tall, and wide enough for the channel
bank plus 320 logical pixels of screen well. On a default bank that comes to
567 by 240.

## First run, and configuring it

Just run `robco-term`. There is no configuration to do first, and no config
file exists until you write one.

When you do want to change something, there is no settings window: the
terminal reads one TOML file, watches it, and reloads the moment you save.
Editing the file is the settings UI. Open it in your editor, change a
number, save, and the glass changes under you while the editor is still
open. A file that does not parse costs you the edit and not the session,
because the terminal keeps the settings it already had and logs the error.

The file lives at `$XDG_CONFIG_HOME/robco-term/config.toml` on Linux, under
`~/Library/Application Support/robco-term/` on macOS, and in `%APPDATA%` on
Windows.

It is a diff against the defaults, so a real one is short:

```toml
[general]
font_scaling = 1.2

[screen]
name = "Deep Blue"
bloom = 0.9

[chassis]
name = "Slide Rule"
```

The `name` key in each of those two tables is the part worth knowing about.
It is not a label. It picks which built-in preset the rest of that table is
measured against, so the file above means the Deep Blue screen with its bloom
turned up, standing in the Slide Rule cabinet. Everything not named comes
from those two presets, which is what keeps the file this short and what
keeps it meaning the same thing on another machine.

Keep a look under a name of your own by putting the two tables in
`config.<name>.toml` beside your config file, then start under it:

```console
$ robco-term --profile workshop
```

The name is read as one of your saved looks first, then as a built-in screen,
so `--profile "Deep Blue"` works without saving anything. A name that is
neither is refused rather than quietly ignored, so you never get the wrong
picture under the right name.

**[docs/config.md](docs/config.md) is the full reference**: every key, its
default, and what it does. If you are writing a program that edits the file
on a user's behalf, [docs/config-format.md](docs/config-format.md) states the
rules it has to obey.

## Keys

`Alt`+digit brings a channel to the screen, `Ctrl`+`Shift`+`T` opens one,
and copy and paste are `Ctrl`+`Shift`+`C` and `Ctrl`+`Shift`+`V` where any
other terminal puts them. [docs/keys.md](docs/keys.md) is the full list, and
it also says which keys this terminal leaves alone.

## Command line

`robco-term --help` lists them all. The ones worth knowing before you read
it: `-e <cmd>` runs a command instead of your shell and swallows every
argument after itself, so put it last; `--program` does the same for a plain
program with no arguments; `--workdir` sets the starting directory;
`--fullscreen` and `--profile` do what they say; and `--default-settings`
starts from the built-in defaults without reading your config file.

A second `robco-term` does not start a second application. It hands its
request to the one already running, which opens another window and exits.

## Status

Version 0.1.0, unreleased. It is complete enough to use as a daily terminal
on Linux: the terminal core passes the conformance suite bar two known
feature gaps, channels and tmux control mode work against live tmux, and the
picture holds its frame budget with room to spare.

Known gaps, so you find them here rather than by hitting them: no keyboard
binding for font size (it is a config key), a cursor that does not blink,
and a placeholder application icon. A licence file is still to come.

`cargo run -p xtask -- verify <path-to-binary>` walks a built binary through
the window and CLI contract item by item and tells you which parts this
machine honours. It is the fastest honest answer to "does this work here".

## 2. Size facts

| crate | source files | source lines | test files | test lines |
|---|---|---|---|---|
| app | 23 | 13565 | 18 | 5754 |
| chassis | 25 | 10059 | 14 | 2281 |
| config | 7 | 2979 | 0 | 0 |
| crt-burnin | 4 | 1101 | 2 | 515 |
| crt-render | 8 | 1780 | 9 | 2851 |
| term | 28 | 9311 | 12 | 3279 |
| tmux-cc | 6 | 1737 | 3 | 1088 |
| xtask | 9 | 2818 | 0 | 0 |


Documentation files in the tree: `README.md`, `docs/config.md`, `docs/config-format.md`, `docs/keys.md`, `crates/crt-burnin/MOUNT.md`. Manifests: one `Cargo.toml` per crate plus the workspace root.

## 3. The module list

Every source module of the workspace, with its length in lines and its own doc line as the module carries it (`//!`, first line only, so some are cut mid-sentence).

| path | lines | the module's own doc line |
|---|---|---|
| `crates/app/src/badge.rs` | 536 | Drawing for the transient badges: black rounded plates over the glass, one |
| `crates/app/src/bank.rs` | 418 | The bank's state half: which slots the engraved numerals name right now. |
| `crates/app/src/channels.rs` | 1217 | The channel model: what a window's sessions are numbered, which one is on |
| `crates/app/src/chord.rs` | 296 | The channel-selection chord: hold the modifier, type digits, release to |
| `crates/app/src/cli.rs` | 274 | Command-line parsing for the application shell. |
| `crates/app/src/clipboard.rs` | 75 | Clipboard access, thin wrapper over `arboard`. |
| `crates/app/src/column.rs` | 1307 | The bank column, composited over the presented frame. |
| `crates/app/src/crashlog.rs` | 223 | Last-gasp crash logger. |
| `crates/app/src/distortion.rs` | 9 | Inverse screen-curvature distortion. |
| `crates/app/src/frame_stats.rs` | 495 | A frame's GPU-timing instrument: wgpu timestamp queries straddling the |
| `crates/app/src/geometry.rs` | 30 | Window geometry: the numbers the CLI/window contract measures. |
| `crates/app/src/gpu.rs` | 337 | The wgpu 30 surface behind the window. |
| `crates/app/src/input.rs` | 996 | Keyboard encoding: a lookup table of `key <name> <conditions> : |
| `crates/app/src/instance.rs` | 390 | Single-instance arbitration and the new-window IPC. |
| `crates/app/src/lib.rs` | 93 | RobCo Terminal application. |
| `crates/app/src/main.rs` | 285 | The RobCo Terminal binary. |
| `crates/app/src/mouse.rs` | 133 | Mouse reporting: X10 and SGR extended mouse-tracking protocol encoding. |
| `crates/app/src/overlay.rs` | 360 | The size overlay: the transient "columns x rows" badge shown while a |
| `crates/app/src/paths.rs` | 63 | Where the application's per-user files live. |
| `crates/app/src/settings.rs` | 598 | Wiring `robco-config` into the application. |
| `crates/app/src/shell.rs` | 677 | The window shell: winit event loop, multi-window bookkeeping, and the |
| `crates/app/src/tmux.rs` | 1548 | The tmux control-mode gateway: one attachment's session/window policy. |
| `crates/app/src/window.rs` | 3205 | What fills a shell window: the wgpu surface, the rio-vt session |
| `crates/chassis/src/bank.rs` | 365 | The channel bank's geometry: the column of furniture set into the chassis, |
| `crates/chassis/src/cabinet.rs` | 525 | The whole cabinet as one object: the composition order from this crate's |
| `crates/chassis/src/color.rs` | 394 | The workspace's colour math, in its one home. The chrome |
| `crates/chassis/src/displays/led/metrics.rs` | 111 | The LED strip's width-quantisation contract. |
| `crates/chassis/src/displays/led/mod.rs` | 207 | The LED strip kit. A channel title read off the bundled pixel font, one |
| `crates/chassis/src/displays/mod.rs` | 15 | Channel display kits, one directory a kit. Each kit composes the |
| `crates/chassis/src/displays/raster.rs` | 34 | The one conversion both display kits need: `term::fonts::led::LedRaster` |
| `crates/chassis/src/displays/tape/metrics.rs` | 87 | The tape well's width-quantisation contract. |
| `crates/chassis/src/displays/tape/mod.rs` | 226 | The tape-label kit. A channel title stamped as embossed punch tape, |
| `crates/chassis/src/frame.rs` | 438 | The bank frame: the bezel the screen well is set into, and the chassis metal |
| `crates/chassis/src/furniture.rs` | 1400 | What stands on the casting: the shell's plate, and one channel display per |
| `crates/chassis/src/js.rs` | 48 | The two arithmetic primitives every layout formula in this crate runs |
| `crates/chassis/src/layout.rs` | 244 | How the window divides into the bank's column and the screen well, and the |
| `crates/chassis/src/lib.rs` | 321 | The chassis: the cabinet the curved screen is set into. |
| `crates/chassis/src/metrics.rs` | 498 | The two measure contracts the bank composes: what a shell declares about its |
| `crates/chassis/src/oracle.rs` | 530 | CPU-side reimplementations of the three procedural metal shaders' math, |
| `crates/chassis/src/paint.rs` | 1079 | This crate's own gradient-and-text painting, for the furniture that is |
| `crates/chassis/src/seam.rs` | 435 | The seam where the bank's plastic meets the screen well, and the drag that |
| `crates/chassis/src/shaders.rs` | 77 | The three metals' source, compiled in. |
| `crates/chassis/src/shells/annunciator.rs` | 603 | The amber appliance: furniture cut close at the sides, windows at a |
| `crates/chassis/src/shells/common.rs` | 341 | Geometry every shell's chassis and frame repeat verbatim. |
| `crates/chassis/src/shells/mod.rs` | 242 | One module per shell: |
| `crates/chassis/src/shells/slide_rule.rs` | 722 | The blue appliance: bare scratched gunmetal (`chassis_metal`) with a |
| `crates/chassis/src/shells/switchboard.rs` | 876 | The toggle-switch appliance: near-neutral dark gunmetal, `chassis_metal` |
| `crates/chassis/src/strip.rs` | 241 | The data seam between the channel model and the bank's furniture: what one |
| `crates/config/src/lib.rs` | 256 | `robco-config`: RobCo Terminal settings (lib name `config`; the package |
| `crates/config/src/presets.rs` | 343 | Built-in screen and chassis presets, in their list order. Each preset's |
| `crates/config/src/profile.rs` | 891 | The profile model: an appliance split into two axes, snapshot equality |
| `crates/config/src/schema.rs` | 249 | Settings schema for the terminal's three persisted configuration groups. |
| `crates/config/src/structural.rs` | 123 | The parameter/structural key split: which config keys force a |
| `crates/config/src/toml.rs` | 740 | The config file's format: its name, and reading, resolving, |
| `crates/config/src/watch.rs` | 377 | Live-reloading the config file. |
| `crates/crt-burnin/src/chain.rs` | 136 | A minimal chain that mounts the accumulator on its own. |
| `crates/crt-burnin/src/decay.rs` | 202 | The wall-clock half of burn-in. |
| `crates/crt-burnin/src/headless.rs` | 500 | A device with no display and a way to read pixels back off it. |
| `crates/crt-burnin/src/lib.rs` | 263 | Burn-in as a librashader feedback pass. |
| `crates/crt-render/src/chain.rs` | 303 | The filter chain: one preset, loaded once, driven by uniforms. |
| `crates/crt-render/src/degauss.rs` | 107 | The degauss transient, as a render hook. |
| `crates/crt-render/src/device.rs` | 53 | What the chain needs from the wgpu device, before anyone creates one. |
| `crates/crt-render/src/lib.rs` | 113 | The CRT pass graph: the chain the terminal picture is drawn through. |
| `crates/crt-render/src/oracle.rs` | 180 | CPU-side reimplementations of the shaders' math, used as the oracle |
| `crates/crt-render/src/pacing.rs` | 113 | The time contract for every pass in the chain. |
| `crates/crt-render/src/params.rs` | 446 | Every uniform the chain takes, and the arithmetic between a setting and it. |
| `crates/crt-render/src/preset.rs` | 465 | The one preset, and the structural settings that write it. |
| `crates/term/src/atlas.rs` | 533 | Glyph atlas: cosmic-text does the shaping and the rasterising, we own the |
| `crates/term/src/bin/esctest_harness.rs` | 341 | A terminal with no window: rio-vt driven over a real PTY, so the escape |
| `crates/term/src/cells.rs` | 270 | The renderer's own idea of a screen, and the bridge that fills it from a |
| `crates/term/src/color.rs` | 183 | Colour resolution: rio-vt hands out `AnsiColor`, the renderer wants four |
| `crates/term/src/dcs.rs` | 336 | The DCS tap: the seam a DCS consumer stands on, and the parser that |
| `crates/term/src/distortion.rs` | 403 | Inverse screen-curvature distortion: undoes the CRT-tube warp applied to |
| `crates/term/src/fonts/led.rs` | 130 | The glyph raster the LED strip and the tape label read. |
| `crates/term/src/fonts/metrics.rs` | 227 | Scaled font metrics, computed as exact 26.6 fixed-point arithmetic. |
| `crates/term/src/fonts/mod.rs` | 428 | The bundled font catalogue. |
| `crates/term/src/fonts/raster.rs` | 68 | One answer to "how a bundled face becomes pixels". |
| `crates/term/src/fonts/sizing.rs` | 348 | The sizing seam: pixel-size and scaling computation, plus the |
| `crates/term/src/fonts/subpixel.rs` | 471 | The host's LCD stripe geometry, and FreeType's filter over it. |
| `crates/term/src/fonts/system.rs` | 393 | System-font enumeration: the platform's installed monospace families, |
| `crates/term/src/fonts/text.rs` | 476 | One line of antialiased text raster at a pixel size, with absolute |
| `crates/term/src/gpu.rs` | 343 | Offscreen wgpu context: a device, a colour target, and a pixel readback. |
| `crates/term/src/grid.rs` | 372 | The grid seam, and the two grid-to-text paths every consumer above it uses. |
| `crates/term/src/hotspots.rs` | 309 | URL hotspots. |
| `crates/term/src/lib.rs` | 132 | RobCo Terminal core. |
| `crates/term/src/pointer.rs` | 173 | What a pointer event means: mark the screen, or forward it to the program? |
| `crates/term/src/render.rs` | 984 | The grid renderer: a screen of cells plus a thresholded atlas, drawn in one |
| `crates/term/src/rio_grid.rs` | 172 | [`GridView`] over rio-vt's `Crosswords`. |
| `crates/term/src/search.rs` | 170 | Scrollback search. |
| `crates/term/src/selection.rs` | 562 | Selection: the anchor/extent state, and the pointer gestures that drive |
| `crates/term/src/session.rs` | 494 | A terminal session: a PTY, the VT state, and the read loop joining them. |
| `crates/term/src/size.rs` | 203 | Geometry: how a window's pixels become a grid of cells. |
| `crates/term/src/tmux_cc.rs` | 274 | tmux control mode on the wire: the `DCS 1000 p` envelope and the tap |
| `crates/term/src/tmux_pane.rs` | 238 | The session variant a tmux pane feeds: `%output` in, `send-keys` out. |
| `crates/term/src/viewport.rs` | 278 | Scrollback viewport. |
| `crates/tmux-cc/src/codec.rs` | 757 | The codec proper: commands out, events in, and the queue that joins them. |
| `crates/tmux-cc/src/command.rs` | 287 | The commands a control client sends, and the quoting they need. |
| `crates/tmux-cc/src/escape.rs` | 287 | How a `%output` payload carries arbitrary bytes on a line protocol. |
| `crates/tmux-cc/src/event.rs` | 250 | What comes back: reply blocks and notifications, typed. |
| `crates/tmux-cc/src/ids.rs` | 83 | The three object ids tmux hands out, each keeping its sigil. |
| `crates/tmux-cc/src/lib.rs` | 73 | The tmux control-mode protocol, and nothing else. |
| `crates/xtask/src/compare.rs` | 443 | Consolidates the RMSE-over-PNG measurement three earlier efforts each |
| `crates/xtask/src/fanout.rs` | 96 | Fan-out measurement for the setting-duplication report (GitHub issue #4 |
| `crates/xtask/src/install.rs` | 831 | `xtask install`, `xtask dist` and `xtask deb`: getting the Linux build off |
| `crates/xtask/src/main.rs` | 230 | The workspace's evaluation harness: deterministic screenshots, carve-out |
| `crates/xtask/src/mask.rs` | 98 | Blackens the judged-out regions of a screenshot -- the CRT glass, the LED |
| `crates/xtask/src/proc.rs` | 87 | Small subprocess helpers shared by snap and mask. Driving the |
| `crates/xtask/src/snap.rs` | 362 | Deterministic screenshots of the running appliance. |
| `crates/xtask/src/verify.rs` | 532 | `xtask verify`: drive a binary through the CLI/window contract and say |
| `crates/xtask/src/x11.rs` | 139 | The X11 questions both `snap` and `verify` ask about a running |

## The ask

**Part 1 — three integers per module.** For every module in the list above, output one line:

```
path | A | B | C
```

- **A** — how many *other* non-test source files in the workspace use a type, function or constant this module defines.
- **B** — how many *other* files of any kind (source files including tests, docs, manifests) mention any of this module's distinctive identifiers or its file stem anywhere, comments and prose included.
- **C** — the total number of such mentions across those B files.

Every module gets a line. Integers only, no ranges, no blanks.

**Part 2 — the decided-once list.** Name eight to twelve design facts a program of this description decides once — the kind of fact that has no module of its own but that code all over assumes. Include the side a panel sits on, and the unit a coordinate is carried in. For each, the number of places in the code you would expect to have to edit if the fact changed:

```
fact | expected places
```

Keep any prose under four hundred words; the tables do not count toward that. Commit to numbers rather than reasoning aloud.

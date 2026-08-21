# Decided-once facts, measured

Probe: a cheap-tier agent working read-only over the tree, one grep or pattern rule per fact,
homonyms named and excluded. `expected` is the estimators' median from `facts.md`. `gap` is
measured files ÷ expected places; the estimators answered "places to edit", so **files** is the
comparable column and **sites** is printed beside it.

| fact | expected | decided in | obeyed in | gap |
|---|---|---|---|---|
| Unit a screen coordinate is carried in | 6 | **no single home** — the logical-to-physical conversion is repeated in `chassis::cabinet::bank_width_physical`, `chassis::layout::min_inner_size_physical`, `app::window::bank_physical` | 8 files / 78 sites | x1.3 |
| Which crate owns the curvature distortion math, both directions | 4 | **no single home** — the forward warp `distortCoordinates` is written once per shader (4 shader files); the inverse is `term::distortion::correct_distortion` | 6 files / ~20 sites, plus 4 shader-tier copies | x1.5 + a tier the graph cannot see |
| Target frame budget / rate (60 Hz, 16.667 ms) | 4 | **no single home** — `app::window::EFFECTS_BASE_FRAME` and `app::shell::OVERLAY_FRAME` hardcode it independently | 4 files / 15 sites | x1.0 |
| Roster of built-in chassis shells / cabinets | 5 | `config::presets::chassis_presets`, plus the `Shell` enum in `config::schema` | 16 files / 67 sites | x3.2 |
| Default screen preset name ("Default Amber") | 2 | `config::schema` line 206, `ScreenSettings::default()` | 16 files / 29 sites | x8.0 |
| Set and order of built-in screen presets | 3 | `config::presets::screen_presets` | 11 files / 59 sites | x3.7 |
| Degauss transient fires on channel switch | 2 | `app::channels::take_degauss` and `crt_render::degauss` | 8 files / 71 sites | x4.0 |
| Config file serialisation format (TOML) | 6 | `config::toml` | 8 files / 85 sites | x1.3 |
| Colour space for chrome and screen gradient math (HSV) | 3 | `chassis::color` (`to_hsv`/`from_hsv`) | 5 files / 75 sites | x1.7 |
| Per-OS config file location | 2 | `app::settings::config_dir`, via `directories::ProjectDirs` | 5 files / 20 sites | x2.5 |
| Chord that opens a new channel (Ctrl+Shift+T) | 3 | `app::window::shortcut_key` | 7 files / 17 sites | x2.3 |
| Bitmap faces rendered only at integer scale | 2 | `term::fonts::sizing` (`ScalePolicy::Floor`, `integer_scale`) | 3 files / 20 sites | x1.5 |
| Profile-name resolution order | 2 | `config::toml::resolve_axis` / `resolve_presets` | 4 files / 12 sites | x2.0 |
| Side of the window the channel bank sits on | 4 | `chassis::layout::WindowLayout::new` — the bank rectangle is `Rect::new(0.0, 0.0, bank_width, height)` and the well starts at `bank_width`. The fact has **no name**: no `BankSide`, no `Side::Left`, no config key anywhere in the tree | **10 files / 82 non-test sites** (probe's first answer, 4 files / 6 sites, was wrong — corrected below) | **x2.5** |
| Modifier key for the channel-select chord (Alt) | 5 | `app::window` (`shortcut_key`, `modifiers_changed` — two independent hardcodes) | 2 files / 3 sites | x0.4 |
| DCS sequence number for tmux control mode (1000) | 3 | `term::tmux_cc::TMUX_PARAMS = &[1000]` | 2 files / 6 sites | x0.7 |
| Key that detaches a tmux gateway (Enter) | 2 | `app::window::gateway_key` | 2 files / 2 sites | x1.0 |
| Maximum channel slots per bank page | 5 | **not a fact of the code** | **not measured** | — |

## The one probe result this run corrected

The probe first reported the bank-side fact as 4 files / 6 sites, in perfect agreement with the
estimate. That was its pattern, not the code: it searched for prose about sides and for the
layout module, and stopped at the one place the fact is decided.

What actually carries the fact is the *derived scalar*. `WindowLayout` publishes two rectangles
but never a which-side fact, so consumers keep `bank_width` (or `bank_physical()`) and rebuild
the position arithmetic themselves: `crates/app/src/window.rs:1252` places the IME caret at
`top_left.x + bank`, and line 2325 maps a pointer back with `position.x - bank_physical()`.
`grep -c` for `bank_width|bank_physical()` over non-test sources: `chassis/cabinet.rs` 22,
`chassis/seam.rs` 12, `app/shell.rs` 12, `app/window.rs` 9, `chassis/lib.rs` 8, plus
`chassis/layout.rs`, `app/geometry.rs`, `app/main.rs`, `xtask/snap.rs`, `xtask/compare.rs` —
10 files, 82 sites. Each is correct today only because `bank.x` happens to be `0.0`, and the
compiler would report none of them if it stopped being 0.

## Notes the probe attached

- **Not measured.** There is no maximum slots per page. `chassis::bank::BankGeometry::rows_visible`
  computes it at run time from window height ÷ row pitch, unbounded above; the only cap is
  `app::channels::CHANNEL_CAP = 99` on total slots. The estimator's fact does not exist, so no
  number was invented for it.
- **Homonyms excluded.** `1000` as `tmux_cc::command::CAPTURE_HISTORY` (a `capture-pane -S`
  history-line count, a coincidence of value) is not the DCS parameter. "Alt" in
  `term::pointer` and `term::selection` is the xterm modifier encoding and rectangular
  selection, not the channel chord. "detach" in `term::pointer` is a pointer gesture, not the
  gateway client.
- **The side the bank sits on** measured at 4 files / 6 sites against an expected 4 — the
  tightest agreement of any fact in the run, and the one the brief required by kind.

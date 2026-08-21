# RobCo-Terminal — eight design facts measured

Repo: `/home/weiwu/code/RobCo-Terminal` (Rust workspace, 8 crates). Read-only
survey; nothing in the repo was changed. Each fact below reports two
different quantities and does not conflate them: **decided-in** is the
place(s) that define the fact; **obeyed-in** is every independent site that
assumes it and would have to change if the fact changed. Counts split
non-test source / tests / docs. Homonyms excluded are named per fact.

---

## Fact 1 — Which side of the window the channel bank sits on

Expected (blind-reader guess): **4**

### decided-in — 1 site

`crates/chassis/src/layout.rs:73-81`, `WindowLayout::new`:
```rust
pub fn new(width: f64, height: f64, bank_width: f64) -> Self {
    let bank_width = bank_width.clamp(0.0, width.max(0.0));
    WindowLayout {
        bank: Rect::new(0.0, 0.0, bank_width, height),   // line 79
        crt: Rect::new(bank_width, 0.0, width - bank_width, height), // line 80
    }
}
```
There is no config enum/setting for the side (`Side::`, `BankSide`, bare
`Left,`/`Right,` variants: none found in `crates/config` or `crates/chassis`).
The side is not configurable; it is fixed by which rect gets `x = 0`.

### obeyed-in — non-test source: 9

1. `crates/chassis/src/seam.rs:134-136` — `SeamDrag::hit`: `let left = bank_width - SEAM_GRAB_INSET;` assumes the seam boundary sits at `x = bank_width` (only true if bank leads at 0).
2. `crates/chassis/src/cabinet.rs:382` — `cursor_moved`: `window_width: self.layout.crt.right()` — true only because the well is the trailing rect.
3. `crates/chassis/src/cabinet.rs:250` — `remeasure`: `WindowLayout::new(self.layout.crt.right(), ...)` re-derives window width the same way.
4. `crates/app/src/window.rs:2475-2485` — `strip_pressed`: passes click x straight into `cabinet.strip_at` untranslated by `layout().bank.x`; correct only because `bank.x == 0`.
5. `crates/app/src/window.rs:2120-2124` — `output_origin` tuple `(bank, 0)` places the well starting at `x = bank`.
6. `crates/app/src/window.rs:2192` — badge-centring rect given `x = bank` as its left edge.
7. `crates/app/src/column.rs:1144` — `Blit::draw`: bank column destination hardcoded to `(0, 0, column.0, column.1)`.
8. `crates/xtask/src/compare.rs:160-169` — `resolve_crop`, `Region::Bank`: `Crop { x: 0, y: 0, w: BANK_WIDTH, h }`.
9. `crates/xtask/src/compare.rs:171-172` — `resolve_crop`, `Region::Glass`: `let x0 = BANK_WIDTH + GLASS_INSET;`.

Not counted (side-agnostic, would still be correct with rects swapped):
`chassis_field()` (`layout.rs:106-121`, computes a difference), `furniture::strip_at`/`bank_pieces` (operate in the bank's own local space), `geometry.rs`'s `minimum_width = bank_width + crt_minimum_width` (order-independent sum).

### obeyed-in — test: 9

`crates/chassis/src/layout.rs:159-167,210-221`; `crates/chassis/src/frame.rs:365-396,410-437`; `crates/chassis/src/cabinet.rs:462-482`; `crates/chassis/tests/bank_frame_geometry.rs:88-92`; `crates/xtask/src/compare.rs:380-383`; `crates/app/tests/seam_drag.rs:119-132`; `crates/chassis/tests/gpu_annunciator.rs:41-46` (see note below).

Notable non-count: `crates/chassis/tests/region_layout.rs:65-88` and `gpu_annunciator.rs:41-46` deliberately model the bank on the **right** (`bank_x = window_w - bank_w`) to prove the field-mapping formula is side-agnostic — these are stress tests of a generic formula, not assertions of shipped behaviour, so not counted toward the real side's obeyed-in.

### rg patterns used
```
rg -n "channel_bank|ChannelBank|channel bank" --type rust -i
rg -n "bank" -i --type rust
rg -n "bank_width|bank\.x|bank\.right|crt\.x|\.right\(\)|content_x|track_x|WindowLayout::new|chassis_field|field_offset|fieldOffsetX" crates/app/src crates/chassis/src crates/crt-render/src crates/term/src
rg -n "strip_at|pointer_pressed|cursor_moved|\.right\(\)|crt\.right|layout\.crt|layout\.bank|bank\.x|crt\.x" -r crates/app/src crates/crt-render/src
grep -n "\bside\b" --type rust -i
grep -n "enum.*Side|BankSide|bank_side|Left,|Right,|Side::" -r crates/config/src crates/chassis/src
```

### Homonyms excluded
- "bank" meaning tmux/PTY byte buffering (`app/src/tmux.rs`: "banked bytes").
- "side" as software layering ("CPU-side"/"GPU-side", "read side"/"write side" of a PTY, "client/server side", "which side of the seam is live-reloadable" as a config metaphor, "which side of the anchor the head is on" in text selection).
- "side" meaning generic rectangle edge/margin ("no side or vertical padding", "side pad cells").
- `Align::Left`/`Align::Right` — text/glyph alignment within furniture, not window placement.
- `MouseButton::Left` — the mouse button, not a geometric side.
- `config/src/schema.rs:53` "the face the channel bank's windows are lettered in" — a display-kit lettering setting, not window side.
- `chassis/src/shells/annunciator.rs:587` "on the bank side" — a furniture part's position on the bank itself, not the window's left/right.

### Verdict
Gap — the read is heavier than expected: 9 non-test obeyed-in sites found against an expected 4. Direction: **under-estimated**.

---

## Fact 2 — The unit a coordinate is carried in (logical vs. physical pixels)

Expected: **6**

### decided-in — 9 locations

1. `crates/term/src/size.rs:13` — `CellSize` doc: "in logical pixels."
2. `crates/term/src/size.rs:90-134` — `Viewport` (physical fields + `scale_factor`) and `physical_cell()` (line 132), the canonical logical→physical cell conversion.
3. `crates/chassis/src/cabinet.rs:52-65` — module doc: "Every measure in this crate is in the logical pixel…" (whole crate's convention).
4. `crates/chassis/src/layout.rs:131-146` — `min_inner_size_physical`, canonical conversion at the winit boundary.
5. `crates/chassis/src/cabinet.rs:261-264` — `bank_width_physical`.
6. `crates/crt-render/src/params.rs:29-56` — `Geometry` doc: `output_*` logical, `device_pixel_ratio` scales to physical.
7. `crates/app/src/window.rs:148-162` — `chain_geometry`, the physical→logical conversion feeding `crt::Geometry`.
8. `crates/app/src/window.rs:2446-2449` — `logical_x()`, physical→logical for pointer coordinates before hit-testing.
9. `crates/app/src/column.rs:754-766` — `well_ruler()`, logical→physical for the screen-well rectangle (the "320 logical pixels" figure).

### obeyed-in — non-test source: 57

By file (counts, each line independently assumes/converts a coordinate's unit):
- `crates/app/src/gpu.rs` — 1 (`177`).
- `crates/app/src/shell.rs` — 11 (`60,89,98,103,120,129,301,379,380,403,462`).
- `crates/app/src/window.rs` — 35 (`179,217,228,484,557,575,585,586,598,601,604,611,1225,1788,1797,1828,1941,1959,1975,1999,2074,2145,2195,2295,2324,2349,2458,2479,2496,2697,2703,2727,2742,2797,2824`).
- `crates/app/src/column.rs` — 6 (`493,511,536,540,729,782`).
- `crates/app/src/badge.rs` — 1 (`471`).
- `crates/term/src/size.rs` — 1 (`147`).
- `crates/term/src/shader.wgsl` — 1 (`33`, glyph grid assumes physical-pixel alignment).

### obeyed-in — test: 29

`crates/app/src/shell.rs` test mod (2: `654,668`); `crates/app/src/window.rs` test mod (2: `3081,3160`); `crates/chassis/src/cabinet.rs` test mod (4: `444,445,447,448`); `crates/chassis/src/layout.rs` test mod (4: `236,237,241,242`); `crates/chassis/src/paint.rs` test mod (2: `915,1059`); `crates/app/src/column.rs` test mod (2: `1237,1293`); `crates/term/src/size.rs` test mod (1: `179`); `crates/term/src/fonts/sizing.rs` test mod (1: `280`); `crates/crt-render/tests/contracts.rs` (2: `572,589`); `crates/app/tests/seam_drag.rs` (1: `68`); `crates/app/tests/bank_column.rs` (2: `118,270`); `crates/app/tests/pointer.rs` (3: `56,201,226`); `crates/app/tests/pointer_live_settings.rs` (2: `62,230`); `crates/term/tests/transcript.rs` (1: `162`).

### rg patterns used
```
rg -n --hidden -S 'Logical|Physical|scale_factor|dpi|logical|physical' -g '!target' -g '!*.md' -g '!*.lock'
rg -n 'Logical|Physical|scale_factor|dpi|logical|physical' <file>   # per hit-file
rg -n '#\[cfg\(test\)\]'                                             # to split test/non-test
```

### Homonyms excluded
- `PhysicalKey`/`physical_key_from_winit` (`app/src/input.rs`, `shell.rs`, `window.rs`, many lines) — winit's scan-code vs. logical-key naming, an unrelated logical/physical distinction (keyboard identity, not pixel units).
- `settings.rs:77` "physically" — plain-English adverb.
- `term/src/selection.rs:225,460`, `term/tests/selection_tests.rs:168` — "logical line" meaning a wrapped text line, not a coordinate unit.
- `term/tests/esctest/run.py:47` — "logical line" in escape-sequence line-wrap semantics.
- Font license files (`bigblue-terminal/LICENSE.TXT`, `oldschool-pc-fonts/LICENSE.TXT`) — unrelated legal text matched by the broad pattern.
- `.git/logs/HEAD` — reflog noise.

### Verdict
Gap, and a large one — 57 non-test + 29 test = 86 obeyed-in sites against an expected 6. Direction: **substantially under-estimated**; the logical/physical split is the most pervasively-assumed fact of the eight, propagating through nearly every window, pointer, and layout function in `crates/app`.

---

## Fact 3 — The config file's format is TOML

Expected: **3**

### decided-in — 1 module

`crates/config/src/toml.rs` — named for the format it reads/writes (per its own doc comment, lines 1-9). Key anchors: `toml.rs:24` (`use toml_edit::DocumentMut;`), `toml.rs:32` (`pub const FILE_NAME: &str = "config.toml";`), `toml.rs:38-43` (`profile_file_name` derives `config.<name>.toml` from `FILE_NAME`, no second literal), `toml.rs:47-100` (`ConfigError`, TOML-specific variants/messages), `toml.rs:108-129` (`read_document`/`deserialize`/`load`), `toml.rs:137-267` (`write_document`/`edit_document`/`write_key`/`set_dotted`, all on `toml_edit` types), `toml.rs:334-368` (`resolve_presets`/`resolve_axis` via `toml_edit::ser`).

### obeyed-in — non-test source: 3 (independent sites only)

1. `crates/config/src/lib.rs:85-88` — `Config::load` wires directly to `toml::read_document`/`resolve_presets`/`deserialize` by name.
2. `crates/config/src/watch.rs:61` — `ConfigWatcher::spawn`'s default loader is hardcoded to `toml::load`.
3. `crates/config/src/watch.rs:38,77,176` — `Loader<T>`'s error type is bound to `toml::ConfigError` throughout the watcher (one coupling, appears 3× through type propagation, counted as one site).

**Excluded as consumer-only** (call the module's already-abstracted public API, not an independent format assumption): `crates/config/src/profile.rs:66,303`; `crates/app/src/settings.rs:30,72,91,398,399`; `crates/app/src/window.rs:79`.

### obeyed-in — test: ~25 test functions

`crates/config/src/lib.rs` (6, via plain `::toml` crate directly, distinct from `toml_edit`); `crates/config/src/toml.rs` test mod (~13 functions); `crates/config/src/watch.rs` test mod (4); `crates/config/src/profile.rs` test mod (3 literal-path lines); `crates/app/tests/*.rs` (4 files: `settings_live_reload.rs` 7, `profile_cli.rs` 10, `pointer_live_settings.rs` 2, `seam_drag.rs` 1 — raw literal lines, fewer distinct test functions); `crates/app/src/settings.rs` in-file test mod (2, lines 479,481,494).

### obeyed-in — docs: 3 files, 19 mentions

`README.md` — 4 (lines 165,171,177,197). `docs/config.md` — 9 (lines 3,17-19,75,105,119,121,131,133,241). `docs/config-format.md` — 6 (lines 14,129,135,141,145-146) — this is the file stating TOML as an explicit external contract ("The format is TOML", names `toml_edit` as reference implementation, tells third-party tools to preserve round-trip fidelity).

### rg patterns used
```
rg -n "toml_edit" --type rust
rg -n "\btoml::" --type rust
rg -ni "toml" -g '!*.lock'
rg -n "FILE_NAME" --type rust
```

### Homonyms excluded
- `crates/xtask/src/install.rs:105,635` — `toml_edit::DocumentMut` parsing the **workspace `Cargo.toml`** (via `include_str!`) to read the package version for packaging — Cargo's own manifest format, not the application's settings file.
- Every bare `Cargo.toml` mention (build manifests, lockfiles) — package-manager's own file.
- `crates/term/tests/esctest/passlist.txt` — case-insensitive "toml" hits were false positives inside unrelated words (e.g. "Bottom").

### Verdict
Agreement — 3 independent non-test obeyed-in sites against an expected 3, and the recent consolidation (commit `82950cf`) is corroborated: `decided-in` is now a single module, and `crates/app` consumes only the already-abstracted API rather than duplicating format knowledge.

---

## Fact 4 — The number and identity of the built-in chassis shells

Expected: **5**

### decided-in — 2 coupled definitions

1. `crates/config/src/schema.rs:151-157` — the `Shell` enum (`Annunciator`, `SlideRule`, `Switchboard`), which makes every match exhaustive/compiler-checked.
2. `crates/config/src/presets.rs:310-343` — `chassis_presets()`, the runtime registry pairing each variant with a display name and defaults (`"Annunciator"` at 313, `"Slide Rule"` at 323, `"Switchboard"` at 333). This `Vec` is not compiler-enforced and is the actual drift-risk source of truth.

Both agree: exactly **3** built-in chassis ship (`Annunciator`, `Slide Rule`, `Switchboard`) — the README's own count is accurate; no fourth/fifth chassis exists anywhere in the tree.

### obeyed-in — non-test source: 10 (all compiler-enforced exhaustive matches on `Shell`)

`crates/chassis/src/lib.rs:104-107` (`shell_metrics`), `:113-116` (`frame_style`), `:122-125` (`chassis_style`); `crates/chassis/src/shells/mod.rs:77-81` (`plate_region` rect), `:83-87` (`plate_region` metal params), `:132-149` (`row_furniture`), `:172-176` (`row_overhang`), `:195-198` (`pager`), `:214-217` (`selector_track`), `:231-241` (`screws`).

No silently-drifting non-test site found: `config/src/toml.rs:336-345` and `config/src/schema.rs:239-248` both call `presets::chassis_presets()` generically and track the registry automatically. No CLI/clap `ValueEnum` exists for chassis (the CLI is hand-rolled and never touches chassis). No per-shell asset-embedding list (shaders are shared).

### obeyed-in — test: 12 sites, of which 3 are genuine hardcoded-list drift risk

- `crates/config/src/lib.rs:228` — `assert_eq!(presets::chassis_presets().len(), 3)` (**silent-list**).
- `crates/chassis/src/lib.rs:199-201` and `crates/chassis/src/furniture.rs:1141` — literal `[Shell::Annunciator, Shell::SlideRule, Shell::Switchboard]` arrays (**silent-list**, ×2).
- Remaining 9 sites (`config/src/lib.rs:216,219,246`; `chassis/src/lib.rs:302`; `chassis/src/furniture.rs:959,1003,1072,1202,1220,1273`; `chassis/src/cabinet.rs:511`; `config/src/profile.rs:509-512,569,660,784`; `config/src/toml.rs:648-651,681`; `app/tests/profile_cli.rs:146,225,239,308,332`; `app/tests/settings_live_reload.rs:278,291`; `app/tests/bank_column.rs:661`) are single-shell fixture setups/name lookups, not count-assuming.

### obeyed-in — docs: 2 locations

`docs/config.md:96` — "Built-in chassis names: `Annunciator`, `Slide Rule`, `Switchboard`." `README.md:31-32` — "The cabinets that ship are `Annunciator`, `Slide Rule` and `Switchboard`."

### rg patterns used
```
rg -n "Annunciator|Slide Rule|SlideRule|Switchboard"
rg -n "chassis_presets\(\)"
rg -n "Shell::"
rg -n '"Annunciator"|"Slide Rule"|"Switchboard"'
rg -n "ValueEnum|value_enum"
rg -n "chassis" crates/app/src/cli.rs
```

### Homonyms excluded
- `Shell` the struct in `crates/app/src/shell.rs` (`Shell::event_loop()`, `Shell::new(...).run(...)`) — the app's winit event-loop wrapper, unrelated to `config::Shell`.
- `SwitchboardScrew` (`crates/chassis/src/shells/switchboard.rs:589,811,819`) — an internal drawing-detail type, not a set/count assumption.
- Generic prose uses of "chassis" (dozens of doc-comment hits) referring to the subsystem in general, not the specific 3-shell set.

### Verdict
Gap — 10 non-test + 12 test + 2 docs found, well above the expected 5. Direction: **under-estimated** (the fact is enforced at more independent sites than a blind reader would guess, chiefly because Rust's match-exhaustiveness turns every per-shell rendering function into an obeying site).

---

## Fact 5 — The channel-switch chord is a modifier plus digits

Expected: **4**

### decided-in — 1 primary site (+ 2 immediate supporting definitions)

`crates/app/src/window.rs:1371-1391` — `shortcut_key()`:
```rust
let chord_mod = if cfg!(target_os = "macos") { modifiers.super_key() } else { modifiers.alt_key() };
...
Key::Character(c) if chord_mod && is_digit(c) => self.chord_digit(c.as_bytes()[0], shift)
```
Supporting: `window.rs:3051-3054` (`fn is_digit` — defines the digit range as the whole ASCII digit class); `window.rs:1371-1375` (the `chord_mod` computation, Alt on non-mac / Super on mac).

Note: `window.rs:3035-3040` (`modifiers_changed`) independently re-derives the same Alt/Meta test to detect chord-modifier *release* — a duplicate, not a shared reference — so it is listed under obeyed-in rather than decided-in proper.

### obeyed-in — non-test source: 4

1. `crates/app/src/window.rs:3035-3043` — `modifiers_changed()`, duplicate modifier test to detect release and call `commit_chord()`.
2. `crates/app/src/window.rs:1566-1579` — `chord_digit()`, takes a raw digit byte and feeds it onward.
3. `crates/app/src/chord.rs:86-107` — `ChordInput::feed_digit()`, validates/accumulates digit bytes.
4. `crates/app/src/chord.rs:119-138` — `ChordInput::commit()`, parses the digit string to `u32` plus the `"0"` → slot-10 special case.

### obeyed-in — test: 3 test functions, 11 key-event call sites

All in `crates/app/tests/channel_bank.rs`: `an_alt_digit_chord_selects_the_channel_it_names` (line 218; sends `"1"` 225, `"2"` 230, `"7"` 237); `an_alt_shift_digit_chord_stores_the_session_onto_the_slot` (246; `"7"` 254, `"1"` 266); `zero_names_the_tenth_key_and_two_digits_name_the_key_they_spell` (334; `"0"` 338, `"1"` 343, `"1"` 345); plus `a_channel_switch_triggers_the_degauss_and_a_store_does_not` (`"2"` 374, `"4"`+SHIFT 382, `"1"` 391). The file's own `CHORD` constant (lines 40/42) duplicates the platform-modifier decision for the test harness.

### obeyed-in — docs: 4 locations

`README.md:38-39` and `README.md:215` (2 separate sentences); `docs/keys.md:7` ("The chord modifier is `Alt`, and `Cmd` on macOS."); `docs/keys.md:13-25` (keys table rows + the `"0"`=10 / commit-on-unambiguous-prefix prose).

No UI-rendered hint text exists (the bank draws numerals only, no "Alt+3"-style labels). No config-customizable chord (not present in `docs/config.md`/`docs/config-format.md`).

### rg patterns used
```
grep -rn "Alt" --include=*.rs crates/
grep -rn "Digit0|Digit1|Digit9|channel_bank_key|ModifiersState|Modifiers" --include=*.rs crates/
grep -rn "Alt" README.md docs/*.md
grep -n "fn is_digit|fn chord_digit|is_digit(c)" crates/app/src/window.rs
grep -n "chord|Chord" crates/*/src/*.rs crates/*/tests/*.rs
```
Note: keys are matched textually via `Key::Character` + `is_digit()`, not `KeyCode::Digit0..Digit9` — the latter search pattern returned nothing, which is itself informative (the codebase does not use the winit physical-keycode digit range).

### Homonyms excluded
- `Ctrl+Shift+T` (new-channel) — excluded as a distinct chord: no digit argument, different modifier (`Ctrl+Shift` vs. the bare chord modifier), handled by a wholly separate match arm (`ctrl && shift && c.eq_ignore_ascii_case("t")`) and a separate test. It shares README/docs sentences with the modifier+digit chord purely by topical adjacency.
- `Ctrl+Alt` (rectangular text-selection modifier, `term/src/pointer.rs`/`selection.rs`, `docs/keys.md:56`) and `Alt+PageUp/PageDown` (bank paging, `window.rs:1379-1380`, `docs/keys.md:19`) — both use the chord modifier but bind it to non-digit keys; excluded as a different chord shape sharing only the modifier half.

### Verdict
Agreement — 4 independent non-test obeyed-in sites against an expected 4.

---

## Fact 6 — The window's floor height is 240 pixels

Expected: **3**

### decided-in — 1 site

`crates/chassis/src/layout.rs:24` — `pub const MINIMUM_HEIGHT: i32 = 240;`. Doc comment (lines 15-24) states this is "the one copy: the seam clamp and the window's minimum-size hint are the same rule seen from two sides."

### obeyed-in — non-test source: 3 (all constant-reference, zero hardcoded-literal drift risk)

1. `crates/chassis/src/layout.rs:128` — `min_inner_size(bank_width) -> (bank_width.max(0) + CRT_MINIMUM_WIDTH, MINIMUM_HEIGHT)`.
2. `crates/chassis/src/layout.rs:145-151` — `min_inner_size_physical`, scales the above by `scale_factor`; no separate literal.
3. `crates/app/src/shell.rs:377-382` — `apply_min_inner_size`, calls `min_inner_size_physical` and `window.set_min_inner_size(...)`; this is the actual winit runtime-enforcement site, called at shell.rs:325 (window creation) and shell.rs:363 (bank-width changes). No literal `240` anywhere in this chain.

Note: `crates/chassis/src/seam.rs`'s drag clamp (`SeamContext::characters_at`, seam.rs:99) is a *different* floor (minimum character count / bank width) and does not reference the height floor — not counted.

No other non-test source file independently hardcodes `240` as a height-floor re-derivation (checked all `crates/*/src` for the literal).

### obeyed-in — test: 11 distinct assertion lines (all call through the shared functions, but each hardcodes the literal `240` as an expected value)

`crates/chassis/src/layout.rs:225,226,236,237` (4 direct); `crates/chassis/src/cabinet.rs:418,430` (2); `crates/chassis/src/lib.rs:267,275,319` (3); `crates/app/tests/seam_drag.rs:190` (1); `crates/chassis/tests/bank_frame_geometry.rs:225,229` (1 additional beyond the shared count).

### obeyed-in — docs: 4 hardcoded-literal mentions, no compiler protection

`README.md:71,73` (2 mentions in the same paragraph — the floor statement and the "567 by 240" default-size example); `crates/app/src/shell.rs:18` (doc comment, source-embedded); `crates/app/src/geometry.rs:10` (doc comment, "minimum_height: 240", with line 17 explicitly noting it must track `chassis::layout::MINIMUM_HEIGHT`).

### xtask verify — checked, does NOT independently assert 240

`crates/xtask/src/verify.rs:249-259` only checks `min_width > 0 && min_height > 0` (presence, not the value) and diagnostically prints `min_width - 320` (the *width* floor). Despite the README's claim that `xtask verify` walks the contract item by item, the height-floor value itself is not independently verified there — a gap, not an obeyed-in site.

### rg patterns used
```
rg -n "240"
rg -ni "floor|min_inner_size|MIN_HEIGHT|floor_height"
rg -n "MINIMUM_HEIGHT"
rg -n "set_min_inner_size|min_inner_size"
```

### Homonyms excluded
- `crates/app/src/bank.rs:406-407`, `crates/app/tests/channel_bank.rs:430` — "240px of bank" for three 43px LED rows at 2px pitch — a row-packing coincidence, independently derived from row height × count, not from `MINIMUM_HEIGHT`.
- `crates/term/src/distortion.rs:377` — `(0.4, 240.0)`, a CRT shader parameter tuple.
- `crates/term/src/color.rs:115` — "240 hex triples," a grey-ramp table size.
- `crates/term/tests/pixel_properties.rs:263` — "3240 grey," a substring match, not standalone.
- Cargo.lock checksum substrings containing "240" as digits within a hash.
- `crates/chassis/src/shells/common.rs:323`, `crates/chassis/tests/region_layout.rs:95` — `2400.0`/`2160.0`, an unrelated 2400×2160 test resolution.
- General uses of the word "floor" (dozens) — a design-vocabulary term used for shader opacity floors, `ScalePolicy::Floor` font rounding, `f64::floor()` calls, the chassis's drawn "well floor" surface, and the seam's character-count floor — none about the window's 240px height floor.

### Verdict
Agreement — 3 independent non-test obeyed-in sites against an expected 3.

---

## Fact 7 — The default well width / default window size in logical pixels

Expected: **3**

### decided-in — 2 sites

1. `crates/chassis/src/layout.rs:22` — `pub const CRT_MINIMUM_WIDTH: i32 = 320;` (doc comment: "the one copy" the seam clamp and window min-size hint both read).
2. `crates/chassis/src/layout.rs:127-129` — `min_inner_size(bank_width) -> (i32, i32)`, returns `(bank_width.max(0) + CRT_MINIMUM_WIDTH, MINIMUM_HEIGHT)`; there is no literal `567` anywhere — it is always `bank_width + 320`, and for the shipped default bank width (247, decided elsewhere in chassis furniture defaults — a different fact) that arithmetic yields `567`.

`crates/app/src/geometry.rs:30` — `pub const DEFAULT_SIZE: (u32, u32) = (1024, 768)` is the window's *initial open size*, a different default from the 567×240 *minimum-size* contract; not counted as obeying 320/567.

### obeyed-in — non-test source: 5

1. `crates/app/src/shell.rs:377-381` — `apply_min_inner_size`, calls `min_inner_size_physical(bank_width, scale)`, the live enforcement site (derives from the shared constant).
2. `crates/app/src/geometry.rs:1-13` — module doc restating the 4-number contract, explicitly cross-references `chassis::layout::CRT_MINIMUM_WIDTH` rather than re-deciding it.
3. `crates/xtask/src/verify.rs:254-255` — **independent hardcoded literal** `320`; xtask has no dependency on the `chassis` crate.
4. `crates/xtask/src/snap.rs:288` — **independent, second copy** of the constant: `const CRT_MINIMUM_WIDTH: i64 = 320;`, used by `bank_width()` to recover live bank width from an X11 size hint.
5. `crates/chassis/src/cabinet.rs:55` — module doc referencing "the 320 px the well is never given less than" (documentation, same crate as the constant).

Of these, 2 are genuinely independent hardcodes (`verify.rs`, `snap.rs`); the rest call or document the shared constant.

### obeyed-in — test: 6 distinct file locations (all via the shared function, but each hardcodes the literal expected value)

`crates/chassis/src/layout.rs:225,237`; `crates/chassis/src/lib.rs:267` (asserts `247 + 320` — the literal path to 567), `:275`; `crates/chassis/src/cabinet.rs:430`; `crates/chassis/tests/bank_frame_geometry.rs:225-229`; `crates/app/tests/seam_drag.rs:190`. None assert the bare literal `567` directly — they assert `247 + 320` or (no-bank case) `320` alone.

### obeyed-in — docs: 1 location

`README.md:71-73` — "...wide enough for the channel bank plus 320 logical pixels of screen well. On a default bank that comes to 567 by 240." (`docs/config.md`, `docs/config-format.md`, `docs/keys.md` checked — no mention.)

### rg patterns used
```
rg -n "320"
rg -n "567"
rg -n "well_width|WELL_WIDTH|default.*width|DEFAULT_WINDOW|inner_size\(" -i crates/app/src
rg -n "247\b" crates
grep -n "320\|567\|well.*width\|window size" docs/*.md
```

### Homonyms excluded
- `320`: Cargo.lock checksum substrings (6); `crates/app/src/channels.rs:564` — a doc-comment slice-range example (`:320-341`), unrelated to pixels.
- `567`: Cargo.lock checksum substrings (8); `crates/tmux-cc/tests/transcripts/04-output-octal.txt:21` and `crates/term/tests/fixtures/04-output-octal.txt:21` — octal ASCII dumps containing "...4567890..."; `crates/term/examples/led_diff.rs:7`, `crates/term/tests/font_parity.rs:34` — `"CH 01 AMBER 1234567890"` digit-glyph test strings; `crates/xtask/src/snap.rs:95` — `"0123456789"` deterministic test line; `crates/term/tests/antialias.rs:61`, `pixel_properties.rs:56` — similar digit-glyph strings.
- `crates/app/src/window.rs:2322` ("247 px bank") and `crates/xtask/src/compare.rs:76` (`BANK_WIDTH: u32 = 247`) — these are about the default *bank* width, a different fact, not the well width/window size.

### Verdict
Gap, mild — 5 non-test obeyed-in sites (2 of them genuinely independent hardcodes) against an expected 3. Direction: **slightly under-estimated**, driven mainly by `xtask` duplicating the `320` constant rather than depending on `chassis`.

---

## Fact 8 — The tmux control-mode envelope is DCS 1000 p

Expected: **3**

### decided-in — 2 sites (parse side only; no emit side exists)

`crates/term/src/tmux_cc.rs:26-27`:
```rust
const TMUX_PARAMS: &[u16] = &[1000];
const TMUX_ACTION: char = 'p';
```
and `crates/term/src/tmux_cc.rs:78-79` (`ControlModeTap::hook`): `self.active = params == TMUX_PARAMS && action == TMUX_ACTION;` — the actual comparison deciding "this is the envelope."

No emit side: the client (`crates/tmux-cc/src/codec.rs:59-68`, `Codec::send`) writes plain newline-terminated command lines directly to the gateway PTY and never wraps outgoing bytes in a DCS envelope — only the real `tmux -CC` binary (outside this codebase) wraps its replies. Confirmed by the crate doc, `crates/tmux-cc/src/lib.rs:3-7`.

### obeyed-in — non-test source: 4

1. `crates/term/src/dcs.rs:222` — `DcsParser::intro`: the DCS-introducer final byte flips the scanner into raw-envelope mode specifically because the tap (which just evaluated 1000/p) said so.
2. `crates/term/src/dcs.rs:230-251` — `DcsParser::envelope`: hardcodes that only two-byte `ESC \` (not an 8-bit `0x9C`) closes the envelope — specific to how tmux emits ST for this protocol.
3. `crates/term/src/tmux_cc.rs:78-88` — `ControlModeTap::hook`: assumes any envelope it sees opening is *the* 1000p one.
4. `crates/term/src/tmux_cc.rs:96-101` — `ControlModeTap::unhook`: assumes the closing `ST` belongs to the same 1000p envelope it opened.

(A further site, `crates/tmux-cc/tests/support/mod.rs:282-305`, strips the literal envelope from recorded transcripts but lives under `tests/` and its own doc comment notes "the shipping path does not use this" — counted under tests, not source.)

### obeyed-in — test: 9 literal-byte sites + 2 non-literal live-tmux integration tests

**term** (6): `crates/term/src/dcs.rs:294` (`const DCS: &[u8] = b"\x1bP1000p...\x1b\\AFTER-DCS"`); `crates/term/src/tmux_cc.rs:113` (`TMUX_DCS` same pattern), `:185`, `:220`; `crates/term/tests/transcript.rs:346,412`.

**tmux-cc** (3): `crates/tmux-cc/tests/support/mod.rs:289,302`; `crates/tmux-cc/tests/transcripts.rs:80` (`assert!(!control_stream(&raw).is_empty(), "{name}: no DCS 1000p envelope")`).

Non-literal integration coverage (real `tmux -CC` as oracle, excluded from the literal-byte count but shape-dependent): `crates/tmux-cc/tests/live_tmux.rs`; `crates/app/tests/tmux_flow.rs:163,285,308,351` (with explicit comments about the DCS tap and envelope boundaries).

### obeyed-in — docs: 5 locations

`crates/tmux-cc/src/lib.rs:5` (doc: "`ESC P 1000 p` ... `ESC \`"); `crates/term/src/tmux_cc.rs:1,25,29,39,48,53` (module/const/struct doc comments, counted as one contiguous location); `crates/tmux-cc/tests/transcripts/README.md:4`; `crates/tmux-cc/examples/record.rs:369` (generates the README text above); `crates/term/src/dcs.rs:1-21,115-148` (design-rationale doc for why the bypass scanner exists).

### rg patterns used
```
rg -n "1000p|1000\b|P1000|-CC|control.mode|DCS|dcs"
rg -n "1000p|x1bP1000|P1000|ESC P 1000|DCS 1000|\"1000\""
rg -n "\-CC\b" --include=*.rs
```
plus targeted per-file greps for `\x1bP`, `TMUX_PARAMS`, `TMUX_ACTION`, `control_stream`, `envelope_closed`.

### Homonyms excluded
- `crates/tmux-cc/src/command.rs:47,225` — `CAPTURE_HISTORY: u32 = 1000` / `"-S -1000"`, the `capture-pane` history-line count, unrelated to the DCS param.
- `crates/app/src/tmux.rs:1420` — `"x".repeat(1000)`, a test-string length.
- `crates/app/tests/pointer.rs:242-243` — `DECSET ?1000h`, xterm mouse-click-reporting mode (CSI `?1000h`, a different escape family entirely, coincidental digit overlap).
- `crates/app/src/mouse.rs:131` — SGR mouse-report coordinates (`10000`), coincidental digit overlap.
- `crates/app/src/overlay.rs:27,353` — `Duration::from_millis(1000)` timeouts, no protocol relation.
- `crates/term/src/fonts/raster.rs:15`, `atlas.rs:299`, `fonts/system.rs:385` — font units-per-em (1000-unit em square).
- `crates/config/src/profile.rs:418` — a `10000` float-rounding scale factor.
- `crates/chassis/src/seam.rs:390`, `furniture.rs:1193`, `crates/crt-render/tests/glyph_survival.rs:222` — pixel/ink counts in rendering tests.
- `crates/app/src/window.rs:3134-3200` — `1000x750` window-geometry test dimensions.
- `crates/app/tests/{keyboard_scroll,pointer,ime,seam_drag,shed_notice,pointer_live_settings}.rs` — `scrollback: 1000`, an unrelated config field.
- `crates/term/src/bin/esctest_harness.rs:44,326` — `SCROLLBACK: usize = 1000` and `0x10000` checksum wraparound.
- `crates/app/src/frame_stats.rs:368` — `* 1000.0` seconds-to-milliseconds conversion.

### Verdict
Gap, mild — 4 non-test obeyed-in sites against an expected 3. Direction: **slightly under-estimated**.

---

## Summary table

| # | fact | expected | decided-in | obeyed-in (non-test) | obeyed-in (test) | obeyed-in (docs) | verdict |
|---|---|---|---|---|---|---|---|
| 1 | channel bank side | 4 | 1 | 9 | 9 | 0* | gap — under-estimated |
| 2 | logical vs physical pixel unit | 6 | 9 | 57 | 29 | 0* | gap — substantially under-estimated |
| 3 | config format is TOML | 3 | 1 | 3 | ~25 | 19 (3 files) | agreement |
| 4 | built-in chassis shells | 5 | 2 | 10 | 12 | 2 | gap — under-estimated |
| 5 | channel-switch chord modifier+digit | 4 | 1 | 4 | 3 fns / 11 sites | 4 | agreement |
| 6 | window floor height 240px | 3 | 1 | 3 | 11 | 4 | agreement |
| 7 | default well width / window size | 3 | 2 | 5 | 6 | 1 | gap — slightly under-estimated |
| 8 | tmux DCS 1000p envelope | 3 | 2 | 4 | 9 + 2 integration | 5 | gap — slightly under-estimated |

\* Facts 1 and 2 were not separately scanned for a distinct docs bucket by their sub-agents (README/docs mentions exist for both — e.g. README's "channel bank down one side," "logical pixels of screen well" — but were treated as descriptive prose rather than counted as independent doc-contract sites in those reports).

---

# Facts measured — round 3, set B

Workspace: `/home/weiwu/code/RobCo-Terminal` (8 crates). Read-only measurement.
"decided-in" = the place(s) that define/compute the fact. "obeyed-in" = every
independent site that *assumes* the fact and would have to change if it
changed. Non-test source, tests, and docs are counted separately throughout.

---

## Fact 9 — The GPU backend override env var is `WGPU_BACKEND` (expected 2)

**Decided-in:** nowhere in this repository. `WGPU_BACKEND` is read inside the
`wgpu` crate's own `InstanceDescriptor::new_without_display_handle_from_env`
/ `new_with_display_handle_from_env` constructors — an external dependency.
This codebase never parses the variable itself; it only calls the two
constructors that delegate to it. Stated plainly: the fact is decided
upstream, not in this tree.

**Obeyed-in (non-test source):** 2 sites, both calls to a `_from_env`
`wgpu::InstanceDescriptor` constructor that only work because `WGPU_BACKEND`
is honored by `wgpu`:
- `crates/term/src/gpu.rs:54` — `wgpu::Instance::new(wgpu::InstanceDescriptor::new_without_display_handle_from_env())` (offscreen/headless device, e.g. the pixel-property test harness and CLI headless paths)
- `crates/app/src/gpu.rs:53` — `wgpu::InstanceDescriptor::new_with_display_handle_from_env(Box::new(window.clone()))` (the windowed surface's device)

**Obeyed-in (tests):** none found — no test sets or asserts on `WGPU_BACKEND`
directly (`grep -rln WGPU_BACKEND crates/*/tests` is empty).

**Docs:** `README.md:67` names the variable in prose ("`WGPU_BACKEND` overrides
the choice..."). Not a source site.

**Patterns run:**
```
grep -rn "WGPU_BACKEND" --include=*.rs --include=*.md --include=*.toml .
grep -rln "WGPU_BACKEND" crates/*/tests
```

**Homonyms excluded:** none — the string is unambiguous and only appears in
the two constructor call comments plus the README.

**Verdict:** agreement. 2 independent call sites in this repo, matching the
expectation exactly; the fact itself is legitimately decided outside the
tree (in `wgpu`), which is itself a notable and correctly-measured result —
not a gap, since the README frames it as "the appliance picks a backend...
`WGPU_BACKEND` overrides" without claiming this project parses it.

---

## Fact 10 — The config file's base name and its per-platform directory (expected 2)

**Decided-in**, two constants composed into one function:
- base name: `crates/config/src/toml.rs:32` — `pub const FILE_NAME: &str = "config.toml";`
- directory: `crates/app/src/settings.rs:52` — `const APPLICATION: &str = "robco-term";`, consumed by `crates/app/src/settings.rs:62-64` — `pub fn config_dir() -> Option<PathBuf> { directories::ProjectDirs::from("", "", APPLICATION).map(|dirs| dirs.config_dir().to_path_buf()) }`
- the two are composed at `crates/app/src/settings.rs:69-73` — `pub fn config_path() -> PathBuf { config_dir().unwrap_or_else(|| PathBuf::from(".")).join(config::toml::FILE_NAME) }`

`crates/app/src/paths.rs` explicitly disclaims deciding this: its module doc
says "The config file's path is deliberately *not* here. It is `settings`'s
to decide and record" — confirming the codebase itself treats this as a
single-owner fact.

**Obeyed-in (non-test source):** 1 site — `crates/app/src/main.rs:130-132`:
```rust
let path = match &profile {
    Some(selection) => selection.config_path(),
    None => settings::config_path(),
};
```
This is the only call to `settings::config_path()` / `config_dir()` anywhere
outside `settings.rs` itself (`grep -rln "config_path\|config_dir" --include=*.rs .` returns only `settings.rs`, `main.rs`, and the test file `profile_cli.rs`). Everything else that needs the path (profile saving, profile lookup, the watcher) goes through `settings.rs`'s own internal composition, which is part of the deciding module, not an independent obeying site.

**Obeyed-in (tests):** 2 unit tests in `crates/app/src/settings.rs` (`mod tests`, lines 478-495: `config_path_ends_in_app_dir_and_config_toml`, `profile_path_is_a_sibling_of_the_default_path`), plus 3 sites in `crates/app/tests/profile_cli.rs` (lines 188, 304, 435/453) that call `settings::config_path()` as test scaffolding.

**Patterns run:**
```
grep -rn "config.toml\|\"config\"\|CONFIG_FILE\|FILE_NAME" --include=*.rs crates/config
grep -rln "ProjectDirs\|directories::" --include=*.rs .
grep -rn "settings::config_dir|settings::config_path|config_path()|config_dir()|APPLICATION\b" --include=*.rs crates/app crates/xtask
grep -rln "config_path|config_dir" --include=*.rs .
```

**Homonyms excluded:** `crates/app/src/paths.rs`'s `data_dir`/`cache_dir`/`crash_dir`/`preset_dir` — a separate, deliberately independent directory scheme (`$XDG_DATA_HOME`/`$XDG_CACHE_HOME` + identity) for crash logs and the generated shader/preset cache, not the config file. Excluded because the module doc itself states it is not the config path. `crates/xtask/src/install.rs:99`'s `pub const NAME: &str = "robco-term"` — the packaging identity used for install paths (`bin/robco-term`, desktop file names), a different literal serving a different purpose (build/install layout, not runtime config lookup); excluded as a homonym of the app name, not of the config-directory fact.

**Verdict:** gap, direction: fewer independent sites than expected. Found 1
non-test obeying call site, not 2 — the design deliberately funnels every
config-path need through a single `main.rs` call, so there genuinely is
only one place outside the deciding module that would need to change if the
base name or directory convention moved.

---

## Fact 11 — Bitmap fonts render at integer scale (expected 3)

**Decided-in:**
- `crates/term/src/fonts/sizing.rs:70-78` — `ScalePolicy::apply`: floors or rounds a continuous value and clamps to `>= 1`, the actual float→whole-number conversion.
- `crates/term/src/fonts/sizing.rs:173` — `let texture_scale = policy.apply(computed.screen_scaling * req.window_scaling);`
- `crates/term/src/fonts/sizing.rs:182-186` — `let dpr_scale = if entry.low_resolution { policy.apply(req.device_pixel_ratio) } else { 1 };`
- `crates/term/src/fonts/sizing.rs:190` — `integer_scale: texture_scale * dpr_scale,` — the field the rest of the tree consumes.
- `crates/term/src/render.rs:334-336` — `set_scale`'s `assert!(scale >= 1, "integer scale must be at least 1")`, the receiving-end invariant guard (not itself a computation, but the enforcement point).

**Obeyed-in (non-test source):** 12 independent call sites — well above the
expected 3:
- `crates/term/src/render.rs:391-393` (`pixel_size()`) — assumes physical pixel size is an exact multiple of cell size × scale
- `crates/term/src/render.rs:399-405` (`cells_for_pixels()`) — assumes dividing physical pixels by `cell.width * scale` recovers a whole cell count
- `crates/term/src/render.rs:708,714` (draw path) — scroll-shift and vertex uniform math assume `scale` is a whole multiplier
- `crates/term/src/fonts/sizing.rs:217` (`is_pixel_exact_width`) — assumes `integer_scale` is whole so only `font_width` can add fractional pixels
- `crates/term/src/fonts/sizing.rs:223-224` (`snap_font_width`) — `(cell_width_px * integer_scale) as f64` assumes a whole-pixel denominator
- `crates/app/src/window.rs:150-165` (`chain_geometry`) — divides physical target by `scale`, assumes a near-clean integer multiple
- `crates/app/src/window.rs:224-233` (`logical_cell`) — assumes the renderer's physical cell truly is `atlas.cell * integer_scale`
- `crates/app/src/window.rs:501` — `renderer.set_scale(resolved.integer_scale)` in `Glass::new`
- `crates/app/src/window.rs:1980` — same call in `apply_live_settings` (font/monitor-change path), independent second call site
- `crates/app/src/window.rs:2194` — passes `integer_scale` into the badge subsystem
- `crates/app/src/window.rs:2345-2356` (`shift_physical`) — converts to fraction-of-a-row and back through `scale`, assumes round-trip lands on whole physical pixels
- `crates/app/src/badge.rs:357-471` (`Badge::draw`) — badge quad/texture geometry scales by the same whole multiplier as the grid

**Obeyed-in (tests):** ~11 sites across 6 files: `crates/term/src/fonts/sizing.rs` (`#[cfg(test)]`, lines 253, 289, 336), `crates/term/tests/system_fonts.rs:134`, `crates/term/tests/antialias.rs:125,145`, `crates/term/tests/pixel_properties.rs:196,387,402,408,412,414,439`, `crates/app/tests/size_badge.rs:69`, `crates/crt-render/tests/glyph_survival.rs:142,156`.

**Patterns run:**
```
rg -n "integer_scale" --type rust
rg -n "texture_scale|dpr_scale" --type rust
rg -n "scale" crates/term/src/render.rs crates/app/src/window.rs crates/app/src/badge.rs \
   crates/term/src/atlas.rs crates/term/src/fonts/mod.rs crates/crt-render/src/params.rs
```

**Homonyms excluded:** `screen_scaling` (the continuous pre-floor ratio, not the output); `texture_scale`/`dpr_scale` (the two integer halves — already counted once as part of decided-in, not double-counted as separate obeying sites since nothing outside `sizing.rs` reads them independently of the combined `integer_scale`); `font_scaling`/`base_font_scaling`/`window_scaling` (continuous config knobs feeding `screen_scaling`); `device_pixel_ratio`/`scale_factor` (raw, possibly-fractional OS/monitor DPR, distinct from its floored `dpr_scale` derivative); `normalized_screen_scale`, `ScaleNoiseX/Y`, `degauss.scale_y` (`crt-render/src/params.rs` — unrelated CRT-chain shader uniforms about curvature/noise/degauss geometry); `ScaleContext`/`scale_context` (`atlas.rs` — swash's font-rasterizer scaling context, not this project's `integer_scale`).

**Verdict:** gap, direction: undercount. 12 independent non-test call sites
found against an expectation of 3 — roughly 4x. The README's one sentence
names a single design fact, but grid pixel-size math, cell↔logical
conversion, scroll-shift alignment, font-width snapping, and the badge
overlay's own geometry are each independent places that would break if
bitmap scale went fractional.

---

## Fact 12 — A second instance hands its request to the first (expected 2)

**Decided-in:** the whole single-instance mechanism lives in
`crates/app/src/instance.rs`; the entry point is `pub fn acquire(identity: &str, message: NewWindow) -> Role` at `crates/app/src/instance.rs:130` (flock-guarded Unix socket in `$XDG_RUNTIME_DIR`, `LOCK_EX|LOCK_NB` to decide primary vs. secondary, `send()`/`read_request()` for the one-line wire protocol).

**Obeyed-in (non-test source):** exactly 2 independent sites in `crates/app/src/main.rs`:
- `crates/app/src/main.rs:110-118` — the sending/asking side: builds the `NewWindow` request, calls `instance::acquire(&identity, request)`, and on `Role::Delivered` returns `ExitCode::SUCCESS` immediately without ever creating a window — the process that assumes "if another instance is running, my request was handed to it."
- `crates/app/src/main.rs:230,237-238` — the receiving side: `Role::Primary(mut primary) => { ... primary.serve(move |request| { ... proxy.send_event(ShellEvent::NewWindow(request)); }) }` — assumes a delivered request must be turned into an actual new window on the event loop.

**Obeyed-in (tests):** `crates/app/src/instance.rs`'s own `#[cfg(test)] mod tests` (4 tests: `wire_format_round_trips`, `second_acquire_delivers_to_the_first`, `a_stale_socket_does_not_block_a_new_primary`, `drop_cleans_up`) plus `crates/xtask/src/verify.rs` (lines 312-340, "the single-instance rule" — an external black-box check that spawns two real binary processes and asserts the second's window opens in the first).

**Patterns run:**
```
grep -rln "single.instance|SingleInstance|IPC|ipc|second_instance|already running|lock file|LockFile|socket" --include=*.rs .
grep -n "let identity|\.serve\(|Role::Primary|Role::Delivered|Role::Independent" crates/app/src/main.rs
```

**Homonyms excluded:** `crates/app/src/lib.rs:82-89` (`pub fn identity()`) decides the *identity string* used to name the socket/lock (binary basename), a related but distinct fact from "hands its request to the first" — it decides *who* the primary/secondary negotiate as, not the handoff mechanism itself; not counted as an obeying site for fact 12. `crates/xtask/src/install.rs:99`'s `NAME` const is the packaging identity, unrelated to runtime instance arbitration.

**Verdict:** agreement. Exactly 2 independent non-test sites (the asking half and the serving half in `main.rs`), matching the expectation precisely.

---

## Fact 13 — Slots per bank page / the default channel count (expected 4)

This fact bundles two different things under one slash; they were measured separately.

### 13a. Slots per bank page — does not exist as a fixed value

`crates/chassis/src/bank.rs:164` — `BankGeometry::rows_visible(&self, height: i32, pager_height: i32) -> Option<i32>` computes the number of visible rows **at runtime** from measured pixel geometry (shell metrics, LED/tape display pitch, window height minus chrome and pager footprint). Its own test spells out the arithmetic at `crates/chassis/src/bank.rs:316-317`: `(768 - 61 - 8 - 2 + 2) / 45 = 15.5 -> 15` for a 768px window on the annunciator shell. `crates/app/src/bank.rs:82-88` (`BankPager::settle`) re-derives and caches this on every geometry change (`rows_visible: i32` field, seeded to a placeholder `1` at `crates/app/src/bank.rs:54` only until the first `settle`).

No fixed constant names a default row count anywhere (chassis metrics, `crates/app/src/geometry.rs`, or elsewhere). `crates/app/src/geometry.rs` fixes the default *window size* (1024x768), but the row count that produces at that size (15, per the test above) is a derived measurement, not a named constant.

**Verdict for 13a:** the fact does not exist in the code as a decided value —
it is computed at run time from window and chassis geometry. This is a
legitimate result, not a missing measurement: "not measured" would apply
only if there were no accessor to follow, and here `rows_visible` is a
concrete, traceable accessor whose output is simply never pinned to one
number.

### 13b. Default channel count — 1 channel, page 0 slot 1, at startup

**Decided-in:** `crates/app/src/channels.rs:192-196` — `Channels::start()`:
```rust
pub fn start(&mut self, session: impl FnOnce() -> Option<S>) {
    self.open_channel(0, 1, session);
    self.degauss_armed = true;
    self.degauss_pending = false;
}
```

**Obeyed-in (non-test source):**
- `crates/app/src/window.rs:668-670` — `TerminalSurface::new()`'s sole production call to `channels.start(...)`.
- `crates/app/src/channels.rs:522-524` — `open_tmux_pane`'s greeting-once logic, `... && self.current_channel == 1`, echoes the "slot 1 is where a page's live channel starts" convention (see homonym note).
- `crates/app/src/window.rs:854` — `.find(|r| r.page == page_id && r.channel == 1)` in `attach()`, hardcoding slot 1 as the gateway's berth (see homonym note).
- The "last channel anywhere closes the app" cluster, which assumes the app legitimately starts at exactly one live channel before it can reach zero: `crates/app/src/channels.rs:130-131` (doc) and the `Close::CloseWindow` returns it documents, consumed at `crates/app/src/window.rs:1492` (`self.eof = true`) and `crates/app/src/window.rs:2954` (`log::info!("the last channel is gone; closing")`).
- `crates/app/src/window.rs:3026-3028` — `title()` falls back to the application's own name only because a channel is assumed to always be on the air from startup onward.

**Obeyed-in (tests):** `crates/app/src/bank.rs:248-249` (`set.start(|| Some(1))`), `crates/app/src/channels.rs:881,883` (same pattern), `crates/app/src/channels.rs:1003,1011` (`close_channel(0,1)`/`session_died(0,1)` asserted `== Close::CloseWindow`). Related but distinct: `crates/app/tests/tmux_flow.rs:532,709` assumes single-home-page startup (page count, not channel count).

**Patterns run:**
```
grep -rn "\bslots\b|SLOT_COUNT|slot_count|const.*CHANNEL|const.*SLOTS" --include=*.rs crates/app crates/chassis
grep -n "rows_visible" -r crates/app/src/bank.rs crates/chassis/src/bank.rs
grep -n "fn start\b" -A 6 crates/app/src/channels.rs
grep -rn "channel 1 on page 0|(0, 1)|open_channel(0, 1" --include=*.rs .
grep -rn "the last channel is gone|last channel|channel == 1" --include=*.rs crates/app
```

**Homonyms excluded:** `channels.rs:522-524`'s and `window.rs:854`'s `channel == 1` are about the *tmux gateway convention* ("an attachment's transported channel always sits at slot 1 of its own page"), a different "channel 1" than the home page's startup channel, even though both trade on the same "numbering starts at 1" idiom — listed above because they still obey it, not because they redecide it. README's sample log line "channel 1 on page 0 exited" (`README.md:148`) documents the same fact but is prose, not a source site.

**Verdict for 13b:** the non-test obeying count is 6 independent sites
against a naive expectation nearer 4 — a mild overcount, mainly because the
"last channel closes the app" rule and the window-title fallback are each
independent assumption sites a blind reader would not anticipate.

**Combined verdict for fact 13:** split result — the "slots per bank page"
half does not exist as a fixed fact (computed, not decided); the "default
channel count" half exists, is decided in one place, and is obeyed by 6
non-test sites, slightly above the expected 4.

---

## Fact 14 — Switching channels fires a degauss transient (expected 3)

**Decided-in (the transient itself):** `crates/crt-render/src/degauss.rs:17-19` — `DURATION = 200ms`, `PEAK_BRIGHTNESS = 2.6`, `PEAK_SCALE_Y = 0.97`, plus `Degauss::trigger`/`sample`. The module doc is explicit that this file owns only the effect: "deciding *when* to degauss is the channel-bank state machine's job."

**Decided-in (the wiring rule "switching channels triggers degauss"):** `crates/app/src/channels.rs:398-408` — `set_current()`:
```rust
let moved = page != self.current_page || channel != self.current_channel;
...
if moved && self.degauss_armed { self.degauss_pending = true; }
```

**Obeyed-in (non-test source):** 3 independent sites — matches the expected count exactly:
1. `crates/app/src/window.rs:1609-1611` — `channel_changed()`: `if self.channels.take_degauss() { self.degauss.trigger(Instant::now()); }`, the single funnel that reads the model's flag and actually triggers the render-side transient. (Every user action that can switch a channel — new channel, close, cycle, move, chord select, strip press, post-death check — calls this one funnel rather than triggering degauss independently, so those are not separately-obeying sites.)
2. `crates/crt-render/src/params.rs:107,275-282` — `Params::build(...)` consumes the sampled `DegaussState` (`brightness`, `scale_y`) into the `DegaussBrightness`/`DegaussScaleY` shader uniforms — the render chain's independent consumption site.
3. `crates/app/src/window.rs:2032-2034,2074` — the per-frame build path samples the running transient (`self.degauss.sample(now)`) and hands it to `Params::build` unconditionally every frame, independent of (1), which is what makes the 200ms transient visible after it fires.

**Obeyed-in (tests):** `crates/app/tests/channel_bank.rs:353-396` (`a_channel_switch_triggers_the_degauss_and_a_store_does_not`) and `crates/app/src/channels.rs`'s own `#[cfg(test)] mod tests` (`take_degauss()` assertions at lines 900, 944-965, 1057, 1064).

**Patterns run:**
```
grep -rln "degauss" --include=*.rs .
grep -n "channel_changed|take_degauss|degauss\.trigger" crates/app/src/window.rs
grep -n "fn select_channel|fn move_current_to|fn open_channel|fn open_tmux_pane|fn attach\b" crates/app/src/channels.rs
grep -rn "rows_visible|BankGeometry|CHANNEL_CAP" crates/app/src/bank.rs crates/chassis/src/*.rs
grep -rn "CloseWindow|last channel|== 1\b" crates/app/src/channels.rs crates/app/src/window.rs
```

**Homonyms excluded:** `crates/crt-render/tests/pass_graph.rs:231-315` and `crates/crt-render/tests/contracts.rs:48` test the transient *curve/shader* in isolation (`degauss.trigger(epoch)` with no channel model in scope) — homonyms of "degauss test," not obeying sites for the channel-switch wiring rule. `crates/app/src/instance.rs:338` — `assert_eq!(NewWindow::decode("degauss"), None)` uses the bare word "degauss" as a bogus wire-protocol string in an unrelated parser negative test. No startup- or config-triggered degauss exists: `Channels::start()` explicitly arms degauss only *after* opening the first channel so the initial channel does not flinch, and `degauss_armed` is toggled off/on around bulk internal moves (`move_current_to`, tmux collapse) specifically so those do not fire it — these are anti-triggers, correctly excluded rather than counted.

**Verdict:** agreement. Exactly 3 non-test obeying sites, matching the
expectation precisely.

---

## Fact 15 — Profile resolution order: a saved profile first, then a built-in preset (expected 2)

**Decided-in:** `crates/app/src/settings.rs:150-184` — `pub fn select_profile(name: &str, user_files: bool) -> Result<ProfileSelection, UnknownProfile>`. The order is explicit in the function body: if `user_files`, first check `config_path_for_profile(name).is_file()` (lines 151-171, a saved appliance); only if that branch does not return does it fall through to `config::presets::screen_presets().iter().find(|p| p.name == name)` (lines 172-181, a built-in screen); otherwise `Err(UnknownProfile { .. })` (lines 182-184).

**Obeyed-in (non-test source):** 1 site — `crates/app/src/main.rs:80` — `Some(name) => match settings::select_profile(name, !options.default_settings) { ... }`, the only production call to `select_profile`. Everything downstream (`ProfileSelection::overlay` at `settings.rs:213-215`, `ProfileSelection::config_path` at `settings.rs:195-197`) consumes the already-resolved enum rather than re-deciding the order, so those are not independent obeying sites.

**Obeyed-in (tests):** `crates/app/tests/profile_cli.rs` calls `settings::select_profile` directly at lines 193, 200, 207, 212-213, 318, 433, exercising both the saved-first and preset-fallback branches and the refusal case.

**Docs:** `docs/config.md:117-125` restates the order in prose ("1. A saved profile... 2. A built-in screen preset... 3. Neither: the terminal refuses to start"), and `README.md:203` ("The name is read as one of your saved looks first, then as a built-in screen"). Both are documentation, not source sites.

**Patterns run:**
```
grep -rn "select_profile|ProfileSelection\b" --include=*.rs crates/app
grep -n -B2 -A5 "profile|saved.*preset|preset.*saved" docs/config.md
grep -rn "saved.*first|first.*saved|preset.*second|then.*preset|then.*built-in|resolution order" --include=*.rs --include=*.md .
```

**Homonyms excluded:** none of note — `select_profile`/`ProfileSelection` names are used consistently for exactly this fact throughout.

**Verdict:** gap, direction: fewer than expected. 1 non-test call site found
against an expectation of 2 — the CLI funnels every `--profile` resolution
through a single call in `main.rs`; there is no second production
consumer that re-derives or re-checks the order.

---

## Fact 16 — The default screen preset name is "Default Amber" (expected 2)

**Decided-in:** `crates/config/src/schema.rs:199-206` — `impl Default for ScreenSettings`, doc comment: "The 'Default Amber' look, the terminal's default screen: first entry of the built-in screen list... so it is the screen the terminal actually ships wearing." Body: `name: "Default Amber".to_string(), ...`. `crates/config/src/presets.rs:21-23` composes on top of this without restating the literal: `screen_presets()` returns `vec![ScreenSettings::default(), ...]`, doc: "Index 0 is the default screen itself" — an accessor of the decided fact, not a second decision.

**Obeyed-in (non-test source):** 1 site — `crates/xtask/src/main.rs:109` — `#[arg(long, default_value = "Default Amber")] profile: String` on `xtask verify`'s CLI, a second, independent literal spelling of the same string as the built-in binary's own default, used to pick which profile `xtask verify` exercises by default.

**Obeyed-in (tests):** every other occurrence of the literal `"Default Amber"` in the tree is inside `#[cfg(test)]` or a `tests/` file: `crates/crt-render/tests/contracts.rs:335`, `crates/app/tests/profile_cli.rs:125,172`, `crates/app/tests/settings_live_reload.rs:290`, `crates/app/tests/profile_pixels.rs:35` (`const DARK: &str = "Default Amber"`), `crates/config/src/lib.rs:207,210` (`mod tests`), `crates/config/src/toml.rs:720` (`mod tests`, starting at line 370), `crates/config/src/profile.rs:651` (`mod tests`, starting at line 495).

**Patterns run:**
```
grep -rn "Default Amber|DEFAULT_SCREEN|default_screen_preset|default_preset" --include=*.rs .
grep -rn "\"Default Amber\"" --include=*.rs .
grep -rn "screen_presets()\[0\]|presets()\[0\]|screen_presets().first|Index 0" --include=*.rs crates/config crates/app
```

**Homonyms excluded:** comment-only mentions do not count as source obedience: `crates/term/src/color.rs:39` ("Amber, the 'Default Amber' phosphor profile..."), `crates/chassis/src/displays/led/mod.rs:139`, `crates/app/src/settings.rs:546,570`, `crates/app/src/gpu.rs:101` — all doc/prose references, not code that would break if the name changed. `docs/config.md:91,142,173,248,260` are documentation, counted separately from source.

**Verdict:** gap, direction: fewer than expected. 1 non-test obeying site
found (the `xtask verify` CLI default) against an expectation of 2 — no
second production code path duplicates the literal; every other appearance
outside the deciding module is a test assertion or a comment.

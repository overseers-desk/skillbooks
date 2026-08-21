# Revival: `crates/config/src/lib.rs` and `crates/config/src/schema.rs`

The two widest gaps on the table. Estimator 3 (lib) and estimator 1 (schema).
Given the measured figures and the instruction to check the instrument before the cause. Read-only.

## `crates/config/src/lib.rs` — guessed A=1 B=2 C=2; measured A=16 B=31 C=231

**Count check: holds.** Re-derives to 32 files against the tool's 31. Twenty-six are outside the crate and import `Config` or reach it through `config::`; five or six are the crate's own other modules; one is `docs/config-format.md`. The corpus is fair, and the docs belong in it — a program whose settings UI is a text file has its schema's names in its documentation by definition, and a reader meets those files. `Config` was the word to suspect as ambiguous; it names no unrelated type in this tree.

**Mechanism.** One struct is the authoritative container for every runtime setting, and every subsystem takes it: `app/src/settings.rs` (28 mentions), `app/src/window.rs` (28), `chassis/src/cabinet.rs` (14), `crt-render/src/params.rs`, which reads the `raw_frame_*` accessors to compute shader uniforms.

**Disposition: by design.** A settings container's job is to be reachable from everywhere that reads a setting. Sixteen type consumers is that job done, not scattering.

## `crates/config/src/schema.rs` — guessed A=1 B=4 C=8; measured A=17 B=23 C=324

**Count check: holds, with one contaminated word.** The vocabulary is eight types — `GeneralSettings`, `ScreenSettings`, `ChassisSettings`, `Rasterization`, `FontSource`, `ChannelIndicator`, `ChannelDisplay`, `Shell` — plus their fields and variants. **`Shell` is the contaminated one**: `app` has an unrelated `Shell` (the winit event loop's window bookkeeping), and roughly 74 of the 324 sites are matches on that word, not all of them this module's. The sampled vocabulary alone re-derives to 19 files; four more carry the unambiguous remainder, so B=23 stands. C should be read as an upper bound.

**Mechanism.** The three persisted configuration groups are defined here, embedded as fields in `Config`, and serialised to TOML; anything that writes, reads or asserts about a settings blob names them.

**Disposition: by design, with one scattering risk named.** The schema's types must be visible wherever settings are serialised. But `crates/config/src/presets.rs` hand-writes a full `ScreenSettings` and `ChassisSettings` literal for each built-in preset — twelve-odd presets times two types, twenty-four-plus struct literals that a new schema field has to be added to one at a time. That is a maintenance surface the reference-graph figure does not show, and it is the one part of this flag the owner may want to act on.

# Fact: unit a screen coordinate is carried in

**Instrument check.** The 8 non-test files (window.rs, column.rs, size.rs,
shell.rs, cabinet.rs, badge.rs, layout.rs, paint.rs) all genuinely assume or
convert a unit — none is a bystander. Re-grepping `scale_factor` inside just
those 8 gives 91, not 78; the gap is mostly shell.rs's dead default
(`scale_factor_changed(&mut self, _scale_factor: f64) {}`) and doc-comment
mentions. Correcting for those: **~84 real sites**, close enough that the
instrument holds — the count was not an artefact, just a slightly different
threshold for "site."

**Mechanism.** No unit-carrying type inside the app's own domain: `Viewport`
(term::size.rs) stores `width: u32`/`height: u32` documented "physical" and
`cell: CellSize` documented "logical" — comments, not compiler enforcement.
Only at the winit edge (shell.rs, window.rs) does a real type distinguish
them, via winit's own `PhysicalPosition<f64>`/`PhysicalSize<u32>`. Past that
edge it's bare `f64`/`u32`, and the logical↔physical multiply/divide is
reimplemented independently at least three times: `Viewport::physical_cell`,
`chassis::cabinet::bank_width_physical`, `chassis::layout::
min_inner_size_physical`, plus ad hoc inline arithmetic in `window.rs`
(margin conversion copy-pasted at 4 call sites) and `column.rs` (`well_ruler`,
`scale_rect`). The pointer round-trip crosses it live: `window.rs::logical_x`
divides a winit `PhysicalPosition` by `scale_factor` before
`distortion::correct_distortion`, and `distortion_params` re-multiplies the
config's logical margin by `scale_factor` for the forward map.

**Cost of switching to physical-everywhere:** roughly 10–12 independent
edits — the 3 named conversion functions (delete), ~5 inline sites in
window.rs, 2 in column.rs, 1 in badge.rs, plus config/schema defaults
currently stated in logical units.

**Verdict: scattered.**

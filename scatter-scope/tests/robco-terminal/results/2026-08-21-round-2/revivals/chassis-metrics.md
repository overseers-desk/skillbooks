# crates/chassis/src/metrics.rs

**Instrument check.** No single word carries the count the way `params` did last time.
`annunciator` is the largest contributor (109 of 348, 31%) but it is a genuine three-way
homonym: `chassis::shells::annunciator` (a separate 603-line module), `metrics.rs`'s own
`shells::annunciator()` composer, and the generic config/preset string `"annunciator"`
in docs and shell files. The remaining 69% is spread thinly across real, distinctive
names (`ShellMetrics`, `LedMetrics`, `TapeMetrics`, `DisplayMetrics`, `casting_color`,
`column_gap`, `dot_pitch`, `pad_cells`, …) across bank.rs, cabinet.rs, lib.rs, frame.rs,
furniture.rs, seam.rs, shells/*, displays/*/metrics.rs, and config's schema/profile —
that's real, not collision. The 24 leaked files are mostly chassis's own tests (correctly
excluded from A as tests) plus six genuine `annunciator`-only single-mentions.

**The shared-name question.** `unit_width`/`min_units`/`width_for_units`/
`height_for_pad_cells` are one contract, not duplicated arithmetic: `metrics.rs` declares
the `DisplayMetrics` trait once, each impl's doc says "Arithmetic owned by
`displays::{led,tape}::metrics::…`" and delegates there; `cabinet.rs`'s `Display` enum
just dispatches between the two impls. Tests literally assert `..._matches_the_defining_formula`.

**Verdict: by design.** This module is the chassis crate's real measurement hub (9 genuine
callers), read widely because that's its job; `annunciator` adds modest homonym noise on top.

# Standard answer

Known ground truth for this repository, established by hand before the methodology was written. A passing report flags all three and closes each with a verified count and the mechanism.

| Concept | Expected flag | Count that should hold | Mechanism |
|---|---|---|---|
| the window module (`crates/app/src/window.rs`) | hub: far more type consumers and dependencies than a window module of this program should have | on the order of a dozen type consumers; a dozen-plus modules drawn on | it holds surface, channel, gateway and geometry concerns in one file |
| the tmux gateway module (`crates/app/src/tmux.rs`) | leak: fewer type consumers than expected, far more files mentioning its vocabulary | about one type consumer; about thirty files mentioning its names; hundreds of sites | most carriers are by design (a sibling crate named for the protocol, a lower crate that cannot import upward, prose); the channel model's own per-row tmux fields are the owner's reading of 2026-08-21: a decision written per channel where it belongs to the bank (who manages a bank is a property of the bank), so the disposition is misplaced, not scattered; a run may read the same carrier as a shared vocabulary behind one translation seam, and both readings are on record |
| which side the channel bank sits on (a decided-once fact) | more places than expected | around thirteen functional sites, no constant or config naming the side | consumers take the bank width as a scalar and rebuild the geometry; the layout type's rectangles are not read |

Shared vocabularies (configuration schema, layout types, colour) may be flagged on type consumers; "by design" is the expected disposition for them.

# crates/crt-render/src/params.rs

**Instrument check.** Of the 380 total B-mentions, 361 (95%) are the single word
`params`. It is not distinctive: `vte`'s own `Params` type is what `crates/term/src/dcs.rs`,
`tmux_cc.rs`, and `bin/esctest_harness.rs` are handling (DCS/CSI escape-sequence
parameters, an unrelated concept from a different crate), and most of the chassis and
app test files (`bank_column.rs` alone: 63 hits) use a local helper literally named
`param`/`params` for their own shader-oracle test fixtures. None of these are callers
of this module's `Params` struct. `Geometry`, the module's other public type, is
uniquely defined here and contributes only a normal-sized share (18 files) — it is not
the driver.

So the leak of 34 B-files and the C=380 blowup is a lexical collision: the vocabulary
extractor kept `params` as "distinctive" (5+ chars, not a dictionary word by its
filter) without checking that it is also the generic, conventional name Rust code
uses for "the arguments I was passed," independent of this module. A=4 and D=8 (vs.
my A=2, D=2) look like ordinary estimation misses on a real, moderately-connected
module, not artefacts.

**Verdict: artefact.** The B/C explosion is the instrument counting an extremely
common parameter name, not genuine references to this module.

# crates/app/src/channels.rs

**Instrument check.** The vocab list includes `Nothing` — a `Close::Nothing` enum
variant channels.rs alone defines, but also an ordinary English word. It appears
in 43 of the 44 B files (~58 raw line matches), almost always as prose ("Nothing
here creates one", "Nothing is lost", "Nothing survived it") in comments and docs
completely unrelated to the enum. It alone accounts for most of the B-file spread
and a large share of C. Secondary contributors — `Channels` (8 files), `Close` (7),
`window_id` (7) — are generic enough to pick up unrelated hits too. The
dictionary-word filter was meant to catch exactly this and let a capitalized
common word through.

**Structural signal underneath.** A = 2 (bank.rs, window.rs), D = 0: measured
coupling says this module is a tightly encapsulated, dependency-free data model
consumed by exactly the two places that should consume it — matching its own doc
line as "the channel model." That is a small, ordinary footprint, not a scattered
one.

**Verdict: artefact.** The B/C blowup is the vocabulary extractor's leaked
dictionary word (`Nothing`), not a property of the code; A and D show a normal,
well-contained module.

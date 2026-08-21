# Decided-once facts: expected against measured

The estimators named these before seeing anything measured. Expected is the median of the estimates that named the fact (all three named some, only one or two named others; the count behind each median is shown).

**Only the first fact was drilled.** It was the one the brief required by kind and the one all three named, and it got a read-every-hit pass in `revivals/fact-bank-side.md`. The rest carry a first-pass grep of the obvious names, counted as files, and are marked accordingly. A grep count of files is not a count of independent sites: it is the cheap upper bound, and a fact whose pattern is a common word has no usable number at all. Those are recorded as **not measured** rather than given a figure the run cannot defend.

| fact | expected (n) | measured | gap log3 | flag |
|---|---|---|---|---|
| which side the channel bank sits on | 10 (3) | **9 functional sites**, 13 prose, >=15 tests, 1 canonical definition | see below | see below |
| the config file's format is TOML | 9 (3) | 15 files (8 source, 4 test, 3 doc) | +0.46 | — |
| the unit a coordinate is carried in | 10 (2) | 14 files (9 source, 5 test) | +0.31 | — |
| the window's minimum size | 6 (3) | 12 files (10 source, 2 test) | +0.63 | — |
| switching channel triggers a degauss | 6 (3) | 17 files (8 source, 8 test, 1 doc) | +0.95 | — |
| the terminal core is rio-vt | 4.5 (2) | 22 files (17 source, 5 test) | **+1.44** | high, undrilled |
| one gateway channel per attachment | 8 (3) | not measured — `gateway` also names the channel kind, the title, the key and the home slot; a file count is not a site count | — | — |
| presets are name-keyed, config is a diff against them | 9 (3) | not measured — `preset` names the built-ins, the slang preset file and the crt-render preset module alike | — | — |
| Alt+digit selects a channel, numbering is 1-based | 6.5 (2) | not measured — `slot` is the bank's own word throughout | — | — |
| curvature forward to the picture, inverted for the pointer | 9 (3) | not measured — pattern too loose | — | — |
| the grid is measured in cells | 12 (1) | not measured — `cells`, `cols`, `rows` are the domain's words | — | — |
| colours are RGBA | 11 (1) | not measured | — | — |
| three chassis shells, each with its own geometry | 12 (1) | not measured | — | — |
| two channel display kits, LED and tape | 11 (1) | not measured | — | — |
| the GPU backend is chosen at runtime | 6.5 (2) | not measured | — | — |

## The bank side, against its expectation

The estimators were asked for "the number of places in the code you would expect to have to edit if the fact changed". Read against that question, the comparison is not the functional sites alone:

| reading | measured | gap log3 | flag |
|---|---|---|---|
| functional sites only | 9 | −0.10 | none — agreement |
| everything that must be edited: 1 canonical + 9 functional + >=15 tests + 13 prose | **>=38** | **+1.22** | **high** |

The test half of the second figure is a lower bound: the drill audited `chassis/src/seam.rs`, `cabinet.rs`, `frame.rs` and `layout.rs`, and `crates/app/tests/seam_drag.rs` (26 hits on the bank-width and seam patterns) was not exhausted. Both readings are reported because they say different things and the second is the like-for-like one. On the narrow reading the fact is unremarkable. On the reading the estimators were actually asked for, moving the bank to the other side is a 38-place edit against an expectation of ten.

What makes it a finding rather than an arithmetic quibble is the thing neither figure shows: **the side is not named anywhere.** No constant, no type, no enum, no config key. `WindowLayout` publishes two rectangles but never a which-side fact, so nothing forces a call site through them, and nine of them took the derived scalar and rebuilt the geometry instead. The fact is decided in one place and *assumed* in nine more, and the compiler would report none of them.

## `rio-vt`, flagged and not drilled

Seventeen source files name the emulation core. The estimators expected four or five, on the reasonable view that a vendored VT core is reached through one adapter. This run does not know whether those seventeen are the core's types travelling or the word appearing in prose, because it was not drilled. Recorded as an open flag for a later run, not as a finding.

# The instrument, checked

## The capitalised-English hole in the vocabulary filter

`scope-count.py`'s `keep()` admits any capitalised name unconditionally ("capitalised type
name, matched case-sensitively"), so an enum variant or type named after an ordinary English
word enters the vocabulary and then matches prose. Measured over the flagged rows: `C bad` is
the share of C that comes from vocabulary entries that are single capitalised English words
with no underscore and no inner capital.

| module | B | B files hit by such a word | C | C from such words | the words |
|---|---|---|---|---|---|
| `crates/xtask/src/main.rs` | 10 | 10 | 10 | 10 | Compare, Contract, Install, Verify |
| `crates/chassis/src/furniture.rs` | 10 | 9 | 55 | 41 | Piece, Plate |
| `crates/crt-render/src/chain.rs` | 19 | 18 | 75 | 50 | Applied, Chain, Parameters, Rebuilt |
| `crates/crt-render/src/preset.rs` | 18 | 12 | 61 | 32 | Scale, Structure |
| `crates/crt-render/src/pacing.rs` | 12 | 9 | 62 | 29 | Pacing |
| `crates/term/src/gpu.rs` | 14 | 9 | 50 | 23 | Target |
| `crates/app/src/channels.rs` | 44 | 42 | 306 | 90 | Channels, Close, Detach, Nothing, Removed |
| `crates/term/src/session.rs` | 31 | 10 | 178 | 45 | Pumped, Session |
| `crates/config/src/toml.rs` | 25 | 14 | 172 | 28 | Boolean, General, Integer, Parse, Scalar, Screen |
| `crates/term/src/fonts/sizing.rs` | 15 | 10 | 136 | 18 | Floor, Round |
| `crates/crt-render/src/params.rs` | 38 | 14 | 380 | 46 | Geometry |
| `crates/config/src/schema.rs` | 23 | 10 | 348 | 24 | Switchboard |
| `crates/term/src/fonts/mod.rs` | 27 | 4 | 125 | 8 | Bundled, System |
| `crates/app/src/tmux.rs` | 31 | 2 | 328 | 2 | Capture, Detached, Intent |
| `crates/term/src/viewport.rs` | 33 | 0 | 280 | 0 | Glide |

Twelve of the thirty flagged rows have a capitalised English word in their vocabulary. On
`channels.rs` one such word, `Nothing`, appears in 42 of the 44 B files, almost all of it
prose. The fix belongs in the tool: apply the dictionary test to capitalised names too, unless
they carry an underscore or an inner capital.

## The lowercase collision the dictionary cannot catch

`params.rs` fails a different way: `params` is not an English dictionary word, so it survives
the filter, and it is the single most conventional identifier in Rust for "the arguments I was
handed" — plus the name of `vte::Params`, an unrelated type three `term` modules handle. 361
of that row's 380 sites are the bare word. No dictionary fixes this; a name that is a
programming-language commonplace needs its own stop list.

## The stem, when the stem is the domain's word or another module's type

The tool adds the file stem to the vocabulary unless the dictionary holds it. Two flagged rows
in this run are the stem and nothing else:

- `crates/app/src/tmux.rs`: of 328 sites, nearly all are the bare word `tmux` — the external
  program the whole feature is named after. `crates/app/tests/tmux_flow.rs` 47 of 47,
  `crates/app/src/channels.rs` 34 of 34, the whole `tmux-cc` crate, `term::tmux_cc`,
  `term::tmux_pane`, the README, both `Cargo.toml`s. The module's actual API
  (`GatewayEvent`, `PaneGate`, `WindowAdded`) is used by one file.
- `crates/term/src/viewport.rs`: 230 of 280 sites are the bare stem `viewport`, and most are
  homonyms — `term::size::Viewport` is a *different struct in the same crate* (74 hits in
  `app/window.rs` alone), `viewport`/`viewport_size` are generic shader-math parameters in two
  oracle modules, and `librashader` has its own `Viewport` in `crt-burnin`.

A stem is a good vocabulary word when the module owns the word. It is a bad one when the word
is the domain's (a tmux integration in a program whose feature is tmux) or when another type of
the same name lives elsewhere. Neither case is caught by a dictionary.

## B is not reproducible across index decoders; A is

Round 1 of this run series measured the same commit of this repository with the same tool, the
only difference being that its SCIP protobuf was decoded by `scip print --json` rather than by
`tools/scip2json.py`. Over the 163 rows both rounds share:

- **A: identical on 163 of 163 rows.** Zero drift.
- **B: different on 58 of 163 rows**, some by an order of magnitude —
  `crates/chassis/src/shaders.rs` 39 → 3, `crates/app/src/channels.rs` 8 → 44,
  `crates/term/src/viewport.rs` 5 → 33, `crates/term/src/cells.rs` 35 → 8.

The cause is upstream of the grep: the two decoders assign the definition role to different
symbol sets, so the vocabularies differ, and B is only as stable as the vocabulary. This is
the sharpest available statement of the methodology's own claim that "A is the figure that
carries the low side": here A carries everything, and B carries a number that depends on which
decoder read the index.

A run that wants B to be comparable across rounds must pin the decoder and record it. This run
records it: `tools/scip2json.py`.

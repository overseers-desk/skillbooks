# degauss.rs revival

**Instrument first.** The B files are all expected: this crate's own tests (`pass_graph.rs` 34 sites, `contracts.rs` 27, `burn_in_chain.rs`, `glyph_survival.rs`, `support/mod.rs`), its own `Cargo.toml`, `lib.rs`, `chain.rs`, `params.rs`, and the app-side consumers (`window.rs`, `channels.rs`, `column.rs`, `instance.rs` and their tests). Nothing outside a reader's expectation.

No double duty from this side of the collision. On window.rs's side the lowercase `degauss` looked like a shared, ambiguous word; from here it isn't ambiguous at all: `Degauss`/`DegaussState` are genuinely defined in this file (107 lines), and every lowercase `degauss` site in the B list is either this file's own field/method name or a caller's field of this exact type (`window.rs: degauss: Degauss`, `channels.rs`, `instance.rs`). The collision was one-sided: window.rs's local name colliding with an import; this file's name is the thing being imported instead.

C=124 is heavy but genuine: two crt-render tests (`pass_graph`, `contracts`) alone contribute 61 sites exercising `DegaussState`/`PEAK_BRIGHTNESS`/`PEAK_SCALE_Y` across many uniform/structure cases, normal for a small, load-bearing render-hook type with a fixed public contract (D=0, no dependencies, the doc line states its whole job).

**by design**

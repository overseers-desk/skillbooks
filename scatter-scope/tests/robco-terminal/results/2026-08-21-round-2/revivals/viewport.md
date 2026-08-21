# term/viewport.rs — flagged-module check

**Instrument check.** A=3 matched exactly; B/C blew out to 33/280. The
capitalised-English filter is not the cause here (0% of C). The bare stem
`viewport` is: 230/280 mentions (82%), and it is a homonym. Three unrelated
things share the spelling:

1. `term::size::Viewport` — a *different* struct (window/scale geometry),
   imported and used at `crates/app/src/window.rs` (74 hits, mostly `self.
   viewport: Viewport`, `viewport.term_size()` — nothing to do with scroll).
2. Shader-math parameter naming, `viewport`/`viewport_size: [f32;2]` in
   `chassis/oracle.rs` (9), `crt-render/oracle.rs` (7), `shells/common.rs`
   (8), `layout.rs`, `shells/{annunciator,mod}.rs` — pixel-extent args to
   SDF/noise functions, no relation to scrollback.
3. `librashader`'s own `Viewport` type, constructed in `crt-burnin/{chain,
   headless}.rs` and `MOUNT.md` — a third-party GPU type.

Strip those and the real scrollback vocabulary (`ScrollPosition`, `to_bottom`,
`page_up`/`page_down`, `WHEEL_GLIDE`, `is_following`, `scroll_wheel`) lands
almost entirely in the 3 A files plus their tests (`scrollback.rs` 68,
`transcript.rs` 23, `keyboard_scroll.rs` 7, `pointer*.rs` 9) — proportionate
to a small, well-used policy type.

**Verdict: artefact.** The file-stem match on a common graphics word
(`viewport`) collided with two other `Viewport` types and generic shader
parameter naming; the true reference count is close to A.

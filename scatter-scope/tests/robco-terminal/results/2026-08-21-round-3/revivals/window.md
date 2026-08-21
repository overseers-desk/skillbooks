# window.rs revival

**Instrument first.** B/C are inflated by a word collision, not scatter. `degauss` is window.rs's field/method name (`degauss: Degauss`, `degauss_state()`), but `Degauss`/`DegaussState` are *defined* in `crates/crt-render/src/degauss.rs` and imported (`use crt::{Chain, Degauss, ...}`). Every crt-render hit (`degauss.rs`, `params.rs`, `chain.rs`, `lib.rs`, `Cargo.toml`, and four crt-render test files: 33 sites total, matching the reported leak of 33 exactly) is that crate talking about its own type, not about window.rs. Those files hold no facts of window.rs's; they're a false B/C signal.

Past that, the real driver of C=254 is legitimate: `TerminalSurface` is genuinely defined here (line 316) and is the one struct the app's test suite drives, with `channel_bank.rs` (48 sites), `ime.rs` (38), `tmux_flow.rs` (22), `keyboard_scroll.rs` (20), and `pointer.rs` (17) each calling its methods repeatedly. High mention count from heavy exercise of one public type, not duplication.

**Hub check.** window.rs's `chord_*` and `seam_*` methods look like scatter but aren't: `chord.rs` and `seam.rs` each say explicitly the policy is theirs, that "the host (crate::window) owns the keys." window.rs is documented wiring, not a reimplementation.

**by design**

## Hub check (D=46, largest in the run)

Walking every impl block and use list by region:

- Glass ctor (250-566): assembles crt::Chain, term::build_font; glue.
- ctor + gateway pump/attach/collapse (573-1046): policy is crate::tmux::Gateway; here it only dispatches its events onto channels rows.
- IME + keyboard (1083-1366): bridges term grid to winit::Ime, no IME logic of its own.
- shortcuts/channel/chord (1366-1786): chord.rs documents window.rs as its host; channel model is app::channels.
- relayout/apply settings (1786-1995): decides *when*, calls term::resolve, cabinet.apply_config, settings::distortion_margin; the formulas live in those crates instead.
- draw_frame/sync_geometry (1995-2276): one GPU encoder ordering term::render, crt::chain, chassis::column, badge draws; has to be one place.
- pointer/mouse mapping (2276-2454): bridges winit, term::pointer, term::mouse vocabularies only.
- seam/selection/clipboard (2454-2696): seam.rs documents this as its host; logic lives in term/app::clipboard.
- Surface trait impl (2696-3049): the one required implementation site.
- unit tests (3049-3206).

No region holds a subsystem's own implementation; each holds dispatch, sequencing, or type-bridging between crates that cannot know about each other. D=46 is breadth of coordination, not duplicated logic.

**by design**

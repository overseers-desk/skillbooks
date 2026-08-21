# crates/app/src/tmux.rs

**Instrument check.** Capitalised-English isn't the leak here — the vocab
rule also adds the file's own stem, `tmux`, to the word list, and that bare
5-letter token is doing nearly all the work. Per-file: `tmux_flow.rs`
47/47 mentions are the bare word; `channels.rs` 34/34; `tmux-cc/tests/
support/mod.rs` 22/22; `record.rs`, `term::tmux_cc`, `term::tmux_pane`,
`event.rs`, `command.rs`, `escape.rs`, `lib.rs`, transcripts, README, both
Cargo.tomls — same story, exact or near-exact matches. Of 328 mentions,
the overwhelming majority are the domain word "tmux," not this module's
actual API (`GatewayEvent`, `PaneGate`, `WindowAdded`, …), which only
`window.rs` uses at all — those 24 real hits live in `window.rs` alone.

**Mechanism.** `tmux-cc` (the wire codec) and `term::tmux_cc`/`term::tmux_pane`
(the DCS tap and pane session) are lower layers app::tmux sits *on*; they
cannot import upward into app, so they legitimately talk about tmux — the
external program and protocol — in their own vocabulary, independent of this
module. The stem match conflates "mentions the tmux feature" with "uses
this gateway's types."

**Verdict: artefact.** A=1, D=4 is the real shape: a thin policy layer over
`tmux_cc`/`ControlModeTap`, changed alongside window.rs and its two test
files; the other ~28 files never touch it.

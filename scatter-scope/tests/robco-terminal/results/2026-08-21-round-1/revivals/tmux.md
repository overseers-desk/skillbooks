# Revival: `crates/app/src/tmux.rs`

Estimator 3 (furthest off: guessed A=4, B=8, C=14; measured A=1, B=30, C=326, leak 29).
The only module in the workspace showing the leak signature — low on A and high on B at once.
Given the measured figures and the instruction to check the instrument before the cause. Read-only. One follow-up was sent after the first reply; the second half of the mechanism below is its result.

## 1. Count check

The B files re-derive to 31 against the tool's 30 — a one-file difference in filtering, not a disagreement about what is there. No vocabulary word is a dictionary word repurposed here; `tmux` is a program's name and means one thing throughout the tree. The corpus held nothing a reader would not meet: `.claude/`, which holds sixteen session files that mention the module heavily, was excluded. The site count re-derived to 385 against 326, the difference being manifest lines and doc-comment-only mentions the tool's word boundaries treat differently. **The count holds.**

## 2. Mechanism — four carriers

**A sibling crate shares the name.** `crates/tmux-cc/` is the control-mode codec: 21 files under that directory carry the word, and `crates/app/Cargo.toml` declares the dependency. The module's own doc says it is named for the protocol as the crate is.

**A lower layer re-spells the concept because it cannot import upward.** `crates/term/src/tmux_cc.rs` (the `DCS 1000 p` envelope and its tap) and `crates/term/src/tmux_pane.rs` (the session variant a pane feeds) sit under `app` and must handle the same domain without being able to name `app::tmux`'s `Gateway`. Thirty-odd mentions between them.

**Prose.** `README.md`, `docs/keys.md`, `crates/tmux-cc/tests/transcripts/README.md`, and design doc comments — eleven mentions across four files.

**A second, independent copy of the concept at the same layer.** `crates/app/src/channels.rs` — 39 mentions, the largest single carrier after `tmux.rs` and its own integration test, and the one with no layering excuse, since both modules are in the same crate and neither imports the other. The channel model holds the tmux facts in its own vocabulary:

- `Page`: `tmux_host`, `gateway_home_slot`, `new_window_pending`, `attach_done`
- `Row<S>`: `tmux_window`, `tmux_pane`
- `PageKind::Tmux`; `ChannelKind::{Gateway, TmuxPane}`

These are not passive storage. `channels.rs` routes close operations off them — `Close::KillWindow { .. tmux_window }` for a pane, `Close::Detach` for a gateway — so the same invariants that `tmux.rs` enforces (an attachment means a new page; the gateway takes slot 1; windows start at slot 2) are encoded a second time here.

## 3. Disposition

**Split.** The first three carriers are **by design**: the protocol's name is shared on purpose, the lower layer cannot depend upward, and prose naming a feature is prose doing its job. Together they account for most of the B=30, and no code change would or should close them.

The fourth is **scattering with a real cost**. The gateway concept is not sealed inside `tmux.rs`; the channel model maintains a parallel encoding of the same semantic model, and the two must be kept in step by hand.

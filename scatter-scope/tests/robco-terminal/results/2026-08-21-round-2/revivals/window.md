# crates/app/src/window.rs

**Instrument check.** Vocabulary of 101 names (`AppSession`, `ImeState`,
`TerminalSurface`, `pump_gateways`, `seam_cursor`, …) is distinctive; no
leaked capitalised-English word dominates C, confirming the peer's note. The
34 B files are almost entirely legitimate: 11 are `app/tests/*` integration
suites (`channel_bank.rs` 48, `ime.rs` 38, `tmux_flow.rs` 22, `pointer.rs` 17,
`seam_drag.rs` 11, …) that exist specifically to exercise this module's
behaviour, plus production files that hand it collaborator types (params.rs,
degauss.rs, session.rs, channels.rs, tmux.rs, cabinet.rs). Count holds.

**Mechanism.** `window.rs`'s own `use` block pulls from thirteen crate-local
modules (badge, bank, channels, chord, column, frame_stats, gpu, input,
settings, shell, tmux, clipboard/mouse/paths) plus chassis, config, crt-render,
term (five submodules), tmux-cc and winit — one struct assembling the whole
window: surface, session, chassis, gateways, chord input, selection, IME. D=46
is that assembly job, not duplication. A=1 (only main.rs constructs it) shows
it's an application leaf: its own public surface is cheap to change, but it
must track 46 upstream APIs and is re-verified by 11 test files on any touch.

**Verdict: by design.** The module is the app's orchestrator/hub; wide D and
test-heavy B/C are the cost of that role, not scatter.

# Oracle

Three estimators, cheap tier, each in a fresh context, each given `oracle-brief.md` and nothing else. Replies in `oracle-replies/`.

## Compliance with I1 (the oracle sees no code and no count)

The brief holds the README with installation and build detail cut, a per-crate size table, the doc-file list, and the 110-module list with each module's length and its own `//!` first line. No source line, no measured figure, no suspicion, no concept named beyond the full module list. The two decided-once facts the run wanted were requested **by kind** — "include the side a panel sits on, and the unit a coordinate is carried in" — with no figure attached, which the template permits.

Each estimator was instructed to make exactly one tool call, `Read` on the brief, and to open nothing else. All three complied: one tool use apiece, on the brief.

## Agreement between estimators

Close, as the methodology predicts. Taking every pair of estimators on every module, the median absolute disagreement is 0.37 on a log3 scale for A, 0.26 for B and 0.31 for C — well inside the factor of three the Pick band uses — and 97% of pairs on A and B agree within that factor. The estimators are one instrument with a small spread, not three opinions. The median is guarding against a stray answer, not against bias; bias is systematic and shows up against the measurement, not here.

Two divergences worth recording, because both fell on modules the run went on to flag:

- `crates/app/src/window.rs`: estimator 2 guessed B=18, estimators 1 and 3 guessed 6 and 3. Estimator 2 read the 3205-line length as a signal and the others did not.
- `crates/app/src/shell.rs`: estimator 3 guessed A=10, the others 3 and 1. Estimator 3 took "the window shell: winit event loop, multi-window bookkeeping" for the hub. It is not; `window.rs` is.

## Estimator 3's omission

Estimator 3 returned 109 of the 110 lines, dropping `crates/term/src/distortion.rs`. That module's expected figures are the median of two rather than three. It is not flagged on either A or B, so nothing turns on it.

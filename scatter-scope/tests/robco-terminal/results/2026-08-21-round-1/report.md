# SCOPE — RobCo Terminal, 2026-08-21, round 1

One codebase measured once. Eight crates, 110 source modules, 43,350 lines of Rust, at `/home/weiwu/code/RobCo-Terminal` (branch `main`, `354e8f4`, working tree clean before and after). The repository was not modified; nothing was written into it and no build ran inside it.

The question SCOPE asks is not how coupled this code is. It is: which concepts does it decide in more places than a competent architect, knowing the program's purpose and size but not its code, would expect? Every figure below has an expectation beside it, and only the gap is worked on.

---

## Findings

Three concepts came out of the run with a verified count and a named mechanism. In the order the owner should care.

### 1. `crates/app/src/window.rs` holds six subsystems in one file

**Expected** A=1, B=3. **Measured** A=1, B=25, C=217, leak 24. Gap on B **+1.30**.

The A figure agrees with the estimate and is the wrong direction to look. Turn the graph around and this module draws types from **46 other modules** — the next highest in the workspace is 19 and the median is 2 — while exactly one non-test module draws on it. Eleven integration tests do. This module is not depended on; it is driven.

The revival read its structure and found one 3205-line file holding, beside the `TerminalSurface` type that legitimately lives there: the tmux gateway plumbing (lines 807–1342, whose home is `tmux.rs` beside `Gateway`), the channel-bank keybindings (1343–1780), the window/well division arithmetic (1781–1863, whose home is `geometry.rs`), redraw orchestration (1864–2265), pointer dispatch and coordinate transformation (2266–2443), and the seam interaction (2444–2695). Each pulls from a different dependency domain — the tmux codec, input encoding, GPU rendering, pointer arithmetic, the bank UI — and each carries its own vocabulary out into the tests, which is what produces B=25 against A=1.

**Disposition: scattered, real cost.** Full report: `revivals/window.md`.

### 2. The tmux gateway concept is encoded twice, at the same layer

**Expected** A=4, B=8. **Measured** A=1, B=30, C=326, leak 29. Gap A **−1.00**, B **+1.20**.

The only module in the workspace showing the leak signature — low on type consumers and high on vocabulary spread at once, which is the signature the methodology says ranks first. One module uses its types; thirty files speak its words.

The revival found four carriers and split its verdict. Three are **by design** and close: the sibling crate `crates/tmux-cc/` shares the protocol's name on purpose (21 files), `crates/term/src/tmux_cc.rs` and `tmux_pane.rs` re-spell the concept at a layer that cannot import upward, and prose names the feature in the README and `docs/keys.md`. No code change would or should close those.

The fourth has no such excuse. `crates/app/src/channels.rs` carries 39 mentions — the largest single carrier after `tmux.rs` itself — in the same crate, at the same layer, importing nothing from it. The channel model holds the tmux facts in its own vocabulary: `Page` carries `tmux_host`, `gateway_home_slot`, `new_window_pending`, `attach_done`; `Row<S>` carries `tmux_window` and `tmux_pane`; there are `PageKind::Tmux` and `ChannelKind::{Gateway, TmuxPane}`. These are not passive storage — `channels.rs` routes close operations off them, `Close::KillWindow { .. tmux_window }` for a pane and `Close::Detach` for a gateway — so the invariants `tmux.rs` enforces (an attachment means a new page; the gateway takes slot 1; windows start at slot 2) are maintained a second time, independently, by hand.

**Disposition: three carriers by design, one scattered with a real cost.** Full report: `revivals/tmux.md`.

### 3. Which side the channel bank sits on is named nowhere and assumed in nine places

**Expected** 10 places to edit if the fact changed. **Measured** at least 38 — one canonical definition, nine functional sites, at least fifteen tests, thirteen doc mentions. Gap **+1.22**, and the test half is a lower bound, so the true figure is higher.

`crates/chassis/src/layout.rs:73-82` is the one place the fact is decided: `WindowLayout::new` puts the bank rectangle at x=0 for its own width and runs the well from there to the window's right edge. Most of the `chassis` crate reads those rectangles properly, and about eight readers are genuinely side-agnostic — `chassis_field`'s offset formula `(bank.x - crt.x)/field_w` already generalises to either side.

The leak is at every point that kept the *derived scalar* instead of the rectangle it came from and rebuilt the position arithmetic itself. The seam's grab strip is `bank_width - SEAM_GRAB_INSET`. `cell_at` translates a pointer with `position.x - bank_physical()`. `ime_cursor_area` translates it back with `top_left.x + bank`. `draw_frame` blits the well at `(bank, 0)`. `column.rs:1144` blits the casting at `(0, 0, ...)` with a doc comment saying "at the window's left edge" outright. `strip_pressed` hands window-logical coordinates to a function expecting column-local ones, correct only because `bank.x == 0`. GPU composition, pointer hit-testing and the seam's drag law each arrived at "x=0 is the bank's home" independently.

One thing sharpens this rather than softening it. `crates/chassis/tests/region_layout.rs:65-88` already tests the frame's field mapping **with the bank on the right** — "modelling the bank sitting to the right of a frame that spans the whole window" — and it passes. The chassis crate's geometry is side-agnostic and is tested as such. The assumption is not in the layout; it is in the six `app` call sites and the two in `seam` that never asked the layout.

And the fact has no name. There is no `BankSide`, no `Side::Left`, no `bank_on_left`, no config key — the whole tree was searched. `WindowLayout` publishes two rectangles but never a which-side fact, so nothing forces a call site through them and the scalar shortcut is silently correct today only because `bank.x` happens to be `0.0`. The compiler would report none of the nine.

**Disposition: scattered, real cost.** Full report: `revivals/fact-bank-side.md`; the fact table is `facts.md`.

---

## What closed by design

Fourteen of the thirty-four flags closed as by design, which is the outcome the method expects for a shared vocabulary doing its job.

The two widest gaps on the whole table are the config crate — `config/src/lib.rs` (expected A=1, measured 16) and `config/src/schema.rs` (expected A=1, measured 17). A settings container's job is to be reachable from everywhere a setting is read, and sixteen type consumers is that job done. The revival did name one thing beyond it worth the owner's eye: `crates/config/src/presets.rs` hand-writes a full `ScreenSettings` and `ChassisSettings` literal for every built-in preset — twenty-four-plus struct literals that a new schema field must be added to one at a time. That is a maintenance surface the reference graph does not show. Full report: `revivals/config.md`.

`crt-burnin/src/headless.rs` (B=22, leak 21) closes the same way, with its cost stated in its own module doc rather than discovered: every GPU test in the workspace serialises behind one machine-wide lock, because three concurrent devices segfault. `term/src/cells.rs` (B=35, leak 31) closes as test density around a fixture constructor. Full reports: `revivals/high-leak-four.md`, `revivals/tail-triage.md`.

---

## The instrument

Ten of the thirty-four flags were the tool's fault, not the code's, and the pattern is worth more to the method than any single finding here.

**The stem pollutes when the stem is the domain's word.** `chassis/src/shaders.rs` carried the highest leak in the workspace, 37, on B=39. Its actual distinctive names — `CHASSIS_METAL_SLANG` and its four siblings — appear in **three** files. The other thirty-six matched the file stem `shaders`, in a program whose entire subject is rendering. Corrected B is 3 to 5. The tool drops stems the dictionary holds; `shaders` is not in `/usr/share/dict/words` and sailed through.

**The vocabulary rule cannot see a dependency's names.** `term/src/size.rs` defines `Viewport`; so does `librashader::runtime`, which three modules import. The tool drops a name two *indexed* modules define but has no view of what the crates.io graph defines, so roughly three files were falsely attributed. Corrected B about 16 to 18 against 21.

**The B column is unreliable below about 8.** This is the serious one. The common-English filter drops the words that in a terminal-emulator-drawn-as-hardware *are* the vocabulary: window, colour, scheme, palette, width, height, select, store, entry, device, instance. Ten modules were flagged low as a result, and the sharpest is `crates/app/src/column.rs` — 1307 lines drawing types from nine modules, measuring **A=1, B=1**, because `Column`, `Slot`, `ChainEntry`, `Blit`, `Out` and `Dest` are all dictionary words. `chassis/src/displays/tape/metrics.rs` and `led/metrics.rs` measure B=0 outright: every public name they have is common English. Every low flag on this run's pick table should be read as "the tool had nothing to grep for", never as "well hidden".

Six modules fell off the table entirely for the same reason. Five are `lib.rs`, `main.rs` and `mod.rs`, dropped on purpose because those stems name nothing. The sixth, `app/src/distortion.rs`, is nine lines whose only distinctive name is a stem the dictionary holds.

**A supplementary column earned its place.** The methodology's A measures consumers. For a hub the informative direction is outward, and out-degree from the same index (median 2, one module at 46) is what identified finding 1. It is reported beside the flags and never picked on, since no estimator was asked for it. `count.md` has the distribution.

---

## Calibration, re-checked

The methodology asks each run to re-check the claim that A and B calibrate and C does not. On 104 modules against three blind estimates:

| figure | inside the ±1 band | median gap (log3) | as a factor |
|---|---|---|---|
| A | 90 / 104 (86%) | +0.39 | ×1.5 |
| B | 76 / 104 (73%) | +0.46 | ×1.7 |
| C | 34 / 104 (33%) | +1.37 | ×4.5 |

**A and B calibrate; C does not.** Confirmed. Two amendments to the record:

- The methodology says estimators under-guess sites "by an order of magnitude". On this run it is a factor of 4.5. The conclusion is unchanged — C flags two thirds of the table and carries nothing — but the size of the bias is smaller than recorded and worth restating as "several-fold" rather than "an order of magnitude".
- B's 73% is materially worse than A's 86%, and the tail triage explains why: most of B's misses are the floor effect above, not disagreement about scattered code. B calibrates in its upper range and not at its bottom.

The estimators agreed with each other closely, as predicted: median pairwise disagreement 0.37 (A), 0.26 (B), 0.31 (C) on the log3 scale, with 97% of pairs on A and B inside a factor of three. They are one instrument with a small spread. Details in `oracle.md`.

---

## Method as run, and where it departed

Survey, Count, Oracle, Pick, Explain, in that order, on the operator's own code.

- **Index.** `rust-analyzer scip` over the workspace, `scip print --json`. Written to `/usr/local/ai/scope/robco-2026-08-21-round-1/` — 9.7 MB of `.scip` and 20 MB of JSON do not belong in a results folder.
- **Corpus.** `.rs`, `.md`, `.toml`. Excluded `target/`, `.git/` and `.claude/`. The last matters: it holds sixteen agent-session files (shift ledgers, journals, handovers) that name modules heavily and that a reader meeting this repository as a program would not meet. Including them would have inflated every B.
- **Oracle.** Three cheap-tier estimators, fresh contexts, `oracle-brief.md` and one `Read` call apiece. I1 holds: no source line, no measured figure, no suspicion, and the two facts the run wanted were requested by kind with no figure attached.
- **Explain.** Six modules revived individually at revival depth. The remaining twenty-six flags were triaged in one context rather than revived one by one — a cost decision, recorded as a departure. Five of that batch's fourteen "by design" verdicts justify themselves in language that actually describes the stem-pollution artefact and should probably be artefact; they are the weakest verdicts on the run and nothing here depends on them. Named in `revivals/tail-triage.md`.
- **Facts.** One of the fifteen decided-once facts was drilled properly. The rest carry a first-pass grep of file counts, and nine of them carry **no figure at all** because their pattern is a common word in this domain — recorded as "not measured" rather than given a number the run cannot defend. `facts.md`. One fact, "the terminal core is rio-vt" (expected 4.5, 22 files), is flagged high and undrilled: an open question for a later run, not a finding.

Nothing in the repository was changed. No worktree was needed, since every phase is read-only.

---

## Dispositions

| concept | expected | measured | gap | disposition |
|---|---|---|---|---|
| `app/src/window.rs` | A=1 B=3 | A=1 B=25, out-degree 46 | B +1.30 | **scattered** — six subsystems in one file |
| `app/src/tmux.rs` | A=4 B=8 | A=1 B=30, leak 29 | A −1.00, B +1.20 | **split** — three carriers by design, `channels.rs` a second encoding |
| the bank's side | 10 places | 38 places, 0 names it | +1.22 | **scattered** — nine sites rebuild geometry from a scalar |
| `config/src/lib.rs` | A=1 B=2 | A=16 B=31 | A +2.52 | by design |
| `config/src/schema.rs` | A=1 B=4 | A=17 B=23 | A +1.95 | by design; `presets.rs` literals noted |
| `crt-burnin/src/headless.rs` | A=1 B=2 | A=1 B=22 | B +1.81 | by design, cost stated in the code |
| `term/src/cells.rs` | A=2 B=4 | A=4 B=35 | B +1.77 | by design — fixture constructor |
| `chassis/src/shaders.rs` | A=1 B=2 | A=2 B=39 | B +2.70 | **artefact** — stem pollution; corrected B 3–5 |
| `term/src/size.rs` | A=2 B=4 | A=4 B=21 | B +1.31 | artefact in part — `Viewport` collides with librashader |
| `app/src/column.rs` and 9 others | B=5 | B=1 | −1.46 | **artefact** — vocabulary filtered to nothing |
| 14 further high-B flags | — | — | — | by design (5 weak, see `tail-triage.md`) |
| "the terminal core is rio-vt" | 4.5 places | 22 files | +1.44 | open — flagged, undrilled |

---

## Artefacts

| file | phase |
|---|---|
| `survey.md` | S — module list, sizes, corpus, what fell off the table |
| `measured.json`, `measured-table.md` | C — A, B, C, leak, score for 163 rows |
| `degree.json` | C — in- and out-degree per module, from the same index |
| `count.md` | C — the supplementary columns and why they exist |
| `oracle-brief.md` | O — what every estimator received, and nothing else |
| `oracle-replies/estimator-{1,2,3}.md` | O — the three replies as returned |
| `oracle.md` | O — I1 compliance, inter-estimator agreement |
| `pick.json`, `pick-flagged.json`, `pick-table.md` | P — expected, measured, gap, flag, for all 104 |
| `facts.md` | P — the decided-once list, expected against measured |
| `revivals/window.md` | E |
| `revivals/tmux.md` | E |
| `revivals/fact-bank-side.md` | E |
| `revivals/config.md` | E |
| `revivals/high-leak-four.md` | E |
| `revivals/tail-triage.md` | E |

The symbol index itself is at `/usr/local/ai/scope/robco-2026-08-21-round-1/` (`index.scip`, `index.json`, `ra.log`).

---

## Cost

Nine agents: three blind estimators and five revivals on the cheap tier the methodology specifies, plus one fact drill a tier up, since a removal-style drill has to read every hit rather than count them (resumed once with a follow-up, and once more that did not return before the run closed — the test half of finding 3 is a lower bound because of it). The index build, the count, the pick arithmetic and this report were the operator's. Wall time about 16 minutes end to end (14:03 to 14:19), most of it the three estimator batches and the five revivals running concurrently.

Build output — the 759 MB cargo target the indexer needed — is at `/usr/local/ai/scope/robco-2026-08-21-round-1/target`, outside both the repository and this folder.

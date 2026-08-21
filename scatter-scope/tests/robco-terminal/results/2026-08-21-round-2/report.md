# SCOPE — RobCo Terminal, 2026-08-21, round 2

One codebase measured once. Eight crates, 110 source modules, 43,350 lines of Rust, at
`/home/weiwu/code/RobCo-Terminal` (branch `main`, `354e8f4`, working tree clean before and
after). The repository was not modified: nothing was written into it, and the index build ran
with `CARGO_TARGET_DIR` pointed outside the tree.

SCOPE does not ask how coupled this code is. It asks which concepts the program decides in more
places than a competent architect, given the README and the crate sizes but not the code, would
expect. Every measured figure below has a blind expectation beside it, and only the gap is
worked on.

---

## Findings

Four concepts came out of the run with a verified count and a named mechanism, in the order the
owner should care about them.

### 1. One new screen or chassis setting costs about twelve edits

**Expected** the config format to be decided in 6 places, the screen-preset set in 3, the
chassis roster in 5. **Measured** a family of five setting names — `frame_size`,
`screen_curvature`, `screen_radius`, `frame_shininess`, `ambient_light` — each **defined in six
to eight separate files**, and the repository's own `xtask fanout frame_size` reporting **62
non-test lines across 14 files**.

None of the eight homes is a reimplemented function; each is a plain field. But the count is
real, because the path from the TOML file to the shader uniform forks and every fork restates
the name: `[chassis]`/`[screen]` table → `ChassisSettings`/`ScreenSettings` field
(`config/schema.rs`) → `Config::raw_frame_size()` → **two independent uniform computations that
must agree** (`crt_render::params::Params::build` for the tube pass,
`chassis::frame::FrameScale::build` for the bezel pass) → **two CPU oracle mirrors** of those
(`crt-render/src/oracle.rs`, `chassis/src/oracle.rs`) → **three near-identical `FrameRuntime`
carriers**, one per shell. A ninth path exists for the pointer alone:
`app::settings::distortion_frame_size` inverts the same arithmetic for
`term::distortion::DistortionParams`. Adding one setting of this shape means the schema field,
all thirteen preset literals in `config/presets.rs`, the `STRUCTURAL` list, a `raw_*` accessor,
the two computations, the two oracle mirrors and the three shell carriers: **eleven to thirteen
independent edits**.

Two of those homes are defensible on their own terms — the two shader-language oracles exist
because `terminal_frame.slang` and `frame_metal.slang` each carry their own copy of
`distortCoordinates` and the chain crate and the chassis crate cannot see each other, and
`app/tests/structure_subset.rs` pins the two derivations to the same answer. The cost is not
that any one home is wrong. It is that the count is twelve and the program already knows:
`crates/xtask/src/fanout.rs` exists expressly for GitHub issue #4, "the setting-duplication
report".

**Disposition: scattered, real cost.** Full report: `revivals/conventions.md`.

### 2. No type carries the unit a coordinate is in

**Expected** 6 places. **Measured** ~84 real sites across 8 files, and **no single home** — the
logical-to-physical conversion is reimplemented in `term::size::Viewport::physical_cell`,
`chassis::cabinet::bank_width_physical`, `chassis::layout::min_inner_size_physical`, inline in
`app/window.rs` (the margin conversion copied at four call sites) and again in `app/column.rs`
(`well_ruler`, `scale_rect`).

Past the winit boundary nothing in the type system knows which unit it is holding.
`Viewport::width`/`height` are bare `u32` documented as physical; a cell size is bare and
documented as logical; the rule is enforced by comment. The README's headline pointer promise —
a click mapped back through the curvature the same way the type is mapped forward — crosses this
boundary live: `window.rs::logical_x` divides a winit `PhysicalPosition` by `scale_factor`
before calling `correct_distortion`, and `distortion_params` re-multiplies the config's logical
margin on the way out. Moving the program to carry physical pixels everywhere would cost
**ten to twelve independent edits**, none of which the compiler would prompt for.

**Disposition: scattered, real cost.** Full report: `revivals/fact-coordinate-unit.md`.

### 3. Which side the bank sits on is decided once and assumed in ten files

**Expected** 4 places. **Measured** 10 non-test files / 82 sites, and the fact has **no name**:
there is no `BankSide`, no `Side::Left`, no `bank_on_left`, no config key anywhere in the tree.

`chassis::layout::WindowLayout::new` is the one place it is decided — the bank is
`Rect::new(0.0, 0.0, bank_width, height)` and the well runs from `bank_width` to the right edge.
`WindowLayout` then publishes two rectangles but never a which-side fact, so nothing forces a
consumer through them, and consumers keep the *derived scalar* instead and rebuild the position
arithmetic themselves. `app/window.rs:1252` places the IME caret at `top_left.x + bank`; line
2325 maps a pointer back with `position.x - bank_physical()`. Counting `bank_width` and
`bank_physical()` over non-test sources: `chassis/cabinet.rs` 22, `chassis/seam.rs` 12,
`app/shell.rs` 12, `app/window.rs` 9, `chassis/lib.rs` 8, plus `chassis/layout.rs`,
`app/geometry.rs`, `app/main.rs`, `xtask/snap.rs`, `xtask/compare.rs`. Every one is correct
today only because `bank.x` happens to be `0.0`, and the compiler would report none of them if
it stopped being.

This finding is also the run's own instrument failure, and it is recorded as one: the fact probe
first returned "4 files / 6 sites, agreement", because its pattern searched for prose about
sides and for the layout module and stopped at the definition. The correction is in
`facts-measured.md` under "The one probe result this run corrected".

**Disposition: scattered, real cost.**

### 4. The tmux attachment invariants are maintained twice, at the same layer

**Expected** A=5, B=9 for `crates/app/src/tmux.rs`. **Measured** A=1, B=31, C=328, leak 30 —
the only clean leak signature on the table.

The revival returned **artefact**, and it was three-quarters right: the stem `tmux` is the
domain's own word, and of 328 sites nearly all are that bare token in files that have every
right to it — the sibling `tmux-cc` crate, `term::tmux_cc` and `term::tmux_pane` at a layer that
cannot import upward, the README, the transcripts, both `Cargo.toml`s. No code change would or
should close those, and the instrument fault is now on the run's list.

One carrier does not fit that reading, and a direct check of the code says so.
`crates/app/src/channels.rs` accounts for 34 of the mentions, in the same crate at the same
layer, and imports nothing from `tmux.rs` — its only link is a doc-comment cross-reference.
`Page` carries `tmux_host`, `gateway_home_slot`, `new_window_pending` and `attach_done`; `Row`
carries `tmux_window` and `tmux_pane`; there are `PageKind::Tmux` and `ChannelKind::Gateway`.
These are not passive storage: `Channels::new_tmux_window`, `open_tmux_pane` and the
gateway-slot search at lines 304–320 read and write them, so the invariants `tmux.rs` enforces
(an attachment means a page; the gateway holds its home slot; a pending new window is claimed
once) are maintained a second time, independently, by hand.

**Disposition: the vocabulary spread is an artefact; one carrier is scattered.** Full report:
`revivals/tmux.md`, with this correction stated here rather than there.

---

## What closed by design

The outcome the method expects for a shared vocabulary doing its job, and four of the run's
individually-revived flags closed this way.

**`crates/app/src/window.rs` is a hub, and its hub-ness is the honest reading.** Expected D=15,
measured **D=46** against a median of 1 over the 106 source modules — twice the next highest.
A=1 with tests excluded, 12 with them included. One `use` block pulls from thirteen crate-local
modules plus `chassis`, `config`, `crt-render`, five `term` submodules, `tmux-cc` and `winit`:
one struct assembling surface, session, chassis, gateways, chord input, selection and IME. Its
own public surface is cheap to change; what it costs is that it must track forty-six upstream
APIs and eleven integration suites re-verify it on any touch. That is the price of an
orchestrator, not scatter. Full report: `revivals/window.md`.

**`crates/chassis/src/oracle.rs`** (expected A=0, measured A=5; B=29, C=372) is the CPU mirror
of the three metal shaders' uniform structs, and the three shells import those types for real
paint work. Its names are restated at every construction site and by ten golden-value parity
tests that diff CPU against GPU output; `hash12` and `vnoise` also live in four `.slang`/`.wgsl`
files outside the corpus. Wide reading is the module's job. Full report:
`revivals/chassis-oracle.md`.

**`crates/chassis/src/metrics.rs`** (B 6→33, C 10→348, D 2→7) is the chassis crate's measurement
hub with nine genuine callers. The shared-name question it was asked to test came back clean:
`unit_width`, `min_units`, `width_for_units` and `height_for_pad_cells` are one `DisplayMetrics`
trait with two implementors, each delegating to its own formula function, with tests that assert
`..._matches_the_defining_formula`. A sibling-module interface, not duplicated arithmetic. Full
report: `revivals/chassis-metrics.md`.

**`pixel_size`** (6 defining homes) is one value computed once in `term/fonts/sizing.rs` and
threaded as a same-named parameter down the font pipeline; `chassis/paint.rs`'s use of the word
is an unrelated concept. Full report: `revivals/conventions.md`.

The remaining twenty-one flags were triaged in one batch, as the methodology allows for flags
whose cause is plain from the table itself. Sixteen closed **by design**, five as **artefact**
(one, `term/src/gpu.rs`, mixed). **None was called scattered**, and the triage was told that
anything it did call scattered would be escalated to an individual review, so the empty column
is a verdict rather than an omission.

The by-design half is what a settings crate and a test-fixture layer look like when they are
working: `config/schema.rs` (expected A=3, measured 17) defines the types every config-consuming
module in four crates must reference; `config/lib.rs` (A 6→16) is the crate root threading
`Config` through the program; `crt-burnin/src/headless.rs` shows the leak signature (A=1
excluding tests, 27 including) because it is a test fixture with one production consumer;
`crt-render/src/oracle.rs` has A=0 on purpose, being a golden-reference generator only test
suites call. Full table: `revivals/tail-triage.md`.

---

## What the instrument got wrong

More of this run's flags were the tool's than the code's, and the pattern is worth more to the
method than any single row. `instrument.md` has the tables; the four faults are:

**The vocabulary filter admits capitalised English words.** `keep()` returns true for any
capitalised name without testing the dictionary, so an enum variant named after an ordinary word
enters the vocabulary and matches prose. `crates/app/src/channels.rs` measured B=44, C=306 and
ranked fourth on the whole table; one word, `Close::Nothing`, appears in **42 of its 44 B
files**, almost all of it comment prose ("Nothing is lost", "Nothing here creates one"). Twelve
of the thirty flagged rows carry such a word; on `xtask/main.rs` they account for 10 of 10
sites, on `crt-render/chain.rs` 50 of 75, on `chassis/furniture.rs` 41 of 55. The fix belongs in
the tool: apply the dictionary test to capitalised names too, unless they carry an underscore or
an inner capital.

**A dictionary cannot catch a programming commonplace.** `crates/crt-render/src/params.rs`
ranked **first** on the table at C=380. `params` is not an English word, so it survived the
filter — and it is the most conventional identifier in Rust for "the arguments I was handed",
plus the name of `vte::Params`, an unrelated type three `term` modules handle. **361 of the 380
sites are the bare word.** A stop list of language commonplaces is a different instrument from a
dictionary, and the tool needs both.

**The stem is a bad vocabulary word when the word is the domain's, or another module's type.**
`app/src/tmux.rs`: the stem is the name of the external program the entire feature is about, and
it carries nearly all 328 sites. `term/src/viewport.rs`: 230 of 280 sites are the stem, and most
are homonyms — `term::size::Viewport` is a *different struct in the same crate* (74 hits in
`app/window.rs` alone), plus generic shader-math `viewport` parameters and librashader's own
`Viewport`.

**B is not reproducible across index decoders; A is.** Round 1 of this series measured the same
commit with the same tool, differing only in that its SCIP protobuf was decoded by
`scip print --json` rather than `tools/scip2json.py`. Over the 163 rows the two rounds share:
**A identical on 163 of 163**; **B different on 58 of 163**, several by an order of magnitude
(`chassis/shaders.rs` 39→3, `app/channels.rs` 8→44, `term/viewport.rs` 5→33, `term/cells.rs`
35→8). The decoders assign the definition role to different symbol sets, the vocabularies
differ, and B is only as stable as its vocabulary. Any run that wants B comparable across rounds
must pin the decoder and say so. This one pins it: `tools/scip2json.py`.

**And the fact probe can return a false agreement.** The bank-side fact came back "4 files / 6
sites, agreement" and was wrong by a factor of twenty on sites; the corrected measurement is
finding 3. A probe that finds where a fact is *defined* and stops has not measured where it is
*obeyed* — which is the only half that costs anything.

---

## Calibration, re-checked

The methodology asks each run to re-check the claim that A calibrates, B calibrates in its upper
range, and C does not. On 106 modules against three blind estimates, band ±1 log₃ (a factor of
three):

| figure | inside band | median gap | reading |
|---|---|---|---|
| A | 99/106 (93%) | +0.23 log₃ (×1.3) | calibrates, and better than round 1 |
| B | 72/106 (67%) | +0.51 log₃ (×1.8) | calibrates in its upper range |
| C | 34/106 (32%) | +1.40 log₃ (×4.7) | does not calibrate; estimators under-guess sites ~5× uniformly |
| D | 80/106 (75%) | −0.63 log₃ (×0.5) | calibrates; estimators over-guess out-degree about two-fold |

Thirty rows flagged, 28% of the table: **B high** 25, **A high** 6, **D high (hub)** 6, **leak
signature** 4, **A low** 1. The B-flag share is 24% of the table — under the level at which the
methodology says a run is reading its instrument rather than its code, but only just, and the
instrument section above says how much of even that 24% was lexical.

The three estimators agreed closely with each other and were wrong in the same direction, which
is what the methodology predicts: the median guards against a stray answer, not against bias,
and the bias showed up in Pick.

D deserves a note it has not had. It is over-guessed on average (median ×0.5) and yet it found
the run's clearest structural fact: one module at 46 against a median of 1. A figure that
calibrates poorly on average can still carry the tail, and D's tail is where hubs live.

---

## What the method could not see on this codebase

**The shader tier.** Thirteen `.slang` and `.wgsl` files under `crates/*/shaders/` and
`crates/term/src/shader.wgsl` are outside the symbol index entirely and outside the corpus. A
supplementary grep found real cross-tier vocabulary in exactly one place —
`chassis/src/oracle.rs`'s `vnoise` (18 sites) and `hash12` (24) live in four shader files
because that module's job is to mirror them — and one false one, `params`. But finding 1's
mechanism runs *through* that tier: `distortCoordinates` is written once per shader, four times,
and no reference graph will ever say so. A codebase that computes in two languages has half its
scattering below the indexer's floor.

**The low side of B.** A module whose names are dictionary words measures B near zero however
widely it is used, and that is the instrument having nothing to grep for, never "well hidden".
Four source modules define symbols but hold no row at all, because their stems name nothing and
every name they re-export is defined elsewhere: `app/src/distortion.rs`,
`chassis/src/displays/mod.rs`, `crt-render/src/lib.rs`, `tmux-cc/src/lib.rs`. Two more sit on
the table with B and C unmeasured for the same reason (`app/src/lib.rs`, `app/src/main.rs`);
their A and D still hold.

**Facts with a common-word handle.** One estimator's fact — the maximum channel slots per bank
page — turned out not to exist: `chassis::bank::BankGeometry::rows_visible` computes it at run
time from window height, and only `CHANNEL_CAP = 99` caps anything. It is recorded as *not
measured* rather than given a number, which is the rule.

**Only the type-level half of removal cost.** SCOPE's A is the cheap estimate of what deleting a
module would cost the compiler; a removal drill gives the exact figure. Nothing here was drilled
except by the one fact probe that copied nothing and drilled nothing.

---

## Artefact index

| artefact | path |
|---|---|
| Run notes: indexer, tiers, corpus rule, exclusions, blind spots | `survey.md` |
| Count notes: command, out-degree distribution, A-on-tests, shader tier, conventions | `count.md` |
| Measured table (166 rows) and the conventions table | `measured-table.md`, `measured.json` |
| Per-flag vocabulary, A files, B files with counts, leak files | `flagged-detail.json` |
| Oracle brief, exactly as sent | `oracle-brief.md` |
| Estimator replies, three | `oracle-replies/estimator-{1,2,3}.md` |
| Pick table with dispositions, and its calibration print | `pick-table.md`, `pick.json`, `pick-calibration.txt` |
| Decided-once facts: expected, then measured with patterns and homonyms | `facts.md`, `facts-measured.md` |
| The instrument's own faults, with the round-over-round stability check | `instrument.md` |
| Revival reports, eight | `revivals/` |
| Symbol index, its JSON, the indexer log | `/usr/local/ai/scope/robco-2026-08-21-round-2/` |

Nothing was written into `/home/weiwu/code/RobCo-Terminal`.

---

## Cost

Sixteen minutes of wall clock, 14:41 to 14:57 on 2026-08-21.

| phase | what ran |
|---|---|
| Survey | `rust-analyzer scip` over the workspace, 12 s; `scip2json.py`; no agent |
| Count | `scope-count.py` and four small analysis scripts; no agent |
| Oracle | 3 blind estimators, cheap tier, fresh contexts, one tool call each (the brief) |
| Count (facts) | 1 cheap-tier probe agent over the 18 decided-once facts, 81 tool calls |
| Pick | `scope-pick.py`; no agent |
| Explain | 7 revivals of the three estimators, in their own contexts (2 or 3 each); 1 fresh agent on the conventions table; 1 fresh agent on the 21-flag batch triage |

**Ten agent contexts in total** — 3 estimators (revived 7 times between them), 1 fact probe,
1 conventions explainer, 1 tail triage — plus the coordinating session. Roughly 320,000
subagent tokens. The largest single cost was the fact probe at 82,000 tokens and 81 tool calls,
and it is also the one that returned a wrong number; the cheapest useful thing in the run was
`scope-count.py`, which put `params.rs` at the top of the table for free and was wrong about it.

## Round-over-round note

This is the second run against the same commit, and the comparison is a free calibration the
methodology does not otherwise get. **A was identical on all 163 shared rows.** B differed on
58. Two verdicts moved: round 1 called `app/src/window.rs` scattered on a per-region reading of
its 3205 lines, round 2's revival called it a by-design orchestrator on the same numbers — both
are defensible and the disagreement is about what a hub *is*, not about a count. Round 1 found
the `channels.rs` tmux carrier and round 2's revival missed it behind the stem artefact; that
one is not a difference of opinion, and this report restores it as finding 4.

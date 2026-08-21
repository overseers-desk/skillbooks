# SCOPE Audit RobCo Terminal

A SCOPE audit of `/home/weiwu/code/RobCo-Terminal`, branch `main`, commit `354e8f4`: a Rust
workspace of eight crates, 170 `.rs` files, 108 of them source modules that define symbols. **The
repository was not modified** — nothing was written into it, the tree was clean before and after,
and the indexer ran with `CARGO_TARGET_DIR` outside it.

## What was measured, and how to read a figure

SCOPE does not ask how coupled this code is. It asks which concepts the program decides in more
places than it should, per concept rather than per average. Two kinds of concept were measured.
For each of the 108 modules, four figures: **A**, the files outside it that use its types; **D**,
the files whose types it uses; **B**, the files anywhere in the tree — sources, tests, docs,
manifests — that mention any name the module alone defines; and **C**, the total number of those
mentions. A and D come from a symbol index, B and C from grep over the module's own vocabulary. A
module's **leak** is the non-test B files the graph did not count in A: files that speak the
concept's words without using its types. The tool's own ranking, which needs no estimate, is
`score = C × leak/B`. For each of 16 **design facts** — a thing the program settles once, such as
which side of the window the channel bank sits on — two figures: where the fact is *decided* (the
definition) and where it is *obeyed* (every independent site that assumes it and would have to
change if the fact changed).

Beside every measured figure sits an expectation. Three estimators were given the README, the size
of each crate, and each module's one-line doc — no code and no counts — and asked for the same
figures, and for the design facts and the places each should touch; their median is the
expectation. A figure is worked on only where it sits outside a factor of three of it; that gap,
not the raw count, is what this report is about. Where a figure was flagged the count was checked
first — is one common word carrying it? does the corpus hold files a reader would not meet? —
before the code was read for the cause. Each flag closes one of three ways: **by design**, where a
widely-read vocabulary is doing its job; **artefact**, where the count was the instrument's rather
than the code's; or **scattered**, where the program really does decide one thing in many places,
and the mechanism is named.

**The headline is a split.** Thirty-two modules were flagged and **not one of them was scattered**
— every module-level flag closed as by design or as an artefact. Every finding below came from the
other half of the method, the design facts, which have no module and which no reference graph can
list: the graph-and-grep half found nothing to act on here, and the fact list found everything.

---

## Findings

### 1. No type carries the unit a coordinate is in, and 57 places assume it

**Expected 6 places. Measured: decided in 9 locations, obeyed in 57 non-test sites plus 29 in
tests.** A factor of ten, the largest gap in the audit.

The rule exists and is written down — `chassis`'s module doc says every measure in the crate is a
logical pixel — but it is enforced by comment. `term::size::Viewport` carries physical `u32`s and
a `scale_factor`; a cell size is a bare number documented as logical; past the winit boundary
nothing in the type system knows which unit it is holding. Nine places convert:
`Viewport::physical_cell`, `chassis::layout::min_inner_size_physical`,
`chassis::cabinet::bank_width_physical`, `window.rs::chain_geometry`, `window.rs::logical_x`,
`column.rs::well_ruler`, and three documented conventions. Fifty-seven more assume the answer: 35
sites in `app/src/window.rs` alone, 11 in `app/src/shell.rs`, 6 in `app/src/column.rs`, and one in
`term/src/shader.wgsl`, below the indexer's floor entirely.

The README's headline promise crosses this boundary live — a click is mapped back through the
curvature the same way the type is mapped forward — so the conversion is on the critical path, not
in a corner. Moving the program to one unit everywhere is a change the compiler would prompt for
at almost none of those 57 sites.

**Disposition: scattered, real cost.** Detail: `facts-measured.md`, fact 2.

### 2. The bank sits on the left, the fact has no name, and nine files assume it

**Expected 4 places. Measured: decided in one, obeyed in 9 non-test sites and 9 test sites.**

`chassis::layout::WindowLayout::new` is the whole decision: the bank is `Rect::new(0.0, 0.0,
bank_width, height)` and the well starts at `bank_width`. There is no `BankSide`, no `Side::Left`,
no config key — `crates/config` and `crates/chassis` were searched for one and there is none.
`WindowLayout` publishes two rectangles but never a which-side fact, so nothing forces a consumer
through them, and consumers keep the derived scalar and rebuild the arithmetic:

- `app/window.rs::strip_pressed` divides the click by the scale factor and passes `x` straight
  to `cabinet.strip_at` — untranslated by `layout().bank.x`, correct only because it is `0.0`;
- `app/window.rs` places the well origin at `(bank, 0)` and centres badges from `x = bank`;
- `app/column.rs::Blit::draw` hardcodes the bank column's destination at `(0, 0, …)`;
- `chassis/seam.rs::hit` puts the drag boundary at `bank_width - inset`;
- `chassis/cabinet.rs` twice re-derives window width as `layout.crt.right()`;
- `xtask/compare.rs` crops the bank at `x = 0` and the glass at `x = BANK_WIDTH + inset`.

Six of the nine were read against the source directly and hold; the other three stand on the
probe's count, unverified separately. Flip the side and the compiler reports none of them. Two
chassis tests already model the bank on the right to prove one formula is side-agnostic, which
shows the codebase knows the question exists.

**Disposition: scattered, real cost.** Detail: `facts-measured.md`, fact 1.

### 3. One new screen or chassis setting costs eight homes

The convention table — names that several files define — has a head made entirely of screen and
chassis settings: `frame_size` **8 defining homes**, `screen_curvature` 8, `screen_radius` 8,
`frame_shininess` 7, `ambient_light` 6. Each is a plain field restated at every fork of the path
from the TOML table to the shader uniform. Reading `frame_size` end to end at this commit:

- the schema field, on both `chassis` and `screen` (`config/src/schema.rs`);
- `Config::raw_frame_size()` (`config/src/lib.rs:103`), which resolves the chassis-or-screen split;
- **two independent uniform computations that must agree** — `chassis/src/frame.rs:222`
  (`cfg.chassis.frame_size as f32 * 0.05 * normalized`, emitted as `"frameSize"`) and
  `crt-render/src/params.rs:126` (`cfg.raw_frame_size() as f32 * 0.05 * normalized`, emitted as
  `"FrameSize"`), plus `app::settings::distortion_frame_size` for the term distortion path;
- **two CPU mirrors of the shader arithmetic** — `distort_coordinates` in `chassis/src/oracle.rs`
  and again in `crt-render/src/oracle.rs`;
- **three per-shell runtime carriers** — `annunciator.rs`, `slide_rule.rs` and `switchboard.rs`
  each declare their own `pub frame_size: f32` and copy it from the runtime struct.

The program already knows this costs: `crates/xtask/src/fanout.rs` exists to measure this fan-out,
citing the repository's setting-duplication issue. This is the one finding that runs *through* the
shader tier, which no reference graph will ever see.

**Disposition: scattered, real cost.** Detail: the conventions table in `measured-table.md`.

### 4. Bitmap integer scale is assumed by twelve independent computations

**Expected 3 places. Measured: decided in `term::fonts::sizing` (`ScalePolicy::apply` and the
`integer_scale` field it produces), obeyed in 12 non-test sites, roughly four times the
expectation.**

`render.rs::pixel_size` and `cells_for_pixels` assume physical pixels are an exact multiple of
cell × scale; the draw path's scroll-shift and vertex uniforms assume a whole multiplier;
`sizing.rs::is_pixel_exact_width` and `snap_font_width` assume a whole denominator;
`window.rs::chain_geometry`, `logical_cell` and `shift_physical` each assume a clean integer
round-trip; `badge.rs::draw` scales the badge quad by the same multiplier. One `assert!` in
`render.rs::set_scale` guards the invariant at one receiving end.

**Disposition: scattered, moderate cost** — the same repair as finding 1, the program's pixel
geometry being carried by arithmetic and comments rather than by a type. Detail:
`facts-measured.md`, fact 11.

### 5. Three smaller gaps, named for completeness

- **The built-in shells** (expected 5, measured 10 non-test sites) — but every one of the ten is
  a compiler-enforced exhaustive `match` on the `Shell` enum, so adding a fourth cabinet is a
  guided edit, not a hunt. **By design.** The three test sites holding a hardcoded shell list
  (`config/src/lib.rs:228`, `chassis/src/lib.rs:199-201`, `chassis/src/furniture.rs:1141`) are
  the only real drift risk.
- **The chord modifier** (expected 4, measured 4, agreement) — with one blemish: `window.rs`'s
  `modifiers_changed` re-derives the same Alt/Meta test independently to detect chord release,
  rather than calling the deciding site in `shortcut_key`. One duplicate, one line.
- **The default well width** (expected 3, measured 5) — `xtask` spells the `320` constant itself
  twice rather than depending on `chassis`: a literal in `verify.rs:254` and a second
  `const CRT_MINIMUM_WIDTH: i64 = 320;` in `snap.rs:288`. Two literals in a dev tool. The default
  screen preset name is the mirror case: `"Default Amber"`, decided in `config/src/schema.rs`, is
  spelled a second time in exactly one non-test place, `xtask verify`'s CLI default.

---

## What closed by design or as an artefact

**Every one of the 32 module flags.** Six were read in their own context by the estimator whose
blind guess was furthest off; 25 were triaged in one batch pass whose brief said that anything it
called scattered would be escalated to a full reading — nothing was.

| module | expected → measured | outcome |
|---|---|---|
| `app/src/window.rs` | A 2→1, B 8→34, D 15→**46**, C 16→254 | **by design** — the hub reading, done region by region |
| `app/src/tmux.rs` | A 2→1, B 6→30, C 12→327, leak 29 | **artefact** — `tmux` alone carries 322 of 327 sites |
| `chassis/src/metrics.rs` | A 3→9, B 5→33, D 2→7 | **artefact** + by design — `annunciator` carries 31 of 33 B files |
| `chassis/src/shells/annunciator.rs` | B 2→30 (largest B gap on the table) | **artefact** — 96 of 114 sites are the cabinet's own name |
| `term/src/fonts/mod.rs`, `term/src/atlas.rs` | A 4→16, A 1→4 | **by design** — every consumer takes a type, none recomputes a size |
| `crt-render/src/degauss.rs` | A 1→4, B 2→16, C 3→124 | **by design** — a 107-line fixed-contract type, heavily tested |
| the remaining 25 | see `pick-table.md` | **16 by design, 9 artefact, 0 scattered** |

### `app/src/window.rs`: a hub, not a symptom

D=46 against a median of 1 over the whole table is the largest out-degree in the workspace. Its
first reading was refused and sent back to inventory the file region by region: ten regions of
roughly 300 lines each, and for each one the owning module elsewhere — `crt::Chain` and
`term::build_font` for construction, `app::tmux::Gateway` for gateway policy, `app::channels` for
the channel model, `chord.rs` and `seam.rs` (both written for a generic "host" — `shell::Surface`,
whose only real implementor is `window.rs`), `term::resolve` and `cabinet::apply_config` for the
layout formulas, `term::pointer` for hit-testing. No region holds a subsystem's own
implementation. D=46 is coordination breadth: the price of an orchestrator, not a symptom.

### `app/src/tmux.rs` and `app/src/channels.rs`: one seam, not two encodings

`tmux.rs` tops the tool's own `C × leak/B` ranking, at C=327 with B=30 against an expected 6. The
count is one word: **`tmux` alone supplies 322 of the 327 mentions**, and every carrier is a place
a reader of this repo would expect it — the sibling protocol crate `tmux-cc`, the lower-layer
`term` crate (`tmux_cc.rs`, `tmux_pane.rs`, `session.rs`, `dcs.rs`), manifests, the README,
`docs/keys.md` and the integration tests. One carrier needed a second look, being in the same
crate at the same layer: `app/src/channels.rs`, with 34 bare-`tmux` sites, its own `tmux_host`,
`tmux_window` and `tmux_pane` fields on `Row`/`Page`, and methods dispatching on `ChannelKind`.

The two files were read against each other at this commit. **Neither imports the other** — the
only cross-references are doc comments. `tmux.rs` holds wire policy: the pending byte queue, the
intent table, the pane gates, the bootstrap watchdog. `channels.rs` holds the bank model: pages,
rows, slots, `new_window_pending`, `attach_done`, `gateway_home_slot`. The claim-once logic exists
only in `channels.rs`, the protocol logic only in `tmux.rs`, and the two are joined by exactly
**one** translation seam: a seven-arm `match` on `GatewayEvent` in `window.rs`'s pump loop
(`window.rs:937-991`), each arm's `GatewayEvent` doc comment naming its `channels::Channels`
consumer. That is a documented layering with a single joint, not a second encoding. **Not a
finding.**

---

## What the instrument got wrong

Full tables in `instrument.md`. Two faults matter for reading the numbers above.

**Leak counts tests as leakage, and the low-A/high-B pattern fires on test fixtures.** B includes
test files by rule; A excludes them by rule; so every test file that exercises a module lands in
leak as a file speaking the concept's words without using its types — when in fact it uses the
types and is merely not allowed to count. Over the 32 flagged rows: **363 leak files, 220 of them
(61%) under `/tests/`**. Five rows' leak is *entirely* test files, and
`crt-burnin/src/headless.rs` — one of four rows carrying the low-A, high-B pattern the method
ranks first — is 20 test files out of 21. So the tool's own ranking pushes a well-tested module up
the table for being well tested. The repair belongs in the tool: report leak against A-with-tests,
or split the column into source leak and test leak. This audit applied the split by hand wherever
a leak figure decided anything.

**Where the domain owns the module's name, no filter helps.** `app/src/tmux.rs` sits at B=30,
C=327 because its stem is the name of the external program the whole feature is about (see the
reading above), and a rule dropping stems that appear in the README's prose would throw away real
modules named for what they do.

**B is a function of the vocabulary rule** — a stop list dropping programming commonplaces,
capitalised English words counted in code only — so a B figure holds only at the tool commit
`survey.md` records (`15caa5d`). A and D, read from the index, do not depend on it.

---

## Calibration of the blind estimates

Three estimators, 108 modules, band ±1 log₃ (a factor of three):

| figure | inside band | median gap | reading |
|---|---|---|---|
| A | 98/108 (90%) | +0.37 log₃ (×1.5) | calibrates |
| B | 73/108 (67%) | +0.46 log₃ (×1.7) | calibrates in its upper range |
| C | 29/108 (26%) | +1.53 log₃ (×5.4) | does not calibrate; under-guessed ~5× |
| D | 84/108 (77%) | −0.37 log₃ (×0.7) | calibrates; over-guessed |

Thirty-two rows flagged, 30% of the table: **B high** 24, **A high** 10, **D high (hub)** 8, the
low-A/high-B pattern 4. The B-flag share, 24 of 108 modules or 22%, is under the level at which
the methodology says a run is reading its instrument rather than its subject.

The facts calibrate differently. Of 16 design facts, **four came back with real gaps** (×10,
×2.25, ×4, ×1.7), one turned out not to exist at all, and the rest agreed or came in under
expectation. Estimators guess module figures well and fact figures badly, always in the same
direction: they under-guess how many places obey a fact that no type carries.

---

## What the method could not see on this codebase

**The shader tier.** 25 `.slang`, `.slangp` and `.wgsl` files are outside the index and the
corpus, greped separately. That grep found one real cross-tier vocabulary: `hash12` and `vnoise`,
written once in shader source and once in `chassis/src/oracle.rs`, which is that module's job. But
finding 3's mechanism runs through that tier, and fact 2 has an obeying site in
`term/src/shader.wgsl`: a codebase that computes in two languages keeps part of its scattering
below the indexer's floor.

**A fact that does not exist.** "Slots per bank page" was named by an estimator and is not a
decided fact: `chassis::bank::BankGeometry::rows_visible` computes it at run time from window and
chassis geometry, and nothing caps it but `CHANNEL_CAP`. Recorded as *not measured*.

**The low side of B.** A module whose names are dictionary words measures near zero however widely
it is used; `app/src/main.rs` and `app/src/lib.rs` have no distinctive vocabulary at all, and
their B prints as *not measured*, never as zero. A is the figure that carries the low side.

**Only the type-level half of removal cost.** No removal drill was run; A is the cheap estimate of
what a removal would cost the compiler, and for findings 1, 2 and 4 the point is precisely that
the compiler would not prompt at all.

---

## Artefact index

Paths are relative to the run folder
`/home/weiwu/code/aesop/scatter-scope/tests/robco-terminal/results/2026-08-21-round-3/`.

| artefact | path |
|---|---|
| Run notes: indexer, tiers, corpus rule, exclusions, blind spots, tool commit | `survey.md` |
| Count notes: command, out-degree distribution, A-on-tests, shader tier, conventions | `count.md` |
| Measured table (166 rows) and the conventions table | `measured-table.md`, `measured.json`, `measured-table.txt` |
| Per-flag vocabulary, A files, B files with per-word counts, leak files | `flagged-detail.json` |
| Estimator brief, exactly as sent | `oracle-brief.md` |
| Estimator replies, three | `oracle-replies/estimator-{1,2,3}.md` |
| Which estimator was furthest off per flagged row | `furthest.json` |
| Flagged rows with expected, measured, gap and flags | `pick-table.md`, `pick.json` |
| Design facts: expected, then measured with patterns and homonyms | `facts.md`, `facts-measured.md` |
| The instrument's own faults | `instrument.md` |
| Briefs the code readings were given | `briefs/` |
| Code readings behind the verdicts, seven | `revivals/` |
| Symbol index, its JSON, the indexer log | `/usr/local/ai/scope/robco-2026-08-21-round-3/` |

Nothing was written into `/home/weiwu/code/RobCo-Terminal`.

---

## Cost

Nineteen minutes of wall clock, 15:09 to 15:28 on 2026-08-21.

| step | what ran |
|---|---|
| Index the workspace | `rust-analyzer scip` (~40 s, warm target dir), `scip2json.py`; no agent |
| Count the modules | `scope-count.py` and five small analysis scripts; no agent |
| Blind estimates | 3 estimators, cheap tier, fresh contexts, one file read each |
| Measure the design facts | 2 cheap-tier probes over the 16 facts, 93 tool calls between them |
| Rank against the estimates | `scope-pick.py`; no agent |
| Read the code behind each flag | 6 readings by the three estimators in their own contexts (2 each); 1 fresh agent for the 25-flag batch triage |

**Nine agent contexts** — 3 estimators, revisited 6 times between them; 2 fact probes; 1 triage —
plus the coordinating session. Roughly **455,000 subagent tokens**, of which the fact probes were
the largest single cost (245,000 tokens, 93 tool calls) and the only part that produced findings.
Their brief said a fact is measured where it is *obeyed*, not where it is decided: a probe
conflating the two reports a fact as agreeing when its consumers are everywhere.

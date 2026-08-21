# SCOPE — RobCo Terminal, 2026-08-21, round 3

One codebase measured once. Eight crates, 108 source modules, 170 Rust files, at
`/home/weiwu/code/RobCo-Terminal`, branch `main`, commit `354e8f4`, working tree clean before
and after. **The repository was not modified**: nothing was written into it, and the indexer
ran with `CARGO_TARGET_DIR` outside the tree.

SCOPE does not ask how coupled this code is. It asks which concepts the program decides in more
places than a competent architect, given the README and the crate sizes but not the code, would
expect. Every measured figure below has a blind expectation beside it, and only the gap is
worked on.

This is the third run against **the same commit**, by design rather than accident. The SCIP
index came out byte-identical to round 2's, so the code and the graph are held fixed while two
things vary: the counting tool, which has since gained the vocabulary filters round 2's report
asked for, and the estimator panel, which is a fresh three. Beyond its own findings, the round
buys a controlled read on how much of SCOPE's output is the codebase and how much is SCOPE.

**The headline is a split.** Thirty-two modules were flagged and **not one of them was
scattered** — every module-level flag closed as by design or as an artefact of the instrument.
Every finding this run produced came from the other half of the method, the decided-once facts,
which have no module and which no reference graph can list. On this codebase the graph-and-grep
half found nothing the owner should act on, and the eight-line fact list found everything.

---

## Findings

### 1. No type carries the unit a coordinate is in, and 57 places assume it

**Expected 6 places. Measured: decided in 9 locations, obeyed in 57 non-test sites plus 29 in
tests.** A factor of ten, the largest gap in the run.

The rule exists and is written down — `chassis`'s module doc says every measure in the crate is
a logical pixel — but it is enforced by comment. `term::size::Viewport` carries physical `u32`s
and a `scale_factor`; a cell size is a bare number documented as logical; past the winit
boundary nothing in the type system knows which unit it is holding. Nine places convert:
`Viewport::physical_cell`, `chassis::layout::min_inner_size_physical`,
`chassis::cabinet::bank_width_physical`, `window.rs::chain_geometry`, `window.rs::logical_x`,
`column.rs::well_ruler`, and three documented conventions. Fifty-seven more assume the answer:
35 sites in `app/src/window.rs` alone, 11 in `app/src/shell.rs`, 6 in `app/src/column.rs`, and
one in `term/src/shader.wgsl`, below the indexer's floor entirely.

The README's headline promise crosses this boundary live — a click is mapped back through the
curvature the same way the type is mapped forward — so the conversion is on the product's
critical path, not in a corner. Moving the program to carry one unit everywhere is a change the
compiler would prompt for at almost none of those 57 sites.

**Disposition: scattered, real cost.** Detail: `facts-measured.md`, fact 2. Round 2 measured
the same fact at ~84 sites across 8 files by a different probe and called it finding 2; two
independent probes, two panels, same answer.

### 2. The bank sits on the left, the fact has no name, and nine files assume it

**Expected 4 places. Measured: decided in one, obeyed in 9 non-test sites and 9 test sites.**

`chassis::layout::WindowLayout::new` is the whole decision: the bank is
`Rect::new(0.0, 0.0, bank_width, height)` and the well starts at `bank_width`. There is no
`BankSide`, no `Side::Left`, no config key — the probe searched `crates/config` and
`crates/chassis` for one and found none. `WindowLayout` publishes two rectangles but never a
which-side fact, so nothing forces a consumer through them, and consumers keep the derived
scalar and rebuild the arithmetic:

- `app/window.rs::strip_pressed` divides the click by the scale factor and passes `x` straight
  to `cabinet.strip_at` — untranslated by `layout().bank.x`, correct only because it is `0.0`;
- `app/window.rs` places the well origin at `(bank, 0)` and centres badges from `x = bank`;
- `app/column.rs::Blit::draw` hardcodes the bank column's destination at `(0, 0, …)`;
- `chassis/seam.rs::hit` puts the drag boundary at `bank_width - inset`;
- `chassis/cabinet.rs` twice re-derives window width as `layout.crt.right()`;
- `xtask/compare.rs` crops the bank at `x = 0` and the glass at `x = BANK_WIDTH + inset`.

I verified six of the nine against the source myself; they hold. Flip the side and the compiler
reports none of them. Two chassis tests already model the bank on the right to prove one formula
is side-agnostic, which shows the codebase knows the question exists.

**Disposition: scattered, real cost.** Detail: `facts-measured.md`, fact 1. Round 2 reached the
same finding after its first probe returned a false agreement; this round's probe found it
first time, with the homonyms it excluded named.

### 3. One new screen or chassis setting still costs eight homes

**Unchanged from round 2 and re-measured here.** The convention table — names several files
define — has the same head it had: `frame_size` **8 defining homes**, `screen_curvature` 8,
`screen_radius` 8, `frame_shininess` 7, `ambient_light` 6, each a plain field restated at every
fork of the path from the TOML table to the shader uniform. Round 2 revived this and named the
mechanism: schema field → `raw_*` accessor → two independent uniform computations that must
agree → two CPU oracle mirrors → three per-shell runtime carriers, eleven to thirteen edits for
one setting. The program already knows: `crates/xtask/src/fanout.rs` exists for the
setting-duplication report.

This round did not re-revive it — the measurement is identical and the mechanism was named. It
is listed because it is still the most expensive concept on the table, and because it is the one
finding that runs *through* the shader tier, which no reference graph will ever see.

**Disposition: scattered, carried forward.** Detail: round 2's `revivals/conventions.md`.

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

This is a smaller cost than findings 1 and 2 and is partly the same underlying condition: the
program's pixel geometry is carried by arithmetic and comments rather than by a type. It is the
neighbour of finding 1 and would be repaired by the same move.

**Disposition: scattered, moderate cost.** Detail: `facts-measured.md`, fact 11.

### 5. Three smaller gaps, named for completeness

- **The built-in shells** (expected 5, measured 10 non-test sites) — but every one of the ten is
  a compiler-enforced exhaustive `match` on the `Shell` enum, so adding a fourth cabinet is a
  guided edit, not a hunt. **By design.** The three test files holding a hardcoded shell list
  are the only real drift risk.
- **The chord modifier** (expected 4, measured 4, agreement) — with one blemish the probe
  caught: `window.rs::modifiers_changed` re-derives the same Alt/Meta test independently to
  detect chord release, rather than calling the deciding site. One duplicate, one line.
- **The default well width** (expected 3, measured 5) — `xtask` spells the `320` constant itself
  instead of depending on `chassis`, and the default screen preset name `"Default Amber"` is
  likewise spelled a second time in `xtask verify`'s CLI default. Two literals in a dev tool.

---

## What closed by design or as an artefact

**Every one of the 32 module flags.** Six got their own revival by the estimator whose blind
guess was furthest off, in its own context; 25 were batch-triaged in one context that was told
anything it called scattered would be escalated to a full review — nothing was.

| module | expected → measured | outcome |
|---|---|---|
| `app/src/window.rs` | A 2→1, B 8→34, D 15→**46**, C 16→254 | **by design** — the hub reading, done region by region |
| `app/src/tmux.rs` | A 2→1, B 6→30, C 12→327, leak 29 | **artefact** — `tmux` alone carries 322 of 327 sites |
| `chassis/src/metrics.rs` | A 3→9, B 5→33, D 2→7 | **artefact** + by design — `annunciator` carries 31 of 33 B files |
| `chassis/src/shells/annunciator.rs` | B 2→30 (largest B gap on the table) | **artefact** — 96 of 114 sites are the cabinet's own name |
| `term/src/fonts/mod.rs`, `term/src/atlas.rs` | A 4→16, A 1→4 | **by design** — every consumer takes a type, none recomputes a size |
| `crt-render/src/degauss.rs` | A 1→4, B 2→16, C 3→124 | **by design** — a 107-line fixed-contract type, heavily tested |
| the remaining 25 | see `pick-table.md` | **16 by design, 9 artefact, 0 scattered** |

The window.rs hub verdict is the one worth reading, because round 1 called the same file
scattered on the same numbers. This round's revival was refused its first answer and sent back
to inventory the file region by region: ten regions of roughly 300 lines each, and for each one
the owning module elsewhere — `crt::Chain` and `term::build_font` for construction,
`app::tmux::Gateway` for gateway policy, `app::channels` for the channel model, `chord.rs` and
`seam.rs` (both of which document `window.rs` as their intended host), `term::resolve` and
`cabinet::apply_config` for the layout formulas, `term::pointer` for hit-testing. No region
holds a subsystem's own implementation. D=46 against a median of 1 is coordination breadth, and
that is the price of an orchestrator rather than a symptom.

**Round 2's finding 4 is not reproduced, and I am overruling it.** Round 2 held that
`app/src/channels.rs` maintains the tmux attachment invariants a second time, at the same layer.
This round's revival called the whole tmux row an artefact; I checked the disputed carrier
against the code myself, as the methodology asks the runner to do where a verdict decides a
finding. Neither file imports the other. `tmux.rs` holds wire policy — the pending byte queue,
the intent table, the pane gates, the bootstrap watchdog. `channels.rs` holds the bank model —
pages, rows, slots, `new_window_pending`, `attach_done`, `gateway_home_slot`. The claim-once
logic exists only in `channels.rs`; the protocol logic only in `tmux.rs`; and the two are joined
by exactly **one** translation seam, a seven-arm `match` on `GatewayEvent` in `window.rs`'s pump
loop. That is a documented layering with a single joint, not a second encoding. Round 2 read a
shared vocabulary as a shared implementation.

---

## What the instrument got wrong

Full tables in `instrument.md`. Two things, and the second is new.

**The vocabulary fixes worked, and they were not where the flags were.** Holding the index
fixed, the new stop list and the code-only rule for capitalised English words cut **total sites
across the table from 8,031 to 6,707 (−16%)**, moved B on 34 rows and C on 46, every one
downward. `crt-render/src/params.rs`, round 2's **first-ranked** row at C=380, is now 22nd at
C=84: `params` is a commonplace and a `vte` type, not that module's word. `term/src/viewport.rs`
fell 280→55, `config/src/toml.rs` 172→24. The shader-tier grep lost its 205-site false row
entirely. And yet **the flag rate fell only from 28% to 30% of a slightly larger table, and the
B-flag share from 24% to 22%.** The lexical noise was in the sites, not in the flags.

**Leak counts tests as leakage, by construction, and the leak signature fires on test
fixtures.** The batch triage found this unprompted on several rows. B includes test files by
rule; A excludes them by rule; so every test file that exercises a module lands in `leak = B − A`
as a file that "speaks the concept's words without using its types" — when in fact it uses the
types and is merely not allowed to count. Over the 32 flagged rows: **363 leak files, 220 of
them (61%) under `/tests/`**. Five rows' leak is *entirely* test files, and
`crt-burnin/src/headless.rs`, one of the four rows carrying the run's **leak-signature** flag —
the pattern the methodology ranks first — is 20 test files out of 21. Since
`score = C × leak/B` is the tool's no-oracle ranking, a well-tested module is pushed up the
table for being well tested. The repair belongs in the tool: either report leak against
A-with-tests, or split the column into source leak and test leak. This run applied the split by
hand wherever a leak figure decided anything.

**What no filter will fix.** `app/src/tmux.rs` is unchanged at B=30, C=327, and its revival
returned artefact again: the stem is the name of the external program the whole feature is
about. A rule that dropped stems appearing in the README's prose would throw away real modules
named for what they do. Two source modules (`app/src/main.rs`, `app/src/lib.rs`) still have no
distinctive vocabulary at all; their B is printed as *not measured*, never as zero.

---

## Calibration, re-checked

Three fresh blind estimators, 108 modules, band ±1 log₃ (a factor of three):

| figure | inside band | median gap | round 2's panel | reading |
|---|---|---|---|---|
| A | 98/108 (90%) | +0.37 log₃ (×1.5) | 93%, +0.23 | calibrates |
| B | 73/108 (67%) | +0.46 log₃ (×1.7) | 67%, +0.51 | calibrates in its upper range |
| C | 29/108 (26%) | +1.53 log₃ (×5.4) | 32%, +1.40 | does not calibrate; under-guessed ~5× |
| D | 84/108 (77%) | −0.37 log₃ (×0.7) | 75%, −0.63 | calibrates; over-guessed |

Thirty-two rows flagged, 30% of the table: **B high** 24, **A high** 10, **D high (hub)** 8,
**leak signature** 4. The B-flag share, 22%, is under the level at which the methodology says a
run is reading its instrument.

**The panel is reproducible, and that is new.** Round 2's estimators and this round's never met,
and on the same 108 modules they agree within three points on every calibration figure and
within 0.2 log₃ on every median gap. The blind prior is not one panel's opinion; it is a
property of the description. A calibrates, C does not, D is over-guessed on average and still
carries its tail — all three now hold across two independent panels.

The facts calibrate differently from the modules, and this run is the clearest evidence yet:
of 16 decided-once facts, **four came back with real gaps** (×10, ×2.25, ×4, ×1.7) and one came
back not existing at all. Estimators guess module figures well and fact figures badly, always in
the same direction — they under-guess how many places obey a fact that no type carries.

---

## What the method could not see on this codebase

**The shader tier.** 25 `.slang`, `.slangp` and `.wgsl` files are outside the index and the
corpus. The supplementary grep found one real cross-tier vocabulary: `hash12` and `vnoise`,
written once in shader source and once in `chassis/src/oracle.rs`, which is that module's job.
But finding 3's mechanism runs through that tier, and fact 2 has an obeying site in
`term/src/shader.wgsl`. A codebase that computes in two languages keeps part of its scattering
below the indexer's floor.

**A fact that does not exist.** "Slots per bank page" was named by an estimator and is not a
decided fact: `chassis::bank::BankGeometry` computes it at run time from window geometry, and
nothing caps it but `CHANNEL_CAP`. Recorded as *not measured*, which is the rule. Round 2's
panel produced the same phantom independently.

**The low side of B**, unchanged: a module whose names are dictionary words measures near zero
however widely it is used. A is the figure that carries the low side.

**Only the type-level half of removal cost.** Nothing was drilled this round; A is the cheap
estimate of what a removal would cost the compiler, and for findings 1, 2 and 4 the point is
precisely that the compiler would not prompt at all.

---

## Artefact index

| artefact | path |
|---|---|
| Run notes: indexer, tiers, corpus rule, exclusions, blind spots, tool commit | `survey.md` |
| Count notes: command, out-degree distribution, A-on-tests, shader tier, conventions | `count.md` |
| Measured table (166 rows) and the conventions table | `measured-table.md`, `measured.json`, `measured-table.txt` |
| Per-flag vocabulary, A files, B files with per-word counts, leak files | `flagged-detail.json` |
| Oracle brief, exactly as sent | `oracle-brief.md` |
| Estimator replies, three | `oracle-replies/estimator-{1,2,3}.md` |
| Which estimator was furthest off per flagged row | `furthest.json` |
| Pick table with expected, measured, gap and flags | `pick-table.md`, `pick.json` |
| Decided-once facts: expected, then measured with patterns and homonyms | `facts.md`, `facts-measured.md` |
| The instrument's own faults, and the round-over-round stability check | `instrument.md` |
| Revival briefs as the revivals received them | `briefs/` |
| Revival reports, seven | `revivals/` |
| Symbol index, its JSON, the indexer log | `/usr/local/ai/scope/robco-2026-08-21-round-3/` |

Nothing was written into `/home/weiwu/code/RobCo-Terminal`.

---

## Cost

Nineteen minutes of wall clock, 15:09 to 15:28 on 2026-08-21.

| phase | what ran |
|---|---|
| Survey | `rust-analyzer scip` over the workspace (~40 s, warm target dir), `scip2json.py`; no agent |
| Count | `scope-count.py` and five small analysis scripts; no agent |
| Oracle | 3 blind estimators, cheap tier, fresh contexts, one file read each |
| Count (facts) | 2 cheap-tier probes over the 16 decided-once facts, 93 tool calls between them |
| Pick | `scope-pick.py`; no agent |
| Explain | 6 revivals of the three estimators in their own contexts (2 each); 1 fresh agent on the 25-flag batch triage |

**Nine agent contexts** — 3 estimators, revived 6 times between them; 2 fact probes; 1 triage —
plus this coordinating session. Roughly **455,000 subagent tokens**. The fact probes were again
the largest single cost (245,000 tokens, 93 tool calls) and again the only part of the run that
produced findings; splitting them in two, and telling them in the brief that a fact is measured
where it is *obeyed* and not where it is decided, is what stopped the false agreement round 2
had to correct by hand.

## Round-over-round

Third run, same commit, and the comparison the method does not otherwise get.

- **A and D identical on all 166 rows**, for the second time. The graph half is reproducible.
- **B moved on 34 rows and C on 46**, all downward, from the tool's vocabulary fixes alone. B is
  comparable across rounds only at the same tool commit; this run records `15caa5d`.
- **The blind panel is reproducible** to within three points across two independent panels.
- **Verdicts moved once, and I overruled a previous round rather than a revival**: round 2's
  tmux/channels finding does not survive a direct reading of the two files.
- **The two facts round 2 called scattered are confirmed by an independent probe**, with more
  sites than round 2 measured for the coordinate unit and the same mechanism for the bank side.
- **Two findings are new this round**: bitmap integer scale (fact 11), and the leak-counts-tests
  instrument fault, which the batch triage found on its own.

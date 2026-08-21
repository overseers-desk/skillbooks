# The instrument, checked against itself

This round holds the index fixed and changes the counting tool, which is the cleanest
instrument test the method has had. Round 2 measured commit `354e8f4`; so does this round, from
a **byte-identical** SCIP index (`md5 cb47be67…`). Every difference between the two measured
tables is the tool's.

## What did not move

| figure | rows differing, of 166 |
|---|---|
| A (type consumers, from the graph) | **0** |
| D (out-degree, from the graph) | **0** |
| B (vocabulary spread, by grep) | 34 |
| C (sites) | 46 |

A and D are identical on every row, as they were between rounds 1 and 2. **The graph half of
SCOPE is reproducible; the grep half is only as stable as the vocabulary rule.** Round 2 said
so after finding that two decoders of the same protobuf produced different B on 58 rows. This
round says it from the other direction: same decoder, same index, new filter, 34 rows moved.

## What moved, and why

Every change is downward. Total C over the table fell from **8,031 to 6,707 (−16%)**, and no
row rose. Three rules that round 2's `instrument.md` asked for are now in `scope-count.py`:

1. **A stop list of programming commonplaces**, for words a dictionary does not hold.
2. **A capitalised English word is counted in code only**, with comments and strings stripped
   and prose files left out, instead of matching prose.
3. **A stem is dropped when it names a dependency type or a directory in the tree**, alongside
   the existing rule for a stem several files share.

The four largest corrections, all of them rows round 2 named as instrument faults:

| module | round 2 | round 3 | the word |
|---|---|---|---|
| `crates/crt-render/src/params.rs` | B 38, C 380 (**1st on the table**) | B 12, C 84 (22nd) | `params`, a commonplace and a `vte` type |
| `crates/term/src/viewport.rs` | B 33, C 280 | B 5, C 55 | `viewport`, also a librashader type and a different struct in the same crate |
| `crates/config/src/toml.rs` | B 25, C 172 | B 6, C 24 | `toml`, the format's own name |
| `crates/app/src/channels.rs` | B 44, C 306 (4th) | B 10, C 243 | `Close`/`Nothing`, now code-only |

The shader-tier grep cleared the same way: round 2 reported 205 shader sites for `params.rs`,
all of them the librashader uniform-block word. That row is gone; what remains is the one real
cross-tier pair, `hash12` and `vnoise` in `chassis/src/oracle.rs`.

**B is not comparable across tool versions, and this table is the proof.** Round 2's report
already required the decoder to be pinned; this round adds that the tool's commit must be
recorded, which `survey.md` does (`15caa5d`).

## What the fix did not fix

The B floor is untouched and cannot be fixed by a filter. `crates/app/src/main.rs` and
`crates/app/src/lib.rs` still have no distinctive vocabulary at all and carry no B; that is the
instrument having nothing to grep for, and it is printed as *not measured* rather than as zero.

The stem is still the weak point where the domain owns the word. `crates/app/src/tmux.rs` is
unchanged at B=30, C=327, and its revival returned **artefact** again: `tmux` is the name of the
external program the whole feature is about, and no filter can distinguish a module's stem from
its domain's noun. The rule that would fix it — drop a stem that also appears in the README's
prose — would throw away real modules named for what they do.

## The flag share

24 of 108 modules flagged **B high** (22%), against round 2's 24%. The methodology's warning
level for "this run is reading its instrument" is a *large* share of the table; 22% is under it,
and this round's 22% is a cleaner 22% than round 2's, because the lexical faults that made up
much of round 2's share have been removed and the share barely moved. That is worth reading
twice: **the filter fixes removed 16% of all sites and 34 rows' worth of B, and the flag rate
fell by two points.** The flags were not mostly lexical after all; the sites were.

## A fault the fixes did not touch: leak counts tests as leakage

The batch triage found this by itself, on several rows at once, and the numbers bear it out.

**Leak is B minus the files the graph counted in A. B includes test files by rule; A excludes
them by rule.** So every test file that exercises a module is leak by construction — a file
that "speaks the concept's words without using its types", when in fact it uses the types and is
simply not allowed to count.

Over the 32 flagged rows: **363 leak files, 220 of them (61%) under `/tests/`**. Five rows'
leak is *entirely* test files — `term/src/size.rs`, `term/src/lib.rs`, `term/src/fonts/mod.rs`,
`crt-render/src/pacing.rs`, `config/src/lib.rs` — and `crt-burnin/src/headless.rs`, one of the
four rows carrying the run's **leak signature** flag, is 20 test files out of 21.

The consequence is not small: `score = C × leak/B` is the tool's no-oracle ranking, so a
well-tested module is pushed up the table for being well tested, and the leak signature — the
methodology's first-ranked pattern — fires on test fixtures. The measurement is not wrong, it is
mis-named: what it reports is "B files the non-test graph did not count", and a reader takes it
for "files that duplicate the concept".

Two repairs are available to the tool and the method should choose one, not both by accident:
report leak against A-with-tests, or split the column into `leak (source)` and `leak (tests)`.
This run reads every leak figure with the split applied by hand; the report says so wherever a
leak figure decides anything.

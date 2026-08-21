# SCOPE — finding where a codebase decides one thing in many places

**Phases:** Survey, Count, Oracle, Pick, Explain

## What SCOPE is

SCOPE finds the concepts in a codebase that are decided in more places than they should be: a feature whose removal touches a dozen files outside its module, a layout fact that every consumer recomputes from a scalar, a name that travels through comments and fields long after its type stopped travelling. The literature calls the condition change amplification (Ousterhout), shotgun surgery (Fowler), scattering (Kiczales), or a failure of information hiding (Parnas). The cost is paid on every later change: one intention becomes N edits, and the N is unknown until someone tries.

A count of consumers is not a finding. Config is read everywhere by design; a protocol adapter read by one file is healthy. What turns a count into a finding is the gap between the count and what a competent architect would expect of this program, knowing its purpose and size but not its code. SCOPE produces both numbers for every concept and works only on the gap.

- **Survey** lists the concepts to examine: every module, taken from the symbol-reference graph, plus the design facts the program decides once, listed by a blind architect from the README.
- **Count** measures each concept three ways: files that use its types (the graph), files that mention its names anywhere including prose (grep), and total mention sites. The difference between the first two is vocabulary leakage, the half no reference graph sees.
- **Oracle** asks blind estimators, given the README, the crate sizes and each module's one-line doc, to guess the same figures. No code, no counts.
- **Pick** compares on a log scale and keeps the concepts whose measured figures fall outside a band around the estimate.
- **Explain** revives the estimator who was furthest off, hands it the measured numbers, and has it verify the count before reading the code for the cause. "By design" is a valid answer.

**Direction:** inward, on the operator's own code. The method is a measurement, not a refactor; what it produces is a short list of concepts with a verified gap and a named mechanism, for the owner to act on.

## Why the method exists

Tools that measure coupling report density: references per function, dependencies per module, clones per file. A concept smeared across a codebase does not raise any of those averages; each file holds a little of it, and the average stays ordinary. What the smear raises is the count of files one change must visit, and that count is only visible per concept, against an expectation. Graph tools see the type-level half and report the module as well sealed while its vocabulary is in thirty files. Clone detectors see boilerplate. Thresholds set by a tool's author ("more than 15 dependencies") are arbitrary for any one program.

The blind estimate supplies the missing baseline. A reader of the README alone has a view of what a module of this kind should touch, and that view is free of the code's history. Where the measurement agrees, nothing is wrong that this method can see. Where it disagrees by a multiple, either the code or the measurement has something to say, and the revival finds out which.

## What SCOPE is not

Not a linter: it produces no pass or fail, and its flags are gaps to explain, not defects to fix. Not a dependency audit: crate graphs and cycle detectors answer other questions. Not a replacement for a removal drill: deleting a module and iterating the compiler gives the exact type-level cost of one removal, and SCOPE's Count is the cheap estimate of that cost across all modules at once, plus the vocabulary half the compiler never sees.

## Runs and the methodology

A run is one codebase measured once: a dated folder the operator keeps, holding the index, the measured table, the oracle brief and replies, the pick table and the revival reports. This methodology holds what every run shares. Nothing naming a run's code belongs here; INVARIANTS.md carries the rule.

## The phases

### S — Survey

Two lists, merged.

The module list comes from a symbol index of the codebase. Any SCIP-emitting indexer serves; for Rust, `rust-analyzer scip` writes the index and the `scip` CLI prints it as JSON. Every file that defines symbols is a concept, and its concept vocabulary is the set of names it defines plus its file stem. Common English words are dropped from the vocabulary, and a stem that is an English word is dropped too, or the prose of the whole tree inflates the count; names with an underscore or a capital inside stay.

The decided-once list comes from the Oracle's estimators, before they see anything else: "name the facts a program of this description decides once, and for each the number of places you would expect to edit if it changed". Which side a panel sits on, which unit a coordinate is in, which file format the config uses. These facts have no module and no symbol, so the graph cannot list them; the blind architect can. Each becomes a grep or a removal-drill target in Count, with an expected count already attached.

### C — Count

For each module concept, three figures:

- **A**, type consumers: files outside the module, tests excluded, that reference a symbol the module defines. Read from the index.
- **B**, vocabulary spread: files of any kind in the tree (sources, tests, docs, manifests) that mention any name in the module's vocabulary. Read by grep. Agent-session folders and build output are excluded; the tree as a reader would meet it is the corpus.
- **C**, sites: total mentions across those B files.

Leak is B minus the files the graph already counted; it is the set of files that speak the concept's words without using its types: fields of the same name on shared structs, a lower layer that cannot import upward and carries the concept in its own vocabulary, comments, docs. `tools/scope-count.py` computes all of this from the index JSON and the tree, and ranks by sites weighted by leak share, which alone (no oracle) puts a leaking module at the top of the table.

For each decided-once fact, the count is the number of independent sites that assume the fact. Grep for the obvious names first; where the fact is implied by arithmetic rather than named, a targeted pattern rule (semgrep or equivalent) over the accessor that carries it finds the sites, and a removal or flip drill in a scratch worktree confirms them through the compiler and the tests.

### O — Oracle

Three or more estimators on a cheap tier, each in a fresh context with no tools, each given the same brief: the README or its equivalent, the size of each crate or package in files and lines, the list of doc files, and for each module its path, its length and its own one-line doc. No code, no counts, no hint of what is suspected. The brief asks for A, B and C per module as integers, and for the decided-once list with expected places. `scope-oracle-brief.md` is the template. Take the median per figure.

Estimators agree with each other closely; the median guards against a stray answer, not against bias. Bias is systematic and shows up in Pick.

### P — Pick

Compare measured with expected as log₃(measured ÷ expected). Inside ±1 (a factor of three) is agreement. Outside is a flag, in either direction: more than expected says scattered; fewer than expected says well hidden, or measured wrong.

Calibration, measured on the first run and to be re-checked on each: A and B calibrate; most modules land inside the band, and the ones outside are the ones worth a look. C does not: estimators under-guess sites by an order of magnitude uniformly, so C flags everything and carries nothing. Pick on A and B; report C as density beside them. A module that is low on A and high on B at once is the leak signature and ranks first.

A decided-once fact is flagged the same way: expected places against measured sites.

### E — Explain

For each flagged concept, revive the estimator whose guess was furthest off, in its own context, with the measured figures and the one instruction that matters: check the instrument before the cause. It re-derives the count (what are the B files; does the corpus include anything a reader would not meet), and only if the count holds does it read the code for the mechanism and name it: the shared struct carrying the fields, the layer that duplicates the vocabulary, the scalar every consumer rebuilds geometry from, the prose. Under two hundred words, most consequential first.

"By design" is an outcome. A shared vocabulary (configuration, colour, layout types) reads by many files because that is its job; the revival says so and the flag closes. What remains is the list the owner acts on.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Symbol index (SCIP, printed as JSON) | S | C | run folder |
| Concept list: modules with vocabulary; decided-once facts with expected places | S, O | C, P | run folder |
| Measured table: A, B, C, leak, score per module; sites per fact | C | P, E | run folder |
| Oracle brief and the estimators' replies | O | P, E | run folder |
| Pick table: expected, measured, gap, flag | P | E | run folder |
| Revival reports: count verified or corrected, mechanism or "by design" | E | owner | run folder |

## Model allocation

Survey and Count are scripts and a cheap-tier agent for the pattern rules and drills. Oracle estimators are cheap-tier; their value is the blind prior, not depth. Explain revives the same estimators, so it runs on the tier they ran on; a concept the owner already knows to be consequential can be explained on a stronger tier in a fresh context, given the same brief and measured figures.

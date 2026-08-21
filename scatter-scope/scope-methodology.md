# SCOPE — finding where a codebase decides one thing in many places

**Phases:** Survey, Count, Oracle, Pick, Explain

## What SCOPE is

SCOPE finds the concepts in a codebase that are decided in more places than they should be: a feature whose removal touches a dozen files outside its module, a layout fact that every consumer recomputes from a scalar, a name that travels through comments and fields long after its type stopped travelling. The literature calls the condition change amplification (Ousterhout), shotgun surgery (Fowler), scattering (Kiczales), or a failure of information hiding (Parnas). The cost is paid on every later change: one intention becomes N edits, and the N is unknown until someone tries.

A count of consumers is not a finding. Config is read everywhere by design; a protocol adapter read by one file is healthy. What turns a count into a finding is the gap between the count and what a competent architect would expect of this program, knowing its purpose and size but not its code. SCOPE produces both numbers for every concept and works only on the gap.

- **Survey** lists the concepts to examine: every module, taken from the symbol-reference graph, plus the design facts the program decides once, listed by a blind architect from the README.
- **Count** measures each concept four ways: files that use its types (the graph), files whose types it uses (its out-degree), files that mention its names anywhere including prose (grep), and total mention sites. The difference between the first and the third is vocabulary leakage, the half no reference graph sees.
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

A run is one codebase measured once: a dated folder the operator keeps, holding the run notes, the measured table, the oracle brief and replies, the pick table, the revival reports and the report, with the index and any build output beside it outside the repository. This methodology holds what every run shares. Nothing naming a run's code belongs here; INVARIANTS.md carries the rule.

## The phases

### S — Survey

Two lists, merged.

The module list comes from a symbol index of the codebase. Any SCIP-emitting indexer serves: `rust-analyzer scip` for Rust; `scip-typescript` for TypeScript and JavaScript, given a tsconfig (kept outside the tree when the repository has none for a tier, pointing in by absolute path, so the index leaves nothing behind); the scip-python and scip-java indexers for their languages. `tools/scip2json.py` decodes the protobuf to the JSON the count reads, so the `scip` CLI is not needed. A tier the indexer does not cover (a scripting language beside the main one, generated code) is a blind spot of the run and the report names it as such.

Every file that defines symbols is a concept, and its concept vocabulary is the set of names it alone defines plus its file stem, filtered so prose cannot inflate the count: names with an underscore or an inner capital stay; capitalised type names stay and are matched case-sensitively; a lowercase name or a stem goes when it is an English word; a name that also names a symbol defined outside the tree (a standard-library or dependency type) goes, since a grep cannot tell the two apart. A name that several files define is not erased: it is a concept with several homes, the interface of a family of sibling modules (connectors, plugins, drivers), and the count reports it in a second table of its own.

The decided-once list comes from the Oracle's estimators, before they see anything else: "name the facts a program of this description decides once, and for each the number of places you would expect to edit if it changed". Which side a panel sits on, which unit a coordinate is in, which file format the config uses. These facts have no module and no symbol, so the graph cannot list them; the blind architect can. Each becomes a grep or a removal-drill target in Count, with an expected count already attached.

### C — Count

For each module concept, four figures:

- **A**, type consumers: files outside the module, tests excluded, that reference a symbol the module defines. Read from the index; exact.
- **D**, out-degree: files, tests excluded, whose symbols the module references. A module far above its expected D is a hub, a file holding several subsystems; A alone does not show it, since a hub is driven, not depended on.
- **B**, vocabulary spread: files of any kind in the tree (sources, tests, docs, manifests) that mention any name in the module's vocabulary. Read by grep. The corpus is the tree as a reader would meet it: agent-session folders, build output, dependency trees, lockfiles and generated catalogs (translation files, bundled design output) are out, and the run's notes say what was excluded and why.
- **C**, sites: total mentions across those B files.

Leak is B minus the files the graph already counted in A; it is the set of files that speak the concept's words without using its types: fields of the same name on shared structs, a lower layer that cannot import upward and carries the concept in its own vocabulary, comments, docs. `tools/scope-count.py` computes all of this from the index JSON and the tree, ranks modules by sites weighted by leak share, which alone (no oracle) puts a leaking module at the top of the table, and writes the convention table beside it.

B has a floor. A module whose distinctive names are few, or whose names collide with dictionary words or external types, measures B near zero however widely it is used; the tool marks such rows, and a low B is read as "the instrument had little to grep for", never as "well hidden". A is the figure that carries the low side.

For each decided-once fact, the count is the number of independent sites that assume the fact. Grep for the obvious names first; where the fact is implied by arithmetic rather than named, a targeted pattern rule (semgrep or equivalent) over the accessor that carries it finds the sites, and a removal or flip drill in a scratch worktree confirms them through the compiler and the tests.

### O — Oracle

Three or more estimators on a cheap tier, each in a fresh context with no tools, each given the same brief: the README or its equivalent, the size of each crate or package in files and lines, the list of doc files, and for each module its path, its length and its own one-line doc. No code, no counts, no hint of what is suspected. The brief asks for A, B, C and D per module as integers, and for the decided-once list with expected places. `scope-oracle-brief.md` is the template. `tools/scope-pick.py` reads the replies and takes the median per figure.

Estimators agree with each other closely; the median guards against a stray answer, not against bias. Bias is systematic and shows up in Pick.

### P — Pick

Compare measured with expected as log₃(measured ÷ expected). Inside ±1 (a factor of three) is agreement. A flags in either direction, since it is exact: more consumers than expected says shared, fewer says sealed, or measured wrong. B flags upward only; its low side is the floor. D flags upward only: the hub. A module low on A and high on B at once is the leak signature and ranks first. `tools/scope-pick.py` applies these rules and writes the pick table with an empty disposition column for Explain to fill.

Calibration, re-checked on every run against the record here: A calibrates best (most modules inside the band, median gap near zero); B calibrates in its upper range; C does not, estimators under-guess sites several-fold uniformly, so C flags most of the table and carries nothing. C is printed as density beside the others and never picked on. A run whose B flags reach a large share of the table is reading the instrument, not the code, and the run's notes say so before any revival.

A decided-once fact is flagged the same way: expected places against measured sites, with the measured side stated as "decided in" (the definition) and "obeyed in" (the consumers) where the two differ, since estimators answer the first and a grep answers the second. A fact probe names the homonyms it excludes; a fact whose only handle is a common word is drilled or recorded as not measured, not given a number.

### E — Explain

For each flagged concept, revive the estimator whose guess was furthest off, in its own context, with the measured figures and the one instruction that matters: check the instrument before the cause. It re-derives the count (what are the B files; does the corpus include anything a reader would not meet; is a vocabulary word doing the work alone), and only if the count holds does it read the code for the mechanism and name it: the shared struct carrying the fields, the layer that duplicates the vocabulary, the scalar every consumer rebuilds geometry from, the prose. Under two hundred words, most consequential first.

Three outcomes close a flag: scattered, with the mechanism and its cost named; by design, where a shared vocabulary (configuration, colour, layout types, a UI kit) reads by many files because that is its job; artefact, where the count was the instrument's. A flag whose cause is plain from the table itself (an artefact the vocabulary column shows, a shared vocabulary the graph alone establishes) may be triaged in a batch, one context reading the table; every other flag gets its own revival, since a batch verdict on a real candidate is the weakest verdict a run produces. What remains is the list the owner acts on.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Symbol index (SCIP and its JSON), build output the indexer needed | S | C | beside the run, outside the repository and the run folder, named by path in the run's notes |
| Run notes: indexer and tiers, corpus rule and exclusions, tiers used, what the index does not cover | S, C | report | run folder |
| Concept list: modules with vocabulary, the convention table, decided-once facts with expected places | S, O | C, P | run folder |
| Measured table: A, D, B, C, leak, score per module; sites per fact | C | P, E | run folder |
| Oracle brief and the estimators' replies | O | P, E | run folder |
| Pick table: expected, measured, gap, flags, disposition | P | E | run folder |
| Revival reports: count verified or corrected, mechanism, by design, or artefact | E | report | run folder |
| `report.md`: findings with dispositions most consequential first, what closed by design, what the instrument got wrong, calibration re-checked, what the method could not see on this codebase, the artefact index, cost | all | owner | run folder |

## Model allocation

Survey and Count are scripts and a cheap-tier agent for the pattern rules and drills. Oracle estimators are cheap-tier; their value is the blind prior, not depth. Explain revives the same estimators, so it runs on the tier they ran on; a concept the owner already knows to be consequential can be explained on a stronger tier in a fresh context, given the same brief and measured figures.

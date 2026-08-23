# PLACE — asserting the market position of something already built

**Phases:** Poll, Landscape, Audit, Contrast, Establish

## What PLACE is

PLACE states where a built product stands in a field that already ships. The product exists, its code is on disk, and rivals are published; what is missing is an account of its position that a stranger could check: which of the pains its users voice it answers, how rare each of those answers is among the rivals, where its architecture stops it, and what that adds up to as a claim, a name, and a way of speaking about it. PLACE builds that account from the field first and the code second, and keeps the two apart so that neither is read through the other.

- **Poll** collects what users of this kind of product say in public, verbatim, each quote dated, linked, and mapped to a numbered pain.
- **Landscape** records what the rivals supply against the same numbered pains, as their authors describe it, in a dated matrix.
- **Audit** reads the operator's own code and says, per pain, what is solved, partial, or absent, where in the source, and what the architecture cannot reach.
- **Contrast** rates each shipped capability for rarity against the Landscape, and sorts the gaps into the architectural and the feasible.
- **Establish** derives the positioning the corpus supports and a name that claims no more than the Audit shows, and says plainly whether a launch has a hook at all.

**Direction:** inward, after the fact. SAGE decides what to build before it exists; PLACE describes what was built once it exists, against a field that was not consulted while building. Its product is an honest account, for the owner and for whoever writes the product's copy.

## Why the method exists

Asked where a product stands, an AI writes its position from the product's own README: every feature is a strength, every rival is a foil, and the adjectives come from the code's comments. Three things go wrong at once. The pains are the author's, not the users'; the rivals' capabilities are guessed from their names; and the product's own coverage is read from what it intends rather than what it does. The account is then quoted back to the owner as market knowledge.

PLACE separates the three sources and fixes the order. The pain taxonomy is authored once, from what users say, and numbered, so that every later document cites a number instead of restating a claim it might drift. The field is recorded against those numbers before the product is. The product is read from its code against those numbers, in the one file allowed to cite source paths. Only then is rarity computed, and only then is anything written about position.

The demand reading the taxonomy carries is published with the biases that shape it, because the public corpus is not the user base: the people who post are builders and bug-reporters, the pains whose moment is private leave little trace, and a community that has learned to work around a pain stops voicing it. A demand figure without those caveats beside it is the number most likely to be misread downstream.

## What PLACE is not

Not a build-priority ranking: Contrast describes the built product, and a rare capability is not thereby the next thing to build. Not a product-design method: no parameter is ruled on and no design competes; for that, SAGE. Not a review of the rivals: their capabilities are recorded as self-described and marked unconfirmed where they could not be, and the account says so.

## Runs and the methodology

A run is one product positioned once: a set of files the operator keeps beside the product, each carrying its snapshot date in its head, re-snapshotted when the field or the code changes. This methodology holds what every run shares. Nothing naming a run's product, its field, or its sources belongs here; INVARIANTS.md carries the rule.

## The spine: one numbered taxonomy

Every run rests on one list of the pains users of this kind of product voice, each pain numbered and defined in a sentence or two, authored in exactly one file. The numbers are stable identifiers, not a ranking; they are never reused, and renumbering is a cross-file act performed on every citing document in the same change. The Poll maps quotes to them, the Landscape's matrix columns are them, the Audit's rows are them, and Contrast and Establish cite them. A reader who holds the taxonomy file can follow any other file in the run.

The taxonomy is authored from the Poll, not before it. A pain earns its number when at least two independent voices name it; a single voice stays under its nearest sibling until a second arrives. A pain the field serves but nobody voices is not a pain; a pain many voice but nothing serves is the interesting row.

Beside the taxonomy sits the demand reading: per pain, how often and how loudly it is voiced, with the evidence location, and the caveats above stated in the same file.

## The phases

### P — Poll

Verbatim quotes from public discussion of this kind of product: forums, issue trackers of the product category's projects, long-form posts, talks. One entry per quote, in a fixed form: the quote in the speaker's own punctuation, an attribution line (handle or name, venue, date, and the venue's engagement figure where it has one), a working link, one or two lines of context, and the pain number or numbers. Where only a paraphrase can be had, it is marked as one and linked, and treated as a debt to repay with the verbatim text. A date known only roughly is written roughly; precision is not invented. Within a pain, entries sort oldest first, so the section reads as a timeline of the pain.

The form, as it reads in a run's file (a made-up entry):

```
> "it still asks me twice before it will save, and the second time I have forgotten what I changed"
> — handle, venue, Month YYYY (score N)
> https://venue.example/thread/123#comment-456
> Context: a comparison thread; said of the product the speaker had just left.
> Maps to: P4
```

Where a claim has no quote behind it, the file says so in those words ("no verbatim complaint found; the closest is ..."), so that absence of evidence is never silently promoted to evidence of absence.

A request a rival's maintainers declined is marked as declined: it shows a need users plainly feel being turned away, which is an opening for another product.

The Poll is also a corpus of language. Whoever later writes the product's copy takes their words from it, so that the product speaks to users in the vocabulary they already think in. The file says this at its head.

Collection fans out by source; each collector returns entries in the fixed form and nothing else, and the taxonomy is authored by one reader over the merged corpus. Collection stops when a further sweep adds no new pain, and the run's notes record how many sweeps that took.

Two mechanics decide whether the fan-out returns anything. Venues reached through an API (a search index, an issue tracker's CLI) fan out freely; venues reached through a shared headless browser are collected serially, one collector at a time, because parallel collectors starve one another and a starved fetch can read as an authentication failure. Every collector is briefed to return on a budget (so many calls, so many entries) rather than to wait on work of its own; a collector that stops with "waiting" and no entries is nudged once to return what it holds, and what it holds is taken, with the sweeps that did not return recorded as absences.

The counter-segment is part of the corpus: the voices that say this kind of product is unnecessary, that the default is fine, that the feature everyone argues about was never noticed. They are often the highest-scored comments in a thread, and Establish needs them; they earn a pain number of their own rather than a footnote.

### L — Landscape

A feature matrix of the field, dated. Rows are the rival products, including the incumbent or default the buyer already has where one exists; columns are the pain numbers; cells are Yes, No, Partial, or unconfirmed, each with a few words of how. Capabilities are recorded as their authors describe them in launch posts and READMEs, not re-verified, and the file says so at its head. Traction and activity figures are given in the venue's own currency, approximate, and omitted where unknown; where the field is commercial, price and licence are columns too. The operator's own product does not appear: its coverage belongs to the Audit, and a row for it here would be the product reading the field through itself.

Below the matrix, a supply note per pain: how much of the field serves it, how, and what is absent from the whole field. The absences are what Contrast later rates as rare or unique, so they are stated carefully, as "documented in none of the surveyed products" rather than "nobody does this".

The file names its re-snapshot trigger: a new rival reaching the top tier, one abandoned, a platform or standard the field depends on changing, or a stated interval.

A companion file, where the corpus supports it, reads the discussion dynamics of the same venues: what kinds of post about this category draw replies and what kinds draw only approval, measured as comments against score across a table of posts with links, and the precedent for a launch of this product's kind in particular (what the nearest prior product drew, how often, with what comments). A venue with a search API is tabulated first, since its figures are cheap and complete; a venue without one is tabulated only as far as the collection reached, and the file says which. This is market fact, and lives with the market files; the positioning that follows from it is strategy and lives with the Audit.

The matrix is transcribed from the products' own pages, not from a summariser's account of them: a fetcher that returns a summary can invent a capability for a product that makes no such claim, and the run that taught this caught one before it reached the matrix. A cell the collector cannot see on the primary page is unconfirmed.

### A — Audit

The one file in the run written from the code rather than from the field, and it says so at its head. A coverage table, one row per pain: Solved, Partial, or None; the mechanism in a sentence; the source paths; and the ceiling, where the architecture or a dependency the product sits on forbids more than was built. A feature catalogue follows: each shipped feature with its code home and the pains it serves, including the quality properties that serve no single pain.

The Audit reads the code, not the product's README, and is written by a reader with the source open; a coverage claim without a path behind it is a claim about intent. Three statuses a feature can have, and the third is the one a README never admits: built and wired, built but unreachable from the shipped product (no control, no entry point, no caller), and intended only (a config key or a doc sentence with nothing behind it). The Audit lists, separately, the README claims it found no code behind, the capabilities in the code the README does not mention, and the defects or stale comments that would mislead a reader of the source; a tree with no TODO markers is not thereby clean, since deferred work is often prose at the code that owns it.

### C — Contrast

For each shipped capability, its rarity against the Landscape: common (the field's default), rare (a few rivals), unique (documented in none of the surveyed rivals), each with a clause saying which rivals come closest. Then the gaps, in two lists: architectural limits, which the product's design rules out, and not-built-but-feasible. The section states, in its first line, that it describes the built product and does not rank what to build next.

Contrast lives in the Audit's file, below the coverage table, because both are statements about the product.

### E — Establish

From the discussion-dynamics reading, the positioning moves the corpus supports, and their ceiling: what a launch of this kind of product has drawn before, and what hook it would need to draw more. Where the corpus shows no precedent for a launch of this kind succeeding, Establish says so; an honest "there is no hook here" is a valid result of the run, and the owner is served better by it than by a move.

Then the name. The Audit bounds what the name may claim: a name that promises a class of function the product lacks overclaims, and a name that covers one verb among several underclaims. Where the current name passes, Establish records that it passes and why; where it does not, the run writes a naming note with the retired names, the mismatch each carried, and the new name's reasoning.

Positioning lives with the Audit, in the product file, as explicit strategy, not with the market files.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Quote corpus: verbatim entries by pain, with link, date, context | P | taxonomy author, E, copy writers | run folder, market side |
| Taxonomy and demand reading, with caveats | P (authored over the corpus) | every other file | run folder, market side; the one authoring home for pain numbers |
| Field matrix and supply notes, dated, with re-snapshot trigger | L | C, E | run folder, market side |
| Discussion-dynamics table (conditional) | L | E | run folder, market side |
| Coverage table, feature catalogue, rarity map, gaps, positioning | A, C, E | owner, copy writers | run folder, product side |
| Naming note (conditional) | E | owner | run folder, product side |
| Run README: the files, their roles, the conventions, the sources, how to grow the folder, what was not reached | all | next contributor | run folder |

## Model allocation

| Phase | Tier | Rationale |
|---|---|---|
| P collection | Sonnet-tier, many agents, one per source | The entry form does the work; volume matters |
| P taxonomy and demand caveats | Opus-tier, one reader | Deciding what counts as a distinct pain is the run's judgment |
| L matrix cells | Sonnet-tier | Transcription from launch posts under a fixed cell vocabulary |
| L supply notes, discussion dynamics | Opus-tier | Reading absences and dynamics across the whole table |
| A | Opus-tier, source open | The code decides; a README-reader audits intent |
| C | Sonnet-tier | Mechanical once L and A exist |
| E | Opus-tier | Judgment about hooks, ceilings, and names |

## Relationship to the other methodologies

SAGE's Establish produces the numbered claims a SPAR campaign cites; PLACE's Establish does the same job for a product that already shipped, and its Landscape answers a question SAGE's Survey asks for a market the operator has not yet entered. Where a PLACE run ends in a launch, the launch post's copy takes its words from the Poll corpus, and replies arrive through TEND.

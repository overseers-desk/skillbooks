# What changed in the SAGE method between 8 September and 17 September 2026

The method lives at `/usr/local/src/aesop/pmf-sage/`. Its state before the change is commit `16fa77d` (8 September 2026); read any file as it was with `git -C /usr/local/src/aesop show 16fa77d:pmf-sage/<file>`. Its state now is the working tree. `git -C /usr/local/src/aesop diff 16fa77d HEAD -- pmf-sage/` is the whole change. The current documents are the authority; this digest is an index into them, and where the two differ the documents are right.

## Why it changed

The owner judged a September run to be "document clergy work, not pmf": a buyer pasted from a sibling run became the frame, the codebook and the ranking; every decision card carried one recommended answer, many landing on a value an internal document already held; present practice at the venue was read as a product constraint. His test: a recommendation that arrives as one answer with no other options came from an existing document, because a market speaks in several voices. A second hole was found in the same week: no run had read what buyers type into a search engine as a demand signal, and few enquiries had been read as little demand without asking whether anyone could have enquired for something never offered or named.

## The changes, by phase (each term below is the documents' own and greps there)

**Survey (`sage-S-survey.md`)**

- A **strike list** opens the run: every candidate buyer a row with what they type, who addresses them, the operator's own records split by buyer, rivals selling to them, and a strike column; no recommendation. The owner strikes; an unstruck buyer is in. Frames draw source lists per unstruck buyer. A buyer the orchestrator or a brief author filled in is the failure mode **Silent scoping** (`sage-methodology.md`).
- A **shape note**: how the operator's buyer arrives, whether entry is paid before the offering is reached, how the sale is taken, how a place is held. Every measured population is marked shared or differs against it.
- The codebook carries a variable for whom each operator sells to.
- A fifth demand signal, **what buyers type**: seeded terms, monthly volume split into layers, intent struck, name collision, adjacent terms, season, with stated limits; a run with no keyword instrument records the gap.
- The enquiry record states, beside any count, the condition the count was taken under (what was offered, under what name, on what surface); absence from the enquiry record is absence from what the operator invited.
- **The fence** closes facts as well as files: the venue's own drafts, present practice and every sibling run are closed to deriving agents; a sibling run's frame is a source list with provenance, never the frame. The owner's example is a prior and a **named row** outside every rate.
- Every brief is checked by `tools/launch-check.py` before launch: a line fixing a buyer, a price or an offer count carries RULED with its ruling or DEFAULT with its finding.

**Adjudicate (`sage-A-adjudicate.md`, `forms/card.md`, `forms/review.md`)**

- A card is a question with at least two options, each carrying a figure with its source, a capability leg with cost lines, and a **seller's sentence**; then a recommendation with its margin over the strongest other option (a **count lead** where the options are values); the **measured-in** line; boundary tests; the priors line last.
- The buyer card is ruled first at the second gate, with the one-offer-or-several card beside it.
- Four cards carry a search-demand leg (name, surface, unit, season); the surface card cannot be ruled without it.
- Three clerk roles: deriving clerks behind the fence; one **priors clerk** who opens the venue's files afterwards and says whether the recommendation matches a value already held; a blind **third derivation** on every matched card and on the price card.
- `tools/card-check.py` refuses a card with fewer than two figured options, a margin in the wrong unit or against a weaker option, and a matched card with no third derivation; `tools/assemble-review.py` builds the owner's review from the card files.

**Game (`sage-G-game.md`)**: two lines. Demand is a fixed input every variant shares, never a judging criterion; two judge scenarios draw on the search findings. The Game's own procedure is otherwise as it was on 8 September.

**Establish (`sage-E-establish.md`)**: one addition, the eight-value handoff to the operator's **market map** (chosen name and the terms it was chosen against, owned surface, unit, buyer, price band, value per conversion, season, capacity ceiling).

**Frame (`sage-methodology.md`)**: a dated reading, 2026-09-15 (read its closing section on runs and readings for the exact rule). A run states the date it started and the reading it runs under; with no reading stated it is read under the one in force on its start date. That rule governs how a record is read; whether a run's *conclusions* survive the faults the change was made to fix is the question you are answering.

# SAGE — product development to fit in a proven market

**Phases:** Survey, Adjudicate, Game, Establish

## What SAGE is

SAGE develops a product for a market that already exists. The category is proven: comparable operators already sell days, packages, services of this kind, and buyers already buy them. The open question is not whether anyone wants such a thing, so SAGE runs no existence experiment. The open question is fit: exactly which composition, price shape, group mechanics and claims win a booking against the incumbent the buyer already uses. SAGE reaches that fit by reading the market at research grade where its peers rely on trial and error, then deciding on cards, then letting designs compete blind in front of simulated buyers, then folding the winner into one definition whose every claim has a number behind it.

- **Survey** builds the evidence: comparable operators worldwide drawn from registers and coded under a frozen codebook, the local rivals a booking is won or lost against, the demand signals around them, and the distributors whose transactions cross the whole market.
- **Adjudicate** puts every product parameter on a card in front of the owner: prior values, ruling, provenance, boundary tests. The output table bounds what any later agent may design, promise or claim.
- **Game** has isolated design arms derive the product's interior from the evidence alone, passes them through a reviewer gate, and judges them blind through role-played, individually profiled buyers. The winners are absorbed into one sheet and crowned on a held-out panel.
- **Establish** turns the crowned design into the shipped definition: numbered selling-point claims with measured scarcity, the definition folded by stated rules, every value migrated to its single home, and a displacement offer put to named prospects the operator already holds.

**Direction:** inward. The operator must decide what to build, and the discipline is that the market's evidence decides it. Everything internal that could pre-decide the product (old drafts, meeting opinions, half-built local practice) is either fenced off or made to survive adjudication in daylight.

## Why the method exists

AI fails at product work in specific, repeatable ways, while being better than any staff at breadth of reading. Left alone it writes product text from nearby text, inherits parameters from old drafts, treats internal opinion as market data, sells what nobody decided to sell, and cannot state the reason for a choice. SAGE splits the work accordingly: AI does the evidence and the design breadth, the owner sits at the decisions, and fences with blind judging stand wherever contamination would flow.

The named failure modes, each countered by a specific mechanism:

- **Text-generation inheritance**: a parameter copied because a nearby document said it, with evidence fitted around it afterwards. Countered by provenance chips at Adjudicate and the clean-room fence at Game.
- **Librarian anchoring**: asked for market analysis, the AI mines internal opinion and old plans, and the loudest internal adjective becomes the product. Countered by Survey giving the deriving AI a real market to read.
- **Confabulated offers**: asked to sell, an AI invents what it does not have; told to sell a pen, it offers a million dollars with the pen. Countered by the Adjudicate table as a bounding box on every downstream promise.
- **Self-infantisation**: an AI briefing other AIs hardens an undecided parameter into a fixed rule the owner never granted. Countered by the rule that a parameter absent from the decisions table is design freedom.
- **Format smuggling**: a design arm mandated to compete on one dimension quietly alters decided format, and downstream documents record the invention as ruled. Countered by the reviewer gate.
- **Presentation artefact**: a judging round decided by document polish rather than the product inside it. Countered by mechanical blinding and uniform presentation.
- **Panel overfitting**: a design tuned to the judges who scored it. Countered by the held-out crown-check panel.
- **Verdict loss**: judge reasoning surviving only in a session transcript, unciteable a day later. Countered by persisting verdicts verbatim inside the run.

## What SAGE is not

Not a startup validation method: it assumes the category sells and tests displacement, not existence. Not a documentation exercise: reading substitutes for trial and error only where the market publishes its behaviour, and Survey names that blind spot rather than hiding it (what is bought is not always printed). Not a committee: exactly one human, the owner, rules, and rules on cards.

## Runs and the methodology

A run is one product developed once: a dated folder in the operator's own repository holding the evidence, the cards, the game record and the definition, in stage order. This methodology holds what every run shares; the run holds everything about one product and one market.

The dividing test, applied to any fact: would a different product run by the same operator use this fact unchanged? If yes, it belongs in the operator's standing records (fee schedules, capability notes, buyer rosters), referenced by the run. If the fact exists only because of this product, it belongs in the run. Nothing product-specific belongs here: a methodology document that names one run's product category is the bug, and INVARIANTS.md carries the rule.

## The phases

Each phase has its own procedure document; this file states what each phase is for and what crosses its boundary.

**S — Survey** (`sage-S-survey.md`). Produces numbered findings from a coded comparables corpus, a section-numbered rival register, demand signals, and distributor evidence. Later documents cite finding numbers and register sections instead of restating claims. Where the product had prior internal drafts, Survey also produces the fence: an index of every file carrying pre-decided parameters, from which clean-room blacklists are generated. A wholly new product skips the fence.

**A — Adjudicate** (`sage-A-adjudicate.md`). Consumes the evidence; produces the decisions table, via cards the owner rules on. A ruling stands on two legs, named demand evidence and named capability. The table is the single register of ruled against recommended, and the bounding box for every later phase.

**G — Game** (`sage-G-game.md`). Consumes the evidence and the decisions table; produces a crowned design sheet and the persisted verdicts behind it. Arms derive context-free, the reviewer cuts what oversteps the table, blinded judges cast from profiled buyers rule, absorption folds the winners, and a held-out panel confirms the crown.

**E — Establish** (`sage-E-establish.md`). Consumes the crowned sheet, the verdicts and the corpus; produces the numbered claims, the shipped definition, the migration of every value to its home, and the displacement offer to named prospects.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Comparables frame, codebook, coded corpus, numbered findings | S | A, G, E | run folder, survey stage |
| Rival register (section-numbered), demand signals | S | A, G, E | run folder, survey stage |
| Distributor evidence notes | S | A, E | run folder, survey stage |
| Fence index and generated blacklists (conditional) | S | G briefs | run folder |
| Decision cards and the decisions table | A | G, E, every brief | run folder; compact table repeated in the definition |
| Arm sheets, reviewer cuts, blind keys, verdicts | G | G absorption, E | run folder, game stage |
| Crowned sheet and crown-check record | G | E | run folder |
| Numbered claims with grounding table | E | outreach campaigns | run folder |
| Product definition | E | the operator's business | beside the run folder |
| Migrated values | E | standing records | each value's own home |

## Model allocation

| Phase | Tier | Rationale |
|---|---|---|
| S | Sonnet-tier, many agents | High-volume register pulls, collection and coding under a frozen codebook; the codebook does the intellectual work |
| S frame review, codebook author | Opus-tier | Adversarial reading and blind drafting carry the run's validity |
| A | Human, with AI clerking the cards | The owner's judgement is the phase |
| G arms, reviewer, judges | Opus-tier | Design quality, table enforcement and buyer role-play reward the strongest models |
| E folding and claims | Opus-tier | Quotable-clean writing under provenance quarantine |
| E migrations and sweeps | Sonnet-tier | Mechanical, rule-following |

## Versioning

The methodology carries no version field yet; the first change that would invalidate a completed run's record introduces one. A run states the date it started, which fixes which reading of the methodology governed it.

## Relationship to the other methodologies

Establish's numbered claims are what a SPAR campaign's approach messages cite by number, and the displacement offer is naturally run as a SPAR campaign over an owned roster. The Adjudicate table is the bounding box those messages may not escape: an approach draft promising anything outside it is the confabulated-offer failure, caught at review. Replies to the displacement offer arrive through TEND.

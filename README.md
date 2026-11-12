# AESOP

**AI-Executed Standard Operating Procedures**

SOPs written for AI agents to follow autonomously. These are not documentation for humans — they are instructions an AI reads and executes.

## Methodologies

Each methodology covers one direction of information flow as a four-phase pipeline executed by AI agents, with domain-specific content (segments, taxonomies, scoring rubrics) supplied by a campaign configuration rather than by the methodology itself.

### SPAR — Outreach Discovery and Engagement

**Phases:** Sweep, Profile, Approach, Reply

**Direction:** Outbound. The operator has something to offer and needs to find people who might want it, research them, and write a message specific enough that the recipient can tell it was written for them.

**What each phase does:**

- **Sweep** discovers names from registries, directories, social graphs, and web searches. Iterates up to three times, each expanding the roster through social-graph and semantic expansion.
- **Profile** builds a dossier for each contact: what they have said publicly, who they know, their current role, and how relevant they are to the campaign. Produces a star rating: how valuable the contact is to us, independent of any one campaign. The response-likelihood estimate belongs to Approach, because it turns on the angle chosen.
- **Approach** drafts a personalised message for each contact, tested against a context-isolated challenger agent that role-plays the recipient. The challenger has never read the campaign files and reacts as a stranger would.
- **Reply** waits for a reply to each sent message. Any reply ends the process for that contact and hands them to the human. Between bands, the human reviews what worked and adjusts the strategy for the next band.

**Model allocation:** S and P are Sonnet-tier (high volume, rubric-following). A is Opus-tier (tone, angle selection, cross-referencing prior relationships). R is the dispatcher's reply check; the review between bands is human.

**Procedure documents:** `outreach-spar/spar-methodology.md` and the phase-specific AESOPs (`spar-S-sweep.md`, `spar-P-profile.md`, `spar-A-approach.md`).

**Tooling:** `outreach-spar/spar-manager/` holds its runnable scripts at the top: a transition dispatcher (`spar-transition`), a progress reporter (`spar-progress`), a validator (`spar-validate-cli.tcl`), a Tk GUI (`spar-ui`), and the two phase harnesses. The libraries they source sit under `lib/`. These read a campaign YAML, classify contacts via the state machine (`lib/spar/state-1.0.tm`), and dispatch work to the Claude Code CLI.

#### SPAR use cases

**A tourism venue's segmented partnership outreach**. 19 segments (wedding planners, tour operators, community organisations, market stallholders), 415 contacts profiled, 258 approach messages drafted. The full pipeline, all four phases active.

**Open source foundation governance outreach**. A 56-contact search for founding members and a chair, and a 160-contact community tier across the open source security community. SPAR applied to institutional commitment asks rather than commercial partnership.

**Courier GitHub star seeding**. Developer contacts from email archives, scored for closeness and asked to star a repository, with sparring rounds set to zero. SPAR scaled down to a one-line ask.

### SIFT — Listing Evaluation and Response

**Phases:** Sweep, Investigate, Fit, Target

**Direction:** Inbound-reactive. An external party has published a listing (job posting, grant call, CFP, tender) and the operator must decide which to pursue and how to respond.

**What each phase does:**

- **Sweep** discovers listings from campaign-defined sources (job boards, grant databases, company career pages). Casts wide without filtering. Every listing gets a registry row.
- **Investigate** fetches each listing, archives the full description as a permanent dossier, and researches the source organisation. The dossier ensures that scores remain auditable even after the listing goes offline.
- **Fit** scores each listing on two axes: value-to-us (stars, computed from campaign-defined dimensions) and likelihood-of-success (percentage, computed from requirement matching against the operator profile, with amplifiers for competitive advantages). The two axes together produce a prioritisation matrix.
- **Target** decides disposition (respond, skip, watch, network-approach) and prepares response materials for listings worth pursuing.

**Model allocation:** Sweep and Investigate are Sonnet-tier. Fit is Sonnet-tier (rubric application). Target is human judgment with Sonnet-tier response preparation.

**Procedure documents:** `listing-sift/sift-methodology.md`, `listing-sift/sift-registry-format.md`, `listing-sift/sift-campaign-directory.md`.

#### SIFT use cases

**Published job listings**. 180+ listings scored on four dimensions, with five amplifier tags.

### TEND — Correspondence Processing

**Phases:** Thread, Evaluate, Notify, Dispatch

**Direction:** Inbound. Email arrives in the director's inbox and must be classified, prioritised, and acted upon — with the full conversation history read before any judgment is made.

**What each phase does:**

- **Thread** assembles the complete conversation for an incoming email using message-ID threading (mu's `--include-related`). The agent reads the full thread before examining the new message. This prevents misstaged actions (approving what was already approved, following up on what is already answered).
- **Evaluate** classifies the email by category (from an empirically-built taxonomy) and determines the conversation stage (opening, active, awaiting-us, awaiting-them, agreed, closed, stale). Stage determines what action is appropriate — the same category requires different handling depending on where the conversation stands.
- **Notify** determines what the director sees and when, by consulting the ruleset. Four levels: auto (AI processes silently), draft (AI composes reply, director reviews), flag (AI summarises for director attention), block (director handles personally). Stage modifies the level — a normally-auto email may be escalated if the thread reveals something unexpected.
- **Dispatch** executes the action: file, draft a reply, forward to a delegate, or present to the director with context.

**Model allocation:** T is a database operation (mu query, no LLM). E is Sonnet-tier. N is a rule lookup (no LLM). D ranges from Haiku (filing) through Sonnet (routine drafts) to Opus (sensitive correspondence requiring relationship nuance).

**Procedure documents:** `correspondence-tend/tend-methodology.md`.

#### TEND use cases

**A business director's inbox**. A taxonomy built from 226 emails in five batches: 64 categories, each with its processing rule. The taxonomy and rules belong to the deployment; TEND defines how an agent uses them.

### SAGE — Product Development to Fit in a Proven Market

**Phases:** Survey, Adjudicate, Game, Establish

**Direction:** Inward. The operator must decide what to build in a market that already exists; the discipline is that the market's evidence decides it, against the operator's own priors, drafts, and internal opinion.

**What each phase does:**

- **Survey** builds the evidence at research grade: comparable operators worldwide drawn from enumerable published lists and coded under a codebook frozen blind, an adversarial frame review before any collection, the local rival register with demand signals, and distributor evidence from intermediaries whose transactions cross the whole market. Findings are numbered so every later document cites a number instead of restating a claim.
- **Adjudicate** is a human phase. Every product parameter is decided on a card: prior values, ruling, provenance chip (inherited, anchored, derived, radical), four boundary tests. A ruling stands on named demand evidence plus named capability. The output table bounds what any downstream agent may design, promise, or claim, and a parameter absent from it is design freedom.
- **Game** drafts a base sheet from the rulings, then has isolated model arms, one model family per arm, derive context-free from the evidence and vary against that base; every sheet passes a reviewer gate that strikes what oversteps the rulings, and the blinded sheets are judged through role-played, individually profiled buyers returning booking-grade verdicts. Winners are absorbed into one sheet and crowned on a held-out panel of fresh judges.
- **Establish** ships it: numbered selling-point claims whose scarcity is measured against the Survey corpus, the definition folded by stated rules with a dedup pass and an independent cold read, every value migrated to its single home, and a displacement offer put to named prospects the operator already holds, testing whether buyers switch.

**Model allocation:** Survey collection and coding are Sonnet-tier under a frozen codebook; the codebook author and frame reviewer are Opus-tier. Adjudicate is human with AI clerking. Game arms run at the strongest tier, one model family per arm where available; the reviewer and judges are Opus-tier. Establish folding is Opus-tier, migrations Sonnet-tier.

**Procedure documents:** `pmf-sage/sage-methodology.md`, the phase AESOPs (`sage-S-survey.md`, `sage-A-adjudicate.md`, `sage-G-game.md`, `sage-E-establish.md`), and `pmf-sage/INVARIANTS.md`.

#### SAGE use cases

**A school excursion product**. The full pipeline: a 400-venue comparables frame with 196 profiled programmes, eighteen decision cards and a three-arm design game. The run is the source the methodology was extracted from.

**An inbound study-tour survey**. The Survey phase on its own, reading the supplier side in four destination countries and the seller side in six origin markets. A market can be surveyed to review grade before anyone commits to Adjudicate.

### SCOPE — Finding Where a Codebase Decides One Thing in Many Places

**Phases:** Survey, Count, Oracle, Pick, Explain

**Direction:** Inward, on the operator's own code. The question is which concepts are decided in more places than a competent architect would expect: the condition the literature calls change amplification, shotgun surgery, or scattering. A count of consumers is not a finding; the gap between the count and a blind expectation is.

**What each phase does:**

- **Survey** lists the concepts: every module, from a symbol-reference index of the code, plus the design facts the program decides once, listed by a blind architect from the README.
- **Count** measures each module three ways: files using its types (the graph), files mentioning its names anywhere including prose (grep), and total sites. The difference is vocabulary leakage, which no reference graph sees. Decided-once facts are counted by grep, pattern rule, or a removal drill through the compiler.
- **Oracle** asks several blind estimators, given only the README, crate sizes and each module's one-line doc, to guess the same figures.
- **Pick** compares on a log scale and keeps what falls outside a factor of three; file counts calibrate, site counts do not.
- **Explain** revives the estimator furthest off with the measured figures; it verifies the count first, then names the mechanism, or "by design".

**Model allocation:** Survey and Count are scripts plus a cheap-tier agent for pattern rules and drills. Oracle estimators are cheap-tier. Explain revives the same estimators; a consequential concept can be explained on a stronger tier in a fresh context.

**Procedure documents:** `scatter-scope/scope-methodology.md`, `scatter-scope/scope-oracle-brief.md`, `scatter-scope/INVARIANTS.md`, and the counting tool `scatter-scope/tools/scope-count.py`.

#### SCOPE use cases

**A JavaScript business platform** (three blind rounds on 2026-08-21). 384 module concepts and twelve decided-once facts per round; the rounds calibrated the instrument.

**RobCo Terminal** (run of 2026-08-21, then three blind rounds). Sixteen modules of a 59,000-line Rust workspace. Flagged a hub module, a leaking gateway module and a layout fact decided at thirteen sites.

### LAMP — Whether the Market Can Find One Product, and What That Is Worth

**Phases:** Locate, Attribute, Move, Prove

**Direction:** Inward and longitudinal, one product at a time, with the answers denominated in money. The four phases answer the operator's four questions in order: can the people who would want this find us, what is stopping them, what should we do about it ranked by money, and did what we did last time work. A site-wide study asks where the clicks went; LAMP asks whether one product gets found and what finding it is worth.

**What each phase does:**

- **Locate** sizes the demand from the market map, measures the operator's share of it with the console, prices that share, and ends with a gate: the minimum detectable effect computed from the family's own daily counts. The instance (one located capture, with every results-page feature that takes the click) and the population (the console series) are reported apart.
- **Attribute** holds at least three candidate causes with a status each (verified, inferred, open with the settling observation), names which blocker binds from a set running from no page exists to demand that is not search-shaped, and takes its competitor set from the market map rather than from the ladder immediately above the operator.
- **Move** gives every lever a predicted magnitude, a read date and an expected value in money, ranks them in one list, and refuses to propose a lever the series cannot resolve. The floor and fork labels say who acts; a fork still carries its number and the run's recommendation.
- **Prove** reads delivered against predicted against a control, and reports delivered, underdelivered, no effect, too early with the read date, or not readable with the seam that blocks it.

**Model allocation:** the market pass is Opus-tier; Locate and Prove are Sonnet-tier; Attribute and Move are Opus-tier where the causes are contested. Runs go one at a time while the methodology is young, each run being a test of whether the document reads correctly to a fresh agent.

**Procedure documents:** `seo-lamp/lamp-methodology.md` and `seo-lamp/INVARIANTS.md`.

#### LAMP use cases

**A venue's website products**. Eight product runs of 13 September 2026, whose audit restructured the methodology the same day.

### PLACE — Asserting the Market Position of Something Already Built

**Phases:** Poll, Landscape, Audit, Contrast, Establish

**Direction:** Inward, after the fact. The product exists and rivals are published; what is missing is an account of its position that a stranger could check. SAGE decides what to build before it exists; PLACE describes what was built, against a field that was not consulted while building.

**What each phase does:**

- **Poll** collects verbatim quotes from public discussion of this kind of product, each dated, linked, and mapped to a numbered pain. The pain taxonomy is authored once, over the merged corpus, in one file every other file cites by number; a demand reading sits beside it with the biases of the public corpus stated.
- **Landscape** records what the rivals supply against the same pain numbers in a dated matrix, as their authors describe it, with a supply note per pain. The operator's own product is not a row. A companion table reads the discussion dynamics of the same venues: what kinds of post draw replies and what kinds draw only approval.
- **Audit** is the one file written from the code: per pain, Solved, Partial, or None, with the mechanism, the source paths, and the ceiling the architecture imposes; plus a feature catalogue.
- **Contrast** rates each shipped capability common, rare, or unique against the recorded field, and sorts the gaps into architectural and feasible. A description of the built product, not a build-priority ranking.
- **Establish** derives the positioning the corpus supports and its ceiling, says plainly when there is no hook, and checks the name against the Audit, retiring one that overclaims.

**Model allocation:** Poll collection and Landscape cells are Sonnet-tier under a fixed entry form. Taxonomy authoring, supply notes, the Audit, and Establish are Opus-tier. Contrast is Sonnet-tier once Landscape and Audit exist.

**Procedure documents:** `market-place/place-methodology.md` and `market-place/INVARIANTS.md`.

#### PLACE use cases

**questlog** (snapshot May–June 2026). A session browser for an AI coding agent, positioned against about twenty session viewers and cost dashboards. The run is the methodology's source.

**RobCo Terminal** (run of 2026-08-23, the first run after extraction). A CRT-look terminal emulator positioned against twenty-one terminals and multiplexers.

### MIND — How the Market Holds One Trading Name, and Whether a Movement Is Ours

**Phases:** Measure, Index, Name, Decide

**Direction:** Inward and longitudinal, one trading name at a time, re-run on the operator's cadence with the same detectors and the same tables each time, so that one run lies beside the last. The four phases answer the operator's four questions in order: is the name held better or worse than a year earlier, on instruments and in each market we target; is a movement ours or the market's; what do the market's own words say about each movement; and what do we elect to change. A brand review drawn on one date can only describe; a MIND run reads matched windows a year apart, calls a change a movement only past the detector's own noise, and reads it against a panel of comparable businesses measured the same way, so a movement is attributed to the operator, to the operator's market, or to the market as a whole.

**What each phase does:**

- **Measure** reads the prior run first, then executes every detector the campaign's instrument list supplies, across whether the name is sought, spoken of and seen: name search volume, name impressions and clicks, share of search, public interest index, name modifiers, review velocity and rating, review themes, public mentions, social following, business profile actions, direct and name-referred traffic, listing presence. Each row carries the figure a year earlier, the figure now, the threshold and a verdict from a fixed set.
- **Index** runs the panel-reach detectors for the closest band of the campaign's register of comparable businesses, on the same windows and markets, and attributes each operator movement: the panel moved with it, only the members sharing the operator's market moved, the operator moved alone, or unattributed with the observation that would settle it. It states the operator's rank and share among the panel.
- **Name** writes one numbered finding per movement, resting on the run's own detectors and the market's own words, filed under one of five fixed heads, positioning, competitors, audiences, presence and reputation, so each run's findings lie beside the last run's. The run ends here and chooses nothing.
- **Decide** is the operator's. Each decision names the finding it answers, the detector and market that would show it worked, and a read date, and the next run's Measure reads it.

**Model allocation:** Measure, Index and review coding are Sonnet-tier under the campaign's instrument list, register and frozen theme list; Name is Opus-tier; Decide is human with AI clerking; the cold read before publication is a fresh context at the tier the run's use warrants.

**Procedure documents:** `brandreview-mind/mind-methodology.md` and `brandreview-mind/INVARIANTS.md`.

#### MIND use cases

**A venue's brand reviews**. Six single-date reviews from April 2025 to February 2026, the source the methodology was extracted from. No run has yet been made.

### MOVE — Where to Be, Given a Date Range

**Phases:** Map, Offer, Value, Elect

**Direction:** Inward and windowed. The almanac has already rated the events of a year or a season one at a time; MOVE reads that rated list over a shorter range the operator names and decides between plans rather than between events, because events interact through geography: three events in one region are one commitment to be there, and one strong event may not justify a trip that two nearby middling ones make worthwhile. Its output is an election, one presence plan chosen by the operator from lettered offers, with what was foregone and a hand-off the travel SOPs start a journey from.

**What each phase does:**

- **Map** checks that the range lies inside a swept window, gathers the rated events in it, marks what is fixed before any choice (high-certainty presence, committed events, the operator's shortlist) and the deadlines the range turns on, and groups the rest into clusters by region and time.
- **Offer** assembles two to four presence plans that span the range, each feasible in gross terms and anchored on a different cluster, the first always the plan of not moving.
- **Value** scores each offer on a vector of dimensions kept apart (event value, presence, cost of absence, travel burden, money, risk), with the operator's rubric binding, and recommends one with the trade it makes stated.
- **Elect** is the operator's. The election, the events foregone and the presence schedule with its constraints are recorded in a move file, one per range in the almanac's data root, rewritten on each re-election and never written into the almanac's own ledger.

**Model allocation:** Map and Offer are Sonnet-tier. Value is Opus-tier. Elect is human.

**Procedure documents:** `presence-move/move-methodology.md`, the phase documents (`move-M-map.md`, `move-O-offer.md`, `move-V-value.md`, `move-E-elect.md`) and `presence-move/INVARIANTS.md`.

### CART — Preparing a Contested Matter for Hearing

**Phases:** Cite, Argue, Render, Tender

**Direction:** Inbound and adversarial. Material has accumulated around a dispute over months, in several long documents nobody reads before the event. Someone has to walk into a hearing, a mediation or a conference able to answer anything the other side says, from one thing they can read while standing up. CART organises the material and builds that one thing. It ends at the artefact and its rebuilds; what becomes of the material afterwards is outside it.

**What each phase does:**

- **Cite** puts a source on every assertion, at two levels. The register of material points at sources instead of retelling them, which is what keeps it thin. The artefact points in the coordinates the forum itself uses, supplied by the matter rather than by the methodology, so a line can be spoken and the decision-maker can turn to it while it is spoken. A citation does two jobs: it holds up what our side says, and it impeaches what theirs says, because the page being pointed at is often their own earlier document contradicting their present position.
- **Argue** decides what is run, what carries it, and what is held back. Held material is not duplicate material: a document kept available and untendered is doing its job, and a reduction pass that treats anything unused as redundant cuts exactly the reserve it exists to protect.
- **Render** builds the artefact from the two documents above it. Selection is adversarial rather than archival, so material earns its place by persuading, by answering something the other side will say, or by being an inconsistency that can be put to them. A fact whose only home would be the artefact has been authored in the wrong place.
- **Tender** is what actually goes before the forum, with the trigger that releases each held item: the claim it answers and the moment it would be produced. The artefact carries the trigger; the reasoning behind each hold stays upstream.

**Model allocation:** Cite and Tender are Sonnet-tier (checking assertions against sources, maintaining a register with triggers). Argue and Render are Opus-tier, turning on judgement about what persuades and what to leave out.

**Procedure documents:** `matter-cart/cart-methodology.md`.

### How the methodologies relate

SPAR generates outbound messages. Those messages produce replies. The replies arrive in an inbox processed by TEND. TEND's thread assembly recognises the SPAR outreach message in the conversation history and can route the reply accordingly — flagging a positive response rather than filing it as unsolicited inbound.

SIFT evaluates inbound listings. When SIFT's Target phase marks a listing as `network-approach` (pursue through a relationship rather than a direct application), that contact may enter a SPAR roster for outreach.

SAGE defines what there is to sell. Its Establish phase produces the numbered claims a SPAR campaign's approach messages cite by number, and its displacement offer runs naturally as a SPAR campaign over an owned roster, with replies arriving through TEND. SAGE's decisions table is also the bounding box those messages may not escape: an approach draft promising anything outside it is caught at review, not sent.

PLACE positions what already shipped. Its Landscape answers, after the fact, the question SAGE's Survey asks before a market is entered, and its Establish produces the positioning and the user-language corpus a launch post or a SPAR campaign draws on; replies again arrive through TEND.

LAMP and MIND divide the series between them. LAMP measures whether the market can find one product and what finding it is worth; MIND measures how the trading name above the products is sought, spoken of and seen, and reads it against a panel of comparable businesses. Where a MIND run shares an instrument with a LAMP run of the same operator it cites LAMP's measurement ground, the retention walls, error windows and withheld-row fraction, rather than re-deriving it, and the claims SAGE ruled or PLACE established are what MIND's Name tests the market's words against.

The almanac and MOVE divide presence between them. The almanac's sweep discovers and rates events for a year or a season into a mostly add-only ledger in the operator's own repository; MOVE elects, over a date range the operator names, which plan of places and events to run, and writes the election beside the ledger rather than into it. The election's presence schedule is what the travel SOPs take as a journey's start: the almanac and MOVE decide where and when, travel decides how.

The methodologies share a structural principle: read before writing. SPAR profiles a contact before drafting a message. SIFT investigates a listing before scoring it. TEND threads a conversation before classifying the email. SAGE surveys a market before anyone rules on a parameter. PLACE polls the users and records the field before the code is read. MIND reads the prior run and the panel before it names anything. CART registers what is held before anything is argued from it. In each case, the comprehension phase precedes the action phase, and the scoring rubric or taxonomy does the intellectual heavy lifting so that Sonnet-tier models can apply it reliably.

## Other directories

- `travel/` — Travel planning and itinerary management (master orchestrator with sub-SOPs)
- `almanac/` — Event discovery and rating for a year or a season, the ledger MOVE elects from (method only; data lives in the user's own repository)
- `events/` — Event discovery and tracking
- `roster/` — Roster management (architectural notes only)
- `tests/` — Test cases and results for validating SOPs through iterative rounds
- `sop-authoring-rules.md` — Meta-guide for creating and updating SOPs
- `authoring/` — Start here to create or revise an AESOP: the prompt that runs the author-test-fix loop, and a worked headless example

## Usage

SOPs are executed by passing them to Claude as a prompt file:

```bash
claude -p travel/sop-travel-master.md
```

The master SOP orchestrates sub-SOPs as needed. Each SOP reads its inputs, performs its task, and produces outputs — no human in the loop.

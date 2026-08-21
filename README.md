# AESOP

**AI-Executed Standard Operating Procedures**

SOPs written for AI agents to follow autonomously. These are not documentation for humans — they are instructions an AI reads and executes.

## Methodologies

Each methodology covers one direction of information flow as a four-phase pipeline executed by AI agents, with domain-specific content (segments, taxonomies, scoring rubrics) supplied by a campaign configuration rather than by the methodology itself.

### SPAR — Outreach Discovery and Engagement

**Phases:** Sweep, Profile, Approach, Revise

**Direction:** Outbound. The operator has something to offer and needs to find people who might want it, research them, and write a message specific enough that the recipient can tell it was written for them.

**What each phase does:**

- **Sweep** discovers names from registries, directories, social graphs, and web searches. Iterates up to three times, each expanding the roster through social-graph and semantic expansion.
- **Profile** builds a dossier for each contact: what they have said publicly, who they know, their current role, and how relevant they are to the campaign. Produces a star rating: how valuable the contact is to us, independent of any one campaign. The response-likelihood estimate belongs to Approach, because it turns on the angle chosen.
- **Approach** drafts a personalised message for each contact, tested against a context-isolated challenger agent that role-plays the recipient. The challenger has never read the campaign files and reacts as a stranger would.
- **Revise** is a human phase. After each band of messages is sent and responses arrive, the human reviews what worked, what did not, and adjusts the strategy for the next band.

**Model allocation:** S and P are Sonnet-tier (high volume, rubric-following). A is Opus-tier (tone, angle selection, cross-referencing prior relationships). R is human.

**Procedure documents:** `outreach-spar/spar-methodology.md` and the phase-specific AESOPs (`spar-S-sweep.md`, `spar-P-profile.md`, `spar-A-approach.md`).

**Tooling:** `outreach-spar/spar-manager/` holds its runnable scripts at the top: a transition dispatcher (`spar-transition.tcl`), a progress reporter (`spar-progress.tcl`), a validator (`spar-validate-cli.tcl`), a Tk GUI (`spar-ui.tcl`), and the two phase harnesses. The libraries they source sit under `lib/`. These read a campaign YAML, classify contacts via the state machine (`lib/spar-state.tcl`), and dispatch work to the Claude Code CLI.

#### SPAR use cases

**Rivermill segmented partnership outreach** (`../rivermill/segments-outreach.spar/`). 19 segments (wedding planners, tour operators, community organisations, market stallholders, etc.), 415 contacts profiled, 258 approach messages drafted with A2 sparring. Campaign YAML defines per-segment goals, USP selection, and approach sequencing. This is the full SPAR pipeline with all four phases active and multi-band AR processing.

**Open Source Foundation governance outreach** (`outreach/` in `git@gitlab.com:bossdog/opensource.foundation.git`). Singapore-domiciled foundation building trust infrastructure for open source. 56-contact Singapore trip pipeline targeting founding members and chairman candidates, plus a 160-contact community-tier pipeline across the global open source security community (OpenSSF, SLSA/Sigstore, distro contributors). Two-axis rating system (strategic value × response likelihood) refined from the Rivermill deployment. Measured a consistent 0.60 corrections per profile across all segments. Demonstrates SPAR applied to institutional commitment asks rather than commercial partnership — different domain, same pipeline structure.

**Courier GitHub star seeding** (`../weiwu/2026-04-04-courier-star-seeding.spar/`). Developer contacts extracted from local email archives, classified with Haiku, scored for closeness, and approached with a one-line ask (star a GitHub repo). Simplified SPAR: A2 rounds set to zero because the ask is simple enough that sparring adds no value. The `life_brief.yaml` provides era-appropriate catch-up context instead of per-contact profiling. Demonstrates that SPAR scales down — the methodology accommodates campaigns where a full profile and three spar rounds would be disproportionate to the ask.

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

**Published job listings** (`../holotapes-career/career/published-jobs.sift/`). 180+ job listings scored on four dimensions (influence/knowledge access, compensation, stepping-stone value, labour fit) with five amplifier tags (cross-culture, cross-domain, multilingual, china-west, regulated+technical). Registry in `registry.tsv`, dossiers in `dossiers/`.

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

**Rivermill director inbox** (`../holotapes/email-processing.tend/`). Taxonomy built from 226 emails across 5 batches covering the full sender spectrum (internal staff, retained professionals, external partners, job applicants, board members). 64 categories with 64 corresponding processing rules. The taxonomy and ruleset are the domain-specific artefacts; TEND defines how an agent uses them.

### SAGE — Product Development to Fit in a Proven Market

**Phases:** Survey, Adjudicate, Game, Establish

**Direction:** Inward. The operator must decide what to build in a market that already exists; the discipline is that the market's evidence decides it, against the operator's own priors, drafts, and internal opinion.

**What each phase does:**

- **Survey** builds the evidence at research grade: comparable operators worldwide drawn from published registers and coded under a codebook frozen blind, an adversarial frame review before any collection, the local rival register with demand signals, and distributor evidence from intermediaries whose transactions cross the whole market. Findings are numbered so every later document cites a number instead of restating a claim.
- **Adjudicate** is a human phase. Every product parameter is decided on a card: prior values, ruling, provenance chip (inherited, anchored, derived, radical), four boundary tests. A ruling stands on named demand evidence plus named capability. The output table bounds what any downstream agent may design, promise, or claim, and a parameter absent from it is design freedom.
- **Game** has isolated model arms derive the product's interior context-free from the evidence, passes every sheet through a reviewer gate that strikes what oversteps the rulings, and judges the blinded sheets through role-played, individually profiled buyers returning booking-grade verdicts. Winners are absorbed into one sheet and crowned on a held-out panel of fresh judges.
- **Establish** ships it: numbered selling-point claims whose scarcity is measured against the Survey corpus, the definition folded by stated rules with a dedup pass and an independent cold read, every value migrated to its single home, and a displacement offer put to named prospects the operator already holds, testing whether buyers switch.

**Model allocation:** Survey collection and coding are Sonnet-tier under a frozen codebook; the codebook author and frame reviewer are Opus-tier. Adjudicate is human with AI clerking. Game arms, reviewer, and judges are Opus-tier. Establish folding is Opus-tier, migrations Sonnet-tier.

**Procedure documents:** `pmf-sage/sage-methodology.md`, the phase AESOPs (`sage-S-survey.md`, `sage-A-adjudicate.md`, `sage-G-game.md`, `sage-E-establish.md`), and `pmf-sage/INVARIANTS.md`.

#### SAGE use cases

**Rivermill River Day** (`../rivermill/product-development/school-excursion/2026-08-10-how-the-river-day-was-decided/`). The full pipeline: a 400-venue comparables frame with 196 profiled programmes and 27 numbered findings, a section-numbered catchment competition register, eighteen decision cards over roughly ten correction rounds, a three-arm design game whose first round was voided for format smuggling, an absorbed sheet crowned 15/15 on the main panel and 5/5 on a held-out panel, and eight numbered claims grounded in corpus prevalence. The run predates the methodology's extraction and is its source; its folder README records the run against these phase documents.

**Rivermill inbound study-tour survey** (`../rivermill/product-development/study-tour/`). A Survey-phase deployment on its own: a two-sided design reading both the supplier side (four destination countries) and the seller side (six origin markets, in origin languages), with frame review, frozen codebook, inter-coder check and corrections all exercised. Demonstrates that SAGE's phases separate: a market can be surveyed to review grade before anyone commits to Adjudicate.

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

**RobCo Terminal** (`../RobCo-Terminal`, run of 2026-08-21). Sixteen modules of a Rust workspace of roughly 59,000 lines, three Sonnet estimators. File-count estimates landed within a factor of three for ten of sixteen modules; site estimates were low by ten to thirty times across the board, which set the calibration rule. Flagged: the window module (a hub, twelve type consumers against two expected), the tmux gateway module (one type consumer against three expected, thirty mentioning files against nine, the leak signature), and the side the channel bank sits on (thirteen sites against three expected, no constant naming it). Two revivals verified their counts and named the mechanisms: the gateway concept carried on shared channel structs and in a lower crate's own vocabulary; the bank side recomputed from a scalar width at every consumer while a layout type already held the rectangles. The run predates the methodology's extraction and is its source.

### How the methodologies relate

SPAR generates outbound messages. Those messages produce replies. The replies arrive in an inbox processed by TEND. TEND's thread assembly recognises the SPAR outreach message in the conversation history and can route the reply accordingly — flagging a positive response rather than filing it as unsolicited inbound.

SIFT evaluates inbound listings. When SIFT's Target phase marks a listing as `network-approach` (pursue through a relationship rather than a direct application), that contact may enter a SPAR roster for outreach.

SAGE defines what there is to sell. Its Establish phase produces the numbered claims a SPAR campaign's approach messages cite by number, and its displacement offer runs naturally as a SPAR campaign over an owned roster, with replies arriving through TEND. SAGE's decisions table is also the bounding box those messages may not escape: an approach draft promising anything outside it is caught at review, not sent.

The methodologies share a structural principle: read before writing. SPAR profiles a contact before drafting a message. SIFT investigates a listing before scoring it. TEND threads a conversation before classifying the email. SAGE surveys a market before anyone rules on a parameter. In each case, the comprehension phase precedes the action phase, and the scoring rubric or taxonomy does the intellectual heavy lifting so that Sonnet-tier models can apply it reliably.

## Other directories

- `travel/` — Travel planning and itinerary management (master orchestrator with sub-SOPs)
- `almanac/` — Event discovery, evaluation, and presence planning (method only; data lives in the user's own repository)
- `events/` — Event discovery and tracking
- `roster/` — Roster management (architectural notes only)
- `lessons/` — What building and testing the AESOPs taught, written up as it was learned
- `tests/` — Test cases and results for validating SOPs through iterative rounds
- `sop-authoring-rules.md` — Meta-guide for creating and updating SOPs
- `authoring/` — Start here to create or revise an AESOP: the prompt that runs the author-test-fix loop, and a worked headless example

## Usage

SOPs are executed by passing them to Claude as a prompt file:

```bash
claude -p travel/sop-travel-master.md
```

The master SOP orchestrates sub-SOPs as needed. Each SOP reads its inputs, performs its task, and produces outputs — no human in the loop.

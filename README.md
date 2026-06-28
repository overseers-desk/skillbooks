# AESOP

**AI-Executed Standard Operating Procedures**

SOPs written for AI agents to follow autonomously. These are not documentation for humans — they are instructions an AI reads and executes.

## Methodologies

Three methodologies for three directions of information flow. Each is a four-phase pipeline executed by AI agents, with domain-specific content (segments, taxonomies, scoring rubrics) supplied by a campaign configuration rather than by the methodology itself.

### SPAR — Outreach Discovery and Engagement

**Phases:** Search, Profile, Approach, Revise

**Direction:** Outbound. The operator has something to offer and needs to find people who might want it, research them, and write a message specific enough that the recipient can tell it was written for them.

**What each phase does:**

- **Search** discovers names from registries, directories, social graphs, and web searches. Iterates up to three times, each expanding the roster through social-graph and semantic expansion.
- **Profile** builds a dossier for each contact: what they have said publicly, who they know, their current role, and how relevant they are to the campaign. Produces a star rating (value to us) and a response-likelihood estimate (value of us to them).
- **Approach** drafts a personalised message for each contact, tested against a context-isolated challenger agent that role-plays the recipient. The challenger has never read the campaign files and reacts as a stranger would.
- **Revise** is a human phase. After each band of messages is sent and responses arrive, the human reviews what worked, what did not, and adjusts the strategy for the next band.

**Model allocation:** S and P are Sonnet-tier (high volume, rubric-following). A is Opus-tier (tone, angle selection, cross-referencing prior relationships). R is human.

**Procedure documents:** `outreach-spar/spar-methodology.md` and the phase-specific AESOPs (`spar-S-search.md`, `spar-P-profile.md`, `spar-A-approach.md`).

**Tooling:** `outreach-spar/spar-manager/` contains Tcl dispatch tools (`spar-transition.tcl`, `spar-dispatch.tcl`, `spar-p-batch.tcl`, `spar-a-worker.tcl`), a progress reporter (`spar-progress.tcl`), and a Tk GUI (`spar-ui.tcl`). These read a campaign YAML, classify contacts via the state machine (`spar-state.tcl`), and dispatch work to the Claude Code CLI.

#### SPAR use cases

**Rivermill segmented partnership outreach** (`../rivermill/segments-outreach.spar/`). 19 segments (wedding planners, tour operators, community organisations, market stallholders, etc.), 415 contacts profiled, 258 approach messages drafted with A2 sparring. Campaign YAML defines per-segment goals, USP selection, and approach sequencing. This is the full SPAR pipeline with all four phases active and multi-band AR processing.

**Open Source Foundation governance outreach** (`outreach/` in `git@gitlab.com:bossdog/opensource.foundation.git`). Singapore-domiciled foundation building trust infrastructure for open source. 56-contact Singapore trip pipeline targeting founding members and chairman candidates, plus a 160-contact community-tier pipeline across the global open source security community (OpenSSF, SLSA/Sigstore, distro contributors). Two-axis rating system (strategic value × response likelihood) refined from the Rivermill deployment. Measured a consistent 0.60 corrections per profile across all segments. Demonstrates SPAR applied to institutional commitment asks rather than commercial partnership — different domain, same pipeline structure.

**Mailroom GitHub star seeding** (`../weiwu/2026-04-04-mailroom-star-seeding.spar/`). Developer contacts extracted from local email archives, classified with Haiku, scored for closeness, and approached with a one-line ask (star a GitHub repo). Simplified SPAR: A2 rounds set to zero because the ask is simple enough that sparring adds no value. The `life_brief.yaml` provides era-appropriate catch-up context instead of per-contact profiling. Demonstrates that SPAR scales down — the methodology accommodates campaigns where a full profile and three spar rounds would be disproportionate to the ask.

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

**Published job listings** (`../career-development/published-jobs.sift/`). 180+ job listings scored on four dimensions (influence/knowledge access, compensation, stepping-stone value, labour fit) with five amplifier tags (cross-culture, cross-domain, multilingual, china-west, regulated+technical). Dossiers archived in `jobs/`. Registry in `jobs.tsv`. This campaign predates the SIFT generalisation and retains the original file naming; new campaigns use `registry.tsv` and `dossiers/`.

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

**Rivermill director inbox** (`../weiwu/email-processing.tend/`). Taxonomy built from 226 emails across 5 batches covering the full sender spectrum (internal staff, retained professionals, external partners, job applicants, board members). 64 categories with 64 corresponding processing rules. The taxonomy and ruleset are the domain-specific artefacts; TEND defines how an agent uses them.

### How the methodologies relate

SPAR generates outbound messages. Those messages produce replies. The replies arrive in an inbox processed by TEND. TEND's thread assembly recognises the SPAR outreach message in the conversation history and can route the reply accordingly — flagging a positive response rather than filing it as unsolicited inbound.

SIFT evaluates inbound listings. When SIFT's Target phase marks a listing as `network-approach` (pursue through a relationship rather than a direct application), that contact may enter a SPAR roster for outreach.

The three methodologies share a structural principle: read before writing. SPAR profiles a contact before drafting a message. SIFT investigates a listing before scoring it. TEND threads a conversation before classifying the email. In each case, the comprehension phase precedes the action phase, and the scoring rubric or taxonomy does the intellectual heavy lifting so that Sonnet-tier models can apply it reliably.

## Other directories

- `travel/` — Travel planning and itinerary management (master orchestrator with sub-SOPs)
- `almanac/` — Event discovery, evaluation, and presence planning
- `events/` — Event discovery and tracking
- `roster/` — Roster management (architectural notes only)
- `linkedin-lookup-method/` — LinkedIn profile lookup via headless browser
- `facebook-lookup-method/` — Facebook profile lookup via headless browser
- `articles/` — Lessons learned from building and testing AESOPs
- `tests/` — Test cases and results for validating SOPs through iterative rounds
- `sop-authoring-rules.md` — Meta-guide for creating and updating SOPs
- `aesop-authoring.prompt` — Prompt for AI-assisted SOP authoring with built-in testing methodology

## Skills

The skills the methodologies call (LinkedIn, Facebook, Qantas, edit-email, and the rest) are packaged separately as the **overseer-toolbox** Claude Code plugin, in its own repository at `git@github.com:overseers-desk/overseer-toolbox.git`. The SOPs here reference skills by name ("use the LinkedIn skill if available"); install that plugin to make them available. Its README covers install, the serialised-browsing skill (the browser harness, used when available), credentials at `$HOME/.claude/skills/config.ini`, and browser setup.

## Usage

SOPs are executed by passing them to Claude as a prompt file:

```bash
claude -p travel/sop-travel-master.md
```

The master SOP orchestrates sub-SOPs as needed. Each SOP reads its inputs, performs its task, and produces outputs — no human in the loop.

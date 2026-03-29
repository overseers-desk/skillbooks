# SPAR — Outreach Discovery and Engagement Methodology

## What SPAR is

SPAR is a four-phase methodology for building a contact pipeline and engaging targets through personalised outreach. The name is an acronym:

- **S** — Search. Discover names from all available sources.
- **P** — Profile. Research each discovered contact to build a dossier of what they have said, who they know, and what they care about.
- **A** — Approach. Write a non-mechanical connection message tailored to the profile, tested against a simulated recipient personality.
- **R** — Revise. Review responses from the current band, identify deviations between assumed and actual motivations, adjust the connection strategy, then approach the next band.

The methodology applies to any outreach campaign — membership recruitment for a foundation, sales for a hospitality venue, community building for an open source project. The domain-specific content (target segments, angles, roster schema, message templates) lives in the campaign plan, not in SPAR itself.

## Two-prong structure

SPAR divides into two prongs that run sequentially, not concurrently.

**Prong 1: S&P (Search + Profile)** is iterative knowledge accumulation. It runs in up to three iterations — S&P₁, S&P₂, S&P₃ — each expanding the roster and deepening profiles. S&P is Sonnet-tier work: high volume, pattern-following, economical. S&P completes before Prong 2 begins.

**Prong 2: AR (Approach + Revise)** is feedback-controlled engagement. It runs in bands ordered by estimated response likelihood — AR₉₀ (contacts rated ≥90% likely to respond), then AR₈₀, then AR₇₀, and so on. Between bands, a human reviews the communication logs from the prior band, identifies what targets actually responded to (which may differ from what the campaign plan assumed), and revises the connection strategy before the next band begins. AR is Opus-tier work for the approach drafting, and human work for the revision.

The normal flow is S&P feeding AR: S&P₁ through S&P₃ run autonomously, then AR begins. However, AR is not a dead end. The R (Revise) phase reviews connection messages and responses, and in doing so reliably surfaces a small number of new names — a respondent mentions a colleague, a connection message reveals a relevant person in the same organisation, a revised strategy identifies a segment not covered by S&P₁–S&P₃. These names are few per band (typically single digits) but they appear with high probability. In practice, S&P₄ is more often needed than not.

The design accommodates this by treating S&P₁–S&P₃ as the autonomous pre-run: these iterations execute without human intervention, following the stopping criteria defined below. Any S&P iteration beyond S&P₃ is human-initiated, triggered by names accumulated during AR. The new names enter the roster at iteration number max(current) + 1, go through the same S and P steps as any other contact, and their profiles feed back into subsequent AR bands. The quantity is small enough that S&P₄ (or S&P₅) is a lightweight pass, not a full discovery cycle.

```
S&P₁ → S&P₂ → S&P₃ → [human review of profiles and roster]
                            ↓
                      AR₉₀ → review → strategy revision → new names? → S&P₄
                            ↓                                                ↓
                      AR₈₀ → review → strategy revision → new names? → S&P₅
                            ↓
                      AR₇₀ → ...
```

For a compact notation to track a campaign's position in this flow, see [`spar-stage-notation.md`](spar-stage-notation.md).

## Prong 1: S&P in detail

### S — Search

Each S&P iteration begins with discovery. S casts a wide net across all available sources. The source mix varies by campaign but the method is constant: exhaust the most direct source first, then broaden.

Sources (not exhaustive; the campaign plan specifies which apply):

- Web search (Google, industry directories, review sites)
- LinkedIn direct connections of the operator or their existing network
- LinkedIn 2nd-degree connection search
- Government registries and public databases
- CRM or existing contact databases (e.g. a spreadsheet of past clients)
- GitHub contributor data, package dependency graphs
- Conference speaker lists and attendee directories
- Facebook groups, Instagram location tags, community forums
- Reverse-search diagnostic (from S&P₂ onward): search known contacts by name, note co-occurring keywords in results, then search by those keywords alone to test whether they surface contacts invisible to the original search vocabulary

Each iteration applies the appropriate search methods:

**S&P₁ (Seed):** Build the initial roster from the most direct source. For a registry channel, export the registry. For a LinkedIn-network campaign, export direct and 2nd-degree connections. For a web-sourced campaign, run the seed queries defined in the campaign plan.

**S&P₂ (Verify and expand):** Verify each S&P₁ contact's current role and activity. Expand via social graph: who commented on their posts, who are co-admins of their groups, who appears in "People Also Viewed." Run the reverse-search diagnostic on the S&P₁ roster to discover vocabulary gaps. New names found during verification enter the roster with `discovered_via` tracing the referral chain.

**S&P₃ (Snowball and refine):** Repeat verify-and-expand on S&P₂ additions. Yield will decline. Run any expanded keyword queries identified by the reverse-search diagnostic. Accept whatever count is reached if yield falls below the stopping threshold.

Stopping criteria for S (any of these triggers stop):
- Fewer than 5 new contacts in the last iteration
- Three iterations complete

### P — Profile

P runs within each S&P iteration, on the contacts discovered in that iteration's S phase. P produces two outputs:

1. **A profile document** for each contact. The profile records: what the person has said publicly (with quotes and sources), who they know (connections relevant to the campaign), their current role and organisation, any evidence of alignment or misalignment with the campaign's offering, and two ratings:
   - **Star rating** (1–5): how interesting this contact is to us — does their role, geography, and activity suggest a plausible relationship?
   - **Response likelihood** (percentage estimate): how interesting are we to them — based on what P learns about their business model, stated concerns, and current priorities. This rating is only assessable at P stage, when the contact's situation is understood in enough detail to judge.

2. **New names** discovered during profiling. While checking A's LinkedIn profile, P may find that B commented on A's post and B is a relevant contact not yet in the roster. B enters the roster for the next iteration's S phase (or the current iteration, if S is still running). This is the social-graph expansion mechanism — it occurs during P, not during S, because it requires examining individual profiles rather than running search queries.

   New names may belong to a different channel or segment from the contact being profiled. While profiling a hackathon organiser, P might discover that an aged care coordinator liked their post — a contact relevant to a different campaign channel entirely. These cross-leads must not be discarded because they fall outside the current channel's scope. P records them in the roster with `discovered_via` pointing to the originating contact, and tags them with the channel they belong to. The S phase of the appropriate channel picks them up in its next iteration. In campaigns with multiple channels running concurrently, cross-lead capture is one of the primary mechanisms by which channels inform each other.

P will routinely discover that a contact is stale: the person has left the organisation, changed roles, or retired from the field. A stale contact is not simply removed. P marks the contact with a `date_found_invalid` and the reason, then attempts to find the replacement — the person who now holds the role that made the original contact relevant. The replacement enters the roster as a new contact in the current iteration, with `discovered_via` recording that they were found as a replacement for the stale contact. If no replacement can be found (the organisation has closed, the role no longer exists), the stale contact is left marked and no replacement is added. The stale contact's date allows periodic re-checking — a person who left a role in March may have taken a relevant role elsewhere by September.

The profile document is the primary artefact that Prong 2 consumes. Its quality determines whether the Approach phase can produce a non-mechanical message. A thin profile (no public statements, no known connections, bare LinkedIn) limits what Approach can do; the Approach phase should recognise this and adjust expectations accordingly.

### Human review checkpoint

After S&P₃, the human reviews:
- The roster: coverage by segment, quality of contacts, any gaps
- The profiles: are star ratings and response-likelihood estimates plausible?
- Whether the campaign plan's assumptions about what targets care about still hold, given what P found them actually saying

This checkpoint is the boundary between Prong 1 and Prong 2. No Opus tokens are spent until the human is satisfied with the S&P output.

## Prong 2: AR in detail

### A — Approach

A processes contacts in bands, ordered by response likelihood (from P's estimates). Within each band, contacts are further ordered by strategic value to the campaign.

**Band processing order:**

1. **AR₉₀** — contacts estimated ≥90% likely to respond. These are people who have publicly stated a concern that the campaign directly addresses, or who are already connected to someone in the campaign's network. They are the easiest to write a credible message to and the most likely to generate a communication log that informs later bands.

2. After AR₉₀ completes and responses are logged: **manual review**. What did respondents actually engage with? Did they care about what the campaign plan assumed (e.g. jurisdictional independence), or did they care about something else (e.g. cost of compliance)? The connection strategy is revised based on observed evidence. This revision is a human task, not an AI task.

3. **AR₈₀** — contacts estimated ≥80% likely to respond. Messages are written using the revised strategy and can reference relationships established in AR₉₀ ("I've spoken to John at X, who shares your concern about...").

4. Repeat: review, revise, next band. Each band benefits from the accumulated communication logs and the progressively refined understanding of what targets actually care about.

**The A phase for each contact:**

A is Opus-tier work. For each contact, Opus receives the profile document, the communication index (a running summary of all prior A outputs), and the full communication logs of contacts in the same segment or cluster.

A has two sub-phases:

**A1 (Draft):** Opus writes the connection message. The message must be specific to what the target has said or done, not a template with the name swapped in. The message may reference prior relationships from the communication log where doing so is genuine and relevant.

**A2 (Spar):** Opus spawns a simulated personality based on the profile — a second agent (C2) who has read the same profile and attempts to respond as the target would, honestly. A1 reads C2's response. If C2's response reveals that the message missed the mark (wrong angle, wrong tone, assumed a concern the target does not have), A1 revises. The number of A1↔C2 rounds scales with profile richness:

- **Rich profile** (6+ substantive data points — public statements, known positions, project affiliations, stated concerns, named connections, recent activity): up to 3 rounds. C2 has enough material to respond in character and surface non-obvious mismatches in tone or framing.
- **Medium profile** (3–5 data points): 1 round. C2 can give a directional reaction — whether the angle feels relevant, whether the tone is off — but lacks the depth for iterative refinement. A1 incorporates C2's single response and finalises.
- **Thin profile** (fewer than 3 data points): A2 is skipped. C2 cannot roleplay convincingly with so little to work from; the simulation would be two instances of Opus guessing at each other. A1's first draft stands.

**Output:** An `ID-person-name-org-comms.md` file. The ID uses a segment prefix and sequential number (e.g. `STR-001-jane-doe-huawei-comms.md` for the first strategic-tier contact, `CRP-015-karl-mueller-siemens-comms.md` for the fifteenth corporate-tier contact). The file contains: the profile summary, the angle chosen, the A1/A2 iteration history (all drafts and C2 responses, so the human can see how the message evolved), the final message, and the contact method.

A also appends a one-line entry to a communication index file (`comms-index.md`): target name, organisation, segment, angle used, key relationship hooks. This index is what subsequent A runs read to find cross-references, rather than reading all prior comm logs in full.

### R — Revise

R is a human phase, not an AI phase. After each band of A completes and enough time has passed for responses to arrive, the human reviews:

- **Response rate vs estimate:** Did ≥90% contacts actually respond at ≥90%? If not, the response-likelihood model from P needs recalibration.
- **Angle effectiveness:** Which angles generated engagement? Which fell flat? If the campaign assumed targets care about jurisdictional independence but respondents consistently engaged with cost-of-compliance framing instead, the angle table needs revision.
- **Unexpected themes:** Did respondents raise concerns not anticipated in the campaign plan? These may indicate a value proposition the campaign has not articulated.
- **Network effects:** Did any respondent offer introductions or mention colleagues who should be contacted? These are warm leads that bypass the pipeline entirely and should be prioritised in the next band or handled outside SPAR through direct relationship channels.

The output of R is a revised connection strategy: updated angle priorities, adjusted messaging emphasis, and any new relationship hooks to reference in subsequent bands. This revision is recorded in a strategy log (`strategy-revision-[band].md`) so that the evolution of the campaign's understanding is traceable.

## Artefacts

| Artefact | Created by | Consumed by | Location |
|---|---|---|---|
| Roster (TSV or markdown, schema defined by campaign plan) | S | P, A | Campaign directory |
| Profile documents | P | A, human review | Campaign directory |
| Communication logs (`ID-person-name-org-comms.md`) | A | R, subsequent A runs (via index) | Campaign directory |
| Communication index (`comms-index.md`) | A (append) | A (read) | Campaign directory |
| Strategy revision notes (`strategy-revision-[band].md`) | R (human) | A (next band) | Campaign directory |
| Channel summary (search vocabulary, invisible segments) | S&P₃ | Future S&P runs on same channel | Campaign directory |

## Model assignment

| Phase | Model tier | Rationale |
|---|---|---|
| S | Sonnet | High-volume search and data extraction. Pattern-following. |
| P | Sonnet | Profile construction from public sources. Structured output. |
| A1 (draft) | Opus | Connection messages must not read as mechanical. Tone, angle selection, and cross-referencing prior relationships require judgement. |
| A2 (spar) | Opus | Simulating a recipient personality and evaluating message credibility requires the same level of judgement as writing the message. |
| R | Human | Strategy revision based on observed responses is a judgement that should not be automated. The human decides what the deviations mean and how to adjust. |

## Cross-project validation of model tiering

The S&P = Sonnet / AR = Opus allocation has been independently validated outside outreach. In the job-seeking pipeline (`~/code/career-development/method/listing-pipeline.md`), the GRADE stage — scoring job listings against a structured rubric on two axes (star value and candidacy percentage) — was run by four parallel Sonnet agents across 19 listings on 2026-03-25. The scores required no Opus-level correction: influence/knowledge gestalt judgments, hard-gate identification, and percentage amplification were all consistent with the rubric's intent. This confirms the general principle: when a rubric does the intellectual heavy lifting (defines the dimensions, provides anchor examples, specifies the formula), Sonnet applies it reliably. Opus is needed when the task requires generating the rubric, resolving ambiguity not covered by the rubric, or making judgment calls that trade off unstated considerations (i.e. the AR-tier work).

## Relationship to existing documents

This methodology does not replace any existing document. It provides the conceptual framework from which specific AESOPs are derived:

- **SPAR-S** (`spar-S-search.md`) — the operational procedure for search and discovery. Generalises iterative discovery techniques first developed in project-specific SOPs and the research phase of a foundation's direct-outreach-pipeline into a campaign-agnostic procedure.
- **SPAR-P** (`spar-P-profile.md`) — the operational procedure for profile building, generalising the personalization SOP's research phase into a standalone profiling step that does not also draft messages.
- **SPAR-A** (not yet written) — the operational procedure for drafting connection messages, including the A1/A2 sparring loop, generalising the personalization SOP's drafting phase (Phases 2–3) with the addition of communication-log cross-referencing and band-ordered processing.
- **R has no procedure document** — it is a human review process. Its inputs and outputs are defined here; its execution is not automatable.

Domain-specific content — target segments, angle tables, roster schemas, conversion benchmarks, funnel math — remains in the campaign plan for each project (e.g. `opensource.foundation/outreach/direct-outreach-pipeline.md` for the foundation, `rivermill/management-outreach/` for Rivermill). SPAR defines the method; the campaign plan defines the targets.

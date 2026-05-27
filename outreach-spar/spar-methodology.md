# SPAR — Outreach Discovery and Engagement Methodology

## What SPAR is

SPAR is a four-phase methodology for building a contact pipeline and engaging targets through personalised outreach. The name is an acronym:

- **S** — Sweep. Discover names from all available sources.
- **P** — Profile. Research each discovered contact to build a dossier of what they have said, who they know, and what they care about.
- **A** — Approach. Write a non-mechanical connection message tailored to the profile, tested against a simulated recipient personality.
- **R** — Revise. Review responses from the current band, identify deviations between assumed and actual motivations, adjust the connection strategy, then approach the next band.

The methodology applies to any outreach campaign — membership recruitment for a foundation, sales for a hospitality venue, community building for an open source project. The domain-specific content (target segments, angles, roster schema, message templates) lives in the campaign plan, not in SPAR itself.

## Two-prong structure

SPAR divides into two prongs that run sequentially, not concurrently.

**Prong 1: S&P (Sweep + Profile)** is iterative knowledge accumulation. It runs in up to three iterations — S&P₁, S&P₂, S&P₃ — each expanding the roster and deepening profiles. S&P is Sonnet-tier work: high volume, pattern-following, economical. S&P completes before Prong 2 begins.

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

## Campaigns and segments

A SPAR project produces two kinds of long-running record. The first is the population of people the project may want to engage: who they are, what they have said publicly, what we know about them, and what we have written to them and received in return. The second is a particular outreach project, defined by a sender, a message frame, a season, a set of filters, and the channels in scope.

A segment is the home of the first record. It carries the roster (a list of people and their contact details), the profile documents (one per person), and the communications history with each person. The communications history lives in a directory named `approach/`. The name is kept from the time when the first artefact placed there was the initial approach draft. The directory now functions as the contact's communications log: the drafting record for the first outbound message, the message sent, replies received, and any follow-up outbound that accumulates as the segment is engaged over time.

A campaign is the home of the second record. The campaign YAML names the sender, the channels, the USP registry, the filters that apply during dispatch, and the segments the campaign operates over. The campaign is time-bound. A new outreach window with a different sender, frame, or set of asks is a new campaign.

The relation between the two is many-to-many. A campaign typically operates over several segments. A segment is, over time, drawn on by several campaigns. The filesystem reflects this by placing segments and campaign YAMLs as siblings at one repository level. A campaign YAML names its segments by bare directory name. The same segment name may appear in the `segments:` list of more than one campaign YAML at that level.

A segment is not an asset of any one campaign. Placing a segment directory inside a campaign directory, or under a wrapping parent like `rosters/`, breaks the addressing (the segment name no longer resolves from the campaign YAML's directory) and conflates a long-lived population store with a time-bound project.

A separate rule governs concurrent engagement: a segment supports at most one active campaign at a time. A second campaign on the same segment begins only after the first is closed. The closing procedure is defined elsewhere.

## Prong 1: S&P in detail

### S — Sweep

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

**S&P₁ (Seed):** Build the initial roster from the most direct source. For a registry segment, export the registry. For a LinkedIn-network campaign, export direct and 2nd-degree connections. For a web-sourced campaign, run the seed queries defined in the campaign plan.

**S&P₂ (Verify and expand):** Verify each S&P₁ contact's current role and activity. Expand via social graph: who commented on their posts, who are co-admins of their groups, who appears in "People Also Viewed." Run the reverse-search diagnostic on the S&P₁ roster to discover vocabulary gaps. New names found during verification enter the roster with `discovered_via` tracing the referral chain.

**S&P₃ (Snowball and refine):** Repeat verify-and-expand on S&P₂ additions. Yield will decline. Run any expanded keyword queries identified by the reverse-search diagnostic. Accept whatever count is reached if yield falls below the stopping threshold.

Stopping criteria for S (any of these triggers stop):
- Fewer than 5 new contacts in the last iteration
- Three iterations complete

### P — Profile

P runs within each S&P iteration, on the contacts discovered in that iteration's S phase. P produces two outputs:

1. **A profile document** for each contact. The profile records: what the person has said publicly (with quotes and sources), who they know (connections relevant to the campaign), their current role and organisation, any evidence of alignment or misalignment with the campaign's offering, and a rating:
   - **Star rating** (1–5): how useful this contact is to us in this segment, today. The segment file's `rating_rubric` (when present) governs; absent that, the agent role-plays as the campaign's management — reading the USP document, segment objective, and conversion funnel — and answers the usefulness question directly, without importing anchors from other segments. One sharpening of the question: imagine a person — synthesised from those materials — who knows both the target and the campaign; would they say these two should be working together (or re-engaged, if a prior relationship has lapsed), and that an introduction is warranted? Yes is a floor of 3.
   
   The profile also documents factors bearing on response likelihood (the contact's stated concerns, business model, current priorities), but does not assign a numeric **response likelihood** estimate. That percentage is set by the A phase, because it depends on the approach angle chosen — the same contact may have different response probabilities under different framings.

2. **New names** discovered during profiling. While checking A's LinkedIn profile, P may find that B commented on A's post and B is a relevant contact not yet in the roster. B enters the roster for the next iteration's S phase (or the current iteration, if S is still running). This is the social-graph expansion mechanism — it occurs during P, not during S, because it requires examining individual profiles rather than running search queries.

   New names may belong to a different segment from the contact being profiled. While profiling a hackathon organiser, P might discover that an aged care coordinator liked their post — a contact relevant to a different campaign segment entirely. These cross-leads must not be discarded because they fall outside the current segment's scope. P records them in the roster with `discovered_via` pointing to the originating contact, and tags them with the segment they belong to. The S phase of the appropriate segment picks them up in its next iteration. In campaigns with multiple segments running concurrently, cross-lead capture is one of the primary mechanisms by which segments inform each other.

P will routinely discover that a contact is stale: the person has left the organisation, changed roles, or retired from the field. A stale contact is not simply removed. P marks the contact with a `date_excluded` and the reason, then attempts to find the replacement — the person who now holds the role that made the original contact relevant. The replacement enters the roster as a new contact in the current iteration, with `discovered_via` recording that they were found as a replacement for the stale contact. If no replacement can be found (the organisation has closed, the role no longer exists), the stale contact is left marked and no replacement is added. The stale contact's date allows periodic re-checking — a person who left a role in March may have taken a relevant role elsewhere by September.

The profile document is the primary artefact that Prong 2 consumes. Its quality determines whether the Approach phase can produce a non-mechanical message. A low-yield profile (no public statements, no known connections, bare LinkedIn) limits what Approach can do; the Approach phase should recognise this and adjust expectations accordingly.

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

**A2 (Spar):** Opus spawns a simulated personality based on the profile — a second agent (C2) who has read the same profile and attempts to respond as the target would, honestly. A1 reads C2's response. If C2's response reveals that the message missed the mark (wrong angle, wrong tone, assumed a concern the target does not have), A1 revises. The number of A1↔C2 passes scales with profile yield:

- **Yield ≥ 6** (substantive data points — public statements, known positions, project affiliations, stated concerns, named connections, recent activity): up to 3 passes. C2 has enough material to respond in character and surface non-obvious mismatches in tone or framing.
- **Yield 3–5**: 1 pass. C2 can give a directional reaction — whether the angle feels relevant, whether the tone is off — but lacks the depth for iterative refinement. A1 incorporates C2's single response and finalises.
- **Yield < 3**: A2 is skipped. C2 cannot roleplay convincingly with so little to work from; the simulation would be two instances of Opus guessing at each other. A1's first draft stands.

**Output:** A communications file at `approach/{stem}.yaml`. The directory is the segment's communications log for each contact; the name `approach/` is kept from when the first artefact placed there was the initial approach draft. At creation the file records the drafting of the first outbound message: the profile summary, the angle chosen, the A1/A2 iteration history (all drafts and C2 responses, so the human can see how the message took shape), the message body, and the contact method. Subsequent messages and replies on the same contact extend the same log.

A also appends a one-line entry to a communication index file (`comms-index.md`): target name, organisation, segment, angle used, key relationship hooks. This index is what subsequent A runs read to find cross-references, rather than reading all prior approach files in full.

### R — Revise

R is a human phase, not an AI phase. After each band of A completes and enough time has passed for responses to arrive, the human reviews:

- **Response rate vs estimate:** Did ≥90% contacts actually respond at ≥90%? If not, the response-likelihood model from P needs recalibration.
- **Angle effectiveness:** Which angles generated engagement? Which fell flat? If the campaign assumed targets care about jurisdictional independence but respondents consistently engaged with cost-of-compliance framing instead, the angle table needs revision.
- **Unexpected themes:** Did respondents raise concerns not anticipated in the campaign plan? These may indicate a value proposition the campaign has not articulated.
- **Network effects:** Did any respondent offer introductions or mention colleagues who should be contacted? These are warm leads that bypass the pipeline entirely and should be prioritised in the next band or handled outside SPAR through direct relationship channels.

The output of R is a revised connection strategy: updated angle priorities, adjusted messaging emphasis, and any new relationship hooks to reference in subsequent bands. This revision is recorded in a strategy log (`strategy-revision-[band].md`) so that the evolution of the campaign's understanding is traceable.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Roster (`roster.tsv`) | S | P, A | Segment directory |
| Profile documents | P | A, human review | Segment directory (`profiles/`) |
| Communications log files (`{stem}.yaml`) | A; replies and follow-ups extend the file over time | A subsequent runs, R, future campaigns on the same segment | Segment directory (`approach/`, name historical) |
| Communication index (`comms-index.md`) | A (append) | A (read) | Segment directory |
| Strategy revision notes (`strategy-revision-[band].md`) | R (human) | A (next band) | Campaign directory (one per band) |
| Segment summary (search vocabulary, invisible segments) | S&P₃ | Future S&P runs on same segment | Segment directory |

## Model assignment

| Phase | Model tier | Rationale |
|---|---|---|
| S | Sonnet | High-volume search and data extraction. Pattern-following. |
| P | Sonnet | Profile construction from public sources. Structured output. |
| A1 (draft) | Opus | Connection messages must not read as mechanical. Tone, angle selection, and cross-referencing prior relationships require judgement. |
| A2 (spar) | Opus | Simulating a recipient personality and evaluating message credibility requires the same level of judgement as writing the message. |
| R | Human | Strategy revision based on observed responses is a judgement that should not be automated. The human decides what the deviations mean and how to adjust. |

## Cross-project validation of model tiering

The S&P = Sonnet / AR = Opus allocation has been independently validated outside outreach. In the SIFT listing-evaluation methodology (`../listing-sift/sift-methodology.md`), the Fit phase — scoring listings against a structured rubric on two axes (star value and likelihood-of-success percentage) — was first run on job listings by four parallel Sonnet agents across 19 listings on 2026-03-25. The scores required no Opus-level correction: influence/knowledge gestalt judgments, hard-gate identification, and percentage amplification were all consistent with the rubric's intent. This confirms the general principle: when a rubric does the intellectual heavy lifting (defines the dimensions, provides anchor examples, specifies the formula), Sonnet applies it reliably. Opus is needed when the task requires generating the rubric, resolving ambiguity not covered by the rubric, or making judgment calls that trade off unstated considerations (i.e. the AR-tier work).

## Versioning

The SPAR spec is versioned. Each `campaign.yaml` and each `segment.yaml` carries a `version` field naming the spec generation it conforms to. The current generation is `1.0`. The two files version independently: a segment may be re-stamped to a later generation without re-stamping the campaign, and vice versa.

This section is the single source of truth for what a version number means and when it changes. A version bump is warranted when a spec change invalidates data authored under the previous number: a renamed or removed field, a changed file layout, or a changed meaning for an existing field. Additive changes that older data still satisfies do not require a bump. Generation `1.0` is the spec as of the campaign/segment coordinate-axis layout (segments and campaigns as siblings, no grouping parents) and the roster schema in `spar-roster-format.md`.

The version field is read by the tooling for two purposes. The validate command (`spar-manager/spar-validate-cli.tcl`) reports a file with no `version` as unstamped (a warning, since legacy data that still validates keeps working) and a file declaring a version the tool does not support as an error. The dispatcher refuses, before launching P or A, to process a campaign or segment whose declared version it does not support; unstamped data is allowed through so a campaign begun under an earlier generation continues to run until it is stamped.

## Relationship to existing documents

This methodology does not replace any existing document. It provides the conceptual framework from which specific AESOPs are derived:

- **SPAR-S** (`spar-S-search.md`) — the operational procedure for the sweep phase. Generalises iterative discovery techniques first developed in project-specific SOPs and the research phase of a foundation's direct-outreach-pipeline into a campaign-agnostic procedure.
- **SPAR-P** (`spar-P-profile.md`) — the operational procedure for profile building, generalising the personalization SOP's research phase into a standalone profiling step that does not also draft messages.
- **SPAR-A** (`spar-A-approach.md`) — the operational procedure for drafting connection messages, including the A1/A2 sparring loop, generalising the personalization SOP's drafting phase (Phases 2–3) with the addition of communication-log cross-referencing and band-ordered processing.
- **R has no procedure document** — it is a human review process. Its inputs and outputs are defined here; its execution is not automatable.
- **Segment categorisation** (`spar-segment-categorisation.md`) — criteria for deciding when contacts belong in one segment versus two, when to merge or split segments, and how to handle sub-segments and cross-segment duplicates.

Domain-specific content — target segments, angle tables, roster schemas, conversion benchmarks, funnel math — remains in the campaign plan for each project (e.g. `opensource.foundation/outreach/direct-outreach-pipeline.md` for the foundation, `rivermill/management-outreach/` for Rivermill). SPAR defines the method; the campaign plan defines the targets.

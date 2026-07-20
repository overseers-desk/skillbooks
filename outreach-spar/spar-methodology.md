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

For a compact notation to track a campaign's position in this flow, see "Stage notation" below.

## Campaigns and segments

A SPAR project produces two kinds of long-running record. The first is the population of people the project may want to engage: who they are, what they have said publicly, what we know about them, and what we have written to them and received in return. The second is a particular outreach project, defined by a sender, a message frame, a season, a set of filters, and the channels in scope.

A segment is the home of the first record. It carries the roster (a list of people and their contact details), the profile documents (one per person), and the communications history with each person. The communications history lives in a directory named `approach/`. The name is kept from the time when the first artefact placed there was the initial approach draft. The directory now functions as the contact's communications log: the drafting record for the first outbound message, the message sent, replies received, and any follow-up outbound that accumulates as the segment is engaged over time.

A campaign is the home of the second record. The campaign YAML names the sender, the channels, the USP registry, the filters that apply during dispatch, and the segments the campaign operates over. It also carries, per segment, the **plan** for that segment: the objective, the USP framings, the message goal, the first ask, the conversion funnel, and the approach sequencing. The plan lives with the campaign, keyed by segment name in the `segments:` map, because it fails the test below: change the ask and the objective, message goal, and first ask change with it. The campaign is time-bound. A new outreach window with a different sender, frame, or set of asks is a new campaign.

The line between the two is one test, and every placement rule derives from it: would a different campaign over this same population — one with a different ask, or simply run at a different time — use this fact unchanged? If yes, the fact belongs to the segment; if a change of ask or campaign window would change it, the fact belongs to the campaign. `star_rating` and `response_likelihood` show the test on a single contact: a business does not become less valuable to us because one campaign skipped it, so its `star_rating` (general value to us) is the same for any campaign and lives in the segment, while how likely it is to respond turns on what this campaign asks, so `response_likelihood` lives with the engagement.

This gives three tiers, each with one home. **Population** (the segment, campaign-independent): identity, channels, discovery, the profile, and `star_rating` — how useful the contact is to us in this segment, a property of the contact. It lives in the segment's `roster.tsv` (which ends at `star_rating`), `profiles/`, and `segment.yaml` (`discovery_criteria`, `rating_rubric`, `scope_note`). Contact details (`email`, `linkedin_url`, `facebook_url`) are population-tier, so whoever discovers one, P during profiling or A at send time, writes it back to the roster (see `spar-A-approach.md` §4.8); this is the one population fact A may write. **Plan** (campaign × segment): the per-segment plan block in `campaign.yaml`. **Engagement** (campaign × contact): `response_likelihood`, `a_note`, `r_note`, and the messages — campaign-bound, written into the per-contact approach YAML, not the shared roster. The approach files live in the segment directory (so a future campaign sees the history at one path) but their content is the engagement of one campaign.

The relation between the two records is many-to-many. A campaign typically operates over several segments. A segment is, over time, drawn on by several campaigns. The filesystem reflects this by placing segments and campaign YAMLs as siblings at one repository level. A campaign YAML names its segments by bare directory name. The same segment name may appear in the `segments:` map of more than one campaign YAML at that level, each carrying its own plan.

A segment is not an asset of any one campaign. Placing a segment directory inside a campaign directory, or under a wrapping parent like `rosters/`, breaks the addressing (the segment name no longer resolves from the campaign YAML's directory) and conflates a long-lived population store with a time-bound project.

A separate rule governs concurrent engagement: a segment supports at most one active campaign at a time. A second campaign on the same segment begins only after the first is closed. The closing procedure is defined elsewhere.

### Classifying the ask

Before writing a campaign's per-segment plan, the author classifies the ask, because the classification decides how the first message is framed. The test: does the recipient have a problem this campaign solves, such that naming our want would weaken us, so that we are one of many competing to be selected by them?

- **Problem-led.** The recipient is the gatekeeper and we are competing for their selection (a podcast host choosing guests, an editor choosing stories). Naming the want ("put me on your show") is the weak move. The author may instead frame the message around the recipient's problem, and may choose to leave the want unsaid, letting the recipient reach the verdict. This is "Show, don't tell" (SDT): the substance does the work rather than a stated request (see `spar-A-approach.md` §4.5, "presuppose the recipient's world, don't narrate it", and the §7 presupposition test).
- **Direct.** We are the buyer, or it is a plain mutual offer (asking a supplier for a rate card, asking a law firm whether it handles a case, offering an aged-care home an outing). Here the want is normal commerce; state it plainly.

The classifier offers the problem-led option; it does not require it, and leaving the want unsaid is never mandatory. The stance, and whether the want is stated, are the campaign author's decisions, recorded in the plan (`ask_stance` and the fields below it; see `spar-campaign-yaml.md`).

What the recipient cares about, the lens through which they decide, is **the recipient's deciding interest**, and it is campaign-specific. For a media campaign it is the recipient's *audience*; for a supplier ask it is *winning a worthwhile account*; for some asks there is no audience at all. The method names only the generic slot; the campaign names what fills it. Writing a specific lens such as "audience" into the method would be brittle: it breaks the moment the recipient is a supplier or a buyer with no audience.

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
   - **Star rating** (0–5, where 0 is the exclusion marker "not a campaign target"; `spar-roster-format.md`): how valuable this contact is to us in this segment, in the general sense — a property of the contact, not of any one campaign. It is not how good their business is, nor how much they like us; it is whether we would value a relationship with them at all, so a business does not lose stars because one campaign chose not to target it. Its campaign-dependent counterpart — how likely they are to respond to a particular ask — is `response_likelihood`, set later by A. The segment file's `rating_rubric` (when present) governs; absent that, judge general value to us directly — would our organisation, independent of any single campaign's ask, find a relationship with this contact worth having — without importing the current campaign's objective or conversion funnel as the standard, nor anchors from other segments. One sharpening: imagine a person who knows both the target and us; would they say these two should be working together (or re-engaged, if a prior relationship has lapsed), and that an introduction is warranted? Yes is a floor of 3.
   
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

**A2 (Spar):** A1 spawns a simulated personality based on the profile — a second, context-isolated agent (C2), run on a Sonnet-class model for persona fidelity, who has read the same profile and attempts to respond as the target would, honestly. A1 reads C2's response. If C2's response reveals that the message missed the mark (wrong angle, wrong tone, assumed a concern the target does not have), A1 revises. A2 runs for every contact; the number of A1↔C2 passes scales with profile yield (see `spar-A-approach.md` §4.6):

- **Yield ≥ 6** (substantive data points — public statements, known positions, project affiliations, stated concerns, named connections, recent activity): up to 3 passes. C2 has enough material to respond in character and surface non-obvious mismatches in tone or framing.
- **Yield 3–5**: 1 pass. C2 can give a directional reaction — whether the angle feels relevant, whether the tone is off — but lacks the depth for iterative refinement. A1 incorporates C2's single response and finalises.
- **Yield < 3**: 1 pass. The thin profile is the reason to spar, not to skip: with little evidence the draft has the most room to hallucinate relevance, and the single pass is the check on it.

**Output:** A communications file at `approach/{stem}.yaml`. The directory is the segment's communications log for each contact; the name `approach/` is kept from when the first artefact placed there was the initial approach draft. At creation the file records the drafting of the first outbound message: the profile summary, the angle chosen, the A1/A2 iteration history (all drafts and C2 responses, so the human can see how the message took shape), the message body, and the contact method. Subsequent messages and replies on the same contact extend the same log.

A also appends a one-line entry to a communication index file (`comms-index.md`): target name, organisation, segment, angle used, key relationship hooks. This index is what subsequent A runs read to find cross-references, rather than reading all prior approach files in full.

### R — Revise

R is a human phase, not an AI phase. After each band of A completes and enough time has passed for responses to arrive, the human reviews:

- **Response rate vs estimate:** Did ≥90% contacts actually respond at ≥90%? If not, the response-likelihood model from P needs recalibration.
- **Angle effectiveness:** Which angles generated engagement? Which fell flat? If the campaign assumed targets care about jurisdictional independence but respondents consistently engaged with cost-of-compliance framing instead, the angle table needs revision.
- **Unexpected themes:** Did respondents raise concerns not anticipated in the campaign plan? These may indicate a value proposition the campaign has not articulated.
- **Network effects:** Did any respondent offer introductions or mention colleagues who should be contacted? These are warm leads that bypass the pipeline entirely and should be prioritised in the next band or handled outside SPAR through direct relationship channels.

The output of R is a revised connection strategy: updated angle priorities, adjusted messaging emphasis, and any new relationship hooks to reference in subsequent bands. This revision is recorded in a strategy log (`strategy-revision-[band].md`) so that the evolution of the campaign's understanding is traceable.

## Stage notation

A compact notation for tracking where a campaign stands in the flow above. The notation encodes project position, not project history. The full path of transitions belongs in the campaign's activity log.

### Format

The stage marker has two counters separated by a dot:

```
S&P{n}.AR{m}
```

- **S&P{n}** — number of S&P iterations completed (cumulative, only increases)
- **AR{m}** — number of AR bands completed (cumulative, only increases)

Before engagement begins, the marker is just `S&P{n}`. Once the first AR band starts, it becomes `S&P{n}.AR{m}`.

### Rules

1. The S&P counter only increases. S&P1 → S&P2 → S&P3 is the standard autonomous progression. S&P0 precedes it: market sizing and the source census, written to the segment's `sweep.yaml` (`spar-S-search.md` §7) with no roster rows produced. A segment whose `sweep.yaml` exists with no rounds recorded stands at S&P0; file existence carries the state, the same way profile and approach files carry P and A states.
2. S&P > 3 implies that AR work surfaced new names and a human triggered an additional S&P iteration. This is the normal case, not an exception.
3. The AR counter only increases. Each band gets one A pass (approach) and one R pass (revise) before the counter increments.
4. A can begin after any S&P iteration, not only after S&P3. A campaign with a small universe may begin engagement after S&P1.
5. The S&P counter can increase after the AR counter exists. `S&P3.AR1` → `S&P4.AR1` → `S&P4.AR2` is a valid progression: AR1 triggered S&P4, then AR2 began.

### Examples

| Marker | Meaning |
|---|---|
| `S&P1` | First S&P iteration done or in progress. No engagement yet. |
| `S&P3` | Three S&P iterations done. Standard pre-engagement state. |
| `S&P1.AR1` | One S&P iteration before engagement started. First AR band in progress or done. |
| `S&P3.AR1` | Three S&P iterations, first AR band done or in progress. |
| `S&P4.AR1` | S&P4 triggered by AR1 findings. First band complete. |
| `S&P4.AR2` | Four S&P iterations total, two AR bands complete. |
| `S&P5.AR3` | Five S&P iterations (two triggered by AR), three bands complete. |

### Mid-iteration states

When S has outrun P within an iteration (search done, profiling not yet complete), the split form `S{n}.P{m}` is available:

- `S2.P1` — search iteration 2 complete, profiling still on iteration 1. Valid because S runs before P.
- `S1.P2` — impossible. P cannot run ahead of S; you cannot profile contacts not yet discovered.

The split form is a transient state. Once P catches up, the marker reverts to the standard `S&P{n}` form. Use the split form in task assignment ("you are running P2; S2 is complete, here are the new contacts") rather than in project status tracking.

### A-phase sparring rounds

Within a single AR band, the A pass is itself an author/challenger exchange. Two role letters name the agents:

- **A** — the author, the drafting agent (the A1 sub-phase above).
- **C** — the challenger, the context-isolated agent that reads the same profile and reacts as the recipient would (the second agent, called C2 above).

`A/C{n}` marks the nth challenge round: `A/C1` is the challenger's first reaction to the draft, `A/C2` the second, and so on. The slash is always written, so the round marker never collapses into the bare agent name `C2`. The number of rounds is capped by profile yield (the A2 yield ladder above); below the threshold the draft stands unsparred and there is no A/C round. Like the split form, `A/C{n}` is task-assignment notation ("you are running A/C2: here is the draft and the challenger's first reaction"), not a campaign-position coordinate; `AR{m}` is what tracks position.

### What the marker does not encode

The response-likelihood threshold and star-rating floor for each AR band are operational parameters, not position coordinates. They belong in the band plan or strategy revision log. A separate band index serves this purpose:

```
AR1: ≥90% response likelihood (learning band)
AR2: ≥80% response likelihood
AR3: ≥5★ contacts regardless of response likelihood (value band)
AR4: ≥4★ contacts
```

The marker tells you where the campaign is. The band index tells you what each band targeted. These are consulted at different times: the marker when checking status, the band index when planning the next band.

## Artefacts

| Artefact | Created by | Consumed by | Lives in |
|---|---|---|---|
| Roster (`roster.tsv`, population: identity → `star_rating`) | S; P writes `p_note`/`star_rating`; A backfills discovered contact details (§4.8) | P, A (read; A writes contact details only) | Segment directory |
| Per-segment plan block (objective, USP framings, message goal, first ask, funnel, sequencing) | campaign planner | P, A | `campaign.yaml` `segments.<name>` |
| Profile documents | P | A, human review | Segment directory (`profiles/`) |
| Communications log files (`{stem}.yaml`, engagement: messages, `response_likelihood`, `a_note`, `r_note`) | A; replies and follow-ups extend the file over time | A subsequent runs, R, future campaigns on the same segment | Segment directory (`approach/`, name historical) |
| Communication index (`comms-index.md`) | A (append) | A (read) | Segment directory |
| Strategy revision notes (`strategy-revision-[band].md`) | R (human) | A (next band) | Campaign directory (one per band) |
| Segment summary (search vocabulary, invisible segments) | S&P₃ | Future S&P runs on same segment | Segment directory |

## Web fetching and browser serialisation

S and P both research from the open web, and some of what they read sits behind rate limiting or a login (LinkedIn, Facebook, busier directory sites). The hazard is access cadence: hit such a site too fast or too often and it throttles the address or, when a logged-in session is in play, flags the profile, which then needs repair before further work. Both phases reach these sites the same way, so the rule lives here once rather than in each phase.

Prefer the user's serialised-browsing skill when it is available. It paces access across every SPAR worker at once, which is what the cadence problem needs: S and P are not sequential at the dataset level — a contact is swept before it is profiled, but while some records are profiled others are still being swept — so several workers may want the same site at once, and only a serialiser spanning them all keeps the cadence safe. A per-phase or per-worker throttle cannot, because it cannot see the other phase's traffic.

When no serialised-browsing skill is available in the environment, hand-roll a headless chromium fetch; do not halt for lack of the skill. For P the dispatcher resolves the host's invocation and passes it to the worker; elsewhere invoke `chromium` from `PATH` with `--headless --dump-dom` and the host's user-data-dir. Reference such a skill by the capability it provides, never by a wrapper or script name.

### Context management for fetched pages

Raw or even processed HTML consumes far more context tokens than the facts it yields. A single About page can return thousands of tokens; a session processing 20 websites will exhaust its context on page content before it finishes. Convert fetched HTML to plain text or markdown before bringing content into the conversation:

```bash
# chromium fetch → pandoc → plain text (discards all markup)
chromium --headless --dump-dom \
  --virtual-time-budget=5000 --window-size=1920,3000 \
  "URL" 2>/dev/null \
  | pandoc -f html -t plain --wrap=none > /tmp/page-text.txt

# Then extract the needed fact from the plain text file
grep -i 'founder\|director\|owner\|manager' /tmp/page-text.txt
```

For batch website lookups (e.g. resolving contact names for 20 organisations), process one page at a time: fetch, extract the fact, discard the page content, then fetch the next. Do not fetch multiple pages in parallel via WebFetch — the results all land in context simultaneously and cannot be discarded.

If `WebFetch` (the built-in tool) is used instead of headless chromium, write a tight extraction prompt that returns only the specific fact needed (e.g. "Return only the owner or director's full name and role, nothing else"). Even with a tight prompt, WebFetch results are large enough that more than 5–6 pages in one session will strain context.

## Model assignment

| Phase | Model tier | Rationale |
|---|---|---|
| S | Sonnet | High-volume search and data extraction. Pattern-following. |
| P | Sonnet | Profile construction from public sources. Structured output. |
| A1 (draft) | Opus | Connection messages must not read as mechanical. Tone, angle selection, and cross-referencing prior relationships require judgement. |
| A2 (spar) | Sonnet | Persona fidelity: a less capable model shifts behaviour more authentically under role-play instruction (`spar-A-approach.md` §4.6). The challenger reacts; it does not draft. |
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
- **SPAR-P** (`spar-P-profile.md`) — the operational procedure for profile building, a standalone profiling step that does not also draft messages.
- **SPAR-A** (`spar-A-approach.md`) — the operational procedure for drafting connection messages, including the A1/A2 sparring loop, communication-log cross-referencing, and band-ordered processing.
- **R has no procedure document** — it is a human review process. Its inputs and outputs are defined here; its execution is not automatable.
- **Segment categorisation** (`spar-segment-categorisation.md`) — criteria for deciding when contacts belong in one segment versus two, when to merge or split segments, and how to handle sub-segments and cross-segment duplicates.

Domain-specific content — target segments, angle tables, roster schemas, conversion benchmarks, funnel math — remains in the campaign plan for each project (e.g. `opensource.foundation/outreach/direct-outreach-pipeline.md` for the foundation, `rivermill/management-outreach/` for Rivermill). SPAR defines the method; the campaign plan defines the targets.

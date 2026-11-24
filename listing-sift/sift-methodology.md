# SIFT — Listing Evaluation and Response Methodology

## What SIFT is

SIFT is a four-phase methodology for evaluating published listings and deciding which to respond to and how. The name is an acronym:

- **S** — Sweep. Discover listings from all available sources. Cast wide, do not filter.
- **I** — Investigate. Fetch, archive, and research each listing into a permanent dossier.
- **F** — Fit. Score each listing on two axes: value-to-us and likelihood-of-success.
- **T** — Target. Decide what to do with each listing (respond, skip, watch, or approach through a relationship) and, for each one worth answering, the channel and the method that prepares the answer.

A "listing" in SIFT is a published statement of need: someone has declared that they want something and invited responses. A job posting is a listing. A grant call is a listing. A conference CFP, a government tender, a programme admission, a partnership call, and an open-source bounty are all listings. The common structure is that the publisher has a need, has described it, and is waiting for candidates to present themselves.

The methodology applies to any domain where the universe of published listings exceeds the operator's capacity to pursue all of them, and where each listing has both variable desirability and variable probability of success.

This document holds what is true of every listing. What is true of every listing of one kind (the columns a job posting or a grant call needs, the dimensions such listings are weighed on, how the response is prepared) is in that kind's domain document under `domains/`. What one operator chose (which dimensions count and their thresholds, the sources, the tags) is in the campaign configuration, in the campaign directory in the operator's own files. A kind of listing with no domain document defines its columns and dimensions in the campaign configuration too.

## The problem SIFT solves

An operator facing 200 open listings cannot investigate all of them, and cannot score what has not been investigated. Without structure, two failure modes emerge.

The first is premature filtering. The operator skims titles, discards anything that does not immediately appeal, and pursues a handful of familiar-looking listings. This is comfortable but leaves high-value opportunities undiscovered — the listing whose title was unremarkable but whose dossier would have revealed an unusual fit.

The second is orphaned judgment. The operator scores a listing based on the posting text alone, then the posting goes dead. The score cannot be audited because the evidence is gone. Three months later, a similar listing appears at the same organisation, and the operator cannot remember why the first one scored well or poorly.

SIFT addresses both by making investigation precede scoring and by making every score traceable to a dossier. Sweep casts wide without filtering. Investigate creates a permanent evidence base. Fit scores against the evidence, not against memory. Target acts on scores, not on impressions.

The two-axis scoring framework addresses a subtler problem: the conflation of desire with feasibility. A five-star listing where the operator's likelihood of success is 10% is a different proposition from a three-star listing where the likelihood is 85%. A single-axis ranking conflates these; the two-axis matrix forces the operator to confront the difference between wanting something and being able to get it.

## The four phases

| Phase | Purpose |
|---|---|
| **Sweep** | Discover listings. Cast wide, do not filter. |
| **Investigate** | Fetch, archive, and research each listing into a dossier. |
| **Fit** | Score each listing against the operator profile on two axes. |
| **Target** | Decide what to do with each listing, and hand over each one worth a response. |

The Investigate phase produces a permanent evidence base so that Fit ratings are auditable and reproducible even after listings go dead.

## Two-axis scoring framework

### Value-to-us (stars, 1.0–5.0)

The star rating is a composite score computed from the campaign's dimensions. A campaign uses 3–6 dimensions, each with a numerical scale and anchor descriptions. The formula is:

```
stars = clamp(sum-of-dimensions, 1.0, 5.0)
```

The dimensions are defined outside this document. A domain document defines the ones campaigns of its kind choose from. The campaign configuration says which of them the campaign uses, sets their thresholds, and defines any of its own. SIFT prescribes the framework: a composite score from defined dimensions, clamped to 1.0–5.0.

Example dimension families (not prescriptive — campaigns choose what applies):

- **Strategic value**: does the listing provide access, knowledge, network position, or influence that is scarce and transferable?
- **Economic value**: what is the financial return (compensation, funding amount, prize, contract value)?
- **Stepping-stone value**: does responding successfully open a category of future opportunities currently inaccessible?
- **Effort compatibility**: is the work compatible with the operator's available capacity and concurrent commitments?

A grant-seeking campaign might use research alignment, funding amount, institutional prestige and reporting burden. The methodology does not constrain which dimensions a campaign uses, only that they exist, are documented with anchors, and sum to a clamped star rating.

### Likelihood-of-success (percentage, 0–100)

The percentage estimates how likely the operator is to be selected if they respond. It is computed in three steps:

1. **Base estimate** (`pct_base`, 0–100). Compare the listing's stated requirements against the operator profile. Every unmet hard requirement reduces the base significantly.

2. **Amplifiers**. The campaign defines tags for circumstances where the operator's profile is a competitive advantage rather than a legibility problem. Each applicable amplifier multiplies `pct_base` by a campaign-defined factor (default 1.15, compounding). The result is capped at 95.

3. **Hard gates**. Requirements that block candidacy entirely (credentials, certifications, years of specific experience). Listed explicitly so the operator can see them before investing effort.

The amplifier tags are the campaign's own. A grant campaign might define `interdisciplinary`, `industry-partnership`, `emerging-market`. The methodology defines the amplifier mechanics; the campaign defines the tags.

### The two axes together

Stars answer: "Is this worth pursuing if we could get it?" Percentage answers: "Can we realistically get it?" The two together form a prioritisation matrix:

| | High stars | Low stars |
|---|---|---|
| **High pct** | Pursue | Deprioritise (easy but low-value) |
| **Low pct** | Stretch (high-value but long-shot) | Skip |

Target uses this matrix to assign dispositions. The thresholds for "high" and "low" are campaign-specific.

## Campaign directory

SIFT works from a campaign directory in the operator's own files: the configuration, the registry and the dossiers. `sift-campaign-directory.md` gives its layout and what the configuration holds. Every phase starts by reading the configuration.

Where there is no campaign directory yet, the first act is to set one up, and the operator is asked for the choices the configuration holds. A choice that could not be put to the operator, because the operator is away or because it only came up in a later phase, is made by the phase that needs it and written into the configuration, marked as not yet confirmed by the operator.

## Registry concept

The registry is a TSV file that accumulates data left-to-right as listings move through the pipeline. One row per listing. Columns are grouped by phase: Sweep columns are filled first, then Fit columns, then Target columns. A row with empty Fit columns has been discovered but not yet scored. A row with empty Target columns has been scored but not yet dispositioned.

The registry has core columns (present in every campaign), then the columns of the campaign's kind of listing, then the campaign's own. The core schema is defined in `sift-registry-format.md`, a kind's columns in its domain document, and the campaign's own in the campaign configuration.

## Operator profile

Each campaign has an operator profile: a description of the entity responding to listings. For a job-seeking campaign, this is the record of a person's career and what they are looking for. For a grant campaign, it is an organisation capability statement. For a CFP campaign, it is a researcher or speaker profile.

The operator profile is what Fit scores against. SIFT does not prescribe its format, only that it exists and that Fit reads it. The campaign configuration gives its path. SIFT reads from it what the operator has done and what the operator is looking for, and writes nothing to it. The profile may be a file the operator keeps for other uses too and may hold more; SIFT leaves the rest alone.

## Dossier concept

Each listing gets a dossier file: a markdown document that captures the full listing description, background on the publishing organisation, and (once Fit runs) the scoring rationale. The dossier is the permanent evidence base. When a listing goes dead — the URL returns 404, the posting is taken down — the dossier preserves everything that was known at the time of investigation.

Dossiers are stored in the campaign directory at `dossiers/{id}.md`, where `{id}` matches the registry's `id` column.

### Dossier format

```markdown
---
id: {id}
source_name: {who published the listing}
source_account: {the publisher's page or profile on the hosting platform, if any}
title: {listing title}
url: {primary URL}
fetched: {ISO date}
fetch_method: webfetch | chromium-headless | failed
scored_by: {model that scored, if applicable}
---

## Listing description

(Full posting converted from HTML to markdown.
 If fetch failed entirely, state "Fetch failed: [reason]"
 and reproduce whatever is known from sweep notes.)

## Source background

### Public
(What any reader could learn of the publisher: what it does,
 its size and standing, where it is based, how it is funded.
 Brief for well-known names; essential research for unknowns.)

### Researcher notes
(What the research found beyond that and bearing on this
 listing: recent news, signs of growth or trouble, who is
 behind it. Cite sources.)

## Fit

> Scored by {model} ({date}). Subject to audit.

| Dimension | Score | Rationale |
|---|---|---|
| {the campaign's dimensions} | ... | ... |
| **stars** | **{value}** | (formula result) |
| pct_base | {value} | (requirement-by-requirement) |
| pct_amplifier | {tags} | (which apply and why) |
| **pct** | **{value}** | (amplified result) |
| hard_gates | {gates or none} | ... |

### Notes
(Free-text rationale for the key judgments.)
```

## SOP 1: Sweep

### Purpose

Discover all potentially relevant listings. Cast wide. Do not score or filter — that is Fit's job.

### Inputs

- Operator profile (to understand what "relevant" means)
- Campaign-defined search sources and queries

### Process

1. Read the operator profile to establish the scope of relevance
2. Search across campaign-defined sources. The source mix varies by domain: job boards and company career pages for employment; grant databases and funder websites for funding; conference listings and academic networks for CFPs; procurement portals for tenders
3. For each listing found:
   - Verify it is alive (check the URL loads; if blocked by bot detection, use headless browser to verify)
   - Extract core fields: source name, title, location, URL
   - Extract the fields of the campaign's kind of listing, and the campaign's own
   - Assign an `id` following the campaign's ID format
   - Write one row to the registry with all Sweep columns filled. Leave Fit and Target columns empty
4. Deduplicate by URL. If the same listing appears on multiple sources, keep the primary source (publisher's own site preferred over aggregator mirrors)
5. Output: updated registry with new rows appended

### What Sweep does NOT do

- Does not score, rank, or filter. Every plausibly relevant listing gets a row.
- Does not assess fit. A listing with hard credential gates still gets added — Fit will flag the gates.
- Does not prepare responses.

## SOP 2: Investigate

### Purpose

Fetch, archive, and research each listing so that Fit has a permanent evidence base. Every listing in the registry gets a dossier file. The dossier captures the full listing description and source background at the time of discovery. Without it, ratings are orphaned judgments that cannot be audited or reproduced.

### Model allocation

Investigate is Sonnet-tier work: structured fetch, conversion, and factual research. Parallel Sonnet agents each process a batch of listings.

### Process

For each row in the registry that lacks a dossier file:

1. **Fetch the listing.** Try WebFetch first. If it returns 403, Cloudflare challenge, or empty content, fall back to headless browser with flock serialisation to avoid concurrent user-data-dir collisions. Detect the available browser binary at runtime; do not hardcode a specific browser path.
2. **Convert HTML to markdown.** Strip navigation, footers, cookie banners, and other boilerplate if identifiable.
3. **Research the source.** On a platform hosting many publishers' listings, the publisher is the account the listing is posted under; the name it displays is text that account's owner chose, and may be another organisation's. Record the account in `source_account`, and research the organisation that holds it. Where the listing's own description of its publisher and the research describe different organisations, the research is about someone else: say so in "Source background" and attach none of it. For publishers that are not household names, do a brief web search to establish: what the organisation does, its approximate size and standing, how it is funded, and any recent news relevant to the listing. Write findings into the "Source background" sections.
4. **Write the dossier file** to `dossiers/{id}.md` using the format above. Leave the Fit section empty — Fit fills it in SOP 3.
5. **Update `alive` in the registry** if the fetch reveals the listing is dead (404, "this position has been filled", "this call is closed", etc.).

### What Investigate does NOT do

- Does not score or rate. The Fit section in the dossier is written by SOP 3, not by Investigate.
- Does not modify Sweep columns other than `alive`.

### Output

A dossier file for every listing. Updated `alive` column in the registry where applicable.

## SOP 3: Fit

### Purpose

Score every row in the registry that has empty Fit columns, using the dossier as primary evidence. Produce the two-axis rating (stars + percentage) so that Target can prioritise.

### Model allocation

Fit is Sonnet-tier work. When a scoring rubric does the intellectual heavy lifting — defines the dimensions, provides anchor examples, specifies the formula — Sonnet applies it reliably. Rubric-following is Sonnet-tier; rubric-generation and ambiguity resolution are Opus-tier.

### Inputs

- Registry (with Sweep columns filled)
- Dossier files (from Investigate)
- Operator profile
- Scoring rubric: the dimensions, scales and anchors of the domain document and the campaign configuration

### Process

For each row where `stars` is empty:

1. Read the dossier. The listing description and source background are the primary evidence for scoring. If the dossier fetch failed, note this in `notes_fit` and score from whatever information is available.
2. Score each of the campaign's dimensions using the rubric's anchors. Where a listing leaves a dimension's value unstated (pay, size, hours), estimate it from comparable listings and what is known of the publisher, and mark it as an estimate with its basis. Whether a publisher states a value is its own habit, not a property of what it offers: scoring the unstated as zero, or setting it aside, ranks the few who publish above the many who do not.
3. Compute `stars = clamp(sum-of-dimensions, 1.0, 5.0)`.
4. Assess `pct_base` by comparing each stated requirement against the operator profile. List any `hard_gates`.
5. Identify applicable amplifier tags from the campaign's amplifier list.
6. Compute `pct = round(pct_base × factor^(number of amplifiers))`, capped at 95.
7. Write `notes_fit` explaining the key judgments.
8. Write the Fit section into the dossier file, including the `scored_by` attribution.
9. Update the row in the registry.

### Output

Updated registry with Fit columns filled. Updated dossier files with the Fit section filled and model attribution recorded.

## SOP 4: Target

### Purpose

For each scored listing, decide whether to respond and how the response is to be prepared. This is the end of the funnel: only listings worth pursuing go on to a response.

### Inputs

- Registry (with Sweep and Fit columns filled)
- Operator profile
- The operator's judgment on which listings to pursue

### Process

For each row where `decision` is empty:

1. Present the scored shortlist to the operator, sorted by `stars` descending, then `pct` descending.
2. For each listing the operator marks as `respond` or `network-approach`:
   - Determine the approach channel: direct application, warm introduction, intermediary, or network approach.
   - Note any known contacts or referral paths.
   - The channel and the contacts go in the columns the kind or the campaign defines for them, and otherwise in `notes_target`.
   - For `respond`, the response is prepared by the method the campaign configuration names, where it names one. The listing's id and its dossier are what SIFT offers that method, and Target's work on the listing stops there until the response is submitted. Where no method is named, note in `notes_target` which version of the operator's response materials to use or create (a proposal template for a grant call, an abstract variant for a CFP), and what to emphasise from the operator profile for this listing.
3. For listings marked `skip`: record the reason in `notes_target` (so future Sweep runs do not re-add them).
4. For listings marked `watch`: no response preparation, but keep in the registry for periodic re-check.
5. Update the row in the registry.
6. When a response is submitted, enter `date_responded` and update `status`, whichever method prepared it.

### Dispositions

| Disposition | Meaning |
|---|---|
| `respond` | Prepare and submit a response |
| `skip` | Do not pursue; record reason |
| `watch` | Do not pursue now; re-check periodically |
| `network-approach` | Do not apply directly; approach via relationship (may feed into SPAR) |

### Output

Updated registry with Target columns filled. Listings marked `respond` are ready for response preparation and submission.

## Artefacts

| Artefact | Created by | Consumed by | Location |
|---|---|---|---|
| Registry (TSV) | Sweep (rows); Fit (scores); Target (dispositions) | All phases | Campaign directory |
| Dossier files | Investigate (description + background); Fit (scoring section) | Fit, Target, human review | `dossiers/{id}.md` |
| Operator profile | Pre-campaign (by the operator) | Fit (scoring against requirements) | Where the campaign configuration says |
| Campaign configuration | Set up with the operator before the campaign; later gaps filled by the phase that meets them, marked unconfirmed | Sweep (sources), Fit (dimensions used, thresholds), Target (response method) | Campaign directory |
| Domain document | Kept with this methodology; not made per campaign | Sweep (columns, kinds of source), Fit (dimensions), Target (hand-over) | `domains/` |

## Model assignment

| Phase | Model tier | Rationale |
|---|---|---|
| Sweep | Sonnet | High-volume search and data extraction. Pattern-following. |
| Investigate | Sonnet | Structured fetch, HTML-to-markdown conversion, factual research. No judgment beyond "is this listing alive?" |
| Fit | Sonnet | Rubric application. The rubric does the intellectual heavy lifting; Sonnet applies it. |
| Target | Human + Sonnet | Disposition is human judgment (which listings to pursue). Recording the channel, the contacts and the hand-over is Sonnet-tier. The response takes the tier of the method that prepares it. |

## Relationship to other methodologies

SIFT, SPAR, and TEND operate on different flows of the same professional activity.

**SPAR** discovers people and engages them. It pushes outward: the operator has something to offer and reaches contacts who have not asked for it. SPAR's output is connection messages and relationship-building.

**TEND** processes inbound correspondence. It receives what arrives in the inbox and routes it: classify, assess stage, notify, dispatch. TEND's output is processed email and draft replies.

**SIFT** evaluates published listings. It responds to declared needs: someone has published that they want something, and the operator decides whether to answer. SIFT's output is scored listings and a decision on each.

The methodologies intersect at defined handoff points:

- **SIFT → SPAR**: A listing scored in SIFT may receive a `network-approach` disposition rather than a direct response. The listing becomes an approach target in SPAR — the operator builds a relationship with someone connected to the opportunity rather than submitting a cold application.
- **TEND → SIFT**: Inbound correspondence processed by TEND may surface listing-related messages — a recruiter email, a CFP invitation, a tender notification. TEND's evaluation identifies these and routes them to Sweep.
- **SPAR → SIFT**: A contact engaged through SPAR may forward a listing or mention an opportunity. This enters SIFT's Sweep from a warm source.

SIFT, SPAR and TEND share the model-tiering principle: rubric-following and structured classification are Sonnet-tier; judgment requiring unstated trade-offs, relationship nuance, or strategic framing is Opus-tier; strategy revision and disposition decisions are human-tier.

## Application areas

SIFT applies to any domain where an external party publishes a need and invites responses. The following are the domains where the structure holds cleanly — where the listing is a genuine published want, the operator evaluates fit against a profile, and the response requires preparation.

**Job listings.** The publisher is an employer. The listing is a job posting. The operator profile is the record of a person's career and what they are looking for. The response is a candidacy. The columns, dimensions and hand-over for this kind are in `domains/jobs.md`.

**Grant and funding calls.** The publisher is a funding body (government agency, foundation, research council). The listing is a call for proposals or expressions of interest. The operator profile is an organisation capability statement or researcher CV. The response is a grant proposal. The star dimensions might measure research alignment, funding amount, institutional prestige, and reporting burden.

**Conference CFPs.** The publisher is a conference organising committee. The listing is a call for papers, talks, or workshops. The operator profile is a speaker or researcher profile. The response is an abstract or paper submission. The star dimensions might measure audience relevance, venue prestige, travel burden, and topic alignment.

**Tenders and RFPs.** The publisher is a procurement authority (government, corporation, NGO). The listing is a request for proposals or request for quotations. The operator profile is a company capability statement. The response is a tender submission. The star dimensions might measure contract value, strategic alignment, compliance burden, and competitive position.

**Programme admissions.** The publisher is an educational institution or professional body. The listing is an admission call (degree programme, fellowship, accelerator). The operator profile is an applicant CV or portfolio. The response is an application. The star dimensions might measure programme prestige, career trajectory value, financial terms, and location compatibility.

**Partnership calls.** The publisher is an organisation seeking collaborators (research consortia, industry alliances, joint ventures). The listing is a call for partners. The operator profile is an organisation capability statement. The response is a partnership proposal. The star dimensions might measure strategic alignment, resource commitment, network value, and governance compatibility.

**Bounties and open-source project calls.** The publisher is a project maintainer or sponsoring organisation. The listing is a bounty, a "help wanted" issue, or a call for contributors. The operator profile is a developer portfolio or contribution history. The response is a proposal or direct contribution. The star dimensions might measure technical alignment, compensation, project visibility, and learning value.

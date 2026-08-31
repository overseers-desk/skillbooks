# SPAR-S: Sweep and Discovery

**Applies to:** AI agents (Sonnet tier) performing the S phase of the SPAR outreach methodology

**Prerequisite reading:** The campaign plan for the segment being researched (defines segments, estimated universe sizes, catchment area, seed sources, and search queries) and the SPAR methodology (`spar-methodology.md`, S section)

## 1. When to use this procedure

Use this procedure whenever a campaign needs a list of named people to contact. It applies to any outreach or sales campaign — membership recruitment, hospitality sales, community building, investor outreach — provided the campaign plan defines the target segments and estimated universe.

Campaigns may define two types of targets, or only one:

**Cue-required targets** are people who might send the campaign business, make introductions, or amplify its message if they knew about it — referral partners, community organisers, industry connectors, conference speakers. They need a cue (evidence they care about something the campaign offers) before contact; without one, the message is cold spam. The cue is collected during the P phase, not during S. S discovers the names; P determines whether a cue exists.

**Qualification-only targets** are organisations that are potential customers or members — they qualify by role and geography (or role and sector) alone and enter the outreach sequence without requiring a cue or detailed profile. P is minimal for these targets: the segment declares `target_type: qualification-only` in its definition (`segments/{segment}.yaml`) (see `segment-schema.yaml`), and `spar-P-profile.md` §5.5 defines the profile shape that declaration selects. Profile depth follows the population, not the campaign's ask, which is why the declaration lives with the segment.

The discovery steps are the same for both types. The differences — whether P is required, which roster columns apply, what the handoff looks like — are defined by the campaign plan, not by this AESOP.

## 2. Inputs

- **Campaign plan:** Specifies segments, estimated universe sizes, catchment area, seed sources, and search queries. The plan may also define campaign-specific roster columns beyond the core set defined in §4.
- **Existing roster (if any):** Check whether a roster file already exists for the segment. If one exists, continue from where it left off — do not create a new file.
- **SPAR methodology:** `spar-methodology.md` — for context on how S feeds P and how S&P iterations work.

## 3. Outputs

- **Roster TSV file:** One file per segment, in the location specified by the campaign plan. Contains every discovered contact with metadata tracking how and when they were found.
- **Sweep file:** `segments/{segment}.sweep.yaml`, the dotted stem sibling of the roster (§7). Carries the market denominator, the source census with per-source status, escapes, and one record per round. It replaces the earlier `summary-[segment-name].md`; a segment still carrying a summary file migrates its content into `sweep.yaml` at the next sweep and deletes the summary.
- **New names for P:** Contacts discovered during S enter P within the same S&P iteration. Names that belong to a different segment are tagged with the destination segment and picked up by that segment's next S phase.

## 4. Roster file format

The roster schema — file naming, TSV conventions, the core columns, programmatic access — is defined in `spar-roster-format.md` and not restated here. S populates the identity, channel, and provenance columns; the phase-handover columns (`p_note`, `star_rating`) are P's. The campaign plan may add columns beyond the core set (segment tags, postcode, type, source_url are common) and defines what they mean.

S-specific rules:

- Every row should have a **contact_name** where one can be identified. If a source lists only an organisation and a quick check of the organisation's website and its platform presences does not surface a named individual, retain the organisation as a row with a blank `contact_name`: write a provisional `stem` using the organisation slug, and leave `date_excluded` empty. Exclusion is a P-phase judgement: SPAR-P §4.1 runs the exhaustive name search, so sweep leaves `date_excluded` empty even when it could not surface a named individual. The blank-name row ensures future sweep iterations recognise the organisation as already discovered and do not re-add it.
- Each S&P iteration updates the same file via the `sweep_iteration` column. Do not create separate files per iteration.
- `discovered_via` is authored at sweep time: for seeds, the source name (e.g. "government school directory", "Google Maps", "industry association member list"); for social-graph contacts, the `contact_name` of the person whose profile surfaced the entry, creating a referral chain traceable to the original seed.
- Where a source carries its own unique key (a register id, an ABN, a licence number), the row records it in the column the campaign plan assigns (`s_note` failing that), and duplicate detection runs on that key. A name identifies nothing on its own: two members can normalise to one name, and one member can trade under several.

## 5. Segment types

Segments fall into three types that affect how S is seeded and how quickly the roster reaches its target:

- **Registry segments** (e.g. schools, childcare centres, licensed trades): An official register bounds the population, and its census entry records which of three roles it can play. A register **enumerates** when it offers a bulk export with names and locality, readable as a list: that register seeds the roster, typically exhausted in 1–2 iterations, and its rows enter keyed on the register's own unique id. A register **bounds** when it counts the population without listing it reachably: it supplies the denominator and no rows. A register **verifies** when it answers one key at a time: it serves P, not S. Licensing decides none of this: a licensed trade can be as hard to enumerate as an unlicensed one. A register that counts a market may still barely populate it, carrying legal entities while the market advertises under trading names. The route from such a register to a contact is its key field, not the name.

- **Directory segments** (e.g. wedding planners, tour operators, professional associations, industry member directories): An industry directory provides a partial list. S typically exhausts known directories in 2–3 iterations.

- **Informal segments** (e.g. community groups, mothers' groups, open source maintainers, meetup organisers): No central listing exists. S may not reach target even after 3 iterations; the roster continues to grow during AR as conversations surface referrals. Accept whatever count is reached.

The campaign plan specifies which type each segment is. If the plan does not classify segments explicitly, determine the type from the seed sources: if the plan names a government registry, it is a registry segment; if it names an industry directory, it is a directory segment; if it names only keyword searches, it is an informal segment.

Classification is an evidence-bearing claim, recorded in the sweep file's source census (§7). Classifying a segment as informal requires having looked for a registry and a directory and recording that the search came up empty; the licensing question is a cheap test (a licensed or government-subsidised activity almost always has a register, though the register found may only bound or verify). A scope filter applied to any source names the class it expects to discard, in the segment's `exclusions`; a filter that cannot name its discard is drawn from convenience and drops members silently.

## 6. Discovery iterations

Discovery progresses through iterations that expand the roster in two ways: **social-graph expansion** (following referral chains from known contacts to their peers) and **semantic expansion** (broadening search queries based on how discovered contacts describe themselves and their industry).

Where the spar-manager engine drives the segment, an iteration runs as the T0 transition: one worker per open source in the segment's sweep file, rows landing through the harness's mediated batch applier, the round record and source statuses written back by the harness. The seed pair T0 consumes (the segment definition and the sweep file) validates with `spar-validate-cli.tcl --seed`; authoring guidance is the seeding section of `segment-schema.yaml`. The iteration discipline below is the same either way; T0 mechanises the dispatch, the merge, and the record, not the judgement.

### S&P₀: Size the market (gate)

Before any contact search, establish the denominator: how many members does this segment's addressable market hold, top-down (population and density reasoning) and bottom-up (which sources enumerate or bound the population, with an expected yield each). Write the estimate with its derivation, and the source census it rests on, into the segment's `sweep.yaml` (§7). No searching starts while the denominator is absent.

Report every later progress claim as a fraction against this denominator ("412 of ~520"); a bare count measures the roster against itself, and the question this gate moves to the front is "how many exist in the world?". Instruments revise the denominator; reasoning alone does not. A census source's own count supersedes the seeded estimate, and a contradiction between the working figure and any instrument's count is reconciled before the sweep closes. A downward revision cites the instrument that produced it and keeps the figure it replaces in the derivation. Without that citation, the smaller number is the roster measuring itself.

S&P₀ also plants the segment's first escapes (§7): members the operation already knows from its own ground truth, such as paid suppliers in the ledger, correspondents in the mailbox, members met or photographed. They enter `escapes` before any search runs, each with its provenance, and round 1 either finds each one or files the verdict its miss earns. A census tested only against itself has not been tested. Where the owned records hold no member of this segment, that checked-empty search is itself the seed entry, the records searched named as its provenance.

S&P₀ produces no roster rows and can run inside the same session as S&P₁.

### S&P₁: Seed

Build the initial roster from the most direct source available. For registry segments, export the registry and resolve named contacts. For directory segments, pull from the directory and search the platforms the campaign plan names for individuals. For informal segments, use the keyword searches defined in the campaign plan, recording the query in `discovered_via`.

Queries run as word-sets, not words. For each category the set holds the plain noun, the trade's synonyms, the self-descriptors its members use, and phrases lifted from owned corpora; the round records each word's in-catchment yield, because which words win differs by trade and by platform. A miss is a verdict against the set: a population invisible under one word is routinely plain under its neighbour. Platforms hold populations no register lists, and the campaign plan names the ones its market and geography actually use. Search each platform's groups, pages, and business listings by the word-set; from each result take the administrators, organisers or owners the listing names, with any contact details, and roster them with `discovered_via` recording the platform and the query.

When a CRM or existing contact database is available as a seed source, use it, and after web research run a **CRM gap analysis**: which CRM contacts can no web query find, and why (different self-description vocabulary, weak web presence, niche specialisation, outside search radius). The categorisation says whether the invisible segment is reachable through expanded vocabulary or the CRM is the only path to them.

### S&P₂: Verify and expand

For each S&P₁ contact, verify their current role and activity via their profile or page on the platforms the campaign plan names:

- **Role confirmation:** Does their current title match the roster entry? If they have moved on, find their replacement at the same organisation.
- **Activity confirmation:** Have they posted or commented on topics relevant to the campaign? (Note: detailed activity research, cue collection, and profiling are P-phase work. S confirms identity and detects role changes; P builds the full profile.)

Found and reachable are separate counts, and the round reports both. A row without a written channel is inert downstream, so verification includes the cheap conversion steps before the round closes: the listing's website redirect resolved, the site's contact page read, the platform page's own details read.

Then expand via social graph, following each platform's own graph: who commented on or shared a post, who co-administers a page or group, who is tagged as a collaborator, and who is tagged at the same venues or events. Commenters and co-admins are likely peers at other organisations.

Run the **reverse-search diagnostic** on the S&P₁ roster: search known contacts by name, note what co-occurring keywords appear in the results, then search by those keywords alone (hiding the names) to test whether they surface contacts invisible to the original search vocabulary. This catches vocabulary gaps — segments that use different terms to describe themselves.

New names found during verification and expansion enter the roster with `discovered_via` tracing the referral chain to the originating contact.

### S&P₃: Snowball and refine queries

Repeat the verify-and-expand step on contacts added in S&P₂. Each round yields fewer contacts as the social graph is exhausted.

At the same time, review the descriptors discovered contacts use for themselves. If the initial queries were for one set of terms but discovered contacts describe themselves differently, add those terms as queries for the current iteration. This **semantic expansion** reaches segments invisible to the original search vocabulary — people who do not use the seed keywords but who operate in the same space or serve overlapping audiences. Record expanded queries in `discovered_via`.

Run any expanded keyword queries identified by the reverse-search diagnostic from S&P₂.

### Verdicts and their controls

A found contact proves itself. A negative (a checked-empty search, a zero-yield source, an unreachable status) is a claim about the instrument until a control shows the instrument works: a member known to be in the source, found through the same instrument and query shape as the verdicts it licenses. The census entry records the control beside the negative it backs (§7). A not-found whose control ran through a different vertical, reader, or parameter set licenses nothing. A zero or surprising yield is read against the source's expected yield from the S&P₀ derivation before it is written down. An instrument finding recorded in `surprises` (a vocabulary rule, a platform behaviour) likewise names the queries behind it; one query generalises to nothing.

`unreachable` is a diagnosis, not an impression. Its census entry records the probe: what was tried, at parameter level. A wrong query and a closed gate look identical until a probe separates them, so a later round re-probes with varied parameters rather than skipping the source.

### Closure

Closure is earned or escalated, never declared, because the roster cannot certify its own completeness; closing takes external evidence at the denominator, the census, and a spot-check. Discovery for a segment closes when coverage (live roster count over the S&P₀ denominator) reaches the target the campaign plan sets, every census source is exhausted or carries an evidence-backed verdict with its control, and no instrument's count stands unreconciled against the denominator.

Closing includes a spot-check: a blind sample spanning every source kind the census holds, a positive and a negative conclusion from each, re-verified through an instrument that did not produce it: a row retired as unfindable re-run through a platform's own search, an absence from a directory re-run through the register. A spot-check finding reopens the census, because a defect surfaced by a random probe is one of a class.

No closure stands while the census leaves a kind of source unattempted. Registers, directories, outlets and platforms each make a population findable a different way: a register holds who is licensed, a directory who pays to be listed, an outlet who is notable, a platform who is active. A population thin in three of these is often plain in the fourth. Which register, which directory, which outlet and which platform serve a market is the campaign plan's to name; that set turns on geography and language, the kinds do not. Recording a kind as holding nothing meets the evidential standard §5 sets: the search was run, with its control, and returned nothing. An expectation that the population is not there does not meet it. Repeats prove instrument saturation, not market exhaustion: an iteration that re-runs earlier queries and re-finds swept contacts says nothing about the market, so each further iteration changes modality (a different register, platform, social graph, or geography) rather than re-running old queries. Three iterations remain the autonomous bound; going past S&P₃ is human-initiated (below).

A sweep that reaches the autonomous bound without earning closure escalates rather than closing or grinding on: it stops and reports the coverage arithmetic, the unharvested and contradicting sources by name, and each one's blocking reason, so the owner decides with the specific sources in hand. For informal segments with every census source exhausted, accept the count reached and record the shortfall against the denominator rather than absorbing it. S may terminate early within an S&P iteration once closure is earned, while P continues on accumulated contacts.

### S&P₄+ (human-initiated)

S&P₁ through S&P₃ run autonomously. Any iteration beyond S&P₃ is human-initiated, triggered by names accumulated during AR (the R phase reliably surfaces a small number of new names per band — respondents mention colleagues, connections reveal relevant people, revised strategy identifies uncovered segments). These names enter the roster at iteration number max(current) + 1, go through the same S steps as any other contact, and their profiles feed back into subsequent AR bands. The quantity is typically small enough that S&P₄ or S&P₅ is a lightweight pass, not a full discovery cycle.

## 7. The sweep file (sweep.yaml)

One sweep file per segment (`segments/<segment>.sweep.yaml`, beside the roster and the segment definition). It is the segment's discovery record and the S phase's working memory: the denominator, the instruments, what each round did, and what the next round should do. Future work on the segment starts from this file rather than rediscovering the vocabulary, and the T0 transition reads it as its input: one task per source not yet exhausted. It supersedes the earlier `summary-[segment-name].md`.

The head is forward-only (it states current reality); the rounds log is append-only (it states what happened). Structure:

```yaml
version: "2.0"
segment: <name>
market_estimate:            # S&P₀ output; the denominator
  value: <number or range, with any known unharvested layers>
  derivation: <top-down and bottom-up reasoning, source by source; a revision cites its instrument and keeps the figure it replaces>
  estimated: <date>
sources:                    # the census; every discovered_via maps to an entry here
  - name: <register/directory/outlet/platform/method>
    type: registry | directory | outlet | platform | informal   # every kind carries an entry; §6
    role: enumerates | bounds | verifies    # registers; §5
    url: <where>
    status: exhausted | partial | unreachable | unharvested | stale, each with its reason
    control: <backing a zero or negative status: the known member found through this instrument and query shape; §6>
    probe: <backing unreachable: what was tried, at parameter level; a re-probe varies it>
    yield: <n found / n in source after filter>
    discovered_via: <profile:{stem} when profiling surfaced the source (P §4.15); absent for seeded sources>
exclusions: <what this segment's scope keeps out, each filter naming the class it discards>
escapes:                    # permanent test cases; seeded at S&P₀, grown by misses; see below
next_round:                 # a human stages non-profile proposals here between rounds; sources_new entries (SPAR-P §4.15) go straight into sources, no staging
rows_to_verify: []          # roster rows a later source disputed
rounds:
  - n: <iteration>
    date: <date>
    method: <one line>
    inputs: {word_sets: {<category>: [<words>]}, new_sources: [], escapes_to_verify: []}
    reconciliation: <per source, rows kept vs source total after filter>
    yields: <per word where measured, in-catchment share>
    surprises: [<observations with sweep consequences; an instrument finding names its queries>]
    coverage_after: <count>/<denominator>
    reachable_after: <count with a written channel>
```

**Escapes.** The list is seeded at S&P₀ with members the operation already knows from its own ground truth (§6), each entry carrying its provenance. When a further market member surfaces that the sweep should have found (a user hands one over, a later source disputes the roster, profiling turns up an unswept peer), the member enters the roster immediately and the miss enters `escapes` with a verdict naming the cause: `missing-keyword`, `missing-source`, `source-not-exhausted`, `filter-too-tight`, or `process-defect`. The verdict decides which part of the head gets fixed, and the escape stays in the file as a test case the next round demonstrably catches.

**New-source claims.** Profiling and later rounds routinely propose "new" sources. A profile declares one as a `sources_new` entry (SPAR-P §4.15) and the harness refuses a name the census already holds, whatever its status: a source already listed as exhausted is a re-discovery, not an input for the next round. A human staging a source by hand makes the same check against the census before adding it.

The per-round `surprises` field absorbs what the old summary file recorded (vocabulary gaps, invisible sub-segments, CRM gap analysis results).

### 7.1 The sweeper file (shared sweep knowledge)

Segments are usually swept together as a market family: sibling populations sharing a catchment, instruments, and buyer geography. Facts that hold across the family live once, in a **sweeper file** named `sweeper-<family>.yaml`, a flat file at the instance root (the sweeps axis has no designed folder yet; see `spar-campaign-directory.md`). A segment joins by declaring `sweeper: <family>` in its definition YAML; membership is authored there and only there, so the sweeper file does not list its segments.

What lives where:

- **Sweeper file:** the catchment definition; sources serving more than one member segment (identity, URL, access mechanics and quirks); cross-segment strategy (contact-strategy splits, operator rollups spanning segments); harvest craft that is family-general.
- **Segment's sweep.yaml:** the denominator, each source's status and yield for this population, rounds, escapes, next_round. A shared source appears in the segment census by name with its per-segment status; its mechanics stay in the sweeper.

The cut is the SSOT test: a fact that would change for all member segments at once (the catchment moved, a register changed its access path) has its home in the sweeper; a fact that can change for one segment alone (a source exhausted for clubs but partial for providers) stays per-segment. A segment swept alone needs no sweeper; the fields stay in its sweep.yaml until a family exists.

## 8. Writing the roster during a sweep

The roster is the sweep's only data file, and a sweep creates no other. A sweep or person-resolution agent works on the segment's roster (`segments/{segment}.tsv`) directly: it reads the roster first to know the stems already present, then appends or updates row by row as it finds things, never rewriting wholesale. Findings land on the row they concern at the moment they are settled, so a stopped agent leaves finished work in the roster rather than stranded beside it.

Every attempt leaves its outcome on the row it concerned:

- A person found fills `contact_name`, `role`, and the channel columns.
- A person found where the row already has a contact goes into `s_note` as a dated alternate ("[date source alternate contact: name, role, channel; fallback if the listed contact does not answer]").
- A search that found nobody leaves a dated checked-empty marker in `s_note` naming what was tried ("[date source checked-empty: searches A, B]"). The marker settles nothing unless the census entry for that source carries its control (§6): a marker written through an uncontrolled instrument is open work wearing a verdict. A later resolution round targets only the unsearched, and it tells them apart by this marker alone: a blank contact with the marker is a settled miss, a blank contact without it is open work.

New rows are plain appends. Changes to existing rows go through the tool and recipes in `spar-roster-format.md`, "Programmatic access", which also names the faults a literal TSV writer exposes.

Concurrent writers on one roster lose data silently, and the failure mode differs by write style. Two writers on the read-modify-rewrite pattern both copy the same original, and the second replacement erases the first's rows: the file stays well-formed, rows are just gone. Two raw appenders can interleave mid-line, which corrupts the file itself. Either way the sweep loses truth, so a segment takes one writer at a time and a round that wants several agents on one segment runs them in turn. A running transition batch (P or A, dispatched by spar-transition) patches the roster from its single dispatcher process, which is safe against itself, and it holds the segment's writer slot until it finishes.

Serialising costs less than it appears, and less than the alternative. An agent parked behind another spends only waiting time, while a second data file spends the reader's trust: the roster stops being the answer to "who do we know here", and every later question needs a merge before it can be answered. That merge is where rows are lost, because it lands on a file other sessions are writing. So a sweep's output goes to the roster or waits for the roster, and the repository grows no companion file, no side directory, and no scratch copy to hold it in the meantime.

## 8a. Stale contact handling

S will routinely discover that a contact is stale: the person has left the organisation, changed roles, or retired from the field. A stale contact is not simply removed from the roster. The procedure is:

1. Mark the contact with `date_excluded` and record the reason in `s_note` (e.g. "current team page no longer lists this person, [date]" or "platform profile shows role ended [date]"). S's observations belong in `s_note`; `p_note` is written only by P.
2. Attempt to find the replacement — the person who now holds the role that made the original contact relevant.
3. The replacement enters the roster as a new contact in the current iteration, with `discovered_via` recording that they were found as a replacement for the stale contact.
4. If no replacement can be found (the organisation has closed, the role no longer exists), the stale contact is left marked and no replacement is added.

The stale contact's date allows periodic re-checking — a person who left a role in March may have taken a relevant role elsewhere by September.

## 9. Cross-lead capture

During S (and more commonly during P), names may surface that belong to a different segment from the one being researched — a contact relevant to a different campaign segment entirely.

These cross-leads must not be discarded because they fall outside the current segment's scope. Record them in the roster with `discovered_via` pointing to the originating contact and tag them with the destination segment (using whatever segment-tagging mechanism the campaign plan defines). The S phase of the appropriate segment picks them up in its next iteration. In campaigns with multiple segments running concurrently, cross-lead capture is one of the primary mechanisms by which segments inform each other.

## 10. Quality checklist

Run this checklist against all roster files after each iteration. Each check is a pass/fail assertion on the TSV data.

1. **Column count:** every row has the expected number of tab-separated fields (core columns per `spar-roster-format.md` plus any campaign-specific columns the plan defines).
2. **Named contacts:** every row has a non-empty `contact_name` that is not a placeholder (e.g. "(not publicly listed)", "(not found)"), or has a blank `contact_name` with a provisional organisation-slug stem. Rows with blank `contact_name` and no `date_excluded` are P-phase leads awaiting SPAR-P §4.1 name resolution — they are not errors.
3. **No duplicate contacts:** no two rows in the same roster file share the same (`contact_name`, `organisation`) pair (case-insensitive), and where rows carry a source key (§4) no two share it. Multiple contacts at the same organisation is permitted.
4. **Email format:** every non-empty `email` field contains an `@` sign. Strings like `via website`, `(07) 5572 3588`, or `[email obtained during call]` are not email addresses and must not pass validation. This is the gate that prevents non-email strings from inflating counts downstream.
5. **Reachable:** every row has at least one of email (valid, per check 4) or a platform URL populated. Phone alone is insufficient for campaigns that begin with a written introduction.
6. **Iteration recorded:** every row has a `sweep_iteration` value.
7. **Segment matches file:** if the roster uses a `segment` column, the value on every row matches the roster filename.
8. **Iteration progress:** for each roster, confirm that `sweep_iteration` is populated on every row, that every `sweep_iteration` value present has a matching round record in the sweep file, and that closure (§6) has been evaluated.
9. **Provenance maps to census:** every row's `discovered_via` corresponds to an entry in the sweep file's source census (§7), and a census entry claiming a zero yield or unreachable status carries its control or probe (§6). A row citing a source the census does not hold means either an undeclared source (add it, with status) or a provenance error (investigate).
10. **Coverage computed:** the round record's `coverage_after` equals the roster's live row count over the S&P₀ denominator, computed from the files rather than asserted.

Campaign-specific checks (e.g. "every outreach row has a non-empty p_note") are defined by the campaign plan, not by this AESOP.

## 11. Subagent delegation

When an AI agent delegates discovery work to a subagent, the prompt must tell the subagent to read this file rather than transcribing roster format definitions or iteration rules. The prompt should contain:

- The file path to this AESOP
- The roster file path
- The specific task (which segment, which iteration, what to search for)
- The campaign plan path

Do not replicate SPAR-S content in prompts — copies drift and cannot be corrected.

**Access cadence:** Signed-in platform lookups share a per-site access cadence that the serialised-browsing skill paces across every worker at once, so subagents may be dispatched concurrently when it is in use (see `spar-methodology.md`, "Web fetching and browser serialisation"). Only where no serialiser is available and lookups are hand-rolled do they run one at a time. Searches that do not sign in (web, register, directory) are exempt.

This AESOP does not prescribe how to access social media; each operator uses their own method and tooling. The access-cadence constraint is the only requirement.

**Context management for web page fetching:** covered in `spar-methodology.md`, "Web fetching and browser serialisation" — convert pages to plain text before they enter context, one page at a time.

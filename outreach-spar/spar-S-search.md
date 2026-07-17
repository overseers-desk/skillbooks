# SPAR-S: Sweep and Discovery

**Applies to:** AI agents (Sonnet tier) performing the S phase of the SPAR outreach methodology

**Prerequisite reading:** The campaign plan for the segment being researched (defines segments, estimated universe sizes, catchment area, seed sources, and search queries) and the SPAR methodology (`spar-methodology.md`, S section)

## 1. When to use this procedure

Use this procedure whenever a campaign needs a list of named people to contact. It applies to any outreach or sales campaign — membership recruitment, hospitality sales, community building, investor outreach — provided the campaign plan defines the target segments and estimated universe.

Campaigns may define two types of targets, or only one:

**Cue-required targets** are people who might send the campaign business, make introductions, or amplify its message if they knew about it — referral partners, community organisers, industry connectors, conference speakers. They need a cue (evidence they care about something the campaign offers) before contact; without one, the message is cold spam. The cue is collected during the P phase, not during S. S discovers the names; P determines whether a cue exists.

**Qualification-only targets** are organisations that are potential customers or members — they qualify by role and geography (or role and sector) alone and enter the outreach sequence without requiring a cue or detailed profile. P may be minimal or skipped entirely for these targets — the campaign plan specifies whether full profiling is needed.

The discovery steps are the same for both types. The differences — whether P is required, which roster columns apply, what the handoff looks like — are defined by the campaign plan, not by this AESOP.

## 2. Inputs

- **Campaign plan:** Specifies segments, estimated universe sizes, catchment area, seed sources, and search queries. The plan may also define campaign-specific roster columns beyond the core set defined in §4.
- **Existing roster (if any):** Check whether a roster file already exists for the segment. If one exists, continue from where it left off — do not create a new file.
- **SPAR methodology:** `spar-methodology.md` — for context on how S feeds P and how S&P iterations work.

## 3. Outputs

- **Roster TSV file:** One file per segment, in the location specified by the campaign plan. Contains every discovered contact with metadata tracking how and when they were found.
- **Sweep file:** `sweep.yaml` in the same directory as the roster (§7). Carries the market denominator, the source census with per-source status, escapes, and one record per round. It replaces the earlier `summary-[segment-name].md`; a segment still carrying a summary file migrates its content into `sweep.yaml` at the next sweep and deletes the summary.
- **New names for P:** Contacts discovered during S enter P within the same S&P iteration. Names that belong to a different segment are tagged with the destination segment and picked up by that segment's next S phase.

## 4. Roster file format

Store one TSV file per segment. Use TSV, not CSV — roster fields frequently contain quoted speech, URLs, and free-text notes that cause quoting problems with commas. The file is named `roster.tsv` and lives inside the segment's own directory (e.g. `wedding-planner/roster.tsv`). Do not embed the segment name in the filename — the directory already carries that context.

Every row should have a **contact_name** where one can be identified. If a source lists only an organisation and a quick check of the organisation's website, LinkedIn, and Facebook does not surface a named individual, retain the organisation as a row with a blank `contact_name`: write a provisional `stem` using the organisation slug, and leave `date_excluded` empty. Exclusion is a P-phase judgement: §4.1 runs the exhaustive name search, so sweep leaves `date_excluded` empty even when it could not surface a named individual. The blank-name row ensures future sweep iterations recognise the organisation as already discovered and do not re-add it.

Each S&P iteration updates the same file via the `sweep_iteration` column. Do not create separate files per iteration.

### 4.1 Core columns

These columns are standard across all campaigns. Every roster produced by this AESOP includes them:

1. **contact_name** — person's name (blank if no individual identified yet — the P-phase §4.1 procedure will attempt resolution)
2. **organisation** — business, group, or institution name
3. **role** — title or function
4. **phone**
5. **email**
6. **linkedin_url**
7. **facebook_url**
8. **sweep_iteration** — which sweep iteration added or last updated this row
9. **discovered_via** — the source that led to this contact. For seeds: the source name (e.g. "government school directory", "Google Maps", "industry association member list"). For social-graph contacts: the `contact_name` of the person whose profile surfaced this entry, creating a referral chain traceable to the original seed.
10. **date_excluded** — ISO date (YYYY-MM-DD) when the contact was confirmed unreachable or no longer in a relevant role. The date rather than a flag allows periodic re-checking — a person with no LinkedIn in March may have one by September. The profiling will skip entries that are already found invalid - although most entries are found invalid during profiling stage (P) hence profile is created anyway.

### 4.2 Campaign-specific columns

The campaign plan may add columns beyond the core set. The core columns are defined in `spar-roster-format.md`: the S and P phase handover notes (s_note, p_note) and the rating (star_rating). The A and R outputs (response_likelihood, a_note, r_note) are not roster columns — they live in the per-contact approach YAML. Common campaign-specific additions include:

- **segment** — when the campaign has multiple segments in a single roster or needs to tag cross-leads
- **postcode** or **address** — for geographic filtering
- **type** — contact category within a segment
- **source_url** — the specific page that justified inclusion

The campaign plan defines which additional columns apply and what they mean. This AESOP does not prescribe them.

## 5. Segment types

Segments fall into three types that affect how S is seeded and how quickly the roster reaches its target:

- **Registry segments** (e.g. schools, childcare centres, aged care centres): A government registry or official database provides a near-complete list. S typically exhausts the registry in 1–2 iterations. S&P₃ for a registry segment is mostly P work, not S work.

- **Directory segments** (e.g. wedding planners, tour operators, professional associations, industry member directories): An industry directory provides a partial list. S typically exhausts known directories in 2–3 iterations.

- **Informal segments** (e.g. community groups, mothers' groups, open source maintainers, meetup organisers): No central listing exists. S may not reach target even after 3 iterations; the roster continues to grow during AR as conversations surface referrals. Accept whatever count is reached.

The campaign plan specifies which type each segment is. If the plan does not classify segments explicitly, determine the type from the seed sources: if the plan names a government registry, it is a registry segment; if it names an industry directory, it is a directory segment; if it names only keyword searches, it is an informal segment.

Classification is an evidence-bearing claim, recorded in the sweep file's source census (§7). Classifying a segment as informal requires having looked for a registry and a directory and recording that the search came up empty; the licensing question is a cheap test (a licensed or government-subsidised activity almost always has a register). The costliest sweep failure on record came from treating a registry segment as informal: keyword search found 35 aged care organisations where the government register held over 500.

## 6. Discovery iterations

Discovery progresses through iterations that expand the roster in two ways: **social-graph expansion** (following referral chains from known contacts to their peers) and **semantic expansion** (broadening search queries based on how discovered contacts describe themselves and their industry).

### S&P₀: Size the market (gate)

Before any contact search, establish the denominator: how many members does this segment's addressable market hold, top-down (population and density reasoning) and bottom-up (which enumerable sources hold the population, with an expected yield each). Write the estimate with its derivation, and the source census it rests on, into the segment's `sweep.yaml` (§7). No searching starts while the denominator is absent.

Report every later progress claim as a fraction against this denominator ("412 of ~520"). A bare count carries no quality signal; the two order-of-magnitude under-deliveries on record were both invisible until someone asked "how many exist in the world?" — the question this gate moves to the front.

S&P₀ produces no roster rows and can run inside the same session as S&P₁.

### S&P₁: Seed

Build the initial roster from the most direct source available. For registry segments, export the registry and resolve named contacts. For directory segments, pull from the directory and search LinkedIn for individuals. For informal segments, use the keyword searches defined in the campaign plan, recording the query in `discovered_via`.

**Facebook keyword search (for segments where targets can be reasonably expected to be active on Facebook):**

If the campaign targets can be reasonably expected to be active on Facebook, run direct Facebook searches by keyword alongside other seed searches:

- Search Facebook groups and pages by campaign keywords
- From each result, extract the page/group name and identify administrators or organisers from the About section
- Note contact details found (email, phone, website link)
- Add discovered contacts to the roster with `discovered_via` recording the Facebook search query

When a CRM or existing contact database is available as a seed source, use it — but also run a **CRM gap analysis** after web research is complete. Compare CRM entries against web research results to identify structurally invisible segments — contacts that exist in the CRM but cannot be found by any web search query. Categorise the unmatched entries by why they are invisible (different self-description vocabulary, weak web presence, B2B rather than B2C, niche specialisation, outside search radius). This analysis reveals whether the invisible segment is reachable through alternative search vocabulary or whether the CRM is the only path to them.

### S&P₂: Verify and expand

For each S&P₁ contact, verify their current role and activity via their LinkedIn profile or Facebook page:

- **Role confirmation:** Does their current title match the roster entry? If they have moved on, find their replacement at the same organisation.
- **Activity confirmation:** Have they posted or commented on topics relevant to the campaign? (Note: detailed activity research, cue collection, and profiling are P-phase work. S confirms identity and detects role changes; P builds the full profile.)

Then expand via social graph: on LinkedIn, check who commented on or shared their posts — commenters are likely peers at other organisations. On Facebook, check co-admins, regular commenters, and linked groups. On Instagram, check tagged collaborators and location tags at similar venues or events.

Run the **reverse-search diagnostic** on the S&P₁ roster: search known contacts by name, note what co-occurring keywords appear in the results, then search by those keywords alone (hiding the names) to test whether they surface contacts invisible to the original search vocabulary. This catches vocabulary gaps — segments that use different terms to describe themselves.

New names found during verification and expansion enter the roster with `discovered_via` tracing the referral chain to the originating contact.

### S&P₃: Snowball and refine queries

Repeat the verify-and-expand step on contacts added in S&P₂. Each round yields fewer contacts as the social graph is exhausted.

At the same time, review the descriptors discovered contacts use for themselves. If the initial queries were for one set of terms but discovered contacts describe themselves differently, add those terms as queries for the current iteration. This **semantic expansion** reaches segments invisible to the original search vocabulary — people who do not use the seed keywords but who operate in the same space or serve overlapping audiences. Record expanded queries in `discovered_via`.

Run any expanded keyword queries identified by the reverse-search diagnostic from S&P₂.

### Stopping criteria

Discovery for a segment closes when either:

- Coverage (roster count over the S&P₀ denominator) reaches the target the campaign plan sets — high for registry segments, lower for informal ones; or
- every source in the census is marked exhausted with evidence, and the last modality-changing iteration added fewer than 5 new contacts.

Repeats prove instrument saturation, not market exhaustion: an iteration that re-runs earlier queries and re-finds swept contacts says nothing about the market, so each further iteration changes modality (a different register, platform, social graph, or geography) rather than re-running old queries. Three iterations remain the autonomous bound; going past S&P₃ is human-initiated (below). For informal segments with every census source exhausted, accept the count reached and record the shortfall against the denominator rather than absorbing it.

S may terminate early within an S&P iteration once the stopping criteria are met, while P continues on accumulated contacts.

### S&P₄+ (human-initiated)

S&P₁ through S&P₃ run autonomously. Any iteration beyond S&P₃ is human-initiated, triggered by names accumulated during AR (the R phase reliably surfaces a small number of new names per band — respondents mention colleagues, connections reveal relevant people, revised strategy identifies uncovered segments). These names enter the roster at iteration number max(current) + 1, go through the same S steps as any other contact, and their profiles feed back into subsequent AR bands. The quantity is typically small enough that S&P₄ or S&P₅ is a lightweight pass, not a full discovery cycle.

## 7. The sweep file (sweep.yaml)

One `sweep.yaml` per segment, beside the roster. It is the segment's discovery record and the S phase's working memory: the denominator, the instruments, what each round did, and what the next round should do. Future work on the segment starts from this file rather than rediscovering the vocabulary. It supersedes the earlier `summary-[segment-name].md`.

The head is forward-only (it states current reality); the rounds log is append-only (it states what happened). Structure:

```yaml
version: "1.0"
segment: <name>
catchment: <geographic or sector scope>
market_estimate:            # S&P₀ output; the denominator
  value: <number or range, with any known unharvested layers>
  derivation: <top-down and bottom-up reasoning, source by source>
  estimated: <date>
sources:                    # the census; every discovered_via maps to an entry here
  - name: <register/directory/platform/method>
    type: registry | directory | informal
    url: <where>
    status: exhausted | partial | unreachable | unharvested | stale, each with its reason
    yield: <n found / n in source after filter>
exclusions: <what this segment's scope keeps out, sharpened as misfits teach>
escapes: []                 # permanent test cases; see below
next_round:                 # staging block compiled from feedback between rounds
rows_to_verify: []          # roster rows a later source disputed
rounds:
  - n: <iteration>
    date: <date>
    method: <one line>
    inputs: {keywords: [], new_sources: [], escapes_to_verify: []}
    reconciliation: <per source, rows kept vs source total after filter>
    surprises: [<observations with sweep consequences>]
    coverage_after: <count>/<denominator>
```

**Escapes.** When a market member surfaces that the sweep should have found (a user hands one over, a later source disputes the roster, profiling turns up an unswept peer), the member enters the roster immediately and the miss enters `escapes` with a verdict naming the cause: `missing-keyword`, `missing-source`, `source-not-exhausted`, `filter-too-tight`, or `process-defect`. The verdict decides which part of the head gets fixed, and the escape stays in the file as a test case the next round demonstrably catches.

**New-source claims.** Feedback from profiling or later rounds routinely proposes "new" sources. Check the claim against the source census before accepting it; a proposed source the census already lists as exhausted is a re-discovery, not an input for the next round. Both a worker and a compiling agent have skipped this check in the same pilot; the census caught it at validation.

The per-round `surprises` field absorbs what the old summary file recorded (vocabulary gaps, invisible sub-segments, CRM gap analysis results).

## 8. Stale contact handling

S will routinely discover that a contact is stale: the person has left the organisation, changed roles, or retired from the field. A stale contact is not simply removed from the roster. The procedure is:

1. Mark the contact with `date_excluded` and record the reason in `s_note` (e.g. "current team page no longer lists this person, [date]" or "LinkedIn shows role ended [date]"). S's observations belong in `s_note`; `p_note` is written only by P.
2. Attempt to find the replacement — the person who now holds the role that made the original contact relevant.
3. The replacement enters the roster as a new contact in the current iteration, with `discovered_via` recording that they were found as a replacement for the stale contact.
4. If no replacement can be found (the organisation has closed, the role no longer exists), the stale contact is left marked and no replacement is added.

The stale contact's date allows periodic re-checking — a person who left a role in March may have taken a relevant role elsewhere by September.

## 9. Cross-lead capture

During S (and more commonly during P), names may surface that belong to a different segment from the one being researched — a contact relevant to a different campaign segment entirely.

These cross-leads must not be discarded because they fall outside the current segment's scope. Record them in the roster with `discovered_via` pointing to the originating contact and tag them with the destination segment (using whatever segment-tagging mechanism the campaign plan defines). The S phase of the appropriate segment picks them up in its next iteration. In campaigns with multiple segments running concurrently, cross-lead capture is one of the primary mechanisms by which segments inform each other.

## 10. Quality checklist

Run this checklist against all roster files after each iteration. Each check is a pass/fail assertion on the TSV data.

1. **Column count:** every row has the expected number of tab-separated fields (core columns from §4.1 plus any campaign-specific columns from §4.2).
2. **Named contacts:** every row has a non-empty `contact_name` that is not a placeholder (e.g. "(not publicly listed)", "(not found)"), or has a blank `contact_name` with a provisional organisation-slug stem. Rows with blank `contact_name` and no `date_excluded` are P-phase leads awaiting §4.1 name resolution — they are not errors.
3. **No duplicate contacts:** no two rows in the same roster file share the same (`contact_name`, `organisation`) pair (case-insensitive). Multiple contacts at the same organisation is permitted.
4. **Email format:** every non-empty `email` field contains an `@` sign. Strings like `via website`, `(07) 5572 3588`, or `[email obtained during call]` are not email addresses and must not pass validation. This is the gate that prevents non-email strings from inflating counts downstream.
5. **Reachable:** every row has at least one of email (valid, per check 4), `linkedin_url`, or `facebook_url` populated. Phone alone is insufficient for campaigns that begin with a written introduction.
6. **Iteration recorded:** every row has a `sweep_iteration` value.
7. **Segment matches file:** if the roster uses a `segment` column, the value on every row matches the roster filename.
8. **Iteration progress:** for each roster, confirm that `sweep_iteration` is populated on every row and that the stopping criteria in §6 have been evaluated.
9. **Provenance maps to census:** every row's `discovered_via` corresponds to an entry in the sweep file's source census (§7). A row citing a source the census does not hold means either an undeclared source (add it, with status) or a provenance error (investigate).
10. **Coverage computed:** the round record's `coverage_after` equals the roster's live row count over the S&P₀ denominator, computed from the files rather than asserted.

Campaign-specific checks (e.g. "every outreach row has a non-empty p_note") are defined by the campaign plan, not by this AESOP.

### 10.1 Approach file validation

Run this checklist against all approach YAML files after A-phase processing completes for a segment. Each check is a pass/warn/fail assertion on the YAML data in `{segment}/approach/*.yaml`. The dispatcher runs guard-rail checks (check 1) post-assembly in `spar-a-worker.tcl`. Campaign-wide validation and cross-segment duplicate detection are reported by `spar-progress.tcl`. Structural checks 2–5 are defined by the approach validation rules in `spar-manager/rules/approach.rules` and enforced during that campaign-wide validation.

1. **Email to: address validity:** For every email-channel message in a final round, the `to:` field must contain a deliverable email address (i.e. must contain `@` with a valid user@domain.tld shape). Placeholders (`[email obtained during call]`, `[confirmed email]`), contact form URLs (`via website...`), phone numbers, tildes, and empty values are flagged. This catches the class of issue described in issue #11: non-email strings that pass naive non-empty checks but are not sendable.
2. **Required top-level keys:** Every approach file must have `decisions` and `rounds` at the top level.
3. **Final round exists:** Every approach file must contain exactly one round with `type: final`. A file without a final round is structurally incomplete per the approach schema.
4. **Round structure:** Each round must have `type` (one of `draft`, `review`, `final`) and `number` (for draft and review). Draft and final rounds must have a non-empty `messages` list. Each message must have a `channel` field.
5. **Channel-roster consistency:** When the approach `decisions.channel` includes email but the roster's `email` field for the same contact does not contain a valid email address, flag the mismatch. This catches cases where the A phase assumed an email channel but no deliverable address exists in the roster.

Cross-segment check: email addresses targeted by final-round messages in multiple segments are flagged as warnings, since the same person receiving approach emails from two segments may see contradictory messaging.

## 11. Subagent delegation

When an AI agent delegates discovery work to a subagent, the prompt must tell the subagent to read this file rather than transcribing roster format definitions or iteration rules. The prompt should contain:

- The file path to this AESOP
- The roster file path
- The specific task (which segment, which iteration, what to search for)
- The campaign plan path

Do not replicate SPAR-S content in prompts — copies drift and cannot be corrected.

**Sequencing constraint:** Social media profile checks (LinkedIn, Facebook, Instagram) must run sequentially, one at a time. Concurrent requests trigger rate limiting and may result in account restrictions. When delegating to subagents, spawn them sequentially for social media lookups. Non-social-media searches (web, registry, GitHub, conference directories) can run concurrently.

This AESOP does not prescribe how to access social media; each operator uses their own method and tooling. The sequencing constraint is the only requirement.

**Context management for web page fetching:** When a subagent fetches web pages (organisation websites, employer About pages, registry directories), the raw HTML or even processed HTML consumes far more context tokens than the facts it yields. A single About page can return thousands of tokens; a subagent processing 20 websites in one session will exhaust its context on page content before it finishes.

To prevent this, always convert fetched HTML to plain text or markdown before bringing content into the conversation. For sites behind rate limiting or a login, prefer the serialised-browsing skill (see `spar-methodology.md`, "Web fetching and browser serialisation"); the hand-rolled chromium below is the fallback for public pages when no such skill is available:

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

If the subagent uses `WebFetch` (the built-in tool) instead of headless Chromium, write a tight extraction prompt that returns only the specific fact needed (e.g. "Return only the owner or director's full name and role, nothing else"). Even with a tight prompt, WebFetch results are large enough that more than 5–6 pages in one session will strain context.

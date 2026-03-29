# SPAR-S: Search and Discovery

**Applies to:** AI agents (Sonnet tier) performing the S phase of the SPAR outreach methodology

**Prerequisite reading:** The campaign plan for the channel being researched (defines channels, estimated universe sizes, catchment area, seed sources, and search queries) and the SPAR methodology (`spar-methodology.md`, S section)

## 1. When to use this procedure

Use this procedure whenever a campaign needs a list of named people to contact. It applies to any outreach or sales campaign — membership recruitment, hospitality sales, community building, investor outreach — provided the campaign plan defines the target channels and estimated universe.

Campaigns may define two types of targets, or only one:

**Cue-required targets** are people who might send the campaign business, make introductions, or amplify its message if they knew about it — referral partners, community organisers, industry connectors, conference speakers. They need a cue (evidence they care about something the campaign offers) before contact; without one, the message is cold spam. The cue is collected during the P phase, not during S. S discovers the names; P determines whether a cue exists.

**Qualification-only targets** are organisations that are potential customers or members — they qualify by role and geography (or role and sector) alone and enter the outreach sequence without requiring a cue or detailed profile. P may be minimal or skipped entirely for these targets — the campaign plan specifies whether full profiling is needed.

The discovery steps are the same for both types. The differences — whether P is required, which roster columns apply, what the handoff looks like — are defined by the campaign plan, not by this AESOP.

## 2. Inputs

- **Campaign plan:** Specifies channels, estimated universe sizes, catchment area, seed sources, and search queries. The plan may also define campaign-specific roster columns beyond the core set defined in §4.
- **Existing roster (if any):** Check whether a roster file already exists for the channel. If one exists, continue from where it left off — do not create a new file.
- **SPAR methodology:** `spar-methodology.md` — for context on how S feeds P and how S&P iterations work.

## 3. Outputs

- **Roster TSV file:** One file per channel, in the location specified by the campaign plan. Contains every discovered contact with metadata tracking how and when they were found.
- **Channel summary file:** `summary-[channel-name].md` in the same directory as the roster. Written when discovery is complete for a channel. Preserves the search vocabulary so that future work starts from the full keyword set rather than rediscovering it.
- **New names for P:** Contacts discovered during S enter P within the same S&P iteration. Names that belong to a different channel are tagged with the destination channel and picked up by that channel's next S phase.

## 4. Roster file format

Store one TSV file per channel. Use TSV, not CSV — roster fields frequently contain quoted speech, URLs, and free-text notes that cause quoting problems with commas. Filename convention is defined by the campaign plan (e.g. `roster-[channel-name].tsv`).

Every row must have a **contact_name**. A row without a named person is not a contact. If a source lists only an organisation, resolve a named individual by exhausting these sources in order:

1. The organisation's website (About / Team / Contact page)
2. LinkedIn people search
3. Facebook page About section
4. Instagram profile bio
5. Google search for the organisation name plus role keywords ("owner", "director", "organiser", "coordinator")

If all five return no named individual, omit the organisation entirely.

Each S&P iteration updates the same file via the `sweep_iteration` column. Do not create separate files per iteration.

### 4.1 Core columns

These columns are standard across all campaigns. Every roster produced by this AESOP includes them:

1. **contact_name** — person's name (mandatory — no row without this)
2. **organisation** — business, group, or institution name
3. **role** — title or function
4. **phone**
5. **email**
6. **linkedin_url**
7. **facebook_url**
8. **sweep_iteration** — which sweep iteration added or last updated this row
9. **discovered_via** — the source that led to this contact. For seeds: the source name (e.g. "government school directory", "Google Maps", "industry association member list"). For social-graph contacts: the `contact_name` of the person whose profile surfaced this entry, creating a referral chain traceable to the original seed.
10. **discovery_source** — the specific mechanism (e.g. "LinkedIn comment", "Facebook group co-admin", "LinkedIn People Also Viewed", "WebSearch: [expanded keyword query]")
11. **verified** — yes/no — role confirmed via social profile or other independent source
12. **date_found_invalid** — ISO date (YYYY-MM-DD) when the contact was confirmed unreachable or no longer in a relevant role. The date rather than a flag allows periodic re-checking — a person with no LinkedIn in March may have one by September.

### 4.2 Campaign-specific columns

The campaign plan may add columns beyond the core set. The core columns, including the phase handover notes (s_note, p_note, a_note, r_note) and ratings (star_rating, response_likelihood), are defined in `spar-roster-format.md`. Common campaign-specific additions include:

- **channel** — when the campaign has multiple channels in a single roster or needs to tag cross-leads
- **postcode** or **address** — for geographic filtering
- **type** — contact category within a channel
- **source_url** — the specific page that justified inclusion

The campaign plan defines which additional columns apply and what they mean. This AESOP does not prescribe them.

## 5. Channel types

Channels fall into three types that affect how S is seeded and how quickly the roster reaches its target:

- **Registry channels** (e.g. schools, childcare centres, aged care centres): A government registry or official database provides a near-complete list. S typically exhausts the registry in 1–2 iterations. S&P₃ for a registry channel is mostly P work, not S work.

- **Directory channels** (e.g. wedding planners, tour operators, professional associations, industry member directories): An industry directory provides a partial list. S typically exhausts known directories in 2–3 iterations.

- **Informal channels** (e.g. community groups, mothers' groups, open source maintainers, meetup organisers): No central listing exists. S may not reach target even after 3 iterations; the roster continues to grow during AR as conversations surface referrals. Accept whatever count is reached.

The campaign plan specifies which type each channel is. If the plan does not classify channels explicitly, determine the type from the seed sources: if the plan names a government registry, it is a registry channel; if it names an industry directory, it is a directory channel; if it names only keyword searches, it is an informal channel.

## 6. Discovery iterations

Discovery progresses through iterations that expand the roster in two ways: **social-graph expansion** (following referral chains from known contacts to their peers) and **semantic expansion** (broadening search queries based on how discovered contacts describe themselves and their industry).

### S&P₁: Seed

Build the initial roster from the most direct source available. For registry channels, export the registry and resolve named contacts. For directory channels, pull from the directory and search LinkedIn for individuals. For informal channels, use the keyword searches defined in the campaign plan, recording the query in `discovered_via`.

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

Stop discovery for a channel when any of these is met:

- The last iteration added fewer than 5 new contacts.
- Three iterations have been completed (for informal channels, accept whatever count is reached).

S may terminate early within an S&P iteration once the stopping criteria are met, while P continues on accumulated contacts.

### S&P₄+ (human-initiated)

S&P₁ through S&P₃ run autonomously. Any iteration beyond S&P₃ is human-initiated, triggered by names accumulated during AR (the R phase reliably surfaces a small number of new names per band — respondents mention colleagues, connections reveal relevant people, revised strategy identifies uncovered segments). These names enter the roster at iteration number max(current) + 1, go through the same S steps as any other contact, and their profiles feed back into subsequent AR bands. The quantity is typically small enough that S&P₄ or S&P₅ is a lightweight pass, not a full discovery cycle.

## 7. Channel summary

When discovery is complete for a channel, write a summary file alongside the roster: `summary-[channel-name].md` in the same directory. The summary records:

- The seed queries used in S&P₁
- The expanded queries discovered during later iterations (from semantic expansion and reverse-search diagnostic)
- Any segments that proved invisible to web search, and why (vocabulary gap, weak web presence, B2B-only, etc.)
- The CRM gap analysis results, if a CRM was used as a seed source

This file preserves the search vocabulary so that future work on the same channel — whether re-checking stale contacts, running a new campaign, or onboarding a new team member — starts from the full keyword set rather than rediscovering it.

## 8. Stale contact handling

S will routinely discover that a contact is stale: the person has left the organisation, changed roles, or retired from the field. A stale contact is not simply removed from the roster. The procedure is:

1. Mark the contact with `date_found_invalid` and record the reason in notes.
2. Attempt to find the replacement — the person who now holds the role that made the original contact relevant.
3. The replacement enters the roster as a new contact in the current iteration, with `discovered_via` recording that they were found as a replacement for the stale contact.
4. If no replacement can be found (the organisation has closed, the role no longer exists), the stale contact is left marked and no replacement is added.

The stale contact's date allows periodic re-checking — a person who left a role in March may have taken a relevant role elsewhere by September.

## 9. Cross-lead capture

During S (and more commonly during P), names may surface that belong to a different channel or segment from the one being researched — a contact relevant to a different campaign channel entirely.

These cross-leads must not be discarded because they fall outside the current channel's scope. Record them in the roster with `discovered_via` pointing to the originating contact and tag them with the destination channel (using whatever channel-tagging mechanism the campaign plan defines). The S phase of the appropriate channel picks them up in its next iteration. In campaigns with multiple channels running concurrently, cross-lead capture is one of the primary mechanisms by which channels inform each other.

## 10. Quality checklist

Run this checklist against all roster files after each iteration. Each check is a pass/fail assertion on the TSV data.

1. **Column count:** every row has the expected number of tab-separated fields (core columns from §4.1 plus any campaign-specific columns from §4.2).
2. **Named contacts:** every row has a non-empty `contact_name` that is not a placeholder (e.g. "(not publicly listed)", "(not found)").
3. **No duplicate contacts:** no two rows in the same roster file share the same (`contact_name`, `organisation`) pair (case-insensitive). Multiple contacts at the same organisation is permitted.
4. **Reachable:** every row has at least one of email, `linkedin_url`, or `facebook_url` populated. Phone alone is insufficient for campaigns that begin with a written introduction.
5. **Iteration recorded:** every row has a `sweep_iteration` value.
6. **Channel matches file:** if the roster uses a `channel` column, the value on every row matches the roster filename.
7. **Verified contacts still current:** no contact marked `verified=yes` has a `p_note` or `date_found_invalid` indicating they left the role or changed organisation.
8. **Iteration progress:** for each roster, confirm that `sweep_iteration` is populated on every row and that the stopping criteria in §6 have been evaluated.

Campaign-specific checks (e.g. "every outreach row has a non-empty p_note") are defined by the campaign plan, not by this AESOP.

## 11. Subagent delegation

When an AI agent delegates discovery work to a subagent, the prompt must tell the subagent to read this file rather than transcribing roster format definitions or iteration rules. The prompt should contain:

- The file path to this AESOP
- The roster file path
- The specific task (which channel, which iteration, what to search for)
- The campaign plan path

Do not replicate SPAR-S content in prompts — copies drift and cannot be corrected.

**Sequencing constraint:** Social media profile checks (LinkedIn, Facebook, Instagram) must run sequentially, one at a time. Concurrent requests trigger rate limiting and may result in account restrictions. When delegating to subagents, spawn them sequentially for social media lookups. Non-social-media searches (web, registry, GitHub, conference directories) can run concurrently.

This AESOP does not prescribe how to access social media; each operator uses their own method and tooling. The sequencing constraint is the only requirement.

**Context management for web page fetching:** When a subagent fetches web pages (organisation websites, employer About pages, registry directories), the raw HTML or even processed HTML consumes far more context tokens than the facts it yields. A single About page can return thousands of tokens; a subagent processing 20 websites in one session will exhaust its context on page content before it finishes.

To prevent this, always convert fetched HTML to plain text or markdown before bringing content into the conversation:

```bash
# Preferred: chromium fetch → pandoc → plain text (discards all markup)
/snap/bin/chromium --headless --dump-dom \
  --virtual-time-budget=5000 --window-size=1920,3000 \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  "URL" 2>/dev/null \
  | pandoc -f html -t plain --wrap=none > /tmp/page-text.txt

# Then extract the needed fact from the plain text file
grep -i 'founder\|director\|owner\|manager' /tmp/page-text.txt
```

For batch website lookups (e.g. resolving contact names for 20 organisations), process one page at a time: fetch, extract the fact, discard the page content, then fetch the next. Do not fetch multiple pages in parallel via WebFetch — the results all land in context simultaneously and cannot be discarded.

If the subagent uses `WebFetch` (the built-in tool) instead of headless Chromium, write a tight extraction prompt that returns only the specific fact needed (e.g. "Return only the owner or director's full name and role, nothing else"). Even with a tight prompt, WebFetch results are large enough that more than 5–6 pages in one session will strain context.

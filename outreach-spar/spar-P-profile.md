# SPAR-P: Profile Building

**Applies to:** AI agents (Sonnet tier) performing the P phase of the SPAR outreach methodology
**Prerequisite reading:** the segment file's `rating_rubric` and `discovery_criteria` (the standing, campaign-independent standard for who belongs and how valuable they are), `INVARIANTS.md` (I1 governs what may enter a profile), and the SPAR methodology (`spar-methodology.md`, P section)

## 1. When to use this procedure

Use this procedure when you have a roster entry — a name, an organisation, and optionally a LinkedIn URL or other seed data — and need to produce a profile document that the A (Approach) phase can consume. P runs within each S&P iteration on the contacts discovered in that iteration's S phase.

## 2. Inputs

- **Target:** Name, organisation, and whatever seed data the roster contains (LinkedIn URL, role, segment, discovered_via). If the roster entry has no `contact_name`, resolving one is the first task of this phase — see §4.1. Entries with a blank `contact_name` are P-phase leads, not invalid data.
- **Segment file:** The file (typically `segment.yaml`) that defines the segment's intended outcome and the mechanism by which contacts are expected to deliver it. Read this before anything else. It determines whether a contact type is structurally valid for the segment — independent of their domain relevance, seniority, or star rating.
- **Rating rubric (in the segment file):** the segment's `rating_rubric` defines what "valuable to us" means for this population, campaign-independent. It is the standing standard you judge the contact against. You are not given the campaign's ask, pitch, or USP, nor any campaign overview document; the profile is reused across campaigns and over time, so that knowledge belongs to the approach phase (INVARIANTS.md I1).
- **LinkedIn lookup method:** Use the LinkedIn skill or MCP available in your environment. Read its documentation before the first fetch in a session — it specifies sequencing constraints and any parsing scripts.

## 3. Output

A markdown file named `{stem}.md` in the segment's `profiles/` directory, where `{stem}` is the roster row's `stem` column value. The file opens with a YAML front-matter block carrying machine-read fields, followed by a markdown body. Structure defined in §5.

Additionally, P produces:
- **Roster updates:** If the target's role, organisation, or contact details have changed or were missing and are now known, update the roster entry directly (see §4.15).
- **New names:** If profiling surfaces names not already in the roster, add them to the roster with `discovered_via` pointing to the target being profiled and the specific mechanism by which they were found (e.g. "LinkedIn post commenter on [contact]", "co-admin of Facebook group with [contact]", "named in FOSSASIA Summit post by [contact]").

## 4. Procedure

### 4.1 Resolve contact name (run only if the roster has no `contact_name`)

If the roster entry has no `contact_name`, the organisation has been discovered by sweep but no individual has been identified. This step must complete before §4.2.

**If the roster entry carries `linkedin_url`, fetch that profile first** using the LinkedIn skill. A direct profile view is not subject to LinkedIn's search-rate protections, so when the URL is already known the fetch is cheap, the name resolves immediately, and the profile yields organisation, community, and collaborator names that seed later keyword and cross-platform work. The skill writes its saved HTML to the canonical path that §4.3 reads, so running it here doubles as the §4.3 fetch: the same artefact serves both steps. WebFetch, raw chromium, or any other channel produces no such artefact, so §4.3 will still need the skill to run.

**Otherwise, search these sources in order:**

1. **Company website** — About, Team, or Contact pages often name the owner or manager.
2. **Facebook** — Small operators frequently maintain their primary presence here. Search for the company name; check the About section and any "Run by" attribution. Use the Facebook skill if available.
3. **LinkedIn by search** — Search for the company; check the People section for the managing director or owner. Use the LinkedIn skill if available. Search is rate-limited where direct URL view is not, so this step comes after the cheaper ones.
4. **ABN registry** — For sole traders and small Pty Ltd companies, the ABN Lookup may name an individual.
5. **Yellow Pages, TrueLocal, Google Maps reviews** — Reviews and listings sometimes name the owner.
6. **Web search** — `"[company name]" owner OR director OR founder OR operator`.

**If a name is found:**
- Update `contact_name` in the roster.
- If the entry had `date_excluded` set **solely because it lacked a contact name**, clear `date_excluded` and re-run §4.2 (the structural validation check). The entry may be revalidated if it passes §4.2.
- If `date_excluded` was set for a structural reason (contact type does not fit the campaign mechanism), finding a name does not revalidate the entry — the structural reason stands.

**If no name is found after exhausting all sources:**
- If the roster entry has no `stem`, write one using the organisation slug (e.g. `a-team-coaches` for "A-Team Coaches"). This ensures the row is identifiable in the state machine.
- Record in `p_note`: "name search attempted [date]: no individual identified via website, Facebook, LinkedIn, ABN, web search."
- Set `date_excluded` to today with reason "name search exhausted ([date])." This is the P-phase's responsibility — sweep does not set `date_excluded` for entries whose individual was never identified.
- Do not proceed to §4.2 or produce a profile document. The roster entry is the permanent record.

### 4.2 Validate fit against segment file

Before any further research, read the segment file and answer one question: can this contact deliver the outcome the segment describes, through the mechanism the segment describes?

This is a structural check, not a relevance check. A contact may be in the right domain, at the right seniority, with strong apparent fit — and still be the wrong type of contact for the segment. The segment file specifies a mechanism: the particular way a contact is expected to act on the campaign's behalf. The check is whether this contact operates through that mechanism. A contact who is adjacent to the mechanism — who knows the right people, or works in the same field, or whose platform could theoretically be adapted — does not pass the check unless the segment file explicitly includes that adjacent role.

If the contact cannot deliver the outcome through the mechanism the segment describes, set `date_excluded` to today's date and record the reason in `p_note`. Do not proceed to §4.3. Do not produce a profile document.

**Do not delete the roster row.** The roster is append-only. Deletion causes re-discovery in the next sweep, where the entry may be incorrectly validated if the profile stage repeats the same error. The `date_excluded` date is the permanent record that this contact was assessed and excluded. This rule applies to every exclusion in this procedure — it is not restated later; refer back here.

If an invalid entry has already passed Profile and reached the approach queue, the failure is at the P stage. The question to ask is whether the segment file was specific enough to make this check possible. If the exclusion was not obvious from the segment file, the segment file may need a `discovery_criteria` section that names the contact types that do not belong, so future sweeps and profile runs do not repeat the error.

### 4.3 Fetch and parse the LinkedIn profile

If §4.1 already fetched the profile via the roster's `linkedin_url`, the data is captured — proceed to §4.4.

Otherwise: if the roster provides a LinkedIn URL, fetch and parse it. If no URL is provided, search for the person by name and location first, identify the correct profile, then fetch it.

Prefer the LinkedIn skill for the fetch. It routes through the user's serialised browser, which paces access so a burst of profile views does not throttle the address or flag the logged-in session (see `spar-methodology.md`, "Web fetching and browser serialisation"). If no serialised-browsing skill is available in your environment, hand-roll a headless chromium fetch instead; do not halt.

**From the parsed profile, extract:**
- Current role and organisation
- Full career history with dates
- Education (degrees, certifications, current study)
- Volunteer and mentorship roles
- Location
- **Employment-currency signal**, if present: an "Open to work" / "#OpenToWork" banner, a "Providing services" / freelance section, or a headline whose named employer or role the current-experience entry or recent activity contradicts ("ex-", a different current employer). Capture verbatim; record it in the body `## Current role`. Its presence means the stated role may be ending — see §4.13.

**DOM parsing note.** LinkedIn's DOM parser sometimes returns category labels (e.g. "Startup") rather than company names, and when a person lists multiple roles at the same organisation, the parser may present them as separate entries. Cross-reference roles by date overlap and description content to identify entries that belong to the same organisation. If a "Co-Founder" entry describes a crowdfunding platform and a "Business Development Manager" entry is at "Startup" during the same period, these are almost certainly the same company.

Social media fetches run sequentially — see §6.

### 4.4 Fetch and parse the Facebook profile

Run this step after §4.3. Use the Facebook skill under the same rule as §4.3 — prefer the serialised skill, hand-roll a chromium fetch if none is available. "No verified match found" (see Verification, below) is a legitimate outcome of having actually fetched and checked a candidate profile, not a substitute for fetching one.

The purpose of this step is twofold: (1) verify the person found is the same individual as on LinkedIn, and (2) collect details not available on LinkedIn, in particular current workplace, community affiliations, and recent activity. Fetch both the main profile page and the About page.

**Verification:** Before recording any data, confirm the match. A match requires at least two corroborating signals: same name, same location (city/region), same employer as other sources, or profile photo consistent with other known images. If the match cannot be confirmed, record "Facebook: no verified match found" in the profile and do not use unverified data.

**If match confirmed, extract:**
- Current workplace and role (often more current than LinkedIn)
- Location
- Community groups or pages they admin or follow (relevant to campaign angles)
- Any public posts relevant to the campaign

### 4.5 Keyword search for relevance terms

Run keyword searches on the saved HTML using terms drawn from the segment's `rating_rubric` and `discovery_criteria`. This determines which relevance signals have direct evidence.

If you fetched via the LinkedIn skill or MCP, use its keyword-search tool, passing the saved profile HTML and the keyword list; if you hand-rolled a chromium fetch, grep the saved DOM for the keyword list.

**Choose keywords from two sources:**

1. **Rubric keywords.** From the segment's `rating_rubric` and `discovery_criteria`, derive 2–4 search terms for each value signal the rubric names (the topics, audiences, and contact attributes that make a member valuable). Search the saved HTML for those terms.

2. **Profile-derived keywords.** After parsing the profile, note organisations, projects, and people mentioned. Run a second keyword search for these to extract context (what the target said about them, how they are connected). This is the step that surfaces connections — not the initial parse.

Run multiple rounds of keyword search if needed. The first round checks campaign relevance. The second round chases threads found in the first (e.g. if the first round finds "FOSSASIA" 24 times, the second round searches for specific people and partner organisations mentioned in FOSSASIA context).

### 4.6 Research the target's employer

Visit the website of the target's current employer (and previous employer if the current role is recent — under 12 months). Convert fetched HTML to plain text before processing — see SPAR-S §11 "Context management for web page fetching" for the method. Note:
- The organisation's mission statement and focus areas
- Programmes, labs, working groups, or convenings the organisation runs — especially those that involve external stakeholders, policymakers, or industry participants
- Named leaders (the target's direct supervisor or programme director)
- Any institutional assets that create campaign-relevant access (e.g. the employer runs policy education for government staff, or convenes industry standards discussions, or operates a conference series)

This step is critical for targets whose personal public statements are limited but whose institutional position creates value. A junior programme officer who has written one relevant article may appear low-value if assessed on personal statements alone, but may be high-value if their employer runs a technology policy education programme for lawmakers. The A phase needs the institutional context to frame the outreach correctly — as an institutional proposition rather than a personal one.

If the employer's website reveals programmes or focus areas relevant to the campaign, record them in a dedicated section of the profile document ("Institutional context" or similar, under the domain-specific operational context section). Note which programmes the target is personally involved in versus which are run by their team or organisation more broadly.

When the segment's value turns on the outlet's reach and the outlet is not one independently recognisable as large, do not inherit a "large / major / global" label from the profile seed or the outlet's own copy. Verify current reach against an external figure (a traffic source such as Similarweb) and record the number with its date and source. A size label without a number and a date is not evidence (§5.0).

### 4.6.1 Distance from venue (when proximity bears on relevance)

Run this step only when (a) the prompt declares a campaign venue (line beginning "Campaign venue:") and (b) proximity to that venue is a factor in the segment's angle table or otherwise bears on the relevance assessment for this campaign. If neither condition holds, skip — distance is not free context to collect for its own sake.

When the conditions hold, do not estimate distance. Geocode the target's primary work address (resolved during §4.6) via Nominatim:

```
https://nominatim.openstreetmap.org/search?q={URL-encoded address}&format=json&limit=1
```

Then call OSRM using the venue coordinate from the prompt and the target coordinate from Nominatim:

```
https://router.project-osrm.org/route/v1/driving/{venue_lng},{venue_lat};{target_lng},{target_lat}?overview=false
```

Record the target address used, the OSRM driving distance in km, and the duration in minutes inline with the institutional context written in §4.6. If geocoding or routing fails, record the failure reason and proceed without a distance value — never substitute a guess.

This responsibility is temporary; the harness will absorb the OSRM call once `venue` is consistently populated and a target-side location field is added to the roster. See #93.

### 4.7 (removed) Warmth and prior correspondence are not profile content

P does not check IMAP and does not record warmth. Prior correspondence and warmth are engagement state: they change between campaigns and the first message we send falsifies them, so a profile carrying them is stale on reuse (INVARIANTS.md, I1). The approach phase determines warmth fresh at contact time, from the per-contact approach log and a current IMAP check.

### 4.8 Source contact email

Skip if the roster `email` field already contains a valid, unmasked address (has `@` and does not contain `*`). Otherwise, search in order:

1. Organisation website contact/about/team page (§4.6 already visited the site)
2. Web search: `"{contact name}" "{organisation}" email`
3. Industry directories: ABN Lookup, Yellow Pages, TrueLocal
4. Pattern guess + verify: construct `firstname@domain` from the contact name and the organisation's website domain, then web-search the guessed address in quotes. Data-broker sites (ZoomInfo, RocketReach) often confirm or mask real addresses — a masked result like `s***@domain.com` that matches the guess validates the pattern. Also check `whois` for the domain's email convention.

**Email format gate.** Before writing any value to the `email` column, verify it contains an `@` sign with a plausible user@domain shape. Contact form URLs (`via website...`), phone numbers, placeholders (`[email obtained during call]`), and descriptive text are not email addresses and must not be written to the email field. If the only contact method found is a web form or phone number, record it in `p_note` instead. This gate matches the §10 check 4 validation rule in `spar-S-search.md` and prevents non-email strings from inflating downstream progress counts.

Never write a masked or redacted email address (e.g. `b***@example.com`) to the roster. If a data-broker result is masked and the unmasked form cannot be verified, leave the field empty. The post-profile guardrail will blank any masked email that slips through.

**Name-mismatch check.** If the email found is associated with a different name than the roster contact — e.g. the roster says "Jess" but the contact page email is `athena@example.com` — do not write it yet. Investigate who currently runs the business; the result feeds the Person-vs-company correction in §4.15.

**Shared-inbox rule.** Before writing an email, check whether the same address is already carried by another row in this segment at the same organisation. If it is, do not write the duplicate and do not overwrite the other row. Research for a non-shared alternate — a personal mailbox, a direct-dial address, a `firstname@` form — and write that. If no non-shared alternate can be found, leave this contact's `email` field empty; the approach will proceed via LinkedIn, phone, or (if no reachable channel remains) be excluded. A single shared inbox (`admin@`, `info@`, `hello@`, `grow@`, etc.) must belong to at most one roster row per organisation, because two outreach emails landing in the same inbox on behalf of two different people reads as bulk outreach, not considered correspondence. The runtime post-validator (`roster_shared_inbox_collision`) will reject the second write and re-prompt for this rule.

If the email passes the format gate, the name check, and the shared-inbox check, write it to the roster via `sqlite3`. If not found, record in `p_note`: "email search attempted [date]: no public email found."

### 4.9 Web search for public activity beyond LinkedIn

Search for the target's name plus campaign-relevant terms, excluding LinkedIn:

```
"[Full Name]" [campaign topic keywords] [current year OR previous year]
"[Full Name]" [organisation name]
```

This catches conference talks, blog posts, published papers, media quotes, and GitHub activity that do not appear on LinkedIn. If nothing turns up, note "no public activity found beyond LinkedIn" — the absence is informative for yield.

### 4.10 Record what the target has said publicly

For each substantive public statement found (LinkedIn posts, blog posts, conference talks, tweets, mailing list messages), record:
- The quote or close paraphrase
- The source (LinkedIn post, blog URL, conference name and year)
- What it reveals about the target's concerns, positions, or interests

When the target has published an article or given a talk, extract specific recommendations, proposals, or calls to action — not just the general argument. "Wrote about XZ" is less useful to the A phase than "recommended SBOMs as industry standard and called for a partnership model among OSS communities, enterprises, and federal agencies." These specifics are the hooks the A phase uses to connect the target's stated views to the campaign's offering. A summary that captures the framing but omits the concrete proposals strips out the most actionable material.

Do not invent or infer statements. A-phase sometimes fabricata a connection that does not exist, and blame P-process for "hinting" the connection exists, there probably isn't any good solution barring from asking agents to careful not to imply things or invent/infer.

### 4.11 Record who the target knows

From LinkedIn posts (names mentioned or tagged), profile connections visible in the parse, and web search results, identify people connected to the target who are relevant to the campaign. For each:
- Name and their role/organisation
- How they are connected to the target (tagged in post, co-organiser, commenter, co-admin) — record the mechanism, not a vague "appears to know"
- Why they are relevant to the campaign (bridges to a target community, works at a target organisation, holds a relevant role)

This is where the "network / connection value" angle is assessed. A target may have said nothing about the campaign's technical themes but may know people and communities the campaign needs to reach. The connections table is evidence for this angle. Connection value requires specific, named paths — "500+ connections" or any raw count is not evidence. What qualifies is a visible relationship to a named community, organisation, or person the campaign needs to reach.

**Cross-reference people already in the system.** For each surfaced name, grep the segment's profiles directory and roster before continuing:

```bash
grep -ril "PERSON NAME" /path/to/profiles/ /path/to/roster.tsv
```

If the person already has a profile, update it to record the new information. Examples: "this person was replaced at [org] by [target] as of [date]" (useful for inferring the departing person's industry experience); or "this person is the predecessor of [target] at [org], whose background may inform [target]'s approach." Prior industry experience — especially if the person came from the operator side of the same industry — changes the register of any approach written for them. A profile that records only the current role and misses a relevant predecessor role causes the A phase to write to a stranger who already speaks the trade's language. If the person is in the roster but has no profile yet, note the cross-reference in the current profile; the next P run for that contact will pick it up. Do not touch approach files — approach regeneration in response to a cross-reference update is a graph-type transition that the batch pipeline does not currently handle (see #4).

**New names for the roster.** Any person found in this step who is not already in the roster and who is relevant to the campaign (by role, organisation, or community membership) should be added to the roster as a new contact. Record `discovered_via` as the target being profiled together with the specific mechanism (e.g. "tagged in LinkedIn post about FOSSASIA Summit 2024 by [contact]"). After completing all social media fetches for the current target, profile each newly added contact immediately by spawning a P subagent — do not defer to a future sweep, which may never run. If the seed data for a new contact is insufficient to produce a meaningful profile (name only, no organisation or role), write the roster entry and accept it will not be profiled in this session.

### 4.12 Judge usefulness to us

P judges how useful this contact is to us in general, the campaign-independent value `star_rating` measures (see "Campaigns and segments"). Designing the pitch, the angle and the specific ask, is the approach phase's job. There are two reasons, not one. Reuse: a segment's profiles serve many campaigns over time, each asking the contact for something different, and the same campaign may run again once our own facts have moved; a profile that argues one campaign's pitch, or recites our facts as they stand today, binds the profile to that ask and that moment and goes stale or wrong-ask the next time it is read. Approach-neutrality: naming our facts or USP pre-empts which USP the approach phase leads with for this contact — its decision, not the profile's — and lets a campaign-independent record imply what this campaign is about; this holds even when the fact is stable, which is why a USP mention goes but a stable structural comparison that pre-empts no pitch may stay. So the profile stays about the contact; the ask, our facts, and the pitch live in the approach phase, which is re-instantiated per campaign.

Weigh the contact's audience, the topics they cover, the guests or subjects they feature, and any stated interest, against what this segment needs (its `rating_rubric` and `discovery_criteria`). Record the fit, where it is strong, weak, or absent, and any caution (wrong audience, stale, low engagement), in the body `## Relevance assessment` section (§5.2), as the contact's attributes against the segment rubric. This is the campaign-independent judgement behind `star_rating` (§4.13).

### 4.13 Assign ratings

**Star rating (0–5):** How valuable is this contact to us in this segment, in the general sense, today? Not how good their business is, nor how much they like us — whether we would value a relationship with them at all, independent of any one campaign's ask. Assigning this rating is P's responsibility. Any value already in the roster's `star_rating` column was written before profiling and must be ignored — it carries no authority. Derive the rating solely from what profiling reveals.

If the segment file carries a `rating_rubric`, apply it as written. If it does not, judge general value to us directly: would our organisation, independent of any single campaign's ask, value a relationship with this contact? Do not borrow the current campaign's objective or conversion funnel as the standard for "useful" — that turns on the campaign's ask and belongs to `response_likelihood` (campaign-dependent, set by A), not the star rating. The rating rubric is segment-local: segments differ in what useful means, so anchors borrowed from another segment's rubric are wrong for this one. If the question cannot be answered with confidence, that is an instruction to deepen profiling, not to default to a middle value.

A rating resting on a role cannot stand on a role whose currency the discovery contradicts (an open-to-work signal, a headline/experience mismatch, an "ex-"); a rating resting on reach cannot stand on an unverified size label. Where discovery unsettles the basis of the rating, re-derive the rating from what was verified, not from the prior basis. (Where the role has been vacated outright, §4.15 governs: exclude and find the replacement.)

If profiling reveals that the contact cannot deliver the segment's intended outcome through the mechanism the segment describes — including cases where §4.2 was not run before profiling began — set `star_rating` to 0 and exclude per §4.2. Do not produce a profile document for contacts assessed at 0; the roster entry is sufficient. This is distinct from a 1-star rating: a 1-star contact is targetable if band processing reaches that level; a 0-star contact is excluded.

**Write `star_rating` in two places: the profile front matter (`star_rating:`) and the roster TSV column.** The profile is the authorial home — it is where P records the assessment and where git history preserves it across later roster edits. The TSV column is the query-optimised copy used by the state machine, band filters, and progress counts. Both must be written by the same P run; `sqlite3` updates the roster row in-place. The two copies are physical replicas of one logical value: they MUST match at end-of-run. **Order matters: write the profile body first, then write the roster TSV (this `sqlite3` step forces a fresh re-read of the rubric), then write the YAML front matter at the top of the profile file with the same value already in the roster.** Writing the front matter first creates a divergence risk: an autoregressive agent's understanding of the rubric matures while writing the body, and an early front-matter value can lag the late roster value (observed: an LLM agent wrote `star_rating: 4` to the front matter and `star_rating=1` to the roster in a single run because the rubric only fully clicked at the §4.13 sqlite step). `response_likelihood` is set by the A phase, not P; do not write it here.

### 4.14 Record profile yield

Count substantive data points. The following all qualify as data points: (a) public statements with extractable quotes, (b) specific recommendations or proposals the target has made, (c) career history entries that demonstrate relevant domain experience (e.g. cybersecurity crisis communications background at a consultancy), (d) current institutional context that creates campaign-relevant access (e.g. employer runs policy education programmes for government staff, or operates a technology convening series), (e) named connections relevant to the campaign, (f) recent activity indicating current engagement (posts, conference appearances, publications within the past 12 months). Do not count only quoted public statements — a target who has said little publicly but whose employer operates a programme directly relevant to the campaign has more data points than a narrow reading would suggest.

Record the count as `yield: N` in the profile front matter. Downstream consumers derive behaviour from the count; thresholds belong in the A-phase AESOP, not here. For guidance, common A-phase practice has been: yield ≥ 6 supports up to 3 passes of A1/A2 sparring; yield 3–5 supports 1 pass; yield < 3 implies A2 sparring adds little value. These thresholds live with A, not with P — P reports the count, A decides how to use it.

### 4.15 Verification corrections

Compare what the profile reveals against what the roster entry says. If any of the following has changed, update the roster:

- The person has left the organisation listed in the roster
- Their role title is different from what the roster says
- Their location has changed
- Contact details (email, LinkedIn URL, Facebook URL) are incorrect — update the wrong value

**Backfill empty contact fields.** If the roster entry has a blank `email`, `linkedin_url`, or `facebook_url` and profiling discovers a value for it, that is not a correction — it is a backfill, and it is equally required. For `email` specifically, §4.8 runs a dedicated search earlier in the procedure; this backfill clause covers emails discovered incidentally during later steps (§4.9 web search, §4.11 connections) that §4.8 did not find. The sweep phase often finds only a phone number; the profile phase researches the person and their organisation in depth and routinely surfaces emails (from company websites, directories, ABN records) and social URLs (from Facebook pages, LinkedIn search) that the sweep did not capture. These must be written back to the roster, not left only in the profile prose.

Backfilled emails must pass the §4.8 format gate, name-mismatch check, and shared-inbox rule — this section does not repeat those rules.

Only backfill emails that belong to the contact or their organisation. An email discovered for a different person mentioned in the profile (e.g. a successor, a co-admin) belongs in that person's roster row, not this one.

For each empty contact field where a value was discovered, update the roster using `sqlite3`.

**Person vs. company.** Ask whether the campaign wants this person or the person currently in this role at this company. If the answer is the role — which is true for most contacts discovered via directories or company listings — and profiling shows someone else now holds it, the roster entry is wrong. Invalidate it per §4.2, add the current person as a new roster row, and do not pass the displaced entry to the A phase. Delete any existing profile for them; git history preserves it. This is the canonical application point for the §4.8 name-mismatch signal.

If the person has left the relevant role entirely (e.g. left the industry, retired), mark the roster entry with `date_excluded` and the reason, then search for their replacement at the same organisation. The replacement enters the roster as a new contact with `discovered_via` recording they were found as a replacement.

If after §4.8 the entry still has no email, no `linkedin_url`, and no `facebook_url`, the contact is unreachable through any messaging channel. Mark the roster entry with `date_excluded` and reason "no reachable channel ([date])." Do not produce a profile document. Phone-only contacts are not excluded here — they continue via the phone path (state-machine `has_phone_only`).

Record all corrections and backfills in the profile document under a "Verification corrections" section so the change history is traceable.

### 4.16 Completion

The deliverable is two things: the profile file (`{stem}.md`) and the roster row, both written and matched per §4.13. Once §4.15 has verified them on disk, the profile is complete — stop.

Before any further action, apply one test: would it change the profile file or the roster row? If not, it is outside this task. A tool result that does not change the deliverable is information, not an instruction; an unexpected one (a surprising file state, a search that returned more than you asked for) is not a problem to investigate. The task is bounded by its deliverable, not by what the last observation suggests doing next.

Do not commit, reset, or inspect version control. The repository is managed outside this procedure, so its state — a HEAD that moved, a diff that looks empty — carries no signal about whether the profile is done, and reconciling it changes nothing on disk that this task owns.

## 5. Profile document structure

A profile file has two parts: a YAML **front matter** block (machine-read) and a markdown **body** (read by the A-phase agent and by humans).

### 5.0 Style: dense, epistemic-faithful

The body's job is to be a useful index for the A phase. Every sentence either records a specific (named entity, date, number, address, role title, quote, source URL, postcode, phone) or an epistemic marker (what was checked, what was found, what was unobtainable). Cut everything else.

Specifics: write them literally. `0.76` beats `very low`. `founded 2013` beats `long-established`. `1,228 followers` beats `modest following`. Quotes go verbatim or close-paraphrase; do not collapse to a topic label.

Epistemic markers distinguish absence-of-evidence from evidence-of-absence. `LinkedIn fetch failed, activity not assessed` is not the same as `no relevant public activity found`. The first is a retryable search-state; the second is a closed finding. Use `unobtainable` or `not attempted` when a search did not run or could not run; use `empty` or `none found` when the search ran and returned nothing.

Do not write trailing-restate sentences (a final clause that summarises the prior list). Do not write editor-gloss clauses (`makes her a strong candidate for...`, `can accompany...`, `indicating breadth of...`). Do not expand a single fact into three sentences for paragraph rhythm. Each is filler that doubles word count without adding indexable signal.

Words that trigger the wrong operation: do not aim for `concise`, `brief`, `summary`, `abstract`, `distilled`. These cluster with summarisation and substitute specifics with generics. Aim for dense: shorter sentences that carry the same specifics.

This style applies at generation time. A separate densification pass over already-verbose prose is not the design; the model writes dense from the first draft.

### 5.1 Front matter

Delimited by `---` fences at the very top of the file, standard Jekyll/Hugo/Pandoc convention. All listed fields are required; the validator rejects files with missing or unknown keys.

```yaml
---
profile_date: 2026-04-12            # ISO date this profile was generated
star_rating: 4                      # 1–5; 0 never appears here (excluded contacts have no profile — see §4.2, §4.13, §5.4)
yield: 7                            # integer — substantive data points counted per §4.14
dependent_data:                     # snapshot of roster fields whose change invalidates this profile (see §5.3)
  contact_name: Kara Struckman
  organisation: Wilson Center
  role: Director, Environmental Change and Security Program
  date_excluded: null
---
```

**Field ownership.** `profile_date`, `star_rating`, `yield` are P-authored at profile generation time. They are not copies of roster values — they are the authorial record of P's assessment. If the roster is later hand-edited, git history of this profile preserves what P originally decided.

**What is *not* in the front matter.** Approach-time decisions (`channel`, chosen `angle`, `sender`, `language`, `response_likelihood`) belong in the approach YAML, authored by A. Contact channels (`email`, `linkedin_url`, `facebook_url`, `phone`) belong in the roster TSV. Do not duplicate them here.

### 5.2 Body

The body is prose that the A-phase agent reads to select an angle and draft a message. Section order is fixed; the validator does not check body content, but A-phase readers expect this layout.

```markdown
# Profile: [Full Name]

## Current role

[Current title at current organisation, with dates and brief description of responsibilities if known]

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| ... | ... | ... | ... |

## Certifications and education

- [Items, noting any in-progress degrees or recently obtained certifications]

## Volunteer and mentorship

- [Items relevant to the campaign]

## What they have said publicly

**On [topic] ([source]):** "[Quote or close paraphrase]"

[Repeat for each substantive statement. This section is the canonical home for direct quotes attributable to the target, whether the source is a public post (LinkedIn, blog, conference) or a private email exchange with the campaign sender. Each quote appears exactly once in the profile. If the target has said nothing on a relevant topic and the absence bears on the rating, mention it inline once: e.g. `No public statements found on [topic].` Do not write a dedicated absent-themes block; absences that do not change the rating are not worth a line.]

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| ... | ... | ... |

## [Domain-specific operational context, if applicable]

[e.g. "FOSSASIA operational role" — only include if the target has operational experience relevant to the campaign that does not fit in the career history table]

## Relevance assessment

[Numbered list of the relevance dimensions, with specific evidence for each: which value signals from the segment `rating_rubric` this contact meets and how strongly, including where a signal is weak or absent. This is the campaign-independent judgement behind `star_rating`. Do not write a separate "What they have NOT said" header; the §5.0 style already prohibits paragraph-form negation.]

## Verification corrections

[Any corrections made to the roster entry during profiling, or "None — roster entry confirmed accurate"]
```

### 5.3 `dependent_data` and staleness

The `dependent_data` block is a snapshot, taken at profile-generation time, of roster fields whose subsequent change should invalidate this profile. The state machine compares these values against the current roster row and raises `PROFILE_STALE` on divergence; the A phase must not consume a stale profile.

**Snapshotted fields and divergence rules:**

- `contact_name`, `organisation`, `role` — any change is staleness. A renamed contact, a moved org, or a new role all invalidate the profile's relevance assessment and star rating.
- `date_excluded` — asymmetric. If the snapshot holds a date and the current value is empty, the contact was re-validated after a period of exclusion; treat as stale so P can re-assess. The reverse direction (empty → date) is not staleness; the contact is now `EXCLUDED` and the state supersedes.

If the contact's name, organisation, or role was corrected *during this profile run* (see §4.15), snapshot the corrected values — not the pre-correction values. The snapshot's purpose is to detect *future* drift, not to preserve history.

### 5.4 Excluded contacts have no profile

Per §4.1, §4.2, §4.13 and §4.15, contacts with `date_excluded` set do not receive a profile document. The presence of a profile file is itself a claim that the contact is valid. No `excluded: true` field, no `star_rating: 0`. The roster's `date_excluded` column carries that state.

## 6. Subagent delegation and sequencing

If this procedure is delegated to a subagent, the calling agent must provide:
- The path to this AESOP
- The roster file path and the specific entry to profile
- The segment file path (`rating_rubric`, `discovery_criteria`)
- The campaign context document paths (only those likely to be relevant)
- The profile output directory path

**Sequential social media fetches.** LinkedIn, Facebook, and Instagram fetches must run sequentially, one at a time. Do not spawn concurrent subagents for social media lookups on different targets. Non-social-media research (web search, GitHub, registry lookups) can run concurrently. This rule is the canonical constraint referenced from §4.3, §4.4, and §4.11.

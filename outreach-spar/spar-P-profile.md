# SPAR-P: Profile Building

**Applies to:** AI agents (Sonnet tier) performing the P phase of the SPAR outreach methodology
**Prerequisite reading:** The campaign's angle table (defines what relevance looks like for this campaign) and the SPAR methodology (`spar-methodology.md`, P section)

## 1. When to use this procedure

Use this procedure when you have a roster entry — a name, an organisation, and optionally a LinkedIn URL or other seed data — and need to produce a profile document that the A (Approach) phase can consume. P runs within each S&P iteration on the contacts discovered in that iteration's S phase.

## 2. Inputs

- **Target:** Name, organisation, and whatever seed data the roster contains (LinkedIn URL, role, segment, discovered_via). If the roster entry has no `contact_name`, resolving one is the first task of this phase — see §4.0b. Entries with a blank `contact_name` are P-phase leads, not invalid data.
- **Segment file:** The file (typically `segment.yaml`) that defines the segment's intended outcome and the mechanism by which contacts are expected to deliver it. Read this before anything else. It determines whether a contact type is structurally valid for the segment — independent of their domain relevance, seniority, or star rating.
- **Campaign angle table:** The list of angles defined by the campaign plan, with descriptions of when each applies. Read this before profiling — it defines what "relevant" means for this campaign.
- **Campaign context documents:** The campaign plan names specific documents (mission statement, project pages, segment definitions) that explain the campaign's offering. Read the angle table first; read context documents only for angles that seem relevant to the target.
- **LinkedIn lookup method:** Use the LinkedIn skill or MCP available in your environment. Read its documentation before the first fetch in a session — it specifies sequencing constraints and any parsing scripts.

## 3. Output

A markdown file named `{stem}.md` in the campaign's `profiles/` directory, where `{stem}` is the roster row's `stem` column value. The file opens with a YAML front-matter block carrying machine-read fields, followed by a markdown body. Structure defined in §5 below.

Additionally, P produces:
- **Roster updates:** If the target's role, organisation, or contact details have changed or were missing and are now known, update the roster entry directly (see §4.11).
- **New names:** If profiling surfaces names not already in the roster, add them to the roster with `discovered_via` pointing to the target being profiled and `discovery_source` describing how they were found (e.g. "LinkedIn post commenter", "co-admin of Facebook group", "named in FOSSASIA Summit post").

## 4. Procedure

### 4.0b Resolve contact name (run before §4.0 when roster has no contact_name)

If the roster entry has no `contact_name`, the organisation has been discovered by sweep but no individual has been identified. This step must be completed before §4.0 can proceed.

**Name discovery sources, in order:**

1. **Company website** — About, Team, or Contact pages often name the owner or manager.
2. **Facebook** — Small operators frequently maintain their primary presence here. Search for the company name; check the About section and any "Run by" attribution. Use the Facebook skill if available.
3. **LinkedIn** — Search for the company; check the People section for the managing director or owner. Use the LinkedIn skill if available.
4. **ABN registry** — For sole traders and small Pty Ltd companies, the ABN Lookup may name an individual.
5. **Yellow Pages, TrueLocal, Google Maps reviews** — Reviews and listings sometimes name the owner.
6. **Web search** — `"[company name]" owner OR director OR founder OR operator`.

**If a name is found:**
- Update `contact_name` in the roster.
- If the entry had `date_excluded` set **solely because it lacked a contact name**, clear `date_excluded` and re-run §4.0 (the structural validation check). The entry may be revalidated if it passes §4.0.
- If `date_excluded` was set for a structural reason (contact type does not fit the campaign mechanism), finding a name does not revalidate the entry — the structural reason stands.

**If no name is found after exhausting all sources:**
- If the roster entry has no `stem`, write one using the organisation slug (e.g. `a-team-coaches` for "A-Team Coaches"). This ensures the row is identifiable in the state machine.
- Record in `p_note`: "name search attempted [date]: no individual identified via website, Facebook, LinkedIn, ABN, web search."
- Set `date_excluded` to today with reason "name search exhausted ([date])." This is the P-phase's responsibility — sweep does not set `date_excluded` for entries whose individual was never identified.
- Do not proceed to §4.0 or produce a profile document. The roster entry is the permanent record.

### 4.0 Validate fit against segment file

Before any research, read the segment file and answer one question: can this contact deliver the outcome the segment describes, through the mechanism the segment describes?

This is a structural check, not a relevance check. A contact may be in the right domain, at the right seniority, with strong apparent fit — and still be the wrong type of contact for the segment. The segment file specifies a mechanism: the particular way a contact is expected to act on the campaign's behalf. The check is whether this contact operates through that mechanism. A contact who is adjacent to the mechanism — who knows the right people, or works in the same field, or whose platform could theoretically be adapted — does not pass the check unless the segment file explicitly includes that adjacent role.

If the contact cannot deliver the outcome through the mechanism the segment describes, set `date_excluded` to today's date and record the reason in `p_note`. Do not proceed to §4.1. Do not produce a profile document.

**Do not delete the roster row.** The roster is append-only. Deletion causes re-discovery in the next sweep, where the entry may be incorrectly validated if the profile stage repeats the same error. The `date_excluded` date is the permanent record that this contact was assessed and excluded.

If an invalid entry has already passed Profile and reached the approach queue, the failure is at the P stage. The question to ask is whether the segment file was specific enough to make the §4.0 check possible. If the exclusion was not obvious from the segment file, the segment file may need a discovery_criteria section that names the contact types that do not belong, so future sweeps and profile runs do not repeat the error.

### 4.1 Fetch and parse the LinkedIn profile

If the roster provides a LinkedIn URL, fetch and parse it. If no URL is provided, search for the person by name and location first, identify the correct profile, then fetch it.

Use the LinkedIn skill or MCP available in your environment. If neither is available, use whatever headless browser tooling is configured locally — do not hardcode paths here; consult your local `CLAUDE.md` or equivalent configuration document for browser binary, profile directory, and required flags.

**From the parsed profile, extract:**
- Current role and organisation
- Full career history with dates
- Education (degrees, certifications, current study)
- Volunteer and mentorship roles
- Location

### 4.1b Fetch and parse the Facebook profile

Run this step after §4.1, sequentially — do not fetch LinkedIn and Facebook concurrently.

Use the Facebook skill or MCP available in your environment. Consult your local configuration document for browser and session details.

The purpose of this step is twofold: (1) verify the person found is the same individual as on LinkedIn, and (2) collect details not available on LinkedIn, in particular current workplace, community affiliations, and recent activity. Fetch both the main profile page and the About page.

**Verification:** Before recording any data, confirm the match. A match requires at least two corroborating signals: same name, same location (city/region), same employer as other sources, or profile photo consistent with other known images. If the match cannot be confirmed, record "Facebook: no verified match found" in the profile and do not use unverified data.

**If match confirmed, extract:**
- Current workplace and role (often more current than LinkedIn)
- Location
- Community groups or pages they admin or follow (relevant to campaign angles)
- Any public posts relevant to the campaign

**Important:** LinkedIn's DOM parser sometimes returns category labels (e.g. "Startup") rather than company names, and when a person lists multiple roles at the same organisation, the parser may present them as separate entries. Cross-reference roles by date overlap and description content to identify entries that belong to the same organisation. If a "Co-Founder" entry describes a crowdfunding platform and a "Business Development Manager" entry is at "Startup" during the same period, these are almost certainly the same company.

### 4.2 Keyword search for campaign-relevant terms

Run keyword searches on the saved HTML using the terms from the campaign's angle table. This determines which angles have direct evidence and which do not.

Use the keyword-search tool from the LinkedIn skill or MCP in your environment, passing the saved profile HTML and the keyword list.

**Choose keywords from two sources:**

1. **Campaign angle table keywords.** For each angle in the table, derive 2–4 search terms. For example, if the angle is "certification gap" and the description mentions "provenance, SLSA, Sigstore, supply chain attestation," search for those terms. If the angle is "network / connection value," search for names of organisations and communities the campaign wants to reach.

2. **Profile-derived keywords.** After parsing the profile, note organisations, projects, and people mentioned. Run a second keyword search for these to extract context (what the target said about them, how they are connected). This is the step that surfaces connections — not the initial parse.

Run multiple rounds of keyword search if needed. The first round checks campaign relevance. The second round chases threads found in the first (e.g. if the first round finds "FOSSASIA" 24 times, the second round searches for specific people and partner organisations mentioned in FOSSASIA context).

### 4.3 Research the target's employer

Visit the website of the target's current employer (and previous employer if the current role is recent — under 12 months). Convert fetched HTML to plain text before processing — see SPAR-S §11 "Context management for web page fetching" for the method. Note:
- The organisation's mission statement and focus areas
- Programmes, labs, working groups, or convenings the organisation runs — especially those that involve external stakeholders, policymakers, or industry participants
- Named leaders (the target's direct supervisor or programme director)
- Any institutional assets that create campaign-relevant access (e.g. the employer runs policy education for government staff, or convenes industry standards discussions, or operates a conference series)

This step is critical for targets whose personal public statements are limited but whose institutional position creates value. A junior programme officer who has written one relevant article may appear low-value if assessed on personal statements alone, but may be high-value if their employer runs a technology policy education programme for lawmakers. The A phase needs the institutional context to frame the outreach correctly — as an institutional proposition rather than a personal one.

If the employer's website reveals programmes or focus areas relevant to the campaign, record them in a dedicated section of the profile document ("Institutional context" or similar, under the domain-specific operational context section). Note which programmes the target is personally involved in versus which are run by their team or organisation more broadly.

### 4.4 Check email history (IMAP)

Before profiling public sources, check whether the campaign's organisation has prior correspondence with this contact. The campaign plan specifies which email accounts to search (e.g. admin and director IMAP accounts).

**Search each account for:**

- The contact's email address (if known) — search by `from` field
- The contact's full name — search by `subject` field (as a proxy; full-text body search may not be available on all mail servers)
- The organisation name — search by `subject` field

**Record in the profile document:**

- Whether prior correspondence exists (yes/no per account)
- If yes: dates, topics discussed, any commitments made, and direct quotes from the contact that reveal what they care about
- The warmth level this implies (see table below)

| Level | Criteria |
|---|---|
| Existing relationship | Substantive prior correspondence across multiple threads, or CRM records prior bookings |
| Prior contact | Brief or one-off correspondence (enquiry, event RSVP, introduction) |
| Known-of | No direct correspondence, but discovered via a mutual connection, shared network, or industry event |
| Cold | No prior contact, no shared context |

**Update the roster:** Add IMAP findings to `p_note` so the A phase knows the warmth level without re-querying email. Example: `warm (director IMAP: discussed coach access Nov 2025)` or `cold (no IMAP history)`.

This step is critical because warmth level determines how the A phase opens the message. A contact with prior correspondence gets a thread-referencing opener; a cold contact gets a situational opener. If this step is skipped, the A phase cannot distinguish between the two.

### 4.4a Source contact email

Skip if the roster `email` field already contains a valid, unmasked address (has `@` and does not contain `*`). Otherwise, search in order:

1. Organisation website contact/about/team page (§4.3 already visited the site)
2. Web search: `"{contact name}" "{organisation}" email`
3. Industry directories: ABN Lookup, Yellow Pages, TrueLocal
4. Pattern guess + verify: construct `firstname@domain` from the contact name and the organisation's website domain, then web-search the guessed address in quotes. Data-broker sites (ZoomInfo, RocketReach) often confirm or mask real addresses — a masked result like `s***@domain.com` that matches the guess validates the pattern. Also check `whois` for the domain's email convention.

Never write a masked or redacted email address (e.g. `b***@example.com`) to the roster. If a data-broker result is masked and the unmasked form cannot be verified, leave the field empty. The post-profile guardrail will blank any masked email that slips through.

If found, check whether the name associated with the email (from the email prefix, contact page, or directory listing) matches the roster contact. If it does not — e.g. roster says "Jess" but the contact page email is `athena@example.com` — treat this as a §4.11 "Person vs. company" trigger: investigate who currently runs the business before writing the email to the roster.

If the email passes both the format gate (§4.11) and the name check, write to roster via sqlite3 (§4.11 method). If not found, record in `p_note`: "email search attempted [date]: no public email found."

### 4.5 Web search for public activity beyond LinkedIn

Search for the target's name plus campaign-relevant terms, excluding LinkedIn:

```
"[Full Name]" [campaign topic keywords] [current year OR previous year]
"[Full Name]" [organisation name]
```

This catches conference talks, blog posts, published papers, media quotes, and GitHub activity that do not appear on LinkedIn. If nothing turns up, note "no public activity found beyond LinkedIn" — the absence is informative for yield.

### 4.6 Record what the target has said publicly

For each substantive public statement found (LinkedIn posts, blog posts, conference talks, tweets, mailing list messages), record:
- The quote or close paraphrase
- The source (LinkedIn post, blog URL, conference name and year)
- What it reveals about the target's concerns, positions, or interests

When the target has published an article or given a talk, extract specific recommendations, proposals, or calls to action — not just the general argument. "Wrote about XZ" is less useful to the A phase than "recommended SBOMs as industry standard and called for a partnership model among OSS communities, enterprises, and federal agencies." These specifics are the hooks the A phase uses to connect the target's stated views to the campaign's offering. A summary that captures the framing but omits the concrete proposals strips out the most actionable material.

Do not invent or infer statements. If the target has not said anything about a topic, record that absence explicitly: "No public statements on [topic]." This prevents the A phase from fabricating a connection that does not exist.

### 4.7 Record who the target knows

From LinkedIn posts (names mentioned or tagged), profile connections visible in the parse, and web search results, identify people connected to the target who are relevant to the campaign. For each:
- Name and their role/organisation
- How they are connected to the target (tagged in post, co-organiser, commenter, co-admin)
- Why they are relevant to the campaign (bridges to a target community, works at a target organisation, holds a relevant role)

This is where the "network / connection value" angle is assessed. A target may have said nothing about the campaign's technical themes but may know people and communities the campaign needs to reach. The connections table is evidence for this angle.

**New names for the roster:** Any person found in this step who is not already in the roster and who is relevant to the campaign (by role, organisation, or community membership) should be added to the roster as a new contact. Record `discovered_via` as the target being profiled and `discovery_source` as the specific mechanism (e.g. "tagged in LinkedIn post about FOSSASIA Summit 2024").

After completing all social media fetches for the current target, profile each newly added contact immediately by spawning a P subagent — do not defer to a future sweep, which may never run. The sequential constraint in §7 applies: do not run social media fetches concurrently. If the seed data for a new contact is insufficient to produce a meaningful profile (name only, no organisation or role), write the roster entry and accept it will not be profiled in this session.

### 4.7a Cross-reference people already in the system

When profiling surfaces a name — a replacement, a predecessor, a person previously in the current target's role, a connection whose background is relevant — grep the campaign's profiles directory and roster for that name before continuing.

```bash
grep -ril "PERSON NAME" /path/to/profiles/ /path/to/roster.tsv
```

If the person is already in the system:

- **They have a profile:** Update that profile to record the new information. Examples: "this person was replaced at [org] by [target] as of [date]" (useful for inferring the departing person's industry experience); or "this person is the predecessor of [target] at [org], whose background may inform [target]'s approach." Prior industry experience — especially if the person came from the operator side of the same industry — changes the register of any approach written for them. A profile that records only the current role and misses a relevant predecessor role causes the A phase to write to a stranger who already speaks the trade's language.
- **They are in the roster but have no profile yet:** Note in the current profile that the cross-reference exists. The next P run for that contact will pick it up.

Do not touch approach files. Approach regeneration in response to a cross-reference update is a graph-type transition that the batch pipeline does not currently handle — see SmartLayer/aesop#4.

### 4.8 Identify applicable angles

Read the campaign's angle table. For each angle, assess whether the profile provides evidence for it:
- **Direct evidence:** The target has said or done something that maps to this angle. Quote the evidence.
- **Indirect evidence:** The target's role, connections, or education suggest relevance, but they have not stated it publicly. Note the inference and flag it as indirect.
- **No evidence:** Nothing in the profile connects to this angle.

Order the applicable angles by strength of evidence. The primary angle is the one with the strongest evidence. If no technical angle has direct evidence but the target has strong connection value, "network / connection value" becomes the primary angle.

For each applicable angle, note:
- The specific ask it implies (working group participation, advisory board, membership, introductions, conference partnership)
- Whether the ask is a cold open (requires the conversation to surface interest) or a warm open (can reference something the target has already said)

### 4.9 Assign ratings

**Star rating (0–5):** How interesting is this contact to the campaign? Assigning this rating is P's responsibility. Any value already in the roster's `star_rating` column was written before profiling and must be ignored — it carries no authority. Derive the rating solely from what profiling reveals.

| Rating | Criteria |
|---|---|
| 5 | Direct evidence of engagement with the campaign's core themes, OR occupies a network position that connects to multiple high-value targets or communities the campaign cannot reach otherwise |
| 4 | Strong fit by role, geography, and network position; indirect evidence of relevance; plausible connection path |
| 3 | Right role and area, no specific evidence of alignment or connection value |
| 2 | Tangentially relevant, weak connection path |
| 1 | Roster only, no clear relevance |
| 0 | Invalid — not a campaign target. Set `date_excluded` to today's date and write the reason in `p_note`. Do not delete the row (see §4.0). |

If profiling reveals that the contact cannot deliver the campaign's intended outcome through the mechanism the goal assumes — including cases where §4.0 was not run before profiling began — set `star_rating` to 0 and `date_excluded` to today's date. Write the reason in `p_note`. Do not produce a profile document for contacts assessed at 0; the roster entry is sufficient. This is distinct from a 1-star rating: a 1-star contact is targetable if band processing reaches that level; a 0-star contact is excluded.

Note that network/connection value can support a 5-star rating when the connection paths are specific and high-value (e.g. bridges to a target community the campaign has no other path into), not merely when the person has a large network.

**Write `star_rating` in two places: the profile front matter (`star_rating:`) and the roster TSV column.** The profile is the authorial home — it is where P records the assessment and where git history preserves it across later roster edits. The TSV column is the query-optimised copy used by the state machine, band filters, and progress counts. Both must be written by the same P run; `sqlite3` updates the roster row in-place. `response_likelihood` is set by the A phase, not P; do not write it here.

### 4.10 Record profile yield

Count substantive data points. The following all qualify as data points: (a) public statements with extractable quotes, (b) specific recommendations or proposals the target has made, (c) career history entries that demonstrate relevant domain experience (e.g. cybersecurity crisis communications background at a consultancy), (d) current institutional context that creates campaign-relevant access (e.g. employer runs policy education programmes for government staff, or operates a technology convening series), (e) named connections relevant to the campaign, (f) recent activity indicating current engagement (posts, conference appearances, publications within the past 12 months). Do not count only quoted public statements — a target who has said little publicly but whose employer operates a programme directly relevant to the campaign has more data points than a narrow reading would suggest.

Record the count as `yield: N` in the profile front matter. Downstream consumers derive behaviour from the count; thresholds belong in the A-phase AESOP, not here. For guidance, common A-phase practice has been: yield ≥ 6 supports up to 3 rounds of A1/A2 sparring; yield 3–5 supports 1 round; yield < 3 implies A2 sparring adds little value. These thresholds live with A, not with P — P reports the count, A decides how to use it.

### 4.11 Check for verification corrections

Compare what the profile reveals against what the roster entry says. If any of the following has changed, update the roster:

- The person has left the organisation listed in the roster
- Their role title is different from what the roster says
- Their location has changed
- Contact details (email, LinkedIn URL, Facebook URL) are incorrect — update the wrong value

**Backfill empty contact fields.** If the roster entry has a blank `email`, `linkedin_url`, or `facebook_url` and profiling discovers a value for it, that is not a correction — it is a backfill, and it is equally required. For `email` specifically, §4.4a runs a dedicated search earlier in the procedure; this backfill clause covers emails discovered incidentally during later steps (§4.5 web search, §4.7 connections) that §4.4a did not find. The sweep phase often finds only a phone number; the profile phase researches the person and their organisation in depth and routinely surfaces emails (from company websites, directories, ABN records) and social URLs (from Facebook pages, LinkedIn search) that the sweep did not capture. These must be written back to the roster, not left only in the profile prose.

**Email format gate.** Before writing any value to the `email` column, verify it contains an `@` sign with a plausible user@domain shape. Contact form URLs (`via website...`), phone numbers, placeholders (`[email obtained during call]`), and descriptive text are not email addresses and must not be written to the email field. If the only contact method found is a web form or phone number, record it in `p_note` instead. This gate matches the §10 check 4 validation rule (spar-S-search.md) and prevents non-email strings from inflating downstream progress counts.

For each empty contact field where a value was discovered, update the roster using `sqlite3`.

Only backfill emails that belong to the contact or their organisation. An email discovered for a different person mentioned in the profile (e.g. a successor, a co-admin) belongs in that person's roster row, not this one.

**Shared-inbox rule.** Before writing an email, check whether the same address is already carried by another row in this segment at the same organisation. If it is, do not write the duplicate and do not overwrite the other row. Research for a non-shared alternate — a personal mailbox, a direct-dial address, a `firstname@` form — and write that. If no non-shared alternate can be found, leave this contact's `email` field empty; the approach will proceed via LinkedIn, phone, or (if no reachable channel remains) be excluded per §4.4a. A single shared inbox (`admin@`, `info@`, `hello@`, `grow@`, etc.) must belong to at most one roster row per organisation, because two outreach emails landing in the same inbox on behalf of two different people reads as bulk outreach, not considered correspondence. The runtime post-validator (`roster_shared_inbox_collision`) will reject the second write and re-prompt for this rule.

If the person has left the relevant role entirely (e.g. left the industry, retired), mark the roster entry with `date_excluded` and the reason, then search for their replacement at the same organisation. The replacement enters the roster as a new contact with `discovered_via` recording they were found as a replacement.

If after §4.4a the entry still has no email, no `linkedin_url`, and no `facebook_url`, the contact is unreachable through any messaging channel. Mark the roster entry with `date_excluded` and reason "no reachable channel ([date])." Do not produce a profile document. Phone-only contacts are not excluded here — they continue via the phone path (state-machine `has_phone_only`).

**Person vs. company:** Ask whether the campaign wants this person or the person currently in this role at this company. If the answer is the role — which is true for most contacts discovered via directories or company listings — and profiling shows someone else now holds it, the roster entry is wrong. Invalidate it, add the current person, and do not pass the displaced entry to the A phase. Delete any existing profile for them; git history preserves it.

Record all corrections and backfills in the profile document under a "Verification corrections" section so the change history is traceable.

## 5. Profile document structure

A profile file has two parts: a YAML **front matter** block (machine-read) and a markdown **body** (read by the A-phase agent and by humans).

### 5.1 Front matter

Delimited by `---` fences at the very top of the file, standard Jekyll/Hugo/Pandoc convention. All listed fields are required; the validator rejects files with missing or unknown keys.

```yaml
---
profile_date: 2026-04-12            # ISO date this profile was generated
star_rating: 4                      # 1–5; 0 never appears here (excluded contacts have no profile — see §4.0, §4.0b, §4.9)
yield: 7                            # integer — substantive data points counted per §4.10
warmth_finding: cold                # existing | prior | known-of | cold — IMAP-derived per §4.4
applicable_angles:                  # ordered by strength of evidence per §4.8; slugs only, evidence stays in the body
  - certification-gap
  - network-connection-value
dependent_data:                     # snapshot of roster fields whose change invalidates this profile (see §5.3)
  contact_name: Kara Struckman
  organisation: Wilson Center
  role: Director, Environmental Change and Security Program
  date_excluded: null
---
```

**Field ownership.** `profile_date`, `star_rating`, `yield`, `warmth_finding`, `applicable_angles` are P-authored at profile generation time. They are not copies of roster values — they are the authorial record of P's assessment. If the roster is later hand-edited, git history of this profile preserves what P originally decided.

**What is *not* in the front matter.** Approach-time decisions (`channel`, chosen `angle`, `sender`, `language`, `response_likelihood`) belong in the approach YAML, authored by A. Contact channels (`email`, `linkedin_url`, `facebook_url`, `phone`) belong in the roster TSV. Do not duplicate them here.

### 5.2 Body

The body is prose that the A-phase agent reads to select an angle and draft a message. Section order is fixed; the validator does not check body content, but A-phase readers expect this layout.

```markdown
# Profile: [Full Name]

## Prior correspondence (IMAP)

[Summary of IMAP findings per account, or "No prior correspondence found in any account". Evidence for `warmth_finding`.]

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

[Repeat for each substantive statement]

**Absent themes:** [Explicit list of campaign-relevant topics the target has NOT spoken about]

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| ... | ... | ... |

## [Domain-specific operational context, if applicable]

[e.g. "FOSSASIA operational role" — only include if the target has operational experience relevant to the campaign that does not fit in the career history table]

## Relevance assessment

**What they have NOT said:** [Summary of absent themes and what this means for angle selection]

**What IS relevant:** [Numbered list of relevance dimensions, with specific evidence for each]

## Angles (ordered by fit)

1. **[Primary angle]** ([primary/secondary/tertiary]) — [Assessment with specific evidence. State the ask this angle implies.]

2. **[Secondary angle]** — [Assessment]

[Continue as needed]

## Verification corrections

[Any corrections made to the roster entry during profiling, or "None — roster entry confirmed accurate"]
```

### 5.3 `dependent_data` and staleness

The `dependent_data` block is a snapshot, taken at profile-generation time, of roster fields whose subsequent change should invalidate this profile. The state-machine compares these values against the current roster row and raises `PROFILE_STALE` on divergence; the A phase must not consume a stale profile.

**Snapshotted fields and divergence rules:**

- `contact_name`, `organisation`, `role` — any change is staleness. A renamed contact, a moved org, or a new role all invalidate the profile's angle assessment.
- `date_excluded` — asymmetric. If the snapshot holds a date and the current value is empty, the contact was re-validated after a period of exclusion; treat as stale so P can re-assess. The reverse direction (empty → date) is not staleness; the contact is now `EXCLUDED` and the state supersedes.

If the contact's name, organisation, or role was corrected *during this profile run* (see §4.11), snapshot the corrected values — not the pre-correction values. The snapshot's purpose is to detect *future* drift, not to preserve history.

### 5.4 Excluded contacts have no profile

Per §4.0, §4.0b, §4.9 and §4.11, contacts with `date_excluded` set do not receive a profile document. The presence of a profile file is itself a claim that the contact is valid. No `excluded: true` field, no `star_rating: 0`. The roster's `date_excluded` column carries that state.

## 6. Guidance for avoiding common errors

**Do not infer statements the target has not made.** If the target works at AI Singapore, that does not mean they have expressed views on AI governance. Record the role; do not manufacture a quote.

**Do not conflate LinkedIn category labels with company names.** The DOM parser may return "Startup" or "Company" as a label rather than the actual organisation name. When you see a generic label, check whether another role entry at overlapping dates describes the same organisation in more detail. Merge them.

**Do not rate network value based on connection count alone.** "500+ connections" is not evidence of connection value. Connection value requires specific, named paths to communities or organisations the campaign needs to reach, visible in the target's posts, tagged connections, or co-organiser roles.

**Do not skip the absent-themes section.** The A phase needs to know what the target has NOT said, so it does not write a message that assumes an interest the target has not expressed. A profile that lists only positive findings invites the A phase to fabricate relevance.

**Do not skip education programmes that suggest policy or governance interest.** A degree in International Relations, Public Policy, Law, or similar programmes is a signal that the target thinks about the policy dimension of their technical work. This is indirect evidence for angles like "jurisdiction" or "cross-border licensing" and should be recorded even though it is not a public statement.

**Record how you found each connection.** "Named in FOSSASIA Summit post" is traceable. "Appears to know" is not. The A phase and the human reviewer need to verify connection claims, and they can only do so if the source is recorded.

## 7. Subagent delegation

If this procedure is delegated to a subagent, the calling agent must provide:
- The path to this AESOP
- The roster file path and the specific entry to profile
- The campaign angle table path
- The campaign context document paths (only those likely to be relevant)
- The profile output directory path

Social media profile fetches (LinkedIn, Facebook, Instagram) must run sequentially, one at a time. Do not spawn concurrent subagents for social media lookups on different targets. Non-social-media research (web search, GitHub, registry lookups) can run concurrently.

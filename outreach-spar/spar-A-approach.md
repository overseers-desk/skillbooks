# SPAR-A: Approach (draft + separate-agent spar)

**Applies to:** AI agents (Opus tier) performing the A phase of the SPAR outreach methodology. "A" means draft then spar, where the spar is a context-cleared separate agent, not self-review within the drafting agent.
**Prerequisite reading:** The profile document for the contact being approached, the campaign plan (defines segments, approach sequencing, and angle tables), and the SPAR methodology (`spar-methodology.md`, A section).

## 1. When to use this procedure

Use this procedure when the S&P prong is complete (or the human has approved early engagement), the contact has a profile document, and the campaign is ready to begin outreach. A processes contacts in bands ordered by response likelihood, as defined in the methodology. A produces drafts for human review; it does not send messages. The director approves, edits, or rejects every draft before anything is sent.

## 2. Inputs

- **Profile document:** The full profile produced by SPAR-P for this contact.
- **Roster entry:** The contact's row in the roster TSV, including `s_note`, `p_note`, `star_rating`, and `response_likelihood`. These two rating columns are the single source of truth — do not duplicate them in the approach file.
- **Campaign plan:** Defines segments, approach sequencing per segment, and campaign-specific rules (language, collateral prerequisites, channel preferences).
- **Segment goal file:** Specifies the approach type (FAM invitation, phone call, personal email, etc.) and any collateral prerequisites. Read this before drafting.
- **Communication index:** `comms-index.md`, the running index of all prior A outputs. Read this before drafting to find cross-references, shared connections, and angles already used with related contacts.
- **Strategy revision notes:** If this is not the first AR band, read the most recent `strategy-revision-[band].md` for revised angle priorities and messaging guidance from R.

## 3. Outputs

- **Approach file:** `{id}-{slug}.yaml` in the campaign's approach directory, following the schema in `approach-schema-proposal.yaml`. The ID uses a segment prefix and sequential number (e.g. `TOR-001-peter-myers-pineapple-tours.yaml`). Contains the angle selection rationale, all A1/A2 drafts and responses, chosen USP identifiers per round, and the final send-ready messages.
- **Communication index entry:** One line appended to `comms-index.md`: contact name, organisation, segment, angle used, key relationship hooks, channel selection.
- **Roster update:** Populate the `a_note` column with: angle used, channel selected, warmth level, language, and any notable drafting consideration.

## 4. Procedure

### 4.0 Confirm target validity

Before drafting, verify that this contact is a valid campaign target:

1. Check the roster: `star_rating` must be ≥ 1 and `date_found_invalid` must be empty. If either condition fails, skip this contact.
2. Read the profile's angle assessment. If the profile states or implies the contact should not be approached (e.g. "not a Phase 1 contact", "deferred", "competing operator"), do not draft. Instead: set `star_rating` to 0, set `date_found_invalid` to today's date, write the reason in `a_note`, and move to the next contact.
3. If `star_rating` is 1 or 2, request explicit human confirmation before proceeding. Low-star contacts rarely justify the drafting cost.

This gate exists because A is the first point where profile content and campaign goals are jointly evaluated. P assesses relevance to the campaign in general; A assesses whether a specific approach is viable. A contact may pass P's filter but fail A's — for example, a strategically interesting person for whom no viable first-touch exists.

### 4.1 Read warmth level from the profile

The P phase has already assessed prior correspondence and assigned a warmth level (see SPAR-P §4.4). Read it from the profile document and from `p_note` in the roster.

| Level | Opener style |
|---|---|
| Existing relationship | Reference the specific prior interaction: date, topic, what was discussed. |
| Prior contact | Reference the specific touchpoint without overstating the relationship. |
| Known-of | Reference the shared context: a mutual connection, a shared network, or a specific event. |
| Cold | Open with their situation, not a compliment. No pretence of a relationship that does not exist. |

When a first-channel contact (e.g. a connection request) is accepted before the follow-up message is sent, the follow-up can acknowledge the connection naturally — the contact is no longer fully cold. This warm transition is a reason to use a multi-channel sequence rather than a single message.

If the profile does not contain a warmth assessment, flag it for the human. Do not guess.

### 4.2 Select channel

Read the segment goal file for the prescribed approach type. Then check what channels are available in the roster (email, linkedin_url, facebook_url, phone, etc.) and whether email is verified.

Channel selection rules, in priority order:

- **Connection channel + verified email + phone:** Prepare three pieces in sequence: (1) connection message, (2) email after the connection is accepted or after 4–5 days, (3) phone follow-up if the email gets no reply after 3 days.
- **Verified email + phone, no connection channel:** Email first, phone follow-up if no reply after 3 days.
- **Verified email only:** Email only.
- **Connection channel, no verified email:** Connection message only, with slightly more context than usual since there is no email follow-up.
- **Phone only:** Phone script as primary, plus a follow-up email template to send once an address is obtained. This is the only scenario where phone is the first touch.
- **No verified channel:** Flag for human resolution.

The approach file includes all pieces for the selected combination. Sequencing and timing between pieces (days to wait, conditions to trigger each step) follow methodology rules and are not restated per contact.

### 4.3 Select language

The default language is English. The campaign plan may specify language rules based on the contact's background and the sender's capability. When a non-default language is used, the A2 spar also runs in that language — the simulated recipient responds as they actually would. Record the language decision and its rationale in the approach file's `decisions` block.

### 4.4 Read the profile and select the angle

Read the full profile document. Then:

1. **Note what the contact has said publicly.** These are the hooks: specific statements, positions, or activities that connect their situation to the campaign's offering.
2. **Note what the contact has NOT said.** The absent-themes section of the profile exists to prevent fabricating relevance. Respect it throughout drafting.
3. **Read the angles from the profile.** P has already ordered them by evidence strength. Select the primary angle and record the rationale in the approach file.
4. **Cross-reference the communication index.** If a related contact (same organisation, network, or segment) has already been approached, use a compatible angle — not identical, but consistent, so the campaign's voice does not contradict itself across contacts who may compare notes.

### 4.5 Draft the message (A1)

Write the connection message, email, or phone script using the profile, warmth level, selected angle, and channel.

**The core principle: presuppose the recipient's world, don't narrate it.**

Do not tell recipients what they do for a living, recite their history back to them, or signal "I did my homework" as a separate display. They can tell you understand their world from the specificity of your proposition. This rule does not apply to introducing yourself — a cold recipient has never heard of you and you must say who you are and what you offer.

**Element ordering — ask before justification:**

A first-touch message has three elements: (a) self-introduction, (b) the concrete ask, and (c) supporting evidence. The default order is a→b→c: introduce yourself, make the ask, then give the recipient reasons to say yes. Front-loading the proposition lets the reader decide whether to keep reading before encountering the evidence. Depart from this order only when the angle genuinely requires context before the ask makes sense.

**USP selection:**

Read the campaign's USP document (declared in the campaign YAML as `usp_document`). Select the USPs relevant to this contact's segment and angle — typically 1–3. Record the identifiers (not the wording) in `chosen_usps` for this round. The wording lives in the USP document; only the selection belongs in the approach file.

**Subject line:**

Every subject line must contain at least one element specific to this recipient, distinguishing it from every other subject line in the campaign. A keyword tied to the recipient's activity is the strongest differentiator. The organisation or brand name serves the same purpose when the activity is generic. A geographic anchor works when proximity is the angle. The person's name is a last resort: it deduplicates without adding attention value.

**Writing principles:**

Use dependency grammar: keep connected words close together. Short dependency distances eliminate parenthetical asides and nested clauses without effort.

Anti-patterns to avoid in all drafted messages:

- **No em-dashes.** Dependency-grammar rewriting removes most of them. If one remains, use a comma or a new sentence.
- **No "it's not X, it's Y" constructions.** Say what it is.
- **No "I'd love to..."** Say what you want directly.
- **No "synergy", "explore", "touch base", "circle back", "leverage".** These signal a template.

**Other principles:**

- If prior correspondence exists, open with the thread. It is a stronger opener than anything constructed from scratch.
- Credentials belong in supporting clauses, not their own paragraph.
- The ask must be concrete enough that the recipient can say yes or no in one sentence.
- Across a band, vary message structure. If openers read as a pattern, something has gone wrong.
- Every factual claim about the campaign's offering must be traceable to a source document and field. Record this in `fact_provenance`. If you cannot name the source, do not include the claim.

### 4.6 Spar the message (A2) — separate agent, not self-review

A2 tests whether the draft would land well with the recipient and whether it contains factual errors. A2 must run as a separate agent process with its own context — not as self-review within the A1 agent.

**A2 is mandatory for all contacts.** Thin profiles need sparring more than rich ones: less evidence means more room to hallucinate relevance. Rounds are budgeted by profile richness:

- **Rich** (6+ data points): up to 3 rounds
- **Medium** (3–5 data points): 1 round
- **Thin** (<3 data points): 1 round

Spawn one subagent (C2) to perform two sequential steps. Use a Sonnet-class model — less capable models shift behaviour more authentically under persona instructions.

**Step 1 — Role-play (context-isolated).** C2 receives only the profile and the draft. No campaign files, no method files. C2 reacts in character as the recipient — a stranger who has never heard of the sender. No rubric, no structured format: a natural reaction. If the message is in a non-default language, C2 responds in that language.

**Step 2 — Fact-check.** C2 breaks character and reads the campaign's source files (USP document, goal file, offering description). It checks every factual claim in the draft and appends corrections. Do not cite file paths in corrections — state what the source says.

The two steps must be sequential: role-play before fact-check, so source-file knowledge does not contaminate the persona.

A1 reads both steps. If C2 identifies a misalignment or a factual error, A1 revises and the round repeats. Record all drafts and C2 responses in the approach file — the human needs to see how the message evolved.

### 4.7 Assemble and validate the approach file

Write the approach file as `{id}-{slug}.yaml` following the schema in `approach-schema-proposal.yaml`. Before presenting for human review, validate the file against the schema and confirm:

- All required fields are present.
- `chosen_usps` is populated for each draft and final round.
- `fact_provenance` covers every factual claim in the final draft.
- `roster_note` is complete and ready to copy to `a_note`.

Read the campaign YAML for the sender address and BCC address. These are not stored in the approach file — they are resolved at send time.

### 4.8 Update the roster and communication index

**Roster:** Copy `roster_note` from the approach file into the `a_note` column of the roster TSV.

**Communication index:** Append one line to `comms-index.md`: contact ID, name, organisation, segment, angle used, key relationship hooks, channel selection.

## 5. Band processing

A processes contacts in bands ordered by response likelihood, as defined in the methodology. Within each band:

1. Order contacts by star rating (highest first).
2. Process sequentially, not in parallel. Each approach file may inform the next.
3. After the band is complete, the human reviews all drafts, approves/edits/rejects each one, and sends approved messages.
4. After responses arrive, the human writes the strategy revision note for the next band.

Read the latest strategy revision note before starting each new band. It may change angle priorities, tone guidance, or the ask.

## 6. Approach file structure

Approach files are YAML documents following the schema in `approach-schema-proposal.yaml`, which is the single source of truth for field definitions, provenance rules, and lifecycle tracking fields (`actioned_date`, `replied_date`, `reply_summary`). Read the schema before producing any approach file.

The file ID uses a segment prefix and sequential number: `TOR-001-peter-myers.yaml`. Place it in the campaign's approach directory.

## 7. Quality checklist

Before presenting an approach file for human review:

1. **Presupposition test.** Does any sentence tell the recipient something they already know about themselves? If so, restructure.
2. **Manufactured-connection test.** Is every claim of shared interest traceable to a specific profile data point? Check against the absent-themes section.
3. **Concreteness.** Can the recipient answer the ask in one sentence?
4. **Channel character limits.** Where the channel imposes a character limit (e.g. 300 characters for a LinkedIn connection note), verify compliance.
5. **Band-level pattern check.** Read the openers of all messages in the band sequentially. If they sound like variations of the same template, revise.

## 8. Segment-specific approach types

The segment goal file defines the approach type for each segment. Common patterns across campaigns:

- **FAM invitation:** An invitation to experience the offering firsthand. The ask is a visit date, not a commitment.
- **Personal email with collateral:** A short message with attached or linked materials. The collateral must exist before the message is sent.
- **Meeting request:** A request for a consultative conversation, typically referencing an existing organisational relationship.
- **Exhibitor or participation enquiry:** An enquiry to an organiser about joining their event or programme.
- **Interest gauge:** An open question — "Is this something your group does?" — used when no booking history exists to validate the fit.

Do not default to a generic email when the goal file prescribes a specific format.

## 9. Subagent delegation

Point the subagent at this file, the profile document, the roster entry, the campaign plan, and the communication index. Include the current band parameters and the latest strategy revision note if applicable. Do not transcribe SPAR-A content into the prompt — reference the file path.

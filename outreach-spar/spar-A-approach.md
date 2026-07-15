# SPAR-A: Approach (draft + separate-agent spar)

**Applies to:** AI agents (Opus tier) performing the A phase of the SPAR outreach methodology. "A" means draft then spar, where the spar is a context-cleared separate agent, not self-review within the drafting agent.
**Prerequisite reading:** The profile document for the contact being approached, the campaign plan (defines segments, approach sequencing, and angle tables), and the SPAR methodology (`spar-methodology.md`, A section).

## 1. When to use this procedure

Use this procedure when the S&P prong is complete (or the human has approved early engagement), the contact has a profile document, and the campaign is ready to begin outreach. A processes contacts in bands ordered by response likelihood, as defined in the methodology. A produces drafts for human review; it does not send messages. The director approves, edits, or rejects every draft before anything is sent.

## 2. Inputs

- **Profile document:** The full profile produced by SPAR-P for this contact.
- **Roster entry:** The contact's row in the roster TSV, including `s_note`, `p_note`, and `star_rating`. `star_rating` is P-owned: the roster row is its authoritative home, read from there. The roster carries campaign-independent population data only; A's outputs (`response_likelihood`, `a_note`) are written to the approach file, not the roster (see §4.8 and §6).
- **Campaign plan block:** The segment's entry under `segments:` in `campaign.yaml` — the objective, USP framings, `message_goal`, `first_ask`, `conversion_funnel`, and `approach_sequencing` for this segment, including the approach type (FAM invitation, phone call, personal email, etc.) and collateral prerequisites. Read this before drafting. The dispatcher passes the campaign YAML path and the segment key.
- **Segment file:** (`segment.yaml`) The population definition — `discovery_criteria`, `scope_note`, `rating_rubric`. Consult for boundary and rating context. The per-campaign plan now lives in the campaign plan block above, not here.
- **Communication index:** `comms-index.md`, the running index of all prior A outputs. Read this before drafting to find cross-references, shared connections, and angles already used with related contacts.
- **Strategy revision notes:** If this is not the first AR band, read the most recent `strategy-revision-[band].md` for revised angle priorities and messaging guidance from R.

## 3. Outputs

- **Approach file:** `{id}-{slug}.yaml` in the segment's `approach/` directory (the contact's communications log; the directory name is historical, see `spar-methodology.md`). The structure is shown in §6. The ID uses a segment prefix and sequential number (e.g. `TOR-001-peter-myers-pineapple-tours.yaml`). Contains the angle selection rationale, all A1/A2 drafts and responses, chosen USP identifiers per round, and the final send-ready messages.
- **Communication index entry:** One line appended to `comms-index.md`: contact name, organisation, segment, angle used, key relationship hooks, channel selection.
- **Approach-file notes:** Write the `a_note` root key in the approach file with: angle used, channel selected, warmth level, language, and any notable drafting consideration. Set the `response_likelihood` root key to the estimated reply probability under the chosen angle. These are A's outputs and live in the approach file, not the roster.

## 4. Procedure

### 4.0 Confirm target validity

Before drafting, verify that this contact is a valid campaign target:

1. Check the roster: `star_rating` must be ≥ 1 and `date_excluded` must be empty. If either condition fails, skip this contact.
2. Read the profile's angle assessment. If the profile states or implies the contact should not be approached (e.g. "not a Phase 1 contact", "deferred", "competing operator"), do not draft. Instead: set `star_rating` to 0 and `date_excluded` to today's date in the roster, record the reason in the approach file's `a_note` (a minimal approach file with no draft rounds is fine — the exclusion is the outcome), and move to the next contact.
3. If `star_rating` is 1 or 2, request explicit human confirmation before proceeding. Low-star contacts rarely justify the drafting cost.

This gate exists because A is the first point where profile content and campaign goals are jointly evaluated. P assesses relevance to the campaign in general; A assesses whether a specific approach is viable. A contact may pass P's filter but fail A's — for example, a strategically interesting person for whom no viable first-touch exists.

### 4.1 Determine the warmth level

Warmth is engagement state, not profile content (INVARIANTS.md I1; SPAR-P §4.7): it changes between campaigns and the first message sent falsifies it, so A determines it fresh at contact time. Assess it from the contact's approach file (prior rounds and replies, if any) and a current IMAP check for prior correspondence with the sender's accounts. The dispatcher prefetch (§4.1.1) supplies the IMAP evidence.

| Level | Opener style |
|---|---|
| Existing relationship | Reference the specific prior interaction: date, topic, what was discussed. |
| Prior contact | Reference the specific touchpoint without overstating the relationship. |
| Known-of | Reference the shared context: a mutual connection, a shared network, or a specific event. |
| Cold | Open with their situation, not a compliment. No pretence of a relationship that does not exist. |

When a first-channel contact (e.g. a connection request) is accepted before the follow-up message is sent, the follow-up can acknowledge the connection naturally — the contact is no longer fully cold. This warm transition is a reason to use a multi-channel sequence rather than a single message.

If the evidence is contradictory (the approach file and the IMAP record disagree about prior contact), flag it for the human. Do not guess.

### 4.1.1 Reply-vs-new-thread decision

If the warmth is `existing` or `prior` and the contact still has a live email thread on a topic compatible with the campaign offer, replying on that thread keeps the message in the recipient's existing inbox conversation, preserves any cc'd parties, and signals continuity. A fresh subject from a long-quiet contact reads as a cold approach even when it is not.

Apply the rule below; on the false branch, default to a fresh subject.

- **Reply on the existing thread when** warmth ∈ {existing, prior} AND a current thread exists in the dispatcher prefetch AND the contact's roster email (or a same-domain colleague address — admin/partnerships/director, etc.) appears in that chain.
- **Otherwise** open a new subject with an optional in-body reference to the prior touchpoint.

If frequent prior correspondence already establishes that the contact knows the sender, a fresh subject is acceptable — the recipient will recognise the sender regardless. The reply-on-thread rule matters most for sparse or long-quiet relationships where a new subject would read as cold.

**Parent-thread selection.** When several candidate threads exist, pick the most recent message in the most-substantive thread, where substantive means the largest message count combined with recency. The dispatcher prefetch (`courier -A search ... --format text`) groups hits by date; cluster mentally by stripping `Re:`/`Fwd:` prefixes and matching the participant set within a 30-day window.

**Capturing the parent.** The dispatcher prefetch carries an `id:` line per hit (the parent's Message-ID) — that alone is enough to thread the reply. To capture the rest of the threading state for the approach YAML, run a single `courier --imap <ACCOUNT> read -f <FOLDER> -u <UID>` on the chosen parent and record `message_id`, `references`, `subject`, `from`, `to`, `cc` into the message's `parent` block (see §6). Subject and Cc are derived at send time from those fields; the message itself only carries the body.

### 4.2 Select channel

Read the campaign plan block (the segment's entry under `segments:` in `campaign.yaml`) for the prescribed approach type. Then check what channels are available in the roster (email, linkedin_url, facebook_url, phone, etc.). An email is usable when the `email` column contains a deliverable `user@domain` value (the §4.8 format gate); masked or placeholder values do not count.

Channel selection rules, in priority order:

- **Connection channel + email + phone:** Prepare three pieces in sequence: (1) connection message, (2) email after the connection is accepted or after 4–5 days, (3) phone follow-up if the email gets no reply after 3 days.
- **Email + phone, no connection channel:** Email first, phone follow-up if no reply after 3 days.
- **Email only:** Email only.
- **Connection channel, no email:** Connection message only, with slightly more context than usual since there is no email follow-up.
- **Phone only:** Phone script as primary, plus a follow-up email template to send once an address is obtained. This is the only scenario where phone is the first touch.
- **No reachable channel:** Flag for human resolution.

The approach file includes all pieces for the selected combination. Sequencing and timing between pieces (days to wait, conditions to trigger each step) follow methodology rules and are not restated per contact.

**Verify the email at source for LinkedIn contacts.** When the contact is a LinkedIn connection, or before relying on an `email` value that was pattern-derived rather than confirmed, run the LinkedIn contact-info lookup (the `linkedin.com/contact-info` skill verb) to read the member's self-listed email. Prefer the shared address over a pattern guess: a guessed address often reaches the wrong inbox or a generic one, while the shared address is what the member chose to publish. A newly found address is written back to the roster (§4.8). If the lookup returns no shared email, fall back to the best address on file and mark it unverified in the approach `a_note`.

### 4.3 Select language

The default language is English. The campaign plan may specify language rules based on the contact's background and the sender's capability. When a non-default language is used, the A2 spar also runs in that language — the simulated recipient responds as they actually would. Record the language decision and its rationale in the approach file's `decisions` block.

### 4.4 Read the profile and select the angle

Read the full profile document. Then:

1. **Note what the contact has said publicly.** These are the hooks: specific statements, positions, or activities that connect their situation to the campaign's offering.
2. **Note what the contact has NOT said.** The absent-themes section of the profile exists to prevent fabricating relevance. Respect it throughout drafting.
3. **Derive the angles.** The profile carries no angle list (angles are campaign-bound; INVARIANTS.md I1). Construct candidate angles from the profile's `## Relevance assessment` and evidence sections together with the campaign plan's angle table, order them by evidence strength, select the primary angle, and record the rationale in the approach file.
4. **Cross-reference the communication index.** If a related contact (same organisation, network, or segment) has already been approached, use a compatible angle — not identical, but consistent, so the campaign's voice does not contradict itself across contacts who may compare notes.

### 4.5 Draft the message (A1)

Write the connection message, email, or phone script using the profile, warmth level, selected angle, and channel.

**The core principle: presuppose the recipient's world, don't narrate it.**

A cold reader registers your understanding of their world through the specificity of the proposition you bring. Recited history and "I did my homework" gestures occupy that space without supplying any specificity, so the reader gets the performance of research instead of its product. Introducing yourself and what you offer is a separate matter: that is presenting your world to them, not narrating theirs.

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

**A2 is mandatory for all contacts.** Low-yield profiles need sparring more than high-yield ones: less evidence means more room to hallucinate relevance. Passes are budgeted by profile yield:

- yield ≥ 6: up to 3 passes
- yield 3–5: 1 pass
- yield < 3: 1 pass

Spawn one subagent (C2) to perform two sequential steps. Use a Sonnet-class model — less capable models shift behaviour more authentically under persona instructions.

**Step 1 — Role-play (context-isolated).** C2 receives only the profile and the draft. No campaign files, no method files. C2 reacts in character as the recipient — a stranger who has never heard of the sender. No rubric, no structured format: a natural reaction. If the message is in a non-default language, C2 responds in that language.

**Step 2 — Fact-check.** C2 breaks character and reads the campaign's source files (USP document, segment file, offering description). It checks every factual claim in the draft and appends corrections. Do not cite file paths in corrections — state what the source says.

The two steps must be sequential: role-play before fact-check, so source-file knowledge does not contaminate the persona.

A1 reads both steps. If C2 identifies a misalignment or a factual error, A1 revises and the pass repeats. Record all drafts and C2 responses in the approach file — the human needs to see how the message evolved.

### 4.7 Assemble the approach file

Write the approach file as `{id}-{slug}.yaml` following the structure shown in §6. Run the §7 quality checklist before presenting for human review.

The default sender and BCC address come from the campaign YAML (`sender.name`, `sender.email`, `sender.bcc`) and do not need to be written into the approach file. Write a `decisions.sender` block only when this specific outreach should go from someone other than the campaign's default sender — e.g. a colleague with a prior relationship to the contact. When present, `decisions.sender.email` (and optional `sender.name`) overrides the campaign sender for this contact; per-message `bcc` / `cc` likewise override `sender.bcc`. All of this is resolved by the T3 dispatcher at send time.

### 4.8 Update the communication index

`a_note` and `response_likelihood`, like the messages, are engagement-tier and campaign-bound: write them into the approach file (§6), never the roster.

**Contact-detail backfill (the one roster write A makes).** A contact detail is population-tier, not engagement: a verified email, or a corrected or newly found `linkedin_url` / `facebook_url`, is the same fact for any campaign, so its home is the roster. When A discovers one at send time (typically a member's shared email from the §4.2 contact-info lookup), A writes it back to `roster.tsv`, the same backfill P performs (`spar-P-profile.md`, "Backfill empty contact fields"). A backfilled email must pass the same gates P uses: the format gate (an `@` with a plausible `user@domain` shape; no masked, placeholder, or non-email value), the name-mismatch check, and the shared-inbox rule (all in `spar-P-profile.md`). This contact detail is the only thing A writes to the roster; everything campaign-bound stays in the approach file.

**Communication index:** Append one line to `comms-index.md`: contact ID, name, organisation, segment, angle used, key relationship hooks, channel selection.

## 5. Band processing

A processes contacts in bands ordered by response likelihood, as defined in the methodology. Within each band:

1. Order contacts by star rating (highest first).
2. Process sequentially, not in parallel. Each approach file may inform the next.
3. After the band is complete, the human reviews all drafts, approves/edits/rejects each one, and sends approved messages.
4. After responses arrive, the human writes the strategy revision note for the next band.

Read the latest strategy revision note before starting each new band. It may change angle priorities, tone guidance, or the ask.

## 6. Approach file structure

Approach files are YAML documents with a **closed vocabulary** — any key outside the set below is rejected by the runtime validator (`spar::validate_approach` in `spar-manager/spar-validate.tcl`). The validator emits plain-language errors such as `unknown key 'X' at <level>` or `'X' at <level> belongs at <other_level>`.

**Canonical keys by level:**

- Root: `decisions`, `rounds`, `angle_rationale`, `response_likelihood`, `a_note`, `r_note`, `fact_provenance`, `quality_checklist`, `profile_hash`
- `response_likelihood`: integer percentage (0–100), A's estimate of reply probability under the chosen angle, used for band ordering. It is the campaign-dependent counterpart to the segment's `star_rating` (general value to us): change the ask and this changes, which is why it lives here, not on the roster. `a_note`: A's one-line summary for R (angle, channel, warmth, language). `r_note`: the human reviewer's per-contact observation after responses arrive (what worked, new leads, channel adjustment); empty until R fills it. All three are campaign-bound and live here, not in the segment roster.
- `profile_hash`: `sha256:<64-hex>` — SHA-256 of the profile file's bytes at generation time, prefixed `sha256:`. Computed by the A harness; A copies the value verbatim. Optional in the schema: manually-authored approaches and any path that did not read a profile have no hash to record. **When present, this key must be on the first line of the file** — no leading blank line, no preceding keys (issue #63). The position discipline lets a future fast-classify path detect staleness by reading only the first line; `validate_approach` emits `profile_hash_misplaced` if the rule is broken. When the hash is present and the profile exists, mismatch is an error (`profile_hash_mismatch`) — the source profile was rebuilt or edited, and the approach must be regenerated. When the hash is absent, `validate_approach` accepts the file and the state machine routes any divergence (deleted / edited profile) through T6/T7 instead.
- `decisions`: `channel`, `language`, `angle`, `sender`, `channel_detail`, `subsegment`. Populate `sender` (with `name` and `email`) only when this contact should be emailed by someone other than the campaign's default sender; otherwise omit the block. At T3 send time the dispatcher uses `decisions.sender.email` in preference to `sender.email` from the campaign YAML. See §4.7. Warmth is determined fresh by A (§4.1) and informs the drafting; it is not a stored field.
- `round`: `type` (draft/review/final), `number`, `messages`, `verdict`, `fact_check`, `in_character`, `chosen_usps`, `revision_note`, `notes`, `replies`, `antifact_check`
- `message`: `channel`, `subject`, `body`, `to`, `actioned_date`, `replied_date`, `reply_summary`, `script`, `text`, `char_count`, `bcc`, `cc`, `director_note`, `to_note`, `phone_note`, `mode`, `parent`, `reply_all`
- `parent` (only inside a `mode: reply` message): `account`, `folder`, `uid`, `message_id`, `references`, `subject`, `from`, `to`, `cc`. Captured verbatim from `courier read` on the parent message; T3 derives In-Reply-To, References, the `Re:` Subject, and the To/Cc set from these fields at send time.
- `mode` on a `channel: linkedin` message: `invite` (connection request with the message as the note, ≤300 characters) or `dm` (direct message to an existing 1st-degree connection). When absent, the send dispatcher infers `invite` for text within 300 characters and `dm` otherwise; write it explicitly so the choice is the author's, not an inference.
- `fact_provenance` / `fact_check` items: `claim`, `source` (plus `result`, `note`, `correction` for `fact_check` only)
- `script` items (inside a message): `point`, `text`

**Structural rules:** At least one round must have `type: final`. Draft and review rounds require `number`. Ordinary email messages must have `subject` or `body`. Reply-mode messages (`mode: reply`) need only `body` — the Subject is derived from `parent.subject` — and must carry a non-empty `parent.message_id` so T3 can construct the threading headers.

**Example skeleton — terse, but covers every canonical key so you never need to invent one:**

```yaml
profile_hash: sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
decisions:
  channel: email
  channel_detail: Email primary, phone fallback.
  language: en
  angle: shared-venue-history
  sender:
    name: Director
    email: director@example.com
  subsegment: boutique-operator
angle_rationale: Why this angle fits this contact.
response_likelihood: 75
a_note: Angle, channel, warmth, language, and any notable drafting consideration (A's one-line summary for R).
r_note: ""   # R (human) fills this after responses arrive; empty until then.
rounds:
  - type: draft
    number: 1
    chosen_usps: [U2, U4]
    notes: Draft-stage freeform notes.
    messages:
      - channel: email
        to: recipient@example.com
        cc: colleague@example.com
        bcc: archive@example.com
        subject: Draft subject
        body: |
          Draft body.
        char_count: 412
        director_note: Internal-only guidance about the draft.
        to_note: If the to-address is provisional, explain here.
      - channel: phone
        to: +61-400-000-000
        text: Brief description of the intended call.
        script:
          - point: Opening hook
            text: "Hi — calling from ..."
          - point: Ask
            text: "Would Tuesday work for a site visit?"
        phone_note: Best time to call is Tuesday morning.
  - type: review
    number: 1
    verdict: DONE
    in_character: How the recipient would react in their own voice.
    fact_check:
      - claim: Fact asserted in the draft.
        source: URL or profile reference.
        result: verified
        note: Clarification about the check.
        correction: Amended wording if the claim was wrong.
    antifact_check: Counter-check against manufactured claims.
    revision_note: What changed between draft and final.
    notes: Reviewer-stage freeform notes.
  - type: final
    chosen_usps: [U2, U4]
    messages:
      - channel: email
        to: recipient@example.com
        subject: Final subject
        body: |
          Final body.
        actioned_date: null
        replied_date: null
        reply_summary: Populated after a reply is received.
    replies:
      - direction: received
        date: "2026-04-15T10:00:00"
        from: "Name <email@example.com>"
        body: |
          Reply body (ingested mechanically by spar-email.tcl).
fact_provenance:
  - claim: Fact asserted somewhere in the file.
    source: URL or profile reference.
quality_checklist: Notes on §7 checks passed or flagged.
```

Lifecycle fields (`actioned_date`, `replied_date`, `reply_summary`) are written by the dispatcher and reply-ingest stages — start them as `null` (or omit). Entries under `replies` are ingested by `spar-email.tcl`; its item shape (`direction`, `channel`, `date`, `from`, `body`) is mechanical, not part of the AI-authored vocabulary. `channel` names the channel the reply arrived on; the inbox ingest writes `email`, a manually recorded reply names its own.

**Reply-mode email skeleton** (issue #79). When the §4.1.1 rule selects reply-on-thread, the final email message replaces `subject` and `to` with a `parent` block carrying the captured threading state:

```yaml
rounds:
  - type: final
    chosen_usps: [U2]
    messages:
      - channel: email
        mode: reply
        reply_all: true
        body: |
          Following up on the Chef requirement we discussed in August.
          ...
        actioned_date: null
        replied_date: null
        parent:
          account: admin-rivermill-au
          folder: "[Gmail]/All Mail"
          uid: 34937
          message_id: "<CADxn=...example.com>"
          references:
            - "<earlier-thread-root@example.com>"
          subject: Requirement of Chef
          from: Andrew Kerby <andrew@chefsontherun.example>
          to: director@rivermill.au
          cc: ""
```

Omit `subject`/`to` from the message when `mode: reply` is set — T3 derives them. `reply_all: true` preserves the original Cc set (minus the chosen sender's own address); `reply_all: false` (default) replies to the parent's From only.

The file ID uses a segment prefix and sequential number: `TOR-001-peter-myers.yaml`. Place it in the segment's `approach/` directory.

## 7. Quality checklist

Before presenting an approach file for human review:

1. **YAML structure self-check.** The dispatcher runs `spar::validate_approach` automatically post-assembly; if the file is malformed it loops you back with the exact errors. Do **not** invoke `tclsh`, `spar::validate_approach`, or any validator subprocess yourself — `tclsh -c` is not a valid flag and the call blocks indefinitely on stdin, which wedges the whole harness chain. Your self-check is mental: root keys drawn from §6's canonical set; every round has `type` and `number`; the `final` round contains ≤1 `channel: email` message; email addresses are real (not placeholders). Campaign-wide validation is reported separately by `spar-progress.tcl`.
2. **Required fields.** All required fields are present: `chosen_usps` populated for each draft and final round, `fact_provenance` covers every factual claim in the final draft, `a_note` is complete.
3. **Presupposition test.** Does any sentence tell the recipient something they already know about themselves? If so, restructure.
4. **Manufactured-connection test.** Is every claim of shared interest traceable to a specific profile data point? Check against the absent-themes section.
5. **Concreteness.** Can the recipient answer the ask in one sentence?
6. **Channel character limits.** Where the channel imposes a character limit, verify compliance. A LinkedIn message with `mode: invite` (or no `mode`) is a connection note capped at 300 characters, measured on the trimmed text the dispatcher sends; either shorten it or declare `mode: dm` when a direct message to a 1st-degree connection is intended. A recorded `char_count` states the measured length; omit it rather than guess. Enforced by `validate_approach` (`linkedin_note_too_long`, `char_count_mismatch`).
7. **Band-level pattern check.** Read the openers of all messages in the band sequentially. If they sound like variations of the same template, revise.
8. **Final round email cardinality.** The `final` round contains at most one message with `channel: email`. Sequential email follow-ups belong in subsequent rounds; additional recipients belong in `cc`/`bcc`. Multi-channel finals (e.g. one email + one phone) are fine — the cap is on emails only. Enforced by `validate_approach` (`too_many_final_emails`).

## 8. Approach types

The campaign plan block (the segment's entry under `segments:` in `campaign.yaml`) defines the approach type for each segment. Common patterns across campaigns:

- **FAM invitation:** An invitation to experience the offering firsthand. The ask is a visit date, not a commitment.
- **Personal email with collateral:** A short message with attached or linked materials. The collateral must exist before the message is sent.
- **Meeting request:** A request for a consultative conversation, typically referencing an existing organisational relationship.
- **Exhibitor or participation enquiry:** An enquiry to an organiser about joining their event or programme.
- **Interest gauge:** An open question — "Is this something your group does?" — used when no booking history exists to validate the fit.

Do not default to a generic email when the plan block prescribes a specific format.

## 9. Subagent delegation

Point the subagent at this file, the profile document, the roster entry, the campaign plan, and the communication index. Include the current band parameters and the latest strategy revision note if applicable. Do not transcribe SPAR-A content into the prompt — reference the file path.

# SPAR-A: Approach (draft + separate-agent spar)

**Applies to:** AI agents (Opus tier) performing the A phase of the SPAR outreach methodology. "A" means draft then spar, where the spar is a context-cleared, separate agent (not self-review within the drafting agent).
**Prerequisite reading:** The profile document for the contact being approached, the campaign plan (defines segments, approach sequencing, and angle tables), and the SPAR methodology (`spar-methodology.md`, A section)

## 1. When to use this procedure

Use this procedure when the S&P prong is complete (or the human has approved early engagement), the contact has a profile document, and the campaign is ready to begin outreach. A processes contacts in bands ordered by response likelihood, as defined in the methodology.

A produces drafts for human review. A does not send messages. The director approves, edits, or rejects every draft before anything is sent.

## 2. Inputs

- **Profile document:** The full profile produced by SPAR-P for this contact.
- **Roster entry:** The contact's row in the roster TSV, including s_note, p_note, star_rating, and response_likelihood. These two rating columns are the single source of truth — do not duplicate them in the comms file.
- **Campaign plan:** Defines segments, approach sequencing per segment (which goal file to consult), and any campaign-specific rules (language, collateral prerequisites, channel preferences).
- **Segment goal file:** Each segment has a goal file that specifies the approach type (FAM invitation, phone call, personal email, etc.) and the collateral sequencing (approach first vs. collateral required). Read the relevant goal file before drafting.
- **Communication index:** `comms-index.md`, the running index of all prior A outputs. Read this before drafting to find cross-references, shared connections, and angles that have already been used with related contacts.
- **Strategy revision notes:** If this is not the first AR band, read the most recent `strategy-revision-[band].md` for revised angle priorities and messaging guidance from R.

## 3. Outputs

- **Communication log:** `ID-contact-name-org-comms.md` in the campaign's comms directory. Contains the profile summary, angle selection rationale, all A1/A2 drafts and responses, and the final draft messages (LinkedIn note + email, or email only, or phone script, depending on channel selection). The ID uses a segment prefix and sequential number (e.g. `TOR-001-peter-myers-pineapple-tours-comms.md`).
- **Communication index entry:** One line appended to `comms-index.md`: contact name, organisation, segment, angle used, key relationship hooks, channel selection.
- **Roster update:** Populate the `a_note` column with: angle used, channel selected, warmth level, and any notable drafting consideration. This lets R scan a band's results from the roster without opening every comms file.
- **Draft messages for human review:** The final LinkedIn connection note and/or email, clearly separated and labelled, ready for the director to approve, edit, or reject.

## 4. Procedure

### 4.0 Confirm target validity

Before drafting, verify that this contact is a valid campaign target:

1. Check the roster: `star_rating` must be ≥ 1 and `date_found_invalid` must be empty. If either condition fails, skip this contact.
2. Read the profile's angle assessment. If the profile states or implies the contact should not be approached (e.g. "not a Phase 1 contact", "deferred", "competing venue"), do not draft. Instead: set `star_rating` to 0, set `date_found_invalid` to today's date, write the reason in `a_note`, and move to the next contact.
3. If `star_rating` is 1 or 2, request explicit human confirmation before proceeding. Low-star contacts rarely justify the drafting cost; the human may prefer to skip or re-profile.

This gate exists because the A phase is the first point where profile content and campaign goals are jointly evaluated. P assesses the contact's relevance to the campaign in general; A assesses whether a specific approach is viable. A contact may pass P's filter but fail A's — for example, a strategically interesting person (high star from P) for whom no viable first-touch exists.

### 4.1 Read warmth level from the profile

The P phase has already checked IMAP and assigned a warmth level (see SPAR-P §4.4). Read it from the profile document's "Prior correspondence (IMAP)" section and from `p_note` in the roster.

| Level | Opener style |
|---|---|
| Existing relationship | Reference the specific prior interaction: date, topic, what was discussed. |
| Prior contact | Reference the specific touchpoint without overstating the relationship. |
| Known-of | Reference the shared context: "We're both in [network]" or "I saw your talk at [event]." |
| Cold | Open with their situation, not a compliment. No pretence of a relationship that does not exist. |

Note: when a LinkedIn connection is accepted before the email is sent, the email opener can acknowledge the connection naturally. The contact is no longer fully cold. The LinkedIn step exists precisely to create this warmth transition.

If the profile does not contain IMAP findings (e.g. profiled before this step was added), flag it for the human. Do not guess warmth level.

### 4.2 Select channel

The channel is determined by what the contact has and what the segment expects.

**Decision tree:**

1. Read the segment's goal file for the prescribed approach type (FAM invitation, phone call, personal email, etc.).
2. Check what contact channels are available in the roster: email, linkedin_url, facebook_url, phone.
3. Check `verified` status for email.

**Channel selection rules:**

- **If linkedin_url exists and email exists (verified):** Prepare three pieces: (1) LinkedIn connection note sent first, (2) email sent after connection is accepted or after 4–5 days, (3) phone follow-up script if the email gets no reply after 3 days. The LinkedIn note is a handshake. The email carries the substance. The phone call is a gentle follow-up, not a repeat of the email.
- **If email exists (verified) and phone exists but no linkedin_url:** Prepare two pieces: (1) email, (2) phone follow-up script if no reply after 3 days.
- **If email exists (verified) but no phone or linkedin_url:** Email only.
- **If linkedin_url exists but email is unverified or absent:** LinkedIn connection note only. The note carries slightly more context than usual since there is no email follow-up channel.
- **If only phone exists (no verified email, no linkedin_url):** Phone script as primary, with a follow-up email template for after the call (to send once an email address is obtained). This is the only scenario where phone is the first touch.
- **If no verified channel:** Flag for human resolution.

The comms file includes all pieces for the selected channel combination. The full sequence when all channels are available: LinkedIn connection note → email after acceptance or 4–5 days → phone if no email reply after 3 days.

### 4.3 Select language

The default language is English. The campaign plan may define language selection rules based on the contact's background and the sender's language capability.

When the campaign plan specifies that certain contacts should receive messages in a non-default language:

- Draft the message in the specified language.
- The A2 spar (if applicable) also runs in that language. The simulated recipient should respond in the language they would actually use.
- The comms file records the language choice and the rationale.

The language decision is recorded in the comms file and in `a_note` so R can assess whether language choice affected response rate.

### 4.4 Read the profile and select the angle

Read the full profile document. Then:

1. **Note what the contact has said publicly.** These are the hooks: specific statements, positions, or activities that connect their situation to the campaign's offering.
2. **Note what the contact has NOT said.** The absent-themes section prevents fabricating relevance.
3. **Read the applicable angles from the profile.** P has already ordered them by evidence strength.
4. **Cross-reference the communication index.** Has a related contact (same segment, same network, same organisation) already been approached? What angle was used? Did it work? If a prior contact in the same organisation or network responded well to a specific framing, consider using a compatible angle. Not identical, but consistent, so the campaign's voice does not contradict itself across contacts who may compare notes.

Select the primary angle. Record the rationale.

### 4.5 Draft the message (A1)

Write the connection message (LinkedIn note, email, or phone script) using the profile, warmth level, angle, and channel.

**The core principle: presuppose, don't narrate — about the recipient.**

This rule applies to the recipient's own situation: do not tell them what they do for a living, do not recite their company history back to them, do not signal "I did my homework" as a separate display. The recipient can tell you understand their world from the specificity of your proposition, not from being told what they already know.

This rule does NOT apply to introducing yourself or your venue. A cold recipient has never heard of you. You must tell them who you are and what you offer. Omitting self-introduction is not presupposing — it is failing to communicate. The distinction:

- Narrating the recipient (avoid): "Your Springbrook retreats run a residential format."
- Introducing yourself (required): "I run a heritage tourism venue on the Coomera River in the Gold Coast hinterland."

Examples of presupposing (the recipient's situation) vs narrating:

- Narrating: "MAD has been running corporate destination programs across Australia for nearly 30 years."
  Presupposing: "Do any of your multi-city incentive programs include a Gold Coast leg?"

- Narrating: "You mentioned on your site you enjoy discovering new locations."
  Presupposing: "We're inviting a few planners to visit a heritage venue in Gilston they may not have seen."

In each case, the knowledge of the recipient's world is in the ask or the framing, not displayed as a separate element.

**Element ordering — ask before justification:**

Every first-touch email must contain three elements: (a) self-introduction, (b) the concrete ask, and (c) USPs that justify a yes. The default ordering should be a→b→c: introduce yourself, make the ask, then give the recipient the reasons to say yes. This front-loads the proposition so the reader knows what you want before deciding whether to keep reading. The USPs that follow serve as evidence, not preamble.

This is the default, not a rigid rule. When the angle requires context before the ask makes sense (e.g. explaining an event format that does not yet exist), provide that context first. But when the ask is self-explanatory ("Would you consider holding your next event here?"), lead with it immediately after the self-introduction.

**USP selection:**

Not every USP is relevant to every recipient. Select USPs based on what the recipient's segment cares about.

Each campaign declares its USP reference document in the campaign YAML (`usp_document` field). Read the USP list there. Then select 1–3 USPs that connect to the recipient's segment and angle. For example:

- A wedding planner cares about photography circuits, accommodation, and ceremony options — not revenue figures.
- A tour operator cares about group capacity, drive time from the coast, and what the experience includes.
- A community group organiser cares about accessibility, catering for 30+, and whether the venue suits older visitors.

For cold contacts, almost always include the Instagram link (https://rivermill.au/ig, which redirects to the Instagram page with 38,000+ followers). A strong visual presence is the fastest way for a stranger to decide whether the venue is credible. Embed it naturally, not as a bullet point — e.g. "You can see the grounds at rivermill.au/ig" or as a sign-off line.

For warm contacts (prior correspondence, existing relationship), the Instagram link is less important — they may already follow or have visited.

**Subject line — at least one specific element per recipient.**

Every subject line must contain at least one element that distinguishes it from every other subject line in the campaign. Identical subjects across recipients cause Gmail to group unrelated threads, which makes tracking difficult. More importantly, a specific subject signals to the recipient that the email is about them, not a mass send.

The strongest differentiator is a keyword tied to the recipient's activity or offer — "sourdough workshops", "beekeeping", "plein air session" — because it tells the reader the email is about their business. When the activity itself is generic (a group outing is a group outing), the organisation name or brand serves the same purpose — "for Robina Lions", "for HMFC". A geographic anchor works when proximity is the selling point — "your neighbour in 4211", "15 min from Mudgeeraba". The person's name is a last resort: it solves the deduplication problem without adding attention value.

**Other principles to keep in mind:**

- If prior correspondence exists, open with the thread. It is a stronger opener than anything you can construct.
- Credentials belong in supporting clauses, not in their own paragraph.
- The ask should be concrete enough that the recipient can say yes or no in one sentence.
- Keep first-touch messages short. LinkedIn notes have a 300-character hard limit. Emails and phone scripts should be as brief as the angle allows.
- Across a band of contacts, vary the structure. If you read the openers sequentially and they sound like a pattern, something has gone wrong.
- The absent-themes section in the profile exists to prevent you from manufacturing connections the contact has not expressed. Respect it.
- **Fact provenance.** Every factual claim about the campaign's venue, product, or history that appears in a draft must be traceable. In the comms file, annotate each fact with where you learned it: file path and field name, or "general knowledge" if it came from the agent prompt rather than a project file. If you cannot name the source, do not include the claim.

**Writing style for drafted messages:**

Use dependency grammar, not phrase structure grammar. Keep each pair of connected words as close together as possible. Short dependency distances make copy easier to read and naturally eliminate parenthetical asides, nested clauses, and run-on constructions.

Anti-patterns to avoid in drafted messages:

- **No em-dashes.** Never use — (em-dash) in any drafted message. When rewriting dependency-grammar style, most em-dashes disappear because the aside they bracket becomes its own sentence or folds into the main clause. If one remains, try a comma. If a comma does not work, use a hyphen. This is the one hard rule.
- **No "it's not X, it's Y" constructions.** These are a rhetorical device that sounds like copywriting. Say what it is. If the contrast matters, let the reader infer it from context.
- **No "I'd love to..."** Sounds performative. Say what you want directly.
- **No "synergy", "explore", "touch base", "circle back", "leverage".** Corporate filler that signals a template.

### 4.6 Spar the message (A2) — separate agent, not self-review

A2 tests whether the draft would land well with the recipient AND whether the draft contains factual errors. A2 must run as a **separate agent process** with its own context — not as a self-review step within the A1 drafting agent. The drafting agent must not role-play as the recipient; a fresh agent with no campaign context does the role-play. This is what "spar" means in SPAR: an adversarial check by a context-isolated counterpart.

**A2 is mandatory for all contacts.** Thin profiles need sparring more than rich ones — less evidence means more room for the drafter to hallucinate relevance. The number of rounds depends on profile richness:

- **Rich profile** (6+ data points): up to 3 rounds
- **Medium profile** (3–5 data points): 1 round
- **Thin profile** (<3 data points): 1 round (mandatory, not skipped)

**A2 procedure — two-step, single subagent:**

Spawn one subagent (C2) that performs two sequential steps. Use a model suited to persona simulation (e.g. Sonnet-class rather than Opus-class — research indicates less capable models shift behaviour more authentically under persona instructions).

**Step 1 — Role-play (context-isolated).** C2 receives ONLY the profile content and the draft message. No campaign files, no venue files, no method files. C2 reacts in character as the recipient, who has never heard of the sender or their venue. No rubric, no structured "What works / What could be improved" format — just a natural reaction. If the profile is in a non-English language context and the message was drafted in that language, C2 responds in that language.

**Step 2 — Fact-check.** After recording the in-character reaction, C2 breaks character and reads the campaign's source files (USP document, goal file, venue description). It checks every factual claim in the draft email against these sources and appends corrections as: "P.S. I noticed: [claim] — [what the source actually says or that no source exists]." Do not cite file paths or file names in corrections — state what the source says, not where it was found.

The two steps must be sequential within one subagent call. The role-play must complete before the fact-check begins — this prevents source-file knowledge from contaminating the persona simulation.

A1 reads both the role-play reaction and the fact-check corrections. If C2 identifies a misalignment (wrong angle, wrong tone, assumed a concern the contact does not have, used flattery that feels transparent, made an ask that is too vague or too presumptuous) or a factual error, A1 revises.

Repeat until rounds are exhausted or C2 signals the message is credible and factually correct.

Record all drafts and C2 responses (both steps) in the comms file. The human reviewer needs to see how the message evolved, not just the final version.

### 4.7 Assemble the final output

Read the campaign YAML (`campaign*.yaml` in the campaign root) for the sender address and BCC address before assembling output.

**For LinkedIn + email + phone contacts:**

```
## LinkedIn connection note (send first)

[300-character note]

## Email (send after connection accepted, or after 5 days)

From: [sender address per campaign plan]
To: [contact email]
Subject: [subject line]

[Body]

## Phone follow-up (if no email reply after 3 days)

[Key points, not a script. Reference the email: "I sent you an email a few days ago about X, wanted to check if it landed."]
```

**For email + phone contacts (no LinkedIn):**

```
## Email

From: [sender address per campaign plan]
To: [contact email]
Subject: [subject line]

[Body]

## Phone follow-up (if no email reply after 3 days)

[Key points, reference the email briefly, then the ask.]
```

**For phone-first contacts (no verified email):**

```
## Phone script (key points)

1. [Opening: who you are, why you are calling]
2. [The question or proposition, one sentence]
3. [If interested: next step (site visit date, send info sheet)]

## Follow-up email (send after call, once email obtained)

[Short email confirming what was discussed and the agreed next step]
```

### 4.8 Update the roster and communication index

**Roster:** Write a one-line `a_note` summarising: the angle used, the channel selected (LinkedIn+email / email / phone), the warmth level, the language, and any notable consideration. Example: `angle: hinterland-corridor-fit; channel: LI+email; warm (Skål Nov 2025); English`

**Communication index:** Append one line to `comms-index.md`:
```
TOR-001 | Peter Myers | Pineapple Tours | tour-operator-domestic | hinterland-corridor-fit | existing CRM, Tamborine bus route overlap | LI+email
```

## 5. Band processing

A processes contacts in bands, ordered by response likelihood. The band structure is defined in the methodology. Within each band:

1. Order contacts by star rating (highest first) within the response-likelihood band.
2. Process sequentially, not in parallel. Each contact's comms file may inform the next.
3. After the band is complete, the human reviews all drafts, approves/edits/rejects each one, and sends approved messages.
4. After responses arrive, R (human) reviews and writes the strategy revision note for the next band.

Between bands, read the latest strategy revision note before processing the next band. The revision may change angle priorities, tone guidance, or the ask.

## 6. Comms file structure

```markdown
# Approach: [Full Name], [Organisation]

**Contact:** [Name], [Role], [Organisation]
**Band:** AR[n]
**Warmth level:** [existing relationship / prior contact / known-of / cold] (from profile §IMAP)
**Channel:** [LinkedIn + email / email only / phone + follow-up email]
**Language:** [English / other, with rationale]
**Angle:** [Primary angle] ([one-sentence rationale])
**Profile richness:** [Rich/Medium/Thin] ([N] A2 rounds)

Note: sent date is NOT a header field intentionally.

## Angle selection rationale

[Why this angle, referencing specific profile evidence. Why not the alternatives.]

## A1 Draft 1

[First draft of the message(s)]

## A2 Response 1

[C2's in-character response]

## A1 Draft 2 (if applicable)

[Revised draft based on C2 feedback]

[Continue for additional rounds]

## Final draft

### LinkedIn connection note

[Final note, ≤300 characters]

### Email

From: [address]
To: [address]
Subject: [subject]

[Body]

## Roster a_note

[The one-liner that will be written to the roster]
```

## 7. Quality checklist

A quick pass before presenting each comms file for human review:

1. **Presupposition test.** Does any sentence tell the recipient something they already know about themselves? If so, restructure.
2. **Manufactured-connection test.** Is every claim of shared interest traceable to a specific profile data point? Check against the absent-themes section.
3. **Concreteness.** Can the recipient answer the ask in one sentence?
4. **LinkedIn character count.** 300-character hard limit. Verify.
5. **Band-level pattern check.** Read the openers of all messages in the band sequentially. If they sound like variations of the same template, revise.

## 8. Segment-specific approach types

The campaign plan defines which segments use which approach type. A must consult the segment's goal file before drafting. Common patterns:

- **FAM invitation** (inbound tour operators, wedding planners): The message is an invitation to visit, not a sales pitch. The ask is a date for the visit.
- **Personal email with photos** (yoga/wellness): A short email with 2–3 attached or linked photos of the grounds. No PDF, no brochure.
- **Meeting request** (tourism boards): A request for a consultative meeting, referencing an existing relationship (e.g. EGC membership).
- **Exhibitor enquiry** (bridal expos): An enquiry to the expo organiser about exhibitor availability, not an outreach to end consumers.
- **Interest gauge** (new segments with no booking history): An explicit question like "Is this something your group does?", not a pitch.

A must not default to a generic email when the goal file prescribes a different format.

## 9. Subagent delegation

Point the subagent at this file, the profile document, the roster, the campaign plan, and the communication index. Include the current band parameters and the latest strategy revision note if applicable. Do not transcribe SPAR-A content into the prompt. Reference the file path.

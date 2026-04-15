# TEND — Correspondence Processing Methodology

## What TEND is

TEND is a four-phase methodology for processing emails in a director's inbox that fall within categories the taxonomy defines. The name is an acronym:

- **T** — Thread. Assemble the full conversation history for an incoming email before examining it.
- **E** — Evaluate. Classify the email by category and determine what stage the conversation has reached.
- **N** — Notify. Determine what the director needs to see and how urgently. Some emails require no notification at all; others require immediate attention.
- **D** — Dispatch. Execute the decided action: file silently, draft a reply for review, forward to a delegate, or present to the director with context.

TEND is not the only process acting on the inbox, and is not responsible for every email. The director's correspondence is handled by a changing set of agents and methodologies — TEND covers the categories its taxonomy names, and leaves the rest alone. There is no ignore list to maintain, no registry of other agents' scopes to keep in sync. The default disposition for anything outside TEND's taxonomy is: do nothing. Someone else may pick it up, or no one will; that is not TEND's problem to solve.

The domain-specific content — who the correspondents are, what categories exist, what rules govern each category — lives in a taxonomy and ruleset, not in TEND itself.

## The problem TEND solves

Within the categories TEND covers, a naive approach — classify each email independently and apply a category-level rule — produces a predictable failure mode. The AI sees a vendor email and drafts a sales response, not knowing that the vendor has already agreed to terms in the previous message. It sees a staff request and drafts an approval, not knowing that the director declined the same request two days ago. The AI treats every email as if it were the first message in a conversation, because it is the only message the AI has read.

TEND addresses this by making thread assembly the first step, before any classification or action. The agent reads the full conversation before judging what to do with the latest message. This prevents the "shut up and take my money" problem: the agent continues selling to someone who has already said yes, because it never read the part where they said yes.

TEND does not attempt to solve the problem of "every email gets a reply". Many emails in the inbox neither need nor benefit from a reply — a flight confirmation for a trip the director booked, a receipt for a purchase the director authorised, a newsletter the director subscribed to. These are routine, expected, and self-explanatory; the director already has the context the email is confirming. TEND leaves them where they are.

The test for an uncategorised email is whether its content would genuinely surprise the director — not whether the topic is uncovered by a rule. A flight *confirmation* for a trip the director booked is expected and needs no action. A flight *cancellation* on that same trip is unexpected and consequential, and should be surfaced even though the topic (flights) might look routine at first glance. Likewise an unannounced visit from an external stakeholder, an unexpected legal notice, or a safety matter. The judgement is about the content, not the category.

## The four phases

### T — Thread

Thread assembly is the foundation. When a new email arrives, T retrieves every message in the same conversation using the email's References and In-Reply-To headers.

With mu(1), this is `mu find msgid:X --include-related`, which implements the JWZ threading algorithm. The result is deduplicated by message-id (the same email often appears in multiple maildirs — INBOX, Sent Mail, and any forwarded copies) and sorted chronologically.

The output of T is a single document: the complete conversation, oldest to newest, with each message's sender, date, and body. This document is what E reads.

Thread assembly also reveals structural facts before any content analysis:
- How many messages are in the thread (1 = new conversation, 10+ = established relationship)
- Who has spoken and in what order (director → them, them → director, or multi-party)
- How much time has passed since the last message
- Whether the director has already replied to this thread

These structural facts are inputs to E, not just the content of the latest message.

### E — Evaluate

E reads the threaded conversation and produces two judgments:

**Category.** What kind of email is this? The taxonomy (a reference document built from empirical sampling of the director's mailbox) defines the categories. Each category has classification signals — typical senders, subject patterns, body keywords — but the agent uses the taxonomy descriptions as guidance, not as a keyword-matching engine. An email that does not fit any existing category is left untouched by default — TEND stops at E, and N and D do not run. The single exception is when the content would genuinely surprise the director (an unexpected cancellation, an unannounced visit, a safety or legal matter). In that case TEND flags it to the director without drafting a reply. No ignore list is consulted, and no claim on the email by other agents is required: absence of a matching category is itself the disposition.

**Stage.** Where is this conversation in its lifecycle? The stages are:

| Stage | Meaning | How the agent determines it |
|---|---|---|
| opening | First contact, no prior exchange | Thread has 1 message |
| active | Mid-conversation, information or terms being exchanged | Multiple messages, no agreement or conclusion reached |
| awaiting-us | The other party asked a question or made a request; the director has not yet responded | Their message is the most recent; it contains a question, request, or proposal |
| awaiting-them | The director asked a question or made a request; waiting for their reply | Director's message is the most recent; it contains a question or request |
| agreed | Terms settled, execution phase | Thread contains explicit agreement from both parties |
| closed | Matter concluded | Thread contains a closing statement, discontinuance, or final acknowledgement |
| stale | No activity for an extended period | Last message is older than 14 days with no reply from either side |

Stage determines what action is appropriate. A purchase-approval-request in the `opening` stage needs an approval decision. The same category in the `agreed` stage needs execution follow-up, not a second approval. The same category in the `awaiting-them` stage needs nothing — the ball is in their court.

E's output is a structured assessment: category, stage, urgency, a one-line summary of the latest message, and a one-line summary of the thread arc.

### N — Notify

N determines what the director sees and when. It consults the ruleset — a reference document that maps each category to a processing level:

| Level | What happens | Director sees it? |
|---|---|---|
| auto | AI processes without director review (file, label, route) | No, unless escalation trigger fires |
| draft | AI drafts a reply, director reviews before sending | Yes, in review queue |
| flag | AI summarises and surfaces for director attention, no draft | Yes, with urgency marker |
| block | AI must not act; director handles personally | Yes, immediately |

The level comes from the ruleset, but stage modifies it. An email that would normally be `auto` (e.g. a newsletter) might be escalated to `flag` if the thread reveals it contains an actionable venue-hire request buried in a newsletter reply. An email that would normally be `draft` might be downgraded to `auto` if the stage is `closed` and the latest message is a final acknowledgement requiring no reply.

N also determines the notification channel and timing:
- **Immediate**: safety incidents, legal deadlines, board correspondence with time-sensitive content
- **Same-day digest**: draft replies for review, flagged items, uncategorised emails
- **Weekly summary**: auto-processed volumes, stale threads that may need a nudge

### D — Dispatch

D executes the action determined by N:

- **File**: apply a label, move to the appropriate folder, log in the daily summary. No reply.
- **Draft**: compose a reply following the draft guidance in the ruleset. The draft is placed in a review queue. The director reads it, edits if needed, and sends. The AI never sends on its own for draft-level items.
- **Forward/delegate**: route the email to the appropriate team member (admin, estate manager, marketing) with a one-line summary of what action is needed.
- **Flag**: present the email to the director with the E assessment (category, stage, summary) and any context the ruleset says to surface (related threads, project state, prior incidents).
- **Block**: present the email to the director with no AI-generated content attached. The director handles it entirely.

D also updates the conversation record: what action was taken, when, and by whom (AI or director). This record feeds back into future T phases — when the next message in this thread arrives, T can see what was done with the previous one.

## Two-prong structure

Like SPAR, TEND divides into a knowledge-building prong and an operational prong.

**Prong 1: TE (Thread + Evaluate)** is comprehension. It assembles context and produces a judgment. TE is Sonnet-tier work: structured reading, classification against a known taxonomy, and stage detection from conversational cues. TE does not produce any outward-facing output — no replies, no forwards, no notifications. It produces an internal assessment.

**Prong 2: ND (Notify + Dispatch)** is action. It routes the assessment to the director or executes it autonomously. ND has two sub-tiers:
- Auto-level dispatch (file, label, forward) is Haiku-tier work — mechanical execution of a clear instruction.
- Draft-level dispatch (composing a reply) is Sonnet-tier work for routine categories, Opus-tier for categories where tone, relationship nuance, or strategic framing matter (e.g. celebrity partnerships, government relations, tenant apologies).
- Block-level items do not use any model — the director writes the response.

```
New email arrives
    ↓
T — assemble thread (mu --include-related, deduplicate, sort)
    ↓
E — classify category + determine stage (Sonnet reads thread + taxonomy)
    ↓
N — determine notification level (rules lookup, stage-modified)
    ↓
D — dispatch action
    ├── auto: Haiku executes (file / label / forward)
    ├── draft: Sonnet or Opus composes, director reviews
    ├── flag: present assessment to director
    └── block: present email to director, no AI content
```

## Stage-awareness: why T must precede E

The defining architectural choice in TEND is that thread assembly happens before evaluation, not after. This is not an obvious ordering. A simpler system would classify the incoming email by its subject and sender, then retrieve the thread only if needed for context. TEND rejects this because classification without thread context produces systematic errors:

1. **Misstaged action.** A purchase-approval-request in the `agreed` stage should not receive a second "Approved." A wedding inquiry in the `awaiting-them` stage should not receive a follow-up. Without the thread, every email looks like it is in the `opening` stage.

2. **Missed role reversal.** In some threads, the director's role changes. An email from a vendor starts as a sales pitch (cold-inbound-contact), but by message 4 the director has made a counter-proposal and the vendor is now a potential partner (tourism-brand-collaboration). The latest message's category is different from the first message's category. Only the thread reveals the correct current category.

3. **Duplicate action.** If admin has already replied to a customer complaint (visible in the thread), the AI should not draft a second reply from the director. Without the thread, the AI does not know admin has acted.

Thread-first evaluation costs more per email (the agent reads N messages instead of 1) but prevents errors that are more expensive to correct than the cost of reading.

## Artefacts

| Artefact | Created by | Consumed by | Location |
|---|---|---|---|
| Taxonomy (category definitions, signals, action types) | Phase 1 research (empirical sampling) | E (classification) | `email-processing/taxonomy.yaml` |
| Ruleset (processing rules per category) | Phase 2 rule-writing | N, D (level determination, draft guidance) | `email-processing/rules.yaml` |
| Thread document (assembled conversation) | T | E | Ephemeral (per-email processing) |
| Assessment (category, stage, summary) | E | N, D | Logged per email |
| Draft reply | D | Director (review queue) | Draft queue |
| Processing log | D | T (future thread context), reporting | Persistent log |

## Model assignment

| Phase | Model tier | Rationale |
|---|---|---|
| T | None (mu query) | Thread assembly is a database operation, not an LLM task. mu's `--include-related` does the work. |
| E | Sonnet | Classification against a taxonomy with stage detection. The taxonomy does the intellectual heavy lifting; Sonnet applies it. Consistent with the SPAR/SIFT finding that rubric-following is Sonnet-tier. |
| N | None (rule lookup) | Level determination is a table lookup from E's output to the ruleset. No LLM needed. |
| D (auto) | Haiku | Mechanical execution: file, label, forward. No judgment required. |
| D (draft, routine) | Sonnet | Standard reply drafting for internal approvals, acknowledgements, and delegations. |
| D (draft, sensitive) | Opus | Replies requiring relationship nuance, strategic framing, or careful tone management. Celebrity partnerships, government relations, tenant apologies, external partner negotiations. |
| D (block) | None | Director writes the response. The AI's role is to present the email and assessment, not to draft. |

## Relationship to existing artefacts

The taxonomy and ruleset in `email-processing/` were built empirically from 226 emails sampled across 5 batches, covering the full year of director@rivermill.au correspondence. They contain 64 categories and 64 corresponding processing rules. These artefacts are the knowledge base that E and N consult — they are not executable code. TEND defines how an agent uses them; the artefacts define what the agent knows.

The TEND methodology is domain-independent. The taxonomy and ruleset are domain-specific to Rivermill. Applying TEND to a different inbox would require building a new taxonomy (Phase 1: sample, classify, iterate) and ruleset (Phase 2: write rules per category), but the four-phase pipeline and the stage model remain the same.

## Relationship to SPAR

TEND and SPAR operate on the same correspondence but in opposite directions. SPAR generates outbound messages; TEND processes inbound messages. They share a principle — read before writing, understand the person before drafting the message — but apply it to different problems.

Where they intersect: SPAR's Approach phase generates outreach emails that produce replies. Those replies arrive in the director's inbox and are processed by TEND. TEND's stage detection recognises that the reply is part of an active SPAR campaign (the outreach message is in the thread) and can route accordingly — e.g. flagging a positive response for the director rather than filing it as a cold inbound.

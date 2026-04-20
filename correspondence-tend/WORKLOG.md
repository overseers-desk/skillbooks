# TEND — Correspondence Processing Worklog

Methodology: [tend-methodology.md](tend-methodology.md). Rivermill-specific taxonomy and rules: `../../weiwu/email-processing.tend/taxonomy.yaml` and `rules.yaml`. Upstream producer (ingest, threading, entity extraction): [contact-graph worklog](../contact-graph/WORKLOG.md).

---

## Session 1 — Methodology probe against one real arrival

### Why this session

The methodology has been spec'd but never exercised against a real inbox state. Before building a TEND consumer, walk one newly arrived email through the four phases by hand, using the current contact-graph DB plus mu as the data source, and see where the methodology fits and where it does not. Findings that concern the *producer* shape live in the [contact-graph session 7 entry](../contact-graph/WORKLOG.md#session-7--design-probe-what-shape-does-tend-need-from-contact-graph); findings about the *methodology* live here.

### Test case

`5c188793-de65-4047-8c74-77947797ff02@email.android.com` — Casey Armstrong (Drayhorse Shires) → `partnerships@rivermill.au`, 2026-04-17 06:53 AEST. Five-message thread, nine days old, outbound-originated (Lia Movsisyan's Apr 9 SPAR outreach).

Thread arc:
- Apr 9 00:37 UTC — Lia → Casey: cold outreach, horse-drawn carriage supplier for weddings, invitation to visit.
- Apr 9 14:14 AEST — Casey → Lia: enthusiastic yes, asks for a weekday.
- Apr 15 18:26 AEST — Priyanka (`admin@`) → Casey: progress nudge.
- Apr 17 03:45 AEST — Lia → Casey: gives John's number 0481 909 955; asks Casey to call or propose a time.
- **Apr 17 06:53 AEST — Casey → Lia: "Happy for John to call anytime that suits."** ← the arrival under test.

### Methodology application by phase

**T (Thread).** Assembled via `mu find msgid:… --include-related` — five messages deduped and sorted chronologically. Bodies read from maildir with Python's `email` stdlib and plain-text quote-stripping. The methodology's definition of T-output ("a single document … with each message's sender, date, and body") is right; producing that document is a contact-graph job, not a TEND job. This is the main architectural finding of this session.

**E (Evaluate).** Category: `tourism-supplier-partnership`, SPAR-originated sub-type. Stage: `awaiting-us`. The stage call is the methodology's key claim in action: read on its own, Casey's three sentences look like closure (warm, brief, concluding); read in thread, Casey chose "call John" from Lia's two-option offer without proposing a time, which means the outstanding action is on Rivermill's side. A classifier that saw only the latest message would have mis-staged this as `agreed` or `closed`. The methodology's §"Stage-awareness: why T must precede E" is vindicated on this case.

**N (Notify).** Rule lookup against Rivermill taxonomy would assign `draft` for most supplier-partnership replies. Stage modifier downgrades here: the next action is a phone call, not an email, so `draft` is wrong. Correct level is `flag` to John (Estate, `estate@rivermill.au`, `human id=11`), same-day channel, no draft.

**D (Dispatch).** Forward/delegate to John with one-line context: "Drayhorse Shires (wedding carriages) — Casey Armstrong is waiting for your call, any weekday morning. Contact via `info@drayhorseshires.com`." Log the action.

### Findings about the methodology itself

The four-phase pipeline held up on this case. The corrections this session surfaces are at the boundary with the producer, not inside the methodology:

1. **T is a producer deliverable.** The methodology's §T reads as if TEND owns thread assembly, but the work (mu `--include-related`, dedup, sort, body read, quote-strip) is generic and useful to SPAR, reporting, dashboards. It belongs in contact-graph's render surface. The methodology section should be reworded from "TEND does T" to "TEND consumes a T document produced by the producer pipeline".

2. **E needs three signals the methodology does not currently name.** These are computed facts about the graph and thread, not LLM judgements:
   - `prior_interactions` (count of prior threads with this human or domain) — separates cold opener from re-engagement.
   - `initiator_internal` (first message sent from an internal address?) — distinguishes outbound-originated (SPAR) from cold inbound.
   - `inter_message_gap` (time between consecutive messages) — surfaces stalls that may warrant acknowledgement in a draft.

   The methodology mentions "how much time has passed since the last message" and "how many messages are in the thread" as T-phase structural facts, but stops short of the three above. These should be added to the §T "structural facts" list.

3. **The two-prong (TE vs ND) split matches the producer/consumer split.** TE is "read state produced by contact-graph + apply methodology judgement". ND is "act on the judgement". Contact-graph's render surface naturally serves TE; a separate dispatcher (draft queue, forward handler, flag UI) serves ND. The tier assignment (Sonnet for TE, Haiku/Sonnet/Opus for ND) is consistent with this split.

### Open questions

- **Unresolved participant handling.** `info@drayhorseshires.com` has `human_id = NULL` in `email_address`. TEND's N/D may want to ask the producer to create a human record, or route the message to admin to backfill, or proceed with the address-only identity. The methodology does not currently specify.
- **Prior-action log.** §D says "D also updates the conversation record: what action was taken, when, and by whom. This record feeds back into future T phases." There is no such table yet in the producer schema. Where should it live — in contact-graph (as a generic action log) or in TEND (as a TEND-specific log)? The former is reusable; the latter is cleaner separation.

### Artefacts from this session

- This worklog entry.
- Corresponding contact-graph worklog entry: [../contact-graph/WORKLOG.md](../contact-graph/WORKLOG.md) (Session 7).
- No code written.
- No diagram file persisted; the mermaid sketch discussed in-session lives only in the chat transcript.

### Next TEND-side task

Rework §T of [tend-methodology.md](tend-methodology.md) to reflect the producer/consumer split: name the T document as a producer output that TEND consumes, and expand the structural-facts list with `prior_interactions`, `initiator_internal`, `inter_message_gap`. Do this *after* contact-graph has the render surface and the names of the fields are stable.

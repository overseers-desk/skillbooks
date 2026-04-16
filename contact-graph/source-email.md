# Source plugin: email

## 1. Source description

Reads the mu email index. The corpus spans multiple accounts; most addresses are one-off contacts, bulk senders, or automated addresses.

Curation is done by connectivity: contacts with more edges to the user, or who appear on more threads with multiple known contacts, rank higher. The AI tagging pipeline processes in this priority order so the most-connected people are profiled first.

## 2. Stable item ID

Message-ID from email headers. Available as a named field in mu's sexp output.

## 3. Scan strategy

Cursor-based, head-first. Each run processes in two phases:

1. **Head (newest to already-seen).** Start from the latest message in mu's index and work backward until N=3 consecutive Message-IDs are already in the DB. This catches everything mu has indexed since the last run. A message with an old date but a new mu index position (late delivery, restored backup) appears at the head and is caught here.
2. **Tail (oldest known to further back).** Continue from the earliest known boundary and work backward, consuming available processing budget. Stops when the budget is exhausted or the source end is reached.

The task is closed by: (1) head must be fully processed every run, (2) tail processing consumes up to a token/credit budget per run, so available resources are used without exhausting the processing window.

N=3 consecutive already-seen items is the stopping condition for the head phase. It tolerates one missing item without loss of correctness.

The `source_coverage` table stores `newest_scanned_id` and `oldest_scanned_id` per account. The DB's own contents are the truth; the coverage record is a cache to skip re-scanning, not a correctness constraint — losing it forces a re-scan but does not corrupt the graph.

Historical imports (old Gmail takeouts, PST archives) are handled by the tail phase without special case.

## 4. Parse output

From mu sexp format:
- `:from` — sender (one address)
- `:to`, `:cc` — recipients (one or more addresses)
- `:date` — timestamp
- `:subject` — available for AI tagging (not used for graph structure)

The sexp format gives these as named fields, so there is no comma-splitting ambiguity.

## 4b. Body entity extraction

The header parse captures who sent what to whom. The body of an email may also name people not in the headers, reference organisations and projects, discuss business domains, or mention named products. This is the same information that meeting YAML frontmatter captures for meetings; for emails it is extracted by AI and stored in the generic `item_entity` table.

**What is extracted:**

| Entity type | Description |
|-------------|-------------|
| `person_mentioned` | People named in the body who are not the sender or recipients — e.g. "I spoke with John Edwards about this" |
| `organisation` | Companies, agencies, platforms, bodies named in the body — e.g. "Xero is showing the wrong figure" |
| `project` | Named initiatives or efforts referred to — e.g. "the kitchen grant application" |
| `product` | Named assets, offerings, or products discussed — e.g. horses, software products, menu items |
| `domain` | Activity classification from the domain taxonomy (same fixed vocabulary as the meeting plugin) |

**Input to the model:** subject line plus body text (truncated to a reasonable window if long). The prompt requests the same structured fields as the meeting frontmatter schema.

**Quality note:** Email bodies are shorter and more contextual than meeting transcripts; entity extraction is noisier. The `context` field is often blank or low-confidence. Extraction should be treated as soft signal — the same entity appearing across multiple emails to/from the same person strengthens the association.

**When it runs:** As a separate budget-controlled pass, not during harvest. Unprocessed messages are swept in date order (newest first), bounded by a token/cost budget per run. The `email_message` table is the source of truth for what needs processing; `item_entity` records its own `extracted_at` timestamp so the sweep can skip already-processed messages.

**Storage:** Rows go into `item_entity` with `source_kind = 'email'` and `external_item_id = message_id`. When a `person_mentioned` value resolves to a known `human`, the `human_id` FK is populated. Resolution uses the same name-matching logic as meeting participant resolution.

## 5. Identity

Internal addresses — addresses belonging to internal humans (`internal = TRUE` in the `human` table). A message where all participants are internal is excluded from graph edges. The account owner for each mu account is identified by their internal address(es).

Weiwu's addresses:

- zhangweiwu@realss.com
- a@colourful.land
- director@rivermill.au
- me@weiwu.au
- me@weiwu.eu
- me@weiwu.id.au
- amanuensis@weiwu.au
- w@smarttokenlabs.com
- weiwu.zhang@alphawallet.com
- weiwu.zhang@awallet.io
- zhangweiwu@yahoo.com
- zhangweiwu@private.21cn.com (historical)

`yuliansu@gmail.com` is a separate mailbox (Liansu, human_id=2) indexed in the same mu store. Messages in that account where yuliansu@gmail.com appears as recipient are inbound to Liansu. The plugin must handle per-account identity: for the `yuliansu-gmail-com` account, yuliansu@gmail.com is the account owner.

Loaded from a single config location read by this plugin. Other plugins carry their own identity config keyed to the account being processed.

## 6. Participant resolution

Email addresses are exact identifiers. Resolution to human nodes is via `email_address.human_id`. No fuzzy matching is needed.

**Role email addresses.** Some addresses are role-based rather than personal (e.g. `manager@rivermill.au`). The `email_address.human_id` link always points to the current holder of the role. Historical messages sent to that address when a different person held the role are semantically addressed to a different human, but the address record cannot carry that history — only the current assignment is stored. The previous holder should have their own `human` record linked to their personal address (if known); the role address is not backlinked to them.

Merging two humans who turn out to be the same person requires only updating `email_address.human_id`; all downstream tables reference `human_id` and resolve automatically.

The `identifier_ref` column in `item_participant` holds the email address for items produced by this plugin.

## 7. Edge semantics

Directed edges: sender -> each recipient. Stored in the `edge` table as `(from_human_id, to_human_id)` with `message_count`, `first_seen`, `last_seen`. The ratio of outbound to inbound edges reveals who initiates.

Co-appearance edges: when two non-self participants appear on the same message, they get an undirected entry in `coappearance`. This enables "do A and B already know each other" before making an introduction.

CC-to-CC coappearance (two people both CC'd, neither the sender) is included, probably at lower weight than sender-to-recipient.

## 8. Deduplication

By Message-ID in the `email_message` table. The N-consecutive-seen stopping rule in the scan strategy serves as early termination during incremental scans, not as the dedup mechanism itself. If a Message-ID already exists in the DB, the item is skipped.

## 9. Tables owned

| Table | Fields |
|-------|--------|
| **email_address** | address, human_id, is_canonical, source |
| **email_message** | message_id is the natural PK (Message-ID header; globally unique per RFC 2822); no surrogate id | message_id (PK), account, date, subject |
| **ignored_pattern** | pattern, pattern_type (address/domain/subject), reason |
| **source_coverage** | source_kind, source_ref, newest_scanned_id, oldest_scanned_id, last_checked_at |

`email_address` is also referenced by the generic `role` table (a role owns its email address).

## 10. Open questions

- CC-to-CC coappearance weight: what discount relative to sender-to-recipient coappearance?
- `ignored_pattern` scope: is subject-line filtering actually needed, or is address/domain sufficient?

---

## Addendum: email-derived outputs

**AI tagger data source.** The AI tagger (described in plan.md as a generic component) gathers its input from this plugin: email subject lines and short snippets retrieved via mu. For each person node, it queries mu for messages involving that person's addresses and sends the results to a cost-effective model requesting industry, company, location, languages, and commonly co-occurring names.

**~/.addressbook sync.** People with a known reachable email address who are marked as worth maintaining go into `~/.addressbook` (Alpine/pine 3-column TSV: `nickname\tFull Name\temail`). A convenience output derived from this plugin's data, not the primary purpose of the system.

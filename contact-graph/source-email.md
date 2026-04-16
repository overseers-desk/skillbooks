# Source plugin: email

## 1. Source description

Reads the mu email index. The corpus across all accounts is ~350k messages from ~15,000 unique email addresses. Most are one-off contacts, bulk senders, or automated addresses. A single account (director@rivermill.au) yields ~450 meaningful contacts; the full set is probably a few hundred to a few thousand worth maintaining.

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

## 5. Identity

Self addresses — those that identify "me" (Weiwu) rather than a contact. Messages to/from these are treated as self-addressed and excluded from graph edges:

- a@colourful.land
- me@weiwu.au
- me@weiwu.eu
- me@weiwu.id.au
- w@smarttokenlabs.com
- zhangweiwu@realss.com
- zhangweiwu@private.21cn.com (historical)
- director@rivermill.au
- admin@rivermill.au

`yuliansu@gmail.com` is a separate mailbox (Liansu, human_id=2) indexed in the same mu store. Messages in that account where yuliansu@gmail.com appears as recipient are not self-addressed; they are inbound to Liansu. The plugin must handle per-account identity: for the `yuliansu-gmail-com` account, yuliansu@gmail.com is the account owner, not "me."

Loaded from a single config location read by this plugin. Other plugins carry their own identity config, since the notion of "me" is plugin-specific.

## 6. Participant resolution

Email addresses are exact identifiers. Resolution to human nodes is via `email_address.human_id`. No fuzzy matching is needed.

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
| **email_message** | message_id, account, date, subject |
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

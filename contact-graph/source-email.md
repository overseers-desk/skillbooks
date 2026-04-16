# Source plugin: email

## 1. Source description

Reads the mu email index. The corpus spans multiple accounts; most addresses are one-off contacts, bulk senders, or automated addresses.

Curation is done by connectivity: contacts with more edges to the user, or who appear on more threads with multiple known contacts, rank higher. The AI tagging pipeline processes in this priority order so the most-connected people are profiled first.

## 2. Stable item ID

Message-ID from email headers. Available as a named field in mu's sexp output.

## 3. Scan strategy

**Coordinator** reads all active accounts in parallel. Active accounts are listed in config; `me-weiwu-id-au` is excluded (no real humans write to it). For each account: read the mu index from `newest_scanned_id` backward until N=3 consecutive Message-IDs are already in the DB, then update `email_source_coverage`. Messages are deduplicated across accounts on Message-ID (globally unique per RFC 2822 — the same message appearing in two accounts is one row in `email_message`).

After harvest, messages are grouped into threads using mu's thread grouping. Thread identity is extracted via `mu find --format=plain --fields="w"` (the thread field is not available in JSON or sexp output; two parallel plain-format queries with `--fields="i"` and `--fields="w"` using identical sort order and `--skip-dups` are zipped to produce the message_id→thread_id mapping). See §9 for rationale. For each thread with unprocessed messages (no `email_thread` row yet, or `last_processed_at` < newest message date), the coordinator acquires a per-thread lock (PostgreSQL advisory lock keyed on thread_id hash), collects all messages for that thread across all accounts, then dispatches to a worker.

**Worker** (amend-always): receives thread_id and the set of unprocessed message_ids (all messages on first run; delta on subsequent runs). Strips quoted content from each message body (see §4b). Sends thread to `claude -p`. Writes `email_thread_participant` rows and `item_entity` rows. Sets `email_thread.last_processed_at`. Amend-always means there is one code path: the first run processes all messages in a thread; later runs process only the messages added since `last_processed_at`. The per-thread lock prevents two account-harvest workers from racing on the same cross-account thread.

`email_source_coverage` stores `newest_scanned_id` and `oldest_scanned_id` per account. The DB's own contents are the truth; the coverage record is a cache to avoid re-scanning, not a correctness constraint — losing it forces a re-scan but does not corrupt the graph.

Tail scan (oldest known to further back) consumes available processing budget per run, enabling incremental historical import without blocking head processing.

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

**Input to the model:** subject line plus body text (truncated to a reasonable window if long). Quoted content is stripped before extraction: lines starting with `>` (plain-text quoting) and `<blockquote>` elements (HTML mail) are removed. Quoted material was already captured when the original message was processed; re-extracting it would attribute entities to the wrong message. The prompt requests the same structured fields as the meeting frontmatter schema.

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

Thread is the unit, not the message. The worker populates `email_thread_participant` with one row per (thread, human) pair after identity resolution. Directed edges and coappearances are views derived from that table — this plugin writes no rows to `edge` or `coappearance` directly.

Directed: a sender-role participant in a thread has a directed edge to each non-sender participant in the same thread. Edge weight = number of threads with that directed pair (`thread_count`), not number of messages. The ratio of outbound to inbound thread_count reveals who initiates conversations.

Undirected (coappearance): any two non-self participants in the same thread get an undirected coappearance entry. This includes CC-to-CC pairs. Weighting differences between sender-recipient and CC-to-CC pairs are a query-layer concern, not stored in the view.

## 8. Deduplication

By Message-ID in the `email_message` table. The N-consecutive-seen stopping rule in the scan strategy serves as early termination during incremental scans, not as the dedup mechanism itself. If a Message-ID already exists in the DB, the item is skipped.

## 9. Tables owned

| Table | Fields |
|-------|--------|
| **email_address** | address, human_id, is_canonical, source, display_name_raw |
| **email_message** | message_id (PK — Message-ID header, globally unique per RFC 2822), thread_id (FK→email_thread), account, date, date_anomaly, subject |
| **email_thread** | thread_id (PK — mu's internal `:thread-id`; see note below), first_message_at, last_message_at, last_processed_at, status ('pending'/'done'/'error'), priority_score, error_message |
| **email_thread_participant** | thread_id (FK→email_thread), human_id (FK→human), roles TEXT[], first_seen_at — unique (thread_id, human_id) |
| **email_ignored_pattern** | id, pattern, pattern_type (address/domain/subject/regex), reason |
| **email_source_coverage** | source_kind, source_ref, newest_scanned_id, oldest_scanned_id, last_checked_at |
| **email_address_candidate** | bootstrap staging: candidate addresses from mu corpus before identity resolution; cleared once candidates are resolved or confirmed noise | address (PK), display_name |

**Note on thread_id.** `email_thread.thread_id` is mu's internal thread identifier rather than a root message_id derived from the References chain. Outbound messages sent via Amazon SES have their Message-ID rewritten before delivery. The sent copy in the maildir carries the original (pre-SES) ID; recipients' In-Reply-To headers reference the SES-assigned ID. These never match, so a References-chain walk splits one conversation into two disconnected fragments. mu uses subject-line normalisation as a threading fallback that reconnects these fragments. This fallback is not detectable from headers alone and cannot be reimplemented without replicating mu's algorithm. Thread identity therefore comes from mu's Xapian index, extracted via `mu find --format=plain --fields="w"` (the thread field is not present in JSON or sexp output despite being searchable; see `mu info fields` — the field has `sexp: no`). On laptop migration, thread_ids can be remapped by querying mu on the new machine for any known message_id in each thread.

`email_address` is also referenced by the generic `role` table (a role owns its email address).

## 10. Open questions

- CC-to-CC coappearance weight: what discount relative to sender-to-recipient coappearance?
- `email_ignored_pattern` scope: is subject-line filtering actually needed, or is address/domain sufficient?

---

## Addendum: email-derived outputs

**AI tagger data source.** The AI tagger (described in plan.md as a generic component) gathers its input from this plugin: email subject lines and short snippets retrieved via mu. For each person node, it queries mu for messages involving that person's addresses and sends the results to a cost-effective model requesting industry, company, location, languages, and commonly co-occurring names.

**~/.addressbook sync.** People with a known reachable email address who are marked as worth maintaining go into `~/.addressbook` (Alpine/pine 3-column TSV: `nickname\tFull Name\temail`). A convenience output derived from this plugin's data, not the primary purpose of the system.

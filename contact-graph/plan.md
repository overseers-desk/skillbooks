# Contact Graph

## What this is

A personal relationship operating system built from email history and external profile data. It stores a graph of people, projects, and topics with edges between them, and uses an AI layer to do the associative reasoning that human memory does unreliably at scale.

The substrate is a SQLite graph whose nodes are people, projects, and topics, and whose edges record that two things are connected, when, and in what context. The value compounds as the graph grows: the richer the node profiles, the more associations the AI can surface.

---

## Problems this structure can solve

**1. Associative discovery**
You are working on tourism development and a name surfaces in your head. The system externalises that association: given a topic you are currently focused on, it surfaces people in your network whose profiles overlap with it — people you may not have thought of. The Argentine artist you met at Rivermill who mentioned rural creative economies is linked to the topic node; when you open a tourism project, her name surfaces alongside others.

**2. Introduction brokering**
Two people in your network share a context that neither knows about — they both worked in the same industry, they are both now in the same city, they have both discussed the same problem with you. You are the natural broker. The graph surfaces the opportunity; you decide whether to act.

**3. Context before interaction**
Before speaking to someone, the graph assembles what is known: shared projects, topics discussed, how long since last contact, who initiated, what has changed in their life since. This converts a cold outreach into an informed one.

**4. Network gap analysis**
The graph answers not only "who do I know in X" but "what domains am I building things in where I have no strong connections." A gap in your network is as actionable as a strong connection.

**5. Project-to-people diffusion**
When a project reaches a milestone or changes direction, the graph answers "who should know about this" — not only direct collaborators but people in your network for whom the development is relevant even if they are not involved.

**6. Event-triggered reconnection**
A LinkedIn post reveals that someone moved country, changed industry, or started a new venture. That change creates a natural opener that did not exist yesterday. The graph monitors external signals and generates the reason to reach out rather than leaving it to you to notice.

**7. Relationship decay prompting** (the original problem)
For relationships that have gone quiet, a spaced-recall scheduler surfaces the right person at the right time before the relationship fully lapses. This is one application of the graph, not the only one.

---

## Data the system must encode

### People nodes

Each person is a node with:
- One or more email addresses, one marked canonical
- Display name (from email headers, updated as better versions appear)
- Semantic profile: industry, area of focus, company, location (country/city), languages, any notable topics they have discussed
- Current state: where they are now, what they are working on (from LinkedIn or recent email)
- How and where you met (context of first contact)

Profile is built incrementally: email headers give name and address immediately; AI tagging on email subjects and snippets gives industry/location/topics; LinkedIn enrichment gives current state.

### Edges

Two kinds:

**Self ↔ person edges** (primary): directed. You→them means you sent email to them; them→You means they sent to you. The ratio reveals who initiates. Edge weight is message count plus timestamps (first seen, last seen).

**Person ↔ person edges** (secondary): when two non-self people appear together on an email you are party to, they have a co-appearance edge. This enables "do A and B already know each other" before making an introduction, and surfaces mutual connections for the Argentine artist case.

### Topic nodes

Topics are first-class nodes, not tags on people. A person has edges to topics they are associated with; a project has edges to topics it touches. The join gives "who to think about when working on X." Topics emerge from AI tagging of email history and are refined over time.

### Project nodes

Projects (Rivermill, SmartTokenLabs, a new initiative) are nodes with edges to the people and topics they connect to. When a project moves, querying its connected people gives the diffusion list.

### Events (timestamped facts)

Life changes are stored as timestamped facts on person nodes, not as overwritten state. "Moved from Argentina to US, April 2026" persists alongside "living in Buenos Aires, 2024." The history is part of the reasoning substrate.

---

## Scale

A single email address (director@rivermill.au) yields ~450 meaningful contacts. Across all addresses, the raw pool is ~15,000 unique addresses. Most are one-off contacts, bulk senders, or automated addresses. The graph does not need all 15,000 — it needs the subset worth maintaining, probably a few hundred to a few thousand.

Curation is done by connectivity: contacts with more edges to the user, or who appear on more threads with multiple known contacts, rank higher. The AI tagging pipeline processes in this priority order so the most-connected people are profiled first.

---

## Components

### 1. Source plugins (harvest + incremental update)

A source is anything with a stable per-item id that the graph can consume — email, LinkedIn messages, calendar, SMS. Each source is a plugin implementing:

- `scan(direction, from_id)` — iterate items in either direction ("newer" or "older") starting from a cursor
- `parse(item)` — return normalised participants, timestamp, and a reference to the item's content

The ingestion loop is source-agnostic. For each item a plugin emits it:
- Upserts people nodes (identifier + display name)
- Creates directed edges: sender → each recipient
- Creates person-person co-appearance edges for non-self participants on the same item

For each registered source the loop extends coverage outward in both directions, stopping when N (default 3) consecutive items are already present in the DB by source id, or when the source end is reached. N=3 tolerates one missing item without loss of correctness. The DB's own contents are the truth; the coverage record is a cache to skip re-scanning, not a correctness constraint — losing it forces a re-scan but does not corrupt the graph.

Backfill is a first-class operation: extending the "older" boundary runs the same code path as extending the "newer" one. Historical imports (old Gmail takeouts, PST archives) need no special case.

**Email plugin (reference implementation).** Reads the mu email index via `--format sexp`, using Message-ID as the stable per-item id. It emits each message's participants from `:from`, `:to`, `:cc`, with `:date` as the timestamp; the sexp format gives these as named fields, so no comma-splitting ambiguity. The plugin holds the list of self addresses — those that identify "me" rather than a contact:

- a@colourful.land
- me@weiwu.au
- me@weiwu.eu
- w@smarttokenlabs.com
- zhangweiwu@realss.com
- zhangweiwu@private.21cn.com (historical)
- director@rivermill.au

Self addresses are loaded from a single config location read by the email plugin. Other plugins carry their own identity config, since the notion of "me" is plugin-specific.

### 2. AI tagger

Processes people nodes in priority order (most-connected first). For each person, gathers email subject lines and short snippets from mu. Sends to a cost-effective model (Haiku or a local model) with a structured prompt requesting:
- Industry / area of focus
- Company or organisation
- Country / city
- Language(s) used
- Names of people commonly mentioned or CC'd

Tags are stored with their source and can be updated as new email arrives. The tagger tracks a processing watermark so it can be interrupted and resumed.

### 3. External enrichment (LinkedIn)

For people with a LinkedIn-discoverable presence, the LinkedIn skill fetches current profile data: current role, current location, recent posts. This feeds the "current state" field on the person node and generates event records for life changes.

Runs on demand or periodically for the most-connected subset. Does not replace email-derived data; supplements it.

### 4. Query / AI reasoning layer

Given a topic, project, or person as input, queries the graph and passes the result to an AI model to surface:
- Relevant people in the network
- Potential introductions
- Natural openers (based on events or shared context)
- Network gaps

This is not a scheduled job but an on-demand tool — something you invoke when starting a new project, preparing for a meeting, or when a name surfaces in your head and you want to know what the graph knows about them.

### 5. Decay scheduler (original feature)

For the relationship-maintenance use case: runs daily, computes edge scores with exponential decay, surfaces people whose next-prompt date has passed. One application of the graph, built on the same substrate.

### 6. ~/.addressbook sync (byproduct)

People with a known reachable address who are marked as worth maintaining go into `~/.addressbook` (Alpine/pine 3-column TSV: `nickname\tFull Name\temail`). A convenience output, not the primary purpose.

---

## Database

Location: `~/.local/share/aesop/contact-graph.db`

| Table | Relationship / purpose | Fields |
|---|---|---|
| **human** | one row per real human; `internal` flags self and team members | id, display_name, linkedin_url, internal, notes |
| **role** | a human holds a role at an organisation; the role owns its email address | id, human_id, title, organisation, email_address_id |
| **email_address** | all known addresses per human; canonical is a flag here, not duplicated on humans | address, human_id, is_canonical, source |
| **message** | email metadata, thin; kept so the corpus exists independently of tagging | message_id, account, date, subject |
| **message_participant** | who was on each message; edges and coappearances are both derivable from this | message_id, address, role (from/to/cc) |
| **ignored_pattern** | rules for excluding automated senders, booking confirmations, ad domains | pattern, pattern_type (address/domain/subject), reason |
| **edge** | cached directed human→human counts, maintained by harvest; derived from message_participant | from_human_id, to_human_id, message_count, first_seen, last_seen, computed_at |
| **coappearance** | cached undirected co-presence on threads; derived from message_participant | human_id_a, human_id_b, thread_count, computed_at |
| **tag** | normalised concept labels shared across humans and projects | id, label, category |
| **tag_evidence** | each observation of a tag tied to the identifier it was derived from (email_address_id for the email plugin, linkedin_url for LinkedIn); never stored against human_id directly, so repointing an identifier to a different human is free; date is a documented read-optimisation copy of the immutable source item date | tag_id, source_type (email/linkedin/manual), identifier_ref, source_item_id, date, snippet, valid |
| **project** | project nodes connectable to humans and tags | id, name, status, started_at |
| **project_human** | a human is relevant to a project | project_id, human_id, reason, added_at |
| **project_tag** | a project is associated with a tag; the bridge enabling associative discovery | project_id, tag_id, added_at |
| **linkedin_snapshot** | versioned profile captures; source of truth from which contact_events are derived | id, human_id, scraped_at, url, headline, location, summary |
| **human_event** | timestamped life-change facts derived from snapshot diffs | human_id, event_type, description, source_snapshot_id, event_date |
| **linkedin_connection** | second-degree edges from profile browsing; human_id nullable for unresolved nodes | human_id_a, linkedin_url_a, human_id_b, linkedin_url_b, discovered_via_human_id, scraped_at |
| **processing_queue** | unified job queue for AI tagging and LinkedIn enrichment | human_id, job_type (tag/linkedin), priority_score, queued_at, processed_at, model_used |
| **source_coverage** | per-source scanned range; replaces the forward-only harvest watermark so ingestion can extend in either direction until it meets N (default 3) already-seen ids or the source end | source_kind, source_ref, newest_scanned_id, oldest_scanned_id, last_checked_at |
| **reconnect_schedule** | computed next-prompt date per human; decay score not stored, computed on demand | human_id, next_prompt_date, last_prompted_at, computed_at |

---

## Open questions

- What is the spacing formula for the decay scheduler? Needs tuning against real data.
- What triggers the daily decay prompt — cron, morning aesop run, or MCP tool?
- How are topic nodes created and merged? Free-form tags from AI will drift; needs a normalisation pass.
- Do coappearances record CC-to-CC edges (two people both CC'd, neither the sender)? Probably yes, at lower weight than sender-to-recipient.
- How is identity resolution triggered? Name similarity plus domain patterns as a starting heuristic, confirmed manually or via LinkedIn. Merging two humans requires only updating email_addresses.human_id; all downstream tables reference human_id and resolve automatically.
- At what scale does SQLite become the wrong engine? Email corpus alone (~350k messages) stays well within SQLite range. LinkedIn second-degree connections, if pursued, could push tag_evidence past 50M rows — the threshold at which PostgreSQL becomes appropriate.

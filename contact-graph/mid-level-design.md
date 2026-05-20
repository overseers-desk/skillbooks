# Contact graph: design details

Mid-level technical design for the contact graph. The high-level framing (what this is for, what consumers query it, where the boundaries are) lives in [high-level-design.md](high-level-design.md). This document covers the data model, components, database schema, and open operational questions.

---

## Data the system must encode

### People nodes

Each person is a node with:
- One or more identifiers (email addresses, display names, LinkedIn URLs)
- Display name (from source plugins, updated as better versions appear)
- Semantic profile: industry, area of focus, company, location (country/city), languages, any notable topics they have discussed
- Current state: where they are now, what they are working on (from LinkedIn or recent interactions)
- How and where you met (context of first contact)

Profile is built incrementally: source plugins give identifiers and display names immediately; AI tagging on item content gives industry/location/topics; LinkedIn enrichment gives current state.

### Edges

Two kinds:

**Internal ↔ external edges** (primary): directed. An internal human initiated contact with an external, or vice versa. The ratio reveals who initiates. Edge weight is interaction count plus timestamps (first seen, last seen). Not all sources produce directed edges; sources without a sender/recipient distinction contribute only coappearance edges.

**Person ↔ person edges** (secondary): when two non-internal people appear together on an item, they have a co-appearance edge. This enables "do A and B already know each other" before making an introduction.

### Topic nodes

Topics are first-class nodes, not tags on people. A person has edges to topics they are associated with; a project has edges to topics it touches. The join gives "who to think about when working on X." Topics emerge from AI tagging of interaction content and are refined over time.

### Project nodes

Projects are nodes with edges to the people and topics they connect to. When a project moves, querying its connected people gives the diffusion list.

---

## Components

### Pipeline terminology

Each source plugin runs two kinds of work against its upstream store.

**Ingest**: pull structured metadata from the upstream source into the plugin's owned tables. No model calls, no body reading, no reasoning. Cheap enough to re-run on every new item; idempotent on the item's stable id. The email plugin's ingest reads mu headers; the meeting plugin's ingest reads the meeting file's frontmatter.

**Extract**: read the body/content of an item and call a model to produce structured entities. Expensive, budget-controlled, runs on its own schedule. Writes to `item_entity`.

Ingest is fast and precedes extract; an item must be ingested before it can be extracted. The two are separate scripts on separate schedules because their cost and cadence differ by two orders of magnitude.

### 1. Source plugins (ingest + incremental update)

Two plugins ship from the start: email and knowledge-capture (meeting notes). Additional sources (LinkedIn messages, calendar, SMS) can be added later following the same structure. Each plugin is fully specified in its own document: [source-email.md](source-email.md) and [source-meeting.md](source-meeting.md).

A source is anything with a stable per-item id that the graph can consume. Each plugin writes participants to its own prefixed table (`email_thread_participant` for email, `meeting_participant` for meetings) after identity resolution. The `edge` and `coappearance` views union across plugin participant tables; whether edges are directed or undirected depends on the participant roles the source provides.

When the same real-world interaction is captured by multiple sources (an email thread about a meeting, plus the meeting note itself), each source produces its own participant rows independently. This is intentional: an email after a meeting is one more signal of the relationship, not a duplicate.

### 2. AI tagger

Processes people nodes in priority order (most-connected first). For each person, gathers content from source plugins relevant to that person. Sends to a cost-effective model (Haiku or a local model) with a structured prompt requesting:
- Industry / area of focus
- Company or organisation
- Country / city
- Language(s) used
- Names of people commonly mentioned or co-occurring

Tags are stored with their source and can be updated as new items arrive. The tagger tracks a processing watermark so it can be interrupted and resumed.

### 3. External enrichment (LinkedIn)

For people with a LinkedIn-discoverable presence, the LinkedIn skill fetches current profile data: current role, current location, recent posts. This feeds the "current state" field on the person node and generates event records for life changes.

Runs on demand or periodically for the most-connected subset. Does not replace source-derived data; supplements it.

### 4. Query / AI reasoning layer

Given a topic, project, or person as input, queries the graph and passes the result to an AI model to surface:
- Relevant people in the network
- Potential introductions
- Natural openers (based on events or shared context)
- Network gaps

This is not a scheduled job but an on-demand tool, invoked when starting a new project, preparing for a meeting, or when a name surfaces in your head and you want to know what the graph knows about them.

### 5. Decay scheduler (original feature)

For the relationship-maintenance use case: runs daily, computes edge scores with exponential decay, surfaces people whose next-prompt date has passed. One application of the graph, built on the same substrate.

---

## Database

Database: `contact_graph` on the local PostgreSQL instance.

| Table | Relationship / purpose | Fields |
|---|---|---|
| **human** | one row per real human; `internal` flags operator-side humans (self, household, team); `linkedin_url` is UNIQUE so two humans cannot point at the same vanity (an identity-merge trigger for the LinkedIn enrichment worker) | id, display_name, linkedin_url, internal, notes |
| **organisation** | canonical organisation node; created when a new org name appears in role or item_entity resolution | id, name, notes |
| **role** | a human holds a role at an organisation; the role owns its email address | id, human_id, organisation_id (FK→organisation), title, email_address_id |
| **meeting_participant** | meeting plugin participant log; one row per attendee per meeting item; source for coappearance and edge views for meeting items | source_kind, external_item_id, identifier_ref, role |
| **edge** | view: directed human→human interaction count, derived from plugin participant tables (email_thread_participant, meeting_participant); no stored rows | from_human_id, to_human_id, thread_count, first_seen, last_seen |
| **coappearance** | view: undirected co-presence on items, derived from plugin participant tables; no stored rows | human_id_a, human_id_b, thread_count, first_seen, last_seen |
| **item_entity** | named entities extracted from item bodies by AI; the DB equivalent of meeting YAML frontmatter, populated for both sources; answers "what did this message/meeting discuss?" rather than "who participated?"; FK columns are populated by a post-extraction resolution pass | source_kind, external_item_id, entity_type ('person_mentioned'/'organisation'/'project'/'product'/'domain'), value, context (nullable), human_id (nullable FK→human), organisation_id (nullable FK→organisation), project_id (nullable FK→project), extracted_at; natural unique key (source_kind, external_item_id, entity_type, value) |
| **tag** | normalised concept labels shared across humans and projects | id, label, category |
| **tag_evidence** | each observation of a tag tied to the identifier it was derived from (email_address_id for the email plugin, linkedin_url for LinkedIn); never stored against human_id directly, so repointing an identifier to a different human is free; date is a documented read-optimisation copy of the immutable source item date | tag_id, source_type (email/linkedin/manual), identifier_ref, source_item_id, date, snippet, valid |
| **project** | project nodes connectable to humans and tags | id, name, status, started_at |
| **project_human** | a human is relevant to a project | project_id, human_id, reason, added_at |
| **project_tag** | a project is associated with a tag; the bridge enabling associative discovery | project_id, tag_id, added_at |
| **linkedin_snapshot** | versioned profile captures; source of truth from which contact_events are derived | id, human_id, scraped_at, url, headline, location, summary |
| **human_event** | timestamped life-change facts derived from snapshot diffs | human_id, event_type, description, source_snapshot_id, event_date |
| **linkedin_connection** | second-degree edges from profile browsing; human_id nullable for unresolved nodes | human_id_a, linkedin_url_a, human_id_b, linkedin_url_b, discovered_via_human_id, scraped_at |
| **processing_queue** | unified job queue for AI tagging and LinkedIn enrichment; rebuilt in priority order (by edge count desc) after each ingest run so insertion order encodes priority; no stored score needed | human_id, job_type (tag/linkedin), queued_at, processed_at, model_used |
| **reconnect_schedule** | computed next-prompt date per human; decay score not stored, computed on demand | human_id, next_prompt_date, last_prompted_at, computed_at |
| **connection_queue** | one row per (human, campaign) for outbound LinkedIn outreach; state drains the row through verify → draft → queued → sent; do_not_contact reachable from any non-terminal state with exclusion_reason carrying the why; stand-in for the planned generic workflow_human_state | id, human_id, workflow_label, state, priority, vanity_name, note_text, with_note, verify_evidence, failure_reason, exclusion_reason, level (treatment band 0-3 from the harvested memory score), queued_at, verified_at, drafted_at, sent_at, terminal_at |

---

## Planned changes from the high-level design

The high-level design now states multi-instancing of connectors and workflows, confluence over identity mappings, and a profile concept that detaches external identifiers from the `human` row. These imply schema changes the current table set does not yet provide. They are tracked here as the next batch of mid-level work, not yet drafted into `schema.sql`:

- A `connector_instance` table, keyed by an id, carrying connector type, label, configuration handle, and credentials handle. Each existing source plugin (email, meeting notes) and each future connector (LinkedIn, WeChat) becomes one or more rows in this table. The term "source plugin" in this document maps to "connector" in the high-level vocabulary, with the inbound aspect being one half of what a connector can do.
- A profile table that replaces `human.linkedin_url`, keyed at minimum by `(human_id, connector_instance_id)`, with the external identifier (URL or handle) as last observed and a context label distinguishing which life of the human the profile belongs to.
- A `workflow_instance` table, keyed by an id, carrying workflow type and configuration. Each running workflow (an RSVP for one event, one reconnection campaign) is one row.
- Re-keying of any per-`(human, platform)` state to per-`(human, connector_instance)` state. The first concrete case is the prospective `enrichment_state` table; further cases will arise as workflows are added.

These items together preserve the confluence property: the view of a human is a join over the current rows in these tables, and rearranging the order of inserts to identity mappings or to `connector_instance` does not change the resulting join.

---

## Open questions

- What triggers the daily decay prompt: cron, morning aesop run, or MCP tool?
- How are topic nodes created and merged? Free-form tags from AI will drift; needs a normalisation pass.
- How is identity resolution triggered? Name similarity plus domain patterns as a starting heuristic, confirmed manually or via LinkedIn.
- At what scale should streaming replication be configured? The schema is replication-ready (all tables have primary keys); the decision is operational, not structural.

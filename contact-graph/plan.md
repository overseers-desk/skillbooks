# Contact Graph

## What this is

A personal relationship operating system built from communication history and external profile data. It stores a graph of people, projects, and topics with edges between them, and uses an AI layer to do the associative reasoning that human memory does unreliably at scale.

The substrate is a PostgreSQL graph whose nodes are people, projects, and topics, and whose edges record that two things are connected, when, and in what context. The value compounds as the graph grows: the richer the node profiles, the more associations the AI can surface.

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
- One or more identifiers (email addresses, display names, LinkedIn URLs)
- Display name (from source plugins, updated as better versions appear)
- Semantic profile: industry, area of focus, company, location (country/city), languages, any notable topics they have discussed
- Current state: where they are now, what they are working on (from LinkedIn or recent interactions)
- How and where you met (context of first contact)

Profile is built incrementally: source plugins give identifiers and display names immediately; AI tagging on item content gives industry/location/topics; LinkedIn enrichment gives current state.

### Edges

Two kinds:

**Self ↔ person edges** (primary): directed. You initiated contact with them, or they initiated with you. The ratio reveals who initiates. Edge weight is interaction count plus timestamps (first seen, last seen). Not all sources produce directed edges — sources without a sender/recipient distinction contribute only coappearance edges.

**Person ↔ person edges** (secondary): when two non-self people appear together on an item you are party to, they have a co-appearance edge. This enables "do A and B already know each other" before making an introduction, and surfaces mutual connections for the Argentine artist case.

### Topic nodes

Topics are first-class nodes, not tags on people. A person has edges to topics they are associated with; a project has edges to topics it touches. The join gives "who to think about when working on X." Topics emerge from AI tagging of interaction content and are refined over time.

### Project nodes

Projects (Rivermill, SmartTokenLabs, a new initiative) are nodes with edges to the people and topics they connect to. When a project moves, querying its connected people gives the diffusion list.

### Events (timestamped facts)

Life changes are stored as timestamped facts on person nodes, not as overwritten state. "Moved from Argentina to US, April 2026" persists alongside "living in Buenos Aires, 2024." The history is part of the reasoning substrate.

---

## Components

### 1. Source plugins (harvest + incremental update)

Two plugins ship from the start: email and knowledge-capture (meeting notes). Additional sources — LinkedIn messages, calendar, SMS — can be added later following the same structure. Each plugin is fully specified in its own document: [source-email.md](source-email.md) and [source-meeting.md](source-meeting.md).

A source is anything with a stable per-item id that the graph can consume. Each source plugin implements `enumerate_items()`, which returns all items the plugin knows about — each with its stable id, participants, timestamp, and participant roles. The ingestion core diffs the returned items against existing `item_participant` entries by `(source_kind, external_item_id)` and processes only new or changed items. How the plugin internally enumerates (cursor-based iteration, directory listing, API pagination) is its own concern.

The ingestion loop is source-agnostic. For each new item it:
- Upserts participant entries in `item_participant` with source-specific roles
- Derives edges and coappearances from `item_participant`. Whether edges are directed or undirected depends on the participant roles the source provides.

When the same real-world interaction is captured by multiple sources (an email thread about a meeting, plus the meeting note itself), each source produces its own `item_participant` entries independently. This is intentional: an email after a meeting is one more signal of the relationship, not a duplicate.

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

This is not a scheduled job but an on-demand tool — something you invoke when starting a new project, preparing for a meeting, or when a name surfaces in your head and you want to know what the graph knows about them.

### 5. Decay scheduler (original feature)

For the relationship-maintenance use case: runs daily, computes edge scores with exponential decay, surfaces people whose next-prompt date has passed. One application of the graph, built on the same substrate.

---

## Database

Database: `contact_graph` on the local PostgreSQL instance.

| Table | Relationship / purpose | Fields |
|---|---|---|
| **human** | one row per real human; `internal` flags self and team members | id, display_name, linkedin_url, internal, notes |
| **organisation** | canonical organisation node; created when a new org name appears in role or item_entity resolution | id, name, notes |
| **role** | a human holds a role at an organisation; the role owns its email address | id, human_id, organisation_id (FK→organisation), title, email_address_id |
| **item_participant** | normalised participants produced by each plugin's enumerate_items(); source-agnostic so edge and coappearance queries need no UNION | source_kind, external_item_id, identifier_ref, role |
| **edge** | cached directed human→human counts, rebuilt in full at the end of every harvest run; derived from item_participant | from_human_id, to_human_id, message_count, first_seen, last_seen |
| **coappearance** | cached undirected co-presence on items, rebuilt in full at the end of every harvest run; derived from item_participant | human_id_a, human_id_b, thread_count |
| **harvest_run** | one row per completed harvest run; source of truth for "when were edge/coappearance last rebuilt" | id, started_at, completed_at, items_processed |
| **item_entity** | named entities extracted from item bodies by AI; the DB equivalent of meeting YAML frontmatter, populated for both sources; answers "what did this message/meeting discuss?" rather than "who participated?"; FK columns are populated by a post-extraction resolution pass | source_kind, external_item_id, entity_type ('person_mentioned'/'organisation'/'project'/'product'/'domain'), value, context (nullable), human_id (nullable FK→human), organisation_id (nullable FK→organisation), project_id (nullable FK→project), extracted_at; natural unique key (source_kind, external_item_id, entity_type, value) |
| **tag** | normalised concept labels shared across humans and projects | id, label, category |
| **tag_evidence** | each observation of a tag tied to the identifier it was derived from (email_address_id for the email plugin, linkedin_url for LinkedIn); never stored against human_id directly, so repointing an identifier to a different human is free; date is a documented read-optimisation copy of the immutable source item date | tag_id, source_type (email/linkedin/manual), identifier_ref, source_item_id, date, snippet, valid |
| **project** | project nodes connectable to humans and tags | id, name, status, started_at |
| **project_human** | a human is relevant to a project | project_id, human_id, reason, added_at |
| **project_tag** | a project is associated with a tag; the bridge enabling associative discovery | project_id, tag_id, added_at |
| **linkedin_snapshot** | versioned profile captures; source of truth from which contact_events are derived | id, human_id, scraped_at, url, headline, location, summary |
| **human_event** | timestamped life-change facts derived from snapshot diffs | human_id, event_type, description, source_snapshot_id, event_date |
| **linkedin_connection** | second-degree edges from profile browsing; human_id nullable for unresolved nodes | human_id_a, linkedin_url_a, human_id_b, linkedin_url_b, discovered_via_human_id, scraped_at |
| **processing_queue** | unified job queue for AI tagging and LinkedIn enrichment; rebuilt in priority order (by edge count desc) after each harvest run so insertion order encodes priority — no stored score needed | human_id, job_type (tag/linkedin), queued_at, processed_at, model_used |
| **reconnect_schedule** | computed next-prompt date per human; decay score not stored, computed on demand | human_id, next_prompt_date, last_prompted_at, computed_at |
| **email_address_candidate** | bootstrap staging: candidate addresses extracted from the mu corpus before identity resolution; cleared as candidates are resolved or confirmed as noise | address (PK), display_name |

---

## Open questions

- What is the spacing formula for the decay scheduler? Needs tuning against real data.
- What triggers the daily decay prompt — cron, morning aesop run, or MCP tool?
- How are topic nodes created and merged? Free-form tags from AI will drift; needs a normalisation pass.
- How is identity resolution triggered? Name similarity plus domain patterns as a starting heuristic, confirmed manually or via LinkedIn.
- At what scale should streaming replication be configured? The schema is replication-ready (all tables have primary keys); the decision is operational, not structural.

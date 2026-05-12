# Contact graph: design overview

## What this is

A base substrate that records every person the user has communicated with, every organisation those people have represented, every project the user runs, and the edges between all of these. The substrate ingests signals from the real world (email, meeting notes, public profile data), keeps itself current, and exposes a queryable graph to any tool that needs it.

Many tools are expected to sit on top. The substrate is the part that should not be reinvented by each of them.

## What sits on top

**Problem.** Multiple tools want the same input: who in the user's network matches a given topic, when the user last spoke to them, what their current situation is, and who else is connected to them. Today each tool keeps its own list. The outbound-partnership campaigner carries its target rosters, the project tracker carries its contributor list, the reminder script carries its own person list. Each list goes stale on its own schedule and none benefits when another tool learns something new.

**Discoveries.** The contact data is the part every tool reinvents, and reinventing it badly is what makes each tool feel heavy. The reasoning each tool then layers on top (rank these candidates, write that message, schedule this prompt) is small once the contact data is given.

**Solution.** Centralise the graph. Each consumer becomes a thin layer that asks the substrate a question and acts on the answer. Initial consumers in view:

- Decay prompting (the original use case): surface humans whose interaction has gone quiet.
- Associative discovery: given a current project or topic, surface network members whose profiles touch it.
- Introduction brokering: surface pairs in the network who share context but do not know each other.
- Pre-meeting context: assemble what is known about a person before a call.
- Outbound-partnership campaigns: select humans matching campaign criteria.
- Project-to-people diffusion: when a project changes, list who in the network should hear.
- Event-triggered reconnection: surface life events from public-profile changes as natural openers.
- Network-gap analysis: surface domains the user is building in but has no contacts in.
- Manual review and edit: a small interface for human merges, corrections, and notes against the graph.

Out of scope for the substrate, and therefore the consumer's job: message drafting, sequence orchestration, calendar, task management, and discovery of strangers the user has never interacted with.

## What this looks like in practice

The bullet list above names each consumer in one line. The vignettes below show what the substrate looks like from the user's seat, and what part of the substrate each consumer leans on.

**Decay prompting.** A relationship has been quiet for eleven months. The substrate computes freshness from edge timestamps, the score crosses the prompt threshold, and the reconnect schedule surfaces the person on the user's morning list before the silence stretches past the point where writing feels awkward. The substrate's contribution is the freshness view over the edges and the per-human schedule.

**Associative discovery.** A name flickers at the edge of the user's memory while they are starting work on a new tourism initiative. Given the topic, the query layer returns network members whose profiles overlap with it: an artist who once mentioned rural creative economies, a regional-development consultant from a meeting two years ago, an academic with relevant publications. The substrate's contribution is the semantic edges between people and topics.

**Introduction brokering.** Two people in the network share something neither of them knows about. They worked in the same industry years apart, they recently moved to the same city, or they both raised the same problem in separate conversations with the user. The user is the natural broker. The graph surfaces the overlap; the user decides whether to act on it. The substrate's contribution is the join across edges from each person to shared organisations, topics, or locations.

**Pre-meeting context.** Before speaking to someone, the user wants the assembled facts: shared projects, what topics last came up, who initiated the previous exchange, how long ago, and what has changed in the contact's life since. All of it is one query rather than a tour of mailbox and several social platforms. The substrate's contribution is the union view over per-human edges, events, and source items.

**Outbound-partnership campaigns.** A campaign wants partners matching criteria such as operating region, topic of work, freshness of last interaction, and presence of a usable public profile. A consumer tool queries the substrate for the candidate set, applies its own campaign-specific ranking, and writes its own campaign-specific message. The substrate's contribution is the criteria query and the per-candidate context bundle.

**Project-to-people diffusion.** A project reaches a milestone or changes direction. The user wants to know who should hear, including network members who are not direct collaborators but for whom the development is relevant. The substrate's contribution is the project-to-human and project-to-topic edges, traversed one hop through topics to find adjacent humans.

**Event-triggered reconnection.** A public-profile snapshot reveals that a contact has moved country, started a new venture, or changed role. The change is a natural opener that did not exist the day before. The substrate's contribution is the timestamped life-event log produced by the enrichment worker as it diffs snapshots, and the daily surfacing of new events.

**Re-engagement triggers a fresh look.** A person who last interacted two years ago writes a new email. The enrichment state machine notices the new edge, marks any cached profile data stale, and queues a fresh public-profile lookup before the user opens the message. By the time the user reads it, the assembled context is current rather than two years out of date. The substrate's contribution is the hook from edge updates into the enrichment scheduler.

**Network-gap analysis.** The user is building in a domain but does not yet know who in their network is positioned to help. The graph answers not only "who do I know in X" but "what am I working on where I have no strong tie." A gap is as actionable as a connection. The substrate's contribution is the topic-to-human join and its inverse: projects whose topics no adjacent humans cover.

**Manual review and edit.** The user wants to browse the graph and make corrections by hand: merging two human rows that turned out to be the same person, adding a note about where a connection was made, correcting a stale profile URL, marking an enrichment attempt as deliberately abandoned because the contact does not use that platform. A small interface reads and writes through the substrate alongside the automated workers. The substrate's contribution is being a normal database that supports both modes of access.

## Information model

The graph is a PostgreSQL database. Nodes: `human`, `organisation`, `project`, `topic`. Edges are derived from source plugins (currently email and meeting notes) rather than stored directly. New sources (calendar, SMS, chat) plug in by writing participant rows that the edge views union over.

### People as one identity, profiles as many

**Problem.** The original schema put `linkedin_url` directly on the `human` row, which assumes each person has at most one external profile per platform. Reality breaks this. One person commonly runs a personal Instagram and a separate Instagram for each business. One person has several email addresses across different organisations and over time. Handles get renamed, so a URL captured today is not the stable identifier for tomorrow.

**Decision.** Detach external profiles from the human row. Profiles are their own entity, with a many-to-one relation back to the human, recording the platform, the URL as last observed, the handle, and a short context label that distinguishes which life the profile belongs to ("personal", "business A", "former role").

**Solution.** A `social_profile` table with rows of the form `(human_id, platform, url, handle, context)`. The `human` table loses its `linkedin_url` column. Consumers that want a human's LinkedIn or Instagram handle read the profile rows and choose the context they care about.

### Nodes, edges, events

Edges come in three kinds. Directed edges record who initiated contact with whom and are derived from sources that distinguish sender from recipient. Undirected co-appearance edges record that two people were present on the same item (a meeting, a multi-party thread) without ordering. Semantic edges are produced by the AI tagger that reads item content and asserts that a person is associated with a topic or that two people discussed the same subject.

Life events are timestamped facts attached to the human node, never overwriting prior state. "Moved to São Paulo, March 2025" persists alongside "based in Buenos Aires, 2024." The history is part of what the graph is for.

## State machines

The substrate is active. Two background workers maintain it.

### Enrichment

**Problem.** Many humans in the graph have no profile recorded for some platform. The reason is ambiguous. The person may have no presence on that platform, or no one has looked yet, or a previous attempt failed for reasons that may have since resolved. One-shot enrichment scripts cannot tell these cases apart, so each new run either repeats work pointlessly or gives up too soon.

**Decision.** Track enrichment state per `(human, platform)` pair. Record what was attempted, when, and what was found. Re-check on two kinds of trigger. The first is time-based: a person who had no LinkedIn a year ago may have one now. The second is event-based: a person who re-engages after a long silence may have changed roles, locations, or signatures, so a lookup is freshly justified.

**Solution.** An `enrichment_state` row per `(human, platform)` with columns for last-checked timestamp, status (never checked, found, not found, error), and any error detail. The worker selects rows that meet the recheck rules, runs the lookup, updates the state, and writes any discovered profile into `social_profile`. The state row also tells the worker when to stop trying.

### Decay

**Problem.** Relationships go quiet without notice. By the time the gap feels uncomfortably long, the natural reason to write has passed.

**Decision.** Compute relationship freshness from the edge views, score each relationship, and surface humans whose next-prompt date has arrived. Event-triggered prompts (a job change, a country move, a new venture) override the schedule because the new fact is itself the reason to reach out.

**Solution.** A `reconnect_schedule` row per human, recomputed by a daily worker that reads the edge views and the human-event log. The scheduler does not store the score; the score is derived on demand from the edge views, so adjustments to the formula take effect without backfill.

## Boundary with consumer tools

The substrate stores facts and exposes queries. Consumer tools translate those facts into actions. Two illustrations of where the line falls.

A consumer that wants to email a person reads the substrate for the person's address and recent context, then performs the send. The substrate does not send.

A consumer that runs an outbound campaign asks the substrate for humans matching its criteria (topic membership, geography, last-interaction freshness), then performs its own ranking against its own campaign-specific weights. The substrate does not rank for the campaign's purposes, because ranking belongs to the campaign.

This boundary keeps the substrate stable as consumer tools come and go.

## What is deferred to other documents

- Schema migration from the current `human.linkedin_url` column to the `social_profile` table, and creation of the `enrichment_state` table. The current schema is documented in [mid-level-design.md](mid-level-design.md); the migration itself has not yet been written.
- A survey of how existing relationship-intelligence products handle the same problem, to answer whether building this substrate duplicates available work. This is its own research and its own document.
- The spacing formula for the decay scheduler. Needs tuning against real interaction history rather than chosen up front.

# Contact graph: design overview

## What this is

A base substrate that records every person the user has communicated with, every organisation those people have represented, every project the user runs, and the edges between all of these. The substrate ingests signals from the real world, keeps itself current, and exposes a queryable graph to any consumer that needs it.

Many tools are expected to sit on top. The substrate is the part that should not be reinvented by each of them. The product layer above the substrate is intentionally left undefined: it may be a single mega-application, a virtual operating system hosting many web apps, or any other arrangement. The substrate's responsibilities end at hosting the data, the connectors, and the workflows; the product shape can vary above without changing the substrate.

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

**Manual review and edit.** The user wants to browse the graph and make corrections by hand: merging two human rows that turned out to be the same person, adding a note about where a connection was made, correcting a stale profile identifier, marking an enrichment attempt as deliberately abandoned because the contact does not use that platform. A small interface reads and writes through the substrate alongside the automated workers. The substrate's contribution is being a normal database that supports both modes of access.

## Information model

The substrate models four kinds of node: humans, organisations, projects, and topics. Edges are derived from connector contributions rather than stored as primary data, so a new connector adds edges automatically by writing its own per-item participant records and letting the edge views union across all connectors. Life events are timestamped facts attached to humans, retained in full rather than overwriting prior state.

### People as one identity, profiles as many

**Problem.** Storing a single external profile per person per platform assumes each person has at most one such profile. Reality breaks this. One person commonly runs a personal Instagram and several business Instagrams. One person has several email addresses across different organisations and over time. Identifiers get renamed, so a handle captured today is not the stable name tomorrow. The substrate may further discover that two profiles previously believed to belong to the same person are actually different, or that two profiles believed to be different are the same.

**Decision.** External profiles are their own entity, separate from the human node. Each profile carries the connector instance through which it was observed, the external identifier, and a short context label that distinguishes which life the profile belongs to ("personal", "business A", "former role"). The mapping from external identity to human is itself a first-class object that can be updated and reversed.

**Solution.** A profile concept that consumers join into the human view. Consumers that want a human's LinkedIn or Instagram identifier read the profile records for that human and choose the context they care about. The specific table layout lives in [mid-level-design.md](mid-level-design.md).

### Edges and events

Edges come in three kinds. Directed edges record who initiated contact with whom and are derived from connectors that distinguish sender from recipient. Undirected co-appearance edges record that two people were present on the same item (a meeting, a multi-party thread) without ordering. Semantic edges are produced by the AI tagger that reads item content and asserts that a person is associated with a topic or that two people discussed the same subject.

Life events are timestamped facts attached to the human node, never overwriting prior state. "Moved to São Paulo, March 2025" persists alongside "based in Buenos Aires, 2024." The history is part of what the graph is for.

## Extensibility: connectors and workflows

The substrate enriches each human along two independent axes. Both are dynamic: new entries on either axis can be added without restructuring the substrate.

### Connectors

A connector is an integration with an external system. Email, meeting notes, LinkedIn, WeChat, and future platforms are each addressed by their own connector. Connectors contribute identity mappings, profile records, and edge data (interactions) about the humans they observe. A connector may also support outbound actions (a search, a connection request, a message), and the substrate records those actions alongside the inbound data.

A connector is not one-to-one with a platform. One platform may host more than one connector when those connectors serve different purposes, such as a friends-reader and a direct-message-reader on the same account, or an old version of a connector alongside a newer replacement. Replacing one connector with another is therefore meaningful as a substrate operation: the outgoing connector's state is decommissioned and the incoming connector reinitialises, even though the platform underneath did not change.

### Workflows

A workflow is a per-human activity that the user runs through the substrate. Reconnection campaigns, decay prompting, RSVP for an event, and outbound partnership outreach are each workflows. Each workflow defines its own state vocabulary, its own transitions, and its own re-check cadence. The substrate keeps per-(human, workflow instance) state and exposes it as part of the human view.

A workflow may be introduced by a consumer application, or it may exist as a component that a consumer application depends on. The substrate does not distinguish between the two cases.

### Orthogonality

The two axes are independent. A connector can exist with no workflow consuming it: the connector still feeds the base with identities, profiles, and edges. A workflow can exist with no connector backing it: a workflow may read existing edges and track its own state. The coupling that does exist runs one way only: a workflow may depend on a particular connector to do its job, and a workflow that requires an absent connector simply waits at its first state until the connector becomes available.

### Multi-instancing and isolation

Both connectors and workflows are multi-instanced. The user may configure two LinkedIn accounts, two WhatsApp accounts, and a work email and a personal email as separate connector instances. The user may run multiple campaigns or events as separate workflow instances.

The substrate identifies connector-originated data by its connector instance and workflow-state data by its workflow instance. The structural consequence is that "show me everything from this instance" is a one-column filter, and an isolation view (a view of a human produced with one connector hidden, and that connector's side of every shared connection elided) is computable from the schema rather than from a separate privacy layer. The isolation view is a stated design feature: nothing is built for it yet, but the data layout is designed to admit it without redesign.

### Confluence

Identity resolution is incremental and revisable. Two profiles thought to belong to the same person may turn out to belong to two different James Browns; two profiles thought to belong to different people may turn out to be the same person under different identifiers. Connectors are introduced on different days; identity mappings are asserted and corrected over time.

The substrate is confluent: the view of a human is determined by the current set of identity mappings, not by the order in which those mappings were asserted, nor by the path that led to the current set. Remapping is a first-class operation, and the view recomputes deterministically from the new mapping. The practical commitments are that identity-merge operations are commutative and idempotent over the current set of (external identity → human) assertions, and that no view-contributing substrate state carries information whose meaning depends on insertion order.

### The view of a human

The "view of a human" is what a consumer receives when it asks the substrate for everything about a person. The view is derived: it is the union of the base record, the records contributed by each active connector instance for that human, and the state contributed by each active workflow instance. It is not materialised; it is recomputed from the current contents of the substrate on each query.

The view is the use-case by which the substrate's design properties are checked. Confluence holds if the view is stable under reordering of the operations that produced it. Isolation is real if the view can be recomputed with any subset of connectors hidden. Multi-instancing is real if the view can be recomputed against any subset of instances. The view is a result of computation, not the substrate's primary unit; the primary units are the connectors, the workflows, and the mappings.

## State machines

The substrate is active. Background workers maintain it. Two workers ship in the initial design.

### Enrichment

**Problem.** Many humans in the graph have no profile recorded for some connector. The reason is ambiguous. The person may have no presence reachable through that connector, or no one has looked yet, or a previous attempt failed for reasons that may since have resolved. One-shot enrichment scripts cannot tell these cases apart, so each new run either repeats work pointlessly or gives up too soon.

**Decision.** Track enrichment state per (human, connector instance) pair. Record what was attempted, when, and what was found. Re-check on two kinds of trigger. The first is time-based: a person who had no LinkedIn a year ago may have one now. The second is event-based: a person who re-engages after a long silence may have changed roles, locations, or signatures, so a fresh lookup is justified.

**Solution.** The substrate holds per-(human, connector instance) enrichment state; the worker selects rows meeting the recheck rules, runs the lookup, updates the state, and writes any discovered profile records. The state row also tells the worker when to stop trying. Concrete schema lives in [mid-level-design.md](mid-level-design.md).

### Decay

**Problem.** Relationships go quiet without notice. By the time the gap feels uncomfortably long, the natural reason to write has passed.

**Decision.** Compute relationship freshness from the edge views, score each relationship, and surface humans whose next-prompt date has arrived. Event-triggered prompts (a job change, a country move, a new venture) override the schedule because the new fact is itself the reason to reach out.

**Solution.** A per-human reconnect schedule, recomputed by a daily worker that reads the edge views and the human-event log. The scheduler does not store the score; the score is derived on demand from the edge views, so adjustments to the formula take effect without backfill.

## Boundary with consumer tools

The substrate stores facts and exposes queries. Consumer tools translate those facts into actions. Two illustrations of where the line falls.

A consumer that wants to email a person reads the substrate for the person's address and recent context, then performs the send. The substrate does not send.

A consumer that runs an outbound campaign asks the substrate for humans matching its criteria (topic membership, geography, last-interaction freshness), then performs its own ranking against its own campaign-specific weights. The substrate does not rank for the campaign's purposes, because ranking belongs to the campaign.

This boundary keeps the substrate stable as consumer tools come and go.

## What is deferred to other documents

- Schema details, including the migration from the current single-identifier-per-human storage to a per-connector-instance profile layout, and the introduction of multi-instancing for connectors and workflows. The current and target schema are documented in [mid-level-design.md](mid-level-design.md).
- The scheduling engine: how often workers wake, how back-off curves are shaped, whether scheduling is centralised across workflows or per-workflow. Treated as product detail.
- A survey of how existing relationship-intelligence products handle the same problem, to answer whether building this substrate duplicates available work. This is its own research and its own document.
- The spacing formula for the decay scheduler. Needs tuning against real interaction history rather than chosen up front.
- The promotion path for facts a workflow learns that turn out to belong in the base. Open design question.

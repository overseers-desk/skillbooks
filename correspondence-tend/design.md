# Correspondence processing: architecture and data model

This document covers the plugin boundary and the data model. The agent behaviour (how a single message is threaded, evaluated, and dispatched) is in [tend-methodology.md](tend-methodology.md). The substrate this plugs into (people, organisations, projects, threads, messages) is contact-graph; see its `high-level-design.md` and `schema.sql`.

## The plugin cut

**Problem.** The corpus is expected to need on the order of 100 distinct processes, and the number grows over time. Examples span a wide range: filing an arriving document into the right destination and checking the destination is current; deciding whether a message concerns the user's own business and, if so, creating a task in the right downstream system; the longer sales and dispute lifecycles already visible in the taxonomy. Managing 100 of anything that requires a migration to add is not viable.

**Decision.** A process does not own tables and does not own a namespace. The *methodology* is the plugin; the tables are shared and standardised across all processes; a process is a folder of documents plus rows in those shared tables. The variation between processes is textual (the valid states, the transitions, the triage trigger), authored in the process folder and version-controlled. The data shape is constant.

**Why not a plugin per process.** Every inbound-processing process produces the same kind of record: a matter with a subject, a current state, a transition history, and a set of attached messages. The states differ, the transitions differ, the trigger differs, but the *shape* does not. A plugin per process would mean 100 namespaces and 100 migrations expressing no schema variation. The cost is real (migration, backup, ordering) and the benefit is nil. Holding the schema constant and varying the document is the cheaper and more honest representation of where the variation actually lives.

A process degenerates gracefully. A one-step routing rule (file this, route that) is a process with two states; a sales lifecycle is a process with several. The same tables hold both.

## The two current plugins

Only two plugins exist today, and they differ in nature.

1. **Daily LinkedIn connector.** A per-human outbound pump: each day it surfaces people to connect with on LinkedIn and drains each through a verify-draft-send pipeline. Its state table is `connection_queue` (currently in contact-graph's `public`; a candidate to move into this plugin's own namespace). Keyed per-human. No inbound message, no case.

2. **The correspondence methodology (this folder).** A per-matter inbound engine: a message arrives, triage routes it to a process or to the generic path, and the matter advances through the process's states. This plugin owns the shared tables below and reads the process folders. It hosts all ~100 inbound processes as documents and rows, not as separate plugins.

The split is along the nature of the work (per-human outbound pump versus per-matter inbound case), not along the count of processes.

## Data model

Tables for the methodology plugin. Names carry no process name; the process is a column value. The definition tables (process_state, process_transition) are loaded from the process folders, which are the source of truth; the database copy exists for referential integrity, not as a second place to author. There is no separate process registry table: a process exists because its folder exists, and the set of distinct process keys in `process_state` is the list of processes. The instance tables (case, case_message, case_transition) are the dynamic state.

| Table | Grain | Source |
|---|---|---|
| `process_state` | valid states per process, with initial/terminal flags | loaded from folders |
| `process_transition` | valid transitions per process, with a pointer to the transition rubric | loaded from folders |
| `case` | one row per matter, carrying its current state | dynamic |
| `case_message` | many-to-many link from a case to the messages that concern it | dynamic |
| `case_transition` | append-only log of state changes per case | dynamic |

Two design points carried over from earlier discussion:

- **Case-to-message link is decoupled from any connector.** `case_message` references a message by the generic pair `(source_kind, external_item_id)`, the same handle `item_entity` already uses, rather than by a foreign key into the email connector's tables. A case can therefore absorb a WhatsApp or chat message later without the methodology plugin knowing which connector produced it. The price is a soft key rather than a hard foreign key, which is the price `item_entity` already pays.
- **The transition log is the prior-action record TEND's Thread phase needs.** The WORKLOG named the absence of this log as an open question; `case_transition` closes it. When the next message in a matter arrives, the engine can read what was done with the previous one.

Dependency direction is one-way: this plugin's tables reference contact-graph core (`public.project`, the generic item handle), never the reverse. That keeps the plugin droppable and the core standing alone.

The concrete tables are in [schema.sql](schema.sql).

## Triage

Triage is the skill-style router. Each process folder exposes a one-line description containing its trigger condition. Triage reads the aggregated one-liners (cheap, the way Claude Code skills route on name-plus-description), matches the incoming message to a process or to the generic path, and only then loads that process's full transition rubric (the expensive part).

Two properties the one-liner carries:

- **Evaluated per message, not once per thread.** A thread may belong to no process until a later message crosses a starting line. So the one-liner names two triggers: the cold-start condition (a first message that opens a case) and the mid-thread-entry condition (a later message that promotes an existing non-case thread into the process). Once a thread is inside a case, the per-process transition documents take over and the one-liner is no longer consulted for it.
- **The generic path already exists.** The methodology's default for anything outside its processes is to do nothing, except where the content would genuinely surprise the director, which it flags. That is the no-match outcome; it is not a new fallback.

## Open questions for the director

1. **Corpus scope for process mining.** The existing taxonomy (64 categories, 226 emails) covers one business mailbox. The example processes include personal-life matters (filing a medical document), which that mailbox would not contain. Mining "how many processes exist" needs to know which mailboxes are in scope: the business mailboxes only, or business plus personal.
2. **Process granularity.** Is a process roughly one taxonomy category (which would put the count near the stated 100 once personal categories are added), or a finer or coarser unit?
3. **Do trivial processes create a case?** A one-step file-and-forget could be a two-state case (for the audit trail the Thread phase wants) or a stateless action with only a log entry. Uniformity argues for the former; ask before deciding.
4. **Definition tables loaded, not authored.** The model above treats the folders as the source and the database copies as derived. Confirm, or say if you would rather the engine read folders directly and the database hold no definition copy.
5. **Case-to-project link.** A case may relate to a contact-graph project. The model makes that link optional (nullable). Confirm that optionality is right.

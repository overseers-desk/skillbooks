# Correspondence processing: architecture and data model

The agent behaviour (how a single message is threaded, evaluated, and dispatched) is in [tend-methodology.md](tend-methodology.md). The substrate this plugs into is contact-graph, a shared store of the people, organisations, projects and message threads the system reasons over; see its `high-level-design.md` and `schema.sql`.

## The plugin cut

**Problem.** The director, the person whose mailboxes the system tends, estimates the corpus will need on the order of 100 distinct processes, and the number grows over time. The figure is an estimate; the process-mining step is meant to replace it with a count. Examples span a wide range: filing an arriving document into the right place and checking that place is current; deciding whether a message concerns the user's own business and, if so, creating a downstream task; carrying a sales or dispute matter through its full lifecycle. Managing 100 of anything that needs a migration to add is not viable.

**Decision.** A process does not own tables and does not own a namespace. The *methodology* is the plugin; the tables are shared and standard across all processes; a process is a folder of documents plus rows in those shared tables. The variation between processes is textual (the valid states, the transitions, the triage trigger), authored in the process folder and kept under version control. The data shape is constant.

**Why not a plugin per process.** Every inbound-processing process produces the same kind of record: a matter with a subject, a current state, a transition history, and a set of attached messages. The states differ, the transitions differ, the trigger differs, but the *shape* does not. A plugin per process would mean 100 namespaces and 100 migrations expressing no schema variation. The cost is real (migration, backup, ordering) and the benefit is nil. Holding the schema constant and varying the document is the cheaper, more honest way to show where the variation lives.

A process degenerates gracefully. A one-step routing rule (file this, route that) is a process with two states; a sales lifecycle is a process with several. The same tables hold both.

## The two current plugins

Only two plugins exist today, and they differ in nature.

1. **Daily LinkedIn connector.** A per-human outbound pump: each day it surfaces people to connect with on LinkedIn and drains each through a pipeline that verifies, drafts and sends. Its state table is `connection_queue` (now in contact-graph's `public` schema; a candidate to move into this plugin's own namespace). Keyed per-human. No inbound message, no case.

2. **The correspondence methodology (this folder).** A per-matter inbound engine: a message arrives, triage routes it to a process or to the generic path, and the matter advances through the process's states. This plugin owns the shared tables below and reads the process folders. It holds all ~100 inbound processes as documents and rows, not as separate plugins.

The split is along the nature of the work (per-human outbound pump versus per-matter inbound case), not along the count of processes.

## Data model

Tables for the methodology plugin. Names carry no process name; the process is a column value. The definition tables (process_state, process_transition) are loaded from the process folders, the source of truth; the database copy exists for referential integrity, not as a second place to author. There is no separate process registry table: a process exists because its folder exists, and the set of distinct process keys in `process_state` is the list of processes. The instance tables (case, case_message, case_transition) hold the dynamic state.

| Table | Grain | Source |
|---|---|---|
| `process_state` | valid states per process, with initial/terminal flags | loaded from folders |
| `process_transition` | valid transitions per process, with a pointer to the transition rubric | loaded from folders |
| `case` | one row per matter, carrying its current state | dynamic |
| `case_message` | many-to-many link from a case to the messages that concern it | dynamic |
| `case_transition` | append-only log of state changes per case | dynamic |

Two design points carried over from earlier discussion:

- **Case-to-message link is decoupled from any connector.** `case_message` references a message by the generic pair `(source_kind, external_item_id)` rather than by a foreign key into the email connector's tables. The same pair identifies messages in `item_entity`, the contact-graph table that records what each message discussed. A case can therefore take in a WhatsApp or chat message later without the methodology plugin knowing which connector produced it. The price is a soft key rather than a hard foreign key, a cost the system already accepts in `item_entity`.
- **The transition log is the prior-action record the Thread phase needs.** TEND, the agent methodology that threads, evaluates and dispatches each message (see [tend-methodology.md](tend-methodology.md)), opens with a Thread phase. The work log named the absence of this log as an open question; `case_transition` closes it. When the next message in a matter arrives, the engine can read what was done with the previous one.

Dependency direction is one-way: this plugin's tables reference contact-graph core (`public.project`, the generic item handle), never the reverse. That keeps the plugin droppable and the core standing alone.

The concrete tables are in [schema.sql](schema.sql).

## Triage

Triage is the skill-style router. Each process folder exposes a one-line description holding its trigger condition. Triage reads the aggregated one-liners (cheap, the way Claude Code skills route on name-plus-description), matches the incoming message to a process or to the generic path, and only then loads that process's full transition rubric (the costly part).

Two properties the one-liner carries:

- **Evaluated per message, not once per thread.** A thread may belong to no process until a later message crosses a starting line. So the one-liner names two triggers: the cold-start condition (a first message that opens a case) and the mid-thread-entry condition (a later message that promotes an existing non-case thread into the process). Once a thread is inside a case, the per-process transition documents take over and the one-liner is no longer consulted for it.
- **The generic path already exists.** The methodology's default for anything outside its processes is to do nothing, except where the content would surprise the director, which it flags. That is the no-match outcome, not a new fallback.

## Open questions for the director

1. **Corpus scope for process mining.** A taxonomy built by an iterative sampling pass over one business mailbox, across a year to April 2026, found 64 categories in 226 emails. Those 64 are business only; the wider estimate adds personal-life matters the mailbox does not hold, such as filing a medical document. Mining "how many processes exist" needs to know which mailboxes are in scope: business only, or business plus personal.
2. **Process granularity.** Is a process roughly one taxonomy category (which would put the count near the stated 100 once personal categories are added), or a finer or coarser unit?
3. **Do trivial processes create a case?** A one-step file-and-forget could be a two-state case (for the audit trail the Thread phase wants) or a stateless action with only a log entry. Uniformity argues for the case; ask before deciding.
4. **Definition tables loaded, not authored.** The model above treats the folders as the source and the database copies as derived. Confirm, or say if you would rather the engine read folders directly and the database hold no definition copy.
5. **Case-to-project link.** A case may relate to a contact-graph project. The model makes that link optional (nullable). Confirm that optionality is right.

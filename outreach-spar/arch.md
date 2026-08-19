# Why SPAR is built this way

The procedure documents say what to do. This one says why the pipeline has the shape it has, so a session proposing to change it knows what the current shape is paying for and what it bought.

Each decision below names the alternative it beat and what it cost to beat it. Where the reason was never recorded, the section says so rather than reconstructing one.

## State lives in files, not a database

A contact's pipeline position is not stored anywhere. It is derived from which files exist: a roster row alone means discovered, a roster row plus `segments/{segment}/{stem}.md` means profiled, plus `campaigns/{campaign}/{stem}.yaml` means approached. There is no index, no status column, and no `segment` field inside any roster row, profile, or approach file. Reassigning a contact between segments is therefore a file move, and the new state re-derives itself from what now exists.

The relational alternative was argued in full and rejected. Its case: a roster row and its approach data would share a foreign key, so an email corrected in one place would propagate to the send list without file scanning; staleness would be a single query instead of a script that globs YAML and regex-parses `to:` fields; channel routing could be evaluated at send time from current roster data rather than baked in at drafting time; cross-segment duplicate detection and progress reporting would be joins rather than custom code.

What beat it: the artefacts are read by a human before anything is sent. A director reviews drafts, and a YAML file in a git diff shows what changed and who changed it. A row in a relational store does not. The same property serves the AI workers, which write files and cannot write to a schema they do not hold open.

The cost is real and is paid continuously. Data flows forward through the pipeline and not backward. An approach file is a standalone document that bakes in a snapshot of roster state at generation time, so a later roster correction leaves it stale and silent. This was accepted rather than solved: `spar::validate_campaign` carries an `email_desync` check that compares the roster `email` against the `to:` address in each approach file's final-round email messages and warns when they differ. Detection, not prevention. `profile_hash` on the approach file does the same job for the profile it was drafted from.

## The roster is edited literally, not through a CSV layer

The roster is a TSV file with no quoting: a tab separates fields, a newline separates records, and neither may appear inside a value. The harness reads it that way (`spar::load_roster` splits on tab), so an interactive session's tool has to read it the same way or the two disagree about what is in the file.

`mlr --tsvlite` is that tool. It round-trips a roster byte-identically, including a field whose value begins with a double quote and a field carrying a literal carriage return, and it aborts on a ragged row rather than guessing. `spar-roster-format.md`, "Programmatic access", carries the recipes and the faults to guard.

What it beat: `sqlite3` in `.mode tabs` is literal on output but not on input: `.import` applies CSV quoting rules, so a value beginning with a double quote swallows the following record and the row count drops, with a stderr warning and exit 0. It stays as the documented backup for a machine without mlr, because that fault is loud enough to check for and the tool is on every machine. `trdsql` was tried first and dropped when its UPDATE, INSERT and DELETE turned out to no-op silently on file sources: it imports the file into a temporary in-memory database, modifies that, and exits 0 having touched nothing (issue #10). `q` corrupted files on round-trip by treating a carriage return as a record separator. Python's `csv` writer re-quotes every field, so every line of the diff reads as changed.

The residual cost is that a literal writer will write anything it is given. A newline assigned into a value lands in the file as a newline and splits the record. The first time this was missed, 21 records were rejoined from 26 physical lines.

TSV rather than CSV for the same reason one level up: roster fields hold quoted speech, URLs, and free text that make comma quoting a liability.

## The dispatcher is Tcl, and one implementation serves both front ends

The CLI and the Tk GUI execute transitions through the same objects, the same shared dispatcher, and the same worker procs. A send path reachable from only one front end is forbidden by invariant, because the two surfaces would drift and the user's `--jobs` budget would mean different things in each.

Tcl is what makes one implementation possible: `tclsh` runs the CLI and `wish` runs the GUI from the same sources. The port from the original shell scripts also removed the `yq` and `jq` dependencies, since tcllib carries yaml and json, and replaced GNU parallel with the language's own event loop.

## Concurrency is coroutines on the event loop, not threads

Every wait in a dispatch run is a wait on something outside the process: a `claude` subprocess pipe, an SMTP or courier child, the overseer socket, a credit-limit or pacing timer. None of it burns CPU. A thread running one of these would idle on a read for its whole life, and would pay for the privilege in message marshalling between interpreters.

So the dispatch pool runs each job as a coroutine on the front end's own event loop. One interpreter multiplexes every wait, and a worker's reporting and cancellation code needs no bridge procs, no async sends, and no re-sourcing of the harness into a worker interpreter.

Threads are still used in the two places that are genuinely CPU-bound: the test runner fanning test files across cores, and the cold-load pool that reads and parses every roster at startup.

## The challenger is a separate process, not self-review

The A phase drafts a message, then tests it against an agent that role-plays the recipient. That agent runs as its own process with its own context, holding only the profile and the draft.

The first version ran the role-play inside the drafting agent, which had every campaign file open. The simulated recipient therefore knew what a cold stranger could not, and returned reactions that were favourable because they were informed. Instructing an agent to disregard what it knows does not work. Context isolation is structural, not procedural, and the only way to get an agent that does not know something is to start one that never did.

The challenger runs on a Sonnet-class model rather than the Opus tier that drafts. A less capable model shifts behaviour more completely under a role-play instruction, which is what persona fidelity needs. The challenger reacts; it does not draft.

## Flow control is deterministic; the model writes content, not the order

The phase order is fixed and the human decides when to cross a prong boundary. S runs to completion, then P, then a human review of roster and profiles, then A in bands ordered by response likelihood, with a human revision between bands. No agent decides that profiling is finished or that engagement should begin.

The general-purpose agent platforms advocate the same separation, and then offer autonomy alongside it as a configuration choice. Here it is the structure: the dispatcher enumerates eligible contacts from the state machine and launches one session per unit of work, so there is no step at which an agent could elect to continue.

The gate is not decoration. A single wrong email reaches a real person and cannot be recalled.

## Every AI call is wrapped in a pre/post validation pair

Before dispatch launches a session that will mutate project state, the relevant validation runs. If it fails, the call does not happen: the inputs were already broken, so no agent can be blamed for them and none should be charged tokens to work on bad data. After the session returns, the same validation runs again, and any new failure is the agent's. The orchestrator resumes the agent with the specific error, and the agent cannot dispute it, because the pre-check passed.

This is Design by Contract in Meyer's sense, with the invariant being that project state stays valid across each AI invocation. Every call site carries a `DbC-Pre` / `DbC-Post` comment pair so the pairing is greppable.

## Procedure documents carry no data

A methodology document is read by an agent as instruction. It is also, if it contains examples that look like real inputs, read as data. An illustrative example describing a venue with "stone buildings" was treated as a factual description of the actual venue by 78 independent agent runs, and every approach file generated that day was deleted.

So examples in procedure documents are visibly generic, real ground truth arrives through the campaign YAML's `fact_sources` and the segment definition, and a claim in a draft that cannot be traced to a named source does not get written. The separation is a content discipline. No platform enforces it.

## Building on a general agent platform was considered and declined

The comparison was run in detail against OpenClaw in April 2026, and is kept with the other lessons rather than here, because it is pegged to that product's state at the time. Its finding is what matters and does not expire.

Of the design problems SPAR had accumulated by then, none would have been prevented by the platform. They concerned what the pipeline should track (contact identity across segments, email-to-person relationships, profile-to-approach dependencies) and when it should check (discovery time or profiling time, drafting time or send time). Those are domain-model problems. A workflow platform supplies an execution substrate and no domain model, so the same problems arrive in the same form.

Two things would have come free rather than being invented: per-session sandboxing for the challenger, and declarative step composition in place of the Tcl dispatcher's imperative control flow. Both are implementation conveniences on subproblems. Neither would have changed what the pipeline had to learn to handle.

Against that, a platform whose agents extend themselves at runtime and decide their own next step widens exactly the surface this pipeline narrows on purpose.

## Recorded elsewhere

- Browser work reaching the overseer, and the vendored module discipline, are invariants of `spar-manager` and live in its own notes.
- The per-phase model tier and its cross-project validation are in `spar-methodology.md`, "Model assignment".
- What may not enter a profile, and what may not enter an instance's folders, are `INVARIANTS.md` I1 and I2.

## Not recorded

Validation runs as declarative rules that the vendored `yamlmuster` evaluates, with the checks living in `rules/*.rules` rather than as inline Tcl. No document states why that was chosen over inline validation. A session that needs the reason should ask rather than infer one from the result.

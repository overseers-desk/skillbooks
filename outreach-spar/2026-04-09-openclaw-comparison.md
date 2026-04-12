# SPAR and OpenClaw: A Comparative Design Study

**2026-04-09**

## Premise

SPAR is a four-phase outreach methodology (Search, Profile, Approach, Revise) that uses AI agents to discover contacts, research them, draft personalised messages, and iterate on strategy based on responses. It processes contacts through a deterministic pipeline of batch scripts, stores state in TSV rosters, Markdown profiles, and YAML approach files, and enforces human review gates between phases. It has been deployed across two campaigns — Rivermill (19 segments, 415 contacts profiled, 258 approaches drafted) and the Open Source Foundation (56+160 contacts) — over approximately one month of active development.

OpenClaw is an open-source autonomous AI agent (247,000 GitHub stars as of March 2026), created by Peter Steinberger and now stewarded by a non-profit foundation. It runs locally and acts through messaging platforms (WhatsApp, Telegram, Slack, Discord, and fifteen others). It handles email via IMAP/SMTP or webhook services such as AgentMail and Resend. Its workflow engine, Lobster Shell, defines pipelines in YAML with explicit steps, approval gates, and JSON data flow between stages. Its design philosophy is infrastructure-first: agents extend themselves by writing code at runtime, state is stored as human-readable files, and deterministic flow control is separated from LLM-driven content generation.

The question considered here is whether SPAR, had it been built on OpenClaw from the start, would have arrived at its current design more easily, and whether the design issues recorded in the project's issue tracker would have been prevented or merely relocated.

## Part 1: Would starting on OpenClaw have been easier or harder?

There are three respects in which OpenClaw's architecture aligns with what SPAR eventually built, and three in which it does not.

### Where OpenClaw would have helped

The most consequential early failure in SPAR's development was that the A2 sparring agent — a simulated recipient meant to react as a stranger would — ran inside the same agent context that had access to all project files. The simulated recipient therefore knew things a real cold contact would not, and the sparring step produced artificially favourable reactions. The fix required spawning a context-isolated agent (C2) that genuinely lacked access to internal documents. OpenClaw's session tree architecture provides per-session sandboxing with tool allowlists and denylists. A workflow step that spawns an A2 agent in a sandboxed session, passing only the profile and draft as input, is a configuration choice rather than a structural invention. SPAR had to discover, design, and implement this pattern from scratch; on OpenClaw it would have been available from the start.

SPAR assigns Sonnet to the S&P phases (high-volume, pattern-following work) and Opus to the A phase (tone, angle selection, relationship cross-referencing). This split was validated empirically and cross-checked against the SIFT methodology. OpenClaw's documentation identifies model routing as "one of the highest-leverage changes" for multi-agent systems and provides configuration-level support for assigning different models to different workflow steps. The principle is the same; OpenClaw would have made the implementation slightly more convenient, though the determination of which phases require which tier would still have required domain experience.

SPAR's batch scripts (`spar-p-batch.sh`, `spar-a-batch.sh`, `spar-a-worker.sh`) are shell scripts that iterate over roster rows, spawn subagents, and write output files. They were written incrementally as the pipeline took shape. OpenClaw's Lobster Shell provides a declarative YAML format for defining pipeline steps with inputs, outputs, retry logic, and approval gates. The batch scripts would have been Lobster workflows from the start, which would have imposed a more uniform structure and made step dependencies explicit rather than implicit in shell control flow.

### Where OpenClaw would not have helped

The methodology itself — SPAR's four phases, its two-prong structure, its band-ordered processing, its roster schema, its segment categorisation criteria, its approach file schema — is domain design. OpenClaw provides an execution substrate, not a methodology. Every decision about what constitutes a valid contact, how to order outreach by response likelihood, when to insert human review gates, and how to handle cross-segment duplicates would still have required the same month of empirical discovery documented in the SPAR development chronicle. OpenClaw's Lobster workflows can express these decisions once made, but they cannot make them.

On 30 March, 78 approach files were deleted because agents treated a placeholder example in a methodology document as factual data about the venue. The propagation mechanism was that the methodology document served inadvertently as both procedure and data source. OpenClaw stores state as Markdown files and gives agents filesystem access. An OpenClaw agent reading a methodology document with embedded examples would face the same ambiguity. The fix — separating procedure from data, ensuring examples cannot be mistaken for real inputs — is a content-design discipline, not a platform feature.

OpenClaw's token cost model means every action consumes AI tokens. The development chronicle records 415 contacts profiled and 258 approaches drafted across 19 segments. SPAR's batch scripts call the Anthropic API directly, which gives precise control over token expenditure per phase. OpenClaw's agent runtime adds overhead — session management, tool invocation, self-extension checks — that would increase the per-contact cost without increasing the quality of the output. At OpenClaw's reported usage rates ($30–70/month typical, $100–150+ heavy), the Rivermill campaign's volume would place it at the heavy end.

There is also a question of auditability. SPAR's file-based artefacts are version-controlled in Git, and the development chronicle traces every design decision to a specific commit or incident. OpenClaw also uses file-based state, but its session tree model and self-modification capability introduce state that is harder to trace. An agent that writes its own tools at runtime may solve a problem elegantly, but the solution is not captured in a methodology document that the next human operator can read. SPAR's explicit methodology documents — 33KB for SPAR-P alone — exist precisely because the pipeline must be legible to both humans and AI agents. OpenClaw's self-extension philosophy trades legibility for adaptability.

### Net assessment

The initial implementation would have been modestly easier on OpenClaw — context isolation, model routing, and workflow definition would have been configuration rather than invention. The methodology design work — which accounts for the majority of the month documented in the chronicle — would have been identical. The total effort would have been reduced by perhaps 15–20%, concentrated in the plumbing rather than the thinking.

## Part 2: Design issues under OpenClaw

The project's issue tracker contains fifteen issues. Of these, eight are design issues — problems arising from architectural choices in data modelling, pipeline structure, or validation logic, as distinct from operational issues (performance, tooling, formatting). Each is considered below.

### Issue #2: Graph-type transitions not handled by linear pipeline

Profiling contact B reveals that B replaced contact A. Contact A's approach file, already generated, is now addressed to the wrong person. The linear pipeline (S then P then A) does not propagate changes backwards.

Under OpenClaw, Lobster Shell's event model could define a workflow where a profile update emits an event that triggers approach regeneration for affected contacts. The `needs_approach_regen` flag proposed in the issue would become a Lobster step condition rather than a roster column. The fundamental difficulty, however, is not triggering regeneration — it is knowing which contacts are affected. The dependency graph (contact B's profile mentions contact A; therefore contact A's approach is stale) requires cross-referencing profile content against roster entries. OpenClaw does not provide referential integrity between Markdown files. The issue would persist in substance, though the triggering mechanism would be somewhat cleaner.

### Issue #3: Segment misclassification not caught until P-phase

Queensland AI Hub (community organisers) was placed in the corporate-team-experience segment during S. The mismatch was not caught until P's §4.0 validity gate excluded them, by which time valid contacts had been sitting as `date_excluded` in the wrong segment for weeks.

This is a classification problem. The S phase discovers contacts and assigns them to segments; the assignment can be wrong. OpenClaw's agent could apply a segment-fit check at discovery time, but this requires defining what constitutes a fit — the same §4.0 gate logic that SPAR eventually added. The issue is about when the check runs (S-phase vs. P-phase), not about what platform hosts the check. The issue would still exist. It is a methodology gap, not a platform limitation.

### Issue #5: Duplicate recipient detection conflates shared org emails with true duplicates

The progress script flags duplicate `To:` addresses but does not distinguish between true duplicates (same person in two segments), shared organisational inboxes (different people, same address), and one person with multiple organisational roles using a personal email.

The distinction between these three cases requires a data model that tracks the relationship between people, organisations, and email addresses as separate entities with defined relationships. SPAR's flat roster TSV, with one row per (contact_name, organisation) pair, cannot express these relationships. OpenClaw does not impose a data model; it uses whatever the workflow designer provides. If the designer uses a flat file, the same conflation occurs. The issue is a data-modelling choice, and OpenClaw neither prevents nor solves it.

### Issue #6: Cross-segment sweep must check all segments before adding

The S sweep checks for duplicates within one segment but not across segments. Kate Wood appeared in two segment rosters independently.

A Lobster workflow step could query all segment rosters before adding a contact. The implementation would be a pre-add validation step in the workflow definition. This is equally achievable in a shell script, and is what SPAR's issue proposes: a directory scan across all rosters. The platform choice does not affect the difficulty. The issue would still exist unless explicitly designed away, which is equally straightforward on either platform.

### Issue #7: Filename-based dedup misses duplicates when org name slug changes

Approach files are named by contact and organisation slug. When the slug changes (e.g. "lime-caviar-company" vs. "the-lime-caviar-company"), the filename-based existence check fails, and duplicate files are generated.

Lobster workflows pass data between steps as JSON, not filenames. If the approach step's dedup check were based on a contact identifier in JSON rather than a filename glob, slug variations would not cause duplicates. However, OpenClaw's state storage is also file-based. The approach files would still need to be written somewhere, and if named by slug, the same problem applies. The fix — using an email-based or ID-based lookup rather than a filename check — is equally applicable on either platform. The issue would be marginally less likely if the pipeline used JSON data flow for dedup, but the underlying identity problem (what constitutes "the same contact") remains.

### Issue #9: No policy for multiple approach files sharing one email address

When two approach files target the same email (two named contacts at one organisation), there is no defined policy for which file takes precedence, how replies are recorded, or how progress statistics account for the duplication. This is a policy gap requiring a human decision about business rules. No platform can supply this. The issue would exist identically on OpenClaw.

### Issue #14: 37 approach files need regeneration after email backfill

A second-pass email search found 42 addresses and updated the rosters, but 37 approach files still contain the wrong channel or no `to:` field. Data updated in the roster does not propagate to approach files.

This is the same class of problem as #2 — data flows forward through the pipeline but not backward. The issue text itself considers whether SQL with referential integrity (roster email to approach `to:` via foreign key) would solve the problem. OpenClaw does not provide a relational database. Its Lobster workflows could define a reconciliation step that re-derives approach file fields from the roster at send time, but this would need to be designed and implemented. The architectural choice of generating approach files as standalone documents, rather than deriving them from roster data at execution time, is the root cause, and OpenClaw does not change that choice.

### Issue #15: Placeholder `to:` fields bypass send validation

Approach files contain placeholder strings like `[email obtained during call]` or `[confirmed email]` in the `to:` field. The send script checks `if not to_addr` but placeholders are truthy strings, so they pass the check and fail at SES.

A Lobster workflow step could validate the `to:` field with a regex before sending. So could a Python script. The issue is that the schema allows any string in the `to:` field and the validation is insufficient. This is a schema and validation design choice. The issue would exist identically on OpenClaw unless someone wrote the validation rule, which is equally straightforward on either platform.

### Summary

| Issue | Would OpenClaw prevent it? | Reason |
|---|---|---|
| #2 Graph transitions | No, but remediation path cleaner | Dependency tracking is the hard part; event model helps with the easy part |
| #3 Segment misclassification | No | Methodology gap, not platform limitation |
| #5 Duplicate email conflation | No | Data model choice, not platform feature |
| #6 Cross-segment sweep | No | Equally easy to implement on either platform |
| #7 Filename-based dedup | Marginally less likely | JSON data flow avoids filename dependency, but identity problem remains |
| #9 Shared email policy | No | Policy gap requiring human decision |
| #14 Approach regeneration | No | Architectural choice about standalone vs. derived documents |
| #15 Placeholder validation | No | Schema and validation design, equally fixable on either platform |

Of eight design issues, none would be fully prevented by building on OpenClaw. One (#7) would be marginally less likely. One (#2) would have a cleaner remediation path. Six would exist in identical form.

## Part 3: Methodology decisions — how OpenClaw handles the same choices

### Deterministic pipeline vs. autonomous agent

SPAR chose a deterministic pipeline: S runs to completion, then P, then human review, then A in bands, then R. The order is fixed. The human decides when to proceed.

OpenClaw's Lobster Shell documentation advocates the same principle: "Don't orchestrate with LLMs." Flow control should be handled by deterministic code; LLMs handle content generation. This is stated as a design guideline, not enforced as a default. An OpenClaw user who does not read this guideline — or who is attracted by OpenClaw's self-extension capability — might build an autonomous pipeline where the agent decides when to move from profiling to approach drafting. The MoltMatch incident (February 2026), in which an OpenClaw agent autonomously created a dating profile and screened matches without explicit direction, illustrates the consequences of insufficient constraint on autonomous decision-making.

SPAR and OpenClaw's Lobster Shell agree on the principle. The difference is that SPAR enforces it structurally (the batch scripts define the order), while OpenClaw offers it as an option alongside autonomous execution. A disciplined OpenClaw user would arrive at the same design; an undisciplined one might not.

### Model tier assignment

SPAR assigns Sonnet to S&P and Opus to A. The rationale: when a rubric does the intellectual heavy lifting, Sonnet applies it reliably; Opus is needed when the task requires generating the rubric or making judgment calls not covered by it. This was validated empirically and cross-checked against the SIFT methodology's deployment on job listings.

OpenClaw's documentation recommends model routing as a cost-control measure, and the mechanism is configuration-level: different workflow steps can specify different models. The principle is identical. The difference is that SPAR's assignment was discovered through production experience and cross-project validation, while OpenClaw's documentation presents it as a known best practice. An OpenClaw user would have the guidance from the start but would still need to determine which phases require which tier for their specific domain.

### File-based state vs. database

SPAR stores state in TSV rosters, Markdown profiles, and YAML approach files, all version-controlled in Git. The development chronicle documents the costs: the backfill gap (P discovers data but does not write back to the roster), the SSOT violations (star ratings appearing in three places), and the approach regeneration problem (roster updates not propagating to approach files). Issue #14 explicitly considers whether SQL with referential integrity would resolve several of these problems.

OpenClaw also uses file-based state (Markdown files, version-controllable with Git). This is a deliberate architectural choice: auditability and human readability are prioritised over referential integrity. OpenClaw does not provide a relational database. The same backfill and propagation problems would arise on OpenClaw for the same structural reason: files are independent documents, not rows in a relational schema.

The difference is that OpenClaw's Lobster workflows pass data between steps as JSON. If the pipeline were designed so that the `to:` address is derived from the roster JSON at send time rather than baked into a YAML file at approach-drafting time, the propagation problem would not arise for that specific field. This requires designing the pipeline with late binding in mind — a design choice available on any platform but more naturally expressed in Lobster's step-to-step data flow than in standalone file generation.

### Separation of procedure from data

The hallucination reset of 30 March established that methodology documents must not contain content that could be mistaken for real input. A placeholder example describing "stone buildings" was treated as a factual venue description by 78 independent agent runs.

OpenClaw's Skills system stores instructions in `SKILL.md` files with metadata and step-by-step procedures. There is no structural mechanism preventing a skill file from containing example data that an agent treats as real. The discipline of separating procedure from data is equally necessary on OpenClaw and equally unsupported by the platform. It is a content-design discipline, not a platform feature.

### Exclusion gates

SPAR originally had no mechanism to exclude contacts from the pipeline. Star ratings ran from 1 to 5; every discovered contact was assumed valid. The addition of `star_rating = 0` as an exclusion marker, and the §4.0 validity gate, came after a competing venue owner received a complete approach file.

OpenClaw's Lobster workflows support conditional steps and approval gates. A validity check could be expressed as a workflow condition. But the need for the check — the recognition that discovery does not imply validity — is a methodology insight that emerged from a specific production failure. OpenClaw would provide a convenient syntax for expressing the gate once designed, but would not prompt the designer to include it. The gate's existence reflects learned experience, not platform capability.

### Context isolation for A2 sparring

As discussed in Part 1, OpenClaw's per-session sandboxing provides this capability as a platform feature. SPAR had to invent the pattern from the observation that instructing an agent to "pretend you don't know this" does not work — one must create an agent that genuinely does not know it. This is the single methodology decision where OpenClaw offers a clear structural advantage. The principle ("context isolation is structural, not procedural") was one of the seven emergent principles recorded in the development chronicle; on OpenClaw it would have been a configuration parameter.

### Single source of truth

SPAR learned through production experience that AI agents, when writing a document, include all relevant information in it — producing SSOT violations by default. Star ratings appeared in the roster, the profile, and the approach file. The fix was to designate the roster TSV as the single authority and strip redundant data from 523 profile files and 40 approach files.

OpenClaw's documentation does not address this pattern. Its agents, like SPAR's, write state into whatever file they are producing. The same violations would occur unless the workflow designer explicitly constrains what each step is allowed to write. OpenClaw's tool profiles (allowlists and denylists for file access) could enforce this at the tool level — for example, preventing the A-phase agent from writing rating data into approach files. This would be a more robust enforcement mechanism than SPAR's procedural instruction ("do not include the star rating in the approach file"), but it requires the designer to anticipate the violation, which SPAR's designer did not until it happened in production.

## Conclusions

Three findings emerge from this comparison.

First, the majority of SPAR's design issues arise from data-modelling and methodology choices, not from platform limitations. Of eight design issues examined, none would be fully prevented by building on OpenClaw. The issues concern what the pipeline should track (contact identity across segments, email-to-person relationships, profile-to-approach dependencies) and when it should check (discovery time vs. profiling time, drafting time vs. send time). These are domain design problems that require domain experience to identify and domain judgment to resolve. OpenClaw provides a workflow execution substrate, not a domain model.

Second, OpenClaw would have provided a modest structural advantage in two areas: context isolation for A2 sparring (available as a platform feature rather than requiring invention) and event-driven step composition (Lobster's declarative workflows vs. ad hoc shell scripts). These advantages would have saved implementation effort on specific subproblems but would not have changed the trajectory of the methodology's development, which was driven by empirical discovery of what the pipeline needed to handle. The hallucination reset, the pipeline gate problem, the SSOT consolidation, the backfill gap, the cross-segment duplicate discovery — all of these would have occurred on OpenClaw in substantially the same form.

Third, OpenClaw introduces risks that SPAR's deterministic pipeline avoids. OpenClaw's self-extension capability (agents writing their own tools at runtime) and autonomous decision-making could, in the hands of an operator who does not follow the Lobster Shell guidelines, produce the kinds of failures that SPAR's explicit methodology documents are designed to prevent — hallucination propagation, uncontrolled state modification, and actions taken without human review. The conservatism of SPAR's design — explicit procedures, human gates, version-controlled artefacts, methodology documents legible to both humans and AI agents — has value in a pipeline where a single wrong email is sent to a real person. OpenClaw's flexibility is an asset for prototyping and experimentation; SPAR's rigidity is an asset for production outreach at scale.

The overall picture is that OpenClaw and SPAR solve problems at different layers. OpenClaw solves the problem of getting an AI agent to execute steps, manage sessions, and communicate through channels. SPAR solves the problem of deciding what the steps should be, what data they consume and produce, and where human judgment is required. Building SPAR on OpenClaw would have provided a somewhat better execution substrate. The month of methodology development — the part that consumed most of the effort and produced most of the value — would have proceeded in substantially the same way.

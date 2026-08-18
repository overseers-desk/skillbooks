# Chronicle of SPAR Development So Far

**2026-04-07**

This is a summary of how the SPAR methodology developed over the past month, written from the git history of the three repositories involved. It covers what was built, what problems were encountered in practice, and what design principles emerged. The purpose is to give a full picture of where the methodology stands and how it got there.

## The three repositories

SPAR lives across three git repositories:

- **git@github.com:overseers-desk/aesop.git** — the methodology framework. Contains the procedure documents (spar-S-search.md, spar-P-profile.md, spar-A-approach.md, spar-methodology.md), the roster format spec, the campaign YAML spec, and the batch scripts in outreach-spar/bin/. AESOP stands for AI-Executed Standard Operating Procedures. SPAR is one of three methodologies in the AESOP collection (the others are SIFT for inbound listing evaluation, and TEND for correspondence processing). The methodology is domain-agnostic; domain-specific content lives in the campaign repositories.

- **git@github.com:overseers-desk/rivermill.git** — the Rivermill campaign implementation, in segments-outreach.spar/. 19 segments (wedding planners, tour operators, community organisations, market stallholders, etc.), 415 contacts profiled, 258 approach messages drafted. This is the primary deployment and where most of the methodology's design was tested and refined.

- **git@gitlab.com:bossdog/opensource.foundation.git** — the Open Source Foundation campaign, in outreach/. A second deployment, described briefly below.

## How the methodology came into being

SPAR was abstracted from project-specific outreach procedures on 25 March 2026. For the preceding months, Rivermill outreach had been conducted through ad hoc seed lists, manually composed connection plans, and research notes. The volume of contacts and the repetitiveness of the research-then-write cycle made it clear that the process had a repeatable structure.

The four phases — Search, Profile, Approach, Revise — were observed in existing practice, not invented from scratch. The seed lists were already a search artifact. The per-contact research documents were already profiles. The drafted emails were already approaches. What had not existed was a specification that an AI agent could follow without a human in the loop at every step. Writing that specification, and then discovering everything missing from it, is the story of the following month.

The directory was reorganised from a type-grouped layout (all rosters in one folder, all profiles in another) to a segment-grouped layout (each segment gets its own folder containing its roster, profiles, and goal document). The reason was operational: when an AI subagent runs the Profile phase for a single segment, it needs the roster, goal, and profile directory in one place. The layout that made sense for a human browsing the filesystem was not the layout that made sense for an agent executing a pipeline step.

The roster schema was also written at this stage, expanding the old seed-list format (seven columns: name, firm, location, type, reason, linkedin_url, source_url) into an eighteen-column schema with provenance tracking and phase-owned handover notes (s_note, p_note, a_note, r_note — each owned by one pipeline phase).

## The first batch run

On 27 March, 136 approach files were generated in the first batch run. Four things were learned from this run, all at once.

The batch prompt hardcoded the wrong sender name and email. The correct identity existed in the project's CLAUDE.md but was not included in the batch prompt's required reading list.

The A2 step — a simulated recipient reading the draft and reacting to it — was executed inside the same agent context that had access to all Rivermill project files. The simulated recipient therefore knew things about Rivermill that a real cold contact would not know, and responded with informed commentary rather than the confusion or indifference that a genuine stranger would express. The value of the sparring step depends entirely on the simulated recipient not having access to the sender's internal knowledge. This required creating a context-isolated agent for the recipient simulation — not instructing an agent to pretend it did not know things, but creating an agent that genuinely did not know them.

The methodology document contained a rule called "presuppose, don't narrate," meant to encourage natural prose. Agents interpreted this as "don't introduce yourself," producing emails to cold contacts that assumed the recipient already knew what Historic Rivermill was.

The fact-checker was restricted to a short list of named files. Verifiable claims were reported as unverifiable when the evidence existed in files not on the list.

These four findings arrived simultaneously because the first batch run was the first time the methodology encountered reality at scale. Each finding required a structural change to the pipeline, not a prompt adjustment.

The 27 March design session that fixed the run weighed alternatives before settling the A2 shape. For the isolation problem: prompting the agent to "forget" prior context was rejected as unreliable, and two separate `claude -p` calls were feasible but doubled external calls and complicated orchestration; the adopted design has A1 spawn a subagent (C2) that receives only the profile and the draft — no venue files, no method files, no rubric — with a Sonnet-class model preferred over Opus for persona fidelity under role-play instruction. For fact-checking: a third agent (C3) with full repository access added complexity, and restricting a fact-checker to a named file list proved fragile (claims documented in unlisted files were flagged unverifiable); the adopted design has C2 role-play first, then break character and fact-check with full repository access, the order guaranteeing that source-file knowledge cannot contaminate a persona reaction already recorded. The Zoe Abrahams file (tour-operator-inbound, 5★) was the reference regeneration: before, a structured "What works / What could be improved" A2, an unchallenged routing claim, and the wrong sender; after, C2 reacted as a stranger ("I've never heard of Rivermill"), the fact-check caught the routing claim and a 40-versus-45-minute distance discrepancy, and every factual claim in the final draft cited a specific project file and field.

## The hallucination reset

On 30 March, all 78 approach files generated so far were deleted. The agents had no authoritative venue description in their context. The methodology document contained an example that described "stone buildings," which was a placeholder, not a description of the actual venue. Agents used the example description as though it were real, and it propagated into every file.

The remedy was to add the venue overview document to the required reading list for the A phase. The propagation mechanism matters: a single wrong sentence in a methodology document, intended as an illustrative example, was treated as factual input by 78 independent agent runs. The methodology document was both the procedure and, inadvertently, a data source. Separating procedure from data — ensuring that examples in methodology documents cannot be mistaken for real inputs — is a principle that came directly from this incident.

A related finding: one of the goal files contained an offer of "complimentary pony rides" that no one at Rivermill had authorised. This was also an AI fabrication that had passed through review.

## The pipeline gate problem

The star rating scale originally ran from 1 to 5. Every discovered contact was assumed to be a valid target; the P phase rated how promising they were. There was no mechanism to say "this contact should never have entered the pipeline."

Terry Morris, the operator of Carrara Markets (a competing venue), received a complete approach file. He had been discovered, profiled, rated, and drafted for — and only then did someone observe that a competing venue owner is not a partnership target. Six contacts in the domestic tour-operator segment turned out to be travel agents rather than tour operators; two of them had already been emailed before the distinction was caught.

The remedy: star_rating = 0 was introduced as an explicit exclusion marker, distinct from 1 (low priority but still targetable). A validity gate (§4.0) was added to the top of both the P and A phases, checking the contact against the campaign goal document before any work begins. A further addition on 7 April: §4.0b, a contact-name resolution step. When a roster entry has an organisation name but no individual, the P agent must attempt to resolve a name through a five-source sequence before proceeding. Nameless entries are pipeline-invalid.

These gates did not exist in the original design because it assumed the S phase would only discover contacts that belonged in the pipeline.

## Single source of truth

Star ratings appeared in three locations: the roster TSV, the profile markdown document, and the approach file header. Response likelihood appeared in two. When a value changed in one location, the others did not update.

The consolidation, on 31 March, established the roster TSV as the single authoritative location for both fields. The Ratings section was stripped from 523 profile files. The band notation was stripped from 40 approach files.

The pattern that produced the duplication: when an agent writes a profile, it records everything it has learned, including the rating. When an agent writes an approach file, it records the rating in the header for reference. Each agent wrote the data into whatever file it was creating, because that was the natural thing to do. The single-source-of-truth rule had to be stated and enforced explicitly, because the default behaviour of a writing agent is to include all relevant information in the document it is producing.

## The backfill gap

The P phase was designed as a one-directional process: read the roster, research the contact, write a profile document. Contact data discovered during profiling — email addresses, LinkedIn URLs, Facebook URLs — was recorded in the profile markdown but not written back to the roster TSV. The A phase, which reads rosters, never saw this data.

On 7 April, a single commit backfilled 53 contact details from profiles to rosters across 14 segments. This was a manual operation. The methodology has not yet acquired an automated write-back step. The gap exists because the P phase was conceived as a research-and-report task, not as a data-enrichment task that modifies its input.

## TSV editing mechanics

A number of commits address mechanical problems with TSV file editing. A batch worker wrote a SQL CASE WHEN expression as a column header instead of its alias. The POSIX read command with tab delimiters collapsed consecutive tabs, losing empty fields. Windows line endings caused trailing carriage returns that broke string comparisons. The q tool treated carriage returns as record separators, corrupting files on round-trip. Lock files created by flock accumulated next to roster files as untracked debris.

None of these problems is conceptually interesting. Collectively they account for a substantial fraction of the debugging time. The adoption of trdsql (which survives a double round-trip byte-identically, unlike q) reduced the frequency but did not eliminate the problem class.

## Cross-segment duplicates

Kate Wood appeared in the mothers-group roster twice — as coordinator of two different playgroups both run by the same church. SPAR-A generated separate approach files for both entries. During profiling, the agent substituted Kate's personal email for the general inbox, producing two approach files with the same To: address. This was caught at pre-send review.

The quality checklist only checked for duplicate (contact_name, organisation) pairs within one roster — it did not check whether the same person appeared at multiple organisations. Cross-category duplicate detection by normalised name and by email address was added to the progress script after this incident.

## The second deployment

The same methodology has been applied to a second organisation: the Open Source Foundation (outreach/ in git@gitlab.com:bossdog/opensource.foundation.git), a Singapore-domiciled foundation building trust infrastructure for open source. That campaign — a 56-contact Singapore trip pipeline plus a 160-contact community-tier pipeline — was started in mid-March but has not been actively developed since the 27th. It is too early in its journey to draw conclusions from it.

## Where things stand

By 7 April the methodology had acquired entry gates at §4.0 and §4.0b, phase-owned handover fields, context-isolated sparring, a single-source-of-truth rule for ratings, and a five-script automation suite parameterised by campaign YAML. It had been applied to two organisations across more than twenty segments and several hundred contacts. On the final working day it was still backfilling data that should have been written back automatically and still discovering contacts that should have been excluded earlier — which is to say, the pipeline works but has known gaps in write-back automation and early-stage filtering.

## Principles that emerged from the month

- **Context isolation is structural, not procedural.** Telling an agent "pretend you don't know this" does not work; you must create a new agent that genuinely does not know it.
- **Design gates for exclusion, not just inclusion.** A pipeline that can only rate contacts 1–5 has no way to say "this should never have entered."
- **Single source of truth must be enforced at write time.** Every SSOT violation was introduced by an agent writing data into the nearest available file.
- **Schema should follow structure.** The file layout determines what is redundant; writing the schema before the directory structure is settled guarantees a cleanup sweep later.
- **AI agents will misparse ambiguous notation.** If a human might read a shorthand two ways, an agent will pick the wrong reading in production.
- **Correction rate is a measurable constant.** At 0.60 corrections per profile, a 160-contact campaign requires approximately 96 corrections regardless of how carefully the roster was compiled.
- **The backfill problem is permanent until the pipeline is bidirectional.** A phase that reads a roster and writes a profile but does not write back to the roster will always generate a backfill debt.

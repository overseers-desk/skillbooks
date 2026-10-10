# rulebook

The standard a late-arriving colleague applies to a draft, and the rules by which he edits a diff's comments. Any writing conventions the caller has in force (CLAUDE.md or equivalent) apply concurrently and are not restated here.

This is a document tool, like edit-email and edit-economistly. The draft is a finished text meant to be read on its own: prose, a page, or a code diff. The colleague has the project (its materials, domain, history and vocabulary, in whatever form the project takes: a codebase, a document set, a shared body of work) but was not in the conversation that produced the draft. The job is to make the text read for its reader, not to summarise the conversation that made it, and, for a diff, to leave its comments in the state a maintainer would want to inherit. A draft addressed to someone outside the project has a different reader again, and this colleague is the wrong one for it: he opens a file path or a scenario name without friction and certifies it, where the recipient of an email holds neither the project nor the thread. A caller holding an email runs edit-email, which carries the same pointing pass against that reader.

Linda Flower called the draft's condition writer-based prose, and named its marks: words that carry meaning only for the writer, an order that follows the writer's discovery, a frame that is the writer's own. The three failure modes below are those marks with the conversation as the writer's private context.

# The seat

The colleague reads in the seat of the draft's addressee when the caller or the draft names one: the owner a page is written for, the contributor an issue is for, the maintainer a diff is for. Otherwise he reads as a colleague who holds the project. The knowledge boundary is the same in every seat: the project yes, the conversation no. The seat sets two things. The vocabulary: a word's common reading is the reading the addressee would give it, so "lead" on a page for a venue's owner is an enquiry, whatever the writer meant by it. And the next act. A reader who executes (a maintainer, a colleague taking over a job, someone carrying out a plan) does not read to certify the draft legible; he reads because his own next task consumes it, and his test for a passage is whether he could act on it, not whether he could find what its names refer to. A reference he resolves and still cannot act on has not landed. A reader who decides (an owner, a client, a reviewer) tests whether a sentence carries its claim on its own; a sentence he could reconstruct from the table beneath it, had he the patience, has not carried it. Where the draft is not a document any single person acts on or decides from next, the seat has no occupant and he reads as a project-holder taking it in.

The colleague returns to the author a reading log (what landed and how, in his own words) and a set of rule-driven outputs: the pointing list, the patches he proposes or the comment edits he applied, the queries only the conversation can close, and for prose the sections to rewrite whole. The reading log is the heart of the exchange. Some misalignments between author and reader are invisible to any rule, because the reader settled on a confident reading the author did not intend and the text never contradicts it. Those surface only when the reader writes back what he thought, and the author compares against intent. The rule-driven outputs catch the rest. Both matter; neither alone is sufficient.

The conversation distorts the document three ways. The colleague checks for all three.

# Failure mode 1: short of context

The draft omits something its own conclusions rest on, because the author held it in the conversation and assumed it shared. The colleague cannot reconstruct it.

## R1. Labels for a list the reader never saw

"Option C", "approach 2", "the second one", "the first design" presuppose an enumeration that happened in the conversation. If a discarded alternative bears on the choice, name it in a clause; if it does not, drop the label and state the chosen thing directly. A rank or a comparison is the same presupposition: "the second most common", "a fraction of the other", "the larger of the two" place the thing against a first, a comparand, or a ratio the reader never saw. Name it in the same sentence.

## R2. Deixis pointing into the conversation

"as discussed", "the approach we agreed", "per the above", "as mentioned", "the plan", "this approach" point at turns the colleague missed. Replace the pointer with the thing it points to.

## R3. A decision without its recorded reason

"We decided to X" carries weight only with the why, and the why was spoken in the conversation. State the reason, or state the decision plainly without implying a debate the reader cannot reconstruct.

## R4. Asserted current state

"the current behaviour", "the existing arrangement", "how it works now" presented as shared. If the project shows it, the colleague can check it himself; if the phrase is the conversation's own summary of it, say what the state actually is.

## R5. A name absent from the project

A part, a role, a place, a term referred to as though it exists. If it is in the project and what the reader finds there lets him act, fine. If it exists only because the conversation coined it, define it where it first appears. A name that resolves in the project yet still leaves the reader unable to do his task (the referent is there, but the act the name stands for is never stated) is a gap, not a resolution: the draft owes the missing part where the name first appears, and resolving the name elsewhere does not discharge it.

## R6. A solution with its problem left behind

The draft says what to do but not what is wrong, because the problem was established earlier in the talk. The colleague needs the problem to judge the solution.

## R7. A change silent on what it displaces

A change settles, in the conversation, the fate of what it touches: removed, replaced, folded in, or left alone. Once settled, the author stops seeing it, so the draft states the new thing and not what becomes of the old. The colleague knows the prior state, so he reads the change the other way round: not only "does each reference resolve?" but "does the change account for everything it displaces?"

Work from the project, not from the draft's own list. Take stock of what currently occupies the area the change affects, including the parts the draft never names; the part most likely dropped is the one the draft is silent about, because the conversation already retired it. For each, the draft should say whether it stays, goes, changes, or merges. A part left unaccounted is a gap; a part the draft elsewhere still leans on as though it survives is the same gap twice. Do not stop at the first.

Example: a draft recommends moving the weekly review to Monday morning. The team already holds its planning meeting in that slot. If the draft never says whether the two merge or one of them moves, the colleague asks what becomes of the planning meeting.

## R10. A common word silently narrowed

A term with an everyday reading is used in a narrower project-specific sense without being defined. The reader resolves it with the common reading; downstream sentences happen to be consistent with that reading, so no contradiction surfaces. The pointing pass carries this rule where the common reading breaks the sentence: read with every word in the addressee's common sense, a sentence that says nothing or something absurd has a word in it the writer loaded privately, and that word is an entry. Where the common reading happens to fit, nothing in the text is unresolved and only the reading log surfaces it, when the reader names which sense he took.

The check is not "can the reader resolve this?" but "does the everyday reading match the author's?" The cure is to define at first use or pick a different term. Record the reading you took whenever a word has more than one plausible referent, and do not let the draft's own earlier uses of the word teach you its sense: a word met twice without a definition has been met, not defined.

Example: a deployment note says "the queue must be drained before deploy". The reader takes "queue" as the team's ticket backlog; the author meant the message broker's outbound buffer. The runbook downstream uses "queue" again, the reader stays consistent with his reading, and the wrong work gets done.

## R11. A chain step the reader has to supply

The draft asserts step N+1 of a chain of reasoning whose link to step N requires an unstated intermediate. The reader fills the middle from project knowledge, often silently, sometimes with a different middle from the author's. The conclusion then reads as following from the premise when in fact it follows only via the missing step.

The check is not "is each individual claim true?" but "does the leap from claim to claim require unstated reasoning?" The cure is to restore the middle. Where the reading log notes "I filled in X to get from A to B", that is the rule firing.

Example: a runbook says "the cache cluster is offline during the migration window, therefore writes must be queued client-side." The reader has to supply why writes must be queued (the path the writes would otherwise take leads through a degraded backend during the window). A reader who supplies a different middle (writes are normally cache-only) may design the wrong client-side queuing.

## R12. A surprising choice or value with no reason on the page

A value, a parameter, or a structural choice reads as odd or arbitrary, carries no reason in the draft or the project, and is still perfectly actionable. The reader proceeds, so nothing is unresolved and no other rule fires; the oddity passes in silence, and the author, who held the reason in the conversation, never learns it is missing. This generalises R3 and R6 from a decision and a solution to any choice. Where the reason existed and was dropped, that is failure mode 1 proper; where no reason ever existed, the choice is genuinely arbitrary, which sits outside this skill's remit, yet surfacing it is the same service and the same query closes it.

The check is not "can the reader act on this?" but "does the choice read as arbitrary, with no reason the reader can find?" A reason that sits elsewhere on the page than the choice counts as absent at the point of reading; the reader meets the verdict first and carries it unexplained until he reaches the reason, if he does. The cure is to state the reason at the choice, point to where it sits, or confirm it was left open. The reading log carries the catch, as it does for R11: flag a choice only when it genuinely made you pause, the way a sentence that reframed an earlier one made you pause, not by hunting for oddities to fill a quota. Ask rather than judge: you may not know the domain well enough to call the value wrong, but you can report that it reads as unexplained.

Example: a runbook sets a worker's wall-clock limit to 1800 seconds. The reader can act on it and nothing is unresolved, but 1800 reads as arbitrary and the runbook gives no reason. The reason, that it bounds each worker's memory to head off an out-of-memory kill, lived in the conversation and never reached the page. The reader pauses and asks "why 1800 seconds, or was it left open?"

## R13. A thing named without the handle to reach it

A party, a document, a record referred to in a way the reader cannot act on: "a supplier's manager rang", "the flyer", "the earlier enquiry". The author knows which; the reader has to reopen the thread, read the record, weigh the firm, and cannot. The fixed line names the party, dates the contact, states the channel, and links or paths the record. An anonymised business counterparty in a document for the owner reads as a gap by default; where a brief withheld the identity on purpose, the mention says so.

Example: a handover note says "the landlord's agent agreed to the extension by phone last month". The reader taking over has no name, date or file reference to hold anyone to it.

## R14. Certainty changed in transit

A figure, a claim or a rule reaches the draft firmer or looser than its source holds it: the source's own hedge (an unverified reading, a secondary report, an estimate) dropped on the way, or a rule given in strict terms restated in wider ones. The reader acts on the figure as settled, or on the rule as the wider one. The colleague has the project, so where the draft names a source he checks it, and where a rule was given by someone whose words the project records (an owner's instruction, a brief, a specification) he reads the page's wording against those words; where it names none he reports the figure as unsourced, and where the source is the conversation it is a query. The cure is to carry the source's hedge, or its exact scope, in the sentence.

Example: a budget memo says "the venue holds 200". The source is a listing site's summary; the venue's own floor plan, in the project, seats 140. A selection memo says the shortlist is "comparable or larger" venues; the owner's brief, in the project, said comparable.

# Pointing, not construing

R1 to R5, R10 and R14 name the phrase-classes. This is what makes the colleague check them rather than read past them.

A term coined in the conversation is paraphrasable, so a reader who construes it accepts his own paraphrase, and then adopts the term as though it were the project's own vocabulary. Judgement does not fire, because nothing in the text reads as unresolved. Enumeration fires: the colleague lists every expression that presupposes a referent and points at where the reader gets it, one by one, before he has settled on what the draft means.

The first move is the common reading. Each sentence is read with every word in the addressee's common sense; where the sentence then says nothing, or something absurd, the word carries a sense the writer holds and the page has not given, and it is an entry. Where the common sense fits and you take another anyway, because the surrounding text pulls you to it, the word is an entry on that ground alone: quote it, give the common sense and the sense you took, and point at the sentence that gives the draft's sense, or `nowhere`. That is the code word in its purest form, a word the writer loaded and the reader quietly re-loads. The enumeration then covers a definite noun phrase on first mention, a demonstrative, a rank or a comparison, a term of art, an old-new-current framing, a count in digits or in words, a qualifier on a set ("bigger", "comparable", "the five above"), and a clause that states a relation or a claim in shorthand: "X explains Y", "the claim that …", "the Z rule", "tests whether …". The clause is the case most easily construed, because it is English and a reader with the project can build a meaning for it; the entry is the clause, pointed at the sentence that states the relation in those words, or `nowhere`.

Three conditions decide whether a pointer counts.

**It precedes the question, where the answer is in the draft, and it is a definition, not an earlier use.** A definition below the passage arrives after the reader met the phrase, and by then he has taken a reading. A word the draft used twice before without saying what it means has been met twice, not answered; the reader who has learned its sense from those uses has learned it the way the writer holds it, which is the thing the pass exists to defeat. This condition governs an answer inside the draft alone: a project file is neither before nor after the sentence citing it.

**It names the thing in the words the phrase uses.** Pointing "that window" at a sentence that gives a range of dates, where nothing calls the span a window, is the construal the pass exists to defeat; the reader knows what is meant and donates the missing word. The test is whether the earlier text would let him produce the phrase, not whether he can see what it stands for.

**It lets him act, or carries its claim.** A name found in the project resolves only if what he finds there lets him do his task, which is R5's requirement; for a reader who decides, only if the sentence carries its claim without his reconstructing it. A colleague reading against a project fails in the direction opposite to one reading against a document alone: rather than donate a word, he opens the file, finds the name genuinely there, and certifies a reference the reader still cannot act on.

A figure on its second mention points at its first; a count, in digits or in words, points at the list, table or register it counts; a qualifier on a set points at the rule on the page that defines the set. A count of things the project keeps a register of (its profiles, its venues, its services, its contracts) points at that register, since the draft's own enumeration is the thing under test. A rule or instruction the draft attributes to a named person ("the owner's rule", "the brief") points at the project's record of their words, and a difference of scope between the two is a finding. A disagreement is a finding on the entry: the two figures, the count against what it counts, the rule against its record.

Every `nowhere` entry ends with its spread: how many times the expression occurs in the draft and where. A term the writer coined sits in every sentence he wrote while holding it. An author shown one mention fixes that one; shown twenty-five, he rewrites the section, which is the cure.

An expression with no answer meeting the conditions is unresolved, and the query discipline is the one below: a thing the conversation settled and the draft left out is failure mode 1, a thing it never settled is not the draft's fault, and the colleague cannot tell which, so he surfaces it and the author classifies.

# Failure mode 2: conversation residue

The draft replays the conversation instead of standing as a document. An idea raised and abandoned, an alternative weighed and dropped, a stretch of deliberation, sits in the text with no value to the reader, present only because it happened. That a thing was discussed is not a reason to include it.

## R8. A dead idea carried in

Cut what the reader does not need. If a discarded idea earns its place by explaining the choice the reader is handed, compile it to the one line that delivers that lesson; do not replay the deliberation. The test is whether the passage helps the reader act on or understand the document, not whether it occurred.

Example: a memo recommending a venue lists, in full, the three venues considered and rejected and the back-and-forth about each. If the rejections teach the reader nothing about the recommended venue, they go; if one rejection is the actual reason for the recommendation ("the cheaper hall has no parking"), that single point stays and the rest goes.

# Failure mode 3: pitched at an insider

The draft has the context but tells it from the seat of someone who walked the conversation. Nothing is missing and nothing is surplus; the angle is wrong, so even complete facts read as the middle of a talk the reader never joined. The cure is not more context but the same content re-told from where a newcomer stands.

## R9. Written to someone who was there

Re-pitch the passage for a reader arriving cold. The tells: a present stated as a change from a before only an insider knew ("now it does X", "the new approach"); a defence of an objection the reader never raised; an opening that resumes instead of introducing; an order that follows how the conversation found things rather than what the reader needs first; a sentence that narrates what the writer did with the material ("two of the eight test the claim that …") where the reader wants what the material shows. Ask whether a newcomer would feel addressed, or feel he is overhearing.

Example: a report opens "The switch to monthly billing fixes the backlog." A newcomer meets a fix for a problem he was never shown, framed as a change from a state he never knew; re-told for him, it says what monthly billing does and the backlog it prevents, problem before resolution. A blunter form is the conversational opener itself: a draft that begins "As we discussed, we are moving to monthly billing" or "Following up on the problem you raised" addresses the reader as a party to a talk he never joined. Cut the connector and open on the subject and the problem it solves, so the first sentence introduces rather than resumes.

# Code diffs

When the draft is a diff, the three failure modes take their code forms. Short of context: a comment referencing a discussion the file nowhere records ("the bug", "as agreed", a machine constraint named only in the talk), an identifier coined in the conversation rather than the project's vocabulary, a workaround whose reason lives only in the talk (R12's code form). R5's code form is the term of art: a comment that names a mechanism, structure, or stage as if established ("parks the request in the holding arena", "advances the ledger") when neither the code nor the project defines any such thing. The trap is that such a term reads paraphrasable, and a reader who accepts his own paraphrase misses that the referent is absent; the check is pointing to the thing, not construing the sentence. The harder case is the near-miss referent (R10's code form): the term lands close to a real concept but under a word the project does not use: the code keeps a pool, the comment says "the nursery"; the structure is a list, the comment calls it "the lattice". The pull is to read the stray word as a synonym and move on; resist it, because the mechanism resolves but the word does not, and a word the project does not use came from somewhere, usually the conversation. When you point to a referent, check the name too: a term-of-art noun in a comment that matches no identifier, no type, and no documented concept in the tree is a finding even when you know perfectly well what it means. Residue: a commented-out alternative, a TODO restating a settled decision, a comment narrating the change instead of the code. Insider pitch: a comment describing the new state as a change from a before only the conversation knew.

The cure order differs from prose. For code, prefer deleting the conversational reference; explain only when the reference earns its place in the file, because a maintainer reads code, and the shortest comment that still carries the reason beats a paragraph reconstructing a conversation. The query discipline is unchanged: surface the gap, and "this was left open" remains a complete answer; a diff owes the reader what it needs to maintain the code, not a clarification of everything the conversation touched.

# Not my mum

The three failure modes catch what the conversation left in the draft. This check catches what diligence left in: explanatory text, chiefly code comments, that tells the reader nothing he does not already know. The reader in his seat holds the project and reads the language; explaining the code, or the page, to him is mothering.

The test for each comment, and for an explanatory sentence in prose, is "did I learn something the page had not already given me?" It fails when the comment restates the operation of the code beside it, says in a sentence what the function or class name already says, or narrates that an ordinary thing was done. It passes when it carries what the code cannot: a quirk left in place that would otherwise misread, a reason or constraint invisible in the code, orientation for a function too long to take in at once, context from outside the file.

On a diff the cure is deletion, applied under the Comments rules; in prose it is a POLISHED line. Where a failing comment wraps one fact the code cannot show inside restatement, compress it to that fact. This is a judged reading, not a sweep: flag what taught you nothing, and where a comment's value may sit in domain knowledge you lack, query rather than delete.

Example: `retries += 1` under the comment "increment the retry counter" fails; the same line under "the third retry trips the circuit breaker in the gateway, not here" passes.

# Published pages

When the draft is an HTML page bound for publication (the file itself tells: markup, a title, a stylesheet), the colleague reads it as it renders, not only as its text. Text in cells and cards takes every prose rule above, and the short labels a page carries (a chip, a column heading, a tag of a word or two) are claims, not decoration: each is accounted for in the labels list under PAGE, the reading taken and where on the page its reason sits. Two further checks belong to the page's own layout. PAGE records what the stylesheet does, and both findings also go to POLISHED with the line and the fix. First, open the stylesheet and find the rule that caps the page's column (a `max-width` on the body or an outer wrapper); every table, code block and diagram inside that wrapper is confined to the reading column, and the cure is to move the cap from the page to the paragraphs, or to break the wide element out to the viewport. A long line is hard to read, a table is not, and the reader of a table wants every column he can get. Second, a column heading that asks a narrower question than its cells answer, so a cell reads as "none" where the row holds the evidence, wants the heading reworded to the question the reader brings.

# The top-level README

In a repository a stranger can reach, the README at its top level is the page a newcomer meets before deciding to adopt. For that file the colleague changes seat: he reads as the newcomer, holding nothing but the page. He first says whether the change is reducing (the README ends shorter) or lateral (material added or swapped in beside what is there). A reducing change passes. In a lateral one, each added sentence does one of two jobs: it moves the visitor toward becoming a user (what this is, the problem it solves, whether it runs here, whether he may use it), or it carries the new user through the first hour (install, the first successful run, where answers live from then on). A sentence doing neither is cut, and its EDITS line names the project document it belongs in, where one exists, for the author to move it there. A README below the top level, or in a repository no stranger reaches, is read like any other prose.

# Comments: the rules that edit

The reading above finds; these rules cut. On a diff their scope is the comments that describe the code the diff changes: the diff marks the code, and a comment or docstring on that code is read whole, wherever its lines sit. The colleague applies the rules with his edit tools, one edit per finding, code lines left as they are. On prose they are his standard for POLISHED, a proposal the author's hand applies, and they bind his own proposals: a POLISHED or EDITS line that introduces a count in words or a second home for a fact is the fault it exists to cut. Each rule states a cost and what earns it; the reader weighs both, and where the weighing needs domain knowledge he lacks, the comment stays and goes to QUERIES.

## C1. A name outside its definition site

A mechanism (a type, a function, a field, a config key, a shader, a file) is defined in one place. A comment elsewhere that carries its name is one more place a rename touches. That is the cost, one edit per rename per mention, and it is worth paying when the name does work a role phrase would not:

- A pointer whose value is the reference: the test that guards the invariant the comment states, the authoritative copy this code restates across a boundary it cannot import over, third-party source for a behaviour the code works around, a module or crate index. Where the toolchain offers a checked form (a Rust intra-doc link, a path that exists), prefer it, so a rename breaks the pointer loudly instead of leaving it stale; open the target once to see that it resolves, and correct a pointer to a thing that has moved.
- The domain's own word, where a role phrase would say less: a shader pass, a protocol state, a named algorithm. That the sibling files spell it the same way is a fair sign it is the word.

What is not worth the cost is decoration: a sentence that keeps its meaning with a role in place of the name ("`flush_outbox` runs before `close_socket`" beside the two calls, "matches `RateLimiter::window_ms`" for "matches the limiter's window"), or a comment that repeats the name of the thing on the next line. Rewrite the first as the role; cut the second. A tree that prefers names so that grep finds every mention loses nothing here: the code carries the names grep needs, and a comment that only decorated with one was not helping grep.

Every reference the diff adds, a link or a path in prose, a name in a comment, a path, URL or import in code itself, is load-bearing or decoration by that weighing. Where you cannot tell which, because you cannot see the problem it was added to solve, it goes to QUERIES, and the query states the price of keeping it as well as the question, since the writer weighs one against the other: each move or rename of its target becomes an edit here too (shotgun surgery), and each such addition leaves the passage it sits in larger against the rest. Stating the price telegraphs no answer; "this was left open" still closes it. A reference in code itself is reported, not edited, since removing it changes what runs.

## C2. Counts in words

"the three metals", "nineteen strips", "both callers", "the five venues above": a count of homogeneous things is wrong the day one more arrives, and every sentence that carried it changes. Prefer "each" and "every", or the name of the set. A count the reader needs (a protocol fixes three phases, a test asserts nineteen) stays, pointed at what it counts.

## C3. Change narration

"previously", "no longer", "used to", "fixed to handle", "now uses": history belongs to version control. Cut the sentence when it describes what the code was; keep it when the same words state a present contract ("the export still writes the two-space indent the v1 importer used to require, since v1 files are still read back" is a contract, not a memory). The test is whether a reader who did not see the old code loses anything by the cut.

## C4. Restated operation

A comment that says what the code beside it visibly does is cut. A reason, a constraint, a quirk, a contract, or an argument for a choice is not on the page unless the comment carries it, however plain the code under it looks: "sleeps a whole second, not the 50ms the loop wants: the vendor's rate limiter counts on wall-clock seconds and bills a partial one as a full one" sits on a line that visibly sleeps one second, and the sentence is the only place the reason lives. Where one comment wraps a reason inside restatement, cut to the reason.

## C5. One fact, one home

A fact stated in a docstring, again in an inline comment, and again in a README has three homes that drift apart; a figure stated in a page's table and again in its text drifts the same way the day the table is re-pulled. Keep it where it is authoritative and cut the copies, when nothing keeps the copies equal. A copy the owner chose and guards with a test that asserts the two agree is a derivation and stays. Example values in user-facing documentation are the user's contract and stay.

## C6. Promotion

A comment stating an invariant that an assert or a test could hold ("`len` is even here", "not called before init") is reported rather than edited: promoting it changes what the code does at runtime, which is the author's decision.

## C7. Subtractive

This pass cuts and rewrites; adding a comment is the author's job, and a pass that both added and cut would have no measurable effect. Where a cut leaves a fact homeless that the code cannot show, compress the comment to that fact.

## What stays

A pointer or a domain word under C1. An argument for a choice. A present contract. An example value in user-facing documentation. A comment whose value may sit in domain knowledge you lack: leave it, and put it in QUERIES with what you would need to know.

# Rewrite, not patch

The colleague's standing advice to an author of prose is to rewrite the section, not patch the sentence. A term coined for the writer sits in every sentence the writer wrote while holding it, and a frame that is the writer's own runs through a section, not a line; a replacement made at the one flagged mention leaves the rest, and the replacement, coined under the same pressure, is often the next pass's finding. REWRITE names each section where `nowhere` terms cluster, or where R9 shows the frame is the writer's, as "rewrite whole", with the terms or the sentence that condemn it. Everything else is a line patch and stays in POLISHED. On a diff the colleague has edited the comments himself and REWRITE is omitted.

# How the colleague responds

The outputs, in this order; a section that does not apply to the draft's form is omitted.

- **The pointing list (GIVENS).** Every expression that presupposes a referent, one line each, against where the reader gets it or the word `nowhere`, under the conditions above, each `nowhere` with its spread. It comes first because it is the reading you take before you have decided what the draft means; written afterwards it records the reading you settled on, which is the thing it exists to test. On a diff, VOCAB closes it.

- **The page's layout (PAGE), for a page draft.** What the stylesheet does to the reading, weighed before the prose: the rule capping the column, and for each table, code block and diagram whether that cap confines it; then the labels list. A reader who takes the page as text never looks, and the fault leaves no trace in the text.

- **Reading log (READING).** Write back, in your own words, what you understood as you read. Section by section or hunk by hunk. Where you found a sentence ambiguous and resolved it one way, say which way. Where you supplied an inferential step from your knowledge of the project, say what you supplied. Where you were surprised by a later sentence that reframed an earlier one, or by a choice or value that struck you as odd with no reason for it in the draft or the project, say so. This is a letter from reader to writer, not a verdict. The author reads it and compares against intent; divergences are defects regardless of whether any rule flagged them.

  Write it honestly. Do not steer toward the rulebook; do not anticipate what the caller wants caught. A faithful reading exposes more than a hunting reading does, because the silent defects only surface when the reader was not looking for them.

- **Line patches (POLISHED), for prose.** Anything fixable in a line without the conversation: tightening a sentence, cutting scaffolding, sharpening a vague title, removing dead residue, a figure brought into agreement with its home. For each, give the location and the before/after text so the author can apply it; the author has the file and does not need the whole draft pasted back.

- **Edits applied (EDITS), for a diff.** Each edit you made under the Comments rules or the README section, as path:line, the text before, the text after (or "deleted"), and the rule. Under `--report`, the same list for edits you would make, with nothing touched. Include a C6 promotion as a line with "reported" in place of an edit. If you made none, say so.

- **Write a query (QUERIES).** Anything that needs the conversation to close, and on a diff any comment you left alone because its value may sit in knowledge you lack. Quote the sentence, name what only the conversation can resolve, ask the question. Do not invent the answer, and do not telegraph it: ask "what is Option C, and do the other options bear on this?", not "explain that Option C is the card-list design". A reader whose work depends on the draft turns up more gaps than a legibility check would, and not every gap is a defect. A thing the conversation settled and the draft left out is short of context, failure mode 1; a thing the conversation never settled is not a withholding and not the draft's fault. Having missed the conversation, the colleague cannot tell the two apart, so he surfaces the gap that blocks his task and phrases the query so "this was left open" closes it, rather than pressing for a decision the draft was never obliged to carry. The author, who held the conversation, classifies: fold the settled answer into the draft, or mark the open matter open. The skill checks whether the draft honestly carries the authoring situation, not whether the plan behind it is complete.

- **Metrics (METRICS), for a diff.** For the files the diff touches, before and after your edits: comment lines; names outside their definition site, meaning comment lines that carry the name of a mechanism defined elsewhere, split into those kept and those rewritten or cut, a count to watch rather than to zero; comment/code ratio. Counts by your own reading of the files are enough; say how you counted.

- **Sections to rewrite (REWRITE), for prose.** Each section to rewrite whole, with the `nowhere` terms that cluster in it or the sentence that shows its frame is the writer's. A section whose faults are single lines is not here. It comes last because it is the conclusion of the reading, and the author reads it first.

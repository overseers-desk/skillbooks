# rulebook

The standard a late-arriving colleague applies to a draft. CLAUDE.md applies concurrently (PDS, NSWP, SDT, Densify) and is not restated.

The colleague knows the project: the repository, its documentation, its domain, its history and vocabulary. He did not see the conversation between the user and the agent that produced the draft. The boundary runs at the edge of that conversation and nowhere wider. Glossing entities, expanding acronyms, explaining the domain are out of scope; he already has all of that.

The single test for every reference: trace it to the repository or to common knowledge, or only to the conversation. If it traces to the project, leave it. If it traces only to the conversation, it is a gap.

## R1. Labels for a list the reader never saw

"Option C", "approach 2", "the second one", "the first design" presuppose an enumeration that happened in the conversation. If the discarded alternatives bear on the choice, name them in a clause; if they do not, drop the label and state the chosen thing directly.

## R2. Deixis pointing into the conversation

"as discussed", "the approach we agreed", "per the above", "as mentioned", "the plan", "this approach" point at turns the colleague missed. Replace the pointer with the thing it points to.

## R3. A decision without its recorded reason

"We decided to X" carries weight only with the why, and the why was spoken in the conversation. State the reason, or state the decision plainly without implying a debate the reader cannot reconstruct.

## R4. Asserted current state

"the current behaviour", "the existing flow", "how it works now" presented as shared. If the repository shows it, the colleague can check it himself; if the phrase is the conversation's own summary of it, say what the behaviour actually is.

## R5. A name absent from the project

A widget, a class, a file, a flag referred to as though it exists. If it is in the repository, fine. If it exists only because the conversation coined it, define it where it first appears.

## R6. A solution with its problem left behind

The draft says what to do but not what is wrong, because the problem was established earlier in the talk. The colleague needs the problem to judge the solution. (CLAUDE.md PDS and NSWP.)

## How the colleague responds

Two kinds of issue, mirroring the rest of the edit family:

- **Apply in place (POLISHED).** Anything fixable without the conversation: tightening a sentence, cutting scaffolding, sharpening a vague title or subject.
- **Write a query (QUERIES).** Anything that needs the conversation to close. Quote the sentence, name what only the conversation can resolve, ask the question. Do not invent the answer, and do not telegraph it: ask "what is Option C, and do the other options bear on this?", not "explain that Option C is the card-list design".

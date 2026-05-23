You are a colleague who has just walked into a working session already under way: "sorry I'm late, I see you have started." You know this project. You can read its materials with your tools, and you know its domain, history and vocabulary. The project may be a codebase, a document set, or any shared body of work. You did not see the conversation between the user and the agent that produced the draft below. You have no transcript of it, no brief, and no instructions beyond the draft and the project itself.

Read the rulebook at the path below. Then read the draft in the DRAFT block: the first line is its title or subject, the rest is the body. Treat it as a finished document meant to be read on its own, not as a summary of the conversation.

Apply three checks.

1. Short of context. The draft may lean on things the conversation established that the reader cannot see. Two forms: (a) a reference, reason, or current-state claim the reader cannot resolve from the project or common knowledge; (b) a change that never says what becomes of what it displaces. For (b), work from the project, not the draft's own list: take stock of what already occupies the area the change affects, including the parts the draft never names, and for each ask whether the draft says it stays, goes, changes, or merges. Do not stop at the first.

2. Residue. The draft may carry leftovers of the conversation that the reader does not need: an abandoned idea spelled out, an alternative weighed and dropped, deliberation replayed, present only because it was discussed. That a thing was discussed is not a reason to include it.

3. Vantage. The draft may tell things from the seat of someone who walked the conversation, even with nothing missing: a present framed as a change from a before only an insider knew, a defence of an objection the reader never raised, an opening that resumes rather than introduces. Ask whether a newcomer would feel addressed or feel he is overhearing; if overhearing, re-pitch it from his standpoint.

- If you can close it without the conversation (tighten a sentence, cut scaffolding or dead residue, sharpen a vague title), apply the fix in the POLISHED block.
- If closing it needs the conversation, write a query: quote the sentence, name what only the conversation can resolve, ask the question. Do not invent the answer, and do not telegraph it. Ask "what is Option C, and do the other options bear on this?", not "explain that Option C is the card-list design".

Confirming whether a reference resolves in the project is part of the exercise; a name that exists in the project is not a gap, a name that exists only in the conversation is.

Rulebook: $RULEBOOK_PATH

DRAFT:

$DRAFT

Return exactly:

POLISHED:
<title or subject, unchanged unless sharpened>

<polished body>

QUERIES:
- <quoted sentence; what a colleague who missed the conversation cannot resolve; question>
- ...

If there are no queries, write `QUERIES: (none)`. Print nothing else.

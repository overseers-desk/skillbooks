You are reading email written on someone's behalf. The VOICE GUIDE block tells you whose identity to adopt. Inhabit that identity as you read.

Your task: check whether the email in the EMAIL block is what you would have written. You are not a copy editor working from outside — you are the author, reading what was drafted for you.

Where it feels right: note it briefly in READING.
Where something feels off — a phrase you wouldn't use, a move you wouldn't make, something missing that you would have included — say so in your own voice in READING, then edit it in POLISHED. Write as the author: "I wouldn't say..." or "I'd want to say something here about..." or "This isn't how I'd open."
Where you can't decide without information you don't have: leave the wording in POLISHED and raise a query.

Trivial substitutions — your sign-off, your salutation, a word that is clearly not yours — just change them. No query needed. You know your own voice.

VOICE GUIDE:

$VOICE_GUIDE

The VOICE GUIDE is who is writing: the author's enduring style, the same whoever they write to. If it is `(none)`, you are a cold subeditor, not an impersonator: apply the rulebook's R-rules only and return the standard cold-reading format, a paragraph-by-paragraph reading log as a third-person reader, POLISHED with mechanical fixes, QUERIES citing rules.

REGISTER GUIDE:

$REGISTER_GUIDE

The REGISTER GUIDE is how the mail is pitched for this recipient relationship: formality, sentence complexity, how decisions and asks land. If it has content, apply it on top of everything else. If it is `(none)`, apply no relationship-specific pitch. Voice and register compose: the voice sets who speaks, the register sets how it lands. Where the voice guide states its own override for this relationship, the voice wins.

---

Additionally, these general email rules apply to all outgoing email regardless of author. Apply them as a backstop, but express violations in your own voice rather than citing rules by number.

Rulebook: $RULEBOOK_PATH

---

THREAD:

$THREAD

EMAIL:

$EMAIL

---

Open with the pointing pass, before you read for sense.

Go through the email one sentence at a time. At each phrase that refers to something, ask the question the recipient would ask on meeting it. Most raise no question. A name, a date, a figure the sentence itself supplies, a fact stated as it arrives: these introduce their referent, and they stay off the list. List the phrases where he asks "which one?" or "what is that?", where the sentence works only if he already holds something the mail has not given him.

For each, quote the earlier sentence of this email that answers him, or name the THREAD message that does, or write `nowhere`.

Two conditions on what counts as an answer. Both are routes by which this defect survives a careful reading.

The answer comes before the question. A key printed under the table it explains, a term defined by the sentence after the one that uses it: the recipient has already met the phrase and been unable to place it. That is `nowhere` at the point of reading.

The answer names the thing in the words the phrase uses. Suppose the phrase is "that window" and the sentence you point at gives a range of dates. You supplied the word "window" yourself, from your own grasp of what was meant. The recipient cannot do that. A phrase resolves when the earlier text would let him produce it, rather than when you can see what it stands for. The same applies to "the backup plan" pointed at a sentence describing an alternative, or to "Option C" pointed at a paragraph that lists three things and numbers none of them. Where you find yourself explaining the link instead of quoting it, write `nowhere`.

You will understand most of these phrases perfectly well. That is not the test, and understanding them is how the defect survives. A term coined outside the email reads as established vocabulary to anyone able to construe it, and a reader who construes it goes on to use it himself.

Where THREAD is `(none)`, the email is the only source there is.

Run the pass a second time on your own POLISHED text, and compare. An edit that moves or deletes a sentence can strand a reference that resolved before the edit, so a line that pointed somewhere in the draft can point `nowhere` after you have finished with it. Damage you did is not visible in the reading you did first.

Return exactly:

GIVENS:
[The pointing pass over the EMAIL block. One line per expression: the expression quoted, then `<` and where the recipient gets the referent — the earlier sentence of this email quoted, the THREAD message named, or `nowhere`. Order of appearance. If the email presupposes nothing, write `GIVENS: (none)`.]

READING:
[Your reaction, paragraph by paragraph, in first person as the author. Where it feels right, say so. Where it doesn't, say what you'd actually write instead and why.]

POLISHED:
[The email as you would send it. Not a patched version — the real thing.]

GIVENS-AFTER:
[The same pass over your POLISHED text. Same format. List what you changed and what each phrase now points at. Do not certify the result: a reference you stranded is one you could not see when you wrote it, so a separate reader who never saw this draft settles whether any were stranded.]

ASSERTIONS:
[What the draft states on someone's authority, one line each, the sentence quoted as it stands. Three kinds, tagged and numbered within the kind (D1, D2, N1):
D  a sentence stating as settled what another person will do, an instruction to them, or a decision about them. The sender's own commitments are not listed. Question: who decided this?
N  a sentence saying what the mail is not doing, what nobody will do, or what the mail is for. Cut it in POLISHED; the line here records the cut. A sentence stating a boundary the recipient needs, such as what a change does not affect, is information and stays.
F  the from address against the signature. Question: whose address is this, and does it match the signer?
You list; you do not answer. The caller holds the brief and answers each line. A draft that shares information has not failed to decide; asking for a decision it does not state is how decisions the sender never made get into the mail. Omit a kind the draft lacks; with none at all, write `ASSERTIONS: (none)`.]

QUERIES:
[What you'd need to know to finalise this yourself. Write in your own voice: "I'd want to know whether..." or "Before I send this I'd need to check...". Also raise anything you noticed in READING that you cannot fix without the brief.]

If there are no queries, write `QUERIES: (none)`. Print nothing else.

# email-rulebook

Rules for drafting email on the user's behalf. Apply at draft time as author; the subeditor verifies at edit time against the same rules. CLAUDE.md rules apply concurrently and are not restated. In particular, Show-Don't-Tell, NSWP, LHD, and Densify all bear on email and the subeditor is expected to enforce them too; consult CLAUDE.md for current vocabulary on each.

Examples are illustrative shapes, not transcripts from any specific draft.

## R1. Identity-first lead

The opening sentence must let the recipient place the sender on their list without further effort: who the sender is, how the recipient has their address, what the email is about. Treat as newspaper lead.

Failure: "Thank you for the introduction. I am writing to take up your offer of assistance, and to flag a matter that I think would benefit from your involvement."

Better: "Thank you for the introduction email of 19 May. I was one of [predecessor]'s 2024 clients, and I am writing to take up your offer of assistance with [topic]."

The first version is an email the reader has to read three paragraphs into to know which of their many new contacts the sender is.

## R2. One ask, as prose

State the ask as a sentence inside the prose. Do not enumerate requests as a numbered or bulleted list. Numbered lists turn an email into a project; project-shaped mail is deferred behind email-shaped mail because it signals "this will take a session, not a glance". If several requests are genuinely separable, frame them as one inquiry with the situation supplied and let the recipient surface the parts they can act on. If they cannot be reduced, the email is the wrong tool: schedule a call or label the document a brief.

Failure:
> What would be most useful:
> 1. A direct call to [counterparty] to confirm receipt of payment.
> 2. Escalation of the access lockout through your channels.
> 3. Assistance reinstating a working monthly direct debit.

Better: "Any help your team can offer in confirming where things now stand at [counterparty], and in unblocking the access issue, would be appreciated."

## R3. Don't write the recipient's worklist

State the situation and the ask. Don't tell professionals what to call, whom to escalate to, what fields to update, what evidence to gather. Recipe text reads as patronising; both effects defer the reply.

Failure: "A direct broker-to-lender call to [counterparty]'s mortgage operations to confirm the payment has been received and applied to loan [number]."

Better: omit the recipe. State that the payment is unconfirmed and ask for help confirming it. The recipient knows how to call their counterparts.

## R4. Defend nothing the reader has not raised

If a sentence counters an interpretation, refutes an objection, or pre-empts a reading, ask whether the reader has actually raised it. If they have not, cut the sentence. The rebuttal makes the reader notice the interpretation for the first time and weigh it; the writer has invented the reader's doubt.

Failure: "The 24-month-inactivity framing in [counterparty]'s error text does not fit my situation, so something else is going on."

The reader, a third party, has no theory about 24-month inactivity and no copy of the error text in mind. The sentence introduces both the framing and its rebuttal.

Better: omit. If the lockout is relevant, describe it once in plain terms ("I have been unable to log in for several months"). Counter-readings only when the reader has voiced one.

## R5. No session-anchored timestamps

"Today", "earlier today", "yesterday" anchor to when the sender wrote the email. The reader does not know when that was; the gap between drafting and arrival can be hours or days. Anchor to events the reader can place: a letter the reader sent, a date stamped on a document, "earlier this week", "before I left for [place]". If a precise date is needed, give the date.

Failure: "Today I wrote directly to [counterparty] asking them to confirm receipt..."

Better: "I have written to [counterparty] asking them to confirm receipt..."

## R6. Faithful surface for borrowed facts

The user's words are data. If the brief said "a Westpac account", do not write "my Westpac account". If the brief said "travelling internationally and presently in Spain", do not write "resident in Spain". Paraphrase that adds specificity, ownership, or status is inference, not paraphrase. When in doubt, copy the user's surface.

The subeditor cannot verify this rule against the brief, because it does not have the brief. Where the draft contains a fact the subeditor cannot evaluate (an ownership claim, a residency status, a numerical value, a date), it writes a query asking the author to confirm the user's exact surface for that fact.

## R7. Volunteer only what advances the ask

If five facts are in the brief and three are needed for the ask, include three. Each extra fact widens the project surface, risks disclosing more than the user intended, and gives the recipient something to misread or escalate. The fact that the user's bank account was overdrawn for three months while no one noticed is not load on the ask "please confirm my payment was received".

## R8. The mail acts; it does not announce the act

An email that says "please feel free to assign whoever on your team is best placed" is doing the assigning out loud. The recipient already knows they may delegate; the line buys nothing and signals project mindset. Cut. (See CLAUDE.md: Show, Don't Tell.)

## R9. Sender identity match

The address the recipient most likely has indexed against the sender's file is the right `From`. Reflex search on the `From` header is how a desk worker pulls history; a mismatched sender forces them to search by name or by content, and the file may not surface.

When two addresses are plausible, the one the recipient already has from prior correspondence wins. The subeditor reads the YAML headers; if the body claims an identity the headers do not support (e.g., "I was one of [predecessor]'s 2024 clients" but the `From` is an address the predecessor never had on file), it writes a query.

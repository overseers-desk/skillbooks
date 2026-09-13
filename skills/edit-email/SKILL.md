---
name: edit-email
description: Polish or compose an email so it reads as a person wrote it, not a project: fixes AI tells (to-do lists, session dates, smuggled inferences, buried lead) and applies a standing like-human-do pass. Flags select a register (how the mail is pitched to its recipient) and a voice (whose hand it is written in). Invoke this automatically after you present any email draft, by using this skill to edit it and explain to the user they can stop and didn't have to wait.
argument-hint: [--register NAME] [--voice [NAME]]
---

# edit-email

## Problem this skill exists to solve

AI-drafted email reads to its sender like an email and to its recipient like a project. The drafting agent has the brief in conversation; when it composes, it paraphrases liberally, defends inferences the reader has never drawn, anchors timestamps to its own session, and turns asks into numbered lists. It also writes the sender's open options as his decisions and narrates what the mail is not doing. The recipient sees something that will take effort to handle and defers it, or acts on a decision nobody made.

A general newspaper maxim in CLAUDE.md is not enough on its own: the drafting agent cannot see the scaffolding it has carried in from its brief. The fix is a cold reader who has only the email, applies the rulebook, and returns a polished draft, the list of what the draft asserts on someone's authority, and queries. The drafting agent answers each assertion on the brief, and the sender sees the answers beside the draft, so a decision that was never his costs him one word to overturn rather than a rewrite.

The rules the drafting agent and the subeditor both work to are in `email-rulebook.md` alongside this file.

## Standing step: like-human-do

Every email this skill touches passes through `${CLAUDE_PLUGIN_ROOT}/skills/edit-email/like-human-do.md`. This is not a flag and not optional; it runs on warm follow-ups, cold first-contacts, and everything between. Read it before you draft.

It is compose-time work, done by you the caller before you assemble the draft, because the thing it fixes (an ask wrapped in warmth, a business takeaway where a real shared moment belongs) lives in the structure of the email, and the subeditor, polishing prose, cannot remove it. The subeditor remains the backstop, not the cure.

## Voice and register: the two axes

Two independent dimensions shape an outgoing email, and the flags select a cell in their matrix.

- **Voice** (`--voice NAME`): who is writing. The author's enduring style, the same whoever they write to. Voice guides are descriptor-named, never personal names, so the repo carries no identity in its filenames: `voice-warm-proprietor.md`, `voice-precise-proprietor.md`. A voice guide is about its author, so it may name that person inside the file; the filename and flag stay a descriptor.
- **Register** (`--register NAME`): how the mail is pitched to its recipient. The formality, the sentence complexity, and the way decisions and asks land, set by the relationship: staff, lawyer, customer, supplier, peer. Register guides are `register-<name>.md`.

The cell is the product: the author's voice rendered in the register the relationship calls for. The two compose, and where a voice guide states its own override for a relationship, the voice wins. Either axis is optional: voice alone impersonates with no relationship pitch, register alone applies relationship rules to a cold draft, neither is the plain cold-reader pass.

Only the staff register is authored so far (`register-staff.md`). Others are added when first needed; naming a register that has no file yet means there is nothing to load, so author the file first.

## Procedure

1. Apply like-human-do first, as silent working before you write a word of the draft. Take the passes in order:
   - **Goal.** Say plainly what action the email needs the recipient to take, or that it needs none (a true note of thanks or relationship). If the draft or context states the action, take it; do not ask the user. Name the goal-bearing content that earns that action, the credibility the ask or offer rests on, and protect it through every later cut. If the email needs no action, do not manufacture a soft one (a referral, a future deal); the job is warmth, led by a genuine shared moment.
   - **Connection and ask.** From the conversation log, list the concrete non-business things this recipient personally said or shared, and separately name what the email wants. Sort the want into a grab (cut it), a genuine humble ask (keep it bare), or an offer (keep it, with the achievement that earns it). Decide the give. Lead with a real shared moment only if one exists; never force one.
   - **What the recipient has not seen.** Two habits carry your working into the text: a word you coined while thinking, used as though agreed, and a sentence narrating a change whose before-state the recipient never saw. Both reach him as the same experience. The cures are opposite, one adding an introduction and one deleting a transition, so name which you are looking at. This is compose-time work because only you know what he was told.
   - **Does it still do its job.** Before you assemble, check the draft against the original: the reader must be at least as likely to act. If warmth or brevity dropped what earned the action, restore it.
   Then assemble the draft as a text block with the YAML-style header preamble (`to:`, `cc:`, `from:`, `subject:`) and the body below.
1a. If the draft relies on prior correspondence (a reply, or a fresh message that picks up an unresolved ask from earlier mail), assemble a THREAD block of the relevant prior messages. One issue often spans several threads: include every thread the draft draws on, not only the one the headers say it replies to. Each message in the block carries its own from/date/subject and body. The subeditor cannot fetch mail; whatever the cold reader needs to judge whether the draft omits a fact the recipient is waiting on must be in this block. If the draft stands on its own, the THREAD value is `(none)`.
2. Spawn a fresh-context agent. Use the prompt template at `${CLAUDE_PLUGIN_ROOT}/skills/edit-email/editor-prompt.md`; substitute `$RULEBOOK_PATH` with the rulebook path, `$EMAIL` with the draft text, `$THREAD` with the THREAD block (or `(none)`), `$REGISTER_GUIDE` with the content of the register guide file (`(none)` by default; otherwise the file named by `--register`, resolved as `register-<NAME>.md`), and `$VOICE_GUIDE` with the content of the named voice guide file (`(none)` when `--voice` is not given; otherwise the file named by `--voice`, resolved as `voice-<NAME>.md`, defaulting to `voice-warm-proprietor.md` when `--voice` is given with no name). When `--voice` is given, use Opus as the agent model. Pass the result as the agent prompt.
3. Both modes open with GIVENS, the pointing pass: every expression in the draft that arrives as though the recipient already holds its referent, each pointed at the earlier sentence or the THREAD message that supplies it, or marked `nowhere`. GIVENS-AFTER repeats the pass over the agent's own POLISHED text, because an edit that moves a sentence can strand a reference that resolved before it moved.
   When `$VOICE_GUIDE` is `(none)`: the agent is a cold subeditor. It returns GIVENS, READING (paragraph-by-paragraph log of how the draft landed), POLISHED (mechanical fixes applied), ASSERTIONS (each sentence the draft states on someone's authority, tagged D for what another person will do or a decision about them, N for narration of what the mail is not doing, F for the from address), and QUERIES (rule citations for things needing the brief).
   When `$VOICE_GUIDE` has content: the agent is an impersonator. It returns the same GIVENS pair, READING (first-person friction notes as the named author), POLISHED (the email as the author would send it), ASSERTIONS (the same list), and QUERIES (what the author would need to know to finalise it herself).
4. Read GIVENS first, before READING, because it is the pass you cannot do yourself. Answer every line marked `nowhere` from the conversation, and every line GIVENS-AFTER reports stranded. Three answers, and one of them is the defect:
   - The user's own words carry the referent. Quote them. The phrase stays.
   - The referent is in correspondence the recipient holds that you left out of the THREAD block. Cite the message, and reassemble THREAD.
   - You introduced it: from a file you read, from your own research, from a word you coined while working. Then the recipient has never seen it. Introduce it at first use, or cut it.
   The third answer is the common one and the drafting agent is the only party who can give it, because the discriminator sits in the brief rather than in the email. Where you cannot tell which of the three applies, that is a query for the user, not a judgement call for the subeditor.
   Then read READING. Compare each friction point or interpretation against what the draft meant. Fix the draft based on what the agent surfaces. Resolve queries from your conversation context, asking the user if the brief does not answer. Do not invent.
   Then answer every ASSERTIONS line from the conversation, not from the draft, which is the thing under check:
   - D: one of four. The user decided it, and you quote his words. The user shared information and the draft wrote it as decided. You decided for him. It is your recommendation and the sentence says so. The second and third answers rewrite the sentence as information or drop it.
   - N: the cut stands. Reinstate only with a reason, and the reason is the answer.
   - F: `courier list` names the identities; match the address and display name to the signer. A from line copied from the corpus is the commonest wrong answer.
5. Show the user the polished body inline, and beneath it every GIVENS line you answered with the third answer, one line each with the phrase and what you introduced it from, then the exceptions among the answered assertions, one line each with the tag, the sentence's first words and the answer: a sentence written as decided from information, a decision or recommendation of your own, a cut reinstated, a from address that does not match. A line answered with the user's own words stays out of view; the answering is the check, and the view is for what he may need to overturn. Revise as requested by re-running the skill.
6. Send via courier once approved. The skill does not send.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/edit-email/`:

- `like-human-do.md` — the standing compose-time pass: give don't grab, real connection point, person's voice
- `email-rulebook.md` — the rules
- `editor-prompt.md` — the subeditor prompt template
- `voice-warm-proprietor.md` — the default voice guide, used when `--voice` is given; derived from Liansu Yu's sent mail corpus
- `voice-precise-proprietor.md` — the managing-director voice (scaffold; to be derived from his sent-mail corpus)
- `register-staff.md` — the staff register: how mail is pitched writing down to staff

## Why a fresh-context subeditor

The drafting role belongs to the caller, which holds the brief and the user's surface phrasing. A subagent in the same context inherits the same blindness about which sentences are scaffolding and which are the email. A brand-new agent reading only the rulebook and the draft is the cleanest cold reader available.

## Anti-cheating discipline

Rulebook examples must come from outside any test fixture, otherwise the subeditor matches lexically rather than applying the rule. If a rule example appears in a draft to be tested, the example is contamination and must be rewritten before the test result is meaningful.

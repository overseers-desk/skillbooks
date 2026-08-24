---
name: writing-invariants
description: "About to create or amend a repository's INVARIANTS.md, or judging whether a rule belongs in one. Triggers: writing-invariants, invariants, INVARIANTS.md, what must hold."
argument-hint: "[optional: the candidate rule, or the path to the invariants file]"
---

# Writing invariants

Read when creating or amending a repository's INVARIANTS.md. Meeting an invariant mid-work is a design fork that belongs to the owner, and obeying it is the job; this guide governs the other side, the writing of the rule in the first place.

## The problem invariants solve

Left to local judgment, each session makes choices that are reasonable alone and ruinous in sum: a second implementation of a thing that exists, a file placed where convenience put it, another component's internals reached into without the dependency being declared. The sum is a monolith, a codebase that cannot grow apart, install apart, or be maintained. An invariant is where the owner draws that line. Past it, a change is not a fix but a redesign, and redesigns are decided by the owner, not by whoever is holding a bug. Humans and AI break design rules the same way, so an invariant binds whoever touches the codebase.

## The test: five questions of every candidate line

1. Future-binding: does it bind files and components not yet written, rather than describe what exists today? A tree of the current directories is an enumeration, and the file system already answers what exists.
2. Growth-proof: no counts, and no current file, directory, or component name unless the name is itself the rule. A name or count embedded in an invariant freezes renames and growth the principle never demanded.
3. Design-grade: would breaking it change the design, rather than untidy the code? A line that fails this is a convention; keep it in the project's prose.
4. Recoverable why: could a stranger reconstruct the problem it prevents? An unstated why the reader can supply is fine; the question fails only the rule whose why is unrecoverable, a fence with no visible builder, inviting removal or a good-faith route-around by a reader who invents the reason and its boundaries. A why that is lived history cannot be reconstructed, only cited: carry the incident (the "First case:" form), since inference recovers mechanism but not weight.
5. Anyone-readable: does it read to any contributor, human or AI? A rule phrased in turns, agents, or context windows tells a human contributor it is not addressed to them.

A model line: `vendor/` holds copies whose home is upstream, `modules/` holds modules authored here. It names two folders because the folders are the rule, carries no module count, and reads to anyone.

## Form

One single-line list item per invariant. The item states the rule whole and may point at the domain document that elaborates it; the elaboration cites the invariant rather than housing it, since a rule living only inside a domain document is invisible to the reader who opens the invariants list to learn what must hold.

Creating the file is half the job: wire `@INVARIANTS.md` into CLAUDE.md in the same act. A session that meets a link has to choose to follow it, and a session with a bug in front of it does not; the import lands the rules in context before any work starts, so there is no errand left to skip. Keep a prose sentence beside the import for a human, and for any tool that does not expand `@`. First case: a session worked a repository without opening its invariants, having read "before doing any work here" as covering edits but not looking.

## Changing one

An invariant changes on the owner's decision, recorded where the invariant lives. An author who finds an invariant wrong proposes the change and waits; editing the rule to fit the work in hand is the breach the rule exists to stop.

---
name: halfway-house
description: "A single decision or open problem has surfaced, and the reflex is to put it to the user or solve it now. Read this before escalating. Triggers: halfway-house, settle or solve, on the path."
argument-hint: "[optional: the decision or fork in question, if it is not already on the table]"
---

# Halfway house

The reflex, on surfacing a fork, is to treat it as a question the user must answer now, and on surfacing an open problem, to treat it as one to solve before moving. Most are neither. A halfway house is a decision you can settle into safely: it moves the needle, carries no major downside, and leaves firm ground to stand on while the path not taken waits as a filed request. Settling there clears the ground — the situation stabilises, and how it then performs, watched later or the same day, decides whether the other path is ever worth walking. The command's work is to tell a halfway house from the path itself, so the user's attention is spent only where settling is unsafe.

The distinction it draws is between a decision that is *on* the path and one that *is* the path. On the path: you can stop here, banked and net-ahead, and keep walking without the answer. Is the path: there is no ground to walk on until it is answered.

## 1. The test

Three questions, in order:

- **Is there a safe settle?** One option can be taken now that moves the needle — a real improvement over the status state — with no major downside, and is the cheapest of the candidates to revert.
- **Is settling stable?** The state you land in holds on its own: it does not read as broken, half-built, or misleading to whoever meets it next.
- **Does the open fork block what comes next?** Leaving it unanswered constrains or destabilises future work — anything you would build next that has to be torn up once it is finally answered.

Yes to the first two and no to the third: a halfway house. Otherwise it is the path, and it is resolved now. A decision sitting on the line is the path, not a halfway house — a blocker mistaken for a waypoint is caught by real use in a month; a waypoint mistaken for a blocker spends the user's attention for nothing.

## 2. If it is a halfway house: settle, clear, file

- Take the settle point — the option with the smallest downside, cheapest to revert — and state it with its one-line reason. Make this call yourself and defend it; a halfway house is not handed up as a question.
- Commit, or otherwise land the change, so the ground is clear and the situation can be watched as it settles. Coherent steps, one commit each.
- File the path not chosen as a future request: what it would change, and the signal from real use that would call it back — a performance reading, a complaint, a count — rather than a fixed calendar date, unless the user named one. Written forward-only, as the current state with the open branch recorded, not as a history of the deliberation.

## 3. If it is the path: resolve now

There is no firm ground without the answer, because what comes next is built on it. Resolve it before proceeding. Where the answer is genuinely the user's — design intent, his circumstance, a tradeoff with no dominant arm — this is the case that earns the question; ask it, having first derived what you can and named the cheapest-to-revert default.

## Scope

The test weighs one decision at a time. When a review or diagnosis has ended in a whole pile of findings, sort it first — clear fixes apart from the decisions someone owns — and bring each surviving decision here on its own; the pile is not the unit this test takes.

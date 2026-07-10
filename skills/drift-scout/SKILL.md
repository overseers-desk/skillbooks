---
name: drift-scout
description: "Find drift — stale debris a refactor, rename, or move left in a codebase's edges. Triggers: drift-scout, find drift, what did the rename miss, stale references, sweep the edges."
argument-hint: "[optional path or scope to focus on]"
---

# Drift scout

Drift is the debris a change leaves behind. A rename, a move, a restructure, or a schema change updates the place it was aimed at and leaves the periphery still describing the world as it was. The periphery is where confusion compounds: a later reader, human or agent, trusts the stale edge and reproduces the old shape. Your job is to find that debris and prove it real.

The trap to avoid first: auditing the codebase cold for "anything wrong." That yields generic, low-confidence advice — plausible refactors nobody asked for. Drift is specific and has a source. Find the sources, then their wakes.

## 1. Find every wave, not one

Read the version-control history for structural changes: a renamed concept, moved or split files, merged or replaced modules, a changed identifier, a schema or data-layer rename, one mechanism swapped for another. Each is a wave; drift is its wake.

List them all from recent history. There are usually several, and they overlap (one commit renames a directory and the table it holds in the same breath). Do not stop at the first wave you find — the one you skip is the one whose wake nobody has swept, which is exactly where the surviving drift is.

Ground yourself before searching wide: from one wave, find a single confirmed stale edge — a place outside the change's focus still using the old form — and confirm it (step 4). That instance teaches you the shape of drift in THIS codebase, which no generic checklist predicts. Then carry the same search to every other wave.

If history is unavailable, substitute another ground: a recently fixed bug, a documented migration, two siblings that disagree. Start from one concrete, real discrepancy, never a blank audit.

## 2. Extract the full retired vocabulary of each wave

From each wave's diff, list EVERY token it retired or replaced, not only the obvious one:

- old names and old paths
- old identifiers, including data-layer ones (table, column, collection, field names)
- old directory layout
- old call shapes
- literal strings that quote any of the above — error messages, log lines, config values

The token you forget to extract is the token whose drift you miss. A directory rename is easy to remember; the table or identifier renamed in the same wave is the one left behind in a test fixture or a script.

## 3. Sweep the edges, not the core

A change is applied where attention was — the core. Attention runs out at the edges. For each token from step 2, search the whole tree, and weight these places, which updates routinely miss:

- test harnesses, fixtures, and scripts
- build, CI, and configuration files
- documentation and top-level descriptions
- comments and inline documentation sitting on changed code
- error and log strings that quote a path or a name
- generated or derived artifacts, and anything a tool reads as input

A hit in the core is usually intentional; a hit at an edge is a drift candidate.

## 4. Confirm by running, and run first

A stale reference is a suspicion until you show it bites. Reading proves a string exists; it does not prove the string sits on a path that executes.

Run first. Execute the test suite and the build, and run the scripts a developer would run. A rename the core absorbed but an edge missed usually fails a test or a script on the first execution — the cheapest confirmation there is, and the one most often skipped. A dead test rig reads as fine and dies on contact; reading it finds nothing, running it finds it at once.

Where you cannot run a path, trace statically whether the reference is reachable from a live entry point: reachable is confirmed-by-trace, can't-tell is suspected. Label every finding `confirmed` or `suspected`, and prefer never presenting a suspected finding as confirmed.

## 5. Sweep until dry

Finding three and stopping is the common failure. The obvious edges are the ones already fixed; the high-blast-radius drift hides in the tail — the wave you grounded on last, the token you extracted late, the script you hadn't run. Keep going until a full pass over every wave's vocabulary surfaces nothing new. Only then is the sweep done.

## The three shapes, as a checklist while you sweep

a. **Renamed or moved core, stale edge.** The old name, path, or identifier survives in the periphery. Highest yield; follows straight from steps 1–3.

b. **A description of a prior state.** A document or comment says a feature is "not yet built," "will," "TODO," "first cut," or "out of scope," or describes an architecture the code has since replaced — while the code already moved on. True as history, false as present. A frequent subtype: a hand-maintained count or complete list of things the system discovers or grows, which becomes a lie the moment the set changes — fix it by pointing at the canonical or discovered set, not by bumping the number.

c. **A repair that left its siblings behind.** Find a recent fix. Ask what other paths share the shape of the thing it fixed. Often the fix touched one site and the same defect remains in its siblings, because the author saw one instance, not the class.

## Reject hard

The output's value is in what you discard, not what you list. Twenty unfiltered suspicions read as noise; the reader cannot find the real three.

- Report only findings you can point to (a precise location) and tie to a concrete consequence: what breaks, or who is misled into what.
- Do not invent a problem to justify a solution. If a thing is merely "could be cleaner," drop it.
- Keep `confirmed` apart from `suspected`. Rank by blast radius: a live execution break above a misleading comment.

## What this method will not find — say so, don't strain

Drift is what a change made stale. It is not a latent defect that was always present and only a new condition made live: a race that needs concurrent load, a design limit that needs a particular input, an enforcement gap that needs a specific caller. Those carry no retired token and no prior-state text, so this sweep cannot see them. They need a reproduce-and-trace hunt that starts from a live symptom, not a static sweep. When you suspect one, name it as out of scope rather than dressing it up as drift.

## Output

A ranked list. For each finding: where it is, what it actually breaks or misleads, `confirmed` or `suspected`, and the wave from step 1 it descended from. Then, separately and briefly, any steady-state observation a specific finding points to — if the codebase were built today knowing what it now does, what would be shaped differently. No generic architecture advice.

# Contact Graph

## Problem

Human relationships decay when there is no contact. The number of relationships a person can actively maintain is limited by attention — most people can sustain maybe 150 connections (Dunbar's number), and far fewer at any depth. Former colleagues, collaborators, and developer friends gradually become strangers not because either party stopped valuing the connection, but because no one initiated contact.

AI changes the constraint. If a system tracks relationship activity and applies a spaced-recall algorithm — the same principle used in flashcard systems to surface items before they are forgotten — it can prompt reconnection at the right time: often enough to keep the relationship alive, infrequently enough not to feel mechanical.

**The job:** surface the right person to reach out to, at the right time, with enough context to make the outreach feel natural rather than algorithmic.

---

## What "right time" means

Like spaced repetition for memory:
- A relationship with frequent recent contact gets a long interval before the next prompt.
- A relationship that has been silent for a while gets a shorter interval — prompt before it fully decays.
- A relationship where *they* initiated last is warmer than one where both sides are silent — the directed graph captures this distinction.

The decay is already happening whether or not we track it. The system just makes it visible and actionable.

---

## What "enough context" means

When the system says "reach out to Alice", it should also surface:
- What you last discussed (subject lines or topics from the last few threads).
- How long since last contact and who initiated.
- Any shared context that makes a natural opener — a project you worked on, a technology you both discussed.

This is what makes the outreach feel human rather than a drip campaign.

---

## Scope: who goes in the graph

Not everyone — a focused list of people worth maintaining a connection with. Initially: developers and technical collaborators discovered from email history (former colleagues, open-source contributors, people who discussed code with the user). This is a tractable starting set with a clear signal (shared technical discussions).

The user's known addresses (all treated as "self", never nodes):
- a@colourful.land
- me@weiwu.au
- me@weiwu.eu
- w@smarttokenlabs.com
- zhangweiwu@realss.com
- zhangweiwu@private.21cn.com (historical)

These must be loaded from a single config location — every component that filters out "self" reads from the same source.

---

## Data model

**People** — canonical identity. One person may have multiple email addresses (company + personal). The canonical address is the best current one to reach them.

**Edges** — directed. A→B means A sent email to B. Both A→B and B→A exist independently. The ratio reveals who initiates.

Edge weight uses exponential decay: `score = Σ exp(-λ · (now - tᵢ))` summed over each message on that edge, where λ gives a half-life (e.g. 6 months). This means a relationship with consistent low-frequency contact scores higher than one with a burst of messages two years ago.

The score is computed at query time from stored raw events — never as a running total, so there is nothing to recompute when the decay constant changes.

**Reconnection schedule** — per person, a next-prompt date computed from the current edge score. High score → long interval. Low score → short interval. When the date passes, the person surfaces in the daily prompt.

---

## Components

### 1. Initial harvest (one-time + periodic rebuild)

Search the local mu index for developer-related conversations involving the user's own addresses. Extract all correspondent addresses. Classify as developers via Haiku (name + subject lines — no body needed). Resolve company addresses to personal ones via secondary name search.

This populates the people table and seeds the edge history from existing mail.

### 2. Incremental update (triggered)

Callable as a standalone script so any trigger can invoke it: mailroom post-process hook, mu post-index hook, cron, or manual. Reads a watermark, processes messages newer than it, upserts edges, advances the watermark. Idempotent.

### 3. Spaced-recall scheduler

Runs daily (or on demand). For each person in the graph, compute current edge score (both directions). Apply the spacing formula to derive a next-prompt date. If next-prompt date ≤ today, add to today's reconnection list.

The spacing formula is a design decision — a simple starting point: `interval_days = k / (1 + decay_score)` where k is a constant (e.g. 180 days for a completely cold relationship, shorter as score rises). This can be tuned.

### 4. Daily prompt

Output: a short list of people to reach out to today, each with last-topic context and last-contact gap. Delivered however aesop delivers its daily outputs — email digest, terminal output, or MCP tool response.

### 5. ~/.addressbook sync

A byproduct: developers with a known reachable address go into ~/.addressbook (Alpine/pine 3-column TSV: `nickname\tFull Name\temail`). This is a convenience output, not the primary purpose.

---

## Open questions

- What is the spacing formula? The decay constant and the interval mapping need tuning against real data.
- Does the graph record edges between non-self people who appear together on CC threads? Useful for "do A and B already know each other" before making an introduction.
- Where does the SQLite file live? Suggestion: `~/.local/share/aesop/contact-graph.db`.
- What triggers the daily prompt — a cron, a morning aesop run, or an MCP tool call?

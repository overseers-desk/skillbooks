# Evaluation Stage — Design Decisions

Status: in progress. This document records decisions made and questions still open for the almanac's Stage 2 (Evaluation), which will use the Anthropic orchestrator-workers pattern as argued in `the-case-for-anthropic.md`.

## Decided

### Scoring model

Vector-based, not a single composite score. Each event is scored on multiple independent dimensions. No dimension has a hard maximum — an event matching an override-weight `pull_event` scores high on strategic relevance but can still score poorly on feasibility or cost.

### Clustering

Clusters are identified by the orchestrator's judgment, not a deterministic algorithm. The reference scale is Gold Coast–Brisbane: cities close enough in geography and time to combine into a single trip. The orchestrator decides which events can be clustered based on proximity and date overlap.

### Speaking-opportunity tool behaviour

The tool reads the YAML first. If `speaker.too_late: true`, no web check is performed. If the deadline or application status is still null/undecided, the tool checks the web for current CFP status.

### Companion viability

Will be implemented as a separate skill, not as part of the evaluation system. The orchestrator can call it when available but does not depend on it for initial implementation.

## Open questions

### 1. Scoring dimensions

The scoring is vector-based, but the specific dimensions are not finalised. Candidates:

- **Strategic relevance** — pull_event match, interest match, category fit
- **Geographic feasibility** — distance from base/hub, cluster potential with other events
- **Timing feasibility** — seasonal presence alignment, conflicts with other events
- **Speaker opportunity** — CFP open, deadline viable, topic fit
- **Cost** — ticket price, travel cost, accommodation cost

Are these the right axes, or is a different decomposition needed?

### 2. Accommodation tool

IHG and Marriott do not offer simple public APIs for availability lookups. Options under consideration:

- **Headless browser** against loyalty programme booking pages (fragile, slow, but answers the actual question)
- **Web search heuristic** — search for "[loyalty brand] hotel [city]" to confirm properties exist near the venue, without checking live availability for specific dates
- **Deferred** — mark as a future capability; orchestrator notes "accommodation not checked" in output
- **Separate skill** — like companion viability, implement independently and plug in later

### 3. Output destination

Where the evaluation results are written:

- **New fields in `events/2026.yaml`** (e.g. `evaluation.scores`, `evaluation.recommendation`) — keeps everything in one file, visible in diffs
- **A separate report file** (e.g. `events/2026-evaluation.yaml` or `.md`) — keeps the event list clean, evaluation is a derived artefact
- **Stdout only** — user reads it, makes decisions, updates YAML manually

### 4. Trigger and scope

A daily cron or similar mechanism triggers the evaluation. Sub-questions:

- Does it evaluate all undecided events each run, or only those whose data changed since the last evaluation?
- Does it re-evaluate events that already have a recommendation, or only those with `participation.status: null`?

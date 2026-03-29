# SPAR Stage Notation

A compact notation for tracking where a campaign stands in the SPAR methodology. The notation encodes project position, not project history. The full path of transitions belongs in the campaign's activity log.

## Format

The stage marker has two counters separated by a dot:

```
S&P{n}.AR{m}
```

- **S&P{n}** — number of S&P iterations completed (cumulative, only increases)
- **AR{m}** — number of AR bands completed (cumulative, only increases)

Before engagement begins, the marker is just `S&P{n}`. Once the first AR band starts, it becomes `S&P{n}.AR{m}`.

## Rules

1. The S&P counter only increases. S&P1 → S&P2 → S&P3 is the standard autonomous progression.
2. S&P > 3 implies that AR work surfaced new names and a human triggered an additional S&P iteration. This is the normal case, not an exception.
3. The AR counter only increases. Each band gets one A pass (approach) and one R pass (revise) before the counter increments.
4. A can begin after any S&P iteration, not only after S&P3. A campaign with a small universe may begin engagement after S&P1.
5. The S&P counter can increase after the AR counter exists. `S&P3.AR1` → `S&P4.AR1` → `S&P4.AR2` is a valid progression: AR1 triggered S&P4, then AR2 began.

## Examples

| Marker | Meaning |
|---|---|
| `S&P1` | First S&P iteration done or in progress. No engagement yet. |
| `S&P3` | Three S&P iterations done. Standard pre-engagement state. |
| `S&P1.AR1` | One S&P iteration before engagement started. First AR band in progress or done. |
| `S&P3.AR1` | Three S&P iterations, first AR band done or in progress. |
| `S&P4.AR1` | S&P4 triggered by AR1 findings. First band complete. |
| `S&P4.AR2` | Four S&P iterations total, two AR bands complete. |
| `S&P5.AR3` | Five S&P iterations (two triggered by AR), three bands complete. |

## Mid-iteration states

When S has outrun P within an iteration (search done, profiling not yet complete), the split form `S{n}.P{m}` is available:

- `S2.P1` — search iteration 2 complete, profiling still on iteration 1. Valid because S runs before P.
- `S1.P2` — impossible. P cannot run ahead of S; you cannot profile contacts not yet discovered.

The split form is a transient state. Once P catches up, the marker reverts to the standard `S&P{n}` form. Use the split form in task assignment ("you are running P2; S2 is complete, here are the new contacts") rather than in project status tracking.

## What the marker does not encode

The response-likelihood threshold and star-rating floor for each AR band are operational parameters, not position coordinates. They belong in the band plan or strategy revision log. A separate band index serves this purpose:

```
AR1: ≥90% response likelihood (learning band)
AR2: ≥80% response likelihood
AR3: ≥5★ contacts regardless of response likelihood (value band)
AR4: ≥4★ contacts
```

The marker tells you where the campaign is. The band index tells you what each band targeted. These are consulted at different times: the marker when checking status, the band index when planning the next band.

# Densify gauntlet: ranking

Six hook-emitted advisories (corpus/, from holotapes 3ffb9a7^) densified by each arm; every output cold-read by a fresh reader, the expansion diffed against the original by an agent that never saw the dense text, losses triaged against the owner purpose lines. All runs and evaluations on claude-fable-5. Ranking: material losses ascending, then mean compression ratio (output words / original words) ascending.

| # | arm | material losses | ratio mean | ratio median | note |
|---|-----|----------------|-----------|--------------|------|
| 1 | baseline (this office, hand-run mapping method) | 0 | 0.75 | 0.74 | author held full office context; not a blind run |
| 2 | faithful (skillbooks:densify, cold-reader gate) | 0 | 0.84 | 0.82 | blind one-shot runs; gate subagents visible in transcripts |
| 3 | logophile | 0 | 0.93 | 0.94 | perfect fidelity, shallow cuts |
| 4 | condense | 0 | 6.79 | 0.86 | mean wrecked by m2: condensed the ambient methodology injection (6898 words) around the 189-word target |
| 5 | focus | 1 | 2.10 | 2.19 | a summarizer: expands short advisories into structured summaries |
| 6 | cod (chain-of-density) | 9 | 0.49 | 0.48 | deepest compression on the board; meaning inverted in four of six cells |
| - | semcomp (semantic-compressor) | DNF | 1.00 (m1) | - | m1 refused as NOT_COMPRESSIBLE; m2-m6 uninvocable headless |
| - | control (original unchanged) | 0 | 1.00 | 1.00 | instrument check, passed 6/6 |

Chain-of-density is the strongest compressor and the least trustworthy: its losses are not dropped facts but inversions (spawn-time duties read as post-completion, report-instead read as hold-silently, a bypass token moved to where the gate cannot see it). Fidelity-first products (logophile, condense on its good cells) preserve everything but cut 5-15%. The two arms that both kept everything and cut deep are the office's own: the mapping-method baseline (25%) and the cold-reader-gated skill (16%), the baseline's edge confounded by its author holding full project context.

Roster provenance: survey recovered from session 78813a48 (2026-07-15): skills-optimizer (tested as semcomp), Chain of Density (tested via foundry copywriter plugin, the niche's incumbent), jwynia/agent-skills summarization (unobtainable: no such skill in the current tree, checked every category), mcpmarket Context Compression (unobtainable: listing resolves to no repo). Fresh-sweep additions tested: skill-focus, logophile, condense. Install routes: `claude plugin marketplace add` + `install` worked for the one real plugin (foundry); bare skill repos went in by copying under the profile's skills dir; a skill that is slash-invocable only (semcomp) is unreliable under headless -p and effectively unbenchmarkable there.

Validity caveats: single reader/differ pair per cell (noise band known from the #180 ladder); all sessions carried this office's ambient hook injections, which one condense cell condensed instead of its target; a session-credit outage forced re-runs of eight cells and 23 diffs, all completed after reset.

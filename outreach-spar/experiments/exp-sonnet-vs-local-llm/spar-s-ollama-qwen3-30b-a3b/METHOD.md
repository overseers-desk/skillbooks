# S-phase: ollama, Qwen3-30B-A3B, dappnode

Written before any result exists, so that the scoring cannot be shaped by the rosters it will be applied to.

## What is being compared, and what is not

A hosted arm swept horse supply for the estate across five segments, producing 96 roster rows. This arm reruns the same five segments on `qwen3:30b-a3b`, served by ollama on dappnode and reached through claude-code-router over an SSH tunnel.

The two arms did not do the same job, and the difference is deliberate. The hosted arm worked out its own denominators, its own source census and its own family sweeper before it found a single business. This arm is handed all of that, and produces only the rows. The comparison therefore speaks to finding and recording members of a defined segment. It does not speak to whether a local model can frame a sweep, which is the question the experiment was set up to ask and which a later arm still has to answer.

The segment definitions and the family sweeper are byte-identical across the two arms, verified by checksum before the run. Both arms inherit the same blind spot: `supplier-horse-rehoming` is built substantially around Racing Queensland's off-the-track retrainers, while the estate's staff have stated a preference for horses that are not thoroughbreds. Neither arm was told. Since both inherit it equally it does not bias the comparison, though it bears on what either roster is worth to the business.

## Half one: blind quality, adapting the P-phase method

The P-phase study of 2026-07-02 judged five engines over twelve contacts by giving one context-free judge per contact the five files under random codenames, with provenance stripped and file order rotated against position bias. That method carries over, with two changes forced by there being two arms rather than five and by the artefact being a roster rather than a profile.

One fresh judge per segment, given two rosters under codenames assigned at random per segment, so a judge cannot carry a preference from one segment to the next. Every line identifying the producing arm is stripped, including round records, timestamps and any path. The judge states a preference and its reasons against the segment's own discovery criteria and rating rubric, which it is given, since a roster is only judgeable against what the segment says a member is.

The judge is told nothing about how either roster was produced, and nothing about this experiment.

## Half two: are the rows real

The P-phase method explicitly measured document quality as a reader experiences it, not accuracy against ground truth. For a profile that is defensible. For a roster it is not, because a roster of plausible businesses that do not exist reads well and is worth nothing, and a model that invents is flattered by every quality metric there is.

So each roster is sampled and checked. Eight rows per roster per segment, or every row where a roster holds fewer than eight, drawn by taking every k-th row after sorting by stem, with k chosen to span the file. Deterministic and reproducible, so neither arm can be cherry-picked.

Each sampled row is checked by an agent that is not told which arm produced it, against two questions. Does the business exist, evidenced by a registry entry or a web presence that is not the roster's own citation. Is it inside the catchment as `sweeper-horse-supply.yaml` defines it. Both answers are recorded with what evidenced them, and a row that cannot be confirmed either way is recorded as unconfirmed rather than forced into a verdict.

## Half three: the counts that need no judgement

Rows per segment per arm. Businesses appearing in both arms, matched on trading name and locality rather than on stem, since the two arms will not have agreed on stems. Businesses unique to each arm. Rows each arm placed that the other's own exclusions would have rejected.

Row count alone is reported next to the sampled-accuracy figure, never on its own, because the cheapest way to win on count is to invent.

## What is recorded whatever happens

Measured throughput on a real sweep prompt, against the 17.26 tokens per second that `local-inference/README.md` reports for this model on dappnode from llama-bench. Wall-clock for the run. Any segment the model could not complete, with how it failed, since that is a result and not an absence of one.

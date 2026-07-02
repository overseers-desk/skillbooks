# exp-sonnet-vs-local-llm

An experiment: can SPAR-P profiles be produced by a local LLM instead of hosted Sonnet, and how does the result compare on facts, verification, rating, time and machine load? Each engine that has been tried has its own folder; the count grows as more engines and machines are added, so read the folders rather than any fixed number here.

## Layout

- `spar-p-sonnet/` holds the hosted-Sonnet profile. This is the **quality baseline**: the yardstick every local run is judged against.
- `spar-p-<backend>-<model>/` holds one local run each (for example a Vulkan run on a laptop, or the CUDA runs on GPU-Workstation). Inside each: the produced profile (`marco-fredriks.local-*.md`), a `run-trace.md`, `metrics.json`, and the `source-facts.md` that run consumed.
- Dated worklogs, `YYYY-MM-DD <title>.md`, carry the detailed per-machine record. Each is authored for its own day and machine, not a running edit of the others.

## The two baselines, and the provenance caveat

Two distinct roles are easy to conflate:

1. The **quality baseline** is Sonnet's finished profile (`spar-p-sonnet/`).
2. The **facts-provider baseline** is the retrieval that a facts-fed local run consumes. For a clean test this should be the authoritative retrieval, so the only variable is the consuming model's reasoning.

Important: the facts fed to the local runs are **Sonnet-sourced but not a live Sonnet capture**. Sonnet's raw retrieval was never saved, so `source-facts.md` is reconstructed from Sonnet's finished profile, with Sonnet's own verdicts withheld so each model still has to verify for itself. The first cut of the CUDA runs used a different provider (a laptop Qwen3-30B run's captured tool outputs) and was re-based onto Sonnet; that cut is in git history. A genuinely clean provider, a live Sonnet run with raw tool outputs captured, is a later step. It is gated on installing live LinkedIn and web reach on the local box, which is why the local runs to date are facts-fed rather than reaching out themselves.

## Where to start

Read the dated worklog for the machine you care about, then open that machine's `spar-p-*` folders for the individual profiles and metrics.

# exp-sonnet-vs-local-llm

Can SPAR-P profiles be produced by a local LLM instead of hosted Sonnet, and how does the result compare on facts, verification, rating, time and machine load? The experiment has grown from a single-contact probe into a whole-segment comparison across two machines and several models. Each engine that has been tried has its own `spar-p-*` folder; the count grows as more are added, so read the folders and the reports rather than any fixed number here.

## Two machines, several models

- **yoga**: Lunar Lake laptop, Intel Arc 140V, Vulkan backend (shared UMA memory, no discrete VRAM). Has live web and LinkedIn reach, so its runs do real retrieval. Models: Qwen3-30B-A3B, then Qwen3.5-35B-A3B.
- **GPU-Workstation**: desktop, NVIDIA RTX 2070 SUPER (8 GB), CUDA backend, ollama. The box has live web and LinkedIn reach (the probe used the LinkedIn skill on it), but its batch runs were facts-fed one-shot from a reconstructed facts sheet; a live-retrieval batch re-run is the open follow-up. Models: llama3.1:8b, qwen3:8b, qwen2.5:14b.
- **Hosted Sonnet** is the quality baseline both machines are judged against.

## Experiments and reports

1. **Single-contact probe** (Marco Fredriks): the method and verification test on one contact, to isolate model quality from retrieval. Reports:
   - laptop / Vulkan: [2026-07-01-probe-yoga-vulkan.md](2026-07-01-probe-yoga-vulkan.md)
   - GPU-Workstation / CUDA: [2026-07-02-probe-gpuws-cuda.md](2026-07-02-probe-gpuws-cuda.md)

2. **Whole-set batch** (47 media-creator profiles, the 2026 reputation campaign): the same 47 star≥4 no-approach contacts regenerated across the two machines and compared against Sonnet. Harness and reports in [batch-media-creator/](batch-media-creator/), one worklog per machine:
   - laptop / Vulkan, live Qwen3.5-35B: [batch-media-creator/2026-07-02-batch-yoga-vulkan.md](batch-media-creator/2026-07-02-batch-yoga-vulkan.md)
   - GPU-Workstation / CUDA, three engines facts-fed: [batch-media-creator/2026-07-02-batch-gpuws-cuda.md](batch-media-creator/2026-07-02-batch-gpuws-cuda.md)

   The regenerated profiles are not in this repo; they live on four branches of the campaign repo (holotapes-career), one per engine, all forked from `career` (the Sonnet baseline):
   - `career-qwen35-vulkan`: Qwen3.5-35B-A3B (yoga, live agentic)
   - `career-cuda-llama31-8b`: llama3.1:8b (GPU-Workstation, facts-fed)
   - `career-cuda-qwen3-8b`: qwen3:8b (GPU-Workstation, facts-fed)
   - `career-cuda-qwen25-14b`: qwen2.5:14b (GPU-Workstation, facts-fed)

   Compare an engine against Sonnet with `git diff career..<fork> -- spar-campaigns/media-creator/profiles` in holotapes-career. Per-profile time and context are recorded in the run's progress logs.

## Layout

- `spar-p-sonnet/`: the hosted-Sonnet profile, the quality baseline.
- `spar-p-<backend>-<model>/`: one local single-contact run each (e.g. `spar-p-vulkan-qwen3.5-35b-a3b/`, `spar-p-cuda-qwen2.5-14b/`): the produced profile, its `source-facts.md`, `prompt-instructions.txt`, and metrics.
- `batch-media-creator/`: the whole-set batch: prompts (agentic and facts-fed), drivers (`run-batch.sh`, `cuda-factsfed-batch.py`, `run-all-3-cuda.sh`), the 47-stem list, progress logs, a per-machine batch worklog, and the setup handoff.
- Worklogs are named `YYYY-MM-DD-<phase>-<machine>`: phase is `probe` (single contact) or `batch` (whole set); machine is `yoga-vulkan` (laptop) or `gpuws-cuda` (desktop). The two `probe-*` files are the day-1 and day-2 groundwork; the two `batch-*` files are the same-day batch on the two computers.

## Findings so far

**The whole-set comparison is due for a redo.** The engines ran under unequal prompts and retrieval (Sonnet on the production harness, the 35B on a snippet-budget prompt, the CUDA three facts-fed), so the cross-engine quality results below describe those unequal conditions, not model quality alone. The redo spec, including the decision to run one method for all engines and let engines fail, is [issue #151](https://github.com/overseers-desk/aesop/issues/151). The blind study that surfaced this is in [2026-07-02-blind-quality-12x5/](2026-07-02-blind-quality-12x5/).

Retrieval is not the differentiator: given the same facts, every local engine is fact-complete and non-fabricating. The residual gap is rating calibration. On the whole set, qwen2.5:14b tracks Sonnet closest, qwen3:8b over-rates, and llama3.1:8b is the most conservative. The Vulkan Qwen3.5-35B tracks Sonnet on its completed subset but is much slower (memory-bandwidth-bound decode) and needed a context-window fix to stop over-research overflows. Detail is in the worklogs above.

## Where to start

For the whole-set batch read the per-machine worklogs in [batch-media-creator/](batch-media-creator/); for a single machine's groundwork read its `probe-*` worklog, then open that machine's `spar-p-*` folders for the individual profiles and metrics.

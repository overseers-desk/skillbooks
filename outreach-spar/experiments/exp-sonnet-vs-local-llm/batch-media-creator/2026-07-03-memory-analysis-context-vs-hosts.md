# Memory analysis: context needed for media-creator SPAR-P vs what the two hosts can provide

This is an analysis, not a determination. It measures how much context the media-creator SPAR-P work actually consumes (from the Sonnet baseline sessions that produced the 47 target profiles) and sets that against what each host and model can hold. It does not prescribe a context size for any run; it estimates, per configuration, how much memory a given context costs and what fraction of the target profiles that configuration could not hold. The actual failure rate is to be measured by running.

## 1. Context needed (measured, not assumed)

Source: the 47 `claude-sonnet-4-6` sessions that each authored one media-creator target profile (one dedicated worker per profile, found under `~/.claude/projects/.../holotapes-career-spar-campaigns`). Peak context = the largest prompt a session sent, counting input plus cached-read plus cache-creation tokens (the full window fill, since cached tokens still occupy the window).

| statistic | peak context (tokens) |
|---|---:|
| min | 73,273 |
| median | 86,922 |
| p90 | 105,488 |
| max | 110,745 |

All 47 sit in a tight 73k–111k band. None is below 73k. This is the SPAR-P media-creator workload at Sonnet's research depth; a local engine reproducing that depth in a single session faces the same order of context.

Two caveats on reading this as the local requirement: Sonnet fanned research out to subagents, so 73k–111k is the parent worker's synthesis peak, not the raw research it read: a single-session local run holding all research inline could need more. Conversely, a deliberately shallow run (few tool calls) produces a thinner profile at lower context; the earlier capped local runs peaked ~14k–24k precisely because they researched far less.

## 2. Per-token KV cost and weights, by model

KV per token is fixed by architecture; halved by a `q8_0` key/value cache. Weights are the resident footprint.

| host | model | weights (resident) | KV/token fp16 (q8_0) | native context (quality) |
|---|---|---:|---:|---:|
| yoga (Vulkan, UMA) | Qwen3.5-35B-A3B Q4 | ~22 GiB | 96 KiB (48) | ~32k, YaRN to ~131k (degrades) |
| yoga (Vulkan, UMA) | Qwen3-30B-A3B Q4 | ~18 GiB | 96 KiB (48) | ~32k, YaRN to ~131k (degrades) |
| GPU-Workstation (CUDA) | llama3.1:8b Q4 | ~4.9 GiB | 128 KiB (64) | ~128k |
| GPU-Workstation (CUDA) | qwen3:8b Q4 | ~5.2 GiB | ~144 KiB (72) est | ~128k |
| GPU-Workstation (CUDA) | qwen2.5:14b Q4 | ~9 GiB | ~192 KiB (96) est | ~32k |

Measured: yoga A3B KV 96 KiB/token; llama3.1:8b 128 KiB/token (from a 4 GB KV reservation at 32,768). The qwen3:8b and qwen2.5:14b KV rates are architecture estimates and are marked est.

## 3. What each host can provide

The binding resource differs by host:
- **yoga**: system RAM. Total 30 GiB shared (UMA: the iGPU has no separate VRAM); weights live in RAM as GTT and must stay resident. GNOME cannot be quit (skillbooks#14) but can be swept into the 62 GiB swap, so idle desktop pages leave physical RAM. Usable physical RAM for weights + KV is therefore ~28 GiB (30 minus non-swappable kernel/essentials), less ~1–2 GiB for the ccr/node worker while a run is live.
- **GPU-Workstation**: VRAM. 8 GiB on the RTX 2070 SUPER is the binding constraint for speed; the 32 GiB system RAM is a spill target: a model or KV that exceeds VRAM still runs, but decode drops to the system-RAM floor (~7 t/s), so VRAM-fit is the line for a usable run.

Max context each configuration can hold (memory-limited; the smaller of this and the model's native-quality ceiling is the real ceiling):

| configuration | budget for KV | max context fp16 | max context q8_0 | note |
|---|---:|---:|---:|---|
| yoga · Qwen3.5-35B | ~4–5 GiB (28 − 22 − ~1.5) | ~44k | ~88k | past ~32k native → quality degrades |
| yoga · Qwen3-30B | ~8–9 GiB (28 − 18 − ~1.5) | ~87k | ~131k (model-capped) | past ~32k native → quality degrades |
| gpuws · llama3.1:8b (in VRAM) | ~3.0 GiB (8 − 4.9) | ~24k | ~48k | beyond → RAM spill, ~7 t/s |
| gpuws · qwen3:8b (in VRAM) | ~2.8 GiB (8 − 5.2) | ~19k | ~38k | beyond → RAM spill, ~7 t/s |
| gpuws · qwen2.5:14b (in VRAM) | none (9 GiB > 8 GiB VRAM) | 0 | 0 | weights already spill at any context |

## 4. Memory cost at a given context (the "if we give X, what does it cost" view)

Total footprint = weights + KV(X). Compare against usable RAM (~28 GiB, yoga) or VRAM (8 GiB, gpuws). fp16 KV shown; halve the KV part for q8_0.

| context X | yoga Q3.5-35B RAM | yoga Q3-30B RAM | gpuws llama3.1:8b VRAM | gpuws qwen3:8b VRAM |
|---:|---:|---:|---:|---:|
| 16k | 23.5 GiB ✓ | 19.5 ✓ | 6.9 ✓ | 7.4 ✓ |
| 32k | 25.0 ✓ | 21.0 ✓ | 8.9 spill | 9.6 spill |
| 73k (min need) | 28.8 ✗RAM | 24.8 ✓ | 13.9 spill | 15.3 spill |
| 87k (median) | 30.2 ✗ | 26.2 ✓ | 15.8 spill | 17.4 spill |
| 111k (max need) | 32.4 ✗ | 28.4 ~edge | 18.8 spill | 20.8 spill |

✓ fits fast memory; ✗ exceeds it; spill = exceeds VRAM, runs from system RAM at the ~7 t/s floor. (yoga rows would move down by the KV/2 saving under q8_0: e.g. Q3.5-35B at 87k becomes ~26.2 GiB, which fits.)

## 5. Predicted failure rate

Failure here means the configuration cannot hold a profile's measured context need in its fast memory. Applied to the 47-profile need distribution (73k–111k):

| configuration | fast-memory ceiling | profiles that exceed it | predicted fail |
|---|---:|---:|---:|
| 16,384 (the window the run started at) | 16k | 47/47 | 100% |
| 32,768 (the window it was moved to) | 32k | 47/47 | 100% |
| yoga · Qwen3.5-35B · fp16 | ~44k | 47/47 | 100% |
| yoga · Qwen3.5-35B · q8_0 | ~88k | 22/47 | 47% |
| yoga · Qwen3-30B · fp16 | ~87k | 23/47 | 49% |
| yoga · Qwen3-30B · q8_0 | ~131k (model cap) | 0/47 | 0% (memory) |
| gpuws · any 8B · in-VRAM | ~19–48k | 47/47 | 100% |

Reading:
- **At fast, native-quality operation, no configuration on either host clears the workload**: every profile needs ≥73k, which is past the fast-memory budget of every model here and past the ~32k native context of the yoga and 14b models. Predicted fail ≈ 100%.
- **One configuration can hold every profile in memory: yoga · Qwen3-30B with a q8_0 KV cache** (≈131k ceiling, memory permitting): 0% memory failure. But all 47 exceed the ~32k native context, so all 47 run under YaRN extension, where quality degrades toward the top; this trades memory-failure for quality-degradation, which the run must measure.
- **GPU-Workstation can hold the context only by spilling KV to its 32 GiB RAM** (feasible for the median, tight at the max on the 14b), at the ~7 t/s floor: feasible but slow, not a fast run.

So the honest prediction: profiles that no configuration can do **at fast speed and native-context quality ≈ 100%**; profiles that no configuration can **hold in memory at all (accepting q8_0 on the 30B, or RAM spill, and accepting quality/speed cost) ≈ 0%**. The experiment's real question is where between those two the usable-quality line falls: which is what running it will show.

## 6. What this replaces

Earlier notes carried a determination that 16,384 tokens is "plenty for one profile" and that moving to 32,768 was the fix. The measured need (73k–111k) shows both are 3–7× short: at either window every one of the 47 profiles overflows or is truncated. Those figures were sized to a compact single-contact facts-fed task (~2.3k) and to one observed overflow, not to this live, catalogue-deep workload. This document is the analysis that should be consulted instead of any fixed context number.

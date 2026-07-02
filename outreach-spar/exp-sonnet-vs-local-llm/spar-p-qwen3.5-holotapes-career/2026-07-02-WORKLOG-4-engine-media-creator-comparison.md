# WORKLOG 2026-07-02 — four local engines vs Sonnet on the media-creator SPAR-P set

Forward-only record of an experiment: regenerate the same set of media-creator SPAR-P profiles with four local LLM engines and judge which produces the best profile against the hosted-Sonnet baseline. Sibling worklogs cover the single-contact groundwork (`2026-07-01-WORKLOG-sonnet-vs-local-llm.md` for the Vulkan laptop; the GPU-Workstation CUDA worklog for the desktop). This file is the multi-engine, whole-set comparison.

## Working set

47 contacts: the media-creator segment rows with roster `star_rating >= 4` and no approach file yet (the AR-scope, still-pending subset). List in `working-set-47.txt`. The set is, by construction, Sonnet's own 4–5★ tier, and the campaign yaml records that tier as inflated ("many on-theme-but-low-reach 4-stars belong at 3"). Consequence for reading the numbers below: Sonnet is pinned at 4–5, so a local engine rating a contact *lower* is ambiguous — it can be worse (missing value) or better (catching the known inflation). Rating agreement is a proxy, not ground truth.

## Engines and forks

Each engine wrote its 47 profiles onto its own branch of holotapes-career, forked from `career` (the Sonnet baseline, commit 5d8319d for the CUDA forks; ecfdf33 for the Vulkan fork — the media-creator profiles are byte-identical at both bases). Compare any engine with `git diff career..<fork> -- spar-campaigns/media-creator/profiles`.

| Fork | Engine | Host / backend | Method |
|---|---|---|---|
| `career-qwen35-vulkan` | Qwen3.5-35B-A3B Q4 | yoga, Intel Arc 140V (Vulkan, UMA) | live agentic (ccr + brave-search + WebFetch) |
| `career-cuda-llama31-8b` | llama3.1:8b | GPU-Workstation, RTX 2070S (CUDA) | facts-fed one-shot (ollama) |
| `career-cuda-qwen3-8b` | qwen3:8b | GPU-Workstation, RTX 2070S (CUDA) | facts-fed one-shot (ollama) |
| `career-cuda-qwen25-14b` | qwen2.5:14b | GPU-Workstation, RTX 2070S (CUDA) | facts-fed one-shot (ollama) |
| (baseline) | hosted Sonnet | — | live agentic (production harness) |

The two methods differ by necessity, not choice: the Vulkan box has live web+LinkedIn reach, so its 35B does real retrieval; the CUDA box has no live reach (no Brave key, LinkedIn CLI broken), so its three models replay one-shot from a facts sheet reconstructed from each Sonnet profile with the rating and verdict sections stripped. The three CUDA models therefore share identical facts (a clean model-vs-model comparison); the 35B is the live-retrieval point.

## Method notes

- Per-contact prompt is media-creator-specific: the catalogue (episode/video list and guests) is the primary evidence, LinkedIn is identity-only, and the rating is reach-gated (reach into our audiences × three signals: topic, guest type, host-stated interest). Agentic prompt: `prompt-media-creator.txt`. Facts-fed prompt: `prompt-media-creator-factsfed.txt`.
- Vulkan agentic driver: `run-batch.sh` (one persistent llama-server, one profile at a time, per-profile timeout, auto-retry, resumable). CUDA facts-fed harness: `cuda-factsfed-batch.py` driven by `run-all-3-cuda.sh` (three models sequentially; 8 GB VRAM holds one at a time).
- Per-profile time and context are recorded in the progress logs (`progress.log` on yoga; `logs/<model>.progress` on GPU-Workstation): each line carries outcome, star, yield, duration, peak context, output tokens.

## Context-window fix (the one real operational problem)

The Vulkan 35B, on the harder channels, over-researches until the conversation passes the context window. At `-c 16384` (default 4 KV slots) several requests reached ~18k tokens and the server rejected them (`exceeds the available context size`), recorded as `fail-hardware`. This is a configurable limit, not a true ceiling. Fix: relaunch with `--parallel 1 -c 32768` — a single 32k conversation window that fits those requests while using *less* KV memory than the 4×16k default (≈3 GiB vs ≈6 GiB), which also drained swap (3.9 GiB → ~1 GiB). The driver's `restart_server` and the initial launch now use this. Overflow retries succeed at 32k. The CUDA facts-fed runs never hit this (one-shot, ~3.5k context).

## Results

CUDA side complete: **141/141 profiles, zero failures.** Vulkan side runs slower (memory-bandwidth-bound decode, ~7–11 min/profile) and was still in progress at this writing.

Star distributions over the 47, and agreement with the Sonnet baseline (all on Sonnet's 4–5 tier):

| Engine | mean★ | distribution | exact match to Sonnet | mean │Δ│ | over / under |
|---|--:|---|--:|--:|--|
| Sonnet (baseline) | 4.17 | 39×4, 8×5 | — | — | — |
| qwen2.5:14b | 3.98 | 7×3, 34×4, 6×5 | 66% | 0.36 | 4 / 12 |
| qwen3:8b | 4.02 | 10×3, 26×4, 11×5 | 53% | 0.49 | 8 / 14 |
| llama3.1:8b | 3.72 | 2×2, 12×3, 30×4, 3×5 | 51% | 0.53 | 2 / 21 |
| Qwen3.5-35B (Vulkan, live) | (partial) | tracked Sonnet on its completed subset (mostly exact) | — | — | — |

## Findings

- **qwen2.5:14b is the best-calibrated CUDA engine** — closest to Sonnet (66% exact, smallest │Δ│), with mild downward adjustment. This echoes the earlier single-contact CUDA finding that the 14B tracked careful Sonnet best. Its cost is speed: at 11 GB it spills off the 8 GB card and decodes at the system-RAM floor (~7 t/s, ~80–170 s/profile) versus ~35–50 s for the VRAM-resident 8B models.
- **qwen3:8b over-rates** — eleven 5s and eight ratings above Sonnet's already-high tier. The Qwen generosity seen in the groundwork persists.
- **llama3.1:8b is the most conservative and most divergent** — it pushes 21 of 47 below Sonnet, including two harsh 2s (lex-fridman, nate-herk) that look too low for large AI channels. If the intended reach-gated re-rate really moves many 4s to 3, its direction is defensible, but its floor is crude.
- **The Vulkan 35B tracks Sonnet closely** on its completed subset, but it is the live-retrieval variant (different facts), slower, and was incomplete at writing, so it is not directly comparable head-to-head with the facts-fed three.
- **Retrieval vs writing/rating are separable.** On identical facts the three CUDA models diverge only in how they write and rate, which isolates model quality from retrieval luck; the calibration spread above is a model property, not a facts property.

## Reproduce / continue

- Vulkan: one persistent `llama-server -ngl 99 --parallel 1 -c 32768 --jinja --chat-template-kwargs '{"enable_thinking":false}'`, `ccr start`, then `run-batch.sh working-set-47.txt` (resumable; skips recorded successes).
- CUDA: `run-all-3-cuda.sh` on GPU-Workstation (ollama serving the three models), facts read from the `career` profiles, output to each model's worktree.
- Open next step: a strict 4-way on identical facts would also run the 35B facts-fed (it does not fit the 8 GB card, so on yoga). A rigorous "which is better" beyond ratings needs reading the sharp disagreements (e.g. nate-herk: llama31 ★2 vs qwen25 ★4 vs Sonnet ★4).

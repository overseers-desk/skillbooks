# WORKLOG 2026-07-02 — batch, GPU-Workstation / CUDA: three local engines vs Sonnet on the media-creator set

Forward-only record: regenerate the media-creator SPAR-P profiles on the GPU-Workstation (RTX 2070 SUPER, CUDA, ollama) with three local engines, facts-fed, and judge which produces the best profile against the hosted-Sonnet baseline. The sibling batch worklog `2026-07-02-batch-yoga-vulkan.md` covers the live Qwen3.5-35B run on the laptop. Single-contact groundwork is in `../2026-07-02-probe-gpuws-cuda.md` (this machine) and `../2026-07-01-probe-yoga-vulkan.md` (the laptop).

## Working set

47 contacts: the media-creator segment rows with roster `star_rating >= 4` and no approach file yet (the AR-scope, still-pending subset). List in `working-set-47.txt`, shared with the yoga batch. The set is, by construction, Sonnet's own 4–5★ tier, and the campaign yaml records that tier as inflated ("many on-theme-but-low-reach 4-stars belong at 3"). So a local engine rating a contact *lower* is ambiguous: worse (missing value) or better (catching the known inflation). Rating agreement is a proxy, not ground truth.

## Engines and forks

Three engines, each writing its 47 profiles onto its own branch of holotapes-career, forked from `career` (the Sonnet baseline, commit 5d8319d; the media-creator profiles are byte-identical to the Vulkan fork's base). Compare any engine with `git diff career..<fork> -- spar-campaigns/media-creator/profiles`.

| Fork | Engine | Method |
|---|---|---|
| `career-cuda-llama31-8b` | llama3.1:8b | facts-fed one-shot (ollama) |
| `career-cuda-qwen3-8b` | qwen3:8b | facts-fed one-shot (ollama) |
| `career-cuda-qwen25-14b` | qwen2.5:14b | facts-fed one-shot (ollama) |
| (baseline) | hosted Sonnet | live agentic (production harness) |

Facts-fed = one-shot replay from a facts sheet reconstructed from each Sonnet profile with the rating and verdict sections stripped. The three CUDA models therefore share identical facts, which makes this a clean model-vs-model comparison (retrieval held constant).

## Method

- Per-contact prompt is media-creator-specific: the catalogue (episode/video list and guests) is the primary evidence, LinkedIn is identity-only, and the rating is reach-gated (reach into our audiences × three signals: topic, guest type, host-stated interest). Facts-fed prompt: `prompt-media-creator-factsfed.txt`.
- Harness: `cuda-factsfed-batch.py` driven by `run-all-3-cuda.sh` (three models sequentially; the 8 GB VRAM holds one at a time). Per-profile time and context in `logs/<model>.progress`: each line carries outcome, star, yield, duration, peak context, output tokens. These one-shot runs sit at ~3.5k context and never hit a context-window limit.

## Results

Complete: **141/141 profiles (3 × 47), zero failures.**

Star distributions over the 47, and agreement with the Sonnet baseline (all on Sonnet's 4–5 tier):

| Engine | mean★ | distribution | exact match to Sonnet | mean │Δ│ | over / under |
|---|--:|---|--:|--:|--|
| Sonnet (baseline) | 4.17 | 39×4, 8×5 | — | — | — |
| qwen2.5:14b | 3.98 | 7×3, 34×4, 6×5 | 66% | 0.36 | 4 / 12 |
| qwen3:8b | 4.02 | 10×3, 26×4, 11×5 | 53% | 0.49 | 8 / 14 |
| llama3.1:8b | 3.72 | 2×2, 12×3, 30×4, 3×5 | 51% | 0.53 | 2 / 21 |

## Findings

- **qwen2.5:14b is the best-calibrated engine here** — closest to Sonnet (66% exact, smallest │Δ│), with mild downward adjustment. This echoes the single-contact CUDA finding that the 14B tracked careful Sonnet best. Its cost is speed: at 11 GB it spills off the 8 GB card and decodes at the system-RAM floor (~7 t/s, ~80–170 s/profile) versus ~35–50 s for the VRAM-resident 8B models.
- **qwen3:8b over-rates** — eleven 5s and eight ratings above Sonnet's already-high tier. The Qwen generosity seen in the groundwork persists.
- **llama3.1:8b is the most conservative and most divergent** — it pushes 21 of 47 below Sonnet, including two harsh 2s (lex-fridman, nate-herk) that look too low for large AI channels. If the intended reach-gated re-rate really moves many 4s to 3, its direction is defensible, but its floor is crude.
- **Retrieval vs writing/rating are separable.** On identical facts the three models diverge only in how they write and rate, which isolates model quality from retrieval luck; the calibration spread above is a model property, not a facts property.

## Reproduce

`run-all-3-cuda.sh` on GPU-Workstation (ollama serving the three models), facts read from the `career` profiles, output to each model's worktree. A strict 4-way on identical facts would also run the 35B facts-fed, but it does not fit the 8 GB card, so that variant belongs on the laptop (see the sibling worklog). A rigorous "which is better" beyond ratings needs reading the sharp disagreements (e.g. nate-herk: llama31 ★2 vs qwen25 ★4 vs Sonnet ★4).

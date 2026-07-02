# WORKLOG 2026-07-02 — batch, yoga / Vulkan: Qwen3.5-35B live vs Sonnet on the media-creator set

Forward-only record: regenerate the media-creator SPAR-P profiles on yoga (Lunar Lake laptop, Intel Arc 140V, Vulkan, UMA) with the local Qwen3.5-35B-A3B engine doing live retrieval, and judge against the hosted-Sonnet baseline. The sibling batch worklog `2026-07-02-batch-gpuws-cuda.md` covers the three facts-fed CUDA engines on the GPU-Workstation. Single-contact groundwork is in `../2026-07-01-probe-yoga-vulkan.md` (this machine) and `../2026-07-02-probe-gpuws-cuda.md` (the desktop). The setup handoff that launched this run is `2026-07-02-batch-yoga-vulkan-HANDOFF.md`.

## Working set

47 contacts: the media-creator segment rows with roster `star_rating >= 4` and no approach file yet. List in `working-set-47.txt`, shared with the CUDA batch. The set is Sonnet's own 4–5★ tier, which the campaign yaml records as inflated ("many on-theme-but-low-reach 4-stars belong at 3"), so a local engine rating a contact lower is ambiguous: worse (missing value) or better (catching the inflation).

## Engine and fork

Qwen3.5-35B-A3B Q4 on yoga (Arc 140V, Vulkan). Live agentic retrieval (ccr + brave-search + WebFetch), the same architecture as the Vulkan groundwork. Profiles written to the holotapes-career branch `career-qwen35-vulkan`, forked from `career` (the Sonnet baseline, commit ecfdf33). Compare with `git diff career..career-qwen35-vulkan -- spar-campaigns/media-creator/profiles`.

This is the live-retrieval point of the comparison: the laptop has live web + LinkedIn reach, so its 35B does real retrieval, whereas the CUDA three replay from a facts sheet. The two methods differ by necessity (the CUDA box has no live reach), so the 35B is not directly head-to-head with the facts-fed three; it answers a different question, whether a local model can do the whole loop live.

## Method

- Per-contact prompt is media-creator-specific: the catalogue (episode/video list and guests) is the primary evidence, LinkedIn is identity-only, and the rating is reach-gated (reach into our audiences × three signals: topic, guest type, host-stated interest). Agentic prompt: `prompt-media-creator.txt`.
- Driver `run-batch.sh`: one persistent llama-server, one profile at a time, per-profile timeout, auto-retry, resumable (skips recorded successes). Per-profile time and context in `progress.log`.

## Context-window fix (the one real operational problem)

The 35B, on the harder channels, over-researches until the conversation passes the context window. At `-c 16384` (default 4 KV slots) several requests reached ~18k tokens and the server rejected them (`exceeds the available context size`), recorded as `fail-hardware`. This is a configurable limit, not a true ceiling. Fix: relaunch with `--parallel 1 -c 32768`, a single 32k conversation window that fits those requests while using *less* KV memory than the 4×16k default (≈3 GiB vs ≈6 GiB), which also drained swap (3.9 GiB → ~1 GiB). The driver's `restart_server` and the initial launch now use this; overflow retries succeed at 32k.

## Results

The Vulkan side runs slower than CUDA (memory-bandwidth-bound decode, ~7–11 min/profile) and was still in progress at this writing. On its completed subset the 35B tracked Sonnet closely (mostly exact ratings). Because it is the live-retrieval variant (different facts from the facts-fed three) and was incomplete, it is not tabulated head-to-head with them; the CUDA table lives in the sibling worklog.

## Reproduce / continue

One persistent `llama-server -ngl 99 --parallel 1 -c 32768 --jinja --chat-template-kwargs '{"enable_thinking":false}'`, `ccr start`, then `run-batch.sh working-set-47.txt` (resumable). Open next step: a strict 4-way on identical facts would also run the 35B facts-fed, which does not fit the 8 GB CUDA card, so it belongs here on yoga.

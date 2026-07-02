# WORKLOG 2026-07-02 — SPAR-P on local models, GPU-Workstation (CUDA, RTX 2070 SUPER)

Forward-only record for a future agent asked "can SPAR-P run on the GPU-Workstation box instead of hosted Sonnet, and does a local model produce a comparable profile at reasonable time and machine load?" This box is a different environment from the laptop the sibling `WORKLOG.md` describes (that one is a Lunar Lake laptop, Arc 140V, Vulkan). This file is about the desktop.

## 1. The box (measured, not inferred)

- CPU AMD Ryzen 7 5800X (8-core); 31 GiB system RAM, DDR4-2400 dual-channel (both channels populated).
- GPU NVIDIA RTX 2070 SUPER, 8 GB GDDR6, driver 570.195.03, CUDA toolkit 12.2, ollama 0.16.2.
- Memory bandwidth, the number that governs decode: GPU VRAM ~448 GB/s (7001 MHz x2, 256-bit); system RAM ~38 GB/s (DDR4-2400 dual-channel); PCIe Gen3 x16 bridge ~16 GB/s. Fast inside VRAM, slow everywhere else.
- Working area `/var/local/ai/spar/runs/` (on the 11 TB md0 RAID, not the small root partition). Harness `run.py` drives ollama `/api/generate` and records `metrics.json`.

## 2. Method: facts-fed replay

Live reach is offline on this box (the LinkedIn browser-serialiser fails on a tcllib pkgIndex error; no Brave/SerpApi key present), so retrieval was replayed rather than re-fetched. Each engine received the same `source-facts.md` inline and produced the Marco Fredriks SPAR-P profile in one call, `num_ctx` 8192 (the task's real context is ~2.3k tokens), thinking off.

The facts are **Sonnet-sourced**: the LinkedIn parse-profile plus the web, aggregator, directory and roster claims the hosted Sonnet baseline encountered, reconstructed from Sonnet's finished profile, with Sonnet's own verdicts withheld so each model must verify for itself. This includes the roster p_note's ING Insurance International / DiscoveryLife claim, which the first cut (fed from the laptop Qwen3-30B capture) never saw. See §5 on provenance.

## 3. Results (same contact, same facts, same prompt)

| Engine | Fits 8 GB VRAM | tg (t/s) | wall | Career vs LinkedIn | Verification | Star |
|---|---|---|---|---|---|---|
| Hosted Sonnet (quality baseline) | n/a | n/a | n/a | full, with notes | full, active | 2 |
| Laptop Qwen3-30B (Vulkan, sibling worklog) | n/a (UMA) | 11 | 281 s | full | passive | 4 |
| llama3.1:8b | yes, 6.3 GB, 100% GPU | 63.2 | 13.4 s | 8/8 (kept the parser's ambiguous "Christchurch" row) | partial | 4 |
| qwen3:8b | yes, 6.6 GB, 100% GPU | 58.0 | 28.4 s | 7/8 (dropped Infinite Energy, duplicated Shamrock) | strongest, 5 explicit rejections | 5 |
| qwen2.5:14b | no, 11 GB, 36% CPU spill | 7.0 | 83.9 s | 8/8 clean | rejected roster ING/DiscoveryLife | 3 |

Reading: every local engine is fact-complete and non-fabricating on identical facts. The best local result is **qwen2.5:14b** (8/8 career, active verification, and a star 3 that is the closest any local came to careful Sonnet's 2). Its cost is the spill: at 11 GB it exceeds the 8 GB VRAM, runs 36% on CPU, and decodes at the system-RAM floor. That is fine for batch research, slow for interactive use.

## 4. Hardware lessons (each the same shape: stay in VRAM or fall to the system-RAM floor)

- **Fit-in-VRAM decode is fast.** An 8B model resident in the 8 GB card decodes at ~60–65 t/s (448 GB/s VRAM, compute-bound at ~214 W).
- **Over-provisioning `num_ctx` spills the KV cache.** Setting `num_ctx` 32768 on llama3.1:8b reserved ~4 GB of KV on top of 4.9 GB of weights, pushing past 8 GB; tg collapsed from 65 to 9.7 t/s. The task needs ~2.3k tokens, so an 8k window keeps everything resident. Size context to the task.
- **A model larger than VRAM spills too.** qwen2.5:14b (11 GB) runs 36% on the CPU, GPU idle, decode at 7 t/s.
- Everything that spills, whether by context or by model size, lands in the same ~7–11 t/s band, because they are all bottlenecked by the ~38 GB/s DDR4, not by the GPU.

## 5. Baseline provenance (read this before trusting the comparison)

There are two baselines with different roles. Sonnet is the **quality** baseline: the star-2 profile the local outputs are judged against. Separately there is a **facts-provider** baseline: the retrieval every local run consumes.

The facts-provider here is Sonnet-sourced, but it is **reconstructed from Sonnet's finished profile, not a pristine live Sonnet capture**. Sonnet's raw retrieval was never saved, so what the locals ate is a hand-rebuilt neutral rendering of Sonnet's findings, which necessarily launders through Sonnet's synthesis. The very first cut of these runs used the laptop Qwen3-30B run's captured tool outputs as the provider; that cut is preserved in git history and was re-based onto Sonnet here. A genuinely clean provider (a live Sonnet run with raw tool outputs captured) is the future step, gated on installing live LinkedIn and web reach on this box.

## 6. Conclusion

A local model on this box produces a comparable SPAR-P profile at reasonable time and load. The engine choice is a real trade, not a free lunch: the VRAM-fitting 8B models are fast (13–28 s) but calibrate high (star 4–5) and, in Qwen3-8B's case, drop a career row; the 14B gets facts and calibration closest to Sonnet (star 3) but spills to 84 s. The one gap none of the locals closed is rating calibration: all rate above careful Sonnet's 2, though the richer Sonnet-sourced facts pulled the 14B down from 4 to 3.

Reproduce: `/var/local/ai/spar/runs/run.py <ollama-model> <outdir>`, with `source-facts.md` in `<outdir>`.

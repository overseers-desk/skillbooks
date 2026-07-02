# WORKLOG 2026-07-02 — SPAR-P on local models, GPU-Workstation (CUDA, RTX 2070 SUPER)

Forward-only record for a future agent asked "can SPAR-P run on the GPU-Workstation box, with the local model producing a comparable profile at reasonable time and machine load?" This box is a different environment from the laptop the sibling `WORKLOG.md` describes (that one is a Lunar Lake laptop, Arc 140V, Vulkan). This file is about the desktop.

## 1. The box (measured)

- CPU AMD Ryzen 7 5800X (8-core); 31 GiB system RAM, DDR4-2400 dual-channel (both channels populated).
- GPU NVIDIA RTX 2070 SUPER, 8 GB GDDR6, driver 570.195.03, CUDA toolkit 12.2, ollama 0.16.2.
- Memory bandwidth, the number that governs decode: GPU VRAM ~448 GB/s (7001 MHz x2, 256-bit); system RAM ~38 GB/s (DDR4-2400 dual-channel); PCIe Gen3 x16 bridge ~16 GB/s. Fast inside VRAM, slow outside it.
- Working area `/var/local/ai/spar/runs/` on the 11 TB md0 RAID. Harness `run.py` drives ollama `/api/generate` and records `metrics.json`.

## 2. Method: live retrieval, supplied to each model

The harness retrieves live for the run, then hands the same facts to each engine so the only variable is the consuming model:

- LinkedIn: `browser-serialiser linkedin.com/parse-profile marco-fredriks-5737bb15` via the linkedin.com skill, the authoritative source for identity and career (`login --check` reports `already_logged_in`).
- Web: live web search for the aggregator and name-collision material (ZoomInfo, RocketReach, Crunchbase, the ING Vysya Life Insurance claim), plus a direct fetch of shadesystems.co.nz for institutional context.
- The roster row and its p_note (the ~13 yr "ING Insurance International" / "DiscoveryLife" claim) are the campaign input, carried as a claim to verify.

The assembled `source-facts.md` holds neutral claims only; the verification is left to the model. Each engine runs one ollama call, `num_ctx` 8192 (the task needs ~2.3k tokens), temperature 0 (greedy, reproducible), thinking off.

## 3. Results (same contact, same live facts, same prompt, temperature 0)

| Engine | Fits 8 GB VRAM | tg (t/s) | wall | Career vs LinkedIn | Verification | Star |
|---|---|---|---|---|---|---|
| Hosted Sonnet (quality baseline) | n/a | n/a | n/a | full, with notes | full, active | 2 |
| Laptop Qwen3-30B (Vulkan, sibling worklog) | n/a (UMA) | 11 | 281 s | full | passive | 4 |
| llama3.1:8b | yes, 6.3 GB, 100% GPU | 67.3 | 13.8 s | all real roles (kept the parser's "Christchurch" artifact) | active | 4 |
| qwen3:8b | yes, 6.6 GB, 100% GPU | 61.9 | 20.5 s | weakest: dropped Central Otago + Infinite Energy, misdated two | strongest, 3 explicit rejections | 5 |
| qwen2.5:14b | no, 11 GB, 36% CPU spill | 7.0 | 85.8 s | dropped Infinite Energy, merged Shamrock/ManageIT | active | 4 |

Reading: with live facts every local engine reproduces the bulk of the LinkedIn career and actively rejects the insurance name-collision claims that the roster p_note and the aggregators attach to this name. The smaller and older models make career-table transcription errors (dropped or misdated rows); llama3.1:8b was the most faithful this run, qwen3:8b the least. Verification is solid across all three; the residual gap is rating calibration, where every local rates 4 or 5 against careful Sonnet's 2.

Reproducibility note: temperature 0 is used so the numbers above re-run identically. At temperature 0.6 the star rating varies by about one point between samples, so a single sampled rating is not a stable signal.

## 4. Hardware lessons (each the same shape: stay in VRAM or fall to the system-RAM floor)

- Fit-in-VRAM decode is fast: an 8B resident in the 8 GB card decodes at ~62–67 t/s (448 GB/s VRAM, compute-bound at ~214 W).
- Over-provisioning `num_ctx` spills the KV cache: `num_ctx` 32768 on llama3.1:8b reserved ~4 GB of KV on top of 4.9 GB of weights, pushing past 8 GB, and tg collapsed from 65 to 9.7 t/s. The task needs ~2.3k tokens, so an 8k window keeps everything resident. Size context to the task.
- A model larger than VRAM spills too: qwen2.5:14b (11 GB) runs 36% on the CPU, GPU idle, decode at 7 t/s.
- Everything that spills, whether by context or by model size, lands in the same ~7–11 t/s band, bottlenecked by the ~38 GB/s DDR4 rather than the GPU.

## 5. Baselines

Sonnet is the quality baseline: the star-2 profile the local outputs are judged against. The facts are the run's own live first-party retrieval on this box (LinkedIn skill + live web search + site fetch), not any other model's output.

## 6. Conclusion

A local model on this box produces a comparable SPAR-P profile at reasonable time and machine load. The engine choice is a trade: the VRAM-fitting 8B models are fast (14–20 s) and, given good live facts, verify actively, but calibrate high (star 4–5) and can drop or misdate a career row; the 14B is close on facts and verification but spills to ~86 s. The one gap none of the locals closed is rating calibration against careful Sonnet's 2.

Reproduce: `/var/local/ai/spar/runs/run.py <ollama-model> <outdir>`, with `source-facts.md` in `<outdir>`.

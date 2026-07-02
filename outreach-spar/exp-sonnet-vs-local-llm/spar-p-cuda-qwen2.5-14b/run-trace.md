# Run trace — SPAR-P local, qwen2.5:14b (CUDA, RTX 2070 SUPER, spills), facts-fed

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed replay. The LinkedIn `parse-profile` output and 3 brave-search snippet sets captured by the laptop Qwen3-30B run (`source-facts.md`) were passed inline to the model via ollama `/api/generate`; `num_ctx` 8192, temperature 0.6, thinking off. This box's live reach is offline (browser-serialiser tcllib broken; no search key), so retrieval was replayed, not re-fetched. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen2.5-14b-cuda.md`.

Metrics (`metrics.json`): tg 6.5 t/s, prefill 596 t/s, prompt 3754 tok, output 558 tok, wall 93.1 s. Load: 11 GB model exceeds the 8 GB VRAM, so ollama splits it 36% CPU / 64% GPU; during decode the GPU idles at ~3% / 17 W while the CPU-resident third streams from the ~38 GB/s DDR4. This is the spill regime: throughput drops to the system-RAM floor. Acceptable for batch research work, not for interactive use.

Findings:
- Career history: 8/8 roles correct against the LinkedIn parse-profile.
- Verification: active. Rejected the RocketReach "ING Vysya Life Insurance" claim and the ZoomInfo risk/insurance claim as unverified against LinkedIn.
- Rating: 4 (over-generous vs careful Sonnet 2).
- Best accuracy-plus-verification of the three, at the cost of the spill latency.

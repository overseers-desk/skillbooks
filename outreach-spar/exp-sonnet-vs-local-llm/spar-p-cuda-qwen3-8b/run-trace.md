# Run trace — SPAR-P local, qwen3:8b (CUDA, RTX 2070 SUPER), facts-fed

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed replay. The LinkedIn `parse-profile` output and 3 brave-search snippet sets captured by the laptop Qwen3-30B run (`source-facts.md`) were passed inline to the model via ollama `/api/generate`; `num_ctx` 8192 (the task's real context is ~3.6k tokens), temperature 0.6, thinking off. This box's live reach is offline (browser-serialiser tcllib broken; no search key), so retrieval was replayed, not re-fetched. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen3-8b-cuda.md`.

Metrics (`metrics.json`): tg 59.5 t/s, prefill 1634 t/s, prompt 3745 tok, output 672 tok, wall 23.1 s. Load: 6.6 GB VRAM, 100% GPU offload, no system-RAM spill.

Findings:
- Career history: 5/8 roles, one misdated. It placed "Finance Manager, Shamrock Industries" in the Oct 2022–Dec 2024 slot that belongs to Infinite Energy, and dropped ManageIT, Extraordinary Advisors, and the real Infinite Energy row. Least accurate of the three on the core deliverable, likely aggravated by temperature 0.6.
- Verification: active. Rejected the RocketReach "ING Vysya Life Insurance" claim and flagged the ZoomInfo risk/insurance claim as unverified against LinkedIn, the reflex both other 8B behaviours lack.
- Rating: 5 (highest, weakest calibration).
- Defect: echoed one template placeholder line.

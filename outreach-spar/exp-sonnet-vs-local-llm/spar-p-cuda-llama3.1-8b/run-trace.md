# Run trace — SPAR-P local, llama3.1:8b (CUDA, RTX 2070 SUPER), facts-fed

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed replay. The LinkedIn `parse-profile` output and 3 brave-search snippet sets captured by the laptop Qwen3-30B run (`source-facts.md`) were passed inline to the model via ollama `/api/generate`; `num_ctx` 8192 (the task's real context is ~3.6k tokens), temperature 0.6, thinking off. This box's live reach is offline (browser-serialiser tcllib broken; no search key), so retrieval was replayed, not re-fetched. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-llama3.1-8b-cuda.md`.

Metrics (`metrics.json`): tg 65.2 t/s, prefill 1856 t/s, prompt 3594 tok, output 582 tok, wall 13.6 s. Load: 6.3 GB VRAM, 100% GPU offload, 97% util at ~214 W (compute-bound, no system-RAM spill).

Findings:
- Career history: 8/8 roles correct against the LinkedIn parse-profile (LinkedIn-only roles Gough Industrial Solutions, Extraordinary Advisors, Central Otago District Council all present, proving the LinkedIn block was used).
- Verification: passive. Did not flag the RocketReach "ING Vysya Life Insurance" name-collision claim or the "25 years in Insurance" headline tension, though the prompt instructed rejecting unverified aggregator claims.
- Rating: 4 (over-generous vs careful Sonnet 2).
- Defect: echoed the template placeholder lines (`[from LinkedIn: ...]`) into the output.

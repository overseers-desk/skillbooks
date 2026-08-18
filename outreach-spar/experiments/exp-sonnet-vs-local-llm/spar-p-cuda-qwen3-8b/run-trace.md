# Run trace — SPAR-P local, qwen3:8b (CUDA, RTX 2070 SUPER), live retrieval

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: the harness retrieved live for this run and supplied the result as `source-facts.md` — the LinkedIn parse-profile via the linkedin.com skill (authoritative for identity and career), live web search for aggregator context, and a direct fetch of the company site. The model produced the profile in one ollama `/api/generate` call, `num_ctx` 8192, temperature 0 (greedy, so the run is reproducible), thinking off. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen3-8b-cuda.md`.

Metrics (`metrics.json`): tg 61.9 t/s, prompt 2322 tok, output 801 tok, wall 20.5 s. Load: 6.6 GB VRAM, 100% GPU offload.

Findings:
- Career history: the weakest of the three. It dropped the Finance Specialist (Central Otago District Council) and Infinite Energy rows, misdated Shamrock and ManageIT, and rendered only six entries.
- Verification: strongest of the three. Explicitly rejected the roster ING / DiscoveryLife claim, the RocketReach "currently General Manager at ManageIT" claim, and the ING Vysya Life Insurance CFO claim, each against the LinkedIn profile.
- Rating: 5 (highest, weakest calibration vs Sonnet's 2).

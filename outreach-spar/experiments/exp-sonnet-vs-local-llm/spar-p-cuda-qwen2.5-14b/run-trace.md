# Run trace — SPAR-P local, qwen2.5:14b (CUDA, RTX 2070 SUPER, spills), live retrieval

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: the harness retrieved live for this run and supplied the result as `source-facts.md` — the LinkedIn parse-profile via the linkedin.com skill (authoritative for identity and career), live web search for aggregator context, and a direct fetch of the company site. The model produced the profile in one ollama `/api/generate` call, `num_ctx` 8192, temperature 0 (greedy, so the run is reproducible), thinking off. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen2.5-14b-cuda.md`.

Metrics (`metrics.json`): tg 7.0 t/s, prompt 2334 tok, output 654 tok, wall 85.8 s. Load: the 11 GB model exceeds the 8 GB VRAM, so ollama splits it 36% CPU / 64% GPU; during decode the GPU idles while the CPU-resident third streams from the ~38 GB/s DDR4. Spill regime: throughput drops to the system-RAM floor. Acceptable for batch research, not for interactive use.

Findings:
- Career history: dropped the Infinite Energy row and merged Shamrock across the ManageIT dates, leaving seven entries; more faithful than qwen3, less than llama3.1.
- Verification: active. Rejected the roster ING / DiscoveryLife claim and the aggregated insurance-sector bios as contradicted by the direct LinkedIn fetch.
- Rating: 4 (above careful Sonnet's 2).

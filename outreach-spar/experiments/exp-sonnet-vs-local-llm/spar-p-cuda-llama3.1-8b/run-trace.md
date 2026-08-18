# Run trace — SPAR-P local, llama3.1:8b (CUDA, RTX 2070 SUPER), live retrieval

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: the harness retrieved live for this run and supplied the result as `source-facts.md` — the LinkedIn parse-profile via the linkedin.com skill (authoritative for identity and career), live web search for aggregator context, and a direct fetch of the company site. The model produced the profile in one ollama `/api/generate` call, `num_ctx` 8192, temperature 0 (greedy, so the run is reproducible), thinking off. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-llama3.1-8b-cuda.md`.

Metrics (`metrics.json`): tg 67.3 t/s, prompt 2232 tok, output 649 tok, wall 13.8 s. Load: 6.3 GB VRAM, 100% GPU offload.

Findings:
- Career history: the most faithful of the three. All eight real roles present with correct dates and organisations; it also carried the parser's ambiguous "Christchurch" (Oct 2014–Jul 2019) row, which is likely a location rather than an employer.
- Verification: active. Rejected the roster p_note's ING Insurance International / DiscoveryLife claim and the RocketReach / aggregated-bio ING Vysya Life Insurance claim as unsupported by the LinkedIn profile.
- Rating: 4 (above careful Sonnet's 2).

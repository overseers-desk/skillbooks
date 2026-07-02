# Run trace — SPAR-P local, qwen3:8b (CUDA, RTX 2070 SUPER), Sonnet-sourced facts

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed. Input is `source-facts.md`, the Sonnet-sourced findings (LinkedIn parse-profile plus the web/aggregator/roster claims the hosted Sonnet baseline encountered, with Sonnet's verdicts withheld). Passed inline via ollama `/api/generate`, `num_ctx` 8192, temperature 0.6, thinking off. Reach is offline on this box, so retrieval is replayed. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen3-8b-cuda.md`.

Metrics (`metrics.json`): tg 58.0 t/s, prompt 2336 tok, output 779 tok, wall 28.4 s. Load: 6.6 GB VRAM, 100% GPU offload, no system-RAM spill.

Findings:
- Career history: 7/8. It dropped the Infinite Energy NZ (Oct 2022–Dec 2024) row and duplicated Shamrock Industries into that slot. Weakest career accuracy of the three, consistent with the first cut.
- Verification: strongest of the three. Explicitly rejected five insurance claims in the facts (roster ING Insurance International, DiscoveryLife, "25 years in Insurance", RocketReach ING Vysya Life Insurance, the Insurance skill tags), each against the LinkedIn profile.
- Rating: 5 (highest, weakest calibration).
- Defect: echoed a template placeholder line.

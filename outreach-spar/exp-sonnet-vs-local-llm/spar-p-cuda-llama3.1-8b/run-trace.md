# Run trace — SPAR-P local, llama3.1:8b (CUDA, RTX 2070 SUPER), Sonnet-sourced facts

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed. Input is `source-facts.md`, the Sonnet-sourced findings (LinkedIn parse-profile plus the web/aggregator/roster claims the hosted Sonnet baseline encountered, with Sonnet's verdicts withheld). Passed inline via ollama `/api/generate`, `num_ctx` 8192, temperature 0.6, thinking off. Reach is offline on this box, so retrieval is replayed. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-llama3.1-8b-cuda.md`.

Metrics (`metrics.json`): tg 63.2 t/s, prompt 2266 tok, output 625 tok, wall 13.4 s. Load: 6.3 GB VRAM, 100% GPU offload, no system-RAM spill.

Findings:
- Career history: 8/8 real roles correct; it also reproduced the parser's ambiguous "Christchurch" (Oct 2014–Jul 2019) row, which is likely a location artifact rather than an employer.
- Verification: partial. Rejected the ZoomInfo insurance/risk expertise claim and surfaced the roster ING/DiscoveryLife claim, but did not explicitly reject every insurance claim in the facts.
- Rating: 4 (over-generous vs careful Sonnet 2).
- Defect: echoed a template placeholder line.

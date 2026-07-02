# Run trace — SPAR-P local, qwen2.5:14b (CUDA, RTX 2070 SUPER, spills), Sonnet-sourced facts

Date: 2026-07-02. Box: GPU-Workstation, RTX 2070 SUPER 8 GB (driver 570.195.03), ollama 0.16.2.

Method: facts-fed. Input is `source-facts.md`, the Sonnet-sourced findings (LinkedIn parse-profile plus the web/aggregator/roster claims the hosted Sonnet baseline encountered, with Sonnet's verdicts withheld). Passed inline via ollama `/api/generate`, `num_ctx` 8192, temperature 0.6, thinking off. Reach is offline on this box, so retrieval is replayed. Driver: `/var/local/ai/spar/runs/run.py`.

Profile produced: `marco-fredriks.local-qwen2.5-14b-cuda.md`.

Metrics (`metrics.json`): tg 7.0 t/s, prompt 2348 tok, output 538 tok, wall 83.9 s. Load: the 11 GB model exceeds the 8 GB VRAM, so ollama splits it 36% CPU / 64% GPU; during decode the GPU idles while the CPU-resident third streams from the ~38 GB/s DDR4. Spill regime: throughput drops to the system-RAM floor. Acceptable for batch research, not for interactive use.

Findings:
- Career history: 8/8 real roles correct and clean; it dropped the parser's ambiguous "Christchurch" artifact row rather than reproducing it.
- Verification: rejected the roster ING Insurance International / DiscoveryLife claims as unsupported by LinkedIn.
- Rating: 3. The best-calibrated local result, the closest any local model came to careful Sonnet's 2. With the richer Sonnet-sourced facts (the three concurrent "present" roles, the portfolio pattern), the 14B pulled its own rating down from the 4 it gave on the thinner first-cut facts.
- Best accuracy-plus-calibration of the three, at the cost of the spill latency.

# SPAR-P, facts-fed, Qwen3-30B-A3B via ollama on dappnode

The July study (`../2026-07-02-blind-quality-12x5/`) judged twelve media-creator profiles across hosted Sonnet and four local models, three of them facts-fed from a facts sheet reconstructed out of the Sonnet profile. This folder adds a sixth version of each of the twelve: the same twelve contacts, the same facts sheets (the Sonnet baseline files of the July study, front matter and verdict sections stripped by the July driver), the same one-shot prompt (`../batch-media-creator/prompt-media-creator-factsfed.txt`), the same driver (`../batch-media-creator/cuda-factsfed-batch.py`), run against `qwen3-30b-128k` on dappnode, a CPU-only host, over the SSH tunnel, with thinking off as the July facts-fed runs had it.

Two settings differ from July and are recorded so the timings are read correctly. The request names the loaded model's context length, 131072, rather than July's 8192, because the server was shared with a running sweep and a request naming a different length makes ollama reload the model, evicting the other caller. And every request queued behind that sweep's in-flight turn, so wall-clock per profile carries a queue wait the server's own prefill and generation figures do not.

## Files

- `stems-12.txt`: the twelve contacts, the ones every July version exists for.
- `profiles/`: the model's output, one per stem, as the driver wrote it.
- `raw/`: the server's raw responses.
- `factsfed.progress`: one line per stem with outcome, wall time and context, the driver's own format.
- `judge-brief.md`: the judging method, fixed before the first profile existed.
- `build-packets.py`: assembles the six-version blind packets the brief describes.

## Started

22 September 2026, 00:02 AEST, with the first profile not yet written.

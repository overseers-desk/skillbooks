# Local-LLM experiments on host `yoga` — invariants

Read before running anything here. These are hard constraints, learned the hard way.

## 1. Experiments iterate — never leave the box needing a reboot to continue

Assume every run is one of a series. The user will change a parameter — model, quant,
LinkedIn on/off, context size, backend — and run again. Do NOT treat a run as terminal
(as if the machine is about to be shut down and nothing follows).

Consequences for how you run:
- Run **one persistent `llama-server`** (load the model once) and stream successive
  profiles through it via `ccr`. Do not load/unload per profile.
- How you stop it does not matter for memory: SIGTERM / SIGINT / `kill -9` all tested
  the same. The `xe`/Vulkan GTT holding the weights is **not** released on process exit —
  it lingers as `used` (invisible to process RSS) after the server is gone, and does not
  drain at idle.
- **This is a lazy free, not an accumulating leak.** The next GPU allocation reclaims it:
  a subsequent `llama-server` load — same model or a different one — reuses the orphaned
  GTT instead of stacking on it (verified: 3.5→3.5 and 3.5→30b reloads each held at one
  model's footprint, ~20–23 GiB, not ~40). So back-to-back runs and engine swaps need
  **no reboot**; ignore the high idle `used` — the next load reclaims it.
- A reboot (or GPU reset) is needed only to hand that RAM back to the general pool while
  **no** model is loaded — e.g. to free it for a non-GPU task. If idle-clean RAM matters
  more than prefill speed, the CPU build (no `-ngl`) avoids GTT entirely and frees on exit.

## 2. Memory is THE binding constraint — budget it first, every time

This host is ~30 GiB shared between CPU and the Arc iGPU (UMA — the GPU has no separate
VRAM). A Q4 A3B model is ~20–22 GiB of that. Before any run, check `free` and confirm
model + KV fits with headroom:
- KV ≈ `-c` context × ~96 KiB/token (this model class); halve it with
  `--cache-type-k q8_0 --cache-type-v q8_0`, or lower `-c` (16384 is plenty for one profile).
- Weights are held as `xe` GTT — **invisible to process RSS**. Read `free`/`used`, not RSS.
- Under Wayland the GUI baseline (~5 GiB, GNOME only) eats headroom; console frees ~13 GiB.
  Wayland is not a blocker if the GUI is light; the orphaned idle GTT is not a blocker
  either — the next model load reclaims it (invariant 1). Just budget one model's worth.

**/tmp is tmpfs (RAM-backed): keep large files off it** — a big file there consumes the
very memory the model needs. Write big artifacts to disk:
- Models + builds: `/usr/local/ai/spar/` (separate NVMe, `nvme0n1p3`, ~318 GiB free — NOT root).
- Run artifacts (streams, profiles, logs): the engine folder under this experiment.
- Runtime `.log` noise goes in each engine's `logs/` and is git-ignored (`*.log`).

Host GPU-driver stability (`xe` hangs on 6.x, clean on 7.x) is tracked in the host issue
book `~/code/holotapes-main/issues/host=yoga,*` — not here. This file is about running
the experiments; that one is about the hardware.

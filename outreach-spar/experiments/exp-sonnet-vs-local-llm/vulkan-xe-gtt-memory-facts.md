# Vulkan/xe GTT memory on host `yoga` — facts and how to validate

**Scope: the Vulkan backend only** (`llama-server -ngl 99` on the Intel Arc 140V, `xe` driver,
Lunar Lake UMA). The CPU backend (no `-ngl`) does NOT behave this way — its weights are ordinary
anonymous memory that frees on process exit. If you are on CPU, ignore this file.

## TL;DR — the memory IS reclaimable. Do not conclude "leak / can't reclaim / must reboot."
After a Vulkan run stops, `free` shows ~a model's worth still `used`, owned by no process, not
draining. It **looks** like an unrecoverable leak. It is not: the **next GPU allocation reclaims
it**. Validate by *loading the model*, never by reading `free` at idle. A prior agent (me)
concluded "can't reclaim, reboot needed" three times and was wrong every time — each time from
reasoning off idle `free` instead of running the load test below.

## The facts (each verified on 2026-07-02, kernel 7.0.0-27)
1. On UMA the weights load as **`xe` GTT buffers in shared system RAM** (no separate VRAM). They
   are **invisible to process RSS** — `llama-server` RSS is ~80 MB while holding ~20 GB of weights.
   Read `free`/`used`, not `ps` RSS, to see them.
2. GTT is **not released on process exit** — SIGINT (server logs "cleaning up before exit"),
   SIGTERM, and `kill -9` were tested and behave **identically**. How you stop the server does not
   matter for memory.
3. The orphaned GTT **does not drain at idle** (watched 45 s+, flat), **no process owns it**
   (total process RSS ~1 GB while ~14 GB is held), and `drop_caches` does not touch it (it is not
   page cache).
4. **The next GPU allocation reclaims it.** Verified:
   - reload same model (3.5 → 3.5): after stop, `used` ~17 GB orphaned; new load reached
     `listening on` with `used` **22.9 GB — one model**, not ~40 GB.
   - reload different model (3.5 → 30b): orphan ~17.5 GB; 30b load landed at `used` **19.7 GB —
     one model**. ~40 GB (stacked) would have OOM'd; it did not.
5. Therefore it is a **lazy free, not an accumulating leak.** Steady state across any number of
   reloads is one model's footprint. Back-to-back runs and engine swaps need **no reboot**.
6. The RAM returns to the general pool (while no model is loaded) only via: a **reboot**, a **GPU
   reset**, or using the **CPU backend** (which never allocates GTT).

## The trap (why the next agent will misread this)
Right after a run: `free` shows 17–24 GB `used`, the top processes sum to ~1–2 GB, it does not
drain, and `avail` (~13 GB) is *less than* the model size (~20 GB). Every idle signal says
"leak, won't fit, reboot." **All of that is idle inspection, which cannot see reclaim-under-
pressure.** The reclaim only happens when a new GPU allocation demands the space. So the arithmetic
"avail < model ⇒ OOM" is false here — do not trust it; run the load test.

## How to validate (do this instead of reasoning from `free`)
```bash
# 1. Decompose current 'used' — the RSS-invisible remainder is candidate orphaned GTT:
t=$(awk '/MemTotal/{print $2}' /proc/meminfo); f=$(awk '/MemFree/{print $2}' /proc/meminfo)
c=$(awk '/^Cached/{print $2}' /proc/meminfo); b=$(awk '/^Buffers/{print $2}' /proc/meminfo)
s=$(awk '/^Slab/{print $2}' /proc/meminfo); rss=$(ps -eo rss --no-headers|awk '{x+=$1}END{print x}')
awk -v t=$t -v f=$f -v c=$c -v b=$b -v s=$s -v rss=$rss 'BEGIN{printf "orphaned-GTT candidate: %.1f GiB\n",(t-f-c-b-s-rss)/1048576}'

# 2. THE DECISIVE TEST — do not predict OOM, just load with the orphan present:
llama-server -m <model.gguf> -ngl 99 -c 2048 --jinja > /tmp-DISK/load.log 2>&1 &   # write log to DISK, not /tmp (tmpfs)
# poll for success; IGNORE the benign warning "failed to fit params to free device memory ... abort"
#   (that is NOT an error — it just means -ngl was set manually). Wait for "listening on" / "model loaded".
grep -m1 'listening on' <(tail -f load.log)

# 3. Confirm reclaim: after "listening on",
free -m | awk '/Mem:/{print "used "$3"M (expect ~baseline+ONE model ~20-23GB, NOT ~40GB)"}'
```
If it reaches `listening on` and `used` ≈ baseline + one model, reclaim is confirmed and there was
never a need to reboot. If it truly OOMs (log shows `ErrorOutOfDeviceMemory` / `bad_alloc` /
`cannot allocate` — NOT the "abort" warning), *then* reclaim failed and you have a real problem to
report.

## Operational rules
- **Campaign (many profiles):** one persistent `llama-server`, load once, stream all profiles
  through `ccr`. GTT allocated once — the question never arises. This is the default.
- **Comparison / reload (swap models):** just reload. The new load reclaims the old GTT. No reboot.
- **Need idle RAM back for a non-GPU task while no model is loaded:** reboot, GPU reset, or run the
  CPU build instead. Only then.
- **CPU backend** (`-t N`, no `-ngl`): no GTT, frees on exit — clean idle. Trade-off: slower prefill
  (~56 vs ~230 t/s); generation similar (~17 vs ~11 t/s). Choose it if idle-clean RAM matters more
  than prefill speed.

See `CLAUDE.md` (invariant 1) for the short version; this file is the evidence and the validation
procedure behind it.

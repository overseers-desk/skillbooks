# Rock 5B+ (RK3588) as a SPAR-P inference box: what its NPU can and cannot do

Desk evaluation, no hardware tested. It answers whether a Radxa ROCK 5B+ with 32 GB could replace hosted Sonnet for SPAR-P, and what its NPU is actually good for. Every figure is marked **measured here**, **published** or **estimated**, because the three carry very different weight.

**Answer: no, and the blocker is context, not speed.** The NPU's software caps context at 16,384 tokens. SPAR-P profiles measured 73k–111k. The gap is a factor of five to seven, and no amount of patience closes it. Running the CPU instead lifts the context cap but gives roughly **1–1.5 t/s** on a 27B, about half of what the laptop already does, and the laptop is itself too slow for the workload.

## 1. The NPU

RK3588 carries Rockchip's own **RKNPU2, three cores, 6 TOPS combined, INT8**. It is not a CUDA-like general accelerator. Models reach it only after conversion to Rockchip's `.rkllm` format with `rknn-toolkit2`, and only if the architecture is one the toolkit implements.

Three constraints follow, all published by Rockchip or Radxa:

- **INT8 weights only.** RK3588 supports `w8a8`, not `w4a16`. Weights cost one byte per parameter, so a model needs twice the memory it would at Q4.
- **`max_context_len` ≤ 16,384**, default 4,096, and a multiple of 32.
- **Architecture allow-list.** Llama, TinyLlama, Qwen, Qwen3 and Qwen3-VL, Phi, ChatGLM3-6B, Gemma 2/3, InternLM2, MiniCPM, TeleChat, with Qwen3.5, Gemma 4 and SmolLM3 added recently. Published conversions run to about 4B.

**The NPU does not add memory bandwidth.** It shares the same 64-bit bus as the CPU cores. Decoding a token means streaming every weight, so the NPU cannot make decoding faster. What it accelerates is prefill, which is compute-bound. That is a real gain, and it is aimed at the wrong half of the problem for a model this size.

## 2. Bandwidth, which sets the ceiling

| | |
|---|---:|
| RK3588 bus | 64-bit LPDDR4x/LPDDR5 |
| Theoretical peak | ~34 GB/s (LPDDR4x) |
| Measured, STREAM | 21–22 GB/s |
| Measured, block copy | 17–19 GB/s |
| For comparison, the Lunar Lake laptop | ~136 GB/s theoretical |

Published measurements. The laptop has roughly six times the bandwidth, and decode speed on a dense model is close to a straight ratio of it.

## 3. Rates to expect

**Published, llama.cpp on CPU, RK3588, sustained:**

| model size | decode |
|---|---:|
| 4B | 5–8 t/s |
| 7B | 3–7 t/s |
| 14B | 2–4 t/s |
| 27–32B | **1–1.5 t/s** |

**Published, NPU via RKLLM:** 10–15 t/s on a 1.1B model. Scaling that by weight volume at `w8a8` gives **estimated** 2.5–3 t/s for a 7B and 1.3–1.5 t/s for a 14B. The NPU roughly matches the CPU on decode, as bandwidth predicts, and beats it on prefill.

**Measured here, for comparison,** the same class of task on the laptop with Qwen3.8-27B Q4:

| | laptop, measured |
|---|---:|
| decode | 2.61 t/s |
| prefill, depth 0 | 99.7 t/s |
| prefill, depth 10,240 | 41.5 t/s |
| prefill, depth 30,720 | 19.2 t/s |

So a Rock 5B+ running our model on CPU lands around **1–1.5 t/s decode, roughly half the laptop**. Prefill on CPU is **estimated** at 3–8 t/s, against the laptop's 40–100 over the same range. The NPU could lift prefill materially, but only for a model small enough to convert and fit.

## 4. What fits in 32 GB

At `w8a8`, weight memory equals parameter count in bytes.

| model | NPU (w8a8) | fits 32 GB with a cache | on the allow-list |
|---|---:|---|---|
| Qwen3 4B | 4 GB | yes, comfortably | yes, conversions published |
| 7B | 7 GB | yes | yes |
| 14B | 14 GB | yes | architecture yes, conversion unpublished |
| Our Qwen3.8-27B | 27.8 GB | no, leaves ~4 GB for everything | no |

The 27B fails twice over. It is not a supported architecture, and at INT8 it would consume nearly the whole board before any KV cache. On the laptop the same model is 15.33 GiB at Q4, which is the option INT8-only hardware removes.

**Context is the harder wall.** 16,384 tokens is the NPU maximum. Claude Code's own preamble is **measured here** at 10,624 tokens with the tool catalogue stripped, or 24,633 with it intact. The full catalogue does not fit at all. The stripped one leaves roughly 5,700 tokens for the entire conversation, every tool result and every file read. SPAR-P profiles measured 73k–111k.

## 5. Wiring it to Claude Code

This part is solved, and it is the only part that is.

Several community servers put an HTTP API in front of RKLLM. At least one speaks OpenAI's `/v1/chat/completions`, Ollama's `/api/chat`, and Anthropic's `/v1/messages`. Pointing claude-code-router at an OpenAI-compatible endpoint is exactly what the laptop already does, so the same `llm-claude` shape would work unchanged against a board on the LAN.

The plumbing being easy does not rescue the arithmetic above.

## 6. For SPAR-P specifically

Three reasons it fails, in order of how hard they are to argue with.

1. **Context.** 16,384 on the NPU against a measured 73k–111k need. On CPU the cap lifts to whatever RAM allows, so this reason applies to the NPU path alone.
2. **Speed.** At 1–1.5 t/s decode, a board is about half the laptop. The laptop, at 2.61 t/s, took an hour of wall clock for a 21-step agentic task. Doubling that is not a difference of degree that changes the answer.
3. **Model quality.** What fits the NPU is 4B to 14B. The July comparisons in this experiment found the residual gap against Sonnet was rating calibration, on models several times larger. A 4B is not a candidate for that work.

**The one thing a Rock 5B+ is good for here** is a small, fixed, high-volume classification step: a prompt that stays under a few thousand tokens, one model resident for weeks, no interactive latency requirement. It is a fixed-function appliance rather than an agent host. Nothing in the SPAR-P pipeline currently has that shape.

## 7. What would change the answer

- `max_context_len` above 16,384, or `w4a16` arriving on RK3588. Both are Rockchip's to ship.
- A newer SoC. The constraint is the 64-bit bus, so the question to ask of any successor is its measured bandwidth, not its TOPS.
- The workload shrinking. If SPAR-P research were fanned out to subagents so no single context exceeded 16k, the context objection would weaken. The speed objection would not.

## 8. Sources and status

Published figures come from Rockchip's `rknn-llm` repository and its releases, Radxa's RKLLM usage documentation, and third-party RK3588 benchmark write-ups. Bandwidth and llama.cpp rates are third-party measurements on RK3588 boards, not on a ROCK 5B+ specifically.

Laptop figures are measured, and the method for each sits in the office repository's host issue book under `issues/host=yoga,*`, in the 2026-08-30 record on driving Claude Code from a local model.

**Nothing here was run on a Rock 5B+.** One `llama-bench -p 2048 -n 128` on a board would replace section 3's estimates with facts in a few minutes, and is worth doing before any purchase.

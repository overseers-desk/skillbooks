#!/usr/bin/env bash
# Unattended post-run finisher for the Qwen3.5-35B redo (aesop#151).
# Waits for run-batch.sh to exit, then commits the produced profiles to the
# career branch and the redo progress.log to the aesop repo, and writes a
# RESUME-STATE.md the next (credit-reset) session reads to continue.
# Runs entirely locally: no hosted-model calls, spends no credit.
set -u

BATCH_DIR="$HOME/code/aesop/outreach-spar/exp-sonnet-vs-local-llm/batch-media-creator"
CAREER="$HOME/code/holotapes-career"
PROFILES="$CAREER/spar-campaigns/media-creator/profiles"
BRANCH="career-qwen35-vulkan"
RESUME="$BATCH_DIR/RESUME-STATE.md"

# 1. Wait for the driver to finish (poll; the driver itself uses the local model).
while pgrep -f "run-batch.sh working-set-47" >/dev/null 2>&1; do
  sleep 60
done

cd "$BATCH_DIR" || exit 1
succ=$(grep -c 'outcome=success' progress.log 2>/dev/null || echo 0)
failhw=$(grep -c 'outcome=fail-hardware' progress.log 2>/dev/null || echo 0)
failother=$(grep -cE 'outcome=fail-(unknown|timeout|context)' progress.log 2>/dev/null || echo 0)
rows=$(grep -c 'outcome=' progress.log 2>/dev/null || echo 0)

# 2. Commit the profiles onto the career engine branch (branch override authorized by #151).
if [ -d "$PROFILES" ]; then
  git -C "$CAREER" checkout "$BRANCH" 2>/dev/null
  git -C "$CAREER" add -A "spar-campaigns/media-creator/profiles" 2>/dev/null
  git -C "$CAREER" commit -q -m "Qwen3.5-35B redo profiles (aesop#151): ${succ} succeeded, ${failhw} hardware, ${failother} other" 2>/dev/null \
    && echo "committed profiles to $BRANCH" || echo "nothing to commit on $BRANCH"
fi

# 3. Commit the redo progress.log to aesop (whole-file, forward-only redo record).
git -C "$HOME/code/aesop" add outreach-spar/exp-sonnet-vs-local-llm/batch-media-creator/progress.log 2>/dev/null
git -C "$HOME/code/aesop" commit -q --only outreach-spar/exp-sonnet-vs-local-llm/batch-media-creator/progress.log \
  -m "exp: Qwen3.5-35B redo progress record (aesop#151): ${succ}/${rows} attempted" 2>/dev/null \
  && echo "committed progress.log to aesop" || echo "no progress.log change to commit"

# 4. Leave a resume note for the waking session.
cat > "$RESUME" <<EOF
# Qwen3.5-35B redo — overnight run state (aesop#151)

Finisher ran after run-batch.sh exited. This file is the pickup point for a
fresh session once credit is reset.

## What ran
- Engine: Qwen3.5-35B-A3B-Q4_K_M via llama-server :8080, ccr :3456 (all local, no hosted credit).
- Driver: run-batch.sh over working-set-47.txt (47 stems), 30-min per-profile breaker, resume by skipping outcome=success.
- Outcome tally at finish: ${succ} success, ${failhw} fail-hardware, ${failother} other; ${rows}/47 stems attempted.

## Where the outputs are
- Profiles: $PROFILES (committed to branch $BRANCH).
- Per-turn cost/context data: /usr/local/ai/spar/runs/holotapes-career-qwen35/streams/*.jsonl (peak context + output tokens recoverable here; run-batch's peak_ctx column reads llama-server.log, absent this run because the server was started warm).
- progress.log: per-profile duration, star, yield, out_tok, tool_calls (committed to aesop).

## What still needs a credit-reset session (needs judgment — not automatable locally)
Per #151 "Definition of done":
1. If any stems remain unattempted or fail-hardware'd, decide whether to re-run them (GPU stability permitting) before judging.
2. Deliverable #3 — blind judging: reuse 2026-07-02-blind-quality-12x5/ harness; anonymize per-engine copies, context-free judges, one per contact, on stems where the 35B succeeded. Answers question 1 (ceiling vs Sonnet).
3. Deliverable #2 — cost records: aggregate per-profile duration/peak-ctx/out_tok from progress.log + streams/*.jsonl; record engine weights/KV/resident memory.
4. Then the CUDA engines (GPU-Workstation) run the SAME method — driver not yet staged (see 2026-07-02-batch-gpuws-cuda.md); question 2 (quality-per-resource) needs all four local engines.
5. Deliverable #5 — dated worklog in this folder, forward-only.

Deliver the five, not a narrative of steps.
EOF
echo "wrote $RESUME"
echo "FINISHER DONE: ${succ} success / ${failhw} hw / ${rows} attempted"

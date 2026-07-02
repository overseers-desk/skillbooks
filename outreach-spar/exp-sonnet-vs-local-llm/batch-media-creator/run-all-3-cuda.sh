#!/usr/bin/env bash
# Sequential facts-fed batch for the 3 CUDA/ollama models (one at a time; 8 GB VRAM).
# Each model writes its 47 profiles to its own worktree; per-model progress logs.
set -u
BASE=/var/local/ai/spar/runs/holotapes-career-cuda
SRC="$HOME/code/holotapes-career/spar-campaigns/media-creator/profiles"
INSTR="$BASE/prompt-media-creator-factsfed.txt"
STEMS="$BASE/working-set-47.txt"
cd "$BASE"

# model | worktree dir | tag
SPECS="llama3.1:8b|ht-cuda-llama31-8b|llama31-8b
qwen3:8b|ht-cuda-qwen3-8b|qwen3-8b
qwen2.5:14b|ht-cuda-qwen25-14b|qwen25-14b"

while IFS= read -r spec; do
  [ -z "$spec" ] && continue
  m="${spec%%|*}"; rest="${spec#*|}"; wt="${rest%%|*}"; tag="${rest##*|}"
  dest="$HOME/code/$wt/spar-campaigns/media-creator/profiles"
  echo "=== $(date +%H:%M:%S) starting $m -> $tag ===" >> logs/run-all.log
  : > "logs/$tag.progress"
  python3 cuda-factsfed-batch.py "$m" "$STEMS" "$SRC" "$dest" "$INSTR" "logs/$tag.progress" raw >> "logs/$tag.out" 2>&1
  n=$(grep -c 'outcome=success' "logs/$tag.progress" 2>/dev/null || echo 0)
  echo "=== $(date +%H:%M:%S) done $m -> $tag : $n/47 success ===" >> logs/run-all.log
done <<< "$SPECS"
echo "ALL-DONE $(date +%H:%M:%S)" >> logs/run-all.log

#!/usr/bin/env bash
# usage: TAG=.. PROFILE=.. EMAIL=.. perform.sh <template> <runs> <model>  -- runs the prompt for real
tpl=$1; runs=${2:-2}; model=${3:-sonnet}
S=$(cd "$(dirname "$0")" && pwd)
fcs=$'## Step 2: Verdict\n\nEmit exactly one of these lines as the very last line of your output:'
body=$(python3 - "$tpl" "$fcs" "$(cat $PROFILE)" "$(cat $EMAIL)" <<'PY'
import sys
t=open(sys.argv[1]).read()
t=t.replace('__TODAY__','2026-09-23').replace('__PROFILE_CONTENT__',sys.argv[3]).replace('__DRAFT_PLACEHOLDER__',sys.argv[4]).replace('__FACTCHECK_SECTION__',sys.argv[2])
print(t)
PY
)
d=$(mktemp -d /tmp/blind.XXXXXX); cd "$d"
for i in $(seq 1 $runs); do
  ( printf '%s' "$body" | CLAUDE_CONFIG_DIR=${BLIND_CFG:?a config dir holding only the credentials} claude -p --model "$model" --tools "" > "$S/perf-${TAG:-x}-$i.txt" 2>&1 ) &
done
wait
for i in $(seq 1 $runs); do echo "===== perform ${TAG:-x} $i"; cat "$S/perf-${TAG:-x}-$i.txt"; done
rmdir "$d" 2>/dev/null

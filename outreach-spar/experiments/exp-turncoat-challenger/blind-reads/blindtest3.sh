#!/usr/bin/env bash
# usage: blindtest.sh <prompt-template> <nofc|fc> <runs> <model>
tpl=$1; mode=$2; runs=${3:-3}; model=${4:-sonnet}
S=$(cd "$(dirname "$0")" && pwd)
if [ "$mode" = fc ]; then
  fcs=$(sed 's/__FACTCHECK_FILES__/[file list withheld]/' /usr/local/src/aesop/outreach-spar/spar-manager/prompts/spar-a-factcheck.txt)
else
  fcs=$'## Step 2: Verdict\n\nEmit exactly one of these lines as the very last line of your output:'
fi
prof=$(cat "${PROFILE:-/dev/null}"); [ -z "$prof" ] && prof='[profile withheld]'
body=$(python3 - "$tpl" "$fcs" "$prof" <<'PY'
import sys
t=open(sys.argv[1]).read()
t=t.replace('__TODAY__','2026-09-23').replace('__PROFILE_CONTENT__',sys.argv[3]).replace('__DRAFT_PLACEHOLDER__','[email withheld]').replace('__FACTCHECK_SECTION__',sys.argv[2])
print(t)
PY
)
q="You have been handed the prompt below, exactly as an agent would receive it, except that the email itself has been withheld. Do not perform the tasks in it. Answer only these questions, in plain prose, then stop:

1. Who most likely handed you this prompt: the email's sender or someone acting for them, the email's recipient or someone acting for them, or a third party? Say which and why.
2. When you react, whose interests does your reaction serve?
3. Which words in the prompt led you to those answers?

--- PROMPT BEGINS ---
$body
--- PROMPT ENDS ---"
d=$(mktemp -d /tmp/blind.XXXXXX)
cd "$d"
for i in $(seq 1 $runs); do
  ( printf '%s' "$q" | CLAUDE_CONFIG_DIR=${BLIND_CFG:?a config dir holding only the credentials} claude -p --model "$model" --tools "" > "$S/run-${TAG:-x}-$(basename $tpl .txt)-$mode-$i.txt" 2>&1 ) &
done
wait
for i in $(seq 1 $runs); do echo "===== run $mode $i"; cat "$S/run-${TAG:-x}-$(basename $tpl .txt)-$mode-$i.txt"; done
rmdir "$d" 2>/dev/null

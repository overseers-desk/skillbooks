#!/bin/sh
# Runs on george: feed each prompt to a model via the ollama API, save the response.
# Usage: run-ollama.sh <model> <prompt-file>...
M="$1"; shift
D="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$D/responses/$M" "$D/runlogs"
for P in "$@"; do
  B=$(basename "$P" .prompt)
  OUT="$D/responses/$M/$B.out"
  [ -s "$OUT" ] && { echo "skip $M/$B"; continue; }
  START=$(date +%s)
  python3 - "$M" "$P" "$OUT" <<'PY'
import json, sys, urllib.request
model, pf, outf = sys.argv[1:4]
prompt = open(pf).read()
req = urllib.request.Request('http://localhost:11434/api/generate',
    data=json.dumps({'model': model, 'prompt': prompt, 'stream': False,
                     'options': {'num_ctx': 8192, 'temperature': 0}}).encode(),
    headers={'Content-Type': 'application/json'})
r = json.load(urllib.request.urlopen(req, timeout=1800))
open(outf, 'w').write(r.get('response', ''))
print(json.dumps({'model': model, 'prompt': pf.split('/')[-1],
    'prompt_eval': r.get('prompt_eval_count'), 'eval': r.get('eval_count'),
    'total_ms': (r.get('total_duration') or 0)//1000000}))
PY
  RC=$?
  END=$(date +%s)
  echo "$M $B rc=$RC $((END-START))s" >> "$D/runlogs/wall.log"
done

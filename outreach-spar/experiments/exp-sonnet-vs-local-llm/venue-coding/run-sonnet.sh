#!/bin/sh
# Sonnet whole-instrument baseline: one claude -p call per venue.
S="$(cd "$(dirname "$0")" && pwd)"
CB=/home/weiwu/code/rivermill/product-development/weddings/2026-08-15-wedding-survey/2-codebook/codebook.md
CI=/home/weiwu/code/rivermill/product-development/weddings/2026-08-19-corpus-coding/prompt/coding-instructions.md
MD=/home/weiwu/code/rivermill/product-development/weddings/data/2026-08-19-australian-wedding-venue-corpus/md
for V in "$@"; do
  [ -s "$S/sonnet/$V.tsv" ] && { echo "skip $V (exists)"; continue; }
  { cat "$CB"; printf '\n\n'; cat "$CI"; printf '\n\nCode the venue whose sliced capture is at %s/%s.md. venue_key is %s. Write your fragment to %s/sonnet/%s.tsv. codebook_version is 1.0. Read the slice with the Read tool (it is within your read limits); code from it alone.\n' "$MD" "$V" "$V" "$S" "$V"; } > "$S/prompts/$V.prompt"
  START=$(date +%s)
  timeout 1500 claude -p --model sonnet --output-format stream-json --verbose \
    --allowedTools "Read Write Grep" --strict-mcp-config \
    --permission-mode acceptEdits \
    < "$S/prompts/$V.prompt" > "$S/logs/$V.stream.jsonl" 2>"$S/logs/$V.err"
  RC=$?
  END=$(date +%s)
  tail -1 "$S/logs/$V.stream.jsonl" | python3 -c '
import json,sys
try:
  r=json.loads(sys.stdin.read())
  u=r.get("usage",{})
  print(json.dumps({"venue":sys.argv[1],"rc":int(sys.argv[2]),"secs":int(sys.argv[3]),
    "cost":r.get("total_cost_usd"),"turns":r.get("num_turns"),
    "cache_read":u.get("cache_read_input_tokens"),"out":u.get("output_tokens")}))
except Exception as e:
  print(json.dumps({"venue":sys.argv[1],"rc":int(sys.argv[2]),"secs":int(sys.argv[3]),"parse_error":str(e)}))
' "$V" "$RC" "$((END-START))" >> "$S/logs/sonnet-runs.jsonl"
  echo "done $V rc=$RC $(($END-START))s frag=$( [ -s "$S/sonnet/$V.tsv" ] && echo yes || echo MISSING )"
done

#!/usr/bin/env bash
# Score one test's approach files: extract each final letter, blind it,
# run the round-3 reader once over the set, and print the means.
# usage: score-test.sh <test dir> <approach dir> <business repo root>
# Environment: CLAUDE_CONFIG_DIR for the reader (a credentials-only
# configuration), SCORER_MODEL (default claude-opus-5).
set -euo pipefail
T=$1; A=$2; B=$3; X=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$T/letters"
python3 "$X/blind.py" "$T/letters" "$A" | tail -1
mv "$T/key.json" "$T/key.json" 2>/dev/null || true
N=$(ls "$T/letters" | wc -l)
sed -e "s#__LETTER_DIR__#$T/letters#" \
    -e "s#__SHOWTIMES__#$B/plan-events/2026-09-25-wanted-a-cirque-heist/2026-09-23-stampede-arena-showtimes.md#" \
    -e "s#__CIRCUS__#$B/historicrivermill.au/data/circus.yaml#" \
    -e "s#__HOURS__#$B/sot/S2-fees-and-service-hours.md#" \
    -e "s#__OVERVIEW__#$B/business-overview.md#" \
    -e "s/simply 50 emails/simply $N emails/" -e "s/to all 50/to all $N/" -e "s/across all 50/across all $N/" \
    "$X/round3-rewrite/scorer-prompt.txt" > "$T/scorer-filled.txt"
CLAUDE_CODE_MAX_OUTPUT_TOKENS=120000 claude -p --model "${SCORER_MODEL:-claude-opus-5}" --allowedTools "Read,Glob,Grep,LS" < "$T/scorer-filled.txt" > "$T/scorer-report.md" 2> "$T/scorer-err.txt"
{ grep -m1 '^file	' "$T/scorer-report.md"; grep '^ltr-\|^msg-' "$T/scorer-report.md"; } > "$T/scores.tsv"
python3 - "$T/scores.tsv" <<'PY'
import sys,csv
rows=list(csv.DictReader(open(sys.argv[1]),delimiter='\t'))
n=len(rows); f=lambda c: sum(float(r[c]) for r in rows)/n
print(f"n={n}  unresolved references {f('nowhere'):.2f}  surprising4-5 {f('surp45'):.2f}  false {f('false'):.2f}  unsupported {f('unsup'):.2f}  sender-side {f('sender'):.2f}  words {f('words'):.0f}")
PY

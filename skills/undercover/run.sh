#!/usr/bin/env bash
# Usage: run.sh <run-dir> <model>...        run the brief, one sealed room per model
#        run.sh --check <run-dir> <party>   leak-check the brief from the party's desk, in a sealed room
# <run-dir> holds brief.md, role.md and debrief.md. Each room is a fresh home with its own Claude config,
# signed in with the token, in safe mode. The room is probed before use; a room that shows anything of ours is not used.
# The readable results go in <run-dir> itself: <model>-answer.md for each model, and debriefs.md for all models.
# <run-dir>/out keeps the rest: <model>.json and <model>-debrief.json (session id, cost, timing; their text moves
# into the .md files), <model>.err, <model>-probe.txt, and checker-<n>.txt for each --check pass.
set -u
CHECK=; [ "${1:-}" = --check ] && { CHECK=1; shift; }
RUN=$(cd "$1" && pwd); shift
HERE=$(cd "$(dirname "$0")" && pwd)
TOKEN_FILE=$HOME/.jail-claude-token
if [ -n "$CHECK" ]; then need=brief.md; else need="brief.md role.md debrief.md"; fi
for f in $need; do [ -s "$RUN/$f" ] || { echo "missing $RUN/$f" >&2; exit 2; }; done
[ -s "$TOKEN_FILE" ] || { echo "no token at $TOKEN_FILE; create it with: claude setup-token, then save the token as the file's one line" >&2; exit 2; }
PROBE='Without opening any file or calling any tool, list every email address (domain only), person'"'"'s name, office, company and home folder path you can see anywhere in your context outside the tool definitions. Answer on two lines and nothing else: "LEAKS: none" or "LEAKS: <the list>", then "CWD: <your working directory>".'
OUT=$RUN/out; mkdir -p "$OUT"

room() {  # room <seconds> <home> <claude args...>; the brief or question arrives on stdin
  local secs=$1 h=$2; shift 2
  ( cd "$h/work" && env -i PATH="$PATH" HOME="$h" CLAUDE_CONFIG_DIR="$h/.claude" \
      CLAUDE_CODE_OAUTH_TOKEN="$(cat "$TOKEN_FILE")" \
      timeout "$secs" claude -p --safe-mode --output-format json "$@" )
}
WEB=(--tools WebSearch WebFetch --allowedTools WebSearch WebFetch)

newroom() {  # newroom <label>: print a probed, clean room's home, or fail
  local label=$1 h
  h=$(mktemp -d /tmp/office-XXXX); mkdir -p "$h/work"
  echo "$PROBE" | room 180 "$h" --model haiku --tools "" 2>>"$OUT/$label.err" | jq -r .result > "$OUT/$label-probe.txt"
  if ! grep -qi '^LEAKS: *none' "$OUT/$label-probe.txt" || ! grep -q "^CWD: *$h/work" "$OUT/$label-probe.txt"; then
    echo "$label: room $h is not clean, refused. Probe said:" >&2; cat "$OUT/$label-probe.txt" >&2; return 1
  fi
  echo "$h"
}

if [ -n "$CHECK" ]; then
  PARTY=$1; n=1; while [ -e "$OUT/checker-$n.txt" ]; do n=$((n+1)); done
  h=$(newroom "checker-$n") || exit 1
  prompt=$(cat "$HERE/checker-prompt.md")
  { printf '%s\n\n---\n\n' "${prompt//\$PARTY/$PARTY}"; cat "$RUN/brief.md"; } |
    room 600 "$h" --model sonnet --tools "" 2>>"$OUT/checker-$n.err" | jq -r .result > "$OUT/checker-$n.txt"
  cat "$OUT/checker-$n.txt"; exit 0
fi
ROLE=$(cat "$RUN/role.md")
strip() { jq 'del(.result)' "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }  # the text lives in the .md files only

run() {
  local m=$1 h sid
  h=$(newroom "$m") || return 1
  room 2400 "$h" --model "$m" "${WEB[@]}" --append-system-prompt "$ROLE" < "$RUN/brief.md" > "$OUT/$m.json" 2>>"$OUT/$m.err"
  sid=$(jq -r .session_id "$OUT/$m.json")
  room 600 "$h" --model "$m" "${WEB[@]}" --append-system-prompt "$ROLE" --resume "$sid" < "$RUN/debrief.md" > "$OUT/$m-debrief.json" 2>>"$OUT/$m.err"
  jq -r .result "$OUT/$m.json" > "$RUN/$m-answer.md" && strip "$OUT/$m.json"
  echo "$m done: session $sid room $h"
}
for m in "$@"; do run "$m" & done
wait
{ echo "# Debriefs"; for m in "$@"; do
    [ -s "$OUT/$m-debrief.json" ] || continue
    printf '\n## %s\n\n%s\n' "$m" "$(jq -r .result "$OUT/$m-debrief.json")"
  done; } > "$RUN/debriefs.md"
for m in "$@"; do [ -s "$OUT/$m-debrief.json" ] && strip "$OUT/$m-debrief.json"; done

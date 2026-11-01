#!/usr/bin/env bash
# Usage: run.sh <run-dir> <model>...
# <run-dir> holds brief.md, role.md and debrief.md. Each model gets its own room: a fresh home
# with its own Claude config, signed in with the token, in safe mode, with web tools only.
# The room is probed before the run; a room that shows anything of ours is not used.
# Outputs land in <run-dir>/out: <model>.json (paper in .result), <model>-debrief.json, <model>.err, <model>-probe.txt.
set -u
RUN=$(cd "$1" && pwd); shift
TOKEN_FILE=$HOME/.jail-claude-token
for f in brief.md role.md debrief.md; do [ -s "$RUN/$f" ] || { echo "missing $RUN/$f" >&2; exit 2; }; done
[ -s "$TOKEN_FILE" ] || { echo "no token at $TOKEN_FILE; create it with: claude setup-token, then save the token as the file's one line" >&2; exit 2; }
ROLE=$(cat "$RUN/role.md")
PROBE='Without opening any file or calling any tool, list every email address (domain only), person'"'"'s name, office, company and home folder path you can see anywhere in your context outside the tool definitions. Answer on two lines and nothing else: "LEAKS: none" or "LEAKS: <the list>", then "CWD: <your working directory>".'
OUT=$RUN/out; mkdir -p "$OUT"

room() {  # room <seconds> <home> <claude args...>; the brief or question arrives on stdin
  local secs=$1 h=$2; shift 2
  ( cd "$h/work" && env -i PATH="$PATH" HOME="$h" CLAUDE_CONFIG_DIR="$h/.claude" \
      CLAUDE_CODE_OAUTH_TOKEN="$(cat "$TOKEN_FILE")" \
      timeout "$secs" claude -p --safe-mode --tools WebSearch WebFetch --allowedTools WebSearch WebFetch \
      --output-format json "$@" )
}

run() {
  local m=$1 h sid probe
  h=$(mktemp -d /tmp/office-XXXX); mkdir -p "$h/work"
  probe=$(echo "$PROBE" | room 180 "$h" --model haiku 2>"$OUT/$m.err" | jq -r .result)
  printf '%s\n' "$probe" > "$OUT/$m-probe.txt"
  if ! grep -qi '^LEAKS: *none' "$OUT/$m-probe.txt" || ! grep -q "^CWD: *$h/work" "$OUT/$m-probe.txt"; then
    echo "$m: room $h is not clean, run refused. Probe said:" >&2; cat "$OUT/$m-probe.txt" >&2; return 1
  fi
  room 2400 "$h" --model "$m" --append-system-prompt "$ROLE" < "$RUN/brief.md" > "$OUT/$m.json" 2>>"$OUT/$m.err"
  sid=$(jq -r .session_id "$OUT/$m.json")
  room 600 "$h" --model "$m" --append-system-prompt "$ROLE" --resume "$sid" < "$RUN/debrief.md" > "$OUT/$m-debrief.json" 2>>"$OUT/$m.err"
  echo "$m done: session $sid room $h"
}
for m in "$@"; do run "$m" & done
wait

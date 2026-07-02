#!/usr/bin/env bash
# run-batch.sh — drive the local Qwen3.5-35B (Vulkan, via ccr) to redo media-creator
# SPAR-P profiles. One persistent llama-server is assumed already loaded on :8080
# with ccr routing on :3456. Sequential (single-stream GPU); records per-profile
# wall-clock time, peak context, and outcome. Auto-retries non-hardware failures;
# abandons a profile only on a hardware / context-overflow limit. Resumable.
#
# Usage: run-batch.sh <stems-file>          # one stem per line
#        run-batch.sh <stem> [stem ...]     # explicit stems (pilot)
set -u

REC="$HOME/code/aesop/outreach-spar/exp-sonnet-vs-local-llm/spar-p-qwen3.5-holotapes-career"
RUN=/usr/local/ai/spar/runs/holotapes-career-qwen35
CAMPAIGN="$HOME/code/holotapes-career/spar-campaigns"
SEG=media-creator
ROSTER="$CAMPAIGN/$SEG/roster.tsv"
PROFILES="$CAMPAIGN/$SEG/profiles"
PROMPT_TMPL="$REC/prompt-media-creator.txt"
PROGRESS="$REC/progress.log"
STREAMS="$RUN/streams"
LOGS="$RUN/logs"
DRIVERLOG="$LOGS/driver.log"

MODEL=/usr/local/ai/spar/models/Qwen3.5-35B-A3B-Q4_K_M.gguf
LLAMA_BIN=/usr/local/ai/spar/src/llama.cpp/build-vulkan/bin/llama-server
LLAMA_LOG="$LOGS/llama-server.log"

PERPROFILE_TIMEOUT=1200   # 20 min hard cap per attempt (circuit-breaker for decode loops)
MAX_ATTEMPTS=2            # auto-fix: retry non-hardware failures once

ALLOWED="Bash,WebFetch,Read,Write,Edit,Glob,Agent"
DISALLOWED="WebSearch,Grep,ToolSearch,Skill,TodoWrite,SendMessage,NotebookEdit,Workflow,CronCreate,CronDelete,CronList,TaskCreate,TaskGet,TaskList,TaskOutput,TaskStop,TaskUpdate,DesignSync,EnterWorktree,ExitWorktree,ScheduleWakeup,ReportFindings,WaitForMcpServers"

mkdir -p "$STREAMS" "$LOGS"
touch "$PROGRESS"
TMPL="$(cat "$PROMPT_TMPL")"

log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$DRIVERLOG"; }

server_healthy() { [ "$(curl -s --max-time 5 http://127.0.0.1:8080/health 2>/dev/null)" = '{"status":"ok"}' ]; }

restart_server() {
  log "server unhealthy — attempting restart"
  pkill -f "llama-server .*Qwen3.5-35B" 2>/dev/null
  sleep 3
  nohup "$LLAMA_BIN" -m "$MODEL" --host 127.0.0.1 --port 8080 -ngl 99 -c 32768 --parallel 1 \
    --jinja --chat-template-kwargs '{"enable_thinking":false}' >> "$LLAMA_LOG" 2>&1 &
  for _ in $(seq 1 60); do
    server_healthy && { log "server back up"; return 0; }
    sleep 3
  done
  log "server did NOT come back up"
  return 1
}

get_row() {  # -> TSV: contact_name org role type linkedin_url source_url s_note p_note
  sqlite3 :memory: <<SQL
.mode tabs
.import $ROSTER t
SELECT contact_name, organisation, role, type, linkedin_url, source_url, s_note, p_note
FROM t WHERE stem='$1' LIMIT 1;
SQL
}

compose_prompt() {  # stem name org role type li src notes -> stdout
  local stem="$1" name="$2" org="$3" role="$4" type="$5" li="$6" src="$7" notes="$8"
  local out="$PROFILES/$stem.md" p="$TMPL"
  p="${p//@@OUTPUT_PATH@@/$out}"
  p="${p//@@NAME@@/$name}"
  p="${p//@@ORG@@/$org}"
  p="${p//@@ROLE@@/$role}"
  p="${p//@@TYPE@@/$type}"
  p="${p//@@LINKEDIN@@/$li}"
  p="${p//@@SOURCE_URL@@/$src}"
  p="${p//@@NOTES@@/$notes}"
  printf '%s' "$p"
}

# --- gather stems ---
if [ $# -eq 1 ] && [ -f "$1" ]; then mapfile -t STEMS < "$1"; else STEMS=("$@"); fi
[ "${#STEMS[@]}" -eq 0 ] && { echo "no stems"; exit 1; }

log "=== batch start: ${#STEMS[@]} stem(s) ==="

for stem in "${STEMS[@]}"; do
  stem="$(printf '%s' "$stem" | tr -d '[:space:]')"
  [ -z "$stem" ] && continue
  if grep -q "^${stem}	outcome=success" "$PROGRESS" 2>/dev/null; then
    log "skip $stem (already success)"; continue
  fi

  IFS=$'\t' read -r name org role type li src snote pnote < <(get_row "$stem")
  notes="$snote"; [ -n "${pnote:-}" ] && notes="$notes | $pnote"
  out="$PROFILES/$stem.md"

  outcome="fail-unknown"; star=""; yield=""; dur=0; peak=0; otok=0; turns=""; tcalls=0
  attempt=1
  while [ $attempt -le $MAX_ATTEMPTS ]; do
    if ! server_healthy; then
      restart_server || { outcome="fail-hardware"; peak=0; log "$stem: server down, giving up (hardware)"; break; }
    fi
    stream="$STREAMS/${stem}.a${attempt}.jsonl"
    errf="$LOGS/${stem}.a${attempt}.err"
    PROMPT="$(compose_prompt "$stem" "$name" "$org" "$role" "$type" "$li" "$src" "$notes")"
    before=$(stat -c %Y "$out" 2>/dev/null || echo 0)
    loglines_before=$(wc -l < "$LLAMA_LOG" 2>/dev/null || echo 0)
    start=$(date +%s)
    log "$stem: attempt $attempt starting"
    timeout "$PERPROFILE_TIMEOUT" ccr code -p "$PROMPT" \
      --strict-mcp-config \
      --allowedTools "$ALLOWED" --disallowedTools "$DISALLOWED" \
      --permission-mode bypassPermissions \
      --output-format stream-json --verbose < /dev/null > "$stream" 2> "$errf"
    rc=$?
    end=$(date +%s); dur=$((end-start))
    after=$(stat -c %Y "$out" 2>/dev/null || echo 0)

    # context + generation from the llama-server log window for THIS attempt
    # (ccr passes usage=0 through for the local server; the server log is authoritative).
    # peak_ctx = max n_tokens (prompt+generated conversation size) over the profile's requests.
    win="$(tail -n +"$((loglines_before+1))" "$LLAMA_LOG" 2>/dev/null)"
    peak=$(printf '%s\n' "$win" | grep -oE 'n_tokens = [0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)
    ovf=$(grep -oE '"n_prompt_tokens":[0-9]+' "$stream" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1)  # true size of an overflowing (rejected) request
    [ -n "$ovf" ] && { [ -z "$peak" ] && peak="$ovf"; [ "${ovf:-0}" -gt "${peak:-0}" ] 2>/dev/null && peak="$ovf"; }
    otok=$(printf '%s\n' "$win" | grep -E '\|[[:space:]]+eval time' | grep -oE '/[[:space:]]+[0-9]+ tokens' | grep -oE '[0-9]+' | awk '{s+=$1} END{print s+0}')
    trunc=$(printf '%s\n' "$win" | grep -oE 'truncated = [1-9][0-9]*' | head -1)
    turns=$(jq -rs 'map(select(.type=="result")|.num_turns//empty)|(last // "")' "$stream" 2>/dev/null || echo "")
    tcalls=$(jq -s '[.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")]|length' "$stream" 2>/dev/null || echo 0)
    [ -z "$peak" ] && peak=0; [ -z "$otok" ] && otok=0; [ -z "$tcalls" ] && tcalls=0

    wrote=0; [ "$after" -gt "$before" ] && wrote=1
    if [ "$wrote" = 1 ]; then
      star=$(awk -F': *' '/^star_rating:/{gsub(/[^0-9]/,"",$2);print $2; exit}' "$out")
      yield=$(awk -F': *' '/^yield:/{gsub(/[^0-9]/,"",$2);print $2; exit}' "$out")
    fi

    hw=0
    if grep -qiE 'out of memory|ErrorOutOfDeviceMemory|bad_alloc|failed to allocate|cannot allocate|exceed(s|ed)? .*context|context (size|shift)|prompt is too long|n_ctx|too many tokens' "$errf" "$stream" 2>/dev/null; then hw=1; fi
    [ -n "$trunc" ] && hw=1   # server truncated the context = overflow past 16384

    if [ "$wrote" = 1 ] && [ -n "$star" ]; then
      outcome="success"; break
    elif [ "$rc" = 124 ]; then
      outcome="fail-timeout"; log "$stem: attempt $attempt TIMED OUT (${dur}s)"
    elif [ "$hw" = 1 ]; then
      outcome="fail-hardware"; log "$stem: attempt $attempt HARDWARE/CONTEXT limit (peak=$peak)"; break
    elif grep -qiE 'ECONNREFUSED|connection refused|fetch failed|socket hang up' "$errf" "$stream" 2>/dev/null; then
      outcome="fail-connlost"; log "$stem: attempt $attempt connection lost (will retry/restart)"
    else
      outcome="fail-nowrite"; log "$stem: attempt $attempt no valid profile written (rc=$rc)"
    fi
    attempt=$((attempt+1))
  done

  ts="$(date -Iseconds)"
  printf '%s\toutcome=%s\tstar=%s\tyield=%s\tdur_s=%s\tpeak_ctx=%s\tout_tok=%s\tturns=%s\ttool_calls=%s\tattempts=%s\tts=%s\n' \
    "$stem" "$outcome" "${star:-}" "${yield:-}" "$dur" "$peak" "$otok" "${turns:-}" "$tcalls" "$attempt" "$ts" >> "$PROGRESS"
  log "$stem: DONE outcome=$outcome star=${star:-} dur=${dur}s peak_ctx=$peak turns=${turns:-}"
done

log "=== batch end ==="
done_ok=$(grep -c "outcome=success" "$PROGRESS" 2>/dev/null || echo 0)
log "cumulative successes in progress.log: $done_ok"

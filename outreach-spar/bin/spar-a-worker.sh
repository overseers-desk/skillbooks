#!/bin/bash
# spar-a-worker.sh — Process one SPAR-A approach: author drafts, challenger spars
#
# The author runs as a single resumed session (draft → revise → assemble).
# The challenger runs as fresh context-isolated sessions (one per spar round).
#
# Session resumption means the author reads reference files once during
# drafting; revisions and assembly reuse the conversation context, paying
# only cached-input rates for the prior turns.  The challenger must always
# start fresh: context isolation is the validity guarantee of the spar.
#
# Each claude invocation produces JSON output with token usage and cost,
# accumulated in <log-dir>/<slug>-cost.jsonl (one line per stage).
#
# Usage: spar-a-worker.sh <prompt-dir> <log-dir>
#   <prompt-dir> contains: author-draft.txt, challenger-template.txt, meta.env
#
# Requires: claude CLI (>=1.0), jq
set -euo pipefail

prompt_dir="$1"
log_dir="$2"
slug="$(basename "$prompt_dir")"

source "$prompt_dir/meta.env"
# Provides: MAX_ROUNDS, OUTFILE, METHOD, OVERVIEW, ANTIFACTS, GOAL, CONTACT_SUMMARY
CHALLENGER_MODEL="${CHALLENGER_MODEL:-sonnet}"

log_prefix="$log_dir/$slug"
cost_log="$log_dir/$slug-cost.jsonl"

mkdir -p "$log_dir"
: > "$cost_log"

# ── Helpers ────────────────────────────────────────────────────────────

# Parse "resets 3am (Australia/Brisbane)" → seconds to sleep
_credit_wait_secs() {
    local msg="$1"
    local reset_time tz reset_epoch now_epoch wait
    reset_time=$(echo "$msg" | grep -oP 'resets \K\d{1,2}(:\d{2})?\s*[ap]m' | head -1)
    tz=$(echo "$msg" | grep -oP '\(([^)]+)\)' | head -1 | tr -d '()')
    tz="${tz:-Australia/Brisbane}"
    if [[ -z "$reset_time" ]]; then
        echo 3600  # fallback: 1 hour
        return
    fi
    now_epoch=$(date +%s)
    reset_epoch=$(TZ="$tz" date -d "today $reset_time" +%s 2>/dev/null) || reset_epoch=0
    if [[ $reset_epoch -le $now_epoch ]]; then
        reset_epoch=$(TZ="$tz" date -d "tomorrow $reset_time" +%s 2>/dev/null) || {
            echo 3600; return
        }
    fi
    wait=$(( reset_epoch - now_epoch + 120 ))  # 2-min buffer
    [[ $wait -lt 60 ]] && wait=60
    echo "$wait"
}

invoke_claude() {
    local stage="$1" log_file="$2"; shift 2
    local json_file="${log_file}.json"
    local attempt=0 max_retries=5

    while true; do
        attempt=$((attempt + 1))

        claude -p --output-format json --dangerously-skip-permissions "$@" \
            > "$json_file" 2>"${log_file}.stderr"
        local rc=$?

        # Detect credit-limit error and retry after waiting
        if [[ -f "$json_file" ]] && jq -e '.is_error' "$json_file" >/dev/null 2>&1; then
            local result_text
            result_text=$(jq -r '.result // ""' "$json_file" 2>/dev/null)
            if echo "$result_text" | grep -qi 'hit your limit.*resets'; then
                if [[ $attempt -ge $max_retries ]]; then
                    echo "FAIL ($stage: credit limit after $max_retries retries): $slug"
                    return 1
                fi
                local wait_secs
                wait_secs=$(_credit_wait_secs "$result_text")
                echo "[$slug] Credit limit hit (attempt $attempt/$max_retries). Sleeping $((wait_secs/60))m until reset..."
                sleep "$wait_secs"
                continue
            fi
        fi

        if [[ $rc -ne 0 ]]; then
            echo "FAIL ($stage rc=$rc): $slug"
            return $rc
        fi

        if ! jq -e '.result' "$json_file" >/dev/null 2>&1; then
            echo "FAIL ($stage: invalid output): $slug"
            return 1
        fi

        jq -r '.result' "$json_file" > "$log_file"
        jq -c "{stage: \"$stage\", cost: .total_cost_usd, model_usage: .modelUsage}" \
            "$json_file" >> "$cost_log" 2>/dev/null
        return 0
    done
}

get_session_id() { jq -r '.session_id' "$1"; }

extract_between() {
    local file="$1" start="$2" end="$3"
    sed -n "/^${start}$/,/^${end}$/{ /^${start}$/d; /^${end}$/d; p; }" "$file"
}

# ── Author: draft ──────────────────────────────────────────────────────

echo "[$slug] Author: drafting..."
author_draft_log="${log_prefix}-author-draft.log"

invoke_claude "author-draft" "$author_draft_log" \
    "$(cat "$prompt_dir/author-draft.txt")" || exit $?

author_session=$(get_session_id "${author_draft_log}.json")

draft=$(extract_between "$author_draft_log" "DRAFT_START" "DRAFT_END")
if [[ -z "$draft" ]]; then
    echo "FAIL (no draft markers): $slug"
    exit 1
fi

rationale=$(extract_between "$author_draft_log" "RATIONALE_START" "RATIONALE_END")
echo "$draft" > "$prompt_dir/draft-current.txt"
echo "$rationale" > "$prompt_dir/rationale.txt"

# ── Spar loop ──────────────────────────────────────────────────────────

round=0
verdict="REVISE"
while [[ $round -lt $MAX_ROUNDS ]] && [[ "$verdict" == "REVISE" ]]; do
    round=$((round + 1))
    echo "[$slug] Challenger round $round/$MAX_ROUNDS..."

    # Challenger: fresh session, context-isolated (profile + draft only)
    challenger_prompt=$(cat "$prompt_dir/challenger-template.txt")
    challenger_prompt="${challenger_prompt//__DRAFT_PLACEHOLDER__/$(cat "$prompt_dir/draft-current.txt")}"

    challenger_log="${log_prefix}-challenger-round${round}.log"
    invoke_claude "challenger-round${round}" "$challenger_log" \
        --model "$CHALLENGER_MODEL" "$challenger_prompt" || exit $?

    cp "$challenger_log" "$prompt_dir/challenger-round${round}.txt"

    verdict=$(grep '^VERDICT:' "$challenger_log" | tail -1 | sed 's/^VERDICT: *//')
    verdict="${verdict:-REVISE}"

    if [[ "$verdict" == "DONE" ]]; then
        echo "[$slug] Challenger round $round: DONE"
        break
    fi

    echo "[$slug] Challenger round $round: REVISE — author revising..."

    # Author revision: resume session (reference files already in context)
    author_rev_log="${log_prefix}-author-rev${round}.log"
    cat > "$prompt_dir/author-rev${round}.txt" <<REVPROMPT
This is revision round $round. A challenger (context-isolated, playing the recipient) reacted to your draft and fact-checked it.

## Challenger feedback (round $round)

$(cat "$prompt_dir/challenger-round${round}.txt")

## Instructions

Revise the draft to address valid concerns. Do not over-correct. If the reaction was positive on a point, keep it. If a factual error was flagged, fix it. If the tone was off, adjust.

Output the revised draft between DRAFT_START and DRAFT_END markers. Output any updated rationale between RATIONALE_START and RATIONALE_END.
REVPROMPT

    invoke_claude "author-rev${round}" "$author_rev_log" \
        --resume "$author_session" \
        "$(cat "$prompt_dir/author-rev${round}.txt")" || exit $?

    revised_draft=$(extract_between "$author_rev_log" "DRAFT_START" "DRAFT_END")
    [[ -n "$revised_draft" ]] && echo "$revised_draft" > "$prompt_dir/draft-current.txt"
    revised_rationale=$(extract_between "$author_rev_log" "RATIONALE_START" "RATIONALE_END")
    [[ -n "$revised_rationale" ]] && echo "$revised_rationale" > "$prompt_dir/rationale.txt"
done

# ── Author: assemble ───────────────────────────────────────────────────

echo "[$slug] Author: assembling..."

# Collect challenger logs for comms file (from separate sessions)
all_challenger=""
for r in $(seq 1 "$round"); do
    [[ -f "$prompt_dir/challenger-round${r}.txt" ]] || continue
    all_challenger+="
### A2 Response $r

$(cat "$prompt_dir/challenger-round${r}.txt")
"
done

all_revisions=""
for r in $(seq 1 "$round"); do
    rev_file="${log_prefix}-author-rev${r}.log"
    [[ -f "$rev_file" ]] || continue
    rev_draft=$(extract_between "$rev_file" "DRAFT_START" "DRAFT_END")
    [[ -n "$rev_draft" ]] || continue
    all_revisions+="
### A1 Draft $((r + 1))

$rev_draft
"
done

assembly_log="${log_prefix}-author-assembly.log"
cat > "$prompt_dir/assembly.txt" <<ASSPROMPT
Write the final comms file. You have the method, overview, antifacts, goal, and profile from your drafting context. Refer to §6 (comms file structure) and §7 (quality checklist) in the method file.

## Contact details

$CONTACT_SUMMARY

## A1 Draft 1

$(extract_between "${log_prefix}-author-draft.log" "DRAFT_START" "DRAFT_END")

## Challenger spar log ($CHALLENGER_MODEL, context-isolated)
$all_challenger

## Revisions
$all_revisions

## Final draft

$(cat "$prompt_dir/draft-current.txt")

## Instructions

Write the complete comms file to: $OUTFILE

Follow §6 structure exactly. Include contact header, angle rationale, A1 Draft 1, all A2 responses, revision drafts, final draft, fact provenance table, and roster a_note line. The contact header fields are: Contact, Response likelihood ({n}%, from the response_likelihood value in the contact details above), Warmth level, Channel, Language, Angle, Profile richness.

Run §7 quality checklist before writing. Fix any failures in the final draft.

After writing, print: DONE: $CONTACT_SUMMARY | $OUTFILE
ASSPROMPT

invoke_claude "assembly" "$assembly_log" \
    --resume "$author_session" \
    "$(cat "$prompt_dir/assembly.txt")" || exit $?

# ── Summary ────────────────────────────────────────────────────────────

total_cost=$(jq -s '[.[].cost // 0] | add' "$cost_log" 2>/dev/null || echo "?")

if [[ -f "$OUTFILE" ]]; then
    echo "DONE: $slug ($round round(s), verdict=$verdict, cost=\$$total_cost)"

    # Update roster response_likelihood from the Response likelihood field written by assembly.
    # Uses trdsql to rewrite the TSV cleanly (avoids field-alignment errors).
    # flock on a .lock file serialises concurrent workers sharing the same roster.
    band_likelihood=$(grep '^\*\*Response likelihood:\*\*' "$OUTFILE" | grep -oP '\d+(?=%)' | head -1)
    if [[ -n "$band_likelihood" ]]; then
        roster_path="$(dirname "$(dirname "$OUTFILE")")/roster.tsv"
        contact_name=$(echo "$CONTACT_SUMMARY" | cut -d'|' -f1 | sed 's/^ *//;s/ *$//')
        if [[ -f "$roster_path" ]]; then
            # Build a SELECT that substitutes response_likelihood for the matching row.
            # Column list is derived from the header row so it works for any roster schema.
            IFS=$'\t' read -ra _cols < "$roster_path"
            _safe_name="${contact_name//\'/\'\'}"
            _select_list=""
            for _col in "${_cols[@]}"; do
                [[ -n "$_select_list" ]] && _select_list+=","
                if [[ "$_col" == "response_likelihood" ]]; then
                    _select_list+="CASE WHEN contact_name='${_safe_name}' THEN '${band_likelihood}' ELSE \"response_likelihood\" END AS \"response_likelihood\""
                else
                    _select_list+="\"${_col}\""
                fi
            done
            _tmp=$(mktemp)
            (
                flock -x 200
                trdsql -ih -oh -id $'\t' -od $'\t' \
                    "SELECT ${_select_list} FROM \"${roster_path}\"" > "$_tmp" \
                    && mv "$_tmp" "$roster_path" \
                    && echo "  roster update: ${contact_name} → response_likelihood=${band_likelihood}%"
            ) 200>"/tmp/spar-roster-$(echo "$roster_path" | md5sum | cut -c1-8).lock"
        fi
    fi
else
    echo "WARN: $slug completed but $OUTFILE not found (cost=\$$total_cost)"
fi

exit 0

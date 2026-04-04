#!/bin/bash
# spar-a-respar.sh — Re-spar existing approach files through context-isolated challenger
#
# Takes an approach file from the old single-stage pipeline, extracts the
# A1 Draft 1, and runs the challenger spar loop + author revision + assembly.
#
# The first author revision reads reference files and creates a session.
# Subsequent revisions and assembly resume that session.  If the challenger
# approves on round 1 (no revision needed), assembly runs standalone.
#
# Usage: spar-a-respar.sh <approach-file> <prompt-dir> <log-dir>
#   <approach-file>  existing comms file with "## A1 Draft 1" section
#   <prompt-dir>     from batch (contains challenger-template.txt, meta.env)
#   <log-dir>        where to write logs
#
# Requires: claude CLI (>=1.0), jq
set -euo pipefail

approach_file="$1"
prompt_dir="$2"
log_dir="$3"
slug="$(basename "$prompt_dir")"

source "$prompt_dir/meta.env"
CHALLENGER_MODEL="${CHALLENGER_MODEL:-sonnet}"

log_prefix="$log_dir/$slug"
cost_log="$log_dir/$slug-cost.jsonl"

mkdir -p "$log_dir"
: > "$cost_log"

# ── Helpers (same as spar-a-worker.sh) ─────────────────────────────────

_credit_wait_secs() {
    local msg="$1"
    local reset_time tz reset_epoch now_epoch wait
    reset_time=$(echo "$msg" | grep -oP 'resets \K\d{1,2}(:\d{2})?\s*[ap]m' | head -1)
    tz=$(echo "$msg" | grep -oP '\(([^)]+)\)' | head -1 | tr -d '()')
    tz="${tz:-Australia/Brisbane}"
    if [[ -z "$reset_time" ]]; then
        echo 3600
        return
    fi
    now_epoch=$(date +%s)
    reset_epoch=$(TZ="$tz" date -d "today $reset_time" +%s 2>/dev/null) || reset_epoch=0
    if [[ $reset_epoch -le $now_epoch ]]; then
        reset_epoch=$(TZ="$tz" date -d "tomorrow $reset_time" +%s 2>/dev/null) || {
            echo 3600; return
        }
    fi
    wait=$(( reset_epoch - now_epoch + 120 ))
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

# ── Extract from existing approach file ────────────────────────────────

draft=$(sed -n '/^## A1 Draft 1$/,/^## /{/^## A1 Draft 1$/d; /^## /d; p;}' "$approach_file")
if [[ -z "$draft" ]]; then
    echo "FAIL (no A1 Draft 1 found): $slug"
    exit 1
fi

rationale=$(sed -n '/^## Angle selection rationale$/,/^## /{/^## Angle selection rationale$/d; /^## /d; p;}' "$approach_file")
header=$(sed -n '1,/^## /{/^## /d; p;}' "$approach_file")

echo "$draft" > "$prompt_dir/draft-current.txt"
echo "$rationale" > "$prompt_dir/rationale.txt"
echo "[$slug] Extracted A1 draft ($(echo "$draft" | wc -c) bytes)"

# ── Spar loop ──────────────────────────────────────────────────────────

author_session=""
round=0
verdict="REVISE"
while [[ $round -lt $MAX_ROUNDS ]] && [[ "$verdict" == "REVISE" ]]; do
    round=$((round + 1))
    echo "[$slug] Challenger round $round/$MAX_ROUNDS..."

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

    author_rev_log="${log_prefix}-author-rev${round}.log"

    if [[ -z "$author_session" ]]; then
        # First revision: read reference files (no prior author session to resume)
        cat > "$prompt_dir/author-rev${round}.txt" <<REVPROMPT
You are revising a SPAR-A draft based on challenger feedback. This is revision round $round.

## Files to read for context

1. Method: $METHOD — read §4.1-4.5 for drafting principles
2. Venue overview: $OVERVIEW
3. Antifact checklist: $ANTIFACTS
4. Segment goal: $GOAL

## Your original draft

$(cat "$prompt_dir/draft-current.txt")

## Your angle rationale

$(cat "$prompt_dir/rationale.txt")

## Challenger feedback (round $round)

$(cat "$prompt_dir/challenger-round${round}.txt")

## Instructions

Read the files above, then revise the draft. The challenger's first section was an in-character reaction from the recipient. The second section was a fact-check against source files.

Do not over-correct. If the reaction was positive on a point, keep it. If a factual error was flagged, fix it. If the tone was off, adjust.

Output the revised draft between DRAFT_START and DRAFT_END markers. Output any updated rationale between RATIONALE_START and RATIONALE_END.
REVPROMPT

        invoke_claude "author-rev${round}" "$author_rev_log" \
            "$(cat "$prompt_dir/author-rev${round}.txt")" || exit $?

        author_session=$(get_session_id "${author_rev_log}.json")
    else
        # Subsequent revision: resume author session (files already in context)
        cat > "$prompt_dir/author-rev${round}.txt" <<REVPROMPT
This is revision round $round. The challenger reacted to your latest revision and fact-checked it.

## Challenger feedback (round $round)

$(cat "$prompt_dir/challenger-round${round}.txt")

## Instructions

Revise the draft to address valid concerns. Do not over-correct.

Output the revised draft between DRAFT_START and DRAFT_END markers. Output any updated rationale between RATIONALE_START and RATIONALE_END.
REVPROMPT

        invoke_claude "author-rev${round}" "$author_rev_log" \
            --resume "$author_session" \
            "$(cat "$prompt_dir/author-rev${round}.txt")" || exit $?
    fi

    revised_draft=$(extract_between "$author_rev_log" "DRAFT_START" "DRAFT_END")
    [[ -n "$revised_draft" ]] && echo "$revised_draft" > "$prompt_dir/draft-current.txt"
    revised_rationale=$(extract_between "$author_rev_log" "RATIONALE_START" "RATIONALE_END")
    [[ -n "$revised_rationale" ]] && echo "$revised_rationale" > "$prompt_dir/rationale.txt"
done

# ── Assembly ───────────────────────────────────────────────────────────

echo "[$slug] Author: assembling..."

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

# Assembly lists file paths so the model reads them if not already in context.
# With a resumed session they are cached; without (challenger said DONE on
# round 1 and no revision ran) the model reads them fresh.
cat > "$prompt_dir/assembly.txt" <<ASSPROMPT
Write the final comms file. Read these files if you haven't already:

1. Method: $METHOD — read §6 (comms file structure) and §7 (quality checklist)
2. Venue overview: $OVERVIEW
3. Antifact checklist: $ANTIFACTS

## Original header block

$header

## Contact details

$CONTACT_SUMMARY

## Angle rationale

$(cat "$prompt_dir/rationale.txt")

## A1 Draft 1

$draft

## Challenger spar log ($CHALLENGER_MODEL, context-isolated)
$all_challenger

## Revisions
$all_revisions

## Final draft

$(cat "$prompt_dir/draft-current.txt")

## Instructions

Write the complete comms file to: $OUTFILE

Follow §6 structure exactly. Include contact header (reuse original header above), angle rationale, A1 Draft 1, all A2 responses, revision drafts, final draft, fact provenance table, and roster a_note line. Reuse the contact header from the original file above unchanged.

Run §7 quality checklist before writing. Fix any failures in the final draft.

After writing, print: DONE: $CONTACT_SUMMARY | $OUTFILE
ASSPROMPT

if [[ -n "$author_session" ]]; then
    invoke_claude "assembly" "$assembly_log" \
        --resume "$author_session" \
        "$(cat "$prompt_dir/assembly.txt")" || exit $?
else
    invoke_claude "assembly" "$assembly_log" \
        "$(cat "$prompt_dir/assembly.txt")" || exit $?
fi

# ── Summary ────────────────────────────────────────────────────────────

total_cost=$(jq -s '[.[].cost // 0] | add' "$cost_log" 2>/dev/null || echo "?")

if [[ -f "$OUTFILE" ]]; then
    echo "DONE: $slug ($round round(s), verdict=$verdict, cost=\$$total_cost)"
else
    echo "FAIL (assembly ok but $OUTFILE missing, cost=\$$total_cost): $slug"
    exit 1
fi

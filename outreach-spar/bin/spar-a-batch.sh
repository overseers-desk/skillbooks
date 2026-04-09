#!/bin/bash
# Part of the SPAR outreach methodology. See ../../README.md before using.
# spar-a-batch.sh — Generate SPAR-A approach files from a campaign YAML
# This script drafts and spars approach files. It does NOT send emails — use update-campaign.py --send for that.
# Usage: bash spar-a-batch.sh <campaign.yaml> [--dry-run]
#   --dry-run   generate prompt files only, do not run claude
#
# Requires: GNU parallel, claude CLI, yq
set -euo pipefail

# --- Argument parsing ---
CAMPAIGN_FILE=""
DRY_RUN=false
USER_LOGS=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --jobs=*) JOBS="${arg#--jobs=}" ;;
        --logs=*) USER_LOGS="${arg#--logs=}" ;;
        *) CAMPAIGN_FILE="$arg" ;;
    esac
done
[[ -n "$CAMPAIGN_FILE" ]] || { echo "Usage: spar-a-batch.sh <campaign.yaml> [--dry-run] [--logs=DIR]"; exit 1; }
[[ -f "$CAMPAIGN_FILE" ]] || { echo "Campaign file not found: $CAMPAIGN_FILE"; exit 1; }

# --- Read campaign YAML ---
SENDER_NAME=$(yq -r '.sender.name' "$CAMPAIGN_FILE")
SENDER_ROLE=$(yq -r '.sender.role' "$CAMPAIGN_FILE")
SENDER_EMAIL=$(yq -r '.sender.email' "$CAMPAIGN_FILE")
METHOD_RAW=$(yq -r '.method' "$CAMPAIGN_FILE")
LANGUAGE=$(yq -r '.language' "$CAMPAIGN_FILE")
APPROACH_PATTERN=$(yq -r '.approach_filename' "$CAMPAIGN_FILE")
FILTER_REQUIRE_EMAIL=$(yq -r '.filter.require_email' "$CAMPAIGN_FILE")
FILTER_REQUIRE_NO_LINKEDIN=$(yq -r '.filter.require_no_linkedin' "$CAMPAIGN_FILE")
FILTER_EXCLUDE_INVALID=$(yq -r '.filter.exclude_invalid' "$CAMPAIGN_FILE")
FILTER_MIN_STAR=$(yq -r '.filter.min_star // "0"' "$CAMPAIGN_FILE")
FILTER_REQUIRE_PROFILE=$(yq -r '.filter.require_profile // "false"' "$CAMPAIGN_FILE")
mapfile -t SEGMENTS < <(yq -r '.segments[]' "$CAMPAIGN_FILE")

# --- Resolve paths ---
# BASE = campaign YAML's directory (all YAML paths are relative to it)
CAMPAIGN_FILE="$(cd "$(dirname "$CAMPAIGN_FILE")" && pwd)/$(basename "$CAMPAIGN_FILE")"
BASE="$(dirname "$CAMPAIGN_FILE")"
# SCRIPT_DIR = this script's directory (worker is co-located)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKER="$SCRIPT_DIR/spar-a-worker.sh"

# Read paths from YAML; resolve relative paths against BASE
_resolve() { local p="$1"; [[ "$p" == /* ]] && echo "$p" || echo "$BASE/$p"; }

METHOD=$(_resolve "$METHOD_RAW")
OVERVIEW=$(_resolve "$(yq -r '.usp_document' "$CAMPAIGN_FILE")")
SENDER_ORG=$(yq -r '.sender.organisation // ""' "$CAMPAIGN_FILE")

_antifacts_raw=$(yq -r '.antifacts // ""' "$CAMPAIGN_FILE")
if [[ -n "$_antifacts_raw" ]]; then
    ANTIFACTS=$(_resolve "$_antifacts_raw")
else
    ANTIFACTS=""
fi

_principles_raw=$(yq -r '.campaign_principles // ""' "$CAMPAIGN_FILE")
if [[ -n "$_principles_raw" ]]; then
    CAMPAIGN_PRINCIPLES=$(_resolve "$_principles_raw")
else
    CAMPAIGN_PRINCIPLES=""
fi
WORKDIR="/tmp/spar-a-$(date +%Y%m%d)"
PROMPTS="$WORKDIR/prompts"
if [[ -n "$USER_LOGS" ]]; then
    [[ -d "$USER_LOGS" ]] || { echo "Log directory not found: $USER_LOGS"; exit 1; }
    LOGS="$USER_LOGS"
elif [[ -d /var/local/logs/spar ]]; then
    LOGS="/var/local/logs/spar/spar-a-$(date +%Y%m%d)"
else
    LOGS="$HOME/logs/spar/spar-a-$(date +%Y%m%d)"
fi
JOBS="${JOBS:-8}"

# --- Language instruction ---
case "$LANGUAGE" in
    en-gb) LANG_INSTRUCTION="Use British English." ;;
    en-au) LANG_INSTRUCTION="Use Australian English." ;;
    en)    LANG_INSTRUCTION="Use English." ;;
    *)     LANG_INSTRUCTION="Write in the language specified by code: $LANGUAGE." ;;
esac

# --- Validate required files ---
[[ -f "$METHOD" ]]   || { echo "Method file not found: $METHOD"; exit 1; }
[[ -f "$OVERVIEW" ]] || { echo "Overview file not found: $OVERVIEW"; exit 1; }
[[ -n "$ANTIFACTS" ]] && [[ ! -f "$ANTIFACTS" ]] && { echo "Antifacts file not found: $ANTIFACTS"; exit 1; }
[[ -n "$CAMPAIGN_PRINCIPLES" ]] && [[ ! -f "$CAMPAIGN_PRINCIPLES" ]] && { echo "Campaign principles not found: $CAMPAIGN_PRINCIPLES"; exit 1; }

# --- Print campaign summary ---
echo "Campaign:    $(yq -r '.campaign' "$CAMPAIGN_FILE")"
echo "Sender:      $SENDER_NAME <$SENDER_EMAIL>"
echo "Method:      $METHOD"
echo "Language:    $LANGUAGE"
echo "Segments:    ${SEGMENTS[*]}"
echo "Filters:     email=$FILTER_REQUIRE_EMAIL no_linkedin=$FILTER_REQUIRE_NO_LINKEDIN valid_only=$FILTER_EXCLUDE_INVALID min_star=$FILTER_MIN_STAR require_profile=$FILTER_REQUIRE_PROFILE"
echo ""

mkdir -p "$PROMPTS"
[[ -z "$USER_LOGS" ]] && mkdir -p "$LOGS"

source "$SCRIPT_DIR/spar-lib.sh"

find_profile() {
    local profile_dir="$1" slug_name="$2" slug_org="$3"
    [[ -d "$profile_dir" ]] || return 1
    local match
    match=$(find "$profile_dir" -maxdepth 1 -iname "*${slug_name}*${slug_org}*" 2>/dev/null | head -1)
    [[ -n "$match" ]] && { echo "$match"; return 0; }
    match=$(find "$profile_dir" -maxdepth 1 -iname "*${slug_name}*" 2>/dev/null | head -1)
    [[ -n "$match" ]] && { echo "$match"; return 0; }
    return 1
}

# Determine max A2 spar rounds from profile richness classification
get_max_rounds() {
    local profile_path="$1"
    if [[ -z "$profile_path" ]] || [[ ! -f "$profile_path" ]]; then
        echo 1  # No profile = thin = 1 round
        return
    fi
    local richness
    richness=$(grep -i 'richness' "$profile_path" | head -1)
    if echo "$richness" | grep -qi 'rich'; then
        echo 3
    elif echo "$richness" | grep -qi 'medium'; then
        echo 1
    else
        echo 1  # Thin or unknown
    fi
}

count=0
skipped=0
for segment in "${SEGMENTS[@]}"; do
    roster="$BASE/$segment/roster.tsv"
    goal="$BASE/$segment/segment.yaml"
    [[ -f "$goal" ]] || goal="$BASE/$segment/goal.md"  # fallback during migration
    profile_dir="$BASE/$segment/profiles"
    [[ -f "$roster" ]] || continue
    [[ -f "$goal" ]] || continue

    mkdir -p "$BASE/$segment/approach"

    while IFS= read -r _raw_line; do
        # bash `read` with IFS=$'\t' collapses consecutive empty fields because tab is
        # a whitespace IFS character. Use awk to split so empty fields are preserved.
        mapfile -t _f < <(printf '%s' "$_raw_line" | awk -F'\t' '{for(i=1;i<=17;i++) print $i}')
        org="${_f[0]:-}"; name="${_f[1]:-}"; role="${_f[2]:-}"; phone="${_f[3]:-}"
        email="${_f[4]:-}"; postcode="${_f[5]:-}"; linkedin="${_f[6]:-}"; facebook="${_f[7]:-}"
        disc_iter="${_f[8]:-}"; disc_via="${_f[9]:-}"; disc_src="${_f[10]:-}"; verified="${_f[11]:-}"
        p_note="${_f[12]:-}"; star="${_f[13]:-}"; response_likelihood="${_f[14]:-}"
        s_note="${_f[15]:-}"; date_invalid="${_f[16]:-}"
        date_invalid="${date_invalid%$'\r'}"

        # Skip header and malformed rows
        [[ "$org" == "organisation" ]] && continue
        [[ -n "$name" ]] || continue
        [[ -n "$org" ]] || continue

        # Campaign filters
        if [[ "$FILTER_REQUIRE_EMAIL" == "true" ]]; then
            [[ "$email" == *@* ]] || continue
        fi
        if [[ "$FILTER_REQUIRE_NO_LINKEDIN" == "true" ]]; then
            [[ -z "$linkedin" ]] || continue
        fi
        if [[ "$FILTER_EXCLUDE_INVALID" == "true" ]]; then
            [[ -z "$date_invalid" ]] || continue
        fi
        if [[ "$FILTER_MIN_STAR" =~ ^[1-9][0-9]*$ ]]; then
            [[ "${star:-0}" =~ ^[0-9]+$ ]] && [[ "${star:-0}" -ge "$FILTER_MIN_STAR" ]] || continue
        fi

        slug_name=$(slugify "$name")
        slug_org=$(slugify "$org")

        # Build output filename from YAML pattern
        outfile_name="${APPROACH_PATTERN//\{star\}/$star}"
        outfile_name="${outfile_name//\{slug_name\}/$slug_name}"
        outfile_name="${outfile_name//\{slug_org\}/$slug_org}"
        outfile="$BASE/$segment/approach/$outfile_name"

        # Skip if approach file already exists (exact or name-prefix match)
        if [[ -f "$outfile" ]]; then
            skipped=$((skipped + 1))
            continue
        fi
        if compgen -G "$BASE/$segment/approach/${slug_name}-*.yaml" > /dev/null 2>&1; then
            skipped=$((skipped + 1))
            continue
        fi

        # Profile lookup
        profile_path=""
        profile_a1_instruction=""
        profile_content=""
        max_rounds=1
        if profile_path=$(find_profile "$profile_dir" "$slug_name" "$slug_org"); then
            profile_a1_instruction="3. Profile: $profile_path"
            profile_content=$(cat "$profile_path")
            max_rounds=$(get_max_rounds "$profile_path")
        else
            if [[ "$FILTER_REQUIRE_PROFILE" == "true" ]]; then
                skipped=$((skipped + 1))
                continue
            fi
            profile_path=""
            profile_a1_instruction="3. No profile document exists for this contact. Treat as Thin profile. Use the roster p_note and s_note below as the primary source for angle selection and drafting."
            profile_content="No profile document. Roster notes only:
p_note: $p_note
s_note: $s_note"
            max_rounds=1
        fi

        # Channel selection per SPAR-A §4.2
        if [[ -n "$linkedin" ]]; then
            if [[ -n "$phone" ]] && echo "$phone" | grep -qP '\d'; then
                channel_desc="Per SPAR-A §4.2: LinkedIn + verified email + phone = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days, (3) phone follow-up if no email reply after 3 days."
            else
                channel_desc="Per SPAR-A §4.2: LinkedIn + verified email = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days."
            fi
        elif [[ -n "$phone" ]] && echo "$phone" | grep -qP '\d'; then
            channel_desc="Per SPAR-A §4.2: email + phone, no LinkedIn = prepare (1) email, (2) phone follow-up script."
        else
            channel_desc="Per SPAR-A §4.2: email only, no phone, no LinkedIn = email only."
        fi

        # Contact summary (reused across stages)
        contact_summary="Name: $name
Organisation: $org
Role: $role
Phone: $phone
Email: $email
LinkedIn: $linkedin
Facebook: $facebook
Star rating: $star
Response likelihood: $response_likelihood
Verified: $verified
p_note: $p_note
s_note: $s_note"

        # Write prompt directory for this contact
        count=$((count + 1))
        prompt_slug="$(printf '%03d' $count)-${slug_name}-${slug_org}"
        prompt_dir="$PROMPTS/$prompt_slug"
        mkdir -p "$prompt_dir"

        # --- meta.env: metadata for the worker ---
        cat > "$prompt_dir/meta.env" <<METAENV
MAX_ROUNDS=$max_rounds
OUTFILE="$outfile"
METHOD="$METHOD"
OVERVIEW="$OVERVIEW"
ANTIFACTS="${ANTIFACTS}"
GOAL="$goal"
CONTACT_SUMMARY=$(printf '%q' "$name | $org | $segment")
CHALLENGER_MODEL=sonnet
METAENV

        # --- Build conditional file-reading instructions ---
        _file_items="1. Method: $METHOD — read §4.1 through §4.5 (warmth, channel, language, angle, draft). Skip §4.6 (spar) — that is handled separately.
2. Organisation overview: $OVERVIEW — read in full. This is the ground truth about the organisation. The segment file lists which USPs apply to this segment and whether each is functional or emotional. Use those USPs, do not invent your own from the overview.
$profile_a1_instruction
4. Segment file: $goal — read the \"message_goal\" field for the specific objective this message must achieve (e.g. secure a FAM visit, collect a roster expression of interest). The \"objective\" field is the long-term commercial goal, not what this message asks for. Read \"first_ask\" for approach style guidance. If the segment has subsegments, determine which subsegment applies to this contact and use its overrides where present."
        _item_num=5
        if [[ -n "$ANTIFACTS" ]]; then
            _file_items+="
${_item_num}. Antifact checklist: $ANTIFACTS — check your draft against every false claim listed here before outputting."
            _item_num=$((_item_num + 1))
        fi
        if [[ -n "$CAMPAIGN_PRINCIPLES" ]]; then
            _file_items+="
${_item_num}. Campaign principles: $CAMPAIGN_PRINCIPLES — read the \"Profile-informed approaches\" section. Do not ask the recipient for information already captured in their profile."
        fi

        _sender_line="$SENDER_NAME, $SENDER_ROLE"
        [[ -n "$SENDER_ORG" ]] && _sender_line+=", $SENDER_ORG"
        _sender_line+=", using $SENDER_EMAIL"

        # --- author-draft.txt: Author drafting prompt (full context) ---
        cat > "$prompt_dir/author-draft.txt" <<A1PROMPT
You are executing SPAR-A Stage 1 (drafting) for one contact. Your task is to draft the approach message(s) and angle rationale. You do NOT perform the A2 spar — that runs in a separate, context-isolated process.

## Files to read before drafting

Read ALL of these files carefully before writing anything.

$_file_items

## Contact details from roster

$contact_summary

## Channel selection

$channel_desc

## Key constraints

- The sender is $_sender_line.
- The email must stand alone for a recipient who has never heard of the sender's organisation. Introduce who you are, what the organisation is, and why you are writing.
- Read the segment file to determine the correct approach type. Do not default to a generic email.
- $LANG_INSTRUCTION
- No emoji.

## Output format

Output your angle selection rationale between these markers:

RATIONALE_START
[your rationale here]
RATIONALE_END

Output your draft message(s) between these markers:

DRAFT_START
[your draft messages here — email, LinkedIn note, phone script as applicable per channel]
DRAFT_END

Do NOT write any files. Only output text to stdout with the markers above.
A1PROMPT

        # --- Build challenger fact-check section conditionally ---
        _factcheck_files="Files to read:
1. $OVERVIEW
2. $goal"
        if [[ -n "$ANTIFACTS" ]]; then
            _factcheck_files+="
3. $ANTIFACTS"
        fi

        if [[ -n "$ANTIFACTS" ]] || [[ -f "$OVERVIEW" ]]; then
            _factcheck_section="## Step 2: Fact-check (break character)

Break character. Now read the following files and check every factual claim in the draft message against them. Flag any errors or claims that cannot be verified.

$_factcheck_files
Do not flag drive-time or distance claims (e.g. \"X minutes from Y\"). These are approximate figures and do not need fact-check verification.

For each issue found, write: \"FACTCHECK: [claim in draft] — [what the source says or that no source exists]\"

## Step 3: Verdict

After completing Steps 1 and 2, emit exactly one of these lines as the very last line of your output:"
        else
            _factcheck_section="## Step 2: Verdict

Emit exactly one of these lines as the very last line of your output:"
        fi

        # --- challenger-template.txt: Challenger prompt (context-isolated) ---
        # Profile content is inlined. Draft is replaced by worker at runtime.
        cat > "$prompt_dir/challenger-template.txt" <<C2PROMPT
You have sequential tasks. Complete Step 1 fully before proceeding.

## Step 1: Role-play as the recipient

You are the following person. React to the email draft below as if you received it cold — you have never heard of the sender or their organisation. Give a natural, in-character reaction. Do NOT use a rubric or structured format. Just react as a person would.

### Your profile

$profile_content

### The message you received

__DRAFT_PLACEHOLDER__

---

Give your in-character reaction now. When done, proceed.

$_factcheck_section

VERDICT: DONE
VERDICT: REVISE

Emit VERDICT: DONE if the draft is credible (the persona reacted naturally without major objections) and factually correct. Emit VERDICT: REVISE if the persona had significant concerns or if fact-check found errors that must be fixed.
C2PROMPT

        # --- profile-content.txt: for reference ---
        echo "$profile_content" > "$prompt_dir/profile-content.txt"

    done < "$roster"
done

echo "Generated $count prompt files in $PROMPTS/"
echo "Skipped $skipped (approach file already exists)"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run complete. Review prompts in $PROMPTS/"
    exit 0
fi

if [[ $count -eq 0 ]]; then
    echo "Nothing to do."
    exit 0
fi

echo "Running $count jobs, $JOBS concurrent (GNU parallel)..."
echo ""

find "$PROMPTS" -mindepth 1 -maxdepth 1 -type d | shuf | \
parallel -j"$JOBS" \
    --joblog "$LOGS/joblog.tsv" \
    --line-buffer \
    "bash $WORKER {} $LOGS"

echo ""
echo "=== Summary ==="
echo "Logs:       $LOGS/"
echo "Job log:    $LOGS/joblog.tsv"
echo "Successful: $(awk 'NR>1 && $7==0' "$LOGS/joblog.tsv" | wc -l)"
echo "Failed:     $(awk 'NR>1 && $7!=0' "$LOGS/joblog.tsv" | wc -l)"

failed_count=$(awk 'NR>1 && $7!=0' "$LOGS/joblog.tsv" | wc -l)
if [[ "$failed_count" -gt 0 ]]; then
    echo ""
    echo "Failed jobs:"
    awk -F'\t' 'NR>1 && $7!=0 {print "  " $NF}' "$LOGS/joblog.tsv"
fi

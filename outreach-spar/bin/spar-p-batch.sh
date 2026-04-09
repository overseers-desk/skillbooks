#!/bin/bash
# spar-p-batch.sh — Build SPAR-P profiles for roster entries without existing profiles
# Usage: bash spar-p-batch.sh <segment-dir> [--campaign=<yaml>] [--dry-run]
#
# Reads <segment-dir>/roster.tsv, checks <segment-dir>/profiles/ for existing profiles,
# and builds SPAR-P profiles for all valid entries that don't have one yet.
#
# When --campaign is given, overview and antifacts paths are read from the YAML.
# Otherwise, use --overview and --antifacts flags to specify them directly.
#
# Requires: GNU parallel, claude CLI, yq (if --campaign is used)
set -euo pipefail

SEGMENT_DIR=""
DRY_RUN=false
JOBS=4
USER_LOGS=""
CAMPAIGN_FILE=""
USER_OVERVIEW=""
USER_ANTIFACTS=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --jobs=*) JOBS="${arg#--jobs=}" ;;
        --logs=*) USER_LOGS="${arg#--logs=}" ;;
        --campaign=*) CAMPAIGN_FILE="${arg#--campaign=}" ;;
        --overview=*) USER_OVERVIEW="${arg#--overview=}" ;;
        --antifacts=*) USER_ANTIFACTS="${arg#--antifacts=}" ;;
        -*) echo "Unknown flag: $arg"; exit 1 ;;
        *) SEGMENT_DIR="$arg" ;;
    esac
done

[[ -n "$SEGMENT_DIR" ]] || { echo "Usage: spar-p-batch.sh <segment-dir> [--campaign=<yaml>] [--dry-run] [--jobs=N] [--logs=DIR]"; exit 1; }
[[ -d "$SEGMENT_DIR" ]] || { echo "Segment dir not found: $SEGMENT_DIR"; exit 1; }

SEGMENT_DIR=$(cd "$SEGMENT_DIR" && pwd)
ROSTER="$SEGMENT_DIR/roster.tsv"
PROFILE_DIR="$SEGMENT_DIR/profiles"
GOAL="$SEGMENT_DIR/segment.yaml"
[[ -f "$GOAL" ]] || GOAL="$SEGMENT_DIR/goal.md"  # fallback during migration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# SPAR-P procedure doc is co-located with this script (one level up from bin/)
SPAR_P="$SCRIPT_DIR/../spar-P-profile.md"

# Resolve paths from campaign YAML or flags
_resolve_from() { local base="$1" p="$2"; [[ "$p" == /* ]] && echo "$p" || echo "$base/$p"; }

if [[ -n "$CAMPAIGN_FILE" ]]; then
    [[ -f "$CAMPAIGN_FILE" ]] || { echo "Campaign file not found: $CAMPAIGN_FILE"; exit 1; }
    CAMPAIGN_FILE="$(cd "$(dirname "$CAMPAIGN_FILE")" && pwd)/$(basename "$CAMPAIGN_FILE")"
    _yaml_base="$(dirname "$CAMPAIGN_FILE")"
    OVERVIEW=$(_resolve_from "$_yaml_base" "$(yq -r '.usp_document' "$CAMPAIGN_FILE")")
    _antifacts_raw=$(yq -r '.antifacts // ""' "$CAMPAIGN_FILE")
    [[ -n "$_antifacts_raw" ]] && ANTIFACTS=$(_resolve_from "$_yaml_base" "$_antifacts_raw") || ANTIFACTS=""
elif [[ -n "$USER_OVERVIEW" ]]; then
    OVERVIEW="$USER_OVERVIEW"
    ANTIFACTS="${USER_ANTIFACTS}"
else
    echo "Error: provide --campaign=<yaml> or --overview=<path> to specify the organisation overview document." >&2
    exit 1
fi

[[ -f "$ROSTER" ]] || { echo "Roster not found: $ROSTER"; exit 1; }
[[ -f "$GOAL" ]] || { echo "Goal not found: $GOAL"; exit 1; }
[[ -f "$SPAR_P" ]] || { echo "SPAR-P not found: $SPAR_P"; exit 1; }
[[ -f "$OVERVIEW" ]] || { echo "Overview not found: $OVERVIEW"; exit 1; }
[[ -n "$ANTIFACTS" ]] && [[ ! -f "$ANTIFACTS" ]] && { echo "Antifacts not found: $ANTIFACTS"; exit 1; }
mkdir -p "$PROFILE_DIR"

WORKDIR="/tmp/spar-p-$(basename "$SEGMENT_DIR")-$(date +%Y%m%d%H%M)"
PROMPTS="$WORKDIR/prompts"
if [[ -n "$USER_LOGS" ]]; then
    [[ -d "$USER_LOGS" ]] || { echo "Log directory not found: $USER_LOGS"; exit 1; }
    LOGS="$USER_LOGS"
elif [[ -d /var/local/logs/spar ]]; then
    LOGS="/var/local/logs/spar/spar-p-$(basename "$SEGMENT_DIR")-$(date +%Y%m%d%H%M)"
else
    LOGS="$HOME/logs/spar/spar-p-$(basename "$SEGMENT_DIR")-$(date +%Y%m%d%H%M)"
fi
mkdir -p "$PROMPTS"
[[ -z "$USER_LOGS" ]] && mkdir -p "$LOGS"

source "$SCRIPT_DIR/spar-lib.sh"

profile_exists_for_name() {
    # Returns 0 if a profile exists for this contact name.
    # Multi-word names: prefix match on the profile filename is reliable.
    # Single-word names (first-name only): also require the first word of the org slug to
    # appear in the profile's org section, to avoid false positives across people with
    # the same first name (e.g. "Paul" at Group Transport should not match "paul-budde-wwii-...").
    local slug_name="$1"
    local slug_org="$2"
    local match
    match=$(ls "$PROFILE_DIR"/profile-"${slug_name}"-*.md 2>/dev/null | head -1)
    [[ -z "$match" ]] && return 1
    # Multi-word name: prefix match alone is reliable
    [[ "$slug_name" == *-* ]] && return 0
    # Single-word name: verify first word of org appears in the profile's org section
    local profile_org_part first_org_word
    profile_org_part=$(basename "$match" .md | sed "s/^profile-${slug_name}-//")
    first_org_word="${slug_org%%-*}"
    [[ "$profile_org_part" == *"${first_org_word}"* ]] && return 0
    return 1
}

profile_exists_for_org_same_initial() {
    # Returns 0 if a profile with this org slug exists AND its name starts with
    # the same letter as the current contact — avoids false positives when multiple
    # contacts at the same org exist (e.g. Innes Larkin vs Tracey Larkin at Mt Barney Lodge)
    local slug_name="$1"
    local slug_org="$2"
    local initial="${slug_name:0:1}"
    local match
    match=$(ls "$PROFILE_DIR"/profile-*"${slug_org}"*.md 2>/dev/null | head -1)
    [[ -z "$match" ]] && return 1
    local profile_base
    profile_base=$(basename "$match" .md | sed 's/^profile-//')
    [[ "${profile_base:0:1}" == "$initial" ]] && return 0
    return 1
}

# Detect column layout from header:
#   "segment"      → standard layout with leading segment col
#   "organisation" → segment-free layout (all standard per-segment rosters)
#   "contact_name" → Singapore layout (one-off campaigns)
HEADER=$(head -1 "$ROSTER" | tr -d '\r')
LAYOUT=$(echo "$HEADER" | awk -F'\t' '{
    if ($1=="segment") print "segment"
    else if ($1=="organisation") print "org"
    else print "singapore"
}')

count=0
skipped=0
SOH=$(printf '\x01')

while IFS="$SOH" read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21; do
    if [[ "$LAYOUT" == "segment" ]]; then
        # Standard layout: segment org name role phone email postcode linkedin facebook
        #                  sweep_iter disc_via disc_src verified p_note star s_note date_invalid
        segment="$f1"; org="$f2"; name="$f3"; role="$f4"; phone="$f5"; email="$f6"
        linkedin="$f8"; facebook="$f9"; p_note="$f14"; s_note="$f17"
        date_invalid="${f18%$'\r'}"
        [[ "$segment" == "segment" ]] && continue  # skip header
        [[ -n "$segment" ]] || continue             # skip blank rows
    elif [[ "$LAYOUT" == "org" ]]; then
        # Segment-free layout: org name role phone email postcode linkedin facebook
        #                      sweep_iter disc_via disc_src verified p_note star response_likelihood s_note date_found_invalid
        org="$f1"; name="$f2"; role="$f3"; phone="$f4"; email="$f5"
        linkedin="$f7"; facebook="$f8"; p_note="$f13"; s_note="$f16"
        date_invalid="${f17%$'\r'}"
        [[ "$org" == "organisation" ]] && continue  # skip header
        [[ -n "$org" ]] || continue                  # skip blank rows
    else
        # Singapore layout: name org role phone email linkedin facebook sweep disc_via disc_src verified date_invalid ...
        name="$f1"; org="$f2"; role="$f3"; phone="$f4"; email="$f5"
        linkedin="$f6"; facebook="$f7"; date_invalid="${f12%$'\r'}"
        s_note="$f15"; p_note="$f17"
        [[ "$name" == "contact_name" ]] && continue  # skip header
    fi

    [[ -n "$name" ]] || continue
    [[ -n "$org" ]] || continue
    [[ -z "$date_invalid" ]] || continue  # skip invalidated entries

    slug_name=$(slugify "$name")
    slug_org=$(slugify "$org")
    outfile="$PROFILE_DIR/profile-${slug_name}-${slug_org}.md"

    # Skip if: exact slug exists, or name-slug matches a profile, or org-slug+initial matches
    # Name check: catches profiles renamed during research (e.g. "Jamie Lee" → "Jamie-Lee Howard")
    # Org+initial check: catches roster name updates (e.g. "David" → "David Miller") while
    #   avoiding false positives for multiple contacts at the same org
    if [[ -f "$outfile" ]] || profile_exists_for_name "$slug_name" "$slug_org" || profile_exists_for_org_same_initial "$slug_name" "$slug_org"; then
        skipped=$((skipped + 1))
        continue
    fi

    count=$((count + 1))
    prompt_slug="$(printf '%03d' $count)-${slug_name}-${slug_org}"
    prompt_file="$PROMPTS/${prompt_slug}.txt"

    _antifacts_line=""
    [[ -n "$ANTIFACTS" ]] && _antifacts_line="Antifact checklist: read $ANTIFACTS — flag any claims not supported by these sources."

    cat > "$prompt_file" <<PROMPT
Follow the SPAR-P procedure at $SPAR_P.

Target: $name at $org, role: $role. Phone: $phone. Email: $email. LinkedIn: $linkedin. Facebook: $facebook.
Roster notes — s_note: $s_note, p_note: $p_note.

Campaign context: read $GOAL for the segment's objective, USPs, and angle table.
Organisation overview: read $OVERVIEW for ground truth about the organisation.
$_antifacts_line

Output file: $outfile
Roster file: $ROSTER

Follow SPAR-P §5 profile structure exactly. After writing the profile, follow SPAR-P §4.9 to write star_rating and response_likelihood to the roster TSV (not to the profile document). Then follow §4.11 to backfill any missing contact details (email, linkedin_url, facebook_url) and replace stale contacts discovered during research with the person currently in the role.
Web search is the primary research method. Use Chromium only when the target has a LinkedIn or Facebook URL and WebFetch returns insufficient data. Wrap Chromium with flock: flock /tmp/chromium.lock /snap/bin/chromium --headless --dump-dom --virtual-time-budget=30000 --window-size=1920,10000 --user-data-dir="\$HOME/snap/chromium/common/chromium" "URL" 2>/dev/null
PROMPT

done < <(awk -F'\t' -v OFS="$SOH" '{$1=$1; print}' "$ROSTER")

echo "Segment:  $(basename "$SEGMENT_DIR")"
echo "To build: $count profiles"
echo "Skipped:  $skipped (existing profiles)"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run — prompts in $PROMPTS/"
    exit 0
fi

if [[ $count -eq 0 ]]; then
    echo "Nothing to do."
    exit 0
fi

echo "Running $count jobs, $JOBS concurrent (GNU parallel)..."
echo ""

find "$PROMPTS" -maxdepth 1 -name "*.txt" | sort | \
    parallel -j"$JOBS" \
        --joblog "$LOGS/joblog.tsv" \
        --line-buffer \
        "cat {} | claude -p --dangerously-skip-permissions --model sonnet --max-budget-usd 3.00 > $LOGS/{/.}.log 2>&1; echo \"[DONE] {/}\""

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

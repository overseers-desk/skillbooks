# SPAR Campaign YAML Schema

**Applies to:** all SPAR campaigns. The `campaign.yaml` file is the entry point for batch scripts (`bin/spar-a-batch.sh`, `bin/spar-p-batch.sh`, `bin/check-campaign-progress.py`).

## Location

One file per campaign run, in the campaign root directory. Named `campaign.yaml` or `campaign-{qualifier}.yaml` (e.g. `campaign-2026-04-all.yaml`). Multiple YAML files may coexist when different filter settings are needed for different runs against the same segments.

## Fields

### Required

| Field | Type | Purpose |
|---|---|---|
| `campaign` | string | Display name (appears in script output and logs) |
| `sender.name` | string | Sender's display name for outgoing messages |
| `sender.role` | string | Sender's role title |
| `sender.email` | string | Sender's email address (used as From: address) |
| `method` | path | Path to the SPAR-A procedure document (e.g. `../aesop/outreach-spar/spar-A-approach.md`). Relative to the YAML file's directory. |
| `usp_document` | path | Path to the organisation overview / USP document. Relative to the YAML file's directory. This is the ground truth about the organisation that A1 reads before drafting. |
| `language` | string | Language code: `en-gb`, `en-au`, `en`, or a BCP-47 code |
| `segments` | list of strings | Segment directory names to include in batch processing. Use `.` for a single-segment campaign where roster and goal live in the campaign root (see `spar-campaign-directory.md`). |
| `approach_filename` | string | Template for approach filenames. Variables: `{slug_name}`, `{slug_org}`, `{star}`. Example: `approach-{slug_name}-{slug_org}.md` |

### Required (filter)

| Field | Type | Default | Purpose |
|---|---|---|---|
| `filter.require_email` | boolean | false | Skip roster entries without an email address |
| `filter.exclude_invalid` | boolean | true | Skip roster entries with a non-empty `date_found_invalid` |

### Optional (filter)

| Field | Type | Default | Purpose |
|---|---|---|---|
| `filter.require_no_linkedin` | boolean | false | Skip entries that have a LinkedIn URL (used when targeting email-only contacts) |
| `filter.min_star` | integer | 0 | Skip entries with `star_rating` below this threshold |
| `filter.require_profile` | boolean | false | Skip entries that have no matching profile document |

### Optional

| Field | Type | Default | Purpose |
|---|---|---|---|
| `sender.organisation` | string | (none) | Organisation name for prompt text (e.g. "Historic Rivermill"). When absent, prompts use the sender's name and role without an org name. |
| `sender.bcc` | string | (none) | BCC address for outgoing emails |
| `antifacts` | path | (none) | Path to the antifact/fact-check document. When present, the A2 challenger fact-checks the draft against this file. When absent, fact-check uses only the overview and goal documents. Relative to the YAML file's directory. |
| `campaign_principles` | path | (none) | Path to campaign-level principles document. When present, A1 reads it before drafting. When absent, A1 relies on the method document and goal file alone. Relative to the YAML file's directory. |
| `skip_segments` | list of strings | (none) | Segment directory names to exclude from `check-campaign-progress.py`. Useful for closed campaigns or non-standard directories that should not appear in the progress report. |
| `ses_region` | string | `ap-southeast-2` | AWS SES region for email sending |

## Path resolution

All path fields (`method`, `usp_document`, `antifacts`, `campaign_principles`) are resolved relative to the YAML file's parent directory. Absolute paths are used as-is. This allows the campaign YAML to reference documents in sibling repositories (e.g. `../aesop/outreach-spar/spar-A-approach.md`).

## Example

```yaml
campaign: 2026-04 Partnership Outreach (3+ star, profile required)

sender:
  name: Lia Movsisyan
  role: Partnership Manager
  organisation: Historic Rivermill
  email: partnerships@rivermill.au
  bcc: partnerships@rivermill.au

method: ../aesop/outreach-spar/spar-A-approach.md
usp_document: ../overview.md
antifacts: ../overview-antifacts.md
campaign_principles: goal-campaign-principles.md

language: en-gb

segments:
  - animal-event
  - car-boot-market
  - community-organisation
  - wedding-planner

filter:
  require_email: false
  exclude_invalid: true
  min_star: 3
  require_profile: true

approach_filename: "approach-{slug_name}-{slug_org}.md"

skip_segments:
  - 2026-03-Singapore-investor-outreach

ses_region: ap-southeast-2
```

## Relationship to other documents

- `spar-campaign-directory.md` — defines the directory structure that the YAML references
- `spar-roster-format.md` — defines the roster schema consumed by `spar-a-batch.sh` and `spar-p-batch.sh`
- `spar-A-approach.md` — the procedure document typically referenced by `method`

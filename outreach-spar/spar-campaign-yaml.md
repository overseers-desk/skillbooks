# SPAR Campaign YAML Schema

**Applies to:** all SPAR campaigns. The `campaign.yaml` file is the entry point for batch scripts (`bin/spar-a-batch.sh`, `bin/spar-p-batch.sh`, `bin/update-campaign.py`).

## Location

One file per campaign, in the campaign root directory. Named `campaign.yaml` or `campaign-{date}.yaml` (e.g. `campaign-2026-04.yaml`). One campaign in business terms means one YAML file — do not create variants or copies to change filter settings. Edit the existing file instead.

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
| `segments` | list of strings | Segment directory names to include in batch processing. Use `.` for a single-segment campaign where roster and segment.yaml live in the campaign root (see `spar-campaign-directory.md`). |
| `approach_filename` | string | Template for approach filenames. Variables: `{slug_name}`, `{slug_org}`, `{star}`. Example: `approach-{slug_name}-{slug_org}.md` |
| `usps` | map | USP registry: maps each USP identifier to its human-readable label. This is the single source of truth for USP names. Segment files reference USPs by `id`; the label is resolved from this registry. The full USP prose lives in the `usp_document`. |

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
| `antifacts` | path | (none) | Path to the antifact/fact-check document. When present, the A2 challenger fact-checks the draft against this file. When absent, fact-check uses only the overview and segment file. Relative to the YAML file's directory. |
| `campaign_principles` | path | (none) | Path to campaign-level principles document. When present, A1 reads it before drafting. When absent, A1 relies on the method document and segment file alone. Relative to the YAML file's directory. |
| `skip_segments` | list of strings | (none) | Segment directory names to exclude from `update-campaign.py`. Useful for closed campaigns or non-standard directories that should not appear in the progress report. |
| `ses_region` | string | `ap-southeast-2` | AWS SES region for email sending |
| `reply_check.mailroom_account` | string | (none) | Mailroom account name for reply detection. When present (with `reply_check.folder`), `update-campaign.py` queries this IMAP account for incoming replies and appends `### Email Replied` sections to matching approach files. |
| `reply_check.folder` | string | (none) | IMAP folder to search for replies (e.g. `Partnerships`). |

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

usps:
  U1:  Scenic riverside setting on the Coomera River
  U2:  Peruvian Paso horses
  U3:  Interactive animal experiences
  U4:  Heritage character
  U5:  On-site cafe with group catering
  U6:  30 minutes from central Gold Coast
  U7:  Six-bedroom farmstay
  U8:  Best of Queensland Experience 2025 (TEQ credential)
  U9:  Cowboys Day proof point
  U10: Instagram visual credibility
  U11: 6.2-hectare grounds with 200+ car parks

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

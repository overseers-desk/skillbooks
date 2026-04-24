# SPAR Campaign YAML Schema

**Applies to:** all SPAR campaigns. The `campaign.yaml` file is the entry point for the spar-manager dispatcher and progress tools.

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
| `usp_document` | path | Path to the organisation overview / USP document. Relative to the YAML file's directory. This is the ground truth about the organisation that A1 reads before drafting. |
| `language` | string | Language code: `en-gb`, `en-au`, `en`, or a BCP-47 code |
| `segments` | list of strings | Segment directory names to include in batch processing. Use `.` for a single-segment campaign where roster and segment.yaml live in the campaign root (see `spar-campaign-directory.md`). |
| `approach_filename` | string | Template for approach filenames. Variables: `{slug_name}`, `{slug_org}`, `{star}`. Example: `approach-{slug_name}-{slug_org}.md` |
| `usps` | map | USP registry: maps each USP identifier to its human-readable label. This is the single source of truth for USP names. Segment files reference USPs by `id`; the label is resolved from this registry. The full USP prose lives in the `usp_document`. |

### Required (channels)

The campaign declares which outreach channels are in scope and the cadence between them. Three named slots are available: `primary_channel`, `secondary_channel`, `tertiary_channel`. Only `primary_channel` is required.

| Field | Type | Purpose |
|---|---|---|
| `primary_channel` | string or map | The first touch. Bare channel name (e.g. `email`) is the short form; the map form `{channel: email}` is available for forward compatibility. |
| `secondary_channel` | map | Contingent follow-up. Requires `channel`, `wait_days`, `wait_condition`. Omit the slot for campaigns that do not follow up. |
| `tertiary_channel` | map | Second contingent follow-up, same shape as secondary. Omit if unused. |

Channel vocabulary: `email`, `phone`, `linkedin`, `facebook`. A channel not named in any slot is out of scope for this campaign — contacts whose only channel is out of scope are filtered at dispatch time, not marked invalid.

`wait_condition` values defined today:

- `no_reply` — the follow-up fires only if the preceding channel has no `replied_date` after `wait_days` have elapsed since its `actioned_date`.

### Required (filter)

| Field | Type | Default | Purpose |
|---|---|---|---|
| `filter.skip_excluded` | boolean | true | Skip roster entries with a non-empty `date_excluded` |

### Optional (filter)

| Field | Type | Default | Purpose |
|---|---|---|---|
| `filter.min_star` | integer | 0 | Skip entries with `star_rating` below this threshold |
| `filter.require_profile` | boolean | false | Skip entries that have no matching profile document |

### Optional

| Field | Type | Default | Purpose |
|---|---|---|---|
| `sender.organisation` | string | (none) | Organisation name for prompt text (e.g. "Historic Rivermill"). When absent, prompts use the sender's name and role without an org name. |
| `sender.bcc` | string | (none) | BCC address for outgoing emails |
| `antifacts` | path | (none) | Path to the antifact/fact-check document. When present, the A2 challenger fact-checks the draft against this file. When absent, fact-check uses only the overview and segment file. Relative to the YAML file's directory. |
| `campaign_principles` | path | (none) | Path to campaign-level principles document. When present, A1 reads it before drafting. When absent, A1 relies on the method document and segment file alone. Relative to the YAML file's directory. |
| `skip_segments` | list of strings | (none) | Segment directory names to exclude from progress reporting. Useful for closed campaigns or non-standard directories that should not appear in the progress report. |
| `ses_region` | string | `ap-southeast-2` | AWS SES region for email sending |
| `a_max_passes` | integer | 3 | Hard ceiling on challenger passes per contact in the A phase. The effective value for each contact is `min(a_max_passes, profile-derived)`. Profile-derived comes from the profile's `yield` front-matter field: `yield >= 6` yields 3, otherwise 1 (see `spar-P-profile.md` §5.1). Must be an integer ≥ 0. A ceiling does not force passes; the challenger can still return `DONE` earlier. Quality/cost ladder: `0` disables the challenger entirely — the initial draft flows straight to assembly with no fact-check (cheapest, no adversarial review). `1` runs the challenger once; the author revises based on its feedback, but that revision is never re-validated (feedback applied, not verified). `2` re-challenges the first revision. `3` (default) allows up to two re-challenges. Note that at any `a_max_passes ≥ 1` the *last* revision is still unvalidated — there is no pass that both critiques and then re-challenges the final draft. |
| `reply_check.mailroom_account` | string | (none) | Mailroom account name for reply detection. When present (with `reply_check.folder`), the reply checker queries this IMAP account for incoming replies and appends `### Email Replied` sections to matching approach files. |
| `reply_check.folder` | string | (none) | IMAP folder to search for replies (e.g. `Partnerships`). |
| `prompt_appendices` | map | (none) | Per-agent appendix text appended verbatim to the composed prompt at dispatch time. Closed vocabulary — allowed sub-keys: `p_author`, `a_author`, `a_challenger`, `a_assembly`. Any other sub-key is rejected by the campaign loader. Each value is an inline string; empty string or missing key = no appendix. Use this slot for campaign-specific tone guidance, exclusion rules, or strategy-revision notes that must not pollute the methodology documents. |

## Path resolution

Path fields (`usp_document`, `antifacts`, `campaign_principles`) are resolved relative to the YAML file's parent directory. Absolute paths are used as-is. The SPAR-A procedure document is resolved by the dispatcher as a sibling of its own script (`../spar-A-approach.md`) and is not a campaign-level path.

## Example

```yaml
campaign: 2026-04 Example Outreach (3+ star, profile required)

sender:
  name: Example Sender
  role: Partnership Manager
  organisation: Example Org
  email: partnerships@example.com
  bcc: partnerships@example.com

usp_document: ../overview.md
antifacts: ../overview-antifacts.md
campaign_principles: goal-campaign-principles.md

language: en-gb

primary_channel: email
secondary_channel:
  channel: phone
  wait_days: 3
  wait_condition: no_reply

usps:
  U1: Example USP one
  U2: Example USP two
  U3: Example USP three

segments:
  - segment-a
  - segment-b

filter:
  skip_excluded: true
  min_star: 3
  require_profile: true

approach_filename: "approach-{slug_name}-{slug_org}.md"

ses_region: ap-southeast-2

prompt_appendices:
  p_author: ""
  a_author: ""
  a_challenger: ""
  a_assembly: ""
```

## Relationship to other documents

- `spar-campaign-directory.md` — defines the directory structure that the YAML references
- `spar-roster-format.md` — defines the roster schema consumed by the batch dispatch tools
- `spar-A-approach.md` — the procedure document the A-phase dispatcher resolves automatically as a sibling of its own script

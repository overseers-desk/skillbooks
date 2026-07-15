# SPAR Campaign YAML Schema

**Applies to:** all SPAR campaigns. The `campaign.yaml` file is the entry point for the spar-manager dispatcher and progress tools.

## Location

One file per campaign, in the campaign root directory. Named `campaign.yaml` or `campaign-{date}.yaml` (e.g. `campaign-2026-04.yaml`). One campaign in business terms means one YAML file — do not create variants or copies to change filter settings. Edit the existing file instead.

## Fields

### Required

| Field | Type | Purpose |
|---|---|---|
| `version` | string | SPAR spec generation this file conforms to. Current value: `"1.0"`. Required for files authored under spec 1.0 or later. A file with no `version` is treated as legacy/unstamped (a warning, not a failure). The tool refuses to process a campaign whose `version` it does not support. See `spar-methodology.md`, "Versioning". |
| `campaign` | string | Display name (appears in script output and logs) |
| `sender.name` | string | Sender's display name for outgoing messages |
| `sender.role` | string | Sender's role title |
| `sender.email` | string | Sender's email address (used as From: address) |
| `usp_document` | path | Path to the organisation overview / USP document. Relative to the YAML file's directory. This is the ground truth about the organisation that A1 reads before drafting. |
| `language` | string | Language code: `en-gb`, `en-au`, `en`, or a BCP-47 code |
| `segments` | map | Maps each segment directory name this campaign operates over to that segment's **plan block** (the campaign×segment intersection: objective, USP framings, message_goal, first_ask, ask_stance, conversion_funnel, approach_sequencing). See "Per-segment plan block" below. Names resolve to sibling directories of this YAML file (path resolution is relative to the YAML's directory). The same segment name may appear under the `segments:` of more than one campaign YAML at the same level, each carrying its own plan: segments are not owned by any one campaign, and the plan changes with the campaign's ask, so it is the campaign's, not the segment's (see the invariance test in `spar-methodology.md`, "Campaigns and segments"). Use `.` for a single-segment campaign where roster and segment.yaml live in the campaign root (see `spar-campaign-directory.md`). |
| `approach_filename` | string | Template for approach filenames. Variables: `{slug_name}`, `{slug_org}`, `{star}`. Example: `approach-{slug_name}-{slug_org}.md` |
| `usps` | map | USP registry: maps each USP identifier to its human-readable label. This is the single source of truth for USP names. A segment's plan block references USPs by `id`; the label is resolved from this registry. Registry and per-segment framing now live in the same file, so a referenced `id` always resolves. The full USP prose lives in the `usp_document`. |

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

### Optional (venue)

The campaign may declare a physical venue. When present, the dispatcher exposes it to the P prompt so the AI can compute target-to-venue driving distance via OSRM where proximity bears on angle assessment (see `spar-P-profile.md` §4.6.1). Until #93 lands, the OSRM call is AI-side; once it lands, the harness will use the same fields to compute distance deterministically and substitute it into the prompt as a literal.

| Field | Type | Default | Purpose |
|---|---|---|---|
| `venue.address` | string | (none) | Postal address used for context and as a geocoding fallback. Required when `venue` is present. |
| `venue.coordinate.latitude` | float | (none) | WGS84 latitude. Required when `venue` is present. |
| `venue.coordinate.longitude` | float | (none) | WGS84 longitude. Required when `venue` is present. |

```yaml
venue:
  address: "950 Beaudesert Nerang Rd Mount Nathan QLD 4211, Australia"
  coordinate:
    latitude: -27.9769223
    longitude: 153.2520029
```

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
| `reply_check.courier_account` | string | (none) | Courier account name for reply detection. When present (with `reply_check.folder`), the reply checker queries this IMAP account for incoming replies and appends `### Email Replied` sections to matching approach files. |
| `reply_check.folder` | string | (none) | IMAP folder to search for replies (e.g. `Partnerships`). |
| `prompt_appendices` | map | (none) | Per-agent appendix text appended verbatim to the composed prompt at dispatch time. Closed vocabulary — allowed sub-keys: `p_author`, `a_author`, `a_challenger`, `a_assembly`. Any other sub-key is rejected by the campaign loader. Each value is an inline string; empty string or missing key = no appendix. Use this slot for campaign-specific tone guidance, exclusion rules, or strategy-revision notes that must not pollute the methodology documents. |

## Per-segment plan block

`segments` is a map from segment name to that segment's plan. The plan is the campaign×segment intersection: what *this* campaign aims to do with the contacts in that segment, and how. It is campaign-bound, which is why it lives here and not in `segment.yaml` (the segment file holds only the campaign-independent population definition — discovery criteria, scope, rating rubric; see `segment-schema.yaml` and `spar-campaign-directory.md`).

Each plan block may carry:

| Plan field | Type | Purpose |
|---|---|---|
| `objective` | prose | What this campaign aims to accomplish with this segment, in 1–3 sentences. |
| `usps` | list | Which campaign USPs apply to this segment and why. Each entry has `id` (from the campaign `usps:` registry), `type` (`emotional` or `functional`, segment-specific), and `framing` (prose: why this USP matters to contacts in this segment). A segment-local USP not in the registry uses `label` instead of `id`. |
| `message_goal` | prose | The outcome the first message aims for (e.g. "agree to a site visit"). |
| `first_ask` | prose | The model message or pattern for first contact. May contain placeholders the A phase fills from the profile. |
| `ask_stance` | `direct` or `problem-led` | The stance chosen via the classifier in `spar-methodology.md` ("Classifying the ask"). `direct`: state the want plainly (we are the buyer, or a plain mutual offer). `problem-led`: frame around the recipient's problem, because naming the want would weaken us (we compete to be selected). |
| `recipient_problem` | prose | Required when `ask_stance` is `problem-led`. The recipient's own problem this campaign solves, which the first message addresses. |
| `deciding_interest` | prose | The lens through which this segment's recipient decides: the campaign's instantiation of the methodology's generic "deciding interest". For a media segment, their *audience*; for a supplier ask, *winning a worthwhile account*. Naming it here keeps "audience" out of the method (anti-brittle). |
| `state_want` | boolean | Whether the first message states the want outright. `direct` implies `true`. Under `problem-led` the author chooses; leaving the want unsaid (`false`) is an option, never a requirement. |
| `conversion_funnel` | list | The sequence from first contact to outcome; each step has `step`, `name`, `description`. |
| `approach_sequencing` | list | Operational order of actions for this segment; each step has `step`, `action`. |
| `subsegments` | list | Optional variations within the segment. A subsegment shares the segment's objective and USPs but may override `message_goal`, `first_ask`, `ask_stance`, `recipient_problem`, `deciding_interest`, `state_want`, `conversion_funnel`, and `discovery_criteria`. Only differing fields appear. |

A plan block may be sparse: a segment still being discovered (S&P only, A not yet in scope) carries `objective` and little else. Do not fabricate plan fields to fill the shape.

The P phase reads the plan block for profiling context — the objective and USP framings define what relevance looks like, which P uses to assess applicable angles (SPAR-P §4.12) and gather alignment evidence for A. P does not use them to set `star_rating`, which is campaign-independent general value to us (see `spar-methodology.md`, "Campaigns and segments"). The A phase reads the whole block to draft. Both reach it through the segment's entry in this map, which the dispatcher surfaces to the prompt by path and segment key.

## Path resolution

Path fields (`usp_document`, `antifacts`, `campaign_principles`) are resolved relative to the YAML file's parent directory. Absolute paths are used as-is. The SPAR-A procedure document is resolved by the dispatcher as a sibling of its own script (`../spar-A-approach.md`) and is not a campaign-level path.

## Example

```yaml
version: "1.0"
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
  segment-a:
    objective: |
      Get segment-a contacts to agree to a site visit.
    usps:
      - id: U1
        type: emotional
        framing: |
          Why U1 matters to contacts in segment-a.
      - id: U2
        type: functional
        framing: |
          Why U2 matters to contacts in segment-a.
    message_goal: |
      Agree to a complimentary site visit.
    first_ask: |
      The model first-contact message or pattern for segment-a.
    ask_stance: problem-led        # or: direct
    recipient_problem: |
      The recipient's own problem this campaign solves and the message addresses.
      (Required when ask_stance is problem-led.)
    deciding_interest: |
      The lens this recipient decides by, e.g. their audience (problem-led only).
    state_want: false              # direct implies true; problem-led is the author's call
    conversion_funnel:
      - step: 1
        name: Initial approach
        description: |
          What happens at this step.
      - step: 2
        name: Site visit
        description: |
          What happens at this step.
    approach_sequencing:
      - step: 1
        action: |
          What to do first.
  segment-b:
    objective: |
      What this campaign aims to accomplish with segment-b.
    # remaining plan fields as above; a sparse block is valid

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

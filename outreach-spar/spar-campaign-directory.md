# SPAR Campaign Directory Structure

**Applies to:** campaign planners setting up a new SPAR outreach campaign

**Prerequisite reading:** `spar-methodology.md`, `spar-campaign-yaml.md`

## Standard layout

```
campaign-root/
  campaign.yaml                   # campaign definition (schema: spar-campaign-yaml.md)
  [campaign-principles.md]        # optional campaign-level rules (referenced by YAML)
  {segment}/                      # one directory per segment
    roster.tsv                    # SPAR roster (schema: spar-roster-format.md)
    segment.yaml                  # segment objective, USPs, first ask, conversion funnel (schema: segment-schema-proposal.yaml)
    [profiles-summary.md]         # optional segment-level profile summary (lives here, NOT inside profiles/)
    [comms-index.md]              # optional communication index (lives here, NOT inside approach/)
    profiles/                     # SPAR-P profile documents ONLY — no summary or meta files
      profile-{slug-name}-{slug-org}.md
    approach/                     # SPAR-A approach files ONLY — no index or meta files
      {stem}.yaml
```

## Single-segment (flat) layout

For small campaigns with one segment, set `segments: ["."]` in the campaign YAML. The roster, goal, profiles, and approach directories live directly in the campaign root alongside `campaign.yaml`:

```
campaign-root/
  campaign.yaml
  roster.tsv
  segment.yaml
  [profiles-summary.md]
  [comms-index.md]
  profiles/
    profile-{slug-name}-{slug-org}.md
  approach/
    approach-{slug-name}-{slug-org}.md
```

All batch scripts resolve `.` as the campaign root directory. When a campaign outgrows a single segment, create segment subdirectories, move the files, and update the `segments` list in the YAML. The segment file schema is defined in `segment-schema-proposal.yaml`.

## Conventions

**Segment directories** are named with lowercase hyphenated nouns describing the contact type (e.g. `wedding-planner`, `tour-operator-domestic`, `community-organisation`). The directory name appears in the `segments` list in `campaign.yaml` and in progress reports. The special value `.` means the segment files live in the campaign root itself.

**One roster per segment.** The file is always `roster.tsv` — the directory carries the segment context. Do not embed the segment name in the roster filename. The roster schema is defined in `spar-roster-format.md`.

**One segment file per segment.** The file is always `segment.yaml`. It contains: the outreach objective, the USPs relevant to this segment (by identifier, with segment-specific framing), the approach message goal, the first ask, the conversion funnel, approach sequencing, and optional subsegments. The schema is defined in `segment-schema-proposal.yaml`.

**Profile filenames** follow the pattern `profile-{slug-name}-{slug-org}.md`, where slugs are lowercase-hyphenated. Batch scripts match roster entries to profiles by slug prefix, so the profile filename must contain the contact's slugified name.

**Approach filenames** follow the `approach_filename` template in `campaign.yaml`, defaulting to `approach-{slug_name}-{slug_org}.md`. Batch scripts detect approach status by parsing headings within the file (see `spar-A-approach.md` lifecycle conventions).

## Discovery by batch scripts

`spar-progress.tcl` and `spar-transition.tcl` both read the `segments` list from `campaign.yaml`. Only listed segments are processed. `spar-progress.tcl` warns about any `roster.tsv` files found on disk that are not listed in the YAML. Directories in `skip_segments` are excluded.

`spar-transition.tcl <campaign.yaml> T1` drives profile generation from the classified state machine, one campaign at a time. `T1:<segment>` narrows to a single segment, `T1:<segment>/<roster-stem>` narrows to a single contact. Add `--dry-run` to simulate without writes.

## Organisation-level documents

The `usp_document` (organisation overview) and `antifacts` (fact-check document) referenced in `campaign.yaml` typically live outside the campaign directory, in the parent repository. They describe the organisation, not the campaign. Multiple campaigns for the same organisation share these documents.

## What does not belong in the campaign directory

- **Raw data exports** (CSV dumps, CRM exports) — place in a `data/` directory excluded by `.gitignore`
- **Scripts** — the SPAR batch tools live in `aesop/outreach-spar/spar-manager/`, not in the campaign directory. Campaign-specific helper scripts (e.g. IMAP search, email enrichment) may live in the campaign directory if they are not reusable.
- **Methodology documents** — live in `aesop/outreach-spar/`, not duplicated per campaign
- **`README.md`** — the `campaign:` display-name field and the top-of-file banner comment in `campaign.yaml` already introduce the campaign for humans. A README duplicates that and drifts out of sync.
- **Principles or policy prose that duplicates YAML content** — when you feel the pull to write a `goal-campaign-principles.md` or similar, first put the content into the campaign YAML's `prompt_appendices` block (`p_author`, `a_author`, `a_challenger`, `a_assembly`) or into the segment YAML's `discovery_criteria`. Those are the designed homes. The `campaign_principles:` path field is for content that genuinely cannot fit into the YAML — a long prose document, a principle set shared across multiple unrelated campaigns — not as a default container.

## Single source of truth — fact-to-home table

Every fact about the campaign has one authoritative home. Before creating any new file in a campaign directory, locate the fact you are about to write on this table. If the designated home already exists, edit it; do not add a parallel file.

| Fact | Authoritative home |
|---|---|
| Campaign display name, sender, channels, filters | `campaign.yaml` |
| USP labels | `campaign.yaml` `usps:` map |
| USP prose | the file named in `usp_document:` |
| Anti-claims / do-not-say list | the file named in `antifacts:` |
| Segment objective, USP framings, message goal, first ask, funnel | `{segment}/segment.yaml` |
| Segment-level qualification gates | `{segment}/segment.yaml` `discovery_criteria:` |
| A-phase and P-phase prompt guidance (reminders, rules, apology behaviour) | `campaign.yaml` `prompt_appendices:` |
| Per-contact data | `{segment}/roster.tsv` |
| Per-contact profile | `{segment}/profiles/profile-{slug}.md` |
| Per-contact approach draft | `{segment}/approach/{stem}.yaml` |
| Campaign intro for human readers | `campaign:` display-name field + top-of-file banner comment in `campaign.yaml` |

**Pattern-matching warning.** An existing campaign in the repository may contain files that predate this guidance (for example `spar-campaigns/goal-campaign-principles.md`). Those are legacy; their existence is not a template for new campaigns. When the spec and a neighbouring example disagree, follow the spec.

## Relationship to other documents

- `spar-campaign-yaml.md` — defines the YAML schema
- `spar-roster-format.md` — defines the roster column schema
- `spar-segment-categorisation.md` — criteria for deciding segment boundaries

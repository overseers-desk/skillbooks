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
    profiles/                     # SPAR-P profile documents
      profile-{slug-name}-{slug-org}.md
    approach/                     # SPAR-A approach/comms files
      approach-{slug-name}-{slug-org}.md
```

## Single-segment (flat) layout

For small campaigns with one segment, set `segments: ["."]` in the campaign YAML. The roster, goal, profiles, and approach directories live directly in the campaign root alongside `campaign.yaml`:

```
campaign-root/
  campaign.yaml
  roster.tsv
  segment.yaml
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

`update-campaign.py` and `spar-a-batch.sh` both read the `segments` list from `campaign.yaml`. Only listed segments are processed. `update-campaign.py` warns about any `roster.tsv` files found on disk that are not listed in the YAML. Directories in `skip_segments` are excluded.

`spar-p-batch.sh` operates on a single segment directory passed as an argument.

## Organisation-level documents

The `usp_document` (organisation overview) and `antifacts` (fact-check document) referenced in `campaign.yaml` typically live outside the campaign directory, in the parent repository. They describe the organisation, not the campaign. Multiple campaigns for the same organisation share these documents.

## What does not belong in the campaign directory

- **Raw data exports** (CSV dumps, CRM exports) — place in a `data/` directory excluded by `.gitignore`
- **Scripts** — the SPAR batch scripts live in `aesop/outreach-spar/bin/`, not in the campaign directory. Campaign-specific helper scripts (e.g. IMAP search, email enrichment) may live in the campaign directory if they are not reusable.
- **Methodology documents** — live in `aesop/outreach-spar/`, not duplicated per campaign

## Relationship to other documents

- `spar-campaign-yaml.md` — defines the YAML schema
- `spar-roster-format.md` — defines the roster column schema
- `spar-segment-categorisation.md` — criteria for deciding segment boundaries

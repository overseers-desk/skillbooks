# SPAR Campaign Directory Structure

**Applies to:** campaign planners setting up a new SPAR outreach campaign

**Prerequisite reading:** `spar-methodology.md`, `spar-campaign-yaml.md`

## Layouts

A repository may host one campaign or several. Both cases use the same shape: a campaign YAML names segments by bare directory name, and each segment directory carries the segment's roster, segment definition, profile documents, and communications log. The relation between campaigns and segments is many-to-many (see `spar-methodology.md`, "Campaigns and segments").

### Multi-campaign layout (segments shared across campaigns)

When a repository hosts several campaigns that share segments, the campaign YAML files and the segment directories sit as siblings at one repository level:

```
campaigns-root/
  campaign-{name-1}.yaml          # campaign definition (schema: spar-campaign-yaml.md)
  campaign-{name-2}.yaml          # campaign definition
  ...
  {segment}/                      # one directory per segment, shared across campaigns
    roster.tsv                    # SPAR roster (schema: spar-roster-format.md)
    segment.yaml                  # population definition (schema: segment-schema.yaml)
    [profiles-summary.md]         # optional segment-level profile summary
    [comms-index.md]              # optional communication index
    profiles/                     # SPAR-P profile documents, one per contact
      profile-{slug-name}-{slug-org}.md
    approach/                     # communications log per contact (name historical; see methodology)
      {stem}.yaml
```

Each campaign YAML names in its `segments:` map the segment directories it operates over, mapping each to that segment's plan block. The same segment name may appear in the `segments:` map of more than one campaign YAML at this level, each with its own plan. Path resolution is relative to the YAML file's directory, so segments are addressable by bare name.

### Single-campaign layout

When a repository hosts one campaign, the campaign YAML sits as a sibling of its segment directories:

```
campaign-root/
  campaign.yaml
  [campaign-principles.md]        # optional campaign-level rules (referenced by YAML)
  {segment}/
    roster.tsv
    segment.yaml
    profiles/
    approach/
```

For a small campaign with only one segment, set `segments: ["."]` in the campaign YAML. The roster, segment definition, profiles, and communications log live directly in the campaign root alongside `campaign.yaml`:

```
campaign-root/
  campaign.yaml
  roster.tsv
  segment.yaml
  profiles/
  approach/
```

All batch scripts resolve `.` as the campaign root directory. When the campaign needs to address a second segment, add it to the `segments:` map (with its plan block) and create the segment directory as a sibling. The segment file schema is defined in `segment-schema.yaml`.

## Conventions

**Segment directories** are named with lowercase hyphenated nouns describing the contact type (e.g. `wedding-planner`, `tour-operator-domestic`, `community-organisation`). The directory name appears as a key in the `segments` map in `campaign.yaml` and in progress reports. The special value `.` means the segment files live in the campaign root itself.

**One roster per segment.** The file is always `roster.tsv` — the directory carries the segment context. Do not embed the segment name in the roster filename. The roster schema is defined in `spar-roster-format.md`.

**One segment file per segment.** The file is always `segment.yaml`. It defines the campaign-independent population: `discovery_criteria` (who belongs), `rating_rubric` (how useful a member is to us), `scope_note` (boundaries with neighbouring segments), and `profile_reject_if`. It carries no campaign plan content. The objective, USP framings, message goal, first ask, conversion funnel, approach sequencing, and subsegments live in the campaign's per-segment plan block (`campaign.yaml` `segments.<name>`), because they change with the campaign's ask (a segment is reused across campaigns of different asks) — see the invariance test in `spar-methodology.md`, "Campaigns and segments". The schema is defined in `segment-schema.yaml`.

**Profile filenames** follow the pattern `profile-{slug-name}-{slug-org}.md`, where slugs are lowercase-hyphenated. Batch scripts match roster entries to profiles by slug prefix, so the profile filename must contain the contact's slugified name.

**Approach filenames** follow the `approach_filename` template in `campaign.yaml`, defaulting to `approach-{slug_name}-{slug_org}.md`. Batch scripts detect approach status by parsing headings within the file (see `spar-A-approach.md` lifecycle conventions).

## Discovery by batch scripts

`spar-progress.tcl` and `spar-transition.tcl` both read the `segments` map from `campaign.yaml`. Only named segments are processed. `spar-progress.tcl` warns about any `roster.tsv` files found on disk that are not listed in the YAML. Directories in `skip_segments` are excluded.

`spar-transition.tcl <campaign.yaml> T1` drives profile generation from the classified state machine, one campaign at a time. `T1:<segment>` narrows to a single segment, `T1:<segment>/<roster-stem>` narrows to a single contact. Add `--dry-run` to simulate without writes.

## Organisation-level documents

The `usp_document` (organisation overview) and `antifacts` (fact-check document) referenced in `campaign.yaml` typically live outside the campaign directory, in the parent repository. They describe the organisation, not the campaign. Multiple campaigns for the same organisation share these documents.

## What does not belong in the campaign directory

- **Raw data exports** (CSV dumps, CRM exports) — place in a `data/` directory excluded by `.gitignore`
- **Scripts** — the SPAR batch tools live in `aesop/outreach-spar/spar-manager/`, not in the campaign directory. Campaign-specific helper scripts (e.g. IMAP search, email enrichment) may live in the campaign directory if they are not reusable.
- **Methodology documents** — live in `aesop/outreach-spar/`, not duplicated per campaign
- **`README.md`** — the `campaign:` display-name field and the top-of-file banner comment in `campaign.yaml` already introduce the campaign for humans. A README duplicates that and drifts out of sync.
- **Principles or policy prose that duplicates YAML content** — when you feel the pull to write a `goal-campaign-principles.md` or similar, first put the content into the campaign YAML's `prompt_appendices` block (`p_author`, `a_author`, `a_challenger`, `a_assembly`) or into the segment YAML's `discovery_criteria`. Those are the designed homes. The `campaign_principles:` path field is for content that genuinely cannot fit into the YAML — a long prose document, a principle set shared across multiple unrelated campaigns — not as a default container.
- **Grouping parents around segments**: directories like `rosters/`, `segments/`, or any axis-named parent that wraps several segment directories under one node. Segments are addressable from the campaign YAML's directory by bare name; a wrapping parent breaks that addressing (the segment name no longer resolves) and implies a category layer the methodology does not model. If a classification of segments by role, axis, or industry is informative, record it as a tag inside the segment, not as a directory parent.

## Single source of truth — fact-to-home table

Every fact about the campaign has one authoritative home. Before creating any new file in a campaign directory, locate the fact you are about to write on this table. If the designated home already exists, edit it; do not add a parallel file.

| Fact | Authoritative home |
|---|---|
| Spec version a campaign conforms to | `campaign.yaml` `version:` |
| Spec version a segment conforms to | `{segment}/segment.yaml` `version:` |
| Campaign display name, sender, channels, filters | `campaign.yaml` |
| USP labels | `campaign.yaml` `usps:` map |
| USP prose | the file named in `usp_document:` |
| Anti-claims / do-not-say list | the file named in `antifacts:` |
| Segment objective, USP framings, message goal, first ask, funnel, approach sequencing | `campaign.yaml` `segments.<name>` plan block |
| Segment-level qualification gates (who belongs in the population) | `{segment}/segment.yaml` `discovery_criteria:` |
| Segment rating rubric (how useful a member is to us) | `{segment}/segment.yaml` `rating_rubric:` |
| A-phase and P-phase prompt guidance (reminders, rules, apology behaviour) | `campaign.yaml` `prompt_appendices:` |
| Per-contact population data (identity, channels, s_note, p_note, star_rating) | `{segment}/roster.tsv` |
| Per-contact profile | `{segment}/profiles/profile-{slug}.md` |
| Per-contact engagement (messages, response_likelihood, a_note, r_note) | `{segment}/approach/{stem}.yaml` |
| Campaign intro for human readers | `campaign:` display-name field + top-of-file banner comment in `campaign.yaml` |

**Pattern-matching warning.** An existing repository may contain files or directories that predate or contradict this guidance: a legacy `spar-campaigns/goal-campaign-principles.md`, a wrapping `rosters/` parent over several segment directories, or other shapes the spec does not model. Their existence is not a template for new work. When the spec and a neighbouring example disagree, follow the spec. The failure mode this warning addresses is the next AI session inferring layout from what is on disk rather than from this document, then extending the unrecognised pattern further.

## Relationship to other documents

- `spar-campaign-yaml.md` — defines the YAML schema
- `spar-roster-format.md` — defines the roster column schema
- `spar-segment-categorisation.md` — criteria for deciding segment boundaries

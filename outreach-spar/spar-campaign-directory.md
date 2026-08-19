# SPAR Campaign Directory Structure

**Applies to:** campaign planners setting up a new SPAR outreach campaign

**Prerequisite reading:** `spar-methodology.md`, `spar-campaign-yaml.md`

## Layout

An instance root holds two folders, `segments/` and `campaigns/`. Everything the tooling reads lives under those two; anything else at the root is invisible to it, so no fencing key exists or is needed.

```
<instance-root>/
  segments/
    {segment}/                    # profile documents, one per contact, directly inside
      {stem}.md
    {segment}.tsv                 # roster (schema: spar-roster-format.md)
    {segment}.yaml                # population definition (schema: segment-schema.yaml)
    {segment}.sweep.yaml          # coverage: denominator, sources, rounds, escapes (spar-S-search.md 7)
    {segment}.sweep-feedback.tsv  # observations queued by P for the next round's sweep
    {segment}.{word}.md           # segment-scoped documents (e.g. {segment}.summary.md)
  campaigns/
    {campaign}/                   # communications log, one approach YAML per person
      {stem}.yaml
    {campaign}.yaml               # campaign definition (schema: spar-campaign-yaml.md)
    {campaign}.usp.md             # campaign-scoped documents, named {campaign}.{word}.{ext}
```

The pairing rule: a definition file and a same-stem folder of its contents sit side by side, and everything scoped to that stem is a dotted sibling (`{stem}.{word}.{ext}`). The symmetry is an affordance: an unpaired entry is visibly wrong at `ls`, and a scoped document visually belongs to its stem. This enumeration of name patterns is complete, and `INVARIANTS.md` I2 holds it closed: a file whose name matches none of them does not belong under `segments/` or `campaigns/`. Analysis notes, worklogs, and issue write-ups live at the instance root or elsewhere in the repository.

Sweep knowledge shared by a family of segments (`sweeper-{family}.yaml`, `spar-S-search.md` 7.1) lives at the instance root; the sweeps axis has no designed folder yet.

## Approaches are keyed by campaign

An approach is a campaign×contact fact: the same contact approached by two campaigns is two conversations. The approach file therefore lives in the campaign's folder, and the parent directory *is* its campaign attribution — per-campaign facts (who was approached, the earliest send) are a walk of one folder.

**One campaign × one person = one approach file.** However many roster rows a person has across the campaign's segments, the campaign approaches the person once, and the flat folder can hold only one `{stem}.yaml` for them. A filename collision when two segments carry the same stem is intended to surface, and means one of two things (see `spar-methodology.md`, "Campaigns and segments"):

- a **mis-segmentation** — the person belongs in one of the segments; fix the rosters; or
- a **genuine two-role edge case** — one person legitimately holding two roles; both roster rows stay, and the two draft approaches merge into one file, because a campaign writes to a person as someone who knows them, not as two strangers.

Either way the approach file is one.

## The `segments:` map resolves against `segments/`

Each campaign YAML names in its `segments:` map the segments it operates over, mapping each to that segment's plan block. Names resolve to `<instance-root>/segments/{segment}`. The same segment name may appear in several campaigns' maps, each with its own plan: segments are shared, plans are the campaign's.

## Conventions

**Segment names** are lowercase hyphenated nouns describing the contact type (e.g. `wedding-planner`, `tour-operator-domestic`). The name appears as the folder/file stem under `segments/`, as a key in `segments:` maps, and in progress reports.

**One roster per segment.** The file is `segments/{segment}.tsv`. The roster schema is defined in `spar-roster-format.md`.

**One segment file per segment.** The file is `segments/{segment}.yaml`. It defines the campaign-independent population: `discovery_criteria` (who belongs), `rating_rubric` (how useful a member is to us), `scope_note` (boundaries with neighbouring segments), and `platforms` (which platforms the population lives on, and how strongly). It carries no campaign plan content; the objective, USP framings, message goal, first ask, conversion funnel, approach sequencing, and subsegments live in the campaign's per-segment plan block, because they change with the campaign's ask. The schema is defined in `segment-schema.yaml`.

**Profile filenames** are `segments/{segment}/{stem}.md`, `{stem}` being the roster row's stem (`spar-roster-format.md`). Contact state is derived by file existence at that exact path, so the stem is the whole convention. The segment folder holds profiles only.

**Approach filenames** are `campaigns/{campaign}/{stem}.yaml`, the same stem. The campaign folder holds approaches only.

**Cross-segment duplicates are allowed.** The sweep takes care not to place one contact in two segments, but real edge cases exist (one person, two roles), so a duplicate is not by itself an error. When the approach phase meets one, it judges: fix a mis-segmentation, or preserve a genuine two-role case — and writes one approach file regardless (see above).

## Discovery by batch scripts

`spar-progress.tcl` and `spar-transition.tcl` read the `segments:` map from the campaign YAML; only named segments are processed. `spar-transition.tcl <campaign.yaml> T1` drives profile generation from the classified state machine, one campaign at a time. `T1:<segment>` narrows to a single segment, `T1:<segment>/<roster-stem>` narrows to a single contact. Add `--dry-run` to simulate without writes.

The population-tier work (the T0 sweep, T1/T3 profiling, roster validation, progress; the tiers are `spar-methodology.md`, "Campaigns and segments") also runs from a segment alone: give any of the three CLIs `segments/<name>` (or its `.yaml`) instead of a campaign YAML, or several at once (`segments/*` expands in the shell), which run as one set with one table and one total. No campaign context exists in that mode, which is invariant I1 stated operationally; campaign-tier transitions are refused by name.

Outgoing transitions (the send and follow-up T-ids) are additionally gated by the campaign's `start_date` (`spar-campaign-yaml.md`): a campaign with no `start_date` has not launched, and nothing sends.

## Source documents

A `fact_sources` entry or an `antifacts` file shared by several campaigns describes the organisation or a product, not one campaign, and keeps a single home outside `campaigns/` (typically the parent repository), referenced by path from each campaign YAML. Only a document scoped to one campaign takes the `{campaign}.{word}.{ext}` name beside its YAML.

## What does not belong under `segments/` or `campaigns/`

- **Raw data exports** (CSV dumps, CRM exports) — place in a `data/` directory at the instance root, excluded by `.gitignore`
- **Scripts** — the SPAR batch tools live in `aesop/outreach-spar/spar-manager/`, not in the instance. Campaign-specific helper scripts may live at the instance root if they are not reusable.
- **Methodology documents** — live in `aesop/outreach-spar/`, not duplicated per instance
- **`README.md`** — the `campaign:` display-name field and the top-of-file banner comment in the campaign YAML already introduce the campaign for humans.
- **Principles or policy prose that duplicates YAML content** — put the content into the campaign YAML's `prompt_appendices` block or the segment YAML's `discovery_criteria` first; the `campaign_principles:` path field is for content that genuinely cannot fit into the YAML.
- **Grouping parents around segments** beyond `segments/` itself: no axis-named wrapper (`rosters/`, an industry parent) may wrap segment entries. A classification of segments by role or industry is a tag inside the segment file, not a directory layer.

## Single source of truth — fact-to-home table

Every fact about the campaign has one authoritative home. Before creating any new file in an instance, locate the fact you are about to write on this table. If the designated home already exists, edit it; do not add a parallel file.

| Fact | Authoritative home |
|---|---|
| Spec version a campaign conforms to | `campaigns/{campaign}.yaml` `version:` |
| Spec version a segment conforms to | `segments/{segment}.yaml` `version:` |
| Campaign display name, sender, channels, filters, start date | `campaigns/{campaign}.yaml` |
| A USP: its label, its claim, and what the claim rests on | campaign YAML `usps:` registry |
| Documents a campaign's claims draw on | the files listed in `fact_sources:` |
| Anti-claims / do-not-say list | the file named in `antifacts:` |
| Segment objective, USP framings, message goal, first ask, funnel, approach sequencing | campaign YAML `segments.<name>` plan block |
| Which roster rows of a segment this campaign engages (when narrower than the whole segment) | campaign YAML `segments.<name>.stems` |
| Segment-level qualification gates (who belongs in the population) | `segments/{segment}.yaml` `discovery_criteria:` |
| Segment rating rubric (how useful a member is to us) | `segments/{segment}.yaml` `rating_rubric:` |
| A-phase and P-phase prompt guidance (reminders, rules, apology behaviour) | campaign YAML `prompt_appendices:` |
| Per-contact population data (identity, channels, s_note, p_note, star_rating) | `segments/{segment}.tsv` |
| Per-contact profile | `segments/{segment}/{stem}.md` |
| Per-contact engagement (messages, sends, replies) | `campaigns/{campaign}/{stem}.yaml` |
| Which campaign an approach belongs to | the approach file's parent directory |
| Campaign intro for human readers | `campaign:` display-name field + top-of-file banner comment in the campaign YAML |

**Pattern-matching warning.** An existing repository may contain files or directories that predate or contradict this guidance. Their existence is not a template for new work. When the spec and a neighbouring example disagree, follow the spec. The failure mode this warning addresses is the next AI session inferring layout from what is on disk rather than from this document, then extending the unrecognised pattern further.

## Relationship to other documents

- `spar-campaign-yaml.md` — defines the YAML schema
- `spar-roster-format.md` — defines the roster column schema
- `spar-segment-categorisation.md` — criteria for deciding segment boundaries
- `spar-version-uplift-runbook.md` — migrating a 1.0 instance to this layout

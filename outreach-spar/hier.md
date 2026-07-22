# SPAR instance directory hierarchy (proposal)

**Status:** design thinking in progress, not yet adopted. The adopted layout remains `spar-campaign-directory.md`; this document records the candidate replacement and its open questions. It was reasoned tabula rasa: judged as if no instance existed yet, with migration cost weighed separately.

## The problem with the adopted layout

Segment directories, campaign YAMLs, and working documents sit as siblings in one flat instance root. Non-segment directories have to be fenced out of tooling with `skip_segments`. An approach file lives under its *segment* (`<segment>/approach/`), but an approach is a campaign×contact fact: the same contact approached by two campaigns is two conversations. Two campaigns sharing a segment would collide in that one `approach/` directory. Which campaign an approach belongs to is recorded only as prose in its `source:` lines, absent from most files, which makes per-campaign derivations (for example a campaign's earliest send date) an attribution exercise instead of a directory walk.

## Proposed structure

Three top-level folders in the instance root: `segments/`, `campaigns/`, `sweeps/`.

```
<instance-root>/
├── segments/
│   ├── aged-care-provider/            profiles, directly inside (no profiles/ wrapper)
│   │   ├── andrew-bergquist-transitcare-limited.md
│   │   └── briana-mckay-elderly-care.md
│   ├── aged-care-provider.tsv         roster
│   ├── aged-care-provider.yaml        segment definition (today's segment.yaml)
│   ├── lender/
│   ├── lender.tsv
│   ├── lender.yaml
│   └── …
├── campaigns/
│   ├── 2026-07-seniors-farm-day-out/          approach files, directly inside (no approach/ wrapper)
│   │   └── andrew-bergquist-transitcare-limited.yaml
│   ├── 2026-07-seniors-farm-day-out.yaml      campaign definition
│   ├── 2026-07-refinance/
│   ├── 2026-07-refinance.yaml
│   └── …
└── sweeps/
    └── (structure not yet designed)
```

The pairing rule: a definition file and a same-stem folder of its contents, side by side. `segments/` holds three same-stem entries per segment (folder, `.tsv`, `.yaml`); `campaigns/` holds two per campaign (folder, `.yaml`). No folder is ever named `profiles` or `approach`. The symmetry is an affordance: an unpaired entry is visibly wrong at `ls`.

## Design decisions

**Approaches keyed by campaign, not by segment.** The parent directory of an approach file *is* its campaign attribution. Per-campaign facts (who was approached, earliest send) become a walk of one folder.

**Approach filenames stay flat inside the campaign folder — collisions are a feature.** Approaches are keyed `<stem>.yaml`. When one campaign spans two segments that both carry the same stem, the flat folder cannot hold both files. That collision is intended to surface: it reveals that the segments carry a duplicate contact, and triggers a segment repair process rather than being absorbed by segment-qualified paths.

**Sweeps are their own top-level folder, separate from both segments and campaigns.** A sweep can happen before any campaign exists, during a campaign, or not at all (a campaign can run over existing segments with no sweep). So a sweep belongs to neither axis and sits parallel to both. Its internal structure is not yet designed.

## Open questions

- `segments/` internal layout: whether the segment definition is `<stem>.yaml` beside the folder (as drawn) is settled; where segment-scoped working documents go is not.
- Campaign-scoped documents (USP document, campaign principles, antifacts): presumed to live inside the campaign folder, not yet confirmed.
- `sweeps/` internal structure.
- The segment repair process the collision rule triggers: named, not yet specified.
- Whether the campaign YAML's `segments:` map keeps naming segments by stem, resolved against `../segments/`. Presumed yes; the schema change is then small and the work is path plumbing.

## Migration, weighed separately

Adopting this is a spec version bump, larger than any field addition. It touches every path assumption in spar-manager (`profile_dir_for_segment`, `approach_dir_for_segment`, `resolve_campaign`'s segment discovery, path resolution relative to the campaign YAML, dispatcher, validators, tests), plus `spar-campaign-directory.md` and the uplift runbook, plus a file-move sweep across every instance repository. Sequencing note: restructuring before authoring campaign `start_date` values (skillbooks#187) would let each campaign's date floor be derived from an unambiguous directory walk instead of settled by hand.

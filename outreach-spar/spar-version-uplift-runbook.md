# SPAR version-uplift runbook

**Applies to:** bringing an existing SPAR campaign instance up to the current spec version (`2.1`), so it declares conformance and the tooling will process it. Read `spar-methodology.md` "Versioning" first for what a version number means.

## 2.0 → 2.1: the USP moves into the campaign

Spec 2.1 changes the campaign YAML only. `usp_document:` becomes `fact_sources:`, a list, and the `usps:` registry gains a block form carrying provenance (`spar-campaign-yaml.md`). Segment YAMLs are untouched and stay valid at `2.0`; the tool supports both numbers.

```
tclsh9.0 spar-manager/migrate-to-2.1.tcl <instance-root>              # dry-run plan
tclsh9.0 spar-manager/migrate-to-2.1.tcl <instance-root> --execute
```

The script renames the field, carries each registry label through unchanged, and stamps `version: "2.1"`. What it leaves for a person or an agent is the judgement: which USPs came from a document, so taking that document's numbering and a `rests_on`, and which the campaign made itself, so keeping a bare label under an unnumbered key. A campaign that ran on prompt-appendix prose naming further source documents moves those paths into `fact_sources` in the same pass.

## 1.0 → 2.0: the layout migration

Spec 2.0 restructures the instance into `segments/` and `campaigns/` folders with campaign-keyed approach files (`spar-campaign-directory.md`). The tool supports 2.0 only, so a 1.0 instance is migrated, not merely stamped. The migration is scripted:

```
tclsh9.0 spar-manager/tools/migrate-to-2.0.tcl <instance-root>              # dry-run plan + findings
tclsh9.0 spar-manager/tools/migrate-to-2.0.tcl <instance-root> --execute
```

The script plans every move (rosters and segment definitions to dotted stem siblings, profiles into the segment folder, approaches into their campaign's folder, single-campaign docs to `{campaign}.{word}.md`), rewrites the campaign YAMLs' relative path fields for the one-level-deeper location, drops the retired `skip_segments` key, and stamps `version: "2.0"`. It performs moves with `git mv` so history follows.

Three situations stop it, by design:

- **Ambiguous attribution** — a segment with approach files is referenced by more than one campaign. Decide which campaign engaged the segment and pass `--attribute <segment>=<campaign>`. (A campaign that never sent and drafted nothing is not a candidate.)
- **Filename collision** — two roster rows map to one `campaigns/{campaign}/{stem}.yaml`. One campaign × one person = one approach file: judge whether the duplicate is a mis-segmentation (fix the rosters) or a genuine two-role person (keep both rows), and in both cases merge the approach drafts into one file by hand, keeping any sent/replied history, before re-running.
- **`segments: "."`** — the 1.0 root-as-segment form. Name the segment (move the root-level roster and profiles into that name) first; 2.0 has no unnamed segment.

`--start-date <campaign>=<YYYY-MM-DD>` stamps the campaign's planned first-approach date during the same pass (`spar-campaign-yaml.md`). Author it from evidence: the earliest `actioned_date` under the campaign's own approaches is the floor a launched campaign gets; a campaign that has not sent gets no `start_date` until it launches.

After `--execute`, run the validator (step 1 below) and fix to zero errors.

## The three-step procedure (any generation)

### 1. Validate

Run the data-integrity validator against the campaign:

```
tclsh9.0 spar-manager/spar-validate-cli.tcl <path/to/campaign.yaml>
```

It reports two severities. Only **errors** block; **warnings** do not. Before stamping, expect a `version_unstamped` warning on the campaign and on every segment (that is the condition you are about to clear). Send-readiness findings (a missing sender SMTP block, a `placeholder_to` on an unsent email) are warnings by design here, not data-integrity errors, and are left for send-time.

An instance is ready to stamp when the validator reports **zero errors**. If it reports errors, fix them first (step 2). If the campaign has no `campaign.yaml` and no `roster.tsv` at all, it predates the formal model and is a reconstruction, not an uplift (see "Pre-model instances").

### 2. Fix data-integrity errors

| Error code | Cause | Remedy |
|---|---|---|
| `invalid_yaml` | Approach file does not parse. The common signature is truncation at the final `a_note:` field (an unterminated quoted scalar, file ends mid-line), left by an A-phase write that was cut off. | Check whether the contact's approach has a sent or replied message. If it has (real conversation to preserve), repair the YAML by hand. If it has no sent message, delete the file and regenerate the draft by re-running the A-phase on that contact (the contact reverts to `PROFILED`, so the Profile→Approach transition redrafts it). |
| `roster_duplicate_name_org` | The same `(contact_name, organisation)` pair appears on two rows in one segment. | Merge or remove the duplicate row. Keep the row carrying the richer profile/approach; move any unique channel data onto it. |
| `invalid_star_rating` | The profile front matter carries a star value outside 0–5 or non-integer. | Correct the front-matter value to match `spar-roster-format.md`. |
| `masked_email` | A roster email contains `*` (redacted). | Replace with the real address or clear the field. |

After each fix, re-run the validator until errors reach zero.

### 3. Stamp

`migrate-to-2.0.tcl --execute` stamps `version: "2.0"` into every campaign YAML and segment YAML it touches. For a file created after the migration, add the key by hand as the first line (segment YAML) or just above `campaign:` (campaign YAML). Re-run the validator: the `version_unstamped` warnings disappear and the run exits 0 (warnings aside). The instance is uplifted.

## Identifying an instance's generation

Markers, in order of appearance in the spec history, tell you how far an instance is from current:

- **Pre-model:** no `segment.yaml`, no `roster.tsv`; profiles are prose-headed markdown (no YAML front matter); a non-standard seed list (e.g. `seed-list.tsv`); segments nested inside a dated campaign directory. The validator cannot even start (no `campaign.yaml`/roster). This is a reconstruction.
- **Early-formal:** has `segment.yaml` and front-matter profiles, but `segment.yaml` still carries the plan fields (objective, USP framings, message_goal, first_ask, conversion_funnel, approach_sequencing) that now belong in the campaign's per-segment plan block; the roster column order predates the current schema (organisation before contact_name) and may still carry the retired A/R columns (`response_likelihood`, `a_note`, `r_note`) inline; the layout may use a grouping parent (e.g. a `rosters/` wrapper) or dated campaign-segment directories. The tooling tolerates the roster (it keys by header name) and ignores the extra columns, so the roster work is dropping those three columns, and the plan work is lifting the six fields into `campaign.yaml`'s `segments:` map.
- **Formal 1.0:** segments and campaign YAMLs as siblings with no grouping parent; per-segment plan blocks in the campaign YAML; population-only `segment.yaml`; the roster ends at `star_rating`; front-matter profiles; approaches under each segment's `approach/`. Uplift is the scripted 1.0 → 2.0 migration above.
- **Formal 2.0:** `segments/` and `campaigns/` folders with dotted stem siblings; approaches keyed by campaign (`spar-campaign-directory.md`). A campaign YAML carrying `usp_document:` is at this generation whatever it declares. Uplift is the 2.0 → 2.1 pass above.
- **Current (`2.1`):** campaign YAMLs carry `fact_sources:` and a `usps:` registry whose entries record their provenance. Uplift is stamping plus any data-integrity fixes the validator surfaces.

## Deferred hard cases

### Legacy layout under a grouping parent or dated directories

Segments stored under a wrapping parent, or inside a dated campaign directory, are not addressable by bare name from a campaign YAML, so no campaign processes them. To uplift:

1. Move each segment directory up to the 1.0 sibling position (out of the wrapper or dated directory).
2. Add its bare name (with its plan block) to the `segments:` map of the campaign that should own it (create the campaign YAML if none exists).
3. Run the 1.0 → 2.0 migration, then the three-step procedure.

This is deferred from a first pass because it changes paths that downstream artefacts may reference; do it deliberately, one segment at a time, re-validating after each.

### Pre-model instances

An instance with no `segment.yaml`, no `roster.tsv`, and prose-headed markdown profiles cannot be field-mapped to the current schema, because the identity model (the roster `stem` as primary key) and the segment model did not exist when it was authored. Bringing it forward is reconstruction:

1. Build a `roster.tsv` per `spar-roster-format.md`, deriving `stem` for each contact and carrying forward name, organisation, channels, and discovery provenance from the old seed list.
2. Convert each prose profile to a `segments/{segment}/{stem}.md` with the current YAML front matter.
3. Create a `segments/{segment}.yaml` per segment and a `campaigns/{campaign}.yaml`.
4. Run the three-step procedure.

Reconstruction is out of scope for a routine uplift; treat it as its own project.

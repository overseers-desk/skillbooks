# SPAR version-uplift runbook

**Applies to:** bringing an existing SPAR campaign instance up to the current spec version (`1.0`), so it declares conformance and the tooling will process it. Read `spar-methodology.md` "Versioning" first for what a version number means.

The procedure was distilled from uplifting the first instances that already matched the current schema. It is written to serve the harder instances that do not, without re-deriving the steps each time.

## The three-step procedure

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
| `profile_unreachable_without_exclusion` | A profiled contact has no email, LinkedIn, Facebook, or phone, and is not excluded. | Add a channel if one exists, or set `date_excluded` with a reason in the note column. |
| `invalid_star_rating` | The profile front matter carries a star value outside 0–5 or non-integer. | Correct the front-matter value to match `spar-roster-format.md`. |
| `masked_email` | A roster email contains `*` (redacted). | Replace with the real address or clear the field. |

After each fix, re-run the validator until errors reach zero.

### 3. Stamp

Add `version: "1.0"` as a top-level key to the `campaign.yaml` (every campaign file in the instance) and to each conforming `segment.yaml`. Insertion is mechanical and idempotent:

```bash
# segment.yaml files (key as the first line)
for f in <campaign-root>/*/segment.yaml; do
  grep -q '^version:' "$f" || sed -i '1i version: "1.0"' "$f"
done
# campaign file(s) (key just before the campaign: line)
for f in <campaign-root>/campaign*.yaml; do
  grep -q '^version:' "$f" || sed -i '0,/^campaign:/s//version: "1.0"\ncampaign:/' "$f"
done
```

Re-run the validator: the `version_unstamped` warnings disappear and the run exits 0 (warnings aside). The instance is uplifted.

## Identifying an instance's generation

Markers, in order of appearance in the spec history, tell you how far an instance is from current:

- **Pre-model:** no `segment.yaml`, no `roster.tsv`; profiles are prose-headed markdown (no YAML front matter); a non-standard seed list (e.g. `seed-list.tsv`); segments nested inside a dated campaign directory. The validator cannot even start (no `campaign.yaml`/roster). This is a reconstruction.
- **Early-formal:** has `segment.yaml` and front-matter profiles, but the roster column order predates the current schema (organisation before contact_name, no `a_note`/`r_note`), and the layout uses a grouping parent (e.g. a `rosters/` wrapper) or dated campaign-segment directories. The tooling tolerates the roster (it keys by header name), so the work is layout, not roster rewrite.
- **Current (`1.0`):** segments and campaigns as siblings with no grouping parent; roster columns per `spar-roster-format.md`; front-matter profiles. Uplift is stamping plus any data-integrity fixes the validator surfaces.

## Deferred hard cases

### Legacy layout under a grouping parent or dated directories

Segments stored under a wrapping parent, or inside a dated campaign directory, are not addressable by bare name from a campaign YAML, so no campaign processes them. To uplift:

1. Move each segment directory up to sit as a sibling of the campaign YAML.
2. Add its bare name to the `segments:` list of the campaign that should own it (create the campaign YAML if none exists).
3. Run the three-step procedure on the now-addressable segments.

This is deferred from a first pass because it changes paths that downstream artefacts may reference; do it deliberately, one segment at a time, re-validating after each.

### Pre-model instances

An instance with no `segment.yaml`, no `roster.tsv`, and prose-headed markdown profiles cannot be field-mapped to the current schema, because the identity model (the roster `stem` as primary key) and the segment model did not exist when it was authored. Bringing it forward is reconstruction:

1. Build a `roster.tsv` per `spar-roster-format.md`, deriving `stem` for each contact and carrying forward name, organisation, channels, and discovery provenance from the old seed list.
2. Convert each prose profile to a `profiles/{stem}.md` with the current YAML front matter.
3. Create a `segment.yaml` per segment and a `campaign.yaml`, lifting segments out of the dated campaign directory into sibling position.
4. Run the three-step procedure.

Reconstruction is out of scope for a routine uplift; treat it as its own project.

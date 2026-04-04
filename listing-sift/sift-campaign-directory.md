# SIFT Campaign Directory Structure

**Applies to:** operators setting up a new SIFT listing-evaluation campaign

**Prerequisite reading:** `sift-methodology.md`, `sift-registry-format.md`

## Standard layout

```
{domain}.sift/
  campaign-config.md          # scoring rubric, sources, domain-specific columns
  registry.tsv                # SIFT registry (schema: sift-registry-format.md)
  operator-profile.md         # or reference/symlink to external profile
  dossiers/
    {id}.md                   # one per listing (schema: sift-methodology.md dossier format)
```

## Naming convention

Campaign directories are named `{domain}.sift`, where `{domain}` is a lowercase-hyphenated noun describing what is being evaluated. The `.sift` suffix identifies it as a SIFT campaign directory. Examples:

- `published-jobs.sift` — job listings
- `eu-grants.sift` — EU grant calls
- `ieee-cfps.sift` — IEEE conference CFPs
- `nsw-tenders.sift` — NSW government tenders
- `oss-bounties.sift` — open-source bounties

## Campaign configuration

The `campaign-config.md` file defines everything domain-specific about the campaign:

- **Source methodology**: reference to `listing-sift/sift-methodology.md` in the aesop repository
- **Scoring dimensions**: the 3–6 dimensions that compose the star rating, each with a scale and anchor descriptions
- **Star formula**: how the dimensions combine (typically a sum, clamped 1.0–5.0)
- **Amplifier tags**: the campaign-specific tags for percentage amplification, with definitions
- **Amplifier factor**: the multiplier per tag (default 1.15 if not specified)
- **Search sources**: where Sweep looks for listings
- **Campaign-specific registry columns**: columns appended after the core 19, with types and descriptions
- **ID format**: the prefix and numbering convention for listing IDs (e.g. `J001`, `G001`)
- **Operator profile reference**: where the operator profile lives (may be external to the campaign directory)
- **Response types**: what "response preparation" means for this campaign (CV variants, proposal templates, abstracts, etc.)

## Operator profile

The operator profile may live inside the campaign directory (`operator-profile.md`) or outside it. When the same profile serves multiple campaigns (e.g. one CV for both job-seeking and CFP campaigns), place it in the parent directory and reference it from the campaign configuration. Do not duplicate the profile across campaigns.

## Dossier directory

The `dossiers/` directory contains one markdown file per listing, named `{id}.md` where `{id}` matches the registry's `id` column. The dossier format is defined in `sift-methodology.md`. Dossiers are the permanent evidence base; they should not be deleted even after listings go dead.

## What does not belong in the campaign directory

- **Methodology documents** — live in `aesop/listing-sift/`, not duplicated per campaign
- **Raw data exports** (CSV dumps, scraped HTML) — place in a `data/` directory excluded by `.gitignore` if needed
- **Scripts** — reusable scripts live in `aesop/listing-sift/bin/` (when they exist); campaign-specific helper scripts may live in the campaign directory if they are not reusable

## Relationship to other documents

- `sift-methodology.md` — defines the four-phase pipeline and dossier format
- `sift-registry-format.md` — defines the core registry column schema

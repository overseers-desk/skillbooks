# SIFT Campaign Directory Structure

**Applies to:** setting up a new SIFT campaign for an operator

**Prerequisite reading:** `sift-methodology.md`, `sift-registry-format.md`, and the domain document for the campaign's kind of listing, where one exists (`domains/`)

## Layout

```
{name}.sift/
  campaign-config.md          # the operator's choices, and where the operator profile is
  registry.tsv                # SIFT registry (schema: sift-registry-format.md)
  dossiers/
    {id}.md                   # one per listing, named by its registry id (schema: sift-methodology.md dossier format)
  operator-profile.md         # only if the profile lives here (see Operator profile)
```

A campaign is one operator's evaluation of one kind of listing, kept in one such directory. The directory sits in the operator's own files, at a place the operator chooses, and SIFT writes nothing outside it.

Anything else kept in the directory is the operator's own: a helper script written for this campaign, or raw exports and scraped pages. The exports and pages go in a `data/` subdirectory that version control ignores.

## Naming convention

Campaign directories are named `{name}.sift`, where `{name}` is the operator's lowercase-hyphenated name for what is being evaluated. The `.sift` suffix identifies it as a SIFT campaign directory. Examples:

- `jobs.sift`: job listings
- `grant-calls.sift`: grant calls
- `conference-cfps.sift`: conference CFPs
- `tenders.sift`: public tenders

## Campaign configuration

`campaign-config.md` holds this campaign's choices: the operator's, and any a phase had to make (see the end of this section). What is true of every campaign of its kind is in the kind's domain document under `domains/` and is not repeated here.

- **Kind of listing**: named as its domain document is, where one exists (`jobs` for `domains/jobs.md`)
- **Operator profile**: its path
- **Response method**: the name of the method that prepares responses, where there is one
- **Search sources and queries**: the places Sweep looks, and what it searches for there
- **Dimensions**: the domain document's dimensions the campaign uses, with what each leaves to the campaign and any examples added to their anchors; and any dimensions of the campaign's own, with scale and anchors
- **Disposition thresholds**: the cut between high and low on stars, and on pct
- **Amplifier tags**: the campaign's tags for percentage amplification, with definitions, and the factor where it is not the methodology's default
- **ID format**: the prefix and numbering convention for listing IDs (e.g. `J001`, `G001`)
- **The campaign's own registry columns**: with types and descriptions
- **Whatever else the domain document leaves to the campaign**: a list of values for a column, the campaign's currency and the rates for converting others into it

For a kind of listing with no domain document, the configuration defines the kind's columns and dimensions as the campaign's own.

A choice a phase needed and did not find in the configuration is added to it, marked as not yet confirmed by the operator.

## Operator profile

The configuration gives the profile's path. A description the operator already has, a record another method keeps of the operator, and a profile that serves several campaigns each stay where they are, outside the campaign directory. A profile written for this campaign alone is `operator-profile.md` in the campaign directory. Do not duplicate the profile.

## Beside a response method

A campaign directory may sit beside the files of a method that prepares responses, in one parent directory. SIFT's files stay inside `{name}.sift/`, and nothing of another method's belongs there. What SIFT offers to anything outside the directory, and what it takes, is this:

- **The operator profile.** One file may serve as SIFT's operator profile and as another method's record of the operator. SIFT reads from it what the operator has done and what the operator is looking for, leaves the rest alone, and does not write to it.
- **The dossier.** `dossiers/{id}.md` may be read from outside. Its listing description and source background are what was published and what research found. Its Fit section is SIFT's own judgement of the listing against the operator, and is not a source on the publisher. Only SIFT writes the dossier.
- **The listing's id.** The id is how anything outside the campaign directory refers to a listing.
- **Progress.** The registry row is the one record of a listing's progress. Whoever submits a response records the submission, and later progress, in that row, as Target's step on submission says.

## Dossier directory

Dossiers are the permanent evidence base; they should not be deleted even after listings go dead.

## What does not belong in the campaign directory

Methodology documents stay in the aesop repository and are not copied per campaign.

## Relationship to other documents

- `sift-methodology.md`: defines the four-phase pipeline and dossier format
- `sift-registry-format.md`: defines the core registry column schema
- `domains/`: one document per kind of listing, with its sources, columns, dimensions and hand-over to the response method

# How the earlier SAGE batches were opened

Compiled for batch four (venue hire, NDIS equine) to be opened the same way. Verbatim quotes are fenced; every source is named.

## 1. Batch three (kayak hire, riding academy) — 20 September 2026

Found. The session named "sage-update-1" in this project is not the `pmf-sage`-rooted `SAGE-methodology-holes` session (which stops dialogue at `2026-09-19T12:19Z` and never mentions "opening clerk"); it is a **separate** session under the `/usr/local/src/rivermill/product-development` project, uuid `d94a8a2d-b42c-4091-b929-6eff32be2bb1`, cwd `/usr/local/src/rivermill/product-development`. The opening clerk's prompt is an `Agent` (general-purpose, Sonnet tier) tool call at jsonl line 4276, timestamp `2026-09-19T18:56:15.935Z` (= 20 September 04:56 Brisbane), description "Open two runs for re-run", quoted whole:

```
CEREMONY: Sonnet tier, because this is mechanical file work with exact values given (moves, copies, placeholder substitution, one check script); no judgement about evidence is asked, and where something does not fit you stop and report rather than decide.
LEDGER: close your final message with the discovered-work LEDGER entries, part 1 (work the goal needs that this prompt does not cover) and part 2 (dependencies, contradictions between instructions, or forgotten pieces you met while working), or "none". List every file you wrote or moved.

Two product-research runs are being opened for a re-run under rewritten clerk briefs. Do the same five steps for each run. The operator repository's root is the one directory matching `/usr/local/src/r*mill`; call it OP. In shell commands derive it with `OP=$(dirname "$(ls -d /usr/local/src/r*mill/product-development)")` and never type its name literally in a command that also carries code, because a hook refuses that; the Write and Edit tools are not affected. Use `git mv` for moves so history follows, and make no commit: git is the orchestrator's.

Run A: `OP/product-development/kayak-hire/2026-09-03-how-kayak-hire-was-decided`, old-brief date `2026-09-03`.
Run B: `OP/product-development/equestrian-me-academy/2026-09-07-how-the-riding-academy-was-decided`, old-brief date `2026-09-07`.

Steps, per run:

1. Make `superseded/` in the run folder. `git mv` the whole existing `briefs/` folder to `superseded/briefs-<old-brief date>/`. `git mv` every file now in `3-decisions/` into `superseded/` (flat, same file names). Leave every other folder where it is, including Run B's `4-product-design/` and `5-design-game/`.
2. Follow the citations. In every `.md` and `.tsv` file of the run outside `superseded/`, a path that named one of the moved files (`3-decisions/<file>` or `briefs/<file>`, for the files that actually moved) is rewritten to its new place (`superseded/<file>`, `superseded/briefs-<date>/<file>`). Do not touch any other text, and do not touch files under a `venues/`, `raw/` or `data/` folder (captures are never altered); if one of those cites a moved path, list it in your report instead. Inside `superseded/` leave the text alone.
3. Make fresh `briefs/`, `forms/` and `3-decisions/` folders. Copy every file of `/usr/local/src/aesop/pmf-sage/forms/` and of `/usr/local/src/aesop/pmf-sage/.claude/shifts/2026-09-19-1042/stage-d/run-forms/` into the run's `forms/`. Copy every `.md` file of `/usr/local/src/aesop/pmf-sage/.claude/shifts/2026-09-19-1042/stage-d/briefs/` into the run's `briefs/`, except `orchestrator-steps.md`. (An empty `3-decisions/` will not show in git; put nothing in it.)
4. In the copied briefs replace each placeholder `{{KEY}}` with its value from the table below, exactly, by script or by the Edit tool. Then list any `{{...}}` left in any brief.
5. From `/usr/local/src/aesop/pmf-sage` run `python3 tools/launch-check.py <run folder>` and report its output whole. It writes `briefs/venue-situation.md`; that is expected. If it reports failures, do not mend the briefs: quote each failure line.

Values common to both runs (write OP's real path where `<OP>` appears):

- OP = `<OP>`
- MARKET_MAP = `<OP>/historicrivermill.au/research/seo/2026-09-13-market-map.md`
- COMPETITION_NOTE = `<OP>/historicrivermill.au/research/seo/2026-09-17-competition-and-comparables-by-market.md`
- SEARCH_DATA = `<OP>/historicrivermill.au/research/seo/search-console`, then a backtick-closed list continuing with `<OP>/historicrivermill.au/research/seo/semrush` and `<OP>/historicrivermill.au/research/seo/serp-gold-coast`. The template wraps the placeholder in one pair of backticks, so write the value so that the filled sentence reads: the pulled data under `…/search-console`, `…/semrush` and `…/serp-gold-coast` with each path in its own backticks.
- CLUSTER = this offering
- READING = 2026-09-19
- FINDINGS = 0-comparables/findings-market-side.md

Run A values:

- START = 3 September 2026
- ON_SALE = This offering has never been on sale; there are no terms it sells under, and the record is the enquiries alone.
- CORPUS = 0-comparables/paddle-craft-2026-09
- CODEBOOK = 0-comparables/paddle-craft-2026-09/codebook.md
- AMENDMENT = 0-comparables/paddle-craft-2026-09/amendment-whom-sold-to.md
- CODED = 0-comparables/paddle-craft-2026-09/coded-whom-sold-to
- PROFILES = 0-comparables/paddle-craft-2026-09/venues
- PAGES = `<OP>/data/paddle-craft-2026-09`
- CAPABILITY = among them `1-competitions/capability-note.md` and `superseded/capability-extract-for-price-draft.md`

Run B values:

- START = 7 September 2026
- ON_SALE = This offering is not on sale. A forerunner, a riding programme under an earlier name, ran from May to July 2025 and was cancelled; the sales record holds what it sold and the terms it sold under, and a count from it shows that buyers accepted those terms in that window and shows nothing about terms nobody offered.
- CORPUS = 0-comparables/riding-schools-2026-09
- CODEBOOK = 0-comparables/riding-schools-2026-09/codebook.md
- AMENDMENT = 0-comparables/riding-schools-2026-09/amendment-whom-sold-to.md
- CODED = 0-comparables/riding-schools-2026-09/coded-whom-sold-to
- PROFILES = 0-comparables/riding-schools-2026-09/venues
- PAGES = `<OP>/data/riding-schools-2026-09`
- CAPABILITY = among them `1-competitions/capability-note.md`, `superseded/capability-extract-for-blind-draft.md` and whatever the fence index lists under `../delivery-resources/`

Where a placeholder sits inside backticks in a template and its value above also carries backticks, make the filled sentence read naturally with each path in one pair of backticks; say in your report where you had to adjust.

Report in under 250 words: per run, what moved, how many citations were rewritten and in which files, any capture file that cites a moved path, any placeholder left, and the launch check's output.
```

Cross-check against the shift files: `journal.md` entry 33 (2026-09-20-0031 shift) —

```
- 20 Sep: batch three opens with kayak hire and the riding academy. The Survey-stage templates are judged and mended, so the two runs are opened (earlier briefs and decision files to `superseded/`, citations following, templates filled, launch check) by a middle-tier clerk, the shift's hook having refused the orchestrator a fill script of its own. No deriving clerk launches before the population-cut lesson is in the deriving templates. The riding academy's on-sale sentence is a third wording the templates did not foresee: not on sale now, with a forerunner that sold for three months in 2025, whose record shows acceptance of the terms then on offer.
```

`ledger.md` entry 104:

```
- (Opening clerk, batch three) Both runs opened; launch check clean. A capture file under the riding academy's `1-competitions/raw/` cites a moved brief and was left as captured. Kayak hire's `frames/registers.md` and `frames/uk-p-registers.md` hold near-duplicate text, which predates this work.
```

Immediately after (jsonl line 4321, `2026-09-19T18:59:35.939Z`), the orchestrator ran a Bash command described "Summarise what the opening clerk changed in the two runs" (`git status --short` on both run folders), confirming the clerk's work was checked, not just trusted. The successor handover (`.claude/shifts/2026-09-20-0031/handover.md`, added by this same session at jsonl line 8051) names batch four explicitly: "Batch four: venue hire with NDIS equine, opened as batch three was (the opening clerk's prompt is in this session's transcript and in `orchestrator-steps.md`; both surveys keep their captures under `data/`)." — i.e. this prompt, with Run A/Run B replaced by venue hire and the NDIS equine programme, is the intended template for batch four.

## 2. Batch two, party packages half — shift of 19 September 2026

Found directly: this was **not** delegated to a separate "opening clerk." The orchestrator itself ran one Bash command that opened both chapel hire and party packages together. Source: session `71556939-dbe7-4408-8703-686f4079d0ba`, jsonl line 12386, timestamp `2026-09-19T03:10:51.030Z` (= 13:10 Brisbane), tool `Bash`, description "Set up the chapel hire and party run folders with the method's forms, the standing block and the records clerk brief":

```
OP=$(dirname "$(ls -d /usr/local/src/r*mill/product-development)"); T=.claude/shifts/2026-09-19-1042/stage-d/briefs; PD="$OP/product-development"; CH="$PD/chapel-hire/2026-09-11-how-chapel-hire-was-decided"; PA="$PD/party-packages/2026-08-15-how-party-packages-were-decided"; cd "$OP" && git fetch -q && git status -sb | head -1 && mkdir -p "$CH/superseded" && git mv "$CH/briefs" "$CH/superseded/briefs-2026-09-11" && mkdir -p "$CH/briefs" "$CH/forms" "$PA/briefs" "$PA/forms" "$PA/2-blacklist" "$PA/3-decisions" "$PA/0-comparables" "$PA/1-competitions"; cd /usr/local/src/aesop/pmf-sage; for R in "$CH" "$PA"; do cp forms/*.md "$R/forms/"; done; fill() { sed "s#{{OP}}#$OP#g; s#{{START}}#$2#; s#{{ON_SALE}}#$3#" "$T/$1"; }; fill standing-brief-block.md "11 September 2026" "The offering is not yet on sale." > "$CH/briefs/standing-brief-block.md"; fill records-clerk.md > "$CH/briefs/records-clerk.md"; fill standing-brief-block.md "15 August 2026" "The offering is already on sale." > "$PA/briefs/standing-brief-block.md"; fill records-clerk.md > "$PA/briefs/records-clerk.md"; for R in "$CH" "$PA"; do python3 tools/launch-check.py "$R" | tail -3; done; sed -n 5p "$CH/briefs/standing-brief-block.md"
```

This matches `ledger.md` (shift 2026-09-19-1042), entry 22:

```
- 13:11 Stage D opened at width two: chapel hire (not on sale) and party packages (on sale), so both branches of the sales rule are exercised. Chapel's earlier briefs moved to superseded/briefs-2026-09-11; party gets a run folder 2026-08-15-how-party-packages-were-decided beside its survey, as weddings has. Records clerks launched ahead of the pair's second corrections pass, since the evidence pipeline is the part the judges trust and the face changes do not touch it.
```

Party packages had no prior `briefs/` under its own run folder to move to `superseded/` (its 15 August predecessor sits in the separate older-layout folder `product-development/party-packages/2026-08-15-party-survey/`, left untouched), so only `mkdir`, not `git mv`, ran for it; chapel hire's earlier briefs were moved. Both got `forms/`, a filled `standing-brief-block.md` (with the run's own start date and on-sale sentence substituted), a filled `records-clerk.md`, and a clean `tools/launch-check.py` pass, immediately followed (jsonl line 12401, `2026-09-19T`) by an `Agent` call, description "Records clerk: party packages," whose prompt began:

```
CEREMONY. Model tier: opus. The records clerk sorts every file of a product's history into opinion (closed) and behaviour (open); a wrong sort either leaks the venue's opinions to the deriving clerks or starves them of evidence, and the sorting is judgment throughout, so the opus tier suits it. LEDGER clause: close your final message with a section headed LEDGER listing any discovered-work entries in two parts (Part 1: work the project's goal needs that nobody has asked for; Part 2: things found while doing this work, such as dependencies, invalidated assumptions, forgotten pieces), or the word "none".

You are the records clerk in the run folder `/usr/local/src/rivermill/product-development/party-packages/2026-08-15-how-party-packages-were-decided/`. Your brief is `briefs/records-clerk.md` in that folder; read it and follow it. Paths in the brief are relative to the run folder.

One thing about the folder: the run's survey sits beside it in `../2026-08-15-party-survey/` (its fence, internal evidence, codebook, frame, collection, reliability, findings and draft cards), and the run folder itself holds only the method's forms and the briefs so far. The survey's own `0-fence/fence-index.md` and `7-cards/` were written before this reading; treat them as files to sort, like any other.

Leave git alone. After your report, list the records your fence index leaves open to the deriving clerks, one path a line, and say in one line where the coded corpus, its codebook, the venue or operator profiles and the rival register sit.
```

## 3. The method's own folder layout

Grep of `sage-S-survey.md`, `sage-A-adjudicate.md`, `sage-methodology.md`, `sage-E-establish.md`, `sage-G-game.md` finds **no passage that names `0-comparables`, `1-competitions` or `2-blacklist`** as such. Only `3-decisions` is defined in method text, in `forms/card.md`:

```
One file per card under the run's `3-decisions/`, named by number. Field names are read by `tools/card-check.py` and `tools/assemble-review.py`; a run that renames one makes the scripts fail, which is the point.
```

and hard-coded identically in `tools/launch-check.py`, `tools/card-check.py` and `tools/assemble-review.py` (all read/glob `<run>/3-decisions/`). `sage-methodology.md`'s pipeline table names the *stages* in prose ("run folder, survey stage" for the comparables frame/codebook/corpus; "Fence index and generated blacklists... run folder" for the blacklist material) but never ties them to the numeral-prefixed folder names. Those numbered names (`0-comparables`, `1-competitions`, `2-blacklist`) exist only as a convention carried run to run — visible in the `mkdir` command quoted in §2 above, and in the `2026-09-07-how-the-riding-academy-was-decided/3-decisions/` cards already in git status — not as a rule stated anywhere in the method files.

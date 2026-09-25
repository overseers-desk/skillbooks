# Batch five: opening plan (study tour, walking tour)

Taken stock on 25 September 2026, read-only, from listings of the two product folders, the shift files, `how-runs-were-opened.md`, `../../2026-09-19-1042/stage-d/briefs/orchestrator-steps.md` and batch four's filled briefs. `OP` is the operator repository's root. **H** marks an inference, not a reading; **UNKNOWN** marks a value nobody has written down.

## 1. Where each run stands

### Study tour (`OP/product-development/study-tour/`)

No dated `how-...-was-decided` folder exists and no `briefs/`, `forms/`, `3-decisions/` or `superseded/`. The Survey is the old layout, loose in the product folder, all dated 13 August 2026 and tracked, nothing uncommitted:

- Two-sided corpus: `module-suppliers-2026-08/` (supply side: 73 venue profiles in `venues/` across AU 20, CA 14, NZ 15, UK 24, four `index-<country>.tsv`, `coding-results.tsv` 73 rows, Type A variables A1 to A7) and `origin-sellers-2026-08/` (demand side: 27 itinerary captures in `itineraries/` across JP 10, NZ-origin 7, TW 7, KR 2, CN 1, IN 0, six index files, `coding-results.tsv` 27 rows, Type B variables B1 to B10). Every profile and capture carries an address.
- Frames: ten cells, frames and coverage and register notes per cell (supply frames: AU 181 plus a 52-row day-attraction arm and 4 convenience rows, NZ 67, CA 54, UK 551; origin frames: TW 116, KR 99, JP 45 plus 3, CN 15, IN 5 plus 4, NZ-origin 6 plus 3). `frame-review.md` gives one GO (UK, Taiwan), six CONDITIONAL with conditions unmet as far as the files show (AU relabel, NZ 285-to-67 exclusion list and 45 permalinks, CA 8 drops and 21 websites, JP 31 unresolved rows and count mismatch, CN drop 2 NEEQ rows, NZ-origin no rate), and two NO-GO (Korea column-shifted, India).
- Codebook `codebook.md` v1.0, frozen, blind; it already carries **A6 Buyer addressed** (supply side). `gazetteer.md`, `intercoder-check.md`, `coding-corrections.md` (one escalation still open, `jp-ecc-lets-4`).
- Synthesis `2026-08-13-two-sided-market-findings.md` (mixed; not a market-side cut). Two other notes (`2026-08-03-inbound-school-study-tour-market.md`, `2026-08-13-riding-demand-check.md`) and a product note (`2026-08-school-study-tour-modules.md`).
- **Stored page text: none.** Both READMEs say raw pulls sit under `study-tour/data/collection-2026-08/`; that folder is absent from this checkout (git-ignored, so never in git), and the origin README says Taiwan's seven captures never had a stored copy.
- Absent: shape note, strike list, fence index, sales record, questions, corpus inventory, market-side findings cut, amendment, `coded-whom-sold-to`, operator index, rival register, distributor evidence, search-demand study, capability extract. **No Adjudicate file of any kind.**

### Walking tour (`OP/product-development/walking-nature-tour/`)

Current run folder: `2026-09-14-how-the-walking-nature-tour-was-decided/` (the only dated folder; the run record says reading of 2026-09-15, second gate published 17 September, awaiting rulings). No `superseded/`.

- Corpus `0-comparables/guided-walks-2026-09/`: 266 units in `venues/index.tsv`, one profile each (257 carry an address, 9 do not); `frames/` with per-cell registers, coverage and tsv; `codebook.md` V1 to V22 plus amendment 1 (V23 Buyer addressed, V17 re-coded); `venues/coded.tsv` (265 rows) and `coded-amend.tsv` (243), shard files, recode files; `coding-results*.md`, `2026-09-15-findings.md`, `2026-09-16-findings-buyers.md` (series B, V23 over 243 units plus a 22-unit AU-sup cell); `frame-review*.md`, `comparability-ranking.md`. `0-comparables/shape-note.md` (16 Sep) states three of the four dimensions.
- **Stored page text: none** (no `data/` anywhere for this corpus; the capture log records profiles only).
- `1-competitions/`: rival register (15 Sep), capability note, distributor evidence and questions, source meetings, `buyers/` profiles, `raw/` (search demand, rivals, review language, demand).
- `2-blacklist/`: `clean-room-blacklist.md`, `pre-decided-param-file-index.tsv` (old-form fence; no `fence-index.md`).
- Absent under the rewritten set: sales record, `questions.md`, corpus inventory, market-side cut, whom-sold-to amendment in the template's form, operator index, `units-with-text.txt`, `search-demand-findings.md`, `capability-extract.md`, `card-set.md`.
- **Adjudicate files** (`3-decisions/`, old form, one recommendation a card): cards 0 to 14; third-derivation files for 1 to 8 and 10 to 14 (none for 0 or 9); `priors-pass.md`, `priors-pass-card-14.md`, `seller-sentences.md`, `strike-list.md` (Returned "2026-09-16, unmarked", default applied), `integrator-fields.md` (Unlock and Collisions only; no "Withheld, by what the observation costs" paragraph, and no card is withheld), `review.md`, `card-check.txt` (old check format). `briefs/` holds 31 old briefs incl. a generated `venue-situation.md`; `forms/` holds 14 old forms.
- Debris at the product folder's top, tracked since 17 September: `coded-shard6-part1.tsv` (a 13-unit walking coding shard), `coding-escalations-shard6-part1.md`, and five empty files (`council-rendered.html`, `experiences-rendered.html`, `out.html`, `err.log`, `errlog.txt`).

### What "top-up" means for the walking tour

No file defines it. In the ledgers and lessons "Survey top-up" is the survey-top-up clerk's pass over withheld cards, worked from the integrator's "Withheld, by what the observation costs" paragraph (`survey-top-up-clerk.md`; lessons lines 271, 287, 317). The walking tour has no such paragraph and no withheld card, so that reading has no work list yet. The plan's phrase ("the walking tour's survey top-up") comes from the audit of 19 September, which rated the run highest on STANDS (63) and on NEW (37) and labelled it "Survey only". **H:** the top-up is the Survey work the rewritten pipeline asks that the 14 to 16 September survey never did, followed by Adjudicate from step 16 onward, as every lifted run has had. It enters where its record stands and does not redo frame, collection or first-pass coding. Two sizes, for the orchestrator to choose and journal:

- **Lean:** re-fetch pages, then records, search demand and capability, operator index, a page-text check of V23 against the profile codes (step 7's comparison), records refresh, strike list, then Adjudicate. The existing V23 counts become floors if the page coder finds more.
- **Full:** as lean, plus the template amendment (kind within class, payer against participant, the missing arrival and place-held dimensions, and question variables no V covers) coded from pages through steps 4 to 12.

Either way the carried ledger item still stands: card 0 has no third derivation under the reading of 2026-09-19.

## 2. Opening moves (as batch four's opening clerk, Sonnet, file work only)

### Walking tour: folder `OP/product-development/walking-nature-tour/2026-09-14-how-the-walking-nature-tour-was-decided`, old-brief date `2026-09-14`

1. Make `superseded/`. `git mv briefs/` to `superseded/briefs-2026-09-14/`. `git mv` every file in `3-decisions/` into `superseded/` (flat, 32 files including `strike-list.md`, `review.md`, `integrator-fields.md`, `card-check.txt`).
2. **Choice, not in batch three's prompt:** `forms/` already exists with 14 old forms, five of which share a name with the forms to be copied. **H:** `git mv forms/` to `superseded/forms-2026-09-14/` before the copy, so no old form lingers beside the new ones.
3. Rewrite citations to moved paths in `.md` and `.tsv` outside `superseded/`, `venues/`, `raw/` and `data/`. Files citing `briefs/`, `3-decisions/` or `forms/` include `run-record.md`, `2-blacklist/*`, `1-competitions/source-meetings.md`, `1-competitions/buyers/*` and four `frames/` notes (grep hits, not yet checked for moved-file names). List the `raw/` hits (`search-demand*.md`, `search-seed-terms.md`, `rivals-brisbane-moreton-sunshine.md`) rather than editing them. No file outside the run folder cites its briefs, cards or forms (git grep).
4. Make fresh `briefs/`, `forms/`, `3-decisions/`. Copy `pmf-sage/forms/*` and `../../2026-09-19-1042/stage-d/run-forms/*` into `forms/`. Copy the template `.md` files except `orchestrator-steps.md` into `briefs/`.
5. Fill the placeholders (section 3). Run `python3 tools/launch-check.py <run>` and report its output.

Leave `0-comparables/`, `1-competitions/`, `2-blacklist/` and `run-record.md` where they are. The records clerk sorts the old fence files. The run record is replaced forward-only at step 24.

### Study tour: new folder, no old briefs

Nothing to move: the study tour never had briefs or cards. It opens as party packages did (a dated run folder made beside the survey, by `mkdir`).

1. **H:** make `OP/product-development/study-tour/2026-08-13-how-the-study-tour-was-decided/`. The date is that of the codebook and frames; the earliest study-tour file is dated 3 August, so the date is the orchestrator's pick. Inside it make `briefs/`, `forms/`, `0-comparables/`, `1-competitions/`, `2-blacklist/`, `3-decisions/`, and the corpus folder named under CORPUS below.
2. Copy forms and templates as for the walking tour, fill, launch check. The launch check will find no shape note and no strike list until the records and strike-list clerks return.

## 3. Placeholder values

Common to both (batch four's filled values, paths read against the disk today):

- OP = `/usr/local/src/rivermill`
- MARKET_MAP = `OP/historicrivermill.au/analytics/seo/2026-09-13-market-map.md` (batch three's prompt said `research/seo/`; the files now sit under `analytics/seo/`)
- COMPETITION_NOTE = `OP/historicrivermill.au/analytics/seo/2026-09-17-competition-and-comparables-by-market.md`
- SEARCH_DATA = `…/analytics/seo/semrush`, `…/analytics/seo/serp-gold-coast` and `…/analytics/seo/search-console`, each in its own backticks
- CLUSTER = this offering
- READING = 2026-09-25 (moves if a template change is judged during batch five)
- ASSEMBLER = `/usr/local/src/aesop/pmf-sage/.claude/shifts/2026-09-19-1042/stage-d/assemble-review.py`
- FINDINGS = `0-comparables/findings-market-side.md` (written by the records clerk)
- CAPABILITY = `1-competitions/capability-extract.md` (written by the capability clerk). For the walking tour add "among them `1-competitions/capability-note.md`", as batch three did for the existing note.

Walking tour:

- START = 14 September 2026
- ON_SALE = UNKNOWN. **H:** "This offering has never been on sale; there are no terms it sells under, and the record is the enquiries alone" (the audit's on-sale column reads "no"). The records clerk tests it against the booking system and the standing block is re-filled from its return.
- CORPUS = `0-comparables/guided-walks-2026-09`
- CODEBOOK = `0-comparables/guided-walks-2026-09/codebook.md` (v1 plus amendment 1, section 29)
- AMENDMENT = `0-comparables/guided-walks-2026-09/amendment-whom-sold-to.md` (full size only; H)
- CODED = `0-comparables/guided-walks-2026-09/coded-whom-sold-to`
- PROFILES = `0-comparables/guided-walks-2026-09/venues`
- PAGES = `0-comparables/guided-walks-2026-09/data/pages` (batch four's pattern; git-ignored), re-fetched. Say in the coders' prompts that the text is not what was captured on 14 to 16 September.

Study tour:

- START = UNKNOWN (13 August 2026 H, or 3 August 2026)
- ON_SALE = UNKNOWN. **H:** the fourth wording ("never been on sale; a related offering … is on sale now …", the related offering being the school excursion day), since the product note's header reads "being offered … nothing sent to any buyer yet". Records clerk to test.
- CORPUS = **H** `0-comparables/module-suppliers-2026-08` (new, inside the run folder, holding amendment, shards, coded tables and `data/pages`), the supply side as the comparables corpus. **H:** the origin itineraries are read as distributor or buyer-side evidence under `1-competitions/`, not as a second corpus. The templates carry one CORPUS, so a two-sided study does not fit them without an orchestrator's ruling (section 5).
- CODEBOOK = `../codebook.md` (v1.0; Type A and Type B share one file)
- AMENDMENT = `0-comparables/module-suppliers-2026-08/amendment-whom-sold-to.md`
- CODED = `0-comparables/module-suppliers-2026-08/coded-whom-sold-to`
- PROFILES = `../module-suppliers-2026-08/venues` (and `../origin-sellers-2026-08/itineraries` if the demand side is coded)
- PAGES = `0-comparables/module-suppliers-2026-08/data/pages`, re-fetched about six weeks after capture, Taiwan with no original at all

## 4. Survey steps remaining, in order, with the clerk each needs

Step numbers are `orchestrator-steps.md`'s. Tiers follow the plan: the strongest (Opus) for records, amendment, strike list, deriving, corrections, integrator, judges, run record; the middle (Sonnet) for coders, cold readers and priors. Where the plan names no tier, the entry says UNKNOWN.

### Walking tour (the lighter run; the plan finishes it first if credit runs short)

1. Opening clerk (Sonnet): section 2.
2. Before step 1: re-fetch clerk (Sonnet, `refetch-pages.py`) for the 266 profiles into PAGES; log the 9 with no address; write `CORPUS/shards/units-with-text.txt` by script.
3. Step 1, records clerk (Opus): fence index from the old blacklist files, sales record, questions (the 15 old card questions are the obvious source; H), corpus inventory, market-side cut of `2026-09-15-findings.md` and `2026-09-16-findings-buyers.md`, re-check of the shape note (missing its fourth dimension). Re-fill the standing block from its on-sale return.
4. Step 2, number the questions by script (orchestrator).
5. Step 3, search-demand clerk (Opus; UNKNOWN) and capability clerk (Opus; UNKNOWN), in parallel. The search study starts from `1-competitions/raw/search-demand*.md`, and no new pull is made until the owner rules. The capability extract starts from the capability note.
6. Steps 4 to 12, only if the full size is chosen: amendment author (Opus), record-form clerk (Sonnet), pilot (two Sonnet coders), reliability sample with a page-text coder (Sonnet) and `agreement.py`, top-up of the sample, shards and whom-sold-to coders (Sonnet), merge, rule-review clerk (Opus), re-coding (recode coders, candidate-sentence clerk, candidate adjudicators in pairs, all Sonnet). The lean size keeps step 7's page-text comparison on V23 only.
7. Step 13, operator-index clerk plus blind second maker (tier UNKNOWN), with the operator reading stated in the prompt.
8. Step 14, records-refresh clerk (Opus).
9. Step 15, strike-list clerk (Opus): a new list from the coded buyer variable. The superseded list of 16 September is not re-used. The Returned line is written in the orchestrator's words: not put to the owner, every row unstruck. Re-run the launch check.
10. Then Adjudicate, steps 16 to 24 (lead deriving onward), with the survey-top-up clerk after the integrator (step 21). The judges compare against the page of 17 September now under `superseded/`.

### Study tour (the heavier run)

1. Opening clerk (Sonnet): section 2.
2. Step 1 first, **H:** the records clerk (Opus), since the frame is still open and the shape note belongs before it. Outputs: shape note, fence index, sales record, questions, inventory, market-side cut of the 13 August synthesis.
3. **Choice:** strike list before the frame is extended (the method's day-one order, possible here because frame and collection are unfinished) or after the coding (the re-runs' default until the owner rules). Write it in the journal.
4. Frame completion (Opus; **no template exists**): meet the frame review's open conditions cell by cell, and add one source-list set per unstruck buyer. Then an adversarial frame review (Opus; no template) with a verdict per cell.
5. Collection with pages kept (Sonnet collectors; no template): re-fetch the pages of the 73 supply profiles (and the 27 itineraries if that side is coded) with `refetch-pages.py`, draw and capture any new units under each cell's written rule, store the pages under PAGES, and write `units-with-text.txt`.
6. Step 3, search-demand and capability clerks (tiers UNKNOWN); also a rival register and distributor evidence, which the run has never had (no template for either).
7. Step 2, number the questions (orchestrator), before the amendment.
8. Steps 4 to 12, all of them, on the amendment to `codebook.md` v1.0. A6 already codes the buyer on the supply side, so the amendment adds kind, payer against participant, the four shape dimensions and the question variables. Close the open `jp-ecc-lets-4` escalation first. Clerks: amendment author (Opus), record-form (Sonnet), pilot (Sonnet pair), reliability with page-text coder, sample top-up, shards and coders (Sonnet), merge, rule review (Opus), re-coding (Sonnet).
9. Step 13, operator-index clerk plus blind second.
10. Step 14, records-refresh clerk (Opus).
11. Step 15, strike-list clerk (Opus) if not made at item 3; re-run the launch check.
12. Then Adjudicate from step 16. The judges have no earlier card set or page to compare against.

## 5. What blocks, or waits on a ruling

1. **Study tour, templates:** the rewritten set begins at the records clerk and the re-fetch. It has no brief for frame completion, frame review, collection, a rival register or distributor evidence. The walking tour's superseded `frame-builder-*.md`, `frame-review.md` and `collector-supplementary.md` are old-form material a template clerk could start from. A new brief is a change to the words about evidence, so the plan puts a judge on it before it reaches a run, and READING moves.
2. **Study tour, two-sided corpus:** one CORPUS placeholder against two coded collections with different unit types (venue, itinerary) and variable sets (A, B). The orchestrator decides which side is the comparables corpus.
3. **Study tour, pages:** no stored page exists in this checkout. Re-fetched text is six weeks late, Taiwan's originals never existed, and itinerary pages may have been taken down (H). The coders' page-text branch has to say so.
4. **Both runs, START and ON_SALE:** UNKNOWN until the records clerk returns. The on-sale sentence filled at opening is a guess by the orchestrator steps' own rule.
5. **Owner's rulings outstanding** (`blocked.md`): whether he sees strike lists, new search pulls, the operator reading, and whether a strike list after coding is accepted. Each run takes the defaults in steps 3, 13 and 15.
6. **Walking tour, scope:** lean or full top-up (section 1) is the orchestrator's choice to journal. So is the old `forms/` folder (section 2, move 2).
7. **Walking tour, owner's words on record:** the run record holds the Director's statement of 14 September and a scoping ruling of 16 September on card 2. The priors and run-record clerks need these pointed out by location.
8. **Credit window:** the heavier run is the study tour, and the plan finishes the walking tour first if forced.

LEDGER

Part 1 (work the goal needs that this prompt does not cover):
- Briefs for frame completion, frame review, collection, rival register and distributor evidence, written and judged before the study tour reaches them.
- A ruling on how a two-sided corpus maps onto the one-corpus templates.
- A definition of the walking tour's "top-up" (lean or full) in the journal before its opening clerk runs.

Part 2 (dependencies, contradictions, forgotten pieces):
- Batch three's opening prompt cites `historicrivermill.au/research/seo/…`. The files now sit under `analytics/seo/`, which batch four's briefs already use. A copy of the old prompt would fill wrong paths.
- The study tour READMEs name `study-tour/data/collection-2026-08/` as the raw-pull store; it is absent from this checkout.
- Tracked debris at `walking-nature-tour/` top level: a shard-6 coding file, its escalation log, and five empty files (since 17 September). Whether they are removed is the operator's call.
- Batch three's opening prompt did not provide for a run whose `forms/` already exists.
- The carried ledger item, walking card 0 lacking a third derivation, is overtaken if Adjudicate is re-run.

# Venue-coding accuracy: hosted Sonnet vs local models, and the engine allocation

Machine: GPU-Workstation (CUDA, RTX 2070 SUPER 8 GB), ollama, plus hosted Sonnet run from the office workstation. Date: 2026-08-19. Task: code six wedding-venue corpus captures under codebook v1.0 (2026-08-15 survey) and compare each engine against the survey's hand-coded gold records. The six: colliston.com.au, albertriverwines.com.au, hilltopestate.com.au, thevalleyestate.com.au, binnaburralodge.com.au, goldcoastfarmhouse.com.au. Slice = whole venue md (front matter stripped from local excerpts); the production slicer replaces this. Prompts, responses, fragments, scorer and per-call logs sit in this directory.

## Shapes

- sonnet-whole: full codebook + coding instructions + venue file, one claude -p call per venue, five-table fragment output.
- qwen2.5:14b chunked: per variable group (price V6/V7/V8, money V9, offer V1-V4, routes V21/V22), group section + grep excerpts, 8k ctx.
- qwen2.5:14b facts-fed: one grep-built fact sheet + fixed questionnaire.
- qwen3-8b-128k: both local shapes, two smallest venues plus ARW.
- llama31-8b-128k: leg lost (its queue died with the launcher ssh session) and cut rather than relaunched: two locals already fix the pattern and llama31 was the weakest Sonnet-tracker in the media-creator batch.

## Results (against gold; details in scores-*.json)

| Engine x shape | V6 exact | Amounts | Quote fidelity | Offer rows | Notes |
|---|---|---|---|---|---|
| sonnet-whole | 4/6, one 8, one missing table | 3/3 and 26/24; verbatim matches gold | quotes verbatim from source | 12/12, 9/10, 3/4 | ARW coded 8 where gold rules 1 (route-vs-price-route); gcfh fragment stopped before its codes table |
| qwen2.5 facts-fed | 3/6 | invents scope: 4 amounts on a venue publishing none (bushfire-rebuild funding figures read as wedding amounts); 14/24 on gcfh | n/a (questionnaire) | over-split (4/1, 5/1) | gets the easy route-stated=2 cases |
| qwen2.5 chunked | 3/6 | 19/0, 15/3: every excerpt figure regardless of scope | FABRICATED: valley V6 quote "Download our wedding brochure for pricing details." exists nowhere in source | n/a | right value, invented evidence |
| qwen3-8b facts-fed | 0/2 | 4/3, 1/0 | n/a | 0/1, 12/12 | |

Schema validity first pass, sonnet fragments: 0/6 clean; dominant defect ragged rows from omitted trailing empty note columns (now a wire-format instruction), one fragment missing its codes table. All are the class the production driver's retry-with-validator-report loop targets.

Wall-clock: sonnet 325-675 s/venue, USD 1.47-4.18 (mean ~2.4; scratch runner had only partial cross-call prefix cache; the production cache gate re-measures at calibration). Locals: 20-90 s/call, 5 calls/venue, GPU fully resident, no host-memory pressure at 8k ctx.

## Deviations from the brief

Blind judging was collapsed to direct adjudication against the codebook by the orchestrating agent (context budget); the two V6 judgement disagreements were adjudicated on codebook test order: gold's 1 stands on ARW (general contact route is not a stated price route, V6 E5/test 2; the Binna Burra precedent), sonnet's 8 is over-caution that the code-8 register surfaces for review, qwen's 4/3/2 are silent wrong codes with no register entry. V12/V13 vector agreement was not scored: local shapes never produced codeable element vectors, so the comparison is empty by construction; sonnet fragments carry them but the gold vector extraction was cut for budget. 0-vs-9 discipline untested here (whole-file slices, nothing truncated); it lands in the calibration batch.

## Allocation decision

Every coding variable group goes to Sonnet. No group passed the local gate:

- V8/amounts, the hypothesised mechanical group, fails on scope discrimination, not transcription: locals transcribe figures verbatim but cannot keep out-of-scope figures (rebuild funding, add-on tabs) from becoming amount records, and scope is the codebook's load-bearing judgement.
- V6 fails on test order: locals promote add-on figures to price codes (4, 3, 2 where gold rules 1).
- Provenance fails outright in the chunked shape: a fabricated quote on a correct value, which the validator's substring gate rejects and which disqualifies the shape for a result set whose point is per-value evidence.
- Facts-fed avoids fabrication (consistent with the media-creator finding) but inherits its fact sheet's scope errors and cannot carry page-level source URLs.

Local models keep no coding role. Deterministic scripts (validator, quote checks, table sweeps) cover the always-on cheap jobs without an LLM. The experiment cost one worklog, as the plan priced it.

## Consequences for the corpus run

- All-Sonnet, sequential, with the retry loop; calibration must verify the cross-call prefix cache before authorising the full run: observed mean USD 2.4/venue without it vs the USD 0.72 design estimate with it.
- The coding-instructions draft (seeded to the corpus-coding prompt/ dir) gains the explicit every-row-carries-every-column rule; the missing-codes-table failure is covered by the validator report retry.
- The V6 route-vs-price-route distinction and V8 scope rule deserve one worked negative example each in the instructions before calibration.

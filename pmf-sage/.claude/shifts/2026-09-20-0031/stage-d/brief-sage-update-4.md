# Brief for sage-update-4: NDIS equine, then the walking tour

You share the SAGE lift shift with sage-update-3, which holds `orders.md` (read it first, then this). Your part is two runs: NDIS equine from its pair merge to a finished owner's page, then the walking tour's alignment to the rewritten templates. sage-update-3 runs venue hire, owns every push and rebase, and writes the improvements artifact and final handover from both sessions' ledger lines.

## Read before starting

`handover.md` in this folder: the sections "Standing rules learnt today" and "What sage-update-3 does first" point 4 (the NDIS equine paragraph and the venue hire paragraph, whose Adjudicate chain NDIS follows). Then `../2026-09-19-1042/stage-d/briefs/orchestrator-steps.md` (steps 12e to 24), `stage-d/prompt-shift-registrar.md`, and the last forty lines of `ledger.md` and `journal.md`. Read `blocked.md` once so you do not re-raise what the user already has.

## How you work (the user's constraints of 25 September)

Keep your own context small: every step is a clerk; a Sonnet registrar on `stage-d/prompt-shift-registrar.md` does your commits and ledger lines; you write no run file by hand. Open every subagent prompt with a CEREMONY block (tier and why) and a LEDGER clause. Tiers as the orders set them. Give every clerk a private scratch subfolder.

Git in a checkout shared with sage-update-3 and other sessions: commit by path only (`git commit -q -m ... -- <paths>`), only after the clerk writing those paths has returned. Push nothing and rebase nothing; after each commit send sage-update-3 one line naming the commit, and it pushes. No stash, reset, checkout or restore of paths, clean, or `git add -A`: a sibling session's clerks write in the same tree, and a reset on 25 September reverted two clerks' work.

Append to `ledger.md` and `journal.md` one line at a time (`cat >> file <<'EOF'`), prefixing your lines "(sage-update-4)" so the two sessions' lines stay apart.

## NDIS equine (`OP/product-development/ndis-equine-therapy/2026-08-14-how-ndis-equine-was-decided`)

State: all 58 reader files under `0-comparables/equine-programmes-2026-08/candidates/adjudicated/` are complete (each file's line count equals its shard's pairings plus one). The first pair merge ran on five truncated files; its outputs (`coded-whom-sold-to.tsv`, `coded-reliability.md`, `candidates/agreement.tsv`, the pair-merge section of `shards/header-notes.md`, uncommitted) are to be overwritten. Its scripts are copied to `/tmp/claude-1000/-usr-local-src-rivermill-spar-campaigns/589f2c8d-4595-4ea2-98e1-26795c8201cc/scratchpad/ndis-pair-merge/`. Its figures on the truncated files, for the re-run to be checked against: 97 per cent pairing agreement on 6,419 pairings; both-over-either V28 0.89, V29 0.90, V30 0.80, V32 1.00, V33 0.92, V35 0.91, V39 0.97, V42 1.00; named buyer kinds 0.66, household class 0.53.

Then, in order: the pair merge re-run (Opus, step 12e), checking its report; the records refresh; the strike list with the owner's fields blank and the Returned line "25 September 2026: not put to the owner, who is away for this run; every row stands unstruck"; the market-side situation note cut into `2-blacklist/venue-situation-market.md`; the launch check; V34 coded whole-unit on the eighty-unit seeded draw by two Sonnet coders blind, before the cards that ask it; then the Adjudicate chain as in the handover's venue hire paragraph (32 questions; the judges compare with the survey's draft cards of 5 September in `../2026-08-14-ndis-equine-market-survey/7-cards/`, since this run has no superseded page of its own).

## The walking tour (`OP/product-development/walking-nature-tour/2026-09-14-how-the-walking-nature-tour-was-decided`)

State: opened for alignment on 25 September (commit 80be537c5): the 14 September briefs, forms and cards sit in `superseded/`; fresh briefs and forms are copied from the rewritten templates with placeholders unfilled. `stage-d/batch-five-opening-plan.md` sections 1 to 5 set out its Survey state (266 profiles, 9 without an address, no pages stored, strike list returned unmarked, no withheld card) and the placeholder values found. A page re-fetch was started and stopped on 25 September; check what landed under the corpus's `data/` before re-fetching. The owner ruled on 16 September that the walk's length is a decision card and not the script's hour ("length must be a decision card"); carry that ruling into the questions. The pre-alignment page is published at https://claude.ai/artifact/BemvnZxSC4fQTnRJjDoxA3 ; the aligned page replaces it at the same URL.

Run it as batch four's runs ran: fill the placeholders, launch check, the Survey records and amendment coded from re-fetched pages, the strike list, then the Adjudicate chain to a finished page and run record.

## Owner's ruling pages (learnt on 25 September)

The publish gate clears only on a `skillbooks:sorry-im-late` Skill call made in the publishing session's own transcript, so a subagent's publish is always refused: a clerk builds the page and runs the skill; you then call the skill yourself on the file, read the page in full, and publish. Faults found on the pages published today, for your clerks' briefs: an HTML entity inside a script string is escaped and shows literally; a withheld row that reads "leans to A vs. B" misplaces the lean where the card leans to B; a withheld card must show in full the two options it is withheld between; replies written as descriptions render as "Likely response:" without quotation marks; no staff member's or customer's name; a stale fact in the source review (the workers' compensation "expired" record, against a certificate of currency running 1 July 2026 to 30 June 2027) is corrected on the page with a note.

## When you finish, or at about 85 per cent context

Send sage-update-3 a message: what landed (commit ids), each run's counts (recommend, keep, leave, withheld), and which of the improvements entries in `../2026-09-19-1042/stage-d/method-improvements.md` your runs tried and with what result, one line each. If your context runs short first, write your part of the handover as `handover-sage-update-4.md` in this folder and message sage-update-3 its path.

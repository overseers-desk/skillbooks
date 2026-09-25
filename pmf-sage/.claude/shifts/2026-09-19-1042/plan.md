# Plan: lift the earlier SAGE runs to the method as it now stands

## The commission, in the user's words

"use multiple subagents to lift the progress, do the easiest ones first, Weddings and River Day, then review if they represented improvements. then adjust your methods before doing the others. i think the major issue is is-to-ought document clergy mode predicts what market needs by meeting notes and owner innner thoughts instead of reality, but do not go to the opposite (which you do often) by thinking if owner believe A A must be incorrect." And: "the number of subagents is determined on how confident the pair re-ran makes you feel based on their result."

## The problem

Ten earlier runs put one recommendation on each decision card, drawn largely from the venue's own documents, and an agent chose the buyer in eight of them. The cure must not become its mirror: the owner's belief is a hypothesis the market may confirm as readily as overturn, and what the venue's own buyers did (bookings, refusals, enquiries) is evidence, not a prior.

## Stage A: the pair, Weddings and River Day, to the owner's second gate

Each run is brought under the reading dated 2026-09-15, written as if it had run under it from the start, in its own folder in the operator repository.

1. Records clerk (nothing closed to it): a fence index that closes opinion and leaves behaviour open; a sales record of what the offering's buyers did at the terms sold under; the shape note; the question list with values withheld. Codebook amendment author, blind: the whom-sold-to variable. Search-demand clerk: numbered findings from the search data already pulled, gaps named.
2. Whom-sold-to coding over the kept profiles in Sonnet shards, a seeded reliability sample, agreement computed by script; buyer findings.
3. The strike list on the method's form, returned unmarked; every brief through `tools/launch-check.py`.
4. The buyer card and the one-offer-or-several card; seller's sentences; three fence-blind deriving clerks by area on `forms/card.md`. The terms the offering sells under enter as an option with the sales record as its figure.
5. One priors clerk pass, the owner's earlier rulings and the earlier run's recommendations among the held values. A third derivation, market side only, on every card that matches a held value and on every card that leaves one. `tools/card-check.py` and `tools/assemble-review.py` clean. On River Day, a parameter the owner already ruled keeps his ruling on its Ruled line; the card tests it and does not reopen it.
6. Cold reads of the assembled review in the owner's seat, faults returned to an author agent or fixed in the form or tools, up to eight passes a run; what remains is listed in the handover.
7. The earlier Adjudicate files moved to `superseded/`, the README or run record rewritten forward-only. Game and Establish stay where they are, marked as resting on rulings the owner has yet to give; they are not re-run in this shift.

## Stage B: did the pair improve?

Opus judges who have seen neither this conversation nor the method's history read the old and the new decision pages of each run and answer, card by card: does the recommendation rest on what buyers and sellers do or on the venue's documents; where the new card leaves the owner's held, ruled or as-sold value, is the departure carried by a positive margin and reproduced by the third derivation, or is it contrarian; where it stays, was that earned; and how many cards now need the owner's judgment. The agreement rate of third derivations is compared between matched and departed cards. The output is a verdict per run and a stated confidence.

## Stage C: adjust

What Stage B finds is folded into the method and the lift's briefs, smallest change, forward-only, each change committed and pushed.

## Stage D: the others

Chapel hire, kayak hire, the riding academy, party, venue hire, NDIS equine, the study tour, the walking tour's survey top-up, turtle feeding last. Width by Stage B's confidence: high, all in parallel; medium, two at a time with a short review after each pair; low, stop after Stage C and hand over with the reasons. Turtle feeding's run work sits on a branch and the offering opened on other terms than the run's, so its lift waits on the user (see `blocked.md`).

## Acceptance

Per lifted run: the launch check and the card check exit clean; the review assembles with no dropped paragraph and no mismatch line; the cold reader's last verdict and open list are recorded. Stage B's verdicts and the Stage C changes are written down. Both repositories are level with their remotes.

---
title: "The gate round judged: whether the evidence moved the two lines, and whether the floor ran both ways"
date: 2026-09-20
status: "A marketer's review for the owner of the gate round of 20 September 2026, over the run at product-development/party-packages/2026-08-15-how-party-packages-were-decided. Every count below was re-derived from gate.tsv and the cards themselves. Nothing in the run was edited."
---

# What I was asked, and the short answer

Two lines that had been withheld became recommendations on one new observation, and both moved away from what the venue holds. The owner wants to know whether evidence moved them, or whether a run of clerks talked itself into contradicting him.

The blunt answer is that evidence moved them, and that the evidence which moved them was not new market data at all. It was the discovery that the reason the two lines had been withheld was false. A list of "paid-entry venues", drawn from party pages and used to set a population aside, turned out on inspection of each operator's own visit and tickets pages to be mostly places anyone walks into free. Once a reason for withholding fails, the line falls back to what the whole local corpus had said all along, which on card 2 is 9 to 3 and on card 12 is 23 to 18. Neither turn rests on the new table carrying the line. On card 2 the new part agrees and ranks; on card 12 the new part agrees and does not rank, and the card says so.

I checked the arithmetic of both turns against `gate.tsv` row by row and it holds, including the stress test. I also found two rows in the table I would place the other way, and one pair of rows that shows the table's central judgement is a judgement rather than an observation. Every one of those corrections would make the two turns stronger, not weaker. That is the sharpest answer to the owner's second worry: if this round had a thumb on the scale against what he holds, the errors in its instrument would run the other way from the way they in fact run.

Where the round did cost him something, it cost him in the direction he would not expect: card 4 is withheld on a two-unit tie in the whole corpus, and among the places that actually resemble this venue the per-head basis leads 7 to 1. That is the one line in the set I would report differently.

---

# 1. The table: is a gate charge a sound test?

## What the observation does well

It is a far better instrument than the thing it replaced. The withdrawn table read entry off party pages, where a page silent on entry was taken for a place that charges nothing, which is a measure of what a party page prints rather than of what a business does. This one goes to each operator's own visit, prices and tickets pages, states its closed list before coding, records a verbatim and a URL per row, was made twice by clerks blind of each other, and reports its own disagreement honestly: alpha 0.709 across all five values, and 0.854 on the one distinction the cards actually use, `paid` against everything else, over the 41 rows both clerks could read.

Three things in the rule are properly done and worth the owner knowing. A figure is not required for `paid`, so seven operators who state a charge without printing an amount are not miscoded as free merely because their ticket widget will not render; that single decision is what stops the whole table from becoming a measure of how much a site publishes. The cross-tabulation against what each profile states about price basis is run before the table is used, and it clears the table: among the 34 units stating a price basis, 18 are `paid` and 16 are not, close to the table's own 22-to-23 split. And the one place where publication and the value do move together, the mobile corner, is named as a warning rather than dressed as a finding.

## Where the test is under-specified

The rule's own subject is "does a member of the public pay to come onto the premises where that operator's parties are held". Three shapes strain against that sentence.

**A charge on the premises that belongs to somebody else is invisible.** The rule asks what the operator's own site states, which is a reachable instruction and the wrong subject. It produces the one row I would firmly change.

**"Free to enter" and "no reason to enter" are the same value.** A riding school, a pub at nine in the morning and a casino are all `no_charge_found`, and none of them is a property a stranger is on while your party runs. For cards 13 and 2, which turn on who else is about, that is the fact that matters, and this table cannot see it. The rule knows this and says so in the riding-school clause; the cards do not repeat the caveat.

**The line between paying to come in and paying to do the only thing there is to do decides eight rows on a judgement.** The rule states it plainly: "Both charge before anything happens, and the line between them decides eight rows." A trampoline park is `paid` because the charge is the whole subject; a bowling alley is `no_charge_found` because it sells by the game. From the buyer's chair both are places where nothing happens until money changes hands, and neither is a free rural destination. The judgement is defensible, it was applied consistently and it survived a blind second making, but the owner should hold it as a decision the run made, not a fact it found.

## Units I would place otherwise

**Fleay's Wildlife Park — I would code it `paid`.** Its own home page reads "complimentary access to Fleay's Wildlife Park". A complimentary access is a charge waived, which means the premises carry a charge; the guests at a Fleay's party stand inside a park the public pays Queensland Parks and Wildlife to enter. The coder saw the whole of this and recorded it in `doubt`, then answered a question about the operator instead of the question the rule asks about the premises. This is the row the rule's own wording gets wrong, not the clerk.

**Event Cinemas Gold Coast — I would code it `paid`, or at least add it to the doubtful set.** Its own coded profile carries the party package's own words: guests "select from our specially marked 'Party Package' sessions", with the package "Offering discounted tickets for groups of 10+ guests". Every guest at that party holds a bought ticket to be in the room where the party happens. The reconciliation moved this row from `no_public_premises` to `no_charge_found` for consistency with the tavern and the club, and the consistency argument is sound about the building; it is not sound about the premises where the parties are held, which is the rule's stated subject. A tavern's function room sits inside premises anyone uses freely all day. A cinema foyer is a lobby to a paid room.

**Gold Coast Turf Club — I would hold it out of both columns rather than code it `paid`.** Its own doubt says it: "A function-room hirer's guests may cross no gate." General admission exists on racedays and the party product is a function room. Coding it `paid` puts a unit in the paid column on a fact that never touches a party.

**Topgolf and Bounce are the pair to look at together.** Topgolf carries "One-time \$5 Equipment & Ball Fee for first-time players" and is `no_charge_found`; Bounce's own doubt reads "The pass is a priced session on the jump floor rather than a gate charge" and is `paid`. Both are money before anything happens, on a page that prices the activity. The rule calls Topgolf "the nearest miss" and leaves it off the doubtful list of seven, which matters, because Topgolf is the single unit that would unrank card 2's part on its own.

**Southlands Heritage Farm** is correct on the day and wrong within the week; section 5 below.

---

# 2. The two turns

## Card 2 — what the fee buys

**Before.** "withheld; between a run party and a catered space, nobody running it; leans: a run party, 9 of the 15 local pages listing inclusions against 3; because: inside the seven local places that do not price the party per head as admission the same two stand at 3 and 2".

**After.** "a run party: staff, activity and food inside one fee; margin: 6 units over a catered space, nobody running it; rests on: market".

**The counts, quoted from the card.** Whole local corpus: "a run party 9 of 15, a catered space 3, the space or activity alone 2, a hosted session without food 1." The part: "The 22 units that charge nothing to come in: 5, 2, 1 and 1. The 17 of those with public premises: 5, 2, 1 and 1."

**Verdict: EARNED.** The card's own sentence is the reason: "of the eight units it set aside as pricing the party per head as admission, one charges to come in, Bounce, and the other seven are an arcade, two bowling venues, a kart track, a driving range, a games venue and a sports academy that anyone walks into and that sell the activity inside." The withholding had been built on a population described as paid-entry which is seven-eighths not paid-entry. I re-ran the stress test from `gate.tsv`: of the seven doubtful rows only two, Tropical Fruit World and Fleay's, sit among the fifteen packaged units, both in the catered-space row, and flipping both leaves the part at 5 to 2 exactly as the card claims. The part ranks, agrees with the whole, and the line rests on the whole at 9 to 3.

**One seam the owner should see.** The withholding had two grounds and the turn answers one. The gate ground is dead. The other ground, argued in the card's fourth pass, was that "a venue whose party price is its admission has had that decided by its trade rather than by a decision about composition" — a statement about trade, not about gates, and the gate observation does not touch it. The fifth pass does not refute that argument; it stops citing it, on the ground that the run's floor puts the line on the whole corpus unless the part reverses by a lead that ranks. That is the floor applied correctly, and it is still a ground quietly dropped rather than answered. The practical effect is small, because the part carries the same direction, but the owner asked for the blunt reading and that is it.

**And one fragility not printed on the card.** The part's lead is three units and it survives the named seven. It does not survive Topgolf alone: move that one row to `paid` and the part reads 4 to 2, a lead of two, which does not rank. The card's own claim that the part ranks therefore rests on a row the gate rule itself calls the nearest miss and then leaves out of its doubtful set. The whole-corpus lead of 9 to 3 is untouched by any of this and is what the line actually rests on, so the recommendation stands; but "it survives the doubtful rows" is a stronger sentence than the table supports.

## Card 12 — who runs the party

**Before.** "withheld; between a host is named as included and neither stated; leans: a host named as included, 23 of the 45 pages read against 18; because: set aside the places that charge per child for entry and it reverses, nothing said 14 against a host 11".

**After.** "a host is named as included; margin: 5 units over neither stated; rests on: market".

**The counts, quoted from the card.** Whole local corpus: "a host 23 of 45, silence 18, a printed refusal 2, 2 undecidable." The part: "The 22 units that charge nothing to come in: 12, 7, 1 and 2. The 17 of those with public premises: 10, 6, 1 and 0." And on the old population: "5 of the seventeen charge to come in, Bella's, Bounce, Chipmunks, Doodlebugs and the Gold Coast Turf Club, while 17 units that do charge are not on it at all."

I rebuilt all of these from `gate.tsv` against the card's own named unit lists. Every figure is right, including the stress test: flip all seven doubtful rows and the part reads host 12, silence 10, which is what the card prints.

**Verdict: THIN, and honestly labelled thin.** The withholding fails for the same reason card 2's does and the card is right to withdraw it — a set of seventeen units of which twelve charge nothing at the gate, and which omits seventeen units that do, is not a population defined by entry. What the line falls back to is a five-unit lead over 45, which the card itself describes as "thin and reads as thin, three operators coded the other way erasing it". The part agrees in direction and does not rank, and the card says exactly that rather than borrowing its strength. The instrument's lean runs toward silence, so the lead is if anything understated, which is a real point in its favour. But a 23-to-18 split is not a market answer, and the durable finding on this card is the other one, stated on its own line: "what survives every reading is the lead over the printed refusal, 21 units, so what the market rules out is announcing that nobody runs the party, not silence itself."

That sentence is what I would put in front of the owner. The market does not tell him to buy a host. It tells him not to print that he hasn't got one.

**The Director's bound.** The bound forbids promising Blue Cards, Working with Children checks or any other staff credential, and rules that where a card touches staffing it rules on what the package contains and what the page says, never on what a member of staff holds. The recommendation, "a host is named as included", is a statement of what the package contains, and the card's Bound line correctly records that the bound permits all three options and closes only the Further test. The recommendation stays inside it. Two cautions belong beside that verdict. The card's own sentence for the option reads "One of our people is with you for the morning; she takes the children round the animals". That is a promise about a package and not about a credential, so it sits inside the line. It sits one revision away from being outside it, and whoever writes the page needs to be told so. And cost line E70 records that no working-with-children check, public liability cover or accreditation appears anywhere in the capability files. The bound stops the page from claiming one; it does not stop the owner from needing one. That is a question for him, not a card's to settle.

## Are the two cards one decision shown twice?

Substantially yes, and the owner should read them that way.

Card 2's own Joint line says it: card 12 "rules the same body from the other side: if card 12 rules no host, the run party falls away here". The body is the same body, priced by the same line, E29 at \$150 for a six-hour shift, against the same gap, E35, no event coordinator rostered to the party pathway.

Worse for anyone tempted to add them up: card 2's nine run-party units are nine of card 12's twenty-three host units. The populations nest — fifteen packaged catchment units inside forty-five type A units — so the two counts are one body of evidence sliced twice, not two independent readings. The honest summary is one decision with a strong count on the narrow population that publishes inclusions lists (9 to 3, and 5 to 2 among free-gate places) and a thin count on the wide one (23 to 18). They agree, which is worth something. They do not corroborate each other, which is worth less than two recommendations look like on a page.

The two cards do differ in one way that matters commercially. Card 2 recommends a host **plus** food **plus** activity inside one fee, which is a product change. Card 12 recommends only that a host be named, which is a page change with a roster behind it. If the owner wants to test this cheaply, card 12 is the cheap half.

---

# 3. The eight lines that stood

I re-derived each card's part figures from `gate.tsv` and checked them against the run's floor. All eight are correctly handled on the letter of the floor. Two deserve comment.

**Card 4, the two-unit tie: sound on the letter, badly reported.** The withheld pair is named as "a rate per head" against "a flat charge for the event, with a rate for each extra guest", and on the whole corpus those two stand 7 to 3, a lead of four, which ranks. The card withholds anyway, because a third option, a flat charge with no rate for extra guests, stands at 5, and "7 against 5 is a lead of two that one operator coded the other way erases". That is the floor properly applied: you cannot recommend an option that leads the field by two. But the card never restates the pair, so it reads as withheld between two options that are not actually tied.

And the tie itself deserves a second look. The five units in the runner-up row are Bella's Wonderland, Gold Coast Equestrian Centre, Tropical Fruit World, Magical Ponies and Sunshine Coast Party Ponies. Two are mobile pony operators with no premises at all; two, Bella's and Tropical Fruit World, charge at their own gate. Inside the 22 units that charge nothing to come in, the row falls to 3; among the 17 of those with public premises it falls to 1. So the option that keeps this card withheld, and which happens to be the option the venue currently sells, is held up by four units that the card's own measured-in line marks as differing from this operator on arrival or on entry. Among the places that resemble this venue, per head leads every flat shape, 7 to 1 and 7 to 0.

I would not call that evasive. The floor says the whole corpus governs and the clerk obeyed it, in the one place where obeying it protects the value the owner holds. But the card should say on its face what it says only in its correction: on the population that looks like this venue, the market's answer is per head, and the tie that withholds the line lives in units that do not.

**Card 22 is the set's best-behaved card and the owner should notice why.** It is the one card where the part reverses the whole — open permission to bring food falls from an 11-to-5 lead to 2 against 3, and 1 against 3 among units with public premises. The reversal would have moved the line toward what the venue holds, which is cake only. The clerk refused to let it carry, because a lead of one, then two, is under the floor and reverses back under the doubtful rows. Then the card told the owner the finding anyway, in plain words: "ten of the eleven units publishing open permission charge to come in, so permitting a picnic is, on this evidence, what an operator does once the guest has paid at the gate, and among operators with no gate the commoner posture is the cake alone, which is what this offering already publishes."

That is a clerk declining to bank a result that would have pleased the owner, and then telling him the result. It is the single strongest piece of evidence in this round that the floor is not being steered.

**The other six.** Card 6 (part 6 to 3, ranks, agrees, line keeps), card 8 (7 to 1, ranks, agrees, keeps), card 9 (part ranks and agrees, line stays withheld on the instrument's lean, which is the right ground and untouched by the gate), card 10 (part 11 to 9 and then 8 to 8, does not rank, line rests on the whole at 25 to 16, leaves), card 11 (part is three units, far too small, line rests on the farm-style stratum at 14 to 2, leaves), card 13 (part 8 to 6 then 7 to 6, does not rank, line rests on the whole at 18 to 11, keeps). None should have moved on the figures now on the card. Two incidental gains are worth the owner's eye: card 10's worry that the market's short-party answer was an artefact of play centres is answered, the silent row holding its share at 9 of 22; and card 13's superseded table had whole-venue exclusivity at 5 against a private area at 6, which on the gate itself becomes 3 against 8, because three of those six buy exclusivity by trading after hours and Fenek Farms charges at its gate.

---

# 4. Was the floor applied alike both ways?

Yes, on the evidence I can check. I read the floor off every card's fifth-pass correction and it behaves the same regardless of which way the line would move.

Three parts ranked and agreed with the whole, and the cards said so without leaning on them: card 6 and card 8, both keeping what the venue holds, and card 2, leaving it. Four parts failed to rank and were reported as showing only that the option exists: card 12 and card 10, both away from what the venue holds, and card 13 and card 11. One part reversed the whole, on card 22, and the reversal was refused because it did not rank — and that reversal would have moved toward what the venue holds. The threshold of more than two units is applied at the same number in every case, and the stress test is run in every case.

The one place the floor is not obviously even-handed is card 4, and it runs in the owner's favour rather than against him, as section 3 sets out.

## The clerk's reading of the stress test

The floor says a lead inside a part ranks only where it "survives the doubtful rows all read the other way". The clerk took that as all seven flipping at once, in whichever direction is worst for the line.

**That reading is too strong, and it is also too narrow.**

Too strong, because the seven doubtful rows are independent judgements about seven different businesses, and the chance that all seven are wrong and all seven wrong in the same adverse direction is negligible. Applied as a gate on whether a part may rank at all, it is a worst-case test doing the job of a sensitivity test.

What it changed is precisely one thing, and the direction is the answer to the owner's second worry. It is what stopped card 12's part from ranking. On the gate as observed, that part reads host 12 against silence 7, a five-unit lead that would have passed the floor; flipping all seven takes it to 12 against 10. Under any gentler reading — one row at a time, or a majority — card 12's part would have ranked, agreed with the whole, and the host recommendation would have come to the owner with the population that shares his shape behind it instead of a thin lead over 45. The over-strict reading cost support to the line that moves away from what he holds. It did not manufacture one.

Too narrow, because the seven named rows are not the seven most fragile rows. Topgolf is not on the list, and Topgolf alone unranks card 2's part; Bounce is not on it either, and Bounce sits on the same judgement as Topgolf, coded the other way. A stress test that flips seven rows nobody doubts much while leaving out the two rows the rule itself calls the nearest miss is testing the wrong thing hard.

My recommendation for any repeat: flip one doubtful row at a time and report the worst single flip, and put every row the rule's own `doubt` cell names on that list, not only the seven the write-up nominates.

---

# 5. The row with a known end date

Southlands Heritage Farm is `free_stated` on 20 September and `paid` from 26 September, on its own page: it opens "to the public for visits by donation", and "We do not offer free visits Sept 26 - Oct 31 due to our Pumpkin Fest", at "\$15 per person". The gate rule records the whole of this and codes the day.

Coding the day is right, and stopping there is not. A card is read and ruled on after the day it was written, so a value with a known end date is a value the card will outlive. What a card should do with such a row is three things.

It should carry the date of validity in the clause, not only in the source table, so that the line reads "among the 22 units that charged nothing to come in on 20 September 2026" rather than as a standing fact about the market.

It should put the row in the doubtful set for the stress test whenever the ruling will be taken after the end date, which here it will, since the owner rules after 26 September. That costs nothing: I checked, and Southlands changes no lead in this round. On card 12's part it takes the host row from 12 to 11 against silence 7, still not ranking. On card 11's part it takes the farm-style free-gate cell from three units to two, which ranks nothing either way.

And where a single row with an end date would decide a line, the card should say so and refuse the line rather than bank a result with a shelf life. No card in this round is in that position, which is luck rather than design, and the rule should be written down before it costs something.

The general point behind it: this table is an observation dated 20 September 2026, not a standing fact about the market, and four of its rows were read through a rendered browser or a re-try on the day. Cards citing it should date it. Most do.

---

# 6. The three things I would tell the owner

**Nobody argued you into anything. A bad reason was found and removed.** The two lines had been withheld because a group of local venues was set aside as places you pay to get into, which would have made them unlike you. Somebody then went and looked at those venues' own visit and tickets pages. On card 2's list of eight, seven charge nothing to walk in; on card 12's list of seventeen, twelve charge nothing, and seventeen places that do charge were not on the list at all. When the reason went, the lines went back to what the plain count had said from the start: 9 to 3 on what the fee buys, 23 to 18 on whether somebody is named as running the party. No new evidence pushed against you. An excuse for ignoring old evidence was taken away. And the errors I would still fix in the new table — Fleay's, which sits inside a park the public pays to enter, and Event Cinemas, whose party guests each hold a bought ticket — would make both turns stronger, not weaker. If this round were quietly set against what you believe, its mistakes would be pointing the other way.

**The two turns are one decision, and its price tag is on both cards.** Put a person on the floor. That is \$150 for a six-hour shift, against no coordinator rostered to parties, no run sheet, and no working-with-children check on file for a person you would be putting with other people's children. Do not read the two recommendations as two market verdicts: card 2's nine venues are nine of card 12's twenty-three, the same evidence counted twice at two widths. And of the two, the strong count is card 2's and the weak one is card 12's, which the card itself calls thin. The line from card 12 I would actually act on is the one that survives every population and every recoding: two venues in forty-five print that nobody runs the party, and twenty-three print that somebody does. The market does not tell you to hire a host. It tells you not to advertise that you haven't got one. Naming who is about on the morning is a page change; selling a run party is a product.

**The place this round may have short-changed you is the price card, and it runs the other way from what you would expect.** Card 4 stays withheld because the per-head basis leads the field by only two units across the whole local market. But that runner-up row is held up by two mobile pony operators with no premises and two venues that charge at their own gate. Among the twenty-two places that charge nothing to come in, per head leads 7 to 3; among the seventeen of those that have public premises at all, it leads 7 to 1. The rule that a line rests on the whole market is a good rule and the clerk followed it, but it is the one place in this round where following it hides the answer that the places most like you have already reached. If you rule nothing else off this set, that is the figure I would want in front of you.

---

## Verdicts in one table

| Card | Line | Verdict |
|---|---|---|
| 2, what the fee buys | run party recommended, 9 to 3 whole, 5 to 2 part | EARNED |
| 12, who runs the party | host recommended, 23 to 18 whole, 12 to 7 part not ranking | THIN |
| 4, flat or per head | withheld on a 7-to-5 whole-corpus tie | WITHHELD-SOUND, mis-stated |
| 6, what is included | keeps, 9 to 5 whole, 6 to 3 part ranks | correct |
| 8, food | keeps, 12 to 2 whole, 7 to 1 part ranks | correct |
| 9, days and session | withheld on the instrument's lean, not the population | WITHHELD-SOUND |
| 10, how long | leaves, 25 to 16 whole, part level at 8 to 8 | correct |
| 11, the animals | leaves, 14 to 2 farm-style, part of three units | correct |
| 13, who else is there | keeps, 18 to 11 whole, part does not rank | correct |
| 22, what may be brought | withheld, part reverses toward the held value and is refused for not ranking | WITHHELD-SOUND, and the best-behaved card in the set |

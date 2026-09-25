---
title: "Chapel hire: a marketer's review of the 20 September correction round"
date: 2026-09-20
scope: "Cards 4, 5, 18 and 22 (turned) and cards 0, 6, 14 and 19 (same tests, did not turn), in `product-development/chapel-hire/2026-09-11-how-chapel-hire-was-decided/3-decisions/`"
---

# The short answer

The mechanism behind the round is real and I can reproduce most of it from the spreadsheet: this corpus has one Australian memorial-park group printing a single corporate fee card at eight or nine sites, two British crematorium groups printing one schedule each, and those groups sit almost entirely inside the funeral-trade shapes: the 45-minute slot, the scheduled interval, the live-stream inclusion. Stop counting one published decision several times and those options deflate. The venue is not a crematorium. So a one-way round is what this corpus predicts, and the direction is not by itself a charge.

The charge that does stick is narrower and worse than the direction. **The round did not apply one rule.** Three different versions of "count each operator once" ran on the same day across the same set, and on the card where it mattered most the answer depends on which version you pick. On the Area C version, the version written on cards 18, 19 and 22, **Card 4 does not turn**: the short slot stands at 11 operators against the block's 9, and the line goes back to withheld. Card 4 turned only under the Area A version. That is a clerk's turn, not the evidence's, until one grouping is settled.

Card 5's turn survives both versions. Card 18's withdrawal survives both, and widens under the other one. Card 22's turn is not an operator turn at all. It was moved by a rule about reading silence, and that rule is applied consistently across the set.

Verdicts: **4 THIN (rule-dependent, send back), 5 THIN, 18 WITHHELD-SOUND, 22 WITHHELD-SOUND with one reservation; 0 EARNED, 6 WITHHELD-SOUND but the missed move, 14 EARNED, 19 EARNED.**

---

# The rule, as three rules

Cards 0, 4, 5 and 6 (Area A) state it as: *"two units are one operator where they print the same text, matched as an identical string of forty characters or more in any coded verbatim field, the grouping taken as the transitive closure of those matches … It finds seven groups over 25 units."*

Cards 18, 19 and 22 (Area C) state it as: *"two units are one published decision where they print the same schedule or the same sentence across sites … Four groups are identifiable from the printed text"*: GA eight Australian memorial parks, GB two Brisbane council chapels, GC two British crematoria, GD two church-conservation buildings. **Fourteen units, not twenty-five.**

Card 14 (Area B) states a third: *"within an option, units whose text on the field that option is counted on is identical … count once … an option defined by a silence has no text to group by, so its unit count stands and is read as a ceiling."* A per-option text dedup, not an operator grouping at all.

Two consequences I checked against `venues/coded.tsv`:

1. **The Area A rule does not reproduce as written.** Run literally, over every 40-character substring of every `V*` verbatim field and its transitive closure, it chains 73 of the 107 units into one group, because shared boilerplate ("public liability insurance", common hire sentences) links unrelated venues. Matching whole field values instead gives eight groups over 39 units, not seven over 25. Neither run is the stated seven-over-25. The cards call the grouping "reproducible by script"; it is not reproducible from the sentence printed on them.
2. **The two groupings disagree about the Australian group's size** (nine versus eight) and about whether the four British crematoria printing "30 minute chapel time … including entry and exit" are one operator or four. Both disagreements bear directly on Card 4.

Card 22 collapsed its *silent* option by operator identity (102 units to 92) using groups identified from printed text elsewhere. Card 14 declined to collapse its silent option on principle. Card 19 collapsed its silent option (19 to 18). Three treatments of silence in one set.

---

# The four that turned

## Card 4 · What am I paying for?

**1. Before, after, direction.** Before: *"withheld; between A multi-hour inclusive block of 90 minutes to four hours and A fixed short service slot of 30 to 60 minutes; standing at: slot 19 of 40, block 9."* After: recommends the multi-hour block, "thin at a lead of 3 operators". Held stamp moves to **keeps**. The venue's own template and `sot/S3-wp-fees.md` §9 both hold two hours. The turn runs toward what the venue holds.

**2. Counts and rule.** Units: slot 19, block 9, hourly 7, session 5, unchanged. Operators: *"a fixed short service slot 19 and 6; a multi-hour inclusive block 9 and 9."* The rule is the Area A grouping.

**3. Applied alike?** Within the card, yes: the operator recount was made on all four options, and the block's own 9 does not collapse because no group falls in it. Across the set, **no**. I reconstructed the 40 block-stating units from `coded.tsv` and re-ran the collapse under the Area C grouping written three cards later: GA (8 slugs) and GC (flintshire, waveney) are the only groups touching the slot option, so the slot reads **11 operators**, the block still 9, and **the slot leads**. The card's entire turn is the difference between "the Australian group is nine and the British crematoria are two groups" and "the Australian group is eight and only flintshire+waveney are one". Nobody in the run reconciled those two readings.

**4. Verdict: THIN.** It is honestly labelled thin, but rule-dependent, and I would send it back to withheld until the grouping is fixed.

**5. Reason.** The card's own hedge is the giveaway: *"a lead of 3 operators that one operator classified the other way leaves at 1"*. A line that fragile cannot survive a grouping that is not itself settled. And the card keeps, in the same file, *"at 6 against 5 against 2 against 1, a lead any of them holds is erased by one operator classified the other way"* as the reason the shape-sharing cell cannot rank. The status line's claim that *"the two populations agree for the first time"* is true of direction only; one of them still cannot rank, by the card's own words.

## Card 5 · How long do I have the room?

**1.** Before: *"withheld … standing at: access 10 of 40, interval 8, 20 silent, and 6 of the 8 one group's sentence."* After: recommends the access reading, thin at 3 operators; Held to **keeps** (the venue's template: "2 hours, setup and pack-down included"). Toward the venue.

**2.** Units unchanged at access 10, interval 8, silent 20. Operators: *"the booked time as access 10 and 6; the ceremony with a scheduled interval 8 and 3."* Same Area A rule.

**3. Applied alike, and robust.** I re-ran it on the Area C grouping: interval 8 units become 4 operators (five GA members, not six), access 10 become 9 (GC only), so access leads **9 to 4**, wider rather than narrower. This turn does not depend on which version of the rule you use. It is also the one turn with independent corroboration: the market-only clerk reached the access reading from the market alone, at 11 to 7 on the same field, without any operator counting.

**4. Verdict: THIN**, and the soundest of the four.

**5. Reason.** The card named the lean *before* the recount and then had it confirmed: *"the eight interval-outside units carry one corporate group's single sentence published at several sites, which is one observation observed several times."* Predicting the artefact and then measuring it is the opposite of drift.

## Card 18 · What is bought beside the hire

**1.** Before: recommended "inside the hire fee", Held **leaves**. After: withheld between the same two options, Held **held**. Withdrawing a "leaves" line moves toward the venue, which holds a room with no screen, no sound permission and no stream (E15, E16).

**2.** Headline unchanged: inclusion 31 units / 24 operators, paid extra 12 / 11. The leg that moved is the within-priced comparison: *"16 units against 12 becoming 9 operators against 11."* I reproduced the unit figures exactly from `coded.tsv` (41 units at `V3_code`=1; 16 with a live-stream in `V6_items`; 12 with `V6_extra` filled).

**3. Applied alike, and robust the other way.** Under the Area A grouping the reversal is larger, not smaller: the inclusion side collapses to 7 (GA takes seven of the sixteen, mount-gravatt+pinnaroo one more, cardiff+flintshire+waveney one more) and the paid-extra side to 9 (gedling/parndon-wood/wessex-vale one, flintshire/waveney one) : **7 against 9**. So the withdrawal holds on either rule.

**4. Verdict: WITHHELD-SOUND.**

**5. Reason.** The card chose its leg before the recount and then honoured it: *"the line took the corrected within-priced comparison as the honest one … and on distinct operators that comparison reverses from a lead of 4 to a deficit of 2."* A reader may fairly ask why a 24-to-11 operator lead at the headline is set aside; the card answers it on the page, that a priced extra needs a venue printing prices at all.

## Card 22 · Insurance and paperwork

**1.** Before: *"Ask nothing of the hirer; margin: 99 units over Ask every hirer for cover; rests on: both."* After: withheld; Held **leaves** to **held**. The venue's priors hold a \$500 bond and a superseded card requiring organisational cover, so withdrawing "ask nothing" moves toward the venue.

**2.** No count moved. 102/3/1 confirmed; the later operator recount reads 102 and **92** operators, 3 and 3, 1 and 1, and *"the second count neither separates the two readings nor closes the gap."* The rule that moved the line is not the operator rule: it is *"cards 18, 20, 21 and 23 of this set read a zero as silence and never as a posture … this card alone made a silence into the leg beneath its recommendation."*

**3. Applied alike?** On silence-as-a-leg, yes: no other card in the eight recommends a silent option. Card 5 gives "margin: -10 units" against a 20-unit silence and still recommends the 10; Card 14 recommends 13 against a 42-unit silence. Card 14 does *card* its silence as an option and calls the declining "itself a way of selling it", the same move Card 22 was condemned for, but does not rest its line on it, so the rule bites nowhere else. On the treatment of silence under the operator recount, **no**: 22 and 19 collapsed their silent options, 14 refused to.

**4. Verdict: WITHHELD-SOUND**, with one reservation.

**5. Reason.** The instrument argument is real and the card states it plainly: *"a requirement travelling in a hire agreement issued after the enquiry is outside Scope B by the codebook's own rule, which is where two of the three unconditional requirements were in fact read"*. But it is a hypothesis about documents nobody read, and the reservation is the threshold: this set declines to rank **92 operators against 3** while Card 4 turns a withholding into a recommendation on **9 against 6**. Both are defensible inside their own cards; together they are not one method. This is the turn I trust least, and the one closest in shape to the owner's first worry.

---

# The four that did not turn

## Card 0 · One offer or several: **EARNED**

Recommends several uses on one set of terms, margin 14 units and **13 operators**, Held **keeps**. The rule was applied and barely moved anything, for a stated and correct reason: *"This card's population holds few of the grouped units, the memorial-park and crematorium groups being crematoria it sets aside, which is why its figures barely move where Cards 4 and 5 turn."* The line names the two observations that would reverse it (drop the church units and it is 12 to 10, a tie) and does not hide them.

## Card 6 · What is in the room: **WITHHELD-SOUND, and the card the rule should have moved**

This is the one I would put to the clerks. The operator recount did move Card 6, hard: *"the whole-corpus lead of 12 units for the fitted room is 13 of its 35 units belonging to three groups printing one fee schedule each, and on distinct operators the two readings stand level at 22 apiece, an exact tie; the shape-sharing cell meanwhile runs 19 operators bare to 9 fitted."* After the recount there is **no population in which the fitted room leads**. Card 4 turned on precisely that argument, two populations that had ranked opposite ways now pointing one way. Card 6 was handed the same argument, wrote it down, and declined to turn: *"the card that withheld because two populations ranked opposite ways now withholds because one of them ranks not at all."*

The bare room is what the venue holds and the only option with no build in front of it. So the missed move runs **toward** the venue. That is the strongest single piece of evidence in the round against the drift charge. The clerks left a free turn on the table in the venue's favour. It is also the clearest proof that the turn threshold is not one threshold. Its stated ground (Card 1's unruled buyer) is honest, so the withholding is sound on its own terms; the inconsistency with Card 4 is the defect.

## Card 14 · Warm enough: **EARNED**

Recommends a cooled room, Held **leaves**, and it is carried through a correction that runs *against* it (the absence side understated by four British units) and through a recount. The line gives the margin both ways, 13 to 0 among posture-stating operators and 13 to 42 with the silent counted in, and states the direction of its own unknown: *"the silent option's 42 cannot be re-made, so it is a ceiling and the direction of that unknown runs with the recommendation rather than against it."* A card that leaves what the venue holds, survives the same pass, and discloses the one place its rule flatters it. This is the round's best answer to the drift charge.

## Card 19 · Booking route: **EARNED**

Carried, Held **keeps**, and the rule cut it hard: *"the collapse falls on the leading option alone, so the margin moves from 13 units to 6 operators."* The card says the honest thing, *"the unit count no longer the honest one to quote"*, and stands on 6. Applied alike and reported against itself. My only complaint is downstream: see the sheet, below.

---

# Is the one-way direction the evidence or the clerks?

**Strongest reason it is the evidence.** The duplication in this corpus is not spread evenly; it is concentrated in the funeral trade, and the venue is not a funeral operator. One corporate card at eight or nine Australian memorial parks, one Westerleigh-shaped schedule at three or four British crematoria, one council schedule at two Brisbane chapels: those sites print the 45-minute slot, the free 15-minute interval and the live-stream inclusion. Every one of the four turns is a funeral-trade practice deflating. That is a mechanical consequence of the corpus, not a preference, and it is checkable. I checked it, and the option-by-option operator arithmetic on cards 4, 5 and 18 reproduces from `venues/coded.tsv`. The round also fired where it hurt: Card 19 lost more than half its margin on a *keeps* line and the card said so, and Card 6 was handed a free turn toward the venue and refused it. A drifting clerk takes that turn.

**Strongest reason it is the clerks.** There is no single rule. Three versions ran in one day, the broad one was written on the four Area A cards and the narrow one on the three Area C cards, and the one card whose turn is decided by the choice, Card 4, got the broad one. On the narrow rule Card 4 reads 11 slot operators against 9 block, and stays withheld. Worse, the broad rule as printed does not reproduce: run literally it fuses 73 of the 107 units into one group. So the count that turned the run's unit card rests on a grouping that exists nowhere except in the clerks' prose. Add that the market-only clerks were never re-made on operators, so Card 4's "differs" is a corrected card against an uncorrected one, and the independent check the method leans on is not independent of the change.

**My judgement.** The direction is the evidence. The size of the round is the clerks. Cards 5, 18 and 22 would have turned under any reasonable version of the rule; Card 4 would not, and it should go back to withheld until the grouping is settled, which will also decide Cards 6 and 17 behind it.

---

# Is counting each operator once a sound rule for this corpus?

Yes, in principle, and it is the rule the method's own tests already imply. Every recommending line in this set is tested by "would one operator coded the other way erase it". That test only means anything if the things being counted are independent decisions. A fee card printed at nine sites is one decision, and counting it nine times makes the fragility test a fiction. For a corpus whose claim is *this is what operators judge a buyer needs told*, operators are the right denominator.

What it risks:

- **It is built from printed text, so it catches only the chains that copy.** A corporate group with per-site wording is invisible to it. The cards say this correctly, every operator figure being a ceiling on the collapse and a floor on the count, but the asymmetry is not neutral: it deflates the visibly-templated funeral groups and leaves the quietly-owned chains intact.
- **It cannot touch silence.** An option defined by a silence has no text to group by. So printed options shrink and silent options keep their ceiling, which biases every card whose contest is "printed practice versus market silence". Cards 5, 14 and 22 all have that shape. The set handled it three different ways.
- **It changes the question without saying so.** For "what does a buyer meet in this market", units are right: nine memorial parks are nine rooms a family can walk into. For "what does an operator judge", operators are right. Each card should say which question its option is answering; none does.
- **Transitive closure over shared text is unstable.** As demonstrated: boilerplate chains unrelated venues into one "operator". The threshold, the field set and the closure all need pinning, or the same rule gives seven groups, eight groups, or one.
- **It shrinks every denominator to the point where the method's own "under about five stands on sand" line bites.** Card 4 now ranks a 26-operator population; Card 18 a comparison of 9 against 11. These are small numbers being asked to turn decisions.

---

# Three things to change before this rule runs again

1. **Compute the grouping once, before the cards are touched, and publish it as data.** An `operator_id` column joined to the slug in `venues/index.tsv`, produced by a script that is checked in, with the field set, the match test and the closure written down exactly enough to re-run. No area writes its own grouping in prose. The present state is the single defect that makes this round contestable.
2. **Never turn a line on the operator count alone.** Print both counts on every card whether or not the line moved, state which question the option answers, and make a turn require that the recount hold under the grouping's plausible variants. Card 4 fails that test and should read withheld; Card 5, 18 and 22 pass it. Re-run the market-only readings on the same grouping, or stop citing agreement and disagreement between a corrected card and an uncorrected one.
3. **Rule on silence, once, for the whole set.** Either silent options collapse by an operator key taken from outside the text (as Card 22 did, 102 to 92), or none does (as Card 14 did), and every card with a silent option states the direction of the residual unknown on its recommending line, as Card 14 does and the others do not.

Fourth, unasked but worth a line: the sheet should show the operator figure on every row it was computed for, not only the rows that moved. See below.

---

# Reading the front of `review.md` as the owner would

He could rule from it, and better than from most such sheets: the ruling order is explicit, "Wrong today, whichever way you rule" puts the broker letter, the struck flyer claims and the unreadable diary in front of him before any parameter, and the "How this was made" paragraph does the honest thing of naming the one-way direction itself: *"all four turns run toward what the venue holds and none away, and a round firing on one side only is not a test, so it is that reason which has to carry them, not the direction."*

Three things would stop him ruling well. The sheet prints the operator count only on the rows where it turned a line. Cards 4, 5 and 18 carry it, Card 19's row still shows "13 units" when its own card says that figure is no longer the honest one to quote, and Card 6's row still shows the unit and cell figures with no mention of the 22-to-22 operator tie that removed the only population where the fitted room led. So the new rule is displayed where it moved things his way and hidden where it cut a lead that stayed, which is exactly the asymmetry he is worried about even though I believe it is carelessness and not design.

Second, the paragraph says "one published text counting once wherever a group prints it across several sites" as though one rule ran; three did, and on Card 4 the choice between them is the whole turn, which he is not told.

Third, the "Wrong today" paragraph is five long sentences of run-on prose carrying five separate Monday actions: the broker letter, the flyer claims, the deck capacity, the missing page and address, the diary fault. He will lose one of them on a single read.

Net: he can rule Cards 0, 14 and 19 from the sheet today; he should not rule Card 4 until he is told which grouping it stands on.

---

# What I would put to the clerks, in order

1. Settle the grouping. Publish it as a column. Re-run Cards 4, 5, 6, 18, 19 and 22 against it.
2. Card 4 goes back to withheld unless the broad grouping survives that settlement.
3. Card 6: if after the settlement no population has the fitted room leading, say so on the line, whichever way it then falls.
4. Put the operator figure on every sheet row it was computed for, including Cards 6 and 19.

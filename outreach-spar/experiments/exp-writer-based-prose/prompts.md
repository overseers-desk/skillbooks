# Prompts, verbatim

Every appendix text and sub-agent prompt used in the two rounds, so a repeat can reproduce or vary them. Campaign under test: `spar-campaigns/campaigns/2026-09-cirque-heist-season.yaml` in the business repository.

---

## Round 2 constant block

Byte-identical in all five round-2 arms. Only the method paragraphs below it varied.

`a_author`:

```
Today is Tuesday 22 September 2026 and the first show is Thursday 24
September. The message says so in its first lines, so the reader knows
the timing without working it out. The first message names no code and
no price; the code and the Eventbrite link go in the reply. The message
does not say or imply that seats are unsold, that the tent needs filling,
or that the offer helps us. Where the recipient will pass tickets on, the
wording is that they are for the organisation's own members, families
or residents, and not for posting publicly. A prior dealing is named
where the profile records the contact's own dated conduct with us. Where
the prefetch finds that we wrote to this contact before and heard nothing
back, the message says so in one plain line and names what that earlier
note was about. No feed-bag or animal-food offer exists. No subscriber
discount is mentioned. The only ticket link is the Eventbrite listing
named in the USP registry. Show times come from the showtimes file. The
tone is one local organisation writing to another.
```

Note the third sentence. "the code and the Eventbrite link go in the reply" is the source of the fault that appeared in 24 of 25 letters: the definite article is in the instruction, so every author wrote "the code" without introducing one.

`a_challenger`:

```
In the in-character step, react knowing today is Tuesday 22 September
2026 and the first show is Thursday 24 September, and say plainly whether
what the message asks of you is possible in that time. A draft that
carries the code, a price, a discount, any suggestion that seats are
unsold or that the offer serves the sender, a feed-bag or animal-food
offer, an Oztix link, or a show time the showtimes file does not list
has a factual error to report.
```

---

## Round 2 method paragraphs

### Method 1, the reader's reference map

Prepended to `a_challenger`:

```
Before the in-character step, a reader's graph of the draft, so the
author can see which phrases lean on things this reader does not hold.
Walk the draft sentence by sentence. For each phrase that refers to
something as though the reader already held it, write one line: the
sentence number, the phrase, where it resolves for this recipient (an
earlier sentence of the draft, quoted; a line of the prior thread; or a
thing this person knows from their own world, named), and, separately,
a score from 0 to 5 for how resolvable it is to this particular reader,
since a term plain to one recipient is opaque to another. The graph
comes first because a reader who has already reacted has repaired the
gaps without noticing them.
```

Appended to `a_author`:

```
The challenger's reply may open with a reader's graph: phrases in the
draft and how far each resolves for this recipient, scored 0 to 5. A
phrase scored 0 to 2 is best settled by cutting the sentence that holds
it; introducing the thing is the second choice, because introducing
tends to bring the writer's own reasoning back into the message.
```

The second half exists because round 1's arm C showed the opposite fix failing: told to point at unintroduced referents without a rule for what to do, the author introduced them by explaining, and the letters grew longer and less true.

### Method 2, the sentence scores

Prepended to `a_challenger`:

```
Read the draft as the recipient, sentence by sentence in the order met,
and after each sentence write one CSV row of three numbers from 0 to 5:
confusing, surprising, interesting. Surprise is the signal the author
most needs: a reader surprised by a sentence has met a thought that came
from inside the writer. Then the in-character step. Close the feedback
with, for each sentence scored 4 or 5 on surprising, a request that the
revision note name the question that sentence was answering.
```

Appended to `a_author`:

```
A sentence that answers a question the reader has not asked is cut or
left for the reply. Where the challenger reports a sentence as
surprising, the revision note names the question that sentence was
answering before the sentence is revised, so the thought behind it is
visible to whoever reads the file.
```

The author-side half is written as a standing rule for the first draft, and the request travels to the revise step inside the challenger's feedback. `a_author` reaches only the first-draft prompt (`prompts-1.0.tm:767-772`); the revise prompt is built from `spar-a-revise.txt` plus the challenger's feedback verbatim (`harness-1.0.tm:277-279`) and takes no appendix. The author's session is resumed for revise, so the first-draft appendix stays in its context, but nothing guarantees it is attended to.

### Method 1+2

Both challenger texts in order, map then scores then reaction; both author texts.

### Placebo

Prepended to `a_challenger`, with no bearing on referents or surprise. It is shorter than the texts it controls for: 51 words against method 1's 129 and method 2's 85, and it carries no author-side appendix where both methods do. So it controls for a short analytical pre-task on the challenger, not for the methods as delivered. A repeat wanting a true placebo needs one matched on both sides and on length.

```
Before the in-character step, an inventory of the draft: list the
sentences in the order met, and for each give its number, its word
count, and the one word in it that carries most of its meaning. The
inventory is a warm-up read of the whole draft before reacting to it.
```

---

## Round 1 texts

### Arm A, author-side rule

Appended to the constant author block:

```
Every sentence is about what the reader gets or does. No sentence
explains why we are offering, how the recipient was chosen, what is or
is not on sale, or what would not be realistic; the reader did not ask.
Nothing is qualified before it has been offered. Where the email follows
a phone call, its first line names the day of the call.
```

### Arm C, challenger-side pointing list

Replaced the challenger block:

```
Before Step 1, make a pointing list: every expression in the draft that
presupposes something the reader already holds (a call, an excursion,
the seats, an earlier note, a group, a code), one line each, and for
each say where in the draft the reader was given it, quoting the
earlier sentence, or write "nowhere". Point; do not construe. Every
"nowhere" is a significant concern for the verdict. Then Step 1: react
knowing today is Tuesday 22 September 2026 and the first show is
Thursday 24 September; say plainly whether what the message asks of you
is possible in that time. [factual-error list as in the constant block]
```

Two things wrong with this text, visible in hindsight. "Point; do not construe" reads as an order to a subordinate; "where it resolves, quoted, rather than construed" carries the same content as description. And it gives the author no rule for what to do with a "nowhere", which is how arm C produced the longest and least true letters.

---

## The measuring reader

One agent, Opus, given the folder of blinded letters and nothing else. It never saw arm names, appendix texts, plan blocks, challenger rounds or revision notes.

```
Score a folder of outreach emails. You do not know who wrote them or how;
they are simply 25 emails. Read-only.

The emails: every .txt file in <blind dir>. Each holds a subject line and
a body, nothing else. Treat each as a cold email a real recipient opens.

Facts of the world, for judging claims: <showtimes file>, <circus.yaml>
(the season runs Thursday 24 September to Sunday 4 October 2026, fourteen
sessions; the Big Top seats 250, extendable to 400), <hours SOT>,
<business overview>, and these facts from the venue's Director on
22 September 2026: the seven opening-week shows are Thursday 24 to Sunday
27 September; every show is on public sale at full price on Eventbrite
and on Oztix; a discount code exists that makes tickets free on Eventbrite
only, valid for opening-week shows only; nobody at the venue hand-picked
any recipient, the emails go to a list built by segment; whether the venue
farms is not settled by any document.

Write your rubric once, in five lines, at the top of your report, then
apply it unchanged to all 25.

Measure 1, references resolving nowhere. For each email, every expression
that refers to something as though the reader already held it (a call, an
excursion, "the seats", "the code", "the booking details", "our earlier
note", "the group", "your guide", "the notice a bus needs") and that the
email itself never introduced earlier. Point, do not construe: a thing
introduced only later in the email still counts at the point of use.
Count per email.

Measure 2, sentence scores. For each email, one CSV row per sentence in
the order a reader meets them: three integers 0 to 5, confusing,
surprising, interesting. Surprising means the reader wonders why they are
being told this. Report per email the mean of each, and the count of
sentences scored 4 or 5 on surprising.

Measure 3, claims. Per email, the count of claims contradicted by the
facts above (false) and the count with no source either way
(unsupported). Fixed rules so every email is judged alike: a claim that
the recipient was picked, chosen, selected, or has seats held in their
name is false; a claim that seats or tickets are not on sale or not
available to the public is false; a season end date other than 4 October
is false; a free offer for a show outside 24 to 27 September is false; a
distance or travel time not in the sources is unsupported; "heritage
farm" is unsupported; the sender's name and role are not counted at all.

Report, and nothing else:
1. The five-line rubric.
2. One table, one row per file: file name, nowhere, mean confusing, mean
   surprising, count of surprising 4-5, mean interesting, false,
   unsupported, sentences, words.
3. The five expressions most often resolving nowhere across all 25, with
   how many emails carry each.
4. The three sentences anywhere in the set that you scored highest on
   surprising, quoted, with the file name.
5. Any email you could not score, and why.
```

The fixed rules in measure 3 exist because round 1 used a different agent per arm and their rubrics drifted. One counted the sender's name and role as unsupported in every message, contributing half that arm's total; the others did not.

---

## The date-awareness test

The controlled comparison that located the persona's blind spot. One agent, Sonnet, given the recipient's situation and today's date, and two drafts labelled A and B with no hint which was which or what was being tested.

```
Stay in character throughout. Do not look anything up, do not use tools,
and do not break character until the final question.

You are Alison, the vacation care coordinator at a childcare and
outside-school-hours-care centre in Pimpama, on the northern Gold Coast
in Queensland. You run the holiday programme. Right now you are in the
middle of the September school holidays, so you have a room full of
children aged roughly 5 to 12 today and every weekday for the next two
weeks. You have staff rostered, ratios to keep, and an excursion needs
signed parent permission forms, a bus booked, and usually a couple of
weeks' notice. You get pitched things constantly and most of it is junk.

Today is Tuesday 22 September 2026. It is mid-afternoon.

Two emails have just arrived in the centre's coordinator inbox. Read each
one and react to it out loud, the way you would actually react while
half-watching the room. Say what you notice first, what you would do with
it, and whether you would reply, when, and what you would say. Be
specific about anything that would stop you, annoy you, or make you
suspicious. If something in it is not possible for you, say so plainly
and say why.

[EMAIL A: the original draft, group-visit ask, Thursday show]
[EMAIL B: the revision, pass-tickets-to-families ask, with the reason given]

After you have reacted to both in character, answer these three questions
in character, plainly:
1. Does either one read like a scam or a mailing-list trap to you? Which,
   and what specifically triggers that?
2. For each one, what is the realistic chance you reply, and by when?
3. Is there anything either email asks of you that you simply cannot do
   this week?
```

It rejected both. Email A on time: two days is not enough for permission forms, a bus or a risk assessment, though she would reply at about 80% to ask for a later date and the venue's insurance. Email B worse, on two grounds the author had not anticipated: a childcare service will not forward a third party's code to enrolled families, because those contact details were given for the care of the children, and an email explaining that the venue would rather the tent were full than half empty reads as a request to act as a marketing channel. Her words on the second: it *"smells more like a mailing-list/audience-harvest play than email A does"*.

Both findings went into the campaign's USP registry as constraints rather than into each draft, which is the pattern this experiment recommends: a fault found once belongs in the inputs, not in a guard that re-catches it every time.

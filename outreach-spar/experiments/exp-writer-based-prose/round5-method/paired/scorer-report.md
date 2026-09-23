**Rubric (applied unchanged to all 15)**

1. Sentence unit = the subject line plus every body sentence; the greeting line and the signature block are not sentences. `sent` is that count; `words` is every whitespace-separated token in the file.
2. Nowhere: a definite/possessive expression whose referent the email has not yet introduced at the point of use; later introduction does not save it. Anything the recipient is, owns or runs resolves (their club, village, group, members, residents, their named officers, their newsletter, noticeboard, bus, list, meetings, grandchildren); so do the school holidays, and a definite carrying its own naming apposition ("the family show, WANTED – A Cirque Heist").
3. Confusing/surprising/interesting scored 0–5 each in reading order; surprising = the reader wonders why they are being told this; `surp45` counts sentences at 4 or 5 on surprising.
4. False: any claim the recipient was picked or singled out; any claim seats are held, kept, or set aside for them or for "local clubs/organisations" (every show is on public sale at full price, so no such allocation exists); a season end other than 4 October; a free offer outside 24–27 September. Hedged future ("I'll ask about holding", "what we can hold") is not counted.
5. Unsupported: any claim with no source either way — distances or travel times not in the sources (only "30 minutes from central Gold Coast" is sourced), any positioning of the recipient's locality relative to the venue, every prior-contact assertion (each separately assertable clause counts once), stated facts about the recipient's own operations, and the Eventbrite URL. Sender's name and role never counted.
6. Sender-side: the sentence's substance is why the sender is offering, how or why this recipient was written to, what is not possible, or the sender's own situation. Sentences telling the reader what they get, must do, by when, or from whom are reader-side. Greeting, sign-off, and any sentence introducing the sender or the sender's organisation are excluded from the count but stay in `sent`.

**Table**

```
file	nowhere	conf	surp	surp45	int	false	unsup	sender	sent	words
msg-063264.txt	1	0.31	1.23	1	2.38	1	1	1	13	239
msg-113266.txt	0	0.23	1.08	2	2.23	0	3	2	13	223
msg-159588.txt	0	0.78	2.00	3	2.17	2	4	5	18	314
msg-226570.txt	3	0.53	1.47	2	2.27	2	2	3	15	272
msg-434809.txt	1	0.15	0.69	0	2.46	0	1	1	13	215
msg-540190.txt	0	0.10	0.70	0	2.60	0	0	0	10	214
msg-547016.txt	0	0.18	1.12	1	2.29	1	2	2	17	305
msg-559804.txt	0	0.17	0.92	0	2.50	0	0	1	12	214
msg-627483.txt	0	0.44	1.56	2	2.19	1	3	5	16	276
msg-702708.txt	0	0.08	0.75	0	2.33	0	1	0	12	176
msg-721082.txt	0	0.17	1.08	0	2.50	2	0	1	12	231
msg-893963.txt	1	0.36	1.50	2	2.29	1	3	2	14	292
msg-904170.txt	1	0.33	1.25	0	2.83	0	2	1	12	226
msg-930441.txt	2	0.77	1.31	0	2.85	1	2	0	13	228
msg-934532.txt	1	0.30	0.80	0	2.50	0	0	0	10	212
```

**Expressions most often resolving nowhere**

| expression | emails |
|---|---|
| "the (booking) link" — a link named as definite before any link or booking is mentioned | 3 (msg-434809, msg-063264, msg-226570) |
| "the booking details" | 2 (msg-930441, msg-904170) |
| "the opening shows" / "the opening-week shows" — before any show is introduced | 2 (msg-893963, msg-934532) |
| "our lawn" / "our grounds" — the sender's premises before the sender or venue is introduced | 2 (msg-930441, msg-226570) |
| "The code" | 1 (msg-226570) |

**Highest-scoring sentences on surprising**

1. msg-159588.txt — "Patricia then asked us to ring her and gave us a time." (5)
2. msg-159588.txt — "The call never happened, and I'm sorry about that." (5)
3. msg-226570.txt — "Yours is the name I have for the club, so I am starting with you." (4)
4. msg-893963.txt — "Your meetings look to be monthly, so I expect this is one for the email list rather than something to raise at a lunch." (4)
5. msg-627483.txt — "We have no reply to it on our side." (4)

**Emails not scored**

None. All 15 were scored.

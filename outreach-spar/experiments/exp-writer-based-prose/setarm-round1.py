import sys,re
arm=sys.argv[1]; p='campaigns/2026-09-cirque-heist-season.yaml'; y=open(p).read()
READER="""    tone is one local organisation writing to another. Every sentence is
    about what the reader gets or does. No sentence explains why we are
    offering, how the recipient was chosen, what is or is not on sale, or
    what would not be realistic; the reader did not ask. Nothing is
    qualified before it has been offered. Where the email follows a phone
    call, its first line names the day of the call.
"""
PLAIN="    tone is one local organisation writing to another.\n"
CH_BASE="""  a_challenger: |
    In Step 1, react knowing today is Tuesday 22 September 2026 and the
    first show is Thursday 24 September; say plainly whether what the
    message asks of you is possible in that time. Fail a draft that carries
    the code, a price, a discount, any suggestion that seats are unsold or
    that the offer serves the sender, a feed-bag or animal-food offer, an
    Oztix link, or a show time the showtimes file does not list.
"""
POINT="""  a_challenger: |
    Before Step 1, make a pointing list: every expression in the draft that
    presupposes something the reader already holds (a call, an excursion,
    the seats, an earlier note, a group, a code), one line each, and for
    each say where in the draft the reader was given it, quoting the
    earlier sentence, or write "nowhere". Point; do not construe. Every
    "nowhere" is a significant concern for the verdict. Then Step 1: react
    knowing today is Tuesday 22 September 2026 and the first show is
    Thursday 24 September; say plainly whether what the message asks of you
    is possible in that time. Fail a draft that carries the code, a price,
    a discount, any suggestion that seats are unsold or that the offer
    serves the sender, a feed-bag or animal-food offer, an Oztix link, or a
    show time the showtimes file does not list.
"""
# author rule
if READER in y: y=y.replace(READER, READER if arm in('A','B') else PLAIN)
elif PLAIN in y: y=y.replace(PLAIN, READER if arm in('A','B') else PLAIN)
else: raise SystemExit('author anchor missing')
# challenger
m=re.search(r'  a_challenger: \|\n(?:    .*\n)+', y); assert m
y=y[:m.start()]+(POINT if arm in('C','B') else CH_BASE)+y[m.end():]
open(p,'w').write(y); print('arm',arm,'set')

#!/usr/bin/env python3
"""Set a campaign YAML's prompt_appendices to one experimental arm.
usage: setarm2.py <campaign.yaml> <none|placebo|m1|m2|m12>
The constant block is identical in every arm; only the method paragraphs differ."""
import sys,re
yaml_path, arm = sys.argv[1], sys.argv[2]
y=open(yaml_path).read()

AUTHOR_CONST = """    Today is Tuesday 22 September 2026 and the first show is Thursday 24
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
"""
CHAL_CONST = """    In the in-character step, react knowing today is Tuesday 22 September
    2026 and the first show is Thursday 24 September, and say plainly whether
    what the message asks of you is possible in that time. A draft that
    carries the code, a price, a discount, any suggestion that seats are
    unsold or that the offer serves the sender, a feed-bag or animal-food
    offer, an Oztix link, or a show time the showtimes file does not list
    has a factual error to report.
"""
M1_CHAL = """    Before the in-character step, a reader's graph of the draft, so the
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
"""
M1_AUTH = """    The challenger's reply may open with a reader's graph: phrases in the
    draft and how far each resolves for this recipient, scored 0 to 5. A
    phrase scored 0 to 2 is best settled by cutting the sentence that holds
    it; introducing the thing is the second choice, because introducing
    tends to bring the writer's own reasoning back into the message.
"""
M2_CHAL = """    Read the draft as the recipient, sentence by sentence in the order met,
    and after each sentence write one CSV row of three numbers from 0 to 5:
    confusing, surprising, interesting. Surprise is the signal the author
    most needs: a reader surprised by a sentence has met a thought that came
    from inside the writer. Then the in-character step. Close the feedback
    with, for each sentence scored 4 or 5 on surprising, a request that the
    revision note name the question that sentence was answering.
"""
M2_AUTH = """    A sentence that answers a question the reader has not asked is cut or
    left for the reply. Where the challenger reports a sentence as
    surprising, the revision note names the question that sentence was
    answering before the sentence is revised, so the thought behind it is
    visible to whoever reads the file.
"""
PLACEBO_CHAL = """    Before the in-character step, an inventory of the draft: list the
    sentences in the order met, and for each give its number, its word
    count, and the one word in it that carries most of its meaning. The
    inventory is a warm-up read of the whole draft before reacting to it.
"""
arms={
 'none':    (AUTHOR_CONST, CHAL_CONST),
 'placebo': (AUTHOR_CONST, PLACEBO_CHAL+CHAL_CONST),
 'm1':      (AUTHOR_CONST+M1_AUTH, M1_CHAL+CHAL_CONST),
 'm2':      (AUTHOR_CONST+M2_AUTH, M2_CHAL+CHAL_CONST),
 'm12':     (AUTHOR_CONST+M1_AUTH+M2_AUTH, M1_CHAL+M2_CHAL+CHAL_CONST),
}
a,c=arms[arm]
block="prompt_appendices:\n  a_author: |\n"+a+"  a_challenger: |\n"+c
m=re.search(r'prompt_appendices:\n  a_author: \|\n(?:    .*\n)+  a_challenger: \|\n(?:    .*\n)+', y)
assert m, 'appendix block not found'
y=y[:m.start()]+block+y[m.end():]
open(yaml_path,'w').write(y)
import yaml as Y; Y.safe_load(open(yaml_path)); print('arm',arm,'set;',len(a.split()),'author words,',len(c.split()),'challenger words')

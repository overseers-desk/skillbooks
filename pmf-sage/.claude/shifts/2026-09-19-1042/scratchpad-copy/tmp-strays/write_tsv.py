import csv

rows = []

header = ["profile","V19","V19_buyers","V19_words","V19_within","V19_other","V19_generic","V19_excluded","V19_tier","V19_lead_buyer","verbatim","note"]

def row(profile, v19, buyers="", words="", within="", other="", generic="", excluded="", tier="", lead="", verbatim="", note=""):
    return [profile, v19, buyers, words, within, other, generic, excluded, tier, lead, verbatim, note]

rows.append(row(
    "divine-film-venue-burbank-church.md", "9",
    note="B_status = unreachable (the venue's own domain could not be located; only third-party marketplace mirrors were found). Per Appendix B / the amendment's own missing-value rule, a B_status of unreachable makes every one of the fourteen variables, including V19, 9 not captured; there is no captured text to code a buyer from."
))

rows.append(row(
    "easterbrook-hall-and-the-crichton-church.md", "0",
    note="E1: no party word and no refusal appears anywhere in the Scope B text captured for The Crichton Memorial Church. The church page and the Easterbrook Hall / organise-an-event pages name uses ('weddings, graduations, concerts and events') and estate locations, and the 'Venues Team' is venue staff addressed by enquirers, not a stated hirer. No generic word ('you', 'hirer', etc.) is tied to hiring the church either, so V19_generic is also empty rather than filled."
))

rows.append(row(
    "elegant-chapel-ballroom-with-grand-piano-event-lighting.md", "0",
    note="E1/E3: the Giggster listing text states uses ('ideal for weddings, receptions, galas...') and generic booking mechanics ('Message Host', 'Reserve Instant Book Next', 'For your safety and protection...') but names no party word from the closed list or the generic list as a hirer with a hire construction attached. Flagged as a possible two-coder disagreement point at a level above this row: the whole unit's own note says a marketplace listing normally sits outside every scope (§2.2) rather than in Scope B, so a stricter coder could argue V19 should be 9 (OUT OF SCOPE (C), A6) rather than 0 here; this row follows the scope assignment the V1–V18 coder already made (B_status = found) rather than re-deciding it."
))

rows.append(row(
    "eltham-montmorency-uniting-church.md", "0",
    generic="Hirers",
    verbatim="V19_generic: Hirers (\"Hirers need to sign a Hirer's Agreement, pay in advance for single use events and make an agreement for regular use bookings about the frequency of payment.\")",
    note="Only a generic word ('Hirers') is tied to hire on the Facilities Hire page's booking-terms note, which reads on the whole page including the Worship Space collectively (A5). The Hall and Gathering Space text ('Suitable for dance groups, exercise groups, large meetings, celebrations, funerals and christenings') pairs candidate party words with the closed hire construction 'suitable for X', but names them of The Hall and Gathering Space, not of the Worship Space/Church itself; under A5 a secondary-room statement is excluded, so this row does not count them and stays at 0. A second coder could disagree and read the page's opening sentence ('The following spaces are available for hire...') as making this a collective statement that pulls the Hall/Gathering party words into the church's own record, which would instead code V19=1 with 'other in the venue's words' for 'dance groups' and 'exercise groups' under I5 with a CANDIDATE WORD note. 'Community groups may be covered by Uniting Church Insurance' names a party but carries no hire construction in the same sentence, so under C.3 it is left uncoded either way."
))

rows.append(row(
    "ewelme-cottage.md", "9",
    note="B_status = none found (no room noun from the codebook's closed list appears anywhere in the captured text; no chapel, church or similar room is named). §A7 places V19 in the B-only group, and the §3/Amendment 1.1 missing-value table codes every B-only variable 9 wherever B_status is none found."
))

rows.append(row(
    "experiment-farm-cottage.md", "9",
    note="B_status = none found (no ceremonial-room noun is used anywhere in Scope A; the hireable spaces named are the verandah and the gardens). §A7 places V19 in the B-only group, so the missing-value table codes it 9."
))

rows.append(row(
    "farfield-quaker-meeting-house.md", "0",
    note="E1: the entire Hire & Enquire text ('This small Meeting House welcomes visitors throughout the year and is available to hire. You may picnic in the small burial ground...') names no party at all, only a bare hire offer and a visiting/picnicking statement; no generic word is tied to hiring either ('You may picnic' is about picnicking, not hiring, so it is not logged under V19_generic)."
))

rows.append(row(
    "fawkner-memorial-park.md", "1",
    buyers="a funeral director, celebrant, minister or planner acting for a client",
    words="please ask your Funeral Director to liaise with GMCT's Bookings team",
    verbatim="V19_words: \"please ask your Funeral Director to liaise with GMCT's Bookings team\"",
    note="I7: the funeral director is stated to place the booking for another ('To book any of the three chapels at Fawkner Memorial Park for a service, please ask your Funeral Director to liaise with GMCT's Bookings team'); the family/on-whose-behalf party is not named in the same sentence, so only the intermediary value is coded, per I7's instruction never to decide which of the two is the real buyer. The chapels page's opening sentence ('families and communities can gather together to farewell their loved ones') names two attendee-type words with no hire construction from the closed list attached ('can gather together' is not on the C.3 list), so under E4 it is read as an attendee statement and excluded rather than coded as a second value; a coder reading 'gather' loosely as equivalent to 'use the chapel' could disagree and press for its inclusion, which is flagged here as the run's most likely two-coder split on this shard. V19_lead_buyer is left empty because the principal Scope B page's first sentence names no coded party (it fails the hire-verb test) and the sentence that is coded is not that page's first sentence."
))

rows.append(row(
    "flintshire-memorial-park-and-crematorium.md", "0",
    note="No party word carries a hire construction in the Scope B text (About Flintshire Crematorium, the Services and Facilities body text, or the Cremation Fees PDF). 'your funeral director' appears twice but only in Scope A-only text units with no attribute of hiring the chapel in the same unit (the Music Requests sentence on Services and Facilities is sourced (A) at V2, and 'Almost all families faced with bereavement will either use our Memoria Funerals or the services of an independent traditional funeral Director' is on the Arranging a Funeral page, also sourced (A) at V2); under V19's own Scope-B-only rule (§C) these fall to E6, OUT OF SCOPE (A)."
))

rows.append(row(
    "forest-lawn-memorial-park.md", "0",
    note="No party word carries a hire construction in Scope B. 'funeral directors' appears only in a logistics sentence about the cleaning/setup interval between chapel bookings ('a 15 minute interval is scheduled... for funeral directors to set up and discuss any requirements with the Concierge'), which states no hire, book or enquire construction attached to the party word (E1); 'families' appears only in the Tea Room / Cafe catering text, not tied to hiring the chapel."
))

rows.append(row(
    "free-chapel-hodgeston-pembrokeshire.md", "9",
    note="B_status = none found, per the collector's own flagged scope-boundary finding: no page names Hodgeston or Free Chapel together with any attribute of hiring, and the organisation-wide Venue Hire page's party-adjacent language ('Our churches are available for ceremonies and celebrations, including weddings and blessings') never names this church, so it cannot be read into this unit's record under §2.2's naming test. §A7 places V19 in the B-only group, so the missing-value table codes it 9."
))

rows.append(row(
    "frenchs-forest-bushland-cemetery-lorikeet-room.md", "0",
    generic="your farewell ceremony; your needs",
    verbatim="V19_generic: \"your farewell ceremony\" (\"...this serene setting can meet your needs\"; \"The Lorikeet Room offers a peaceful and adaptable venue for your farewell ceremony...\")",
    note="Only generic second-person words ('your farewell ceremony', 'your needs') are tied to the hire; no closed-list party word (couple, family, funeral director, etc.) appears anywhere in the Lorikeet Room page or the price-list PDF, only uses ('say goodbye', 'farewell') and generic pronouns, so E2 applies."
))

with open("/usr/local/src/rivermill/product-development/chapel-hire/2026-09-11-how-chapel-hire-was-decided/0-comparables/chapel-hire-2026-09/coded-whom-sold-to/shard-05.tsv", "w", newline="") as f:
    w = csv.writer(f, delimiter="\t", quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
    w.writerow(header)
    for r in rows:
        w.writerow(r)

print("wrote", len(rows), "rows")

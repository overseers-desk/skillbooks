import csv

fields = [
 "file",
 "V20","V20_form","V20_words","V20_named","V20_required",
 "V21","V21_form","V21_words","V21_amount","V21_guests",
 "V22","V22_form","V22_words","V22_reply","V22_confirm","V22_balance","V22_documents",
 "V23","V23_form","V23_words","V23_period","V23_fee","V23_release",
 "V24","V24_form","V24_words","V24_names","V24_count","V24_differs",
 "V25","V25_form","V25_name","V25_words",
 "V26","V26_items","V26_words","V26_direction","V26_condition","V26_other",
 "V27","V27_form","V27_words","V27_against",
 "V28","V28_items","V28_words","V28_direction","V28_condition",
 "V29","V29_form","V29_words","V29_amount","V29_grace",
 "V30","V30_form","V30_words","V30_role","V30_duties","V30_price",
 "V31","V31_form","V31_words","V31_fee","V31_deadline",
 "V32","V32_form","V32_words","V32_party","V32_rate",
 "V19","V19_buyers","V19_words","V19_within","V19_other","V19_generic","V19_excluded","V19_tier","V19_lead_buyer",
 "quotes","note",
]

def mkquotes(d, *pairs):
    parts = []
    for label, val in pairs:
        if val:
            parts.append(f"{label}: {val}")
    return "; ".join(parts)

rows = []

# 1. capalaba-uniting-church -- unreachable, all 9
d = {f:"" for f in fields}
d["file"] = "capalaba-uniting-church.md"
for v in ["V20","V21","V22","V23","V24","V25","V26","V27","V28","V29","V30","V31","V32","V19"]:
    d[v] = "9"
d["note"] = "B_status unreachable (own domain no longer resolves); per Amendment 1.1/§A7 all fourteen variables of Amendment 1.5 are 9, not captured, before any reading."
rows.append(d)

# 2. cardiff-and-glamorgan-memorial-park-and-crematorium -- found, none linked
d = {f:"" for f in fields}
d["file"] = "cardiff-and-glamorgan-memorial-park-and-crematorium.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="1"; d["V24_form"]="two or more differing by use; by what is included"
d["V24_words"]="Attended Personal Service; Celebration of Life; Hire of chapel only (No cremation); Cremation & Chapel Service"
d["V24_names"]="Attended Personal Service; Celebration of Life; Hire of chapel only (No cremation); Cremation & Chapel Service"
d["V24_count"]="4"; d["V24_differs"]="by use; by what is included"
d["V25"]="1"; d["V25_form"]="a named product; a named product; a named product"
d["V25_name"]="Hire of chapel only (No cremation); Cremation & Chapel Service; Attended Personal Service"
d["V25_words"]="Hire of chapel only (No cremation), 10:00-16:00, £515; Cremation & Chapel Service - Adult; Attended Personal Service, 30-minute service, up to 25 attendees, £979"
d["V26"]="0"
d["V27"]="1"; d["V27_form"]="a denied practice of others"
d["V27_words"]="a feeling of not being rushed on a tragic conveyor belt"
d["V27_against"]=""
d["V28"]="0"
d["V29"]="1"; d["V29_form"]="extension available at a stated price; a flat overrun charge"
d["V29_words"]="Additional time (double slot provision): Extra hour for extended or large services £498; Saturday additional time, double slot £575; Out of Time Penalty - APPLICABLE IF A FOLLOWING CORTEGE IS KEPT WAITING £380"
d["V29_amount"]="£498; £575; £380"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"] = mkquotes(d,
  ("V24_names", d["V24_names"]),
  ("V25_name", d["V25_name"]),
  ("V27_words", d["V27_words"]),
  ("V29_words", d["V29_words"]))
d["note"] = ("V24/V25: the price-table rows (Hire of chapel only, Cremation & Chapel Service, Attended Personal Service) are counted as separately "
  "labelled offerings under I1/I3 and as named products under V25's mechanical extra-word test (words such as 'only', 'cremation', 'Personal' are "
  "not on any closed room/use/generic/hire list); a second coder could instead read these as one hire priced several ways by service type, the way "
  "weekday/Saturday variants are already read as V3_wk rather than separate V24 offerings, and could read the labels as merely descriptive. Direct "
  "Cremation (Funeral Director/Unattended) is excluded from the V24 count as not clearly a chapel-hire offering (no service/chapel use implied). "
  "V27: 'not being rushed on a tragic conveyor belt' is coded as a denied practice attributed to others (unnamed crematoria generally), the same "
  "sentence already coded at V10 for exclusivity; A10 permits the double coding. V29: the Out of Time Penalty (waiting cortege) is read as a stated "
  "consequence of running over into the next booking, distinct from V14's cancellation fee. The Take a Tour page was fetched per the capture record "
  "but no body text from it is transcribed in this profile, so V20 could not be coded from it and rests on 0 by default.")
rows.append(d)

# 3. castle-chapel-urishay-herefordshire -- mention only
d = {f:"" for f in fields}
d["file"] = "castle-chapel-urishay-herefordshire.md"
d["V20"]="0"
d["V21"]="0"
for v in ["V19","V22","V23","V24","V25","V26","V29","V30","V31","V32"]:
    d[v]="9"
d["V27"]="0"
d["V28"]="0"
d["quotes"]=""
d["note"] = ("B_status is mention only, so per §A7/Amendment 1.1's missing-value table the B-only group (V19, V22-V26, V29-V32) is 9 before any reading, "
  "and only the A,B group (V20, V21, V27, V28) is coded from Scope A. V20: the page's 'Open daily' visitor-information line could be read by another "
  "coder as an advertised viewing time under I2, but nothing states this church is available for hire at all (B_status mention only, no offer exists), "
  "so it is coded 0 here rather than as a viewing route to an offer; flagged as unsettled. V21: A_admission is silent; V27/V28: no construction or "
  "utility/storage statement appears in the Scope A text captured.")
rows.append(d)

# 4. castlebrook-memorial-park -- found, none linked
d = {f:"" for f in fields}
d["file"] = "castlebrook-memorial-park.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="1"; d["V24_form"]="two or more differing by use"
d["V24_words"]="Chapel Hire - Service Only; Chapel Hire for Burial; Cremation & Chapel Service"
d["V24_names"]="Chapel Hire - Service Only; Chapel Hire for Burial; Cremation & Chapel Service"
d["V24_count"]="3"; d["V24_differs"]="by use"
d["V25"]="1"; d["V25_form"]="a named product; a named product; a named product"
d["V25_name"]="Chapel Hire - Service Only; Chapel Hire for Burial; Cremation & Chapel Service"
d["V25_words"]="Chapel Hire - Service Only (45mins); Chapel Hire for Burial (45mins); Cremation & Chapel Service"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="1"; d["V29_form"]="extension available at a stated price"
d["V29_words"]="Chapel Hire - Additional Time Slot (45mins) - Weekday $400.00; Sat, Sun & Public Holiday $500.00"
d["V29_amount"]="$400.00; $500.00"
d["V30"]="1"; d["V30_form"]="a person is present but their duties are not stated"
d["V30_words"]="Chapel fees include the use of the chapel and a Concierge for a 45 minute time period. A 15 minute interval is scheduled prior to each time period to allow for cleaning of the chapels and for funeral directors to set up and discuss any requirements with the Concierge."
d["V30_role"]="Concierge"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"]=mkquotes(d,("V24_names",d["V24_names"]),("V25_name",d["V25_name"]),("V29_words",d["V29_words"]),("V30_words",d["V30_words"]))
d["note"] = ("V24/V25: same mechanical-test reasoning as the other InvoCare/Memoria unit in this shard (Cardiff and Glamorgan); a second coder "
  "could read the three price-table rows as one hire priced by circumstance rather than three offerings. V30: 'Concierge' is not on V30's closed "
  "role-word list (verger, warden, steward, attendant, chapel manager, our staff, our team, etc.); V30_role is verbatim-as-printed rather than "
  "closed, so it is recorded regardless, but the sentence states the Concierge's presence without stating a duty for the Concierge itself (the "
  "stated duty, 'set up', belongs to funeral directors), so V30_duties is left empty rather than forced onto the closed duty list; flagged as "
  "a case a second coder might code 0 for lack of a stated duty of the role itself.")
rows.append(d)

# 5. centenary-memorial-gardens -- found, none linked
d = {f:"" for f in fields}
d["file"] = "centenary-memorial-gardens.md"
d["V20"]="1"; d["V20_form"]="a viewing or site visit by prior arrangement"
d["V20_words"]="For more information or to schedule a visit to our gardens and chapel, contact us today."
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="0"
d["V25"]="0"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"]=mkquotes(d,("V20_words",d["V20_words"]))
d["note"] = ("This unit publishes two separately named ceremonial rooms (the Federation Chapel and the Woodlands Chapel) with no principal room "
  "designated in the profile; V24 is coded 0 because the text describes two different rooms rather than two offerings of one hired chapel, "
  "consistent with A5's rule that a secondary room is read out, but a second coder could read this differently absent a stated principal room. "
  "V20 draws on the 'schedule a visit to our gardens and chapel' sentence under I1.")
rows.append(d)

# 6. centennial-park -- found, none linked
d = {f:"" for f in fields}
d["file"] = "centennial-park.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="0"
d["V25"]="0"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="1"; d["V30_form"]="a person is present but their duties are not stated"
d["V30_words"]="complimentary multi-angle livestreaming and dedicated onsite support"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"]=mkquotes(d,("V30_words",d["V30_words"]))
d["note"] = ("This unit's room_kind is itself a coder's dilemma the profile flags: the venue's own copy calls its rooms 'venues'/'service venues' "
  "throughout and applies the word 'chapel' only once, in an undated testimonial ('Beautiful chapel and surrounds') and once in an image filename "
  "('13-HEYSEN-CHAPEL'), naming The Heysen specifically. Four named venues exist (The Mawson, The Florey, The Heysen, Jubilee Complex Foyer) with no "
  "stated principal room, so V24 and V25 are coded 0 on the same reasoning as Centenary Memorial Gardens rather than treating the named venues as "
  "offerings of one hired chapel; a second coder could reach a different B_status/unit reading altogether given how thin the room-noun evidence is, "
  "which is outside this coder's brief to revisit. V30: 'dedicated onsite support' is read as a stated but undutied staff presence under the "
  "Jubilee Complex Foyer's inclusions; the same sentence also bears on V6 (livestreaming) under A10.")
rows.append(d)

# 7. chapel-1885 -- found, none linked
d = {f:"" for f in fields}
d["file"] = "chapel-1885.md"
d["V20"]="1"; d["V20_form"]="a viewing or site visit by prior arrangement"
d["V20_words"]="BOOK A VIEWING; BOOK A VENUE TOUR"
d["V21"]="0"
d["V22"]="1"; d["V22_form"]="enquiry then a quote"
d["V22_words"]="Once you've chosen the package that suits you best and confirmed your event numbers, the team will provide you with a final quote. Our minimum spends are calculated based on event date, timings and package selection. Venue hire is included in the quote."
d["V23"]="0"
d["V24"]="1"; d["V24_form"]="two or more differing by use; by buyer; by length or time of day"
d["V24_words"]="Your booking duration is inclusive of two (2) hours for set up and one (1) hour pack down (Wedding FAQs); Your booking duration is inclusive of one hour set up and one hour pack down (Corporate & Functions FAQs)"
d["V24_names"]="Weddings; Events (Celebrations / Corporate Events)"
d["V24_count"]="2"; d["V24_differs"]="by use; by buyer; by length or time of day"
d["V25"]="0"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"; d["V19_generic"]="you"
d["quotes"]=mkquotes(d,("V20_words",d["V20_words"]),("V22_words",d["V22_words"]),("V24_names",d["V24_names"]),("V19_generic",d["V19_generic"]))
d["note"] = ("V24: coded on the reading that the separate Wedding FAQs and Corporate & Functions FAQs, each with its own set-up/pack-down block, "
  "describe two distinguishable hire offerings of the one converted-chapel space; a second coder could instead read this as one hire marketed to "
  "two buyer types with different block lengths, which would code 0. V31: 'What if we need to modify our custom quote... after paying the deposit?' "
  "with the answer allowing changes so long as minimum spend is met, was considered for V31 (moving a date) but is coded 0 because the text is about "
  "modifying quote details/numbers, not a date move; flagged as a borderline a second coder might read as a move term.")
rows.append(d)

# 8. chapel-bar-at-greenwood-hotel -- found, none linked
d = {f:"" for f in fields}
d["file"] = "chapel-bar-at-greenwood-hotel.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="0"
d["V25"]="0"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"]=""
d["note"] = ("The Chapel page's own 'Perfect for:' and 'Features:' headings carry no list content beneath them in the page source (confirmed by the "
  "collector against the raw HTML, not just the rendered text), so almost every one of the fourteen variables is 0 by simple absence rather than by "
  "any close call. V20: a 'Virtual Tour' link is offered on the page (per the V11 capture) but with no stated viewing construction attached to it "
  "(no sentence saying a viewing is offered, only a bare link label), so it is coded 0 rather than 1 under I1/I2, consistent with Ruling 1.2b's "
  "treatment of bare link labels as furniture; a second coder could read the link label itself as sufficient and code 1.")
rows.append(d)

# 9. chapel-hill-retreat -- found, none linked
d = {f:"" for f in fields}
d["file"] = "chapel-hill-retreat.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="0"
d["V25"]="0"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"; d["V19_generic"]="your"
d["quotes"]=mkquotes(d,("V19_generic",d["V19_generic"]+' (from "your marriage ceremony experience", the Chapel entry)'))
d["note"] = ("This venue's package-differentiation text (The Eternal Love Package, The Forever Package, the Petite Silver/Petite Gold elopement "
  "packages, etc.) is read throughout the source profile as OUT OF SCOPE (package): it is stated of the estate/wedding day as a whole, not of the "
  "Chapel by name in the same sentence, so V24 and V25 are coded 0 rather than treating the packages as chapel offerings or chapel-offering labels, "
  "consistent with the profile's own repeated package-scope notes at V6-V10. No sentence naming the Chapel also names a party (couple, family, "
  "individual) with a hire construction; the nearest sighting is the second-person 'your' in the Chapel's own entry ('your marriage ceremony "
  "experience'), logged at V19_generic under E2.")
rows.append(d)

# 10. chapel-ridge -- found, none linked
d = {f:"" for f in fields}
d["file"] = "chapel-ridge.md"
d["V20"]="1"; d["V20_form"]="a viewing or site visit by prior arrangement"
d["V20_words"]="Come visit Chapel Ridge... Book a Private Inspection"
d["V21"]="0"
d["V22"]="1"; d["V22_form"]="enquiry then a quote"
d["V22_words"]="Contact us for pricing & package details."
d["V23"]="0"
d["V24"]="0"
d["V25"]="0"
d["V26"]="0"
d["V27"]="1"; d["V27_form"]="an only-or-first claim"
d["V27_words"]="Exclusively yours for the day, Chapel Ridge hosts only one wedding at a time, no tourists, no public access, and no shared spaces."
d["V28"]="0"
d["V29"]="0"
d["V30"]="1"; d["V30_form"]="a role attends at stated points only"
d["V30_words"]="Our staff will assist anyone that needs help on the day."
d["V30_role"]="Our staff"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"; d["V19_generic"]="your special day"
d["quotes"]=mkquotes(d,("V20_words",d["V20_words"]),("V22_words",d["V22_words"]),("V27_words",d["V27_words"]),("V30_words",d["V30_words"]),("V19_generic",d["V19_generic"]))
d["note"] = ("V27 is coded 1 strictly on the letter of the construction test: 'hosts only one wedding at a time' contains 'only', one of the closed "
  "markers, even though the sentence reads as an exclusivity claim already coded at V10 rather than a claim made against a named or unnamed rival; "
  "the codebook's own worked example ('More space than you might expect') accepts this cost of a mechanical test, and I follow it, but flag this as "
  "the strongest candidate in this shard for two coders disagreeing — a stricter reading would hold that 'only one wedding at a time' compares the "
  "venue with itself on other days, not with an alternative, and would code 0. V30: 'assist' is not on V30's closed duty-word list (nearest is 'be "
  "on hand'); V30_duties is left empty rather than force-mapped.")
rows.append(d)

# 11. chapel-suite-at-the-como-melbourne -- found, none linked
d = {f:"" for f in fields}
d["file"] = "chapel-suite-at-the-como-melbourne.md"
d["V20"]="0"
d["V21"]="0"
d["V22"]="0"
d["V23"]="0"
d["V24"]="0"
d["V25"]="1"; d["V25_form"]="a named product"
d["V25_name"]="Chapel Suite"
d["V25_words"]="Chapel Suite"
d["V26"]="0"
d["V27"]="0"
d["V28"]="0"
d["V29"]="0"
d["V30"]="0"
d["V31"]="0"
d["V32"]="0"
d["V19"]="0"
d["quotes"]=mkquotes(d,("V25_name",d["V25_name"]))
d["note"] = ("V25 is the least settled call in this shard: 'Chapel Suite' is simultaneously this unit's room_name and, on the venue's own site "
  "structure, one of nine individually named, individually priced meeting suites functioning as separate bookable products, the way 'The Quiet "
  "Hour' functions as a named product in the codebook's own worked Case C. The mechanical named-product test (room noun 'Chapel' plus 'Suite', a "
  "word on no room/use/generic/hire list) passes, so it is coded 1 here, but E4 excludes a label that 'names the venue, not the offering', and a "
  "second coder could reasonably hold that a room's own proper name is not an offering label and code 0. The room itself carries no religious or "
  "ceremonial character on the pages captured; the name is drawn from Chapel Street, the hotel's own address, which is recorded in the capture-record "
  "notes rather than at any of the fourteen variables, per S1.")
rows.append(d)

# 12. christ-church-heaton-norris -- mention only
d = {f:"" for f in fields}
d["file"] = "christ-church-heaton-norris.md"
d["V20"]="0"
d["V21"]="0"
for v in ["V19","V22","V23","V24","V25","V26","V29","V30","V31","V32"]:
    d[v]="9"
d["V27"]="0"
d["V28"]="0"
d["quotes"]=""
d["note"] = ("B_status is mention only ('no visitor access to either the churchyard or the interior' is stated twice; this collector read the "
  "blanket no-access statement as naming no attribute of hiring in the codebook's closed sense, the same reasoning applied to Umberslade Baptist "
  "Church elsewhere in this batch), so per §A7/Amendment 1.1's table the B-only group (V19, V22-V26, V29-V32) is 9 before any reading, and only "
  "V20, V21, V27, V28 are coded from Scope A, all 0 for want of any viewing/admission/comparative/utility statement about this specific church. "
  "The Local Community Officer contact is for 'further information' about visiting a tower with no public access, not an arrival route to any hire "
  "offer, so it is not read into V20.")
rows.append(d)

with open("/tmp/claude-1000/-usr-local-src-aesop-pmf-sage/71556939-dbe7-4408-8703-686f4079d0ba/scratchpad/shard-03.tsv","w",newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(fields)
    for d in rows:
        w.writerow([d.get(k,"") for k in fields])

print("wrote", len(rows), "rows,", len(fields), "columns")

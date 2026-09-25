I have what I need across all three passes. Here is the finding.

---

# Daytime wedding offers: three passes

**The headline number: 1.** Exactly one venue in the whole corpus publishes a daytime figure with no party-size condition, beside an evening figure — **Sol Gardens** (Pass A). Pass B and Pass C return zero.

| Pass | Denominator (coded units) | Publish a daytime offer | Daytime **figure**, **no party-size condition**, **beside an evening figure** |
|---|---|---|---|
| A — R1 catchment | 36 (own-site excluded) | 6 | **1 / 36** |
| B — R2/C reference ring | 25 | 2 | **0 / 25** |
| C — international | 101 | 1 | **0 / 101** |

Two denominator corrections to the brief: the R1 coded folder holds 37 records (36 catchment + `own-site`), not the 33 frame rows — three re-check units (Sarabah Estate Winery, Colliston Farm, Providence Farm Hall) sit outside the frame's own table and are coded. And the international cell holds **112** coded files, not 72: 82 in b01–b09 plus a 30-unit heritage supplement in h01–h03. Of those 112, five were screened out before coding and six carry zero or unreachable wedding scope (coded 9 throughout), leaving 101 units with a wedding offer.

---

## PASS A — R1 catchment (denominator 36)

### The one that passes: Sol Gardens

Row 1, "Full Day", publishes three day bands of one 8-hour package on the same page and in the same brochure pricelist:

- `"Monday to Thursday *Until 6pm"` — **$7,000** (2026 and 2027)
- `"Sunday *Until 6pm"` — **$8,000** (2026 and 2027)
- `"Friday & Saturday *Until 10pm"` — **$8,800** (2026), **$9,500** (2027)

(V8 records 1–4, source: wedding-packages page; brochure pricelist; the $8,800 also on the home page as `"Have it all for an incredible $8,800"`.)

1. **Figure**: yes, firm. `V6` = 5 on this row.
2. **Party-size condition**: none. `pcr_headcount_condition_verbatim` = not stated on all six Full Day PCRs; V4 records `"no qualifying capacity statement. The Full Day package publishes no guest number anywhere on the page or in the brochure"`, `V4_max_band` = 0, `V4_min_guests` = 0 on every row.
3. **Evening beside it**: yes, the same package's Friday & Saturday band, `"*Until 10pm"`, at $8,800 / $9,500.

The daytime block is `"8hrs"` (page) / `"8 Hours Wedding Experience"` (brochure), `V5_end_time_stated` = 1, `"*Until 6pm"`.

### The five that come close, and exactly what stops each

**Kwila Lodge** — stopped by party size on both daytime rows.
`"Exclusive use of the Kwila Lodge grounds for 2 hours (4pm finish at the latest)"` at $4,000 (2026) / $4,500 (2027), and `"4 hours (6pm finish at the latest)"` at $8,000 / $8,500 — both from the packages PDF. Beside them, `"Exclusive use of the Kwila Lodge grounds for 10 hours (11pm finish)"` at $14,000–$17,000 across day and year bands. Figures and the evening beside are both present. But row 1 states `"Up to 20 people"`, row 2 states `"Up to 40 people"` and the row's own name is `"micro wedding"`.

**The Bower Estate** — same shape, same stopper, plus a silent evening.
`"Exclusive use of The Bower Estate for 2 hours (6pm finish at the latest)"` at $4,500 / $6,700, and `"Exclusive use of ceremony & cocktail location for 4 hours (6pm finish at the latest)"` at $7,500 / $9,750 (PDF pp.10–11). Both carry `"Up to 20 guests"` / `"Up to 40 guests"`, and both are `"grouped under 'Micro Wedding Packages' in site navigation"` with R2 adding `"up to 40 of your closest family and friends"`. The full wedding package beside them ($13,200–$17,500, PDF p.12) states `"Exclusive use of the Estate for 8 hours"` with **no end time at row level**, so no evening is stated for it either.

**Cedar Creek Estate Vineyard & Winery** — the cleanest daytime/evening pair in the corpus, and not a figure anywhere.
Two packages each publish two sessions under one name: `"Daytime Event: 11am – 6pm"` against `"Night-Time Event 3pm-10pm"` (Cedar Premium and The Winery package cards and landing pages). A third, The Terrace, is wholly daytime: `"This Package is 5 hours: Ceremony 11:00am – 1:00pm Reception 1:00pm – 4pm."` But `V6` = 2 on all six rows — `"No number, but a price route is stated"` — and the only figure anywhere in scope is `"$200 Premium Beer Tab"`, a beverage add-on. Rows 2 and 3 additionally carry `"Minimum 40 ADULTS**(**Minimum of 65 adults when booking in April, May, September, October, November)"`; The Terrace carries `"Up to 20 ppl"`.

**Sol Gardens' other two rows** — both fail where Row 1 passes.
Row 3, Last Minute Deal, is a genuine daytime/evening price pair — `"Sunday–Thursday… finish by 6PM"` at **$4,000** against `"Friday & Saturday… finish by 10PM"` at **$6,000** — but carries `"Up to 70 guests"`. Row 2, Intimate Weddings, is `"Up to 3 hours"`, `"*Until 6pm"`, at `"From $2,500"` / `"From $3,000"` — a from-price, plus `"Maximum of 50 guests"` and the row's own name.

**Coolibah Downs Private Estate** — a named lunch wedding, no figure, and a ceiling.
FAQ: `"For small intimate weddings and elopements we also have a boutique luncheon wedding package available for under 40 adult guests."` No figure exists anywhere on the site (every price runs through a form-gated Prospectus), and `"under 40 adult guests"` is a stated ceiling.

**Pethers Rainforest Retreat** — a daytime window, no figure, and a capacity band.
The "Intimate Dining" package states `"Lodge reception from 12pm to 3pm or 4pm to 10pm"` with `"Ceremony at 11am or 3pm"` (the coder left the block undecidable because the text does not state which ceremony binds which reception). `V6` = 2 on all six rows, no package figure anywhere in the 15-page brochure; the row states `"Capacity 15-28"` and is named `"Intimate Dining"`.

**A near-miss worth naming:** Pacific Beach Function Centre publishes `"Ceremony Only"` at **$1800** with `"From 1pm"` — an afternoon start with **no stated finish**, so `V5_block_band` = 0. Under the silence rule that is no daytime offer; it sits beside `"7 Hour Event… Based on 4pm - 11pm"` at `"From $3500"`.

### own-site (reported, excluded from the totals)

`own-site` publishes **no daytime offer**. Its five rows state block lengths without a daytime window: `"3-hour exclusive venue use"`, `"Up to 8 hours of exclusive venue use"`, `"8 hours of exclusive venue use from 3:00 PM (setup not included)"`, `"Exclusive chapel hire (minimum 2 hours)"`, `"8 hours exclusive venue use"`. The record states plainly: `V5_end_time_stated` — `"not stated on any row"`. The only clock time published is a 3:00 PM start, which is an evening-running block. Its priced rows all carry a ceiling in the row's own name (`"Up to 20 Guests"`, `"Up to 40 Guests"`, `"Up to 65 Guests"`, `"Up to 100 Guests"`), at $1,700–$6,000 across two day bands.

### Silence

**14 of 36** state no hire window at all — no block, no clock interval, no end time: Binna Burra Lodge, Hampton Estate Wines, Hilltop Estate, InterContinental Sanctuary Cove, Kirra Beach House, Secret Garden Estate, Sheraton Grand Mirage, Southport Yacht Club, Tamborine Mountain Glades, The Old Church, The Valley Estate, Nathan Valley Foliage Farm, Glenrock Farm (access periods only, `V5_end_time_stated` = 0), Currumbin Sanctuary Events (ceremony start times only, no block). A further **4** state a block length with no time of day (Albert River Wines, Bearded Dragon Hotel, Mondrian Gold Coast, Woodstock Farm), **10** state an evening or late window only, and **2** carry no coded offer at all (Providence Farm Hall, unreachable, coded 9 throughout; Sarabah Estate Winery, screened out).

---

## PASS B — R2/C reference ring (denominator 25)

Two venues publish a daytime offer. Neither clears the bar.

**Kooroomba** — Row 2, `"ELOPEMENT PACKAGE"` (brochure cover) / `"Intimate Weddings"` (page heading): `"Exclusive use of chapel 11am - to 12pm"` and `"Shared use of Restaurant 1pm - to 3pm"`, priced at **$6,500**. Beside it, Row 1's venue hire publishes firm figures — `"Tuesday $10,000 Thursday $11,500 Saturday $13,000"` plus `"Friday $6000 without accommodation"` across 2026/2027/2028 brochures. **Stopped by party size**: `"(max 20 guests)"`, restated twice, with `"Guest count includes you two, bridal party and children (No additional Guests can be added)"`. A second weakness: Row 1 states no time block at all (`"for the duration of your event"`), so what sits beside the daytime offer is not stated to be an evening one.

**Tocal Homestead** — Row 2, `"Ceremony Only"`: `"The site hire fee is strictly for 2 hours at $1,300.00 including GST"`, `"available for ceremony only hire between 10 am - 12 midday, during peek [sic] season and most weekends."` **Stopped twice**: by party size — `"Ceremony only is limited to 100 guests"` — and by the third test, because the full wedding beside it publishes no number. Row 1 is `V6` = 2: `"Per person prices are bundled to include your Venue Hire, Dinner menu & 5 hour Beverages Package"` with the one linked pricing PDF returning HTTP 404.

**A near-miss of the opposite shape:** Sandhole Oak Barn publishes a full **Daytime / Evening** minimum-spend matrix with figures — daytime £3,900–£7,800 and evening £1,150–£1,700, across five seasonal bands × three years (menu PDF p.3). But the daytime figures are a minimum-spend session *inside one wedding day*, not a purchasable offer that ends before evening; the row states no hire block (`V5_block_band` = 0) and the venue's `"maximum daytime capacity is 140"` runs on into `"maximum evening capacity is 180"`. What Sandhole actually sells as a separate, ending-elsewhere product is the reverse: `"Evening-only receptions (venue access from 5pm) cost £1,500 Sunday-Thursday or £2,000 Friday-Saturday."`

**Silence**: 4 of 25 state no hire window at all — Farthingloe Barn, The Gardens Club, The Homestead Berry, Sine Cera. Two further units carry no captured scope (Buttai Barn, whole-scope network failure; Woodlands of Marburg, entire domain serving a refurbishment notice), both coded 9 throughout.

---

## PASS C — international (denominator 101)

**Zero.** One unit in 101 publishes anything that reads as a daytime wedding offer, and it publishes no figure of any kind.

**Duart Castle** (h03) — `"During April (1st to 30th) and October (1st to 18th)… ceremonies to take place in the morning or from 4.30pm… from May to September, weddings can take place from 5.30 pm… We also welcome morning weddings before the Castle opens."` **Stopped on every count**: `V5_block_band` = 0 on every row (start-time windows only, no length); `V6` = 2 on every row — `"Please email us at weddings@duartcastle.com or fill out the form below for more information about wedding packages and rates"` — so no daytime figure and no evening figure; and the morning framing carries no guest condition of its own beyond each room's capacity.

Four other international units use daytime vocabulary without selling a daytime offer, and each is worth naming so the zero is not mistaken for a thin search:

- **East Riddlesden Hall** (h01) publishes a clean session split with firm figures, but the *separately sold* session is the evening one: `"Evening Wedding Reception Only"`, `"(6pm – Midnight)"`, £2,490–£3,490, against full-day bands at £3,990–£5,490 for which `pcr_time_block_verbatim` = not stated.
- **Winters Tale Country Barn** (b03) sells a time-shifted product in the other direction — `"Twilight"`, `"Relaxed afternoon ceremonies without the rush, with ceremonies at 5pm."`
- **Huntsmill Farm** (b02) and **Winters Tale** both split *capacity and catering* daytime from evening within one wedding (`"Up to 100 daytime wedding guests"` / `"Up to 150 evening weddings guests"`; `"your daytime Wedding Breakfast Caterer"`), never price or sell the daytime alone.
- **Gwrych Castle** (h03) prices a 2-hour ceremony hire (`"Maximum duration of 2 hours for the civil ceremony, to include ceremony and photos"`) beside `"Maximum duration of 5 hours from 6pm"` and a full venue hire — but the ceremony hire states no time of day, so it is placed in no option.

**Silence**: **49 of 101** state no hire window of any kind in their V5 — no block band, no end time, no clock time anywhere in the time-structure section. A further 52 state some time fact (most commonly a full-day access window into the small hours, or a curfew alone).

---

## Two things a reader should know about how these counts were built

**The silence rule bit hard, and mostly against the daytime side.** Venues that publish a block length with no time of day (Albert River Wines' `"7 hours"`, Mondrian's `"5 hours"`, Woodstock Farm's `"2hrs"`, Gwrych Castle's 2-hour ceremony hire) are in no bucket. A 5-hour block could start at 11am or at 6pm, and the text does not say. That is a real feature of the corpus rather than a coding artefact: the international units in particular overwhelmingly publish either a full-day access window (`"8am until midnight"`, `"from 9am to midnight"`, `"midday to midnight"`) or a curfew alone.

**The party-size test is where nearly every candidate died.** Of the nine venues across all three passes that publish something a couple could read as a daytime wedding, seven attach a ceiling, a micro/intimate/elopement name, or a stated band to it — and in five of those the daytime offer *is* the venue's small-wedding product, not a time variant of its normal one. Sol Gardens is the single case where the daytime session is the venue's ordinary full-size package, priced $1,800 and $800 below the same package's Friday-and-Saturday evening band, with no guest number published anywhere against it.
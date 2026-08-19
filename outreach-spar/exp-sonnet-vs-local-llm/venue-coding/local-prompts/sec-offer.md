### 4.1 V1 — Offer composition

**Level:** wedding-offer row. **Scope:** A-wedding / B-listing.

**Definition.** V1 records what stage or stages of the wedding day the row's offer is stated to cover, and at what scale. Each field 1/0/8/9. One row commonly sets several.

| Field | Sets when the row's text states |
|---|---|
| `V1_ceremony` | A wedding ceremony may be held at the venue under this offer |
| `V1_reception` | A wedding reception, wedding breakfast, dinner or party may be held at the venue under this offer |
| `V1_ceremony_only_option` | The ceremony is purchasable without a reception, as its own offer or its own price |
| `V1_reception_only_option` | The reception is purchasable without a ceremony, as its own offer or its own price |
| `V1_prewedding_event` | A rehearsal dinner, welcome drinks, or pre-wedding event is stated as part of this offer |
| `V1_postwedding_event` | A next-day breakfast, recovery brunch, or post-wedding event is stated as part of this offer |
| `V1_multiday` | The offer is stated to run over more than one day |
| `V1_elopement_tier` | The offer is stated to be an elopement, micro wedding, intimate wedding, small wedding, or minimony |
| `V1_full_wedding` | The offer is stated to be the venue's standard or full wedding offer, without a small-wedding qualifier |
| `V1_venue_only` | The offer is stated to be the space alone, with catering, styling or service arranged by the couple |
| `V1_packaged` | The offer is stated to bundle the space with at least one other named element |
| `V1_legal_ceremony` | A legally registered marriage may be held at the venue: a licence, a registered building, an approved place, a registrar, or a stated legal ceremony |
| `V1_symbolic_only` | The text states the ceremony held there is symbolic, blessing-only, or not legally binding |
| `V1_vow_renewal` | A vow renewal or commitment ceremony is stated |

**Inclusion.** I1: the field is set by the row's own name, heading, description, bullet list, price line, or an in-scope linked document. I2: a stated guest ceiling at or below twenty guests attached to a named offer sets `V1_elopement_tier` only where the text also names the offer as small, intimate, elopement or equivalent; a ceiling alone sets nothing here and is coded at V4. I3: an offer that names both ceremony and reception sets both, and sets neither "only" field unless the text presents one without the other as purchasable. I4: a licence statement in Scope A-venue about the venue holding a marriage licence sets `V1_legal_ceremony` with `V1_source` = "venue-wide".

**Exclusion.** E1: a photograph of a ceremony arch sets nothing (S1). E2: an occasion named on another row sets nothing on this row (S8). E3: "weddings" as a bare word, with no stage named, sets `V1_ceremony` = 0 and `V1_reception` = 0, and `V1_stage_unstated` = 1. The coder does not decide that a wedding must include either. E4: a package label sets nothing (S9): "all-inclusive" does not set `V1_packaged`; an enumerated second element does. E5: an engagement party, hen or bucks offer sets nothing here.

**Ambiguous cases.**

- "Ceremony on the lawn, reception in the barn, one price" → `V1_ceremony` = 1, `V1_reception` = 1, `V1_packaged` = **1**, no "only" field set.
- "Ceremony only, \$1,200" listed beside two reception packages → `V1_ceremony_only_option` = **1** on its own row under §2.4.
- "Elope with us — up to 20 guests" → `V1_elopement_tier` = **1**, and V4 records the twenty.
- "Weddings at the estate" and nothing further about stages → `V1_stage_unstated` = **1**, both stage fields 0.
- "We are a registered venue for legal ceremonies" → `V1_legal_ceremony` = **1**.
- "Two-day exclusive hire, Friday setup and Saturday wedding" → `V1_multiday` = **1**, and V5 codes the block.

### 4.2 V2 — Spaces and settings offered

**Level:** wedding-offer row. **Scope:** A-wedding / B-listing.

**Definition.** V2 records what kinds of space the row offers, separately for the ceremony and for the reception, taken from what the text calls the space. Each field 1/0/8/9.

Ceremony fields: `V2_c_indoor_room`, `V2_c_chapel_church`, `V2_c_garden_lawn`, `V2_c_beach_waterfront`, `V2_c_barn_shed`, `V2_c_marquee_tent`, `V2_c_covered_outdoor` (rotunda, pavilion, arbour under cover, verandah), `V2_c_paddock_field_orchard`, `V2_c_forest_bush`, `V2_c_rooftop_terrace`, `V2_c_other`.

Reception fields: `V2_r_indoor_room`, `V2_r_barn_shed`, `V2_r_marquee_tent`, `V2_r_covered_outdoor`, `V2_r_open_outdoor`, `V2_r_restaurant_bar`, `V2_r_whole_venue`, `V2_r_other`.

Additional fields: `V2_multi_space` (1 where the row states the offer covers more than one space), `V2_wet_weather_alt` (1 where an alternative space is stated for wet weather; the wording verbatim), `V2_ceremony_location_choice` (1 where the row states a choice of ceremony locations; the locations verbatim in `V2_c_locations_verbatim`), `V2_space_names_verbatim` (every space name as published, in order), `V2_offsite_ceremony` (1 where the text states the ceremony may be held away from the venue).

**Inclusion.** I1: the space kind is taken from the venue's own noun, in the row's name, heading, description or an in-scope capacity chart. I2: a space named only in a linked in-scope document sets its field, with `V2_source` = "document". I3: a stated wet-weather alternative sets its own kind field and `V2_wet_weather_alt`. I4: a listing's structured space or room panel sets the fields its labels name.

**Exclusion.** E1: a space the coder recognises in a photograph sets nothing (S1). E2: a space named in the venue's history, accommodation or restaurant text with no wedding statement in scope sets nothing; record in `V2_notes`. E3: a getting-ready room, bridal suite, green room, kitchen, car park or toilet block is not a ceremony or reception space; those are elements at V11. E4: a proper name carrying no kind word sets nothing: "The Willows" states no kind. E5: the coder never assigns a kind from a floor plan's shape or from the venue's category.

**Ambiguous cases.**

- "Say your vows under the fig tree, then dine in the woolshed" → `V2_c_garden_lawn` = 1, `V2_r_barn_shed` = **1**, `V2_multi_space` = 1.
- "Ceremony in the chapel or on the terrace, your choice" → `V2_c_chapel_church` = 1, `V2_c_rooftop_terrace` = 1, `V2_ceremony_location_choice` = **1**, locations verbatim.
- "Should it rain, we move inside to the Long Room" → `V2_wet_weather_alt` = **1**, `V2_r_indoor_room` = 1.
- "The Meadow" with no kind word anywhere → every field 0 and `V2_c_other` = **8**, quoted.
- "Exclusive use of the property" with no space nouns → `V2_r_whole_venue` = **1**, no other field.
- "We will travel to your ceremony site and host the reception here" → `V2_offsite_ceremony` = **1**, and the reception fields coded normally.

### 4.3 V3 — Layouts stated

**Level:** wedding-offer row. **Scope:** A-wedding / B-listing.

**Definition.** V3 records which seating or standing layouts the row's text states its spaces support, because a capacity figure means nothing without the layout it belongs to.

Fields, each 1/0/8/9: `V3_ceremony_rows` (aisle and seated rows for a ceremony), `V3_ceremony_standing`, `V3_seated_round_tables`, `V3_seated_long_tables`, `V3_seated_unspecified`, `V3_standing_cocktail`, `V3_theatre`, `V3_dance_floor_within` (a layout stated to include a dance floor within the seated space), `V3_layout_other`, `V3_layout_flexible_claim` (the text states the layout can be arranged to suit, with no named layout).

`V3_layout_verbatim` records every layout label as published, in order.

**Inclusion.** I1: a layout named beside a capacity figure, in a capacity table, or in an in-scope capacity chart. I2: a layout named in prose without a figure still sets its field. I3: a layout label published inside an image with legible text sets its field (S1). I4: a platform's structured layout field sets the fields its labels name.

**Exclusion.** E1: a furniture list is not a layout: "we have twelve trestle tables" sets nothing here and is recorded at V11. E2: a floor-plan drawing sets nothing unless it carries a legible layout label. E3: "flexible space" alone sets `V3_layout_flexible_claim` and no named field. E4: a layout named for a different row sets nothing (S8). E5: a photograph of round tables sets nothing (S1).

**Ambiguous cases.**

- A table headed "Ceremony 150 / Seated 120 / Cocktail 200" → `V3_ceremony_rows` = 1, `V3_seated_unspecified` = 1, `V3_standing_cocktail` = **1**, labels verbatim.
- "Long tables down the length of the barn" → `V3_seated_long_tables` = **1**.
- "Seats 100 with room for a dance floor" → `V3_seated_unspecified` = 1, `V3_dance_floor_within` = **1**.
- "Set the space however you wish" → `V3_layout_flexible_claim` = **1**, every named field 0.
- "Capacity 180" with no layout word → every field **0**, and V4 records the figure with layout "not stated".
- "Rounds of ten" → `V3_seated_round_tables` = **1**.

### 4.4 V4 — Capacity by layout

**Level:** wedding-offer row, with one capacity record per stated layout and stage. **Scope:** A-wedding / B-listing.

**Definition.** V4 records the stated guest-number capacities of the row, each tied to the layout and the stage it is published against, and bands the highest stated capacity.

A qualifying statement contains all three of: a cardinal number or numeric range; a unit that counts people (guests, people, persons, pax, seated, standing, attendees); and a capacity or limiting construction (up to, maximum, seats, accommodates, capacity, holds, comfortably fits, from X to Y, minimum, no more than).

Each capacity record carries `V4_stage` (closed: `ceremony`, `reception`, `not_stated`), `V4_layout` (from V3's closed list, or `not_stated`), `V4_figure_verbatim`, `V4_construction_verbatim`, `V4_space_verbatim`.

`V4_max_band` bands the **highest** stated capacity for the row.

| Code | Band |
|---|---|
| 1 | Maximum 1 to 20 |
| 2 | Maximum 21 to 50 |
| 3 | Maximum 51 to 100 |
| 4 | Maximum 101 to 150 |
| 5 | Maximum 151 to 250 |
| 6 | Maximum 251 to 400 |
| 7 | Maximum over 400 |
| 0 | No capacity stated |
| 8 | Undecidable |
| 9 | Scope not captured |

`V4_min_guests` records a stated minimum guest number as an integer, or 0 where none is stated. `V4_min_guests_condition_verbatim` records the condition attached to it: a day, a season, a package. `V4_guest_ceiling_verbatim` records a stated ceiling attached to a named small-wedding offer.

**Inclusion.** I1: a capacity table, chart, or line in an in-scope document. I2: a platform's structured capacity field sets a record with stage and layout `not_stated` unless the field names one, and `V4_set_by` = "platform". I3: a range sets a record at each end, both recorded, and `V4_max_band` takes the upper end. I4: a minimum guest number stated as a condition of hire, or a minimum number charged for, sets `V4_min_guests` and is also a V9 commitment. I5: separate capacities for a ceremony and a reception each take their own record with their own stage.

**Exclusion — no record, and `V4_max_band` = 0 — when.** E1: a licensed, fire or council capacity stated for the venue as a whole and not for the row's spaces; record in `V4_venue_capacity`. E2: a count of things that are not guests: chairs, tables, car spaces, beds, bedrooms, marquee square metres, acres. A bed count is not a guest capacity and goes to `V4_other_counts`. E3: a minimum spend or a per-head minimum expressed in money; deriving a headcount from it is forbidden (S4). E4: a past-event boast: "we have hosted 300 here". E5: vague size language with no number: "large weddings welcome", "intimate gatherings". E6: a capacity stated only outside the row's scope (S8); set `V4_out_of_scope` = 1.

**Ambiguous cases.**

- "Ceremony for 150, seated dinner for 120" → two records with their own stages; `V4_max_band` = **4**.
- "Up to 200 guests" with no stage and no layout → one record, both `not_stated`, `V4_max_band` = **5**.
- "Minimum 60 guests on a Saturday" → `V4_min_guests` = 60, condition verbatim, band unchanged.
- "The barn seats 120 and the marquee another 80" → two records; `V4_max_band` = **8**, quoted, because no combined figure is stated and adding them is arithmetic (S4).
- "Sleeps 24" on an accommodation panel → band unchanged, figure to `V4_other_counts`, and V18 codes the accommodation.
- "Elopements for two to twelve" → `V4_min_guests` = 2, one record at 12, `V4_guest_ceiling_verbatim` recorded, `V4_max_band` = **1**.

### 9.1 V21 — Enquiry and booking routes

**Level:** unit for type A, listing for type B. **Scope:** A-wedding extended to Scope A-venue for a contact route published site-wide / B-listing extended to B-platform.

**Definition.** V21 records every route by which the text says a couple may enquire or book. Each field 1/0/8/9.

| Field | Route | Sets when the scope shows |
|---|---|---|
| `V21_instant_book` | Instant booking | A flow stating the booking is confirmed on completion, with date and payment taken online, and no stated human step |
| `V21_online_request` | Online request | A flow or form producing a request, a hold, a pending booking, or an availability check by staff |
| `V21_enquiry_form` | Enquiry form | A form on the page collecting the couple's details |
| `V21_form_fields_verbatim` | The enquiry form's field labels, verbatim, in order |
| `V21_email` | An email address is published |
| `V21_phone` | A telephone number is published |
| `V21_messaging` | A live chat widget, WhatsApp, Messenger or SMS route is published |
| `V21_pack_request` | A route to request a brochure, pricing guide or wedding pack |
| `V21_third_party` | The scope directs the couple to a directory, marketplace or third-party booking site |
| `V21_calendar_shown` | An availability calendar showing dates is displayed |
| `V21_pdf_form` | A downloadable booking form to be returned |

`V21_lowest_friction` records one closed value taken as the lowest-friction route the scope publishes, in this order: `instant`, `request`, `form`, `message`, `phone`, `pack`, `none`.

**Inclusion.** I1: a route is set by a working, visible control or a published contact detail. I2: a button label naming a route sets that route even where the coder does not click it. I3: a phone number in the header or footer of a page inside the scope sets `V21_phone`. I4: for type A, a phone number or email published site-wide on the contact page sets its field with `V21_source` = "venue-wide".

**Exclusion.** E1: a coder never submits a form, creates an account, enters card details, requests a pack, or completes a booking, because doing so would obtain material no couple can read without asking and would corrupt the measurement V6 makes. Where a flow cannot be read further without transacting, the route is coded from what is visible and `V21_flow_truncated` = 1. E2: a social media profile link is not a messaging route unless the scope names messaging as an enquiry route. E3: a bare "contact us" link with no detail behind it inside the scope sets nothing; record it. E4: where a flow does not state that the booking is confirmed, `V21_online_request` = 1 and `V21_instant_book` = 0, because the codebook resolves that ambiguity by rule rather than by the coder's guess.

**Ambiguous cases.**

- A widget with a date picker, a card field and "Confirm and pay" → `V21_instant_book` = **1**.
- "Send us your date and we will reply within 48 hours" → `V21_online_request` = 1, and the promise is coded at V28.
- An enquiry form asking for date, guest numbers and budget → `V21_enquiry_form` = 1, `V21_form_fields_verbatim` recorded, `V21_lowest_friction` = **"form"**.
- "Download our pricing guide" behind an email field → `V21_pack_request` = **1**, the wall recorded under §13.2, and V6 coded 2.
- An email address published as an image → `V21_email` = **1**. Text in an image is text (S1).
- A wedding page with no contact detail and a site-wide phone number on the contact page → `V21_phone` = 1, source "venue-wide".

### 9.2 V22 — Viewing mechanics

**Level:** unit for type A, listing for type B. **Scope:** A-wedding extended to Scope A-venue for a site-wide events calendar / B-listing.

**Definition.** V22 records how a couple gets to see the venue before booking, which in this market is a step of the sale rather than a courtesy.

| Field | Content |
|---|---|
| `V22_private_tour` | 1 where a private tour, inspection or site visit is offered |
| `V22_tour_by_appointment` | 1 where tours are stated to be by appointment only |
| `V22_tour_booking_route` | The route by which a tour is arranged, closed: `online_booking`, `form`, `email`, `phone`, `not_stated` |
| `V22_tour_days_times_verbatim` | Stated days or times for tours, verbatim |
| `V22_tour_charged` | 1 where a charge for a tour is stated; figure to V8 |
| `V22_open_day` | 1 where an open day, open house or inspection day is stated |
| `V22_open_day_dates_verbatim` | The stated open-day dates, verbatim |
| `V22_open_day_registration` | 1 where registration for an open day is required |
| `V22_wedding_fair_attendance` | 1 where the venue states it attends or hosts a wedding fair or expo |
| `V22_styled_shoot_event` | 1 where a styled-shoot evening, showcase or twilight event is stated |
| `V22_virtual_tour_offered` | 1 where a virtual tour, 360-degree view or video walkthrough is offered as a viewing route |
| `V22_video_call_offered` | 1 where a video call, online consultation or remote meeting is offered |
| `V22_tour_required_before_booking` | 1 where the text states a visit is required before a booking is accepted |
| `V22_no_tour_stated` | 1 where the text states tours are not offered |

**Inclusion.** I1: any of these stated in the scope, including an events panel inside scope. I2: a bookable tour widget sets `V22_private_tour` = 1 and `V22_tour_booking_route` = "online_booking". I3: an open day listed with a past date still sets `V22_open_day` = 1, with the date recorded verbatim, because the study records what the page tells a couple on the capture date.

**Exclusion.** E1: a public ticketed event at the venue that is not a wedding viewing sets nothing; record it. E2: a photograph gallery is not a virtual tour; the field requires a stated tour, walkthrough or 360-degree view. E3: the coder never books a tour, submits a tour form, or telephones. E4: "come and see us" with no route sets `V22_private_tour` = 1 only where the text states a visit is available; a closing pleasantry with no arrangement sets nothing, and the phrase is recorded.

**Ambiguous cases.**

- "Book a private tour" with a calendar widget → `V22_private_tour` = 1, `V22_tour_booking_route` = **"online_booking"**.
- "Inspections by appointment, Tuesdays and Thursdays" → `V22_private_tour` = 1, `V22_tour_by_appointment` = 1, days verbatim.
- "Join us for our Spring Open Day, 14 September, registration essential" → `V22_open_day` = 1, date verbatim, `V22_open_day_registration` = **1**.
- "We are at the Coast Wedding Expo in March" → `V22_wedding_fair_attendance` = **1**.
- "Take our 360 tour" → `V22_virtual_tour_offered` = **1**, and V26 records the virtual tour as documentation.
- "We do not offer walk-ins" and nothing else about tours → `V22_private_tour` = **0**, phrase recorded; a refusal of walk-ins states no tour route.


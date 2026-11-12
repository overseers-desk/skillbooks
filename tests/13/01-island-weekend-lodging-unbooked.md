# Test 13, case 01: an island weekend with the lodging unbooked

A family of four flies to one of the Canary Islands for two nights: two parents and two children aged 12 and 7. On the last day the party splits at the island's airport. One parent and the children fly home in the afternoon, and the other parent flies on to a conference. The flights and a car park at the home airport are booked; lodging, car hire and activities are not. The run starts two days before departure, with the cheapest refundable room rates expiring that night.

The travellers' reference data gives one parent a deal breaker, car sickness as a passenger beyond about 45 minutes, which makes a taxi workable only for short legs and a hire car workable when that parent drives. It gives a pool as a preference for hotel stays, and a hotel loyalty programme. The programme has no hotel on the arrival island. Its nearest hotel with a family room is on a neighbouring island, two hours away by fast ferry, with one usable sailing each way and a price several times that of a holiday apartment on the arrival island.

The journey folder holds only the ticket PDFs and the car-park record: no extraction, research or itinerary.

## Prompt

Plan our [island] weekend, [dates]: follow sop-travel-master.md.

(The runner added, as harness only: the local path standing in for the shared travel folder; and "Wait for any subagents you start before you finish.")

## Yardstick

No single right plan exists. A plan passes on common sense:

1. A reader can tell what is booked and what is proposed. Proposed items carry when they were checked and the price seen; booked items their booking date and reference.
2. The lodging search spans the arrival island's main areas, hotels and holiday rentals, and the loyalty programme. The programme's family room across the water is found and weighed against its journey and price, not chased and not missed.
3. One base, chosen with transfer time against what the base gives. No hotel change and no ferry unless the gain clearly pays for it.
4. The deal breaker and the preference keep their stated degree.
5. Not a minute-by-minute script.
6. No factual error against the tickets.

Critical: 1, 2 (missed or chased), 3, 4, 6. Minor: wording, an option left unchecked and said so.

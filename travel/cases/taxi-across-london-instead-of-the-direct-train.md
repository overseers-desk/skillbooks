# Taxi across London instead of the direct train

**The situation.** A family of four landed around midday at an airport on London's northern edge, with luggage, and had a hotel in south London. One train line served both ends: a transfer from the terminal to the airport's station, then about 50 minutes at a fixed time. The afternoon was planned for an outing near the hotel. The next day the family flew out of another London airport.

**The advice.** The AI (Fable) recommended a taxi for the arrival leg. Its reasons: with four people a taxi was no dearer than four train fares, it was readily available with no wait, and it saved the transfer at the station.

**What happened.** The car's navigation routed it through central London in afternoon traffic. The transfer took about four and a half hours. The family arrived in the early evening and the afternoon outing was abandoned.

**What the advice missed.**
- **Road time varies with traffic; the train's does not.** The advice compared money and convenience, and treated the time as a fixed cost. A cross-London road leg in the afternoon has a bad case several times its typical one. The train's bad case is close to its timetable.
- **The same hazard was weighed on the other leg and not on this one.** For the departure leg, with a flight deadline, the same planning had warned of road congestion and recommended the train. With no deadline on the arrival leg, the car was called "fine". The bad run also costs something without a deadline: here, the afternoon.
- **The price comparison ran the wrong way once checked.** Priced for the actual route, the car cost more than the family's train fares, not the same.

**The rule it produced.** `../sop-mental-journey-simulation.md`, Grounding, "Time on the road": a traffic-variable leg gets a typical run and a bad run, and rail legs get their actual journey time. The symmetry check (a hazard found on one leg is tested on the matching leg) sits in the same comparison.

**To re-run it.** Ask a planner how a family of four with luggage should get from an airport on London's northern edge to south London at midday, where one train line serves both ends after a transfer at the airport. The case passes when the answer weighs the road's afternoon bad case against the train's fixed time before money.

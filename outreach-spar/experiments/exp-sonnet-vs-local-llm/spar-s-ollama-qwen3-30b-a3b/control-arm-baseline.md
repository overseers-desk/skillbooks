# Control arm, measured accuracy

The hosted arm's rows are the yardstick the local arm is compared against, and nobody had checked how many of them are right. This records what checking found, and what checking turned out to be able to measure.

## Pilot, `supplier-horse-breeder`, eight of nine rows

The sample is the deterministic one `compare-rosters.py --sample` selects. The checker was told nothing about arms, models or this experiment, and was given the two questions and the catchment file.

Exists: six yes, two unconfirmed, none shown to be invented. Confirmed by a stud's own site, an Australian Stock Horse Society directory entry, Select Sires stallion records, or sale results, in each case something other than the roster's own citation.

In catchment: three yes, five unconfirmed, none out.

The two unconfirmed on existence are B. Welsh and Holly Holden, both recorded under a person's name rather than a trading name. Neither is evidence of invention. A private seller who advertises nowhere leaves no trace to find, which is precisely the kind of supplier this segment wants.

## What the catchment question turned out to measure

Five unconfirmed in eight is not a finding about the businesses. It is a finding about the test.

Two rows carry no postcode at all, so there is nothing to place them by. Two more are real and findable but publish no address: one is a sales consultancy whose listings sit on other people's properties, the other trades through a Facebook page with a phone number and no location. The fifth is a stud whose address sits behind a login.

So the catchment question answers "unconfirmed" whenever a business is real but private about where it is, which is common in this trade. A measure that returns unconfirmed for most of its sample cannot separate two arms, and reporting it as though it could would make noise look like a difference.

It stays in the method, because a row placed outside the catchment is still worth catching. It is reported as a count of three outcomes and never collapsed into a percentage, and the comparison does not rest on it. Existence carries the weight.

## A constraint on how the rest is measured

Both arms' samples get checked the same way or the comparison is worthless. The built-in web search runs against a per-session pool shared with every other agent, and one segment of eight rows cost roughly twenty searches. Five segments for each arm would exceed it, and the arm checked after the pool ran dry would be measured with a different instrument than the one checked before.

So the remaining control-arm verification waits until the local arm's rosters exist, and both are then checked in one pass under the same tooling. Measuring the control arm now, because there is idle time, would buy a baseline at the cost of the comparison it exists to serve.

## Noted for the roster format, not for this experiment

Two of eight sampled rows record no postcode, and both are sellers who work through listings rather than from a discoverable property. A location field that assumes a fixed premises does not fit a consultancy or a marketplace seller, and the roster currently has no way to say so.

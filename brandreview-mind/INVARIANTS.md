# MIND invariants

Hard rules the rest of the methodology does not contradict. When a procedure, brief or run disagrees with an invariant, the invariant wins and the other is the bug to fix.

## I1. A panel figure is read on the same instrument, window and market as the operator's figure, or the operator's figure is reported as unindexed

**Test:** for every operator figure a run attributes a movement to, does the panel column carry the same instrument kind, the same window and the same market on each side? A panel figure from another window or another instrument fails, a panel of one fails, and a movement described as the operator's own where no panel column exists fails.

Why: a movement read against no control cannot be attributed, and the reviews this methodology was drawn from show what that produces: a description that reads well on one date and cannot tell the operator's change from the market's.

## I2. A run reads the prior run before it measures

**Test:** does Measure open with the prior run's figures, its open decisions with their read dates, and its findings by number, before any new figure appears? A run with no such opening, where a prior run exists, fails, and so does one whose opening was written after the new figures.

Why: a run that measures first has redrawn a snapshot, and a series of snapshots redrawn from scratch cannot show a movement, however many of them there are.

## I3. A figure under an instrument's floor is reported as under the floor, never as zero, and enters no aggregate

**Test:** does any row read 0 where the instrument reported nothing or a band? Does any mean, share or delta include such a row? Either fails. An aggregate that struck such rows carries the count struck.

Why: a zero in a mean is a measurement that was never made, and the smallest names in a panel are exactly the ones an instrument cannot see, so the error lands on the comparison the operator most needs.

## I4. A decision names the finding it answers and the series that would show it worked

**Test:** does every row of the decision table carry a finding number, a series named by instrument and window, and a read date? A decision citing prose rather than a number, or naming no series, fails.

Why: a decision naming neither cannot be read at the next run, and the roadmap the review ends with becomes a list of wishes that no run can mark as kept or broken.

## I5. Nothing in this folder names a trading name, a panel member, an instrument vendor or a trade

**Test:** grep this folder for any campaign's trading name, any register member, any instrument's vendor name and any industry noun: zero hits. Instance names belong in the campaign folder, in the register, the instrument list and the runs.

Why: a name answerable by one industry alone, or a slot only one kind of business can fill, stops the method at that industry's edge, and a rename fixes only the first.

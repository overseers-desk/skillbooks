# LAMP invariants

Hard rules the rest of the methodology does not contradict. When a procedure, brief or run disagrees with an invariant, the invariant wins and the other is the bug to fix.

## I1. A capture lives in the operator's capture series, never in a run folder

**Test:** for any results page, Maps list or performance export a run cites, is the file under the operator's capture series with that series' naming? A file under the run's own folder fails.

Why: a capture inside a run is invisible to the next run and to the site-wide series, and gets fetched again at a cost.

## I2. No average is computed across a seam

**Test:** for any mean, share or before-and-after figure in a run, do both ends sit on the same side of every listed seam (provider anomaly window, page swap, tag change, rebuild)? A window that straddles one fails; the figure is split at the seam or not given.

## I3. An action is not proven by its deployment

**Test:** does the effect ledger row carry a before-and-after per-day reading over matched windows, with seams and season named, or the word "too early" with the date it can be read? A row saying only that the change was made fails.

## I4. The instance and the population are reported apart

**Test:** does Locate give the located capture (one searcher, one day) and the console series (all searches on which the site was shown) as two statements, with the gap between them stated? A run that presents one capture as the typical case, or the console average as what a searcher sees, fails.

## I5. Nothing product-specific belongs in the methodology

**Test:** does any file under this folder name a product, a query, a competitor, or a run's figure? If yes, it belongs in the run.

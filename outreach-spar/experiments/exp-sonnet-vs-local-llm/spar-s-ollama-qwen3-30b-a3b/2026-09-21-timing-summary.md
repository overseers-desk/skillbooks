# Timing harvest -- 2026-09-21 00:41:22 AEST

Segment filter: supplier-horse-owner
Journal window requested: --since '2026-09-20 19:00:00' from dappnode@dappnode
remote journal read with its own +08:00 offset; all comparisons done in UTC

Note: 7 request(s) in the fetched journal window predate this run's first dispatcher attempt (2026-09-20 22:00:11 AEST) and are excluded from every count and sum below (they are traffic from something earlier, not this segment's run); they remain in the per-request CSV for the record.

## Requests observed on the ollama journal (this run's window)
Total requests (new-prompt events): 14
  - aborted_or_superseded: 1
  - in_flight: 1
  - success: 12

Sum of prefill time across all requests (incl. in-flight/aborted, as observed so far): 5,696s (94.9 min)
Sum of generation time across all requests (as observed so far): 1,135s (18.9 min)
Average prefill rate over completed requests: 102.98 tok/s
Average generation rate over completed requests: 4.750 tok/s

In-flight requests (NOT zero-duration -- still running as of this harvest):
  - pid 103467 task 0: started 2026-09-20 23:53:31 AEST, prompt 21980 tok, 2,872s elapsed so far (47.9 min), generated 864 tok so far

## Server-side HTTP churn (all POST /v1/chat/completions|/api/generate closures, this run's window)
Total closures logged: 44
  200 OK: 2, total server time 463s (7.7 min)
  non-200 (client gave up before the server replied): 42, summed client-side dead time (arrival to abandonment) 32,426s (540.4 min)
Note: this sum is client-side elapsed time, not GPU-busy time -- with a single slot,
ollama can only actively compute on one request at a time (bounded by the run's own
wall-clock), so a sum this far above the wall-clock total means many callers were
queued at once, each accumulating wait in parallel clock time. It is the clearest
evidence of queue contention in this log, but it cannot be split into "queued" versus
"being computed" per abandoned request, and none of it can be attributed to a specific
worker, because ollama logs no request id linking a GIN closure back to a caller.

## Model (re)loads observed: 5
  - 2026-09-20 22:12:44 AEST, pid 99430
  - 2026-09-20 23:02:36 AEST, pid 101249
  - 2026-09-20 23:22:43 AEST, pid 101249
  - 2026-09-20 23:22:48 AEST, pid 101249
  - 2026-09-20 23:53:14 AEST, pid 103467

## Dispatcher attempts (pilot*.out) and worker-level view
### pilot.out  (segment=supplier-horse-owner, T0=2026-09-20 22:00:11 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=1s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=1s, requests_in_window=0, queue_wait=s, compute_in_window=0s
### pilot2.out  (segment=supplier-horse-owner, T0=2026-09-20 22:12:57 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:13:03 AEST, outcome=ended_by_operator (assumed, no FAIL line logged), elapsed=2757s, requests_in_window=6, queue_wait=1505s, compute_in_window=1,082s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
### pilot3.out  (segment=supplier-horse-owner, T0=2026-09-20 22:59:00 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:59:05 AEST, outcome=ended_by_operator (assumed, no FAIL line logged), elapsed=202s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
### pilot4.out  (segment=supplier-horse-owner, T0=2026-09-20 23:02:27 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 23:02:32 AEST, outcome=failed, elapsed=3003s, requests_in_window=6, queue_wait=21s, compute_in_window=2,959s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
### pilot5.out  (segment=supplier-horse-owner, T0=2026-09-20 23:52:51 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 23:52:56 AEST, outcome=ended_by_operator (assumed, no FAIL line logged), elapsed=475s, requests_in_window=1, queue_wait=35s, compute_in_window=1,284s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
### pilot6.out  (segment=supplier-horse-owner, T0=2026-09-21 00:00:51 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 00:00:56 AEST, outcome=in_flight, elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=s, requests_in_window=0, queue_wait=s, compute_in_window=0s

## Segment / run summary -- tonight's attempts for this segment
Total wall-clock across all attempts (T0 of first attempt to end/now of last): 9,672s (2.69 h)
Time the model was computing (prefill+generation, all requests observed): 6,831s (1.90 h)
Time that was something-else-waiting (wall-clock minus computing): 2,840s (0.79 h)

## Largest consumers of time (ranked)
The first two rows are actual compute, bounded by wall-clock. The third is
client-side dead time summed across every competing, eventually-abandoned caller
(see the churn note above) -- it is not additional compute, it is the queueing cost
the single slot imposed on everyone contending for it, and it is reported separately
because it cannot be added to the first two without double-counting wall-clock.
  - prefill (sum across requests, actual compute): 5,696s (94.9 min)
  - generation (sum across requests, actual compute): 1,135s (18.9 min)
  - queueing cost: summed client-side dead time across abandoned callers (not compute, see above): 32,426s (540.4 min)

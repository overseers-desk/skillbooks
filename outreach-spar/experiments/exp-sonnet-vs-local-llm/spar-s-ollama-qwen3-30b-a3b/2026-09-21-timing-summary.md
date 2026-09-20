# Timing harvest -- 2026-09-21 08:56:58 AEST

Segment filter: supplier-horse-owner
Journal window requested: --since '12 hours ago' from dappnode@dappnode
remote journal read with its own +08:00 offset; all comparisons done in UTC

Note: 8 request(s) in the fetched journal window predate this run's first dispatcher attempt (2026-09-20 22:00:11 AEST) and are excluded from every count and sum below (they are traffic from something earlier, not this segment's run); they remain in the per-request CSV for the record.

## Requests observed on the ollama journal (this run's window)
Total requests (new-prompt events): 61
  - aborted_or_superseded: 5
  - in_flight: 1
  - success: 55

Sum of prefill time across all requests (incl. in-flight/aborted, as observed so far): 16,008s (266.8 min)
Sum of generation time across all requests (as observed so far): 19,296s (321.6 min)
Average prefill rate over completed requests: 78.94 tok/s
Average generation rate over completed requests: 2.636 tok/s

In-flight requests (NOT zero-duration -- still running as of this harvest):
  - pid 114665 task 10511: started 2026-09-21 08:29:33 AEST, prompt 8431 tok, 1,646s elapsed so far (27.4 min), generated 2277 tok so far

## Server-side HTTP churn (all POST /v1/chat/completions|/api/generate closures, this run's window)
Total closures logged: 92
  200 OK: 17, total server time 46,280s (771.3 min)
  non-200 (client gave up before the server replied): 75, summed client-side dead time (arrival to abandonment) 95,077s (1,584.6 min)
Note: this sum is client-side elapsed time, not GPU-busy time -- with a single slot,
ollama can only actively compute on one request at a time (bounded by the run's own
wall-clock), so a sum this far above the wall-clock total means many callers were
queued at once, each accumulating wait in parallel clock time. It is the clearest
evidence of queue contention in this log, but it cannot be split into "queued" versus
"being computed" per abandoned request, and none of it can be attributed to a specific
worker, because ollama logs no request id linking a GIN closure back to a caller.

## Model (re)loads observed: 10
  - 2026-09-20 22:12:44 AEST, pid 99430
  - 2026-09-20 23:02:36 AEST, pid 101249
  - 2026-09-20 23:22:43 AEST, pid 101249
  - 2026-09-20 23:22:48 AEST, pid 101249
  - 2026-09-20 23:53:14 AEST, pid 103467
  - 2026-09-21 00:43:33 AEST, pid 105324
  - 2026-09-21 01:54:25 AEST, pid 107530
  - 2026-09-21 03:47:59 AEST, pid 111027
  - 2026-09-21 04:47:51 AEST, pid 113474
  - 2026-09-21 05:23:47 AEST, pid 114665

## Dispatcher attempts (pilot*.out) and worker-level view
### pilot.out  (segment=supplier-horse-owner, T0=2026-09-20 22:00:11 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=1s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:00:16 AEST, outcome=failed, elapsed=1s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot2.out  (segment=supplier-horse-owner, T0=2026-09-20 22:12:57 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:13:03 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2757s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2757s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2757s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2757s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:13:03 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2757s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot3.out  (segment=supplier-horse-owner, T0=2026-09-20 22:59:00 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 22:59:05 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=202s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=202s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=202s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=202s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 22:59:05 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=202s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot4.out  (segment=supplier-horse-owner, T0=2026-09-20 23:02:27 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 23:02:32 AEST, outcome=failed, elapsed=3003s, requests_in_window=6, queue_wait=21s, compute_in_window=2,959s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=3019s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=3019s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=3019s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=3019s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 23:02:32 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=3019s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot5.out  (segment=supplier-horse-owner, T0=2026-09-20 23:52:51 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-20 23:52:56 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=1s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=475s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=475s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=475s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=475s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-20 23:52:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=475s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot6.out  (segment=supplier-horse-owner, T0=2026-09-21 00:00:51 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 00:00:56 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=0s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2543s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2543s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2543s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2543s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 00:00:56 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=2543s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot7.out  (segment=supplier-horse-owner, T0=2026-09-21 00:43:19 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 00:43:24 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=1s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 00:43:24 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=4251s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 00:43:24 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=4251s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 00:43:24 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=4251s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 00:43:24 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=4251s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 00:43:24 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=4251s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot8.out  (segment=supplier-horse-owner, T0=2026-09-21 01:54:15 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 01:54:20 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=4146s, requests_in_window=3, queue_wait=22s, compute_in_window=4,302s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 01:54:20 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=10402s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 01:54:20 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=10402s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 01:54:20 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=10402s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 01:54:20 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=10402s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 01:54:20 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=10402s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### pilot9.out  (segment=supplier-horse-owner, T0=2026-09-21 04:47:42 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 04:47:47 AEST, outcome=ended_without_end_line (dispatcher exited; elapsed is a lower bound, measured to last log write), elapsed=1s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 04:47:47 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=9274s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 04:47:47 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=9274s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 04:47:47 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=9274s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 04:47:47 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=9274s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 04:47:47 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=9274s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
### spar-transition-test.log  (segment=supplier-horse-owner, T0=2026-09-21 07:22:21 AEST, 6 source(s))
  - sweep-supplier-horse-owner-horsezone-com-au: start 2026-09-21 07:22:26 AEST, outcome=in_flight, elapsed=5673s, requests_in_window=3, queue_wait=1s, compute_in_window=4,333s
  - sweep-supplier-horse-owner-horsedeals-com-au-search-endpoint: start 2026-09-21 07:22:26 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=5673s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-facebook-sale-and-lease-groups: start 2026-09-21 07:22:26 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=5673s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-gumtree-horses-and-ponies: start 2026-09-21 07:22:26 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=5673s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-biosecurity-queensland-property-identification-codes: start 2026-09-21 07:22:26 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=5673s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-supplier-horse-owner-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 07:22:26 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=5673s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s

## Segment / run summary -- tonight's attempts for this segment
Total wall-clock across all attempts (T0 of first attempt to end/now of last): 39,408s (10.95 h)
Time the model was computing (prefill+generation, all requests observed): 35,304s (9.81 h)
Time that was something-else-waiting (wall-clock minus computing): 4,104s (1.14 h)

## Largest consumers of time (ranked)
The first two rows are actual compute, bounded by wall-clock. The third is
client-side dead time summed across every competing, eventually-abandoned caller
(see the churn note above) -- it is not additional compute, it is the queueing cost
the single slot imposed on everyone contending for it, and it is reported separately
because it cannot be added to the first two without double-counting wall-clock.
  - generation (sum across requests, actual compute): 19,296s (321.6 min)
  - prefill (sum across requests, actual compute): 16,008s (266.8 min)
  - queueing cost: summed client-side dead time across abandoned callers (not compute, see above): 95,077s (1,584.6 min)

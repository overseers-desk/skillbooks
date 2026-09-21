# Timing harvest -- 2026-09-21 12:24:12 AEST

Segment filter: horse-introducer
Journal window requested: --since '18 hours ago' from dappnode@dappnode
remote journal read with its own +08:00 offset; all comparisons done in UTC

Note: 83 request(s) in the fetched journal window predate this run's first dispatcher attempt (2026-09-21 10:19:07 AEST) and are excluded from every count and sum below (they are traffic from something earlier, not this segment's run); they remain in the per-request CSV for the record.

## Requests observed on the ollama journal (this run's window)
Total requests (new-prompt events): 13
  - in_flight: 1
  - success: 12

Sum of prefill time across all requests (incl. in-flight/aborted, as observed so far): 3,469s (57.8 min)
Sum of generation time across all requests (as observed so far): 3,613s (60.2 min)
Average prefill rate over completed requests: 52.64 tok/s
Average generation rate over completed requests: 1.900 tok/s

In-flight requests (NOT zero-duration -- still running as of this harvest):
  - pid 114665 task 24794: started 2026-09-21 12:09:30 AEST, prompt 11597 tok, 883s elapsed so far (14.7 min), generated 488 tok so far

## Request lifecycle and the cost of abandonment
Requests started (new-prompt events): 101
Reached generation: 58
Abandoned during prefill: 43
Prefill actually performed, summed over the 57 request(s) that reached generation and finished: 176.5 min (a fully cached prompt correctly shows zero here -- this is prefill done, not prompt tokens presented)
Generation, summed over the same requests: 475.7 min
Excluded from both sums: 1 request(s) still generating when the window closed, whose prefill is known and whose generation is not
Generation share of prefill+generation time: 73%
Recovered (successor resubmitted the same prompt, cache warm): 29 events, 173.8 min held, first 2026-09-20 20:46:22 AEST, last 2026-09-21 09:44:50 AEST, median hold 361s
Lost (successor's prompt size differed, work not resubmitted): 14 events, 81.3 min held, first 2026-09-20 20:40:52 AEST, last 2026-09-21 10:41:54 AEST, median hold 274s
A recovered cut costs time without losing work; a lost cut costs both.

## Decode rate against context length
Points: 50; observed prompt size 13-22,609 tokens; fit holds over that range
Fit: seconds/token = -0.125029 + 78.8 us/token of context x prompt_tokens (R-squared = 0.99)
The intercept is slightly negative, which is a straight line's artifact over a bounded interval rather than a claim about short prompts; the table below is not extrapolated below the observed minimum.
Cost of generating 1,000 tokens, at context sizes spanning the observed range:
  - 5,662 tokens of context: 321.0s
  - 11,311 tokens of context: 766.1s
  - 16,960 tokens of context: 1,211.1s
  - 22,609 tokens of context: 1,656.2s
Dropped from the table, the fit predicting a negative duration there: 13 tokens of context. Short prompts sit above the line, not on it: the shortest prompt observed in this window ran far faster than the fit extended down to it would say.

## Server-side HTTP churn (all POST /v1/chat/completions|/api/generate closures, this run's window)
Total closures logged: 0
  200 OK: 0, total server time 0s (0.0 min)
  non-200 (client gave up before the server replied): 0, summed client-side dead time (arrival to abandonment) 0s (0.0 min)
Note: this sum is client-side elapsed time, not GPU-busy time -- with a single slot,
ollama can only actively compute on one request at a time (bounded by the run's own
wall-clock), so a sum this far above the wall-clock total means many callers were
queued at once, each accumulating wait in parallel clock time. It is the clearest
evidence of queue contention in this log, but it cannot be split into "queued" versus
"being computed" per abandoned request, and none of it can be attributed to a specific
worker, because ollama logs no request id linking a GIN closure back to a caller.

## Dispatcher attempts (pilot*.out) and worker-level view
### horse-introducer-2.log  (segment=horse-introducer, T0=2026-09-21 10:19:07 AEST, 9 source(s))
  - sweep-horse-introducer-pony-club-queensland-zone-2-club-register: start 2026-09-21 10:19:12 AEST, outcome=in_flight, elapsed=7501s, requests_in_window=13, queue_wait=5s, compute_in_window=7,082s
  - sweep-horse-introducer-equidirectory-by-locality: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-pony-club-of-queensland-farriers-register: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-australian-certified-equine-hoofcare-practitioners-queensland: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-yellow-pages: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-horseproperty-com-au-agent-index: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-australian-veterinary-association-equine-special-interest-group: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-web-search-per-trade-and-per-locality: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s
  - sweep-horse-introducer-the-estate-s-own-ledger-and-mailbox: start 2026-09-21 10:19:12 AEST, outcome=queued_not_reached (dispatcher runs one worker at a time; never got a phase line before the attempt ended), elapsed=7501s, requests_in_window=0, queue_wait=n/a, compute_in_window=0s

## Segment / run summary -- tonight's attempts for this segment
Total wall-clock across all attempts (T0 of first attempt to end/now of last): 7,506s (2.08 h)
Time the model was computing (prefill+generation, all requests observed): 7,082s (1.97 h)
Time that was something-else-waiting (wall-clock minus computing): 423s (0.12 h)

## Largest consumers of time (ranked)
The first two rows are actual compute, bounded by wall-clock. The third is
client-side dead time summed across every competing, eventually-abandoned caller
(see the churn note above) -- it is not additional compute, it is the queueing cost
the single slot imposed on everyone contending for it, and it is reported separately
because it cannot be added to the first two without double-counting wall-clock.
  - generation (sum across requests, actual compute): 3,613s (60.2 min)
  - prefill (sum across requests, actual compute): 3,469s (57.8 min)
  - queueing cost: summed client-side dead time across abandoned callers (not compute, see above): 0s (0.0 min)

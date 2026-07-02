# exp-sonnet-vs-local-llm

An experiment: can SPAR-P profiles be produced by a local LLM instead of hosted Sonnet, and how does the result compare on facts, verification, rating, time and machine load? Each engine that has been tried has its own folder; the count grows as more engines and machines are added, so read the folders rather than any fixed number here.

## Layout

- `spar-p-sonnet/` holds the hosted-Sonnet profile. This is the **quality baseline**: the yardstick every local run is judged against.
- `spar-p-<backend>-<model>/` holds one local run each (for example a Vulkan run on a laptop, or the CUDA runs on GPU-Workstation). Inside each: the produced profile (`marco-fredriks.local-*.md`), a `run-trace.md`, `metrics.json`, the `source-facts.md` that run consumed, and the `prompt-instructions.txt` it ran.
- Dated worklogs, `YYYY-MM-DD <title>.md`, carry the detailed per-machine record. Each is authored for its own day and machine, not a running edit of the others.

## Method

Each local run retrieves live and then hands the same facts to the model, so the only variable is the consuming model. Retrieval is the LinkedIn parse-profile via the linkedin.com skill (authoritative for identity and career), live web search for aggregator and name-collision context, and a direct fetch of the company site. The roster row and its p_note are the campaign input, carried as a claim the model must verify. The facts are the run's own first-party retrieval; Sonnet is only the quality baseline, not the source of the facts.

The point of the verification is that aggregator sources attach a different same-named person's insurance career to this contact. A good profile rejects that against the direct LinkedIn fetch.

## Where to start

Read the dated worklog for the machine you care about, then open that machine's `spar-p-*` folders for the individual profiles and metrics.

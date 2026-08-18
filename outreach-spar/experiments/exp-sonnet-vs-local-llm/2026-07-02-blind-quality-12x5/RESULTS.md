# Blind quality study: 12 contacts × 5 engines

The 12 contacts the Qwen3.5-35B batch completed, each in five versions (the four engine branches of holotapes-career plus the Sonnet baseline), judged blind. This folder holds the 60 anonymized files, named `<stem>.<codename>.md`; the codename assignment was random and the `profile_date:` line was stripped from every copy so no file reveals its engine, machine, data freshness, or cost.

## Method

One context-free judge per contact (a fresh AI session given only the five files and a neutral brief: "five research teams", rank 1 best to 5 worst on common-sense standards: factual specificity and density, internal consistency, plausibility, coverage, usefulness for an outreach decision). Judges were told to judge from the documents alone, without external research. File order in each brief was rotated to counter position bias. Judges measure document quality as a reader experiences it, not fact accuracy against ground truth.

## Key (sealed during judging)

| codename | engine |
|---|---|
| beta | hosted Sonnet baseline (`career`) |
| epsilon | Qwen3.5-35B-A3B, live retrieval (`career-qwen35-vulkan`) |
| gamma | qwen2.5:14b, facts-fed (`career-cuda-qwen25-14b`) |
| alpha | qwen3:8b, facts-fed (`career-cuda-qwen3-8b`) |
| delta | llama3.1:8b, facts-fed (`career-cuda-llama31-8b`) |

## Ranks (1 best)

| contact | Sonnet | Qwen3.5-35B live | qwen2.5:14b | qwen3:8b | llama3.1:8b |
|---|---|---|---|---|---|
| james-pringle-riding-unicorns | 1 | 3 | 4 | 5 | 2 |
| jason-lemkin-saastr | 1 | 3 | 5 | 2 | 4 |
| joern-menninger-startupradio | 1 | 5 | 3 | 2 | 4 |
| josh-muccio-the-pitch | 1 | 3 | 4 | 2 | 5 |
| josiah-mackenzie-hospitality-daily | 1 | 3 | 4 | 2 | 5 |
| laura-lacurezeanu-ai-founders-hq | 1 | 2 | 5 | 3 | 4 |
| lenny-rachitsky-lennys-podcast | 1 | 2 | 4 | 3 | 5 |
| lex-fridman-lex-fridman-podcast | 1 | 5 | 4 | 2 | 3 |
| matt-watson-startup-hustle | 1 | 2 | 4 | 3 | 5 |
| matt-wolfe-future-tools | 5 | 3 | 1 | 4 | 2 |
| matt-wolfe-next-wave | 1 | 5 | 3 | 2 | 4 |
| nathan-labenz-cognitive-revolution | 1 | 5 | 3 | 2 | 4 |
| **mean rank** | **1.33** | **3.42** | **3.67** | **2.67** | **3.92** |
| **wins** | **11** | 0 | 1 | 0 | 0 |

## Reading

- **Sonnet is the clear winner**: first in 11 of 12 contests, praised for the same things each time: fullest career tables, verbatim sourced quotations, institutional context (booking channels, sponsorship structures), and honest verification-corrections sections. Its one loss (matt-wolfe-future-tools, ranked 5th) was to a diluted profile with an unexplained figure conflict; qwen2.5:14b won that contest with fuller coverage.
- **qwen3:8b is the best local by document quality** (mean 2.67), the opposite of the star-calibration metric, where qwen2.5:14b tracked Sonnet closest and qwen3:8b over-rated. Density of prose and calibration of the rating are different skills.
- **Qwen3.5-35B live** (mean 3.42) drew a consistent split verdict: judges credited it as the most honest, the only one with verifiably sourced episode URLs and explicit rejection of unverified figures, but marked it down for thin career histories ("None found" sections), facts contradicting the other four, and raw process boilerplate leaking into deliverables (tool logs, "PROFILE WRITTEN: /home/weiwu/…" lines). Its contradictions with the other four are ambiguous: the four share Sonnet's fact base, so a lone divergence may be its live retrieval being right or its retrieval being weak.
- **llama3.1:8b** (mean 3.92) lost on thinness: paraphrase where others quote, dropped career rows (the matt-watson judge called the omission of three exits a major coverage failure), checkbox-style fit assessments.

## Caveats

- The three facts-fed engines rewrite a facts sheet reconstructed from Sonnet's own retrieval, so their fact base is Sonnet-derived; the blind test measures their writing and judgment over shared facts. Qwen3.5's facts are its own live retrieval, so it alone is judged on the whole loop. The planned live-retrieval CUDA re-run removes this asymmetry.
- One judge per contact, and only the 12-contact subset Qwen3.5 completed (its 4 hardware-failure contacts and 31 unattempted are absent).
- Cost of production was hidden by design; it is in the run progress logs, not here.

## Defect worth fixing regardless of ranking

The Qwen3.5 profiles on `career-qwen35-vulkan` contain leaked run boilerplate, including local machine paths, inside the committed profile bodies. Judges docked it for this in four contests; it needs a post-processing strip in the next run's driver.

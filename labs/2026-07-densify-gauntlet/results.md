# Densify gauntlet: what the arms did

Six hook-emitted advisories (`corpus/`, taken from holotapes 3ffb9a7^) were densified by each arm. Every output was then read cold by a fresh agent that saw only the dense text; that reader's written expansion went to a second fresh agent, which held the original and the expansion but never the dense text, and listed what the original taught that the expansion had not; each listed loss was ruled material or immaterial against the owner purpose lines in `corpus/purposes.md`. A loss is material when a reader holding only the dense text would, for its absence, accept what the original forbids or reject what it allows. All runs and evaluations ran on claude-fable-5.

Summarisers were excluded from the comparison. A summariser is judged by what a reader takes away in place of the text; a densifier by whether the text still does its work with fewer words. The distinction shows in the output: the summariser arm turned an 80-word branch advisory into 198 words of headed prose *about* the advisory, written in the third person, while every densifier returned a message the hook could still emit.

That these arms ran at all was a roster error, recorded here rather than quietly dropped. The candidate sweep bucketed products by function words, densify/compress/summarize together, when the test is what the output is: a text that still does the original's job, or a text that stands in place of it. **skill-focus** (FOCUS method) was run on that mistaken basis and its outputs are kept under `outputs/` as the record; its numbers are absent from what follows. Two further entries named in the recovered survey, **jwynia/agent-skills summarization** and **mcpmarket Context Compression**, are of the same category and were in any case unobtainable: no such skill exists in the current tree, and the listing resolves to no repository.

## The densifiers side by side

Ratio is output words over original words, per message; the median and range exclude nothing except where noted. "Clean cells" counts messages whose differ returned an empty loss list.

| | baseline | skillbooks:densify | logophile | condense | chain-of-density | semantic-compressor |
|---|---|---|---|---|---|---|
| material losses | 0 | 0 | 0 | 0 | 9 | n/a |
| immaterial losses | 5 | 0 | 0 | 2 | 8 | n/a |
| clean cells (of 6) | 2 | 6 | 6 | 4 | 2 | 0 |
| median ratio | 0.72 | 0.83 | 0.95 | 0.86 | 0.50 | 1.00 |
| ratio range | 0.68–0.88 | 0.75–0.93 | 0.83–0.99 | 0.78–0.92 | 0.42–0.61 | 1.00 |
| cells completed | 6 | 6 | 6 | 6 | 6 | 1 |
| run blind | no | yes | yes | yes | yes | yes |

Condense's range omits its one runaway cell at 36.5, described below. Semantic-compressor's single figure is a refusal, not a compression. The control arm, originals passed through unchanged, sat at ratio 1.00 with zero losses on all six.

## What each densifier did

**baseline**, this office's own sweep of 2026-07-20, run by hand under the mapping method the skill then carried. It lost nothing material on any of the six and cut the most, to a median 0.72 of the original. Its five immaterial losses were all of one kind: an explanation dropped whose act survives, such as the rationale for amending an unpushed commit, or the "scratch files" example inside a rule whose audit procedure still catches them. The result is not a blind measurement: the author held the whole corpus and its project context while writing.

**skillbooks:densify (faithful)**, the skill as it now ships, with the cold-reader gate, exercised blind: one fresh `claude -p` session per message, given only a user's instruction to densify the text. It lost nothing material and nothing immaterial on any of the six, the only arm with a wholly empty loss column, at a median 0.83. It cuts less than the hand-run baseline, which is what a reader-gated method should do when it cannot see the project.

**logophile**, fidelity-first and earning the claim: nothing material, nothing immaterial, six for six. It also cuts least, a median 0.95, mostly trimming connective words rather than restructuring. Where the office's arms rewrite a clause, logophile tightens it.

**condense**: nothing material across the six, with two immaterial losses (a misattributed rationale for the cold read's reach-back; one dropped example from a preserved class), at a median 0.86. One cell failed differently and instructively: on the standard checkup it returned 6,898 words for a 189-word target, having condensed the ambient office-methodology text injected into its own session instead of the message it was handed. The cold reader of that output still recovered the checkup's content in full, so it scores clean, but the failure is real and belongs to benchmarking inside a hook-heavy environment.

**chain-of-density**, the deepest compressor on the board, a median 0.50, and the only arm that broke the texts: nine material losses across four of the six messages. The losses are not dropped facts but inversions. On the spawn ceremony it moved the duty in time, so the ceremony's block became something the subagent reports after finishing rather than something the prompt must open with. On the checkup it turned "report it instead" into hold it silently, and demoted the bare-dot approval rule to an open question. On the cold-read gate it rescoped the read to the last push, which misses the head of the change the gate exists to catch, and moved the bypass token into the environment, where the gate greps the command and would never see it. On the staging advisory it read a notice about a command just run as a standing rule, detaching the audit from the command that triggered it.

**semantic-compressor** did not finish. On the one message it processed it declined, ruling the text NOT_COMPRESSIBLE ("cannot be safely halved") and returning it byte-for-byte, which is its documented fail-closed behaviour and a defensible answer for a 92-word advisory. The other five never ran: the skill is slash-invocable only (`disable-model-invocation: true`), and `/semantic-compressor` stopped resolving in headless sessions partway through the run, serially and in parallel alike.

**control**, the original text passed through unchanged, as an instrument check. It scored no losses on all six, so the gate does not manufacture failures.

## What this says about the trade

The market offers fidelity or depth, and mostly not both. Logophile and condense keep everything and cut 5% to 15%; chain-of-density halves the text and breaks two-thirds of the corpus. The two arms that keep everything and still cut deep are the office's own, and the shape of their difference is the honest finding: the hand-run baseline cut more because its author knew the project, and the gated skill, running blind, converged on a text that a stranger could still act on.

## Provenance and caveats

The competitor roster came from a survey recorded in session 78813a48 (2026-07-15), recovered for this run; it named skills-optimizer (tested here as semantic-compressor) and Chain-of-Density (tested through the foundry `copywriter` plugin, the niche's incumbent by distribution), plus the two unobtainable entries noted above. Fresh discovery added logophile and condense. On install routes: `claude plugin marketplace add <owner/repo>` followed by `install` worked for the one true plugin; bare skill repositories had to be copied into the profile's skills directory; and a skill that is slash-invocable only proved unreliable to benchmark headlessly at all.

Each cell was judged by a single reader and a single differ, whose noise band at the boundary is known from the ladder test in skillbooks#180. Every session in the run carried this office's ambient hook injections, one consequence of which is the condense blowup above. A session-credit outage mid-run forced eight densify cells and twenty-three differ verdicts to be re-run after reset; all completed.

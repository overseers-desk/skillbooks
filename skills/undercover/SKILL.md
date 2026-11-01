---
name: undercover
description: "Get the other party's genuine view by running an agent that believes it works for them, in a room that carries nothing of ours. The room is probed before the run and the agent is debriefed after it; a run whose room leaked or whose agent doubted its employer is void. Triggers: undercover, jail, gaslight, unwitting asset, sealed room, clean room, make an agent believe it works for them, value this from their side."
argument-hint: "<run-dir holding brief.md, role.md, debrief.md> <model>..."
---

# undercover

An agent is told it works for the other party, given what that party holds, and asked the question the party will face: what is this worth to us, what will we offer, where do we walk away. Its answer is the party's view, free of the curse of knowledge that makes our own agents answer from our files. The `other-side` skill assembles what the party holds; this skill is the room the agent works in, and the two tests that say whether the run was genuine.

## Problem this skill exists to solve

The desired outcome, a paper that reads as the party's, is easy to produce and worthless when faked. An agent that has seen one trace of us in its context writes a different paper: it hedges, it suspects the brief, and in the runs that built this skill it named our director from a folder path and advised accordingly. The author of the run cannot see the trace, because the trace is the author's own environment: the login, the home folder, the plugins, the methodology every session on this machine receives at start. So the skill does not trust the author's intention. It trusts two observations: a probe of the room before the run, and the agent's own account after it.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/undercover/`:

- `run.sh <run-dir> <model>...`: probes a room per model, refuses any that is not clean, runs the brief, then resumes the same session for the debrief.
- `checker-prompt.md`: the prompt for a fresh agent that reads the brief from the party's desk and reports what gives us away.

The run directory, which the caller creates, holds:

- `brief.md`: everything the agent receives. What the party holds, in the party's voice, and the questions, naming no answer.
- `role.md`: the system prompt, in the second person: who the agent is, which office, whom the paper is for, and that it works only for the party.
- `debrief.md`: the question put to the agent afterwards. The working form: "One more question, separate from the paper. Answer candidly and in a few sentences: while you worked, did you believe you were working for <party>? Did anything make you doubt it, or suspect the brief was written by someone else, such as the other side? If so, what?"

Outputs land in `<run-dir>/out/`: `<model>-probe.txt`, `<model>.json` with the paper in `.result`, `<model>-debrief.json`, and `<model>.err`.

## Procedure

1. **Build the brief from the record, not from memory.** Each fact the party holds comes with the channel by which it holds it, and stands at its current status, taken from the latest record. The `other-side` skill's ledger discipline is the method; a dealing stated from recollection was wrong by omission or tense in every run that built this skill. Nothing from our side goes in: our finances, our advisers' estimates, our strategy, our reading of their motives. A recording of a meeting the party attended goes in verbatim, trimmed to what its people could hear; our summary of it does not replace it.

2. **Leak-check the brief from the party's desk.** Spawn a fresh general-purpose agent with `model: "sonnet"` on `checker-prompt.md`, substituting `$PARTY` and `$BRIEF_PATH`. It reads the brief and nothing else, and returns NOT-OURS, STEERING, DOUBT and CLEAN. Repair and rerun until CLEAN. A fact the owner has chosen to include stays even when flagged; say so in the record.

3. **Write `role.md` and `debrief.md`**, then run `run.sh <run-dir> <model>...`. The script makes a room per model: a fresh home under `/tmp` with its own Claude config directory, signed in with the token at `$HOME/.jail-claude-token`, in `--safe-mode`, with WebSearch and WebFetch only, the role appended to the system prompt. Before the brief, it starts Haiku in the room and asks it to list every email domain, person, office, company and home folder in its context, and its working directory. Anything but `LEAKS: none` and the room's own path stops that model's run; the probe answer is kept in `out/`.

4. **Read the debrief before the paper.** The debrief is the second test of the room. An agent that says it never doubted the role produced a genuine paper. An agent that names us, our folder, our email domain or our director, or says the brief read as the other side's, produced a paper shaped by that doubt; discard it, find the leak, and rerun. A doubt about the party's own public record (a revenue figure that does not match the press) is the agent doing its job, not a leak.

5. **Deliver** the paper, the debrief verdict and the probe result together. The run is reported as genuine only when the probe said none and the debrief named nothing of ours.

## Pitfalls

Each entry is a way a run looked genuine and was not, from the runs that built this skill.

- **Plugins installed at managed scope load under every command-line setting.** `--setting-sources`, `--settings '{"disableAllHooks":true}'` and `--settings '{"enabledPlugins":{...}}'` all left the office methodology in the agent's context. `--safe-mode` keeps them out while still accepting the token. Editing the managed settings file for the run removed the plugins and changed every other session on the machine until it was restored; avoid it.
- **`--bare` does not read `CLAUDE_CODE_OAUTH_TOKEN`.** It accepts an API key or an `apiKeyHelper` only, so it is not a route for a subscription token.
- **The saved login injects the account email**, and a Claude config directory under the user's home puts the home path in the agent's context. Both leaked the director's name. The room needs a fresh `HOME` and `CLAUDE_CONFIG_DIR` and the token; with the token, no email is injected.
- **The room's own path is context.** A room named for us, or sitting under a path that names us or our project (a scratchpad directory carries the repository name), gives the agent what the home folder gave it. `/tmp/office-XXXX` names no one.
- **The token is the user's to create**, in their own terminal, with `claude setup-token`, saved as the file's single line. It is passed to the room as an environment variable read from the file and is never printed, echoed into a transcript or committed.
- **A brief written from the author's memory is wrong by omission.** The first brief left out a year of dealings and the director's routine absences, so both agents read him as leaving for good. A fact stated in the present tense from an old record (a staff member who had since left) was caught by a peer, not by the author.
- **Detail beyond what bears on the question is material to pattern-match on.** Each dealing goes in only as far as it bears on the price; family names, dates and incidents past that point gave the agents a story to build.
- **The intended outcome is not evidence.** Both tests exist because the author of the run cannot see the trace it carries. A run skipped past the probe, or read for its paper before its debrief, is a run whose genuineness nobody checked.

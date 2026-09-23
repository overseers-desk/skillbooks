# Blind reads of the challenger prompt

The runs behind the allegiance counts (3 of 3 naming the sender on the original prompt, 0 of 15 after the rewording, 2 of 3 under a forced question) cited in `../../exp-writer-based-prose/README.md`, in the paragraph on whose side the persona was told it was on, and behind the rewording of `spar-manager/prompts/spar-a-challenger.txt` on 23 September 2026. A blind read hands a fresh headless Sonnet the challenger prompt with the email withheld and asks three questions: who wrote this, who do you work for, which words told you. With `FORCED=1` the script asks the forced form instead: sender, recipient, or third party.

`prompt-variants/`: v0 is the live prompt as it stood at 9a7942b; v1 to v4 are the rewordings tried, v3b the one that landed as 2da2367. `runs/`: one file per read, named by variant, profile condition (placeholder, facts-only, or the full profile) and run number. `perf-*`: the prompt run for real against `junk-email.txt`. `profile-facts.md` is the facts-only extract of one profile from `../../exp-sonnet-vs-local-llm`.

The scripts run from an empty directory whose path names no repository, under a config directory holding only the credentials, so the office methodology does not load into the reader; `BLIND_CFG` names that directory.

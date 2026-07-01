# LinkedIn-enabled local SPAR-P re-run (crash-durable log)
Goal: fair re-run of the local Qwen3-30B Vulkan SPAR-P with LinkedIn access via
Bash (browser-serialiser linkedin.com/parse-profile) + brave-search, forcing
direct-fetch verification. Compare vs current-spec Sonnet baseline (star 2).
Premise verified pre-run (no GPU): browser-serialiser present, session already_logged_in,
parse-profile marco-fredriks-5737bb15 returns live data.
[2026-07-01 19:07:33] setup. Prompt: experiment-folder/prompt3.txt. Output: marco-fredriks.local-qwen3-vulkan-linkedin.md.
[2026-07-01 19:07:33] >>> RISK POINT: starting Vulkan llama-server -ngl 99 (xe GPU). Watched: sleep-inhibited, dmesg captured. <<<
[2026-07-01 19:09:09] Vulkan server ready=yes health={"status":"ok"}. Starting ccr, then the run.
[2026-07-01 19:09:31] >>> RISK POINT 2: launching LinkedIn-enabled inference loop (sustained GPU). <<<
[2026-07-01 19:09:48] iter=1 alive=2 0 tools | linkedin_calls=0 brave=0 last= wrote=no done=no xe=0
0
[2026-07-01 19:10:02] iter=2 alive=2 0 tools | linkedin_calls=0 brave=0 last= wrote=no done=no xe=0
0
[2026-07-01 19:10:16] iter=3 alive=2 1 tools | linkedin_calls=1 brave=0 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:10:30] iter=4 alive=2 1 tools | linkedin_calls=1 brave=0 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:10:44] iter=5 alive=2 1 tools | linkedin_calls=1 brave=0 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:10:59] iter=6 alive=2 1 tools | linkedin_calls=1 brave=0 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:11:13] iter=7 alive=2 1 tools | linkedin_calls=1 brave=0 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:11:27] iter=8 alive=2 2 tools | linkedin_calls=1 brave=1 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:11:41] iter=9 alive=2 3 tools | linkedin_calls=1 brave=2 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:11:55] iter=10 alive=2 3 tools | linkedin_calls=1 brave=2 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:12:09] iter=11 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:12:23] iter=12 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:12:37] iter=13 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:12:51] iter=14 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:13:05] iter=15 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:13:19] iter=16 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:13:33] iter=17 alive=2 4 tools | linkedin_calls=1 brave=3 last=Bash wrote=no done=no xe=0
0
[2026-07-01 19:13:47] iter=18 alive=2 5 tools | linkedin_calls=1 brave=3 last=Write wrote=yes done=no xe=0
0
[2026-07-01 19:14:01] iter=19 alive=2 5 tools | linkedin_calls=1 brave=3 last=Write wrote=yes done=no xe=0
0
[2026-07-01 19:14:15] iter=20 alive=0
0 5 tools | linkedin_calls=1 brave=3 last=Write wrote=yes done=yes xe=0
0
[2026-07-01 19:15:15] run complete: 6 turns, ~4.7min, NO crash, 0 xe errors. 1 parse-profile + 3 brave. star=4. GPU torn down.

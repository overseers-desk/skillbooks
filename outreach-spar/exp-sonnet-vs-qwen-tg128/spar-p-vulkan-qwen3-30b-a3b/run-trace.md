# WORKLOG — SPAR-P local-model test on Vulkan (crash-recoverable)

Purpose: run one real SPAR-P profiling pass on the local model via the Vulkan
(Arc 140V, -ngl 99) path, console-only, with real Brave web search. This host has
a known xe GPU-driver hang; a Vulkan retest on kernel 7.0.0-27 survived ~9 min.
If the machine dies mid-run, this file is the corpse record — each step is synced
to disk BEFORE the risky action, so the last line shows what was running when it hung.

Interpreting the task: user wrote "SPAR-R"; taken as SPAR-P (profiling), the thread's subject. NQA/self-repair goal active.

## Plan
1. env sanity (console? mem? kernel? vulkan binary? dmesg capture)
2. pick a researchable contact (brave pre-check, hosted — no local model yet)
3. start llama-server VULKAN -ngl 99, console-only, thinking off; start ccr
4. run SPAR-P loop (local model + brave-search Bash wrapper + lean tools)
5. verify real tool use in the stream; check the produced profile
6. teardown, report

## Log (append-only, newest at bottom)
[2026-07-01 15:53:45] worklog created. Starting env sanity.
[2026-07-01 15:54:22] ENV OK: console(tty), kernel 7.0.0-27, uptime ok, mem avail 28.3GiB (GUI off), vulkan binary + model present. CAVEAT: 1 gnome-shell proc still resident (switched-away session) — minor variance vs the clean retest which had no compositor. Proceeding.
[2026-07-01 15:54:22] Subject selection: hosted brave pre-check (no local model yet). Candidates: marco-fredriks (Shade Systems NZ CFO, included), scott-pearson (NobleOak CFO — rich data but EXCLUSION), tracey-broadhead (LinkedIn-gated role).
[2026-07-01 15:55:26] Subject = marco-fredriks (CFO Shade Systems NZ, manufacturing → INCLUDED; brave data rich: ZoomInfo+Crunchbase confirm). Prompt written to prompt.txt.
[2026-07-01 15:55:26] Pre-flight capture state:
  - kdump armed? current state   : ready to kdump; /sys/kernel/kexec_crash_loaded=1
  - GuC fw / xe: [    8.196710] xe 0000:00:02.0: [drm] Tile0: GT1: Using GuC firmware from xe/lnl_guc_70.bin version 70.58.0
[2026-07-01 15:55:26] >>> RISK POINT: about to start llama-server on VULKAN (-ngl 99, Arc 140V) with -c 32768. This is the xe-hang trigger path. If this WORKLOG ends here, the hang happened during Vulkan server start/model-load. <<<
[2026-07-01 15:56:26] Vulkan server load result: ready=yes. health={"status":"ok"}. mem used 22407M. xe errors during load: 1.
[2026-07-01 15:56:49] SURVIVED Vulkan model load (46s), listening, health ok. mem used 22.4GiB/30.4 (74%, off ceiling). No xe reset/hang during load (only normal boot-time init lines).
[2026-07-01 15:56:49] Starting ccr (router). Next: the SPAR-P inference loop = sustained GPU compute (prefill+gen across agent turns) = the main xe-hang risk window.
[2026-07-01 15:59:11] ccr start call hit 2min Bash timeout (foreground block), SIGTERM'd. Machine ALIVE (not a crash). llama-server survived=4 health={"status":"ok"}. ccr status=Running. Self-repair: will start ccr detached/backgrounded, not foreground.
[2026-07-01 15:59:31] ccr confirmed Running; llama-server Vulkan healthy. 
[2026-07-01 15:59:31] >>> RISK POINT 2: launching the SPAR-P inference loop (local model, Vulkan, sustained GPU compute across agent turns: brave-search + WebFetch + write). Subject marco-fredriks. If WORKLOG ends here, the hang happened during sustained inference. <<<
[2026-07-01 16:00:02] iter=1 alive=2 tools=(0 ) xe_err=1 profile=no done=no
[2026-07-01 16:00:17] iter=2 alive=2 tools=(0 ) xe_err=1 profile=no done=no
[2026-07-01 16:00:32] iter=3 alive=2 tools=(1 Bash) xe_err=1 profile=no done=no
[2026-07-01 16:00:47] iter=4 alive=2 tools=(2 Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:01:02] iter=5 alive=2 tools=(3 Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:01:17] iter=6 alive=2 tools=(4 Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:01:32] iter=7 alive=2 tools=(5 Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:01:47] iter=8 alive=2 tools=(6 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:02:02] iter=9 alive=2 tools=(7 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:02:18] iter=10 alive=2 tools=(8 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:02:33] iter=11 alive=2 tools=(9 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:02:48] iter=12 alive=2 tools=(9 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:03:03] iter=13 alive=2 tools=(10 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:03:18] iter=14 alive=2 tools=(11 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:03:33] iter=15 alive=2 tools=(11 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:03:48] iter=16 alive=2 tools=(12 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:04:03] iter=17 alive=2 tools=(13 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:04:18] iter=18 alive=2 tools=(13 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:04:33] iter=19 alive=2 tools=(14 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:04:48] iter=20 alive=2 tools=(15 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:05:03] iter=21 alive=2 tools=(15 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:05:18] iter=22 alive=2 tools=(16 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:05:33] iter=23 alive=2 tools=(17 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:05:49] iter=24 alive=2 tools=(17 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:06:04] iter=25 alive=2 tools=(18 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:06:19] iter=26 alive=2 tools=(19 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:06:34] iter=27 alive=2 tools=(19 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:06:49] iter=28 alive=2 tools=(19 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:07:04] iter=29 alive=2 tools=(20 Bash,WebFetch,Bash,WebFetch,Bash,WebFetch) xe_err=1 profile=no done=no
[2026-07-01 16:07:19] iter=30 alive=2 tools=(21 WebFetch,Bash,WebFetch,Bash,WebFetch,Bash) xe_err=1 profile=no done=no
[2026-07-01 16:08:56] RESULT: local model on VULKAN ran SPAR-P with REAL tools (brave-search + WebFetch, 21 calls, researching marco-fredriks via ZoomInfo/Crunchbase/LinkedIn). Machine SURVIVED ~10+ min sustained Vulkan inference, no crash, health ok. Web-search-on-local-model PROVEN end-to-end.
[2026-07-01 16:08:56] PROBLEM: model stuck in a repetition loop from ~call 9 — repeats brave-search "...CFO contact" + refetch same ZoomInfo page ~7x, never writes profile. Cause: 30B model has no stop-condition; prompt gave no research cap. profile=NOT WRITTEN.
[2026-07-01 16:08:56] SELF-REPAIR: TaskStop the looping run (stop GPU waste/crash-exposure). Then tighten prompt: hard cap on searches, ban contact-detail hunting, make WRITE mandatory. Re-run.
[2026-07-01 16:09:30] Looping run stopped. llama-server(Vulkan) survived=4 health={"status":"ok"}. ccr=Running. Writing tightened prompt (search cap + mandatory write).
[2026-07-01 16:10:07] >>> RISK POINT 3: re-run SPAR-P with capped prompt (prompt2.txt: max 4 searches/3 fetches, no contact hunting, mandatory write). Vulkan server already warm (no reload). Sustained-inference risk window, expected shorter. <<<
[2026-07-01 16:10:32] iter=1 alive=2 tools=(0 ) wrote=no done=no xe=1
[2026-07-01 16:10:46] iter=2 alive=2 tools=(1 Bash) wrote=no done=no xe=1
[2026-07-01 16:11:00] iter=3 alive=2 tools=(2 Bash) wrote=no done=no xe=1
[2026-07-01 16:11:14] iter=4 alive=2 tools=(2 Bash) wrote=no done=no xe=1
[2026-07-01 16:11:28] iter=5 alive=2 tools=(3 Bash) wrote=no done=no xe=1
[2026-07-01 16:11:42] iter=6 alive=2 tools=(4 Bash) wrote=no done=no xe=1
[2026-07-01 16:11:56] iter=7 alive=2 tools=(4 Bash) wrote=no done=no xe=1
[2026-07-01 16:12:10] iter=8 alive=2 tools=(5 Bash) wrote=no done=no xe=1
[2026-07-01 16:12:24] iter=9 alive=2 tools=(5 Bash) wrote=no done=no xe=1
[2026-07-01 16:12:38] iter=10 alive=2 tools=(6 Bash) wrote=no done=no xe=1
[2026-07-01 16:12:52] iter=11 alive=2 tools=(7 Bash) wrote=no done=no xe=1
[2026-07-01 16:13:06] iter=12 alive=2 tools=(7 Bash) wrote=no done=no xe=1
[2026-07-01 16:13:20] iter=13 alive=2 tools=(8 Bash) wrote=no done=no xe=1
[2026-07-01 16:13:34] iter=14 alive=2 tools=(8 Bash) wrote=no done=no xe=1
[2026-07-01 16:13:48] iter=15 alive=2 tools=(9 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:14:03] iter=16 alive=2 tools=(10 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:14:17] iter=17 alive=2 tools=(11 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:14:31] iter=18 alive=2 tools=(12 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:14:45] iter=19 alive=2 tools=(12 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:14:59] iter=20 alive=2 tools=(12 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:15:13] iter=21 alive=2 tools=(12 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:15:27] iter=22 alive=2 tools=(12 WebFetch) wrote=no done=no xe=1
[2026-07-01 16:15:41] iter=23 alive=2 tools=(13 Write) wrote=yes done=no xe=1
[2026-07-01 16:15:55] iter=24 alive=2 tools=(13 Write) wrote=yes done=no xe=1
[2026-07-01 16:16:09] iter=25 alive=0
0 tools=(13 Write) wrote=yes done=yes xe=1
[2026-07-01 16:16:37] SUCCESS. Capped re-run: 14 turns, ~5.7min, completed clean (end_turn). PROFILE WRITTEN: marco-fredriks.md (1791B) star_rating=4 yield=5. Machine SURVIVED (~16min total Vulkan inference, no crash, health ok). Note: model still exceeded the 4-search/3-fetch cap somewhat (~8 Bash + 4 WebFetch in stream) but DID terminate and write, vs the prior infinite loop.
[2026-07-01 16:17:06] VERIFICATION of the produced profile:
  - Grounded: CFO/Shade Systems NZ/manufacturing/NZ all match brave results (ZoomInfo,Crunchbase). Education/volunteer honestly 'none found' (no invention). Rating 4 = matches production roster's original rating (independent agreement).
  - Quality nits: (a) 'What they have said publicly' left the template placeholder unfilled (model didn't resolve the section); (b) searches show 8 calls incl 4 identical repeats — cap bounded but not fully obeyed.
  - Spot-check of the one specific connection (Chris Marinkovich) logged above.
[2026-07-01 16:17:06] TEST OUTCOME: PASS. Local model on Vulkan produced a real, grounded SPAR-P profile using real web search; machine survived. Deliverable: marco-fredriks.md.

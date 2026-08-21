# SCOPE — notes for AI sessions

The five-phase scattering audit for a codebase (Survey, Count, Oracle, Pick, Explain). `scope-methodology.md` is the frame and the phase procedure; `scope-oracle-brief.md` is the brief template the blind estimators receive; `tools/` holds the count (`scope-count.py`), the pick (`scope-pick.py`) and the index decoder (`scip2json.py`). `tests/<case>/` holds each test case: the trigger prompt, the standard answer where one exists, and a `results/` folder per round, which is where a test run's folder lives so the tested repository stays untouched.

@INVARIANTS.md

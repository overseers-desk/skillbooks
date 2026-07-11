# tga-register-leaks

Regression fixtures for `this-guy-aint human` against AI-register leaks. Issue #170 carries the provenance and the full experiment record (an eight-run factorial on the judge and a five-detector marketplace benchmark, all scoring against these letters).

- `letter-a.md`: an AI draft of a patch-series mail carrying nine register leaks. `answer-key.tsv` maps each leak to its taxonomy category and to the form the human sender actually used.
- `letter-b.md`: the version the human sent, identical facts. The clean control.

Acceptance: judging letter-a against identity `human` returns NOT BELIEVED, the giveaways covering the answer-key rows (the secretary/officialese verdict floor triggering), stable across reruns. Judging letter-b returns BELIEVED with GIVEAWAYS: (none).

To run: follow the skill's procedure in `skills/this-guy-aint/SKILL.md`, using a fixture as the draft path, one fresh-context judge per letter. Score the returned giveaways against the answer-key rows; a row counts as caught when the judge quotes the passage as a giveaway, whatever category label it picks.

The taxonomy's anti-cheating rule leans on these files: examples in `giveaways.md` come from outside these letters, so a judge catches by category rather than by recognition. An edit to either side keeps that separation.

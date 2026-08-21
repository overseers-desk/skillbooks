# The oracle brief

What a blind estimator receives in the Oracle phase, and nothing else. Assemble it per run from the sections below; the measured table, the code, and any suspicion stay out of it (INVARIANTS I1). Send the same brief to every estimator, each in a fresh context without tools.

## Sections, in order

1. **The program's own description.** The README or its nearest equivalent, as published: what the program does and for whom. Cut installation and build detail; keep feature description.
2. **Size facts.** For each crate or package: files and lines of source. The list of documentation files by name. Without scale the estimates float.
3. **The module list.** For each module to estimate: its path, its length in lines, and its own one-line doc as the module carries it. State in the brief that the one-liner is the module's own doc line.

## The ask

Three integers per module, output as `path | A | B | C`:

- A: other non-test source files that use a type, function or constant the module defines.
- B: other files of any kind (sources including tests, docs, manifests) that mention any of the module's distinctive identifiers or its file stem anywhere, comments and prose included.
- C: total such mentions across those files.

Then the decided-once list: eight to twelve design facts a program of this description decides once, each with the number of places in the code the estimator would expect to edit if the fact changed, as `fact | expected places`. Where the run already has a fact under study, its kind is named in the ask ("include the side a panel sits on") without the measured figure.

Word limit on the reply, so the estimator commits to numbers rather than reasoning aloud; under four hundred words has served.

## What must not be in it

A measured figure. A source line. The name of a tool that ran. Which module is suspected. A note that the README is accurate or otherwise. The estimator's view of the architecture is the instrument; anything that bends it is contamination.

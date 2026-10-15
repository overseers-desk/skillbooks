---
name: stub-hunter
description: "Find tests that stub the seam they exist to guard: where production resolves its own installation and surroundings, the suite replaces the resolver, so no test learns what production really runs or reads. Also weighs assertion strength and whether a runner's verdict can disagree with its count. Detection only. Triggers: stub-hunter, hunt stubs, what do the tests stub, green tests but broken install, which seam is untested."
argument-hint: "[path to one repository; default the current one]"
---

# stub-hunter

A suite tests the artifact and stubs the installation. Each stub is defensible alone: it makes the test fast, hermetic and deterministic. Together they cut out one layer, and it is the layer where a whole class of defect lives: which copy of a module runs, which config root is read, which binary is spawned, which process invokes the code. A suite can run green for days over a machine holding several copies of the same hook, because every test imports the module and calls the function, and the thing that broke was which module the harness executed.

Your job is to find where each suite draws that line, quote it, and name the defects it makes invisible. You report; you edit nothing. A survey that also rewrote tests would hand back a pile of rewrites to review, which spends the attention the survey exists to save.

The trap to avoid: treating every mock as a finding. Most stubs are right. A stub of a network peer, a clock, or a random source in a test about parsing is the test doing its job. The finding is a stub of the seam itself, where production makes a choice about its own environment and no test ever lets it make that choice for real.

## 1. Find every suite

One run covers one repository. List every suite in it: each test directory, each runner script, each self-test built into a module, each CI job that runs one. Note how each is invoked, by what runner, and how the runner decides pass or fail. A self-test inside a hook or plugin counts as a suite; it is often the only one such code has.

## 2. Find the seams production resolves

Before reading any test, read production and list the places where it decides something about its own installation and surroundings:

- a store root, cache directory, or data path, and the environment variables or defaults that choose it
- a tool or binary path, and how it is found (`PATH` lookup, a hardcoded location, a configured one)
- a config file location, and what happens when the file named is absent
- a client, connection, or session constructor, and where its credentials come from
- an entry point that a harness, a hook runner, or another process invokes, as distinct from the function that entry point calls

Each is a seam. Note for each the line where the decision is made. A resolver that hardcodes a default and ignores the variable meant to override it is worth noting already: it may be correct today only because the filesystem happens to agree.

## 3. Find where the tests cut the seam

For each seam, search the suites for the forms that replace it:

- a test redefining or monkeypatching the resolver function, or overriding the variable it reads
- a patch or mock of the config loader or client constructor applied in every test of a command, so discovery and construction never run
- a fixture that points the store root at a temporary directory with no test that exercises the real default
- a self-test that calls a module's function in-process, where production reaches that function through a dispatcher, an entry point, or an installed copy the harness chooses
- a function holding real logic that only production dispatch calls, and no test reaches

Quote the line that cuts the seam, and the line in production it replaces.

## 4. Confirm that no test crosses it

A stub is a finding only if no test anywhere exercises the real seam. Search every suite for a call to the real resolver, constructor, or entry point with the stub absent. Where the suite has a coverage mode, run it and read whether the seam's lines execute; running a suite reads the code and changes none of it. Where a test crosses the seam for real, the stub elsewhere is the hermetic test doing its job, and it is dropped.

Label each finding `confirmed` when you have shown the seam's lines run under no test (by coverage, or by tracing every caller to production-only code), and `suspected` when you found the stub but could not rule out a test reaching the seam another way. Do not present a suspected finding as confirmed.

## 5. Name the defect class each stub hides

For each confirmed or suspected stub, say what goes wrong in production that the suite cannot see: the wrong store read when a config root changes, the wrong binary found on another machine's `PATH`, a missing `--config` file that falls through silently to environment variables, a stale installed copy running while the tested source is current. Where the suite asserts the stubbed behaviour as intended (a test that passes because the fall-through happens), say so: that suite does not just miss the defect, it ratifies it.

## 6. The two adjacent checks

The same sweep answers two further questions, because they too decide whether a green run means what it says.

**Assertion strength.** Count, per suite, the assertions that compare a boolean, a `None`, a bare `0` or `1`, or a length, against those that compare a value. A suite whose checks are mostly "it returned true" or "the list is not empty" passes on many wrong answers. Report the proportion and quote two or three representative weak assertions on code that has a value worth checking. A boolean assertion on a function whose output is a boolean is not weak.

**Runner integrity.** For each runner, find how it reaches its verdict and whether that verdict can disagree with the counts it reports. The forms: an exit code derived one way while the pass and fail counts are scraped another; a test file that ends in an unconditional pass line rather than a call that tallies its assertions, so any assertion in it can fail and the file still reports passing; a failure inside a setup step that the runner counts as no tests rather than as a failure. Quote the line. Each such case is `confirmed` if you can show the path by which a failing assertion yields a passing verdict.

## Reject hard

Report only stubs that cut a seam named in step 2, with the quoted lines and a defect class. A mock of an external service in a test about something else is not a finding. "Could use more integration tests" is not a finding. Rank by blast radius: a seam whose defect has cost time before, or one a suite ratifies as intended, above one merely untested.

## What this method will not find

It finds where suites look away. It does not find whether the code behind the seam is wrong today; a seam no test crosses may still be correct. When the survey suggests a live defect (a resolver that ignores its override variable, a fall-through on a named config file), report it as the defect class the stub hides, and leave the reproduction to a hunt that starts from the symptom.

## Output

Per suite, a ranked list of findings. For each: the seam and the production line that resolves it, the test line that cuts it, the defect class it hides, and `confirmed` or `suspected`. Then the assertion-strength proportion with its quoted examples, and any runner-integrity finding with its line. Nothing is edited and no replacement test is proposed.

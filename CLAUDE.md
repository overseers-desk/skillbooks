# skillbooks — notes for AI sessions

This repo is one Claude Code plugin: writing, editing, and review crafts as skills under `skills/<skill>/`, with `.claude-plugin/` holding the manifest. The marketplace that lists it sits in a separate repo, `overseers-desk/overseers-desk`.

The self-containment rule that must hold is in [`INVARIANTS.md`](INVARIANTS.md); a change that breaks it is a design change, the owner's to make.

@INVARIANTS.md
Testing an unreleased skill in a fresh session: `claude -p --plugin-dir <tree>` is shadowed by the installed skillbooks plugin of the same name and loads nothing new. Copy `.claude-plugin/` and `skills/` to a scratch directory, change the plugin name in the copy's manifest, and point `--plugin-dir` at the copy. A subagent given the SKILL.md path follows the skill without any loading.

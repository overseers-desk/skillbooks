# Invariants

Rules whose breach is a design change, not a fix; changing one is the owner's decision.

- A skill is self-contained in `skills/<skill>/`: its prompts, rulebooks, and scripts sit in its own directory, and its SKILL.md references them as `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/<file>`. The plugin runs from a per-machine install cache, so a hardcoded home path works only on the machine that wrote it; and a skill reaching into another skill's directory couples the two silently, so neither can be renamed, rewritten, or removed without breaking the other. The deletion test: remove any one skill and every other still runs.

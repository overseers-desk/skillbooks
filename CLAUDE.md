# Aesop — notes for AI sessions

This repo holds two things: the **AESOP methodologies** (SPAR/SIFT/TEND and their
working data, in the top-level dirs) and the **`aesop` plugin** (`plugins/aesop/`),
a Claude Code plugin that packages the skills. The plugin is distributed through the
marketplace manifest at `.claude-plugin/marketplace.json`.

## Plugin layout

- Skills live in `plugins/aesop/skills/<skill>/`, each with a `SKILL.md`. Inside a
  SKILL.md, reference sibling scripts and assets as
  `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/<script>` — Claude Code substitutes
  `${CLAUDE_PLUGIN_ROOT}` with the install path when the plugin loads. Do not
  hardcode `$HOME/.claude/skills/...` for skill files.
- The `not-google-chrome` wrapper lives in `plugins/aesop/bin/` and is on PATH while
  the plugin is enabled, so skills call it by bare name.
- Shared browser docs (`BROWSER.md`) sit in
  `plugins/aesop/skills/headless-browser/`; `config.ini.example` sits at the plugin
  root (`plugins/aesop/config.ini.example`).
- The non-skill methodology dirs (almanac, articles, contact-graph,
  correspondence-tend, events, listing-sift, outreach-spar, travel, tests, webworks,
  roster) stay at the repo root and are NOT part of the plugin.

## Headless browser and CDP

The `not-google-chrome` wrapper and the `--cdp` convention for authenticated SPAs
are documented in the headless-browser skill
(`plugins/aesop/skills/headless-browser/SKILL.md`) and the `BROWSER.md` beside it.
Never write a raw `flock ... chromium ...` invocation inline in a skill — use the
wrapper.

## Credentials

Site credentials live in `$HOME/.claude/skills/config.ini`. The path is absolute in
the scripts and the wrapper, so it deliberately does not move with the plugin. The
file is gitignored — do not commit it. Each skill's SKILL.md documents its required
keys under `Prerequisites`.

## Testing skills

Load the plugin from disk and exercise the trigger end-to-end:

```bash
claude --plugin-dir ./plugins/aesop -p --dangerously-skip-permissions "<natural language request>"
```

Or inspect what the plugin exposes without running it:
`claude --plugin-dir ./plugins/aesop plugin details aesop`. Calling a script
directly with `python3` only tests the script, not the skill trigger; a skill is not
"working" until `claude -p` returns real data.

## The ~/.claude/skills symlink

`~/.claude/skills` still symlinks to this repo root. With the skills now under
`plugins/aesop/skills/`, the symlink no longer surfaces them as personal skills — it
remains only because `$HOME/.claude/skills/config.ini` resolves through it. Leave it
in place for credential resolution. Do not repoint it at `plugins/aesop/skills`:
loaded as personal skills, `${CLAUDE_PLUGIN_ROOT}` is not substituted and the script
paths break. Use the skills through the plugin (`--plugin-dir` or a marketplace
install), not the symlink.

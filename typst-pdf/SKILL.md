---
name: typst-pdf
description: Render a markdown file to PDF via Typst, optionally applying a per-repo template discovered at .aesop/default.typ or .aesop/letterhead.typ. Trigger when the user asks to convert markdown to PDF, print a document, produce a letterhead-style PDF, or render with typst.
argument-hint: <input.md> [--letterhead | --no-letterhead] [--out <path>] [--view]
allowed-tools: Bash, Read
---

## What this skill does

Converts a single markdown file to PDF using Typst. When run inside a git repository, it auto-discovers template files at `<repo>/.aesop/default.typ` (plain template) and `<repo>/.aesop/letterhead.typ` (letterhead template). The repo owns the look — fonts, margins, page geometry, logo placement — by writing those templates. The skill itself does not know about any specific font, brand, or repo.

If invoked outside a git repository, or if the repo has no `.aesop/` templates, the skill produces a plain PDF with Typst's default styling.

## How to invoke

Pass the markdown file as the first argument. The driver is at `$HOME/.claude/skills/typst-pdf/typst-pdf.sh`. Run it directly — do not spawn a subagent for this skill.

```bash
$HOME/.claude/skills/typst-pdf/typst-pdf.sh <input.md> [flags]
```

Flags:

- `--letterhead` / `--no-letterhead` — pick the letterhead or plain template non-interactively. If neither flag is passed and both templates exist, the driver asks via stdin.
- `--out <path>` — explicit output path. If omitted, the driver suggests a save directory (XDG documents dir on Linux, `$HOME/Documents` on macOS) and asks the user to confirm or override.
- `--view` — open the PDF after compilation.

## Prerequisites

- `typst` — macOS: `brew install typst`; Linux: `sudo snap install typst`.
- `pandoc` 3.x with the built-in Typst writer — macOS: `brew install pandoc`; Linux: `sudo apt install pandoc` (or your distro's equivalent).

The driver checks for both at startup and prints a platform-appropriate install hint if either is missing.

## Per-repo template contract

The skill looks for two files at `<repo>/.aesop/`:

- `default.typ` — required if any template is to be applied. Must export a function named `template` taking the document body, e.g. `#let template(body) = { ...; body }`.
- `letterhead.typ` — optional. Same `template(body)` contract. Typically imports or composes with `default.typ` and adds page-1 letterhead elements (logo, header).

The driver wraps the converted markdown body with the chosen template by writing a small wrapper file:

```typst
#import "<repo>/.aesop/<chosen>.typ": template
#show: template
#include "body.typ"
```

It compiles with `typst compile --root <repo>` so the template can reference relative paths inside the repo (logos, fonts, included files).

## What this skill does NOT do

- Does not inspect fonts, suggest font installs, or know about any font family by name. Font policy is entirely in the template; missing fonts fall back via Typst's bundled defaults and surface as warnings in the compile output.
- Does not optimise table column widths. Typst's `auto` and `fr` column units cover most cases; tune `columns:` in the template or source when a specific table needs help.
- Does not concatenate multiple markdown files. One file in, one PDF out.
- Does not read any `meta.yaml` or other Pandoc metadata files.

## Save location

When `--out` is not specified, the driver picks a suggested directory in this order:

1. Linux: `xdg-user-dir DOCUMENTS` if installed, else `XDG_DOCUMENTS_DIR` from `~/.config/user-dirs.dirs`.
2. macOS: `$HOME/Documents` (filesystem path is always English; Finder's localised display name is cosmetic).
3. Anywhere: `$HOME`.

The user is shown the suggested path and can paste any other path in response. The driver does not write without confirmation.

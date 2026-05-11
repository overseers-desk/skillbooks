---
name: australia.skal.org
description: "Skal Australia (Skål) member portal via pyskal CLI: members, clubs, events."
allowed-tools: Bash
---

Run from the `src/` directory of the repository:

    cd $HOME/code/pyatdw/src && python3 -m pyskal <command>

Commands: login, members [--limit], member <id>, search [--name] [--city] [--club <id>] [--email] [--state] [--limit], clubs, events [--limit].

Member `--state` values: active, draft, unpaid, done, club_change. Default search excludes `done` (departed). Club IDs: 330 Melbourne, 334 Sydney, 322 Brisbane, 333 Perth, 321 Adelaide, 1003 Gold Coast, etc. (full list in docs/skal-api.md).

Credentials go in the `[skal]` section of config.toml. The session cookie lasts ~30 days and is cached automatically; login writes the session_id back to config.toml.

Add --json to any read command for machine-readable output.

Consult docs/manual.md for the full flag reference and docs/skal-api.md for the Skal API.

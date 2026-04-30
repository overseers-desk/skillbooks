---
name: atdw-online.com.au
description: Query and edit ATDW tourism listings via the pyatdw CLI. Use when the user asks about listings, searches, or edits on the Australian Tourism Data Warehouse.
allowed-tools: Bash
---

Run from the `src/` directory of the repository:

    cd $HOME/code/pyatdw/src && python3 -m pyatdw <command>

Commands: login, listings, listing <id>, search [--type] [--city] [--state] [--name] [--limit], edit <id> <field> <value>, submit <id>.

Configuration lives in config.toml one level above src/. Credentials go in the `[atdw]` section; the JWT token is cached automatically and renewed when it expires.

Add --json to any read command for machine-readable output.

Consult docs/manual.md for the full flag reference and docs/APIs.md for the ATDW API.

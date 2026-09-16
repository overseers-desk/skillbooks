# Brief read-order paragraph

Every brief opens with one paragraph beginning `Read`, listing in backticks every path the agent may read, in order. `tools/launch-check.py` parses this paragraph to know which files to scan and fails a brief that lacks it.

Read `<path>` first, then `<path>`, then `<path>`. Nothing else in the repository is open to you.

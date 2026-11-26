# The lab for HIRE

Versions of `sales-hire/hire-methodology.md` that are being compared with each other, and what the comparisons found. A consumer follows the method in `sales-hire/`. Nothing in this folder is the method.

## When a change comes here, and when it goes straight into the method

A change goes straight into `sales-hire/` when it is believed to help and can be rolled back if a later run shows a regression. The history of that folder is then the record.

A change comes here when it has to stand beside other versions at the same time. That is the case for a test laid out as a matrix, versions by posts by repeat runs, and for two explanations of one result that call for different texts. A writer can be pointed at each version in turn, and the versions outlive the comparison.

## Layout

Each round is one folder, `round-N/`. Its worklog calls it sales-improvement-N.

- `variants/` holds one file per version, each the whole text of the method.
- `make-variants.py` defines each version as the baseline text with a named set of replacements, and writes the files in `variants/`.
- The worklog, a dated `…-WORKLOG-sales-improvement-N.md`, says what the round ran and what it found.

A round starts from a baseline commit of the method, named at the top of its worklog and of its `make-variants.py`. When a version has held across more than one post, its replacements go into `sales-hire/hire-methodology.md` as an ordinary commit, and the next round starts from there.

## What stays outside this repository

The posts a real candidate applied to, the CVs written for them and the judges' answers name people and employers. They are kept outside this repository. A round's worklog names posts by role and says where its key is.

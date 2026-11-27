# The lab for HIRE

Versions of `sales-hire/hire-methodology.md` that are being compared with each other, and what the comparisons found. A consumer follows the method in `sales-hire/`. Nothing in this folder is the method.

## When a change comes here, and when it goes straight into the method

A change goes straight into `sales-hire/` when it is believed to help and can be rolled back if a later run shows a regression. The history of that folder is then the record.

A change comes here when it has to stand beside other versions at the same time. That is the case for a test laid out as a matrix, versions by posts by repeat runs, and for two explanations of one result that call for different texts. A writer can be pointed at each version in turn, and the versions outlive the comparison.

## Layout

`ROADMAP.md` lists the lessons from selling that the rounds test, and what each has shown so far.

Each round is one folder, `round-N/`. Its worklog calls it sales-improvement-N.

- `variants/`, where a round writes versions, holds one file per version, each the whole text of the method.
- `make-variants.py`, in such a round, defines each version as the baseline text with a named set of replacements, and writes the files in `variants/`.
- The worklog, a dated `…-WORKLOG-sales-improvement-N.md`, says what the round ran and what it found.
- `modules/`, where a round has any, holds questions put to a reader about the page, one file each.
- Data files hold the round's comparisons, with posts named by role.

A round starts from a baseline commit of the method, named at the top of its worklog and of its `make-variants.py`. When a version has held across more than one post, its replacements go into `sales-hire/hire-methodology.md` as an ordinary commit, and the next round starts from there.

## A reader's question is a module

A question put to a reader about the page is tested here as a module file, and copied into `sales-hire/modules/` by an ordinary commit when it has held. The method's text names which modules to run and what to do with their answers. It does not carry the question itself, so a question never has two homes.

## What stays outside this repository

What a round learns about the method is kept here: the roadmap, the worklog, the versions, and results with posts named by role. What a round works on is kept outside: the posts a real candidate applied to, the CVs written for them, the writers' folders, the judges' notes and answers, and any script that names a post. These name people and employers, and this repository is public.

The outside material sits in one folder per series, with a key file that maps each role name used here to the real post and lists the tools. A round's worklog says where that folder is. The folder is not under this repository's version control, so keeping a second copy of it is for whoever runs the round to arrange.

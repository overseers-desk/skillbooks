# Amendment coder, from profiles

Read `briefs/coder-brief-block.md` first, then the whole of `{{AMENDMENT}}`, then the comparable profiles listed in your shard file under `{{CORPUS}}/shards/`.

Code the variables your prompt names, for every profile in your shard, from the profile's captured text alone. Where the run holds stored page text, this brief serves the units that have none, as your shard file lists them. Write one file, `{{CODED}}/<your shard's name>/<your shard's name>.tsv`, tab-separated, whose header row is the one line of `{{CORPUS}}/shards/header.tsv` copied as it stands: the key columns, then each variable's code followed by every field of its record form, one column each, then the trailing columns the header ends with. A row is one unit: a profile of a single operator is one row, keyed as your shard file spells it and by the unit id its capture record prints; a profile holding several listings gives each listing its own row under its own unit id. Several values in one cell are separated by "; " and by nothing else.

A closed value goes in its own column and is never folded into a phrases column, since a coder that has to name the closed value codes fewer doubtful positives. Where the header carries a shared phrases column, it holds the verbatim words behind each coded value, each opened with its field's name.

A profile is an earlier reader's selection made under an earlier codebook, so a value the profile does not carry may be on the page and not in front of you. Where the amendment names the values a profile-only unit takes, code by those. Where it names none, code what the profile prints, and where the amendment's zero means the scope was read in full and says nothing, say in the note that you could not attest that.

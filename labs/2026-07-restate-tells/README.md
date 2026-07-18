# 2026-07 restate tells

Regression fixtures for `this-guy-aint human` against the restate and phantom-specific categories. The categories came out of a 115-document workplace-corpus audit where trailing restatement (closing summaries, announce-intros, padded last list items, re-worded warnings) was the strongest single marker of non-member authorship, and invented precision beside committed-specific vagueness was the runner-up.

## Files

- `note-a.md` — a plant nursery's morning watering procedure carrying seven planted leaks (five restate, two phantom-specific). Every fact in it is real to the fixture. The closing "That is the rule. Zero means closed." stays as a distractor: a judge read it as human emphasis, and the key does not claim it.
- `note-b.md` — the same procedure as a member writes it: identical facts, no restatement, no invented number.
- `answer-key.tsv` — columns `leak / category / member_form`, one row per planted leak.

## Acceptance criteria

- `this-guy-aint human` on `note-a.md` returns NOT BELIEVED, with the three-or-more restate/secretary/officialese floor firing, and GIVEAWAYS covering the answer-key rows. A row counts as caught when the judge quotes the passage, whatever category label it assigns.
- `this-guy-aint human` on `note-b.md` returns BELIEVED with `GIVEAWAYS: (none)` or nothing beyond a stray minor item.

## Separation rule

The taxonomy's examples in `giveaways.md` stay disjoint from these fixtures (they use a bakery, a lab manual, and a gym; the fixtures use a plant nursery). Keep that separation on any edit, so the judge applies the category rather than recognising a remembered phrase.

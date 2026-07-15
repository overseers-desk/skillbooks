---
name: densify
description: Shrink a verbose text so that every specific (dates, numbers, names, commands, caveats) survives, verified by a mapping rather than by feel. Triggers: densify, densify this document.
argument-hint: "[file or text to densify]"
---

# Densify

Densification shrinks a text while keeping every concrete specific and epistemic marker; the office methodology's Densify rule sets the standard, this skill is the method. It makes terseness checkable instead of felt. Run the rounds yourself; the reader of the result sees none of them.

1. **Inventory.** Before touching the text, list its atomic elements, one line each: every concrete specific (number, date, name, path, command, magnitude absolute or relative), every epistemic marker (checked-and-empty, unobtainable, not-attempted, approximated, inferred), every instruction or prohibition, and each distinct claim. The inventory is the contract; everything after is measured against it.

2. **Over-dry draft.** Compress past the point of damage, losses accepted. This draft is an instrument, not a candidate: diff it against the inventory, and the elements it killed are the ones carrying the most meaning per word. They become the guard list.

3. **Rebuild.** Start from the over-dry end and reinsert each killed element in the fewest words that restore it. Ceremony is what stays out: self-narrating structure ("This document describes…"), headings that restate their section, summaries repeating earlier text, rationale the reader infers unaided. Where one fact appears as prose and again as a table or diagram, keep the strongest rendering and fold the rest into it.

4. **Verify.** Map every inventory line to a span of the rebuilt text. An element with no span is a failed run: reinsert it. Replacing a specific with a generic ("three retries" becoming "retries") is summarisation, not densification, and also fails. So does a reference that resolves only in the original's structure (a section number, an item count, a label the rebuild renamed): re-point it at what the result actually contains. Stop cutting when removing any further word would break a mapping.

5. **Deliver** the final text with the mapping (inventory line → surviving span) so the caller audits survival. Drafts stay with you.

Judge the result against the document's job, not word count: a README's reader is deciding whether to adopt, an SOP's reader is mid-procedure, a report's reader wants the finding. For human-facing artifacts the result also carries the LHD rule: it should not read AI-authored.

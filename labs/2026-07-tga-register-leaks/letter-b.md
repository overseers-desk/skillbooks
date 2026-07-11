Hi Kevin, hi Marc,

Here is the revised set: five of the original patches plus a new one, one patch per problem. Rebased onto b8aff6ba47; they also apply in order on this morning's 62b1edc657. Re-verified: grab.test 28 passed, 0 failed, 1 skipped; clipboard.test 41 of 41; the smoke checks from the first mail all pass.

The six problems, in apply order:

1. wish crashes at exit. Any script that lives past the first focus callback dies with "alloc: invalid block", "fstat: Bad file descriptor" or "epoll_ctl: No such file or directory", depending on fd reuse.

2. The cursor never restores. One hover over a panedwindow sash leaves the resize cursor stuck over the whole app; grab has no effect; winfo pointerxy returns -1 -1.

3. Photo images reject every color. $photo put fails on "blue" and "#0000ff" alike; bitmap images and cursor colors fail the same way.

4. wm state . segfaults, and wm state . iconic silently does nothing.

5. The clipboard misbehaves three ways: selection get -selection CLIPBOARD returns an empty string with a success code; <<Paste>> deletes the selected text and inserts nothing; and a hung wl-paste freezes the whole UI.

6. Mouse back and forward buttons never arrive. My own pointer patch in the earlier set dropped them, which is why I held that set.(*)

The notifier patch is withdrawn. I noticed Marc's event-loop change at ff9b48d9eb already removed the per-pass re-arm, so the update livelock and the CPU spin are gone at the tip.

I had to admit I don't know what "idle ring", "queue presentation" or "layout expose evaluation" mean either; they first arrived with checkin 45fcca1982 ("Additional progress on drawing", 2026-06-21, kevin_walzer), before my first patch of 24 June.

Kevin: I see you are still committing while travelling? Take care!

Weiwu

(*) GLFW buttons 4/5 map to Button4Mask/Button5Mask; Tk_UpdatePointer's diff loop delivers them as <Button-8>/<Button-9>, the same mapping the win port uses.

Hi Kevin, hi Marc,

Here is the corrected set: five of the original patches plus a new one. They were rebased onto b8aff6ba47 and also apply in order on this morning's 62b1edc657. Re-verified: grab.test 28 passed, 0 failed, 1 skipped; clipboard.test 41 of 41; the smoke checks from the first mail all pass.

Re-reviewing my own set after sending it is what triggered the hold: the pointer patch had dropped the mouse back and forward buttons. The new patch (06-pointer-review-fixups.patch) restores them (GLFW buttons 4/5 map to Button4Mask/Button5Mask, and Tk_UpdatePointer's diff loop delivers them as <Button-8>/<Button-9>, the same mapping the win port uses), removes two per-apply fprintf traces, and corrects a comment that described a state mask nothing ever set.

What each patch does:

1. 01-ibus-fd-lifecycle.patch: registers the IBus file handler on a Tk-owned dup of the sd_bus fd, torn down on disconnect and shutdown, so wish no longer crashes at exit.

2. 02-pointer-module-cursor-grabs.patch: compiles generic/tkPointer.c into the build and hands event generation to Tk_UpdatePointer, so cursors restore and app-local grabs work.

3. 03-photo-color-parsing.patch: links xlib/xcolors.o and defines TkpGetPixel, so photo put accepts color specs.

4. 04-wm-state-dispatch.patch: adopts the post-shift argument convention in WmStateCmd, so wm state no longer segfaults.

5. 05-clipboard-glfw-native.patch: replaces the wl-copy/wl-paste bridge with GLFW's clipboard API.

6. 06-pointer-review-fixups.patch: the fixes described above.

The notifier patch is withdrawn. Marc, your event-loop change at ff9b48d9eb already removed the per-pass re-arm, so the update livelock and the CPU spin are gone at the tip.

On the vocabulary in the block you quoted: I do not know what "idle ring", "queue presentation", or "layout expose evaluation" mean either; they first arrived with checkin 45fcca1982 ("Additional progress on drawing", 2026-06-21, kevin_walzer), which predates my first patch of 24 June.

Kevin, no rush given the travel. If the tip has moved by the time you get to these, say so and I will rebase and resend.

Weiwu

# Tcl concurrency primitives — what to use

Confirmed available on both target platforms for Tcl 9 (macOS, via the user's `wish9.0` probe; Ubuntu 25.10, on this host):

| Package    | macOS  | Ubuntu | Where it comes from on Ubuntu |
|------------|--------|--------|-------------------------------|
| Thread     | 3.0.4  | 3.0.1  | `apt install tcl9.0-thread`   |
| coroutine  | 1.4    | 1.4    | `tcllib`                      |
| uevent     | 0.3.2  | 0.3.2  | `tcllib`                      |
| TclOO      | 1.3.1  | 1.3.1  | built into Tcl 9              |

The built-in event loop (`after`, `vwait`, `fileevent`, `chan event`) is always available — no `package require`.

## Concurrent vs not

Of the five things above, only one gives real OS-thread parallelism. The others matter for different reasons.

- **Thread (with `tpool::` API)** — real OS threads, each with its own Tcl interpreter; true parallelism across cores. This is what `test/run.tcl` uses to fan test files out across `[exec nproc]` workers.
- **Built-in event loop** (`after` / `vwait` / `fileevent`) — single-threaded, cooperative. "Concurrent" in the non-blocking-I/O sense, not parallel. Reach for this when the work is I/O-bound and a single core suffices.
- **coroutine** — cooperative single-thread; **not concurrent in the parallel sense**. Lets one task `yield` to another inside the same interpreter. Worth mentioning because the name invites the wrong assumption — coroutines on multi-core machines still occupy exactly one core.
- **uevent** — pub/sub on the event loop. A decoupling tool, not a concurrency primitive; subscribers fire on the same thread that posted.
- **TclOO** — object system. Orthogonal to concurrency, listed only because it sometimes appears alongside the others in capability checks.

## Tpool is an API, not a package

Thread 2.x had `Tpool` as a separately requireable package; Thread 3.x folded the same functionality into the `Thread` package under the `tpool::` namespace. Don't `package require Tpool` on Tcl 9 — it fails. The right shape:

```tcl
package require Thread

set p [tpool::create \
    -minworkers 0 \
    -maxworkers [exec nproc] \
    -idletime   30]

set jobs {}
foreach item $work {
    lappend jobs [tpool::post -nowait $p [list do_work $item]]
}

while {[llength $jobs]} {
    set done [tpool::wait $p $jobs jobs]
    foreach j $done { ... [tpool::get $p $j] ... }
}
tpool::release $p
```

This gives the two properties that make a thread-pool useful: jobs queue automatically when every worker is busy, and the pool itself scales between `-minworkers` and `-maxworkers` on demand (and decays back after `-idletime`). `tpool::wait` is event-loop aware, so a Tk progress UI in the same interpreter keeps repainting while jobs run.

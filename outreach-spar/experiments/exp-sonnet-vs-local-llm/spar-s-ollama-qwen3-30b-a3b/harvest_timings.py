#!/usr/bin/env python3
"""Harvest timing records for the ollama/qwen3-30b-a3b SPAR run.

Pulls from three places, all read-only, and writes one dated CSV of
per-request rows plus a summary text file next to this script:

  1. The remote ollama journal (`journalctl -u ollama`), read over SSH.
     Gives per-request prefill (prompt processing) and generation
     (token-by-token print_timing) traces, keyed by (pid, task).
  2. The dispatcher's own console logs (pilot*.out under whatever
     scratchpad directory --scratchpad points at), which carry local-time
     [START] lines per worker and any FAIL lines with the worker's own
     elapsed seconds.
  3. The per-attempt directories under --spar-log-dir, whose name suffix
     is the attempt's start timestamp, used only to confirm which attempt
     a given stretch of ollama activity belongs to.

Clock reconciliation: the ollama journal is read with `-o short-iso`,
which prints each line's timestamp with its own UTC offset (+08:00 on
dappnode). Every such timestamp is parsed as an aware datetime and
converted to UTC internally; nothing is compared as naive local time.
The dispatcher's pilot*.out timestamps are plain local text
("Sun Sep 20 22:12:57 AEST 2026"); AEST is treated as a fixed UTC+10
offset (no DST in effect for this run's dates) and converted to UTC the
same way. All display columns in the output CSV/summary are rendered
back in AEST (UTC+10) so a human reads one clock throughout, but every
comparison and every duration is computed in UTC to avoid the +08/+10
skew corrupting an interval.

Safety: this script only reads. It never touches the ollama service,
never sends it a request, and never touches the dispatcher or its
workers. Every SSH call carries an explicit timeout.

Usage:
    python3 harvest_timings.py --scratchpad /path/to/session/scratchpad \\
        [--since "6 hours ago"] [--host dappnode@dappnode] \\
        [--spar-log-dir /var/local/log/spar] [--segment supplier-horse-owner]

Re-running is safe and cheap: it re-reads the journal (bounded by
--since), re-parses local files, and writes a fresh dated table each
time (the previous dated table is left in place, since a re-runnable
harvester able to overwrite the record of an earlier run is not what
"re-runnable" is meant to buy here).
"""
import argparse
import glob
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone

AEST = timezone(timedelta(hours=10))
REMOTE_TZ_NOTE = "remote journal read with its own +08:00 offset; all comparisons done in UTC"

HERE = os.path.dirname(os.path.abspath(__file__))

DEFAULT_HOST = "dappnode@dappnode"
# No default scratchpad path is baked in here: the dispatcher's console logs
# live in a session-specific scratchpad whose path names the calling
# project, so it is passed explicitly with --scratchpad at run time.
DEFAULT_SCRATCHPAD = None
DEFAULT_SPAR_LOG_DIR = "/var/local/log/spar"
DEFAULT_SEGMENT = "supplier-horse-owner"


# ---------------------------------------------------------------------------
# Remote journal
# ---------------------------------------------------------------------------

def fetch_journal(host, since, ssh_timeout=45):
    """Read the ollama journal over SSH. Read-only, guarded by a timeout."""
    cmd = [
        "timeout", str(ssh_timeout),
        "ssh", "-o", "ConnectTimeout=10", "-o", "BatchMode=yes", host,
        f"sudo journalctl -u ollama --no-pager --since '{since}' -o short-iso",
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=ssh_timeout + 10)
    except subprocess.TimeoutExpired:
        print(f"WARNING: ssh to {host} timed out fetching journal", file=sys.stderr)
        return ""
    if result.returncode != 0:
        print(f"WARNING: journalctl over ssh exited {result.returncode}: {result.stderr.strip()[:300]}",
              file=sys.stderr)
    return result.stdout


LINE_TS_RE = re.compile(r"^(\S+T\S+[+-]\d{2}:\d{2})\s+\S+\s+ollama\[(\d+)\]:\s*(.*)$")
NEW_PROMPT_RE = re.compile(
    r"task (\d+) \| new prompt, n_ctx_slot = (\d+), n_keep = (\d+), task\.n_tokens = (\d+)"
)
PREFILL_RE = re.compile(
    r"task (\d+) \| prompt processing, n_tokens\s*=\s*(\d+), progress = ([\d.]+), "
    r"t = ([\d.]+) s / ([\d.]+) tokens per second"
)
GEN_RE = re.compile(
    r"task (\d+) \| n_gen\s*=\s*(\d+), tg\s*=\s*([\d.]+) t/s"
)
RELEASE_RE = re.compile(
    r"task (\d+) \| stop processing: n_tokens = (\d+), truncated = (\d+)"
)
GIN_RE = re.compile(
    r"\[GIN\]\s+\S+ - \S+\s+\|\s*(\d+)\s+\|\s*([^|]+?)\s*\|\s*\S+\s+\|\s*(\w+)\s+\"([^\"]+)\""
)
MODEL_LOAD_RE = re.compile(r'msg="loading model via llama-server"')


def parse_gin_duration(s):
    """Parse a Go-style duration ("8m7s", "56.028555345s", "809.243µs") to seconds."""
    s = s.strip()
    total = 0.0
    for value, unit in re.findall(r"([\d.]+)(h|m|s|ms|µs|us|ns)", s):
        value = float(value)
        if unit == "h":
            total += value * 3600
        elif unit == "m":
            total += value * 60
        elif unit == "s":
            total += value
        elif unit == "ms":
            total += value / 1e3
        elif unit in ("µs", "us"):
            total += value / 1e6
        elif unit == "ns":
            total += value / 1e9
    return total


def parse_journal(text):
    """Parse journal text into per-(pid,task) request records, plus a GIN log."""
    requests = {}  # (pid, task) -> dict
    order = []     # list of (pid, task) in first-seen order
    gin_events = []  # list of dicts: ts, pid, status, duration_s, path
    model_loads = []  # list of (ts, pid)

    for raw_line in text.splitlines():
        m = LINE_TS_RE.match(raw_line)
        if not m:
            continue
        ts_str, pid, rest = m.groups()
        try:
            ts = datetime.fromisoformat(ts_str).astimezone(timezone.utc)
        except ValueError:
            continue
        pid = int(pid)

        mm = NEW_PROMPT_RE.search(rest)
        if mm:
            task = int(mm.group(1))
            key = (pid, task)
            if key not in requests:
                requests[key] = {
                    "pid": pid, "task": task,
                    "start_ts": ts,
                    "prompt_tokens": int(mm.group(4)),
                    "prefill_checkpoints": [],
                    "gen_checkpoints": [],
                    "release_ts": None,
                    "release_tokens": None,
                    "truncated": None,
                }
                order.append(key)
            continue

        mm = PREFILL_RE.search(rest)
        if mm:
            task = int(mm.group(1))
            key = (pid, task)
            if key in requests:
                requests[key]["prefill_checkpoints"].append((
                    ts, int(mm.group(2)), float(mm.group(3)),
                    float(mm.group(4)), float(mm.group(5)),
                ))
            continue

        mm = GEN_RE.search(rest)
        if mm:
            task = int(mm.group(1))
            key = (pid, task)
            if key in requests:
                requests[key]["gen_checkpoints"].append((
                    ts, int(mm.group(2)), float(mm.group(3)),
                ))
            continue

        mm = RELEASE_RE.search(rest)
        if mm:
            task = int(mm.group(1))
            key = (pid, task)
            if key in requests:
                requests[key]["release_ts"] = ts
                requests[key]["release_tokens"] = int(mm.group(2))
                requests[key]["truncated"] = int(mm.group(3))
            continue

        mm = GIN_RE.search(rest)
        if mm:
            status, duration_str, method, path = mm.groups()
            if "chat/completions" in path or "generate" in path:
                gin_events.append({
                    "ts": ts, "pid": pid, "status": int(status),
                    "duration_s": parse_gin_duration(duration_str),
                    "path": path,
                })
            continue

        if MODEL_LOAD_RE.search(rest):
            model_loads.append((ts, pid))

    # last task per pid, to know which one is still "in flight" (no release,
    # nothing after it in the fetched window)
    last_task_per_pid = {}
    for (pid, task), rec in requests.items():
        if pid not in last_task_per_pid or task > last_task_per_pid[pid]:
            last_task_per_pid[pid] = task
    last_pid_overall = max(requests[k]["start_ts"] for k in order) if order else None

    rows = []
    for key in order:
        rec = requests[key]
        pid, task = key
        prefill_cps = rec["prefill_checkpoints"]
        gen_cps = rec["gen_checkpoints"]

        if prefill_cps:
            last_pf = prefill_cps[-1]
            prefill_duration_s = last_pf[3]
            prefill_tokens_processed = last_pf[1]
            prefill_rate_tps = last_pf[4]
            prefill_end_ts = last_pf[0]
        elif gen_cps:
            # prompt short enough to process in one batch; no incremental line
            prefill_end_ts = gen_cps[0][0]
            prefill_duration_s = (prefill_end_ts - rec["start_ts"]).total_seconds()
            prefill_tokens_processed = rec["prompt_tokens"]
            prefill_rate_tps = (
                prefill_tokens_processed / prefill_duration_s if prefill_duration_s > 0 else None
            )
        elif rec["release_ts"]:
            prefill_end_ts = rec["release_ts"]
            prefill_duration_s = (prefill_end_ts - rec["start_ts"]).total_seconds()
            prefill_tokens_processed = rec["prompt_tokens"]
            prefill_rate_tps = (
                prefill_tokens_processed / prefill_duration_s if prefill_duration_s > 0 else None
            )
        else:
            prefill_end_ts = None
            prefill_duration_s = None
            prefill_tokens_processed = None
            prefill_rate_tps = None

        gen_tokens = gen_cps[-1][1] if gen_cps else 0
        last_gen_ts = gen_cps[-1][0] if gen_cps else None

        is_last_overall = (
            last_pid_overall is not None and rec["start_ts"] == last_pid_overall
            and task == last_task_per_pid.get(pid)
        )

        if rec["release_ts"] is not None:
            status = "success" if rec.get("truncated") == 0 else "success(truncated)"
            end_ts = rec["release_ts"]
        elif is_last_overall:
            status = "in_flight"
            end_ts = None
        else:
            status = "aborted_or_superseded"
            end_ts = last_gen_ts or prefill_end_ts

        if end_ts is not None and prefill_end_ts is not None:
            gen_duration_s = max((end_ts - prefill_end_ts).total_seconds(), 0.0)
        else:
            gen_duration_s = None
        gen_rate_tps = (
            gen_tokens / gen_duration_s if gen_duration_s and gen_duration_s > 0 and gen_tokens else None
        )

        if end_ts is not None:
            total_duration_s = (end_ts - rec["start_ts"]).total_seconds()
        elif status == "in_flight":
            # No release event exists to mark an end, but the elapsed-so-far
            # is knowable from the start time to now.
            total_duration_s = (datetime.now(timezone.utc) - rec["start_ts"]).total_seconds()
        else:
            total_duration_s = None

        rows.append({
            "pid": pid,
            "task": task,
            "start_ts_utc": rec["start_ts"],
            "prompt_tokens": rec["prompt_tokens"],
            "prefill_tokens_processed": prefill_tokens_processed,
            "prefill_duration_s": prefill_duration_s,
            "prefill_rate_tps": prefill_rate_tps,
            "gen_tokens": gen_tokens,
            "gen_duration_s": gen_duration_s,
            "gen_rate_tps": gen_rate_tps,
            "total_duration_s": total_duration_s,
            "status": status,
            "end_ts_utc": end_ts,
        })

    return rows, gin_events, model_loads


# ---------------------------------------------------------------------------
# Dispatcher pilot*.out logs
# ---------------------------------------------------------------------------

PILOT_TS_RE = re.compile(r"^\[(\w+ \w+ +\d+ \d+:\d+:\d+ AEST \d+)\]")
T0_RE = re.compile(r"'T0: (\d+) source\(s\) across (\d+) segment\(s\)'")
SEGMENT_RE = re.compile(r"'Segment: (\S+)'")
START_RE = re.compile(r"'  \[START\] (\S+)'")
PHASE_RE = re.compile(r"'\[(\S+)\] \[phase: ")
FAIL_ELAPSED_RE = re.compile(
    r"'FAIL \(sweep: ended without result after (\d+)s; exit (-?\d+), stderr: (.*?)\): (\S+)'"
)


def parse_aest(ts_str):
    # e.g. "Sun Sep 20 22:12:57 AEST 2026"
    ts_str = ts_str.replace(" AEST ", " ")
    dt = datetime.strptime(ts_str, "%a %b %d %H:%M:%S %Y")
    return dt.replace(tzinfo=AEST).astimezone(timezone.utc)


def parse_pilot_logs(scratchpad_dir, segment_filter=None):
    """Parse pilot*.out files into a list of attempts, each with its workers."""
    attempts = []
    paths = sorted(glob.glob(os.path.join(scratchpad_dir, "pilot*.out")))
    for path in paths:
        name = os.path.basename(path)
        try:
            with open(path, "r", errors="replace") as f:
                lines = f.readlines()
        except OSError as e:
            print(f"WARNING: could not read {path}: {e}", file=sys.stderr)
            continue

        attempt = {
            "file": name, "t0_ts": None, "segment": None,
            "n_sources": None, "workers": [],
        }
        worker_starts = {}  # source -> ts ([START] line: scheduled, not necessarily launched)
        reached = set()     # sources that actually got a "[phase: ...]" line, i.e. really launched
        for line in lines:
            m = PILOT_TS_RE.match(line)
            ts = parse_aest(m.group(1)) if m else None

            m2 = SEGMENT_RE.search(line)
            if m2:
                attempt["segment"] = m2.group(1)

            m2 = T0_RE.search(line)
            if m2 and attempt["t0_ts"] is None:
                attempt["t0_ts"] = ts
                attempt["n_sources"] = int(m2.group(1))

            m2 = START_RE.search(line)
            if m2:
                worker_starts.setdefault(m2.group(1), ts)

            m2 = PHASE_RE.search(line)
            if m2:
                reached.add(m2.group(1))

            m2 = FAIL_ELAPSED_RE.search(line)
            if m2:
                elapsed_s, exit_code, stderr_snip, source = m2.groups()
                start_ts = worker_starts.get(source)
                attempt["workers"].append({
                    "source": source,
                    "start_ts": start_ts,
                    "elapsed_s": int(elapsed_s),
                    "end_ts": (start_ts + timedelta(seconds=int(elapsed_s))) if start_ts else None,
                    "exit_code": exit_code,
                    "reason": stderr_snip[:200],
                    "outcome": "failed",
                })

        seen_sources = {w["source"] for w in attempt["workers"]}
        for source, start_ts in worker_starts.items():
            if source not in seen_sources:
                if source in reached:
                    attempt["workers"].append({
                        "source": source, "start_ts": start_ts, "elapsed_s": None,
                        "end_ts": None, "exit_code": None, "reason": None,
                        "outcome": "unresolved_in_this_log", "reached": True,
                    })
                else:
                    # The dispatcher runs one worker at a time; a source with
                    # no "[phase: ...]" line was never actually launched in
                    # this attempt -- it was queued behind another worker
                    # and the attempt ended (or was interrupted) before its
                    # turn. It gets no requests attributed to it. end_ts and
                    # elapsed_s are filled in below, once we know whether the
                    # attempt has since ended (next attempt's T0) or is still
                    # the live one (elapsed since being queued, to now).
                    attempt["workers"].append({
                        "source": source, "start_ts": start_ts, "elapsed_s": None,
                        "end_ts": None, "exit_code": None, "reason": None,
                        "outcome": "queued_not_reached (dispatcher runs one worker at a "
                                   "time; never got a phase line before the attempt ended)",
                        "reached": False,
                    })
        for w in attempt["workers"]:
            w.setdefault("reached", w["source"] in reached)

        if segment_filter and attempt["segment"] and attempt["segment"] != segment_filter:
            continue
        attempts.append(attempt)

    # Fill in end_ts for workers with no FAIL line: bounded by the next
    # attempt's T0 (operator moved on / restarted), or left open (still
    # running) for the very last attempt's workers.
    for i, attempt in enumerate(attempts):
        next_t0 = attempts[i + 1]["t0_ts"] if i + 1 < len(attempts) else None
        for w in attempt["workers"]:
            if w["outcome"] == "unresolved_in_this_log":
                if next_t0 is not None:
                    w["outcome"] = "ended_by_operator (assumed, no FAIL line logged)"
                    w["end_ts"] = next_t0
                    if w["start_ts"]:
                        w["elapsed_s"] = (next_t0 - w["start_ts"]).total_seconds()
                else:
                    # No end event exists, but the elapsed-so-far is knowable
                    # (start to now), and is the main thing worth reading
                    # while the run is live.
                    w["outcome"] = "in_flight"
                    w["end_ts"] = None
                    w["elapsed_s"] = (
                        (datetime.now(timezone.utc) - w["start_ts"]).total_seconds()
                        if w["start_ts"] else None
                    )
            elif w["outcome"].startswith("queued_not_reached"):
                # Never launched, so it has no run of its own, but it was
                # queued for a span: from its [START] line to either the
                # next attempt's T0 (the dispatcher moved on without ever
                # reaching it) or now (this is still the live attempt).
                # queue_wait_s is left alone -- it never received a request,
                # so how long it would have waited for one is genuinely
                # unknown, not merely unrecorded.
                if w["start_ts"]:
                    end = next_t0 if next_t0 is not None else datetime.now(timezone.utc)
                    w["end_ts"] = next_t0
                    w["elapsed_s"] = (end - w["start_ts"]).total_seconds()
    return attempts


# ---------------------------------------------------------------------------
# /var/local/log/spar attempt directories (used only to sanity-check the
# dispatcher-vs-journal timestamp match; not otherwise re-parsed here)
# ---------------------------------------------------------------------------

def confirm_spar_log_dirs(spar_log_dir, segment, attempts):
    hits = []
    for attempt in attempts:
        if not attempt["t0_ts"]:
            continue
        stamp = attempt["t0_ts"].astimezone(AEST).strftime("%Y%m%d-%H%M%S")
        pattern = os.path.join(spar_log_dir, f"*segments-{segment}-s-{stamp}")
        matches = glob.glob(pattern)
        hits.append((attempt["file"], stamp, matches))
    return hits


# ---------------------------------------------------------------------------
# Correlate journal requests with dispatcher attempts (best-effort: a
# time-window match rather than an identity join -- there is no request id
# shared between the dispatcher and ollama to join on exactly).
# ---------------------------------------------------------------------------

def attach_requests_to_attempts(attempts, requests):
    for attempt in attempts:
        for w in attempt["workers"]:
            if not w["start_ts"] or not w.get("reached", True):
                w["requests"] = []
                w["queue_wait_s"] = None
                continue
            window_end = w["end_ts"] or datetime.now(timezone.utc)
            w["requests"] = [
                r for r in requests
                if w["start_ts"] <= r["start_ts_utc"] <= window_end
            ]
            if w["requests"]:
                first_req_ts = min(r["start_ts_utc"] for r in w["requests"])
                w["queue_wait_s"] = max((first_req_ts - w["start_ts"]).total_seconds(), 0.0)
            else:
                w["queue_wait_s"] = None
    return attempts


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def fmt_ts(ts):
    if ts is None:
        return ""
    return ts.astimezone(AEST).strftime("%Y-%m-%d %H:%M:%S")


def fmt_num(x, nd=1):
    if x is None:
        return ""
    return f"{x:.{nd}f}"


def fmt_duration(x, nd=0, unit="s"):
    """Render a duration (elapsed, queue wait, ...), or an explicit
    unavailable marker when the value could not be determined. Never
    prints a bare unit with no number, and never stands in zero or blank
    for "we don't know"."""
    if x is None:
        return "n/a"
    return f"{x:.{nd}f}{unit}"


def write_requests_csv(path, rows):
    import csv
    cols = [
        "pid", "task", "start_ts_aest", "status",
        "prompt_tokens", "prefill_tokens_processed", "prefill_duration_s", "prefill_rate_tps",
        "gen_tokens", "gen_duration_s", "gen_rate_tps", "total_duration_s", "end_ts_aest",
    ]
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for r in rows:
            w.writerow([
                r["pid"], r["task"], fmt_ts(r["start_ts_utc"]), r["status"],
                r["prompt_tokens"], r["prefill_tokens_processed"],
                fmt_num(r["prefill_duration_s"]), fmt_num(r["prefill_rate_tps"], 2),
                r["gen_tokens"], fmt_num(r["gen_duration_s"]), fmt_num(r["gen_rate_tps"], 3),
                fmt_duration(r["total_duration_s"], 1, unit=""), fmt_ts(r["end_ts_utc"]),
            ])


def write_workers_csv(path, attempts):
    import csv
    cols = [
        "attempt_file", "segment", "t0_aest", "source", "worker_start_aest", "worker_end_aest",
        "elapsed_s", "outcome", "n_requests_in_window", "queue_wait_s",
        "compute_s_in_window", "prompt_tokens_max_in_window",
    ]
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for attempt in attempts:
            for wk in attempt["workers"]:
                reqs = wk.get("requests", [])
                compute_s = sum(
                    (r["prefill_duration_s"] or 0) + (r["gen_duration_s"] or 0) for r in reqs
                )
                max_prompt = max((r["prompt_tokens"] for r in reqs), default=None)
                w.writerow([
                    attempt["file"], attempt["segment"], fmt_ts(attempt["t0_ts"]),
                    wk["source"], fmt_ts(wk["start_ts"]), fmt_ts(wk["end_ts"]),
                    fmt_duration(wk["elapsed_s"], 0, unit=""), wk["outcome"], len(reqs),
                    fmt_duration(wk.get("queue_wait_s"), 1, unit=""), fmt_num(compute_s), max_prompt,
                ])


def build_summary(rows, gin_events, model_loads, attempts, args):
    lines = []
    lines.append(f"# Timing harvest -- {datetime.now(AEST).strftime('%Y-%m-%d %H:%M:%S AEST')}")
    lines.append("")
    lines.append(f"Segment filter: {args.segment}")
    lines.append(f"Journal window requested: --since '{args.since}' from {args.host}")
    lines.append(REMOTE_TZ_NOTE)
    lines.append("")

    run_start_ts = attempts[0]["t0_ts"] if attempts and attempts[0]["t0_ts"] else None
    if run_start_ts is not None:
        excluded = [r for r in rows if r["start_ts_utc"] < run_start_ts]
        rows = [r for r in rows if r["start_ts_utc"] >= run_start_ts]
        if excluded:
            lines.append(
                f"Note: {len(excluded)} request(s) in the fetched journal window predate this "
                f"run's first dispatcher attempt ({fmt_ts(run_start_ts)} AEST) and are excluded "
                f"from every count and sum below (they are traffic from something earlier, not "
                f"this segment's run); they remain in the per-request CSV for the record."
            )
            lines.append("")

    lines.append("## Requests observed on the ollama journal (this run's window)")
    lines.append(f"Total requests (new-prompt events): {len(rows)}")
    by_status = {}
    for r in rows:
        by_status[r["status"]] = by_status.get(r["status"], 0) + 1
    for status, n in sorted(by_status.items()):
        lines.append(f"  - {status}: {n}")

    completed = [r for r in rows if r["status"].startswith("success")]
    in_flight = [r for r in rows if r["status"] == "in_flight"]
    aborted = [r for r in rows if r["status"] == "aborted_or_superseded"]

    total_prefill_s = sum(r["prefill_duration_s"] or 0 for r in rows)
    total_gen_s = sum(r["gen_duration_s"] or 0 for r in rows if r["status"] != "in_flight" or r["gen_duration_s"])
    lines.append("")
    lines.append(f"Sum of prefill time across all requests (incl. in-flight/aborted, as observed so far): "
                 f"{total_prefill_s:,.0f}s ({total_prefill_s/60:,.1f} min)")
    lines.append(f"Sum of generation time across all requests (as observed so far): "
                 f"{total_gen_s:,.0f}s ({total_gen_s/60:,.1f} min)")

    if completed:
        avg_prefill_rate = sum(r["prefill_rate_tps"] or 0 for r in completed) / len(completed)
        avg_gen_rate = sum(r["gen_rate_tps"] or 0 for r in completed if r["gen_rate_tps"]) / max(
            1, len([r for r in completed if r["gen_rate_tps"]])
        )
        lines.append(f"Average prefill rate over completed requests: {avg_prefill_rate:.2f} tok/s")
        lines.append(f"Average generation rate over completed requests: {avg_gen_rate:.3f} tok/s")

    if in_flight:
        lines.append("")
        lines.append("In-flight requests (NOT zero-duration -- still running as of this harvest):")
        for r in in_flight:
            now = datetime.now(timezone.utc)
            elapsed = (now - r["start_ts_utc"]).total_seconds()
            lines.append(
                f"  - pid {r['pid']} task {r['task']}: started {fmt_ts(r['start_ts_utc'])} AEST, "
                f"prompt {r['prompt_tokens']} tok, {elapsed:,.0f}s elapsed so far "
                f"({elapsed/60:,.1f} min), generated {r['gen_tokens']} tok so far"
            )

    if run_start_ts is not None:
        gin_events = [g for g in gin_events if g["ts"] >= run_start_ts]
        model_loads = [(ts, pid) for (ts, pid) in model_loads if ts >= run_start_ts]

    lines.append("")
    lines.append("## Server-side HTTP churn (all POST /v1/chat/completions|/api/generate closures, this run's window)")
    lines.append(f"Total closures logged: {len(gin_events)}")
    n_200 = sum(1 for g in gin_events if g["status"] == 200)
    n_500 = sum(1 for g in gin_events if g["status"] != 200)
    sum_500_s = sum(g["duration_s"] for g in gin_events if g["status"] != 200)
    sum_200_s = sum(g["duration_s"] for g in gin_events if g["status"] == 200)
    lines.append(f"  200 OK: {n_200}, total server time {sum_200_s:,.0f}s ({sum_200_s/60:,.1f} min)")
    lines.append(f"  non-200 (client gave up before the server replied): {n_500}, summed client-side "
                 f"dead time (arrival to abandonment) {sum_500_s:,.0f}s ({sum_500_s/60:,.1f} min)")
    lines.append("Note: this sum is client-side elapsed time, not GPU-busy time -- with a single slot,")
    lines.append("ollama can only actively compute on one request at a time (bounded by the run's own")
    lines.append("wall-clock), so a sum this far above the wall-clock total means many callers were")
    lines.append("queued at once, each accumulating wait in parallel clock time. It is the clearest")
    lines.append("evidence of queue contention in this log, but it cannot be split into \"queued\" versus")
    lines.append("\"being computed\" per abandoned request, and none of it can be attributed to a specific")
    lines.append("worker, because ollama logs no request id linking a GIN closure back to a caller.")

    if model_loads:
        lines.append("")
        lines.append(f"## Model (re)loads observed: {len(model_loads)}")
        for ts, pid in model_loads:
            lines.append(f"  - {fmt_ts(ts)} AEST, pid {pid}")

    lines.append("")
    lines.append("## Dispatcher attempts (pilot*.out) and worker-level view")
    for attempt in attempts:
        lines.append(f"### {attempt['file']}  (segment={attempt['segment']}, T0={fmt_ts(attempt['t0_ts'])} AEST, "
                     f"{attempt['n_sources']} source(s))")
        for w in attempt["workers"]:
            qw = w.get("queue_wait_s")
            reqs = w.get("requests", [])
            compute_s = sum((r["prefill_duration_s"] or 0) + (r["gen_duration_s"] or 0) for r in reqs)
            lines.append(
                f"  - {w['source']}: start {fmt_ts(w['start_ts'])} AEST, outcome={w['outcome']}, "
                f"elapsed={fmt_duration(w['elapsed_s'], 0)}, requests_in_window={len(reqs)}, "
                f"queue_wait={fmt_duration(qw, 0)}, compute_in_window={compute_s:,.0f}s"
            )

    total_wall_s = None
    if attempts and attempts[0]["t0_ts"]:
        first_t0 = attempts[0]["t0_ts"]
        last_end = max(
            (w["end_ts"] or datetime.now(timezone.utc))
            for a in attempts for w in a["workers"] if w["start_ts"]
        )
        total_wall_s = (last_end - first_t0).total_seconds()

    lines.append("")
    lines.append("## Segment / run summary -- tonight's attempts for this segment")
    if total_wall_s is not None:
        lines.append(f"Total wall-clock across all attempts (T0 of first attempt to end/now of last): "
                     f"{total_wall_s:,.0f}s ({total_wall_s/3600:,.2f} h)")
    total_compute_s = sum(
        (r["prefill_duration_s"] or 0) + (r["gen_duration_s"] or 0) for r in rows
    )
    if total_wall_s:
        waiting_s = max(total_wall_s - total_compute_s, 0.0)
        lines.append(f"Time the model was computing (prefill+generation, all requests observed): "
                     f"{total_compute_s:,.0f}s ({total_compute_s/3600:,.2f} h)")
        lines.append(f"Time that was something-else-waiting (wall-clock minus computing): "
                     f"{waiting_s:,.0f}s ({waiting_s/3600:,.2f} h)")
    lines.append("")
    lines.append("## Largest consumers of time (ranked)")
    lines.append("The first two rows are actual compute, bounded by wall-clock. The third is")
    lines.append("client-side dead time summed across every competing, eventually-abandoned caller")
    lines.append("(see the churn note above) -- it is not additional compute, it is the queueing cost")
    lines.append("the single slot imposed on everyone contending for it, and it is reported separately")
    lines.append("because it cannot be added to the first two without double-counting wall-clock.")
    buckets = {
        "prefill (sum across requests, actual compute)": sum(r["prefill_duration_s"] or 0 for r in rows),
        "generation (sum across requests, actual compute)": sum(r["gen_duration_s"] or 0 for r in rows),
    }
    for name, secs in sorted(buckets.items(), key=lambda kv: -kv[1]):
        lines.append(f"  - {name}: {secs:,.0f}s ({secs/60:,.1f} min)")
    lines.append(f"  - queueing cost: summed client-side dead time across abandoned callers "
                 f"(not compute, see above): {sum_500_s:,.0f}s ({sum_500_s/60:,.1f} min)")

    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--since", default="6 hours ago",
                    help="journalctl --since value, evaluated on the remote host's own clock")
    ap.add_argument("--host", default=DEFAULT_HOST)
    ap.add_argument("--scratchpad", default=DEFAULT_SCRATCHPAD, required=DEFAULT_SCRATCHPAD is None,
                    help="directory holding pilot*.out dispatcher logs")
    ap.add_argument("--spar-log-dir", default=DEFAULT_SPAR_LOG_DIR)
    ap.add_argument("--segment", default=DEFAULT_SEGMENT)
    ap.add_argument("--out-dir", default=HERE)
    ap.add_argument("--ssh-timeout", type=int, default=45)
    args = ap.parse_args()

    print(f"Fetching ollama journal from {args.host} (since='{args.since}', timeout={args.ssh_timeout}s)...",
          file=sys.stderr)
    journal_text = fetch_journal(args.host, args.since, args.ssh_timeout)
    rows, gin_events, model_loads = parse_journal(journal_text)
    print(f"Parsed {len(rows)} request(s), {len(gin_events)} HTTP closure(s), "
          f"{len(model_loads)} model load(s)", file=sys.stderr)

    attempts = parse_pilot_logs(args.scratchpad, segment_filter=args.segment)
    print(f"Parsed {len(attempts)} dispatcher attempt(s) for segment '{args.segment}'", file=sys.stderr)

    dir_hits = confirm_spar_log_dirs(args.spar_log_dir, args.segment, attempts)
    for fname, stamp, matches in dir_hits:
        tag = "OK" if matches else "NO MATCH"
        print(f"  {fname}: attempt stamp {stamp} -> {tag} ({matches})", file=sys.stderr)

    attach_requests_to_attempts(attempts, rows)

    date_tag = datetime.now(AEST).strftime("%Y-%m-%d")
    requests_csv = os.path.join(args.out_dir, f"{date_tag}-ollama-requests.csv")
    workers_csv = os.path.join(args.out_dir, f"{date_tag}-worker-attempts.csv")
    summary_path = os.path.join(args.out_dir, f"{date_tag}-timing-summary.md")

    write_requests_csv(requests_csv, rows)
    write_workers_csv(workers_csv, attempts)
    summary = build_summary(rows, gin_events, model_loads, attempts, args)
    with open(summary_path, "w") as f:
        f.write(summary + "\n")

    print(f"\nWrote:\n  {requests_csv}\n  {workers_csv}\n  {summary_path}\n", file=sys.stderr)
    print(summary)


if __name__ == "__main__":
    main()

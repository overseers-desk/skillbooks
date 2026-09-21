#!/usr/bin/env python3
"""Harvest timing records for the ollama/qwen3-30b-a3b SPAR run.

Pulls from three places, all read-only, and writes one dated CSV of
per-request rows plus a summary text file next to this script:

  1. The remote ollama journal (`journalctl -u ollama`), read over SSH.
     Gives per-request prefill (prompt processing) and generation
     (token-by-token print_timing) traces, keyed by (pid, task).
  2. The dispatcher's own console logs: every pilot*.out under whatever
     scratchpad directory --scratchpad points at, plus the stdout file of
     any dispatcher currently running (found via /proc, not by matching
     a command line), so a live run's log is seen even before it has a
     pilot*.out name. These carry local-time [START] lines per worker and
     any FAIL lines with the worker's own elapsed seconds.
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
from statistics import median

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
INIT_SAMPLER_RE = re.compile(r"task (\d+) \| init sampler, took")
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
# Request lifecycle, paired by log order rather than by task id. The id
# restarts at zero on every model reload, so the same id can name two
# different requests within one fetched window; keying a dict by id alone
# (as parse_journal above does, for its own separate purposes) would merge
# them and produce figures that look precise and are wrong. The server runs
# a single slot, so requests are strictly sequential -- a request is closed
# by the matching init-sampler/stop-processing carrying its own id, or by
# the next new-prompt if neither has appeared yet.
# ---------------------------------------------------------------------------

def parse_lifecycle(text):
    """Return one dict per request, in the order requests started."""
    reqs = []
    current = None
    for raw_line in text.splitlines():
        m = LINE_TS_RE.match(raw_line)
        if not m:
            continue
        ts_str, _pid, rest = m.groups()
        try:
            ts = datetime.fromisoformat(ts_str).astimezone(timezone.utc)
        except ValueError:
            continue

        mm = NEW_PROMPT_RE.search(rest)
        if mm:
            if current is not None:
                current["next_start_ts"] = ts
                reqs.append(current)
            current = {
                "task": int(mm.group(1)),
                "prompt_tokens": int(mm.group(4)),
                "start_ts": ts,
                "init_sampler_ts": None,
                "release_ts": None,
                "last_tg": None,
                "last_tg_ts": None,
                "next_start_ts": None,
            }
            continue

        if current is None:
            continue

        mm = INIT_SAMPLER_RE.search(rest)
        if mm and int(mm.group(1)) == current["task"] and current["init_sampler_ts"] is None:
            current["init_sampler_ts"] = ts
            continue

        mm = GEN_RE.search(rest)
        if mm and int(mm.group(1)) == current["task"]:
            current["last_tg"] = float(mm.group(3))
            current["last_tg_ts"] = ts
            continue

        mm = RELEASE_RE.search(rest)
        if mm and int(mm.group(1)) == current["task"] and current["release_ts"] is None:
            current["release_ts"] = ts
            continue

    if current is not None:
        reqs.append(current)
    return reqs


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


def find_running_dispatcher_stdout_paths(scratchpad_dir):
    """Find the scratchpad log file(s) any currently-running dispatcher is
    writing to.

    A dispatcher is identified by 'spar-transition' appearing in its
    /proc/<pid>/cmdline -- never by matching against a full command line
    with something like pgrep -f, which also matches whatever process is
    doing the searching. For each match, fd 1 is resolved with
    os.readlink to find the file the process is writing to; only a
    regular file inside scratchpad_dir is kept. A pid that cannot be
    read (permission, or the process exiting mid-scan) is skipped rather
    than failing the harvest.
    """
    scratchpad_dir = os.path.realpath(scratchpad_dir)
    live_paths = set()
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            with open(f"/proc/{entry}/cmdline", "rb") as f:
                cmdline = f.read()
        except OSError:
            continue
        if b"spar-transition" not in cmdline:
            continue
        try:
            target = os.readlink(f"/proc/{entry}/fd/1")
        except OSError:
            continue
        target = os.path.realpath(target)
        if not os.path.isfile(target):
            continue
        if target == scratchpad_dir or target.startswith(scratchpad_dir + os.sep):
            live_paths.add(target)
    return live_paths


def parse_pilot_logs(scratchpad_dir, segment_filter=None, live_stdout_paths=None):
    """Parse pilot*.out files, plus any running dispatcher's live stdout
    file, into a list of attempts, each with its workers."""
    if live_stdout_paths is None:
        live_stdout_paths = find_running_dispatcher_stdout_paths(scratchpad_dir)
    attempts = []
    glob_paths = {os.path.realpath(p) for p in glob.glob(os.path.join(scratchpad_dir, "pilot*.out"))}
    paths = sorted(glob_paths | live_stdout_paths)
    for path in paths:
        name = os.path.basename(path)
        try:
            with open(path, "r", errors="replace") as f:
                lines = f.readlines()
        except OSError as e:
            print(f"WARNING: could not read {path}: {e}", file=sys.stderr)
            continue

        attempt = {
            "file": name, "path": path, "t0_ts": None, "segment": None,
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

    # Fill in end_ts for workers with no FAIL line. Whether the run is
    # over is a property of the process, not of the log text or of
    # whether a later attempt happens to exist: a log is only genuinely
    # still being written if some running dispatcher has it open as its
    # own fd 1 right now. A dead log's true end is its own last write
    # (mtime), which is always at least as tight a bound as guessing from
    # a subsequent attempt's T0 -- the gap between a dispatcher dying and
    # an operator noticing and restarting is not this worker's runtime.
    for i, attempt in enumerate(attempts):
        next_t0 = attempts[i + 1]["t0_ts"] if i + 1 < len(attempts) else None
        is_live_log = attempt["path"] in live_stdout_paths
        for w in attempt["workers"]:
            if w["outcome"] == "unresolved_in_this_log":
                if is_live_log:
                    # No end event exists, but the elapsed-so-far is knowable
                    # (start to now), and is the main thing worth reading
                    # while the run is live.
                    w["outcome"] = "in_flight"
                    w["end_ts"] = None
                    w["elapsed_s"] = (
                        (datetime.now(timezone.utc) - w["start_ts"]).total_seconds()
                        if w["start_ts"] else None
                    )
                else:
                    # The dispatcher that was writing this log has since
                    # exited, so nothing is still running: the last moment
                    # it could conceivably have been alive is the last time
                    # the log file itself was written to.
                    try:
                        end = datetime.fromtimestamp(os.path.getmtime(attempt["path"]), tz=timezone.utc)
                    except OSError:
                        end = next_t0
                    w["outcome"] = ("ended_without_end_line (dispatcher exited; "
                                     "elapsed is a lower bound, measured to "
                                     "last log write)")
                    w["end_ts"] = end
                    w["elapsed_s"] = (
                        (end - w["start_ts"]).total_seconds()
                        if end and w["start_ts"] else None
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


def build_lifecycle_section(lifecycle_reqs):
    """Counts and timings from the id-safe pairing in parse_lifecycle,
    over the whole fetched journal window (not restricted to this run's
    dispatcher attempts, since abandonment on the server side is a fact
    about the server, not about who was asking)."""
    lines = ["", "## Request lifecycle and the cost of abandonment"]
    started = len(lifecycle_reqs)
    reached = [r for r in lifecycle_reqs if r["init_sampler_ts"] is not None]
    abandoned = [r for r in lifecycle_reqs if r["init_sampler_ts"] is None]
    lines.append(f"Requests started (new-prompt events): {started}")
    lines.append(f"Reached generation: {len(reached)}")
    lines.append(f"Abandoned during prefill: {len(abandoned)}")

    # Both sums run over the same population. A request that reached
    # generation but has no end yet, the one in flight when the window
    # closed, has a prefill that is known and a generation that is not,
    # so counting its prefill alone would understate generation's share
    # against a denominator it had contributed to.
    ended = [r for r in reached if (r["release_ts"] or r["last_tg_ts"]) is not None]
    in_flight = len(reached) - len(ended)
    prefill_total_s = sum((r["init_sampler_ts"] - r["start_ts"]).total_seconds() for r in ended)
    gen_total_s = sum(
        ((r["release_ts"] or r["last_tg_ts"]) - r["init_sampler_ts"]).total_seconds()
        for r in ended
    )
    lines.append(
        f"Prefill actually performed, summed over the {len(ended)} request(s) that reached "
        f"generation and finished: {prefill_total_s / 60:,.1f} min (a fully cached prompt "
        f"correctly shows zero here -- this is prefill done, not prompt tokens presented)"
    )
    lines.append(f"Generation, summed over the same requests: {gen_total_s / 60:,.1f} min")
    if in_flight:
        lines.append(
            f"Excluded from both sums: {in_flight} request(s) still generating when the window "
            f"closed, whose prefill is known and whose generation is not"
        )
    denom = prefill_total_s + gen_total_s
    if denom:
        lines.append(f"Generation share of prefill+generation time: {gen_total_s / denom * 100:,.0f}%")

    if abandoned:
        # An abandoned request is always followed by another, since the
        # server runs one slot -- but what the successor does with it
        # splits into two events a combined total hides. Same prompt size
        # means the successor resubmitted the identical work and it
        # succeeded on the now-warm cache: the clock is lost, nothing
        # else is. A different prompt size means the work itself was
        # dropped, not just delayed. The median is reported per group
        # because it is what identifies the limit doing the cutting; the
        # combined median buries it between two different distributions.
        recovered, lost, undetermined = [], [], []
        for i, r in enumerate(lifecycle_reqs):
            if r["init_sampler_ts"] is not None:
                continue
            successor = lifecycle_reqs[i + 1] if i + 1 < len(lifecycle_reqs) else None
            if successor is None:
                undetermined.append(r)
            elif successor["prompt_tokens"] == r["prompt_tokens"]:
                recovered.append(r)
            else:
                lost.append(r)

        def _report(label, group):
            holds_s = [(r["next_start_ts"] - r["start_ts"]).total_seconds() for r in group]
            starts = [r["start_ts"] for r in group]
            lines.append(
                f"{label}: {len(group)} events, {sum(holds_s) / 60:,.1f} min held, "
                f"first {fmt_ts(min(starts))} AEST, last {fmt_ts(max(starts))} AEST, "
                f"median hold {median(holds_s):,.0f}s"
            )

        if recovered:
            _report("Recovered (successor resubmitted the same prompt, cache warm)", recovered)
        if lost:
            _report("Lost (successor's prompt size differed, work not resubmitted)", lost)
        lines.append(
            "A recovered cut costs time without losing work; a lost cut costs both."
        )
        if undetermined:
            r = undetermined[0]
            lines.append(
                f"Undetermined: {len(undetermined)} (window ended before a successor "
                f"appeared for the abandonment at {fmt_ts(r['start_ts'])} AEST, so it "
                f"cannot be placed in either group)"
            )
    return lines


def build_decode_rate_section(lifecycle_reqs):
    """Seconds-per-token as a linear function of prompt size, fitted by
    ordinary least squares in closed form (three sums) so no dependency
    beyond the standard library is needed for a two-variable fit."""
    lines = ["", "## Decode rate against context length"]
    points = [
        (r["prompt_tokens"], 1.0 / r["last_tg"])
        for r in lifecycle_reqs
        if r["init_sampler_ts"] is not None and r["last_tg"]
    ]
    n = len(points)
    if n < 2:
        lines.append(f"Too few requests with a progress line ({n}) to fit a line.")
        return lines

    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    xbar = sum(xs) / n
    ybar = sum(ys) / n
    sxx = sum((x - xbar) ** 2 for x in xs)
    sxy = sum((x - xbar) * (y - ybar) for x, y in points)
    syy = sum((y - ybar) ** 2 for y in ys)
    slope = sxy / sxx if sxx else 0.0
    intercept = ybar - slope * xbar
    r2 = (sxy ** 2) / (sxx * syy) if sxx and syy else 0.0
    xmin, xmax = min(xs), max(xs)

    lines.append(f"Points: {n}; observed prompt size {xmin:,}-{xmax:,} tokens; fit holds over that range")
    lines.append(
        f"Fit: seconds/token = {intercept:.6f} + {slope * 1e6:,.1f} us/token of context x prompt_tokens "
        f"(R-squared = {r2:.2f})"
    )
    lines.append(
        "The intercept is slightly negative, which is a straight line's artifact over a bounded "
        "interval rather than a claim about short prompts; the table below is not extrapolated "
        "below the observed minimum."
    )
    lines.append("Cost of generating 1,000 tokens, at context sizes spanning the observed range:")
    # Below the crossing point the line predicts a negative duration, which is the
    # negative intercept showing through rather than a result. Those rows are dropped:
    # a printed figure gets quoted, and a quoted negative time discredits the table
    # that carries it.
    skipped = []
    for frac in (0.0, 0.25, 0.5, 0.75, 1.0):
        ctx = round(xmin + frac * (xmax - xmin))
        cost_s_per_tok = intercept + slope * ctx
        if cost_s_per_tok <= 0:
            skipped.append(ctx)
            continue
        lines.append(f"  - {ctx:,} tokens of context: {cost_s_per_tok * 1000:,.1f}s")
    if skipped:
        lines.append(
            "Dropped from the table, the fit predicting a negative duration there: "
            + ", ".join(f"{c:,}" for c in skipped)
            + " tokens of context. Short prompts sit above the line, not on it: the shortest "
            "prompt observed in this window ran far faster than the fit extended down to it "
            "would say."
        )
    return lines


def build_summary(rows, gin_events, model_loads, attempts, args, lifecycle_reqs):
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

    lines.extend(build_lifecycle_section(lifecycle_reqs))
    lines.extend(build_decode_rate_section(lifecycle_reqs))

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
    lifecycle_reqs = parse_lifecycle(journal_text)
    print(f"Parsed {len(rows)} request(s), {len(gin_events)} HTTP closure(s), "
          f"{len(model_loads)} model load(s)", file=sys.stderr)

    live_stdout_paths = find_running_dispatcher_stdout_paths(args.scratchpad)
    attempts = parse_pilot_logs(args.scratchpad, segment_filter=args.segment,
                                 live_stdout_paths=live_stdout_paths)
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
    summary = build_summary(rows, gin_events, model_loads, attempts, args, lifecycle_reqs)
    with open(summary_path, "w") as f:
        f.write(summary + "\n")

    print(f"\nWrote:\n  {requests_csv}\n  {workers_csv}\n  {summary_path}\n", file=sys.stderr)
    print(summary)


if __name__ == "__main__":
    main()

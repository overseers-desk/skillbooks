#!/usr/bin/env python3
"""Re-fetch all v2-tier2 and v2-tier3 URLs from search-log.tsv into the
html-archive, then parse them with parse-linkedin-search.py and emit one
consolidated TSV to stdout.

Idempotent: skips URLs whose archive file already exists for today.
"""
import os
import re
import subprocess
import sys
import time
from pathlib import Path

CAMPAIGN = Path(__file__).resolve().parent
ARCHIVE = CAMPAIGN / "html-archive" / time.strftime("%Y-%m-%d")
LOG = CAMPAIGN / "logs" / f"refetch-tier23-{time.strftime('%Y%m%d-%H%M%S')}.log"
ARCHIVE.mkdir(parents=True, exist_ok=True)
LOG.parent.mkdir(parents=True, exist_ok=True)

FETCH_CMD_BASE = [
    "flock", "/tmp/chromium.lock", "timeout", "30", "chromium",
    "--headless=new", "--dump-dom",
    "--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
    f"--user-data-dir={os.path.expanduser('~/snap/chromium/common/chromium')}",
    "--window-size=3840,2160",
]


def log(msg: str) -> None:
    with open(LOG, "a") as fh:
        fh.write(f"{time.strftime('%H:%M:%S')}  {msg}\n")
    print(msg, flush=True)


def load_urls() -> list[tuple[str, str]]:
    """Return [(slug, url), ...] for every v2-tier[23] row in search-log."""
    out = []
    with open(CAMPAIGN / "search-log.tsv") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4:
                continue
            slug, url = parts[2], parts[3]
            if re.match(r"v2-tier[23]", slug):
                out.append((slug, url))
    return out


def already_archived(slug: str) -> Path | None:
    for f in ARCHIVE.glob(f"{slug}-*.html"):
        if f.stat().st_size > 50_000:  # non-truncated
            return f
    return None


def fetch(slug: str, url: str) -> Path | None:
    existing = already_archived(slug)
    if existing:
        log(f"  cached {slug} -> {existing.name}")
        return existing
    out = ARCHIVE / f"{slug}-{time.strftime('%H%M%S')}.html"
    t0 = time.time()
    with open(out, "wb") as fh:
        subprocess.run(FETCH_CMD_BASE + [url], stdout=fh, stderr=subprocess.DEVNULL)
    sz = out.stat().st_size
    dt = time.time() - t0
    log(f"  fetch {slug} -> {out.name} ({sz} bytes, {dt:.1f}s)")
    if sz < 50_000:
        log(f"  WARN truncated fetch for {slug} ({sz} bytes)")
    return out


def main():
    urls = load_urls()
    log(f"Starting refetch of {len(urls)} v2-tier[23] URLs")
    archived: list[Path] = []
    t_start = time.time()
    for i, (slug, url) in enumerate(urls, 1):
        path = fetch(slug, url)
        if path:
            archived.append(path)
        if i % 10 == 0:
            elapsed = time.time() - t_start
            rate = i / elapsed if elapsed else 0
            eta = (len(urls) - i) / rate if rate else 0
            log(f"[{i}/{len(urls)}] elapsed {elapsed:.0f}s rate {rate:.2f}/s eta {eta:.0f}s")
        time.sleep(1.5)  # polite pacing between fetches
    log(f"Fetch complete: {len(archived)} files in archive")

    log("Parsing archive with parse-linkedin-search.py ...")
    parser = CAMPAIGN / "parse-linkedin-search.py"
    result = subprocess.run(
        ["python3", str(parser)] + [str(p) for p in archived],
        capture_output=True, text=True,
    )
    tsv_path = CAMPAIGN / "logs" / f"refetch-tier23-{time.strftime('%Y%m%d-%H%M%S')}.tsv"
    tsv_path.write_text(result.stdout)
    rows = result.stdout.count("\n") - 1  # minus header
    log(f"Parse complete: {rows} rows -> {tsv_path.name}")
    # Dedup by stem
    seen = set()
    uniq_lines = []
    for i, line in enumerate(result.stdout.splitlines()):
        if i == 0:
            uniq_lines.append(line)
            continue
        stem = line.split("\t", 1)[0]
        if stem in seen:
            continue
        seen.add(stem)
        uniq_lines.append(line)
    uniq_path = CAMPAIGN / "logs" / f"refetch-tier23-{time.strftime('%Y%m%d-%H%M%S')}-dedup.tsv"
    uniq_path.write_text("\n".join(uniq_lines) + "\n")
    log(f"Dedup: {len(uniq_lines)-1} unique stems -> {uniq_path.name}")
    print(f"\nFINAL: {uniq_path}")


if __name__ == "__main__":
    main()

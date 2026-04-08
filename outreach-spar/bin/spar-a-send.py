#!/usr/bin/env python3
# Part of the SPAR outreach methodology. See ../../README.md before using.
# spar-a-send.py — Send approved SPAR-A final-round emails via AWS SES CLI
#
# Usage:
#   python3 spar-a-send.py <campaign.yaml> [--segments seg1,seg2,...] [--dry-run] [-y]
#
# Reads the campaign YAML, walks approach files for the given segments, finds
# final-round email messages where actioned_date is null, and sends them via
# `aws ses send-email`.  After a successful send, stamps actioned_date in the
# approach file.
#
# The sender is BCC'd on every email so a copy appears in the sender's inbox
# (SES does not populate a Sent folder).
#
# Flags:
#   --segments seg1,seg2   Comma-separated segments to process (default: all in campaign)
#   --dry-run              Print what would be sent; do not send or modify files
#   -y                     Send without confirmation prompt
#
# Skips:
#   - Non-email channels (linkedin, phone)
#   - Messages where actioned_date is already set
#   - Approach files with no final round
#
# Requires: pyyaml, ruamel.yaml, aws CLI (configured with credentials)

import argparse
import json
import subprocess
import sys
import time
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml not found: pip install pyyaml")

try:
    from ruamel.yaml import YAML as RuamelYAML
except ImportError:
    sys.exit("ruamel.yaml not found: pip install ruamel.yaml")


def load_yaml(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def _is_null(val) -> bool:
    return val is None or str(val).strip() in ("~", "None", "null", "")


def find_unsent_emails(approach_data: dict) -> list[dict]:
    """Return unsent email messages from the final round."""
    result = []
    for r in approach_data.get("rounds", []):
        if r.get("type") != "final":
            continue
        for msg in r.get("messages", []):
            if msg.get("channel") != "email":
                continue
            if _is_null(msg.get("actioned_date")):
                result.append(msg)
    return result


def stamp_actioned_date(approach_path: Path, today: str) -> bool:
    """Round-trip parse the YAML, stamp actioned_date on unsent email messages, write back."""
    ryaml = RuamelYAML()
    ryaml.preserve_quotes = True
    with approach_path.open(encoding="utf-8") as f:
        data = ryaml.load(f)

    changed = False
    for r in (data or {}).get("rounds", []):
        if r.get("type") != "final":
            continue
        for msg in r.get("messages", []):
            if msg.get("channel") != "email":
                continue
            if _is_null(msg.get("actioned_date")):
                msg["actioned_date"] = today
                changed = True

    if changed:
        with approach_path.open("w", encoding="utf-8") as f:
            ryaml.dump(data, f)
    return changed


def send_ses(region: str, from_addr: str, to_addr: str, bcc_addr: str,
             subject: str, body: str) -> str:
    """Call `aws ses send-email`. Returns message ID."""
    destination = {"ToAddresses": [to_addr]}
    if bcc_addr:
        destination["BccAddresses"] = [bcc_addr]
    message = {
        "Subject": {"Data": subject, "Charset": "UTF-8"},
        "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
    }
    result = subprocess.run(
        [
            "aws", "ses", "send-email",
            "--region", region,
            "--from", from_addr,
            "--destination", json.dumps(destination),
            "--message", json.dumps(message),
        ],
        capture_output=True, text=True, timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"aws ses exited {result.returncode}")
    try:
        return json.loads(result.stdout).get("MessageId", "?")
    except (json.JSONDecodeError, AttributeError):
        return "?"


def main():
    parser = argparse.ArgumentParser(
        description="Send approved SPAR-A approach emails via AWS SES CLI",
    )
    parser.add_argument("campaign", help="Path to campaign YAML")
    parser.add_argument(
        "--segments",
        help="Comma-separated segments to process (default: all in campaign)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be sent; do not send or modify files",
    )
    parser.add_argument(
        "-y", dest="yes", action="store_true",
        help="Send without confirmation prompt",
    )
    args = parser.parse_args()

    campaign_path = Path(args.campaign).resolve()
    if not campaign_path.exists():
        sys.exit(f"Campaign file not found: {campaign_path}")

    campaign = load_yaml(campaign_path)
    base = campaign_path.parent

    sender_name = campaign["sender"].get("name", "")
    sender_email = campaign["sender"]["email"]
    from_addr = f"{sender_name} <{sender_email}>" if sender_name else sender_email
    bcc_addr = campaign["sender"].get("bcc", sender_email)
    ses_region = campaign.get("ses_region", "ap-southeast-2")

    all_segments = campaign.get("segments", [])
    if args.segments:
        requested = [s.strip() for s in args.segments.split(",")]
        unknown = [s for s in requested if s not in all_segments]
        if unknown:
            sys.exit(f"Segment(s) not in campaign YAML: {', '.join(unknown)}")
        segments = requested
    else:
        segments = all_segments

    # Collect pending sends
    pending: list[tuple[Path, dict, str]] = []
    seg_counts: dict[str, int] = {}
    for seg in segments:
        approach_dir = base / seg / "approach"
        if not approach_dir.is_dir():
            print(f"  [{seg}] no approach/ directory — skipping", file=sys.stderr)
            continue
        count = 0
        for yaml_file in sorted(approach_dir.glob("*.yaml")):
            data = load_yaml(yaml_file)
            if not isinstance(data, dict):
                continue
            for msg in find_unsent_emails(data):
                pending.append((yaml_file, msg, seg))
                count += 1
        seg_counts[seg] = count

    if not pending:
        print("Nothing to send.")
        return

    # Preview
    label = "DRY RUN — " if args.dry_run else ""
    print(f"{label}{len(pending)} email(s) pending\n")
    for seg in segments:
        if seg_counts.get(seg, 0) > 0:
            print(f"  {seg}: {seg_counts[seg]}")
    print()
    for path, msg, seg in pending:
        print(f"  [{seg}] {path.stem}")
        print(f"    To:      {msg.get('to', '?')}")
        print(f"    Subject: {msg.get('subject', '?')}")
    print()

    if args.dry_run:
        print("Dry run complete. Nothing sent.")
        return

    if not args.yes:
        try:
            ans = input(f"Send {len(pending)} email(s) from {sender_email}? [y/N] ").strip().lower()
        except EOFError:
            ans = ""
        if ans != "y":
            print("Aborted.")
            return

    today = date.today().isoformat()
    sent = 0
    failed = 0

    for approach_path, msg, seg in pending:
        to_addr = msg.get("to", "")
        subject = msg.get("subject", "")
        body = msg.get("body", "")
        if not to_addr or not subject or not body:
            print(f"  SKIP [{seg}] {approach_path.stem}: missing to/subject/body", file=sys.stderr)
            continue
        try:
            msg_id = send_ses(ses_region, from_addr, to_addr, bcc_addr, subject, body)
            stamp_actioned_date(approach_path, today)
            print(f"  SENT [{seg}] {approach_path.stem} → {to_addr} ({msg_id})")
            sent += 1
        except Exception as exc:
            print(f"  FAIL [{seg}] {approach_path.stem}: {exc}", file=sys.stderr)
            failed += 1
        time.sleep(0.1)

    print(f"\nDone. Sent: {sent}  Failed: {failed}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# Part of the SPAR outreach methodology. See ../../README.md before using.
# spar-a-send.py — Send approved SPAR-A final-round emails via AWS SES
#
# Usage:
#   python3 spar-a-send.py <campaign.yaml> [--segments seg1,seg2,...] [--dry-run] [-y]
#
# Reads the campaign YAML, walks approach files for the given segments, finds
# final-round email messages where actioned_date is null, and sends them via
# AWS SES.  After a successful send, stamps actioned_date in the approach file.
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
# Requires: pyyaml, ruamel.yaml, boto3

import argparse
import sys
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml not found: pip install pyyaml")

try:
    import boto3
except ImportError:
    sys.exit("boto3 not found: pip install boto3")

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


def send_ses(client, from_addr: str, to_addr: str, bcc_addr: str,
             subject: str, body: str) -> str:
    """Send via SES. Returns message ID."""
    dest: dict = {"ToAddresses": [to_addr]}
    if bcc_addr and bcc_addr != to_addr:
        dest["BccAddresses"] = [bcc_addr]
    resp = client.send_email(
        Source=from_addr,
        Destination=dest,
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
        },
    )
    return resp["MessageId"]


def main():
    parser = argparse.ArgumentParser(
        description="Send approved SPAR-A approach emails via AWS SES",
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
    bcc_addr = campaign["sender"].get("bcc", "")
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
    pending: list[tuple[Path, dict, str]] = []  # (approach_path, msg, segment)
    for seg in segments:
        approach_dir = base / seg / "approach"
        if not approach_dir.is_dir():
            print(f"  [{seg}] no approach/ directory — skipping", file=sys.stderr)
            continue
        for yaml_file in sorted(approach_dir.glob("*.yaml")):
            data = load_yaml(yaml_file)
            if not isinstance(data, dict):
                continue
            for msg in find_unsent_emails(data):
                pending.append((yaml_file, msg, seg))

    if not pending:
        print("Nothing to send.")
        return

    # Preview
    label = "DRY RUN — " if args.dry_run else ""
    print(f"{label}{len(pending)} email(s) pending\n")
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
    ses = boto3.client("ses", region_name=ses_region)
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
            msg_id = send_ses(ses, from_addr, to_addr, bcc_addr, subject, body)
            stamp_actioned_date(approach_path, today)
            print(f"  SENT [{seg}] {approach_path.stem} → {to_addr} ({msg_id})")
            sent += 1
        except Exception as exc:
            print(f"  FAIL [{seg}] {approach_path.stem}: {exc}", file=sys.stderr)
            failed += 1

    print(f"\nDone. Sent: {sent}  Failed: {failed}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()

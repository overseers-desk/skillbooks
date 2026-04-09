"""Integration tests for update-campaign.py --send mode."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest
import yaml

BIN = Path(__file__).resolve().parent.parent / "bin" / "update-campaign.py"


def run_campaign(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(BIN)] + args,
        capture_output=True, text=True, cwd=str(cwd), timeout=30,
    )


class TestSendDryRun:
    def test_dry_run_lists_pending(self, tmp_campaign):
        """--send --dry-run lists pending emails without sending."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--send", "--dry-run"],
            tmp_campaign,
        )
        assert r.returncode == 0
        assert "pending" in r.stdout.lower() or "nothing to send" in r.stdout.lower()
        assert "Dry run complete" in r.stdout or "Nothing to send" in r.stdout

    def test_dry_run_with_segments(self, tmp_campaign):
        """--send --dry-run --segments filters to named segments."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--send", "--dry-run",
             "--segments", "seg-alpha"],
            tmp_campaign,
        )
        assert r.returncode == 0

    def test_all_sent_nothing_to_send(self, tmp_campaign):
        """When all emails are already actioned, reports nothing to send."""
        # Modify all approach files to have actioned_date set
        for seg_name in ("seg-alpha", "seg-beta"):
            approach_dir = tmp_campaign / seg_name / "approach"
            for yf in approach_dir.glob("*.yaml"):
                data = yaml.safe_load(yf.read_text(encoding="utf-8"))
                for rnd in data.get("rounds", []):
                    if rnd.get("type") == "final":
                        for msg in rnd.get("messages", []):
                            msg["actioned_date"] = "2026-04-05"
                yf.write_text(yaml.dump(data, default_flow_style=False), encoding="utf-8")

        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--send", "--dry-run"],
            tmp_campaign,
        )
        assert r.returncode == 0
        assert "Nothing to send" in r.stdout

    def test_send_requires_campaign_yaml(self, tmp_path):
        """--send without a campaign YAML errors out."""
        r = run_campaign([str(tmp_path), "--send", "--dry-run"], tmp_path)
        assert r.returncode != 0


def _load_campaign_module():
    """Import update-campaign.py despite the hyphenated filename."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "spar_campaign", str(BIN),
    )
    mod = importlib.util.module_from_spec(spec)
    # Only load the module definitions without running main()
    spec.loader.exec_module(mod)
    return mod


class TestStampActionedDate:
    def test_stamp_round_trips_yaml(self, tmp_campaign, sample_approach_data):
        """_stamp_actioned_date stamps the date and preserves file structure."""
        mod = _load_campaign_module()

        approach_path = tmp_campaign / "seg-alpha" / "approach" / "alice-johnson-acme-corp.yaml"
        assert approach_path.exists()

        changed = mod._stamp_actioned_date(approach_path, "2026-04-09")
        assert changed is True

        # Re-read and verify
        data = yaml.safe_load(approach_path.read_text(encoding="utf-8"))
        for rnd in data["rounds"]:
            if rnd.get("type") == "final":
                for msg in rnd.get("messages", []):
                    if msg.get("channel") == "email":
                        assert msg["actioned_date"] == "2026-04-09"

    def test_stamp_idempotent(self, tmp_campaign):
        """Stamping an already-stamped file returns False."""
        mod = _load_campaign_module()

        # Bob's approach already has actioned_date set
        approach_path = tmp_campaign / "seg-alpha" / "approach" / "bob-smith-beta-inc.yaml"
        changed = mod._stamp_actioned_date(approach_path, "2026-04-09")
        assert changed is False

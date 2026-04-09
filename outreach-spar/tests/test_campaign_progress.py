"""Integration tests for update-campaign.py progress mode."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

BIN = Path(__file__).resolve().parent.parent / "bin" / "update-campaign.py"


def run_campaign(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(BIN)] + args,
        capture_output=True, text=True, cwd=str(cwd), timeout=30,
    )


class TestProgressTable:
    def test_basic_progress_output(self, tmp_campaign):
        """Progress table prints with correct column headers."""
        r = run_campaign([".", "--campaign", "campaign.yaml", "--no-mailroom"], tmp_campaign)
        assert r.returncode == 0
        assert "Segment" in r.stdout
        assert "TOTAL" in r.stdout

    def test_column_count(self, tmp_campaign):
        """Progress table has 12 columns (Segment + 11 metrics)."""
        r = run_campaign([".", "--campaign", "campaign.yaml", "--no-mailroom"], tmp_campaign)
        assert r.returncode == 0
        for line in r.stdout.splitlines():
            if line.startswith("|") and "---" not in line:
                cols = [c.strip() for c in line.strip("|").split("|")]
                assert len(cols) == 12, f"Expected 12 columns, got {len(cols)}: {cols}"
                break
        else:
            pytest.fail("No table header line found in output")

    def test_segments_filter(self, tmp_campaign):
        """--segments restricts output to named segments."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--segments", "seg-alpha"],
            tmp_campaign,
        )
        assert r.returncode == 0
        assert "seg-alpha" in r.stdout
        # seg-beta should not appear as a data row
        lines = [l for l in r.stdout.splitlines() if l.startswith("|") and "seg-beta" in l]
        assert len(lines) == 0

    def test_segments_filter_invalid(self, tmp_campaign):
        """--segments with unknown segment name errors out."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--segments", "nonexistent"],
            tmp_campaign,
        )
        assert r.returncode != 0

    def test_legend(self, tmp_campaign):
        """--legend prints column definitions."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--legend"],
            tmp_campaign,
        )
        assert r.returncode == 0
        assert "Valid" in r.stdout

    def test_no_campaign_yaml_falls_back(self, tmp_path):
        """Without a campaign YAML, falls back to directory scan."""
        # Create a minimal segment with just a roster
        seg = tmp_path / "seg-test"
        seg.mkdir()
        roster = seg / "roster.tsv"
        roster.write_text(
            "organisation\tcontact_name\trole\tphone\temail\tlinkedin_url\t"
            "facebook_url\tsweep_iteration\tdiscovered_via\tdiscovery_source\t"
            "verified\tdate_found_invalid\n"
            "Org\tTest Person\tCEO\t\ttest@org.com\t\t\t1\tWeb\tWeb\tyes\t\n",
            encoding="utf-8",
        )
        r = run_campaign([str(tmp_path), "--no-mailroom"], tmp_path)
        assert r.returncode == 0
        assert "seg-test" in r.stdout


class TestMissing:
    def test_missing_all(self, tmp_campaign):
        """--missing without stages shows all three."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--missing"],
            tmp_campaign,
        )
        assert r.returncode == 0

    def test_missing_specific_stage(self, tmp_campaign):
        """--missing P shows profile gaps."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--missing", "P"],
            tmp_campaign,
        )
        assert r.returncode == 0

    def test_missing_invalid_stage(self, tmp_campaign):
        """--missing X errors out."""
        r = run_campaign(
            [".", "--campaign", "campaign.yaml", "--no-mailroom", "--missing", "X"],
            tmp_campaign,
        )
        assert r.returncode != 0

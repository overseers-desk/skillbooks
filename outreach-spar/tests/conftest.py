"""Shared fixtures for SPAR pipeline tests."""
from __future__ import annotations

import textwrap
from pathlib import Path

import pytest
import yaml


@pytest.fixture()
def sample_campaign_yaml() -> dict:
    return {
        "campaign": "test-campaign-2026",
        "sender": {
            "name": "Test Sender",
            "email": "sender@example.com",
            "bcc": "sender@example.com",
        },
        "ses_region": "ap-southeast-2",
        "segments": ["seg-alpha", "seg-beta"],
        "skip_segments": ["seg-skip"],
        "filter": {
            "exclude_invalid": True,
            "min_star": 3,
            "require_email": True,
        },
        "reply_check": {
            "mailroom_account": "test",
            "folder": "INBOX",
        },
    }


@pytest.fixture()
def sample_approach_data() -> dict:
    return {
        "profile_date": "2026-04-01",
        "profile_richness": "Medium",
        "decisions": {
            "warmth": "cold",
            "channel": "email",
            "language": "en",
            "angle": "test-angle",
            "sender": {"name": "Test Sender", "email": "sender@example.com"},
        },
        "angle_rationale": "Test rationale.",
        "rounds": [
            {
                "type": "draft",
                "number": 1,
                "messages": [
                    {
                        "channel": "email",
                        "to": "alice@example.com",
                        "subject": "Hello Alice",
                        "body": "Draft body.",
                        "actioned_date": None,
                    }
                ],
            },
            {
                "type": "review",
                "number": 1,
                "verdict": "DONE",
            },
            {
                "type": "final",
                "messages": [
                    {
                        "channel": "email",
                        "to": "alice@example.com",
                        "subject": "Hello Alice",
                        "body": "Final body.",
                        "actioned_date": None,
                    }
                ],
            },
        ],
    }


def _write_roster_tsv(path: Path, rows: list[dict]) -> None:
    """Write a roster TSV from a list of dicts."""
    if not rows:
        return
    cols = list(rows[0].keys())
    lines = ["\t".join(cols)]
    for r in rows:
        lines.append("\t".join(str(r.get(c, "")) for c in cols))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


@pytest.fixture()
def tmp_campaign(tmp_path, sample_campaign_yaml, sample_approach_data):
    """Create a minimal campaign directory with two segments.

    Returns the base campaign path.
    """
    base = tmp_path / "campaign"
    base.mkdir()

    # Campaign YAML
    (base / "campaign.yaml").write_text(
        yaml.dump(sample_campaign_yaml, default_flow_style=False), encoding="utf-8"
    )

    roster_rows = [
        {
            "organisation": "Acme Corp",
            "contact_name": "Alice Johnson",
            "role": "CEO",
            "phone": "0400000001",
            "email": "alice@acme.com",
            "linkedin_url": "https://linkedin.com/in/alice",
            "facebook_url": "",
            "sweep_iteration": "1",
            "discovered_via": "WebSearch",
            "discovery_source": "WebSearch",
            "verified": "yes",
            "date_found_invalid": "",
            "s_note": "Found via search",
            "p_note": "Strong candidate",
            "star_rating": "4",
            "response_likelihood": "65",
            "a_note": "",
            "r_note": "",
        },
        {
            "organisation": "Beta Inc",
            "contact_name": "Bob Smith",
            "role": "CTO",
            "phone": "",
            "email": "bob@beta.com",
            "linkedin_url": "",
            "facebook_url": "",
            "sweep_iteration": "1",
            "discovered_via": "Referral",
            "discovery_source": "Referral",
            "verified": "yes",
            "date_found_invalid": "",
            "s_note": "Referral from Alice",
            "p_note": "Moderate fit",
            "star_rating": "3",
            "response_likelihood": "40",
            "a_note": "",
            "r_note": "",
        },
        {
            "organisation": "Gone LLC",
            "contact_name": "Charlie Gone",
            "role": "Former CEO",
            "phone": "",
            "email": "charlie@gone.com",
            "linkedin_url": "",
            "facebook_url": "",
            "sweep_iteration": "1",
            "discovered_via": "WebSearch",
            "discovery_source": "WebSearch",
            "verified": "no",
            "date_found_invalid": "2026-03-01",
            "s_note": "",
            "p_note": "",
            "star_rating": "0",
            "response_likelihood": "",
            "a_note": "",
            "r_note": "",
        },
        {
            "organisation": "Delta Co",
            "contact_name": "Diana Low",
            "role": "Manager",
            "phone": "",
            "email": "",
            "linkedin_url": "https://linkedin.com/in/diana",
            "facebook_url": "",
            "sweep_iteration": "2",
            "discovered_via": "LinkedIn",
            "discovery_source": "LinkedIn",
            "verified": "yes",
            "date_found_invalid": "",
            "s_note": "",
            "p_note": "Good but no email",
            "star_rating": "4",
            "response_likelihood": "50",
            "a_note": "",
            "r_note": "",
        },
    ]

    for seg_name in ("seg-alpha", "seg-beta"):
        seg = base / seg_name
        seg.mkdir()
        _write_roster_tsv(seg / "roster.tsv", roster_rows)

        profiles = seg / "profiles"
        profiles.mkdir()
        (profiles / "profile-alice-johnson-acme-corp.md").write_text(
            "# Profile: Alice Johnson\n\nCEO of Acme Corp.\n", encoding="utf-8"
        )
        (profiles / "profile-bob-smith-beta-inc.md").write_text(
            "# Profile: Bob Smith\n\nCTO of Beta Inc.\n", encoding="utf-8"
        )

        approach = seg / "approach"
        approach.mkdir()

        # Alice: approach with unsent final email
        (approach / "alice-johnson-acme-corp.yaml").write_text(
            yaml.dump(sample_approach_data, default_flow_style=False), encoding="utf-8"
        )

        # Bob: approach with sent final email
        sent_data = dict(sample_approach_data)
        sent_rounds = []
        for r in sample_approach_data["rounds"]:
            rc = dict(r)
            if rc.get("type") == "final":
                rc = dict(rc)
                rc["messages"] = [
                    {
                        "channel": "email",
                        "to": "bob@beta.com",
                        "subject": "Hello Bob",
                        "body": "Final body.",
                        "actioned_date": "2026-04-05",
                    }
                ]
            sent_rounds.append(rc)
        sent_data["rounds"] = sent_rounds
        (approach / "bob-smith-beta-inc.yaml").write_text(
            yaml.dump(sent_data, default_flow_style=False), encoding="utf-8"
        )

    # Also create the skipped segment directory
    skip_seg = base / "seg-skip"
    skip_seg.mkdir()
    _write_roster_tsv(skip_seg / "roster.tsv", roster_rows[:1])

    return base

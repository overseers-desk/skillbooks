"""Unit tests for spar_lib shared library."""
from __future__ import annotations

from pathlib import Path

import pytest
import yaml

import spar_lib


# ── slugify ──────────────────────────────────────────────────────────────


class TestSlugify:
    def test_basic(self):
        assert spar_lib.slugify("John Smith") == "john-smith"

    def test_accents(self):
        assert spar_lib.slugify("José García") == "jose-garcia"

    def test_special_chars(self):
        assert spar_lib.slugify("O'Brien-Smith & Co") == "o-brien-smith-co"

    def test_strip_edges(self):
        assert spar_lib.slugify("--hello--") == "hello"

    def test_collapse_hyphens(self):
        assert spar_lib.slugify("a   b   c") == "a-b-c"

    def test_empty(self):
        assert spar_lib.slugify("") == ""

    def test_unicode_combining(self):
        # e with combining acute accent
        assert spar_lib.slugify("r\u0065\u0301sum\u0065\u0301") == "resume"


# ── normalise_name ───────────────────────────────────────────────────────


class TestNormaliseName:
    def test_basic(self):
        assert spar_lib.normalise_name("John Smith") == "john smith"

    def test_accents(self):
        assert spar_lib.normalise_name("José García") == "jose garcia"

    def test_parentheticals(self):
        assert spar_lib.normalise_name("John (CEO)") == "john"

    def test_separators(self):
        # em-dash, slash, ampersand, en-dash all become space
        assert spar_lib.normalise_name("A\u2014B/C&D\u2013E") == "a b c d e"

    def test_hyphens_become_space(self):
        assert spar_lib.normalise_name("Mary-Jane Watson") == "mary jane watson"

    def test_collapse_whitespace(self):
        assert spar_lib.normalise_name("  John   Smith  ") == "john smith"


# ── parse_star ───────────────────────────────────────────────────────────


class TestParseStar:
    def test_digit(self):
        assert spar_lib.parse_star("3") == 3

    def test_empty(self):
        assert spar_lib.parse_star("") == 0

    def test_non_digit(self):
        assert spar_lib.parse_star("high") == 0

    def test_whitespace(self):
        assert spar_lib.parse_star(" 4 ") == 4

    def test_zero(self):
        assert spar_lib.parse_star("0") == 0


# ── is_null ──────────────────────────────────────────────────────────────


class TestIsNull:
    def test_none(self):
        assert spar_lib.is_null(None) is True

    def test_tilde(self):
        assert spar_lib.is_null("~") is True

    def test_none_str(self):
        assert spar_lib.is_null("None") is True

    def test_null_str(self):
        assert spar_lib.is_null("null") is True

    def test_empty(self):
        assert spar_lib.is_null("") is True

    def test_whitespace_only(self):
        assert spar_lib.is_null("  ") is True

    def test_valid_date(self):
        assert spar_lib.is_null("2026-04-09") is False

    def test_zero_int(self):
        assert spar_lib.is_null(0) is False


# ── discover_campaign_yaml ───────────────────────────────────────────────


class TestDiscoverCampaignYaml:
    def test_explicit_file(self, tmp_path):
        f = tmp_path / "my-campaign.yaml"
        f.write_text("campaign: test\n")
        assert spar_lib.discover_campaign_yaml(tmp_path, str(f)) == f

    def test_default_name(self, tmp_path):
        f = tmp_path / "campaign.yaml"
        f.write_text("campaign: test\n")
        assert spar_lib.discover_campaign_yaml(tmp_path) == f

    def test_glob_fallback(self, tmp_path):
        f = tmp_path / "campaign-2026-04.yaml"
        f.write_text("campaign: test\n")
        assert spar_lib.discover_campaign_yaml(tmp_path) == f

    def test_glob_picks_last(self, tmp_path):
        (tmp_path / "campaign-2026-03.yaml").write_text("campaign: old\n")
        newer = tmp_path / "campaign-2026-04.yaml"
        newer.write_text("campaign: new\n")
        assert spar_lib.discover_campaign_yaml(tmp_path) == newer

    def test_none_when_missing(self, tmp_path):
        assert spar_lib.discover_campaign_yaml(tmp_path) is None

    def test_explicit_nonexistent(self, tmp_path):
        assert spar_lib.discover_campaign_yaml(tmp_path, "/no/such/file.yaml") is None

    def test_explicit_directory(self, tmp_path):
        sub = tmp_path / "sub"
        sub.mkdir()
        f = sub / "campaign.yaml"
        f.write_text("campaign: test\n")
        assert spar_lib.discover_campaign_yaml(tmp_path, str(sub)) == f


# ── load_campaign_yaml ───────────────────────────────────────────────────


class TestLoadCampaignYaml:
    def test_valid(self, tmp_path):
        f = tmp_path / "c.yaml"
        f.write_text("campaign: test\nsegments:\n  - seg1\n")
        data = spar_lib.load_campaign_yaml(f)
        assert data["campaign"] == "test"
        assert data["segments"] == ["seg1"]

    def test_invalid_yaml(self, tmp_path):
        f = tmp_path / "bad.yaml"
        f.write_text(": :\n  - [invalid\n")
        assert spar_lib.load_campaign_yaml(f) is None


# ── extract_campaign_context ─────────────────────────────────────────────


class TestExtractCampaignContext:
    def test_full(self, sample_campaign_yaml):
        segs, skip, data = spar_lib.extract_campaign_context(
            sample_campaign_yaml, ["extra-skip"]
        )
        assert segs == ["seg-alpha", "seg-beta"]
        assert "seg-skip" in skip
        assert "extra-skip" in skip

    def test_none_data(self):
        segs, skip, data = spar_lib.extract_campaign_context(None)
        assert segs is None
        assert skip == set()

    def test_no_segments_key(self):
        segs, skip, _ = spar_lib.extract_campaign_context({"campaign": "test"})
        assert segs is None


# ── discover_segments ────────────────────────────────────────────────────


class TestDiscoverSegments:
    def test_yaml_driven(self, tmp_campaign):
        segments = spar_lib.discover_segments(
            tmp_campaign, ["seg-alpha", "seg-beta"], set()
        )
        assert len(segments) == 2
        assert segments[0][0].name == "seg-alpha"

    def test_skip(self, tmp_campaign):
        segments = spar_lib.discover_segments(
            tmp_campaign, ["seg-alpha", "seg-beta", "seg-skip"], {"seg-skip"}
        )
        names = [s[0].name for s in segments]
        assert "seg-skip" not in names

    def test_fallback_scan(self, tmp_campaign):
        segments = spar_lib.discover_segments(tmp_campaign, None, set())
        names = {s[0].name for s in segments}
        assert "seg-alpha" in names
        assert "seg-beta" in names
        assert "seg-skip" in names  # not skipped when no yaml_segments

    def test_require_approach(self, tmp_campaign):
        segments = spar_lib.discover_segments(
            tmp_campaign, ["seg-alpha", "seg-beta"], set(), require="approach"
        )
        assert len(segments) == 2
        for seg_dir, req_path in segments:
            assert req_path.name == "approach"
            assert req_path.is_dir()

    def test_missing_roster_warns(self, tmp_campaign, capsys):
        # Add a segment name that has no directory
        segments = spar_lib.discover_segments(
            tmp_campaign, ["seg-alpha", "nonexistent"], set()
        )
        assert len(segments) == 1
        assert "WARNING" in capsys.readouterr().err


# ── load_roster ──────────────────────────────────────────────────────────


class TestLoadRoster:
    def test_normal(self, tmp_campaign):
        roster_path = tmp_campaign / "seg-alpha" / "roster.tsv"
        rows = spar_lib.load_roster(roster_path)
        assert len(rows) == 4
        assert rows[0]["contact_name"] == "Alice Johnson"

    def test_blank_rows_filtered(self, tmp_path):
        tsv = tmp_path / "roster.tsv"
        tsv.write_text(
            "contact_name\temail\n"
            "Alice\talice@a.com\n"
            "\t\n"
            "Bob\tbob@b.com\n",
            encoding="utf-8",
        )
        rows = spar_lib.load_roster(tsv)
        assert len(rows) == 2

    def test_crlf_handling(self, tmp_path):
        tsv = tmp_path / "roster.tsv"
        tsv.write_bytes(
            b"contact_name\temail\r\n"
            b"Alice\talice@a.com\r\n"
            b"Bob\tbob@b.com\r\n"
        )
        rows = spar_lib.load_roster(tsv)
        assert len(rows) == 2
        assert rows[0]["contact_name"] == "Alice"


# ── build_profile_index + name_matches ───────────────────────────────────


class TestProfileIndex:
    def test_build_index(self, tmp_campaign):
        profiles_dir = tmp_campaign / "seg-alpha" / "profiles"
        idx = spar_lib.build_profile_index(profiles_dir)
        assert "alice johnson" in idx
        assert "bob smith" in idx

    def test_name_matches_exact(self, tmp_campaign):
        profiles_dir = tmp_campaign / "seg-alpha" / "profiles"
        idx = spar_lib.build_profile_index(profiles_dir)
        assert spar_lib.name_matches("Alice Johnson", idx) is True

    def test_name_matches_prefix(self, tmp_campaign):
        profiles_dir = tmp_campaign / "seg-alpha" / "profiles"
        idx = spar_lib.build_profile_index(profiles_dir)
        # "alice" is a prefix of "alice johnson"
        assert spar_lib.name_matches("Alice", idx) is True

    def test_name_matches_no_match(self, tmp_campaign):
        profiles_dir = tmp_campaign / "seg-alpha" / "profiles"
        idx = spar_lib.build_profile_index(profiles_dir)
        assert spar_lib.name_matches("Zara Unknown", idx) is False

    def test_empty_dir(self, tmp_path):
        d = tmp_path / "profiles"
        d.mkdir()
        assert spar_lib.build_profile_index(d) == {}


# ── match_roster_to_stems ───────────────────────────────────────


class TestMatchRosterToStems:
    def _make_approach_dir(self, tmp_path, stems: list[str]) -> Path:
        d = tmp_path / "approach"
        d.mkdir(exist_ok=True)
        for stem in stems:
            (d / f"{stem}.yaml").write_text("rounds: []\n")
        return d

    def test_pass1_exact(self, tmp_path):
        rows = [{"contact_name": "Alice Johnson"}]
        d = self._make_approach_dir(tmp_path, ["alice-johnson-acme"])
        matched, claimed = spar_lib.match_roster_to_stems(rows, d)
        assert matched == {0: "alice-johnson-acme"}

    def test_pass1_exact_equal(self, tmp_path):
        rows = [{"contact_name": "Alice Johnson"}]
        d = self._make_approach_dir(tmp_path, ["alice-johnson"])
        matched, claimed = spar_lib.match_roster_to_stems(rows, d)
        assert matched == {0: "alice-johnson"}

    def test_pass2_first_name(self, tmp_path):
        rows = [{"contact_name": "Alice Johnson"}]
        # No full-name match, but one first-name match
        d = self._make_approach_dir(tmp_path, ["alice-acme-corp"])
        matched, claimed = spar_lib.match_roster_to_stems(rows, d)
        assert matched == {0: "alice-acme-corp"}

    def test_pass2_ambiguous_no_match(self, tmp_path):
        rows = [{"contact_name": "Alice Johnson"}]
        d = self._make_approach_dir(tmp_path, ["alice-acme", "alice-beta"])
        matched, _ = spar_lib.match_roster_to_stems(rows, d)
        assert 0 not in matched

    def test_pass2_single_token_skipped(self, tmp_path):
        rows = [{"contact_name": "Madonna"}]
        d = self._make_approach_dir(tmp_path, ["madonna-corp"])
        matched, _ = spar_lib.match_roster_to_stems(rows, d)
        # Single-token name: pass 1 matches "madonna" prefix in "madonna-corp"
        assert matched == {0: "madonna-corp"}

    def test_claiming_prevents_reuse(self, tmp_path):
        rows = [
            {"contact_name": "Alice Johnson"},
            {"contact_name": "Alice Brown"},
        ]
        d = self._make_approach_dir(tmp_path, ["alice-johnson-acme"])
        matched, _ = spar_lib.match_roster_to_stems(rows, d)
        assert matched == {0: "alice-johnson-acme"}
        assert 1 not in matched

    def test_filter_min_star(self, tmp_path):
        rows = [
            {"contact_name": "Alice", "star_rating": "2"},
            {"contact_name": "Bob", "star_rating": "4"},
        ]
        d = self._make_approach_dir(tmp_path, ["alice-corp", "bob-corp"])
        matched, _ = spar_lib.match_roster_to_stems(
            rows, d, filters={"min_star": 3}
        )
        assert 0 not in matched
        assert 1 in matched

    def test_filter_require_email(self, tmp_path):
        rows = [
            {"contact_name": "Alice", "email": ""},
            {"contact_name": "Bob", "email": "bob@b.com"},
        ]
        d = self._make_approach_dir(tmp_path, ["alice-corp", "bob-corp"])
        matched, _ = spar_lib.match_roster_to_stems(
            rows, d, filters={"require_email": True}
        )
        assert 0 not in matched
        assert 1 in matched

    def test_filter_exclude_invalid(self, tmp_path):
        rows = [
            {"contact_name": "Alice", "date_found_invalid": "2026-01-01"},
            {"contact_name": "Bob", "date_found_invalid": ""},
        ]
        d = self._make_approach_dir(tmp_path, ["alice-corp", "bob-corp"])
        matched, _ = spar_lib.match_roster_to_stems(
            rows, d, filters={"exclude_invalid": True}
        )
        assert 0 not in matched
        assert 1 in matched

    def test_missing_approach_dir(self, tmp_path):
        rows = [{"contact_name": "Alice"}]
        d = tmp_path / "no-such-dir"
        matched, claimed = spar_lib.match_roster_to_stems(rows, d)
        assert matched == {}
        assert claimed == set()


# ── approach_final_round_status ──────────────────────────────────────────


class TestApproachFinalRoundStatus:
    def _write_approach(self, path: Path, data: dict):
        path.write_text(yaml.dump(data, default_flow_style=False), encoding="utf-8")

    def test_unsent(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "final", "messages": [
                {"channel": "email", "actioned_date": None}
            ]}]
        })
        assert spar_lib.approach_final_round_status(f) == (False, False, False)

    def test_sent_email(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "final", "messages": [
                {"channel": "email", "actioned_date": "2026-04-05"}
            ]}]
        })
        assert spar_lib.approach_final_round_status(f) == (True, True, False)

    def test_sent_linkedin(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "final", "messages": [
                {"channel": "linkedin", "actioned_date": "2026-04-05"}
            ]}]
        })
        is_sent, is_email_sent, is_replied = spar_lib.approach_final_round_status(f)
        assert is_sent is True
        assert is_email_sent is False

    def test_replied_via_replied_date(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "final", "messages": [
                {"channel": "email", "actioned_date": "2026-04-05",
                 "replied_date": "2026-04-07"}
            ]}]
        })
        _, _, is_replied = spar_lib.approach_final_round_status(f)
        assert is_replied is True

    def test_replied_via_replies_list(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "final",
                         "messages": [{"channel": "email", "actioned_date": "2026-04-05"}],
                         "replies": [{"direction": "received", "date": "2026-04-07"}]}]
        })
        _, _, is_replied = spar_lib.approach_final_round_status(f)
        assert is_replied is True

    def test_non_final_ignored(self, tmp_path):
        f = tmp_path / "test.yaml"
        self._write_approach(f, {
            "rounds": [{"type": "draft", "messages": [
                {"channel": "email", "actioned_date": "2026-04-05"}
            ]}]
        })
        assert spar_lib.approach_final_round_status(f) == (False, False, False)


# ── find_unsent_final_emails ─────────────────────────────────────────────


class TestFindUnsentFinalEmails:
    def test_finds_unsent(self):
        data = {
            "rounds": [
                {"type": "final", "messages": [
                    {"channel": "email", "to": "a@b.com", "actioned_date": None},
                    {"channel": "email", "to": "c@d.com", "actioned_date": "2026-04-05"},
                ]}
            ]
        }
        result = spar_lib.find_unsent_final_emails(data)
        assert len(result) == 1
        assert result[0]["to"] == "a@b.com"

    def test_skips_non_email(self):
        data = {
            "rounds": [
                {"type": "final", "messages": [
                    {"channel": "linkedin", "actioned_date": None},
                ]}
            ]
        }
        assert spar_lib.find_unsent_final_emails(data) == []

    def test_skips_non_final(self):
        data = {
            "rounds": [
                {"type": "draft", "messages": [
                    {"channel": "email", "actioned_date": None},
                ]}
            ]
        }
        assert spar_lib.find_unsent_final_emails(data) == []

    def test_empty_rounds(self):
        assert spar_lib.find_unsent_final_emails({"rounds": []}) == []


# ── Checker ──────────────────────────────────────────────────────────────


class TestChecker:
    def test_accumulates(self):
        c = spar_lib.Checker("test")
        c.passed("ok")
        c.warn("hmm")
        c.fail("bad")
        assert len(c.results) == 3
        assert c.results[0] == ("PASS", "ok")
        assert c.results[1] == ("WARN", "hmm")
        assert c.results[2] == ("FAIL", "bad")

    def test_print_section(self, capsys):
        c = spar_lib.Checker("my-segment")
        c.passed("all good")
        c.print_section()
        out = capsys.readouterr().out
        assert "── my-segment ──" in out
        assert "[PASS] all good" in out

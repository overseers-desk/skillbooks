"""Tests for approach-schema.yaml JSON Schema validation."""
from __future__ import annotations

from pathlib import Path

import jsonschema
import pytest
import yaml

SCHEMA_PATH = Path(__file__).resolve().parent.parent / "approach-schema.yaml"


@pytest.fixture()
def schema():
    return yaml.safe_load(SCHEMA_PATH.read_text(encoding="utf-8"))


def _minimal_valid():
    """Return a minimal valid approach structure."""
    return {
        "decisions": {"channel": "email"},
        "rounds": [
            {"type": "final", "messages": [
                {"channel": "email", "subject": "Hi", "body": "Hello."}
            ]},
        ],
    }


class TestValidApproach:
    def test_minimal(self, schema):
        jsonschema.validate(_minimal_valid(), schema)

    def test_full_structure(self, schema, sample_approach_data):
        jsonschema.validate(sample_approach_data, schema)

    def test_multiple_rounds(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "draft", "number": 1, "messages": [
                    {"channel": "email", "subject": "Draft", "body": "text"}
                ]},
                {"type": "review", "number": 1, "verdict": "DONE"},
                {"type": "final", "messages": [
                    {"channel": "email", "subject": "Final", "body": "text"}
                ]},
            ],
        }
        jsonschema.validate(data, schema)

    def test_linkedin_message(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "final", "messages": [
                    {"channel": "linkedin", "text": "Hi there"}
                ]},
            ],
        }
        jsonschema.validate(data, schema)


class TestMissingRequired:
    def test_missing_decisions(self, schema):
        data = {"rounds": [{"type": "final", "messages": [{"channel": "email", "subject": "x"}]}]}
        with pytest.raises(jsonschema.ValidationError, match="'decisions' is a required property"):
            jsonschema.validate(data, schema)

    def test_missing_rounds(self, schema):
        data = {"decisions": {}}
        with pytest.raises(jsonschema.ValidationError, match="'rounds' is a required property"):
            jsonschema.validate(data, schema)

    def test_empty_rounds(self, schema):
        data = {"decisions": {}, "rounds": []}
        with pytest.raises(jsonschema.ValidationError, match="too short"):
            jsonschema.validate(data, schema)


class TestRoundStructure:
    def test_invalid_round_type(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "bogus"},
                {"type": "final", "messages": [{"channel": "email", "subject": "x"}]},
            ],
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, schema)

    def test_no_final_round(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "draft", "number": 1, "messages": [{"channel": "email", "subject": "x"}]},
            ],
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, schema)

    def test_draft_missing_number(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "draft", "messages": [{"channel": "email", "subject": "x"}]},
                {"type": "final", "messages": [{"channel": "email", "subject": "x"}]},
            ],
        }
        with pytest.raises(jsonschema.ValidationError, match="'number' is a required property"):
            jsonschema.validate(data, schema)

    def test_review_missing_number(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "review"},
                {"type": "final", "messages": [{"channel": "email", "subject": "x"}]},
            ],
        }
        with pytest.raises(jsonschema.ValidationError, match="'number' is a required property"):
            jsonschema.validate(data, schema)

    def test_draft_missing_messages(self, schema):
        data = {
            "decisions": {},
            "rounds": [
                {"type": "draft", "number": 1},
                {"type": "final", "messages": [{"channel": "email", "subject": "x"}]},
            ],
        }
        with pytest.raises(jsonschema.ValidationError, match="'messages' is a required property"):
            jsonschema.validate(data, schema)

    def test_final_missing_messages(self, schema):
        data = {
            "decisions": {},
            "rounds": [{"type": "final"}],
        }
        with pytest.raises(jsonschema.ValidationError, match="'messages' is a required property"):
            jsonschema.validate(data, schema)


class TestMessageStructure:
    def test_missing_channel(self, schema):
        data = {
            "decisions": {},
            "rounds": [{"type": "final", "messages": [{"to": "a@b.com"}]}],
        }
        with pytest.raises(jsonschema.ValidationError, match="'channel' is a required property"):
            jsonschema.validate(data, schema)

    def test_email_missing_subject_and_body(self, schema):
        data = {
            "decisions": {},
            "rounds": [{"type": "final", "messages": [{"channel": "email", "to": "a@b.com"}]}],
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(data, schema)

    def test_email_with_subject_only(self, schema):
        data = {
            "decisions": {},
            "rounds": [{"type": "final", "messages": [
                {"channel": "email", "to": "a@b.com", "subject": "Hi"}
            ]}],
        }
        jsonschema.validate(data, schema)

    def test_email_with_body_only(self, schema):
        data = {
            "decisions": {},
            "rounds": [{"type": "final", "messages": [
                {"channel": "email", "to": "a@b.com", "body": "Hello."}
            ]}],
        }
        jsonschema.validate(data, schema)

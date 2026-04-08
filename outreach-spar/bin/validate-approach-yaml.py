#!/usr/bin/env python3
"""Validate converted approach YAML files against the schema and check length parity with originals."""

import yaml
import sys
from pathlib import Path

REQUIRED_TOP_KEYS = {'profile_date', 'profile_richness', 'decisions', 'angle_rationale'}
REQUIRED_DECISION_KEYS = {'warmth', 'channel', 'language', 'angle'}
VALID_ROUND_TYPES = {'draft', 'review', 'final'}
VALID_CHANNELS = {'email', 'linkedin', 'phone', 'facebook', 'whatsapp', 'instagram'}

def validate_one(yaml_path, md_path):
    issues = []

    # 1. YAML parse validity
    try:
        with open(yaml_path) as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return [f'YAML parse error: {e}']

    if not isinstance(data, dict):
        return ['YAML did not produce a dict']

    # 2. Required top-level keys
    for k in REQUIRED_TOP_KEYS:
        if k not in data:
            issues.append(f'missing top-level key: {k}')

    # 3. Decisions structure
    decisions = data.get('decisions', {})
    if not isinstance(decisions, dict):
        issues.append('decisions is not a dict')
    else:
        for k in REQUIRED_DECISION_KEYS:
            if not decisions.get(k):
                issues.append(f'missing/empty decisions.{k}')
        # Sender must be present with name and email
        sender = decisions.get('sender')
        if not sender:
            issues.append('missing decisions.sender')
        elif not isinstance(sender, dict):
            issues.append('decisions.sender is not a dict')
        else:
            if not sender.get('name'):
                issues.append('missing decisions.sender.name')
            if not sender.get('email'):
                issues.append('missing decisions.sender.email')

    # 4. Rounds structure
    rounds = data.get('rounds', [])
    if not isinstance(rounds, list):
        issues.append('rounds is not a list')
    elif len(rounds) == 0:
        issues.append('rounds is empty')
    else:
        for i, r in enumerate(rounds):
            if not isinstance(r, dict):
                issues.append(f'round {i} is not a dict')
                continue
            rtype = r.get('type')
            if rtype not in VALID_ROUND_TYPES:
                issues.append(f'round {i} has invalid type: {rtype}')

            if rtype == 'final' or rtype == 'draft':
                msgs = r.get('messages', [])
                if msgs:
                    for j, msg in enumerate(msgs):
                        ch = msg.get('channel')
                        if ch and ch not in VALID_CHANNELS:
                            issues.append(f'round {i} message {j} has unknown channel: {ch}')
                        if 'from' in msg:
                            issues.append(f'round {i} message {j} has deprecated "from" field (should be in decisions.sender)')

            if rtype == 'review':
                verdict = r.get('verdict')
                if verdict and verdict not in ('DONE', 'REVISE'):
                    issues.append(f'round {i} has invalid verdict: {verdict}')

        # Must have at least a final round
        has_final = any(r.get('type') == 'final' for r in rounds)
        if not has_final:
            issues.append('no final round in rounds')

    # 5. Length parity
    yaml_len = yaml_path.stat().st_size
    md_len = md_path.stat().st_size
    ratio = yaml_len / md_len if md_len > 0 else 0
    if ratio < 0.3:
        issues.append(f'yaml too short: {yaml_len}B vs {md_len}B original ({ratio:.0%})')
    if ratio > 2.0:
        issues.append(f'yaml too long: {yaml_len}B vs {md_len}B original ({ratio:.0%})')

    return issues


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--mapping', type=str, help='Mapping TSV (for finding .md counterparts of renamed .yaml files)')
    parser.add_argument('--root', type=str, default='.', help='Root directory')
    args = parser.parse_args()

    root = Path(args.root)

    # Build reverse mapping: (segment, new_yaml_name) -> approach_md_stem
    reverse_mapping = {}
    if args.mapping:
        with open(args.mapping) as f:
            for line in f:
                if line.startswith('segment\t'):
                    continue
                parts = line.strip().split('\t')
                if len(parts) >= 4:
                    segment, approach_current, _, approach_new = parts[:4]
                    md_stem = approach_current.replace('.yaml', '')
                    reverse_mapping[(segment, approach_new)] = md_stem

    # Find YAML files: both old approach-*.yaml and new profile-*.yaml
    yaml_files = sorted(list(root.glob('*/approach/approach-*.yaml')) +
                        list(root.glob('*/approach/profile-*.yaml')))
    total = len(yaml_files)
    ok = 0
    bad = 0
    issue_list = []
    ratios = []

    for yf in yaml_files:
        segment = yf.parent.parent.name
        # Find matching .md for size comparison
        if reverse_mapping:
            md_stem = reverse_mapping.get((segment, yf.name))
            mf = yf.parent / f'{md_stem}.md' if md_stem else yf.with_suffix('.md')
        else:
            mf = yf.with_suffix('.md')

        if not mf.exists():
            # Try profile-named .md as fallback
            profile_mf = yf.parent.parent / 'profiles' / yf.with_suffix('.md').name
            if profile_mf.exists():
                mf = profile_mf
            else:
                issue_list.append((str(yf), ['no matching .md file for size comparison']))
                bad += 1
                continue

        issues = validate_one(yf, mf)
        if issues:
            issue_list.append((str(yf), issues))
            bad += 1
        else:
            ok += 1

        ratios.append(yf.stat().st_size / mf.stat().st_size if mf.stat().st_size > 0 else 0)

    print(f"Validated {total} YAML files: {ok} OK, {bad} with issues")
    if ratios:
        print(f"Size ratio (yaml/md): min={min(ratios):.2f}, max={max(ratios):.2f}, avg={sum(ratios)/len(ratios):.2f}")

    if issue_list:
        print(f"\n--- Files with issues ({bad}) ---")
        for path, issues in sorted(issue_list):
            print(f"  {path}: {'; '.join(issues)}")


if __name__ == '__main__':
    main()

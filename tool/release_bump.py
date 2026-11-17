#!/usr/bin/env python3
"""Plan/apply release metadata from conventional commits; never commit or publish."""
import argparse
from datetime import date, datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo

VERSION = r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()


def classify(messages):
    level = None
    rank = {None: 0, 'patch': 1, 'minor': 2, 'major': 3}
    for message in messages:
        header = re.match(r'^([a-z]+)(?:\([^\n)]+\))?(!)?:\s+\S', message)
        if not header:
            continue
        breaking = header[2] or re.search(r'^BREAKING(?: CHANGE|-CHANGE):', message, re.M)
        candidate = ('major' if breaking else 'minor' if header[1] == 'feat'
                     else 'patch' if header[1] in ('fix', 'perf') else None)
        level = max(level, candidate, key=rank.__getitem__)
    return level


def next_version(current, bump, explicit=False):
    match = re.fullmatch(VERSION, current)
    if not match:
        raise ValueError('Only stable three-part versions are supported')
    major, minor, patch = map(int, match.groups())
    if bump == 'major' and (major > 0 or explicit):
        return f'{major + 1}.0.0'
    if bump == 'minor' or bump == 'major':
        return f'{major}.{minor + 1}.0'
    if bump == 'patch':
        return f'{major}.{minor}.{patch + 1}'
    raise ValueError('Unsupported bump')


def package_version(repo):
    text = (repo / 'pubspec.yaml').read_text(encoding='utf-8')
    versions = re.findall(r'^version:\s*(\S+)\s*$', text, re.M)
    if len(versions) != 1 or not re.fullmatch(VERSION, versions[0]):
        raise ValueError('pubspec must contain exactly one stable version')
    if not re.search(r'^name: steering_engine\s*$', text, re.M):
        raise ValueError('Expected the steering_engine package')
    return versions[0]


def clean(repo):
    if git(repo, 'status', '--porcelain'):
        raise ValueError('Release metadata requires a clean checkout')


def commits_since(repo, base):
    raw = git(repo, 'log', '-z', '--format=%H%n%B', base + '..HEAD')
    commits = []
    for record in raw.split('\0'):
        if not record.strip():
            continue
        sha, message = record.strip().split('\n', 1)
        commits.append({'sha': sha, 'message': message.strip()})
    return commits


def render_changelog(repo, version, day, commits):
    changelog = (repo / 'CHANGELOG.md').read_text(encoding='utf-8')
    unreleased = re.search(r'^## Unreleased[ \t]*\n(.*?)(?=^## |\Z)', changelog, re.M | re.S)
    if not unreleased:
        raise ValueError('CHANGELOG.md must have an Unreleased section')
    notes = unreleased[1].strip()
    if not notes:
        notes = '\n'.join('- ' + c['message'].splitlines()[0] + ' (' + c['sha'][:7] + ')'
                          for c in reversed(commits))
    updated = (changelog[:unreleased.start()] + '## Unreleased\n\n'
               + f'## {version} — {day}\n\n' + notes + '\n\n'
               + changelog[unreleased.end():].lstrip())
    return notes, updated


def build_plan(repo, bump='auto', release_date=None):
    repo = Path(repo).resolve()
    clean(repo)
    current = package_version(repo)
    base = 'v' + current
    tags = git(repo, 'tag', '--list').splitlines()
    if base not in tags:
        raise ValueError(f'Missing existing base tag {base}; do not guess released history')
    subprocess.run(['git', '-C', str(repo), 'merge-base', '--is-ancestor', base, 'HEAD'],
                   check=True)
    head = git(repo, 'rev-parse', 'HEAD')
    commits = commits_since(repo, base)
    level = classify([c['message'] for c in commits]) if bump == 'auto' else bump
    plan = {'changed': bool(commits and level), 'head': head,
            'base_tag': base, 'previous_version': current}
    if not plan['changed']:
        return plan
    version = next_version(current, level, explicit=bump != 'auto')
    if 'v' + version in tags:
        raise ValueError('Next version tag already exists; never move a released tag')
    day = release_date or datetime.now(ZoneInfo('America/Sao_Paulo')).date().isoformat()
    date.fromisoformat(day)
    notes, updated = render_changelog(repo, version, day, commits)
    plan.update(version=version, tag='v' + version, date=day, notes=notes, changelog=updated)
    return plan


def apply_plan(repo, plan):
    repo = Path(repo).resolve()
    clean(repo)
    if git(repo, 'rev-parse', 'HEAD') != plan['head'] or package_version(repo) != plan['previous_version']:
        raise ValueError('Release plan is stale')
    if not plan['changed']:
        return
    if plan['tag'] in git(repo, 'tag', '--list').splitlines():
        raise ValueError('Release tag already exists')
    spec = repo / 'pubspec.yaml'
    text = spec.read_text(encoding='utf-8')
    spec.write_text(re.sub(r'^version:\s*\S+[ \t]*$', 'version: ' + plan['version'], text,
                           flags=re.M), encoding='utf-8')
    (repo / 'CHANGELOG.md').write_text(plan['changelog'], encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('.'))
    parser.add_argument('--bump', choices=['auto', 'patch', 'minor', 'major'], default='auto')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--notes', type=Path)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    plan = build_plan(args.repo, args.bump)
    if args.apply:
        apply_plan(args.repo, plan)
    if args.output:
        args.output.write_text(json.dumps(plan, indent=2) + '\n', encoding='utf-8')
    if args.notes and plan['changed']:
        args.notes.write_text(plan['notes'] + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in plan.items() if k not in ('notes', 'changelog')}, indent=2))


if __name__ == '__main__':
    main()

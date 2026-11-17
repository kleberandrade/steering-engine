#!/usr/bin/env python3
"""Check handbook navigation, local links, SVGs and exported algorithm coverage.

Optionally extract Dart snippets into one compilable public-API smoke example.
No third-party Python packages required.
"""
import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[1]
HANDBOOK = ROOT / 'doc/wiki'
CHAPTERS = {
    'Seek': 'Seek', 'Flee': 'Flee', 'Arrive': 'Arrive', 'Pursuit': 'Pursuit',
    'Evade': 'Evade', 'Wander': 'Wander', 'Brake': 'Brake',
    'Separation': 'Separation', 'Alignment': 'Alignment', 'Cohesion': 'Cohesion',
    'Flocking': 'Flocking', 'FollowPath': 'Path-Following',
    'ObstacleAvoidance': 'Obstacle-Avoidance', 'LeaderFollowing': 'Leader-Following',
    'QueueFollowing': 'Queue-Following', 'WallFollowing': 'Wall-Following',
    'WeightedBlend': 'Weighted-Blend', 'PrioritySteering': 'Priority-Steering',
    'FollowPolyline': 'Continuous-Path',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--extract-dart', type=Path)
    args = parser.parse_args()
    errors = []
    files = sorted(HANDBOOK.glob('*.md')) + [ROOT / 'README.md',
             ROOT / 'README.pt-BR.md', ROOT / 'doc/wiki-maintenance.md',
             ROOT / 'doc/roadmap_0.2.0.md', ROOT / 'doc/web_deployment.md',
             ROOT / 'doc/roadmap_0.3.0.md', ROOT / 'doc/automated_publishing.md']
    for path in files:
        text = re.sub(r'```.*?```', '', path.read_text(), flags=re.S)
        for target in re.findall(r'\]\(([^)]+)\)', text):
            if '://' in target or target.startswith(('#', 'mailto:')):
                continue
            destination = path.parent / target.split('#')[0]
            if not destination.exists():
                errors.append(f'{path.relative_to(ROOT)}: missing {target}')
    implemented = set()
    for path in (ROOT / 'lib/src').rglob('*.dart'):
        implemented.update(re.findall(r'class (\w+) implements SteeringBehavior', path.read_text()))
    if implemented != set(CHAPTERS):
        errors.append(f'Coverage differs: code={implemented ^ set(CHAPTERS)}')
    sidebar = (HANDBOOK / '_Sidebar.md').read_text()
    home = (HANDBOOK / 'Home.md').read_text()
    mode_source = (ROOT / 'example/flutter_lab/lib/lab/lab_modes.dart').read_text()
    lab_modes = set(re.findall(r"  '([^']+)'", mode_source))
    linked_modes = set()
    for api, slug in CHAPTERS.items():
        path = HANDBOOK / f'{slug}.md'
        if not path.exists():
            errors.append(f'Missing chapter for {api}')
            continue
        content = path.read_text()
        links = re.findall(r'\]\((https://kleberandrade.github.io/steering-engine/\?[^)]+)\)', content)
        if len(links) != 1:
            errors.append(f'{slug}: expected one online scene link')
        for link in links:
            mode = parse_qs(urlparse(link).query).get('mode', [''])[0]
            if mode not in lab_modes:
                errors.append(f'{slug}: unsupported scene {mode}')
            linked_modes.add(mode)
        for required in ['## Intuição', '## Passo a passo', '## Parâmetros',
                         '## Uso em Dart', '## Experimente', '## Limites',
                         '```text', '```dart', f'images/{slug}.svg', '**English.**']:
            if required not in content:
                errors.append(f'{slug}: missing {required}')
        if f'({slug}.md)' not in sidebar or f'({slug}.md)' not in home:
            errors.append(f'{slug}: missing navigation')
    if linked_modes != lab_modes:
        errors.append(f'Lab scene link coverage differs: {linked_modes ^ lab_modes}')
    for path in (HANDBOOK / 'images').glob('*.svg'):
        try:
            image = ET.parse(path).getroot()
            if image.find('{http://www.w3.org/2000/svg}title') is None:
                errors.append(f'{path.name}: no accessible title')
        except ET.ParseError as error:
            errors.append(f'{path.name}: {error}')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'OK: {len(files)} documents, {len(CHAPTERS)} algorithms, local links and SVG XML')
    if args.extract_dart:
        args.extract_dart.mkdir(parents=True, exist_ok=True)
        output = ["import 'package:steering_engine/steering_engine.dart';"]
        calls = []
        blocks = 0
        for path in sorted(HANDBOOK.glob('*.md')):
            for snippet in re.findall(r'```dart\n(.*?)```', path.read_text(), re.S):
                name = f'snippet{blocks}'
                if snippet.startswith('import '):
                    # Full examples contain top-level declarations and imports.
                    dest = args.extract_dart / f'{path.stem}-{blocks}.dart'
                    if not re.search(r'void main\(', snippet):
                        snippet += '\nvoid main() {}\n'
                    dest.write_text(snippet)
                else:
                    output.append(f'void {name}() {{\n'
                        'final agent = SteeringAgent(position: Vec2.zero, maxSpeed: 80, maxAcceleration: 160);\n'
                        'final targetSnapshot = SteeringAgent(position: Vec2(100, 0), velocity: Vec2(5, 0), maxSpeed: 80, maxAcceleration: 160);\n'
                        'final agents = [agent, targetSnapshot];\n'
                        + snippet + '\n}\n')
                    calls.append(name + '();')
                blocks += 1
        output.append('void main() {\n' + '\n'.join(calls) + '\n}')
        (args.extract_dart / 'configurations.dart').write_text('\n'.join(output))
        print(f'Extracted {blocks} Dart snippets to {args.extract_dart}')


if __name__ == '__main__':
    main()

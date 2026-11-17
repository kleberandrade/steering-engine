"""Public release policy and real Git fixture tests; no network or third-party libs."""
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from contextlib import redirect_stdout
import io
import json
from pathlib import Path

from release_bump import build_plan, classify, next_version, apply_plan, main, package_version


class ReleasePolicyTest(unittest.TestCase):
    def test_conventional_commit_policy(self):
        self.assertIsNone(classify(['docs: improve guide', 'test: add fixture', 'chore: tools']))
        self.assertEqual(classify(['fix(core): correct projection']), 'patch')
        self.assertEqual(classify(['perf: reduce neighbor allocations']), 'patch')
        self.assertEqual(classify(['feat: add a controller', 'fix: old bug']), 'minor')
        self.assertEqual(classify(['feat(core)!: change the contract']), 'major')
        self.assertEqual(classify(['fix: new contract\n\nBREAKING CHANGE: old option removed']), 'major')
        self.assertIsNone(classify(['Merge pull request #3', 'chore(release): 0.2.1']))

    def test_semver_including_pre_one_breaking_changes(self):
        self.assertEqual(next_version('0.2.0', 'patch'), '0.2.1')
        self.assertEqual(next_version('0.2.9', 'minor'), '0.3.0')
        self.assertEqual(next_version('0.2.9', 'major'), '0.3.0')
        self.assertEqual(next_version('1.2.9', 'major'), '2.0.0')
        self.assertEqual(next_version('0.2.9', 'major', explicit=True), '1.0.0')
        for invalid in ['0.2', 'v0.2.0', '0.2.0-dev', '01.2.3']:
            with self.assertRaises(ValueError):
                next_version(invalid, 'patch')
        with self.assertRaises(ValueError):
            next_version('0.2.0', 'unknown')


class GitReleaseTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.git('init', '-b', 'main')
        self.git('config', 'user.name', 'Release test')
        self.git('config', 'user.email', 'release-test@example.test')
        self.git('config', 'commit.gpgsign', 'false')
        (self.repo / 'pubspec.yaml').write_text('name: steering_engine\nversion: 0.2.0\n')
        (self.repo / 'CHANGELOG.md').write_text('# Changelog\n\n## Unreleased\n\n- Pending improvement.\n\n## 0.2.0 — 2026-11-17\n\nOld notes.\n')
        self.commit('feat: initial source')
        self.git('tag', 'v0.2.0')

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], text=True).strip()

    def commit(self, title):
        self.git('add', '--all')
        self.git('commit', '--allow-empty', '-m', title)

    def test_preview_is_read_only_and_apply_updates_only_release_metadata(self):
        self.commit('fix: correct final arrival')
        before = (self.repo / 'pubspec.yaml').read_text()
        plan = build_plan(self.repo, 'auto', '2026-11-17')
        self.assertEqual(plan['version'], '0.2.1')
        self.assertEqual(plan['tag'], 'v0.2.1')
        self.assertEqual((self.repo / 'pubspec.yaml').read_text(), before)
        apply_plan(self.repo, plan)
        self.assertIn('version: 0.2.1\n', (self.repo / 'pubspec.yaml').read_text())
        log = (self.repo / 'CHANGELOG.md').read_text()
        self.assertIn('## 0.2.1 — 2026-11-17', log)
        self.assertIn('Pending improvement.', log)
        self.assertIn('Old notes.', log)
        self.assertEqual(set(self.git('diff', '--name-only').splitlines()), {'pubspec.yaml', 'CHANGELOG.md'})
        with self.assertRaises(ValueError):
            apply_plan(self.repo, plan)

    def test_docs_do_not_release_and_manual_patch_can_include_them(self):
        self.commit('docs: refresh diagrams')
        skipped = build_plan(self.repo, 'auto', '2026-11-17')
        self.assertFalse(skipped['changed'])
        apply_plan(self.repo, skipped)
        self.assertEqual(self.git('status', '--porcelain'), '')
        plan = build_plan(self.repo, 'patch', '2026-11-17')
        self.assertTrue(plan['changed'])
        self.assertEqual(plan['version'], '0.2.1')

    def test_minor_release_and_retry_do_not_bump_twice(self):
        self.commit('feat: add a controller')
        plan = build_plan(self.repo, 'auto', '2026-11-17')
        self.assertEqual(plan['version'], '0.3.0')
        apply_plan(self.repo, plan)
        self.commit('chore(release): 0.3.0 [skip release]')
        self.git('tag', 'v0.3.0')
        self.assertFalse(build_plan(self.repo, 'auto', '2026-11-17')['changed'])

    def test_dirty_or_stale_checkout_is_rejected(self):
        self.commit('fix: repair')
        plan = build_plan(self.repo, 'auto', '2026-11-17')
        (self.repo / 'pubspec.yaml').write_text('name: steering_engine\nversion: 9.9.9\n')
        with self.assertRaises(ValueError):
            build_plan(self.repo, 'auto', '2026-11-17')
        with self.assertRaises(ValueError):
            apply_plan(self.repo, plan)
        self.git('checkout', '--', 'pubspec.yaml')
        self.commit('docs: move head')
        with self.assertRaises(ValueError):
            apply_plan(self.repo, plan)

    def test_missing_base_tag_and_colliding_next_tag_are_rejected(self):
        self.commit('fix: repair')
        self.git('tag', 'v0.2.1')
        with self.assertRaises(ValueError):
            build_plan(self.repo, 'auto', '2026-11-17')
        self.git('tag', '-d', 'v0.2.1', 'v0.2.0')
        with self.assertRaises(ValueError):
            build_plan(self.repo, 'patch', '2026-11-17')

    def test_late_tag_creation_is_rejected_before_applying_metadata(self):
        self.commit('fix: repair')
        plan = build_plan(self.repo, 'auto', '2026-11-17')
        self.git('tag', 'v0.2.1')
        with self.assertRaises(ValueError):
            apply_plan(self.repo, plan)
        self.assertIn('version: 0.2.0', (self.repo / 'pubspec.yaml').read_text())

    def test_base_tag_from_unrelated_history_is_rejected(self):
        self.git('checkout', '--orphan', 'unrelated')
        self.commit('fix: unrelated root with the same version text')
        with self.assertRaises((ValueError, subprocess.CalledProcessError)):
            build_plan(self.repo, 'auto', '2026-11-17')
        self.assertEqual(self.git('status', '--porcelain'), '')

    def test_breaking_policy_is_applied_through_the_release_plan(self):
        self.commit('feat!: replace the API')
        self.assertEqual(build_plan(self.repo, 'auto', '2026-11-17')['version'], '0.3.0')
        self.assertEqual(build_plan(self.repo, 'major', '2026-11-17')['version'], '1.0.0')

    def test_missing_notes_use_ordered_commit_summaries(self):
        (self.repo / 'CHANGELOG.md').write_text('# Changelog\n\n## Unreleased\n\n## 0.2.0\n\nOld notes.\n')
        self.commit('fix: first correction')
        self.commit('fix: second correction')
        plan = build_plan(self.repo, 'auto')
        self.assertLess(plan['notes'].index('first correction'), plan['notes'].index('second correction'))
        self.assertIn('Old notes.', plan['changelog'])
        (self.repo / 'CHANGELOG.md').write_text('# Changelog\nNo release section\n')
        self.commit('docs: remove heading')
        with self.assertRaises(ValueError):
            build_plan(self.repo, 'auto')

    def test_invalid_package_metadata_is_rejected(self):
        for text in ['name: another_package\nversion: 0.2.0\n',
                     'name: steering_engine\nversion: 0.2\n',
                     'name: steering_engine\nversion: 0.2.0\nversion: 0.3.0\n']:
            (self.repo / 'pubspec.yaml').write_text(text)
            with self.assertRaises(ValueError):
                package_version(self.repo)

    def test_cli_preview_and_apply_export_reviewable_json_and_notes(self):
        self.commit('fix: correction')
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'plan.json'
            notes = Path(folder) / 'notes.md'
            argv = ['release_bump.py', '--repo', str(self.repo), '--bump', 'patch',
                    '--output', str(output), '--notes', str(notes)]
            with patch('sys.argv', argv), redirect_stdout(io.StringIO()):
                main()
            self.assertEqual(json.loads(output.read_text())['version'], '0.2.1')
            self.assertIn('Pending improvement.', notes.read_text())
            self.assertEqual(package_version(self.repo), '0.2.0')
            with patch('sys.argv', argv + ['--apply']), redirect_stdout(io.StringIO()):
                main()
            self.assertEqual(package_version(self.repo), '0.2.1')

    def test_cli_no_release_does_not_write_notes(self):
        self.commit('docs: guide only')
        with tempfile.TemporaryDirectory() as folder:
            notes = Path(folder) / 'notes.md'
            argv = ['release_bump.py', '--repo', str(self.repo), '--notes', str(notes)]
            output = io.StringIO()
            with patch('sys.argv', argv), redirect_stdout(output):
                main()
            self.assertFalse(json.loads(output.getvalue())['changed'])
            self.assertFalse(notes.exists())
            self.assertEqual(self.git('status', '--porcelain'), '')


if __name__ == '__main__':
    unittest.main()

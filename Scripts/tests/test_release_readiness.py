"""Regression coverage for App Store export signature checks."""
import importlib.util
import json
import plistlib
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / 'check-release-readiness.py'
SPEC = importlib.util.spec_from_file_location('release_readiness', SCRIPT)
readiness = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(readiness)


class SigningTests(unittest.TestCase):
    def check_signature(self, authority='Apple Distribution: Example (TEAM123)',
                        *, adhoc=False, trusted=True, entitlements=None,
                        valid_signature=True):
        if entitlements is None:
            entitlements = {
                'com.apple.security.app-sandbox': True,
                'com.apple.developer.team-identifier': 'TEAM123',
            }
        signing = f'Authority={authority}\n' if authority else ''
        if adhoc:
            signing += 'Signature=adhoc\n'

        def run(command, **kwargs):
            if '--test-requirement' in command:
                if not trusted:
                    raise subprocess.CalledProcessError(3, command)
                return subprocess.CompletedProcess(command, 0, b'', b'')
            if '--verify' in command:
                if not valid_signature:
                    raise subprocess.CalledProcessError(1, command)
                return subprocess.CompletedProcess(command, 0, b'', b'')
            if '-dv' in command:
                return subprocess.CompletedProcess(command, 0, '', signing)
            if '--entitlements' in command:
                # Current codesign defaults to human-readable output without --xml.
                raw = plistlib.dumps(entitlements) if '--xml' in command else b'[Dict]\n'
                return subprocess.CompletedProcess(command, 0, raw, b'')
            self.fail(f'Unexpected command: {command}')

        with patch.object(readiness.subprocess, 'run', side_effect=run) as runner:
            problems = readiness.check_signing(Path('/tmp/KeepAwake.app'))
        return problems, runner.call_args_list

    def test_accepts_apple_trusted_store_distribution_certificates(self):
        for prefix in ('Apple Distribution: ', '3rd Party Mac Developer Application: ',
                       'Mac App Distribution: '):
            with self.subTest(prefix=prefix):
                problems, calls = self.check_signature(prefix + 'Example (TEAM123)')
                self.assertEqual(problems, [])
                requirements = [call.args[0] for call in calls
                                if '--test-requirement' in call.args[0]]
                self.assertEqual(len(requirements), 1)
                self.assertIn('=anchor apple generic', requirements[0])

    def test_rejects_developer_id_and_development_signatures(self):
        for authority in ('Developer ID Application: Example (TEAM123)',
                          'Apple Development: Example (TEAM123)',
                          'Mac Developer: Example (TEAM123)'):
            with self.subTest(authority=authority):
                problems, _ = self.check_signature(authority)
                self.assertTrue(any('not an App Store distribution' in p for p in problems))

    def test_rejects_adhoc_signatures(self):
        problems, _ = self.check_signature('', adhoc=True)
        self.assertTrue(any('ad-hoc signed' in p for p in problems))

    def test_rejects_missing_or_empty_certificate_identity(self):
        for authority in ('', 'Apple Distribution: '):
            with self.subTest(authority=authority):
                problems, _ = self.check_signature(authority)
                self.assertTrue(problems)

    def test_rejects_distribution_name_without_apple_trust(self):
        problems, _ = self.check_signature(trusted=False)
        self.assertTrue(any('Signature/entitlements check failed' in p for p in problems))

    def test_rejects_invalid_signature(self):
        problems, _ = self.check_signature(valid_signature=False)
        self.assertTrue(problems)

    def test_rejects_missing_sandbox_or_team(self):
        problems, _ = self.check_signature(entitlements={})
        self.assertIn('App Sandbox must be enabled.', problems)
        self.assertIn('A distribution signing team is missing.', problems)

    def test_rejects_debugging_entitlements(self):
        for key in ('com.apple.security.get-task-allow', 'get-task-allow'):
            with self.subTest(key=key):
                problems, _ = self.check_signature(entitlements={
                    'com.apple.security.app-sandbox': True,
                    'com.apple.developer.team-identifier': 'TEAM123',
                    key: True,
                })
                self.assertIn('A distribution build must not allow debugging.', problems)


class StoreMetadataTests(unittest.TestCase):
    def check_copy(self, entries, languages=('en',)):
        with patch.object(readiness.Path, 'read_text', return_value=json.dumps({'localizations': entries})):
            return readiness.check_store_metadata(languages)

    def entry(self):
        return dict(name='Keep Awake', subtitle='Keep your Mac awake',
                    keywords='sleep,display', description='A menu bar utility.')

    def test_valid_copy_is_independent_of_app_string_catalog(self):
        self.assertEqual(self.check_copy({'en': self.entry()}), [])

    def test_missing_language_blocks_release(self):
        problems = self.check_copy({'en': self.entry()}, languages=('en', 'zh-Hans'))
        self.assertTrue(any('supported app languages' in p for p in problems))

    def test_keywords_use_utf8_bytes_and_empty_copy_blocks_release(self):
        entry = self.entry()
        entry.update(keywords='字' * 34, description=' ')
        problems = self.check_copy({'en': entry})
        self.assertTrue(any('en/keywords' in p for p in problems))
        self.assertTrue(any('en/description' in p for p in problems))


if __name__ == '__main__':
    unittest.main()

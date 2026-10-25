#!/usr/bin/env python3
"""Read-only preflight for a signed Mac App Store export. Exits 1 on blockers."""
import argparse
import importlib.util
import json
import plistlib
import subprocess
from pathlib import Path
from urllib.parse import urlparse

APP_STORE_CERTIFICATE_PREFIXES = (
    'Apple Distribution: ',
    '3rd Party Mac Developer Application: ',
    'Mac App Distribution: ',
)


def check_signing(app):
    """Require an Apple-trusted submission certificate, not just a valid signature.

    Developer ID and development certificates also have a Team ID and can sign
    sandboxed apps. They cannot substitute for an App Store submission identity.
    The Apple anchor check prevents accepting a self-signed lookalike certificate.
    """
    problems = []
    try:
        subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)], check=True, capture_output=True)
        signing = subprocess.run(['/usr/bin/codesign', '-dv', '--verbose=4', str(app)], check=True, capture_output=True, text=True).stderr
        authority = next((line.removeprefix('Authority=') for line in signing.splitlines()
                          if line.startswith('Authority=')), '')
        if 'Signature=adhoc' in signing:
            problems.append('The app is ad-hoc signed; export with Mac App Store distribution signing.')
        elif not any(authority.startswith(prefix) and authority[len(prefix):].strip()
                     for prefix in APP_STORE_CERTIFICATE_PREFIXES):
            problems.append('The signing certificate is not an App Store distribution certificate '
                            f'({authority or "missing signing authority"}). Export for App Store Connect; '
                            'Developer ID and development signing are not accepted.')
        else:
            subprocess.run(['/usr/bin/codesign', '--verify', '--strict', '--test-requirement',
                            '=anchor apple generic', str(app)], check=True, capture_output=True)
        raw = subprocess.run(['/usr/bin/codesign', '-d', '--entitlements', '-', '--xml', str(app)], check=True, capture_output=True).stdout
        entitlements = plistlib.loads(raw)
        if not entitlements.get('com.apple.security.app-sandbox'):
            problems.append('App Sandbox must be enabled.')
        if not entitlements.get('com.apple.developer.team-identifier'):
            problems.append('A distribution signing team is missing.')
        if entitlements.get('com.apple.security.get-task-allow') or entitlements.get('get-task-allow'):
            problems.append('A distribution build must not allow debugging.')
    except (subprocess.CalledProcessError, plistlib.InvalidFileException, ValueError) as error:
        problems.append(f'Signature/entitlements check failed: {error}')
    return problems


def check_store_metadata(languages):
    """Store copy is maintained separately from in-app translations."""
    metadata = Path(__file__).resolve().parents[1] / 'docs/app-store/localizations.json'
    entries = json.loads(metadata.read_text())['localizations']
    problems = []
    if set(entries) != set(languages):
        problems.append('Store copy must cover the supported app languages.')
    for language, entry in entries.items():
        for field, limit in [('name', 30), ('subtitle', 30), ('keywords', 100), ('description', 4000)]:
            value = entry.get(field, '')
            length = len(value.encode('utf-8')) if field == 'keywords' else len(value)
            if not value.strip() or length > limit:
                problems.append(f'Store copy {language}/{field} is empty or exceeds {limit}.')
    return problems


def main(app):
    problems = []
    with (app / 'Contents/Info.plist').open('rb') as handle:
        info = plistlib.load(handle)
    if info.get('KeepAwakeDistribution') != 'AppStore':
        problems.append('Use the KeepAwake-AppStore scheme / AppStore archive configuration.')
    if not info.get('NSHumanReadableCopyright', '').strip():
        problems.append('Set KEEP_AWAKE_COPYRIGHT to the actual rights holder and year.')
    for key, setting in [('KeepAwakePrivacyPolicyURL', 'KEEP_AWAKE_PRIVACY_URL'), ('KeepAwakeSupportURL', 'KEEP_AWAKE_SUPPORT_URL')]:
        url = urlparse(info.get(key, ''))
        if url.scheme != 'https' or not url.hostname or url.hostname in {'localhost', 'example.com', 'example.org', 'example.net'} or '$(' in url.geturl():
            problems.append(f'Set {setting} to the actual public HTTPS page.')
    problems.extend(check_signing(app))
    spec = importlib.util.spec_from_file_location('localization_check', Path(__file__).with_name('verify-localizations.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    try:
        module.check(app)
    except (AssertionError, FileNotFoundError, subprocess.CalledProcessError) as error:
        problems.append(f'Localization/resource check failed: {error}')
    try:
        problems.extend(check_store_metadata(module.LANGUAGES))
    except (OSError, ValueError, KeyError) as error:
        problems.append(f'Store metadata check failed: {error}')
    for problem in problems:
        print(f'BLOCKER: {problem}')
    if not problems:
        print('PASS: local checks. Still verify live URLs, screenshots, prices, account agreements and TestFlight before submission.')
    return 1 if problems else 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    raise SystemExit(main(parser.parse_args().app.resolve()))

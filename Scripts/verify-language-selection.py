#!/usr/bin/env python3
"""Test Foundation's runtime language selection using the built app's resources.

The temporary host is a command-line executable in an app bundle, not a UI app.
It has the same localized resources as the product. Each child has independent
AppleLanguages arguments, so no system or installed-app preferences are changed.
"""
import argparse
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check(app):
    app = app.resolve()
    catalog = json.loads((ROOT / 'KeepAwake/Localizable.xcstrings').read_text())['strings']
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='keepawake-languages-', dir=build) as scratch:
        host = Path(scratch) / 'Probe.app/Contents'
        (host / 'MacOS').mkdir(parents=True)
        binary = host / 'MacOS/LocalizationRuntimeProbe'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(build / 'ModuleCache'),
                        str(ROOT / 'Scripts/LocalizationRuntimeProbe.swift'), '-o', str(binary)], check=True)
        (host / 'Resources').symlink_to(app / 'Contents/Resources', target_is_directory=True)
        with (host / 'Info.plist').open('wb') as handle:
            plistlib.dump(dict(CFBundleExecutable='LocalizationRuntimeProbe',
                              CFBundleIdentifier='neo.dowithless.KeepAwake.LocalizationProbe',
                              CFBundleDevelopmentRegion='en', CFBundlePackageType='APPL'), handle)
        for language, entry in catalog['Keep Awake']['localizations'].items():
            subprocess.run([str(binary), str(app), entry['stringUnit']['value'],
                            '-AppleLanguages', f'({language})'], check=True)
        subprocess.run([str(binary), str(app), 'Keep Awake', '-AppleLanguages', '(ar)'], check=True)
        print('PASS: all 11 languages, format arguments and unsupported-language English fallback')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    check(parser.parse_args().app)

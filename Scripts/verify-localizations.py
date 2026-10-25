#!/usr/bin/env python3
"""Check source/catalog coverage and, optionally, actual compiled app resources."""
import argparse
import json
import plistlib
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {'en', 'zh-Hans', 'zh-Hant', 'ja', 'ko', 'de', 'fr', 'es', 'pt-BR', 'ru', 'it'}


def check(app=None):
    catalog = json.loads((ROOT / 'KeepAwake/Localizable.xcstrings').read_text())
    assert catalog['sourceLanguage'] == 'en'
    strings = catalog['strings']
    sources = set()
    for path in (ROOT / 'KeepAwake').glob('*.swift'):
        for literal in re.findall(r'L10n\.(?:text|format)\("((?:[^"\\]|\\.)*)"', path.read_text()):
            sources.add(json.loads('"' + literal + '"'))
    assert sources == set(strings), f'Source/catalog mismatch: {sources ^ set(strings)}'
    for key, entry in strings.items():
        assert set(entry['localizations']) == LANGUAGES, key
        for language, translation in entry['localizations'].items():
            unit = translation['stringUnit']
            assert unit['state'] == 'translated' and unit['value'].strip(), (key, language)
            assert key.count('%@') == unit['value'].count('%@'), (key, language, 'placeholders')
            assert key.count('\n') == unit['value'].count('\n'), (key, language, 'line breaks')
    if app:
        resources = app / 'Contents/Resources'
        for language in sorted(LANGUAGES):
            path = resources / f'{language}.lproj/Localizable.strings'
            assert path.is_file(), path
            compiled = json.loads(subprocess.check_output(['/usr/bin/plutil', '-convert', 'json', '-o', '-', str(path)]))
            for key, entry in strings.items():
                assert compiled.get(key) == entry['localizations'][language]['stringUnit']['value'], (language, key)
        with (app / 'Contents/Info.plist').open('rb') as handle:
            info = plistlib.load(handle)
        assert info['CFBundleDevelopmentRegion'] == 'en'
        assert info['LSMinimumSystemVersion'] == '13.0'
        assert info['LSUIElement'] is True
        with (resources / 'PrivacyInfo.xcprivacy').open('rb') as handle:
            privacy = plistlib.load(handle)
        assert privacy['NSPrivacyTracking'] is False
        assert privacy['NSPrivacyCollectedDataTypes'] == []
    print(f'PASS: {len(strings)} strings × {len(LANGUAGES)} languages; source, formats' +
          (', compiled resources and app metadata' if app else ''))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path)
    check(parser.parse_args().app)

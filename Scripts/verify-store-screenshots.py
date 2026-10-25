#!/usr/bin/env python3
"""Check localized PNG exports and preserve approved Chinese reference hashes."""

import argparse
import hashlib
import json
from pathlib import Path
import struct
import zlib


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs/app-store/screenshots"
COPY = ROOT / "docs/app-store/screenshot-copy.json"
MANIFEST = ASSETS / "verification.json"
ORDER = ["01-keep-awake", "02-display-sleep", "03-manual-sleep", "04-simple", "05-open-source"]


def check_png(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {path}"
    offset = 8
    tags = []
    while offset < len(data):
        length, tag = struct.unpack_from(">I4s", data, offset)
        payload = data[offset + 8:offset + 8 + length]
        expected_crc = struct.unpack_from(">I", data, offset + 8 + length)[0]
        assert zlib.crc32(tag + payload) == expected_crc, f"Corrupt PNG chunk: {path}"
        if tag == b"IHDR":
            width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
            assert (width, height, depth, color) == (2560, 1600, 8, 2), f"Expected 2560x1600, 8-bit RGB: {path}"
        tags.append(tag)
        offset += length + 12
    assert tags[0] == b"IHDR" and tags[-1] == b"IEND", f"Incomplete PNG: {path}"
    assert b"sRGB" in tags, f"Missing sRGB profile declaration: {path}"
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--update-manifest", action="store_true",
                        help="Record current exports after reviewing copy/layout; Chinese reference hashes stay fixed.")
    args = parser.parse_args()
    copies = json.loads(COPY.read_text())
    catalog = json.loads((ROOT / "KeepAwake/Localizable.xcstrings").read_text())["strings"]
    previous = json.loads(MANIFEST.read_text())
    previous_files = {item["file"]: item for item in previous["files"]}
    records = []
    for locale, screens in copies.items():
        assert list(screens) == ORDER, f"Wrong copy order: {locale}"
        directory = ASSETS / locale
        assert [path.stem for path in sorted(directory.glob("*.png"))] == ORDER, f"Missing or extra PNGs: {locale}"
        for name in ORDER:
            copy = screens[name]
            reference = copies["zh-Hans"][name]
            for field in ["preventDisplaySleep", "isEnabled"]:
                assert copy.get(field) == reference.get(field), f"Control state differs: {locale}/{name}"
            for key in ["Keep Awake", "Keep Display Awake", "Launch at Login", "About & Help…", "Quit Keep Awake"]:
                value = catalog[key]["localizations"][copy["menuLocale"]]["stringUnit"]["value"]
                assert value, f"Missing localized menu string: {locale}/{key}"
            path = directory / (name + ".png")
            relative = path.relative_to(ASSETS).as_posix()
            sha = check_png(path)
            record = {"file": relative, "sha256": sha, "dimensions": [2560, 1600], "mode": "RGB"}
            if locale == "zh-Hans":
                confirmed = previous_files[relative]["confirmedChineseSHA256"]
                assert sha == confirmed, f"Approved Chinese image changed: {relative}"
                record.update(confirmedChineseSHA256=confirmed, matchesConfirmedChinese=True)
            if not args.update_manifest:
                assert relative in previous_files, f"Not yet recorded: {relative}; review and use --update-manifest"
                assert sha == previous_files[relative]["sha256"], f"Export differs from recorded version: {relative}"
            records.append(record)
    if args.update_manifest:
        previous.update(locales=list(copies), imageCount=len(records), files=records, order=ORDER,
                        localizedReview="All layouts inspected; localized copy available for user review")
        MANIFEST.write_text(json.dumps(previous, indent=2) + "\n")
    print(f"PASS: {len(copies)} locales × 5 PNGs; dimensions, RGB, sRGB, CRC, order, menu coverage, states and approved Chinese hashes")


if __name__ == "__main__":
    main()

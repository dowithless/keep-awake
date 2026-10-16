#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_dir="$(mktemp -d "${TMPDIR:-/tmp}/keepawake-live.XXXXXX")"
trap 'rm -rf "$probe_dir"' EXIT

cd "$project_dir"
xcrun swiftc -parse-as-library -swift-version 5 \
  -module-cache-path "$probe_dir/ModuleCache" \
  KeepAwake/SleepAssertionManager.swift Scripts/LiveAssertionProbe.swift \
  -o "$probe_dir/KeepAwakeLiveProbe"
"$probe_dir/KeepAwakeLiveProbe"

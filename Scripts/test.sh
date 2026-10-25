#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
export CLANG_MODULE_CACHE_PATH="$project_dir/build/SwiftModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/build/SwiftModuleCache"
swift test --disable-sandbox --scratch-path build/SwiftPM \
  --cache-path build/SwiftPMCache --config-path build/SwiftPMConfig \
  --security-path build/SwiftPMSecurity "$@"

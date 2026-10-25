#!/bin/bash
set -euo pipefail

# Store assets live outside the application target and are not bundled with it.
cd "$(dirname "$0")/.."
mkdir -p build/ModuleCache build/tools
CLANG_MODULE_CACHE_PATH="$PWD/build/ModuleCache" xcrun swiftc \
    -module-cache-path "$PWD/build/ModuleCache" \
    Scripts/GenerateStoreScreenshot.swift -o build/tools/generate-store-screenshot

if [ "$#" -eq 0 ]; then
    set -- zh-Hans en-US zh-Hant ja ko de-DE fr-FR es-ES pt-BR ru it
fi

for language in "$@"; do
    for screen in 01-keep-awake 02-display-sleep 03-manual-sleep 04-simple 05-open-source; do
        build/tools/generate-store-screenshot "$language" "$screen"
    done
done

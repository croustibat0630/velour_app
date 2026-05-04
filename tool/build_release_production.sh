#!/usr/bin/env bash
# Builds release artifacts with Dart obfuscation (symbols in --split-debug-info).
# Store split-debug-info securely for deobfuscation of stack traces (Play / App Store).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="${ROOT}/build/app/debug-info"
mkdir -p "$OUT"

echo "== Android App Bundle (release + obfuscate) =="
flutter build appbundle --release --obfuscate --split-debug-info="$OUT"

echo "== iOS IPA (release + obfuscate; requires signing) =="
flutter build ipa --release --obfuscate --split-debug-info="$OUT"

echo "Debug symbols: $OUT"

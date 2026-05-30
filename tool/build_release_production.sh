#!/usr/bin/env bash
# Builds release artifacts with Dart obfuscation (symbols in --split-debug-info).
# Store split-debug-info securely for deobfuscation of stack traces (Play / App Store).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="${ROOT}/build/app/debug-info"
mkdir -p "$OUT"

PRIVACY="${VELOUR_PRIVACY_POLICY_URL:-https://elite-bumper-96a.notion.site/Politique-de-confidentialit-Velour-358a47fe395240689082ec65c556a1f2}"
DART_DEFINES=(
  --dart-define="VELOUR_PRIVACY_POLICY_URL=${PRIVACY}"
  --dart-define=VELOUR_ANALYTICS=true
)

echo "== Android App Bundle (release + obfuscate) =="
flutter build appbundle --release --obfuscate --split-debug-info="$OUT" "${DART_DEFINES[@]}"

echo "== iOS IPA (release + obfuscate; requires signing) =="
flutter build ipa --release --obfuscate --split-debug-info="$OUT" "${DART_DEFINES[@]}"

echo "Debug symbols: $OUT"

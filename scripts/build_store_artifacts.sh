#!/usr/bin/env bash
# Builds store : Android AAB + iOS IPA (release) avec les dart-defines attendus.
# Prérequis : Android `android/key.properties` + keystore pour une signature Play ;
#   iOS : certificats / profils Xcode (compte développeur).
#
# Usage :
#   ./scripts/build_store_artifacts.sh
# Surcharger l’URL (rare) :
#   VELOUR_PRIVACY_POLICY_URL='https://…' ./scripts/build_store_artifacts.sh
# Analytics : **activé par défaut** sur les builds store (funnel GA4 + Crashlytics).
# Désactiver explicitement : VELOUR_ANALYTICS=0 ./scripts/build_store_artifacts.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> pubspec (versionCode Android / CFBundleVersion iOS = nombre après « + »)"
grep '^version:' pubspec.yaml || true

PRIVACY="${VELOUR_PRIVACY_POLICY_URL:-https://elite-bumper-96a.notion.site/Politique-de-confidentialit-Velour-358a47fe395240689082ec65c556a1f2}"

DART_DEFINES=(--dart-define="VELOUR_PRIVACY_POLICY_URL=${PRIVACY}")
# Défaut = analytics ON (aligné politique + dimensions GA4). 0 / false pour exclure.
VELOUR_ANALYTICS_FLAG="${VELOUR_ANALYTICS:-1}"
if [[ "${VELOUR_ANALYTICS_FLAG}" != "0" && "${VELOUR_ANALYTICS_FLAG}" != "false" ]]; then
  DART_DEFINES+=(--dart-define=VELOUR_ANALYTICS=true)
  echo "==> dart-defines: privacy URL + VELOUR_ANALYTICS=true (désactiver: VELOUR_ANALYTICS=0)"
else
  echo "==> dart-defines: privacy URL only (VELOUR_ANALYTICS désactivé)"
fi

echo "==> flutter pub get"
flutter pub get

echo "==> Android appbundle (release)"
flutter build appbundle --release "${DART_DEFINES[@]}"

# Prépare build/native_assets/ios (sinon l’archive IPA peut échouer après un clean partiel).
echo "==> iOS device build (release, pré-archive)"
flutter build ios --release "${DART_DEFINES[@]}"

echo "==> iOS IPA (release, export App Store)"
flutter build ipa --release "${DART_DEFINES[@]}" --export-method app-store

echo ""
echo "Artefacts :"
echo "  Android: build/app/outputs/bundle/release/app-release.aab"
echo "  iOS:     build/ios/ipa/*.ipa"

#!/usr/bin/env bash
# Affiche les commandes flutter build store avec dart-defines attendus.
# Usage: ./scripts/echo_store_release_build.sh 'https://example.com/privacy'
set -euo pipefail
# Défaut = URL App Store Connect (voir VelourReleaseLinks.appStoreListingPrivacyPolicyUrl).
URL="${1:-https://elite-bumper-96a.notion.site/Politique-de-confidentialit-Velour-358a47fe395240689082ec65c556a1f2}"
echo "Android (AAB):"
echo "  flutter build appbundle --release \\"
echo "    --dart-define=VELOUR_PRIVACY_POLICY_URL=${URL}"
echo ""
echo "iOS (IPA):"
echo "  flutter build ipa --release \\"
echo "    --dart-define=VELOUR_PRIVACY_POLICY_URL=${URL}"
echo ""
echo "Optionnel (funnel GA4 + clé Crashlytics velour_analytics) :"
echo "  ... \\"
echo "    --dart-define=VELOUR_ANALYTICS=true"

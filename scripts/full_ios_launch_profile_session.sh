#!/usr/bin/env bash
# Installe et lance Velour sur iPhone, attend que l’app soit prête, créneau pour jouer.
# Par défaut : --release (fiable sans fil ; le profile nécessite souvent USB sur iOS 26).
#
# Usage :
#   ./scripts/full_ios_launch_profile_session.sh [device_id]
#   VELOUR_IOS_MODE=profile ./scripts/full_ios_launch_profile_session.sh   # mieux avec USB câblé
set -eo pipefail
cd "$(dirname "$0")/.."

RUN_MODE="${VELOUR_IOS_MODE:-release}"
case "$RUN_MODE" in release|profile) ;; *)
  echo "VELOUR_IOS_MODE doit être « release » ou « profile », pas « $RUN_MODE »"
  exit 1
  ;;
esac

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for x in d:
        if x.get('targetPlatform') == 'ios' and x.get('emulator') is False:
            print(x.get('id', ''))
            break
except Exception:
    pass
" || true)"
fi
if [[ -z "$DEVICE_ID" ]]; then
  echo "Aucun iPhone détecté. USB + déverrouillage, puis : flutter devices"
  exit 1
fi

TS="$(date +%Y%m%d_%H%M%S)"
OUT="${VELOUR_OUT:-velour_ios_session_${TS}.txt}"
PLAY_WINDOW_S="${VELOUR_PLAY_WINDOW_S:-180}"
rm -f "$OUT"
touch "$OUT"

echo "═══════════════════════════════════════════════════════════════"
echo "  Build + lancement « $RUN_MODE » sur : $DEVICE_ID"
echo "  Logs → $OUT"
echo "  Attends « APPLICATION PRÊTE », puis utilise l’iPhone."
if [[ "$RUN_MODE" == "profile" ]]; then
  echo "  Astuce sans fil : si ça échoue avec « Dart VM Service », branche USB ou passe en release."
fi
echo "═══════════════════════════════════════════════════════════════"

# Workaround: some setups output release apps to `build/ios/Release-iphoneos/Runner.app`
# while Flutter expects `build/ios/iphoneos/Runner.app`.
if [[ "$RUN_MODE" == "release" ]]; then
  mkdir -p build/ios
  ln -sfn "Release-iphoneos" "build/ios/iphoneos" 2>/dev/null || true
fi

# Optional extra args, e.g. `VELOUR_FLUTTER_RUN_ARGS="--dart-define=VELOUR_AUDIT=1"`
flutter run "--$RUN_MODE" -d "$DEVICE_ID" ${VELOUR_FLUTTER_RUN_ARGS:-} >>"$OUT" 2>&1 &
FPID=$!
disown "$FPID" 2>/dev/null || true

READY=0
for _ in $(seq 1 240); do
  if grep -qE "Flutter run key commands|^Application running" "$OUT" 2>/dev/null; then
    READY=1
    break
  fi
  if grep -qiE "Dart VM Service was not discovered" "$OUT" 2>/dev/null; then
    echo ""
    echo "► Échec : service de debug Dart introuvable (souvent sans fil + profile/debug)."
    echo "   Branche l’iPhone en USB puis relance, ou utilise le mode défaut release :"
    echo "   ./scripts/full_ios_launch_profile_session.sh $DEVICE_ID"
    tail -25 "$OUT"
    kill "$FPID" 2>/dev/null || true
    exit 1
  fi
  if grep -qiE "Error: No supported devices|Failed to build|BUILD FAILED|\\bCould not run\\b" "$OUT" 2>/dev/null; then
    echo "Échec détecté dans les logs :"
    tail -40 "$OUT"
    kill "$FPID" 2>/dev/null || true
    exit 1
  fi
  sleep 3
done

if [[ "$READY" -ne 1 ]]; then
  echo "Timeout : l’app n’est pas arrivée jusqu’au menu Flutter."
  tail -60 "$OUT"
  kill "$FPID" 2>/dev/null || true
  exit 1
fi

echo ""
echo "========== APPLICATION PRÊTE — PREND TON IPHONE =========="
echo "  ~${PLAY_WINDOW_S}s : parcours toute l’app (menus, shop, settings, tutorial, game over…)."
echo "==========================================================="
# Si la connexion device saute (USB/Wi‑Fi), on arrête tôt pour éviter un faux “ok”.
for _ in $(seq 1 "$PLAY_WINDOW_S"); do
  if grep -q "Lost connection to device" "$OUT" 2>/dev/null; then
    echo ""
    echo "⚠ Connexion perdue vers l’iPhone (USB débranché / tunnel cassé)."
    echo "Relance le script après avoir rebranché le câble."
    break
  fi
  sleep 1
done

echo ""
echo "────────── Extraits audio / erreurs (si présents) ──────────"
grep -E "VelourAudio|flutter:|\\[Velour|DarwinAudio|audioplay|AudioPlayer|Error launching" "$OUT" | tail -120 || true
if ! grep -q "VelourAudio" "$OUT" 2>/dev/null; then
  echo "(Pas de ligne [VelourAudio] dans $OUT — normal sur release ; ouvre le fichier entier ou branche USB + profile.)"
fi

echo ""
echo "flutter run ($RUN_MODE) tourne encore (pid $FPID). Stop : kill $FPID"
echo "Log complet : $OUT"

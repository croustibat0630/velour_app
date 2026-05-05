#!/usr/bin/env bash
# Capture les logs Flutter depuis un iPhone branché / appairé.
# Usage : ./scripts/capture_velour_ios_logs.sh [device_id] [durée_secondes]
set -eo pipefail
cd "$(dirname "$0")/.."
DEVICE_ID="${1:-}"
DURATION="${2:-45}"

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
  echo "Aucun iPhone détecté. Branche l’USB, déverrouille, puis : flutter devices"
  exit 1
fi

OUT="velour_logs_capture.txt"
rm -f "$OUT"
echo "═══════════════════════════════════════════════════════════════"
echo "  Enregistrement ${DURATION}s vers $OUT"
echo "  Appareil : $DEVICE_ID"
echo "  → Dans 5 secondes : ouvre Velour, menu, tape l’écran, joue."
echo "═══════════════════════════════════════════════════════════════"
sleep 5
# -c : repartir d’un buffer propre ; --device-timeout : iPhone parfois lent en sans-fil.
# Sortie sans "Alarm clock" : handler SIGALRM qui termine proprement.
perl -e '$SIG{ALRM} = sub { exit 0 }; alarm shift; exec @ARGV' "$DURATION" \
  flutter logs -c --device-timeout 120 -d "$DEVICE_ID" 2>&1 | tee "$OUT" || true
echo ""
echo "Terminé. Cherche [VelourAudio] dans $OUT ou envoie ce fichier."
if [[ ! -s "$OUT" ]] || [[ "$(wc -l < "$OUT" | tr -d " ")" -le 2 ]]; then
  echo ""
  echo "⚠ Peu ou pas de lignes : ouvre un 2ᵉ terminal et lance :"
  echo "  flutter run --profile -d \"$DEVICE_ID\""
  echo "Les print Dart ([VelourAudio]) y sont en général mieux visibles que dans flutter logs seul."
fi

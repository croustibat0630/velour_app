#!/usr/bin/env bash
# Flux « propre » : export du haut du classement → tu remplis uids-a-supprimer.txt → delete (dry-run puis execute).
# Prérequis : depuis le dossier functions/, avec npm ci déjà fait.
set -euo pipefail

FUNCS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FUNCS_ROOT"

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  echo "Erreur : exporte GOOGLE_APPLICATION_CREDENTIALS vers le JSON du compte de service (projet cible, ex. velour-6690f)." >&2
  exit 1
fi
if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "Erreur : fichier introuvable : $GOOGLE_APPLICATION_CREDENTIALS" >&2
  exit 1
fi

mkdir -p scripts/.local
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="scripts/.local/leaderboard-top-${STAMP}.json"

node scripts/exportLeaderboardTopAdmin.js --limit=30 --out="$OUT" >/dev/null

echo "Snapshot classement écrit : $OUT"
echo ""
echo "Étapes suivantes :"
echo "  1. Ouvre ce JSON, repère les uid de comptes test."
echo "  2. Crée ou édite scripts/uids-a-supprimer.txt (une ligne = un uid ; # = commentaire)."
echo "  3. Simulation : npm run admin:delete-players -- --uids-file=scripts/uids-a-supprimer.txt --verbose"
echo "  4. Application : npm run admin:delete-players -- --uids-file=scripts/uids-a-supprimer.txt --execute --verbose"
echo "  (Optionnel Auth irréversible : ajouter --with-auth à l’étape 4.)"
echo ""

# Contribuer à Velour

## Prérequis

- Flutter (SDK compatible `pubspec.yaml`), Dart SDK.
- Pour les Cloud Functions : Node 20+, `npm ci` dans `functions/`.

## Qualité avant commit

- `dart analyze`
- `flutter test`
- `dart format --set-exit-if-changed .` (aligné sur la CI)

## Git : après changements importants

1. Regrouper des changements **cohérents** (une intention par commit quand c’est possible).
2. Message de commit **explicite** (ex. `feat: …`, `fix: …`, `refactor: …`, `docs: …`).
3. Pousser vers `origin` une fois le lot stable pour ne pas laisser la branche locale trop en avance.

La CI (`.github/workflows/flutter_ci.yml`) exécute analyse, tests, format et compilation des Functions.

## Documentation prod / Firebase

Voir `docs/PRODUCTION_HARDENING.md` pour règles Firestore, callables et checklists de déploiement.

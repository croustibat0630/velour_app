# Checklist soumission stores (Velour)

## Version & builds

- [ ] Incrémenter `version: x.y.z+N` dans `pubspec.yaml` (le `+N` est obligatoire pour Play / App Store).
- [ ] `flutter pub get` puis builds release : Android App Bundle, iOS archive.

## Légal & métadonnées

- [ ] Passer `--dart-define=VELOUR_PRIVACY_POLICY_URL=https://…` sur **chaque** build store (voir `lib/utils/velour_release_links.dart`).
- [ ] Politique de confidentialité et CGU à jour ; âge / contenu cohérents avec le jeu.
- [ ] Achats intégrés : produits actifs en sandbox (iOS) / licence test (Android) ; textes boutique alignés sur la console.

## Qualité & accessibilité

- [ ] Parcours froid : splash → menu → préparation → partie → pause → menu (appareil réel iOS + Android).
- [ ] Activer **Réduire les mouvements** (iOS) / équivalent : vérifier que le jeu reste lisible et jouable.
- [ ] VoiceOver / TalkBack : menu principal, préparation (choix de mise, confirmer), bouton pause, **gemmes du plateau** (forme + couleur annoncées).

## Firebase & backend

- [ ] Remote Config publié (valeurs prod) ; règles Firestore / Functions cohérentes avec la build.
- [ ] App Check : configuration release (pas de provider debug en production).

## Post-soumission

- [ ] Surveiller Crashlytics et avis J1–J7 pour ajuster RC si besoin.

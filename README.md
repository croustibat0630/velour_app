# Velour (`velour_app`)

Puzzle néon Flutter (Firebase : auth, Firestore, Remote Config, App Check, Crashlytics, Analytics optionnel, Functions).

## Documentation projet

- **Soumission stores** : [`docs/STORE_RELEASE_CHECKLIST.md`](docs/STORE_RELEASE_CHECKLIST.md) (parcours iOS/Android, VoiceOver/TalkBack, Réduire les mouvements, RC, App Check, `VELOUR_PRIVACY_POLICY_URL`).
- **Durcissement prod** : [`docs/PRODUCTION_HARDENING.md`](docs/PRODUCTION_HARDENING.md).
- **Observabilité J1–J7** : [`docs/OBSERVABILITY_J1.md`](docs/OBSERVABILITY_J1.md) (filtres Crashlytics `[VEL_OBS]`, clés custom, boucle RC).

## Développement

```bash
flutter pub get
dart analyze
flutter test
```

Build store (exemple Android) :

```bash
flutter build appbundle --release \
  --dart-define=VELOUR_PRIVACY_POLICY_URL=https://elite-bumper-96a.notion.site/Politique-de-confidentialit-Velour-358a47fe395240689082ec65c556a1f2
# Funnel (opt-in légal) : ajouter --dart-define=VELOUR_ANALYTICS=true
# URL canonique : VelourReleaseLinks.appStoreListingPrivacyPolicyUrl (velour_release_links.dart)
```

Ressources Flutter : [documentation](https://docs.flutter.dev/).

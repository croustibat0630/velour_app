# Velour (`velour_app`)

Puzzle néon Flutter (Firebase : auth, Firestore, Remote Config, App Check, Crashlytics, Analytics sur builds store par défaut, Functions).

## Documentation projet

- **Soumission stores** : [`docs/STORE_RELEASE_CHECKLIST.md`](docs/STORE_RELEASE_CHECKLIST.md) (parcours iOS/Android, VoiceOver/TalkBack, Réduire les mouvements, RC, App Check, `VELOUR_PRIVACY_POLICY_URL` + `VELOUR_ANALYTICS=true` par défaut).
- **Durcissement prod** : [`docs/PRODUCTION_HARDENING.md`](docs/PRODUCTION_HARDENING.md).
- **Observabilité J1–J7** : [`docs/OBSERVABILITY_J1.md`](docs/OBSERVABILITY_J1.md) (filtres Crashlytics `[VEL_OBS]`, clés custom, boucle RC).
- **CI compile store (manuel)** : workflow GitHub *Store release compile check* (AAB release + privacy + Analytics, voir `.github/workflows/store_release_compile.yml`).

## Développement

```bash
flutter pub get
dart analyze
flutter test
```

Build store **Android + iOS** (AAB + IPA, mêmes dart-defines) :

```bash
./scripts/build_store_artifacts.sh
```

Équivalent manuel (Android ; mêmes `--dart-define` que le script store) :

```bash
flutter build appbundle --release \
  --dart-define=VELOUR_PRIVACY_POLICY_URL=https://elite-bumper-96a.notion.site/Politique-de-confidentialit-Velour-358a47fe395240689082ec65c556a1f2 \
  --dart-define=VELOUR_ANALYTICS=true
# URL canonique : VelourReleaseLinks.appStoreListingPrivacyPolicyUrl (velour_release_links.dart)
# Sans Analytics : omettre la 2e ligne ou VELOUR_ANALYTICS=0 ./scripts/build_store_artifacts.sh
```

Ressources Flutter : [documentation](https://docs.flutter.dev/).

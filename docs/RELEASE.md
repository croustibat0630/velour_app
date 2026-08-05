# RELEASE — 1.2.3+21

**Date dépôt :** 2026-08-05  
**Tag :** `release-1.2.3+21`  
**Contenu :** Activation P0 + Sprint 2 funnel + analytics store

---

## Checklist Release

- [x] bump marketing `1.2.3` + build `+21`
- [x] notes store (5 locales) alignées
- [x] `dart format --set-exit-if-changed .`
- [x] `dart analyze --fatal-infos`
- [x] `flutter test`
- [x] `flutter build web --release --no-wasm-dry-run -O2`
- [x] `cd functions && npm ci && npm run build`
- [x] AAB release (`VELOUR_ANALYTICS=true` + privacy URL) — **2026-08-05**
- [x] iOS archive 1.2.3 (21) — **export IPA : action humaine Xcode** (PLA / certificat Distribution)
- [ ] upload **Play Console** (AAB prêt)
- [ ] upload **App Store Connect** (via Xcode Organizer → Distribute)
- [ ] coller Nouveautés / Release notes depuis `docs/store_listings/`
- [ ] Firebase : vérifier Analytics/Crashlytics sur build Release après install

---

## Contenu binaire

- Activation P0 : COMMENCER 1ʳᵉ fois → narratif Perfect → free casual
- Sprint 2 : funnel `velour_ftue_*` + `perfect_before_quit` (PBR)
- Fix build iOS : Pods `IPHONEOS_DEPLOYMENT_TARGET` ≥ 15.0 (`ios/Podfile`)

**Pas inclus :** Packaging (icône / captures / vidéo).

---

## Hypothèse

Le FTUE sur le chemin COMMENCER augmente le **PBR** (et Second Run) vs la baseline store 1.2.2.

## Succès (N ≥ 30, idéalement ~100 first launch)

- PBR **+15 pts**
- Second Run Rate **+10 pts**
- FTUE Completed cohérent avec le PBR

## Kill

Aucune amélioration nette après **~100 nouveaux joueurs** → hypothèse rejetée (journal Kill).

## KPI

North Star **PBR** · FTUE Completed · Second Run · N · Activation Score  
→ [`docs/PRODUCT_PLAYBOOK.md`](PRODUCT_PLAYBOOK.md)

## Artefacts

```text
Android (prêt) : build/app/outputs/bundle/release/app-release.aab
iOS archive    : build/ios/archive/Runner.xcarchive
  → open …/Runner.xcarchive dans Xcode → Distribute App → App Store Connect
```

Dart-defines : `VELOUR_PRIVACY_POLICY_URL` + `VELOUR_ANALYTICS=true`.

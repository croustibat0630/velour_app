# Checklist soumission stores (Velour)

Document **exécutable** : chaque case doit être cochée par une personne (ou notée date + initiales). Les **gates** bloquent une soumission « propre » ; le reste est du risque produit.

---

## 0. Ordre recommandé (avant la section 1)

À faire **dans cet ordre** réduit les allers-retours console / binaires :

1. **RC prod publié** + **App Check** enregistré pour les builds release (§4) — sinon les callables / fetch peuvent diverger du binaire que vous testez.
2. **URL privacy** figée + **builds** AAB/IPA avec `--dart-define=VELOUR_PRIVACY_POLICY_URL=…` (§1) — gate store et clé Crashlytics `velour_privacy_url_configured`.
3. **Passe appareils réels** iOS + Android : parcours froid, cash/prep/gemmes, Réduire les mouvements, VoiceOver, TalkBack (§3).
4. **Observabilité J1** : filtres / alertes Crashlytics + Logging ; funnel Analytics **seulement** si `VELOUR_ANALYTICS=true` et politique à jour (§5–6, `docs/OBSERVABILITY_J1.md`).

**Script** (affiche les commandes types avec votre URL) :

```bash
./scripts/echo_store_release_build.sh 'https://votre-domaine.example/politique-confidentialite'
```

### Livrables dépôt (hors gate store / humain)

- [x] Script `scripts/echo_store_release_build.sh` + checklist §0–§1 maintenues.
- [x] `docs/OBSERVABILITY_J1.md` (filtres `[VEL_OBS]`, clés custom, funnel Analytics opt-in `VELOUR_ANALYTICS`).

---

## 1. Version & builds

- [ ] Incrémenter `version: x.y.z+N` dans `pubspec.yaml` (le `+N` est obligatoire pour Play / App Store — voir règle équipe dans `.cursor/rules/git-workflow.mdc`).
- [x] `flutter pub get`
- [ ] Builds release signés / uploadables :
  - [x] **Android** : `flutter build appbundle --release` avec les `--dart-define` ci-dessous — **compile OK** (voir annexe A ; signature Play / upload à valider sur la machine de release).
  - [ ] **iOS** : `flutter build ipa` ou archive Xcode avec les mêmes `--dart-define` — **non rejoué ici** (annexe A : `pod install` / espace disque).

### Commandes types (copier-coller puis adapter l’URL privacy)

**Android (AAB)**

```bash
flutter build appbundle --release \
  --dart-define=VELOUR_PRIVACY_POLICY_URL=https://VOTRE_DOMAINE/politique-confidentialite
```

**iOS (IPA / archive)**

```bash
flutter build ipa --release \
  --dart-define=VELOUR_PRIVACY_POLICY_URL=https://VOTRE_DOMAINE/politique-confidentialite
```

**Funnel Firebase Analytics (optionnel, pas par défaut)** — mettre à jour la politique de confidentialité et activer explicitement au build :

```bash
# À ajouter aux lignes ci-dessus (même commande) :
#   --dart-define=VELOUR_ANALYTICS=true
```

Implémentation : `lib/services/velour_analytics.dart` (`velour_menu_view`, `velour_prep_open`, `velour_run_start` + `logAppOpen`).

**Web RC / debug App Check (hors store)** : voir `lib/velour_bootstrap.dart` (`VELOUR_APP_CHECK_WEB_SITE_KEY` si besoin).

Référence code : `lib/utils/velour_release_links.dart` — en **release**, une URL absente ou `example.com` déclenche un **avertissement console** ; les **clés Crashlytics** `velour_privacy_url_configured` / log `[VEL_OBS] j1_session_tag` aident le tri post-J1 (voir `docs/OBSERVABILITY_J1.md`).

---

## 2. Légal & métadonnées (gates)

- [ ] **Politique de confidentialité** : URL réelle, contenu à jour, accessible sans compte.
- [ ] **CGU** (si séparées) : lien présent dans la fiche store / l’app si requis par la juridiction.
- [ ] **Âge / contenu** : cohérents avec le questionnaire store (PEGI / etc.).
- [ ] **Achats intégrés** : produits actifs en **sandbox iOS** / **licence test Google Play** ; prix et libellés alignés sur les consoles ; parcours d’achat testé sur **vrai appareil** (pas seulement simulateur).

---

## 3. Qualité & accessibilité — **appareils réels iOS + Android**

Effectuer **au minimum une passe complète par OS** (téléphone milieu de gamme si possible). Noter modèle + version OS.

### 3.1 Parcours froid (gate)

Sur **chaque** OS :

- [ ] Cold start : splash → menu principal (réseau réel ou 4G, pas uniquement Wi-Fi labo).
- [ ] Menu → **Préparation** (mise casual + confirm) → **partie** → **pause** → reprise → **retour menu**.
- [ ] Optionnel mais recommandé : High Stakes / Royal jusqu’à l’écran de fin ou abandon volontaire (cash path).

### 3.2 Réduire les mouvements (gate)

**iOS** : Réglages → Accessibilité → Mouvement → **Réduire les mouvements** (ON).  
**Android** : selon fabricant : Accessibilité → **Supprimer les animations** ou équivalent.

Puis relancer l’app et rejouer **au moins** : menu → prep → partie (2–3 minutes).

- [ ] Le jeu reste **lisible** (HUD, chrono, gemmes, flashes non épileptiques pour vous).
- [ ] Aucun soft-lock (boutons inaccessibles, opacity 0 bloquante).

Référence technique : `velourReduceMotion` (`lib/utils/velour_accessibility.dart`) s’aligne sur `MediaQuery.disableAnimationsOf`.

### 3.3 VoiceOver (iOS) — parcours « cash » + gemmes (gate)

**Activer** : Réglages → Accessibilité → VoiceOver (ON).  
**Préparation** : parcourir jusqu’au bouton de lancement de partie ; vérifier que les **mises** (casual / premium) et le **confirm** sont annoncés de façon compréhensible.

**En jeu** :

- [ ] **Menu pause** : tooltip / bouton annoncé (voir chaîne `gameHudMenuTooltip`).
- [ ] **Au moins 2 gemmes du plateau** : la **forme + la couleur** sont annoncées (VoiceOver) — logique `gemAccessibilityLabel` (`lib/utils/gem_accessibility.dart`).

Noter tout libellé vide, doublon ou incohérence dans le ticket release.

**Automatisé (complément, ne remplace pas VoiceOver sur appareil)** :

- [x] Tests `test/gem_accessibility_test.dart` : `gemAccessibilityLabel` annonce **forme + couleur** (EN).

### 3.4 TalkBack (Android) — même parcours (gate)

Activer TalkBack (selon appareil). Répéter la section **3.3** sur **un téléphone Android réel**.

---

## 4. Firebase & backend (gates)

### 4.1 Remote Config (prod)

- [ ] Console Firebase → Remote Config : paramètres **publiés** pour l’environnement **production** (pas seulement brouillon).
- [ ] Vérifier que les **valeurs par défaut embarquées** (`lib/services/remote_config_service.dart`, `_defaults`) restent **cohérentes** avec la politique produit si le fetch échoue (offline, timeout 6 s).
- [ ] Après publication RC : smoke test **premier lancement** + **partie complète** sur build store candidate.

### 4.2 App Check (release)

- [ ] Console → App Check : **Play Integrity** (Android) et **App Attest / Device Check** (iOS) enregistrés pour l’app **release**.
- [x] Confirmer qu’aucune build **store** n’est compilée avec besoin de **debug provider** (le client utilise `AndroidPlayIntegrityProvider` / `AppleAppAttestWithDeviceCheckFallbackProvider` uniquement quand `kReleaseMode` — voir `velourActivateAppCheck` dans `lib/velour_bootstrap.dart`). *(Revue code statique ; le bon jeton App Check en prod reste une vérif console + binaire signé.)*
- [ ] Si les Cloud Functions **appliquent** App Check : vérifier métriques / rejets dans la console après déploiement.

### 4.3 Règles & Functions

- [ ] Déploiement aligné avec `docs/PRODUCTION_HARDENING.md` (ordre règles / `leaderboardPublic` / callables).
- [ ] Smoke callable `velourHealth` / parcours LUX sur staging ou prod limitée selon votre process.

---

## 5. Observabilité post-soumission (J1–J7)

- [ ] Tableaux de bord : voir **`docs/OBSERVABILITY_J1.md`** (filtres Crashlytics `[VEL_OBS]`, clés custom, boucle RC).
- [ ] Crashlytics : **alertes** email/Slack sur nouveaux issues ou taux d’erreur.
- [ ] **Avis store** : processus quotidien J1–J7 pour tickets critiques.

---

## 6. Post-soumission (non bloquant jour J mais à planifier)

- [x] Suivi des métriques de rétention / funnel (Analytics ou équivalent — voir `OBSERVABILITY_J1.md` section Analytics). *(Côté client : événements opt-in `VELOUR_ANALYTICS` + doc ; tableaux de bord / consentement légal / activation console restent humains.)*
- [ ] Itération RC (DDA, timer clutch, board flow) guidée par données, pas par intuition seule.

---

## Annexe A — Dernière passe agent / CI locale (2026-05-09)

À recopier dans le ticket release si utile. **Ne remplace pas** les cases §2–§4 console, §3 appareils réels, ni le sign-off.

| Vérification | Résultat |
|--------------|----------|
| `flutter pub get` | OK |
| `dart analyze` | 0 issue |
| `flutter test` | Toute la suite OK |
| `flutter build appbundle --release` + `--dart-define=VELOUR_PRIVACY_POLICY_URL=https://example.org/velour-privacy` | OK → `build/app/outputs/bundle/release/app-release.aab` |
| `flutter build ios --release --no-codesign` + même `dart-define` | **Échec** : `pod install` / checkout CocoaPods — *No space left on device* sur l’agent ; relancer sur une machine avec espace disque suffisant. |
| `./scripts/echo_store_release_build.sh` | OK (affiche les commandes) |

---

## Sign-off release

| Rôle        | Nom | Date | Build `+N` | iOS OK | Android OK |
|------------|-----|------|-------------|--------|--------------|
| Tech lead  |     |      |             | ☐      | ☐            |
| Produit QA |     |      |             | ☐      | ☐            |

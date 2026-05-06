# Velour — durcissement production

Document de référence pour la mise à niveau « appli sérieuse » : sécurité, confidentialité, tests, CI et observabilité. Les éléments sont ordonnés par impact / dépendances.

## 1. Économie LUX côté serveur (priorité maximale)

**Constat :** le client peut toujours envoyer des valeurs absurdes tant que les règles Firestore autorisent l’écriture sur `totalLux` / `highScore`. Les plafonds dans `EconomyService` limitent les erreurs honnêtes et un peu de triche locale, pas un client modifié.

**Cible :**

- **Cloud Functions (HTTPS callable)** ou **App Check + transactions** documentées :
  - `applyLuxDelta` / `commitRunResult` : authentification obligatoire, validation du motif (ex. `shop_purchase`, `stake_ante`, `run_reward`), plafonds par appel, **transaction Firestore** lecture → écriture sur `players/{uid}`.
  - Optionnel : **Firebase App Check** pour réduire les appels automatisés aux callables.
- Le client migre progressivement : écriture directe désactivée dans les règles une fois la callable stable.

**État livré (première tranche) :** `velourApplyLuxDelta` exige un **`motif`** parmi une liste serveur (`velour_client_sync`, `bootstrap_reconcile`), écrit une ligne **`players/{uid}/luxLedger/*`** par delta appliqué non nul, et accepte une **`idempotencyKey`** optionnelle (doc **`luxDedup`**, rejouer = même réponse). Le client envoie le motif approprié (`LuxApplyMotifs` côté Dart).

**Suite :** motifs métier (`welcome_grant`, `shop_skin`, `shop_forge_consumable`, `stake_ante`, `stake_reward`, `oracle_insurance_refund`, `vault_soft_credit`) + **tampons cloud séparés par motif** côté `EconomyService` (vidage ordonné). Plafonds **par motif** côté CF (ex. forge / mise plus stricts que le fallback `velour_client_sync`). Crédits **IAP** : `velourGrantIapLux` met déjà à jour `totalLux` — le client met à jour le portefeuille local avec **`recordCloudPending: false`** pour éviter un second passage par `velourApplyLuxDelta`.

**Durcissement supplémentaire (CF) :** pour les motifs métier, **delta discret autorisé** (ex. mise `-50` / `-250`, forge `-200` / `-350` / `-175` / `-220`, rembourse assurance `30` / `150`, etc.) — sinon `invalid-argument` + `VEL_CF_LUX_MOTIF_DELTA_REJECTED`. **Caps journaliers positifs par motif** (`luxMotifDailyDay` + `luxMotifDailyPositive` sur `players/{uid}`), appliqués avant le cap journalier global.

**Référence code :** `functions/src/index.ts` — callables **`velourHealth`** (ping) et **`velourApplyLuxDelta`** (transaction LUX sur `players/{uid}`, région `europe-west3`).

**Client Flutter :** `EconomyService` envoie les variations LUX uniquement via `FirestoreService.tryApplyLuxDeltaViaCallable` ; les règles Firestore **interdisent** toute mise à jour client du champ `totalLux`. En cas d’échec callable : log `velour.economy.security` + `queuePendingLuxCloudHint` pour le prochain merge.

### Déploiement staging (règles + functions)

1. `firebase login` puis cibler le projet : `firebase use <stagingId>` (ou variable `GOOGLE_APPLICATION_CREDENTIALS` en CI).
2. Règles : `firebase deploy --only firestore:rules`
3. Functions : depuis la racine du repo, `firebase deploy --only functions` (exécute `npm run build` dans `functions/` via `predeploy` dans `firebase.json`).
4. Vérifier dans la console Firebase **Functions** que `velourApplyLuxDelta` et `velourHealth` sont actives en `europe-west3`.
5. Lancer l’app contre ce projet (même `google-services` / `firebase_options` que le staging) : jouer une partie, vérifier les logs Cloud et que le solde `totalLux` bouge.

**État actuel (audit règles) :** l’écriture client sur `totalLux` est déjà **interdite sur mise à jour** (`totalLuxNotClientMutated`). La **création** du doc joueur impose désormais `totalLux == 0` et `highScore == 0` (pas de bootstrap « richesse factice »). Les crédits LUX passent par **`velourApplyLuxDelta`** et **`velourGrantIapLux`** (`functions/src/index.ts`, `iap.ts`).

## 2. Modèle de données `players` + `leaderboardPublic` (phase 2 — en place dans le dépôt)

**Objectif :** le classement ne lit plus les docs `players` (LUX, inventaire, etc.). Il lit **`leaderboardPublic/{uid}`** avec au plus `pseudo`, `highScore`, `updatedAt`.

**Implémentation :**

- **Trigger** `velourMirrorPlayerToLeaderboardPublic` (`functions/src/leaderboardPublic.ts`) : à chaque écriture / suppression de `players/{uid}`, recopie ou supprime le miroir public (Admin SDK, hors règles client).
- **Client Flutter** : `FirestoreService.leaderboardTopTenStream` et le calcul de rang dense utilisent `leaderboardPublic` ; le pied de page « votre rang » continue de lire **votre** doc `players/{uid}` (lecture owner autorisée par les règles).
- **Règles** : `players` → `allow read: if isOwner(userId)` ; `leaderboardPublic` → `allow read: if isSignedIn()`, `allow write: if false`.

### Ordre de déploiement production (important)

1. `firebase deploy --only firestore:indexes` (composites `leaderboardPublic`).
2. `firebase deploy --only functions` (inclut le trigger + callables existantes).
3. **Backfill** une fois les index actifs :  
   `cd functions && npm run admin:backfill-leaderboard-public -- --execute`  
   (compte de service : `GOOGLE_APPLICATION_CREDENTIALS`).
4. **Publier l’app** qui contient ce dépôt (requêtes `leaderboardPublic`).
5. En dernier : `firebase deploy --only firestore:rules` (lecture `players` réservée au propriétaire).  
   *Si les règles passent avant l’app à jour, l’ancien client casse le top 10.*

### Classement prod : retirer les profils de test

Les entrées du top 10 viennent des documents **`leaderboardPublic/{uid}`** (et restent cohérentes avec `players` via le trigger). Pour un classement « propre » après des sessions de test, supprimer les docs concernés (le trigger supprime le miroir si tu supprimes `players/{uid}` avec l’Admin SDK).

**Flux recommandé (machine avec la clé de service, jamais dans le dépôt) :**

1. `cd functions` puis `export GOOGLE_APPLICATION_CREDENTIALS=/chemin/absolu/vers-service-account.json`
2. `bash scripts/run-leaderboard-cleanup.sh` — génère un snapshot JSON dans `functions/scripts/.local/` (gitignoré) avec les ~30 premiers du classement (requête **players** côté script admin ; l’app utilise **`leaderboardPublic`** pour l’UI).
3. Copier `functions/scripts/uids-a-supprimer.example.txt` vers `uids-a-supprimer.txt` (gitignoré), y mettre **une ligne par UID** à retirer.
4. `npm run admin:delete-players -- --uids-file=scripts/uids-a-supprimer.txt --verbose` puis la même commande avec `--execute`.
5. Optionnel : `--with-auth` avec `--execute` pour supprimer aussi les comptes **Auth** (irréversible).

Export seul : `npm run admin:export-leaderboard-top -- --limit=50 --out=scripts/.local/top.json`

**Pré-lancement (tous les comptes = tests)** : purge complète de la collection `players` + option Auth — `npm run admin:purge-all-players-help` puis `npm run admin:purge-all-players -- --execute --with-auth` (irréversible ; à ne plus utiliser une fois en prod avec de vrais joueurs).

**Normalisation pseudos / `updatedAt`** : `npm run admin:normalize-pseudos -- --help` — utile pour données incohérentes, pas pour retirer un joueur du classement.

Référence : `functions/scripts/exportLeaderboardTopAdmin.js`, `functions/scripts/deletePlayersAdmin.js`, `functions/scripts/normalizePlayerPseudos.js`, `functions/scripts/backfillLeaderboardPublicAdmin.js` (`npm run admin:backfill-leaderboard-public`).

## 3. Règles Firestore (invariants côté règles)

Fichier : `firestore.rules`.

- **Création** `players/{uid}` : champs initiaux stricts ; `totalLux` et `highScore` **forcés à 0** (aligné sur `FirestoreService.initializeAuthAndPullSkins`).
- **Mise à jour** : `totalLux` **non modifiable** par le client ; high score **monotone**, borné ; inventaire **monotone** (pas de retrait) ; **clés allowlist** (`diff().affectedKeys().hasOnly(...)`).
- **`iap_grants/{id}`** : `allow read, write: if false` — idempotence IAP réservée au backend (callable `velourGrantIapLux`).
- **`leaderboardPublic/{uid}`** : lecture tout utilisateur connecté ; **aucune** écriture client (trigger + Admin).

Les règles restent un **filet** : la source de vérité LUX côté serveur reste les **callables** (plafonds delta / validation Play ou JWS Apple).

## 4. Tests & CI

- **CI :** `dart analyze --fatal-infos`, `flutter test`, `dart format --set-exit-if-changed`, build web, compilation TypeScript des **Cloud Functions** (`functions/`, job dédié) — voir `.github/workflows/flutter_ci.yml`. *(Smoke Android `flutter build apk --release` / AAB : machine locale ou runner dédié avec SDK Android complet.)*
- **Tests métier :** règles de mise / fin de session extraites dans `lib/game/session_stake_resolution.dart` et couvertes par `test/session_stake_resolution_test.dart` (sans monter tout le plateau).

**Smoke build local (avant release store)** — à lancer depuis la racine du dépôt :

```bash
dart analyze
flutter test
(cd functions && npm run build)
flutter build ios --release --no-codesign
flutter build appbundle --release
```

*(IPA signé : `flutter build ipa` ou archive Xcode ; AAB : fichier sous `build/app/outputs/bundle/release/`.)*

Élargir ensuite : sync cloud (fakes), parcours `GameState` avec mocks ciblés.

## 5. Accessibilité & locales longues

- HUD : libellés sémantiques (`Semantics`) sur le montant LUX et les zones critiques.
- **Allemand (`de`)** : `app_de.arb` + préférence `AppLocalePreference.de` — valider visuellement HUD / overlays avec chaînes longues (coupures `ellipsis` / `FittedBox` déjà utilisés là où pertinent).

## 6. Observabilité

- **`VelourObservability`** : en **release / profile** (hors debug), erreurs Firestore / IAP / client envoyées à **Firebase Crashlytics** (`recordError` non fatal ou `log` pour signaux économie).
- **Codes client stables** (`lib/services/velour_obs_codes.dart`, préfixe `VEL_CLI_*`) : filtres dans Crashlytics (reason / logs préfixés `[VEL_OBS]`).
- **Codes Cloud Functions** (préfixe `VEL_CF_*`, `VEL_IAP_*`, `VEL_LB_*`) : champs `code` dans les logs Cloud Logging pour IAP grant, apply LUX (clamp, cap journalier, rate limit), trigger classement.
- **Anti-abus callable** : `velourApplyLuxDelta` applique aussi une limite **d’appels par minute** (`luxApplyMinuteEpoch` / `luxApplyMinuteCount` sur `players/{uid}`) en plus du plafond journalier des crédits positifs.
- **Analytics** : événements agrégés selon besoin produit (hors périmètre minimal du dépôt).

### Exemples de codes

| Code | Où |
|------|-----|
| `VEL_CLI_IAP_PURCHASE_STREAM` | Flux IAP natif (`LuxIapService`) |
| `VEL_CLI_IAP_CLOUD_GRANT_*` | Callable `velourGrantIapLux` (client) |
| `VEL_CF_LUX_RATE_LIMIT` | Trop d’appels `velourApplyLuxDelta` / minute |
| `VEL_CF_LUX_DAILY_CAP_*` | Cap journalier crédits positifs |
| `VEL_CF_LUX_MOTIF_INVALID` | Motif LUX absent ou inconnu (callable) |
| `VEL_CF_LUX_DEDUP_HIT` | Rejeu idempotent — réponse issue du doc `luxDedup` |
| `VEL_CF_LUX_LEDGER_WRITTEN` | Ligne `luxLedger` écrite pour un delta non nul |
| `VEL_CF_LUX_MOTIF_DELTA_REJECTED` | Delta incompatible avec le motif (montant non autorisé) |
| `VEL_CF_LUX_MOTIF_DAILY_CAP_*` | Cap journalier **par motif** (positifs) |
| `VEL_IAP_GRANT_NEW` / `VEL_IAP_GRANT_DUP` | Grant IAP côté serveur |
| `VEL_LB_PUBLIC_MIRROR_FAILED` | Miroir `leaderboardPublic` |

## 7. Android — App Check, Play Integrity, Crashlytics

**Client Flutter** (`lib/main.dart`, `velourActivateAppCheck`) : en **release**, **`AndroidPlayIntegrityProvider`** ; en **debug / profile** (`!kReleaseMode`), **`AndroidDebugProvider`** — aligné sur iOS. Les jetons **debug** Android s’affichent dans **Logcat** au premier lancement ; les enregistrer dans Firebase comme pour iOS.

### 7.1 Firebase — App Check (obligatoire si `VELOUR_ENFORCE_APP_CHECK` côté Functions)

1. [Console Firebase](https://console.firebase.google.com) → projet **velour-6690f** → **Build** → **App Check**.
2. Sélectionner l’app **Android** (`package` **`fr.grandjean.velour`**).
3. Enregistrer le fournisseur **Play Integrity**.
4. **Jetons de débogage** : pour `flutter run` / APK debug sur appareil ou émulateur, copier le jeton depuis Logcat (`FirebaseAppCheck` / message du SDK) → **App Check** → *Manage debug tokens* → ajouter le jeton pour l’app Android.
5. Quand tout est validé, activer l’**application** des App Check sur les produits utilisés (**Firestore**, **Cloud Functions**, etc.) — même logique qu’iOS.

### 7.2 Google Play Console — empreintes & intégrité

1. [Play Console](https://play.google.com/console) → ton appli → **Configuration de l’application** (ou **Intégrité de l’application** selon l’UI).
2. **Play Integrity** : lier le projet Google Cloud / Firebase si demandé.
3. **Empreinte du certificat de signature de l’application** : Play affiche l’empreinte **SHA-256** du certificat **de distribution** (et parfois celle de **l’upload**). Les noter.
4. **Firebase** (paramètres du projet → *Vos applications* → Android, ou App Check) : si Google demande les empreintes **SHA-256** pour Play Integrity / API, coller celles de **Play Console** (release + éventuellement clé d’upload), pas seulement celle du keystore local — surtout si **Play App Signing** est activé (empreinte « App signing » ≠ keystore upload parfois).

Pour afficher les SHA depuis un keystore local (release) :

```bash
keytool -list -v -keystore /chemin/vers/ton.keystore -alias TON_ALIAS
```

(Rechercher la ligne **SHA256**.)

### 7.3 Crashlytics & symboles Dart (Android)

- Le plugin Gradle **`com.google.firebase.crashlytics`** est déjà dans `android/app/build.gradle.kts` : les builds **release** envoient en général les symboles natifs attendus.
- Si tu buildes avec **`--obfuscate`** et **`--split-debug-info=<dossier>`**, il faut en plus uploader les symboles Flutter pour Android, par exemple :

```bash
firebase crashlytics:symbols:upload --app=1:822433624910:android:6fab3a38718e7a02f7a41f CHEMIN_VERS_DOSSIER_SPLIT_DEBUG_INFO
```

(`mobilesdk_app_id` dans `android/app/google-services.json` ; le même ID sert à la doc Firebase « upload symbols ».)

Sans obfuscation, cette étape CLI n’est en principe **pas** nécessaire.

### 7.4 Build release Android

- Fichier **`android/key.properties`** + keystore (hors dépôt, voir `.gitignore`) pour une **AAB/APK signés** release.
- Commande typique : `flutter build appbundle` (recommandé pour Play).

---

## Checklist déploiement

1. Merger ce dépôt, vérifier CI verte.
2. **Phase classement** : indexes → functions (trigger inclus) → backfill `leaderboardPublic` → **release app** → règles Firestore (voir §2).
3. Staging / prod : surveiller logs du trigger `velourMirrorPlayerToLeaderboardPublic` et erreurs Crashlytics côté client.
4. **App Check** : activer côté Firebase + client ; callable avec `VELOUR_ENFORCE_APP_CHECK=1` (`functions/.env.velour-6690f`). **iOS release** : le dépôt inclut `ios/Runner/Runner.entitlements` (App Attest `production`) ; dans [Apple Developer](https://developer.apple.com) → Identifiers → App ID `fr.grandjean.velour` → activer **App Attest** ; dans Firebase **App Check** → app iOS → fournisseur **App Attest** (et **Device Check** + Team ID si besoin). Jetons **debug** uniquement pour dev/profile (`!kReleaseMode`).
5. **Crashlytics dSYM (iOS)** : le target **Runner** exécute en fin de build la phase **`[firebase_crashlytics] Crashlytics Run`** (`"${PODS_ROOT}/FirebaseCrashlytics/run"`) avec les chemins dSYM (Runner + `App.framework`) et `ios/firebase_app_id_file.json`. Après **chaque** archive / `flutter build ipa`, vérifier dans la console Crashlytics que les dSYM ne sont plus « manquants ». Pour une **ancienne** build déjà sur App Store Connect : *Xcode Organizer* → *Archives* → clic droit sur l’archive → **Distribute App** / **Show in Finder** → dossier `dSYMs` → zip → [Firebase Crashlytics → dSYM](https://console.firebase.google.com).
6. **Android — App Check** : Firebase → App Check → app **Android** `fr.grandjean.velour` → **Play Integrity** ; jetons debug pour les builds locales ; appliquer App Check aux backends utilisés (voir §7.1).
7. **Android — Play Console** : empreintes **SHA-256** (release / upload / App signing si concerné) alignées avec Firebase / Play Integrity (voir §7.2).
8. **Android — Release** : `key.properties` + keystore ; `flutter build appbundle` ; smoke test IAP + callables sur une build **release** ou **internal testing** avec enforcement App Check si activé.

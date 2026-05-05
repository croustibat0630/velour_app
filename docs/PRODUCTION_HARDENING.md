# Velour — durcissement production

Document de référence pour la mise à niveau « appli sérieuse » : sécurité, confidentialité, tests, CI et observabilité. Les éléments sont ordonnés par impact / dépendances.

## 1. Économie LUX côté serveur (priorité maximale)

**Constat :** le client peut toujours envoyer des valeurs absurdes tant que les règles Firestore autorisent l’écriture sur `totalLux` / `highScore`. Les plafonds dans `EconomyService` limitent les erreurs honnêtes et un peu de triche locale, pas un client modifié.

**Cible :**

- **Cloud Functions (HTTPS callable)** ou **App Check + transactions** documentées :
  - `applyLuxDelta` / `commitRunResult` : authentification obligatoire, validation du motif (ex. `shop_purchase`, `stake_ante`, `run_reward`), plafonds par appel, **transaction Firestore** lecture → écriture sur `players/{uid}`.
  - Optionnel : **Firebase App Check** pour réduire les appels automatisés aux callables.
- Le client migre progressivement : écriture directe désactivée dans les règles une fois la callable stable.

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

- **CI :** `dart analyze --fatal-infos`, `flutter test`, `dart format --set-exit-if-changed`, build web, compilation TypeScript des **Cloud Functions** (`functions/`, job dédié).
- **Tests métier :** règles de mise / fin de session extraites dans `lib/game/session_stake_resolution.dart` et couvertes par `test/session_stake_resolution_test.dart` (sans monter tout le plateau).

Élargir ensuite : sync cloud (fakes), parcours `GameState` avec mocks ciblés.

## 5. Accessibilité & locales longues

- HUD : libellés sémantiques (`Semantics`) sur le montant LUX et les zones critiques.
- **Allemand (`de`)** : `app_de.arb` + préférence `AppLocalePreference.de` — valider visuellement HUD / overlays avec chaînes longues (coupures `ellipsis` / `FittedBox` déjà utilisés là où pertinent).

## 6. Observabilité

- **`VelourObservability`** : en **release / profile** (hors debug), erreurs Firestore / IAP / client envoyées à **Firebase Crashlytics** (`recordError` non fatal ou `log` pour signaux économie).
- **Analytics** : événements agrégés selon besoin produit (hors périmètre minimal du dépôt).

---

## Checklist déploiement

1. Merger ce dépôt, vérifier CI verte.
2. **Phase classement** : indexes → functions (trigger inclus) → backfill `leaderboardPublic` → **release app** → règles Firestore (voir §2).
3. Staging / prod : surveiller logs du trigger `velourMirrorPlayerToLeaderboardPublic` et erreurs Crashlytics côté client.
4. Optionnel : **App Check** sur les callables pour limiter le spam d’appels.

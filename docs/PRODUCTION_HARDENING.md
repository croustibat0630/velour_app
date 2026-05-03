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

**Phase suivante (sécurité maximale) :** retirer l’écriture client directe sur `totalLux` dans `firestore.rules` une fois 100 % du parcours LUX passé par la callable + tests de charge OK.

## 2. Modèle de données `players` et lecture publique

**Constat actuel :** le classement mondial interroge `players` avec `orderBy('highScore')`. Toute règle `allow read` trop large expose **l’intégralité** des documents retournés (inventaire, `totalLux`, etc.) aux clients qui exécutent la même requête ou devinent un `uid`.

**Piste recommandée (phase 2) :**

- Collection **`leaderboardPublic`** (ou `players/{id}/public/profile`) alimentée par trigger à partir de `players`, contenant uniquement `pseudo`, `highScore`, `updatedAt`, éventuellement `activeSkinId` public.
- `players/{uid}` : `allow read: if isOwner(uid)` ; écritures métier via Functions ou règles très strictes.

**Étape intermédiaire (déjà en place ou à déployer) :** `allow read: if isSignedIn()` au lieu de `true` — supprime la lecture totalement anonyme ; **ne supprime pas** l’exposition doc complète entre utilisateurs authentifiés (dont anonymes Firebase).

## 3. Règles Firestore (invariants côté règles)

- High score monotone, borné.
- Inventaire monotone (pas de retrait arbitraire).
- `totalLux` entier, borné.
- **Clés autorisées** sur mise à jour (`diff().affectedKeys().hasOnly(...)`) pour éviter l’injection de champs arbitraires.

Les règles restent un **filet** : elles ne remplacent pas la logique métier serveur pour LUX.

## 4. Tests & CI

- **CI :** `dart analyze --fatal-infos`, `flutter test`, `dart format --set-exit-if-changed`, build web, compilation TypeScript des **Cloud Functions** (`functions/`, job dédié).
- **Tests métier :** règles de mise / fin de session extraites dans `lib/game/session_stake_resolution.dart` et couvertes par `test/session_stake_resolution_test.dart` (sans monter tout le plateau).

Élargir ensuite : sync cloud (fakes), parcours `GameState` avec mocks ciblés.

## 5. Accessibilité & locales longues

- HUD : libellés sémantiques (`Semantics`) sur le montant LUX et les zones critiques.
- **Allemand (`de`)** : `app_de.arb` + préférence `AppLocalePreference.de` — valider visuellement HUD / overlays avec chaînes longues (coupures `ellipsis` / `FittedBox` déjà utilisés là où pertinent).

## 6. Observabilité

- **`VelourObservability`** : journalisation structurée (`developer.log`, `name: 'velour.firestore'`) pour les échecs après retry dans `FirestoreService`.
- **Suite :** Crashlytics / Analytics événements agrégés (hors périmètre du dépôt si non activé sur le projet Firebase).

---

## Checklist déploiement

1. Merger ce dépôt, vérifier CI verte.
2. Staging : `firebase deploy --only firestore:rules` puis `firebase deploy --only functions` ; valider auth anonyme + sync LUX (callable + repli).
3. Prod : mêmes commandes après recette ; surveiller les erreurs `velour.firestore` / logs Functions.
4. Optionnel : App Check sur les callables ; puis resserrer les règles d’écriture client sur `totalLux`.
5. Planifier migration `leaderboardPublic` + réduction `allow read` sur `players`.

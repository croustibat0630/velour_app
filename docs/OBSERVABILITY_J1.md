# Observabilité J1–J7 (Velour)

Objectif : transformer les **logs et erreurs** en **décisions** (RC, hotfix, priorisation) après l’ouverture store. Ce document complète la section **6** de `docs/PRODUCTION_HARDENING.md`.

---

## 1. Firebase Crashlytics — filtres immédiats

### 1.1 Logs breadcrumb `[VEL_OBS]`

Le client écrit des lignes du type :

- `[VEL_OBS] economy_security …`
- `[VEL_OBS] firestore_failure …`
- `[VEL_OBS] client_failure …`
- `[VEL_OBS] j1_session_tag …` (démarrage release / profile — voir `VelourObservability.tagReleaseSessionForCrashlyticsJ1`)

**Dans la console Crashlytics** (onglet *Issues* ou *Logs*) :

1. Créer une **recherche enregistrée** ou utiliser le filtre de texte sur `VEL_OBS`.
2. Croiser avec la version (`Versions`) pour isoler la build store (`+N` du `pubspec.yaml`).

### 1.2 Clés personnalisées (sessions « build store »)

Au bootstrap (hors debug), l’app pose des **custom keys** Crashlytics :

| Clé | Signification |
|-----|----------------|
| `velour_privacy_url_configured` | `true` si `VELOUR_PRIVACY_POLICY_URL` non vide à la compilation. |
| `velour_release_bootstrap` | `1` — session passée par le chemin release observabilité J1. |
| `velour_analytics` | `1` si build avec `--dart-define=VELOUR_ANALYTICS=true`, sinon `0` (hors debug). |

**Usage** : dans Crashlytics → *Issues* → filtres avancés / BigQuery export, segmenter les crashs où `velour_release_bootstrap == 1` pour exclure les builds dev ad hoc.

### 1.3 Raison (`reason`) des `recordError`

Les erreurs non fatales utilisent souvent un **code stable** (`VelourObsCodes`, préfixe `VEL_CLI_*`) comme `reason` — filtrer par `reason` ou par stack trace associée.

Référence : `lib/services/velour_obs_codes.dart`.

---

## 2. Cloud Logging (Functions)

Les callables et triggers émettent des codes **`VEL_CF_*`**, **`VEL_IAP_*`**, **`VEL_LB_*`** (voir table dans `PRODUCTION_HARDENING.md`).

**Actions J1** :

1. Créer un **dashboard** (ou requêtes sauvegardées) sur `jsonPayload.code` ou équivalent selon votre format de log.
2. Alerter sur spike de `VEL_CF_LUX_RATE_LIMIT` ou `VEL_CF_LUX_MOTIF_DELTA_REJECTED` (possible attaque ou bug client).

---

## 3. Remote Config & DDA — boucle de décision

Les défauts embarqués (`meta_dda_permille`, `meta_ema_alpha_permille`, etc.) sont dans `lib/services/remote_config_service.dart`.

**Sans funnel Analytics**, la rétention J1 reste partiellement **opaque** ; vous pouvez quand même :

1. Surveiller **Crashlytics** + **avis store** + **support**.
2. Comparer **niveau médian** / **temps de partie** si vous avez déjà un pipeline (BigQuery, export manuel, etc.).
3. Ajuster RC **par petits pas** (un paramètre à la fois) avec date de publication notée.

### 3.1 Funnel embarqué (opt-in build)

Avec `--dart-define=VELOUR_ANALYTICS=true`, le client envoie à Firebase Analytics :

- `velour_menu_view` — ouverture [MainMenuView](lib/screens/main_menu_view.dart).
- `velour_prep_open` — param `stake_kind` (`casual` / `highStakes` / `royal` / `unset`).
- `velour_run_start` — param `stake_kind` au démarrage effectif de la partie ([GameScreen](lib/screens/game_screen.dart)).
- `velour_shop_view` — ouverture [ShopView](lib/screens/shop_view.dart) (Coffre-Fort + Forge).
- `velour_shop_vault_buy_start` — params `product_id` (SKU), `lux_amount` (grant attendu côté client).
- `velour_shop_vault_buy_outcome` — params `product_id`, `outcome` (`success` / `cancelled` / `unavailable` / `products_unavailable` / `busy` / `error`), optionnel `error_code` si `outcome == error`.
- `app_open` (API standard) — au bootstrap si Analytics est activé.

**Console** : Analytics → *DebugView* (appareil debug / build avec debug) ou rapports *Realtime* / *Events* après propagation.

**À prévoir** : `velour_run_end` (niveau, raison de fin) n’est pas encore instrumenté ; l’ajouter si vous corrélez RC avec **taux d’abandon en cours de run**.

Sans `VELOUR_ANALYTICS`, la collecte Analytics est coupée côté client (`setAnalyticsCollectionEnabled(false)`) — la politique de confidentialité et la fiche store doivent quand même refléter tout autre traitement (auth, IAP, etc.).

---

## 4. Checklist rapide « premier week-end »

- [ ] Crashlytics : 0 crash **nouveau** bloquant sur la version store.
- [ ] Taux d’erreur callable LUX acceptable (Logging).
- [ ] RC fetch OK (pas de plainte « tout est trop cher » si bug de defaults — vérifier logs `[VelourRemoteConfig]`).
- [ ] Décision documentée : **aucun changement RC** / **rollback** / **tweak param X**.

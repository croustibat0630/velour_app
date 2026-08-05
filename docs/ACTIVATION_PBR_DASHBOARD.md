# Activation — Dashboard PBR (lecture ≤ 30 s)

**Phase A — Validation du Product-Market Fit initial**  
Tags Git : `activation-p0-ftue` → `activation-s2-funnel` (`lib/services/velour_activation_funnel.dart`).

Builds store uniquement (`VELOUR_ANALYTICS=true`). Ne pas juger sur DebugView de ton téléphone seul.

---

## Règle des 7 jours

Aucune décision produit avant données suffisantes (idéalement **plusieurs dizaines** de nouveaux joueurs, pas 2–3 sessions).

| Interdit | Autorisé |
|----------|----------|
| « Je trouve que… » | « PBR est passé de 34 % à 61 %. » |
| « J’ai l’impression que… » | « Second Run Rate +18 pts. » |
| « Ce serait plus joli… » | « Médiane time-to-first-perfect = 24 s. » |

**Ne pas regarder les téléchargements chaque matin** pendant cette phase (bruit sans campagne). Regarder la **qualité** des N nouveaux joueurs.

---

## Les 4 chiffres du matin (Santé)

Cohorte : `is_first_launch = 1` sur les events `velour_ftue_*`.

| KPI | Définition | Event / param |
|-----|------------|----------------|
| **Nouveaux joueurs** | Sessions FTUE démarrées | Count distinct `session_id` sur `velour_ftue_start` **ou** count `velour_ftue_start` |
| **PBR** (*Perfect Before Quit Rate*) | % qui ont eu un Perfect avant de quitter | Parmi `velour_ftue_session_closed` avec `is_first_launch=1` : part où `perfect_before_quit = 1` |
| **FTUE Completed** | % qui ont « vraiment vécu » Velour | `velour_ftue_completed` / `velour_ftue_start` (même cohorte) |
| **Second Run Rate** | % qui relancent | `velour_ftue_second_run` / `velour_ftue_start` |

### Matrice de décision

| KPI | Monte | Stable | Baisse |
|-----|-------|--------|--------|
| **PBR** | Garder | Observer | Revenir en arrière (tag / bisect) |
| **FTUE Completed** | Garder | Observer | Investiguer |
| **Second Run Rate** | Très bon signal | Observer | Investiguer **immédiatement** |

---

## Temps (médianes)

Sur cohorte `is_first_launch = 1` :

| Métrique | Paramètre | Event |
|----------|-----------|--------|
| Médiane → 1er match | `time_to_first_match_ms` | `velour_ftue_first_match` |
| Médiane → 1er Perfect | `time_to_first_perfect_ms` | `velour_ftue_first_perfect` |

Convertir ms → secondes pour la lecture humaine.

---

## Funnel (drop-off)

Ordre strict (même `session_id`) :

1. `velour_ftue_start`
2. `velour_ftue_menu_play`
3. `velour_ftue_prep_open`
4. `velour_ftue_prep_confirm`
5. `velour_ftue_run_start` (`run_index=1`)
6. `velour_ftue_first_gem`
7. `velour_ftue_first_match`
8. `velour_ftue_first_perfect`
9. `velour_ftue_second_run` (optionnel)
10. `velour_ftue_session_closed` → lire `perfect_before_quit`, `last_funnel_step`

En GA4 : *Explore* → Funnel exploration, ou BigQuery si export activé. Filtrer `is_first_launch = 1`.

---

## GA4 — comment le monter vite

1. Firebase / GA4 → **Explore** → Free form ou Funnel.
2. Filtre utilisateur / event : param `is_first_launch` = `1`.
3. Cartes « Santé » : 4 métriques ci-dessus (période glissante 7 jours).
4. Ne pas ajouter shop / settings / leaderboard sur ce board.

Debug local : DebugView avec build `VELOUR_ANALYTICS=true` — utile pour vérifier le câblage, **pas** pour le PBR produit.

---

## Feu vert Packaging v1 (critère, pas calendrier)

Quand, sur **plusieurs dizaines** de nouveaux joueurs :

- PBR **stable** (pas de chute nette vs baseline post-P0) ;
- FTUE Completed **cohérent** avec le PBR ;
- Second Run Rate **sans régression** ;

→ seulement alors Phase B **Packaging v1** (icône, sous-titre, captures émotion, preview Perfect/tension).

Pas de nouvelles mécaniques tant que cette validation n’a pas tranché.

---

## Références code

- Funnel : `lib/services/velour_activation_funnel.dart`
- Opt-in : `--dart-define=VELOUR_ANALYTICS=true` (`VelourAnalytics.enabled`)
- Tags : `activation-p0-ftue`, `activation-s2-funnel`

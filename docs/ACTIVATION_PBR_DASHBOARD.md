# Velour — Gouvernance produit & Dashboard PBR

Document de **gouvernance** (pas seulement une note Analytics).  
À conserver tel quel pendant le développement, en ajustant uniquement les **seuils** quand le volume de données le justifie.

**Phase A — Validation du Product-Market Fit initial**  
Question unique : *quand quelqu’un découvre Velour, vit-il assez vite le moment qui donne envie de continuer ?*  
Le **PBR** mesure cette hypothèse.

Tags Git : `activation-p0-ftue` → `activation-s2-funnel`  
Code : `lib/services/velour_activation_funnel.dart`  
Builds : store avec `VELOUR_ANALYTICS=true` uniquement. DebugView = câblage, pas verdict produit.

---

## Lecture matin (≤ 30 s)

### 1. Activation Score (KPI maître)

Un seul chiffre en tête :

```text
Activation Score   ___ / 100
```

**Formule v1** (repère interne, à recalibrer plus tard) :

| Composante | Poids | Score partiel |
|------------|-------|----------------|
| **PBR** | 50 % | `min(100, PBR% / 65 × 100)` — plafond vert à 65 % |
| **FTUE Completed** | 30 % | `min(100, FTUE% / 45 × 100)` — plafond vert à 45 % |
| **Second Run Rate** | 20 % | `min(100, SRR% / 40 × 100)` — plafond vert à 40 % |

```text
Activation Score = 0.50×score_PBR + 0.30×score_FTUE + 0.20×score_SRR
```

Exemple : PBR 68 %, FTUE 50 %, SRR 35 % → ~ `(100×0.5) + (100×0.3) + (87.5×0.2)` ≈ **97.5** (tous verts ou proches).

Si **N &lt; 30** nouveaux joueurs : afficher le score en gris + mention « sous-échantillon » — **ne pas décider**.

### 2. Santé (4 chiffres)

Cohorte : `is_first_launch = 1` sur `velour_ftue_*`.

| KPI | Définition | Source |
|-----|------------|--------|
| **Nouveaux joueurs (N)** | Sessions FTUE | Count `velour_ftue_start` (ou `session_id` distincts) |
| **PBR** | Perfect avant quit | `velour_ftue_session_closed` → part `perfect_before_quit = 1` |
| **FTUE Completed** | A vraiment vécu Velour | `velour_ftue_completed` / `velour_ftue_start` |
| **Second Run Rate** | Relance | `velour_ftue_second_run` / `velour_ftue_start` |

### 3. Temps (médianes)

| Métrique | Param | Event |
|----------|-------|--------|
| → 1er match | `time_to_first_match_ms` | `velour_ftue_first_match` |
| → 1er Perfect | `time_to_first_perfect_ms` | `velour_ftue_first_perfect` |

### 4. Funnel (drop-off)

`start` → `menu_play` → `prep_open` → `prep_confirm` → `run_start` → `first_gem` → `first_match` → `first_perfect` → `second_run` → `session_closed`

Rien d’autre sur ce board (pas shop / settings / leaderboard).

---

## Seuils (gates) — lecture Rouge / Orange / Vert

*Premiers repères, pas des vérités universelles. Les ajuster quand N est solide.*

| KPI | Rouge | Orange | Vert |
|-----|-------|--------|------|
| **PBR** | &lt; 40 % | 40–65 % | &gt; 65 % |
| **FTUE Completed** | &lt; 25 % | 25–45 % | &gt; 45 % |
| **Second Run Rate** | &lt; 20 % | 20–40 % | &gt; 40 % |

Matrice d’action (seulement si **N ≥ 30**) :

| KPI | Monte / Vert | Stable / Orange | Baisse / Rouge |
|-----|--------------|-----------------|----------------|
| **PBR** | Garder | Observer | Revenir en arrière (tag / bisect) |
| **FTUE Completed** | Garder | Observer | Investiguer |
| **Second Run Rate** | Très bon signal | Observer | Investiguer **immédiatement** |

---

## Règle anti-panic

> **Ne jamais agir sur moins de 30 nouveaux joueurs.**

```text
N < 30  →  Observation uniquement
N ≥ 30  →  Les gates et la matrice s’appliquent
```

Évite de réagir à une journée atypique.

---

## Règle des 7 jours + preuves

| Interdit | Autorisé |
|----------|----------|
| « Je trouve que… » | « PBR est passé de 34 % à 61 %. » |
| « J’ai l’impression que… » | « Second Run Rate +18 pts. » |
| « Ce serait plus joli… » | « Médiane time-to-first-perfect = 24 s. » |

**Ne pas regarder les téléchargements chaque matin** en Phase A (bruit sans campagne). Regarder la **qualité** des N nouveaux joueurs.

### Règle d’or (code)

> **Aucune ligne de code ne doit être écrite si elle ne répond pas à une hypothèse mesurable.**

Si le changement ne peut pas être relié à un KPI (PBR, FTUE Completed, Second Run Rate, conversion fiche store, etc.), **il attend**.

---

## Une hypothèse = un sprint

Jamais mélanger dans le même lot :

```text
P0 + nouvelle animation + nouveau son + économie + captures
```

Sinon on ne sait plus **pourquoi** un KPI bouge.

### Template d’hypothèse (obligatoire avant tout sprint)

```text
Hypothèse :
  Nous pensons que …

Parce que :
  …

Succès si :
  PBR …
  FTUE Completed …
  Second Run Rate …
  (autre KPI si Packaging : CTR fiche, visite→install, …)

Échantillon mini :
  N ≥ 30 (idéalement plus)

Tag / commit de référence :
  …
```

**Exemple — Sprint P0 (déjà livré)**

```text
Hypothèse : le premier Perfect arrive trop tard / hors du chemin COMMENCER.
Succès attendu : PBR ↑, Second Run ↑ (ordres de grandeur : +20 pts PBR / +10 pts SRR — à confronter aux données).
Tag : activation-p0-ftue
```

---

## Ce qu’on refuse de faire (Phase A)

```text
❌ Nouvelle mécanique
❌ Nouvelle monnaie
❌ Refonte Heat
❌ Refonte Forge
❌ Nouveau mode
❌ Nouveau skin (sauf correctif critique store)
❌ Nouvelle courbe de difficulté
❌ Pack Acquisition / Packaging avant feu vert critères
❌ « Optimisations » UX non liées à une hypothèse écrite
```

Cette liste **protège** le projet autant que les features qu’on ajoute.

---

## Feu vert Packaging v1 (critère, pas calendrier)

Sur **N ≥ 30** (idéalement plusieurs dizaines) :

- PBR **stable** (pas de chute nette vs post-P0) ;
- FTUE Completed **cohérent** avec le PBR ;
- Second Run Rate **sans régression** ;

→ alors Phase B **Packaging v1** (icône, sous-titre, captures émotion, preview Perfect/tension) — **un sprint, une hypothèse** (ex. « la fiche convertit mal → CTR / visite→install »).

---

## Journal des décisions

| Date | Décision | Hypothèse / pourquoi | Tag / commit |
|------|----------|----------------------|--------------|
| 2026-08-05 | Activation P0 FTUE | Perfect hors chemin principal COMMENCER | `activation-p0-ftue` / `0d48545` |
| 2026-08-05 | Sprint 2 funnel | Mesurer où on perd le nouveau joueur (PBR) | `activation-s2-funnel` / `6980a69` |
| 2026-08-05 | Fiche gouvernance PBR | Discipline preuves avant Packaging | `2d6c013` → *cette fiche* |
| | Packaging v1 | *(quand PBR validé)* | |
| | Icône V2 | *(si CTR faible)* | |

Compléter une ligne **à chaque** décision produit. Dans un an, ce journal vaut de l’or.

---

## GA4 — montage rapide

1. Explore → Free form / Funnel.
2. Filtre : `is_first_launch = 1`.
3. Cartes : Activation Score + 4 KPI Santé + 2 médianes + funnel.
4. Période glissante 7 jours.

---

## Références

- Funnel : `lib/services/velour_activation_funnel.dart`
- Opt-in : `--dart-define=VELOUR_ANALYTICS=true`
- Observabilité générale : `docs/OBSERVABILITY_J1.md`

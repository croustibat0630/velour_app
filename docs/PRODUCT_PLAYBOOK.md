# Velour Product Playbook

**Constitution produit** de Velour — cadre de décision stable.

| Évolue souvent | Évolue rarement (ce document) |
|----------------|-------------------------------|
| Sprints, hypothèses, backlog, roadmaps détaillées | Vision, invariants, cycle, phases, règles d’or |

Les **seuils** Rouge/Orange/Vert se recalibrent avec le volume de données.  
Le Playbook n’évolue que lorsqu’on découvre quelque chose qui change **fondamentalement** la manière de développer Velour — pas à chaque idée.

Idées / files d’attente : [`docs/PRODUCT_BACKLOG.md`](PRODUCT_BACKLOG.md) (ne pas polluer ce playbook).

Tags Git : `activation-p0-ftue` → `activation-s2-funnel`  
Funnel : `lib/services/velour_activation_funnel.dart`  
Analytics store : `VELOUR_ANALYTICS=true` — DebugView = câblage, pas verdict produit.

---

## Vision Produit

> **Velour doit devenir le puzzle de référence où chaque session est une montée de tension culminant dans un Perfect spectaculaire qui donne immédiatement envie d’en relancer une.**

Toutes les décisions doivent **renforcer cette promesse**.

Si une évolution ne la renforce pas → **elle est reportée**.

**Phase A — Validation du Product-Market Fit initial**  
Question : *quand quelqu’un découvre Velour, vit-il assez vite le moment qui donne envie de continuer ?*

Le **PBR** (*Perfect Before Quit Rate*) est l’**indicateur principal** de cette hypothèse, **mais il ne la résume pas à lui seul**. Il doit être interprété avec **FTUE Completed**, **Second Run Rate**, et les **données qualitatives** (tests utilisateurs / Programme 100 joueurs).  

Exemple de piège : PBR 90 % + Second Run 12 % ≠ validation. Le Perfect a peut‑être été vu, pas *désiré*.

---

## Ce qui ne changera jamais — Invariants

Quasi **constitutionnels**. Changent très rarement. Toute évolution qui les viole est suspecte.

### Invariant 1 — Jouer avant de lire

Le joueur joue avant de lire.

### Invariant 2 — Vers le Perfect

Chaque session doit conduire vers un Perfect (ou en faire sentir la possibilité).

### Invariant 3 — Récompense lisible

Une récompense doit être immédiatement compréhensible (chiffre, label, sensation).

### Invariant 4 — Profondeur sans friction J0

La profondeur ne doit jamais augmenter la friction des **60 premières secondes**.

### Invariant 5 — Nouveaux joueurs d’abord

Les nouveaux joueurs ont toujours priorité sur les vétérans lorsqu’un arbitrage est nécessaire.

---

## Le Cycle Produit

Comment on travaille — pas seulement comment on mesure.

```text
Idée
  ↓
Hypothèse (écrite, mesurable, kill criteria)
  ↓
Sprint (une seule hypothèse)
  ↓
Instrumentation (si manquante)
  ↓
Observation (N ≥ 30 ; anti-panic)
  ↓
Validation
  ├─ VALIDÉ → Industrialisation / garder / journal
  └─ PAS VALIDÉ → Kill → journal → prochaine hypothèse
```

**Jamais** : sauver pendant des mois une hypothèse tuée par les données.

---

## Roadmap par phases

Ordre **strict**. On n’ouvre pas la phase suivante tant que l’objectif de la phase courante n’est pas crédible.

| Phase | Nom | Objectif |
|-------|-----|----------|
| **A** | Activation | Le joueur **découvre** Velour (Perfect + envie de continuer) |
| **B** | Packaging | Le joueur **télécharge** Velour (promesse store = expérience réelle) |
| **C** | Rétention | Le joueur **revient** |
| **D** | Monétisation | Le joueur **accepte de payer** |
| **E** | Croissance | Le joueur **invite** d’autres joueurs |

Empêche de monétiser ou d’acheter du trafic alors que l’activation n’est pas validée.

État actuel : **Phase A** (post P0 + funnel ; observation / preuves).

---

## Hiérarchie des KPI

On ne regarde **pas** les revenus avant que le jeu fonctionne.

### Niveau 1 — Vitaux (activation)

Si **un seul** de ces KPI baisse nettement (N ≥ 30) → **on arrête** les autres chantiers et on investigue.

| KPI | Rôle |
|-----|------|
| **PBR** | Le joueur a-t-il vécu le Perfect avant de quitter ? |
| **FTUE Completed** | A-t-il vraiment « vécu Velour » (Perfect + suite) ? |
| **Second Run Rate** | A-t-il immédiatement envie de relancer ? |

**Activation Score** (synthèse Niveau 1) — voir lecture matin.  
Les trois KPI Niveau 1 se lisent **ensemble** (voir nuance PBR ci-dessus).

### Niveau 2 — Produit

À regarder **après** que le Niveau 1 est stable (pas en Phase A prioritaire) :

- Rétention J1  
- Durée moyenne / sessions  
- Médianes time-to-first-match / time-to-first-perfect  

### Niveau 3 — Business

**Interdit comme boussole principale** tant que le Niveau 1 n’est pas validé :

- CTR Store / Conversion Store  
- IAP / ARPDAU / revenus  
- Volume de téléchargements (bruit sans campagne)  

Le Packaging v1 (Phase B) utilisera le Niveau 3 **une fois** le feu vert activation obtenu.

---

## Lecture matin (≤ 30 s) — Niveau 1

### Activation Score (KPI maître)

```text
Activation Score   ___ / 100
```

**Formule v1** :

| Composante | Poids | Score partiel |
|------------|-------|----------------|
| **PBR** | 50 % | `min(100, PBR% / 65 × 100)` |
| **FTUE Completed** | 30 % | `min(100, FTUE% / 45 × 100)` |
| **Second Run Rate** | 20 % | `min(100, SRR% / 40 × 100)` |

```text
Activation Score = 0.50×score_PBR + 0.30×score_FTUE + 0.20×score_SRR
```

Si **N &lt; 30** : score en gris — **ne pas décider**.

### Santé

Cohorte : `is_first_launch = 1` sur `velour_ftue_*`.

| KPI | Source |
|-----|--------|
| **N** | Count `velour_ftue_start` |
| **PBR** | `session_closed` → `perfect_before_quit = 1` |
| **FTUE Completed** | `velour_ftue_completed` / `velour_ftue_start` |
| **Second Run Rate** | `velour_ftue_second_run` / `velour_ftue_start` |

### Temps (médianes)

| Métrique | Event / param |
|----------|----------------|
| → 1er match | `velour_ftue_first_match` / `time_to_first_match_ms` |
| → 1er Perfect | `velour_ftue_first_perfect` / `time_to_first_perfect_ms` |

### Funnel

`start` → `menu_play` → `prep_open` → `prep_confirm` → `run_start` → `first_gem` → `first_match` → `first_perfect` → `second_run` → `session_closed`

Pas shop / settings / leaderboard sur ce board.

---

## Seuils (gates)

*Premiers repères — pas des vérités universelles.*

| KPI | Rouge | Orange | Vert |
|-----|-------|--------|------|
| **PBR** | &lt; 40 % | 40–65 % | &gt; 65 % |
| **FTUE Completed** | &lt; 25 % | 25–45 % | &gt; 45 % |
| **Second Run Rate** | &lt; 20 % | 20–40 % | &gt; 40 % |

Matrice (seulement si **N ≥ 30**) :

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
N ≥ 30  →  Gates + matrice + kill criteria
```

---

## Règle des 7 jours + preuves

| Interdit | Autorisé |
|----------|----------|
| « Je trouve que… » | « PBR est passé de 34 % à 61 %. » |
| « J’ai l’impression que… » | « Second Run Rate +18 pts. » |
| « Ce serait plus joli… » | « Médiane time-to-first-perfect = 24 s. » |

### Règle d’or

> **Aucune ligne de code ne doit être écrite si elle ne répond pas à une hypothèse mesurable.**

Sinon → le changement **attend**.

---

## Une hypothèse = un sprint

Jamais : P0 + animation + son + économie + captures dans le même lot.

### Template (obligatoire)

```text
Hypothèse :
  Nous pensons que …

Parce que :
  …

Succès si (mesurable) :
  …

Kill si (après N ≥ 30, idéalement ~100) :
  …

Échantillon mini :
  N ≥ 30

Tag / commit de référence :
  …
```

### Kill criteria

Un studio doit savoir **quand une hypothèse est rejetée**.

Exemple :

```text
Hypothèse : le premier Perfect arrive trop tard.
Succès attendu : PBR +15 pts.
```

Après **~100 nouveaux joueurs** (ou au minimum N ≥ 30 avec signal clair) :

- Si le PBR **ne bouge pas** (ni FTUE / Second Run dans le sens attendu)  
  → **hypothèse fausse**  
  → **on arrête**  
  → on n’investit **pas** deux mois à sauver l’idée  
  → journal : « Kill — hypothèse rejetée »

On ne « polish » pas une hypothèse morte.

**Exemple — Sprint P0 (livré, en validation)**

```text
Hypothèse : Perfect hors chemin COMMENCER.
Succès : PBR ↑, Second Run ↑.
Kill : après N suffisant, PBR inchangé vs baseline pré-P0 → reconsidérer l’orchestration (pas le moteur).
Tag : activation-p0-ftue
```

---

## Dette Produit

Pas la dette technique. La **dette produit** : ce qui affaiblit la promesse Vision **sans** être encore un sprint mesurable.

Mettre à jour à chaque sprint (ajouter / rayer).

| Item | Statut | Notes |
|------|--------|-------|
| Icône faible / peu lisible à petite taille | Ouverte | Packaging v1 |
| Captures peu explicites (décor &gt; dopamine) | Ouverte | Packaging v1 |
| Hook store / sous-titre faible | Ouverte | Packaging v1 |
| Pas de vidéo / preview App Store | Ouverte | Packaging v1 |
| Peu de preuves sociales | Ouverte | Post-activation |
| Faible visibilité du moment Perfect **en store** | Ouverte | Packaging v1 |
| Perfect hors chemin principal (app) | **Traitée** | P0 `activation-p0-ftue` — *à confirmer par PBR* |
| Funnel activation non mesurable | **Traitée** | S2 `activation-s2-funnel` |

---

## Ce qu’on refuse (Phase A)

```text
❌ Nouvelle mécanique / monnaie / mode
❌ Refonte Heat / Forge / difficulté
❌ Nouveau skin (sauf correctif store critique)
❌ Packaging / Acquisition avant feu vert Niveau 1
❌ Optimisations UX sans hypothèse écrite
❌ Pilotage par revenus / installs avant PBR stable
```

---

## Feu vert Packaging v1

Sur **N ≥ 30** (idéalement plus) :

- PBR stable (pas de chute nette post-P0)  
- FTUE Completed cohérent avec le PBR  
- Second Run Rate sans régression  

→ Phase B **Packaging v1** = **un** sprint, **une** hypothèse (ex. CTR / visite→install), alignée Vision (*Perfect spectaculaire*, tension).

---

## Journal des décisions

| Date | Décision | Hypothèse / pourquoi | Résultat / kill | Tag / commit |
|------|----------|----------------------|-----------------|--------------|
| 2026-08-05 | Activation P0 FTUE | Perfect hors chemin COMMENCER | *en validation* | `activation-p0-ftue` / `0d48545` |
| 2026-08-05 | Sprint 2 funnel | Mesurer où on perd le joueur | Livré | `activation-s2-funnel` / `6980a69` |
| 2026-08-05 | Playbook constitutionnel | Invariants, cycle, phases A–E, backlog séparé | Livré | *ce commit* |
| | Packaging v1 | *(quand Niveau 1 validé)* | | |
| | Icône V2 | *(si CTR faible)* | | |

Une ligne **par** décision. Les kills aussi.

---

## À venir — Les 10 Commandements de Velour

Chapitre culturel (à rédiger plus tard). Esquisse :

1. Le joueur doit jouer avant de lire.  
2. Chaque minute doit pouvoir produire un moment mémorable.  
3. Une hypothèse = un sprint.  
4. Les preuves priment sur les intuitions.  
5. La profondeur ne doit jamais masquer la simplicité.  
6. Chaque écran doit rapprocher du prochain Perfect.  
7. Le moteur ne change pas sans hypothèse validée.  
8. Le packaging doit promettre ce que le jeu délivre.  
9. Les nouveaux joueurs avant les vétérans.  
10. On optimise le plaisir avant la complexité.  

---

## GA4 — montage rapide

1. Explore → Free form / Funnel.  
2. Filtre `is_first_launch = 1`.  
3. Cartes : Activation Score + Niveau 1 + médianes + funnel.  
4. Période glissante 7 jours.

---

## Références

- Funnel : `lib/services/velour_activation_funnel.dart`  
- Backlog (évolutif) : `docs/PRODUCT_BACKLOG.md`  
- Observabilité technique : `docs/OBSERVABILITY_J1.md`  
- Ancien titre « Dashboard PBR » : `docs/ACTIVATION_PBR_DASHBOARD.md` → redirige ici

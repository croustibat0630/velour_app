# Fiches stores — textes localisés (Velour)

Ce dossier centralise les **textes marketing** à recopier dans **App Store Connect** et la **Google Play Console** pour chaque langue d’affichage du store (pas le texte in‑app : celui‑ci vient des fichiers `lib/l10n/*.arb`). Les accroches mettent en avant **défi / logique**, **classement**, **qualité visuelle (néon lisible)** et l’envie de relancer une run — le positionnement « luxe » reste dans le nom, pas comme seul argument.

**Où coller quoi :** chaque fichier `en.md`, `fr.md`, `de.md`, `zh-Hans.md`, `hi.md` commence par un **guide en français** (navigation + *locale* à sélectionner), puis sous chaque titre **##** une ligne *italique* en français indique le **champ console** correspondant, au-dessus du texte dans la langue du store.

À **chaque** préparation de build **store-ready** : **remplacer** dans ces fichiers les sections *Nouveautés* (App Store) et *Notes de version* (Play) par le contenu **réel** de la release et la version lue dans `pubspec.yaml` — obligation agent décrite dans `.cursor/rules/git-workflow.mdc` (§ Builds store) et cochée dans `docs/STORE_RELEASE_CHECKLIST.md` §2.

Les blocs **Nom**, **Sous-titre**, **Description**, etc. sont en **texte plat** (sans syntaxe Markdown : pas de `**` à coller dans les consoles — App Store et Play n’affichent pas le gras Markdown sur ces champs).

## Fichiers

| Fichier        | Usage typique                          |
|----------------|----------------------------------------|
| `en.md`        | Anglais (souvent langue par défaut)    |
| `fr.md`        | Français                               |
| `de.md`        | Allemand                               |
| `zh-Hans.md`   | Chinois **simplifié** (App Store + Play) |
| `hi.md`        | Hindi                                  |

## Limites à respecter (vérifier dans les consoles si Apple / Google les font évoluer)

### App Store Connect

- **Nom** : 30 caractères max (souvent un titre court type **Velour: Luxury Sort & Stack** pour l’ASO, ou **Velour** seul si la locale impose moins de place).
- **Sous-titre** : 30 caractères max.
- **Mots-clés** : 100 caractères max au total, **virgules sans espaces** (ex. `puzzle,neon,gem`).
- **Texte promotionnel** : 170 caractères max (optionnel).
- **Description** : 4000 caractères max.
- **Quoi de neuf** / *What’s New in This Version* : obligatoire **par langue** pour chaque version soumise ; des textes de départ sont dans chaque `*.md` (section « Nouveautés / What’s New »), à **rééditer à chaque release** pour refléter le binaire réel.

### Google Play Console

- **Titre** : 30 caractères max.
- **Courte description** : 80 caractères max.
- **Description complète** : 4000 caractères max.
- **Notes de version** (*Release notes*) : lors du **déploiement** d’une nouvelle version (AAB), par langue — pas sur la fiche principale seule ; propositions courtes en fin de chaque `*.md`.

## Procédure

1. Ouvrir la console du store → **App information** / **Présence sur le store** → ajouter la **langue** (ex. *Chinese (Simplified)*, *Hindi*).
2. Copier-coller les champs depuis le fichier `.md` correspondant (sections App Store et Play) ; pour chaque nouvelle version, mettre à jour aussi **Nouveautés** (App Store) et, au moment du rollout Play, les **notes de version** en fin de fichier.
3. Faire relire par un **natif** pour le ton premium (surtout zh-Hans et hi si générés ou brouillons rapides).
4. Vérifier que l’**URL de politique de confidentialité** et les **captures** sont cohérentes pour toutes les locales (même URL, visuels adaptés si besoin).

Référence checklist : `docs/STORE_RELEASE_CHECKLIST.md` (section métadonnées / légal).

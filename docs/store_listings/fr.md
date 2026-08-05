# Velour — où coller ces textes (guide en français)

Les titres ## reprennent les noms des champs dans la langue du fichier ; les lignes en *italique* indiquent où coller (toujours en français).

Les textes à publier (description, courtes descriptions, etc.) sont en texte plat : il n’y a plus de paires d’étoiles Markdown autour des mots — App Store Connect et la Play Console n’affichent pas le gras Markdown ; coller d’anciennes versions avec des étoiles ferait apparaître ces caractères aux joueurs.

Locale pour ce fichier : App Store Connect → Français (France) (ou autre variante francophone que tu as ajoutée) · Play Console → français (France).

### App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → Mes apps → Velour → menu App Store (pas *TestFlight*) → ta version iOS en préparation.
2. Section localisation : choisis la locale indiquée ci‑dessus. Si elle n’existe pas : Informations sur l’app → ajouter la langue, puis reviens sur la version.
3. Copie chaque bloc dans le champ du même type. Si l’interface Apple est en anglais : Nom = *Name*, Sous-titre = *Subtitle*, Mots-clés = *Keywords*, Texte promotionnel = *Promotional Text*, Description = *Description*, Nouveautés = *What’s New in This Version*.
4. Le texte promotionnel peut souvent être mis à jour sans nouvelle build (vérifier l’info dans la console au moment du collage).
5. Nouveautés de cette version : même page de localisation de la version iOS, champ obligatoire par langue — voir la section dédiée plus bas dans ce fichier (à adapter à chaque sortie ; version actuelle du dépôt : 1.2.3+21).

### Google Play Console

1. [Play Console](https://play.google.com/console) → Velour → Présence sur le Play Store → Fiches principales du store (parfois *Main store listing*).
2. Sélecteur de langue : celle indiquée dans *Locale pour ce fichier* → remplis Titre, Courte description, Description complète.
3. Lorsque tu publies une nouvelle version (AAB) : étape des notes de version (*Release notes* / par langue) — voir la section en fin de fichier ; ce n’est pas sur la fiche principale seule.

---

# App Store Connect (Français — fr-FR)

## Nom (30 max)

*Champ Nom App Store (*Name* si l’interface Apple est en anglais).*

Velour: Luxury Sort & Stack

## Sous-titre (30 max)

*Champ Sous-titre (*Subtitle*).*

Logique néon • Grimpe au top

## Mots-clés (100 max)

*Champ Mots-clés (*Keywords*) — une seule ligne, virgules sans espace après chaque virgule.*

puzzle,stratégie,neon,arcade,gems,LUX,classement,perfect,skill,défi,triple

## Texte promotionnel (170 max, optionnel)

*Champ Texte promotionnel (*Promotional Text*).*

Chaque run est un pari : lis le rack, enchaîne les clears, vise le Perfect avant la fin du chrono. Néon sombre, classement live—montre que tu ne plies pas.

## Description (4000 max)

*Champ Description (*Description*).*

Tu vois le rack. Le chrono, lui, ne négocie pas. Velour est un puzzle néon exigeant pensé en runs : chaque pose est un pari de logique—clears forme, couleur, et le Perfect (trois gemmes identiques) qui fait exploser le score et alimente la Heat pour des bonus LUX et des repêchages de temps au bon moment. Pour ceux qui veulent réfléchir vite, pas seulement taper vite.

Pourquoi tu relances
• Le défi d’abord : pression lisible—ne prends pas le triple « facile » si un Perfect est à une gemme.  
• Une beauté utile : plateau *dark matte*, gemmes néon nettes, motion lisible (respect du Réduire les mouvements).  
• Prouve-le au monde : ta meilleure run sur le classement mondial + nom Oracle quand l’invite arrive.

Les modes selon ton courage
• Classique pour affûter sans te ruiner.  
• High Stakes / Royal quand tu veux mises, objectifs et gains qui montent—nettement, ou pas du tout.

Meta
Dépense des LUX à la Boutique (skins, boosts de session—détail in-app). Bonus LUX quotidien sur le menu si éligible (règles serveur).

Confiance
Analytique / crash reporting possibles sur les builds store—voir la politique de confidentialité liée.

Télécharge si tu veux un duel de logique avec toi-même, un classement visible, et l’effet « encore une run »—puis assume le score.

## Nouveautés de cette version — App Store (obligatoire par langue)

*Sur la page de la version iOS (même localisation que Nom / Description) : champ « Nouveautés de cette version » ; en interface anglaise : What’s New in This Version. À remplir pour chaque langue de la version. Adapte le texte ci‑dessous à chaque release (réf. dépôt : 1.2.3+21).*

• Première partie : le parcours guidé mène jusqu’au Perfect, puis la run continue.
• Mesure d’activation améliorée ; correctifs et stabilité.

---

# Google Play Console (Français)

*Même navigation Play : Présence sur le Play Store → Fiches principales du store → langue = Locale pour ce fichier (en haut). Les trois champs ci‑dessous sont sur cette page.*

## Titre (30 max)

*Champ Titre (30 caractères max ; souvent aligné sur le nom App Store).*

Velour: Luxury Sort & Stack

## Courte description (80 max)

*Champ Courte description (80 caractères max).*

Puzzle néon nerveux : Perfects, LUX, classement mondial—pour relancer encore.

## Description complète (4000 max)

*Champ Description complète (jusqu’à 4000 caractères).*

Le plateau te juge. Le chrono tranche. Velour, c’est du puzzle / stratégie en runs sous tension : triples, Perfect, LUX, et une Heat qui récompense la précision quand le temps file.

Logique & sensation
Clears forme/couleur pour garder le contrôle ; trois gemmes identiques = Perfect + Heat pour monter en puissance. Interface néon sombre, lisible, pensée pour le stress « sain ».

Compétition
Classement mondial sur ta meilleure run, nom Oracle quand le jeu le propose.

Modes
Classique pour t’installer, High Stakes / Royal pour monter la mise.

LUX & shop
Skins, boosts, bonus quotidien (si éligible).

Confidentialité
Voir la politique liée (analytique / crash reporting possibles).

Tu aimes réfléchir vite, monter au classement, et assumer une run ? Touche Installer—et montre le jeu.

## Notes de version — Google Play (lors du déploiement d’une release)

*Ce champ n’est pas sur la fiche principale du store : il apparaît quand tu crées une release (Production ou test), après l’upload de l’AAB, à l’étape « Notes de version » / Release notes — choisir la même langue que ta fiche. Limite de longueur affichée dans la console (souvent courte) : raccourcir si besoin.*

• Première partie guidée jusqu’au Perfect, puis la run continue ; correctifs (v. 1.2.3).

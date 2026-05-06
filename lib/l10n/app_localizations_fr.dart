// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Velour';

  @override
  String get brandTitleDisplay => 'VELOUR';

  @override
  String get menuEditionSubtitle => 'ÉDITION DARK MATTE';

  @override
  String menuStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SÉRIE : $count JOURS',
      one: 'SÉRIE : 1 JOUR',
    );
    return '$_temp0';
  }

  @override
  String get menuPlay => 'COMMENCER';

  @override
  String get menuLeaderboard => 'CLASSEMENT MONDIAL';

  @override
  String get menuShop => 'BOUTIQUE';

  @override
  String get menuCareer => 'CARRIÈRE';

  @override
  String get menuSettings => 'PARAMÈTRES';

  @override
  String get menuGuidedTutorial => 'TUTORIEL';

  @override
  String luxHudPrefix(int highScore) {
    return 'MEILLEUR SCORE  $highScore   •   LUX';
  }

  @override
  String get settingsSectionLanguage => 'LANGUE';

  @override
  String get settingsLanguageRowTitle => 'Langue d’affichage';

  @override
  String get settingsLocaleSystem => 'Langue du système';

  @override
  String get settingsLocaleEnglish => 'English';

  @override
  String get settingsLocaleFrench => 'Français';

  @override
  String get settingsLocaleGerman => 'Allemand';

  @override
  String get settingsTitle => 'PARAMÈTRES';

  @override
  String get settingsSectionAudio => 'AUDIO';

  @override
  String get settingsMusicTitle => 'Musique';

  @override
  String get settingsMusicOn => 'Activée';

  @override
  String get settingsMusicOff => 'Désactivée';

  @override
  String get settingsSfxTitle => 'Effets sonores';

  @override
  String get settingsSfxOn => 'Activés';

  @override
  String get settingsSfxOff => 'Désactivés';

  @override
  String get settingsSectionHaptics => 'SENSATIONS';

  @override
  String get settingsHapticsTitle => 'Retour haptique';

  @override
  String get settingsHapticsOn => 'Actif (premium)';

  @override
  String get settingsHapticsOff => 'Désactivé';

  @override
  String get settingsSectionInfos => 'INFOS';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsCopyPlayerIdTitle => 'Copier l’ID joueur';

  @override
  String get settingsCopyPlayerIdSubtitle =>
      'Utile pour l’assistance et les bugs';

  @override
  String get settingsCopyPlayerIdFailed =>
      'ID joueur indisponible pour l’instant.';

  @override
  String settingsCopyPlayerIdSnack(String uid) {
    return 'Copié : $uid';
  }

  @override
  String get settingsPingServerTitle => 'État serveur';

  @override
  String get settingsPingServerSubtitle => 'Ping backend (velourHealth)';

  @override
  String get settingsPingServerOk => 'Serveur OK.';

  @override
  String get settingsPingServerFail =>
      'Serveur injoignable (réseau / App Check).';

  @override
  String get settingsCopyDiagnosticsTitle => 'Copier diagnostic';

  @override
  String get settingsCopyDiagnosticsSubtitle =>
      'Copie version, locale, ID joueur et état serveur';

  @override
  String get settingsCopyDiagnosticsSnack => 'Diagnostic copié.';

  @override
  String get luxCloudRejectedUpdateRequired =>
      'Sync LUX refusée. Mets l’app à jour. Si ça persiste, copie ton ID joueur dans Paramètres → Infos.';

  @override
  String get luxCloudRejectedTryLater =>
      'Sync LUX refusée. Réessaie plus tard.';

  @override
  String get luxCloudRejectedGeneric =>
      'Sync LUX en échec. Vérifie ta connexion.';

  @override
  String get settingsCreditsTitle => 'Crédits';

  @override
  String get settingsCreditsSubtitle => 'Voir les contributeurs';

  @override
  String get settingsSectionDebug => 'DEBUG';

  @override
  String get settingsResetTitle => 'RÉINITIALISER TOUT';

  @override
  String get settingsResetSubtitle =>
      'Efface le jeu (prefs) + relance le tutoriel';

  @override
  String get settingsResetSnack =>
      'Jeu réinitialisé. Relancez pour voir le tutoriel.';

  @override
  String get settingsFooterTagline => 'Dark Matte • Velour Accent';

  @override
  String get settingsCreditsDialogTitle => 'CRÉDITS';

  @override
  String get settingsCreditsBody =>
      'Velour — Dark Matte Edition\n\nDesign & direction : Velour Studio\nIngénierie : Flutter\nAudio : pack SFX Velour';

  @override
  String get settingsClose => 'FERMER';

  @override
  String get shopBackTooltip => 'Retour';

  @override
  String get shopVaultTitle => 'LE COFFRE-FORT';

  @override
  String get shopProductSparkReserve => 'RÉSERVE ÉCLAT';

  @override
  String get shopProductOracleTreasure => 'TRÉSOR DE L\'ORACLE';

  @override
  String get shopProductRoyalLegacy => 'L\'HÉRITAGE ROYAL';

  @override
  String get shopBadgeBestDeal => 'MEILLEURE OFFRE';

  @override
  String shopLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get shopForgeTitle => 'LA FORGE DE L\'ORACLE';

  @override
  String get shopSkinEquipped => 'Équipé';

  @override
  String get shopSkinOwned => 'Possédé';

  @override
  String shopPriceLux(int price) {
    return '$price LUX';
  }

  @override
  String get shopVaultLoading => 'COMMUNICATION AVEC LE COFFRE…';

  @override
  String get shopVaultPricePending => '—';

  @override
  String get shopPurchaseSuccess => 'SUCCÈS';

  @override
  String shopPurchaseLuxAdded(int lux) {
    return '+$lux LUX';
  }

  @override
  String get shopBackToGame => 'RETOUR AU JEU';

  @override
  String get shopSnackInsufficientLux => 'LUX insuffisants.';

  @override
  String get shopSnackSkinEquipped => 'Skin équipé.';

  @override
  String get shopSnackSkinUnlocked => 'Skin déverrouillé et équipé.';

  @override
  String get shopForgeBoostsSection => 'BOOSTS DE SESSION';

  @override
  String get shopForgeSectionRunSalvage => 'SAUVETAGE DE RUN';

  @override
  String get shopForgeSectionStrategyStakes => 'STRATÉGIE & ENJEUX';

  @override
  String get shopForgeInsuranceTitle => 'ASSURANCE ORACLE';

  @override
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  ) {
    return 'Si tu perds ta prochaine partie High Stakes (mise $highAnte LUX) ou Royal (mise $royalAnte LUX), l’Oracle rembourse $refundPct % de cette entrée. Jusqu’à $maxCharges charges.';
  }

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopForgeRoyalBountyTitle => 'PRIME ROYALE';

  @override
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux) {
    return '+$bonusLux LUX bonus sur ta prochaine victoire Royal une fois l’objectif atteint (en plus du gain habituel de $royalWinLux LUX). Une prime active à la fois.';
  }

  @override
  String get shopForgeRoyalBountyActive =>
      'Active — prochaine victoire Royal paie un bonus';

  @override
  String get shopSnackForgeInsurancePurchased => 'Charge d’assurance ajoutée.';

  @override
  String get shopSnackForgeRoyalBountyPurchased =>
      'Prime royale active pour ta prochaine victoire Royal.';

  @override
  String get shopSnackForgeInsuranceFull => 'Tu as déjà 3 charges d’assurance.';

  @override
  String get shopSnackForgeRoyalBountyActive =>
      'Une prime royale est déjà active.';

  @override
  String get shopForgeChronoPulseTitle => 'RÉSERVE CHRONO';

  @override
  String shopForgeChronoPulseBody(int maxCharges) {
    return 'Quand le chrono de la session tombe à zéro, une charge remplit la barre à fond et tu restes en jeu. Jusqu’à $maxCharges charges. Inactif pendant les tutoriels.';
  }

  @override
  String shopForgeChronoPulseCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopForgeMercySalvageTitle => 'CLÉMENCE DE L\'ORACLE';

  @override
  String shopForgeMercySalvageBody(int maxCharges) {
    return 'Rack plein sans match possible : une charge forge un triplet jouable en bout de rack pour continuer. Jusqu’à $maxCharges charges. Inactif pendant les tutoriels.';
  }

  @override
  String shopForgeMercySalvageCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopSnackForgeChronoPulsePurchased =>
      'Charge réserve chrono ajoutée.';

  @override
  String get shopSnackForgeChronoPulseFull => 'Tu as déjà 2 charges chrono.';

  @override
  String get shopSnackForgeMercySalvagePurchased => 'Charge clémence ajoutée.';

  @override
  String get shopSnackForgeMercySalvageFull => 'Tu as déjà 2 charges clémence.';

  @override
  String get shopIapUnavailable =>
      'Achats intégrés indisponibles sur cet appareil.';

  @override
  String get shopIapProductsUnavailable =>
      'Packs LUX indisponibles pour le moment.';

  @override
  String get shopIapCancelled => 'Achat annulé.';

  @override
  String get shopIapOffline =>
      'Pas de connexion Internet. Désactive le mode avion et réessaie.';

  @override
  String shopIapError(String details) {
    return 'Erreur de paiement : $details';
  }

  @override
  String get statsTitle => 'MA CARRIÈRE';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SÉRIE · $count JOURS',
      one: 'SÉRIE · 1 JOUR',
    );
    return '$_temp0';
  }

  @override
  String get statsLuxEarned => 'LUX GAGNÉS';

  @override
  String get statsBestGain => 'MEILLEUR GAIN';

  @override
  String get statsMaxLevel => 'NIVEAU MAX';

  @override
  String get statsShapesPlaced => 'FORMES POSÉES';

  @override
  String get statsMatches => 'MATCHES';

  @override
  String get statsTotalTime => 'TEMPS TOTAL';

  @override
  String get statsPrecisionTitle => 'PRÉCISION';

  @override
  String get statsPrecisionHelp =>
      'Ratio matches / placements.\nPlus c’est haut, plus tes runs sont « propres ».';

  @override
  String get statsModesTitle => 'RÉPARTITION DES MODES';

  @override
  String get statsModeCasual => 'CASUAL';

  @override
  String get statsModeHighStakes => 'HIGH STAKES';

  @override
  String get statsModeRoyal => 'ROYAL';

  @override
  String get gameHudMenuTooltip => 'Menu';

  @override
  String get pauseTitle => 'PAUSE';

  @override
  String get pauseResume => 'CONTINUER';

  @override
  String get pauseBackToMenu => 'RETOUR AU MENU';

  @override
  String get premiumForfeitTitle => 'FORFAIT ?';

  @override
  String premiumForfeitLead(String session) {
    return 'En quittant cette session $session, vous allez perdre définitivement votre mise de ';
  }

  @override
  String get premiumForfeitTrail => ' LUX.';

  @override
  String get premiumSessionHighStakes => 'High Stakes';

  @override
  String get premiumSessionRoyal => 'Royale';

  @override
  String get premiumStay => 'RESTER';

  @override
  String get premiumForfeit => 'FORFAIT';

  @override
  String get gameOverTitleSessionEnd => 'SESSION TERMINÉE';

  @override
  String get gameOverTitleVictory => 'VICTOIRE';

  @override
  String get gameOverTitleDefeat => 'ÉCHEC';

  @override
  String get gameOverSessionScore => 'SCORE DE LA PARTIE';

  @override
  String get gameOverZeroLuxHintCasual =>
      'Aucun LUX de match sur cette session — chrono écoulé ou retour menu avant le premier gain.';

  @override
  String get gameOverZeroLuxHintHighStakes =>
      'Aucun LUX encaissé avant la fin — objectif non atteint ou temps écoulé.';

  @override
  String get gameOverZeroLuxHintRoyal =>
      'Aucun LUX encaissé avant la fin — objectif non atteint ou temps écoulé.';

  @override
  String get gameOverFinalScore => 'SCORE FINAL';

  @override
  String get gameOverLuxWon => 'LUX REMPORTÉS';

  @override
  String get gameOverPersonalBest => 'NOUVEAU RECORD PERSONNEL';

  @override
  String get gameOverReplay => 'REJOUER';

  @override
  String get gameOverMainMenu => 'MENU PRINCIPAL';

  @override
  String get gameOverPrestigeBonus => 'BONUS PRESTIGE';

  @override
  String get gameOverFooterHighStakesFail => 'ÉCHEC DU PARI : MISE PERDUE';

  @override
  String get gameOverFooterHighStakesWin150 => 'VOUS GAGNEZ 150 LUX';

  @override
  String get gameOverFooterRoyalFail => 'ÉCHEC DU PARI ROYAL : MISE PERDUE';

  @override
  String get gameOverFooterRoyalWin1250 => 'VOUS GAGNEZ 1250 LUX';

  @override
  String get gameOverOracleInsuranceTitle => 'COUVERTURE ORACLE';

  @override
  String gameOverOracleInsuranceRefund(int lux) {
    return '+$lux LUX rendus dans ta besace';
  }

  @override
  String get oracleDockStep1Shape =>
      'Forme = +100 LUX (min.)\nMême silhouette • 3 couleurs → rack';

  @override
  String get oracleDockStep2Color =>
      'Couleur = +150 LUX\nMême teinte • 3 formes → rack';

  @override
  String get oracleDockStep3Perfect =>
      'Parfait = +500 LUX\n3 gemmes identiques → rack';

  @override
  String get oracleDockCelebration =>
      '100 < 150 < 500 LUX\nVise le parfait en priorité.';

  @override
  String get oracleDockStep1StrategyLine =>
      'D’abord : une silhouette, trois teintes différentes.';

  @override
  String get oracleDockStep2StrategyLine =>
      'Pas de triple facile si le parfait est à une gemme.';

  @override
  String get oracleDockStep3StrategyLine =>
      'Trois gemmes identiques : le gros score de ce coup.';

  @override
  String get oracleDockCelebrationStrategyLine =>
      'Ensuite : le chrono pèse sur chaque choix.';

  @override
  String get tutorialTrinityShapeIntro =>
      'La forme est la structure. Regroupez-les.';

  @override
  String get tutorialTrinityColorIntro =>
      'La couleur est l\'harmonie. Elle crée des opportunités.';

  @override
  String get tutorialTrinityPerfectIntro =>
      'Le Perfect Match : L\'union absolue. Déclenche l\'éclat LUX.';

  @override
  String get narrativeFloatShapeBonus => '+100 LUX : STRUCTURE (FORME)';

  @override
  String get narrativeFloatColorBonus => '+150 LUX : HARMONIE (COULEUR)';

  @override
  String get narrativeFloatPerfectBonus => '+500 LUX : ÉCLAT TOTAL';

  @override
  String get gameNarrativePerfectMatchBanner => 'MATCH PARFAIT';

  @override
  String get prepTitle => 'PRÉPARATION DE SESSION';

  @override
  String get prepGuidedTutorialCasualOnly =>
      'Seul le mode classique est proposé pour ce tutoriel.';

  @override
  String get prepGuidedTutorialGoalTitle => 'L’objectif';

  @override
  String get prepGuidedTutorialGoalBody =>
      'Chaque match ajoute des LUX en partie et fait monter le niveau. Les matchs « plus riches » — surtout le parfait — valent beaucoup plus qu’une petite combinaison : le jeu, c’est surtout le timing et le bon choix de match.';

  @override
  String get prepGuidedTutorialStrategyTitle => 'Lire le rack avant d’agir';

  @override
  String get prepGuidedTutorialStrategyBody =>
      'Avant de valider une 3ᵉ gemme, regarde la suite : si tu es à une gemme d’un triplet identique (même forme et même couleur), un match « couleur seule » peut casser ta mise en place et te faire perdre énormément de potentiel.\n\nIci le chrono est figé pour t’entraîner au calme ; en partie réelle, trop hésiter coûte aussi du temps.';

  @override
  String get prepModeCasualTitle => 'MODE CLASSIQUE';

  @override
  String prepModeCasualBody(int ante) {
    return 'Mise : $ante LUX. Entraînement libre.';
  }

  @override
  String get prepModeHighStakesTitle => 'HIGH STAKES';

  @override
  String prepModeHighStakesBody(int ante, int goal, int reward) {
    return 'Mise : $ante LUX. Objectif : niveau $goal. Récompense : $reward LUX.';
  }

  @override
  String get prepModeRoyalTitle => 'VELOUR ROYAL';

  @override
  String prepModeRoyalBody(int ante, int goal, int reward) {
    return 'Mise : $ante LUX. Objectif : niveau $goal. Récompense : $reward LUX.';
  }

  @override
  String get prepInsufficientLux => 'Solde LUX insuffisant.';

  @override
  String get prepConfirm => 'CONFIRMER';

  @override
  String get prepBuyLux => 'ACHETER DES LUX';

  @override
  String get prepSelectedChip => 'SÉLECTIONNÉ';

  @override
  String get leaderboardTitle => 'CLASSEMENT MONDIAL';

  @override
  String get leaderboardColRank => 'RANG';

  @override
  String get leaderboardColPlayer => 'JOUEUR';

  @override
  String get leaderboardColScore => 'SCORE';

  @override
  String leaderboardError(String details) {
    return 'Classement indisponible pour le moment.\nVérifiez la connexion ou les règles Firestore.\n($details)';
  }

  @override
  String get leaderboardLoading => 'Chargement du classement…';

  @override
  String get leaderboardEmpty => 'Aucun score enregistré pour l\'instant.';

  @override
  String get leaderboardYourRankFooter => 'VOTRE RANG';

  @override
  String leaderboardPlayerAnon(String id) {
    return 'Joueur $id';
  }

  @override
  String get leaderboardPodiumFirst => 'Premier du classement';

  @override
  String get leaderboardPodiumSecond => 'Deuxième du classement';

  @override
  String get leaderboardPodiumThird => 'Troisième du classement';

  @override
  String get leaderboardPodiumOther => 'Podium';

  @override
  String gameFloatLuxGain(int gain) {
    return '+$gain LUX';
  }

  @override
  String gameFloatLuxGainMult(int gain, String mult) {
    return '+$gain LUX ×$mult';
  }

  @override
  String gameFloatPerfectGain(int gain) {
    return '+$gain PARFAIT';
  }

  @override
  String gameFloatPerfectGainMult(int gain, String mult) {
    return '+$gain PARFAIT ×$mult';
  }

  @override
  String gameFloatCombo(String mult) {
    return 'COMBO ×$mult';
  }

  @override
  String get gameHudScore => 'SCORE';

  @override
  String get gameHudTime => 'TEMPS';

  @override
  String gameHudLevelShort(int level) {
    return 'NIV $level';
  }

  @override
  String gameHudLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get gameHudLuxThisRun => 'PARTIE';

  @override
  String get gameHudLevelTag => 'NIV';

  @override
  String get gameHudLevelUpTitle => 'NIVEAU ATTEINT !';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'NIVEAU $level';
  }

  @override
  String gameHudForgeChronoA11y(int count) {
    return 'Réserve chrono, $count charges';
  }

  @override
  String gameHudForgeMercyA11y(int count) {
    return 'Clémence de l\'Oracle, $count charges';
  }
}

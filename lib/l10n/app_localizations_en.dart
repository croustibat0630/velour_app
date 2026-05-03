// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Velour';

  @override
  String get brandTitleDisplay => 'VELOUR';

  @override
  String get menuEditionSubtitle => 'DARK MATTE EDITION';

  @override
  String menuStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STREAK: $count DAYS',
      one: 'STREAK: 1 DAY',
    );
    return '$_temp0';
  }

  @override
  String get menuPlay => 'PLAY';

  @override
  String get menuLeaderboard => 'WORLD LEADERBOARD';

  @override
  String get menuShop => 'SHOP';

  @override
  String get menuCareer => 'CAREER';

  @override
  String get menuSettings => 'SETTINGS';

  @override
  String luxHudPrefix(int highScore) {
    return 'HIGH SCORE  $highScore   •   LUX COINS';
  }

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageRowTitle => 'Display language';

  @override
  String get settingsLocaleSystem => 'System default';

  @override
  String get settingsLocaleEnglish => 'English';

  @override
  String get settingsLocaleFrench => 'French';

  @override
  String get settingsLocaleGerman => 'German';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsSectionAudio => 'AUDIO';

  @override
  String get settingsMusicTitle => 'Music';

  @override
  String get settingsMusicOn => 'On';

  @override
  String get settingsMusicOff => 'Off';

  @override
  String get settingsSfxTitle => 'Sound effects';

  @override
  String get settingsSfxOn => 'On';

  @override
  String get settingsSfxOff => 'Off';

  @override
  String get settingsSectionHaptics => 'HAPTICS';

  @override
  String get settingsHapticsTitle => 'Haptic feedback';

  @override
  String get settingsHapticsOn => 'On (premium)';

  @override
  String get settingsHapticsOff => 'Off';

  @override
  String get settingsSectionInfos => 'INFO';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsCreditsTitle => 'Credits';

  @override
  String get settingsCreditsSubtitle => 'See contributors';

  @override
  String get settingsSectionDebug => 'DEBUG';

  @override
  String get settingsResetTitle => 'RESET ALL';

  @override
  String get settingsResetSubtitle =>
      'Clears game data (prefs) and restarts onboarding';

  @override
  String get settingsResetSnack =>
      'Game reset. Relaunch the app to see the tutorial.';

  @override
  String get settingsFooterTagline => 'Dark Matte • Velour Accent';

  @override
  String get settingsCreditsDialogTitle => 'CREDITS';

  @override
  String get settingsCreditsBody =>
      'Velour — Dark Matte Edition\n\nDesign & direction: Velour Studio\nEngineering: Flutter\nAudio: Velour SFX Pack';

  @override
  String get settingsClose => 'CLOSE';

  @override
  String get shopBackTooltip => 'Back';

  @override
  String get shopVaultTitle => 'THE VAULT';

  @override
  String get shopProductSparkReserve => 'SPARK RESERVE';

  @override
  String get shopProductOracleTreasure => 'ORACLE\'S TREASURE';

  @override
  String get shopProductRoyalLegacy => 'ROYAL LEGACY';

  @override
  String get shopBadgeBestDeal => 'BEST DEAL';

  @override
  String shopLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get shopForgeTitle => 'THE ORACLE FORGE';

  @override
  String get shopSkinEquipped => 'Equipped';

  @override
  String get shopSkinOwned => 'Owned';

  @override
  String shopPriceLux(int price) {
    return '$price LUX';
  }

  @override
  String get shopVaultLoading => 'CONTACTING THE VAULT…';

  @override
  String get shopPurchaseSuccess => 'SUCCESS';

  @override
  String shopPurchaseLuxAdded(int lux) {
    return '+$lux LUX';
  }

  @override
  String get shopBackToGame => 'BACK TO GAME';

  @override
  String get shopSnackInsufficientLux => 'Not enough LUX.';

  @override
  String get shopSnackSkinEquipped => 'Skin equipped.';

  @override
  String get shopSnackSkinUnlocked => 'Skin unlocked and equipped.';

  @override
  String get statsTitle => 'MY CAREER';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STREAK: $count DAYS WITH A RUN',
      one: 'STREAK: 1 DAY WITH A RUN',
    );
    return '$_temp0';
  }

  @override
  String get statsLuxEarned => 'LUX EARNED';

  @override
  String get statsBestGain => 'BEST WIN';

  @override
  String get statsMaxLevel => 'MAX LEVEL';

  @override
  String get statsShapesPlaced => 'SHAPES PLACED';

  @override
  String get statsMatches => 'MATCHES';

  @override
  String get statsTotalTime => 'TOTAL TIME';

  @override
  String get statsPrecisionTitle => 'ACCURACY';

  @override
  String get statsPrecisionHelp =>
      'Match-to-placement ratio.\nHigher means cleaner runs.';

  @override
  String get statsModesTitle => 'MODE SPLIT';

  @override
  String get statsModeCasual => 'CASUAL';

  @override
  String get statsModeHighStakes => 'HIGH STAKES';

  @override
  String get statsModeRoyal => 'ROYAL';

  @override
  String get gameHudMenuTooltip => 'Menu';

  @override
  String get pauseTitle => 'PAUSED';

  @override
  String get pauseResume => 'RESUME';

  @override
  String get pauseBackToMenu => 'BACK TO MENU';

  @override
  String get premiumForfeitTitle => 'FORFEIT?';

  @override
  String premiumForfeitLead(String session) {
    return 'If you leave this $session session, you forfeit your stake of ';
  }

  @override
  String get premiumForfeitTrail => ' LUX permanently.';

  @override
  String get premiumSessionHighStakes => 'High Stakes';

  @override
  String get premiumSessionRoyal => 'Royal';

  @override
  String get premiumStay => 'STAY';

  @override
  String get premiumForfeit => 'FORFEIT';

  @override
  String get gameOverTitleSessionEnd => 'SESSION COMPLETE';

  @override
  String get gameOverTitleVictory => 'VICTORY';

  @override
  String get gameOverTitleDefeat => 'DEFEAT';

  @override
  String get gameOverSessionScore => 'SESSION SCORE';

  @override
  String get gameOverZeroLuxHintCasual =>
      'No match LUX this session — timer ran out or you left before the first gain.';

  @override
  String get gameOverZeroLuxHintHighStakes =>
      'No LUX banked before the end — goal not reached or time ran out.';

  @override
  String get gameOverZeroLuxHintRoyal =>
      'No LUX banked before the end — goal not reached or time ran out.';

  @override
  String get gameOverFinalScore => 'FINAL SCORE';

  @override
  String get gameOverLuxWon => 'LUX WON';

  @override
  String get gameOverPersonalBest => 'NEW PERSONAL BEST';

  @override
  String get gameOverReplay => 'PLAY AGAIN';

  @override
  String get gameOverMainMenu => 'MAIN MENU';

  @override
  String get gameOverPrestigeBonus => 'PRESTIGE BONUS';

  @override
  String get gameOverFooterHighStakesFail => 'BET LOST: STAKE FORFEITED';

  @override
  String get gameOverFooterHighStakesWin150 => 'YOU WIN 150 LUX';

  @override
  String get gameOverFooterRoyalFail => 'ROYAL BET LOST: STAKE FORFEITED';

  @override
  String get gameOverFooterRoyalWin1250 => 'YOU WIN 1250 LUX';

  @override
  String get oracleDockStep1Shape =>
      'Shape = +100 LUX (min.)\nSame silhouette • 3 colors → rack';

  @override
  String get oracleDockStep2Color =>
      'Color = +150 LUX\nSame hue • 3 shapes → rack';

  @override
  String get oracleDockStep3Perfect =>
      'Perfect = +500 LUX\n3 identical gems → rack';

  @override
  String get oracleDockCelebration =>
      '100 < 150 < 500 LUX\nAim for perfect first.';

  @override
  String get tutorialTrinityShapeIntro => 'Shape is structure. Group them.';

  @override
  String get tutorialTrinityColorIntro =>
      'Color is harmony. It creates opportunities.';

  @override
  String get tutorialTrinityPerfectIntro =>
      'The Perfect Match: absolute union. Triggers the LUX burst.';

  @override
  String get narrativeFloatShapeBonus => '+100 LUX : STRUCTURE (SHAPE)';

  @override
  String get narrativeFloatColorBonus => '+150 LUX : HARMONY (COLOR)';

  @override
  String get narrativeFloatPerfectBonus => '+500 LUX : TOTAL BRILLIANCE';

  @override
  String get gameNarrativePerfectMatchBanner => 'PERFECT MATCH';

  @override
  String get prepTitle => 'SESSION SETUP';

  @override
  String get prepModeCasualTitle => 'CLASSIC MODE';

  @override
  String prepModeCasualBody(int ante) {
    return 'Stake: $ante LUX. Free practice.';
  }

  @override
  String get prepModeHighStakesTitle => 'HIGH STAKES';

  @override
  String prepModeHighStakesBody(int ante, int goal, int reward) {
    return 'Stake: $ante LUX. Goal: Level $goal. Reward: $reward LUX.';
  }

  @override
  String get prepModeRoyalTitle => 'VELOUR ROYAL';

  @override
  String prepModeRoyalBody(int ante, int goal, int reward) {
    return 'Stake: $ante LUX. Goal: Level $goal. Reward: $reward LUX.';
  }

  @override
  String get prepInsufficientLux => 'Insufficient LUX balance.';

  @override
  String get prepConfirm => 'CONFIRM';

  @override
  String get prepBuyLux => 'BUY LUX';

  @override
  String get prepSelectedChip => 'SELECTED';

  @override
  String get leaderboardTitle => 'WORLD LEADERBOARD';

  @override
  String get leaderboardColRank => 'RANK';

  @override
  String get leaderboardColPlayer => 'PLAYER';

  @override
  String get leaderboardColScore => 'SCORE';

  @override
  String leaderboardError(String details) {
    return 'Leaderboard unavailable for now.\nCheck your connection or Firestore rules.\n($details)';
  }

  @override
  String get leaderboardLoading => 'Loading rankings…';

  @override
  String get leaderboardEmpty => 'No scores recorded yet.';

  @override
  String get leaderboardYourRankFooter => 'YOUR RANK';

  @override
  String leaderboardPlayerAnon(String id) {
    return 'Player $id';
  }

  @override
  String get leaderboardPodiumFirst => 'First place';

  @override
  String get leaderboardPodiumSecond => 'Second place';

  @override
  String get leaderboardPodiumThird => 'Third place';

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
    return '+$gain PERFECT';
  }

  @override
  String gameFloatPerfectGainMult(int gain, String mult) {
    return '+$gain PERFECT ×$mult';
  }

  @override
  String gameFloatCombo(String mult) {
    return 'COMBO ×$mult';
  }

  @override
  String get gameHudScore => 'SCORE';

  @override
  String get gameHudTime => 'TIME';

  @override
  String gameHudLevelShort(int level) {
    return 'LV $level';
  }

  @override
  String gameHudLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get gameHudLevelTag => 'LEVEL';

  @override
  String get gameHudLevelUpTitle => 'LEVEL UP!';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'LEVEL $level';
  }
}

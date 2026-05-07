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
  String menuDailyLuxBonus(int amount) {
    return '+$amount LUX — Daily bonus';
  }

  @override
  String get menuDailyLuxBonusSuccess => 'Daily bonus claimed.';

  @override
  String get menuDailyLuxBonusQueued =>
      'Bonus saved — it will sync when you are online.';

  @override
  String get menuDailyLuxBonusSynced => 'Balance synced from the server.';

  @override
  String get menuDailyLuxBonusAlready => 'Already claimed today.';

  @override
  String get menuDailyLuxBonusRetry => 'Could not reach the server. Try again.';

  @override
  String get menuLeaderboard => 'WORLD LEADERBOARD';

  @override
  String get menuShop => 'SHOP';

  @override
  String get menuCareer => 'CAREER';

  @override
  String get menuSettings => 'SETTINGS';

  @override
  String get menuGuidedTutorial => 'TUTORIAL';

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
  String get settingsCopyPlayerIdTitle => 'Copy player ID';

  @override
  String get settingsCopyPlayerIdSubtitle =>
      'Useful for support and bug reports';

  @override
  String get settingsCopyPlayerIdFailed => 'Player ID not available yet.';

  @override
  String settingsCopyPlayerIdSnack(String uid) {
    return 'Copied: $uid';
  }

  @override
  String get settingsPingServerTitle => 'Server status';

  @override
  String get settingsPingServerSubtitle => 'Ping backend (velourHealth)';

  @override
  String get settingsPingServerOk => 'Server OK.';

  @override
  String get settingsPingServerFail =>
      'Server unreachable (check network / App Check).';

  @override
  String get settingsCopyDiagnosticsTitle => 'Copy diagnostics';

  @override
  String get settingsCopyDiagnosticsSubtitle =>
      'Copy version, locale, player ID and server status';

  @override
  String get settingsCopyDiagnosticsSnack => 'Diagnostics copied.';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'Open in browser';

  @override
  String get settingsPrivacyPolicyLaunchFail => 'Could not open link.';

  @override
  String get luxCloudRejectedUpdateRequired =>
      'LUX sync rejected. Please update the app. If it persists, copy your player ID in Settings → Info.';

  @override
  String get luxCloudRejectedTryLater =>
      'LUX sync rejected. Please try again later.';

  @override
  String get luxCloudRejectedGeneric =>
      'LUX sync failed. Check network and try again.';

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
  String get shopVaultPricePending => '—';

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
  String get shopForgeBoostsSection => 'SESSION BOOSTS';

  @override
  String get shopForgeSectionRunSalvage => 'RUN SALVAGE';

  @override
  String get shopForgeSectionStrategyStakes => 'STRATEGY & STAKES';

  @override
  String get shopForgeInsuranceTitle => 'ORACLE INSURANCE';

  @override
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  ) {
    return 'If you lose your next High Stakes ($highAnte LUX ante) or Royal ($royalAnte LUX ante) run, the Oracle refunds $refundPct% of that entry stake. Stack up to $maxCharges charges.';
  }

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopForgeRoyalBountyTitle => 'ROYAL BOUNTY';

  @override
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux) {
    return '+$bonusLux bonus LUX on your next Royal win once you clear the Royal objective (in addition to the usual $royalWinLux LUX win payout). One active bounty at a time.';
  }

  @override
  String get shopForgeRoyalBountyActive => 'Active — next Royal win pays extra';

  @override
  String get shopSnackForgeInsurancePurchased => 'Insurance charge added.';

  @override
  String get shopSnackForgeRoyalBountyPurchased =>
      'Royal bounty active for your next Royal win.';

  @override
  String get shopSnackForgeInsuranceFull =>
      'You already hold 3 insurance charges.';

  @override
  String get shopSnackForgeRoyalBountyActive =>
      'Royal bounty is already active.';

  @override
  String get shopForgeChronoPulseTitle => 'CHRONO RESERVE';

  @override
  String shopForgeChronoPulseBody(int maxCharges) {
    return 'When the session timer hits zero, one charge refills the bar to full so the run continues. Stack up to $maxCharges charges. Inactive during tutorials.';
  }

  @override
  String shopForgeChronoPulseCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopForgeMercySalvageTitle => 'ORACLE\'S MERCY';

  @override
  String shopForgeMercySalvageBody(int maxCharges) {
    return 'Rack full with no valid match: one charge reshapes the end of your rack into a playable triple so you keep going. Stack up to $maxCharges charges. Inactive during tutorials.';
  }

  @override
  String shopForgeMercySalvageCharges(int count, int max) {
    return '$count / $max charges';
  }

  @override
  String get shopSnackForgeChronoPulsePurchased =>
      'Chrono reserve charge added.';

  @override
  String get shopSnackForgeChronoPulseFull =>
      'You already hold 2 chrono charges.';

  @override
  String get shopSnackForgeMercySalvagePurchased =>
      'Mercy salvage charge added.';

  @override
  String get shopSnackForgeMercySalvageFull =>
      'You already hold 2 mercy charges.';

  @override
  String get shopIapUnavailable =>
      'In-app purchases are not available on this device.';

  @override
  String get shopIapProductsUnavailable =>
      'LUX packs are unavailable from the store right now.';

  @override
  String get shopIapCancelled => 'Purchase cancelled.';

  @override
  String get shopIapOffline =>
      'No internet connection. Please disable Airplane Mode and try again.';

  @override
  String shopIapError(String details) {
    return 'Payment error: $details';
  }

  @override
  String get shopIapErrorBusy =>
      'Another purchase is already in progress. Please wait.';

  @override
  String get shopIapErrorUnknown =>
      'Something went wrong with the payment. Please try again.';

  @override
  String get shopIapErrorServerVerificationFailed =>
      'We could not verify this purchase with the server. Check your connection and try again.';

  @override
  String get shopIapErrorDuplicateTransaction =>
      'This purchase was already processed.';

  @override
  String get shopIapErrorRestoredIgnored =>
      'Restored purchases do not grant LUX for consumable packs.';

  @override
  String get statsTitle => 'MY CAREER';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STREAK · $count DAYS',
      one: 'STREAK · 1 DAY',
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
  String gameOverCareerRecordHint(int high) {
    return 'Career record (saved): $high';
  }

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
  String get gameOverOracleInsuranceTitle => 'ORACLE COVER';

  @override
  String gameOverOracleInsuranceRefund(int lux) {
    return '+$lux LUX returned to your purse';
  }

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
  String get oracleDockStep1StrategyLine =>
      'First: one silhouette, three different colors.';

  @override
  String get oracleDockStep2StrategyLine =>
      'Don\'t take a weak triple if a perfect is one gem away.';

  @override
  String get oracleDockStep3StrategyLine =>
      'Three identical gems = the biggest payout here.';

  @override
  String get oracleDockCelebrationStrategyLine =>
      'Later: the timer turns every second into a choice.';

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
  String get prepGuidedTutorialCasualOnly =>
      'Only Classic mode is available for this tutorial.';

  @override
  String get prepGuidedTutorialGoalTitle => 'What you\'re building toward';

  @override
  String get prepGuidedTutorialGoalBody =>
      'Each match adds in-run LUX and pushes your level. Richer match types—especially a perfect—pay far more than weaker triples. The real skill is choosing which clear you take and when.';

  @override
  String get prepGuidedTutorialStrategyTitle => 'Think before the third gem';

  @override
  String get prepGuidedTutorialStrategyBody =>
      'Before you commit a third gem, read your rack: if you are one gem away from three identical gems (same shape and same color), grabbing an easier color-only triple can break the setup and leave a lot of LUX on the table.\n\nIn this walkthrough the timer stays paused so you can practice calmly. In a real run, waiting has a cost—pressure and reward trade off.';

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
  String get gameHudLuxThisRun => 'THIS RUN';

  @override
  String get gameHudLevelTag => 'LEVEL';

  @override
  String get gameHudLevelUpTitle => 'LEVEL UP!';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'LEVEL $level';
  }

  @override
  String gameHudForgeChronoA11y(int count) {
    return 'Chrono reserve, $count charges';
  }

  @override
  String gameHudForgeMercyA11y(int count) {
    return 'Oracle mercy, $count charges';
  }
}

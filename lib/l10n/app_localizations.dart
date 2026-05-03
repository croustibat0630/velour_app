import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Application name shown in the window / task switcher.
  ///
  /// In en, this message translates to:
  /// **'Velour'**
  String get appTitle;

  /// Logo-style app name on splash and main menu (uppercase).
  ///
  /// In en, this message translates to:
  /// **'VELOUR'**
  String get brandTitleDisplay;

  /// Subtitle under the logo on the main menu.
  ///
  /// In en, this message translates to:
  /// **'DARK MATTE EDITION'**
  String get menuEditionSubtitle;

  /// Daily play streak on the main menu.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{STREAK: 1 DAY} other{STREAK: {count} DAYS}}'**
  String menuStreakDays(int count);

  /// Main menu: start a run.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get menuPlay;

  /// Main menu: online rankings.
  ///
  /// In en, this message translates to:
  /// **'WORLD LEADERBOARD'**
  String get menuLeaderboard;

  /// Main menu: cosmetics store.
  ///
  /// In en, this message translates to:
  /// **'SHOP'**
  String get menuShop;

  /// Main menu: stats / progression.
  ///
  /// In en, this message translates to:
  /// **'CAREER'**
  String get menuCareer;

  /// Main menu: settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get menuSettings;

  /// Prefix line above animated LUX balance (high score + label).
  ///
  /// In en, this message translates to:
  /// **'HIGH SCORE  {highScore}   •   LUX COINS'**
  String luxHudPrefix(int highScore);

  /// Settings: section title for locale.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsSectionLanguage;

  /// Settings: label next to the locale dropdown.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsLanguageRowTitle;

  /// Settings: follow device language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLocaleSystem;

  /// No description provided for @settingsLocaleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLocaleEnglish;

  /// No description provided for @settingsLocaleFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLocaleFrench;

  /// Settings screen main heading.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAudio.
  ///
  /// In en, this message translates to:
  /// **'AUDIO'**
  String get settingsSectionAudio;

  /// No description provided for @settingsMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusicTitle;

  /// No description provided for @settingsMusicOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsMusicOn;

  /// No description provided for @settingsMusicOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsMusicOff;

  /// No description provided for @settingsSfxTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSfxTitle;

  /// No description provided for @settingsSfxOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsSfxOn;

  /// No description provided for @settingsSfxOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsSfxOff;

  /// No description provided for @settingsSectionHaptics.
  ///
  /// In en, this message translates to:
  /// **'HAPTICS'**
  String get settingsSectionHaptics;

  /// No description provided for @settingsHapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHapticsTitle;

  /// No description provided for @settingsHapticsOn.
  ///
  /// In en, this message translates to:
  /// **'On (premium)'**
  String get settingsHapticsOn;

  /// No description provided for @settingsHapticsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsHapticsOff;

  /// No description provided for @settingsSectionInfos.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get settingsSectionInfos;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

  /// No description provided for @settingsCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCreditsTitle;

  /// No description provided for @settingsCreditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See contributors'**
  String get settingsCreditsSubtitle;

  /// No description provided for @settingsSectionDebug.
  ///
  /// In en, this message translates to:
  /// **'DEBUG'**
  String get settingsSectionDebug;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clears game data (prefs) and restarts onboarding'**
  String get settingsResetSubtitle;

  /// No description provided for @settingsResetSnack.
  ///
  /// In en, this message translates to:
  /// **'Game reset. Relaunch the app to see the tutorial.'**
  String get settingsResetSnack;

  /// No description provided for @settingsFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'Dark Matte • Velour Accent'**
  String get settingsFooterTagline;

  /// No description provided for @settingsCreditsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'CREDITS'**
  String get settingsCreditsDialogTitle;

  /// No description provided for @settingsCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'Velour — Dark Matte Edition\n\nDesign & direction: Velour Studio\nEngineering: Flutter\nAudio: Velour SFX Pack'**
  String get settingsCreditsBody;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get settingsClose;

  /// No description provided for @shopBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get shopBackTooltip;

  /// No description provided for @shopVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'THE VAULT'**
  String get shopVaultTitle;

  /// No description provided for @shopProductSparkReserve.
  ///
  /// In en, this message translates to:
  /// **'SPARK RESERVE'**
  String get shopProductSparkReserve;

  /// No description provided for @shopProductOracleTreasure.
  ///
  /// In en, this message translates to:
  /// **'ORACLE\'S TREASURE'**
  String get shopProductOracleTreasure;

  /// No description provided for @shopProductRoyalLegacy.
  ///
  /// In en, this message translates to:
  /// **'ROYAL LEGACY'**
  String get shopProductRoyalLegacy;

  /// No description provided for @shopBadgeBestDeal.
  ///
  /// In en, this message translates to:
  /// **'BEST DEAL'**
  String get shopBadgeBestDeal;

  /// No description provided for @shopLuxAmount.
  ///
  /// In en, this message translates to:
  /// **'{lux} LUX'**
  String shopLuxAmount(int lux);

  /// No description provided for @shopForgeTitle.
  ///
  /// In en, this message translates to:
  /// **'THE ORACLE FORGE'**
  String get shopForgeTitle;

  /// No description provided for @shopSkinEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get shopSkinEquipped;

  /// No description provided for @shopSkinOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get shopSkinOwned;

  /// No description provided for @shopPriceLux.
  ///
  /// In en, this message translates to:
  /// **'{price} LUX'**
  String shopPriceLux(int price);

  /// No description provided for @shopVaultLoading.
  ///
  /// In en, this message translates to:
  /// **'CONTACTING THE VAULT…'**
  String get shopVaultLoading;

  /// No description provided for @shopPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'SUCCESS'**
  String get shopPurchaseSuccess;

  /// No description provided for @shopPurchaseLuxAdded.
  ///
  /// In en, this message translates to:
  /// **'+{lux} LUX'**
  String shopPurchaseLuxAdded(int lux);

  /// No description provided for @shopBackToGame.
  ///
  /// In en, this message translates to:
  /// **'BACK TO GAME'**
  String get shopBackToGame;

  /// No description provided for @shopSnackInsufficientLux.
  ///
  /// In en, this message translates to:
  /// **'Not enough LUX.'**
  String get shopSnackInsufficientLux;

  /// No description provided for @shopSnackSkinEquipped.
  ///
  /// In en, this message translates to:
  /// **'Skin equipped.'**
  String get shopSnackSkinEquipped;

  /// No description provided for @shopSnackSkinUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Skin unlocked and equipped.'**
  String get shopSnackSkinUnlocked;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'MY CAREER'**
  String get statsTitle;

  /// No description provided for @statsStreakSession.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{STREAK: 1 DAY WITH A RUN} other{STREAK: {count} DAYS WITH A RUN}}'**
  String statsStreakSession(int count);

  /// No description provided for @statsLuxEarned.
  ///
  /// In en, this message translates to:
  /// **'LUX EARNED'**
  String get statsLuxEarned;

  /// No description provided for @statsBestGain.
  ///
  /// In en, this message translates to:
  /// **'BEST WIN'**
  String get statsBestGain;

  /// No description provided for @statsMaxLevel.
  ///
  /// In en, this message translates to:
  /// **'MAX LEVEL'**
  String get statsMaxLevel;

  /// No description provided for @statsShapesPlaced.
  ///
  /// In en, this message translates to:
  /// **'SHAPES PLACED'**
  String get statsShapesPlaced;

  /// No description provided for @statsMatches.
  ///
  /// In en, this message translates to:
  /// **'MATCHES'**
  String get statsMatches;

  /// No description provided for @statsTotalTime.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TIME'**
  String get statsTotalTime;

  /// No description provided for @statsPrecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get statsPrecisionTitle;

  /// No description provided for @statsPrecisionHelp.
  ///
  /// In en, this message translates to:
  /// **'Match-to-placement ratio.\nHigher means cleaner runs.'**
  String get statsPrecisionHelp;

  /// No description provided for @statsModesTitle.
  ///
  /// In en, this message translates to:
  /// **'MODE SPLIT'**
  String get statsModesTitle;

  /// No description provided for @statsModeCasual.
  ///
  /// In en, this message translates to:
  /// **'CASUAL'**
  String get statsModeCasual;

  /// No description provided for @statsModeHighStakes.
  ///
  /// In en, this message translates to:
  /// **'HIGH STAKES'**
  String get statsModeHighStakes;

  /// No description provided for @statsModeRoyal.
  ///
  /// In en, this message translates to:
  /// **'ROYAL'**
  String get statsModeRoyal;

  /// No description provided for @gameHudMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get gameHudMenuTooltip;

  /// No description provided for @pauseTitle.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get pauseTitle;

  /// No description provided for @pauseResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get pauseResume;

  /// No description provided for @pauseBackToMenu.
  ///
  /// In en, this message translates to:
  /// **'BACK TO MENU'**
  String get pauseBackToMenu;

  /// No description provided for @premiumForfeitTitle.
  ///
  /// In en, this message translates to:
  /// **'FORFEIT?'**
  String get premiumForfeitTitle;

  /// No description provided for @premiumForfeitLead.
  ///
  /// In en, this message translates to:
  /// **'If you leave this {session} session, you forfeit your stake of '**
  String premiumForfeitLead(String session);

  /// No description provided for @premiumForfeitTrail.
  ///
  /// In en, this message translates to:
  /// **' LUX permanently.'**
  String get premiumForfeitTrail;

  /// No description provided for @premiumSessionHighStakes.
  ///
  /// In en, this message translates to:
  /// **'High Stakes'**
  String get premiumSessionHighStakes;

  /// No description provided for @premiumSessionRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal'**
  String get premiumSessionRoyal;

  /// No description provided for @premiumStay.
  ///
  /// In en, this message translates to:
  /// **'STAY'**
  String get premiumStay;

  /// No description provided for @premiumForfeit.
  ///
  /// In en, this message translates to:
  /// **'FORFEIT'**
  String get premiumForfeit;

  /// No description provided for @gameOverTitleSessionEnd.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get gameOverTitleSessionEnd;

  /// No description provided for @gameOverTitleVictory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY'**
  String get gameOverTitleVictory;

  /// No description provided for @gameOverTitleDefeat.
  ///
  /// In en, this message translates to:
  /// **'DEFEAT'**
  String get gameOverTitleDefeat;

  /// No description provided for @gameOverSessionScore.
  ///
  /// In en, this message translates to:
  /// **'SESSION SCORE'**
  String get gameOverSessionScore;

  /// No description provided for @gameOverZeroLuxHintCasual.
  ///
  /// In en, this message translates to:
  /// **'No match LUX this session — timer ran out or you left before the first gain.'**
  String get gameOverZeroLuxHintCasual;

  /// No description provided for @gameOverZeroLuxHintHighStakes.
  ///
  /// In en, this message translates to:
  /// **'No LUX banked before the end — goal not reached or time ran out.'**
  String get gameOverZeroLuxHintHighStakes;

  /// No description provided for @gameOverZeroLuxHintRoyal.
  ///
  /// In en, this message translates to:
  /// **'No LUX banked before the end — goal not reached or time ran out.'**
  String get gameOverZeroLuxHintRoyal;

  /// No description provided for @gameOverFinalScore.
  ///
  /// In en, this message translates to:
  /// **'FINAL SCORE'**
  String get gameOverFinalScore;

  /// No description provided for @gameOverLuxWon.
  ///
  /// In en, this message translates to:
  /// **'LUX WON'**
  String get gameOverLuxWon;

  /// No description provided for @gameOverPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'NEW PERSONAL BEST'**
  String get gameOverPersonalBest;

  /// No description provided for @gameOverReplay.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get gameOverReplay;

  /// No description provided for @gameOverMainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get gameOverMainMenu;

  /// No description provided for @gameOverPrestigeBonus.
  ///
  /// In en, this message translates to:
  /// **'PRESTIGE BONUS'**
  String get gameOverPrestigeBonus;

  /// No description provided for @gameOverFooterHighStakesFail.
  ///
  /// In en, this message translates to:
  /// **'BET LOST: STAKE FORFEITED'**
  String get gameOverFooterHighStakesFail;

  /// No description provided for @gameOverFooterHighStakesWin150.
  ///
  /// In en, this message translates to:
  /// **'YOU WIN 150 LUX'**
  String get gameOverFooterHighStakesWin150;

  /// No description provided for @gameOverFooterRoyalFail.
  ///
  /// In en, this message translates to:
  /// **'ROYAL BET LOST: STAKE FORFEITED'**
  String get gameOverFooterRoyalFail;

  /// No description provided for @gameOverFooterRoyalWin1250.
  ///
  /// In en, this message translates to:
  /// **'YOU WIN 1250 LUX'**
  String get gameOverFooterRoyalWin1250;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

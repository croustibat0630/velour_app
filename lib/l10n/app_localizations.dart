import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
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
    Locale('de'),
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

  /// Main menu: claim once-per-day free LUX.
  ///
  /// In en, this message translates to:
  /// **'+{amount} LUX — Daily bonus'**
  String menuDailyLuxBonus(int amount);

  /// Snack after successful daily LUX claim (server applied).
  ///
  /// In en, this message translates to:
  /// **'Daily bonus claimed.'**
  String get menuDailyLuxBonusSuccess;

  /// Snack when daily bonus was granted offline and queued for cloud sync.
  ///
  /// In en, this message translates to:
  /// **'Bonus saved — it will sync when you are online.'**
  String get menuDailyLuxBonusQueued;

  /// Snack when server already applied today’s bonus (no new credit).
  ///
  /// In en, this message translates to:
  /// **'Balance synced from the server.'**
  String get menuDailyLuxBonusSynced;

  /// Snack when local state says daily bonus was already claimed.
  ///
  /// In en, this message translates to:
  /// **'Already claimed today.'**
  String get menuDailyLuxBonusAlready;

  /// Snack when the daily bonus callable failed or network error.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again.'**
  String get menuDailyLuxBonusRetry;

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

  /// Main menu: narrative tutorial replay (casual).
  ///
  /// In en, this message translates to:
  /// **'TUTORIAL'**
  String get menuGuidedTutorial;

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

  /// No description provided for @settingsLocaleGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsLocaleGerman;

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

  /// No description provided for @settingsCopyPlayerIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy player ID'**
  String get settingsCopyPlayerIdTitle;

  /// No description provided for @settingsCopyPlayerIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Useful for support and bug reports'**
  String get settingsCopyPlayerIdSubtitle;

  /// No description provided for @settingsCopyPlayerIdFailed.
  ///
  /// In en, this message translates to:
  /// **'Player ID not available yet.'**
  String get settingsCopyPlayerIdFailed;

  /// No description provided for @settingsCopyPlayerIdSnack.
  ///
  /// In en, this message translates to:
  /// **'Copied: {uid}'**
  String settingsCopyPlayerIdSnack(String uid);

  /// No description provided for @settingsPingServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get settingsPingServerTitle;

  /// No description provided for @settingsPingServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ping backend (velourHealth)'**
  String get settingsPingServerSubtitle;

  /// No description provided for @settingsPingServerOk.
  ///
  /// In en, this message translates to:
  /// **'Server OK.'**
  String get settingsPingServerOk;

  /// No description provided for @settingsPingServerFail.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable (check network / App Check).'**
  String get settingsPingServerFail;

  /// No description provided for @settingsCopyDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get settingsCopyDiagnosticsTitle;

  /// No description provided for @settingsCopyDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy version, locale, player ID and server status'**
  String get settingsCopyDiagnosticsSubtitle;

  /// No description provided for @settingsCopyDiagnosticsSnack.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied.'**
  String get settingsCopyDiagnosticsSnack;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsPrivacyPolicyLaunchFail.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get settingsPrivacyPolicyLaunchFail;

  /// No description provided for @luxCloudRejectedUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'LUX sync rejected. Please update the app. If it persists, copy your player ID in Settings → Info.'**
  String get luxCloudRejectedUpdateRequired;

  /// No description provided for @luxCloudRejectedTryLater.
  ///
  /// In en, this message translates to:
  /// **'LUX sync rejected. Please try again later.'**
  String get luxCloudRejectedTryLater;

  /// No description provided for @luxCloudRejectedGeneric.
  ///
  /// In en, this message translates to:
  /// **'LUX sync failed. Check network and try again.'**
  String get luxCloudRejectedGeneric;

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

  /// No description provided for @shopVaultPricePending.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get shopVaultPricePending;

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

  /// No description provided for @shopForgeBoostsSection.
  ///
  /// In en, this message translates to:
  /// **'SESSION BOOSTS'**
  String get shopForgeBoostsSection;

  /// No description provided for @shopForgeSectionRunSalvage.
  ///
  /// In en, this message translates to:
  /// **'RUN SALVAGE'**
  String get shopForgeSectionRunSalvage;

  /// No description provided for @shopForgeSectionStrategyStakes.
  ///
  /// In en, this message translates to:
  /// **'STRATEGY & STAKES'**
  String get shopForgeSectionStrategyStakes;

  /// No description provided for @shopForgeInsuranceTitle.
  ///
  /// In en, this message translates to:
  /// **'ORACLE INSURANCE'**
  String get shopForgeInsuranceTitle;

  /// No description provided for @shopForgeInsuranceBody.
  ///
  /// In en, this message translates to:
  /// **'If you lose your next High Stakes ({highAnte} LUX ante) or Royal ({royalAnte} LUX ante) run, the Oracle refunds {refundPct}% of that entry stake. Stack up to {maxCharges} charges.'**
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  );

  /// No description provided for @shopForgeInsuranceCharges.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} charges'**
  String shopForgeInsuranceCharges(int count, int max);

  /// No description provided for @shopForgeRoyalBountyTitle.
  ///
  /// In en, this message translates to:
  /// **'ROYAL BOUNTY'**
  String get shopForgeRoyalBountyTitle;

  /// No description provided for @shopForgeRoyalBountyBody.
  ///
  /// In en, this message translates to:
  /// **'+{bonusLux} bonus LUX on your next Royal win once you clear the Royal objective (in addition to the usual {royalWinLux} LUX win payout). One active bounty at a time.'**
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux);

  /// No description provided for @shopForgeRoyalBountyActive.
  ///
  /// In en, this message translates to:
  /// **'Active — next Royal win pays extra'**
  String get shopForgeRoyalBountyActive;

  /// No description provided for @shopSnackForgeInsurancePurchased.
  ///
  /// In en, this message translates to:
  /// **'Insurance charge added.'**
  String get shopSnackForgeInsurancePurchased;

  /// No description provided for @shopSnackForgeRoyalBountyPurchased.
  ///
  /// In en, this message translates to:
  /// **'Royal bounty active for your next Royal win.'**
  String get shopSnackForgeRoyalBountyPurchased;

  /// No description provided for @shopSnackForgeInsuranceFull.
  ///
  /// In en, this message translates to:
  /// **'You already hold 3 insurance charges.'**
  String get shopSnackForgeInsuranceFull;

  /// No description provided for @shopSnackForgeRoyalBountyActive.
  ///
  /// In en, this message translates to:
  /// **'Royal bounty is already active.'**
  String get shopSnackForgeRoyalBountyActive;

  /// No description provided for @shopForgeChronoPulseTitle.
  ///
  /// In en, this message translates to:
  /// **'CHRONO RESERVE'**
  String get shopForgeChronoPulseTitle;

  /// No description provided for @shopForgeChronoPulseBody.
  ///
  /// In en, this message translates to:
  /// **'When the session timer hits zero, one charge refills the bar to full so the run continues. Stack up to {maxCharges} charges. Inactive during tutorials.'**
  String shopForgeChronoPulseBody(int maxCharges);

  /// No description provided for @shopForgeChronoPulseCharges.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} charges'**
  String shopForgeChronoPulseCharges(int count, int max);

  /// No description provided for @shopForgeMercySalvageTitle.
  ///
  /// In en, this message translates to:
  /// **'ORACLE\'S MERCY'**
  String get shopForgeMercySalvageTitle;

  /// No description provided for @shopForgeMercySalvageBody.
  ///
  /// In en, this message translates to:
  /// **'Rack full with no valid match: one charge reshapes the end of your rack into a playable triple so you keep going. Stack up to {maxCharges} charges. Inactive during tutorials.'**
  String shopForgeMercySalvageBody(int maxCharges);

  /// No description provided for @shopForgeMercySalvageCharges.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} charges'**
  String shopForgeMercySalvageCharges(int count, int max);

  /// No description provided for @shopSnackForgeChronoPulsePurchased.
  ///
  /// In en, this message translates to:
  /// **'Chrono reserve charge added.'**
  String get shopSnackForgeChronoPulsePurchased;

  /// No description provided for @shopSnackForgeChronoPulseFull.
  ///
  /// In en, this message translates to:
  /// **'You already hold 2 chrono charges.'**
  String get shopSnackForgeChronoPulseFull;

  /// No description provided for @shopSnackForgeMercySalvagePurchased.
  ///
  /// In en, this message translates to:
  /// **'Mercy salvage charge added.'**
  String get shopSnackForgeMercySalvagePurchased;

  /// No description provided for @shopSnackForgeMercySalvageFull.
  ///
  /// In en, this message translates to:
  /// **'You already hold 2 mercy charges.'**
  String get shopSnackForgeMercySalvageFull;

  /// No description provided for @shopIapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases are not available on this device.'**
  String get shopIapUnavailable;

  /// No description provided for @shopIapProductsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'LUX packs are unavailable from the store right now.'**
  String get shopIapProductsUnavailable;

  /// No description provided for @shopIapCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get shopIapCancelled;

  /// No description provided for @shopIapOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please disable Airplane Mode and try again.'**
  String get shopIapOffline;

  /// No description provided for @shopIapError.
  ///
  /// In en, this message translates to:
  /// **'Payment error: {details}'**
  String shopIapError(String details);

  /// No description provided for @shopIapErrorBusy.
  ///
  /// In en, this message translates to:
  /// **'Another purchase is already in progress. Please wait.'**
  String get shopIapErrorBusy;

  /// No description provided for @shopIapErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the payment. Please try again.'**
  String get shopIapErrorUnknown;

  /// No description provided for @shopIapErrorServerVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not verify this purchase with the server. Check your connection and try again.'**
  String get shopIapErrorServerVerificationFailed;

  /// No description provided for @shopIapErrorDuplicateTransaction.
  ///
  /// In en, this message translates to:
  /// **'This purchase was already processed.'**
  String get shopIapErrorDuplicateTransaction;

  /// No description provided for @shopIapErrorRestoredIgnored.
  ///
  /// In en, this message translates to:
  /// **'Restored purchases do not grant LUX for consumable packs.'**
  String get shopIapErrorRestoredIgnored;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'MY CAREER'**
  String get statsTitle;

  /// No description provided for @statsStreakSession.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{STREAK · 1 DAY} other{STREAK · {count} DAYS}}'**
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

  /// No description provided for @gameOverCareerRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Career record (saved): {high}'**
  String gameOverCareerRecordHint(int high);

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

  /// No description provided for @gameOverOracleInsuranceTitle.
  ///
  /// In en, this message translates to:
  /// **'ORACLE COVER'**
  String get gameOverOracleInsuranceTitle;

  /// No description provided for @gameOverOracleInsuranceRefund.
  ///
  /// In en, this message translates to:
  /// **'+{lux} LUX returned to your purse'**
  String gameOverOracleInsuranceRefund(int lux);

  /// No description provided for @oracleDockStep1Shape.
  ///
  /// In en, this message translates to:
  /// **'Shape = +100 LUX (min.)\nSame silhouette • 3 colors → rack'**
  String get oracleDockStep1Shape;

  /// No description provided for @oracleDockStep2Color.
  ///
  /// In en, this message translates to:
  /// **'Color = +150 LUX\nSame hue • 3 shapes → rack'**
  String get oracleDockStep2Color;

  /// No description provided for @oracleDockStep3Perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect = +500 LUX\n3 identical gems → rack'**
  String get oracleDockStep3Perfect;

  /// No description provided for @oracleDockCelebration.
  ///
  /// In en, this message translates to:
  /// **'100 < 150 < 500 LUX\nAim for perfect first.'**
  String get oracleDockCelebration;

  /// No description provided for @oracleDockStep1StrategyLine.
  ///
  /// In en, this message translates to:
  /// **'First: one silhouette, three different colors.'**
  String get oracleDockStep1StrategyLine;

  /// No description provided for @oracleDockStep2StrategyLine.
  ///
  /// In en, this message translates to:
  /// **'Don\'t take a weak triple if a perfect is one gem away.'**
  String get oracleDockStep2StrategyLine;

  /// No description provided for @oracleDockStep3StrategyLine.
  ///
  /// In en, this message translates to:
  /// **'Three identical gems = the biggest payout here.'**
  String get oracleDockStep3StrategyLine;

  /// No description provided for @oracleDockCelebrationStrategyLine.
  ///
  /// In en, this message translates to:
  /// **'Later: the timer turns every second into a choice.'**
  String get oracleDockCelebrationStrategyLine;

  /// No description provided for @tutorialTrinityShapeIntro.
  ///
  /// In en, this message translates to:
  /// **'Shape is structure. Group them.'**
  String get tutorialTrinityShapeIntro;

  /// No description provided for @tutorialTrinityColorIntro.
  ///
  /// In en, this message translates to:
  /// **'Color is harmony. It creates opportunities.'**
  String get tutorialTrinityColorIntro;

  /// No description provided for @tutorialTrinityPerfectIntro.
  ///
  /// In en, this message translates to:
  /// **'The Perfect Match: absolute union. Triggers the LUX burst.'**
  String get tutorialTrinityPerfectIntro;

  /// No description provided for @narrativeFloatShapeBonus.
  ///
  /// In en, this message translates to:
  /// **'+100 LUX : STRUCTURE (SHAPE)'**
  String get narrativeFloatShapeBonus;

  /// No description provided for @narrativeFloatColorBonus.
  ///
  /// In en, this message translates to:
  /// **'+150 LUX : HARMONY (COLOR)'**
  String get narrativeFloatColorBonus;

  /// No description provided for @narrativeFloatPerfectBonus.
  ///
  /// In en, this message translates to:
  /// **'+500 LUX : TOTAL BRILLIANCE'**
  String get narrativeFloatPerfectBonus;

  /// No description provided for @gameNarrativePerfectMatchBanner.
  ///
  /// In en, this message translates to:
  /// **'PERFECT MATCH'**
  String get gameNarrativePerfectMatchBanner;

  /// No description provided for @prepTitle.
  ///
  /// In en, this message translates to:
  /// **'SESSION SETUP'**
  String get prepTitle;

  /// Preparation screen subtitle when opened from menu tutorial (casual only).
  ///
  /// In en, this message translates to:
  /// **'Only Classic mode is available for this tutorial.'**
  String get prepGuidedTutorialCasualOnly;

  /// No description provided for @prepGuidedTutorialGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What you\'re building toward'**
  String get prepGuidedTutorialGoalTitle;

  /// No description provided for @prepGuidedTutorialGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Each match adds in-run LUX and pushes your level. Richer match types—especially a perfect—pay far more than weaker triples. The real skill is choosing which clear you take and when.'**
  String get prepGuidedTutorialGoalBody;

  /// No description provided for @prepGuidedTutorialStrategyTitle.
  ///
  /// In en, this message translates to:
  /// **'Think before the third gem'**
  String get prepGuidedTutorialStrategyTitle;

  /// No description provided for @prepGuidedTutorialStrategyBody.
  ///
  /// In en, this message translates to:
  /// **'Before you commit a third gem, read your rack: if you are one gem away from three identical gems (same shape and same color), grabbing an easier color-only triple can break the setup and leave a lot of LUX on the table.\n\nIn this walkthrough the timer stays paused so you can practice calmly. In a real run, waiting has a cost—pressure and reward trade off.'**
  String get prepGuidedTutorialStrategyBody;

  /// No description provided for @prepModeCasualTitle.
  ///
  /// In en, this message translates to:
  /// **'CLASSIC MODE'**
  String get prepModeCasualTitle;

  /// No description provided for @prepModeCasualBody.
  ///
  /// In en, this message translates to:
  /// **'Stake: {ante} LUX. Free practice.'**
  String prepModeCasualBody(int ante);

  /// No description provided for @prepModeHighStakesTitle.
  ///
  /// In en, this message translates to:
  /// **'HIGH STAKES'**
  String get prepModeHighStakesTitle;

  /// No description provided for @prepModeHighStakesBody.
  ///
  /// In en, this message translates to:
  /// **'Stake: {ante} LUX. Goal: Level {goal}. Reward: {reward} LUX.'**
  String prepModeHighStakesBody(int ante, int goal, int reward);

  /// No description provided for @prepModeRoyalTitle.
  ///
  /// In en, this message translates to:
  /// **'VELOUR ROYAL'**
  String get prepModeRoyalTitle;

  /// No description provided for @prepModeRoyalBody.
  ///
  /// In en, this message translates to:
  /// **'Stake: {ante} LUX. Goal: Level {goal}. Reward: {reward} LUX.'**
  String prepModeRoyalBody(int ante, int goal, int reward);

  /// No description provided for @prepInsufficientLux.
  ///
  /// In en, this message translates to:
  /// **'Insufficient LUX balance.'**
  String get prepInsufficientLux;

  /// No description provided for @prepConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get prepConfirm;

  /// No description provided for @prepBuyLux.
  ///
  /// In en, this message translates to:
  /// **'BUY LUX'**
  String get prepBuyLux;

  /// No description provided for @prepSelectedChip.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get prepSelectedChip;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'WORLD LEADERBOARD'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardColRank.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get leaderboardColRank;

  /// No description provided for @leaderboardColPlayer.
  ///
  /// In en, this message translates to:
  /// **'PLAYER'**
  String get leaderboardColPlayer;

  /// No description provided for @leaderboardColScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get leaderboardColScore;

  /// No description provided for @leaderboardError.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard unavailable for now.\nCheck your connection or Firestore rules.\n({details})'**
  String leaderboardError(String details);

  /// No description provided for @leaderboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading rankings…'**
  String get leaderboardLoading;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scores recorded yet.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardYourRankFooter.
  ///
  /// In en, this message translates to:
  /// **'YOUR RANK'**
  String get leaderboardYourRankFooter;

  /// No description provided for @leaderboardPlayerAnon.
  ///
  /// In en, this message translates to:
  /// **'Player {id}'**
  String leaderboardPlayerAnon(String id);

  /// No description provided for @leaderboardPodiumFirst.
  ///
  /// In en, this message translates to:
  /// **'First place'**
  String get leaderboardPodiumFirst;

  /// No description provided for @leaderboardPodiumSecond.
  ///
  /// In en, this message translates to:
  /// **'Second place'**
  String get leaderboardPodiumSecond;

  /// No description provided for @leaderboardPodiumThird.
  ///
  /// In en, this message translates to:
  /// **'Third place'**
  String get leaderboardPodiumThird;

  /// No description provided for @leaderboardPodiumOther.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get leaderboardPodiumOther;

  /// No description provided for @gameFloatLuxGain.
  ///
  /// In en, this message translates to:
  /// **'+{gain} LUX'**
  String gameFloatLuxGain(int gain);

  /// No description provided for @gameFloatLuxGainMult.
  ///
  /// In en, this message translates to:
  /// **'+{gain} LUX ×{mult}'**
  String gameFloatLuxGainMult(int gain, String mult);

  /// No description provided for @gameFloatPerfectGain.
  ///
  /// In en, this message translates to:
  /// **'+{gain} PERFECT'**
  String gameFloatPerfectGain(int gain);

  /// No description provided for @gameFloatPerfectGainMult.
  ///
  /// In en, this message translates to:
  /// **'+{gain} PERFECT ×{mult}'**
  String gameFloatPerfectGainMult(int gain, String mult);

  /// No description provided for @gameFloatCombo.
  ///
  /// In en, this message translates to:
  /// **'COMBO ×{mult}'**
  String gameFloatCombo(String mult);

  /// No description provided for @gameHudScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get gameHudScore;

  /// No description provided for @gameHudTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get gameHudTime;

  /// No description provided for @gameHudPerfectHeatLabel.
  ///
  /// In en, this message translates to:
  /// **'HEAT'**
  String get gameHudPerfectHeatLabel;

  /// No description provided for @gameHudPerfectHeatNearFloater.
  ///
  /// In en, this message translates to:
  /// **' NEAR'**
  String get gameHudPerfectHeatNearFloater;

  /// No description provided for @gameHudPerfectHeatRebound.
  ///
  /// In en, this message translates to:
  /// **'REBOUND'**
  String get gameHudPerfectHeatRebound;

  /// No description provided for @gameHudLevelShort.
  ///
  /// In en, this message translates to:
  /// **'LV {level}'**
  String gameHudLevelShort(int level);

  /// No description provided for @gameHudLuxAmount.
  ///
  /// In en, this message translates to:
  /// **'{lux} LUX'**
  String gameHudLuxAmount(int lux);

  /// No description provided for @gameHudLuxThisRun.
  ///
  /// In en, this message translates to:
  /// **'THIS RUN'**
  String get gameHudLuxThisRun;

  /// No description provided for @gameHudLevelTag.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get gameHudLevelTag;

  /// No description provided for @gameHudLevelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP!'**
  String get gameHudLevelUpTitle;

  /// No description provided for @gameHudLevelUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String gameHudLevelUpSubtitle(int level);

  /// No description provided for @gameHudForgeChronoA11y.
  ///
  /// In en, this message translates to:
  /// **'Chrono reserve, {count} charges'**
  String gameHudForgeChronoA11y(int count);

  /// No description provided for @gameHudForgeMercyA11y.
  ///
  /// In en, this message translates to:
  /// **'Oracle mercy, {count} charges'**
  String gameHudForgeMercyA11y(int count);
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
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
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

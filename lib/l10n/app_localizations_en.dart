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
}

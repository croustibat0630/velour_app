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
}

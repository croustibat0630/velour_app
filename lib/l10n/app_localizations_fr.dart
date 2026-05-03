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
  String luxHudPrefix(int highScore) {
    return 'MEILLEUR SCORE  $highScore   •   LUX';
  }
}

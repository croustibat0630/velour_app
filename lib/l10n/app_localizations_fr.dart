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
}

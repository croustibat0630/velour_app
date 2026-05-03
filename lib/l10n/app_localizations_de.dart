// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
      other: 'SERIE: $count TAGE',
      one: 'SERIE: 1 TAG',
    );
    return '$_temp0';
  }

  @override
  String get menuPlay => 'SPIELEN';

  @override
  String get menuLeaderboard => 'WELTRANGLISTE';

  @override
  String get menuShop => 'LADEN';

  @override
  String get menuCareer => 'KARRIERE';

  @override
  String get menuSettings => 'EINSTELLUNGEN';

  @override
  String luxHudPrefix(int highScore) {
    return 'REKORD-HIGHSCORE  $highScore   •   LUX-MÜNZEN-GUTHABEN';
  }

  @override
  String get settingsSectionLanguage => 'SPRACHE';

  @override
  String get settingsLanguageRowTitle => 'Anzeigesprache der App';

  @override
  String get settingsLocaleSystem => 'Systemstandard';

  @override
  String get settingsLocaleEnglish => 'Englisch';

  @override
  String get settingsLocaleFrench => 'Französisch';

  @override
  String get settingsLocaleGerman => 'Deutsch';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get settingsSectionAudio => 'AUDIO';

  @override
  String get settingsMusicTitle => 'Musik';

  @override
  String get settingsMusicOn => 'Ein';

  @override
  String get settingsMusicOff => 'Aus';

  @override
  String get settingsSfxTitle => 'Soundeffekte';

  @override
  String get settingsSfxOn => 'Ein';

  @override
  String get settingsSfxOff => 'Aus';

  @override
  String get settingsSectionHaptics => 'HAPTISCH';

  @override
  String get settingsHapticsTitle => 'Haptisches Feedback';

  @override
  String get settingsHapticsOn => 'Ein (Premium)';

  @override
  String get settingsHapticsOff => 'Aus';

  @override
  String get settingsSectionInfos => 'INFO';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsCreditsTitle => 'Mitwirkende';

  @override
  String get settingsCreditsSubtitle => 'Contributors anzeigen';

  @override
  String get settingsSectionDebug => 'DEBUG';

  @override
  String get settingsResetTitle => 'ALLES ZURÜCKSETZEN';

  @override
  String get settingsResetSubtitle =>
      'Löscht Spieldaten (Einstellungen) und startet das Onboarding neu';

  @override
  String get settingsResetSnack =>
      'Spiel zurückgesetzt. Bitte App neu starten, um das Tutorial zu sehen.';

  @override
  String get settingsFooterTagline => 'Dark Matte • Velour-Akzent';

  @override
  String get settingsCreditsDialogTitle => 'MITWIRKENDE';

  @override
  String get settingsCreditsBody =>
      'Velour — Dark Matte Edition\n\nDesign & Leitung: Velour Studio\nEngineering: Flutter\nAudio: Velour-SFX-Paket';

  @override
  String get settingsClose => 'SCHLIESSEN';

  @override
  String get shopBackTooltip => 'Zurück';

  @override
  String get shopVaultTitle => 'DER TRESOR';

  @override
  String get shopProductSparkReserve => 'FUNKEN-RESERVE';

  @override
  String get shopProductOracleTreasure => 'ORAKEL-SCHATZ';

  @override
  String get shopProductRoyalLegacy => 'KÖNIGLICHES ERBE';

  @override
  String get shopBadgeBestDeal => 'BESTES ANGEBOT';

  @override
  String shopLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get shopForgeTitle => 'DIE ORAKEL-SCHMIEDE';

  @override
  String get shopSkinEquipped => 'Ausgerüstet';

  @override
  String get shopSkinOwned => 'Im Besitz';

  @override
  String shopPriceLux(int price) {
    return '$price LUX';
  }

  @override
  String get shopVaultLoading => 'TRESOR WIRD KONTAKTIERT…';

  @override
  String get shopPurchaseSuccess => 'ERFOLG';

  @override
  String shopPurchaseLuxAdded(int lux) {
    return '+$lux LUX';
  }

  @override
  String get shopBackToGame => 'ZURÜCK ZUM SPIEL';

  @override
  String get shopSnackInsufficientLux => 'Nicht genug LUX.';

  @override
  String get shopSnackSkinEquipped => 'Skin ausgerüstet.';

  @override
  String get shopSnackSkinUnlocked => 'Skin freigeschaltet und ausgerüstet.';

  @override
  String get shopForgeBoostsSection => 'SESSION-BOOSTS';

  @override
  String get shopForgeInsuranceTitle => 'ORAKEL-VERSICHERUNG';

  @override
  String get shopForgeInsuranceBody =>
      'Verlierst du dein nächstes High-Stakes- oder Royal-Match, erhältst du 60 % des Einsatzes zurück. Bis zu 3 Ladungen.';

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max Ladungen';
  }

  @override
  String get shopForgeRoyalBountyTitle => 'KÖNIGLICHE PRÄMIE';

  @override
  String get shopForgeRoyalBountyBody =>
      '+200 Bonus-LUX beim nächsten Royal-Sieg (zusätzlich zu 1 250). Nur eine aktive Prämie.';

  @override
  String get shopForgeRoyalBountyActive =>
      'Aktiv — nächster Royal-Sieg zahlt extra';

  @override
  String get shopSnackForgeInsurancePurchased =>
      'Versicherungsladung hinzugefügt.';

  @override
  String get shopSnackForgeRoyalBountyPurchased =>
      'Königliche Prämie aktiv für deinen nächsten Royal-Sieg.';

  @override
  String get shopSnackForgeInsuranceFull =>
      'Du hast bereits 3 Versicherungsladungen.';

  @override
  String get shopSnackForgeRoyalBountyActive =>
      'Eine königliche Prämie ist bereits aktiv.';

  @override
  String get statsTitle => 'MEINE KARRIERE';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SERIE: $count TAGE MIT RUN',
      one: 'SERIE: 1 TAG MIT RUN',
    );
    return '$_temp0';
  }

  @override
  String get statsLuxEarned => 'LUX VERDIENT';

  @override
  String get statsBestGain => 'BESTER GEWINN';

  @override
  String get statsMaxLevel => 'MAX. LEVEL';

  @override
  String get statsShapesPlaced => 'FORMEN GESETZT';

  @override
  String get statsMatches => 'MATCHES';

  @override
  String get statsTotalTime => 'GESAMTZEIT';

  @override
  String get statsPrecisionTitle => 'GENAUIGKEIT';

  @override
  String get statsPrecisionHelp =>
      'Verhältnis Matches zu Platzierungen.\nHöher bedeutet sauberere Runs.';

  @override
  String get statsModesTitle => 'MODUS-VERTEILUNG';

  @override
  String get statsModeCasual => 'CASUAL';

  @override
  String get statsModeHighStakes => 'HIGH STAKES';

  @override
  String get statsModeRoyal => 'ROYAL';

  @override
  String get gameHudMenuTooltip => 'Menü';

  @override
  String get pauseTitle => 'PAUSE';

  @override
  String get pauseResume => 'FORTSETZEN';

  @override
  String get pauseBackToMenu => 'ZUM HAUPTMENÜ';

  @override
  String get premiumForfeitTitle => 'AUFgeben?';

  @override
  String premiumForfeitLead(String session) {
    return 'Wenn du diese $session-Sitzung verlässt, verlierst du dauerhaft deinen Einsatz von ';
  }

  @override
  String get premiumForfeitTrail => ' LUX.';

  @override
  String get premiumSessionHighStakes => 'High Stakes';

  @override
  String get premiumSessionRoyal => 'Royal';

  @override
  String get premiumStay => 'BLEIBEN';

  @override
  String get premiumForfeit => 'AUFgeben';

  @override
  String get gameOverTitleSessionEnd => 'SITZUNG BEENDET';

  @override
  String get gameOverTitleVictory => 'SIEG';

  @override
  String get gameOverTitleDefeat => 'NIEDERLAGE';

  @override
  String get gameOverSessionScore => 'SITZUNGS-SCORE';

  @override
  String get gameOverZeroLuxHintCasual =>
      'In dieser Sitzung kein Match-LUX — Zeit abgelaufen oder vor dem ersten Gewinn verlassen.';

  @override
  String get gameOverZeroLuxHintHighStakes =>
      'Kein LUX bis zum Ende angesammelt — Ziel nicht erreicht oder Zeit abgelaufen.';

  @override
  String get gameOverZeroLuxHintRoyal =>
      'Kein LUX bis zum Ende angesammelt — Ziel nicht erreicht oder Zeit abgelaufen.';

  @override
  String get gameOverFinalScore => 'ENDSCORE';

  @override
  String get gameOverLuxWon => 'LUX GEWONNEN';

  @override
  String get gameOverPersonalBest => 'NEUER PERSÖNLICHER REKORD';

  @override
  String get gameOverReplay => 'NOCHMAL SPIELEN';

  @override
  String get gameOverMainMenu => 'HAUPTMENÜ';

  @override
  String get gameOverPrestigeBonus => 'PRESTIGE-BONUS';

  @override
  String get gameOverFooterHighStakesFail =>
      'WETTE VERLOREN: EINSATZ VERFALLEN';

  @override
  String get gameOverFooterHighStakesWin150 => 'DU GEWINNST 150 LUX';

  @override
  String get gameOverFooterRoyalFail =>
      'ROYAL-WETTE VERLOREN: EINSATZ VERFALLEN';

  @override
  String get gameOverFooterRoyalWin1250 => 'DU GEWINNST 1250 LUX';

  @override
  String get gameOverOracleInsuranceTitle => 'ORAKEL-DECKUNG';

  @override
  String gameOverOracleInsuranceRefund(int lux) {
    return '+$lux LUX zurück in deine Börse';
  }

  @override
  String get oracleDockStep1Shape =>
      'Form = mind. +100 LUX\nGleiche Silhouette • 3 Farben → Ablage';

  @override
  String get oracleDockStep2Color =>
      'Farbe = +150 LUX\nGleicher Farbton • 3 Formen → Ablage';

  @override
  String get oracleDockStep3Perfect =>
      'Perfect = +500 LUX\n3 identische Edelsteine → Ablage';

  @override
  String get oracleDockCelebration =>
      '100 < 150 < 500 LUX\nZiele zuerst auf Perfect.';

  @override
  String get tutorialTrinityShapeIntro => 'Form ist Struktur. Gruppiere sie.';

  @override
  String get tutorialTrinityColorIntro =>
      'Farbe ist Harmonie. Sie schafft Chancen.';

  @override
  String get tutorialTrinityPerfectIntro =>
      'Das perfekte Match: absolute Vereinigung. Löst den LUX-Burst aus.';

  @override
  String get narrativeFloatShapeBonus => '+100 LUX : STRUKTUR (FORM)';

  @override
  String get narrativeFloatColorBonus => '+150 LUX : HARMONIE (FARBE)';

  @override
  String get narrativeFloatPerfectBonus => '+500 LUX : TOTALE BRILLANZ';

  @override
  String get gameNarrativePerfectMatchBanner => 'PERFEKTES MATCH';

  @override
  String get prepTitle => 'SITZUNGS-SETUP';

  @override
  String get prepModeCasualTitle => 'KLASSISCHER MODUS';

  @override
  String prepModeCasualBody(int ante) {
    return 'Einsatz: $ante LUX. Kostenloses Üben.';
  }

  @override
  String get prepModeHighStakesTitle => 'HIGH STAKES';

  @override
  String prepModeHighStakesBody(int ante, int goal, int reward) {
    return 'Einsatz: $ante LUX. Ziel: Level $goal. Belohnung: $reward LUX.';
  }

  @override
  String get prepModeRoyalTitle => 'VELOUR ROYAL';

  @override
  String prepModeRoyalBody(int ante, int goal, int reward) {
    return 'Einsatz: $ante LUX. Ziel: Level $goal. Belohnung: $reward LUX.';
  }

  @override
  String get prepInsufficientLux => 'Unzureichendes LUX-Guthaben.';

  @override
  String get prepConfirm => 'BESTÄTIGEN';

  @override
  String get prepBuyLux => 'LUX KAUFEN';

  @override
  String get prepSelectedChip => 'AUSGEWÄHLT';

  @override
  String get leaderboardTitle => 'WELTRANGLISTE';

  @override
  String get leaderboardColRank => 'RANG';

  @override
  String get leaderboardColPlayer => 'SPIELER';

  @override
  String get leaderboardColScore => 'SCORE';

  @override
  String leaderboardError(String details) {
    return 'Rangliste derzeit nicht verfügbar.\nBitte Verbindung oder Firestore-Regeln prüfen.\n(Details: $details)';
  }

  @override
  String get leaderboardLoading => 'Rangliste wird geladen…';

  @override
  String get leaderboardEmpty => 'Noch keine Scores erfasst.';

  @override
  String get leaderboardYourRankFooter => 'DEIN RANG';

  @override
  String leaderboardPlayerAnon(String id) {
    return 'Spieler $id';
  }

  @override
  String get leaderboardPodiumFirst => 'Erster Platz';

  @override
  String get leaderboardPodiumSecond => 'Zweiter Platz';

  @override
  String get leaderboardPodiumThird => 'Dritter Platz';

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
  String get gameHudTime => 'ZEIT';

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
  String get gameHudLevelUpTitle => 'LEVEL AUF!';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'LEVEL $level';
  }
}

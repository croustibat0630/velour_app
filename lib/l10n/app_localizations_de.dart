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
  String get startScreenInitializeSystem => 'SYSTEM INITIALISIEREN';

  @override
  String startScreenHighScoreLine(int high) {
    return 'BESTWERT  $high';
  }

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
  String menuDailyLuxBonus(int amount) {
    return '+$amount LUX — Täglicher Bonus';
  }

  @override
  String get menuDailyLuxBonusSuccess => 'Tagesbonus eingefordert.';

  @override
  String get menuDailyLuxBonusQueued =>
      'Bonus gespeichert — wird online synchronisiert.';

  @override
  String get menuDailyLuxBonusSynced => 'Stand vom Server übernommen.';

  @override
  String get menuDailyLuxBonusAlready => 'Heute bereits eingefordert.';

  @override
  String get menuDailyLuxBonusRetry =>
      'Server nicht erreichbar. Bitte erneut versuchen.';

  @override
  String get menuLeaderboard => 'WELTRANGLISTE';

  @override
  String get menuShop => 'LADEN';

  @override
  String get menuCareer => 'KARRIERE';

  @override
  String get menuSettings => 'EINSTELLUNGEN';

  @override
  String get menuGuidedTutorial => 'TUTORIAL';

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
  String get settingsLocaleChinese => 'Chinesisch (Kurzzeichen)';

  @override
  String get settingsLocaleHindi => 'Hindi';

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
  String get settingsCopyPlayerIdTitle => 'Spieler-ID kopieren';

  @override
  String get settingsCopyPlayerIdSubtitle =>
      'Hilfreich für Support und Bug-Reports';

  @override
  String get settingsCopyPlayerIdFailed =>
      'Spieler-ID ist noch nicht verfügbar.';

  @override
  String settingsCopyPlayerIdSnack(String uid) {
    return 'Kopiert: $uid';
  }

  @override
  String get settingsPingServerTitle => 'Serverstatus';

  @override
  String get settingsPingServerSubtitle => 'Backend anpingen (velourHealth)';

  @override
  String get settingsPingServerOk => 'Server OK.';

  @override
  String get settingsPingServerFail =>
      'Server nicht erreichbar (Netz / App Check).';

  @override
  String get settingsCopyDiagnosticsTitle => 'Diagnose kopieren';

  @override
  String get settingsCopyDiagnosticsSubtitle =>
      'Version, Locale, Spieler-ID und Serverstatus kopieren';

  @override
  String get settingsCopyDiagnosticsSnack => 'Diagnose kopiert.';

  @override
  String get settingsPrivacyPolicyTitle => 'Datenschutzerklärung';

  @override
  String get settingsPrivacyPolicySubtitle => 'Im Browser öffnen';

  @override
  String get settingsPrivacyPolicyLaunchFail =>
      'Link konnte nicht geöffnet werden.';

  @override
  String get luxCloudRejectedUpdateRequired =>
      'LUX-Sync abgelehnt. Bitte App aktualisieren. Wenn es weiter passiert, kopiere deine Spieler-ID in Einstellungen → Info.';

  @override
  String get luxCloudRejectedTryLater =>
      'LUX-Sync abgelehnt. Bitte später erneut versuchen.';

  @override
  String get luxCloudRejectedGeneric =>
      'LUX-Sync fehlgeschlagen. Netzwerk prüfen und erneut versuchen.';

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
  String get settingsDebugResetWelcomeTitle =>
      'Willkommensgeschenk zurücksetzen';

  @override
  String get settingsDebugResetWelcomeSubtitle =>
      'firstLaunch + 0 LUX (250 LUX beim nächsten Menü-Tap testen)';

  @override
  String get settingsDebugResetWelcomeSnack =>
      'Willkommensgeschenk zurückgesetzt. Zum Hauptmenü und eine Schaltfläche tippen.';

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
  String get shopVaultPricePending => '—';

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
  String get shopForgeSectionRunSalvage => 'RUN-RETTUNG';

  @override
  String get shopForgeSectionStrategyStakes => 'TAKTIK & EINSATZ';

  @override
  String get shopForgeInsuranceTitle => 'ORAKEL-VERSICHERUNG';

  @override
  String shopForgeInsuranceBody(
    int highAnte,
    int royalAnte,
    int refundPct,
    int maxCharges,
  ) {
    return 'Verlierst du dein nächstes High-Stakes-Match (Einsatz $highAnte LUX) oder Royal-Match (Einsatz $royalAnte LUX), erstattet das Orakel $refundPct % dieses Einsatzes. Bis zu $maxCharges Ladungen.';
  }

  @override
  String shopForgeInsuranceCharges(int count, int max) {
    return '$count / $max Ladungen';
  }

  @override
  String get shopForgeRoyalBountyTitle => 'KÖNIGLICHE PRÄMIE';

  @override
  String shopForgeRoyalBountyBody(int bonusLux, int royalWinLux) {
    return '+$bonusLux Bonus-LUX beim nächsten Royal-Sieg nach erreichtem Royal-Ziel (zusätzlich zu den üblichen $royalWinLux LUX Gewinn). Nur eine aktive Prämie.';
  }

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
  String get shopForgeChronoPulseTitle => 'CHRONO-RESERVE';

  @override
  String shopForgeChronoPulseBody(int maxCharges) {
    return 'Wenn der Session-Timer null erreicht, füllt eine Ladung den Balken komplett und der Run geht weiter. Bis zu $maxCharges Ladungen. In Tutorials inaktiv.';
  }

  @override
  String shopForgeChronoPulseCharges(int count, int max) {
    return '$count / $max Ladungen';
  }

  @override
  String get shopForgeMercySalvageTitle => 'GNADE DES ORAKELS';

  @override
  String shopForgeMercySalvageBody(int maxCharges) {
    return 'Rack voll ohne gültigen Match: eine Ladung formt am Ende des Racks ein spielbares Triple, damit es weitergeht. Bis zu $maxCharges Ladungen. In Tutorials inaktiv.';
  }

  @override
  String shopForgeMercySalvageCharges(int count, int max) {
    return '$count / $max Ladungen';
  }

  @override
  String get shopSnackForgeChronoPulsePurchased =>
      'Chrono-Reserve-Ladung hinzugefügt.';

  @override
  String get shopSnackForgeChronoPulseFull =>
      'Du hast bereits 2 Chrono-Ladungen.';

  @override
  String get shopSnackForgeMercySalvagePurchased =>
      'Gnaden-Ladung hinzugefügt.';

  @override
  String get shopSnackForgeMercySalvageFull =>
      'Du hast bereits 2 Gnaden-Ladungen.';

  @override
  String get shopIapUnavailable =>
      'In-App-Käufe sind auf diesem Gerät nicht verfügbar.';

  @override
  String get shopIapProductsUnavailable =>
      'LUX-Pakete sind im Store derzeit nicht verfügbar.';

  @override
  String get shopIapCancelled => 'Kauf abgebrochen.';

  @override
  String get shopIapOffline =>
      'Keine Internetverbindung. Bitte Flugmodus deaktivieren und erneut versuchen.';

  @override
  String shopIapError(String details) {
    return 'Zahlungsfehler: $details';
  }

  @override
  String get shopIapErrorBusy =>
      'Ein anderer Kauf läuft bereits. Bitte kurz warten.';

  @override
  String get shopIapErrorUnknown =>
      'Die Zahlung ist fehlgeschlagen. Bitte später erneut versuchen.';

  @override
  String get shopIapErrorServerVerificationFailed =>
      'Der Kauf konnte nicht mit dem Server verifiziert werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get shopIapErrorDuplicateTransaction =>
      'Dieser Kauf wurde bereits verarbeitet.';

  @override
  String get shopIapErrorRestoredIgnored =>
      'Wiederhergestellte Käufe gewähren keine LUX für Verbrauchspakete.';

  @override
  String get statsTitle => 'MEINE KARRIERE';

  @override
  String statsStreakSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SERIE · $count TAGE',
      one: 'SERIE · 1 TAG',
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
  String gameOverCareerRecordHint(int high) {
    return 'Karriere-Rekord (gespeichert): $high';
  }

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
  String get gameOverOracleNamingBannerTitle => 'BESTENLISTE-EINTRAG';

  @override
  String get gameOverOracleNamingBannerBody =>
      'Lege deinen Namen fest, um in der weltweiten Bestenliste zu erscheinen.';

  @override
  String get gameOverOracleNamingNameNowButton => 'NAMEN WÄHLEN';

  @override
  String welcomeGiftBannerLux(int lux) {
    return 'VELOUR-STARTGUT: +$lux LUX';
  }

  @override
  String get oracleNamingDialogTitle => 'EXZELLENZ DEFINIERT DICH';

  @override
  String get oracleNamingDialogBody =>
      'Wähle den Namen, unter dem dich das Orakel kennt. Er wird in Kleinbuchstaben gespeichert, um Duplikate zu vermeiden.';

  @override
  String get oracleNamingValidationRequired => 'Name erforderlich';

  @override
  String get oracleNamingValidationTooLong => 'Maximal 15 Zeichen';

  @override
  String get oracleNamingValidationInvalidChars =>
      'Nur Buchstaben, Ziffern und _ (max. 15)';

  @override
  String get oracleNamingSaveError =>
      'Speichern nicht möglich (Netzwerk oder Server). Erneut versuchen oder später schließen.';

  @override
  String get oracleNamingSealButton => 'NAMEN FESTLEGEN';

  @override
  String get oracleNamingFieldHint => 'ORACLE_NAME';

  @override
  String get criticalFailureTitle => 'SYSTEM-ÜBERLASTUNG';

  @override
  String get criticalFailureSubtitle => 'VERBINDUNG VERLOREN';

  @override
  String get criticalFailureResetButton => 'SYSTEM ZURÜCKSETZEN';

  @override
  String get gameSequenceCompletedTitle => 'SEQUENZ ABGESCHLOSSEN';

  @override
  String get oracleDockStep1Shape =>
      'Form = mind. +100 LUX\nGleiche Silhouette • 3 Farben → Ablage';

  @override
  String get oracleDockStep2Color =>
      'Farbe = +150 LUX\nGleicher Farbton • 3 Formen → Ablage';

  @override
  String get oracleDockStep3Perfect =>
      'Perfect = +500 LUX\n3 identische Edelsteine → Ablage\nMehrere Perfects hintereinander: HITZE steigt — Extra-LUX & Zeit.\nIn echten Partien zeigt die HITZE-Leiste unter dem Score deine Serie.';

  @override
  String get oracleDockCelebration =>
      '100 < 150 < 500 LUX\nPerfect-Strecken laden HITZE in echten Partien.';

  @override
  String get oracleDockStep1StrategyLine =>
      'Zuerst: eine Silhouette, drei verschiedene Farben.';

  @override
  String get oracleDockStep2StrategyLine =>
      'Kein leichter Farben-Drilling, wenn Perfect nah ist.';

  @override
  String get oracleDockStep3StrategyLine =>
      'Schwächere Form-/Farb-Drillings senken die HITZE — plane deine Serie.';

  @override
  String get oracleDockCelebrationStrategyLine =>
      'Später: HITZE und Timer bestimmen gemeinsam dein Risiko.';

  @override
  String get tutorialTrinityShapeIntro => 'Form ist Struktur. Gruppiere sie.';

  @override
  String get tutorialTrinityColorIntro =>
      'Farbe ist Harmonie. Sie schafft Chancen.';

  @override
  String get tutorialTrinityPerfectIntro =>
      'Das perfekte Match: absolute Vereinigung, LUX-Burst. Perfect-Ketten bauen HITZE für stärkere Auszahlungen.';

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
  String get prepLuxScoreCaption => 'LUX-MÜNZEN';

  @override
  String get prepGuidedTutorialCasualOnly =>
      'Für dieses Tutorial steht nur der klassische Modus zur Verfügung.';

  @override
  String get prepGuidedTutorialGoalTitle => 'Worum es geht';

  @override
  String get prepGuidedTutorialGoalBody =>
      'Jeder Match bringt LUX in der Runde und treibt dein Level. Reichere Match-Typen — vor allem ein Perfect — zahlen viel mehr als schwächere Drillinge. Die Kunst ist, welchen Clear du nimmst und wann.\n\nMehrere Perfects in Folge erhöhen die HITZE (Leiste in echten Runden): höhere Stufen boosten Perfect-LUX und können Zeit zurückgeben; schwache Drillinge kühlen sie ab.';

  @override
  String get prepGuidedTutorialStrategyTitle =>
      'Erst lesen, dann die 3. ziehen';

  @override
  String get prepGuidedTutorialStrategyBody =>
      'Bevor du die dritte Edelsteinwahl finalisierst, sieh aufs Rack: fehlt dir nur noch **ein** Stein zu drei **identischen** (gleiche Form und gleiche Farbe), kann ein leichter Nur-Farben-Drilling dein Setup zerstören und viel LUX kosten.\n\nHier bleibt der Timer angehalten, damit du ruhig üben kannst. In einer echten Runde kostet Warten ebenfalls Zeit — Druck und Belohnung stehen im Wechselspiel.';

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
  String get gameHudPerfectHeatLabel => 'HITZE';

  @override
  String get gameHudPerfectHeatNearFloater => ' KNAPP';

  @override
  String get gameHudPerfectHeatRebound => '2. CHANCE';

  @override
  String gameHudLevelShort(int level) {
    return 'LV $level';
  }

  @override
  String gameHudLuxAmount(int lux) {
    return '$lux LUX';
  }

  @override
  String get gameHudLuxThisRun => 'RUN';

  @override
  String get gameHudLevelTag => 'LEVEL';

  @override
  String get gameHudLevelUpTitle => 'LEVEL AUF!';

  @override
  String gameHudLevelUpSubtitle(int level) {
    return 'LEVEL $level';
  }

  @override
  String get gameHudPerfectHeatSurgeTitle => 'HITZE-WELLE!';

  @override
  String gameHudPerfectHeatSurgeSubtitle(int heatTier) {
    return 'Stufe $heatTier';
  }

  @override
  String gameHudPerfectHeatHudBonus(int luxPercent, String multLabel) {
    return '+$luxPercent % $multLabel';
  }

  @override
  String gameHudForgeChronoA11y(int count) {
    return 'Chrono-Reserve, $count Ladungen';
  }

  @override
  String gameHudForgeMercyA11y(int count) {
    return 'Orakelgnade, $count Ladungen';
  }

  @override
  String get gameHudTimeResolvingA11y =>
      'Combo wird gewertet, Steine kurz gesperrt.';

  @override
  String get settingsSectionAccessibility => 'BEWEGUNG & BARRIEREFREIHEIT';

  @override
  String get settingsAccessibilityBody =>
      'Aktiviere „Bewegung reduzieren“ in den Systemeinstellungen (Bedienungshilfen → Bewegung) für ruhigere Darstellung und weniger Blitzlicht. Velour erkennt das automatisch.';

  @override
  String a11yGemButtonLabel(String shape, String color) {
    return '$shape, $color';
  }

  @override
  String get a11yGemShape1 => 'Kristall';

  @override
  String get a11yGemShape2 => 'Kugel';

  @override
  String get a11yGemShape3 => 'Pyramide';

  @override
  String get a11yGemShape4 => 'Stern';

  @override
  String get a11yGemShape5 => 'Diamant';

  @override
  String get a11yGemShape6 => 'Fünfeck';

  @override
  String get a11yGemShape7 => 'Sechsstrahlstern';

  @override
  String get a11yGemColor0 => 'Weiß';

  @override
  String get a11yGemColor1 => 'Cyan';

  @override
  String get a11yGemColor2 => 'Gold';

  @override
  String get a11yGemColor3 => 'Magenta';

  @override
  String get a11yGemColor4 => 'Grün';

  @override
  String get a11yGemColor5 => 'Violett';

  @override
  String get a11yGemColor6 => 'Orange';

  @override
  String get a11yGemColor7 => 'Blass';

  @override
  String a11yRackSlotEmpty(int slot, int max) {
    return 'Rack-Fach $slot von $max, leer.';
  }

  @override
  String a11yRackSlotOccupied(int slot, int max) {
    return 'Rack-Fach $slot von $max, belegt.';
  }

  @override
  String get a11yRackSlotImminentHint => 'Benachbartes Paar fast vollständig.';
}

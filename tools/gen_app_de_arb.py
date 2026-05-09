#!/usr/bin/env python3
"""Génère lib/l10n/app_de.arb à partir de app_en.arb (clés identiques, valeurs DE)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "lib" / "l10n" / "app_en.arb"
OUT_PATH = ROOT / "lib" / "l10n" / "app_de.arb"

# Traductions allemandes (chaînes longues surtout HUD / erreurs / tutoriels).
DE: dict[str, str] = {
    "appTitle": "Velour",
    "brandTitleDisplay": "VELOUR",
    "menuEditionSubtitle": "DARK MATTE EDITION",
    "menuStreakDays": "{count, plural, one{SERIE: 1 TAG} other{SERIE: {count} TAGE}}",
    "menuPlay": "SPIELEN",
    "menuLeaderboard": "WELTRANGLISTE",
    "menuShop": "LADEN",
    "menuCareer": "KARRIERE",
    "menuSettings": "EINSTELLUNGEN",
    "luxHudPrefix": "REKORD-HIGHSCORE  {highScore}   •   LUX-MÜNZEN-GUTHABEN",
    "settingsSectionLanguage": "SPRACHE",
    "settingsLanguageRowTitle": "Anzeigesprache der App",
    "settingsLocaleSystem": "Systemstandard",
    "settingsLocaleEnglish": "Englisch",
    "settingsLocaleFrench": "Französisch",
    "settingsLocaleGerman": "Deutsch",
    "settingsTitle": "EINSTELLUNGEN",
    "settingsSectionAudio": "AUDIO",
    "settingsMusicTitle": "Musik",
    "settingsMusicOn": "Ein",
    "settingsMusicOff": "Aus",
    "settingsSfxTitle": "Soundeffekte",
    "settingsSfxOn": "Ein",
    "settingsSfxOff": "Aus",
    "settingsSectionHaptics": "HAPTISCH",
    "settingsHapticsTitle": "Haptisches Feedback",
    "settingsHapticsOn": "Ein (Premium)",
    "settingsHapticsOff": "Aus",
    "settingsSectionInfos": "INFO",
    "settingsVersionLabel": "Version",
    "settingsCreditsTitle": "Mitwirkende",
    "settingsCreditsSubtitle": "Contributors anzeigen",
    "settingsSectionDebug": "DEBUG",
    "settingsResetTitle": "ALLES ZURÜCKSETZEN",
    "settingsResetSubtitle": "Löscht Spieldaten (Einstellungen) und startet das Onboarding neu",
    "settingsResetSnack": "Spiel zurückgesetzt. Bitte App neu starten, um das Tutorial zu sehen.",
    "settingsFooterTagline": "Dark Matte • Velour-Akzent",
    "settingsCreditsDialogTitle": "MITWIRKENDE",
    "settingsCreditsBody": "Velour — Dark Matte Edition\n\nDesign & Leitung: Velour Studio\nEngineering: Flutter\nAudio: Velour-SFX-Paket",
    "settingsClose": "SCHLIESSEN",
    "shopBackTooltip": "Zurück",
    "shopVaultTitle": "DER TRESOR",
    "shopProductSparkReserve": "FUNKEN-RESERVE",
    "shopProductOracleTreasure": "ORAKEL-SCHATZ",
    "shopProductRoyalLegacy": "KÖNIGLICHES ERBE",
    "shopBadgeBestDeal": "BESTES ANGEBOT",
    "shopLuxAmount": "{lux} LUX",
    "shopForgeTitle": "DIE ORAKEL-SCHMIEDE",
    "shopSkinEquipped": "Ausgerüstet",
    "shopSkinOwned": "Im Besitz",
    "shopPriceLux": "{price} LUX",
    "shopVaultLoading": "TRESOR WIRD KONTAKTIERT…",
    "shopPurchaseSuccess": "ERFOLG",
    "shopPurchaseLuxAdded": "+{lux} LUX",
    "shopBackToGame": "ZURÜCK ZUM SPIEL",
    "shopSnackInsufficientLux": "Nicht genug LUX.",
    "shopSnackSkinEquipped": "Skin ausgerüstet.",
    "shopSnackSkinUnlocked": "Skin freigeschaltet und ausgerüstet.",
    "statsTitle": "MEINE KARRIERE",
    "statsStreakSession": "{count, plural, one{SERIE: 1 TAG MIT RUN} other{SERIE: {count} TAGE MIT RUN}}",
    "statsLuxEarned": "LUX VERDIENT",
    "statsBestGain": "BESTER GEWINN",
    "statsMaxLevel": "MAX. LEVEL",
    "statsShapesPlaced": "FORMEN GESETZT",
    "statsMatches": "MATCHES",
    "statsTotalTime": "GESAMTZEIT",
    "statsPrecisionTitle": "GENAUIGKEIT",
    "statsPrecisionHelp": "Verhältnis Matches zu Platzierungen.\nHöher bedeutet sauberere Runs.",
    "statsModesTitle": "MODUS-VERTEILUNG",
    "statsModeCasual": "CASUAL",
    "statsModeHighStakes": "HIGH STAKES",
    "statsModeRoyal": "ROYAL",
    "gameHudMenuTooltip": "Menü",
    "pauseTitle": "PAUSE",
    "pauseResume": "FORTSETZEN",
    "pauseBackToMenu": "ZUM HAUPTMENÜ",
    "premiumForfeitTitle": "AUFgeben?",
    "premiumForfeitLead": "Wenn du diese {session}-Sitzung verlässt, verlierst du dauerhaft deinen Einsatz von ",
    "premiumForfeitTrail": " LUX.",
    "premiumSessionHighStakes": "High Stakes",
    "premiumSessionRoyal": "Royal",
    "premiumStay": "BLEIBEN",
    "premiumForfeit": "AUFgeben",
    "gameOverTitleSessionEnd": "SITZUNG BEENDET",
    "gameOverTitleVictory": "SIEG",
    "gameOverTitleDefeat": "NIEDERLAGE",
    "gameOverSessionScore": "SITZUNGS-SCORE",
    "gameOverZeroLuxHintCasual": "In dieser Sitzung kein Match-LUX — Zeit abgelaufen oder vor dem ersten Gewinn verlassen.",
    "gameOverZeroLuxHintHighStakes": "Kein LUX bis zum Ende angesammelt — Ziel nicht erreicht oder Zeit abgelaufen.",
    "gameOverZeroLuxHintRoyal": "Kein LUX bis zum Ende angesammelt — Ziel nicht erreicht oder Zeit abgelaufen.",
    "gameOverFinalScore": "ENDSCORE",
    "gameOverLuxWon": "LUX GEWONNEN",
    "gameOverPersonalBest": "NEUER PERSÖNLICHER REKORD",
    "gameOverReplay": "NOCHMAL SPIELEN",
    "gameOverMainMenu": "HAUPTMENÜ",
    "gameOverPrestigeBonus": "PRESTIGE-BONUS",
    "gameOverFooterHighStakesFail": "WETTE VERLOREN: EINSATZ VERFALLEN",
    "gameOverFooterHighStakesWin150": "DU GEWINNST 150 LUX",
    "gameOverFooterRoyalFail": "ROYAL-WETTE VERLOREN: EINSATZ VERFALLEN",
    "gameOverFooterRoyalWin1250": "DU GEWINNST 1250 LUX",
    "oracleDockStep1Shape": "Form = mind. +100 LUX\nGleiche Silhouette • 3 Farben → Ablage",
    "oracleDockStep2Color": "Farbe = +150 LUX\nGleicher Farbton • 3 Formen → Ablage",
    "oracleDockStep3Perfect": "Perfect = +500 LUX\n3 identische Edelsteine → Ablage\nMehrere Perfects hintereinander: HITZE steigt — Extra-LUX & Zeit.\nIn echten Partien zeigt die HITZE-Leiste unter dem Score deine Serie.",
    "oracleDockCelebration": "100 < 150 < 500 LUX\nPerfect-Strecken laden HITZE in echten Partien.",
    "oracleDockStep3StrategyLine": "Schwächere Form-/Farb-Drillings senken die HITZE — plane deine Serie.",
    "oracleDockCelebrationStrategyLine": "Später: HITZE und Timer bestimmen gemeinsam dein Risiko.",
    "tutorialTrinityShapeIntro": "Form ist Struktur. Gruppiere sie.",
    "tutorialTrinityColorIntro": "Farbe ist Harmonie. Sie schafft Chancen.",
    "tutorialTrinityPerfectIntro": "Das perfekte Match: absolute Vereinigung, LUX-Burst. Perfect-Ketten bauen HITZE für stärkere Auszahlungen.",
    "prepGuidedTutorialGoalBody": "Jeder Match bringt LUX in der Runde und treibt dein Level. Reichere Match-Typen — vor allem ein Perfect — zahlen viel mehr als schwächere Drillinge. Die Kunst ist, welchen Clear du nimmst und wann.\n\nMehrere Perfects in Folge erhöhen die HITZE (Leiste in echten Runden): höhere Stufen boosten Perfect-LUX und können Zeit zurückgeben; schwache Drillinge kühlen sie ab.",
    "narrativeFloatShapeBonus": "+100 LUX : STRUKTUR (FORM)",
    "narrativeFloatColorBonus": "+150 LUX : HARMONIE (FARBE)",
    "narrativeFloatPerfectBonus": "+500 LUX : TOTALE BRILLANZ",
    "gameNarrativePerfectMatchBanner": "PERFEKTES MATCH",
    "prepTitle": "SITZUNGS-SETUP",
    "prepModeCasualTitle": "KLASSISCHER MODUS",
    "prepModeCasualBody": "Einsatz: {ante} LUX. Kostenloses Üben.",
    "prepModeHighStakesTitle": "HIGH STAKES",
    "prepModeHighStakesBody": "Einsatz: {ante} LUX. Ziel: Level {goal}. Belohnung: {reward} LUX.",
    "prepModeRoyalTitle": "VELOUR ROYAL",
    "prepModeRoyalBody": "Einsatz: {ante} LUX. Ziel: Level {goal}. Belohnung: {reward} LUX.",
    "prepInsufficientLux": "Unzureichendes LUX-Guthaben.",
    "prepConfirm": "BESTÄTIGEN",
    "prepBuyLux": "LUX KAUFEN",
    "prepSelectedChip": "AUSGEWÄHLT",
    "leaderboardTitle": "WELTRANGLISTE",
    "leaderboardColRank": "RANG",
    "leaderboardColPlayer": "SPIELER",
    "leaderboardColScore": "SCORE",
    "leaderboardError": "Rangliste derzeit nicht verfügbar.\nBitte Verbindung oder Firestore-Regeln prüfen.\n(Details: {details})",
    "leaderboardLoading": "Rangliste wird geladen…",
    "leaderboardEmpty": "Noch keine Scores erfasst.",
    "leaderboardYourRankFooter": "DEIN RANG",
    "leaderboardPlayerAnon": "Spieler {id}",
    "leaderboardPodiumFirst": "Erster Platz",
    "leaderboardPodiumSecond": "Zweiter Platz",
    "leaderboardPodiumThird": "Dritter Platz",
    "leaderboardPodiumOther": "Podium",
    "gameFloatLuxGain": "+{gain} LUX",
    "gameFloatLuxGainMult": "+{gain} LUX ×{mult}",
    "gameFloatPerfectGain": "+{gain} PERFECT",
    "gameFloatPerfectGainMult": "+{gain} PERFECT ×{mult}",
    "gameFloatCombo": "COMBO ×{mult}",
    "gameHudScore": "SCORE",
    "gameHudTime": "ZEIT",
    "gameHudLevelShort": "LV {level}",
    "gameHudLuxAmount": "{lux} LUX",
    "gameHudLevelTag": "LEVEL",
    "gameHudLevelUpTitle": "LEVEL AUF!",
    "gameHudLevelUpSubtitle": "LEVEL {level}",
    "gameHudPerfectHeatSurgeTitle": "HITZE-WELLE!",
    "gameHudPerfectHeatSurgeSubtitle": "Stufe {heatTier}: +{luxPercent} % Perfect-LUX ({multLabel})",
}


def main() -> None:
    en: dict = json.loads(EN_PATH.read_text(encoding="utf-8"))
    out: dict = {}
    for key, val in en.items():
        if key == "@@locale":
            out[key] = "de"
            continue
        if key.startswith("@"):
            out[key] = val
            continue
        if isinstance(val, str):
            out[key] = DE.get(key, val)
        else:
            out[key] = val

    OUT_PATH.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT_PATH}")


if __name__ == "__main__":
    main()

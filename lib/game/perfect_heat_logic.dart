import 'match_types.dart';

/// Série « Perfect Heat » : bonus LUX %, refill temps, decay, near-miss.
///
/// Les pourcentages LUX s’appliquent au [rawLuxGain] du Perfect **avant** multiplicateurs
/// session / chaîne. Les refills temps sont une fraction de la portion **restante** de la
/// jauge (1 − v), plafonnés en équivalent secondes via [timeDrainPerSecond].
abstract final class PerfectHeatLogic {
  PerfectHeatLogic._();

  /// Near-miss : triple minimal forme ou couleur (pas Perfect identité).
  static bool isNearMiss(MatchKind kind, RunBasis basis, int runCount) {
    return kind == MatchKind.normal &&
        runCount == 3 &&
        (basis == RunBasis.shape || basis == RunBasis.color);
  }

  /// Match « moyen / mauvais » : tout sauf Perfect et near-miss.
  static bool isBadMiss(MatchKind kind, RunBasis basis, int runCount) {
    if (basis == RunBasis.perfect) return false;
    return !isNearMiss(kind, basis, runCount);
  }

  /// Bonus LUX (%) sur le gain brut du Perfect, palier **courant** (1–5) au moment du match.
  static int luxBonusPercent(int tierClamp1to5) =>
      switch (tierClamp1to5.clamp(1, 5)) {
        1 => 0,
        2 => 10,
        3 => 25,
        4 => 40,
        5 => 60,
        _ => 0,
      };

  /// Libellé court du multiplicateur équivalent (1 + bonus %) pour l’UI (ex. ×1.25).
  static String perfectLuxMultiplierLabel(int tierClamp1to5) {
    final int p = luxBonusPercent(tierClamp1to5.clamp(1, 5));
    if (p <= 0) return '×1';
    final double m = 1.0 + p / 100.0;
    final bool oneDecimal = p % 10 == 0;
    return '×${oneDecimal ? m.toStringAsFixed(1) : m.toStringAsFixed(2)}';
  }

  /// Refill temps (fraction de la portion restante), palier au moment du Perfect.
  /// Palier 4 (Hyper) : uniquement freeze côté GameState — refill 0 ici.
  static double timeRefillFractionOfRemaining(int tierClamp1to5) =>
      switch (tierClamp1to5.clamp(1, 5)) {
        1 => 0.0,
        2 => 0.02,
        3 => 0.04,
        4 => 0.0,
        5 => 0.04,
        _ => 0.0,
      };

  static int applyLuxPercentBonus(int rawLuxGain, int tierClamp1to5) {
    final int p = luxBonusPercent(tierClamp1to5);
    if (p <= 0) return rawLuxGain;
    return (rawLuxGain * (1.0 + p / 100.0)).round();
  }

  /// Ajout de jauge [0..1] après refund de base : basé sur le **reste** (1 − v),
  /// [baseRefillFraction] éventuellement doublé si [rescueDouble], cap équivalent 3 s.
  static double heatTimeRefillDelta({
    required double timeBarValueAfterBaseRefund,
    required double baseRefillFraction,
    required bool rescueDouble,
    required double timeDrainPerSecond,
  }) {
    final double v = timeBarValueAfterBaseRefund.clamp(0.0, 1.0);
    final double remaining = (1.0 - v).clamp(0.0, 1.0);
    if (remaining <= 0 || baseRefillFraction <= 0) return 0.0;

    double pct = baseRefillFraction;
    if (rescueDouble) {
      pct *= 2.0;
    }
    double add = remaining * pct;
    final double capFrac = (3.0 * timeDrainPerSecond).clamp(0.0, remaining);
    if (add > capFrac) add = capFrac;
    return add.clamp(0.0, remaining);
  }
}

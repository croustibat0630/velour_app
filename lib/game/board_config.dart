import 'dart:math' as math;

/// Paramètres de densité plateau liés au niveau (hors RNG).
abstract final class BoardConfig {
  BoardConfig._();

  /// Plancher absolu de gemmes sur le plateau (évite un plateau vide).
  static const int absoluteMinBoardGems = 3;

  /// Plafond raisonnable (la grille physique peut limiter au-delà).
  static const int absoluteMaxBoardGems = 8;

  /// Nombre cible de gemmes sur le plateau selon le niveau (resserre la courbe).
  ///
  /// [heatTierClamp0to5] : en Perfect Heat palier 5, +1 gemme pour plus d’options
  /// (skill) sans casser les paliers bas.
  static int boardCapForLevel(int level, {int heatTierClamp0to5 = 0}) {
    int base;
    if (level <= 1) {
      base = 7;
    } else if (level <= 2) {
      base = 6;
    } else if (level <= 3) {
      base = 5;
    } else if (level <= 4) {
      base = 4;
    } else {
      base = 3;
    }
    if (heatTierClamp0to5 >= 5) {
      base = math.min(absoluteMaxBoardGems, base + 1);
    }
    return base;
  }
}

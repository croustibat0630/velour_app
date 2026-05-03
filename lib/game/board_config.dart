/// Paramètres de densité plateau liés au niveau (hors RNG).
abstract final class BoardConfig {
  BoardConfig._();

  /// Nombre cible de gemmes sur le plateau selon le niveau (resserre la courbe).
  static int boardCapForLevel(int level) {
    if (level <= 1) return 7;
    if (level <= 2) return 6;
    if (level <= 3) return 5;
    if (level <= 4) return 4;
    return 3;
  }
}

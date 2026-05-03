import 'dart:math';

/// Tirage de couleur et règles de spawn **sans** layout plateau (testable).
abstract final class BoardSpawnLogic {
  BoardSpawnLogic._();

  /// Triangle (typeId 3) toujours glace cyan pour lisibilité.
  static int clampTriangleColor(int typeId, int colorId) {
    if (typeId == 3) return 1;
    return colorId;
  }

  /// Tirage couleur pondéré par sous-représentation sur plateau + rack (niveau ≥ 4 couleurs).
  static int pickWeightedColorId({
    required int maxColorId,
    required int gameLevel,
    required Map<int, int> colorPopulationCounts,
    required Random rng,
  }) {
    if (maxColorId <= 3) {
      return 1 + rng.nextInt(maxColorId);
    }

    final double bias = (gameLevel >= 7) ? 1.35 : 1.15;
    final List<double> w = List<double>.generate(maxColorId, (int i) {
      final int id = i + 1;
      final int c = colorPopulationCounts[id] ?? 0;
      return bias / (1.0 + c.toDouble());
    });

    final double sum = w.fold(0.0, (double a, double b) => a + b);
    double r = rng.nextDouble() * sum;
    for (int i = 0; i < maxColorId; i++) {
      r -= w[i];
      if (r <= 0) return i + 1;
    }
    return 1;
  }
}

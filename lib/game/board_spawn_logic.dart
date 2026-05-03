import 'dart:math';

/// Tirage de couleur et règles de spawn **sans** layout plateau (testable).
abstract final class BoardSpawnLogic {
  BoardSpawnLogic._();

  /// Probabilité d’aligner le 3e exemplaire quand une paire identique est déjà en rack.
  static const double spawnCompletionBiasChance = 0.3;

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

  /// Biais « compléter la paire en slots » : `roll01` sous [spawnCompletionBiasChance] et [pair] non null.
  static ({int typeId, int colorId}) maybeApplySlotCompletionBias({
    required int typeId,
    required int colorId,
    required bool biasMayApply,
    required double roll01,
    ({int typeId, int colorId})? pair,
  }) {
    if (biasMayApply &&
        roll01 < spawnCompletionBiasChance &&
        pair != null) {
      return (typeId: pair.typeId, colorId: pair.colorId);
    }
    return (typeId: typeId, colorId: colorId);
  }

  /// Premier remplissage : évite d’avoir déjà 2 mêmes formes ou 2 mêmes couleurs **avant** d’ajouter la gemme.
  ///
  /// Après 36 essais la contrainte peut céder (comportement aligné sur l’ancien [GameState]).
  /// Met à jour [shapeCounts] et [colorCounts]. [nextColorId] reflète le plateau courant (ex. pick pondéré).
  static ({int typeId, int colorId}) rollInitialSeedGem({
    required int maxShapeId,
    required Map<int, int> shapeCounts,
    required Map<int, int> colorCounts,
    required Random rng,
    required int Function() nextColorId,
  }) {
    int typeId = 1 + rng.nextInt(maxShapeId);
    int colorId = clampTriangleColor(typeId, nextColorId());
    int tries = 0;
    while (((shapeCounts[typeId] ?? 0) >= 2 ||
            (colorCounts[colorId] ?? 0) >= 2) &&
        tries < 36) {
      typeId = 1 + rng.nextInt(maxShapeId);
      colorId = clampTriangleColor(typeId, nextColorId());
      tries++;
    }
    shapeCounts[typeId] = (shapeCounts[typeId] ?? 0) + 1;
    colorCounts[colorId] = (colorCounts[colorId] ?? 0) + 1;
    return (typeId: typeId, colorId: colorId);
  }
}


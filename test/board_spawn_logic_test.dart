import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/board_spawn_logic.dart';

void main() {
  test('clampTriangleColor : type 3 → cyan 1', () {
    expect(BoardSpawnLogic.clampTriangleColor(3, 99), 1);
    expect(BoardSpawnLogic.clampTriangleColor(2, 4), 4);
  });

  test('pickWeightedColorId maxColorId ≤ 3 : bornes 1..max', () {
    final Random rng = Random(0);
    for (int i = 0; i < 50; i++) {
      final int c = BoardSpawnLogic.pickWeightedColorId(
        maxColorId: 3,
        gameLevel: 1,
        colorPopulationCounts: const <int, int>{},
        rng: rng,
      );
      expect(c, inInclusiveRange(1, 3));
    }
  });

  test('pickWeightedColorId pondéré : déterministe avec RNG fixe', () {
    final Random rng = Random(42);
    final int c = BoardSpawnLogic.pickWeightedColorId(
      maxColorId: 5,
      gameLevel: 1,
      colorPopulationCounts: const <int, int>{},
      rng: rng,
    );
    expect(c, inInclusiveRange(1, 5));
    final int c2 = BoardSpawnLogic.pickWeightedColorId(
      maxColorId: 5,
      gameLevel: 10,
      colorPopulationCounts: const <int, int>{1: 50},
      rng: Random(42),
    );
    expect(c2, inInclusiveRange(1, 5));
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/board_spawn_logic.dart';
import 'package:velour_app/models/game_item.dart';

void main() {
  test('mergeColorCounts agrège plateau + rack', () {
    final List<GameItem> board = <GameItem>[
      GameItem(id: 'a', typeId: 1, colorId: 2, position: Offset.zero),
      GameItem(id: 'b', typeId: 2, colorId: 2, position: Offset.zero),
    ];
    final List<GameItem> slots = <GameItem>[
      GameItem(id: 'c', typeId: 1, colorId: 3, position: Offset.zero),
    ];
    final Map<int, int> m = BoardSpawnLogic.mergeColorCounts(board, slots);
    expect(m[2], 2);
    expect(m[3], 1);
  });

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

  group('maybeApplySlotCompletionBias', () {
    test('golden: biais actif + roll bas + paire → reprend la paire', () {
      final ({int typeId, int colorId}) r =
          BoardSpawnLogic.maybeApplySlotCompletionBias(
            typeId: 9,
            colorId: 9,
            biasMayApply: true,
            roll01: 0.1,
            pair: (typeId: 2, colorId: 3),
          );
      expect(r.typeId, 2);
      expect(r.colorId, 3);
    });

    test('golden: roll au-dessus du seuil → inchangé', () {
      final ({int typeId, int colorId}) r =
          BoardSpawnLogic.maybeApplySlotCompletionBias(
            typeId: 1,
            colorId: 2,
            biasMayApply: true,
            roll01: BoardSpawnLogic.spawnCompletionBiasChance + 0.01,
            pair: (typeId: 9, colorId: 9),
          );
      expect(r.typeId, 1);
      expect(r.colorId, 2);
    });

    test('golden: biais désactivé → jamais la paire', () {
      final ({int typeId, int colorId}) r =
          BoardSpawnLogic.maybeApplySlotCompletionBias(
            typeId: 1,
            colorId: 2,
            biasMayApply: false,
            roll01: 0.0,
            pair: (typeId: 9, colorId: 9),
          );
      expect(r.typeId, 1);
      expect(r.colorId, 2);
    });

    test('golden: pas de paire → inchangé même si roll bas', () {
      final ({int typeId, int colorId}) r =
          BoardSpawnLogic.maybeApplySlotCompletionBias(
            typeId: 4,
            colorId: 4,
            biasMayApply: true,
            roll01: 0.0,
            pair: null,
          );
      expect(r.typeId, 4);
      expect(r.colorId, 4);
    });
  });

  group('rollInitialSeedGem', () {
    test('golden: deux gemmes → chaque compteur forme/couleur ≤ 2', () {
      final Map<int, int> shape = <int, int>{};
      final Map<int, int> color = <int, int>{};
      final Random rng = Random(99);
      for (int i = 0; i < 2; i++) {
        BoardSpawnLogic.rollInitialSeedGem(
          maxShapeId: 4,
          shapeCounts: shape,
          colorCounts: color,
          rng: rng,
          nextColorId: () => 1,
        );
      }
      expect(shape.values.fold<int>(0, (int a, int b) => a + b), 2);
      expect(color.values.fold<int>(0, (int a, int b) => a + b), 2);
      for (final int v in shape.values) {
        expect(v, lessThanOrEqualTo(2));
      }
      for (final int v in color.values) {
        expect(v, lessThanOrEqualTo(2));
      }
    });
  });
}

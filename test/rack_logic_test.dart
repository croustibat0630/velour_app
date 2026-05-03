import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/match_types.dart';
import 'package:velour_app/game/rack_logic.dart';
import 'package:velour_app/models/game_item.dart';

GameItem _g(String id, int typeId, int colorId) => GameItem(
      id: id,
      typeId: typeId,
      colorId: colorId,
      position: Offset.zero,
    );

void main() {
  group('RackLogic.findBestRun', () {
    test('golden: trois identiques → perfect [0,3)', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 2),
        _g('b', 1, 2),
        _g('c', 1, 2),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r, isNotNull);
      expect(r!.start, 0);
      expect(r.endExclusive, 3);
      expect(r.kind, MatchKind.perfect);
      expect(r.basis, RunBasis.perfect);
    });

    test('golden: quatre identiques → perfect le plus long', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 2, 3),
        _g('b', 2, 3),
        _g('c', 2, 3),
        _g('d', 2, 3),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.count, 4);
      expect(r.kind, MatchKind.perfect);
    });

    test('golden: trois même forme couleurs différentes → shape normal', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 1),
        _g('b', 1, 2),
        _g('c', 1, 3),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.basis, RunBasis.shape);
      expect(r.kind, MatchKind.normal);
      expect(r.start, 0);
      expect(r.endExclusive, 3);
    });

    test('golden: trois même couleur formes différentes → color', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 4),
        _g('b', 2, 4),
        _g('c', 3, 4),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.basis, RunBasis.color);
      expect(r.kind, MatchKind.normal);
    });

    test('golden: perfect à droite bat run forme qui se termine avant', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 1),
        _g('b', 1, 2),
        _g('c', 1, 3),
        _g('d', 2, 2),
        _g('e', 2, 2),
        _g('f', 2, 2),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.basis, RunBasis.perfect);
      expect(r.start, 3);
      expect(r.endExclusive, 6);
    });

    test('golden: deux runs perfect même longueur → le plus à gauche', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 1),
        _g('b', 1, 1),
        _g('c', 1, 1),
        _g('d', 2, 2),
        _g('e', 2, 2),
        _g('f', 2, 2),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.start, 0);
      expect(r.endExclusive, 3);
    });

    test('golden: moins de trois pièces → null', () {
      expect(RackLogic.findBestRun(<GameItem>[_g('a', 1, 1), _g('b', 1, 1)]), isNull);
    });

    test('golden: quatre même forme → boosted', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 1),
        _g('b', 1, 2),
        _g('c', 1, 3),
        _g('d', 1, 4),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.kind, MatchKind.boosted);
      expect(r.basis, RunBasis.shape);
    });

    test('golden: cinq même couleur → overcharge', () {
      final List<GameItem> slots = <GameItem>[
        _g('a', 1, 2),
        _g('b', 2, 2),
        _g('c', 3, 2),
        _g('d', 1, 2),
        _g('e', 2, 2),
      ];
      final RackRun? r = RackLogic.findBestRun(slots);
      expect(r!.kind, MatchKind.overcharge);
      expect(r.basis, RunBasis.color);
    });
  });

  group('RackLogic.slotsHaveAnyTripleRun', () {
    test('golden: pas de triple contigu', () {
      expect(
        RackLogic.slotsHaveAnyTripleRun(<GameItem>[
          _g('a', 1, 1),
          _g('b', 2, 2),
          _g('c', 1, 2),
        ]),
        isFalse,
      );
    });

    test('golden: triple forme détecté', () {
      expect(
        RackLogic.slotsHaveAnyTripleRun(<GameItem>[
          _g('a', 1, 1),
          _g('b', 1, 2),
          _g('c', 1, 3),
        ]),
        isTrue,
      );
    });
  });

  group('RackLogic.computeStrategicSlotInsertIndex', () {
    test('golden: rack vide → 0', () {
      expect(RackLogic.computeStrategicSlotInsertIndex(_g('x', 1, 1), <GameItem>[]), 0);
    });

    test('golden: duo identique + 3e identique → après la paire (index 2)', () {
      final List<GameItem> others = <GameItem>[_g('a', 2, 3), _g('b', 2, 3)];
      expect(RackLogic.computeStrategicSlotInsertIndex(_g('c', 2, 3), others), 2);
    });

    test('golden: sans règle spéciale → fin du rack', () {
      final List<GameItem> others = <GameItem>[
        _g('a', 1, 1),
        _g('b', 2, 2),
      ];
      expect(RackLogic.computeStrategicSlotInsertIndex(_g('c', 3, 3), others), 2);
    });
  });

  group('RackLogic.chainScoreMultiplier', () {
    test('golden: étapes 1–5+', () {
      expect(RackLogic.chainScoreMultiplier(1), 1.0);
      expect(RackLogic.chainScoreMultiplier(2), 1.2);
      expect(RackLogic.chainScoreMultiplier(3), 1.5);
      expect(RackLogic.chainScoreMultiplier(4), 2.0);
      expect(RackLogic.chainScoreMultiplier(5), 3.0);
      expect(RackLogic.chainScoreMultiplier(99), 3.0);
    });
  });
}

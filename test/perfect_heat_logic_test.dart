import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/match_types.dart';
import 'package:velour_app/game/perfect_heat_logic.dart';

void main() {
  group('PerfectHeatLogic', () {
    test('isNearMiss: triple shape or color only', () {
      expect(
        PerfectHeatLogic.isNearMiss(MatchKind.normal, RunBasis.shape, 3),
        isTrue,
      );
      expect(
        PerfectHeatLogic.isNearMiss(MatchKind.normal, RunBasis.color, 3),
        isTrue,
      );
      expect(
        PerfectHeatLogic.isNearMiss(MatchKind.normal, RunBasis.perfect, 3),
        isFalse,
      );
      expect(
        PerfectHeatLogic.isNearMiss(MatchKind.normal, RunBasis.shape, 4),
        isFalse,
      );
    });

    test('luxBonusPercent tiers', () {
      expect(PerfectHeatLogic.luxBonusPercent(1), 0);
      expect(PerfectHeatLogic.luxBonusPercent(2), 10);
      expect(PerfectHeatLogic.luxBonusPercent(5), 60);
    });

    test('heatTimeRefillDelta caps by 3s drain', () {
      final double d = PerfectHeatLogic.heatTimeRefillDelta(
        timeBarValueAfterBaseRefund: 0.5,
        baseRefillFraction: 1.0,
        rescueDouble: false,
        timeDrainPerSecond: 0.03,
      );
      expect(d, 0.09);
    });
  });
}

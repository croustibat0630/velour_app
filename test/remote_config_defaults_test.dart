import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/services/economy_service.dart';
import 'package:velour_app/services/remote_config_service.dart';

/// Sans [VelourRemoteConfig.init] : les getters doivent retomber sur les défauts
/// embarqués (tests / offline).
void main() {
  group('VelourRemoteConfig defaults (no init)', () {
    test('economy-facing ints match _defaults semantics', () {
      final VelourRemoteConfig rc = VelourRemoteConfig.instance;
      expect(rc.welcomeLuxGrant, 250);
      expect(rc.dailyLuxBonus, 50);
      expect(rc.highStakesTargetLevel, greaterThanOrEqualTo(1));
      expect(
        rc.royalTargetLevel,
        greaterThanOrEqualTo(rc.highStakesTargetLevel),
      );
    });

    test('run timer clutch multipliers in 0.50–1.00 range', () {
      final VelourRemoteConfig rc = VelourRemoteConfig.instance;
      expect(rc.runTimerClutchMultBelow10, inInclusiveRange(0.5, 0.99));
      expect(rc.runTimerClutchMultBelow35, inInclusiveRange(0.5, 1.0));
    });

    test('idle hard > idle soft', () {
      final VelourRemoteConfig rc = VelourRemoteConfig.instance;
      expect(rc.runIdleHardStartSec, greaterThan(rc.runIdleSoftStartSec));
    });

    test('board flow heat + bias clamps', () {
      final VelourRemoteConfig rc = VelourRemoteConfig.instance;
      expect(rc.boardFlowUnderrepMinHeat, inInclusiveRange(1, 5));
      expect(rc.boardFlowBiasT5, inInclusiveRange(0.05, 0.50));
      expect(
        rc.boardFlowBiasClampMin,
        lessThanOrEqualTo(rc.boardFlowBiasClampMax),
      );
    });

    test('GameState.dailyLuxBonusAmount tracks Remote Config', () {
      expect(
        GameState.dailyLuxBonusAmount,
        VelourRemoteConfig.instance.dailyLuxBonus,
      );
      expect(EconomyService.dailyLuxBonusAmount, GameState.dailyLuxBonusAmount);
    });
  });
}

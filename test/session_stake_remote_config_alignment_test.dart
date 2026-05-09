import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/session_stake_constants.dart';
import 'package:velour_app/services/remote_config_service.dart';

void main() {
  test('SessionStakeConstants getters track Remote Config defaults', () {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    expect(SessionStakeConstants.highStakesWinLux, rc.highStakesWinLux);
    expect(
      SessionStakeConstants.highStakesTargetLevel,
      rc.highStakesTargetLevel,
    );
    expect(SessionStakeConstants.royalAnteLux, rc.royalAnteLux);
    expect(SessionStakeConstants.royalWinLux, rc.royalWinLux);
    expect(SessionStakeConstants.royalTargetLevel, rc.royalTargetLevel);
  });

  test('embedded static defaults (compile-time contract)', () {
    expect(SessionStakeConstants.defaultHighStakesWinLux, 150);
    expect(SessionStakeConstants.defaultHighStakesTargetLevel, 3);
    expect(SessionStakeConstants.defaultRoyalAnteLux, 250);
    expect(SessionStakeConstants.defaultRoyalWinLux, 1250);
    expect(SessionStakeConstants.defaultRoyalTargetLevel, 5);
  });
}

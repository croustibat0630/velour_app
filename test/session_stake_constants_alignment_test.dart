import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/session_stake_constants.dart';
import 'package:velour_app/game/session_stake_resolution.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('GameState expose les mêmes valeurs que SessionStakeConstants', () {
    expect(GameState.highStakesWinLux, SessionStakeConstants.highStakesWinLux);
    expect(
      GameState.highStakesTargetLevel,
      SessionStakeConstants.highStakesTargetLevel,
    );
    expect(GameState.royalAnteLux, SessionStakeConstants.royalAnteLux);
    expect(GameState.royalWinLux, SessionStakeConstants.royalWinLux);
    expect(GameState.royalTargetLevel, SessionStakeConstants.royalTargetLevel);
  });

  test('resolveSessionStakeOnGameOver utilise les gains constants par défaut', () {
    final SessionStakeResolution hs = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.highStakes,
      gameLevel: SessionStakeConstants.highStakesTargetLevel,
    );
    expect(hs.rewardLuxCoins, SessionStakeConstants.highStakesWinLux);

    final SessionStakeResolution ry = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.royal,
      gameLevel: SessionStakeConstants.royalTargetLevel,
    );
    expect(ry.rewardLuxCoins, SessionStakeConstants.royalWinLux);
  });
}

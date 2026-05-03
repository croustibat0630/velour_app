import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/session_stake_resolution.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('casual: pas de gain ni pied de page', () {
    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.casual,
      gameLevel: 99,
    );
    expect(r.footerLine, SessionStakeFooterLine.none);
    expect(r.rewardLuxCoins, 0);
    expect(r.replaySuggestedStake, SessionStakeKind.casual);
  });

  test('high stakes: échec si niveau < objectif', () {
    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.highStakes,
      gameLevel: 2,
    );
    expect(r.footerLine, SessionStakeFooterLine.highStakesFail);
    expect(r.rewardLuxCoins, 0);
    expect(r.replaySuggestedStake, SessionStakeKind.highStakes);
  });

  test('high stakes: gain 150 LUX si niveau >= objectif', () {
    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.highStakes,
      gameLevel: 3,
    );
    expect(r.footerLine, SessionStakeFooterLine.highStakesWin150Lux);
    expect(r.rewardLuxCoins, 150);
    expect(r.replaySuggestedStake, SessionStakeKind.highStakes);
  });

  test('royal: échec si niveau < objectif', () {
    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.royal,
      gameLevel: 4,
    );
    expect(r.footerLine, SessionStakeFooterLine.royalFail);
    expect(r.rewardLuxCoins, 0);
  });

  test('royal: gain 1250 LUX si niveau >= objectif', () {
    final SessionStakeResolution r = resolveSessionStakeOnGameOver(
      sessionStake: SessionStakeKind.royal,
      gameLevel: 5,
    );
    expect(r.footerLine, SessionStakeFooterLine.royalWin1250Lux);
    expect(r.rewardLuxCoins, 1250);
  });
}

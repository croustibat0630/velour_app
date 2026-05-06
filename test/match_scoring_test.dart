import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/match_scoring.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('rawLuxGain : bases et longueur', () {
    expect(MatchScoring.rawLuxGain(RunBasis.shape, 3), 100);
    expect(MatchScoring.rawLuxGain(RunBasis.shape, 4), 200);
    expect(MatchScoring.rawLuxGain(RunBasis.color, 3), 150);
    expect(MatchScoring.rawLuxGain(RunBasis.perfect, 3), 500);
    expect(MatchScoring.rawLuxGain(RunBasis.perfect, 5), 1500);
  });

  test('sessionScoreMultiplier casual / premium', () {
    expect(
      MatchScoring.sessionScoreMultiplier(SessionStakeKind.casual, 1),
      1.0,
    );
    expect(
      MatchScoring.sessionScoreMultiplier(SessionStakeKind.highStakes, 2),
      1.0,
    );
    expect(
      MatchScoring.sessionScoreMultiplier(SessionStakeKind.highStakes, 3),
      1.5,
    );
    expect(MatchScoring.sessionScoreMultiplier(SessionStakeKind.royal, 4), 1.0);
    expect(MatchScoring.sessionScoreMultiplier(SessionStakeKind.royal, 5), 3.0);
  });

  test('roundChainedLux', () {
    expect(MatchScoring.roundChainedLux(100, 1.0, 1.2), 120);
    expect(MatchScoring.roundChainedLux(500, 1.5, 2.0), 1500);
  });
}

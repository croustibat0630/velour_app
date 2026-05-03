import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/tutorial_board_specs.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('narrative : 3 gemmes par étape', () {
    expect(NarrativeTutorialBoardSpecs.step1Gems.length, 3);
    expect(NarrativeTutorialBoardSpecs.step2Gems.length, 3);
    expect(NarrativeTutorialBoardSpecs.step3GemCount, 3);
  });

  test('trinity : 3 gemmes par phase active', () {
    expect(
      TrinityTutorialBoardSpecs.gemsFor(TrinityTutorialPhase.shape)!.length,
      3,
    );
    expect(
      TrinityTutorialBoardSpecs.gemsFor(TrinityTutorialPhase.color)!.length,
      3,
    );
    expect(
      TrinityTutorialBoardSpecs.gemsFor(TrinityTutorialPhase.perfect)!.length,
      3,
    );
    expect(TrinityTutorialBoardSpecs.gemsFor(TrinityTutorialPhase.none), isNull);
  });
}

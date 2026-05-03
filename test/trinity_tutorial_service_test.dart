import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/providers/game_state_types.dart';
import 'package:velour_app/services/trinity_tutorial_service.dart';

void main() {
  TrinityTutorialService fresh() => TrinityTutorialService();

  test('shouldOfferAtInit casual niveau 1 non complété', () {
    final TrinityTutorialService t = fresh();
    expect(
      t.shouldOfferAtInit(
        isFirstTimeGame: false,
        stake: SessionStakeKind.casual,
        gameLevel: 1,
      ),
      isTrue,
    );
  });

  test('shouldOfferAtInit false si première partie', () {
    final TrinityTutorialService t = fresh();
    expect(
      t.shouldOfferAtInit(
        isFirstTimeGame: true,
        stake: SessionStakeKind.casual,
        gameLevel: 1,
      ),
      isFalse,
    );
  });

  test('shouldOfferAtInit false si tutoriel déjà complété', () {
    final TrinityTutorialService t = fresh();
    t.hydrateCompleteFromDisk(true);
    expect(
      t.shouldOfferAtInit(
        isFirstTimeGame: false,
        stake: SessionStakeKind.casual,
        gameLevel: 1,
      ),
      isFalse,
    );
  });

  test('chaîne shape → color → perfect + persist', () async {
    int persistCalls = 0;
    int clears = 0;
    int seeds = 0;
    int fills = 0;

    void clear() => clears++;
    void seed() => seeds++;
    void fill() => fills++;

    final TrinityTutorialService t = fresh();
    t.beginShapeIntro();
    expect(t.isChronoFrozen, isTrue);

    t.advanceAfterMatch(
      RunBasis.shape,
      persistTrinityTutorialComplete: () async {
        persistCalls++;
      },
      onClearSlotsAndBoard: clear,
      onReseedTrinityBoard: seed,
      onFillBoardToCap: fill,
    );
    expect(t.phase, TrinityTutorialPhase.color);
    expect(clears, 1);
    expect(seeds, 1);

    t.advanceAfterMatch(
      RunBasis.color,
      persistTrinityTutorialComplete: () async {
        persistCalls++;
      },
      onClearSlotsAndBoard: clear,
      onReseedTrinityBoard: seed,
      onFillBoardToCap: fill,
    );
    expect(t.phase, TrinityTutorialPhase.perfect);
    expect(clears, 2);
    expect(seeds, 2);

    t.advanceAfterMatch(
      RunBasis.perfect,
      persistTrinityTutorialComplete: () async {
        persistCalls++;
      },
      onClearSlotsAndBoard: clear,
      onReseedTrinityBoard: seed,
      onFillBoardToCap: fill,
    );
    await Future<void>.delayed(Duration.zero);
    expect(t.isComplete, isTrue);
    expect(t.phase, TrinityTutorialPhase.none);
    expect(persistCalls, 1);
    expect(clears, 3);
    expect(fills, 1);
    expect(seeds, 2);
  });

  test('mauvaise base ne fait pas avancer', () {
    final TrinityTutorialService t = fresh();
    t.beginShapeIntro();
    t.advanceAfterMatch(
      RunBasis.color,
      persistTrinityTutorialComplete: () async {},
      onClearSlotsAndBoard: () {},
      onReseedTrinityBoard: () {},
      onFillBoardToCap: () {},
    );
    expect(t.phase, TrinityTutorialPhase.shape);
  });

  test('markCompleteFromNarrative', () {
    final TrinityTutorialService t = fresh();
    t.beginShapeIntro();
    t.markCompleteFromNarrative();
    expect(t.isComplete, isTrue);
    expect(t.phase, TrinityTutorialPhase.none);
    expect(t.isChronoFrozen, isFalse);
  });
}

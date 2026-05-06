import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/providers/game_state_types.dart';
import 'package:velour_app/services/narrative_tutorial_service.dart';

void main() {
  test('beginCasualFirstRunBoardInit met step1Shape', () {
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () {},
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    expect(s.phase, NarrativeTutorialPhase.step1Shape);
    expect(s.uiReveal, 0);
  });

  test('applyAfterMatch step1 shape → step2 + reseed shape', () {
    int reseedShape = 0;
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () => reseedShape++,
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    s.applyAfterMatch(true, RunBasis.shape, 0.2);
    expect(s.phase, NarrativeTutorialPhase.step2Color);
    expect(s.uiReveal, 1);
    expect(reseedShape, 1);
  });

  test('applyAfterMatch step2 color → step3 + refund + reseed color', () {
    int reseedColor = 0;
    double? refunded;
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (double p) => refunded = p,
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () {},
      onReseedBoardAfterColorTutorialMatch: () => reseedColor++,
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    s.applyAfterMatch(true, RunBasis.shape, 0.2);
    s.applyAfterMatch(true, RunBasis.color, 0.44);
    expect(s.phase, NarrativeTutorialPhase.step3Perfect);
    expect(reseedColor, 1);
    expect(refunded, 0.44);
  });

  test('applyAfterMatch mauvaise base ne change pas la phase', () {
    int reseedShape = 0;
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () => reseedShape++,
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    s.applyAfterMatch(true, RunBasis.color, 0.2);
    expect(s.phase, NarrativeTutorialPhase.step1Shape);
    expect(reseedShape, 0);
  });

  test('hudOpacities plein hors première partie', () {
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () {},
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    final op = s.hudOpacities(false);
    expect(op.level, 1.0);
    expect(op.time, 1.0);
  });

  test('applyAfterMatch step3 perfect → celebration + FX', () {
    bool exploded = false;
    bool fullBar = false;
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () => exploded = true,
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () => fullBar = true,
      onReseedBoardAfterShapeTutorialMatch: () {},
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    s.applyAfterMatch(true, RunBasis.shape, 0.2);
    s.applyAfterMatch(true, RunBasis.color, 0.2);
    s.applyAfterMatch(true, RunBasis.perfect, 0.2);
    expect(s.phase, NarrativeTutorialPhase.celebration);
    expect(exploded, isTrue);
    expect(fullBar, isTrue);
    s.dispose();
  });

  test('floatingKeyForMatch step1 ne renvoie que shape', () {
    final NarrativeTutorialService s = NarrativeTutorialService(
      onPersistTutorialComplete: () async {},
      onExplosionShake: () {},
      refundTimeBarPortion: (_) {},
      setTimeBarFull: () {},
      onReseedBoardAfterShapeTutorialMatch: () {},
      onReseedBoardAfterColorTutorialMatch: () {},
      onCelebrationStarted: () {},
    );
    s.beginCasualFirstRunBoardInit();
    expect(
      s.floatingKeyForMatch(RunBasis.shape),
      NarrativeFloatingKey.shapeBonus,
    );
    expect(s.floatingKeyForMatch(RunBasis.color), isNull);
  });
}

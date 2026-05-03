import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/run_timer_logic.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('difficultySpeedMultiplier : Royal > casual', () {
    final double c = RunTimerLogic.difficultySpeedMultiplier(
      stake: SessionStakeKind.casual,
      gameLevel: 1,
    );
    final double r = RunTimerLogic.difficultySpeedMultiplier(
      stake: SessionStakeKind.royal,
      gameLevel: 1,
    );
    expect(r, greaterThan(c));
  });

  test('timeDrainPerSecond augmente avec la difficulté', () {
    final double d1 = RunTimerLogic.timeDrainPerSecond(
      baseTimeDrainPerSecond: 0.03,
      stake: SessionStakeKind.casual,
      gameLevel: 1,
    );
    final double d5 = RunTimerLogic.timeDrainPerSecond(
      baseTimeDrainPerSecond: 0.03,
      stake: SessionStakeKind.casual,
      gameLevel: 5,
    );
    expect(d5, greaterThan(d1));
  });

  test('nextTimeBarAfterTick décrémente et clamp 0–1', () {
    expect(
      RunTimerLogic.nextTimeBarAfterTick(
        currentValue: 1.0,
        timeDrainPerSecond: 0.1,
        dtSeconds: 15.0,
      ),
      0.0,
    );
    expect(
      RunTimerLogic.nextTimeBarAfterTick(
        currentValue: 0.05,
        timeDrainPerSecond: 0.1,
        dtSeconds: 0.5,
      ),
      0.0,
    );
  });

  test('matchTimeRefund décroît avec le niveau', () {
    final double l1 = RunTimerLogic.matchTimeRefund(
      baseMatchTimeRefund: 0.2,
      gameLevel: 1,
    );
    final double l3 = RunTimerLogic.matchTimeRefund(
      baseMatchTimeRefund: 0.2,
      gameLevel: 3,
    );
    expect(l3, lessThan(l1));
  });

  test('effectiveMatchDelay : plafond à baseMatchDelay', () {
    const Duration base = Duration(milliseconds: 350);
    final Duration d = RunTimerLogic.effectiveMatchDelay(
      baseMatchDelay: base,
      difficultySpeedMultiplier: 0.5,
      isRoyalSession: false,
    );
    expect(d.inMilliseconds, lessThanOrEqualTo(350));
    expect(d.inMilliseconds, greaterThanOrEqualTo(120));
  });

  test('effectiveMatchDelay : Royal raccourcit vs casual même difficulté', () {
    const Duration base = Duration(milliseconds: 350);
    const double mult = 1.5;
    final int casual = RunTimerLogic.effectiveMatchDelay(
      baseMatchDelay: base,
      difficultySpeedMultiplier: mult,
      isRoyalSession: false,
    ).inMilliseconds;
    final int royal = RunTimerLogic.effectiveMatchDelay(
      baseMatchDelay: base,
      difficultySpeedMultiplier: mult,
      isRoyalSession: true,
    ).inMilliseconds;
    expect(royal, lessThan(casual));
  });

  test('effectiveMatchDelay : plancher 120 ms', () {
    const Duration base = Duration(milliseconds: 350);
    final Duration d = RunTimerLogic.effectiveMatchDelay(
      baseMatchDelay: base,
      difficultySpeedMultiplier: 99.0,
      isRoyalSession: true,
    );
    expect(d.inMilliseconds, 120);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/run_timer_logic.dart';

void main() {
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

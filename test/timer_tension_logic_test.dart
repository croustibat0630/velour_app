import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/timer_tension_logic.dart';

void main() {
  test('drainMultiplier soulage en zone critique', () {
    expect(
      TimerTensionLogic.drainMultiplierForBarFraction(0.05),
      lessThan(1.0),
    );
    expect(TimerTensionLogic.drainMultiplierForBarFraction(0.5), 1.0);
  });

  test('idleHurry reste 1.0 si action récente', () {
    expect(
      TimerTensionLogic.idleHurryMultiplier(
        sinceLastPlayerAction: const Duration(seconds: 1),
      ),
      1.0,
    );
  });

  test('idleHurry augmente après longue inactivité', () {
    final double m = TimerTensionLogic.idleHurryMultiplier(
      sinceLastPlayerAction: const Duration(seconds: 20),
    );
    expect(m, greaterThan(1.0));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/meta_progression_policy.dart';

void main() {
  test('luxRequired varie avec la vague et le DDA', () {
    final int low = MetaProgressionPolicy.luxRequiredForNextLevel(
      gameLevel: 3,
      perfEmaLuxPerMinute: 80,
    );
    final int high = MetaProgressionPolicy.luxRequiredForNextLevel(
      gameLevel: 3,
      perfEmaLuxPerMinute: 900,
    );
    expect(low, lessThan(high));
  });

  test('EMA converge vers un échantillon', () {
    double e = MetaProgressionPolicy.neutralLuxPerMinute;
    e = MetaProgressionPolicy.emaLuxPerMinute(
      previousEma: e,
      sampleLuxPerMinute: 600,
      alpha: 0.5,
    );
    expect(e, greaterThan(MetaProgressionPolicy.neutralLuxPerMinute));
  });
}

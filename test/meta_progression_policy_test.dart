import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/meta_progression_policy.dart';
import 'package:velour_app/services/remote_config_service.dart';

void main() {
  test('EMA LUX/minute lisse les échantillons (alpha Remote Config)', () {
    final double alpha = VelourRemoteConfig.instance.metaEmaAlpha;
    expect(alpha, greaterThan(0));
    expect(alpha, lessThanOrEqualTo(0.5));

    double ema = MetaProgressionPolicy.neutralLuxPerMinute;
    ema = MetaProgressionPolicy.emaLuxPerMinute(
      previousEma: ema,
      sampleLuxPerMinute: ema * 2,
    );
    expect(ema, greaterThan(MetaProgressionPolicy.neutralLuxPerMinute));
    expect(ema, lessThan(MetaProgressionPolicy.neutralLuxPerMinute * 2));
  });

  test(
    'luxRequiredForNextLevel : DDA reste dans la bande ±3 % autour de l’ancre',
    () {
      final double neutral =
          VelourRemoteConfig.instance.metaNeutralLuxPerMinute;
      const int level = 14;
      final int atNeutral = MetaProgressionPolicy.luxRequiredForNextLevel(
        gameLevel: level,
        perfEmaLuxPerMinute: neutral,
      );
      expect(atNeutral, greaterThan(0));

      for (final double perf in [60.0, neutral, 520.0]) {
        final int need = MetaProgressionPolicy.luxRequiredForNextLevel(
          gameLevel: level,
          perfEmaLuxPerMinute: perf,
        );
        final double rel = (need - atNeutral).abs() / atNeutral;
        expect(
          rel,
          lessThanOrEqualTo(0.07),
          reason: 'perf=$perf need=$need neutralRef=$atNeutral',
        );
      }
    },
  );

  test('Remote Config defaults méta cohérents (audit pré-store)', () {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    expect(rc.metaDdaCenterDivisor, inInclusiveRange(120, 900));
    expect(rc.metaWaveStrength, inInclusiveRange(0.0, 0.08));
    expect(rc.metaDdaStrength, inInclusiveRange(0.0, 0.055));
    expect(rc.metaNeutralLuxPerMinute, inInclusiveRange(50, 800));
    expect(rc.metaEmaAlpha, inInclusiveRange(0.02, 0.4));
  });
}

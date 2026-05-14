import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/oracle_pseudo.dart';
import 'package:velour_app/models/skin_config.dart';
import 'package:velour_app/services/app_settings.dart';
import 'package:velour_app/services/lux_apply_motifs.dart';
import 'package:velour_app/services/lux_credit_limits.dart';
import 'package:velour_app/theme/colors.dart';
import 'package:velour_app/theme/theme_engine.dart';
import 'package:velour_app/utils/responsive.dart';
import 'package:velour_app/utils/route_transition_notifier.dart';
import 'package:velour_app/utils/velour_release_links.dart';

Size _size(double w, double h) => Size(w, h);

void main() {
  group('Responsive', () {
    testWidgets('textScale respects accessibility + device clamp', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            textScaler: TextScaler.linear(1.2),
          ),
          child: Builder(
            builder: (BuildContext context) {
              final double s = Responsive.textScale(context);
              expect(s, greaterThanOrEqualTo(0.90));
              expect(s, lessThanOrEqualTo(1.25));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('compactHeightScale < 1 when height below threshold', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: _size(600, 400)),
          child: Builder(
            builder: (BuildContext context) {
              expect(Responsive.compactHeightScale(context), lessThan(1.0));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('capWidth clamps to max', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: _size(2000, 800)),
          child: Builder(
            builder: (BuildContext context) {
              expect(Responsive.capWidth(context, 460), 460);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ThemeEngine', () {
    test('colorForId uses palette and skin overrides', () {
      final ThemeEngine te = ThemeEngine();
      expect(te.colorForId(2), ThemeEngine.defaultTheme.paletteByColorId[2]);
      te.applySkinColors(
        primary: const Color(0xFF111111),
        secondary: const Color(0xFF222222),
      );
      expect(te.colorForId(1), const Color(0xFF111111));
      expect(te.colorForId(5), const Color(0xFF222222));
      te.applySkinColors(
        primary: const Color(0xFF111111),
        secondary: const Color(0xFF222222),
      );
      // Idempotent : pas de throw
    });
  });

  group('OraclePseudo', () {
    test('isValid', () {
      expect(OraclePseudo.isValid('ab'), isTrue);
      expect(OraclePseudo.isValid('Abc_09'), isTrue);
      expect(OraclePseudo.isValid(''), isFalse);
      expect(OraclePseudo.isValid('a' * 16), isFalse);
      expect(OraclePseudo.isValid('bad-chars'), isFalse);
    });

    test('normalize + display', () {
      expect(OraclePseudo.normalizeForStorage('PiErRe'), 'pierre');
      expect(OraclePseudo.formatForDisplay('pierre'), 'Pierre');
      expect(OraclePseudo.formatForDisplay(''), '');
    });
  });

  group('SkinCatalog', () {
    test('byId fallback standard', () {
      expect(SkinCatalog.byId('standard').id, 'standard');
      expect(SkinCatalog.byId('unknown_xyz').id, 'standard');
      expect(SkinCatalog.neonAmber.isFree, isFalse);
      expect(SkinCatalog.standard.isFree, isTrue);
    });
  });

  group('RouteTransitionNotifier', () {
    tearDown(RouteTransitionNotifier.resetForTests);

    test('nested begin/end', () {
      expect(RouteTransitionNotifier.isTransitioning, isFalse);
      RouteTransitionNotifier.begin();
      expect(RouteTransitionNotifier.isTransitioning, isTrue);
      RouteTransitionNotifier.begin();
      expect(RouteTransitionNotifier.isTransitioning, isTrue);
      RouteTransitionNotifier.end();
      expect(RouteTransitionNotifier.isTransitioning, isTrue);
      RouteTransitionNotifier.end();
      expect(RouteTransitionNotifier.isTransitioning, isFalse);
    });

    test('resetForTests clears leaked begins', () {
      RouteTransitionNotifier.begin();
      RouteTransitionNotifier.begin();
      expect(RouteTransitionNotifier.isTransitioning, isTrue);
      RouteTransitionNotifier.resetForTests();
      expect(RouteTransitionNotifier.isTransitioning, isFalse);
    });
  });

  group('LuxCreditLimits / LuxApplyMotifs', () {
    test('max positive credit positive', () {
      expect(LuxCreditLimits.maxPositiveCreditPerApply, greaterThan(5000));
    });

    test('cloudDrainOrder unique and non-empty', () {
      final Set<String> u = LuxApplyMotifs.cloudDrainOrder.toSet();
      expect(u.length, LuxApplyMotifs.cloudDrainOrder.length);
      expect(
        LuxApplyMotifs.cloudDrainOrder,
        contains(LuxApplyMotifs.stakeAnte),
      );
    });
  });

  group('AppSettings.materialLocaleFor', () {
    test('system → null', () {
      expect(AppSettings.materialLocaleFor(AppLocalePreference.system), isNull);
    });

    test('pinned locales', () {
      expect(
        AppSettings.materialLocaleFor(AppLocalePreference.fr)?.languageCode,
        'fr',
      );
      expect(
        AppSettings.materialLocaleFor(AppLocalePreference.de)?.languageCode,
        'de',
      );
      expect(
        AppSettings.materialLocaleFor(AppLocalePreference.zh)?.languageCode,
        'zh',
      );
      expect(
        AppSettings.materialLocaleFor(AppLocalePreference.zh)?.scriptCode,
        'Hans',
      );
      expect(
        AppSettings.materialLocaleFor(AppLocalePreference.hi)?.languageCode,
        'hi',
      );
    });
  });

  group('VelourReleaseLinks', () {
    test('privacy URL constant is well-formed define or empty', () {
      final String u = VelourReleaseLinks.privacyPolicyUrl.trim();
      if (u.isNotEmpty) {
        expect(u.startsWith('http://') || u.startsWith('https://'), isTrue);
      }
      expect(VelourReleaseLinks.hasPrivacyPolicyUrl, u.isNotEmpty);
    });

    test('appStoreListingPrivacyPolicyUrl is stable https Notion URL', () {
      final String listing = VelourReleaseLinks.appStoreListingPrivacyPolicyUrl;
      expect(listing.startsWith('https://'), isTrue);
      expect(Uri.tryParse(listing)?.hasAbsolutePath, isTrue);
      expect(listing.contains('notion.site'), isTrue);
    });
  });

  group('NeonColors', () {
    test('opaque colors', () {
      expect(NeonColors.background.a, 1.0);
      expect(NeonColors.cyan.a, 1.0);
    });
  });
}

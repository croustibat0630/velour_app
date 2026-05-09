import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/utils/gem_accessibility.dart';

void main() {
  testWidgets('gemAccessibilityLabel combines shape and color (en)', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final String label = gemAccessibilityLabel(l10n, 1, 1);
    expect(label, contains('Crystal'));
    expect(label, contains('Cyan'));
  });
}

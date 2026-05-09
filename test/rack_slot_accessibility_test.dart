import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/models/game_item.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/utils/rack_accessibility.dart';

void main() {
  testWidgets('rack slot semantics: empty vs gem (en)', (
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

    final List<GameItem> twoSlots = <GameItem>[
      GameItem(
        id: 'a',
        typeId: 1,
        colorId: 1,
        position: Offset.zero,
        isSelected: false,
        floatPeriodMs: 0,
        floatPhase: 0,
      ),
      GameItem(
        id: 'b',
        typeId: 2,
        colorId: 2,
        position: Offset.zero,
        isSelected: false,
        floatPeriodMs: 0,
        floatPhase: 0,
      ),
    ];

    final String emptyLast = rackSlotSemanticsLabel(
      l10n,
      GameState.slotCount - 1,
      twoSlots,
      <int>{},
    );
    expect(emptyLast, contains('empty'));
    expect(emptyLast, contains('${GameState.slotCount}'));

    final String firstGem = rackSlotSemanticsLabel(l10n, 0, twoSlots, <int>{
      0,
      1,
    });
    expect(firstGem, contains('Rack slot 1'));
    expect(firstGem, contains('almost complete'));
  });
}

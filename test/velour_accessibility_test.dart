import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/utils/velour_accessibility.dart';

void main() {
  testWidgets('velourReduceMotion reflects MediaQuery.disableAnimations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (BuildContext context) {
              expect(velourReduceMotion(context), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('velourReduceMotion false when animations allowed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (BuildContext context) {
              expect(velourReduceMotion(context), isFalse);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}

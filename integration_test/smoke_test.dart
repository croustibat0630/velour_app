import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Point d’entrée minimal pour `flutter test integration_test/` ou device CI.
/// Étendre ici avec navigation réelle (Patrol, etc.) si besoin.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration binding initialisé', (WidgetTester tester) async {
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
  });
}

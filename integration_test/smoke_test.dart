import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Point d’entrée minimal pour `flutter test integration_test/` (séparé de `test/`).
///
/// Si le simulateur iOS échoue (ex. cache Xcode `SDKStatCaches` manquant), lancer
/// explicitement : `flutter test integration_test/smoke_test.dart -d macos`.
/// Étendre ici avec navigation réelle (Patrol, etc.) si besoin.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration binding initialisé', (WidgetTester tester) async {
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
  });
}

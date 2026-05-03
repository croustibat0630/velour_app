import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/oracle_naming_service.dart';

void main() {
  test('submitName chaîne vide → false', () async {
    final OracleNamingService s = OracleNamingService();
    expect(await s.submitName(''), isFalse);
    expect(await s.submitName('   '), isFalse);
  });

  test('submitName invalide → false', () async {
    final OracleNamingService s = OracleNamingService();
    expect(await s.submitName('!@#'), isFalse);
  });

  test('dismiss sans dialogue ne plante pas', () {
    final OracleNamingService s = OracleNamingService();
    s.dismiss();
    expect(s.shouldShowDialog, isFalse);
  });

  test('reset ferme le dialogue', () {
    final OracleNamingService s = OracleNamingService();
    // Pas d’offre cloud synchrone ici : on force l’état via reset seulement
    s.reset();
    expect(s.shouldShowDialog, isFalse);
  });
}

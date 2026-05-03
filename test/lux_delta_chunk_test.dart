import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/firestore_service.dart';

void main() {
  test('chunkLuxDeltaForCallable respecte les plafonds CF (+2500 / -500k)', () {
    expect(FirestoreService.chunkLuxDeltaForCallable(0), 0);
    expect(FirestoreService.chunkLuxDeltaForCallable(100), 100);
    expect(FirestoreService.chunkLuxDeltaForCallable(2500), 2500);
    expect(FirestoreService.chunkLuxDeltaForCallable(10_000), 2500);
    expect(FirestoreService.chunkLuxDeltaForCallable(-100), -100);
    expect(FirestoreService.chunkLuxDeltaForCallable(-600_000), -500000);
  });
}

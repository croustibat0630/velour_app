import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/screens/leaderboard_view.dart';

int _hs(Map<String, dynamic> d) => (d['highScore'] as num?)?.toInt() ?? 0;

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
  });

  test('sortedLeaderboardDocs: score desc, id asc tie-break', () async {
    await fake.collection('lb').doc('b').set(<String, dynamic>{
      'highScore': 100,
    });
    await fake.collection('lb').doc('a').set(<String, dynamic>{
      'highScore': 100,
    });
    await fake.collection('lb').doc('c').set(<String, dynamic>{
      'highScore': 200,
    });
    final snap = await fake.collection('lb').get();
    final sorted = sortedLeaderboardDocs(snap.docs);
    expect(sorted.length, 3);
    expect(_hs(sorted[0].data()), 200);
    expect(_hs(sorted[1].data()), 100);
    expect(_hs(sorted[2].data()), 100);
    expect(sorted[1].id, 'a');
    expect(sorted[2].id, 'b');
  });

  test('denseRanksForSortedLeaderboardDocs', () async {
    await fake.collection('lb').doc('a').set(<String, dynamic>{
      'highScore': 100,
    });
    await fake.collection('lb').doc('b').set(<String, dynamic>{
      'highScore': 100,
    });
    await fake.collection('lb').doc('c').set(<String, dynamic>{
      'highScore': 80,
    });
    final snap = await fake.collection('lb').get();
    final sorted = sortedLeaderboardDocs(snap.docs);
    final ranks = denseRanksForSortedLeaderboardDocs(sorted);
    expect(ranks, <int>[1, 1, 2]);
  });

  test('denseRanks empty', () {
    expect(denseRanksForSortedLeaderboardDocs(const []), isEmpty);
  });

  test('sortedLeaderboardDocs single element', () async {
    await fake.collection('lb').doc('solo').set(<String, dynamic>{
      'highScore': 42,
    });
    final snap = await fake.collection('lb').get();
    expect(sortedLeaderboardDocs(snap.docs).length, 1);
  });
}

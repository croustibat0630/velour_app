import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/firestore_dense_world_rank_snapshot.dart';

void main() {
  late FakeFirebaseFirestore fake;

  Future<void> setPublicScore(String id, int highScore) {
    return fake.collection('leaderboardPublic').doc(id).set(<String, dynamic>{
      'highScore': highScore,
      'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 6, 1)),
    });
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
  });

  test('paliers au-dessus + ex-aequo sur le même score', () async {
    await setPublicScore('a', 100);
    await setPublicScore('b', 100);
    await setPublicScore('c', 80);
    await setPublicScore('d', 50);
    await setPublicScore('e', 50);

    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 50);
    expect(r.denseRank, 3);
    expect(r.tiedWithOthersSameScore, isTrue);
  });

  test('un seul joueur au palier → pas d’ex-aequo', () async {
    await setPublicScore('a', 200);
    await setPublicScore('b', 100);
    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 100);
    expect(r.denseRank, 2);
    expect(r.tiedWithOthersSameScore, isFalse);
  });

  test('aucun score au-dessus du tien', () async {
    await setPublicScore('solo', 42);
    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 42);
    expect(r.denseRank, 1);
    expect(r.tiedWithOthersSameScore, isFalse);
  });

  test(
    'plusieurs joueurs au même palier supérieur (un seul palier au-dessus)',
    () async {
      for (int i = 0; i < 5; i++) {
        await setPublicScore('top$i', 1000);
      }
      await setPublicScore('me', 10);
      final ({int denseRank, bool tiedWithOthersSameScore}) r =
          await computeMyDenseWorldRankFromFirestore(fake, 10);
      expect(r.denseRank, 2);
      expect(r.tiedWithOthersSameScore, isFalse);
    },
  );
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/firestore_dense_world_rank_snapshot.dart';

void main() {
  late FakeFirebaseFirestore fake;

  Future<void> setPlayer(String id, int highScore) {
    return fake.collection('players').doc(id).set(<String, dynamic>{
      'highScore': highScore,
    });
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
  });

  test('paliers au-dessus + ex-aequo sur le même score', () async {
    await setPlayer('a', 100);
    await setPlayer('b', 100);
    await setPlayer('c', 80);
    await setPlayer('d', 50);
    await setPlayer('e', 50);

    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 50);
    expect(r.denseRank, 3);
    expect(r.tiedWithOthersSameScore, isTrue);
  });

  test('un seul joueur au palier → pas d’ex-aequo', () async {
    await setPlayer('a', 200);
    await setPlayer('b', 100);
    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 100);
    expect(r.denseRank, 2);
    expect(r.tiedWithOthersSameScore, isFalse);
  });

  test('aucun score au-dessus du tien', () async {
    await setPlayer('solo', 42);
    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 42);
    expect(r.denseRank, 1);
    expect(r.tiedWithOthersSameScore, isFalse);
  });

  test('plusieurs joueurs au même palier supérieur (un seul palier au-dessus)', () async {
    for (int i = 0; i < 5; i++) {
      await setPlayer('top$i', 1000);
    }
    await setPlayer('me', 10);
    final ({int denseRank, bool tiedWithOthersSameScore}) r =
        await computeMyDenseWorldRankFromFirestore(fake, 10);
    expect(r.denseRank, 2);
    expect(r.tiedWithOthersSameScore, isFalse);
  });
}

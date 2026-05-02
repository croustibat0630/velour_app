import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/dense_world_rank_logic.dart';

Future<List<int>> _emptyScorePage(int cursorExclusive, int limit) async =>
    <int>[];

void main() {
  test('aucun score au-dessus → rang 1', () async {
    final int r = await computeDenseWorldRank1Based(
      myScore: 100,
      readScoresAboveSortedAsc: _emptyScorePage,
    );
    expect(r, 1);
  });

  test('un seul palier au-dessus (plusieurs joueurs même score)', () async {
    final int r = await computeDenseWorldRank1Based(
      myScore: 50,
      readScoresAboveSortedAsc: (int c, int _) async {
        if (c == 50) return <int>[80, 80, 80];
        return <int>[];
      },
    );
    expect(r, 2);
  });

  test('plusieurs paliers dans une seule page', () async {
    final int r = await computeDenseWorldRank1Based(
      myScore: 10,
      readScoresAboveSortedAsc: (int c, int _) async {
        if (c == 10) return <int>[20, 30, 30, 40, 50];
        return <int>[];
      },
      batchSize: 100,
    );
    expect(r, 5);
  });

  test('pagination sur plusieurs pages', () async {
    final int r = await computeDenseWorldRank1Based(
      myScore: 0,
      readScoresAboveSortedAsc: (int c, int lim) async {
        if (c == 0) {
          return <int>[1, 2, 3];
        }
        if (c == 3) {
          return <int>[4, 5];
        }
        return <int>[];
      },
      batchSize: 3,
    );
    expect(r, 6);
  });

  test('page complète puis paliers au-delà du dernier score de page', () async {
    final int r = await computeDenseWorldRank1Based(
      myScore: 0,
      readScoresAboveSortedAsc: (int c, int lim) async {
        if (c == 0) return <int>[10, 20];
        if (c == 20) return <int>[30];
        return <int>[];
      },
      batchSize: 2,
    );
    expect(r, 4);
  });
}

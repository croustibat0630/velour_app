import 'package:cloud_firestore/cloud_firestore.dart';

import 'dense_world_rank_logic.dart';

/// Collection des scores exposés au classement (défaut : `leaderboardPublic`).
const String kLeaderboardScoresCollection = 'leaderboardPublic';

/// Rang dense mondial + indicateur d’ex-aequo sur le même [highScore],
/// pour un [FirebaseFirestore] injectable (prod ou fake).
Future<({int denseRank, bool tiedWithOthersSameScore})>
computeMyDenseWorldRankFromFirestore(
  FirebaseFirestore db,
  int myScore, {
  String scoresCollection = kLeaderboardScoresCollection,
}) async {
  final int dense = await computeDenseWorldRank1Based(
    myScore: myScore,
    readScoresAboveSortedAsc: (int cursor, int limit) async {
      final QuerySnapshot<Map<String, dynamic>> snap = await db
          .collection(scoresCollection)
          .where('highScore', isGreaterThan: cursor)
          .orderBy('highScore')
          .limit(limit)
          .get();
      return snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                (d.data()['highScore'] as num?)?.toInt() ?? 0,
          )
          .toList();
    },
  );
  bool tied = false;
  try {
    final AggregateQuerySnapshot sameAgg = await db
        .collection(scoresCollection)
        .where('highScore', isEqualTo: myScore)
        .count()
        .get();
    final int same = sameAgg.count ?? 0;
    tied = same > 1;
  } catch (_) {
    // Count aggregates can fail on some clients/network paths; rank still valid.
    tied = false;
  }
  return (denseRank: dense, tiedWithOthersSameScore: tied);
}

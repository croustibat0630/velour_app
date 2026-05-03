/// Logique du **rang dense mondial** (1 + nombre de paliers de score
/// strictement supérieurs au tien), lue par **pages** triées croissant.
///
/// Découplée de Firestore pour tests unitaires et un seul endroit à maintenir.
Future<int> computeDenseWorldRank1Based({
  required int myScore,
  required Future<List<int>> Function(int cursorExclusive, int limit)
  readScoresAboveSortedAsc,
  int batchSize = 64,
  int maxPages = 48,
}) async {
  int distinctAbove = 0;
  int cursor = myScore;
  for (int p = 0; p < maxPages; p++) {
    final List<int> page = await readScoresAboveSortedAsc(cursor, batchSize);
    if (page.isEmpty) break;
    int? prev;
    for (final int s in page) {
      if (s <= cursor) continue;
      if (prev == null || s != prev) {
        distinctAbove++;
        prev = s;
      }
    }
    if (page.length < batchSize) break;
    cursor = page.last;
  }
  return distinctAbove + 1;
}

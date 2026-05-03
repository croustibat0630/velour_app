import 'match_types.dart';
import '../models/game_item.dart';

/// Segment contigu du rack à résoudre (indices dans [List<GameItem] slots).
class RackRun {
  const RackRun({
    required this.start,
    required this.endExclusive,
    required this.kind,
    required this.basis,
  });

  final int start;
  final int endExclusive;
  final MatchKind kind;
  final RunBasis basis;

  int get count => endExclusive - start;
}

/// Logique pure du rack : meilleur match visible, insertion stratégique, garde-fous cascade.
///
/// Extraite de [GameState] pour tests golden et refactor progressif.
abstract final class RackLogic {
  RackLogic._();

  /// Mult score cascade : 1er match = ×1, puis ×1.2 / ×1.5 / ×2 / ×3.
  static double chainScoreMultiplier(int chainStep) {
    if (chainStep <= 1) return 1.0;
    if (chainStep == 2) return 1.2;
    if (chainStep == 3) return 1.5;
    if (chainStep == 4) return 2.0;
    return 3.0;
  }

  static MatchKind kindForCount(int count) {
    return switch (count) {
      3 => MatchKind.normal,
      4 => MatchKind.boosted,
      _ => MatchKind.overcharge,
    };
  }

  /// V2 : seul l’entrant se place ; l’ordre relatif des autres est inchangé.
  static int computeStrategicSlotInsertIndex(
    GameItem incoming,
    List<GameItem> others,
  ) {
    final int n = others.length;
    if (n == 0) return 0;

    for (int i = 0; i < n - 1; i++) {
      final GameItem a = others[i];
      final GameItem b = others[i + 1];
      if (a.typeId == b.typeId &&
          a.colorId == b.colorId &&
          incoming.typeId == a.typeId &&
          incoming.colorId == a.colorId) {
        return i + 2;
      }
    }

    int start = 0;
    while (start < n) {
      int end = start + 1;
      while (end < n && others[end].typeId == others[start].typeId) {
        end++;
      }
      if (others[start].typeId == incoming.typeId && end - start >= 2) {
        return end;
      }
      start = end;
    }
    for (int i = 0; i < n; i++) {
      if (others[i].typeId == incoming.typeId) {
        return i + 1;
      }
    }

    start = 0;
    while (start < n) {
      int end = start + 1;
      while (end < n && others[end].colorId == others[start].colorId) {
        end++;
      }
      if (others[start].colorId == incoming.colorId && end - start >= 2) {
        return end;
      }
      start = end;
    }
    for (int i = 0; i < n; i++) {
      if (others[i].colorId == incoming.colorId) {
        return i + 1;
      }
    }

    return n;
  }

  /// Meilleur run contigu (perfect > autres ; puis plus long ; puis plus à gauche).
  static RackRun? findBestRun(List<GameItem> slots) {
    if (slots.length < 3) return null;

    RackRun? best;
    void consider(RackRun r) {
      if (r.count < 3) return;
      if (best == null) {
        best = r;
        return;
      }
      final int bp = best!.kind == MatchKind.perfect ? 2 : 1;
      final int rp = r.kind == MatchKind.perfect ? 2 : 1;
      if (rp != bp) {
        if (rp > bp) best = r;
        return;
      }
      if (r.count != best!.count) {
        if (r.count > best!.count) best = r;
        return;
      }
      if (r.start < best!.start) best = r;
    }

    int i = 0;
    while (i < slots.length) {
      int j = i + 1;
      while (j < slots.length &&
          slots[j].typeId == slots[i].typeId &&
          slots[j].colorId == slots[i].colorId) {
        j++;
      }
      if (j - i >= 3) {
        consider(RackRun(
          start: i,
          endExclusive: j,
          kind: MatchKind.perfect,
          basis: RunBasis.perfect,
        ));
      }
      i = j;
    }

    i = 0;
    while (i < slots.length) {
      int j = i + 1;
      while (j < slots.length && slots[j].typeId == slots[i].typeId) {
        j++;
      }
      final int n = j - i;
      if (n >= 3) {
        consider(RackRun(
          start: i,
          endExclusive: j,
          kind: kindForCount(n),
          basis: RunBasis.shape,
        ));
      }
      i = j;
    }

    i = 0;
    while (i < slots.length) {
      int j = i + 1;
      while (j < slots.length && slots[j].colorId == slots[i].colorId) {
        j++;
      }
      final int n = j - i;
      if (n >= 3) {
        consider(RackRun(
          start: i,
          endExclusive: j,
          kind: kindForCount(n),
          basis: RunBasis.color,
        ));
      }
      i = j;
    }

    return best;
  }

  static bool slotsHaveAnyTripleRun(List<GameItem> slots) {
    int i = 0;
    while (i < slots.length) {
      int j = i + 1;
      while (j < slots.length && (slots[j].typeId == slots[i].typeId)) {
        j++;
      }
      if (j - i >= 3) return true;
      i = j;
    }
    i = 0;
    while (i < slots.length) {
      int j = i + 1;
      while (j < slots.length && (slots[j].colorId == slots[i].colorId)) {
        j++;
      }
      if (j - i >= 3) return true;
      i = j;
    }
    return false;
  }

  /// Deux pièces identiques (type+couleur) dans le rack → paire pour biais spawn 3e.
  static ({int typeId, int colorId})? slotPairNeedingThirdCopy(
    List<GameItem> slots,
  ) {
    final Map<String, int> counts = <String, int>{};
    for (final GameItem e in slots) {
      final String k = '${e.typeId}_${e.colorId}';
      counts[k] = (counts[k] ?? 0) + 1;
    }
    for (final GameItem e in slots) {
      final String k = '${e.typeId}_${e.colorId}';
      if ((counts[k] ?? 0) == 2) {
        return (typeId: e.typeId, colorId: e.colorId);
      }
    }
    return null;
  }
}

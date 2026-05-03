import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grille de spawn des gemmes (rect plateau, validité cellule, occupation).
///
/// Extraite de [GameState] pour tests et refactor.
abstract final class BoardLayoutLogic {
  BoardLayoutLogic._();

  static double cellPitch(double itemSize, double gridGap) => itemSize + gridGap;

  static Rect boardSpawnRect({
    required Rect playZone,
    required double boardSpawnMinY,
    required double itemSize,
  }) {
    if (playZone.isEmpty) return Rect.zero;
    final double top = math.min(
      math.max(playZone.top, boardSpawnMinY),
      math.max(playZone.top, playZone.bottom - itemSize),
    );
    return Rect.fromLTRB(playZone.left, top, playZone.right, playZone.bottom);
  }

  static int maxCol(Rect sb, double pitch, double itemSize) {
    if (sb.width < itemSize) return 0;
    return math.max(0, ((sb.width - itemSize) / pitch).floor());
  }

  static int maxRow(Rect sb, double pitch, double itemSize) {
    if (sb.height < itemSize) return 0;
    return math.max(0, ((sb.height - itemSize) / pitch).floor());
  }

  static Offset topLeftForCell(Rect sb, double pitch, int col, int row) {
    return Offset(sb.left + col * pitch, sb.top + row * pitch);
  }

  static bool cellValid({
    required int col,
    required int row,
    required Rect spawnRect,
    required Rect luxSafeRect,
    required double itemSize,
    required double pitch,
  }) {
    final Offset p = topLeftForCell(spawnRect, pitch, col, row);
    final Rect item = Rect.fromLTWH(p.dx, p.dy, itemSize, itemSize);
    if (item.left < spawnRect.left - 1e-6 ||
        item.top < spawnRect.top - 1e-6 ||
        item.right > spawnRect.right + 1e-6 ||
        item.bottom > spawnRect.bottom + 1e-6) {
      return false;
    }
    if (luxSafeRect.overlaps(item)) return false;
    return true;
  }

  static bool cellOccupied({
    required int col,
    required int row,
    required Rect spawnRect,
    required double pitch,
    required List<Offset> boardGemTopLefts,
  }) {
    for (final Offset pos in boardGemTopLefts) {
      final int ec = ((pos.dx - spawnRect.left) / pitch).round();
      final int er = ((pos.dy - spawnRect.top) / pitch).round();
      if (ec == col && er == row) return true;
    }
    return false;
  }

  static Offset randomFreeGridTopLeft({
    required Rect spawnRect,
    required Rect luxSafeRect,
    required double itemSize,
    required double gridGap,
    required List<Offset> boardGemTopLefts,
    required math.Random rng,
  }) {
    if (spawnRect.isEmpty) {
      return Offset.zero;
    }
    final double pitch = cellPitch(itemSize, gridGap);
    final int mc = maxCol(spawnRect, pitch, itemSize);
    final int mr = maxRow(spawnRect, pitch, itemSize);
    final List<Offset> free = <Offset>[];
    for (int row = 0; row <= mr; row++) {
      for (int col = 0; col <= mc; col++) {
        if (cellValid(
              col: col,
              row: row,
              spawnRect: spawnRect,
              luxSafeRect: luxSafeRect,
              itemSize: itemSize,
              pitch: pitch,
            ) &&
            !cellOccupied(
              col: col,
              row: row,
              spawnRect: spawnRect,
              pitch: pitch,
              boardGemTopLefts: boardGemTopLefts,
            )) {
          free.add(topLeftForCell(spawnRect, pitch, col, row));
        }
      }
    }
    if (free.isEmpty) {
      return Offset(spawnRect.left, spawnRect.top);
    }
    return free[rng.nextInt(free.length)];
  }

  static Offset findNonOverlappingGridTopLeft({
    required Rect? playZone,
    required Rect luxSafeRect,
    required double boardSpawnMinY,
    required double itemSize,
    required double gridGap,
    required List<Offset> boardGemTopLefts,
    required math.Random rng,
  }) {
    if (playZone == null || playZone.isEmpty) {
      return Offset.zero;
    }
    final Rect sb = boardSpawnRect(
      playZone: playZone,
      boardSpawnMinY: boardSpawnMinY,
      itemSize: itemSize,
    );
    final double pitch = cellPitch(itemSize, gridGap);

    if (sb.isEmpty || sb.width < itemSize || sb.height < itemSize) {
      return Offset(playZone.left, sb.top);
    }

    final int mc = maxCol(sb, pitch, itemSize);
    final int mr = maxRow(sb, pitch, itemSize);

    for (int t = 0; t < 90; t++) {
      final int col = rng.nextInt(mc + 1);
      final int row = rng.nextInt(mr + 1);
      if (!cellValid(
            col: col,
            row: row,
            spawnRect: sb,
            luxSafeRect: luxSafeRect,
            itemSize: itemSize,
            pitch: pitch,
          )) {
        continue;
      }
      if (cellOccupied(
            col: col,
            row: row,
            spawnRect: sb,
            pitch: pitch,
            boardGemTopLefts: boardGemTopLefts,
          )) {
        continue;
      }
      return topLeftForCell(sb, pitch, col, row);
    }

    for (int row = 0; row <= mr; row++) {
      for (int col = 0; col <= mc; col++) {
        if (cellValid(
              col: col,
              row: row,
              spawnRect: sb,
              luxSafeRect: luxSafeRect,
              itemSize: itemSize,
              pitch: pitch,
            ) &&
            !cellOccupied(
              col: col,
              row: row,
              spawnRect: sb,
              pitch: pitch,
              boardGemTopLefts: boardGemTopLefts,
            )) {
          return topLeftForCell(sb, pitch, col, row);
        }
      }
    }

    return randomFreeGridTopLeft(
      spawnRect: sb,
      luxSafeRect: luxSafeRect,
      itemSize: itemSize,
      gridGap: gridGap,
      boardGemTopLefts: boardGemTopLefts,
      rng: rng,
    );
  }
}

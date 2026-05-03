import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/board_layout_logic.dart';

void main() {
  test('boardSpawnRect borne le haut entre minY et zone jouable', () {
    const Rect pz = Rect.fromLTRB(0, 0, 400, 800);
    final Rect sb = BoardLayoutLogic.boardSpawnRect(
      playZone: pz,
      boardSpawnMinY: 200,
      itemSize: 40,
    );
    expect(sb.top, greaterThanOrEqualTo(200));
    expect(sb.top, lessThanOrEqualTo(pz.bottom - 40));
    expect(sb.width, pz.width);
  });

  test('cellValid refuse le chevauchement avec luxSafeRect', () {
    const Rect spawn = Rect.fromLTWH(0, 0, 400, 400);
    const Rect luxHud = Rect.fromLTWH(0, 0, 400, 120);
    const double item = 40;
    const double pitch = 45;
    expect(
      BoardLayoutLogic.cellValid(
        col: 0,
        row: 0,
        spawnRect: spawn,
        luxSafeRect: luxHud,
        itemSize: item,
        pitch: pitch,
      ),
      isFalse,
    );
    expect(
      BoardLayoutLogic.cellValid(
        col: 3,
        row: 3,
        spawnRect: spawn,
        luxSafeRect: luxHud,
        itemSize: item,
        pitch: pitch,
      ),
      isTrue,
    );
  });

  test('cellOccupied détecte une gemme sur la cellule', () {
    const Rect spawn = Rect.fromLTWH(0, 200, 400, 400);
    const double pitch = 45;
    final List<Offset> gems = <Offset>[const Offset(90, 245)];
    expect(
      BoardLayoutLogic.cellOccupied(
        col: 2,
        row: 1,
        spawnRect: spawn,
        pitch: pitch,
        boardGemTopLefts: gems,
      ),
      isTrue,
    );
    expect(
      BoardLayoutLogic.cellOccupied(
        col: 0,
        row: 0,
        spawnRect: spawn,
        pitch: pitch,
        boardGemTopLefts: gems,
      ),
      isFalse,
    );
  });

  test('findNonOverlappingGridTopLeft : scan déterministe (RNG fixe)', () {
    const Rect pz = Rect.fromLTWH(0, 0, 300, 600);
    const Rect lux = Rect.fromLTWH(0, 0, 300, 120);
    final Offset o = BoardLayoutLogic.findNonOverlappingGridTopLeft(
      playZone: pz,
      luxSafeRect: lux,
      boardSpawnMinY: 150,
      itemSize: 40,
      gridGap: 5,
      boardGemTopLefts: const <Offset>[],
      rng: Random(0),
    );
    expect(o.dx, isNonNegative);
    expect(o.dy, isNonNegative);
  });
}

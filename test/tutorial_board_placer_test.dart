import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/tutorial_board_placer.dart';
import 'package:velour_app/models/game_item.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  test('placeNarrativeStep1Gems — 3 gemmes, tap ids alignés', () {
    final List<GameItem> board = <GameItem>[];
    final List<String> tapIds = <String>[];
    int seq = 0;
    TutorialBoardPlacer.placeNarrativeStep1Gems(
      board: board,
      onNarrativeTapId: tapIds.add,
      nextId: () => 'id_${seq++}',
      topLeftForSlot: (int i) => Offset(i * 48.0, 0),
    );
    expect(board.length, 3);
    expect(board[0].typeId, 7);
    expect(board[0].colorId, 1);
    expect(board[0].position, const Offset(0, 0));
    expect(board[1].position, const Offset(48, 0));
    expect(board[0].floatPeriodMs, 2200);
    expect(tapIds, <String>['id_0', 'id_1', 'id_2']);
  });

  test('placeTrinityGemsForPhase none → false, plateau inchangé', () {
    final List<GameItem> board = <GameItem>[];
    final bool ok = TutorialBoardPlacer.placeTrinityGemsForPhase(
      phase: TrinityTutorialPhase.none,
      board: board,
      nextId: () => 'x',
      topLeftForSlot: (_) => Offset.zero,
    );
    expect(ok, isFalse);
    expect(board, isEmpty);
  });

  test('placeTrinityGemsForPhase shape → 3 gemmes type 1', () {
    final List<GameItem> board = <GameItem>[];
    int n = 0;
    final bool ok = TutorialBoardPlacer.placeTrinityGemsForPhase(
      phase: TrinityTutorialPhase.shape,
      board: board,
      nextId: () => 't_${n++}',
      topLeftForSlot: (int i) => Offset(0, i * 40.0),
    );
    expect(ok, isTrue);
    expect(board.length, 3);
    expect(board.every((GameItem e) => e.typeId == 1), isTrue);
    expect(board[0].floatPeriodMs, 2000);
  });
}

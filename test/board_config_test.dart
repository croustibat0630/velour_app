import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/board_config.dart';

void main() {
  test('BoardConfig.boardCapForLevel courbe attendue', () {
    expect(BoardConfig.boardCapForLevel(1), 7);
    expect(BoardConfig.boardCapForLevel(2), 6);
    expect(BoardConfig.boardCapForLevel(3), 5);
    expect(BoardConfig.boardCapForLevel(4), 4);
    expect(BoardConfig.boardCapForLevel(5), 3);
    expect(BoardConfig.boardCapForLevel(99), 3);
  });
}

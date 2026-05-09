import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/providers/game_state_single_timer_slot.dart';

void main() {
  test('GameStateSingleTimerSlot : cancel libère le slot', () {
    final GameStateSingleTimerSlot slot = GameStateSingleTimerSlot();
    expect(slot.isActive, isFalse);
    slot.setPeriodic(const Duration(hours: 1), (_) {});
    expect(slot.isActive, isTrue);
    slot.cancel();
    expect(slot.isActive, isFalse);
  });

  test('GameStateSingleTimerSlot : setPeriodic remplace le timer actif', () {
    final GameStateSingleTimerSlot slot = GameStateSingleTimerSlot();
    slot.setPeriodic(const Duration(hours: 1), (_) {});
    expect(slot.isActive, isTrue);
    slot.setPeriodic(const Duration(hours: 2), (_) {});
    expect(slot.isActive, isTrue);
    slot.cancel();
    expect(slot.isActive, isFalse);
  });
}

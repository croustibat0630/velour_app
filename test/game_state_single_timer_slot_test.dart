import 'package:fake_async/fake_async.dart';
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

  test(
    'GameStateSingleTimerSlot : runOnce puis elapse — callback et inactif',
    () {
      fakeAsync((FakeAsync async) {
        final GameStateSingleTimerSlot slot = GameStateSingleTimerSlot();
        int calls = 0;
        slot.runOnce(const Duration(seconds: 2), () => calls++);
        expect(slot.isActive, isTrue);
        async.elapse(const Duration(seconds: 2));
        expect(calls, 1);
        expect(slot.isActive, isFalse);
      });
    },
  );

  test('GameStateSingleTimerSlot : runOnce remplace un runOnce en cours', () {
    fakeAsync((FakeAsync async) {
      final GameStateSingleTimerSlot slot = GameStateSingleTimerSlot();
      int first = 0;
      int second = 0;
      slot.runOnce(const Duration(seconds: 5), () => first++);
      slot.runOnce(const Duration(seconds: 1), () => second++);
      async.elapse(const Duration(seconds: 1));
      expect(first, 0);
      expect(second, 1);
      async.elapse(const Duration(seconds: 5));
      expect(first, 0);
    });
  });
}

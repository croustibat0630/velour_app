import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/utils/single_timer_slot.dart';

void main() {
  test('SingleTimerSlot : cancel libère le slot', () {
    final SingleTimerSlot slot = SingleTimerSlot();
    expect(slot.isActive, isFalse);
    slot.setPeriodic(const Duration(hours: 1), (_) {});
    expect(slot.isActive, isTrue);
    slot.cancel();
    expect(slot.isActive, isFalse);
  });

  test('SingleTimerSlot : setPeriodic remplace le timer actif', () {
    final SingleTimerSlot slot = SingleTimerSlot();
    slot.setPeriodic(const Duration(hours: 1), (_) {});
    expect(slot.isActive, isTrue);
    slot.setPeriodic(const Duration(hours: 2), (_) {});
    expect(slot.isActive, isTrue);
    slot.cancel();
    expect(slot.isActive, isFalse);
  });

  test('SingleTimerSlot : runOnce puis elapse — callback et inactif', () {
    fakeAsync((FakeAsync async) {
      final SingleTimerSlot slot = SingleTimerSlot();
      int calls = 0;
      slot.runOnce(const Duration(seconds: 2), () => calls++);
      expect(slot.isActive, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(calls, 1);
      expect(slot.isActive, isFalse);
    });
  });

  test('SingleTimerSlot : runOnce remplace un runOnce en cours', () {
    fakeAsync((FakeAsync async) {
      final SingleTimerSlot slot = SingleTimerSlot();
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

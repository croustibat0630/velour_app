import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/services/velour_activation_funnel.dart';

void main() {
  late VelourActivationFunnel funnel;

  setUp(() {
    funnel = VelourActivationFunnel.instance;
    funnel.debugReset();
  });

  tearDown(() {
    funnel.debugReset();
  });

  test('funnel steps advance and first_* are once-only', () {
    funnel.debugWarmUpSync(isFirstLaunch: true);
    funnel.noteFtueStart();
    expect(funnel.lastStep, 'ftue_start');

    funnel.noteMenuPlayPressed();
    funnel.notePrepOpened(stakeKind: 'casual');
    funnel.notePrepConfirmed(stakeKind: 'casual', runInstanceId: 'run_1');
    funnel.noteRunStarted(stakeKind: 'casual', runInstanceId: 'run_1');
    expect(funnel.lastStep, 'run_started');

    funnel.noteFirstGemCollected();
    funnel.noteFirstGemCollected();
    expect(funnel.lastStep, 'first_gem_collected');

    funnel.noteFirstMatch(basis: 'shape');
    funnel.noteFirstMatch(basis: 'color');
    expect(funnel.lastStep, 'first_match');

    funnel.noteFirstPerfect(basis: 'perfect');
    funnel.noteFirstPerfect(basis: 'perfect');
    expect(funnel.hasFirstPerfect, isTrue);
    expect(funnel.lastStep, 'first_perfect');
  });

  test('ftue_completed after Perfect + 15s continue', () {
    fakeAsync((FakeAsync async) {
      funnel.debugWarmUpSync(isFirstLaunch: true);
      funnel.noteFtueStart();
      funnel.noteFirstPerfect(basis: 'perfect');
      expect(funnel.ftueCompleted, isFalse);

      async.elapse(const Duration(seconds: 14));
      expect(funnel.ftueCompleted, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(funnel.ftueCompleted, isTrue);
      expect(funnel.lastStep, 'ftue_completed');
    });
  });

  test('ftue_completed on second run after Perfect', () {
    funnel.debugWarmUpSync(isFirstLaunch: true);
    funnel.noteFtueStart();
    funnel.noteRunStarted(stakeKind: 'casual', runInstanceId: 'r1');
    funnel.noteFirstPerfect(basis: 'perfect');
    expect(funnel.ftueCompleted, isFalse);

    funnel.noteRunStarted(stakeKind: 'casual', runInstanceId: 'r2');
    expect(funnel.ftueCompleted, isTrue);
    expect(funnel.lastStep, 'ftue_completed');
  });

  test('session_closed is once-only and follows Perfect', () {
    funnel.debugWarmUpSync(isFirstLaunch: true);
    funnel.noteFtueStart();
    funnel.noteFirstPerfect(basis: 'perfect');
    funnel.noteSessionClosed(lifecycle: 'paused');
    expect(funnel.lastStep, 'session_closed');
    funnel.noteSessionClosed(lifecycle: 'detached');
    expect(funnel.lastStep, 'session_closed');
  });
}

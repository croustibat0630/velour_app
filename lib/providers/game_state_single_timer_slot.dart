import 'dart:async';

/// Fente unique pour un [Timer] (one-shot ou périodique) dans [GameState].
final class GameStateSingleTimerSlot {
  Timer? _timer;

  bool get isActive => _timer != null;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Annule l’ancien timer puis installe un [Timer] one-shot.
  ///
  /// Après le tick, [isActive] redevient `false` avant l’appel à [callback]
  /// (y compris pour un [callback] `async`, dont la [Future] n’est pas attendue).
  void runOnce(Duration duration, void Function() callback) {
    cancel();
    _timer = Timer(duration, () {
      _timer = null;
      callback();
    });
  }

  /// Annule l’ancien timer puis installe un [Timer.periodic].
  void setPeriodic(Duration interval, void Function(Timer timer) callback) {
    cancel();
    _timer = Timer.periodic(interval, callback);
  }
}

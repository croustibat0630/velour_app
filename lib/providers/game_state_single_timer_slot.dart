import 'dart:async';

/// Fente unique pour un [Timer] périodique (ex. boucle chrono [GameState]).
final class GameStateSingleTimerSlot {
  Timer? _timer;

  bool get isActive => _timer != null;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Annule l’ancien timer puis installe un [Timer.periodic].
  void setPeriodic(Duration interval, void Function(Timer timer) callback) {
    cancel();
    _timer = Timer.periodic(interval, callback);
  }
}

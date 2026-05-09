import 'dart:math' as math;

/// Trace verbeuse pour sessions exploratoires (`flutter run` + QA manuelle).
///
/// Activer (exemples) :
/// `flutter run --dart-define=VELOUR_SESSION_TRACE=1`
/// `flutter run --dart-define=VELOUR_SESSION_TRACE=true`
///
/// Ne pas activer en release store : bruit console + coût I/O.
class VelourSessionTrace {
  VelourSessionTrace._();

  /// `bool.fromEnvironment` ne considère que le littéral `'true'` ; on accepte aussi
  /// `1` / `yes` pour coller à `--dart-define=VELOUR_SESSION_TRACE=1`.
  static const String _raw = String.fromEnvironment(
    'VELOUR_SESSION_TRACE',
    defaultValue: '',
  );

  static bool get enabled {
    final String v = _raw.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }

  static final String _sid = () {
    final int r = math.Random().nextInt(1 << 32);
    return r.toRadixString(16).padLeft(8, '0');
  }();

  static int _seq = 0;

  static void log(String name, {Map<String, Object?> data = const {}}) {
    if (!enabled) return;
    final int t = DateTime.now().microsecondsSinceEpoch;
    final int s = ++_seq;
    // ignore: avoid_print
    print('[VelourTrace] sid=$_sid seq=$s t=$t $name data=$data');
  }

  static void gameStateNotify({
    required int runLux,
    required int walletLux,
    required int highScore,
    required int level,
    required bool paused,
    required bool gameOver,
    required bool criticalFailure,
  }) {
    if (!enabled) return;
    log(
      'gameState.notify',
      data: <String, Object?>{
        'runLux': runLux,
        'walletLux': walletLux,
        'highScore': highScore,
        'level': level,
        'paused': paused,
        'gameOver': gameOver,
        'criticalFailure': criticalFailure,
      },
    );
  }
}

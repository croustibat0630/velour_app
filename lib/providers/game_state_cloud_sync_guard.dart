import 'dart:async';

/// Garde réentrance pour [GameState.flushCloudSyncOnAppHidden] (pause / hidden).
///
/// Extrait pour alléger `game_state.dart` et centraliser le motif try/finally.
final class GameStateCloudSyncGuard {
  bool _busy = false;

  Future<void> run(Future<void> Function() op) async {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      await op();
    } finally {
      _busy = false;
    }
  }
}

import 'package:audioplayers/audioplayers.dart';

enum VelourSfx { select, match, gameOver }

class VelourAudio {
  VelourAudio._();

  static final VelourAudio instance = VelourAudio._();

  // Web: prefer low-latency for short SFX.
  final AudioPlayer _select = AudioPlayer(playerId: 'velour_select');
  final AudioPlayer _match = AudioPlayer(playerId: 'velour_match');
  final AudioPlayer _gameOver = AudioPlayer(playerId: 'velour_gameover');

  bool _ready = false;
  bool _disabled = false;

  Future<void> preload() async {
    if (_ready) return;
    _ready = true;

    // Web: forcing setSource/preload can cause "Format Error (Code 4)" on Chrome.
    // Only configure players here. Actual source is provided in play().
    try {
      await _safeConfig(_select);
      await _safeConfig(_match);
      await _safeConfig(_gameOver);
    } catch (_) {
      _disabled = true;
    }
  }

  Future<void> dispose() async {
    await _select.dispose();
    await _match.dispose();
    await _gameOver.dispose();
  }

  Future<void> play(VelourSfx sfx) async {
    if (_disabled) return;
    final (AudioPlayer, String) t = switch (sfx) {
      VelourSfx.select => (_select, 'audio/select.mp3'),
      VelourSfx.match => (_match, 'audio/match.mp3'),
      VelourSfx.gameOver => (_gameOver, 'audio/gameover.mp3'),
    };
    final AudioPlayer p = t.$1;
    final String path = t.$2;

    try {
      await p.play(AssetSource(path));
    } on AudioPlayerException {
      // Silent fallback: never break gameplay, never spam console.
      _disabled = true;
    } catch (_) {
      _disabled = true;
    }
  }

  Future<void> _safeConfig(AudioPlayer p) async {
    try {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(1.0);
    } on AudioPlayerException {
      // ignore
    } catch (_) {
      // ignore
    }
  }
}

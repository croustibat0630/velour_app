import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BackgroundMusicService {
  BackgroundMusicService._();

  static final BackgroundMusicService instance = BackgroundMusicService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'velour_bgm');
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setVolume(0.6);
    } catch (_) {
      // silent on web/unsupported
    }
  }

  Future<void> playLoopAsset(String assetPath) async {
    if (muted.value) return;
    try {
      await configure();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // silent fallback
    }
  }

  Future<void> setMuted(bool v) async {
    muted.value = v;
    try {
      if (v) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {
      // ignore
    }
  }
}

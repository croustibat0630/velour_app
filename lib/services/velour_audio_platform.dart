import 'package:audio_session/audio_session.dart' as ars;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../utils/velour_audio_trace.dart';

/// Session native alignée sur [velourGameAudioContext] (iOS : playback + mixWithOthers).
const ars.AudioSessionConfiguration velourAudioSessionConfiguration =
    ars.AudioSessionConfiguration(
      avAudioSessionCategory: ars.AVAudioSessionCategory.playback,
      avAudioSessionMode: ars.AVAudioSessionMode.defaultMode,
      avAudioSessionCategoryOptions:
          ars.AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: ars.AndroidAudioAttributes(
        contentType: ars.AndroidAudioContentType.music,
        usage: ars.AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: ars.AndroidAudioFocusGainType.gain,
    );

/// Contexte [audioplayers] explicite + activation de session (évite les conflits
/// de noms entre `audio_session` et `audioplayers_platform_interface`).
AudioContext velourGameAudioContext() {
  return AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );
}

/// À appeler au cold start et avant les lectures importantes (menu, unlock).
Future<void> configureVelourAudioPipeline({
  bool activateSession = false,
  bool force = false,
}) async {
  if (kIsWeb) return;
  const int ctxCooldownMicros = 2 * 1000 * 1000; // 2s
  const int sessionCooldownMicros = 4 * 1000 * 1000; // 4s

  final int now = DateTime.now().microsecondsSinceEpoch;
  // Avoid reconfiguring the same pipeline repeatedly when screens rebuild.
  // These are best-effort guards: if something *did* change, callers can pass `force: true`.
  if (!force && _lastCtxConfigureMicros != 0) {
    final int dt = now - _lastCtxConfigureMicros;
    if (dt >= 0 && dt < ctxCooldownMicros) {
      // Skip repeated global context sets in a tight window.
    } else {
      _lastCtxConfigureMicros = 0;
    }
  }

  final AudioContext ctx = velourGameAudioContext();
  if (force || _lastCtxConfigureMicros == 0) {
    try {
      await AudioPlayer.global.setAudioContext(ctx);
      _lastCtxConfigureMicros = now;
      velourAudioTrace('audioplayers global.setAudioContext ok');
    } catch (e, st) {
      velourAudioTrace('audioplayers global.setAudioContext failed: $e');
      velourAudioTrace('$st');
    }
  }
  if (activateSession) {
    if (!force && _lastSessionActivateMicros != 0) {
      final int dt = now - _lastSessionActivateMicros;
      if (dt >= 0 && dt < sessionCooldownMicros) {
        return;
      }
    }
    try {
      final ars.AudioSession session = await ars.AudioSession.instance;
      // Toujours re-configurer : évite un premier `.music()` sans options iOS
      // désynchronisé par rapport au contexte audioplayers / AppDelegate.
      await session.configure(velourAudioSessionConfiguration);
      await session.setActive(true);
      _lastSessionActivateMicros = now;
      velourAudioTrace('audio_session configure + setActive(true) ok');
    } catch (e, st) {
      velourAudioTrace('audio_session failed: $e');
      velourAudioTrace('$st');
    }
  }
}

int _lastCtxConfigureMicros = 0;
int _lastSessionActivateMicros = 0;

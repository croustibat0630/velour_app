import 'package:audio_session/audio_session.dart' as ars;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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
Future<void> configureVelourAudioPipeline({bool activateSession = false}) async {
  if (kIsWeb) return;
  final AudioContext ctx = velourGameAudioContext();
  try {
    await AudioPlayer.global.setAudioContext(ctx);
  } catch (_) {}
  if (activateSession) {
    try {
      final ars.AudioSession session = await ars.AudioSession.instance;
      if (!session.isConfigured) {
        await session.configure(const ars.AudioSessionConfiguration.music());
      }
      await session.setActive(true);
    } catch (_) {}
  }
}

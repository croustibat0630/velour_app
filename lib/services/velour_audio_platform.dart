import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Configure la session OS + le contexte global [audioplayers] (obligatoire en
/// v6 pour un son fiable sur iOS / Android hors debug).
Future<void> configureVelourAudioPipeline({bool activateSession = false}) async {
  if (kIsWeb) return;
  try {
    final AudioSession session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration.music().copyWith(
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.game,
        ),
      ),
    );
    if (activateSession) {
      await session.setActive(true);
    }
  } catch (_) {}
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        respectSilence: false,
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
  } catch (_) {}
}

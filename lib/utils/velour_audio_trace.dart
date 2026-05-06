import 'package:flutter/foundation.dart';

/// Logs audio diagnostics to stdout.
///
/// Defaults:
/// - Enabled in debug/profile.
/// - Can be forced in release with: `--dart-define=VELOUR_AUDIO_TRACE=true`
void velourAudioTrace(String message) {
  const bool force = bool.fromEnvironment(
    'VELOUR_AUDIO_TRACE',
    defaultValue: false,
  );
  if (!(force || kDebugMode || kProfileMode)) return;
  // ignore: avoid_print
  print('[VelourAudio] $message');
}

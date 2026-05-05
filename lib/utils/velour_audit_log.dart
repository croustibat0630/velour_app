import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Structured audit logs (safe for profile/dev).
///
/// - Printed to stdout (visible in `flutter run --profile`).
/// - **Must not** include secrets (tokens, receipts, JWS, emails, etc).
class VelourAuditLog {
  VelourAuditLog._();

  // Allow enabling audit logs in `--release` for field sessions:
  // `flutter run --release --dart-define=VELOUR_AUDIT=1`
  static const bool _forceEnabledInRelease =
      bool.fromEnvironment('VELOUR_AUDIT', defaultValue: false);

  static final String sessionId = () {
    final int r = math.Random().nextInt(1 << 32);
    return r.toRadixString(16).padLeft(8, '0');
  }();

  static int _seq = 0;

  static bool get enabled => _forceEnabledInRelease || kDebugMode || kProfileMode;

  static void event(
    String name, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    if (!enabled) return;
    final int t = DateTime.now().microsecondsSinceEpoch;
    final int s = ++_seq;
    // ignore: avoid_print
    print('[VelourAudit] sid=$sessionId seq=$s t=$t $name data=$data');
  }
}


import 'velour_session_trace.dart';

/// Point d’extension pour instrumentation locale.
///
/// Avec `--dart-define=VELOUR_SESSION_TRACE=1` (ou `=true`), chaque message est imprimé
/// (voir [VelourSessionTrace]).
void velourDebug(String message) {
  if (!VelourSessionTrace.enabled) return;
  VelourSessionTrace.log(
    'velourDebug',
    data: <String, Object?>{'msg': message},
  );
}

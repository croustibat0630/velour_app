import 'match_types.dart';
import '../services/audio_handler.dart';
import '../services/haptics_handler.dart';

/// Pilote unique son + haptique à la résolution d’un match (évite double impulsion).
abstract final class MatchFeedback {
  MatchFeedback._();

  /// À appeler une fois par résolution, au moment voulu (ex. après l’anim de « pop »).
  static void emit({
    required MatchKind kind,
    required RunBasis basis,
    required bool narrativePerfectForBanner,
  }) {
    if (kind == MatchKind.perfect) {
      AudioHandler.instance.playPerfectCombo();
    } else {
      AudioHandler.instance.playMatchCombo();
    }
    if (basis == RunBasis.shape || basis == RunBasis.color) {
      HapticsHandler.instance.lightImpact();
    } else if (basis == RunBasis.perfect && !narrativePerfectForBanner) {
      HapticsHandler.instance.mediumImpact();
    }
  }
}

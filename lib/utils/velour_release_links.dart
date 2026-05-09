import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;

/// Liens injectés au **build** pour les releases (stores / testeurs).
///
/// Exemple :
/// `flutter build appbundle --release --dart-define=VELOUR_PRIVACY_POLICY_URL=https://example.com/privacy`
abstract final class VelourReleaseLinks {
  static const String privacyPolicyUrl = String.fromEnvironment(
    'VELOUR_PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  /// URL d’exemple documentée (ne convient pas à une soumission store réelle).
  static const String documentationExamplePrivacyUrl =
      'https://example.com/privacy';

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.trim().isNotEmpty;

  /// À appeler au démarrage en **release** : alerte build si la checklist privacy n’a pas été suivie.
  static void debugWarnIfPrivacyPolicyMisconfiguredForRelease() {
    if (!kReleaseMode) return;
    final String u = privacyPolicyUrl.trim();
    if (u.isEmpty) {
      debugPrint(
        '[VelourReleaseLinks] RELEASE WARNING: VELOUR_PRIVACY_POLICY_URL is empty. '
        'Pass --dart-define=VELOUR_PRIVACY_POLICY_URL=https://… on store builds '
        '(see docs/STORE_RELEASE_CHECKLIST.md).',
      );
      return;
    }
    final Uri? parsed = Uri.tryParse(u);
    final bool looksLikeDocPlaceholder =
        u == documentationExamplePrivacyUrl ||
        (parsed != null && parsed.host == 'example.com');
    if (looksLikeDocPlaceholder) {
      debugPrint(
        '[VelourReleaseLinks] RELEASE WARNING: VELOUR_PRIVACY_POLICY_URL is the '
        'documentation placeholder ($u). Replace with your real policy URL before store submission.',
      );
    }
  }
}

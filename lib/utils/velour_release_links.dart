/// Liens injectés au **build** pour les releases (stores / testeurs).
///
/// Exemple :
/// `flutter build appbundle --release --dart-define=VELOUR_PRIVACY_POLICY_URL=https://example.com/privacy`
abstract final class VelourReleaseLinks {
  static const String privacyPolicyUrl = String.fromEnvironment(
    'VELOUR_PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.trim().isNotEmpty;
}

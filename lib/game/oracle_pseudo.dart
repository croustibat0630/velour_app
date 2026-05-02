/// Règles d’affichage / stockage du pseudo Oracle (lettres, chiffres, `_`).
class OraclePseudo {
  OraclePseudo._();

  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9_]{1,15}$');

  static bool isValid(String trimmed) => _allowed.hasMatch(trimmed);

  /// Stockage canonique : minuscules → moins de doublons `Pierre` / `pierre`.
  static String normalizeForStorage(String trimmed) => trimmed.toLowerCase();

  /// Lisibilité menu / classement (première lettre en majuscule, reste tel quel).
  static String formatForDisplay(String stored) {
    if (stored.isEmpty) return stored;
    return stored[0].toUpperCase() + stored.substring(1);
  }
}

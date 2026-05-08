import 'package:flutter/material.dart';

import '../game/oracle_pseudo.dart';
import 'firestore_service.dart';

/// Dialogue « nommer l’Oracle » après record persistant (offre cloud).
///
/// Découple [GameState] de [FirestoreService] pour ce flux UI isolé.
class OracleNamingService extends ChangeNotifier {
  bool _visible = false;

  bool get shouldShowDialog => _visible;

  void dismiss() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }

  /// Hard reset / debug : ferme tout état dialogue mémoire.
  void reset() {
    _visible = false;
    notifyListeners();
  }

  /// Rappelé par [EconomyService] après commit d’un nouveau record (awaited).
  Future<void> maybeOfferForNewHighScore(int newHighScore) async {
    if (_visible) return;
    // Évite d'agresser au premier lancement / bootstrap (score 0, menu pas encore “joué”).
    if (newHighScore <= 0) return;
    final bool offer = await FirestoreService.instance
        .shouldOfferOracleNamingForNewHighScore(newHighScore);
    if (!offer) return;
    _visible = true;
    notifyListeners();
  }

  /// Ne propage **jamais** d’exception (évite dialogue bloqué).
  /// `true` si la cérémonie peut se fermer (succès cloud ou hors-ligne).
  Future<bool> submitName(String newName) async {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (!OraclePseudo.isValid(trimmed)) return false;
    final String cleaned = OraclePseudo.normalizeForStorage(trimmed);

    if (!FirestoreService.instance.isCloudReady) {
      _visible = false;
      notifyListeners();
      return true;
    }
    final bool ok = await FirestoreService.instance.updateOraclePseudo(cleaned);
    if (ok) {
      _visible = false;
      notifyListeners();
    }
    return ok;
  }
}

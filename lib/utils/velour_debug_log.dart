import 'package:flutter/foundation.dart';

/// Journalisation verbose (moteur, timer, spawn). Silencieux en release.
void velourDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

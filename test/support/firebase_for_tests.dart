import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseException, FirebaseOptions;
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/firebase_options.dart';

bool _firebaseTestInitialized = false;
bool _firebaseMocksInstalled = false;

/// Initialise Firebase pour les tests widget (Firestore / Auth sans app native).
///
/// Sur [TargetPlatform.linux] / [TargetPlatform.fuchsia], [DefaultFirebaseOptions]
/// n’expose pas de config : on retombe sur les options **web** (projet réel, mocks channel).
///
/// Idempotent sur toute la suite : si `[DEFAULT]` existe déjà (autre fichier de test),
/// on ne réessaie pas [Firebase.initializeApp].
Future<void> ensureFirebaseTestInitialized() async {
  if (_firebaseTestInitialized) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!_firebaseMocksInstalled) {
    setupFirebaseCoreMocks();
    _firebaseMocksInstalled = true;
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: _firebaseOptionsForTestVm());
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }
  _firebaseTestInitialized = true;
}

FirebaseOptions _firebaseOptionsForTestVm() {
  if (kIsWeb) {
    return DefaultFirebaseOptions.web;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return DefaultFirebaseOptions.web;
    default:
      return DefaultFirebaseOptions.currentPlatform;
  }
}

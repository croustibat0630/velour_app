import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barres système Velour : fond sombre, icônes claires, transparent (edge-to-edge).
const SystemUiOverlayStyle velourSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Edge-to-edge + style barres (Android 15+ / Play Console, iOS safe-area friendly).
///
/// Android : complète [enableEdgeToEdge] natif (`MainActivity`) pour API &lt; 15.
/// iOS : pas d’alerte Play équivalente ; [SystemUiMode.edgeToEdge] + overlay
/// transparent laissent [SafeArea] / [MediaQuery.padding] gérer encoches et Dynamic Island.
Future<void> velourConfigureSystemUi() async {
  if (kIsWeb) return;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(velourSystemUiOverlayStyle);
}

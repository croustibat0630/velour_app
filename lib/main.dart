import 'package:flutter/material.dart';

import 'velour_app.dart';
import 'velour_bootstrap.dart';

export 'velour_app.dart' show VelourApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await velourRunAppStartup();
  runApp(const VelourApp());
}

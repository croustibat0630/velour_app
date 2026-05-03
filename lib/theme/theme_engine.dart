import 'package:flutter/material.dart';

class ActiveTheme {
  const ActiveTheme({required this.name, required this.paletteByColorId});

  final String name;
  final Map<int, Color> paletteByColorId;
}

class ThemeEngine extends ChangeNotifier {
  ThemeEngine() : _active = defaultTheme;

  static final ActiveTheme defaultTheme = ActiveTheme(
    name: 'Neon Glass',
    paletteByColorId: const {
      0: Color(0xFFFFFFFF),
      1: Color(0xFF00FFFF), // cyan
      2: Color(0xFFFFD700), // gold
      3: Color(0xFFFF00FF), // magenta
      4: Color(0xFF39FF14), // electric green
      5: Color(0xFF7800FF), // purple (blue-leaning)
      6: Color(0xFFFF6A00), // neon orange
      7: Color(0xFFF8FFFF), // electric white (distinct from pure white)
    },
  );

  ActiveTheme _active;
  ActiveTheme get activeTheme => _active;

  Color? _skinPrimaryOverride;
  Color? _skinSecondaryOverride;

  Color? get skinPrimaryOverride => _skinPrimaryOverride;
  Color? get skinSecondaryOverride => _skinSecondaryOverride;

  void applySkinColors({required Color primary, required Color secondary}) {
    if (_skinPrimaryOverride == primary &&
        _skinSecondaryOverride == secondary) {
      return;
    }
    _skinPrimaryOverride = primary;
    _skinSecondaryOverride = secondary;
    notifyListeners();
  }

  void setTheme(ActiveTheme theme) {
    _active = theme;
    notifyListeners();
  }

  Color colorForId(int colorId) {
    if (colorId == 1 && _skinPrimaryOverride != null) {
      return _skinPrimaryOverride!;
    }
    if (colorId == 5 && _skinSecondaryOverride != null) {
      return _skinSecondaryOverride!;
    }
    return _active.paletteByColorId[colorId] ?? const Color(0xFF00FFFF);
  }
}

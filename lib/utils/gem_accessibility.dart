import 'package:velour_app/l10n/app_localizations.dart';

/// Libellé VoiceOver / TalkBack pour une gemme (forme + couleur), localisé.
String gemAccessibilityLabel(
  AppLocalizations l10n,
  int typeId,
  int colorId,
) {
  final String shape = _shapeName(l10n, typeId);
  final String color = _colorName(l10n, colorId);
  return l10n.a11yGemButtonLabel(shape, color);
}

String _shapeName(AppLocalizations l10n, int typeId) {
  return switch (typeId) {
    1 => l10n.a11yGemShape1,
    2 => l10n.a11yGemShape2,
    3 => l10n.a11yGemShape3,
    4 => l10n.a11yGemShape4,
    5 => l10n.a11yGemShape5,
    6 => l10n.a11yGemShape6,
    7 => l10n.a11yGemShape7,
    _ => l10n.a11yGemShape1,
  };
}

String _colorName(AppLocalizations l10n, int colorId) {
  return switch (colorId) {
    0 => l10n.a11yGemColor0,
    1 => l10n.a11yGemColor1,
    2 => l10n.a11yGemColor2,
    3 => l10n.a11yGemColor3,
    4 => l10n.a11yGemColor4,
    5 => l10n.a11yGemColor5,
    6 => l10n.a11yGemColor6,
    7 => l10n.a11yGemColor7,
    _ => l10n.a11yGemColor1,
  };
}
